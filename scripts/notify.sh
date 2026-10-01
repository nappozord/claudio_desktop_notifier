#!/bin/sh
# notify.sh <done|ask>
# Shows the Claudio banner. Hook JSON may arrive on stdin; its text feeds the speech bubble.
# Replaces any banner already on screen.
[ -n "$CLAUDIO_NESTED" ] && exit 0   # never fire from Claudio's own phrase-generation call
DIR=$(cd "$(dirname "$0")" && pwd)
BIN="$DIR/claudio"
[ -x "$BIN" ] || BIN="$DIR/../build/claudio"   # running from the repo
mode="${1:-done}"

if [ -t 0 ]; then
  text=""
else
  field=".last_assistant_message"; [ "$mode" = "ask" ] && field=".message"
  text=$(jq -r "$field // empty" 2>/dev/null)
fi

pkill -x claudio 2>/dev/null
f="$(mktemp -u "${TMPDIR:-/tmp}/claudio.XXXXXX")"
nohup "$BIN" "$mode" "$f" >/dev/null 2>&1 &
printf '%s' "$text" | nohup "$DIR/phrase.sh" "$mode" "$f" >/dev/null 2>&1 &
