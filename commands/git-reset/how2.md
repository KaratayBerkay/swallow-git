# `git reset` — Reset current HEAD to the specified state

`git reset` is a powerful command for undoing changes by moving the current branch HEAD backward (or forward) and optionally updating the index and working tree. It has three primary modes — `--soft`, `--mixed` (default), and `--hard` — that control what gets reset.

```
git reset [-q] [<tree-ish>] [-- <pathspec>...]
git reset [-q] [--pathspec-from-file=<file> [--pathspec-file-nul]] [<tree-ish>]
git reset (--patch | -p) [<tree-ish>] [--] [<pathspec>...]
git reset [--soft | --mixed [-N] | --hard | --merge | --keep] [-q] [<commit>]
```

## Description

`git reset` resets the current branch HEAD to a specified state. Depending on the mode, it can also reset the index (staging area) and the working tree. Think of it as Git's "undo" command with varying levels of destructiveness.

At its core, `git reset` moves the branch pointer (HEAD) to a different commit and optionally updates the index and working directory to match. This makes it useful for:
- Unstaging files
- Undoing commits
- Discarding working directory changes
- Squashing commits

---

## The Three Zones

Git has three areas that `git reset` operates on:

| Zone | What it contains | Reset effect |
|------|-----------------|--------------|
| HEAD (Repository) | The current branch pointer | Moves to the target commit |
| Index (Staging Area) | What will go into the next commit | Reset to match target |
| Working Tree | Files on disk | Reset to match target |

---

## The Three Main Modes

### `--soft`

Move HEAD to the specified commit, but leave the index and working tree untouched. All changes from the "undone" commits become **staged** (in the index).

```bash
git reset --soft HEAD~1
```

After `--soft`, the index contains exactly what it had before — meaning it still reflects the undone commit's state. Your working tree is unchanged.

**Use case:** You committed too early. The changes remain staged, ready to be re-committed or amended.

### `--mixed` (default)

Move HEAD to the specified commit and reset the index to match. The working tree is left untouched. Changes from the undone commits become **unstaged** but still present in the working tree.

```bash
git reset HEAD~1           # --mixed is the default
```

After `--mixed`, you'll see the changes as unstaged modifications in `git status`. This is the default mode — running `git reset` without a mode flag uses `--mixed`.

**Use case:** You committed but want to re-examine or re-edit changes before committing again. The working tree preserves all your edits.

### `--hard`

Move HEAD to the specified commit, reset the index **and** the working tree to match. **All uncommitted changes are lost.**

```bash
git reset --hard HEAD~1
```

**Warning:** `--hard` permanently discards uncommitted changes in the working tree. There is no recovery unless you have the changes stashed or backed up elsewhere.

| Mode | HEAD | Index (Stage) | Working Tree | Safety |
|------|------|---------------|--------------|--------|
| `--soft` | Moves | Unchanged | Unchanged | Safe — no data loss |
| `--mixed` (default) | Moves | Resets | Unchanged | Mostly safe — working changes preserved |
| `--hard` | Moves | Resets | Resets | **Dangerous** — working changes lost |

---

## Pathspec: Unstaging Files

When paths are specified, `git reset` does **not** move HEAD. Instead, it resets the index entries for the given paths to match the specified tree-ish (defaults to `HEAD`). This is the standard way to **unstage** files:

```bash
git reset HEAD -- file.txt
git reset -- file.txt       # HEAD is implied
git reset HEAD~1 -- src/    # Reset index for src/ to match previous commit
```

With paths, `--mixed` is forced (other modes like `--soft` and `--hard` are ignored). This form is equivalent to the old `git checkout -- file.txt` for unstaging, but more explicit about the source.

**Contrast with `git restore`:**

```bash
git reset HEAD -- file.txt    # Unstage file.txt (reset index to HEAD)
git restore --staged file.txt # Same thing (modern alternative)
```

---

## Other Modes

### `--merge`

A safer alternative to `--hard`. Resets the index and updates files in the working tree that differ between HEAD and the target commit, but **aborts** if any file has unstaged changes in the working tree:

```bash
git reset --merge ORIG_HEAD
```

**Behavior:**
- If a file differs between HEAD and the target commit, and also has unstaged changes → abort
- If a file is unchanged between HEAD and target, but has unstaged changes → keep those changes
- If a file differs between HEAD and target, and has no unstaged changes → reset it

### `--keep`

Resets the index and updates files that differ between HEAD and the target commit, but **aborts** if any file has local (unstaged) changes and would need to be updated:

```bash
git reset --keep HEAD~1
```

**Difference from `--merge`:** `--keep` is even more conservative — it aborts if there's any conflict between the local changes and the reset, even if the file wasn't modified between HEAD and the target. In practice, `--keep` is useful when you want to reset to an earlier commit but keep your working tree changes, and you want Git to abort if that would cause any conflict.

| Mode | HEAD | Index | Working Tree | Aborts if... |
|------|------|-------|--------------|--------------|
| `--merge` | Moves | Resets | Updates safe files | Unstaged change conflicts with reset |
| `--keep` | Moves | Resets | Updates safe files | Any file with local changes would be overwritten |

Both `--merge` and `--keep` require a commit argument and refuse to work with paths.

---

## Patch Mode (-p / --patch)

Interactively reset hunks of changes. Git presents each diff hunk and asks what to do:

```bash
git reset -p HEAD~1
git reset -p HEAD -- file.txt
```

This lets you selectively unstage or discard specific parts of changes instead of entire files. The interactive prompts use the same keys as `git add -p`:

| Key | Action |
|-----|--------|
| `y` | Reset this hunk |
| `n` | Skip this hunk |
| `q` | Quit |
| `a` | Reset this and all remaining hunks in file |
| `d` | Skip this and all remaining hunks in file |
| `g` | Select a hunk to jump to |
| `/` | Search for hunk by regex |
| `j` | Go to next undecided hunk |
| `J` | Go to next hunk (even if decided) |
| `k` | Go to previous undecided hunk |
| `K` | Go to previous hunk (even if decided) |
| `s` | Split current hunk into smaller ones |
| `e` | Manually edit the current hunk |
| `p` | Print the current hunk |
| `P` | Print using the pager |
| `?` | Print help |

---

## Resetting vs Restoring

Git has three commands for undoing changes, and it's important to understand the distinction:

| Command | Primary use | Scope |
|---------|------------|-------|
| `git reset` | Move branch pointer, reset index, discard working tree changes | Branch-level operation — moves HEAD |
| `git restore` | Restore files from a source to the working tree or index | File-level operation — does NOT move HEAD |
| `git checkout` | Switch branches or restore files | Mixed — switches branches OR restores files |

**Modern workflow (Git 2.23+):**

| Old way | New way | Effect |
|---------|---------|--------|
| `git reset HEAD -- file.txt` | `git restore --staged file.txt` | Unstage a file |
| `git checkout -- file.txt` | `git restore file.txt` | Discard working tree changes |
| `git checkout <branch>` | `git switch <branch>` | Switch branches |
| `git checkout -b <branch>` | `git switch -c <branch>` | Create and switch |

`git reset` is still the right tool when you want to move HEAD (undo commits, squash, or reorder history). Use `git restore` for file-level operations that don't involve moving the branch pointer.

---

## Sequence: What Happens in Each Mode

This table shows the effect of each mode on the three Git zones when run on a specific commit:

```
Before:                    HEAD -> Commit C (latest)
                           Index = Commit C
                           Working Tree = Commit C (with some edits)

git reset --soft HEAD~1:   HEAD -> Commit B
                           Index = Commit C  (unchanged — all changes still staged)
                           Working Tree = Commit C (unchanged — edits preserved)

git reset HEAD~1:          HEAD -> Commit B
                           Index = Commit B  (reset to match B)
                           Working Tree = Commit C (unchanged — edits preserved)

git reset --hard HEAD~1:   HEAD -> Commit B
                           Index = Commit B  (reset to match B)
                           Working Tree = Commit B (reset to match B — edits LOST)
```

---

## Quick Reference

```bash
# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Undo last commit (keep changes unstaged)
git reset HEAD~1

# Undo last commit (discard everything)
git reset --hard HEAD~1

# Unstage a file
git reset HEAD -- file.txt

# Unstage all files
git reset HEAD

# Unstage everything (reset index to HEAD)
git reset

# Undo multiple commits
git reset --hard HEAD~3

# Reset to remote state
git reset --hard origin/main

# Safely undo while keeping working tree changes
git reset --keep HEAD~1

# Undo a merge
git reset --merge ORIG_HEAD

# Interactive unstage (hunk by hunk)
git reset -p

# Reset a directory to a specific commit
git reset HEAD~2 -- src/
```

---

## Real-World Examples

### Undo last commit, keep changes staged

```bash
git reset --soft HEAD~1
# Changes from the undone commit remain in the index (staged)
# Useful when you want to amend the commit or split it
```

### Undo last commit, keep changes in working tree

```bash
git reset HEAD~1
# HEAD moves back, index resets, working tree preserved
# Changes appear as unstaged modifications
git status  # shows modified files (not staged)
```

### Discard last commit and its changes entirely

```bash
git reset --hard HEAD~1
# Everything — HEAD, index, and working tree — reverts to previous commit
# ⚠️ All changes from the undone commit are permanently lost
```

### Unstage a file

```bash
git add file.txt       # accidentally staged
git reset HEAD -- file.txt
# file.txt is now unstaged but changes are still in the working tree
```

### Discard all local changes to match remote

```bash
git fetch origin
git reset --hard origin/main
# Discards all local commits and working changes — your branch now matches origin/main exactly
# ⚠️ Very destructive — use with caution
```

### Squash last 3 commits

```bash
git reset --soft HEAD~3
git commit -m "feat: combine three commits into one"
# All changes from the last 3 commits are now staged
# A single new commit replaces them
```

### Undo a merge

```bash
git merge feature       # oops — not ready yet
git reset --merge ORIG_HEAD
# Undoes the merge while preserving any unstaged changes you had
# ORIG_HEAD is set by Git to the previous HEAD before the merge
```

### Reset but keep unstaged changes

```bash
# You have staged changes + unstaged changes
git reset --keep HEAD~1
# HEAD and index are reset, but unstaged changes are preserved
# Aborts if there's any conflict between reset and unstaged changes
```

### Interactively unstage hunks

```bash
git add .               # staged everything
git reset -p HEAD -- src/main.py
# Shows each hunk — press 'y' to unstage, 'n' to keep staged
# Only the selected hunks are removed from the index
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Lost work after `git reset --hard` | `--hard` overwrites the working tree without warning | Use `git stash` before resetting, or use `--keep`/`--merge` for safety. Check `git reflog` — the old HEAD is still there for 90 days |
| `git reset --soft` didn't change staged files | `--soft` only moves HEAD — the index stays at the old commit | That's the intended behavior of `--soft`. Use `--mixed` if you want changes unstaged |
| Unstaged wrong file | `git reset HEAD -- file.txt` unstages it completely | Use `git add file.txt` to re-stage it. Or use `git reset -p` for granular control |
| `git reset HEAD~1` undid the wrong commit | `HEAD~1` goes back one commit, not two | Use `git reflog` to find the lost commit and `git reset --hard <hash>` to recover |
| Reset with paths doesn't move HEAD | When paths are given, `git reset` only changes the index | That's the design — use `git reset <commit>` (no paths) to move HEAD |
| `git reset origin/main` moved HEAD to a detached state | No branch name — you reset to a remote tracking ref | Use `git reset --hard origin/main` while on a branch, or `git switch -c new-branch` afterward |
| Forgot `--hard` meant to discard | Ran `git reset HEAD~1` instead of `git reset --hard HEAD~1` | The commit is undone but changes are still there as unstaged modifications. Run `git restore .` to discard them |
| `git reset` after `git commit --amend` created chaos | Amend rewrites the commit, so resetting to the old hash creates divergence | Use `git reflog` to find the correct state and reset to that |
| Reset across multiple branches is confusing | `git reset` moves the current branch — if you're on `main`, it resets `main` | Always verify which branch you're on with `git branch` before resetting |

---

## Visual Workflow

```
Before:
Working Tree       Index (Staging)      Repository (HEAD)
   [edits]            [staged]             Commit C ◄ HEAD


git reset --soft HEAD~1:
   [edits]            [staged]             Commit B ◄ HEAD
                     (still has C           └── Commit C (lost from branch)
                      changes)                  but in reflog


git reset --mixed HEAD~1 (default):
   [edits]            [empty/index=B]      Commit B ◄ HEAD
   (contains                                 └── Commit C (reflog)
    C changes)


git reset --hard HEAD~1:
   [clean/index=B]   [empty/index=B]      Commit B ◄ HEAD
                                           └── Commit C (reflog)


git reset HEAD -- file.txt (unstage):
Working Tree       Index (Staging)      Repository
   file.txt           file.txt ◄ HEAD     Commit C ◄ HEAD
   (edited)           (reset to HEAD)
```

`git reset` is your multi-level undo button. Use `--soft` to re-commit, `--mixed` to re-examine, and `--hard` with extreme caution. For file-level undo, prefer `git restore`. Always remember that `git reflog` is your safety net — any reset can be reversed within 90 days.
