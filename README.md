# yay-codex-review

Review AUR build recipes with Codex before yay builds them. The review is
transaction-wide: one review covers the AUR packages selected for an update,
then yay's pre-install hook checks that the files being built still match the
reviewed snapshot.

This is a reference implementation for people who want to build the same
integration into their own yay setup. It is not an official yay or Codex
project.

## What it does

For `yay -Syu`, the `UpgradeSelect` hook gathers AUR package bases from the
selected upgrades and pulled dependencies. The helper fetches their AUR Git
recipes and asks Codex to inspect `PKGBUILD`, `.SRCINFO`, install scripts,
patches, and available commit diffs. It prints up to five actionable findings
or reports that it found none.

Before each AUR build, `AURPreInstall` compares the build files' SHA-256 hashes
and Git commit with the snapshot used for review. A mismatch prompts before
proceeding. Completed reviews are cached by package revisions and review
settings.

The optional wrapper also reviews explicit AUR install targets and gives a
cleanup suggestion after a successful no-op system update. It never removes
packages automatically.

## Requirements

- Arch Linux (or an Arch-based system), `yay` with Lua hook support
- Bash, Git, `jq`, and `pacman`
- [Codex CLI](https://github.com/openai/codex) available as `codex`, or set
  `CODEX_BIN`
- A terminal for consent prompts

The Codex command uses `codex exec --ephemeral --sandbox read-only`. The first
review of an exact package set asks before starting; the prompt explains that
the recipe files will be sent to the configured Codex service. The choices are
review, cancel, or install anyway without review. A completed cached review
does not need another provider request.

## Install

1. Copy `bin/yay-codex-review` to
   `~/.local/lib/yay-codex-review/yay-codex-review` and make it executable.
2. Merge `config/init.lua` into `~/.config/yay/init.lua`. If that file already
   has hooks, keep them and add these three `yay.create_autocmd` blocks rather
   than replacing the file.
3. Start with the hooks only and run your usual `yay -Syu`.
4. Optionally install `bin/yay-wrapper` as `~/.local/bin/yay` and ensure that
   directory comes before `/usr/bin` in `PATH`. The wrapper calls `/usr/bin/yay`
   by default; set `YAY_REAL_BIN` to override it.

Set `YAY_CODEX_REVIEW_HELPER` if the helper is installed somewhere else. Set
`CODEX_BIN` if Codex is not on `PATH`. The wrapper can be skipped: the Lua hooks
are enough for AUR upgrades during `yay -Syu`.

## Review scope and limits

The review is an aid, not a guarantee that a package is safe. It inspects AUR
recipe content and diffs available from the recipe Git repository. It does not
download or inspect upstream source archives, binaries, or other payloads, and
it cannot prove that upstream downloads match the recipe's claims. A clean
result means only that Codex reported no actionable issue in the reviewed
files.

If fetching or reviewing fails, the helper asks before proceeding without a
completed review. The explicit “install anyway” choice bypasses review by
design. Review the scripts before installing them and adapt the consent and
bypass policy to your own threat model.

## Files

- `config/init.lua`: yay `UpgradeSelect`, `AURPreInstall`, and `PostInstall`
  hooks.
- `bin/yay-codex-review`: fetches recipe snapshots, runs/caches reviews,
  verifies build inputs, and formats findings.
- `bin/yay-wrapper`: optional transaction-aware wrapper for explicit installs
  and no-op cleanup suggestions.
- `docs/architecture.md`: hook sequence and manifest details.

## License

No license has been selected yet. Until one is added, normal copyright rules
apply; ask the author before reusing or redistributing this code.
