#!/bin/sh
# Builds Claudio (when run from the repo), copies it to ~/.claude/claudio/ and registers its
# Claude Code hooks in ~/.claude/settings.json. Safe to re-run after every change.
# The Homebrew formula runs this as `claudio-setup`, from a copy with build/claudio already built.
# ./install.sh --no-check   skips the Haiku test call at the end (quicker while iterating)
set -e
REPO=$(cd "$(dirname "$0")" && pwd)
DEST="$HOME/.claude/claudio"
SETTINGS="$HOME/.claude/settings.json"

command -v jq >/dev/null || { echo "jq is required (built into macOS 15 and later; older versions: brew install jq)"; exit 1; }
if [ -d "$REPO/src" ]; then
  command -v swiftc >/dev/null || { echo "swiftc is required: xcode-select --install"; exit 1; }
  echo "Building..."
  mkdir -p "$REPO/build"
  swiftc -O "$REPO"/src/*.swift -o "$REPO/build/claudio"
fi
[ -x "$REPO/build/claudio" ] || { echo "No claudio binary at $REPO/build/claudio"; exit 1; }

echo "Installing to $DEST"
pkill -x claudio 2>/dev/null || true
mkdir -p "$DEST"
cp "$REPO/build/claudio" "$REPO"/scripts/*.sh "$DEST/"
chmod +x "$DEST/claudio" "$DEST"/*.sh
# remember where `claude` is in this shell: hooks may run with a shorter PATH
. "$REPO/scripts/common.sh"
rm -f "$DEST/claude-path"
claude_bin=$(find_claude || true)
[ -n "$claude_bin" ] && printf '%s\n' "$claude_bin" > "$DEST/claude-path"

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

if [ "$1" != "--no-check" ]; then
  printf 'Haiku captions (one test call, about 10s): '
  "$DEST/phrase.sh" --check || echo "  The banner still works, with canned lines. Details: README, \"Haiku captions\"."
fi

echo "Done. Open /hooks once (or start a new Claude Code session) to load the hooks."
if [ -d "$REPO/src" ]; then
  echo "Preview: make preview ITEM=pizza   (ITEM = prop, MODE=done|ask = mood; make props lists the props)"
else
  echo "Preview: CLAUDIO_ITEM=pizza $DEST/notify.sh done < /dev/null"
fi
