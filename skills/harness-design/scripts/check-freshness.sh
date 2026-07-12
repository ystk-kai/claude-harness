#!/usr/bin/env bash
# 蒸留版 (references/*.md) の鮮度を原典 clone と突き合わせて報告する。
#   BEHIND: clone が upstream より遅れている → git pull --ff-only で更新
#   STALE : 蒸留版の distilled_commit が clone の HEAD より古い → DISTILLING.md の手順で更新
# 既定で origin を fetch する (shallow clone は履歴ごと取得)。--offline で fetch を省略。
# 終了コード: 0=全て最新, 1=要対応あり
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
REFS_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/references"
. "$SCRIPT_DIR/frontmatter.sh"

offline=0
if [ "${1:-}" = "--offline" ]; then offline=1; fi
status=0

for doc in "$SKILL_DIR"/references/*.md; do
  [ -e "$doc" ] || { echo "references/ に蒸留版がない"; exit 1; }
  source_url="$(fm_value "$doc" source)"
  pinned="$(fm_value "$doc" distilled_commit)"
  if [ -z "$source_url" ] || [ -z "$pinned" ]; then
    echo "SKIP   $(basename "$doc"): frontmatter に source / distilled_commit がない"
    status=1; continue
  fi
  name="$(repo_dir_name "$source_url")"
  clone="$REFS_ROOT/$name"
  if ! git -C "$clone" rev-parse --git-dir >/dev/null 2>&1; then
    echo "MISS   $name: clone がない/壊れている ($clone) — install.sh --with-references で取得"
    status=1; continue
  fi

  if [ "$offline" -eq 0 ]; then
    if [ "$(git -C "$clone" rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
      git -C "$clone" fetch --quiet --unshallow origin 2>/dev/null \
        || git -C "$clone" fetch --quiet origin 2>/dev/null \
        || echo "NOTE   $name: fetch 失敗 (オフライン?) — ローカル状態のみで判定"
    else
      git -C "$clone" fetch --quiet origin 2>/dev/null \
        || echo "NOTE   $name: fetch 失敗 (オフライン?) — ローカル状態のみで判定"
    fi
  fi

  head_sha="$(git -C "$clone" rev-parse HEAD 2>/dev/null)" \
    || { echo "ERR    $name: HEAD が解決できない ($clone)"; status=1; continue; }

  # 短縮 SHA も受け付け、完全 SHA に解決してから比較する
  pinned_full="$(git -C "$clone" rev-parse --verify --quiet "$pinned^{commit}" 2>/dev/null || true)"
  if [ -z "$pinned_full" ]; then
    echo "ERR    $name: distilled_commit ($pinned) が履歴に見つからない — git -C \"$clone\" fetch origin $pinned で取得"
    status=1; continue
  fi

  upstream="$(git -C "$clone" rev-parse --verify --quiet origin/HEAD 2>/dev/null || true)"
  if [ -n "$upstream" ] && [ "$upstream" != "$head_sha" ]; then
    behind="$(git -C "$clone" rev-list --count HEAD..origin/HEAD 2>/dev/null || echo '?')"
    echo "BEHIND $name: clone が upstream より $behind commits 遅れ — git -C \"$clone\" pull --ff-only"
    status=1
  fi

  if [ "$pinned_full" = "$head_sha" ]; then
    echo "OK     $name @ ${head_sha:0:12}"
  else
    behind="$(git -C "$clone" rev-list --count "$pinned_full..HEAD" 2>/dev/null || echo '?')"
    echo "STALE  $name: 蒸留時 ${pinned_full:0:12} → 現在 ${head_sha:0:12} ($behind commits)"
    git -C "$clone" log --oneline "$pinned_full..HEAD" 2>/dev/null | sed 's/^/         /' || true
    status=1
  fi
done
exit $status
