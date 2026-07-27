---
name: update-deps
description: Update this dotfiles repo's dependencies — Nix flake inputs (flake.lock) and Go modules (go.mod/go.sum) — then verify with a build and tests and commit on a branch. Use when Thomas asks to update dependencies, bump the flake, refresh packages, or invokes /update-deps in the dotfiles repo.
---

# Update Dependencies — Dotfiles

Update the two dependency surfaces in this repo, verify nothing broke, and commit the result on a branch. This is **full auto**: on a clean verification you create the branch and commit without stopping. Only stop to ask if verification fails or the working tree is dirty in a way you can't safely isolate.

## Dependency surfaces

1. **Nix flake inputs** → `flake.lock`, updated with `nix flake update`. Inputs: `nixpkgs` (unstable), `home-manager`, `darwin`, `flake-utils`, `hunk` (see `flake.nix`).
2. **Go modules** → `go.mod` / `go.sum`, updated with `go get -u ./... && go mod tidy`.

**Coupling to know about:** the Go tools are also built by Nix (`nix/packages/go-tools.nix`, a `buildGoModule` with a pinned `vendorHash`). Any change to `go.mod`/`go.sum` invalidates that `vendorHash`, so a Go update is a **three-file** change — `go.mod`, `go.sum`, **and** `go-tools.nix`. Skip the hash refresh and `darwin-rebuild build` fails with `inconsistent vendoring in ... vendor/modules.txt`. Step 4a handles it.

## Workflow

Run from the repo root (`~/Repos/github.com/t-eckert/dotfiles`).

### 1. Check the working tree first

```bash
git status --short
```

- **Clean** → proceed.
- **Dirty** → only `flake.lock`, `go.mod`, `go.sum` will be touched by this skill. If the uncommitted changes are *unrelated* files (e.g. `nix/home/packages.nix`), do **not** sweep them into the deps commit. Tell Thomas what's uncommitted and ask whether to stash it (`git stash -u`) before proceeding or to abort. Never commit unrelated changes.

### 2. Branch

Create a branch off `main` (use today's date):

```bash
git switch -c deps/update-$(date +%Y-%m-%d)
```

If the branch already exists (already ran today), reuse it or append a suffix.

### 3. Update

```bash
nix flake update
go get -u ./... && go mod tidy
```

`nix flake update` refreshes all flake inputs. To update a single input instead (e.g. only nixpkgs), use `nix flake update nixpkgs`. Use the targeted form if Thomas asks for it.

### 4a. Refresh the Go vendorHash (only if go.mod/go.sum changed)

If step 3 changed `go.mod` or `go.sum`, the pinned `vendorHash` in `nix/packages/go-tools.nix` is now stale. Refresh it:

1. Set it to an all-`A` placeholder to force a rebuild and surface the real hash:
   ```
   vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
   ```
2. Run `nix build .#dotfiles-tools --no-link 2>&1 | grep -E "got:|error:"` — the `got:` line is the correct hash.
3. Write that hash back into `vendorHash`.

If go.mod/go.sum did **not** change, leave `go-tools.nix` alone.

### 4. Verify

Both must pass. **No `sudo`, no `switch`** — build only, so nothing mutates the live system and nothing blocks on a password prompt.

```bash
darwin-rebuild build --flake .    # evaluates + builds the whole darwin system
go build ./...
go test ./...
```

`darwin-rebuild build` produces a `./result` symlink but does not activate anything. (It's gitignored via `result`.) If it isn't on PATH, use `nix run nix-darwin -- build --flake .`.

**`go test` has known pre-existing failures.** `tools/slug` fails `TestRenameFileToKebabCase/camelCase` and `/no_extension` on macOS's case-insensitive filesystem — unrelated to dependencies. Do **not** treat these as a regression or a reason to abort. The gate is *"the update introduced no new failure,"* not *"all tests green."* If `go test` fails, confirm the failure is one of these known cases (or otherwise pre-existing) before blaming the update — reproduce it on the original deps with `git stash push go.mod go.sum`, re-test, then `git stash pop`. A genuinely new failure caused by the bump is what blocks the commit.

### 5. Commit or report

- **All green** (build passes, no *new* test failures) → stage only the dependency files and commit. Include `go-tools.nix` **only if** its `vendorHash` changed in step 4a:

  ```bash
  git add flake.lock go.mod go.sum nix/packages/go-tools.nix   # drop go-tools.nix if unchanged
  git commit -m "Update dependencies (nix flake + go modules)"
  ```

  Then report to Thomas what moved: which flake inputs changed (diff `flake.lock` — compare `locked.rev`/`narHash` per input) and which Go modules bumped (diff `go.mod`). He applies with `task rebuild` when ready — mention that; do **not** run `task rebuild` yourself (it uses `sudo darwin-rebuild switch` and mutates the system).

- **Verification failed** → do **not** commit. Report the failing command and output. To isolate the culprit, the two updates are independent — check out one file at a time:
  - Suspect Nix: `git checkout flake.lock` and re-run `darwin-rebuild build --flake .`.
  - Suspect Go: `git checkout go.mod go.sum nix/packages/go-tools.nix` and re-run `go build ./... && go test ./...` (and `darwin-rebuild build --flake .` for the Nix-packaged tools). Note: `inconsistent vendoring` from `darwin-rebuild build` is not a bad update — it means step 4a's `vendorHash` refresh was missed. Do 4a, don't revert.

  Once isolated, offer to commit the half that works, pin/skip the offending input, or hand it back to Thomas.

## Notes

- Never run `darwin-rebuild switch` or `task rebuild` in this skill — applying the config is Thomas's deliberate step.
- Keep the commit to `flake.lock`, `go.mod`, `go.sum`, and (when its `vendorHash` changed) `nix/packages/go-tools.nix` only. Nothing else.
- If both surfaces have nothing to update (lockfiles unchanged after step 3), say so and skip the branch/commit.
