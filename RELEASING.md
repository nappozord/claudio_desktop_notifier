# Releasing Claudio

How to publish a new version to the Homebrew tap, so `brew upgrade` picks it up.

Two repos are involved:

- **This repo** (`nappozord/claudio_desktop_notifier`): the code and a `v<version>` tag.
- **The tap** (`nappozord/homebrew-tap`): `Formula/claudio.rb`. Its `url` is GitHub's source archive for the tag, which Homebrew downloads and builds with `swiftc`, and `sha256` is the checksum of that archive.

Nothing is built or uploaded by hand: the tag is the release. Both paths below assume the two repos sit side by side, as in `~/Desktop/repos/`.

## Why every release edits the formula

- `brew upgrade` only upgrades when the formula's version is newer than the installed one. Homebrew reads the version from the `url` (`.../v1.2.0.tar.gz` → `1.2.0`).
- `sha256` makes Homebrew check that the download is exactly that archive. Every tag has its own archive, so its own checksum.

So a release always ends with a new `url` and `sha256` in the tap.

## 1. Pick the version

Use [semantic versioning](https://semver.org): `1.2.0` → `1.2.1` for fixes only, `1.3.0` for new features, `2.0.0` for changes that break existing installs.

```sh
V=1.3.0
```

The commands below all use `$V`, so run them in the same terminal.

## 2. Check the code

Everything must be committed and pushed, because the tag is what Homebrew builds.

```sh
cd ~/Desktop/repos/claudio_desktop_notifier
git switch main && git pull
git status -sb                 # "## main...origin/main" and nothing else
make build                     # it must compile: Homebrew runs the same swiftc command
```

## 3. Tag

```sh
git tag v$V
git push origin v$V
```

A GitHub release with notes is optional (Releases → Draft a new release → tag `v$V`). The formula uses the tag's source archive either way, so nothing needs to be attached.

## 4. Update the formula

```sh
SHA=$(curl -sSLf https://github.com/nappozord/claudio_desktop_notifier/archive/refs/tags/v$V.tar.gz | shasum -a 256 | cut -d' ' -f1)
echo $SHA

cd ../homebrew-tap
git pull
perl -pi -e "s{/v[\d.]+\.tar\.gz}{/v$V.tar.gz}; s{sha256 \"\w+\"}{sha256 \"$SHA\"}" Formula/claudio.rb
git diff                       # url and sha256, nothing else
brew style Formula/claudio.rb  # "no offenses detected"
git commit -am "claudio $V"
git push
```

## 5. Check the upgrade

```sh
brew update
brew upgrade nappozord/tap/claudio
brew test nappozord/tap/claudio
claudio ITEM=crown                   # the banner shows; click it to close
```

Users who already ran `claudio-setup` need nothing else: the hooks point at Homebrew's `opt/claudio` path, which always holds the installed version.

## When something goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| `SHA256 mismatch` on upgrade | The formula's `sha256` is not the checksum of the tag's archive, usually a typo or a hash from another tag | Re-run the `curl ... \| shasum -a 256` line from step 4 and put that value in the formula |
| `already installed` / no upgrade offered | Homebrew has the old formula, or the `url` still names the old tag | `brew update`, then check the `url` line |
| `404` on download | The tag was not pushed, or its name differs from the `url` | `git ls-remote --tags origin` and compare |
| Build fails in `swiftc` | The tagged code does not compile, or the Xcode Command Line Tools are missing | Run `make build` on that commit; `xcode-select --install`. For the full log: `brew install --verbose --debug nappozord/tap/claudio` |
| A broken version was tagged | | Fix it and release a new patch version. Never move a tag people may have installed from: its checksum would change |

## How the formula installs Claudio

- It builds `src/*.swift` into `libexec/build/claudio` and links it as `claudio` on the `PATH`.
- It installs the scripts, `install.sh` and `uninstall.sh` into `libexec`, and adds two commands: `claudio-setup` (runs `install.sh`) and `claudio-uninstall` (runs `uninstall.sh`).
- Homebrew sandboxes formula installs, so it cannot edit `~/.claude/settings.json`. That is why users run `claudio-setup` once; the formula's caveats say so after `brew install`.
- `install.sh` sees that there is no `src/` next to it and registers hooks that run the scripts from `$(brew --prefix)/opt/claudio/libexec/scripts/`, with no copy into `~/.claude/claudio/`. Running it from the repo instead builds and copies as before. Each mode removes the other's hooks, so switching is safe.
