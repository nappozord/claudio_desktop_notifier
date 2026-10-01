#!/bin/sh
# Asks the banner of this hook's session (if one is on screen) to slide away.
# Used by the UserPromptSubmit and PostToolUse hooks. Other sessions' banners stay: the session id
# is in each banner's phrase-file argument (see notify.sh). Without a session id, any banner goes.
[ -n "$CLAUDIO_NESTED" ] && exit 0
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/common.sh"
sid=""
[ -t 0 ] || sid=$(jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9-')
if [ -n "$sid" ]; then
  pkill -USR1 -f "/claudio (done|ask) .*/claudio\.$sid\." 2>/dev/null && log "dismissed (session $sid)"
else
  pkill -USR1 -x claudio 2>/dev/null && log "dismissed (any session)"
fi
exit 0
