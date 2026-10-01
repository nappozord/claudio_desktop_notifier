# Claudio

A small animated desktop notifier for [Claude Code](https://claude.com/claude-code) on macOS.

When Claude finishes a task or needs input, a banner slides in at the top right of the screen, like a macOS notification. A little orange mascot shouts silently, holds a random prop, and a speech bubble says what happened ("All 24 tests pass!", "Need your OK for Bash!").

- **Done** (Claude finished): the mascot jumps happily and holds something celebratory.
- **Ask** (Claude needs input or permission): the mascot shakes and holds something attention-grabbing.
- **Dismissed** when the user clicks it, sends a new prompt, or Claude resumes working; otherwise after 5 minutes.
- **Quiet while waiting**: no banner when Claude only pauses for a timer or a background task.

## Requirements

- macOS
- Xcode Command Line Tools (`swiftc`): `xcode-select --install`
- `jq`: `brew install jq`
- Claude Code; the `claude` CLI on `PATH` or at `~/.local/bin/claude` for task-specific bubble lines (optional: without it, Claudio uses canned lines)

## Install

```sh
./install.sh        # or: make install
```

This builds the app, copies it to `~/.claude/claudio/`, and registers four hooks in `~/.claude/settings.json`, keeping every other setting (a backup is written to `settings.json.claudio-backup`). Re-running it is safe; it replaces its own entries.

Already-open Claude Code sessions pick up the hooks after `/hooks` is opened once, or after a restart. The hooks apply to every local Claude Code session: CLI, VS Code extension, and the desktop app's Code tab.

To remove everything:

```sh
./uninstall.sh      # or: make uninstall
```

## Preview

```sh
make preview                      # random prop, "done" mood
make preview MODE=ask             # "ask" mood
make preview ITEM=pizza           # a specific prop
make preview ITEM=crown           # the rare crown
```

`make preview` runs the repo build, not the installed copy.

## How it works

| Hook | Script | Effect |
|---|---|---|
| `Stop` | `stop-hook.sh` | Shows the **done** banner, unless the payload lists a running background task |
| `Notification` | `notify.sh ask` | Shows the **ask** banner |
| `UserPromptSubmit` | `dismiss.sh` | Slides the banner away |
| `PostToolUse` | `dismiss.sh` | Slides the banner away once Claude resumes working |

1. `notify.sh` starts the `claudio` app and, in parallel, `phrase.sh`.
2. `phrase.sh` writes a random canned line right away, so the bubble is never empty.
3. It then asks Claude Haiku (`claude -p --model haiku`) to turn the first 1,500 characters of Claude's last message, or the notification text, into a short line. When one clearly fits, Haiku also picks a prop: trophy for passing tests, wrench for a fix, fire extinguisher for a failure, and so on. The app swaps the text and the prop in with a bounce when the answer arrives, usually 6 to 9 seconds later.
4. `dismiss.sh` sends `SIGUSR1`, and the app slides and fades out.

The Haiku call runs with `CLAUDIO_NESTED=1` and no user settings, so it never triggers the hooks again.

**Privacy and cost:** each banner sends Claude's last message (truncated) to Claude Haiku through the local Claude Code login. That is one small API call per banner.

## Props

| Mood | Random props |
|---|---|
| Done | ice cream, magic wand, balloon, trophy, party popper, flag, coffee, pizza, donut, sword, potion, umbrella, fish |
| Ask | megaphone, bell, flashlight, "?" sign, pencil |

- **Seasonal:** pumpkin in October, tree in December, flower from March to May. The seasonal prop shows up about 1 time in 4.
- **Time of day:** a candle after 10pm, more coffee from 6 to 10am.
- **Task-related only:** wrench and fire extinguisher (Haiku can also pick pencil for a done task).
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
install.sh  uninstall.sh  Makefile
```

Tweakable values: `lifetime`, `slideTime` and `uiScale` in `src/Config.swift`. After any change, run `./install.sh` again to rebuild and reinstall.
