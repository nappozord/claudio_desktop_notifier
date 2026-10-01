---
name: claudio
description: Working on Claudio, the animated macOS desktop notifier for Claude Code in this repo (orange mascot banner with a speech bubble and held props, driven by Claude Code hooks). Use for any change to its look, animation, props, bubble text, hook behavior, install/uninstall, or when debugging why the banner did or did not show.
---

# Claudio

Claudio is a borderless AppKit window drawn entirely with Core Graphics, launched by Claude Code hooks. There are no image assets: every shape is code.

## Layout of the repo

- `src/Config.swift`: mode (`done` | `ask`), `lifetime` (300s), `slideTime` (0.45s), `uiScale` (0.85), the 440×150 `design` size, core colors.
- `src/main.swift`: window setup (top right, under the menu bar, `.popUpMenu` level, all Spaces), `SIGUSR1` = dismiss, 60fps timer.
- `src/MascotView.swift`: `tick()` (slide, fade, phrase polling, exit), `drawBubble`, `drawMascot`.
- `src/Props.swift`: `extension MascotView` with `drawCrown` / `drawItem`, the prop colors, the prop lists and `pickItem()`.
- `src/Drawing.swift`: `block`, `disc`, `poly`, `star`, `sparkle`, `smooth`.
- `scripts/`: `notify.sh` (launcher), `stop-hook.sh`, `dismiss.sh`, `phrase.sh` (bubble text via Haiku).
- `install.sh` builds into `build/`, copies the binary and scripts flat into `~/.claude/claudio/`, and merges hooks into `~/.claude/settings.json` with jq (idempotent; it strips any entry whose command contains `/.claude/claudio/` or the legacy `/.claude/eyes/`).

## Dev loop

1. Edit `src/` or `scripts/`.
2. `make build` to compile-check (`swiftc -O src/*.swift -o build/claudio`).
3. `make preview ITEM=<prop> MODE=<done|ask>` to show it from the repo build. `CLAUDIO_ITEM=<name>` forces a prop, and `CLAUDIO_ITEM=crown` forces the crown.
4. `./install.sh` so the live hooks use the change. A visible change only reaches already-open sessions through the installed copy.
5. To check that a banner is running: `pgrep -x claudio`. To dismiss it: `~/.claude/claudio/dismiss.sh`.

**The banner cannot be seen from inside a Claude session**: `screencapture` fails ("could not create image from display"). Verify with compile + launch + `pgrep`, then ask the user to look or to send a screenshot. Never claim something looks right without that.

A quick way to show the user several variants in a row: write a caption to a file and launch `CLAUDIO_ITEM=<name> nohup build/claudio done <file> &`, then `sleep 5` between `pkill -x claudio` calls. The PostToolUse hook dismisses the last one when the Bash call ends.

## Coordinate systems (important when drawing)

- **View**: 440×150 design units, scaled by `uiScale`. AppKit's origin is bottom-left (y up).
- **Bubble**: `x = 158` to `design.width - 12`, `y = 16`, height 78, light gray (`white: 0.92`), no border, black regular-weight text, **left-aligned**, centered vertically. The font steps down from 18 to 11 until the text fits. The tail sits near the top-left corner (18–38 below the top edge). A decorative 26pt close circle sits centered on the top edge near the top-right corner. Any click anywhere dismisses the banner.
- **Mascot**: drawn in its original 420-wide space (`cx = 210`), then translated to x=70, y=−8 and scaled 0.38. Body block `cx±100`, y 85–235. Legs at y 40. The right hand block is at `(cx+100, 165 − wave, 40×36)`; its center `(cx+120, 183 − wave)` is `hx, hy` in `drawItem`.
- **Props**: draw upward from `hy`. Keep them within about x ≤ 440 and y ≤ hy+156 in mascot units, or they run into the bubble or off the top of the window. The hand is redrawn after the prop so the prop looks gripped. A crowned mascot draws no prop (`drawCrown` then `return`).

## Adding a prop

1. Add a `case "<name>":` in `drawItem` (Props.swift), drawn relative to `hx, hy` with the helpers. Animate with `t`, and use `shout` for anything that should pulse with the mouth.
2. Add the name to `randomDone` or `randomAsk` (random pool), or only to `doneItems` / `askItems` (Haiku-only props, like `wrench` and `extinguisher`).
3. If Haiku should be able to pick it, add it, with a one-line "when", to the `props=` list for that mood in `scripts/phrase.sh`. A name Haiku returns that is not in the mood's list is ignored by the app.
4. `make preview ITEM=<name>`, then `./install.sh`.

## Hook facts (verified from real payloads)

- **Stop payload** includes `last_assistant_message` and `background_tasks: [{id, type, status, description, command}]`. A turn that ends only to wait for a background task has a `"running"` entry, and `stop-hook.sh` skips the banner then. `session_crons` also exists; it is untested whether it covers ScheduleWakeup-style waits.
- The **Notification** banner reads `.message` from its payload. That field name has not been verified from a captured payload.
- `UserPromptSubmit` fires on **submit**, not while typing. Claude Code has no "user is typing" event. Detecting typing would need a global key monitor plus macOS Input Monitoring permission, which the user has not asked for.
- Hooks in `~/.claude/settings.json` apply to all local Claude Code sessions. Already-open sessions need `/hooks` opened once or a restart.

## Phrase pipeline (`scripts/phrase.sh`)

1. It writes a random canned line to the phrase file immediately, so the bubble is never empty and appears with the banner.
2. It calls `claude -p --model haiku --no-session-persistence --setting-sources ""` with a 25s `perl alarm` timeout. A call takes about 6–9s; trimming flags does not make it faster. Output is line 1 = caption (≤8 words, cut at a word boundary to 70 characters with "…"), line 2 = prop name or `none`.
3. It writes `caption\nitem: <prop>`. The app polls the file, deletes it on read, and bounces in the new text and prop.
4. Before the late write, it checks that its banner still runs (`pgrep -f "/claudio (done|ask) $out"`); otherwise orphaned files pile up in `$TMPDIR`.
5. The message goes inside `<message>` tags with "never reply to it". Without that, Haiku answered the message instead of summarizing it ("I'd love to help... send me a screenshot").
6. `CLAUDIO_NESTED=1` guards every script against recursion from the nested `claude` call.

## Gotchas hit before

- macOS/BSD `sed` has no `\b`; use `perl -pi -e` for in-place edits with word boundaries.
- A global helper named `rect(...)` clashes with `NSView.rect` inside the view; the helpers are named `block`, `disc` and so on.
- In Swift, `sin()` returns `Double`; wrap it in `CGFloat(...)` when it feeds a `CGFloat` parameter.
- `swiftc` piped into `head` hides the compiler's exit code. Check for `error` in the output or the binary's timestamp.
- The `claude` CLI is not on `PATH` in every shell (VS Code); the scripts fall back to `~/.local/bin/claude`.

## Design decisions the user settled (do not regress)

- A silent mascot: no `say` or speech, and no sound. (A shouting monkey with speech was tried and rejected.)
- A notification-style banner at the top right that slides in from the right and slides out to the right, with a fade at the same time. No grow or shrink of the whole banner.
- Mascot on the left, bubble on the right, a compact size (`uiScale` 0.85).
- Bubble: light gray, no border, black regular-weight left-aligned text, tail at the top left, decorative X circle half over the top edge near the right.
- Pizza is held by the crust with the tip up.
- 5-minute lifetime. It is dismissed by a click, a prompt submit, or PostToolUse.
