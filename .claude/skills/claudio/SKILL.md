---
name: claudio
description: Working on Claudio, the animated macOS desktop notifier for Claude Code in this repo (orange mascot banner with a speech bubble and held props, driven by Claude Code hooks). Use for any change to its look, animation, props, bubble text, hook behavior, install/uninstall, or when debugging why the banner did or did not show.
---

# Claudio

Claudio is a borderless AppKit window drawn entirely with Core Graphics, launched by Claude Code hooks. There are no image assets: every shape is code.

## Layout of the repo

- `src/Config.swift`: argument parsing (positional `<done|ask> <phrase-file>` from the scripts, plus `MODE=` / `ITEM=` / `TEXT=` for running it by hand), the canned lines, mode (`done` | `ask`), `lifetime` (300s), `slideTime` (0.45s), `uiScale` (0.85), the 440×150 `design` size, core colors, `confettiColors`, `animSpeed` (paces the continuous jump/wave/mouth loop), `dozeStart`/`dozeSpan` (the sleepy ramp, shrunk by `CLAUDIO_SLEEP_TEST`).
- `src/main.swift`: window setup (top right, under the menu bar, `.popUpMenu` level, all Spaces), `SIGUSR1` = dismiss, the global key-press monitor (`view.keyMonitor`, feeds "getting sleepy"), 60fps timer.
- `src/MascotView.swift`: the class itself — stored state (phrase, held item, each animation's `...At` timestamp), `tick()` (slide, fade, phrase polling, exit), clicks, stacking. Split from drawing on 2026-10-01 because extensions can't add stored properties, only methods — so state had to stay here regardless.
- `src/Bubble.swift`: `extension MascotView` with `drawBubble` only.
- `src/Mascot.swift`: `extension MascotView` with `drawMascot` and all the mascot's animation math.
- `src/Props.swift`: `extension MascotView` with `drawCrown` / `drawAccessory` / `drawItem`, the prop colors, the prop lists, `pickItem()`, and the `accessory` selection (rare, like the crown).
- `src/Drawing.swift`: `block`, `disc`, `poly`, `star`, `sparkle`, `smooth`.
- `scripts/`: `notify.sh` (launcher), `stop-hook.sh`, `dismiss.sh`, `phrase.sh` (bubble text via Haiku), `common.sh` (sourced by all: extends `PATH`, `find_claude`, `log`).
- `install.sh` builds into `build/`, copies the binary and scripts flat into `~/.claude/claudio/`, and merges hooks into `~/.claude/settings.json` with jq (idempotent; it strips any entry whose command contains `/.claude/claudio/` or the legacy `/.claude/eyes/`).

## Dev loop

1. Edit `src/` or `scripts/`.
2. `make build` to compile-check (`swiftc -O src/*.swift -o build/claudio`).
3. `make preview ITEM=<prop> MODE=<done|ask>` to show it from the repo build (`ITEM` = prop, `MODE` = mood; a prop name passed as `MODE` is treated as `ITEM`; `make props` lists the names). `CLAUDIO_ITEM=<name>` forces a prop, and `CLAUDIO_ITEM=crown` forces the crown. `CLAUDIO_ACCESSORY=sunglasses|partyhat|nose` forces an accessory (separate from `ITEM=`/`CLAUDIO_ITEM`, since accessories aren't held props and don't belong in that validation). `CLAUDIO_SLEEP_TEST=1` shrinks "getting sleepy"'s timing to seconds instead of minutes.
4. `./install.sh` so the live hooks use the change (`--no-check` skips the ~5s Haiku test call at the end). A visible change only reaches already-open sessions through the installed copy.
5. Debug log: `touch ~/.claude/claudio/debug`, then read `~/.claude/claudio/claudio.log` (`rm` the flag to stop). `env -i HOME="$HOME" USER="$USER" TMPDIR="$TMPDIR" PATH=/usr/bin:/bin:/usr/sbin:/sbin sh ~/.claude/claudio/stop-hook.sh` with a JSON payload on stdin simulates a hook started from a Dock app. Without `USER`, `claude` reports "Not logged in".
6. To check that a banner is running: `pgrep -x claudio`. To dismiss it: `~/.claude/claudio/dismiss.sh`.

**The banner cannot be seen from inside a Claude session**: `screencapture` fails ("could not create image from display"). Verify with compile + launch + `pgrep`, then ask the user to look or to send a screenshot. Never claim something looks right without that.

A quick way to show the user several variants in a row: write a caption to a file and launch `CLAUDIO_ITEM=<name> nohup build/claudio done <file> &`, then `sleep 5` between `pkill -x claudio` calls. A banner without a session id (manual launches, `make preview`) is not dismissed by hooks any more, only by a click or `dismiss.sh < /dev/null`.

## Coordinate systems (important when drawing)

- **View**: 440×150 design units, scaled by `uiScale`. AppKit's origin is bottom-left (y up).
- **Bubble**: `x = 158` to `design.width - 12`, `y = 16`, height 78, light gray (`white: 0.92`), no border, black regular-weight text, **left-aligned**, centered vertically. The font steps down from 18 to 11 until the text fits. The tail sits near the top-left corner (18–38 below the top edge). A 26pt close circle (`closeRect`, shared with the click check) sits centered on the top edge near the top-right corner. A click on it only dismisses; a click anywhere else runs `focus.sh` (path in `CLAUDIO_FOCUS`) and dismisses.
- **Bubble scale (`pop` in `drawBubble`)**: an appear/swap pop (unchanged) times a small continuous swell, `1 + 0.025 * shout`, using the same `shout` formula as the mouth in `drawMascot` (not passed in; recomputed from `t`, since both are pure functions of it). Scales from `(bubble.minX, bubble.midY)`, i.e. the tail-side edge, so the tail stays put. Only the bubble shape, tail and close circle are inside that transform; the text is drawn after `ctx.restoreGState()`, at a fixed size and position, so words never stretch or jitter. User's call, 2026-10-01: "in time with the mouth".
- **Mascot**: drawn in its original 420-wide space (`cx = 210`), then translated to x=70, y=−8 and scaled 0.38. Body block `cx±100`, y 85–235. Legs at y 40. The right hand block is at `(cx+100, 165 − wave, 40×36)`; its center `(cx+120, 183 − wave)` is `hx, hy` in `drawItem`.
- **Props**: draw upward from `hy`. Keep them within about x ≤ 440 and y ≤ hy+156 in mascot units, or they run into the bubble or off the top of the window. The hand is redrawn after the prop so the prop looks gripped. A crowned mascot draws no prop (`drawCrown` then `return`).

## Idle mascot animations (2026-10-01)

Random one-off moves layered on top of the always-on jump/wave/mouth loop, so the mascot doesn't look dead still between those cycles. Each gets its own `var ...At` timestamp (declared in MascotView.swift, initialized with `Double.random`) plus a fixed duration constant; `drawMascot` computes a 0–1 progress from `t - xAt` each frame (no stored "is it playing" flag) and reschedules `xAt = t + Double.random(in: ...)` once `t - xAt` passes the duration, regardless of mood or other gating — only whether it's *drawn* is gated, so the schedule never drifts out of phase with real time. This keeps each animation a pure function of `t`, like `shout`, with no separate timer or state machine. `energy`/`drowsy` (from "getting sleepy", below) and `inFlip` (from backflip) are the shared gates several of these read.

- **Blink**: `blinkAt` / `blinkDuration` (0.12s). `1 - 0.92 * sin(p * π)`, eye height only, squashing from the vertical center. Reschedules 2–6s out.
- **Legs**: not reschedule-based, just a steady swing sharing the arms' `wave` (half amplitude), outer two legs only, opposite phase; inner two stay planted.
- **Backflip**: `backflipAt` / `backflipDuration` (0.55s). Extra hop (`sin(p * π) * 70`) plus one full turn (`ctx.rotate(by: p * 2 * .pi)`) around pivot `(cx, 140)`. Reschedules 18–35s out. Done mood only, not while mostly asleep (`!isAsk && !drowsy`); exposes `inFlip` so twirl and prop toss skip it.
- **Twirl**: `twirlAt` / `twirlDuration` (0.4s). Squashes horizontally only, `sx = 1 - 0.85 * sin(p * π)`, anchored at `x = cx` (no mirroring needed). Reschedules 15–28s out. Guarded by `!inFlip && !drowsy`. Both moods.
- **Prop toss**: `tossAt` / `tossDuration` (0.7s). The held item lifts (`sin(p * π) * 90`) and spins twice (`p * 4 * .pi`) out of the hand and back. Reschedules 14–26s out. Guarded by `!inFlip && !drowsy`, and by `k >= 1` (the item's own pop-in finished) so a just-swapped item never launches mid-pop.
- **Getting sleepy**: see its own section below — large enough to warrant one.
- **Confetti**: `confettiAt` / a 1.1s burst, independent of `itemAt` (which only tracks pop-in/swap timing) so it works whether trophy/popper is the initial random pick or a later Haiku swap. 14 pieces, deterministic "golden angle" (`idx * 2.399963`) per piece so no per-particle state is stored, launched from the held item's position with gravity (`vy*p - 300*p*p`) and fading out. Reschedules every 2–3s (gap, not full period) for as long as the item is `"trophy"` or `"popper"`. Guarded by `!drowsy`.
- **Rain cloud**: continuous, not reschedule-based — drawn every frame the item is `"extinguisher"`, fixed above the head regardless of sink/droop (a persistent mood, not tied to sleepiness). A small puff cluster plus 3 looping raindrops (period 0.9s).
- **Knock on the bubble**: `knockAt` / `knockDuration` (0.6s), ask mood only (`isAsk && !drowsy`). Two narrow pulses at `kp≈0.2` and `kp≈0.6` (`max(0, 1 - abs((kp-x)/0.12))`) lift the *right* arm (`knockLift`, also applied to the held item's `hx,hy` so it doesn't look detached) — reschedules 6–10s out. Bubble.swift recomputes the same `sinceKnock`/pulses independently (reading `knockAt`/`knockDuration` off the shared MascotView instance, same pattern as `shout`) to jiggle the bubble (`ctx.rotate(by: jiggle)`) in sync, even though arm and bubble are drawn in completely different coordinate systems — the shared clock is what sells the illusion of contact.
- **Head scratch**: `scratchAt` / `scratchDuration` (1.0s), ask mood only (`isAsk && !drowsy`). Uses the *left* arm (knock already uses the right), a rise-hold-fall envelope (`min(min(sp, 1-sp)/0.25, 1)`) lifting it and adding a quick side-to-side wobble (`sin(sinceScratch*30)`). Reschedules 7–11s out. It originally also popped up a "?" above the head; removed — too small to read and the user didn't like it once they could see it. `scratchEnvelope` is still there for the arm motion alone.
- **Rare accessories**: `accessory: String?` (Props.swift, alongside `crowned`) — `"sunglasses"`, `"partyhat"` or `"nose"`, picked with the same ~1/50 odds as the crown and mutually exclusive with it (`guard !crowned, forced == nil`). Unlike the crown, worn *alongside* whatever's held — `drawAccessory(cx, headDroop)` is called right after the eyes, inside the same sink-transformed block, so it sinks/droops with the head like they do. `CLAUDIO_ACCESSORY=<name>` forces one, independent of the `ITEM=`/`CLAUDIO_ITEM` prop system. A `"headphones"` design (band + ear cups) was tried and rejected by the user ("super ugly") without changes requested beyond removal; replaced with `"nose"`, a big (34×54) Groucho-Marx-style pink square with a lighter top strip and a bigger darker bottom strip for shading — went through three size/shade iterations before landing here.
- **Animation pacing**: `animSpeed` (Config.swift, 0.75) scales only the continuous jump/wave/mouth loop via `let animT = t * animSpeed` in `drawMascot` — every scheduled one-off above stays on raw `t`, so pacing the "how fast it looks like it's moving" feel never desyncs any of their timers. Bubble.swift's own `shout` recomputation also uses `t * animSpeed`, or its mouth-sync pulse would drift out of time with the now-paced mouth. Ask mode is still faster than done (wave frequency 14 vs 9, bigger shake amplitude) — that stayed intentional; `animSpeed` just scaled both down together after the user noticed ask felt too frantic.

### Getting sleepy

The mascot dozes off after a while with no activity, then wakes with a startled jump. Gated out entirely in ask mode (`sleepiness` forced to `0` when `isAsk`) — a banner asking for input shouldn't fall asleep waiting for it.

- **Idle detection is movement-based, not proximity-based** — this was a real bug, not just a tuning issue. The first version reset the idle clock whenever the cursor was merely *within 220pt* of the banner; a user whose cursor simply rested nearby (not moving) kept resetting it every single frame forever, so it could never doze off. Confirmed with a standalone debug build logging `d`/`idleFor` before and after the fix. Now `lastMousePos: NSPoint?` tracks the previous frame's cursor position, and only an actual jump (`hypot(...) > 2`) counts as activity (`lastActivityAt = t`).
- **Keyboard presses count too**: `view.keyMonitor` in main.swift is a global monitor (`NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged])`) calling `view.noteActivity()`. Needs the macOS **Input Monitoring** permission — confirmed with a real test (simulated keystroke via `osascript ... key code`) that it silently does nothing without it; no crash, just no reset. Only the fact that a key was pressed is read, never which key.
- **The ramp**: `idleFor = t - lastActivityAt`; `sleepiness = min(1, max(0, (idleFor - dozeStart) / dozeSpan))`, `dozeStart`/`dozeSpan` = 45/15s normally, 3/5s under `CLAUDIO_SLEEP_TEST` (set by hand for previewing — never by the hooks). `energy = 1 - 0.7 * sleepiness` dampens the jump/wave/mouth/shout-lines amplitude and frequency as it gets sleepier.
- **The body slumps down over the legs**: `sink = sleepiness * 50`, a `ctx.translateBy(0, -sink)` wrapping arms/body/eyes/mouth/accessory/Zzz (legs are drawn *before* this block so they stay planted and get covered from the top, leaving a sliver showing). Arms droop further still (`armDroop = sleepiness * 45`, on top of `sink`) — going slack rather than staying at shoulder height. (A duplicate of the right arm is redrawn after the held item, outside the sink block for its own reasons — see the item note below; it must manually match `armDroop`'s current value or the two draws desync, which happened once already when `armDroop` was bumped from 30 to 45 and this second site wasn't updated.)
- **Eyes**: `eyeOpen = (1 - 0.7 * sleepiness) * (1 + 0.3 * startled)` — stays a visible ~30%-height bar when "closed" rather than vanishing to a hairline (the user explicitly wanted them to read as thick, not gone), and `eyeWidth = 22 + 10 * sleepiness` widens them, both reading as "shut". `headDroop = sleepiness * 45` pushes eyes/mouth down further within the sunk body, like the chin tucking toward the chest.
- **Mouth**: first sags down (`mouthDrop`, ramps over the first 30% of sleepiness) *without* fading, then only once fully down does it fade out via alpha (`mouthVisible`, over the next 15%) — explicitly requested as two separate stages, not shrink-and-fade together like the eyes.
- **The held item slips out of the hand and settles on the ground**: lerps continuously from the hand's current (sunk) position to `(cx+40, 46)` as `sleepiness` goes 0→1, tipping to `-5π/12` (not fully flat — a full 90° clipped against something on an earlier pass).
- **Snot bubble**: only once `sleepiness >= 0.999` (the whole doze-off transition must finish first — an explicit user requirement, not just "mostly asleep"), inflating from the mouth on a 2.2s loop then popping, `NSGradient` radial shading for a glossy look, with a small highlight dot. Went through several size passes (doubled, then enlarged again) before landing at its current scale.
- **"Zzz"**: same `sleepiness >= 0.999` gate. Three letters in `bubbleColor` (matching the speech bubble, not `ink`), each swaying side to side (`sin(t*1.3 + i*2.1) * 14` — explicitly a horizontal "dreamy" drift, not a rise) while fading in and out on its own loop, positioned to overlap the forehead (not drift off above the head into empty space, which was the first, wrong attempt) and sized up (34–54pt font) to actually read at the banner's small final render scale — a mistake repeated more than once this session (also hit with the snot bubble and the rain cloud/confetti) is forgetting that shapes sized for "looks right in the code" end up tiny once the full transform chain (`uiScale * 0.38`) is applied; always ask the user to check real size, don't assume.
- **Waking**: `wokeAt` is set the instant `prevSleepiness` crosses from `> 0.5` to `< 0.5` (i.e. real reawakening, not every frame), driving `startled` (a 0.3s decaying jump + wide-eyed snap via the `eyeOpen`/jump formulas above).

## Adding a prop

1. Add a `case "<name>":` in `drawItem` (Props.swift), drawn relative to `hx, hy` with the helpers. Animate with `t`, and use `shout` for anything that should pulse with the mouth.
2. Add the name to `randomDone` or `randomAsk` (random pool), or only to `doneItems` / `askItems` (Haiku-only props, like `wrench` and `extinguisher`).
3. If Haiku should be able to pick it, add it, with a one-line "when", to the `props=` list for that mood in `scripts/phrase.sh`. A name Haiku returns that is not in the mood's list is ignored by the app.
4. `make preview ITEM=<name>`, then `./install.sh`.

## Hook facts (verified from real payloads)

- **Stop payload** includes `last_assistant_message` and `background_tasks: [{id, type, status, description, command}]`. A turn that ends only to wait for a background task has a `"running"` entry, and `stop-hook.sh` skips the banner then. `session_crons` also exists; it is untested whether it covers ScheduleWakeup-style waits.
- The **Notification** banner reads `.message` from its payload. That field name has not been verified from a captured payload.
- `UserPromptSubmit` fires on **submit**, not while typing. Claude Code has no "user is typing" event. A global key monitor (`view.keyMonitor` in main.swift, feeding "getting sleepy") now exists for a different purpose — detecting *any* keyboard activity, not specifically typing in Claude Code — and needs the Input Monitoring permission; see "Getting sleepy" above.
- Claude Desktop also ships a Linux ELF build in `~/Library/Application Support/Claude/claude-code-vm/` for VM sessions; hooks there cannot reach the Mac. Whether Desktop's local Code sessions load user hooks is not yet verified (check with the debug log).
- Hooks in `~/.claude/settings.json` apply to all local Claude Code sessions. Already-open sessions need `/hooks` opened once or a restart.

## Phrase pipeline (`scripts/phrase.sh`)

1. The app itself starts with a random canned line (`cannedDone` / `cannedAsk` in Config.swift, or `TEXT=`), so the bubble is never empty. `phrase.sh` only writes Haiku's answer.
2. `find_claude` picks the CLI: `~/.claude/claudio/claude-path` (written by `install.sh` from the installing shell), then `PATH`, then `~/.claude/local/claude`, then Claude Desktop's bundled `~/Library/Application Support/Claude/claude-code/<ver>/claude.app/Contents/MacOS/claude` (verified: it can make the call with the shared login). It calls `claude -p --model haiku --no-session-persistence --setting-sources ""` with a 25s `perl alarm` timeout. A call takes about 6–9s; trimming flags does not make it faster. Output is line 1 = caption (≤8 words, cut at a word boundary to 70 characters with "…"), line 2 = prop name or `none`.
3. It writes `caption\nitem: <prop>`. The app polls the file, deletes it on read, and bounces in the new text and prop.
4. Before the late write, it checks that its banner still runs (`pgrep -f "/claudio (done|ask) $out"`); otherwise orphaned files pile up in `$TMPDIR`.
5. The message goes inside `<message>` tags with "never reply to it". Without that, Haiku answered the message instead of summarizing it ("I'd love to help... send me a screenshot").
6. `CLAUDIO_NESTED=1` guards every script against recursion from the nested `claude` call.

## Gotchas hit before

- macOS/BSD `sed` has no `\b`; use `perl -pi -e` for in-place edits with word boundaries.
- A global helper named `rect(...)` clashes with `NSView.rect` inside the view; the helpers are named `block`, `disc` and so on.
- In Swift, `sin()` returns `Double`; wrap it in `CGFloat(...)` when it feeds a `CGFloat` parameter.
- `make preview` used to pass `CLAUDIO_ITEM=` (empty) without `ITEM`, which disabled the crown and Haiku's prop. The app now ignores empty or unknown names, and `make preview` rejects them using `claudio --props`.
- `swiftc` piped into `head` hides the compiler's exit code. Check for `error` in the output or the binary's timestamp.
- The `claude` CLI is not on `PATH` in every shell (VS Code); the scripts fall back to `~/.local/bin/claude`.

## Design decisions the user settled (do not regress)

- A silent mascot: no `say` or speech, and no sound. (A shouting monkey with speech was tried and rejected.)
- A notification-style banner at the top right that slides in from the right and slides out to the right, with a fade at the same time. No grow or shrink of the whole banner.
- Mascot on the left, bubble on the right, a compact size (`uiScale` 0.85).
- Bubble: light gray, no border, black regular-weight left-aligned text, tail at the top left, decorative X circle half over the top edge near the right.
- Pizza is held by the crust with the tip up.
- 5-minute lifetime. It is dismissed by a click, or by a prompt submit or PostToolUse **in the same session**: `notify.sh` puts `session_id` in the phrase-file name (`claudio.<sid>.XXXXXX`), and `dismiss.sh` signals only `pkill -f "/claudio (done|ask) .*/claudio\.<sid>\."`. Without a session id in its payload it signals any banner.
- Click = jump to the finished session and close; click on the X = close only (2026-10-01).
- Several sessions: banners stack one under the other, oldest on top, and the rest glide up when one closes (user's choice, 2026-10-01). `notify.sh` replaces only the same session's banner (`pkill -f` on `claudio.<sid>.`), or the previous session-less one (`claudio.XXXXXX$`) for previews.

## File split (2026-10-01)

Three files instead of one ~300-line one, matching the existing `Type+Concern.swift` idiom `Props.swift` already used (an `extension MascotView` per concern). Reasoned through with the user: Swift extensions share one namespace with no access-control benefit within a single target/`swiftc` compile, so splitting is for navigation only — a file per *concern* (bubble vs. mascot), not a file per animation or per prop, which would be real-Swift-project-sized machinery (a `Prop` protocol + registry, a struct per animation) for a project this size (~850 lines, no Xcode project, no package manager). Props.swift stays a single switch unless it gets unwieldy. No behavior changed; verified by rebuilding and relaunching the banner.

## Stacking (`updateSlot` in MascotView.swift)

- Every 0.25s a banner lists on-screen windows (`CGWindowListCopyWindowInfo`, no permission needed for owner and bounds) owned by processes with its own name, and counts those with a lower pid: that count is its slot. No shared files, and two banners starting together cannot pick the same slot.
- `slotY` eases toward `slot * (height + 8)` each frame (factor 0.15); a new banner starts directly in its slot. Slots are capped at what fits on the screen; extra banners overlap in the last one.
- Verified with three fake sessions: tops at 42 / 178 / 314 (136 = 127.5 + 8 apart), replace-own goes to the bottom, the others glide up after a dismiss.

## Jump to session (`scripts/focus.sh`)

- `notify.sh` exports `CLAUDIO_FOCUS_APP` (`$__CFBundleIdentifier`, which macOS sets for apps and the hooks inherit: `com.microsoft.VSCode` from the VS Code extension), `CLAUDIO_FOCUS_DIR` (payload `.cwd`) and `CLAUDIO_FOCUS_TTY` (the first ancestor process with a tty: the claude CLI; none in VS Code's panel).
- VS Code: the user's windows are opened from `.code-workspace` files, so opening the session folder could open a new window. `code_window` reads `~/Library/Application Support/Code/User/globalStorage/storage.json` (`windowsState`) and opens the folder or workspace file whose folder is the deepest one containing the session; no match = just activate the app. Verified by the user on 2026-10-01: a real click on the banner brought the VS Code window back.
- Terminal.app / iTerm2: AppleScript selects the tab by tty (macOS asks for Automation permission once). Not yet tested by the user; the iTerm2 script is untested (iTerm is not installed here).
- Desktop: `claude://code/continue?session=last` (a link from Desktop's own quick actions). Whether `session=<id>` works is unknown.
- Don't name a shell variable `path` when testing these functions from zsh: zsh ties it to `PATH`.
