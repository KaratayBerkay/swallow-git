# `git cherry-pick` — Apply changes from existing commits

`git cherry-pick` applies the changes introduced by one or more existing commits onto the current branch. Instead of merging a whole branch, it plucks individual commits — like copying a single commit's diff and replaying it at your current position.

```
git cherry-pick [--edit] [-n] [-m <parent-number>] [-s] [-x] [--ff] [-S[<keyid>]] [<commit>...]
git cherry-pick (--continue | --skip | --abort | --quit)
```

## Description

`git cherry-pick` takes a commit that exists elsewhere in the repository and **replays its changes** on top of the current HEAD. The resulting commit is a **new** commit with a new hash, different committer timestamp, and the current branch's HEAD as its parent.

```
Before:
    A ── B ── C ── D  (main, HEAD)
          \
           E ── F    (feature)

git cherry-pick F  (while on main)

After:
    A ── B ── C ── D ── F'  (main, HEAD)
          \
           E ── F           (feature)
          F' = new commit with same diff as F, but different parent/hash
```

Each replayed commit produces one new commit (unless `-n` is used).

---

## Basic Usage

### `git cherry-pick abc123`

Pick a single commit by its hash:

```bash
git cherry-pick abc123
```

The changes from `abc123` are replayed on top of your current branch. A new commit is created with a new hash, the same author and message, but the current timestamp and HEAD as parent.

### `git cherry-pick abc123 def456`

Pick multiple specific commits. They are processed in order (left to right):

```bash
git cherry-pick abc123 def456
```

This creates two new commits: first the changes from `abc123`, then the changes from `def456`.

---

## Cherry-Pick a Range of Commits

Use revision range syntax to cherry-pick a contiguous set of commits:

```bash
git cherry-pick A..B
```

This picks commits from `A` to `B` **excluding** `A` itself (i.e., `A` is not included, `B` is included).

To **include** `A`:

```bash
git cherry-pick A^..B
```

The `A^` means "the parent of `A`", so the range `A^..B` includes `A`.

### Examples

```bash
git cherry-pick HEAD~3..HEAD      # Pick last 3 commits (HEAD~2, HEAD~1, HEAD)
git cherry-pick abc123..def456    # Picks commits after abc123 up to def456
git cherry-pick main..feature     # Pick all commits on feature not on main
```

### Range syntax

| Syntax | Commits picked |
|--------|----------------|
| `HEAD~3..HEAD` | `HEAD~2`, `HEAD~1`, `HEAD` (last 3) |
| `abc123..def456` | Commits after `abc123` up to `def456` (excludes `abc123`) |
| `abc123^..def456` | Commits from `abc123` up to `def456` (includes `abc123`) |
| `main..feature` | Commits on feature not on main |

---

## No-Commit Mode (`-n` or `--no-commit`)

Stage the cherry-picked changes **without creating a commit**. This lets you pick multiple commits and commit them all at once, or inspect the changes before committing:

```bash
git cherry-pick -n abc123 def456
git diff --cached                # Review the combined changes
git commit -m "feat: combine abc123 and def456"
```

Without `-n`, each commit creates a separate new commit:

```bash
git cherry-pick abc123 def456    # Creates 2 commits
```

With `-n` you squash everything into the working tree and index, then commit once.

---

## Edit and Reference

### `-e` / `--edit`

Force the editor to open so you can modify the commit message:

```bash
git cherry-pick -e abc123
```

The editor opens with `abc123`'s original message pre-filled. You can edit it before committing.

### `-x` — Add "cherry picked from" reference

Add a line to the commit message referencing the original commit hash:

```bash
git cherry-pick -x abc123
```

Resulting commit message:

```
Original commit message

(cherry picked from commit abc123def456...)
```

The `-x` flag adds traceability — useful when cherry-picking between branches (e.g., backporting a fix to a release branch).

---

## Sign-Off (`-s` or `--signoff`)

Add a `Signed-off-by` trailer, certifying you have the right to submit the work. Required by projects that enforce a Developer Certificate of Origin (DCO):

```bash
git cherry-pick -s abc123
```

Result:

```
Original commit message

Signed-off-by: Your Name <you@example.com>
```

---

## Mainline (`-m <parent-number>`)

**Required when cherry-picking a merge commit.** Git needs to know which parent's diff to apply. A merge commit has multiple parents, and the diff against each parent is different — `-m` tells Git which parent to diff against.

```bash
git cherry-pick -m 1 merge-commit-hash
```

| `-m` value | What it does |
|------------|-------------|
| `-m 1` | Diff against first parent (usually the target branch, e.g., `main`) |
| `-m 2` | Diff against second parent (usually the feature branch) |

`-m 1` means: "treat the merge as the changes that came from the second parent into the first" — it cherry-picks the diff that the merge brought in.

```
State before cherry-pick:

    main:      ──A──B──C──M──D
                         /
    feature:        X──Y──Z

git cherry-pick -m 1 M replays the diff of (M - parent1) = changes from X, Y, Z
```

**Without `-m`**, cherry-picking a merge commit fails with:

```
fatal: Commit abc123 is a merge but no -m option was given.
```

---

## Fast-Forward (`--ff`)

If the commit being cherry-picked is an ancestor of HEAD, `--ff` **fast-forwards** HEAD instead of creating a new commit:

```bash
git cherry-pick --ff abc123
```

If `abc123` is already an ancestor of HEAD, Git simply moves the branch pointer forward — no new commit is created. If `abc123` is not an ancestor, `--ff` is ignored and a normal cherry-pick occurs.

```
Before (abc123 is an ancestor of HEAD):
    A ── B ── C ── D      (HEAD is D, abc123 is C)

git cherry-pick --ff C:

After (HEAD fast-forwarded, no new commit):
    A ── B ── C ── D      (no change — HEAD is already past C)
```

More useful when cherry-picking a commit that is ahead of HEAD:

```
Before:
    A ── B                 (HEAD)
          \
           C ── D          (feature, abc123 = D)

git cherry-pick --ff D:

After (fast-forward):
    A ── B ── C ── D      (HEAD, feature)
```

If `--ff` can apply, no new commit is made — the branch pointer just advances.

---

## Sequence Commands

When a cherry-pick hits a conflict or you need to control the multi-commit process:

### `--continue`

After resolving conflicts, resume the cherry-pick:

```bash
git add resolved-file.txt
git cherry-pick --continue
```

Opens the editor for the commit message.

### `--abort`

Cancel the entire cherry-pick sequence and restore the original state (HEAD and working tree go back to before the cherry-pick started):

```bash
git cherry-pick --abort
```

### `--quit`

Stop the cherry-pick sequence but **keep the current state** (unlike `--abort`, no rollback):

```bash
git cherry-pick --quit
```

### `--skip`

Skip the current commit and continue with the next one in the sequence. The problematic commit's changes are discarded:

```bash
git cherry-pick --skip
```

### Sequence lifecycle

```bash
# Start cherry-picking a range
git cherry-pick HEAD~5..HEAD

# Conflict on commit 3 of 5
# Resolve, stage, continue
git add src/conflict.js
git cherry-pick --continue

# Another conflict on commit 4 — skip it entirely
git cherry-pick --skip

# Conflict on commit 5 — give up
git cherry-pick --abort
# Working tree is restored to pre-cherry-pick state
```

---

## Options

| Option | Description |
|--------|-------------|
| `-e` / `--edit` | Open editor to modify the commit message |
| `-n` / `--no-commit` | Stage changes without committing |
| `-m <n>` / `--mainline <n>` | Specify parent to diff against for merge commits |
| `-s` / `--signoff` | Add `Signed-off-by` trailer |
| `-x` | Add "cherry picked from" reference to message |
| `--ff` | Fast-forward if the commit is an ancestor of HEAD |
| `-S[<keyid>]` / `--gpg-sign[=<keyid>]` | GPG-sign the resulting commit |
| `--continue` | Resume after resolving conflicts |
| `--skip` | Skip the current commit in the sequence |
| `--abort` | Cancel the cherry-pick in progress |
| `--quit` | Stop the cherry-pick sequence (keep working tree) |

---

## Quick Reference

```bash
# Basic cherry-pick
git cherry-pick abc123                        # Pick a single commit
git cherry-pick abc123 def456                 # Pick two specific commits

# Range cherry-pick
git cherry-pick HEAD~3..HEAD                  # Pick last 3 commits
git cherry-pick main..feature                 # Pick commits on feature not on main
git cherry-pick A^..B                         # Include A in the range

# No-commit (squash)
git cherry-pick -n abc123 def456              # Stage changes without committing
git commit -m "feat: squashed changes"        # Commit once

# Edit and reference
git cherry-pick -e abc123                     # Edit commit message
git cherry-pick -x abc123                     # Add "cherry picked from" reference

# Sign
git cherry-pick -s abc123                     # Add Signed-off-by
git cherry-pick -S abc123                     # GPG-sign
git cherry-pick -S=KEYID abc123              # GPG-sign with specific key

# Merge commit
git cherry-pick -m 1 merge-commit             # Cherry-pick merge, using parent 1

# Fast-forward
git cherry-pick --ff abc123                   # Fast-forward if possible

# Sequence control
git cherry-pick --continue                    # Resume after resolving conflicts
git cherry-pick --skip                        # Skip current commit
git cherry-pick --abort                       # Cancel the cherry-pick
git cherry-pick --quit                        # Stop, keep current state
```

---

## Real-World Examples

### Pick a bugfix commit to the current branch

```bash
git checkout release/v1.0
git cherry-pick abc123
```

Backport a fix that was committed on `main` to a release branch. The commit `abc123` is replayed on `release/v1.0`.

### Pick a commit with traceability

```bash
git cherry-pick -x abc123
```

The commit message will include `(cherry picked from commit abc123...)`, making it clear where the change originated. Standard practice for backporting.

### Squash multiple cherry-picks into one commit

```bash
git cherry-pick -n abc123 def456
git commit -m "fix: apply hotfix abc123 and def456"
```

Stages the changes from both commits into the index, then commits once. Useful when two commits together form one logical fix.

### Cherry-pick a merge commit

```bash
git cherry-pick -m 1 abc123
```

Required when the target commit is a merge. `-m 1` means "diff against the first parent" — effectively picking the changes that were introduced by the merge.

### Pick the last 3 commits from another branch

```bash
git cherry-pick HEAD~3..HEAD
```

Picks the three most recent commits from the current branch's history. The range `HEAD~3..HEAD` includes `HEAD~2`, `HEAD~1`, and `HEAD`.

### Abort a cherry-pick in progress

```bash
git cherry-pick HEAD~5..HEAD
# Conflict on commit 3 of 5
# Realized this was a bad idea
git cherry-pick --abort
```

Returns the repository to the exact state before the cherry-pick started.

### Fast-forward cherry-pick

```bash
git cherry-pick --ff abc123
```

If `abc123` is an ancestor of HEAD, Git fast-forwards instead of creating a new commit. No duplicate commits when the change is already in the branch history.

### Pick and sign off

```bash
git cherry-pick -s abc123
```

Adds `Signed-off-by: Your Name <you@example.com>` to the new commit. Useful when cherry-picking patches from external contributors.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| "is a merge but no -m option was given" | Cherry-picking a merge commit without telling Git which parent to diff against | Add `-m 1` (keep target branch) or `-m 2` (keep feature branch) |
| Cherry-pick creates duplicate commits | Cherry-picking a commit that already exists in the current branch history | Use `--ff` to fast-forward instead if the commit is an ancestor, or check with `git log` first |
| Conflicts during cherry-pick | The diff from the source commit doesn't apply cleanly to the current branch | Resolve conflicts, `git add`, then `git cherry-pick --continue` |
| Cherry-pick of a range replays too many commits | `A..B` excludes A — you may have mis-specified the range | Use `A^..B` to include `A`, or double-check with `git log A..B` |
| "The previous cherry-pick is now empty" | The same changes are already present — cherry-pick produces an empty diff | `git cherry-pick --skip` to move on, or `--abort` to cancel |
| Cherry-picked commit has wrong author date | Cherry-pick preserves the original author timestamp, not the current time | That's the default behavior. Use `git commit --date="now"` after `-n` to override |
| Cherry-pick across unrelated branches fails | Branches diverged significantly — the diff cannot be applied cleanly | Resolve conflicts manually, or consider using `git format-patch` + `git am` |
| `git cherry-pick --abort` fails after `--quit` | `--quit` discards the cherry-pick state — `--abort` cannot roll back | You're past the cherry-pick state; use `git reset --hard` if needed |
| Cherry-pick succeeds but the resulting code doesn't compile | The change depends on other commits that weren't picked | Review which commits you need — you may need to cherry-pick a range, not a single commit |
