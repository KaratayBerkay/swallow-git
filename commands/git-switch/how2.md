# `git switch` — Switch branches

`git switch` switches to a specified branch, updating the working tree and index to match. Introduced in Git 2.23 as part of splitting `git checkout` into focused commands (`git switch` for branches, `git restore` for files). It is the modern, safer way to change branches.

```
git switch [<options>] [<branch>]
git switch [<options>] -c <new-branch> [<start-point>]
git switch [<options>] --detach [<start-point>]
```

## Description

`git switch` changes the current branch (updates `HEAD`, the working tree, and the index to match the target branch). Unlike `git checkout`, it does **one thing** — switch branches — and refuses to do file-level operations (use `git restore` for those).

It replaces the branch-switching overload of `git checkout`:
- `git checkout <branch>` → `git switch <branch>`
- `git checkout -b <branch>` → `git switch -c <branch>`
- `git checkout --detach <commit>` → `git switch --detach <commit>`

---

## Basic Usage

### `git switch <branch>` — Switch to an existing branch

```bash
git switch main
git switch feature-x
```

Fails if the branch doesn't exist, or if there are local changes that would be overwritten (unless `--discard-changes` or `-m` is used).

### `git switch -c <branch>` — Create and switch

Create a new branch and switch to it in one step (replaces `git checkout -b`):

```bash
git switch -c feature-x
git switch -c bugfix main          # create from main
git switch -c experiment HEAD~3    # create from 3 commits ago
```

### `git switch -` — Switch to previous branch

Return to the previously checked-out branch (like `cd -`):

```bash
git switch -
```

Git remembers the previous branch/commit in `HEAD@{1}`. Works across any switch.

---

## Create Branch

### `-c` (or `--create`) — Create and switch

```bash
git switch -c feature-xyz
git switch -c feature-xyz origin/main
```

Creates a new branch starting from `HEAD` (or `<start-point>` if given) and switches to it.

### `-C` (or `--force-create`) — Force create

Like `-c`, but **overwrites** the branch if it already exists (resets it to the start point):

```bash
git switch -C feature-xyz          # reset if exists, create if not
git switch -C feature-xyz main
```

### `--guess` — Guess branch name

When the branch name doesn't exist locally, try to find a matching remote-tracking branch and create a local branch tracking it:

```bash
git switch feature-xyz
# branch 'feature-xyz' set up to track 'origin/feature-xyz'.
```

This is the default behavior. Disable with `--no-guess`. The guess also works across remotes — it checks each remote in order.

---

## Detach

### `--detach` — Detached HEAD state

Switch to a commit without a branch. `HEAD` points directly to the commit rather than a branch reference:

```bash
git switch --detach HEAD~3
git switch --detach main
git switch --detach abc1234
```

In detached HEAD state:
- Any commits made are **not** on a branch
- Switching away loses them (unless you create a branch first)
- Use `git switch -c <name>` to save work done in detached state

Detached HEAD is useful for:
- Inspecting an old commit
- Experimenting without affecting a branch
- Checking out a tag for release validation

---

## Discard Changes

### `--discard-changes` — Force switch discarding local changes

Switch branches even if the working tree or index differs from `HEAD`. **Local changes are lost**:

```bash
git switch --discard-changes main
git switch --discard-changes -c new-branch
```

Without this flag, Git refuses to switch if it would overwrite dirty files. The flag matches `git checkout --force` behavior but with a clearer name.

---

## Merge

### `-m` (or `--merge`) — Three-way merge local changes

Switch branches while performing a three-way merge between:
1. The current branch's state
2. The working tree changes
3. The target branch

```bash
git switch -m feature
```

If you have local modifications that conflict with the target branch, Git attempts a merge. Unmerged conflicts are left for you to resolve. This is equivalent to `git checkout -m`.

---

## Recurse

### `--recurse-submodules`

Update submodules to match the commit recorded in the superproject at the target branch:

```bash
git switch --recurse-submodules feature
git switch --recurse-submodules main
```

Without this flag, submodules remain at whatever commit they were on (detached HEAD in submodules).

---

## Progress

### `--progress` / `--no-progress`

Control progress reporting during the switch:

```bash
git switch --progress feature     # show progress (default on terminals)
git switch --no-progress main     # suppress progress
```

Git auto-detects whether output is a terminal. `--progress` forces it on; `--no-progress` forces it off.

---

## Config

### `switch.overWrite`

Controls whether `git switch` overwrites dirty worktree changes when switching branches. Like `checkout.overwrite` for the old `git checkout`:

```ini
[switch]
    overWrite = false              # refuse to switch if dirty (default behavior)
    overWrite = true               # allow overwriting dirty changes
```

When `switch.overWrite` is `false` (default), Git refuses to switch branches if there are local changes that would be lost. Set to `true` to always allow.

Other related configuration:

```ini
# Guess remote branch names (like --guess)
[gui]
    guessTrackedBranch = false     # disable automatic remote guessing
```

---

## Comparison: `git switch` vs `git checkout` vs `git restore`

| Task | Old way | New way |
|------|---------|---------|
| Switch to a branch | `git checkout <branch>` | `git switch <branch>` |
| Create + switch | `git checkout -b <name>` | `git switch -c <name>` |
| Force switch | `git checkout -f <branch>` | `git switch --discard-changes <branch>` |
| Detached HEAD | `git checkout --detach <commit>` | `git switch --detach <commit>` |
| Merge on switch | `git checkout -m <branch>` | `git switch -m <branch>` |
| Previous branch | `git checkout -` | `git switch -` |
| Discard file changes | `git checkout -- <file>` | `git restore <file>` |
| Unstage a file | `git checkout HEAD -- <file>` | `git restore --staged <file>` |

**Key differences:**

| Behavior | `git switch` | `git checkout` | `git restore` |
|----------|--------------|----------------|---------------|
| Switches branches | Yes | Yes | No |
| Restores files | No | Yes | Yes |
| Creates branches | Yes (`-c`/`-C`) | Yes (`-b`/`-B`) | No |
| Detached HEAD | Yes (`--detach`) | Yes (auto) | No |
| Merges on switch | Yes (`-m`) | Yes (`-m`) | No |
| Multiple remotes guess | Yes | Yes | No |

**When to use which:**

- `git switch` — change branches (the focused, safe option)
- `git checkout` — legacy command; prefer `git switch` + `git restore`
- `git restore` — undo file-level changes (unstage, discard, or both)

---

## Quick Reference

```bash
# Switch to a branch
git switch main                      # switch to main
git switch feature                   # switch to feature
git switch -                         # switch to previous branch

# Create and switch
git switch -c feature-xyz           # create + switch (from HEAD)
git switch -c bugfix main           # create from main + switch
git switch -C feature-xyz           # force create (overwrites if exists)

# Detached HEAD
git switch --detach HEAD~3          # inspect older commit
git switch --detach v1.0            # inspect a tag
git switch --detach main            # switch to branch tip, detached

# Force and merge
git switch --discard-changes main   # discard local changes, switch
git switch -m feature               # merge local changes into new branch

# Options
git switch --no-guess feature       # disable remote guessing
git switch --recurse-submodules     # update submodules
git switch --progress               # show progress
git switch --no-progress            # suppress progress
```

---

## Real-World Examples

### Switch to main

```bash
git switch main
```

The most common operation — return to the main development branch.

### Create a new feature branch

```bash
git switch -c feature-xyz
```

Start working on a new feature. Creates the branch at `HEAD` and switches to it.

### Create a bugfix branch from a remote

```bash
git switch -c bugfix/123 origin/main
```

Create a local `bugfix/123` branch starting from the tip of `origin/main`, and switch to it.

### Go back to the previous branch

```bash
git switch -
```

Quickly toggle between two branches (e.g., `main` and a feature branch). Equivalent to `cd -` for branches.

### Inspect an older commit

```bash
git switch --detach HEAD~3
```

Enter detached HEAD to inspect the state of the project three commits ago. To return: `git switch main`.

### Merge local changes into a new branch

```bash
git switch -m feature
```

You have uncommitted changes on `main` but need to switch to `feature`. Git performs a three-way merge to carry those changes over instead of discarding them.

### Discard local modifications

```bash
git switch --discard-changes main
```

You have dirty files and want to abandon them entirely. Git forces the switch, discarding all local changes. **These changes are lost.**

### Force re-create a branch

```bash
git switch -C feature
```

Reset `feature` to `HEAD` and switch to it, even if `feature` already exists. The old `feature` branch pointer is overwritten.

### Switch with submodules

```bash
git switch --recurse-submodules main
```

Switch to `main` and update all submodules to the commits recorded in the superproject.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git switch` refuses with "local changes would be overwritten" | Dirty files conflict with the target branch | Commit or stash first, or use `-m` (merge) or `--discard-changes` (lose them) |
| `git switch` says "not a valid ref" | Branch name doesn't exist | Check `git branch --list` or `git branch -a`. Use full or partial name. Try `--guess` |
| Switched but submodules are out of sync | Submodules are not updated by default | Use `git switch --recurse-submodules` or `git submodule update --recursive` |
| Lost work done in detached HEAD | Detached HEAD has no branch — switching away discards commits | Create a branch first: `git switch -c my-branch` before switching away |
| `git switch -c <name>` fails with "fatal: a branch named already exists" | Name collision | Use `-C` to force overwrite, or `git branch -d <name>` first |
| `git switch -` doesn't go where expected | Previous branch might have been deleted or reset | Check `git reflog` or `git log -g` to see HEAD history |
| Forgot `--detach` when checking out a non-branch | `git switch <commit>` expects a branch name | Use `git switch --detach <commit>` or `git checkout <commit>` (auto-detaches) |
| `git switch -m` left merge conflicts | Local changes conflicted with the target branch | Resolve conflicts as with any merge, then commit |
| `git switch` with `--discard-changes` lost important modifications | Force switch discards everything without warning | Use `git stash` first if unsure, then `git switch` clean |
| Guessed wrong remote branch with `--guess` | Multiple remotes have similarly named branches | Use explicit remote: `git switch -c <name> <remote>/<name>` |
