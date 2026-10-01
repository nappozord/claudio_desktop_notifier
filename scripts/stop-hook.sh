#!/bin/sh
# Stop hook: show the banner only when the work is really finished,
# i.e. no background task is still running (timers, long commands, monitors).
[ -n "$CLAUDIO_NESTED" ] && exit 0
DIR=$(cd "$(dirname "$0")" && pwd)
payload=$(cat)
running=$(printf '%s' "$payload" | jq '[.background_tasks[]? | select(.status == "running")] | length' 2>/dev/null)
[ "${running:-0}" -gt 0 ] && exit 0
printf '%s' "$payload" | exec "$DIR/notify.sh" done
