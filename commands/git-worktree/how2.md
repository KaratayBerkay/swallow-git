# `git worktree` — Manage multiple working trees attached to the same repository

`git worktree` lets you check out multiple branches at the same time in separate directories, all sharing the same Git repository. Each worktree has its own working tree and index, so you can work on different branches in parallel without stashing, cloning, or switching back and forth.

```
git worktree add [-f] [--detach] [--checkout] [--lock] [-b <new-branch>] <path> [<commit-ish>]
git worktree list [--porcelain]
git worktree lock [--reason <string>] <worktree>
git worktree move <worktree> <new-path>
git worktree prune [-n] [-v] [--expire <expire>]
git worktree remove [-f] <worktree>
git worktree repair [<path>...]
git worktree unlock <worktree>
```

---

## Description

A Git repository normally has one working tree (the directory where you edit files). `git worktree` allows you to create **additional** working trees attached to the same repository. Each worktree:

- Has its own working directory and index (staging area)
- Points to a different branch (or a detached commit)
- Shares the repository's object database, refs, and config
- Can be added, listed, locked, moved, pruned, or removed independently

```
                ┌──────────────────────┐
                │  .git/ (shared)      │
                │  objects, refs, config│
                └──────┬───────────────┘
                       │
          ┌────────────┼──────────────┐
          │            │              │
  ┌───────▼──────┐ ┌──▼───────┐ ┌────▼───────┐
  │ main/        │ │ hotfix/  │ │ feature/   │
  │ (main branch)│ │ (hotfix) │ │ (feature)  │
  │ index A      │ │ index B  │ │ index C    │
  └──────────────┘ └──────────┘ └────────────┘
```

---

## Add

### `git worktree add <path> [<branch>]`

Create a new worktree at `<path>` and check out `<branch>` (or create a new branch if `-b` is given):

```bash
git worktree add ../project-feature feature
```

If `<branch>` doesn't exist and `-b` is not given, Git creates a branch named after the last component of `<path>`:

```bash
git worktree add ../hotfix           # Creates and checks out branch "hotfix"
```

### `-b <new-branch>` — Create a new branch

Create and check out a new branch in the new worktree:

```bash
git worktree add -b feature-xyz ../feature feature-xyz
```

This is equivalent to:
```bash
git branch feature-xyz
git worktree add ../feature feature-xyz
```

### `--detach` — Check out a specific commit in detached HEAD

Check out a specific commit (or tag, or remote branch) in detached HEAD state:

```bash
git worktree add --detach ../experiment HEAD~3
git worktree add --detach ../archive v1.0.0
```

Useful for inspecting old commits without affecting any branch.

### `-f` (or `--force`) — Override safety checks

Force creation even if `<branch>` is already checked out elsewhere or `<path>` is not empty:

```bash
git worktree add -f ../emergency-fix main
```

### `--checkout` / `--no-checkout`

By default, Git checks out the branch contents. Use `--no-checkout` to skip this (creates an empty worktree — you can manually check out files later):

```bash
git worktree add --no-checkout ../empty-worktree feature
```

### `--lock` — Lock immediately on creation

Prevent the worktree from being pruned:

```bash
git worktree add --lock ../critical-worktree main
```

---

## List

### `git worktree list`

Show all worktrees attached to this repository:

```bash
git worktree list
```

Output:
```
/home/user/project          abc1234 [main]
/home/user/project/hotfix   def5678 [hotfix]
/home/user/project/feature  123abcd [feature]
```

Each line shows: path, HEAD commit, and the current branch (in `[brackets]`) or `(detached HEAD)`.

### `--porcelain`

Machine-readable output, one attribute per line:

```bash
git worktree list --porcelain
```

Output:
```
worktree /home/user/project
HEAD abc1234...
branch refs/heads/main

worktree /home/user/project/hotfix
HEAD def5678...
branch refs/heads/hotfix

worktree /home/user/project/feature
HEAD 123abcd...
detached
```

Useful for scripting and tooling.

### `--verbose`

Show additional details (prunable status, lock reason):

```bash
git worktree list --verbose
```

---

## Lock / Unlock

Locking prevents a worktree from being pruned or removed. Useful when you have a long-running task on a worktree.

### `git worktree lock <worktree>`

```bash
git worktree lock ../hotfix
```

### `--reason <string>`

Attach a reason to the lock (shown in `list --verbose`):

```bash
git worktree lock ../hotfix --reason "Hotfix in progress, deployed to staging"
```

### `git worktree unlock <worktree>`

```bash
git worktree unlock ../hotfix
```

Locked worktrees are displayed with `(locked)` in `git worktree list`:

```
/home/user/project/hotfix    def5678 [hotfix] (locked)
```

---

## Move

### `git worktree move <worktree> <new-path>`

Move a worktree to a new location:

```bash
git worktree move ../feature ../moved-feature
```

This:
1. Moves the working directory to `../moved-feature`
2. Updates the administrative files in `.git/worktrees/`
3. Creates a symlink from the old path (if `workstations`) or records the new path

After moving, you can continue working with the new path.

---

## Remove

### `git worktree remove <worktree>`

Remove a worktree. Refuses if the worktree has uncommitted changes or untracked files:

```bash
git worktree remove ../old-feature
```

### `-f` (or `--force`) — Force removal

Remove even if the worktree has changes:

```bash
git worktree remove -f ../abandoned-experiment
```

Only the worktree's working directory and administrative files are removed. The repository and its branches remain intact.

---

## Prune

### `git worktree prune`

Clean up stale administrative files for worktrees whose working directories no longer exist:

```bash
git worktree prune
```

If you delete a worktree directory manually (e.g., `rm -rf ../hotfix`), the administrative data in `.git/worktrees/` becomes stale. `git worktree prune` detects and removes these stale entries.

### `-n` (or `--dry-run`) — Show what would be pruned

```bash
git worktree prune -n
```

### `-v` (or `--verbose`) — Verbose output

```bash
git worktree prune -v
```

### `--expire <expire>` — Prune only older than

Only prune worktrees with stale data older than a specified duration:

```bash
git worktree prune --expire=30.days
git worktree prune --expire="2025-01-01 00:00:00"
```

---

## Repair

### `git worktree repair [<path>...]`

Fix broken worktree administrative files. This is useful after:
- Moving the main repository to a new location
- Moving a worktree directory without using `git worktree move`
- Restoring from backup

```bash
git worktree repair
git worktree repair ../broken-worktree
git worktree repair ../broken-worktree ../another-broken-worktree
```

`git worktree repair` updates the worktree's `.git` file to point to the correct repository location.

---

## Quick Reference

```bash
# Add a new worktree
git worktree add ../hotfix hotfix                            # Create + checkout branch
git worktree add -b feature-xyz ../feature feature-xyz       # Create with new branch name
git worktree add --detach ../experiment HEAD~3               # Detached HEAD at commit
git worktree add -f ../emergency-fix main                    # Force (branch already checked out)
git worktree add --lock ../deploy-release v1.0               # Lock immediately

# List all worktrees
git worktree list                                            # Human-readable
git worktree list --porcelain                                # Machine-readable
git worktree list --verbose                                  # With lock/prune details

# Lock (prevent pruning/removal)
git worktree lock ../hotfix                                  # Basic lock
git worktree lock ../hotfix --reason "Active work"           # Lock with reason

# Move to new location
git worktree move ../feature ../moved-feature

# Remove
git worktree remove ../old-feature                           # Safe remove
git worktree remove -f ../abandoned                          # Force remove

# Prune stale admin entries
git worktree prune                                           # Clean stale refs
git worktree prune -n                                        # Dry-run
git worktree prune --expire=30.days                          # Only prune old entries

# Repair broken links
git worktree repair                                          # Fix all
git worktree repair ../broken-worktree                       # Fix specific

# Unlock
git worktree unlock ../hotfix                                # Release lock
```

---

## Real-World Examples

```bash
# Work on a hotfix while keeping your feature branch active
git worktree add ../hotfix hotfix
# ... work on urgent fix in ../hotfix ...
# ... main worktree is undisturbed

# Create a worktree for a new feature with a specific branch name
git worktree add -b feature-xyz ../feature feature-xyz

# Inspect an old commit (detached HEAD) without affecting any branch
git worktree add --detach ../experiment HEAD~3

# List all active worktrees
git worktree list

# Remove a worktree that is no longer needed
git worktree remove ../old-feature

# Lock a worktree to prevent accidental pruning during active work
git worktree lock ../hotfix --reason "Hotfix in progress"

# Prune stale administrative entries after manually deleting a worktree
git worktree prune

# Move a worktree to a better directory location
git worktree move ../feature ../moved-feature

# Repair a worktree after the main repo was moved
git worktree repair ../broken-worktree
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git worktree add` fails because branch is already checked out | A branch can only be checked out in one worktree at a time | Use `-f` to force, or check out a different branch in the existing worktree |
| Manually deleted a worktree directory | Removed via `rm -rf` instead of `git worktree remove` | Run `git worktree prune` to clean up stale administrative files |
| `git worktree remove` refuses with uncommitted changes | Safety check — you might lose work | Commit, stash, or use `-f` to force removal |
| Forgot which worktree is on which branch | Multiple worktrees, lost track | Use `git worktree list` to see the mapping |
| Worktree broken after moving the main repository | The worktree's `.git` file points to an old path | Run `git worktree repair` to fix the links |
| Cannot remove a locked worktree | Lock prevents accidental removal | `git worktree unlock <worktree>` first, then remove |
| Branch name created from path was unexpected | `git worktree add ../path` auto-creates branch `path` | Use `-b <name>` to explicitly set the branch name |
| Worktree thinks it's in a detached HEAD | Checked out a commit/tag instead of a branch | Use `git worktree add -b <branch> <path> <start-point>` instead |
| `git fetch` doesn't update worktree branches | Fetch updates refs but doesn't check out new commits | Each worktree needs `git pull` or `git merge` independently |
| Worktree shows wrong branch after adding `-b` | The `-b` flag creates but the next arg is the `<path>`, not the branch | Syntax is `-b <new-branch> <path> [<commit-ish>]` — not `<path> -b <branch>` |

---

## Visual Summary

```
Initial repo with one worktree:

    .git/ ─── main worktree (./project) ─── main branch

Adding worktrees:

    .git/ ─── main worktree (./project)   ─── main
           │
           ├── worktree 2 (./hotfix)       ─── hotfix
           │
           └── worktree 3 (./feature)     ─── feature-xyz

Anatomy of a worktree:

    /home/user/project/hotfix/
    ├── .git                        # File pointing to main repo: gitdir: /home/user/project/.git/worktrees/hotfix
    ├── src/
    ├── tests/
    └── ...

    /home/user/project/.git/worktrees/hotfix/
    ├── gitdir                      # Points back to worktree
    ├── HEAD                        # Current ref of this worktree
    ├── index                       # Staging area (separate from other worktrees)
    ├── commondir                   # Points to main repo's .git
    ├── locked                      # (present only if locked)
    └── refs/                       # Worktree-specific refs

Lock lifecycle:

    Created ─── Locked ─── Unlocked ─── Removed
                                 │
                            (prune skipped when locked)
```
