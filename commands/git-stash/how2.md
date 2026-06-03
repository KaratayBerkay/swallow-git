# `git stash` — Stash away changes to a clean working directory

`git stash` temporarily shelves your local modifications so you can work on something else, then re-apply them later. The stash is stored as a stack of commit-like objects — stash entries are identified by `stash@{n}` (most recent = `stash@{0}`).

```
git stash list [<log-options>]
git stash show [-u|--include-untracked|--only-untracked] [<diff-options>] [<stash>]
git stash drop [-q|--quiet] [<stash>]
git stash (pop | apply) [--index] [-q|--quiet] [<stash>]
git stash branch <branchname> [<stash>]
git stash [push [-p|--patch] [-k|--[no-]keep-index] [-q|--quiet]
           [-u|--include-untracked] [-a|--all] [-m|--message <message>]
           [--pathspec-from-file=<file> [--pathspec-file-nul]]
           [--] [<pathspec>...]]
git stash clear [-q|--quiet]
git stash create [<message>]
git stash store [-m|--message <message>] [-q|--quiet] <commit>
```

## Description

`git stash` saves your dirty working directory (modified tracked files and staged changes) onto a stack of unfinished changes. After stashing, your working tree is clean — matching the current commit. You can later restore the stashed changes with `git stash pop` or `git stash apply`.

Each stash entry is stored as a commit object reachable via `refs/stash`. New stashes are pushed onto the top of the stack and renumbered automatically when stashes are dropped or popped.

The stash is **local** — it is never pushed to a remote. It is tied to the repository, not the branch.

---

## Basic Usage

### `git stash` (or `git stash push`)

Stash all tracked file changes (modified and staged). The working tree is reset to match HEAD:

```bash
git stash
```

This is the most common form — a quick way to save everything and get a clean slate.

### `git stash pop`

Restore the most recent stash and remove it from the stash stack:

```bash
git stash pop
```

If there are conflicts, the stash is **not** dropped. You must resolve conflicts first and then `git stash drop` manually.

### `git stash list`

List all stashes in the stack, most recent first:

```bash
git stash list
```

Output:
```
stash@{0}: On main: WIP: refactoring auth
stash@{1}: On feature-x: WIP: login form
stash@{2}: On main: WIP: styling tweaks
```

---

## Push Variants

### `git stash push -m "message"`

Stash with a descriptive message so you can identify it later:

```bash
git stash push -m "WIP: refactoring auth module"
```

The message appears in `git stash list`:
```
stash@{0}: On main: WIP: refactoring auth module
```

### `git stash -u` (or `--include-untracked`)

Stash tracked **and** untracked files (but not ignored files):

```bash
git stash -u
```

Without `-u`, untracked files are left in the working tree. Use this when you want to stash literally everything except ignored files.

### `git stash -a` (or `--all`)

Stash all files — tracked, untracked, **and** ignored:

```bash
git stash -a
```

This is the nuclear option — it stashes everything including build artifacts, `.env` files, etc.

---

## Partial Stash

### `git stash -p` (or `--patch`)

Interactively select hunks to stash. Git presents each diff hunk and asks whether to stash it:

```bash
git stash -p
```

Prompts use the same keys as `git add -p`:

| Key | Action |
|-----|--------|
| `y` | Stash this hunk |
| `n` | Keep this hunk in working tree |
| `q` | Quit |
| `a` | Stash this and all remaining hunks in file |
| `d` | Keep this and all remaining hunks |
| `g` | Select a hunk to jump to |
| `/` | Search for hunk by regex |
| `s` | Split the current hunk |
| `e` | Manually edit the hunk |

### `git stash push -- <file>`

Stash only specific files (or directories), leaving everything else untouched:

```bash
git stash push -- src/app.js
git stash push -- src/ tests/
```

Only changes to the specified paths are stashed. All other modifications remain in the working tree.

### `git stash -k` (or `--keep-index`)

Stash working tree changes but **keep** staged changes in the index:

```bash
git add feature.js
git stash -k
# feature.js is still staged; unstaged changes are stashed
```

Useful when you want to run tests against staged changes only, while saving unstaged work.

### `git stash --no-keep-index`

Stash **including** staged changes (default behavior). Staged changes are unstaged after stashing:

```bash
git stash --no-keep-index
```

### `git stash push --pathspec-from-file=<file>`

Read pathspec patterns from a file (or stdin with `-`):

```bash
git stash push --pathspec-from-file=stash-paths.txt
```

With `--pathspec-file-nul`, entries are NUL-separated (handles filenames with spaces).

---

## Apply vs Pop

| Command | Restores changes | Removes from stash stack |
|---------|-----------------|--------------------------|
| `git stash pop` | Yes | Yes (on success) |
| `git stash apply` | Yes | No |

### `git stash apply`

Restore stashed changes but **keep** the stash on the stack:

```bash
git stash apply               # apply stash@{0}
git stash apply stash@{2}     # apply a specific stash
```

Use this when you want to apply the same stash to multiple branches, or want to double-check before dropping.

### `git stash pop`

Restore stashed changes and **remove** the stash from the stack:

```bash
git stash pop                 # pop stash@{0}
git stash pop stash@{1}       # pop a specific stash
```

The stash is dropped only if the apply succeeds without conflicts. If there are conflicts, the stash is preserved.

---

## Index (`--index`)

By default, when you apply or pop a stash, all changes are restored as unstaged modifications. Use `--index` to restore the staged/unstaged distinction exactly as it was when stashed:

```bash
# Before stash: fileA staged, fileB unstaged
git stash
git stash pop --index
# After pop: fileA staged, fileB unstaged (preserved)
```

Without `--index`, both files would appear as unstaged modifications.

```bash
git stash apply --index       # apply with index preservation
git stash pop --index         # pop with index preservation
```

If `--index` causes conflicts, the stash is still applied but without index preservation.

---

## Show

### `git stash show`

Show a summary of changes in the latest stash (files changed, insertions, deletions):

```bash
git stash show
```

Output:
```
 src/auth.js | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)
```

### `git stash show <stash>`

Show summary for a specific stash:

```bash
git stash show stash@{1}
```

### `git stash show -p` (or `--patch`)

Show the full diff of the stash:

```bash
git stash show -p
git stash show -p stash@{2}
```

### `git stash show -u` (or `--include-untracked`)

Include untracked files in the diff summary:

```bash
git stash show -u
```

### `git stash show --only-untracked`

Show **only** the untracked files part of the stash:

```bash
git stash show --only-untracked
```

Any `<diff-options>` accepted by `git diff` work with `git stash show`:

```bash
git stash show --stat
git stash show --name-only
git stash show --diff-filter=AM
```

---

## Drop

### `git stash drop`

Remove the latest stash from the stack:

```bash
git stash drop
```

### `git stash drop <stash>`

Remove a specific stash:

```bash
git stash drop stash@{1}
```

Once dropped, a stash is gone. It can sometimes be recovered via `git fsck --lost-found` if the commit objects haven't been garbage collected.

### `git stash clear`

Remove **all** stashes from the stack:

```bash
git stash clear
```

**Warning:** This is irreversible (beyond `git fsck --lost-found` recovery).

### `-q` / `--quiet`

Suppress informational messages for drop and clear:

```bash
git stash drop -q stash@{2}
git stash clear -q
```

---

## Branch from Stash

### `git stash branch <branchname> [<stash>]`

Create a new branch from the commit where the stash was created, then apply the stash. If the apply succeeds, the stash is dropped:

```bash
git stash branch feature-x stash@{1}
```

This is useful when you stashed changes while on the wrong branch. The command:
1. Creates a new branch starting at the commit the stash was based on
2. Switches to that branch
3. Applies the stash
4. Drops the stash (on success)

If the stash conflicts, you resolve the conflict manually — the stash is **not** dropped.

```bash
# On main, accidentally stashed work meant for a feature branch
git stash branch feature-login stash@{0}
# Now on feature-login with changes applied
```

---

## Create and Store (Scripting)

### `git stash create [<message>]`

Create a stash commit object **without** modifying the refs/stash or the working tree. Returns the commit hash of the stash object:

```bash
commit_hash=$(git stash create "WIP: backup")
```

This is a plumbing command intended for scripting. It does not update the stash stack.

### `git stash store [-m <message>] [-q] <commit>`

Add a stash commit (created by `git stash create`) to the stash stack:

```bash
git stash store -m "WIP: autosave" $commit_hash
```

Together they form the scriptable stash workflow:

```bash
# Script: autosave before risky operation
hash=$(git stash create "autosave before rebase")
git stash store -m "autosave before rebase" "$hash"
# ... do risky operation ...
git stash pop
```

### Difference between `create`/`store` and `push`/`pop`

| Command pair | Updates working tree | Updates stash ref | Use case |
|-------------|---------------------|-------------------|----------|
| `push` / `pop` | Yes | Yes | Interactive use |
| `create` / `store` | No | `create` = no, `store` = yes | Scripting / automation |

---

## Quick Reference

```bash
# Basic
git stash                           # Stash all tracked changes
git stash push -m "message"         # Stash with a message
git stash list                      # List all stashes
git stash pop                       # Restore + remove latest
git stash apply                     # Restore (keep stash)
git stash drop                      # Remove latest stash

# Push variants
git stash -u                        # Include untracked files
git stash -a                        # Include all files (even ignored)
git stash -p                        # Interactive hunk selection
git stash -k                        # Keep staged changes
git stash push -- file.js           # Stash only specific files

# Apply variants
git stash apply stash@{2}           # Apply specific stash
git stash pop stash@{1}             # Pop specific stash
git stash apply --index             # Preserve staged/unstaged on apply
git stash pop --index               # Preserve staged/unstaged on pop

# Show
git stash show                      # Summary of latest stash
git stash show -p                   # Full diff of latest stash
git stash show stash@{1}            # Summary of specific stash
git stash show -p stash@{1}         # Full diff of specific stash
git stash show -u                   # Include untracked in summary
git stash show --only-untracked     # Only untracked files

# Remove
git stash drop                      # Drop latest stash
git stash drop stash@{1}            # Drop specific stash
git stash clear                     # Drop ALL stashes (irreversible!)

# Branch
git stash branch new-branch         # New branch + apply latest stash
git stash branch new-branch stash@{1} # New branch + apply specific stash

# Scripting
git stash create "msg"              # Create stash commit object
git stash store -m "msg" <commit>   # Store commit as stash

# Quiet
git stash drop -q                   # Quiet drop
git stash clear -q                  # Quiet clear
```

---

## Real-World Examples

```bash
# Save all tracked changes (quick context switch)
git stash

# Stash with a descriptive message
git stash push -m "WIP: refactoring auth"

# Restore and remove the latest stash
git stash pop

# Restore a specific stash without removing it
git stash apply stash@{2}

# Include untracked files when stashing
git stash -u

# Interactively stash specific hunks
git stash -p

# Drop a specific stash
git stash drop stash@{0}

# Remove all stashes
git stash clear

# Show the full diff of a stash
git stash show -p stash@{0}

# Create a new branch from a stash
git stash branch new-feature stash@{1}

# Stash only one specific file
git stash push -- src/app.js

# Keep staged changes, stash only unstaged work
git stash -k

# Apply a stash preserving the staged/unstaged state
git stash apply --index

# Use stash for code review preparation
git add feature.js
git stash -k                       # stash unstaged changes only
npm test                           # run tests on staged code only
git stash pop                      # restore unstaged changes

# Recover when pop fails with conflicts
git stash pop                      # conflict!
# ... resolve conflicts ...
git add resolved-file.js
git stash drop                     # stash was NOT dropped on conflict

# Script: autosave before risky operation
hash=$(git stash create "pre-rebase backup")
git stash store -m "pre-rebase backup" "$hash"
git rebase main
git stash pop
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git stash pop` conflicts and stash is gone | The stash is **not** dropped on conflict — it stays on the stack | Resolve conflicts, then `git stash drop` manually. The stash is preserved until then |
| Stashed but untracked files are still there | By default, only **tracked** files are stashed | Use `git stash -u` to include untracked, or `git stash -a` for everything |
| Stash applied on the wrong branch | `git stash` is not branch-aware — it applies to any branch | Use `git stash branch <name>` to create a branch from the stash's original commit |
| Applied a stash twice (duplicate changes) | `git stash apply` does not remove the stash from the stack | Use `git stash pop` instead of `apply`, or `git stash drop` after applying |
| "Cannot save the current index state" | The stash is full (unlikely) or refs/stash is corrupted | Check `git fsck` and consider `git stash clear` or manual ref cleanup |
| Stash lost after `git stash clear` | `clear` removes all stashes irreversibly | Recovery is possible via `git fsck --lost-found` if commits haven't been GC'd |
| `git stash` says "No local changes to save" | Working tree is clean — nothing to stash | There's nothing to do. Ensure files are modified and not ignored |
| Stash conflict on apply — "CONFLICT (content)" | The branch has diverged since the stash was created | Resolve conflicts manually, `git add`, then `git stash drop` if successful |
| `git stash --index` fails with conflicts | Index preservation could not be cleanly applied | The stash is still applied without `--index` behavior. Resolve conflicts and manually re-stage |
| Accidentally stashed credentials or secrets | Stash commits are stored as real objects in `.git` | Rotate secrets. Stash entries persist in the object store and reflog |
| Stash is eating disk space | Stash objects are stored permanently in `.git/objects` | Use `git stash drop` or `git stash clear`; run `git gc` to garbage collect |
