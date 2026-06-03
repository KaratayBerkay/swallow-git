# `git fetch` — Download objects and refs from another repository

`git fetch` downloads commits, objects, and refs from a remote repository into your local repository. It updates your remote-tracking branches (`origin/main`, `origin/feature`, etc.) but does **not** merge or rebase anything into your working branches — your local work is untouched.

```
git fetch [<options>] [<repository> [<refspec>...]]
git fetch [<options>] <group>
git fetch --multiple [<options>] [(<repository> | <group>)...]
git fetch --all [<options>]
```

---

## Description

`git fetch` is the safe way to see what others have been doing. It reaches out to a remote, downloads any new objects (commits, trees, blobs, tags), and updates your remote-tracking branches under `refs/remotes/<remote>/`.

**Crucially, `git fetch` never changes your working tree or your local branches.** Unlike `git pull` (which is `git fetch` + `git merge`), fetch only updates your view of the remote. You decide later whether to merge, rebase, inspect, or cherry-pick the fetched commits.

```
Before fetch:
Local:   A---B---C  (main)
Remote:  A---B---D---E  (origin/main)

After git fetch:
Local:   A---B---C  (main)
              \
               D---E  (origin/main)    ← updated

Your main branch is untouched. You can now merge, rebase, or inspect E.
```

---

## Basic Usage

### `git fetch`

Fetch from the default remote (`origin`) for the current branch:

```bash
git fetch
```

Updates all remote-tracking branches for `origin`. The default remote is determined by the current branch's `branch.<name>.remote` config.

### `git fetch origin`

Fetch from a specific remote:

```bash
git fetch origin
```

Updates all remote-tracking branches from `origin` (`origin/main`, `origin/feature`, etc.).

### `git fetch --all`

Fetch from **all** remotes defined in the repository:

```bash
git fetch --all
```

If you have multiple remotes (`origin`, `upstream`, `backup`), this fetches from each one.

---

## Refspec

A **refspec** specifies which remote refs to fetch and where to store them locally. The general form is:

```
[+]<src>:<dst>
```

- `<src>` — the ref(s) on the remote to fetch from
- `<dst>` — the local ref(s) to update

The `+` prefix allows non-fast-forward updates (same as `--force` for that ref).

### Default refspec

When you clone a repository, Git sets up this default refspec:

```ini
[remote "origin"]
    url = https://github.com/user/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
```

This means: "fetch all branches from the remote and store them as remote-tracking branches under `refs/remotes/origin/`."

### `git fetch origin <src>:<dst>`

Fetch a specific remote branch and map it to a specific local ref:

```bash
git fetch origin main:feature
```

Fetches `refs/heads/main` from `origin` and writes it to `refs/heads/feature` locally (creating or updating your local `feature` branch).

**Warning:** This can overwrite your local branch. Adding `+` forces the update even if it's not a fast-forward.

### Partial refspecs

| Form | Meaning |
|------|---------|
| `git fetch origin main` | Fetch `refs/heads/main` from origin, store in `refs/remotes/origin/main` |
| `git fetch origin main:refs/heads/local-main` | Fetch `main` and write to local branch `local-main` |
| `git fetch origin :feature` | Fetch nothing, update local `feature` to remote's state (deletes if remote doesn't have it) |
| `git fetch origin +refs/pull/*/head:refs/remotes/origin/pr/*` | Fetch all GitHub PR refs into local remote-tracking namespace |
| `git fetch origin refs/notes/*:refs/notes/*` | Fetch notes refs |

### Force per-refspec with `+`

Prefix with `+` to allow non-fast-forward updates for a specific refspec:

```bash
git fetch origin +main:feature
```

Only the `main → feature` mapping is forced; other refs in the same fetch follow normal fast-forward rules.

---

## Prune

### `-p` / `--prune`

Delete remote-tracking branches that no longer exist on the remote:

```bash
git fetch -p origin
git fetch --prune origin
```

Before: local has `origin/main`, `origin/stale-branch`, `origin/old-feature`
After: `origin/stale-branch` and `origin/old-feature` are deleted (the remote deleted them)

Without `-p`, stale remote-tracking branches accumulate indefinitely.

### `--prune-tags`

Delete local tags that no longer exist on the remote:

```bash
git fetch --prune-tags origin
git fetch -p --prune-tags origin    # Prune both branches and tags
```

---

## Tags

### `--tags`

Fetch **all** tags from the remote:

```bash
git fetch --tags origin
```

By default, Git only fetches tags that are reachable from fetched branches. `--tags` forces all tags to be fetched.

### `--no-tags`

Explicitly skip fetching any tags:

```bash
git fetch --no-tags origin
```

### `--follow-tags`

Fetch annotated tags that are reachable from the fetched commits (but **not** all tags):

```bash
git fetch --follow-tags origin
```

This is the middle ground — tags that are ancestors of the fetched commits are included, but unrelated tags are not.

| Option | Tags fetched |
|--------|-------------|
| Default | Only tags reachable from fetched branches |
| `--no-tags` | No tags |
| `--tags` | All tags from the remote |
| `--follow-tags` | Annotated tags reachable from fetched commits |

---

## Depth and Shallow

### `--depth=<depth>`

Limit the fetch to a given number of commits from the tip. Deepen a shallow repository:

```bash
git fetch --depth 5 origin main
```

Only the latest 5 commits of `origin/main` are fetched. Useful for CI/CD where full history is not needed.

### `--deepen=<depth>`

Deepen a shallow repository by a given number of commits from the current tip:

```bash
git fetch --deepen 10 origin main
```

Adds 10 more commits of history to the already-shallow clone.

### `--shallow-since=<date>`

Fetch commits more recent than a given date:

```bash
git fetch --shallow-since="2025-01-01" origin main
```

### `--shallow-exclude=<revision>`

Deepen or shallow the history excluding commits reachable from a given ref:

```bash
git fetch --shallow-exclude=v1.0 origin
```

### `--unshallow`

Convert a shallow repository to a full one by fetching all history:

```bash
git fetch --unshallow origin
```

If the repository is not shallow, this is a no-op.

---

## Force

### `-f` / `--force`

Update local refs even if the update is not a fast-forward:

```bash
git fetch --force origin main
```

This updates `refs/remotes/origin/main` even if the remote has been force-pushed and the history diverges. Without `--force`, Git rejects non-fast-forward updates to remote-tracking branches.

You can also force per-refspec with `+`:

```bash
git fetch origin +main:main
```

---

## Multiple Remotes

### `--all`

Fetch from all remotes:

```bash
git fetch --all
```

Equivalent to running `git fetch <remote>` for each remote defined in your repo.

### `--multiple`

Fetch from multiple URLs/repositories specified on the command line:

```bash
git fetch --multiple origin upstream
```

Fetches from both `origin` and `upstream` sequentially.

### `--recurse-submodules=yes`

Fetch all submodules recursively:

```bash
git fetch --recurse-submodules=yes origin
```

`--no-recurse-submodules` disables submodule fetching (useful when submodules are slow to access or irrelevant).

---

## Atomic

### `--atomic`

Fetch multiple refs in a single atomic transaction — either **all** refs are updated or **none** are:

```bash
git fetch --atomic origin main feature
```

If fetching `main` succeeds but `feature` fails, the remote-tracking refs are rolled back. Without `--atomic`, `refs/remotes/origin/main` would be updated even if `feature` failed.

---

## Options

### Verbosity

| Option | Description |
|--------|-------------|
| `-v` / `--verbose` | Show more detail during fetch (URLs, ref updates, negotiation) |
| `-q` / `--quiet` | Suppress all non-error output — useful in scripts |

```bash
git fetch -v origin
git fetch -q origin
```

### Submodules

| Option | Description |
|--------|-------------|
| `--no-recurse-submodules` | Do not fetch submodules (default) |
| `--recurse-submodules[=yes/on-demand/no]` | Fetch submodules recursively |

```bash
git fetch --recurse-submodules=yes origin
git fetch --no-recurse-submodules origin
```

### Jobs

| Option | Description |
|--------|-------------|
| `-j <n>` / `--jobs=<n>` | Number of parallel children for fetching submodules |

```bash
git fetch --recurse-submodules --jobs=4 origin
```

### Other options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would be fetched without downloading anything |
| `--refetch` | Refetch all objects from the remote (useful after partial clone) |
| `--no-update-head-ok` | Prevent updating HEAD in a detached state |
| `--negotiation-tip=<ref>` | Specify which refs to use for pack negotiation |
| `--force` / `-f` | Allow non-fast-forward ref updates |
| `--keep` | Keep downloaded pack (do not delete after fetching) |
| `--update-shallow` | Update `.git/shallow` even if the fetch extends shallow boundaries |
| `--stdin` | Read refspecs from standard input |
| `--server-option=<option>` | Pass server option to remote (protocol v2) |

---

## Configuration

### `fetch.prune`

When set to `true`, `git fetch` automatically prunes stale remote-tracking branches:

```bash
git config --global fetch.prune true
```

After this, `git fetch origin` behaves as if `--prune` was always passed.

### `fetch.pruneTags`

When set to `true`, `git fetch` automatically prunes tags that no longer exist on the remote:

```bash
git config --global fetch.pruneTags true
```

Combine with `fetch.prune` to clean both branches and tags on every fetch.

### `fetch.recurseSubmodules`

Control submodule fetching by default:

| Value | Behavior |
|-------|----------|
| `false` / `no` | Do not recurse into submodules |
| `true` / `yes` | Recursively fetch submodules |
| `on-demand` | Only fetch submodules when the parent repo's tree was updated |

```bash
git config --global fetch.recurseSubmodules true
```

### `fetch.negotiationAlgorithm`

Control how Git negotiates which objects to send during fetch (protocol v2):

```bash
git config fetch.negotiationAlgorithm skipping
```

The `skipping` algorithm can speed up negotiation for large repos.

### `remote.origin.fetch`

The default refspec for a remote. For `origin`:

```ini
[remote "origin"]
    url = https://github.com/user/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
```

You can add additional refspecs to fetch extra refs (e.g., pull requests):

```ini
[remote "origin"]
    url = https://github.com/user/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
    fetch = +refs/pull/*/head:refs/remotes/origin/pr/*
```

### `remote.<name>.tagOpt`

Control tag fetching behavior for a specific remote:

```ini
[remote "origin"]
    tagOpt = --no-tags    # Never fetch tags from origin
    tagOpt = --tags       # Always fetch all tags
```

### `fetch.writeCommitGraph`

When set to `true`, Git writes a commit-graph file after each fetch for faster `git log` and `git merge-base`:

```bash
git config --global fetch.writeCommitGraph true
```

---

## Quick Reference

```bash
# Basic fetch
git fetch                                           # Fetch from default remote
git fetch origin                                    # Fetch all branches from origin
git fetch --all                                     # Fetch from all remotes

# Refspec
git fetch origin main                               # Fetch main branch only
git fetch origin main:feature                       # Fetch main into local feature branch
git fetch origin +main:feature                      # Force update feature branch
git fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'

# Prune
git fetch -p origin                                 # Prune stale remote-tracking branches
git fetch --prune-tags origin                       # Prune stale tags
git fetch -p --prune-tags origin                    # Prune both branches and tags

# Tags
git fetch --tags origin                             # Fetch all tags
git fetch --no-tags origin                          # Fetch no tags
git fetch --follow-tags origin                      # Fetch only reachable annotated tags

# Shallow
git fetch --depth 1 origin                          # Shallow fetch (latest commit only)
git fetch --depth 5 origin main                     # Last 5 commits
git fetch --deepen 10 origin                        # Deepen by 10 commits
git fetch --shallow-since="2025-01-01" origin       # Since date
git fetch --unshallow origin                        # Full history

# Force
git fetch -f origin                                 # Allow non-fast-forward ref updates
git fetch --force origin main

# Multiple remotes
git fetch --all                                     # All remotes
git fetch --multiple origin upstream                # Specific remotes

# Atomic
git fetch --atomic origin main feature              # All or nothing

# Submodules
git fetch --recurse-submodules=yes origin           # Fetch submodules too
git fetch --no-recurse-submodules origin            # Skip submodules
git fetch -j 4 --recurse-submodules origin          # Parallel submodule fetch

# Verbosity
git fetch -v origin                                 # Verbose
git fetch -q origin                                 # Quiet (scripts)

# Other
git fetch --dry-run origin                          # Preview without downloading
git fetch --refetch origin                          # Refetch all objects
git fetch --keep origin                             # Keep downloaded pack
git fetch --server-option=ci-skip origin            # Pass server option
```

---

## Real-World Examples

### 1. `git fetch origin`

```bash
git fetch origin
```

The most common fetch — downloads everything new from `origin` and updates all remote-tracking branches. Your working tree and current branch are untouched. Check what changed with:

```bash
git log --oneline main..origin/main
```

### 2. `git fetch --all`

```bash
git fetch --all
```

If you have multiple remotes (e.g., `origin` and `upstream`), this fetches from all of them. Useful in fork-based workflows where you track both your fork and the upstream project.

### 3. `git fetch -p` (prune deleted remote branches)

```bash
git fetch -p origin
```

After a teammate deletes a remote branch, your local `origin/deleted-branch` persists. `-p` cleans it up automatically:

```
 x [deleted]         (none)     -> origin/deleted-branch
```

### 4. `git fetch origin main:feature`

```bash
git fetch origin main:feature
```

Fetches `refs/heads/main` from `origin` and writes it to your local `feature` branch. Useful when you want to create a local branch from a remote branch without switching to it.

### 5. `git fetch --depth 1 origin` (shallow)

```bash
git fetch --depth 1 origin
```

Only the latest commit of each branch on `origin` is fetched. This is a **shallow fetch** — older history is not downloaded. Ideal for CI pipelines or quick inspections.

### 6. `git fetch --tags origin`

```bash
git fetch --tags origin
```

Fetches every tag from the remote, including tags that are not reachable from any fetched branch. Without this flag, Git only fetches tags that are ancestors of fetched branches.

### 7. `git fetch --unshallow`

```bash
git fetch --unshallow origin
```

Converts a shallow clone (created with `git clone --depth 1`) into a full clone by fetching all remaining history. The output shows the full history being downloaded:

```
remote: Enumerating objects: 5000, done.
remote: Counting objects: 100% (5000/5000), done.
remote: Compressing objects: 100% (2500/2500), done.
Receiving objects: 100% (5000/5000), 15.2 MiB | 3.1 MiB/s, done.
Resolving deltas: 100% (3200/3200), done.
```

### 8. `git fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'`

```bash
git fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'
```

Fetches all GitHub pull request refs into your local repository. After this:

```bash
git checkout -b pr-42 origin/pr/42
```

You can review any PR locally. To make this permanent, add it to your config:

```bash
git config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pr/*'
```

### 9. `git fetch --dry-run origin`

```bash
git fetch --dry-run origin
```

Shows what would be fetched without actually downloading anything:

```
From https://github.com/user/repo
 = [up to date]      main       -> origin/main
    abc123..def456   feature    -> origin/feature
```

### 10. `git fetch --prune --prune-tags origin`

```bash
git fetch --prune --prune-tags origin
```

Fully synchronize your remote-tracking branches and tags with the remote: remove stale branches, remove stale tags, and fetch new commits.

### 11. `git fetch --refetch`

```bash
git fetch --refetch origin
```

Refetch all objects, ignoring the local object store. Useful after a partial clone when you want to download everything, or when your local object store is corrupted.

### 12. `git fetch --recurse-submodules=yes origin`

```bash
git fetch --recurse-submodules=yes origin
```

Fetch from `origin` and also fetch updates for all submodules in parallel.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git fetch` doesn't update your working branch | Fetch only updates remote-tracking branches — it never merges | Run `git merge origin/main` or `git rebase origin/main` after fetch |
| `git pull` did a merge you didn't want | `git pull` = `git fetch` + `git merge` | Use `git fetch` then `git rebase origin/main` for linear history |
| Stale remote-tracking branches accumulate | Deleted branches still show in `git branch -r` | Use `git fetch -p` or set `fetch.prune = true` |
| `git fetch origin main:feature` overwrote local work | The refspec writes directly to a local branch | Use `+` only intentionally; stick to `refs/remotes/` namespace for safety |
| "refusing to fetch into current branch" | You tried to fetch into a checked-out branch | Check out a different branch first, or use `git fetch origin main:refs/heads/main` (with caution) |
| "non-fast-forward" error on fetch | Remote was force-pushed and history diverged | Use `git fetch --force` or `+` in the refspec if you trust the new history |
| `git fetch --tags` brought too many unwanted tags | `--tags` fetches every tag, including old ones | Use `--no-tags` or `--follow-tags` for targeted fetching |
| Fetch is very slow on large repos | Full history transfer takes time | Use `--depth 1` for shallow fetch, or set `fetch.negotiationAlgorithm = skipping` |
| Submodules not updated after fetch | `git fetch` does not recurse into submodules by default | Use `git fetch --recurse-submodules=yes` or `git submodule update` |
| Partial clone objects missing after fetch | Fetched only commits, not blobs | Use `git fetch --refetch` or check out files to trigger on-demand blob fetch |
| Forgot `--prune` and have stale `origin/*` branches | Remote branches deleted but local tracking refs remain | `git remote prune origin` also works, or use `git fetch -p` |
