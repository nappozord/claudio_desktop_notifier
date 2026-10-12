#!/bin/sh
# Stop hook: show the banner only when the work is really finished,
# i.e. no background task is still running (timers, long commands, monitors).
#
# Exception: if the SAME session reports "still running" several times in a row, force the
# banner through anyway. A task's "running" status can get stuck in the hook's own payload
# after the real process is long gone — confirmed live: TaskStop returned "not found" for one
# such task ID, yet this hook kept seeing it as running for 17+ minutes across many Stop
# events in one long session. Without this, Claudio can go silent for the rest of a session.
[ -n "$CLAUDIO_NESTED" ] && exit 0
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/common.sh"
payload=$(cat)
log "ran: entrypoint=${CLAUDE_CODE_ENTRYPOINT:-?}, config_dir=${CLAUDE_CONFIG_DIR:-~/.claude}, os=$(uname -s), payload keys: $(printf '%s' "$payload" | jq -c keys 2>&1 | head -c 300)"
running=$(printf '%s' "$payload" | jq '[.background_tasks[]? | select(.status == "running")] | length' 2>/dev/null)

sid=$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9-')
skip_file="${CLAUDIO_HOME:-$HOME/.claude/claudio}/stop-skips${sid:+.$sid}"
FORCE_AFTER=2   # show the banner anyway after this many consecutive "still running" skips

if [ "${running:-0}" -gt 0 ]; then
    skips=$(( $(cat "$skip_file" 2>/dev/null || echo 0) + 1 ))
    if [ "$skips" -le "$FORCE_AFTER" ]; then
        mkdir -p "$(dirname "$skip_file")" 2>/dev/null
        echo "$skips" > "$skip_file"
        log "skipped ($skips/$FORCE_AFTER): $running background task(s) still running"
        exit 0
    fi
    log "forcing banner after $skips consecutive skips despite $running task(s) reported running (likely stale)"
    rm -f "$skip_file"
else
    rm -f "$skip_file"
fi

printf '%s' "$payload" | exec "$DIR/notify.sh" done
