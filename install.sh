#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
TARGET="$CLAUDE_DIR/CLAUDE.md"

mkdir -p "$CLAUDE_DIR/skills"

# skills/*/ を ~/.claude/skills/<name> へ symlink で展開
for skill_dir in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill_dir")"
  dst="$CLAUDE_DIR/skills/$name"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "skip skill $name: $dst に symlink でない実体がある (手動で退避してから再実行)"
    continue
  fi
  ln -sfn "${skill_dir%/}" "$dst"
done

# claude-md/*.md をグローバル CLAUDE.md の managed block として挿入 (既存ブロックは置換)
#
# 全ブロックを取り除いてから貼り直す。1 ブロックずつ「剥がして即追記」すると、剥がした跡の
# 空行が次のブロックより手前に残り、実行ごとに空行が増える (2 ブロック以上で顕在化)。
#
# marker は行全体一致で判定し、BEGIN と END の対応が崩れていたら書き込まずに中断する。
# 部分一致 + 対応チェック無しだと、片割れ marker (編集途中) や単独行に marker を引用した
# 手書き部分から先の内容を巻き込んで消し、CLAUDE.md は手書きなので復元できない。
touch "$TARGET"
content="$(cat "$TARGET")"
for snippet in "$REPO_DIR"/claude-md/*.md; do
  [ -e "$snippet" ] || continue
  block="$(basename "$snippet" .md)"
  stripped="$(printf '%s\n' "$content" | awk \
    -v b="<!-- BEGIN managed:$block -->" -v e="<!-- END managed:$block -->" '
      $0 == b { if (skip) err = 1; skip = 1; next }   # 入れ子の BEGIN
      $0 == e { if (!skip) err = 2; skip = 0; next }   # 対応する BEGIN の無い END
      !skip
      END { if (skip) err = 3; if (err) exit err }     # 閉じていない BEGIN
    ')" || {
    st=$?
    case $st in
      1) reason="managed:$block の BEGIN が入れ子になっている" ;;
      2) reason="managed:$block の END に対応する BEGIN が無い" ;;
      3) reason="managed:$block の BEGIN が END で閉じられていない" ;;
      *) reason="managed:$block の marker 解析に失敗した (awk exit $st)" ;;
    esac
    echo "abort: $TARGET の $reason。手で marker を直してから再実行する ($TARGET は書き換えていない)" >&2
    exit 1
  }
  content="$stripped"
done
# 末尾の空行を落とす (手書き部分と各ブロックの間は常に空行 1 行に揃える)
content="$(printf '%s\n' "$content" | awk '
  { a[NR] = $0 }
  END { l = NR; while (l > 0 && a[l] ~ /^[[:space:]]*$/) l--; for (i = 1; i <= l; i++) print a[i] }
')"
# 出来上がりを組み立ててから、変わるときだけ backup を取って書く
rebuilt="$content"
for snippet in "$REPO_DIR"/claude-md/*.md; do
  [ -e "$snippet" ] || continue
  if [ -n "$rebuilt" ]; then rebuilt="$rebuilt"$'\n\n'"$(cat "$snippet")"; else rebuilt="$(cat "$snippet")"; fi
done
if [ "$rebuilt" != "$(cat "$TARGET")" ]; then
  [ -s "$TARGET" ] && cp "$TARGET" "$TARGET.pre-claude-harness.bak"
  if [ -n "$rebuilt" ]; then printf '%s\n' "$rebuilt" >"$TARGET"; else : >"$TARGET"; fi
fi

# settings/global.json を ~/.claude/settings.json へキー単位でマージする。
# 対象は managed 側に書いたキーだけで、他は既存値のまま残す (settings.json 全体を repo が所有しない)。
# hooks はこの repo の hooks/ を指す handler だけを剥がしてから貼り直すので、再実行しても重複しない。
MANAGED_SETTINGS="$REPO_DIR/settings/global.json"
if [ -f "$MANAGED_SETTINGS" ]; then
  chmod +x "$REPO_DIR"/hooks/*.sh 2>/dev/null || true
  if ! command -v jq >/dev/null 2>&1; then
    echo "skip settings: jq が無い ($MANAGED_SETTINGS のマージには jq が要る)"
  else
    settings="$CLAUDE_DIR/settings.json"
    [ -s "$settings" ] || echo '{}' >"$settings"
    # 壊れた JSON / トップレベルが object でないものは生の jq エラーで落ちるので先に弾く
    if ! jq -e 'type == "object"' "$settings" >/dev/null 2>&1; then
      echo "abort: $settings が JSON object として読めない (壊れているか配列)。手で直すかリネームしてから再実行する" >&2
      exit 1
    fi
    managed="$(jq --arg root "$REPO_DIR" '
      walk(if type == "string" then gsub("\\{\\{REPO_DIR\\}\\}"; $root) else . end)
      | with_entries(select(.key | startswith("_") | not))
    ' "$MANAGED_SETTINGS")"
    merged="$(jq --argjson m "$managed" --arg prefix "$REPO_DIR/hooks/" '
      # matcher entry ごと落とすと、同じ entry に同居するユーザー自前の handler も消える。
      # entry の hooks 配列から repo 配下を指す handler だけを抜き、空になった entry のみ落とす。
      def drop_managed:
        (. // {})
        | with_entries(
            .value |= ( map(.hooks |= map(select((.command // "") | startswith($prefix) | not)))
                        | map(select((.hooks | length) > 0)) ))
        | with_entries(select(.value | length > 0));
      . as $c
      | $c
      + { extraKnownMarketplaces: (($c.extraKnownMarketplaces // {}) + ($m.extraKnownMarketplaces // {}))
        , enabledPlugins:         (($c.enabledPlugins // {}) + ($m.enabledPlugins // {}))
        , hooks: (reduce ($m.hooks // {} | to_entries[]) as $e
                    ($c.hooks | drop_managed; .[$e.key] = ((.[$e.key] // []) + $e.value)))
        }
      | if (.extraKnownMarketplaces | length) == 0 then del(.extraKnownMarketplaces) else . end
      | if (.enabledPlugins        | length) == 0 then del(.enabledPlugins)        else . end
      | if (.hooks                 | length) == 0 then del(.hooks)                 else . end
    ' "$settings")"
    if [ "$(printf '%s' "$merged" | jq -S .)" != "$(jq -S . "$settings")" ]; then
      cp "$settings" "$settings.pre-claude-harness.bak"
      printf '%s\n' "$merged" >"$settings"
      echo "settings merged: $settings (直前の内容は $settings.pre-claude-harness.bak)"
    fi
  fi
fi

# --with-references: 各スキルの references/*.md frontmatter (source) から原典 clone を取得
if [ "${1:-}" = "--with-references" ]; then
  . "$REPO_DIR/skills/claude-harness-refs-update/scripts/frontmatter.sh"
  mkdir -p "$CLAUDE_DIR/references"
  for doc in "$REPO_DIR"/skills/*/references/*.md; do
    [ -e "$doc" ] || continue
    url="$(fm_value "$doc" source)"
    [ -n "$url" ] || continue
    dir="$CLAUDE_DIR/references/$(repo_dir_name "$url")"
    [ -d "$dir" ] || git clone --filter=blob:none "$url" "$dir"
    # 原典が同梱する .claude/skills は Claude Code のディレクトリスコープ skill として
    # 自動登録される (原典を読むだけで第三者の指示が発火し得る)。worktree から外す。
    # .claude/{agents,commands,hooks,settings.json,rules} は入れ子では自動ロードされず
    # 参照価値があるので残す。中身は git -C <clone> show HEAD:<path> で読める。
    git -C "$dir" sparse-checkout set --no-cone '/*' '!/.claude/skills' >/dev/null
  done
fi

echo "applied: skills symlinks + CLAUDE.md managed blocks ($TARGET)"
