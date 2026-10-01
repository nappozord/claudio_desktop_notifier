#!/bin/sh
# Builds Claudio, copies it to ~/.claude/claudio/ and registers its Claude Code hooks
# in ~/.claude/settings.json. Safe to re-run after every change.
set -e
REPO=$(cd "$(dirname "$0")" && pwd)
DEST="$HOME/.claude/claudio"
SETTINGS="$HOME/.claude/settings.json"

command -v jq >/dev/null || { echo "jq is required: brew install jq"; exit 1; }
command -v swiftc >/dev/null || { echo "swiftc is required: xcode-select --install"; exit 1; }

echo "Building..."
mkdir -p "$REPO/build"
swiftc -O "$REPO"/src/*.swift -o "$REPO/build/claudio"

echo "Installing to $DEST"
pkill -x claudio 2>/dev/null || true
mkdir -p "$DEST"
cp "$REPO/build/claudio" "$REPO"/scripts/*.sh "$DEST/"
chmod +x "$DEST/claudio" "$DEST"/*.sh

echo "Registering hooks in $SETTINGS"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.claudio-backup"
tmp=$(mktemp)
# drop any earlier Claudio entries (also the pre-repo ~/.claude/eyes ones), then add the current ones
jq --arg d "$DEST" '
  def ours: (.hooks // []) | any((.command // "") | test("/\\.claude/(claudio|eyes)/"));
  def add($ev; $cmd):
    .hooks[$ev] = ((.hooks[$ev] // []) | map(select(ours | not)))
                  + [{"hooks": [{"type": "command", "command": $cmd, "async": true}]}];
  .hooks = (.hooks // {})
  | add("Stop"; "\($d)/stop-hook.sh")
  | add("Notification"; "\($d)/notify.sh ask")
  | add("UserPromptSubmit"; "\($d)/dismiss.sh")
  | add("PostToolUse"; "\($d)/dismiss.sh")
' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "Done. Open /hooks once (or start a new Claude Code session) to load the hooks."
echo "Preview: make preview   (or: make preview ITEM=pizza MODE=ask)"
