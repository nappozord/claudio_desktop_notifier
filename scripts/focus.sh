#!/bin/sh
# focus.sh: brings the session that showed the banner to the front. The banner runs it when
# clicked anywhere but the X. notify.sh sets CLAUDIO_FOCUS_APP (the app's bundle id),
# CLAUDIO_FOCUS_DIR (the session's folder) and CLAUDIO_FOCUS_TTY (its terminal tab, CLI only).
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/common.sh"
app="$CLAUDIO_FOCUS_APP"; dir="$CLAUDIO_FOCUS_DIR"; tty="$CLAUDIO_FOCUS_TTY"
log "focus: app=${app:-?}, entrypoint=${CLAUDE_CODE_ENTRYPOINT:-?}, dir=$dir, tty=${tty:-none}"
[ -n "$app" ] || exit 0

# VS Code and its forks keep their settings under ~/Library/Application Support/<this name>
code_settings_dir() {
  case "$1" in
    com.microsoft.VSCode) echo "Code" ;;
    com.microsoft.VSCodeInsiders) echo "Code - Insiders" ;;
    com.vscodium) echo "VSCodium" ;;
    com.todesktop.230313mzl4w4u92) echo "Cursor" ;;
    com.exafunction.windsurf) echo "Windsurf" ;;
  esac
}
# code_window <storage.json> <session folder>: the open folder or .code-workspace file whose folder is
# the deepest one containing the session. Opening it focuses that window; opening the session's own
# folder could open a new one (a window opened from a workspace file does not count as that folder).
code_window() {
  best=""; bestlen=0
  for uri in $(jq -r '.windowsState | [.lastActiveWindow] + (.openedWindows // []) | .[] | select(. != null)
                      | (.folder // .workspaceIdentifier.configURIPath // empty)' "$1" 2>/dev/null); do
    case "$uri" in file://*) ;; *) continue ;; esac   # skip remote windows
    wpath=$(printf '%s' "${uri#file://}" | perl -pe 's/%([0-9A-Fa-f]{2})/chr(hex($1))/ge')
    case "$wpath" in *.code-workspace) base=$(dirname "$wpath") ;; *) base="$wpath" ;; esac
    case "$2/" in "$base"/*) [ ${#base} -gt "$bestlen" ] && { best="$wpath"; bestlen=${#base}; } ;; esac
  done
  printf '%s' "$best"
}

case "$app" in
  com.anthropic.claudefordesktop)
    # Desktop's own link to its most recent Code session
    open "claude://code/continue?session=last" ;;
  com.apple.Terminal)
    # select the tab running this session (macOS asks once to allow controlling Terminal)
    osascript - "$tty" <<'EOF' >/dev/null 2>&1 || open -b "$app"
on run argv
  set target to item 1 of argv
  tell application "Terminal"
    repeat with w in windows
      repeat with t in tabs of w
        if tty of t is target then
          set selected of t to true
          set index of w to 1
        end if
      end repeat
    end repeat
    activate
  end tell
end run
EOF
    ;;
  com.googlecode.iterm2)
    osascript - "$tty" <<'EOF' >/dev/null 2>&1 || open -b "$app"
on run argv
  set target to item 1 of argv
  tell application "iTerm2"
    repeat with w in windows
      repeat with t in tabs of w
        repeat with s in sessions of t
          if tty of s is target then
            tell w to select
            tell t to select
            tell s to select
          end if
        end repeat
      end repeat
    end repeat
    activate
  end tell
end run
EOF
    ;;
  *)
    code_dir=$(code_settings_dir "$app")
    target=""
    [ -n "$code_dir" ] && target=$(code_window "$HOME/Library/Application Support/$code_dir/User/globalStorage/storage.json" "$dir")
    log "focus: open -b $app ${target:-(app only)}"
    if [ -n "$target" ]; then open -b "$app" "$target"; else open -b "$app"; fi ;;
esac
