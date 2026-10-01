---
name: claudio-release
description: Publishing a new Claudio version to Homebrew (nappozord/tap/claudio) - building the release tarball, tagging, the GitHub release, and bumping url/sha256/version in the homebrew-tap formula. Use when the user wants to release, publish, ship or bump Claudio, update the Homebrew formula or tap, or asks why brew upgrade does not pick up a new version.
---

# Releasing Claudio to Homebrew

The procedure is in `RELEASING.md` at the repo root. Read it first and follow its steps and commands; this file only adds how to run them with this user.

## Working with the user

- **One step at a time.** Do one step of `RELEASING.md`, report what it produced (file, hash, diff), name the next step, and stop. Do not chain steps.
- **The user runs the outward steps themselves**: `git push`, `git tag` + push, creating the GitHub release, pushing the tap. Give the exact commands and wait. Run them only when the user asks you to in that turn.
- When the user says they did a step, **verify it before moving on**:
  - tag: `git ls-remote --tags origin`
  - release asset: download it and compare `shasum -a 256` with the local tarball
  - tap: `git -C ../homebrew-tap log --oneline -1` and `git status -sb`

## Facts about this setup

- The tap is checked out at `~/Desktop/repos/homebrew-tap` (remote `nappozord/homebrew-tap`), and Homebrew also has its own clone at `$(brew --repository nappozord/tap)`. Edit the first one, not Homebrew's clone.
- `gh` is not installed. The user creates releases on github.com unless they install it.
- Release asset name: `claudio-v<version>-macos-arm64.tar.gz`, containing only `claudio` at the top level (`tar -czf ... -C build claudio`).
- Build from a clean, pushed tree (`git status -sb` shows `## main...origin/main` and nothing else), and never rebuild after hashing: the checksum must match the uploaded file.
- `releases/latest` URLs cannot replace the version bump: `brew upgrade` compares `version`, and `sha256` pins one file.
- The formula installs only the binary. The hooks run `~/.claude/claudio/` (put there by `./install.sh`), so a brew upgrade alone does not update what users see. A formula that builds from source and ships the scripts with a `claudio-setup` command was proposed but not adopted. Raise it again only if the user asks.
