# `git restore` — Restore working tree files

`git restore` restores files in the working tree or the staging area to a known state. Introduced in Git 2.23 as part of splitting `git checkout` into focused commands (`git switch` for branches, `git restore` for files). It is the "undo" command for unstaging and discarding changes.

```
git restore [<options>] [--source=<tree>] [--staged] [--worktree] [--] <pathspec>...
git restore (-p | --patch) [<options>] [--source=<tree>] [--staged] [--worktree] [--] [<pathspec>...]
```

## Description

`git restore` restores files to a specified state. By default, it restores the working tree from the staging area (discarding unstaged changes). With `--staged`, it restores the staging area from HEAD (unstaging changes).

This is the modern replacement for two common `git checkout` use cases:
- `git checkout -- <file>` → `git restore <file>`
- `git checkout HEAD -- <file>` → `git restore --source=HEAD --staged --worktree <file>`

### Three-Zone Model

```
Working Tree          Index (Staging)         HEAD (Last Commit)
    │                       │                       │
    │◄──── worktree ────────┤                       │
    │   (default)           │◄──── staged ─────────┤
    │                       │                       │
    │◄──────── both ───────────────────────────────┤
    │                       │                       │
    │◄──── source ─────────────────────────────────┤  (--source=<tree>)
```

---

## Basic Usage

### `git restore <file>` — Discard working tree changes

Restore the working tree file to match the staging area (index). This **discards unstaged changes**:

```bash
git restore file.txt
```

This is equivalent to the old `git checkout -- file.txt`.

### `git restore --staged <file>` — Unstage

Remove the file from the staging area, bringing it back to match HEAD. The working tree is **not** affected:

```bash
git restore --staged file.txt
```

This is the modern replacement for `git reset HEAD <file>`.

### `git restore --staged --worktree <file>` — Unstage + discard

Both unstage **and** discard working tree changes. The file is restored to match HEAD in both zones:

```bash
git restore --staged --worktree file.txt
```

---

## Source

### `--source=<tree>` (or `-s <tree>`, `--from=<tree>`)

Restore from a specific commit, branch, or tag instead of the default source:

```bash
git restore --source=HEAD~2 file.txt          # version from 2 commits ago
git restore -s main file.txt                  # version from main branch
git restore --source=abc123 file.txt          # from a specific commit
git restore --source=v1.0 --staged file.txt   # stage the tagged version
```

The default source depends on which zone is being restored:
- `--worktree` only (default): source is the index
- `--staged` only: source is HEAD
- `--staged --worktree`: source is HEAD

When `--source` is explicitly given, it overrides these defaults.

---

## Staged vs Worktree

`git restore` can target three combinations of zones:

| Flag | Restores | Default source | Use case |
|------|----------|---------------|----------|
| `--worktree` (default) | Working tree only | Index | Discard unstaged changes |
| `--staged` | Staging area only | HEAD | Unstage a file |
| `--staged --worktree` | Both | HEAD | Full undo to HEAD |
| `-W` | Same as `--worktree` | — | Short form |
| `-S` | Same as `--staged` | — | Short form |

The default (no `--staged` or `--worktree` flag) is `--worktree` only.

```bash
git restore file.txt              # --worktree (default)
git restore -W file.txt           # explicit worktree
git restore -S file.txt           # staged only (unstage)
git restore -SW file.txt          # both (short form of --staged --worktree)
```

### `-W` / `--worktree`

Restore the working tree. When used alone, the index is the default source. This is the default mode.

### `-S` / `--staged`

Restore the staging area (index). HEAD is the default source.

```bash
git restore -S file.txt           # unstage file.txt
```

Both can be combined: `-S -W` or `-SW` forces both zones.

---

## Interactive

### `-p` (or `--patch`)

Restore **hunk by hunk** — interactively choose which parts of a file to restore. Git shows each diff section and asks what to do:

```bash
git restore -p file.txt
```

This lets you selectively undo parts of a change instead of discarding the entire file.

**Available keys in patch mode:**

| Key | Action |
|-----|--------|
| `y` | Restore this hunk (undo it) |
| `n` | Skip this hunk (keep the change) |
| `q` | Quit — don't restore this or any remaining hunks |
| `a` | Restore this hunk and all later hunks |
| `d` | Don't restore this hunk or any later hunks |
| `g` | Select a hunk to go to |
| `/` | Search for a hunk matching a regex |
| `j` | Go to the next undecided hunk |
| `J` | Go to the next hunk (even if decided) |
| `k` | Go to the previous undecided hunk |
| `K` | Go to the previous hunk (even if decided) |
| `s` | Split the current hunk into smaller hunks |
| `e` | Manually edit the current hunk |
| `?` | Print help |

```bash
git restore -p --source=HEAD~1 file.txt     # selectively undo from previous commit
git restore -p --staged file.txt            # selectively unstage hunks
```

---

## Options

### `--overlay`

When restoring from a tree, **overlay** the source tree on top of the working tree rather than removing files that don't exist in the source:

```bash
git restore --source=HEAD --overlay file.txt
```

Without `--overlay` (default), files in the working tree that don't exist in the source tree are removed. With `--overlay`, they are left in place.

### `--recurse-submodules`

Restore submodules recursively, matching the state of the superproject:

```bash
git restore --recurse-submodules .
```

Without this flag, submodules are left as-is.

### `--ignore-unmerged`

Silently skip files that are in an unmerged state (conflicted). Without this flag, `git restore` errors on unmerged paths:

```bash
git restore --ignore-unmerged .
```

### `--ours` / `--theirs`

When restoring from the index during a merge conflict, check out stage #2 (ours) or stage #3 (theirs) for unmerged paths:

```bash
git restore --ours conflicted.txt
git restore --theirs conflicted.txt
```

This is useful for resolving merge conflicts by picking one side.

### `--conflict=<style>`

When restoring conflicted paths, generate a merge conflict style. Options:
- `merge` — standard `<<<<<<<` / `=======` / `>>>>>>>` markers (default)
- `diff3` — also shows the merge base in `|||||||` markers
- `zdiff3` — like diff3 but with smarter hunk alignment

```bash
git restore --conflict=diff3 conflicted.txt
```

### `--ignore-skip-worktree-bits`

Normally `git restore` skips files with the `skip-worktree` bit set. This flag forces restoration even on those files. Rarely needed.

### `--pathspec-from-file=<file>`

Read pathspec from a file (or stdin with `-`):

```bash
git restore --pathspec-from-file=files-to-restore.txt
```

### `--pathspec-file-nul`

Used with `--pathspec-from-file` — entries are NUL-separated instead of newline-separated.

### `--no-overlay`

Explicitly use the default non-overlay mode (remove files not in the source tree).

---

## Comparison: `git restore` vs `git checkout` vs `git reset`

| Task | Old way | New way |
|------|---------|---------|
| Discard working tree changes | `git checkout -- <file>` | `git restore <file>` |
| Unstage a file | `git reset HEAD <file>` | `git restore --staged <file>` |
| Unstage + discard | `git checkout HEAD -- <file>` | `git restore --source=HEAD --staged --worktree <file>` |
| Restore from specific commit | `git checkout <commit> -- <file>` | `git restore --source=<commit> <file>` |
| Interactively discard changes | no direct equivalent | `git restore -p <file>` |

**Key differences:**

| Behavior | `git restore` | `git checkout` | `git reset` |
|----------|---------------|----------------|-------------|
| Moves HEAD | No | Yes (when given a branch) | Yes |
| Modifies working tree | Yes (with `--worktree`) | Yes | No (`--soft`/`--mixed`), Yes (`--hard`) |
| Modifies index | Yes (with `--staged`) | Sometimes | Yes (depends on mode) |
| Switches branches | No | Yes | No |
| Default source | Index (worktree) / HEAD (staged) | HEAD | HEAD |
| Patch mode | Yes (`-p`) | Yes (`-p`) | Yes (`-p`) |

**When to use which:**

- `git restore` — undo file-level changes (unstage, discard, or both)
- `git checkout` — switch branches (use `git switch` instead) or restore files (use `git restore`)
- `git reset` — move branch pointers, unstage, or redo commit history

---

## Quick Reference

```bash
# Discard working tree changes
git restore file.txt                        # discard unstaged changes (from index)
git restore .                               # discard all unstaged changes

# Unstage
git restore --staged file.txt               # unstage (from HEAD)
git restore --staged .                      # unstage everything

# Unstage + discard
git restore --staged --worktree file.txt    # full undo to HEAD
git restore -SW file.txt                    # short form

# Restore from a specific source
git restore --source=HEAD~2 file.txt        # from 2 commits ago
git restore -s main file.txt                # from main branch
git restore --source=abc123 file.txt        # from a specific commit

# Restore staged from a specific source
git restore --source=main --staged file.txt # stage the main version

# Interactive (patch mode)
git restore -p file.txt                     # selectively discard hunks
git restore -p --staged file.txt            # selectively unstage hunks
git restore -p --source=HEAD file.txt       # selectively undo to HEAD

# Merge conflict helpers
git restore --ours conflicted.txt           # take our side
git restore --theirs conflicted.txt         # take their side
git restore --conflict=diff3 file.txt       # show merge base in conflicts

# Options
git restore --overlay --source=HEAD .       # overlay (don't remove extra files)
git restore --recurse-submodules .          # include submodules
git restore --ignore-unmerged .             # skip conflicted files

# Pathspec from file
git restore --pathspec-from-file=list.txt   # restore files from a list
```

### Zone and source defaults

| Flags | Default source | Effect |
|-------|---------------|--------|
| (none) | Index | Restore working tree from index |
| `--staged` | HEAD | Restore index from HEAD |
| `--staged --worktree` | HEAD | Restore both from HEAD |
| `--source=<tree>` | Overrides default | Restore from specified tree |

---

## Real-World Examples

### Discard working tree changes

```bash
git restore file.txt
```

You edited a file but changed your mind. This reverts it to the version in the staging area.

### Unstage a file (undo `git add`)

```bash
git restore --staged file.txt
```

You staged a file by accident (`git add file.txt`) and want to unstage it without losing your edits.

### Full undo — unstage + discard

```bash
git restore --source=HEAD --staged --worktree file.txt
```

You want to completely undo everything since the last commit for this file. Short form: `git restore -SW file.txt` or `git restore -s HEAD -SW file.txt`.

### Restore a deleted file from the last commit

```bash
git restore --source=HEAD -- file.txt
```

You deleted a file and want it back. This restores it from HEAD into the working tree.

### Restore a file from an older commit

```bash
git restore --source=HEAD~2 file.txt
```

The file was broken in the last two commits. This restores it from two commits ago.

### Restore staged version from another branch

```bash
git restore --source=main --staged file.txt
```

Stage the version of `file.txt` that exists on `main`, without changing your working tree.

### Interactively undo specific changes

```bash
git restore -p file.txt
```

You made multiple edits to a file but only want to undo some of them. Git shows each hunk and asks whether to discard it.

### Interactively unstage specific hunks

```bash
git restore -p --staged file.txt
```

You staged a file with `git add -A` but only want to unstage part of it.

### Discard all unstaged changes

```bash
git restore .
```

Reverses every unstaged modification in the current directory. Files are restored to match the index.

### Resolve a merge conflict by picking a side

```bash
git restore --ours conflicted.txt         # keep our changes
git restore --theirs conflicted.txt       # keep their changes
```

During a merge conflict, quickly pick one side. After restoring, `git add conflicted.txt` to mark it resolved.

### Restore from a tag

```bash
git restore --source=v2.0 --staged --worktree config.yml
```

Revert a configuration file to exactly how it was at the `v2.0` release.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git restore` discards changes permanently | There is no "undo" for `git restore` — unstaged changes are lost | Use `git stash` first if unsure, or `git restore -p` for selective undo |
| `git restore .` runs without warning | No confirmation prompt before mass discarding changes | Use `git restore -p .` or check `git diff` first |
| Confusing `--staged` with "restore staged changes to working tree" | `--staged` targets the **staging area**, not the working tree | `--staged` = unstage (remove from index); `--worktree` = discard working changes |
| Forgetting `--source` flag to restore from HEAD | Default source for `--staged` is HEAD, but for `--worktree` alone it's the index | Use `--source=HEAD --staged --worktree` to restore both from HEAD |
| `--ours` / `--theirs` only works during conflicts | These flags read from the index's stage entries, only available during merge conflicts | Resolve the conflict, then `git add` the result |
| `git restore --source=HEAD file.txt` followed by `git restore --staged file.txt` undoes the first restore | The first command restores the working tree; the second unstages, meaning the working tree now differs from the index again | Use `--staged --worktree` together |
| `git restore -p` against a binary file | Patch mode doesn't work with binary files | Restore the entire file without `-p` |
| `git restore` with `--staged` changes the staging area but you expected working tree to change | `--staged` only affects the index, not the working tree | Add `--worktree` to also change the working tree |
| Restoring from `--source` with a sparse checkout | Files outside the sparse cone may be restored incorrectly | Use `git restore --sparse` or adjust sparse-checkout settings |

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Recurse into submodules by default when restoring
[submodule]
    recurse = true
```

There are no `git restore`-specific config options — its behavior is governed by general Git settings for diffs, submodules, and sparse checkout.

---

## Visual Summary

```
Before:                  git restore file.txt:
Working Tree ≠ Index     Working Tree = Index
    file.txt (edited)        file.txt (restored)

Before:                  git restore --staged file.txt:
Index ≠ HEAD             Index = HEAD
    file.txt (staged)        file.txt (unstaged)

Before:                  git restore --staged --worktree file.txt:
Both ≠ HEAD              Both = HEAD
    file.txt (staged)        file.txt (as committed)
    file.txt (edited)

Before:                  git restore -p file.txt:
file.txt has hunks       Selected hunks restored
  hunk 1 (fix)               hunk 1 kept
  hunk 2 (debug)             hunk 2 discarded
```

`git restore` is the focused, safe way to undo file-level changes in Git 2.23+. Use it instead of the file-mode overloads of `git checkout` and `git reset`.
