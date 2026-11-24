# yay-codex-review

Run a Codex security review of AUR recipes before yay builds them.

For `yay -Syu`, the `UpgradeSelect` hook collects the selected AUR packages and
their dependencies. The helper reviews the set in one Codex call. Before each
build, `AURPreInstall` checks that yay's recipe files and commit match the
reviewed snapshot. If they changed, yay asks before continuing.

The review reads `PKGBUILD`, `.SRCINFO`, install scripts, patches, and available
recipe history. It looks at source integrity, build and install actions,
permissions, data access, and changes to the host. Findings include severity,
confidence, and file evidence.

## Install

Requirements: yay with Lua hooks, Bash, Git, `jq`, `pacman`, Codex CLI, and a
terminal for prompts. Codex must be on `PATH` or set `CODEX_BIN`.

1. Install the helper:

   ```sh
   install -Dm755 bin/yay-codex-review \
     ~/.local/lib/yay-codex-review/yay-codex-review
   ```

2. Merge the three hooks in `config/init.lua` into
   `~/.config/yay/init.lua`. Keep any hooks you already have.
3. Run `yay -Syu` as usual.

The Lua hooks cover AUR upgrades. To review explicit AUR installs too, install
`bin/yay-wrapper` as `~/.local/bin/yay` and put `~/.local/bin` before
`/usr/bin` in `PATH`. The wrapper calls `/usr/bin/yay`; set `YAY_REAL_BIN` to
use another path. Set `YAY_CODEX_REVIEW_HELPER` if you install the helper
elsewhere.

## Prompts and cache

For a new review, the helper asks before sending the recipe files to the
configured Codex service. Choose review, cancel, or install anyway. It shows
the findings and asks again before yay continues. An exact cache hit skips the
Codex call, but still shows the findings and asks whether to continue.

The helper caches completed reviews by recipe revision and review settings.
Changing the prompt or output schema makes old results ineligible for reuse.

## Limits

The review is static. It does not run package code, fetch upstream source
archives, or inspect binaries that are not in the AUR recipe repository. A
checksum in a `PKGBUILD` does not prove the downloaded file is safe. “No
actionable findings” only describes the files Codex inspected; it is not a
claim that the package is safe.

The wrapper may suggest checking orphaned dependencies after an update with no
package changes. It does not remove packages.

## License

MIT. See [LICENSE](LICENSE).
