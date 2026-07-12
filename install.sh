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
touch "$TARGET"
for snippet in "$REPO_DIR"/claude-md/*.md; do
  [ -e "$snippet" ] || continue
  block="$(basename "$snippet" .md)"
  begin_mark="<!-- BEGIN managed:$block -->"
  end_mark="<!-- END managed:$block -->"
  content="$(awk -v b="$begin_mark" -v e="$end_mark" '
    index($0, b) { skip = 1; next }
    index($0, e) { skip = 0; next }
    !skip
  ' "$TARGET")"
  printf '%s\n\n' "$content" > "$TARGET"
  cat "$snippet" >> "$TARGET"
done

# --with-references: 各スキルの references/*.md frontmatter (source) から原典 clone を取得
if [ "${1:-}" = "--with-references" ]; then
  . "$REPO_DIR/skills/harness-design/scripts/frontmatter.sh"
  mkdir -p "$CLAUDE_DIR/references"
  for doc in "$REPO_DIR"/skills/*/references/*.md; do
    [ -e "$doc" ] || continue
    url="$(fm_value "$doc" source)"
    [ -n "$url" ] || continue
    dir="$CLAUDE_DIR/references/$(repo_dir_name "$url")"
    [ -d "$dir" ] || git clone --filter=blob:none "$url" "$dir"
  done
fi

echo "applied: skills symlinks + CLAUDE.md managed blocks ($TARGET)"
