# common.sh: sourced by the other scripts (not run on its own).

# Hooks started by apps opened from the Dock (Claude Desktop, sometimes VS Code) can get a
# short PATH (/usr/bin:/bin:/usr/sbin:/sbin), so add the usual Homebrew and installer places.
for d in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin"; do
  case ":$PATH:" in *":$d:"*) ;; *) PATH="$PATH:$d" ;; esac
done
CLAUDIO_HOME="$HOME/.claude/claudio"

# Debug log: on while ~/.claude/claudio/debug exists (or CLAUDIO_DEBUG=1), written to claudio.log there.
CLAUDIO_LOG=""
if [ -n "$CLAUDIO_DEBUG" ] || [ -e "$CLAUDIO_HOME/debug" ]; then
  CLAUDIO_LOG="$CLAUDIO_HOME/claudio.log"
fi
log() {
  [ -n "$CLAUDIO_LOG" ] && [ -d "$CLAUDIO_HOME" ] || return 0
  [ -f "$CLAUDIO_LOG" ] && [ "$(wc -c < "$CLAUDIO_LOG")" -gt 500000 ] && mv "$CLAUDIO_LOG" "$CLAUDIO_LOG.old"
  printf '%s [%s] %s\n' "$(date '+%F %T')" "$(basename "$0")" "$*" >> "$CLAUDIO_LOG"
}

# find_claude: prints the first usable claude CLI. In order: the path install.sh recorded,
# PATH, the old npm-local install, and the copy bundled with Claude Desktop (newest version).
find_claude() {
  for c in "$(cat "$CLAUDIO_HOME/claude-path" 2>/dev/null)" \
           "$(command -v claude 2>/dev/null)" \
           "$HOME/.claude/local/claude" \
           "$(ls -td "$HOME/Library/Application Support/Claude/claude-code/"*/claude.app/Contents/MacOS/claude 2>/dev/null | head -n 1)"; do
    [ -n "$c" ] && [ -x "$c" ] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}
