# `git pull` — Fetch from and integrate with another repository or a local branch

`git pull` is the combination of `git fetch` (download objects and refs from a remote) followed by `git merge` (or `git rebase`) to integrate those changes into your current branch. It's the standard way to update your local branch with upstream changes.

```
git pull [<options>] [<repository> [<refspec>...]]
```

---

## Description

`git pull` runs two commands under the hood:

1. **`git fetch`** — downloads new objects and refs from the remote
2. **`git merge`** (or **`git rebase`**) — integrates the fetched changes into your current branch

The merge step is the default. Use `--rebase` to replace the merge with a rebase.

### Merge vs Rebase

```
Before pull:
  A---B---C  (main)
       \
        D---E  (origin/main)

git pull (merge):
  A---B---C---F  (main)
       \     /
        D---E  (origin/main)

git pull --rebase (rebase):
  A---B---C---D---E  (main)

The merge creates a merge commit F. The rebase replays D and E on top of C,
producing a linear history.
```

**When to use which:**

| Approach | History | Pros | Cons |
|----------|---------|------|------|
| Merge | Non-linear | Preserves exact timeline; safe; easy to undo | Merge commits can clutter history |
| Rebase | Linear | Clean, readable history; no merge bubbles | Rewrites local commits; force-push needed if already shared |

---

## Basic Usage

### `git pull` — Default

```bash
git pull
```

Fetches from the upstream remote (usually `origin`) and merges the remote-tracking branch for the current branch. Uses the branch's `branch.<name>.merge` and `branch.<name>.remote` config.

### `git pull origin main`

```bash
git pull origin main
```

Fetches `main` from `origin` and merges it into the current branch. Explicit remote and refspec.

### `git pull --rebase`

```bash
git pull --rebase
```

Fetches and then **rebases** your local commits on top of the fetched changes, producing a linear history with no merge commits.

---

## Rebase vs Merge

### `--rebase`

Use rebase instead of merge to integrate upstream changes:

```bash
git pull --rebase
```

Your local commits are replayed on top of the fetched commits. If conflicts occur, Git pauses the rebase — resolve them, then `git rebase --continue`.

### `--no-rebase`

Force merge mode even if `pull.rebase` is configured:

```bash
git pull --no-rebase
```

### `--rebase=interactive` (or `-i`)

Pull with an interactive rebase — lets you reorder, squash, fixup, or edit commits as they're replayed:

```bash
git pull --rebase=interactive
```

Shorthand:

```bash
git pull -i
```

This opens a rebase todo list in your editor. Useful for cleaning up local commits before pushing to a shared branch.

### `pull.rebase` config

Control the default pull behavior:

```bash
git config pull.rebase true       # Always rebase on pull
git config pull.rebase false      # Always merge on pull
git config pull.rebase merges     # Rebase but preserve merge commits
git config pull.rebase interactive # Always open interactive rebase
```

---

## Options

### Fast-Forward

| Option | Description |
|--------|-------------|
| `--ff` | Fast-forward when possible; create merge commit only when necessary (default) |
| `--no-ff` | Always create a merge commit, even when fast-forward is possible |
| `--ff-only` | Abort (exit non-zero) if fast-forward is not possible — refuses to merge |

```bash
git pull --ff-only origin main
```

`--ff-only` is the safest option for keeping a linear history while avoiding accidental merge commits.

### `--squash`

Squash all fetched changes into a single change in the working tree and index, but **do not commit**. You commit manually:

```bash
git pull --squash origin main
git commit -m "squashed merge of origin/main"
```

No merge commit is created and no parent relationship is recorded. The fetched commits are collapsed into a single working tree change.

### `--autostash`

Automatically stash local changes before pulling, then pop the stash afterwards:

```bash
git pull --autostash
```

If your working tree is dirty (uncommitted changes), `--autostash` saves them, performs the pull, then restores them. Without this flag, a dirty working tree causes Git to abort the pull.

### `--no-commit`

Perform the merge but **do not auto-commit**. Lets you inspect the result and modify before committing:

```bash
git pull --no-commit origin main
# inspect, perhaps make changes
git commit
```

### `--verify` / `--no-verify`

Control whether commit-msg and pre-merge-commit hooks run:

```bash
git pull --no-verify
```

`--verify` is the default. `--no-verify` bypasses hooks.

---

## Strategies

### `-s <strategy>` (or `--strategy`)

Pass a merge strategy to the underlying merge:

```bash
git pull -s recursive origin main
git pull -s ours origin main
git pull -s octopus origin main feature-b
```

Available strategies: `recursive` (default for two heads), `resolve`, `octopus` (for multiple heads), `ours`, `subtree`.

### `-X <option>` (or `--strategy-option`)

Pass strategy-specific options through to the merge:

```bash
git pull -X theirs origin main       # Favor their changes on conflict
git pull -X patience origin main     # Use patience diff algorithm
git pull -X ignore-space-change origin main
```

Common `-X` options for the `recursive` strategy:

| Option | Effect |
|--------|--------|
| `ours` | Favor our side on conflicts |
| `theirs` | Favor their side on conflicts |
| `patience` | Use patience diff algorithm (better for complex diffs) |
| `diff-algorithm=histogram` | Use histogram diff algorithm |
| `ignore-space-change` | Ignore whitespace changes |
| `ignore-all-space` | Ignore all whitespace |
| `renormalize` | Re-normalize line endings before merge |
| `no-renames` | Turn off rename detection |
| `find-renames=<n>` | Set rename threshold |

---

## Depth

### `--depth=<depth>`

Limit the fetch to a given number of commits from the tip. Shallowens the history:

```bash
git pull --depth 5 origin main
```

Only the last 5 commits of `origin/main` are fetched. The local branch is updated to match.

### `--shallow-since=<date>`

Fetch commits more recent than a date:

```bash
git pull --shallow-since="2025-01-01" origin main
```

### `--unshallow`

Convert a shallow repository to a full one by fetching all history:

```bash
git pull --unshallow origin main
```

If the repo is not shallow, this is a no-op. Equivalent to `git fetch --unshallow` then merge.

---

## Verbosity

| Option | Description |
|--------|-------------|
| `-v` (or `--verbose`) | Show more detail during fetch and merge |
| `-q` (or `--quiet`) | Suppress all non-error output |

```bash
git pull -v origin main   # Verbose
git pull -q origin main   # Quiet — useful in scripts
```

---

## Configuration

### `pull.ff`

Control the default fast-forward behavior:

```bash
git config pull.ff true       # --ff (default)
git config pull.ff false      # --no-ff (always merge commit)
git config pull.ff only       # --ff-only (fail if not fast-forward)
```

### `pull.rebase`

As described above. Values:

| Value | Effect |
|-------|--------|
| `false` | Merge (default) |
| `true` | Rebase |
| `merges` | Rebase preserving merge commits |
| `interactive` | Interactive rebase |
| `yes` | Alias for `true` |

### `pull.twohead`

Set the default merge strategy for two-head merges:

```bash
git config pull.twohead recursive
```

### `pull.octopus`

Set the default merge strategy for octopus merges (more than two heads):

```bash
git config pull.octopus octopus
```

---

## Autostash

The `--autostash` flag handles the common problem of wanting to pull but having uncommitted changes:

```bash
# Dirty working tree — uncommitted changes in progress
git pull --autostash origin main
```

What happens internally:

1. `git stash` — saves uncommitted changes to the stash
2. `git fetch` + `git merge`/`git rebase` — the actual pull
3. `git stash pop` — restores your uncommitted changes

**Without** `--autostash`:

```
error: Your local changes to the following files would be overwritten by merge:
    src/main.py
Please commit your changes or stash them before you merge.
Aborting
```

To make `--autostash` the default:

```bash
git config pull.autostash true
```

---

## Quick Reference

```bash
# Basic pulls
git pull                                         # Default (fetch + merge current branch)
git pull origin main                             # Pull explicit remote/branch
git pull --rebase                                # Fetch + rebase instead of merge
git pull --rebase=interactive                    # Fetch + interactive rebase
git pull -i                                      # Short alias for --rebase=interactive

# Fast-forward control
git pull --ff origin main                        # Fast-forward if possible (default)
git pull --no-ff origin main                     # Always create merge commit
git pull --ff-only origin main                   # Fail if not fast-forward

# Merge behavior
git pull --squash origin main                    # Squash fetched changes, don't commit
git pull --no-commit origin main                 # Merge but don't commit
git pull --no-verify origin main                 # Skip hooks

# Strategies
git pull -s recursive origin main                # Explicit merge strategy
git pull -X theirs origin main                   # Favor their changes
git pull -X ours origin main                     # Favor our changes

# Dirty working tree
git pull --autostash origin main                 # Stash, pull, pop

# Shallow operations
git pull --depth 1 origin main                   # Shallow fetch + merge
git pull --depth 10 origin main                  # Fetch last 10 commits only
git pull --shallow-since="2025-01-01" origin main
git pull --unshallow origin main                 # Full history

# Verbosity
git pull -v origin main                          # Verbose
git pull -q origin main                          # Quiet

# Multiple refspecs
git pull origin main feature                     # Fetch and merge multiple branches
git pull origin main:production                  # Fetch main, merge into production

# All remotes
git pull --all                                   # Pull from all remotes

# Combined
git pull --rebase --autostash origin main        # Rebase + autostash (most common combo)
git pull --no-ff --no-commit origin main         # Merge with no commit
git pull --ff-only --rebase origin main          # Ignored: --ff-only wins over --rebase
```

---

## Real-World Examples

### `git pull origin main`

```bash
git pull origin main
```

Fetch `main` from `origin` and merge into the current branch. The most common explicit pull — updates your branch with the latest from the mainline.

### `git pull --rebase origin feature`

```bash
git pull --rebase origin feature
```

Rebase your local commits in the `feature` branch on top of the latest `origin/feature`. Keeps history linear and avoids merge bubbles.

### `git pull --rebase=interactive`

```bash
git pull --rebase=interactive origin main
```

Interactive rebase during pull. Opens a todo list in your editor where you can:

- `pick` — keep the commit as-is
- `reword` — change the commit message
- `edit` — stop and amend the commit
- `squash` — combine with the previous commit
- `fixup` — combine but discard message
- `drop` — remove the commit

Useful for squashing messy local commits into clean logical units before they hit the shared branch.

### `git pull --ff-only`

```bash
git pull --ff-only origin main
```

Only update if fast-forward is possible. If your local branch has diverged, Git aborts with:

```
fatal: Not possible to fast-forward, aborting.
```

Ideal for branches that should never diverge (e.g., `main` after a rebase workflow).

### `git pull --autostash`

```bash
git pull --autostash origin main
```

You have uncommitted work-in-progress but need to pull without committing. Git stashes your changes, pulls, then restores them:

```
Saved working directory and index state WIP on main: abc1234 ...
Auto-merging src/main.py
On branch main
Your branch is up to date with 'origin/main'.
Dropped refs/stash@{0} (abc1234...)
```

### `git pull --no-ff --no-commit`

```bash
git pull --no-ff --no-commit origin main
```

Force a merge commit, but stop before committing. Allows you to:

- Inspect the merge result
- Run tests before finalizing
- Add additional changes to the merge commit
- Manually commit with a custom message

```bash
git pull --no-ff --no-commit origin main
# Run tests, inspect conflicts
git commit -m "integration: merge main into feature with review"
```

### `git pull --squash`

```bash
git pull --squash origin main
```

All fetched changes from `origin/main` are applied as a single working tree and index change. Nothing is committed:

```
Squash commit -- not updating HEAD
Automatic merge went well; stopped before committing as requested
```

Then commit manually:

```bash
git commit -m "feat: integrate latest mainline changes"
```

The resulting commit has **no parent link** to the fetched branch — it's an orphan of the merge graph.

### `git pull origin main:production`

```bash
git pull origin main:production
```

Fetch `main` from `origin`, then merge it into your local `production` branch. The refspec `main:production` means "fetch origin/main, write it to refs/heads/production."

### `git pull --all`

```bash
git pull --all
```

Pull from **all** remotes defined in the repository. Each remote's default branch for the current local branch is fetched and merged.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git pull` shows "Already up to date" but teammate pushed new commits | You didn't fetch — check `git remote -v` or the remote changed | `git fetch --all` first, or pull explicitly: `git pull origin main` |
| Local changes would be overwritten by merge | Uncommitted changes conflict with incoming changes | Use `git pull --autostash` or commit/stash before pulling |
| "Not possible to fast-forward, aborting" | `--ff-only` and local branch has diverged from remote | Use `git pull --rebase` or `git pull` (with merge) |
| "You are not currently on a branch" | HEAD is detached — can't pull | `git switch <branch>` or `git checkout -b <branch>` first |
| Pull introduces a messy merge commit you didn't want | Default merge behavior when local and remote have diverged | Use `git pull --rebase` to keep history linear |
| Conflict during `--rebase` pull | One or more local commits conflict with upstream changes | Resolve conflicts, `git add <files>`, `git rebase --continue` |
| Forgot `--autostash` and pull was aborted | Dirty working tree caused the pull to fail | `git stash && git pull && git stash pop` — or set `pull.autostash true` |
| `git pull --all` pulled from wrong remote | Multiple remotes defined and the current branch tracks a specific one | Use explicit `git pull <remote> <branch>` |
| "Pull is not possible because you have unmerged files" | Previous merge/rebase left unresolved conflicts | `git status` to find conflicted files, resolve them, then `git add` + `git commit` or `git rebase --continue` |
| `git pull --rebase` rewrote my commits with new hashes | Rebase replays commits — history is rewritten | This is expected. Never force-push after rebasing shared branches |
| Deep shallow clone + pull creates confusion | `--depth` limits fetch to N commits | Use `--unshallow` to deepen, or increase `--depth` value |

(End of file - total 379 lines)
