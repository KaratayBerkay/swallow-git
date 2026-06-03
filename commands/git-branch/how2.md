# `git branch` — List, create, or delete branches

`git branch` manages your branches — lightweight movable pointers to commits. Use it to list existing branches, create new ones, rename them, delete them, and query which branches contain specific commits.

```
git branch [--color[=<when>] | --no-color] [-r | -a] [--list] [-v [--abbrev=<length> | --no-abbrev]]
          [--column[=<options>] | --no-column] [--sort=<key>]
          [--merged [<commit>]] [--no-merged [<commit>]]
          [--contains [<commit>]] [--no-contains [<commit>]] [--points-at <object>]
          [--format=<format>] [(-d | -D) [-r]] <branchname>...?
git branch --edit-description [<branchname>]
```

---

## What is a Branch?

A branch in Git is just a **movable pointer** to a commit. When you make a new commit, the current branch pointer moves forward automatically.

```
       main
        ▼
a1b2c3d ─── e5f6g7a ─── h8i9j0k
                │
                ▼
             feature-x
```

Creating a branch is instant — it does not copy any files. You simply create a new pointer to the current commit.

---

## Basic Usage

### List branches

```bash
git branch              # List local branches (* marks the current one)
git branch --list       # Same as above (explicit)
```

### Create a branch

```bash
git branch <name>                          # Create at HEAD
git branch <name> <start-point>            # Create at a specific commit/branch/tag
```

### Delete a branch

```bash
git branch -d <name>                       # Safe delete (refuses if unmerged)
git branch -D <name>                       # Force delete (even if unmerged)
```

### Rename a branch

```bash
git branch -m <old> <new>                  # Rename (safe — refuses if <new> exists)
git branch -M <old> <new>                  # Rename (force — overwrites <new> if it exists)
```

---

## Create

### `git branch <name>`

Create a new branch pointing at the current commit:

```bash
git branch feature-x
```

### `git branch <name> <start-point>`

Create a branch starting from any commit, branch, or tag:

```bash
git branch bugfix main                     # Branch from main
git branch experiment abc1234              # Branch from a specific commit
git branch hotfix v1.0.0                   # Branch from a tag
git branch chore origin/main               # Branch from a remote-tracking branch
```

### `git checkout -b <name>`

Create and switch to the new branch in one step:

```bash
git checkout -b feature-x
git checkout -b feature-x main             # Create from main and switch
```

Modern alternative:

```bash
git switch -c feature-x
git switch -c feature-x main
```

### `git branch --orphan <name>`

Create a new branch with **no parent** — starts with an empty index:

```bash
git branch --orphan gh-pages
git rm -rf .                               # Clean up files from the old branch
```

Useful for creating documentation branches, GitHub Pages branches, or entirely separate content trees.

---

## Delete

### `-d` (safe delete)

Delete a branch **only if** it has been fully merged. Git refuses if the branch contains unmerged work:

```bash
git branch -d old-feature
```

### `-D` (force delete)

Delete a branch regardless of merge status:

```bash
git branch -D abandoned-experiment
```

### `-d -r` (delete remote-tracking branch)

Delete a remote-tracking branch (the local cache of a branch on a remote):

```bash
git branch -d -r origin/stale-feature
```

Note: this only deletes your local copy. To delete the branch on the remote itself:

```bash
git push origin --delete stale-feature
```

### Delete multiple branches

```bash
git branch -d feature-a feature-b feature-c
```

### Cleanup merged branches

Delete all local branches that are fully merged into `main`:

```bash
git branch --merged main | grep -v "\* main" | xargs git branch -d
```

---

## List

### `-r` (remote-tracking branches)

List branches tracked from remotes:

```bash
git branch -r
```

Output:
```
  origin/main
  origin/feature-x
  origin/develop
```

### `-a` (all branches)

List both local and remote-tracking branches:

```bash
git branch -a
```

Output:
```
  feature-x
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
  remotes/origin/feature-x
```

### `-v` (verbose)

Show the latest commit hash and subject for each branch:

```bash
git branch -v
```

Output:
```
  feature-x  a1b2c3d Add search bar
* main       e5f6g7a Fix login redirect
```

### `-vv` (verbose with tracking info)

Show which remote branch each local branch tracks, and ahead/behind counts:

```bash
git branch -vv
```

Output:
```
  feature-x  a1b2c3d [origin/feature-x: ahead 2] Add search bar
* main       e5f6g7a [origin/main: behind 1] Fix login redirect
```

The format: `[<remote>/<branch>: ahead <N> | behind <M>]`

### `-q` (quiet)

Suppress informational messages:

```bash
git branch -q -d feature-x
```

### `--column[=<options>]`

Display branches in columns:

```bash
git branch --column
git branch --column=rows
git branch --column=plain     # Single column
```

---

## Filter

### `--merged [<commit>]`

List branches that have been merged into `<commit>` (default: `HEAD`):

```bash
git branch --merged                    # Merged into current branch
git branch --merged main               # Merged into main
git branch --merged --all              # All merged branches (local + remote)
```

### `--no-merged [<commit>]`

List branches that have **not** been merged into `<commit>`:

```bash
git branch --no-merged                 # Unmerged into current branch
git branch --no-merged main            # Unmerged into main
```

### `--contains [<commit>]`

List branches that contain `<commit>`:

```bash
git branch --contains abc1234          # Which branches have this fix?
git branch -a --contains v1.5.0        # Has the release been merged everywhere?
```

### `--no-contains [<commit>]`

List branches that do **not** contain `<commit>`:

```bash
git branch --no-contains abc1234
```

### `--points-at <object>`

List branches that point at a specific commit or tag:

```bash
git branch --points-at abc1234
git branch --points-at v1.0.0
```

---

## Sort

### `--sort=<key>`

Sort branches by a specific field. Prefix with `-` for descending order:

```bash
git branch --sort=-committerdate       # Most recently committed branches first
git branch --sort=committerdate        # Oldest first
git branch --sort=-authordate          # Most recently authored first
git branch --sort=refname              # Alphabetical by ref name
```

Common sort keys:

| Key | Description |
|-----|-------------|
| `refname` | Branch name (alphabetical) |
| `committerdate` | Date of last commit |
| `authordate` | Date of last authored commit |
| `creatordate` | Date the ref was created |
| `version:refname` | Natural version sort (`v1.2` before `v1.10`) |

```bash
git branch --sort=-committerdate -v    # Verbose, sorted by recency
git branch --sort=version:refname      # Sort with version awareness
```

---

## Rename

### `-m` (rename)

Rename a branch. Refuses if the new name already exists:

```bash
git branch -m old-name new-name
git branch -m feature-x                # Rename current branch to feature-x
```

### `-M` (force rename)

Rename even if the new name already exists (overwrites it):

```bash
git branch -M OLD-NEW-NAME
```

### `-m` and remote

Renaming a local branch does **not** rename the remote branch. After renaming locally, update the remote:

```bash
git branch -m old-name new-name        # Rename locally
git push origin -u new-name            # Push and set upstream
git push origin --delete old-name      # Delete old remote branch
```

---

## Copy

### `-c` (copy)

Create a new branch as a copy of an existing branch:

```bash
git branch -c source-branch copy-branch
git branch -c feature-x feature-x-backup
```

### `-C` (force copy)

Copy even if the destination name already exists (overwrites it):

```bash
git branch -C source-branch existing-branch
```

---

## Set Upstream

### `--set-upstream-to=<remote/branch>`

Set or change the upstream tracking branch:

```bash
git branch --set-upstream-to=origin/feature-x    # Current branch tracks origin/feature-x
git branch --set-upstream-to=origin/main main    # main tracks origin/main
git branch -u origin/feature-x                   # Shorthand
```

Shorthand with push:

```bash
git push -u origin feature-x                     # Push and set upstream in one step
```

### `--unset-upstream`

Remove the upstream tracking configuration:

```bash
git branch --unset-upstream                      # Remove upstream for current branch
git branch --unset-upstream feature-x            # Remove upstream for feature-x
```

### Tracking info display

`-vv` shows upstream relationships:

```bash
git branch -vv
```

---

## Format

### `--format="..."`

Customize branch output with format placeholders:

```bash
git branch --format="%(refname:short) %(upstream) %(objectname)"
```

Output:
```
feature-x refs/remotes/origin/feature-x a1b2c3d...
main      refs/remotes/origin/main       e5f6g7a...
```

### Common placeholders

| Placeholder | Description |
|-------------|-------------|
| `%(refname)` | Full ref name (e.g., `refs/heads/main`) |
| `%(refname:short)` | Short name (e.g., `main`) |
| `%(refname:lstrip=<n>)` | Strip n leading path components |
| `%(refname:rstrip=<n>)` | Strip n trailing path components |
| `%(objectname)` | Full commit hash |
| `%(objectname:short)` | Abbreviated commit hash |
| `%(objecttype)` | Type of object (commit, tag, etc.) |
| `%(objectsize)` | Object size |
| `%(upstream)` | Full upstream ref name |
| `%(upstream:short)` | Short upstream name |
| `%(upstream:track)` | Tracking status (e.g., `[ahead 2, behind 1]`) |
| `%(upstream:track,nobracket)` | Tracking status without brackets |
| `%(HEAD)` | `*` if this is the current branch, empty otherwise |
| `%(committerdate)` | Committer date |
| `%(committerdate:relative)` | Committer date, relative format |
| `%(committerdate:short)` | Committer date, short format (`2025-01-15`) |
| `%(committerdate:iso)` | Committer date, ISO format |
| `%(authordate)` | Author date |
| `%(authorname)` | Author name |
| `%(authoremail)` | Author email |
| `%(subject)` | Subject of the tip commit |
| `%(body)` | Body of the tip commit |
| `%(contents)` | Full contents of the tip commit |
| `%(color:<color>)` | Change color |
| `%(color:reset)` | Reset color |
| `%(align:<width>,<position>)` | Aligned block |
| `%(end)` | End alignment block |
| `%(if:<condition>)` | Conditional start |
| `%(then)` | Then block |
| `%(else)` | Else block |
| `%(end)` | End conditional |

### Conditional formatting

Show tracking status only if there's an upstream:

```bash
git branch --format="%(refname:short)%(if:%(upstream:track))%(then) %(upstream:track)%(end)"
```

### Colored output in format

```bash
git branch --format="%(color:bold green)%(refname:short)%(color:reset) %(color:yellow)%(upstream:short)%(color:reset)"
```

---

## Config & Options

### Color

Control colored output:

```bash
git branch --color                     # Always color (default if output is terminal)
git branch --color=always              # Force color (useful when piping)
git branch --color=auto                # Color only for terminals
git branch --no-color                  # Never color
```

### Column

Control columnar display:

```bash
git branch --column                    # Columns with default options
git branch --column=always             # Always use columns
git branch --column=auto               # Columns only for terminals
git branch --column=row                # Fill rows first
git branch --column=plain              # Single column
git branch --no-column                 # Never use columns
```

Column options are comma-separated:

```bash
git branch --column=always,row,dense
```

### Sort in config

Set a default sort order in `.gitconfig`:

```ini
[branch]
    sort = -committerdate
```

### `--abbrev=<length>` / `--no-abbrev`

Control commit hash abbreviation in verbose mode:

```bash
git branch -v --abbrev=12             # 12-character hashes
git branch -v --no-abbrev             # Full hashes
```

### `--no-track`

Create a branch without setting up tracking:

```bash
git branch --no-track experiment      # No upstream configured
```

### `--edit-description`

Set or edit a description for a branch (used by `git merge --log`, `git format-patch`, and some GUIs):

```bash
git branch --edit-description feature-x
git branch --edit-description          # Edit description for current branch
```

---

## Quick Reference

```bash
# List
git branch                             # List local branches
git branch -r                          # List remote-tracking branches
git branch -a                          # List all branches (local + remote)
git branch -v                          # Verbose: hash + message
git branch -vv                         # Tracking info (+ ahead/behind)

# Create
git branch <name>                      # Create at HEAD
git branch <name> <start>              # Create from a specific point
git checkout -b <name>                 # Create and switch
git switch -c <name>                   # Create and switch (modern)

# Delete
git branch -d <name>                   # Safe delete (merged only)
git branch -D <name>                   # Force delete
git branch -d -r <remote>/<name>       # Delete remote-tracking branch

# Rename
git branch -m <old> <new>              # Rename (safe)
git branch -M <old> <new>              # Rename (force)

# Copy
git branch -c <src> <dst>              # Copy (safe)
git branch -C <src> <dst>              # Copy (force)

# Upstream
git branch -u <remote>/<branch>        # Set upstream for current
git branch --unset-upstream <name>     # Remove upstream

# Filter
git branch --merged                    # Merged into HEAD
git branch --no-merged                 # Not merged into HEAD
git branch --contains <commit>         # Branches containing commit
git branch --no-contains <commit>      # Branches NOT containing commit
git branch --points-at <object>        # Branches pointing at object

# Sort
git branch --sort=-committerdate       # Most recent first
git branch --sort=committerdate        # Oldest first

# Format
git branch --format="%(refname:short) %(upstream:short)"

# Options
git branch --color                     # Force colored output
git branch --column                    # Columnar display
git branch --sort=-committerdate -vv   # Combined: recency + tracking
```

---

## Real-World Examples

```bash
# Create a feature branch
git branch feature-x

# Create and switch to a feature branch
git checkout -b feature-x
git switch -c feature-x                # Modern alternative

# Delete a fully merged branch
git branch -d old-branch

# Delete an unmerged branch (destroying work)
git branch -D unmerged-branch

# List all branches with last commit details
git branch -a -v

# Delete all branches merged into main (except main itself)
git branch --merged main | grep -v "\* main" | xargs git branch -d

# Rename a branch
git branch -m old-name new-name

# Rename current branch
git branch -m new-name

# Set upstream tracking
git branch --set-upstream-to=origin/main

# Show branches sorted by most recently committed
git branch --sort=-committerdate

# Show branches sorted by recency with full tracking info
git branch --sort=-committerdate -vv

# Find branches containing a specific commit
git branch --contains abc123

# Find branches NOT containing a fix
git branch -a --no-contains abc123

# Show branches that have NOT been merged into main
git branch --no-merged main

# Create a branch from a tag
git branch hotfix v1.0.0

# Copy a branch as backup
git branch -c feature-x feature-x-backup

# Force rename (overwrites destination)
git branch -M NEW-NAME

# Custom format with tracking
git branch --format="%(refname:short) | upstream: %(upstream:short) | %(committerdate:relative)"

# Custom format with colors
git branch --format="%(color:bold cyan)%(refname:short)%(color:reset) %(color:yellow)%(upstream:short)%(color:reset)"

# Find stale branches (no commit in 3 months)
git branch --sort=-committerdate --format="%(committerdate:short) %(refname:short)" | awk '$1 < "2025-01-01"'

# Create an orphan branch (no parent history)
git branch --orphan gh-pages

# Clean up local tracking branches for deleted remotes
git remote prune origin

# Delete remote branch
git push origin --delete stale-branch
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git branch -d` refuses with unmerged | Safe delete only works for merged branches | Check with `git branch --merged`, or use `-D` if you're sure |
| `git branch -m` fails because new name exists | `-m` is safe — refuses to overwrite | Use `-M` to force rename (overwrites destination) |
| Renamed a local branch but remote still has old name | `-m` only renames locally — remote is unaffected | `git push origin -u new-name && git push origin --delete old-name` |
| `git branch -a` shows a remote branch as `origin/HEAD` | This is a symbolic ref pointing to the default branch on remote | It's informational — you can ignore it |
| Deleted a branch and think the commits are gone | Only the **pointer** is deleted. Commits are still there (until garbage collection) | Use `git reflog` or `git fsck --lost-found` to recover |
| `git branch --merged` includes the current branch | The current branch is always considered merged into itself | Filter it out: `git branch --merged | grep -v "\*"` |
| `git branch --no-merged` shows all branches after a fast-forward merge | Fast-forward merges don't create a merge commit — the branch is effectively merged | Use `--merged` to check instead |
| `git branch --contains` is slow in large repos | Git walks the entire DAG to check reachability | Narrow the scope: use `--contains` with `--sort` or pipe to `head` |
| Forgot `-r` with `-d` when deleting a remote-tracking branch | `git branch -d origin/foo` tries to delete a local branch named `origin/foo` | Use `git branch -d -r origin/foo` |
| `git branch --set-upstream-to` says "not a branch" | Target must be a full ref like `origin/feature` | Include the remote prefix: `origin/feature-x`, not just `feature-x` |
| Branch name appears with `remotes/` prefix in `git branch -a` | Remote-tracking branches live under `refs/remotes/` | That's the full ref name — the short name is `origin/<branch>` |

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Default sort order for branch listings
[branch]
    sort = -committerdate

# Auto-setup tracking on first push
[push]
    autoSetupRemote = true

# Default display mode for branches (auto/always/never)
[column]
    ui = auto

# Color mode for branch output (auto/always/never)
[color]
    branch = auto
```

```ini
# Explicit color configuration per ref state
[color "branch"]
    current = yellow reverse
    local = green
    remote = cyan
    plain = normal
```

---

## Visual Summary

```
Create                              Delete
─────────────────                   ─────────────────
                                   ┌──────────────┐
  git branch feature-x   ─────────►│ feature-x    │
  (at HEAD)              ─────────►│ a1b2c3d Fix  │
                                   └──────────────┘
                                                    git branch -d feature-x ────► ✗ removed
                                   ┌──────────────┐
  git branch feature-x main ──────►│ feature-x    │
  (at main's tip)           ──────►│ e5f6g7a Add  │  ──► git branch -D force ──► ✗ removed
                                   └──────────────┘

List / Filter                                        
─────────────────                                   
  git branch ──────────► * main                      
                          feature-x (local only)      
  git branch -a ────────► * main                     
                          feature-x                  
                          remotes/origin/feature-x   
  git branch -vv ───────► * main e5f6g7a [origin/main: behind 1] Fix login
                          feature-x a1b2c3d [origin/feature-x: ahead 2] Add search

Rename / Copy                Upstream
─────────────────            ─────────────────
  old-name ──(-m)──► new-name    git branch -u origin/feature-x
                                         │
  source ──(-c)──► copy                main tracks origin/main
```
