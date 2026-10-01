#!/bin/sh
# notify.sh <done|ask>
# Shows the Claudio banner. Hook JSON may arrive on stdin; its text feeds the speech bubble.
# Replaces this session's banner if one is on screen; other sessions' banners stack above it.
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

# the session id goes in the phrase file's name, so dismiss.sh can find this session's banner by its arguments
sid=$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9-')
# replace only this session's previous banner (or the previous one without a session, e.g. make preview);
# other sessions' banners stay, and the new one stacks under them
if [ -n "$sid" ]; then
  pkill -f "/claudio (done|ask) .*/claudio\.$sid\." 2>/dev/null
else
  pkill -f "/claudio (done|ask) .*/claudio\.[A-Za-z0-9]{6}\$" 2>/dev/null
fi
f="$(mktemp -u "${TMPDIR:-/tmp}/claudio.${sid:+$sid.}XXXXXX")"
nohup "$BIN" "$mode" "$f" >/dev/null 2>&1 &
log "banner started (pid $!)"
[ -n "$CLAUDIO_LOG" ] && (sleep 1; pgrep -x claudio >/dev/null || log "banner exited within 1s") &
printf '%s' "$text" | nohup "$DIR/phrase.sh" "$mode" "$f" >/dev/null 2>&1 &
