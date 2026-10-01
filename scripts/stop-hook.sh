#!/bin/sh
# Stop hook: show the banner only when the work is really finished,
# i.e. no background task is still running (timers, long commands, monitors).
[ -n "$CLAUDIO_NESTED" ] && exit 0
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/common.sh"
payload=$(cat)
log "ran: entrypoint=${CLAUDE_CODE_ENTRYPOINT:-?}, config_dir=${CLAUDE_CONFIG_DIR:-~/.claude}, os=$(uname -s), payload keys: $(printf '%s' "$payload" | jq -c keys 2>&1 | head -c 300)"
running=$(printf '%s' "$payload" | jq '[.background_tasks[]? | select(.status == "running")] | length' 2>/dev/null)
[ "${running:-0}" -gt 0 ] && { log "skipped: $running background task(s) still running"; exit 0; }
printf '%s' "$payload" | exec "$DIR/notify.sh" done
