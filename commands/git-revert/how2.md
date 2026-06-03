# `git revert` — Create a new commit that undoes changes from a previous commit

`git revert` is the **safe undo** command. Instead of deleting history (like `git reset`), it creates a **new commit** that applies the inverse of a target commit's changes. The original commit remains in the log, making `revert` the right choice for shared branches where rewriting history would disrupt collaborators.

```
git revert [--[no-]edit] [-n] [-m <parent-number>] [-s] [-S[<keyid>]] [--continue]
           [--abort] [--quit] [--allow-empty] [--strategy=<strategy>]
           [-X <strategy-option>] [<commit>...]
```

## Description

`git revert` looks at each commit in the given range and computes a **reverse patch** — it figures out what the commit added, changed, or deleted, and creates a new commit that undoes exactly those changes. The history is linear and additive:

- **Original commit:** stays in the log unchanged
- **Revert commit:** new commit that applies the inverse diff
- **Safety:** since history is not rewritten, a revert is safe to push to shared branches

The commit message is auto-generated: `Revert "<original subject>"` with a body that references the reverted commit hash.

---

## Basic Usage

### `git revert HEAD`

Undo the most recent commit:

```bash
git revert HEAD
```

This opens your editor with the default revert message. Save and close to commit the revert.

### `git revert abc123`

Undo a specific commit by its hash:

```bash
git revert abc123
```

The commit `abc123` is unchanged in history. A new commit is created that undoes it.

### `git revert HEAD~3`

Undo the third-most-recent commit (not the last three — just `HEAD~3`):

```bash
git revert HEAD~3
```

---

## Revert a Range of Commits

Revert multiple commits by specifying a revision range:

```bash
git revert HEAD~3..HEAD
```

This reverts commits `HEAD~2`, `HEAD~1`, and `HEAD` (the last 3 commits), creating **one revert commit per original commit** in reverse order (oldest first) to avoid conflicts.

To collapse the whole range into a **single revert commit**, combine with `--no-commit`:

```bash
git revert --no-commit HEAD~3..HEAD
git commit -m "revert: roll back last 3 commits"
```

### Range syntax

| Syntax | Commits reverted |
|--------|-----------------|
| `HEAD~3..HEAD` | `HEAD~2`, `HEAD~1`, `HEAD` (three commits) |
| `abc123..def456` | Commits between `abc123` and `def456` (exclusive of `abc123`) |
| `abc123^!` | Only `abc123` |
| `main..feature` | Commits in feature not in main |

---

## No-Commit Mode (`-n` or `--no-commit`)

Stage the reverse changes **without creating a commit**. This lets you revert several commits and commit them all at once, or inspect the changes first:

```bash
# Revert three commits, stage all changes, commit once
git revert -n HEAD~3..HEAD
git commit -m "revert: batch rollback of last 3 commits"
```

Without `-n`, each reverted commit produces a separate revert commit:

```bash
git revert HEAD~3..HEAD
# Creates 3 new commits: "Revert ...", "Revert ...", "Revert ..."
```

With `-n` you get one clean commit (and avoid cluttering the log).

---

## Mainline (`-m <parent-number>`)

When reverting a **merge commit**, Git cannot automatically determine which parent's history to keep. You must specify which parent is the **mainline** — the branch you want to keep — using `-m <n>`:

```bash
# Merge commit abc123 merged feature into main (parent 1 = main, parent 2 = feature)
git revert -m 1 abc123
```

`-m 1` means "revert the merge, keeping parent 1 (main)" — effectively undoing all the changes that came from parent 2 (feature).

```
Before revert of merge:

    main:      ──A──B──C──M──D
                         /
    feature:        X──Y──Z

After `git revert -m 1 M`:

    main:      ──A──B──C──M──D──R
                         /
    feature:        X──Y──Z

    R = revert of merge M — keeps main changes, drops X, Y, Z
```

| `-m` value | Which side is kept |
|------------|-------------------|
| `-m 1` | First parent (usually the target branch, e.g., `main`) |
| `-m 2` | Second parent (usually the source/feature branch) |

---

## Edit Control

### `--no-edit`

Accept the auto-generated revert message without opening an editor:

```bash
git revert --no-edit HEAD
```

The message will be:

```
Revert "<original subject>"

This reverts commit abc123def456...
```

### `-e` / `--edit`

Force the editor to open (this is the default unless `--no-edit` is given):

```bash
git revert -e HEAD
```

Useful when you've configured `core.editor` but want to explicitly ensure you can edit the message.

### Explicit forms

| Flag | Behavior |
|------|----------|
| `--edit` (default) | Open editor to review/modify message |
| `--no-edit` | Use auto-generated message, skip editor |
| `-e` | Same as `--edit` |

---

## Sequential Reverts — Conflict Resolution

When a revert cannot be applied cleanly (conflicts with subsequent changes), Git pauses and lets you resolve:

### `--continue`

After resolving conflicts, resume the revert:

```bash
git add resolved-file.txt
git revert --continue
```

Opens the editor for the commit message.

### `--abort`

Cancel the entire revert operation and restore the original state:

```bash
git revert --abort
```

### `--quit`

Stop the revert sequence, but **keep the current state** (unlike `--abort`, no rollback):

```bash
git revert --quit
```

### Revert workflow with conflicts

```bash
# Start reverting a range
git revert HEAD~5..HEAD

# Conflict occurs on commit 3 of 5
# Edit and resolve
git add resolved-file.txt
git revert --continue

# Another conflict on commit 4 of 5
# Resolve again
git add resolved-file.txt
git revert --continue

# All 5 reverted successfully
```

---

## Options

| Option | Description |
|--------|-------------|
| `--[no-]edit` | Control whether the editor opens for the commit message |
| `-n` / `--no-commit` | Stage reverse changes without committing |
| `-m <n>` / `--mainline <n>` | Specify parent to keep when reverting a merge |
| `-s` / `--signoff` | Add `Signed-off-by` trailer |
| `-S[<keyid>]` / `--gpg-sign[=<keyid>]` | GPG-sign the revert commit |
| `--continue` | Resume after resolving conflicts |
| `--abort` | Cancel the revert in progress |
| `--quit` | Stop the revert sequence (keep working tree) |
| `--allow-empty` | Create a revert commit even if the diff is empty |
| `--strategy=<strategy>` | Merge strategy to use (`recursive`, `resolve`, `octopus`, `ours`, `subtree`) |
| `-X <opt>` / `--strategy-option=<opt>` | Strategy-specific option (e.g., `-X ours`, `-X patience`) |

### Strategy options (`-X`)

```bash
git revert -X ours HEAD        # In case of conflict, favor our version
git revert -X patience HEAD    # Use patience diff algorithm
```

---

## Comparison: `git revert` vs `git reset`

| Aspect | `git revert` | `git reset` |
|--------|-------------|-------------|
| History | **Adds** a new commit | **Removes** commits (rewrites history) |
| Safety | Safe for shared/public branches | Dangerous for shared branches |
| Commit hash | New hash for the revert commit | Old hash disappears; branch moves |
| Working tree | Only affects HEAD (with `--hard` for reset) | `--soft`, `--mixed`, or `--hard` |
| UI message | Auto-generated revert message | No message (reset is silent) |
| Use case | "Undo this thing" safely | "I want to rewrite my local history" |

### Before and after: `revert` vs `reset`

**Starting state (both commands target `C`):**

```
A──B──C──D  (main, HEAD)
```

**After `git revert HEAD~1` (revert C, keeping D):**

```
A──B──C──D──R  (main, HEAD)
          ^
          R = "Revert C" — C's changes are undone
```

**After `git reset --hard HEAD~1` (remove D):**

```
A──B──C  (main, HEAD)
```

**After `git reset --hard HEAD~2` (remove C and D):**

```
A──B  (main, HEAD)
```

---

## Quick Reference

```bash
# Basic reverts
git revert HEAD                          # Undo last commit
git revert abc123                        # Undo a specific commit
git revert HEAD~3                        # Undo the commit 3 steps back
git revert abc123 def456                 # Revert two specific commits

# Range reverts
git revert HEAD~3..HEAD                  # Revert last 3 commits (3 new commits)
git revert -n HEAD~3..HEAD               # Stage changes, don't commit yet
git commit -m "revert: batch rollback"   # Then commit once

# Merge revert
git revert -m 1 merge-commit-hash        # Revert merge, keep mainline

# Edit control
git revert --no-edit HEAD                # Auto-accept default message
git revert -e HEAD                       # Force editor

# Conflict handling
git revert --continue                    # Resume after resolving
git revert --abort                       # Cancel the revert
git revert --quit                        # Stop revert, keep changes

# Signing
git revert -s HEAD                       # Add Signed-off-by
git revert -S HEAD                       # GPG-sign
git revert -S=KEYID HEAD                 # GPG with specific key

# Strategy
git revert -X ours HEAD                  # In conflicts, keep our version
git revert --strategy=resolve HEAD       # Use resolve strategy

# Edge cases
git revert --allow-empty HEAD            # Create revert even if no diff
```

---

## Sequence Diagram: Revert vs Reset

```
=== git revert ===

Before:
    A──B──C──D  (main, HEAD)

    $ git revert C    # Creates a new commit that undoes C

After:
    A──B──C──D──R  (main, HEAD)
                ^
    C is still there. R is new. Safe to push.

=== git reset ===

Before:
    A──B──C──D  (main, HEAD)

    $ git reset --hard HEAD~1   # Moves HEAD back by 1

After:
    A──B──C  (main, HEAD)
         ^
    D is gone. History rewritten. Unsafe if D was pushed.

=== git revert range (without -n) ===

Before:
    A──B──C──D──E──F  (main, HEAD)

    $ git revert HEAD~3..HEAD   # Revert D, E, F (oldest first)

After:
    A──B──C──D──E──F──R(D)──R(E)──R(F)  (main, HEAD)

=== git revert range with -n ===

    $ git revert -n HEAD~3..HEAD
    $ git commit -m "revert: D, E, F in one commit"

After:
    A──B──C──D──E──F──R  (main, HEAD)
                      ^
    Single commit undoing D, E, F
```

---

## Real-World Examples

### Undo the last commit

```bash
git revert HEAD
```

The most common revert. Creates a commit that undoes whatever `HEAD` introduced.

### Undo a specific bug-introducing commit

```bash
git log --oneline
# a1b2c3d fix: handle edge case
# e5f6g7a BREAKING: refactor payment module  <-- this introduced a bug
# h8i9j0k chore: update deps
git revert e5f6g7a
```

Pinpoints the bad commit and creates a targeted revert.

### Revert 3 commits in one go (no-commit mode)

```bash
git revert --no-commit HEAD~3..HEAD
git commit -m "revert: roll back unstable feature commits"
```

Useful when reverting a feature that spanned multiple commits and you want a single clean revert entry in the log.

### Revert a merge commit (keep mainline)

```bash
# abc123 is a merge of 'feature' into 'main'
git revert -m 1 abc123
```

This keeps all changes that were on `main` before the merge and drops changes that came from `feature`.

### Cancel a revert in progress

```bash
git revert HEAD~5..HEAD
# Conflict occurs on commit 3 of 5
# Realized it's the wrong approach
git revert --abort
```

Returns the repository to the exact state before the revert was started.

### Add a Signed-off-by trailer

```bash
git revert -s HEAD
```

The revert commit message will include `Signed-off-by: Your Name <you@example.com>`. Required in projects that enforce a Developer Certificate of Origin (DCO).

### Revert two specific commits without committing

```bash
git revert -n abc123 def456
git diff --staged        # Review the combined reverse changes
git commit -m "revert: undo abc123 and def456"
```

Stages the inverse of both commits so you can review and commit as one.

### Accept the default message without editing

```bash
git revert --no-edit HEAD
```

For an automated or scripted workflow where the generated message is acceptable.

### Use a different merge strategy

```bash
git revert --strategy=recursive -X theirs HEAD
```

If the revert conflicts, automatically favor the version from the branch being reverted.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Cannot revert a merge without `-m` | Git doesn't know which parent to keep | Add `-m 1` or `-m 2` to specify the mainline |
| Reverting a range creates many commits | Each commit in the range creates a separate revert commit | Use `-n` (no-commit) to stage all changes and commit once |
| "Not a valid commit name" for `HEAD~3..HEAD` | Range must be `older..newer` — the left side is excluded | Use `HEAD~3..HEAD` (3 commits) or `HEAD~3^!` for exactly `HEAD~3` |
| Revert of an old commit conflicts | Later commits changed the same code — reverse patch cannot apply cleanly | Resolve conflicts manually, `git add`, then `git revert --continue` |
| Reverted a commit that was already reverted | Applying the same reverse diff again may produce an empty commit | Check `git log --oneline` first; use `--allow-empty` if intentional |
| `git revert HEAD` says "clean" but I expected an undo | HEAD was a merge commit and `-m` was missing | Re-run with `-m 1` |
| Commits in the range appear in wrong order | Git processes range reverts oldest-first to minimize conflicts | This is intentional and correct — it applies reverse patches in topological order |
| `git revert --abort` fails after `--quit` | `--quit` discards the revert state — `--abort` only works during an active revert | You're already past the revert state; use `git reset --hard` if needed |
| Reverted commit reappears after merge into another branch | The original commit still exists in the shared history — a future merge can bring it back | The revert is a new commit; if the original branch is merged again, the revert may need to be cherry-picked forward |
