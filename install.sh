#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILL_NAME="harness-design"
SNIPPET="$REPO_DIR/claude-md/$SKILL_NAME.md"
TARGET="$CLAUDE_DIR/CLAUDE.md"
BEGIN_MARK="<!-- BEGIN managed:$SKILL_NAME -->"
END_MARK="<!-- END managed:$SKILL_NAME -->"

mkdir -p "$CLAUDE_DIR/skills"
ln -sfn "$REPO_DIR/skills/$SKILL_NAME" "$CLAUDE_DIR/skills/$SKILL_NAME"

touch "$TARGET"
content="$(awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
  index($0, b) { skip = 1; next }
  index($0, e) { skip = 0; next }
  !skip
' "$TARGET")"
printf '%s\n\n' "$content" > "$TARGET"
cat "$SNIPPET" >> "$TARGET"

if [ "${1:-}" = "--with-references" ]; then
  mkdir -p "$CLAUDE_DIR/references"
  grep -oE 'https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' "$REPO_DIR/skills/$SKILL_NAME/SKILL.md" \
    | sort -u | while read -r url; do
      dir="$CLAUDE_DIR/references/$(basename "$url")"
      [ -d "$dir" ] || git clone --depth 1 "$url" "$dir"
    done
fi

echo "applied: skill symlink + CLAUDE.md managed block ($TARGET)"
