# Releasing Claudio

How to publish a new version to the Homebrew tap, so `brew upgrade` picks it up.

Two repos are involved:

- **This repo** (`nappozord/claudio_desktop_notifier`): the code, the tag, and a GitHub release with the built app attached.
- **The tap** (`nappozord/homebrew-tap`): `Formula/claudio.rb`, which says where to download the app (`url`), its checksum (`sha256`) and its `version`.

Both paths below assume the two repos sit side by side, as in `~/Desktop/repos/`.

## Why every release edits the formula

- `brew upgrade` only upgrades when the formula's `version` is newer than the installed one.
- `sha256` makes Homebrew check that the download is exactly the file you published. It is the checksum of that one file, so it changes with every build.

So a release always ends with a new `url`, `sha256` and `version` in the tap.

## 1. Pick the version

Use [semantic versioning](https://semver.org): `1.1.0` → `1.1.1` for fixes only, `1.2.0` for new features, `2.0.0` for changes that break existing installs.

```sh
V=1.2.0
```

The commands below all use `$V`, so run them in the same terminal.

## 2. Build and package

The code must be committed and pushed first: the build has to match the commit you tag.

```sh
cd ~/Desktop/repos/claudio_desktop_notifier
git switch main && git pull
git status                     # must say "nothing to commit, working tree clean"

rm -f build/claudio && make build
tar -czf build/claudio-v$V-macos-arm64.tar.gz -C build claudio
SHA=$(shasum -a 256 build/claudio-v$V-macos-arm64.tar.gz | cut -d' ' -f1)
echo $SHA
```

`-C build` puts `claudio` at the top of the tarball, where the formula's `bin.install "claudio"` expects it.

Do not rebuild after this point. A new build gives a different checksum, and the release and the formula must use the same file.

## 3. Tag and create the release

```sh
git tag v$V
git push origin v$V
```

Then create the release from that tag and attach `build/claudio-v$V-macos-arm64.tar.gz`:

- **On github.com:** Releases → Draft a new release → choose tag `v$V` → attach the file → Publish.
- **With the GitHub CLI** (`brew install gh`, then `gh auth login` once):

  ```sh
  gh release create v$V build/claudio-v$V-macos-arm64.tar.gz --title v$V --notes "What changed"
  ```

Check that the uploaded file is the one you hashed. The two lines must match:

```sh
curl -sSLf https://github.com/nappozord/claudio_desktop_notifier/releases/download/v$V/claudio-v$V-macos-arm64.tar.gz | shasum -a 256
echo $SHA
```

## 4. Update the formula

```sh
cd ../homebrew-tap
git pull
perl -pi -e "s{/v[\d.]+/claudio-v[\d.]+-}{/v$V/claudio-v$V-}; s{sha256 \"\w+\"}{sha256 \"$SHA\"}; s{version \"[\d.]+\"}{version \"$V\"}" Formula/claudio.rb
git diff                       # url (twice), sha256 and version, nothing else
ruby -c Formula/claudio.rb     # "Syntax OK"
git commit -am "claudio $V"
git push
```

## 5. Check the upgrade

```sh
brew update
brew upgrade nappozord/tap/claudio
brew info nappozord/tap/claudio      # shows the new version
```

## When something goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| `SHA256 mismatch` on upgrade | The formula's `sha256` is not the checksum of the uploaded file, usually after a rebuild or a re-upload | Re-run the `curl ... \| shasum -a 256` check from step 3 and put that value in the formula |
| `already installed` / no upgrade offered | Homebrew has the old formula, or `version` was not raised | `brew update`, then check `version` in `Formula/claudio.rb` |
| `404` on download | The tag or the file name in `url` does not match the release | Compare the release's file name with the `url` line |
| A wrong file was released | | Delete the release asset, upload the right one, then redo step 4 with its checksum. Never move a tag that people may have installed from: release a new patch version instead |

## Known limits of the current formula

- **The formula installs only the `claudio` app.** The hooks run the copy in `~/.claude/claudio/`, which `./install.sh` puts there. So a `brew upgrade` does not change what users see until they run `./install.sh` from the repo again.
- **Apple Silicon only.** The tarball is built on an arm64 Mac, so it does not run on Intel Macs.

Both would go away if the formula built Claudio from source and installed the scripts with a `claudio-setup` command. That change is not made yet.
