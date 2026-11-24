# Hook sequence

## System upgrades

1. yay resolves upgrade candidates and fires `UpgradeSelect` with upgrades and
   pulled dependencies.
2. The Lua hook keeps AUR packages, deduplicates them by package base, and
   invokes one `review` operation for the complete set.
3. The helper clones each AUR recipe into a private temporary directory under
   the yay cache. It records the commit plus hashes of `PKGBUILD` and
   `.SRCINFO` in a temporary manifest.
4. Codex reads the temporary workspace in a read-only sandbox. A cache hit is
   accepted only for the same recipe revisions and review configuration.
5. `AURPreInstall` compares yay's actual build paths and repository commit with
   the manifest. A mismatch or missing entry requires an explicit consent
   prompt.
6. `PostInstall` marks a completed transaction for the optional wrapper.

## Explicit package operations

The optional wrapper identifies AUR package targets, creates a temporary
manifest, and reviews the set before invoking yay. The Lua hook then uses that
manifest at `AURPreInstall`. Package names resolved by pacman are left to yay
without a Codex review; `--aur` forces targets to be treated as AUR packages.

The wrapper also detects a successful `-Syu` that did not trigger a
`PostInstall` marker and prints `pacman -Qdtq` cleanup guidance. It does not
remove packages.

## Manifest and cache

The manifest's first line records whether the set was reviewed or explicitly
allowed to proceed unreviewed. Reviewed entries contain package base, recipe
hashes, and commit. They are temporary transaction state, not a durable audit
log. Review JSON is cached below `${XDG_CACHE_HOME:-$HOME/.cache}/yay` and
validated before reuse.

The cache key includes recipe hashes and commits, Codex executable identity,
profile/model settings, Codex configuration hash, prompt hash, and output
schema hash. Changing any of these causes a new review. Cached findings are
validated against the current schema, including severity, confidence, and
field lengths.

The prompt asks for a static walk through the package lifecycle: build-user
recipe functions, package-manager install scripts, source provenance and
integrity, data access, privilege changes, and host effects. Findings must
include evidence and separate confidence from severity. It prohibits running
package code or fetching upstream payloads; the review therefore cannot
evaluate binaries or source archives that are not present in the AUR recipe
repository.

## Trust boundaries

- Recipe files are untrusted input. The review prompt tells Codex not to follow
  instructions in them or execute package code.
- Codex is invoked with a read-only sandbox and ephemeral session.
- The helper clones from `https://aur.archlinux.org`; Git/network availability
  is required for uncached recipe revisions.
- The reviewed snapshot check narrows time-of-check/time-of-use drift for
  recipe files. It does not attest to upstream source payloads or make a
  malicious recipe safe.
- The user can explicitly cancel or bypass an incomplete review. Systems that
  require fail-closed behavior should remove or change those bypass prompts.
