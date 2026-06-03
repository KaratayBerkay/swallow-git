# `git push` — Update remote refs along with associated objects

`git push` uploads local refs (branches, tags) to a remote repository and updates the remote refs to match. It is the counterpart to `git fetch` — sending your local commits to a shared remote so others can see them.

```
git push [--all | --mirror | --tags] [--follow-tags] [--atomic] [-n | --dry-run]
         [--receive-pack=<git-receive-pack>] [--repo=<repository>]
         [-f | --force] [--force-with-lease[=<refname>[:<expect>]]]
         [--delete] [--prune] [-v] [-u <refspec>...]
         [--signed[=<version>]] [--force-if-includes] [--push-option=<string>]
         [--[no-]verify] [--] [<repository> [<refspec>...]]
```

---

## Description

`git push` sends commits from your local repository to a remote. For each refspec you provide, Git determines which local commits the remote needs, packages them up, and sends them over the wire.

By default, `git push` pushes the current branch to its upstream tracking branch using the `simple` push strategy. If no upstream is configured, the push is rejected.

The command fails if the remote has commits you don't have locally (non-fast-forward), unless you use `--force` or `--force-with-lease`.

---

## Basic Usage

### `git push`

Push the current branch to its configured upstream:

```bash
git push
```

If the upstream is not configured, Git rejects with a message suggesting `git push --set-upstream`.

### `git push origin main`

Push the local `main` branch to `origin/main`:

```bash
git push origin main
```

This is the most common form — explicitly naming the remote and branch.

### `git push -u origin main`

Push and set the upstream tracking reference:

```bash
git push -u origin main
```

After this, a bare `git push` from `main` will automatically push to `origin/main`.

---

## Upstream Tracking

### `-u` / `--set-upstream`

The `-u` flag sets the upstream tracking reference for the current branch. This links your local branch to a remote branch so that future `git push` and `git pull` calls know where to push/pull from:

```bash
git push -u origin feature-x
```

After this command:
- `git push` (from `feature-x`) pushes to `origin/feature-x`
- `git pull` pulls from `origin/feature-x`
- `git status` shows divergence from `origin/feature-x`

The mapping is stored in `.git/config`:

```ini
[branch "feature-x"]
    remote = origin
    merge = refs/heads/feature-x
```

### `push.autoSetupRemote`

When set to `true`, Git automatically sets up upstream tracking the first time you push a branch that has no upstream:

```bash
git config --global push.autoSetupRemote true
```

After this, `git push` on a new branch automatically creates the remote branch and tracks it — no `-u` needed.

---

## Refspec

A **refspec** specifies how local refs map to remote refs. The format is:

```
<src>:<dst>
```

- `<src>` — the local ref (branch, tag, or commit-ish) to push
- `<dst>` — the remote ref to update

### `git push origin <src>:<dst>`

```bash
git push origin main:production
```

Pushes the local `main` to the remote branch `production`. The local and remote branch names can differ.

### Omitting parts

| Form | Meaning |
|------|---------|
| `git push origin main` | Push `main` to `main` on remote |
| `git push origin :feature` | Delete `feature` on remote (empty src) |
| `git push origin main:` | Push `main` to a branch with the same name (explicit) |
| `git push origin HEAD` | Push current branch to its counterpart on remote |
| `git push origin HEAD:feature` | Push current branch to `feature` on remote |

### Pushing to a different name

```bash
git push origin feature-x:refs/heads/review/feature-x
```

Useful when the remote uses a different naming convention or you want to push to a review namespace.

### Full refspec with `+`

Prefix the refspec with `+` to allow non-fast-forward updates (same as `--force` for that ref):

```bash
git push origin +main:production
```

Only the `main → production` mapping is forced; other refs in the same push are still subject to fast-forward checks.

---

## Force Push

### `-f` / `--force`

Override the remote's branch with your local state, even if the push is not a fast-forward:

```bash
git push --force origin main
```

**Use with extreme caution.** This overwrites the remote history. Anyone who has pulled the old commits will have diverging history.

### `--force-with-lease`

A safer force push. Git checks that the remote ref hasn't been updated by someone else since you last fetched:

```bash
git push --force-with-lease origin main
```

If the remote has advanced (e.g., a colleague pushed commits), the push is rejected. This protects against accidentally overwriting someone else's work.

Specify a ref for lease-checking:

```bash
git push --force-with-lease=main:abc123 origin main
```

Only succeeds if `origin/main` is exactly at `abc123`.

### `--force-if-includes`

Require that the local ref's history includes what the remote ref points to. Adds an extra safety check on top of `--force-with-lease`:

```bash
git push --force-with-lease --force-if-includes origin main
```

Relevant when you've rebased or amended — ensures your local branch actually contains the remote's current tip.

### Safety comparison

| Command | Overwrites remote | Protects against remote changes | Protects against missing remote commits |
|---------|-------------------|--------------------------------|----------------------------------------|
| `--force` | Yes | No | No |
| `--force-with-lease` | Yes | Yes (checks remote state) | Partial |
| `--force-with-lease --force-if-includes` | Yes | Yes | Yes (checks inclusion) |

---

## Delete

### `git push origin --delete <branch>`

Delete a remote branch:

```bash
git push origin --delete feature-old
```

The remote branch `feature-old` is removed. The local branch is **not** affected.

### `git push origin :<branch>`

The older syntax — push "nothing" to the remote ref:

```bash
git push origin :feature-old
```

This does the same thing as `--delete`.

### Delete a remote tag

```bash
git push origin --delete v1.0-rc
git push origin :refs/tags/v1.0-rc
```

---

## All and Mirror

### `--all`

Push **all** local branches to the remote:

```bash
git push --all origin
```

Tags are **not** included — use `--tags` or `--follow-tags` separately.

### `--mirror`

Push **all** refs under `refs/` (branches, tags, notes, etc.) and also perform **deletions** — any ref on the remote that doesn't exist locally is removed:

```bash
git push --mirror origin
```

The remote becomes an exact copy of your local repo. Useful for mirroring or backup.

**Warning:** Destructive — remote refs not in your local repo are deleted.

### `--tags`

Push all tags (both lightweight and annotated):

```bash
git push --tags origin
```

Without `--tags`, Git only pushes annotated tags that are reachable from pushed commits.

### `--follow-tags`

Push all annotated tags **reachable** from the pushed commits:

```bash
git push --follow-tags origin main
```

Unlike `--tags`, this does **not** push tags that aren't ancestors of the pushed commits. Safer for most workflows.

```bash
git push --follow-tags origin main
# Pushes main + annotated tags that are ancestors of main
```

---

## Prune

### `--prune`

Delete remote-tracking branches on the remote that don't exist locally:

```bash
git push --prune origin
```

Before: `origin` has `main`, `stale-branch`, `old-feature`
After: only `main` is kept on the remote (if it's the only local branch)

Useful for tidying up stale remote branches after local cleanup.

### `--prune-tags`

Delete tags on the remote that don't exist locally:

```bash
git push --prune-tags origin
```

Removes all remote tags that don't have a corresponding local tag.

Combine with `--prune`:

```bash
git push --prune --prune-tags origin
```

Cleans both branches and tags in one push.

---

## Dry-Run

### `-n` / `--dry-run`

Simulate the push without actually sending any data:

```bash
git push --dry-run origin main
```

Output shows what would be pushed (new commits, updated refs) without modifying the remote:

```
To https://github.com/user/repo.git
    abc123..def456  main -> main
```

Always use `--dry-run` when you're unsure about the effects of a force push or a delete.

---

## Atomic

### `--atomic`

Push multiple refs in a single atomic transaction — either **all** refs are updated or **none** are:

```bash
git push --atomic origin main feature
```

If pushing `main` succeeds but `feature` fails, the remote is rolled back to its original state. Without `--atomic`, `main` would be updated even if `feature` failed.

Useful for CI/CD workflows where you need to update multiple branches or tags together.

---

## Signed Pushes

### `--signed[=<version>]`

Cryptographically sign the push certificate, proving to the remote that the push came from you:

```bash
git push --signed origin main
```

The remote must be configured to accept signed pushes (`receive.certNonceSeed`). GitHub and GitLab support this for verified push authentication.

Version options:
- `--signed` — uses the current push certificate version (default)
- `--signed=1` — explicit version

### `--push-cert=<file>`

Use an externally generated push certificate (for scripting or tooling):

```bash
git push --push-cert=/tmp/push-cert.pem origin main
```

---

## Config

### `push.default`

Controls which branches are pushed when no refspec is given:

| Value | Behavior |
|-------|----------|
| `nothing` | Do not push anything — error out |
| `current` | Push the current branch to a matching remote branch of the same name |
| `simple` | Push the current branch to its upstream (the same name). Rejects if names differ. **Default since Git 2.0** |
| `upstream` | Push the current branch to its upstream (can differ in name) |
| `matching` | Push all branches that have a matching remote branch of the same name. **Pre-Git 2.0 default** |

```bash
git config --global push.default simple
```

Most users should stick with `simple` — it's the safest and most intuitive default.

### `push.forceWithLease`

Set to `true` to make `--force-with-lease` the default for all force pushes:

```bash
git config --global push.forceWithLease true
```

With this set, `git push --force` is rejected unless you explicitly opt out with `--no-force-with-lease`.

### `push.autoSetupRemote`

Automatically set up upstream tracking on first push:

```bash
git config --global push.autoSetupRemote true
```

### `push.negotiate`

Control whether to use protocol v2 push negotiation to reduce data transfer:

```bash
git config --global push.negotiate true
```

When enabled, Git and the remote agree on which objects are already present, avoiding unnecessary pack data transfer.

### `push.followTags`

Make `--follow-tags` the default for all pushes:

```bash
git config --global push.followTags true
```

### `push.gpgSign`

Enable signed pushes by default:

```bash
git config --global push.gpgSign true
```

---

## Quick Reference

```bash
# Basic push
git push                                                   # Push current branch to upstream
git push origin main                                       # Push main to origin/main
git push -u origin feature                                 # Push and set upstream

# Force push
git push --force origin main                               # Overwrite remote (dangerous)
git push --force-with-lease origin main                    # Safer force push
git push --force-with-lease --force-if-includes origin main # Safest force push

# Delete
git push origin --delete old-branch                        # Delete remote branch
git push origin :old-branch                                # Delete (older syntax)

# All and mirror
git push --all origin                                      # Push all branches
git push --mirror origin                                   # Exact mirror (includes deletions)
git push --tags origin                                     # Push all tags
git push --follow-tags origin main                         # Push reachable annotated tags

# Prune
git push --prune origin                                    # Remove stale branches on remote
git push --prune --prune-tags origin                       # Remove stale branches and tags

# Safety
git push --dry-run origin main                             # Preview without sending
git push --atomic origin main feature                      # All or nothing

# Signed
git push --signed origin main                              # Cryptographically signed push

# Refspec
git push origin main:production                            # Push main as production on remote
git push origin HEAD:feature                               # Push current HEAD as feature
git push origin +main:experiment                           # Forced refspec (per-ref force)

# Multiple remotes
git push upstream main                                     # Push to a different remote
git push origin main --push-option="ci-skip"               # Pass server option
```

---

## Real-World Examples

### 1. Push a new feature branch

```bash
git checkout -b feature-user-auth
git push -u origin feature-user-auth
```

Creates a local branch, pushes it to `origin`, and sets up tracking. Future pushes from this branch are simply `git push`.

### 2. Push after rebasing (force with lease)

```bash
git rebase main
git push --force-with-lease origin feature-user-auth
```

You've rebased your feature branch onto `main`. Since the commit history changed, a normal push is rejected. `--force-with-lease` safely overwrites the remote, but only if no one else pushed in the meantime.

### 3. Delete a stale remote branch

```bash
git push origin --delete feature-deprecated
```

Removes the branch from the remote. The local branch is untouched.

### 4. Push all tags

```bash
git tag v1.0 v1.1 v1.2
git push --tags origin
```

Pushes all local tags to the remote. Use `--follow-tags` instead if you only want tags reachable from the pushed commits.

### 5. Prune stale remote branches

```bash
git branch -d old-feature
git push --prune origin
```

After deleting `old-feature` locally, `--prune` tells the remote to delete its copy too.

### 6. Push all local branches

```bash
git push --all origin
```

Pushes every local branch to `origin`. Tags are not included — add `--tags` to include them.

### 7. Push to a differently named remote branch

```bash
git push origin main:production
```

Pushes your local `main` to the remote branch `production`. Useful for deployment workflows where the remote branch has a different name.

### 8. Atomic push of multiple branches

```bash
git push --atomic origin main release-v2
```

Both `main` and `release-v2` are pushed as one atomic operation. If either fails, neither is updated on the remote.

### 9. Dry-run before a force push

```bash
git push --dry-run --force-with-lease origin main
```

Shows what would happen during the force push without actually doing it. Always run this first when you're uncertain.

### 10. Mirror a repository

```bash
git clone --mirror https://github.com/user/repo.git repo-mirror
cd repo-mirror
git remote update  # Later, to refresh
```

Or to push a full mirror:

```bash
git push --mirror https://github.com/user/new-repo.git
```

Creates an exact replica including all branches, tags, and refs.

### 11. Push with server options

```bash
git push --push-option=ci-skip --push-option=reviewer=jane origin main
```

Passes options to the remote server (supported by GitHub AE, GitLab). The server can use these for CI, hooks, or access control.

### 12. Refspec with force per-branch

```bash
git push origin +main:main stable:stable
```

The `+` prefix forces `main` (non-fast-forward allowed), while `stable` is pushed normally (fast-forward only).

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git push` fails with "no upstream branch" | The local branch has no tracking reference | Use `git push -u origin <branch>` or set `push.autoSetupRemote` |
| `git push` rejected (non-fast-forward) | Remote has commits you don't have locally | Pull first: `git pull --rebase`, then push |
| Accidental `--force` overwrote remote history | Someone else's commits were lost | `git reflog` on the remote (if accessible) or ask teammates to force-push their commits back |
| Forgot `--tags` — tags not pushed | Tags are not included in `git push` or `git push --all` | `git push --tags origin` |
| `git push origin :branch` deleted the wrong branch | Confused branch name or typo in the refspec | Use `--delete` for clarity: `git push origin --delete <branch>` |
| Pushed with wrong author/email | Local `user.name`/`user.email` not set or incorrect | Fix with `git commit --amend --author="...""` then force push (if alone on the branch) |
| Atomic push partially failed | Some refs pushed, others rejected | Use `--atomic` so the entire push is rolled back on failure |
| Signed push rejected | Remote does not accept signed pushes or cert nonce expired | Disable signed pushes for that push: `git push --no-signed` |
| `git push --mirror` deleted expected branches | Mirror makes remote an exact copy — missing local refs are deleted | Use `--all` instead of `--mirror` for non-destructive bulk push |
| Large push is very slow | Sending a lot of data with no negotiation | Enable `push.negotiate` or use shallow push: `git push --depth=1` |
| Can't delete remote branch "not permitted" | Branch is protected on the remote (GitHub/GitLab) | Unprotect the branch in the remote's settings, or use a merge request |

---

## Comparison: Push Strategies

| Strategy | Behavior | Use case |
|----------|----------|----------|
| `simple` | Push current branch to same-name upstream | Default — safe for most workflows |
| `current` | Push current branch to same name on remote | Fork-based workflows (single-branch pushes) |
| `upstream` | Push current branch to its configured upstream | Branches with different local/remote names |
| `matching` | Push all branches with matching remote names | Legacy behavior, rarely needed |
| `nothing` | Refuse to push without explicit refspec | CI scripting — prevents accidental pushes |

---

## Visual Summary

```
Local Repository                          Remote Repository
      │                                        │
      │  git push origin main                   │
      │  main ───────────────────────────────►  │  refs/heads/main
      │                                        │
      │  git push --all origin                  │
      │  main ───────────────────────────────►  │  refs/heads/main
      │  feature ────────────────────────────►  │  refs/heads/feature
      │                                        │
      │  git push --tags origin                 │
      │  v1.0 ───────────────────────────────►  │  refs/tags/v1.0
      │  v1.1 ───────────────────────────────►  │  refs/tags/v1.1
      │                                        │
      │  git push -f origin main                │
      │  main ─────────── (overwrite) ───────►  │  refs/heads/main
      │                                        │
      │  git push origin --delete old           │
      │  (nothing) ──────────────────────────►  │  (delete refs/heads/old)
      │                                        │
```

`git push` is how your local work reaches the team. Push early, push often, but push carefully — use `--force-with-lease`, try `--dry-run` first, and never force-push to a shared branch without coordinating with your teammates.
