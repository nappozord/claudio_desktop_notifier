#!/bin/sh
# Removes Claudio's hooks from ~/.claude/settings.json and deletes ~/.claude/claudio/.
# Homebrew runs this as `claudio-uninstall`; `brew uninstall claudio` then removes the app itself.
set -e
DEST="$HOME/.claude/claudio"
SETTINGS="$HOME/.claude/settings.json"

pkill -x claudio 2>/dev/null || true
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.claudio-backup"
  tmp=$(mktemp)
  jq '
    def ours: (.hooks // []) | any((.command // "") | test("/\\.claude/(claudio|eyes)/|/claudio/libexec/scripts/"));
    if .hooks then
      .hooks |= (with_entries(.value |= map(select(ours | not)))
                 | with_entries(select(.value | length > 0)))
    else . end
  ' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
fi
rm -rf "$DEST"
echo "Claudio removed. Backup of the previous settings: $SETTINGS.claudio-backup"
