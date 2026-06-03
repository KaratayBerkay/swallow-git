# `git rebase` — Reapply commits on top of another base tip

`git rebase` takes a set of commits and replays them onto a new base. It is a core tool for maintaining a clean, linear project history — instead of merge commits, you rewrite your branch as if it started from the latest state of the target branch.

```
git rebase [-i] [<options>] [--exec <cmd>] [--onto <newbase>] [<upstream> [<branch>]]
git rebase [-i] [<options>] [--exec <cmd>] [--onto <newbase>] --root [<branch>]
git rebase (--continue | --skip | --abort | --quit | --edit-todo | --show-current-patch)
```

## Description

`git rebase` replays commits from the current branch (or `<branch>`) onto `<upstream>` (or `<newbase>` with `--onto`). Instead of a merge commit that ties two histories together, rebase rewrites the commit DAG — each replayed commit is a **new** commit object with a new hash.

The rebase process:
1. Identifies commits to move (those reachable from HEAD but not from `<upstream>`)
2. Saves them as patches
3. Resets HEAD to `<upstream>` (or `<newbase>`)
4. Applies each patch in order, stopping on conflicts

Because history is rewritten, **never rebase commits that exist on a shared branch** — anyone who has pulled the old history will have a divergent repository.

---

## Basic Usage

### `git rebase main`

Rebase the current branch onto `main`. All commits in the current branch that are not in `main` are replayed on top of `main`'s tip:

```bash
git checkout feature
git rebase main
```

```
Before:       After:
  main          main
    |            |
    A──B──C     A──B──C
         |            |
         D──E         D'──E'
  feature       feature
```

### `git rebase main feature`

Check out `feature`, then rebase it onto `main`:

```bash
git rebase main feature
```

Equivalent to:
```bash
git checkout feature
git rebase main
```

---

## `--onto` — Rebase onto an arbitrary base

`--onto` allows you to replay commits from a different starting point. The syntax is:

```
git rebase --onto <newbase> <upstream> [<branch>]
```

This takes commits from `<upstream>..<branch>` and replays them onto `<newbase>`.

```bash
# Before:          After:
#   main            main
#    |               |
#    A──B──C        A──B──C──D'──E'
#         |                  |
#         D──E──F──G         F'──G'
#             |              |
#             F──G           feature
#             |
#           feature
git rebase --onto main feature~2 feature
```

**Use case**: Extract a feature branch that was accidentally based on another feature branch and rebase it directly onto `main`.

```bash
# Move last 3 commits from feature to a new branch off main
git rebase --onto main feature~3 feature
```

---

## Interactive Rebase (`-i`)

Interactive rebase opens a **todo list** in your editor, listing every commit that will be replayed. You can reorder, squash, edit, reword, skip, or split commits.

```bash
git rebase -i HEAD~5     # Rebase last 5 commits
git rebase -i main       # Rebase all commits since diverging from main
git rebase -i --root     # Rebase every commit from the initial commit
```

### Todo list actions

Each line in the todo list starts with a command:

| Command | Short | Effect |
|---------|-------|--------|
| `pick` | `p` | Use the commit as-is |
| `reword` | `r` | Use commit, but edit the message |
| `edit` | `e` | Use commit, but stop to amend |
| `squash` | `s` | Merge into the previous commit, combine messages |
| `fixup` | `f` | Merge into the previous commit, discard this message |
| `drop` | `d` | Remove the commit entirely |
| `exec` | `x` | Run a shell command (the rest of the line) |
| `break` | `b` | Stop here (for `git rebase --continue`) |
| `label` | `l` | Label current HEAD with a name |
| `reset` | `t` | Reset HEAD to a label |
| `merge` | `m` | Create a merge commit |

### Fixup and squash workflow

```bash
git rebase -i HEAD~3
```

Opens editor with:

```
pick a1b2c3d feat: add search bar
pick e5f6g7a fix: correct search pagination
pick h8i9j0k chore: bump lodash

# Rebase a1b2c3d..h8i9j0k onto a1b2c3d (3 commands)
```

To combine `fix` into the previous commit, change `pick` to `fixup`:

```
pick a1b2c3d feat: add search bar
fixup e5f6g7a fix: correct search pagination
pick h8i9j0k chore: bump lodash
```

### Edit — split or amend a commit

Mark a commit as `edit`:

```
pick a1b2c3d feat: add search bar
edit e5f6g7a fix: correct search pagination
pick h8i9j0k chore: bump lodash
```

When Git stops at `e5f6g7a`:

```bash
# Make changes
git add .
git commit --amend -m "fix: better message"
git rebase --continue
```

### Reword — change commit message

```
pick a1b2c3d feat: add search bar
reword e5f6g7a fix: correct search pagination
pick h8i9j0k chore: bump lodash
```

Git opens an editor for `e5f6g7a`'s message.

### Exec — run a command for each commit

```
pick a1b2c3d feat: add search bar
exec npm test
pick e5f6g7a fix: correct search pagination
exec npm test
```

Or from the command line:

```bash
git rebase -i --exec "npm test" main
```

### Break — pause the rebase

```
pick a1b2c3d feat: add search bar
break
pick e5f6g7a fix: correct search pagination
```

`break` stops the rebase so you can inspect the state, run tests, etc. Continue with `git rebase --continue`.

### Reorder commits

Simply rearrange the lines in the todo list:

```
pick h8i9j0k chore: bump lodash
pick a1b2c3d feat: add search bar
pick e5f6g7a fix: correct search pagination
```

Git will replay them in the new order. Conflicts may occur if commits touch the same lines.

---

## Autosquash (`--autosquash`)

Automatically arrange fixup and squash commits in the correct position during interactive rebase.

```bash
# Create a normal commit
git commit -m "feat: add search bar"

# Later, create fixup commits referencing it
git commit --fixup HEAD                # message: "fixup! feat: add search bar"
git commit --squash HEAD~1             # message: "squash! feat: add search bar"

# Rebase with autosquash
git rebase -i --autosquash main
```

Git reorders the todo list automatically:

```
pick a1b2c3d feat: add search bar
fixup d4e5f6g fixup! feat: add search bar
squash g7h8i9j squash! feat: add search bar
pick e5f6g7a fix: correct search pagination
```

Enable by default:

```bash
git config rebase.autoSquash true
```

---

## Options Reference

### Control commands (rebase in progress)

| Option | Effect |
|--------|--------|
| `--continue` | After resolving conflicts, continue the rebase |
| `--skip` | Skip the current commit (discard it) |
| `--abort` | Abort the rebase and restore the original state |
| `--quit` | Quit the rebase but keep the working tree as-is |
| `--edit-todo` | Edit the remaining todo list during a paused rebase |
| `--show-current-patch` | Show the current patch being applied |

```bash
# Resolve conflicts, stage, then continue
git add src/conflict.js
git rebase --continue

# Skip the problematic commit entirely
git rebase --skip

# Give up and go back to pre-rebase state
git rebase --abort

# Quit but stay at current position (for manual resolution later)
git rebase --quit

# Change the remaining todo list mid-rebase
git rebase --edit-todo

# View the patch that's causing the conflict
git rebase --show-current-patch
```

### Timestamp options

| Option | Effect |
|--------|--------|
| `--ignore-date` | Use the current timestamp instead of the original author date (author date = now) |
| `--committer-date-is-author-date` | Set the committer date to match the original author date |

```bash
# All rebased commits get the current date
git rebase --ignore-date main

# Preserve the original author date as the committer date
git rebase --committer-date-is-author-date main
```

### Advanced options

| Option | Effect |
|--------|--------|
| `--no-ff` | Create a new commit even if the rebase is a fast-forward (no replay needed) |
| `--empty=drop` | Drop commits that become empty after replay (default) |
| `--empty=keep` | Keep empty commits |
| `--empty=ask` | Ask what to do for each empty commit |
| `--rebase-merges` | Preserve merge commits in the rebased history (no flattening) |
| `--root` | Rebase all commits including the initial root commit |
| `--exec <cmd>` | Run a shell command after each commit in the resulting history |

```bash
# Force new commit objects even if nothing changed
git rebase --no-ff main

# Preserve merge topology (avoid flattening feature branch merges)
git rebase --rebase-merges main

# Rebase every commit, even the first one
git rebase -i --root

# Rebase the whole branch from the initial commit
git rebase -i --root --onto main
```

### Strategy options

| Option | Effect |
|--------|--------|
| `-s <strategy>` | Use a specific merge strategy (`recursive`, `ort`, `resolve`, `octopus`, `ours`, `subtree`) |
| `-X <option>` | Pass strategy-specific options |

```bash
# Use the ort merge strategy (default since Git 2.33)
git rebase -s ort main

# Prefer our side on conflicting hunks
git rebase -X ours main

# Use patience diff algorithm for better conflict resolution
git rebase -X patience main

# Ignore whitespace changes during rebase
git rebase -X ignore-space-change main

# Rename threshold (detect renames with 50% similarity)
git rebase -X find-renames=50 main
```

### Autostash

Automatically stash and pop the working tree before and after rebase:

```bash
git rebase --autostash main
```

```bash
# Before rebase: dirty working tree
git rebase --autostash main
# Git stashes the dirty state, rebases, then pops the stash
```

Enable by default:

```bash
git config rebase.autoStash true
```

---

## Configuration

```ini
# Automatically arrange fixup/squash commits during rebase -i
[rebase]
    autoSquash = true

# Automatically stash dirty working tree before rebasing
    autoStash = true

# Error out if rebase drops commits (warn/error/ignore)
    missingCommitsCheck = error

# If an exec command fails, automatically reschedule it
    rescheduleFailedExec = true

# Update all refs that point to rebased commits, not just HEAD
    updateRefs = true

# Default strategy for rebase
    strategy = ort
```

| Config | Values | Effect |
|--------|--------|--------|
| `rebase.autoSquash` | `true`, `false` | Automatically reorder fixup/squash commits in `-i` |
| `rebase.autoStash` | `true`, `false` | Stash/unstash dirty worktree around rebase |
| `rebase.missingCommitsCheck` | `warn`, `error`, `ignore` | Warn or error when commits are dropped from the todo list |
| `rebase.rescheduleFailedExec` | `true`, `false` | Reschedule `exec` commands that fail |
| `rebase.updateRefs` | `true`, `false` | Update all branch refs pointing to rebased commits |
| `rebase.stat` | `true`, `false` | Show diffstat after each rebase step |
| `rebase.strategy` | strategy name | Default merge strategy (`ort`, `recursive`, etc.) |
| `rebase.instructionFormat` | format string | Customize the todo list display format |

---

## Quick Reference

```bash
# Basic
git rebase main                          # Rebase current branch onto main
git rebase main feature                  # Check out feature, rebase onto main

# Onto
git rebase --onto main feature~3 feature # Move last 3 commits of feature onto main

# Interactive
git rebase -i HEAD~3                     # Rebase last 3 commits interactively
git rebase -i main                       # Rebase all commits since main

# Autosquash
git fetch origin && git rebase -i --autosquash origin/main
git rebase -i --autosquash HEAD~5

# Advanced
git rebase --onto target upstream branch # Three-arg onto form
git rebase --root                        # Rebase from root
git rebase --rebase-merges main          # Preserve merge topology
git rebase --no-ff main                  # Force new commits
git rebase --empty=keep                  # Keep empty commits
git rebase --exec "npm test" main        # Run test per commit

# Dates
git rebase --ignore-date main            # Author date = now
git rebase --committer-date-is-author-date main  # Committer date = author date

# Strategy
git rebase -s recursive -X theirs main   # Recursive strategy, prefer theirs

# Autostash
git rebase --autostash main              # Stash dirty worktree automatically

# In-progress rebase
git rebase --continue                    # Continue after conflict resolution
git rebase --skip                        # Skip current commit
git rebase --abort                       # Abort and restore original state
git rebase --quit                        # Quit but keep current state
git rebase --edit-todo                   # Edit remaining todo list
git rebase --show-current-patch          # Show patch being applied

# Config
git config rebase.autoSquash true
git config rebase.autoStash true
git config rebase.missingCommitsCheck error
git config rebase.rescheduleFailedExec true
git config rebase.updateRefs true
```

---

## Real-World Examples

### `git rebase main`

Keep a feature branch up to date with the latest `main`:

```bash
git checkout feature
git rebase main
```

Instead of merging `main` into `feature` (which creates a merge commit), rebase rewrites the feature commits on top of `main`'s tip, keeping the history linear.

### `git rebase -i HEAD~3`

Squash three WIP commits into one clean commit:

```bash
git rebase -i HEAD~3
```

In the editor, change the second and third commits from `pick` to `fixup`:

```
pick a1b2c3d WIP: start login flow
fixup d4e5f6d WIP: finish login
fixup g7h8i9j WIP: fix login tests
```

Result: one commit with the message `WIP: start login flow`.

### `git rebase --onto main feature~3 feature`

You started a feature branch from another feature branch. Now you want it on `main` instead:

```bash
# Current state:
# main ── A ── B
#             \
#              C ── D ── E ── F ── G
#                         \
#                          H ── I
#
# You want H and I on main, ignoring C-G

git rebase --onto main feature~3 feature
```

```
# Result:
# main ── A ── B ── H' ── I'
#             \
#              C ── D ── E ── F ── G
```

This replays commits `feature~3..feature` (H and I, the last 2 commits) onto `main`.

### `git rebase -i --autosquash main`

Clean up a feature branch with fixup commits:

```bash
git commit -m "feat: add user authentication"
git commit --fixup HEAD                  # fixup! feat: add user authentication
git commit --fixup HEAD~1                # fixup! feat: add user authentication
git commit -m "chore: update deps"
git rebase -i --autosquash main
```

The todo list is automatically ordered so fixup commits immediately follow their target.

### `git rebase --abort`

Conflict resolution went wrong — start over:

```bash
git rebase main
# CONFLICT in src/main.js
# ... try to resolve, make things worse ...
git rebase --abort
# Back to original state before rebase started
```

### `git rebase --continue` (after conflict resolution)

A conflict occurred during rebase. After fixing it:

```bash
git add src/resolved-file.js
git rebase --continue
# Git applies the next commit in the series
```

If you want to edit the commit message, `--continue` opens your editor.

### `git rebase --rebase-merges main`

Rebase a feature branch that has merge commits without flattening it:

```bash
# Before (feature has a merge from a sub-branch):
#   main ── A ── B
#             \
#              C ──── D ──── G
#                   /        /
#              E ── F ──────
#
# git rebase --rebase-merges main
#
# After (merge topology preserved, replayed on top of main):
#   main ── A ── B
#                \
#                 C' ──── D' ──── G'
#                       /        /
#                  E' ── F' ──────
```

Without `--rebase-merges`, a normal rebase would flatten the history into a straight line.

### `git rebase --exec "npm test" main`

Verify every commit on the feature branch passes tests:

```bash
git rebase --exec "npm test" main
```

Git rebases commits onto `main`, and after each commit runs `npm test`. If any test fails, the rebase stops so you can investigate.

### `git rebase --committer-date-is-author-date`

Preserve the original author date as the committer date during rebase:

```bash
git rebase --committer-date-is-author-date main
```

Useful when you want `git log` to display the original commit times while still being on the new base.

### `git rebase --no-ff main`

Force new commit objects even if the branch is a fast-forward:

```bash
git rebase --no-ff main
```

Even if `feature` is directly ahead of `main` (all feature commits are already ancestors of `main`), this creates new commit objects. Useful for structured workflows where every merge/rebase should produce a new commit.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Rebased a shared branch | Rewriting history someone else has pulled creates divergent repos | Use `git merge` instead of rebase for shared branches |
| Conflict on every commit during rebase | Rebase replays each commit one at a time — conflicts can repeat | Use `git merge` once instead of rebase, or `git rebase -X theirs` |
| Lost commits after a bad rebase | An interactive rebase with wrong `drop`s, or `--skip` on the wrong commit | `git reflog` to find the old commits, `git reset --hard ORIG_HEAD` or `git cherry-pick` them back |
| Forgot `git rebase --abort` before switching branches | A paused rebase leaves you in detached HEAD — switching branches is dangerous | `git rebase --abort` first, or `git checkout --ignore-skip-worktree-bits` |
| `git rebase --continue` failed but changes are already staged | Git won't continue because it detects no changes were made | Either make a real change, or `git rebase --skip` if the commit was empty |
| Autosquash didn't reorder correctly | Fixup/squash commit messages must match exactly (`fixup! <subject>`) | Check the commit message format: `git log --oneline` to verify |
| `git rebase --onto` replayed the wrong commits | The `<upstream>` argument is "upstream of what you want to move" — it's the base you're replacing | Remember: `git rebase --onto <newbase> <upstream> <branch>` replays `<upstream>..<branch>` |
| Rebase took a very long time on a large branch | Every commit is replayed independently, which can be slow | Use `git merge` instead, or rebase in smaller batches |
| Lost merge commits after rebase | Default rebase flattens history — merge commits become regular commits | Use `git rebase --rebase-merges` to preserve merges |
| Exec command failed but rebase continued anyway | `--exec` failures stop the rebase, but only if the command exits non-zero | Check your exec command exits with a proper code, or use `rebase.rescheduleFailedExec` |
| `git rebase --abort` restored a dirty working tree incorrectly | If you had staged but uncommitted changes before rebase, `--abort` may not restore them perfectly | Use `git stash` before rebasing, or `git rebase --autostash` |

---

## Visual Summary

```
Standard rebase:
  Before:                After:
    main ── A ── B        main ── A ── B
              \                       \
               C ── D ── E            C' ── D' ── E'
                     feature                    feature

Interactive rebase (squash C and D):
  pick C ──┐
  squash D ─┤  →  main ── A ── B ── (C+D) ── E'
  pick E  ──┘

Onto rebase:
  Before (feature based on old-main):
    old-main ── X ── Y
              \
               C ── D
                     feature

  git rebase --onto main old-main feature:

    main ── A ── B
                \
                 C' ── D'
                       feature

Rebase with --rebase-merges:
  Before:
    main ── A ── B
              \
               C ──── D ──── G
                    /        /
               E ── F ──────

  After:
    main ── A ── B
                 \
                  C' ──── D' ──── G'
                        /        /
                   E' ── F' ──────

Rebase workflow:
  git rebase main          ──► linear history on latest main
  git rebase -i HEAD~5     ──► clean up last 5 commits
  git rebase --abort       ──► panic button
  git rebase --continue    ──► after resolving conflicts
```

`git rebase` is a powerful history-editing tool. Use it to keep feature branches up to date, squash messy WIP commits into clean logical units, and maintain a linear project history. Respect the golden rule: **never rebase commits that have been pushed to a shared branch.**
