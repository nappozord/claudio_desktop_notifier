#!/bin/sh
# notify.sh <done|ask>
# Shows the Claudio banner. Hook JSON may arrive on stdin; its text feeds the speech bubble.
# Replaces any banner already on screen.
[ -n "$CLAUDIO_NESTED" ] && exit 0   # never fire from Claudio's own phrase-generation call
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/common.sh"
BIN="$DIR/claudio"
[ -x "$BIN" ] || BIN="$DIR/../build/claudio"   # running from the repo
mode="${1:-done}"

payload=""
[ -t 0 ] || payload=$(cat)
field=".last_assistant_message"; [ "$mode" = "ask" ] && field=".message"
text=$(printf '%s' "$payload" | jq -r "$field // empty" 2>/dev/null)

# where the session runs, so a click on the banner can jump back to it (focus.sh reads these)
session_tty() {   # the terminal tab of the nearest ancestor that has one (the claude CLI); none in VS Code or Desktop
  pid=$$
  while [ "${pid:-1}" -gt 1 ]; do
    t=$(ps -o tty= -p "$pid" | tr -d ' ')
    case "$t" in ""|"??") ;; *) echo "/dev/$t"; return ;; esac
    pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
  done
}
CLAUDIO_FOCUS="$DIR/focus.sh"
CLAUDIO_FOCUS_APP="${__CFBundleIdentifier:-}"   # set by macOS for apps and inherited by the hooks
CLAUDIO_FOCUS_DIR=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
CLAUDIO_FOCUS_DIR="${CLAUDIO_FOCUS_DIR:-$PWD}"
CLAUDIO_FOCUS_TTY=$(session_tty)
export CLAUDIO_FOCUS CLAUDIO_FOCUS_APP CLAUDIO_FOCUS_DIR CLAUDIO_FOCUS_TTY
log "mode=$mode, ${#text} chars of text, app=${CLAUDIO_FOCUS_APP:-?}, tty=${CLAUDIO_FOCUS_TTY:-none}, entrypoint=${CLAUDE_CODE_ENTRYPOINT:-?}, os=$(uname -s), jq=$(command -v jq || echo MISSING), PATH=$PATH"

pkill -x claudio 2>/dev/null
f="$(mktemp -u "${TMPDIR:-/tmp}/claudio.XXXXXX")"
nohup "$BIN" "$mode" "$f" >/dev/null 2>&1 &
log "banner started (pid $!)"
[ -n "$CLAUDIO_LOG" ] && (sleep 1; pgrep -x claudio >/dev/null || log "banner exited within 1s") &
printf '%s' "$text" | nohup "$DIR/phrase.sh" "$mode" "$f" >/dev/null 2>&1 &
