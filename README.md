# Claudio

A small animated desktop notifier for [Claude Code](https://claude.com/claude-code) on macOS.

When Claude finishes a task or needs input, a banner slides in at the top right of the screen, like a macOS notification. A little orange mascot shouts silently, holds a random prop, and a speech bubble says what happened ("All 24 tests pass!", "Need your OK for Bash!").

- **Done** (Claude finished): the mascot jumps happily and holds something celebratory.
- **Ask** (Claude needs input or permission): the mascot shakes and holds something attention-grabbing.
- **Dismissed** when the user clicks it, sends a new prompt, or Claude resumes working; otherwise after 5 minutes.
- **Quiet while waiting**: no banner when Claude only pauses for a timer or a background task.

**Claude Code only.** Claudio is started by Claude Code hooks, so it works wherever Claude Code runs on your Mac: the `claude` CLI, the VS Code and JetBrains extensions, and the **Code** tab of Claude Desktop. It does not work with regular Claude chat (in Claude Desktop, on claude.ai or on the phone), which has no hooks. See [Claude Desktop](#claude-desktop) for VM and cloud sessions.

## Requirements

- macOS
- Xcode Command Line Tools (`swiftc`): `xcode-select --install` (Homebrew already needs them)
- `jq`: built into macOS 15 and later; on older versions, `brew install jq`
- Claude Code, logged in, for task-specific bubble lines (optional: without it, Claudio uses canned lines). See [Haiku captions](#haiku-captions) for where Claudio looks for it.

## Install

### With Homebrew

```sh
brew install nappozord/tap/claudio
claudio-setup
```

`brew install` builds Claudio and installs it. Homebrew does not let a formula edit your home folder, so `claudio-setup` is the one extra step: it registers four hooks in `~/.claude/settings.json`, keeping every other setting (a backup is written to `settings.json.claudio-backup`). Run it once; `brew upgrade` needs no re-run.

To remove it:

```sh
claudio-uninstall
brew uninstall claudio
```

### From the repo

```sh
./install.sh        # or: make install
```

This builds the app, copies it to `~/.claude/claudio/`, and registers the same four hooks. Re-running it is safe; it replaces its own entries, including the Homebrew ones (and `claudio-setup` replaces the repo ones). To remove it: `./uninstall.sh` (or `make uninstall`).

### Both ways

- Setup ends with one test call to Haiku and prints `Haiku captions: on (...)` or `off: <reason>`. `--no-check` skips that call.
- Already-open Claude Code sessions pick up the hooks after `/hooks` is opened once, or after a restart. The hooks apply to every local Claude Code session: CLI, VS Code extension, and the desktop app's Code tab.

## Preview

Two settings: **`ITEM` picks the prop**, and **`MODE` picks the mood** (`done` or `ask`).

```sh
make preview ITEM=pizza                 # a specific prop
make preview ITEM=crown                 # the rare crown
make preview ITEM=bell MODE=ask         # a prop in the "ask" mood
make preview                            # random prop, "done" mood
make preview MODE=ask                   # random prop, "ask" mood
make preview TEXT="All 24 tests pass"   # a fake message, sent through Haiku like a real one
make props                              # every name ITEM accepts
```

- **`ITEM`** takes the internal names listed by `make props` (`icecream`, `popper`, `sign`...), not the names in the [Props](#props) table. `make preview` stops and lists the valid names if one is unknown.
- **`MODE`** only changes how the mascot moves and which props it picks at random. A prop name given as `MODE` (`make preview MODE=crown`) is shown as if it were `ITEM`.
- **`TEXT`**: without it, the bubble shows a canned line. With it, Haiku writes the line and may swap in a task-related prop a few seconds later, unless `ITEM` forces one.

`make preview` runs the repo build, not the installed copy.

### Running the app directly

The `claudio` app also takes these settings as arguments, which is handy with the Homebrew install (no repo needed). It shows a canned line, or your `TEXT`, and stays until clicked or for 5 minutes:

```sh
claudio ITEM=crown
claudio ITEM=bell MODE=ask
claudio TEXT="Hello there" ITEM=pizza
claudio --props                         # every name ITEM accepts
claudio --help
```

Run this way, Haiku is not involved: that part lives in the hook scripts.

## How it works

| Hook | Script | Effect |
|---|---|---|
| `Stop` | `stop-hook.sh` | Shows the **done** banner, unless the payload lists a running background task |
| `Notification` | `notify.sh ask` | Shows the **ask** banner |
| `UserPromptSubmit` | `dismiss.sh` | Slides the banner away |
| `PostToolUse` | `dismiss.sh` | Slides the banner away once Claude resumes working |

1. `notify.sh` starts the `claudio` app and, in parallel, `phrase.sh`.
2. The app starts with a random canned line, so the bubble is never empty.
3. It then asks Claude Haiku (`claude -p --model haiku`) to turn the first 1,500 characters of Claude's last message, or the notification text, into a short line. When one clearly fits, Haiku also picks a prop: trophy for passing tests, wrench for a fix, fire extinguisher for a failure, and so on. The app swaps the text and the prop in with a bounce when the answer arrives, usually 6 to 9 seconds later.
4. `dismiss.sh` sends `SIGUSR1`, and the app slides and fades out.

The Haiku call runs with `CLAUDIO_NESTED=1` and no user settings, so it never triggers the hooks again.

**Privacy and cost:** each banner sends Claude's last message (truncated) to Claude Haiku through the local Claude Code login. That is one small API call per banner.

## Haiku captions

`phrase.sh` uses the first `claude` it finds, in this order:

1. The path `install.sh` found in your terminal, saved in `~/.claude/claudio/claude-path`. Hooks can run with a shorter `PATH` than your terminal (apps opened from the Dock get only `/usr/bin:/bin:/usr/sbin:/sbin`), so this matters for npm and nvm installs.
2. `PATH`, with `/opt/homebrew/bin`, `/usr/local/bin` and `~/.local/bin` added.
3. `~/.claude/local/claude` (older npm-local installs).
4. The copy bundled with Claude Desktop (`~/Library/Application Support/Claude/claude-code/<version>/claude.app`), for people who only use Desktop.

The call uses that copy's login. It skips your settings files (`--setting-sources ""`), so an `apiKeyHelper` or provider set only in `settings.json` does not reach it; environment variables do.

## Troubleshooting

Turn on the debug log, reproduce the problem, then read the log:

```sh
touch ~/.claude/claudio/debug        # on
cat ~/.claude/claudio/claudio.log
rm ~/.claude/claudio/debug           # off
```

Each banner logs its mode, how much message text it got, the `PATH` and `jq` the hook saw, then the Haiku result: the caption and prop, a timeout, or the CLI's error (for example `Not logged in`).

- **No lines at all after a Claude turn:** the hooks did not run on this Mac. Open `/hooks` once or restart the session; in Claude Desktop, see below.
- **`no message text`:** the hook payload had no text, so the bubble keeps a canned line.
- **`haiku failed ... Not logged in`:** log in with that `claude` once (`claude`, then `/login`).

### Claude Desktop

Claudio runs from the Claude Code hooks in `~/.claude/settings.json`, so it can only work where Claude Code runs **on this Mac**:

- Regular chat in Claude Desktop is not Claude Code and has no hooks. Use the **Code** tab.
- Claude Desktop can also run Claude Code in a Linux VM (it ships a Linux build for that). A hook running there cannot open a window on the Mac, and does not read the Mac's `~/.claude/settings.json`.
- Cloud and SSH sessions run on another machine for the same reason.

For a local Code session in Desktop, turn on the debug log and send one prompt: no log line means Desktop did not run the hooks for that session.

## Props

| Mood | Random props (name for `ITEM`) |
|---|---|
| Done | ice cream (`icecream`), magic wand (`wand`), balloon, trophy, party popper (`popper`), flag, coffee, pizza, donut, sword, potion, umbrella, fish |
| Ask | megaphone, bell, flashlight, "?" sign (`sign`), pencil |

- **Seasonal:** pumpkin in October, tree in December, flower from March to May. The seasonal prop shows up about 1 time in 4.
- **Time of day:** a candle after 10pm, more coffee from 6 to 10am.
- **Seasonal and time-of-day names:** `pumpkin`, `tree`, `flower`, `candle`.
- **Task-related only:** wrench and fire extinguisher (`extinguisher`); Haiku can also pick pencil for a done task.
- **Rare:** about 1 banner in 50 wears a crown and holds nothing.

## Project layout

```
src/
  Config.swift      mode, timings, scale, core colors
  main.swift        window, dismiss signal, run loop
  MascotView.swift  slide/fade, speech bubble, mascot body
  Props.swift       held objects, colors, and how one is picked
  Drawing.swift     shape helpers
scripts/
  notify.sh  stop-hook.sh  dismiss.sh  phrase.sh
  common.sh  PATH, claude lookup, debug log (sourced by the others)
install.sh  uninstall.sh  Makefile
```

Tweakable values: `lifetime`, `slideTime` and `uiScale` in `src/Config.swift`. After any change, run `./install.sh` again to rebuild and reinstall.
