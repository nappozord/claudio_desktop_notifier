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
  - formula checksum: `curl -sSLf <formula url> | shasum -a 256` matches the formula's `sha256`
  - tap: `git -C ../homebrew-tap log --oneline -1` and `git status -sb`

## Facts about this setup

- The tap is checked out at `~/Desktop/repos/homebrew-tap` (remote `nappozord/homebrew-tap`), and Homebrew also has its own clone at `$(brew --repository nappozord/tap)`. Edit the first one, not Homebrew's clone.
- `gh` is not installed. Releases with notes are optional and done on github.com.
- Since 1.2.0 the formula builds from the tag's source archive (`archive/refs/tags/v<version>.tar.gz`): no tarball is built or uploaded, and the version comes from the url. Up to 1.1.0 it installed a prebuilt arm64 binary attached to the release.
- The checksum is of GitHub's archive, so it can only be computed after the tag is pushed (`curl -sSLf <url> | shasum -a 256`). Do not compute it from a local archive.
- Tag only a clean, pushed `main` that passes `make build`: the tag is what Homebrew compiles.
- `releases/latest` URLs cannot replace the bump: `brew upgrade` compares versions, and `sha256` pins one archive.
- Homebrew sandboxes install and post_install (checked in Homebrew 7.0.7's `formula_installer.rb`), so a formula cannot write `~/.claude/settings.json`. Users run `claudio-setup` once. Its hooks point at `$(brew --prefix)/opt/claudio/libexec/scripts/`, so upgrades need no re-run.
- `brew style Formula/claudio.rb` must report no offenses (it wants `depends_on "jq"` before `depends_on :macos`).
