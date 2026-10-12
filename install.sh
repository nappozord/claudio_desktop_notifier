#!/bin/sh
# Registers Claudio's Claude Code hooks in ~/.claude/settings.json. Safe to re-run.
# - From the repo: builds Claudio, copies it to ~/.claude/claudio/, and the hooks run that copy.
# - From Homebrew (as `claudio-setup`, no src/ next to it): the hooks run the scripts in place,
#   through the version-independent opt/claudio path, so `brew upgrade` needs no re-run.
# ~/.claude/claudio/ also holds the debug flag, the log and claude-path in both cases.
# ./install.sh --no-check   skips the Haiku test call at the end (quicker while iterating)
set -e
# ./install.sh --no-haiku   turns captions off for good (writes haiku=off to ~/.claude/claudio/config): no tokens used
# ./install.sh --haiku      turns them back on
check=1; haiku_set=""
for arg in "$@"; do
  case "$arg" in
    --no-check) check=0 ;;
    --no-haiku) haiku_set=off ;;
    --haiku) haiku_set=on ;;
    *) echo "Unknown option $arg (--no-check, --no-haiku, --haiku)"; exit 1 ;;
  esac
done
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

pkill -x claudio 2>/dev/null || true
mkdir -p "$DEST"
if [ -d "$REPO/src" ]; then
  echo "Installing to $DEST"
  cp "$REPO/build/claudio" "$REPO"/scripts/*.sh "$DEST/"
  chmod +x "$DEST/claudio" "$DEST"/*.sh
  HOOKS="$DEST"
else
  # drop copies left by an earlier repo install, so only one version is around
  rm -f "$DEST/claudio" "$DEST"/*.sh
  HOOKS="$REPO/scripts"
fi
# remember where `claude` is in this shell: hooks may run with a shorter PATH
. "$REPO/scripts/common.sh"
rm -f "$DEST/claude-path"
claude_bin=$(find_claude || true)
[ -n "$claude_bin" ] && printf '%s\n' "$claude_bin" > "$DEST/claude-path"

if [ -n "$haiku_set" ]; then
  # update the haiku= line in place (or append it); other settings stay
  touch "$DEST/config"
  tmp=$(mktemp)
  grep -v '^[[:space:]]*haiku[[:space:]]*=' "$DEST/config" > "$tmp" || true
  echo "haiku=$haiku_set" >> "$tmp"
  mv "$tmp" "$DEST/config"
  echo "Haiku captions set to $haiku_set in $DEST/config"
fi

echo "Registering hooks in $SETTINGS"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.claudio-backup"
tmp=$(mktemp)
# drop any earlier Claudio entries (repo, Homebrew, and the pre-repo ~/.claude/eyes ones), then add the current ones
jq --arg d "$HOOKS" '
  def ours: (.hooks // []) | any((.command // "") | test("/\\.claude/(claudio|eyes)/|/claudio/libexec/scripts/"));
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

if ! haiku_on; then
  echo "Haiku captions: off (config): canned lines only, no tokens used"
elif [ "$check" = 1 ]; then
  printf 'Haiku captions (one test call, about 10s): '
  "$HOOKS/phrase.sh" --check || echo "  The banner still works, with canned lines. Details: README, \"Haiku captions\"."
fi

echo "Done. Open /hooks once (or start a new Claude Code session) to load the hooks."
if [ -d "$REPO/src" ]; then
  echo "Preview: make preview PROP=pizza   (PROP = prop, ACCESSORY = accessory, MASCOT = mascot color, MODE=done|ask = mood; make props/accessories/mascots list the names)"
else
  echo "Preview: claudio PROP=pizza   (claudio --help for more)"
fi
