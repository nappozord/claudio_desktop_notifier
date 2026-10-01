#!/bin/sh
# Asks the banner (if one is on screen) to slide away.
# Used by the UserPromptSubmit and PostToolUse hooks.
[ -n "$CLAUDIO_NESTED" ] && exit 0
pkill -USR1 -x claudio 2>/dev/null
exit 0
