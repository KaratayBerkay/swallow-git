# `git merge` — Join two or more development histories together

`git merge` integrates changes from one or more branches into the current branch. It combines divergent lines of development, creating a merge commit that has two (or more) parents.

```
git merge [-n] [--stat] [--no-commit] [--squash] [--[no-]edit] [--no-verify]
          [-s <strategy>] [-X <strategy-option>] [-S[<keyid>]]
          [--[no-]rerere-autoupdate] [-m <msg>] [-F <file>] [--into-name <branch>]
          [<commit>...]

git merge (--continue | --abort | --quit)
```

---

## Description

`git merge` joins two or more development histories. When you merge branch B into branch A, Git finds the **merge base** (the most recent common ancestor) and applies the changes from B on top of A.

```
Before merge:
    A ── A1 ── A2             main
         \
          B1 ── B2 ── B3     feature

After merge (main):
    A ── A1 ── A2 ─────────── M
         \                  /
          B1 ── B2 ── B3 ──
```

Common scenarios:
- Integrate a completed feature branch back into `main`
- Pull changes from a remote tracking branch (`git pull` = `git fetch` + `git merge`)
- Apply upstream changes into a long-lived feature branch

---

## Basic Usage

### `git merge <branch>`

Merge `<branch>` into the current branch:

```bash
git checkout main
git merge feature
```

This merges the `feature` branch into `main`.

### `git merge <branch1> <branch2>`

Merge multiple branches at once (creates an octopus merge):

```bash
git merge feature-a feature-b feature-c
```

All branches are merged into the current branch in a single merge commit.

### `git merge --no-commit <branch>`

Perform the merge but **stop before creating the merge commit**. Useful for inspection or additional changes:

```bash
git merge --no-commit feature
git diff --cached
git merge --continue
```

---

## Fast-Forward Merge

When the current branch has **not diverged** from the branch being merged, Git defaults to a **fast-forward**: it simply moves the branch pointer forward.

```
Before:     A ── B ── C (main)
                    └── D ── E (feature)

git checkout main
git merge feature   # fast-forward

After:      A ── B ── C ── D ── E (main, feature)
```

No merge commit is created — the history remains linear.

### `--no-ff` — Force a merge commit

Create a merge commit even when a fast-forward is possible:

```bash
git merge --no-ff feature
```

```
Before:     A ── B ── C (main)
                    └── D ── E (feature)

After:      A ── B ── C ─────── M (main)
                    \          /
                     └── D ── E
```

Use `--no-ff` to preserve the explicit branch topology in history.

### `--ff-only` — Fail if not fast-forwardable

Only proceed if the merge can be done as a fast-forward:

```bash
git merge --ff-only feature
# error: Not possible to fast-forward, aborting.
```

Useful in CI/CD pipelines or when you want to guarantee linear history.

| Option | Behavior |
|--------|----------|
| `--ff` (default) | Fast-forward when possible, merge commit otherwise |
| `--no-ff` | Always create a merge commit |
| `--ff-only` | Only fast-forward; abort if merge commit would be needed |

---

## Merge Strategies

Git provides several merge strategies, selected with `-s <strategy>`:

| Strategy | Flag | Description |
|----------|------|-------------|
| **recursive** | `-s recursive` | Default for two-branch merges. Detects renames, supports options. |
| **octopus** | `-s octopus` | Default for merging >2 branches. Refuses conflicts. |
| **ours** | `-s ours` | Keep our version entirely. Discards the other branch's changes but records a merge. |
| **subtree** | `-s subtree` | Like recursive, but adjusts for subtree structure. |
| **resolve** | `-s resolve` | Older two-way merge algorithm. Rarely needed. |

### `-s recursive` (default)

The workhorse strategy. Supports many options via `-X`:

```bash
git merge -s recursive feature
```

This is the default — you rarely need to specify it explicitly.

### `-s ours`

Keep the current branch's content entirely. The merge commit records the other branch as a parent, but its changes are discarded:

```bash
git merge -s ours feature
```

Useful for "ghost merging" — recording that a branch was merged without actually applying its changes (e.g., merging an abandoned branch's history).

### `-s octopus`

Used automatically when merging more than two branches:

```bash
git merge feature-a feature-b feature-c
```

Octopus merges fail if there are any conflicts. Each parent is recorded in the merge commit.

### `-s subtree`

Like recursive, but you can merge a subproject into a subdirectory:

```bash
git merge -s subtree feature
```

Git automatically detects the subtree structure.

---

## Strategy Options

Strategy options are passed with `-X <option>`. These modify the behavior of the chosen strategy.

### `-X theirs`

When a conflict occurs, automatically take the **other** (incoming) branch's version:

```bash
git merge -X theirs feature
```

Compare with `-X ours` which takes the current branch's version.

### `-X patience`

Use the patience diff algorithm for rename detection. Produces cleaner merges at the cost of speed:

```bash
git merge -X patience feature
```

### `-X ignore-all-space`

Ignore whitespace changes entirely during merge:

```bash
git merge -X ignore-all-space feature
```

Useful when merging a branch that has reformatting changes.

### `-X ignore-space-change`

Ignore changes in the amount of whitespace (indentation changes, tabs vs spaces):

```bash
git merge -X ignore-space-change feature
```

### `-X rename-threshold=<n>`

Control the similarity threshold for rename detection (0–100):

```bash
git merge -X rename-threshold=50 feature
```

Default is 50%. Lower values detect more renames; higher values require more similarity.

### `-X no-renames`

Disable rename detection:

```bash
git merge -X no-renames feature
```

### Full option reference

Recursive strategy options:

| Option | Description |
|--------|-------------|
| `ours` | Auto-resolve conflicts favoring our version |
| `theirs` | Auto-resolve conflicts favoring their version |
| `patience` | Use patience diff for rename detection |
| `histogram` | Use histogram diff for rename detection |
| `diff-algorithm=<algo>` | Set diff algorithm (myers, patience, histogram, minimal) |
| `ignore-space-change` | Ignore whitespace amount changes |
| `ignore-all-space` | Ignore all whitespace |
| `ignore-space-at-eol` | Ignore whitespace at end of line |
| `ignore-cr-at-eol` | Ignore carriage-return at end of line |
| `renormalize` | Reapply text normalization (e.g., `text=auto`) |
| `no-renormalize` | Do not renormalize |
| `rename-threshold=<n>` | Similarity threshold for renames (default 50) |
| `subtree[=<path>]` | Merge subtree at given path |
| `find-renames[=<n>]` | Enable rename detection (default is on) |
| `no-renames` | Disable rename detection |

---

## 3-Way Merge Explained

A 3-way merge uses three points to compute the result:

```
          Merge Base (common ancestor)
          /        \
         /          \
Our branch       Their branch
         \          /
          \        /
         Merge Result
```

The merge compares these three versions:

1. **Merge base** — the most recent common ancestor of the two branches
2. **Ours** — the current branch (`HEAD`)
3. **Theirs** — the branch being merged in

Git applies changes from **base→theirs** onto **ours**. Only when both sides modified the same region does a conflict occur.

```
File at merge base:
    line A
    line B
    line C

Our version (base→ours changed line B):
    line A
    line B (modified by us)
    line C

Their version (base→theirs changed line C):
    line A
    line B
    line C (modified by them)

Result (no conflict — changes are in different regions):
    line A
    line B (modified by us)
    line C (modified by them)
```

If both sides modify the same region:

```
Our version:
    line A
    line B (changed by us)
    line C

Their version:
    line A
    line B (changed by them differently)
    line C

Result:
    <<<<<<< HEAD
    line B (changed by us)
    =======
    line B (changed by them differently)
    >>>>>>> feature
    ── CONFLICT ──
```

---

## Squash Merge

### `--squash`

Flatten all commits from the merged branch into a single change in the working tree — **no merge commit** is created and no parent relationship is recorded:

```bash
git checkout main
git merge --squash feature
git commit -m "feat: add feature X"
```

This stages the combined changes without committing. You then commit manually.

**Key differences from a regular merge:**

| Aspect | Regular merge | Squash merge |
|--------|---------------|--------------|
| Creates merge commit | Yes | No |
| Preserves branch history | Yes | No |
| Shows parent relationship | Yes (2+ parents) | No (single parent) |
| Ready to push after command | Yes (auto-commits with `--no-edit`) | No (manual `git commit` needed) |
| Can trace original commits | Yes (`git log --first-parent`) | No |

Use squash merges to keep a linear, clean history on `main` when you don't need every intermediate commit from a feature branch.

---

## Abort and Continue

### `--abort`

Abort a merge that has conflicts and restore the pre-merge state:

```bash
git merge --abort
```

This undoes everything — the working tree and index go back to exactly how they were before `git merge` was run.

### `--quit`

Like `--abort`, but leaves the working tree and index as they are (does not restore them):

```bash
git merge --quit
```

Useful if you want to inspect the conflicted state after giving up on the merge.

### `--continue`

After resolving merge conflicts, finalize the merge:

```bash
# 1. Resolve conflicts in files
# 2. Stage the resolved files
git add src/conflicted.py
# 3. Continue the merge
git merge --continue
```

This creates the merge commit. Git will open the editor for the merge message.

You can provide the message inline:

```bash
git merge --continue -m "Merge feature into main with resolved conflicts"
```

---

## Conflict Resolution

When Git cannot automatically merge changes, it leaves **conflict markers** in the affected files.

### Conflict Markers

```
<<<<<<< HEAD
This is our version of the code.
It was changed on the current branch.
=======
This is their version of the code.
It was changed on the incoming branch.
>>>>>>> feature
```

- `<<<<<<< HEAD` — start of our version (current branch)
- `=======` — divider between our and their versions
- `>>>>>>> feature` — end of their version

### Resolution Steps

```bash
# 1. Identify conflicted files
git status
# Shows: both modified: src/main.py

# 2. Open the file and resolve conflicts
# Edit to keep the correct version, remove markers

# 3. Stage the resolved file
git add src/main.py

# 4. Finalize the merge
git merge --continue
```

### `git mergetool`

Launch a visual merge tool to resolve conflicts:

```bash
git mergetool
```

Configure the tool:

```bash
git config merge.tool vimdiff
git config merge.tool meld
git config merge.tool kdiff3
```

### `git diff` during conflicts

Show conflict diffs:

```bash
git diff                     # show conflict regions (combined diff)
git diff --ours              # show changes vs our version
git diff --theirs            # show changes vs their version
git diff --base              # show changes vs merge base
```

### `git checkout --ours` / `--theirs`

Accept one side entirely for a specific file:

```bash
# Accept our version (discard theirs)
git checkout --ours -- src/main.py

# Accept their version (discard ours)
git checkout --theirs -- src/main.py

# Stage after resolution
git add src/main.py
```

### `git log` during conflicts

See how both sides diverged:

```bash
git log --merge -p          # diff of conflicting changes
git log HEAD..MERGE_HEAD    # commits being merged in
git log MERGE_HEAD..HEAD    # commits on current side
```

---

## Log and Stat

### `--log=<n>`

Include up to `<n>` shortlog entries from the merged branches in the merge commit message:

```bash
git merge --log=5 feature
```

Resulting merge message:

```
Merge branch 'feature'

# Commits:
#   Add user authentication
#   Fix login form validation
#   Add session persistence
#   Update tests for auth
#   Bump dependency version
```

### `--stat`

Show a diffstat of the merge in the merge commit message:

```bash
git merge --stat feature
```

This adds file change summaries below the message.

### `-n` (or `--no-stat`)

Suppress the diffstat in the merge message (default is to show it unless `merge.stat` is false):

```bash
git merge -n feature
```

---

## Verify and Sign

### `--verify-signatures`

Verify that the commits being merged are GPG-signed by trusted parties. Abort if any commit lacks a valid signature:

```bash
git merge --verify-signatures signed-branch
```

If verification fails:

```
error: Commit abc123 has an invalid GPG signature
fatal: merge aborted due to invalid GPG signature
```

### `-S[<keyid>]` (or `--gpg-sign`)

Sign the resulting merge commit with GPG:

```bash
git merge -S feature
git merge -S=ABC123DEF feature   # with specific key
```

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Conflict style
[merge]
    conflictStyle = diff3
# Options: merge (default), diff3 (shows merge base), zdiff3

# Fast-forward behavior
    ff = false           # always create merge commit (--no-ff default)
    ff = only            # only allow fast-forward (--ff-only default)

# Default merge tool
    tool = vimdiff

# Log in merge messages
    log = true           # include shortlog in merge commits (default 20)

# Verify signatures by default
    verifySignatures = true

# Rerere (reuse recorded resolution)
    rerere.enabled = true

# Auto-update rerere
    rerere.autoupdate = true
```

| Config | Values | Description |
|--------|--------|-------------|
| `merge.conflictStyle` | `merge`, `diff3`, `zdiff3` | How conflicts are displayed. `diff3` adds the merge base section. |
| `merge.ff` | `true`, `false`, `only` | Default fast-forward behavior. |
| `merge.tool` | `vimdiff`, `meld`, `kdiff3`, etc. | Default merge tool for `git mergetool`. |
| `merge.log` | `true`/`<n>` | Include shortlog in merge messages. |
| `merge.verifySignatures` | `true`, `false` | Require valid GPG signatures on merge. |
| `merge.stat` | `true`, `false` | Show diffstat in merge commit message. |
| `rerere.enabled` | `true`, `false` | Reuse recorded conflict resolutions. |

---

## Quick Reference

```bash
# Basic merge
git merge feature                            # Merge feature into current branch
git merge feature-a feature-b                # Octopus merge (merge multiple)
git merge --no-commit feature                # Merge but don't commit yet

# Fast-forward control
git merge --no-ff feature                    # Force merge commit
git merge --ff-only feature                  # Fail if not fast-forwardable

# Squash
git merge --squash feature                   # Flatten commits, no merge commit
git commit -m "feat: add feature X"          # (must commit manually after)

# Strategy selection
git merge -s recursive feature               # Default two-branch strategy
git merge -s ours feature                    # Discard their changes
git merge -s subtree feature                 # Subtree-aware merge

# Strategy options
git merge -X theirs feature                  # Auto-resolve conflicts: take theirs
git merge -X patience feature                # Cleaner rename detection
git merge -X ignore-all-space feature        # Ignore whitespace
git merge -X rename-threshold=50 feature     # Set rename similarity threshold

# Messages
git merge -m "Merge feature branch" feature  # Custom merge message
git merge --edit feature                     # Edit message before committing
git merge --no-edit feature                  # Use default message (no editor)
git merge -F msg.txt feature                 # Read message from file

# Log and stat
git merge --log=5 feature                    # Include shortlog (5 entries)
git merge --stat feature                     # Show diffstat in message
git merge -n feature                         # No diffstat

# Verify and sign
git merge --verify-signatures feature        # Verify GPG on incoming commits
git merge -S feature                         # Sign the merge commit
git merge -S=KEYID feature                   # Sign with specific key

# Abort and continue
git merge --abort                            # Abort merge, restore pre-merge state
git merge --quit                             # Abort, keep working tree as-is
git merge --continue                         # Finalize after conflict resolution

# Rerere
git merge --rerere-autoupdate                # Auto-apply recorded resolutions
git merge --no-rerere-autoupdate             # Don't auto-apply
```

---

## Real-World Examples

### Merge a feature branch

```bash
git checkout main
git pull origin main
git merge feature
```

Standard workflow: update `main`, merge the feature branch.

### Preserve branch topology with `--no-ff`

```bash
git checkout main
git merge --no-ff feature
```

Use on shared branches where you want every merge to be explicit and traceable.

### Squash merge for a clean history

```bash
git checkout main
git merge --squash feature
git commit -m "feat: implement user dashboard"
```

Intermediate "WIP" commits from the feature branch are collapsed into one clean commit.

### Auto-resolve conflicts with `-X theirs`

```bash
git merge -X theirs feature
```

When you know the incoming branch has the definitive version for all conflicts.

### Abort a conflicted merge

```bash
git merge feature
# CONFLICT in src/main.py
# Merge conflict — decide what to do
git merge --abort
```

Revert everything back to the pre-merge state.

### Verify signatures on a merge

```bash
git merge --verify-signatures signed-branch
```

Only proceed if every commit in `signed-branch` has a valid GPG signature.

### Log merged commits in the message

```bash
git merge --log=5 main
```

When merging `main` into a feature branch, include the last 5 commit subjects in the merge message.

### Handling merge conflicts step by step

```bash
# 1. Start the merge
git checkout main
git merge feature
# >> CONFLICT (content): Merge conflict in src/config.py

# 2. Check the status
git status
#    both modified: src/config.py

# 3. View conflicts
git diff

# 4. Open and resolve
#    Edit src/config.py, remove conflict markers, keep the correct version

# 5. Stage resolved files
git add src/config.py

# 6. Verify other files are clean
git status

# 7. Continue the merge
git merge --continue
# (editor opens — write message, save, close)
```

### Merge with a custom message

```bash
git merge -m "feat: integrate payment gateway" payment-feature
```

Skip the editor and provide the merge message inline.

### Use difftool during conflict resolution

```bash
git config merge.tool meld
git merge feature
# conflicts...
git mergetool
# Meld opens with 3 panels: LOCAL | BASE | REMOTE
```

### Merge main into feature branch

```bash
git checkout feature
git merge main
```

Keep your feature branch up to date with the latest from `main`. This is often preferred over rebasing on shared branches.

### Octopus merge

```bash
git checkout release
git merge feature-a feature-b feature-c
```

Merge several feature branches into a release branch simultaneously.

### Subtree merge

```bash
git merge -s subtree --prefix=lib/somelib upstream/main
```

Merge an external project into a subdirectory of your repository.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Merge conflict markers left in files | Forgot to resolve all conflicts before committing | Search for `<<<<<<<`, `=======`, `>>>>>>>` in tracked files |
| `git merge --abort` doesn't clean everything | `--abort` only restores tracked files — new files created during merge stay | Check `git status` after abort and clean manually |
| Merge commit created when you wanted squash | Default is `--ff` which creates a merge commit when not fast-forwardable | Use `git merge --squash` explicitly |
| `git merge` created a commit even with conflicts | Git can auto-merge some files; only truly conflicted files stop the merge | Check `git status` for unmerged files with `U` status |
| Merged the wrong branch | `git merge feature` merged the wrong feature | `git merge --abort` if still in progress, or `git reset --hard ORIG_HEAD` after commit |
| Divergent history after `git merge` | Fast-forward wasn't possible — Git created a merge commit | Use `git merge --ff-only` to require linear history, or `git rebase` instead |
| Octopus merge fails with conflicts | `-s octopus` refuses to handle conflicts | Merge branches one at a time instead |
| Merge pulled in unexpected changes | Branch being merged was ahead of where you expected | Verify with `git log main..feature` before merging |
| `git merge --squash` didn't auto-commit | Squash merges never auto-commit — they only stage changes | Remember to run `git commit` after `git merge --squash` |
| `-X theirs` silently lost some of our changes | `-X theirs` auto-resolves all conflicts in favor of theirs | Review the result carefully with `git diff --cached` |
| GPG signature verification failed | Not all commits are signed, or `gpg` is not configured | Use `git config merge.verifySignatures false` or sign all commits |
| Merge conflict in binary files | Git cannot auto-merge binary files | Use `git checkout --ours` or `--theirs` for the file |
| Seeing "refusing to merge unrelated histories" | Branches have no common ancestor | Use `--allow-unrelated-histories` if intentional |
| `git merge --continue` fails because nothing is staged | You resolved conflicts but didn't `git add` the files | Run `git add` on all resolved files, then `git merge --continue` |
