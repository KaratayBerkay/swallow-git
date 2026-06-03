# `git status` — Show the working tree status

`git status` displays the state of the working tree and the staging area. It tells you what's been modified, what's staged, and what's untracked — relative to the current commit (HEAD). It's the first command to run when you need to understand where you are in the Git workflow.

```
git status [<options>] [--] [<pathspec>...]
```

---

## Description

`git status` shows three categories of changes:

| Section | Meaning |
|---------|---------|
| **Changes to be committed** | Files in the staging area — will be included in the next `git commit` |
| **Changes not staged for commit** | Tracked files modified but not yet staged |
| **Untracked files** | Files not tracked by Git (not in the index, not in `.gitignore`) |

---

## Basic Usage

### `git status` — default (long format)

```bash
git status
```

Output:

```
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   src/main.py
        new file:   src/utils.py

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   README.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        notes.txt
```

### `git status -s` — short format

```bash
git status -s
```

Compact two-column output, one file per line:

```
M  src/main.py
A  src/utils.py
 M README.md
?? notes.txt
```

### `git status -b` — branch info

```bash
git status -b
```

Shows the branch line at the top (same as the first line of long format). Can be combined with `-s`:

```bash
git status -sb
```

Output:

```
## main...origin/main [behind 3]
 M README.md
?? notes.txt
```

---

## Status Codes (Short Format)

Each file is shown with two columns of status codes:

| Code | Meaning |
|------|---------|
| `??` | Untracked |
| `!!` | Ignored (with `--ignored`) |
| ` ` | Unmodified |
| `M` | Modified |
| `A` | Added |
| `D` | Deleted |
| `R` | Renamed |
| `C` | Copied |
| `U` | Updated but unmerged |
| `T` | Type changed (file → symlink, etc.) |

The two columns represent: **left** = staging area vs HEAD, **right** = working tree vs staging area.

| Example | Meaning |
|---------|---------|
| ` M` | Modified in working tree, not staged |
| `M ` | Staged modification |
| `MM` | Staged modification, then further modified in working tree |
| `A ` | Staged new file |
| `AM` | Staged new file, then modified in working tree |
| ` D` | Deleted in working tree (not staged) |
| `D ` | Staged deletion |
| `R ` | Staged rename |
| `RM` | Staged rename, then modified in working tree |
| `C ` | Staged copy |
| `??` | Untracked |
| `!!` | Ignored (requires `--ignored`) |

---

## Output Formats

### Long format (default)

```bash
git status              # long format (default)
git status --long       # explicit long format
```

Full human-readable output with section headers, hints, and descriptions.

### Short format

```bash
git status -s
git status --short
```

Compact output — two status columns per file. Designed for terminal use when you want a quick overview.

### Porcelain format (machine-readable)

```bash
git status --porcelain              # v1 by default
git status --porcelain=v1           # explicit v1
git status --porcelain=v2           # v2 — richer format
```

**v1** is identical to `--short` but guaranteed stable across Git versions — safe for scripts. No hints, no colors, no section headers.

**v2** adds more detail per line:

```
1 .M N... 100644 100644 100644 abc123 def456 README.md
1 M. N... 100644 100644 100644 abc123 def456 src/main.py
? notes.txt
```

v2 lines are prefixed with a data type:
| Prefix | Meaning |
|--------|---------|
| `1` | Ordinary tracked file |
| `2` | Renamed/copied (includes similarity) |
| `u` | Unmerged |
| `?` | Untracked |
| `!` | Ignored |

---

## Ignored Files

### `--ignored`

```bash
git status --ignored
```

Shows ignored files in their own section. Combined with `--short` shows `!!` prefix:

```bash
git status --short --ignored
```

Output:

```
 M README.md
?? notes.txt
!! .env
!! node_modules/
```

### `--untracked-files=<mode>` / `-u<mode>`

Controls how untracked files are reported:

| Mode | Behavior |
|------|----------|
| `normal` (default) | Shows untracked directories and files |
| `all` (`-u`) | Shows individual files inside untracked directories |
| `no` | Hides all untracked files entirely |

```bash
git status -u                 # list individual untracked files (recursive)
git status --untracked-files=no   # hide all untracked files
git status -unormal           # default — show untracked dirs as a group
```

---

## Submodules

### `--recurse-submodules`

```bash
git status --recurse-submodules
```

Shows status of all submodules recursively — dirty state, new commits, untracked files inside each submodule.

### `--ignore-submodules=<mode>`

| Mode | Behavior |
|------|----------|
| `none` | Show all submodule changes (default) |
| `untracked` | Ignore untracked files in submodules |
| `dirty` | Ignore all changes in submodule working trees |
| `all` | Completely ignore submodules |

```bash
git status --ignore-submodules=dirty    # only show new commits in submodules
```

---

## Rename and Copy Detection

### `--renames` / `--no-renames`

```bash
git status --renames      # detect renames (default in modern Git)
git status --no-renames   # don't detect renames
```

With `--no-renames`, a renamed file shows as `D` (old name) + `??` (new name) instead of `R`.

### `--find-renames=<n>`

```bash
git status --find-renames=50    # 50% similarity threshold (default)
git status --find-renames=80    # require 80% similarity
git status --find-renames=30    # more aggressive rename detection
```

Only meaningful when used with `--renames`. Lower values detect more renames but may produce false positives.

---

## Branch and Stash

### `-b` / `--branch`

```bash
git status -b
git status --branch
```

Includes the branch line even in short/porcelain mode:

```
## main...origin/main [ahead 2, behind 1]
```

The branch line format:
```
## <branch>[...<upstream> [<ahead-behind>]]
```

### `--show-stash`

```bash
git status --show-stash
```

Shows the number of stash entries at the end of the output:

```
Your stash currently has 3 entries
```

---

## Column Display

### `--column` / `--no-column`

```bash
git status --column                  # display untracked files in columns
git status --column=always           # always use columns
git status --column=auto             # use columns when output is to terminal
git status --no-column               # never use columns (default)
```

Column options:

| Value | Behavior |
|-------|----------|
| `always` | Always columnate |
| `auto` | Columnate for terminals only (default for `--column`) |
| `never` / `no` | Never columnate |
| `plain` | No colors or decorations |
| `dense` | Dense formatting |
| `nodense` | Default spacing |
| `row` | Fill rows first (default) |
| `column` | Fill columns first |

```bash
git status --column=row,dense   # fill by rows with tight spacing
```

---

## Path Filtering

Restrict status to specific paths:

```bash
git status -- src/                  # only files under src/
git status -- README.md             # status of a specific file
git status -- "*.py"                # only Python files
git status -- . ':!node_modules/'   # exclude node_modules
```

The `--` separator tells Git that everything after it is a path, not an option. Useful when a file or directory name starts with `-`.

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
[status]
    short = true                         # default to --short
    branch = true                        # show branch in short format
    showUntrackedFiles = normal          # normal, all, or no
    submoduleSummary = true              # include submodule summary
    aheadBehind = true                   # show ahead/behind in short format

[color "status"]
    header = yellow
    added = green
    changed = red
    untracked = magenta bold
    ignored = cyan bold

[status]
    # Display untracked files in columns
    column = auto
```

### Config reference

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `status.short` | `true`, `false` | `false` | Use short format by default |
| `status.branch` | `true`, `false` | `false` | Show branch info in short format |
| `status.showUntrackedFiles` | `normal`, `all`, `no` | `normal` | Untracked files mode |
| `status.submoduleSummary` | `true`, `false` | `false` | Include submodule summary |
| `status.aheadBehind` | `true`, `false` | `true` | Show ahead/behind info |

---

## Quick Reference

```bash
# Basic usage
git status                         # full status
git status -s                      # short format
git status -b                      # with branch info
git status -sb                     # short + branch (popular combo)

# Output formats
git status --long                  # explicit long format
git status --short                 # same as -s
git status --porcelain             # machine-readable v1
git status --porcelain=v1          # explicit v1
git status --porcelain=v2          # richer machine-readable

# Ignored and untracked files
git status --ignored               # show ignored files
git status -u                      # list individual untracked files
git status -uno                    # hide all untracked files
git status --untracked-files=all   # same as -u

# Submodules
git status --recurse-submodules    # recursive submodule status
git status --ignore-submodules=dirty   # skip dirty submodules
git status --ignore-submodules=all     # skip all submodule changes

# Rename detection
git status --renames               # detect renames (default)
git status --no-renames            # disable rename detection
git status --find-renames=60       # custom rename threshold

# Branch and stash
git status --show-stash            # show stash count
git status --branch                # show branch info

# Column display
git status --column                # columnated output
git status --column=always         # always use columns
git status --no-column             # disable columns

# Path filtering
git status -- src/                 # status for a directory
git status -- README.md            # status for a specific file
git status -- "*.py"               # glob pattern
```

### Status code quick reference

```
Column 1 (index vs HEAD):   Column 2 (working tree vs index):
  (space) = unmodified        (space) = unmodified
  M       = modified          M       = modified
  A       = added             D       = deleted
  D       = deleted           ?       = untracked
  R       = renamed           !       = ignored (--ignored)
  C       = copied
  U       = unmerged
  ?       = untracked
  !       = ignored (--ignored)
```

### Common patterns

```
??   = untracked, not staged
 M   = modified, not staged
M    = staged modification
MM   = staged then modified again
A    = staged new file
D    = staged deletion
R    = staged rename
RM   = staged rename, then modified
!!   = ignored file (--ignored)
```

---

## Real-World Examples

### Quick check before committing

```bash
git status
```

Shows staged, unstaged, and untracked files. The first thing to run before `git add`, `git commit`, `git pull`, or `git merge`.

### Short overview

```bash
git status -s
```

```
 M README.md
 M src/main.py
?? notes.txt
```

Compact enough to scan quickly — no section headers or hints.

### Short format with branch

```bash
git status -sb
```

```
## main...origin/main
 M README.md
?? notes.txt
```

### Machine-readable output for scripts

```bash
git status --porcelain
```

```
 M README.md
 M src/main.py
?? notes.txt
```

Stable format guaranteed not to change between Git versions. Colors, hints, and section headers are always suppressed.

### Check for ignored files

```bash
git status --ignored -s
```

```
 M README.md
?? notes.txt
!! .env
!! node_modules/
```

Useful to verify your `.gitignore` is working correctly.

### Hide untracked files

```bash
git status -uno
```

Only shows modifications to tracked files. Useful when there are many generated/scratch files cluttering the output.

### Detect renames

```bash
git status --renames
```

```
Changes to be committed:
  renamed:    old_name.py -> new_name.py
```

Without `--renames`, Git would show `deleted: old_name.py` and `new file: new_name.py`.

### Show stash entries

```bash
git status --show-stash
```

Appends:

```
Your stash currently has 2 entries
```

### Status of a specific directory

```bash
git status -- src/
```

Limits output to files under `src/`. Useful in monorepos or large projects.

### Interpreting `git status` output

**Clean working tree:**
```
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

**Staged changes only:**
```
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   index.html
        modified:   style.css
```

**Unstaged changes only:**
```
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   index.html
```

**Mixed state (staged + unstaged + untracked):**
```
Changes to be committed:
        modified:   index.html

Changes not staged for commit:
        modified:   style.css

Untracked files:
        notes.txt
```

**A file staged and then modified again** appears in both sections:

```
Changes to be committed:
        modified:   index.html

Changes not staged for commit:
        modified:   index.html
```

In short format this shows as `MM`. The staged version is the one that will be committed; the unstaged changes are further edits after `git add`.

**Diverged branch:**
```
On branch feature
Your branch and 'origin/feature' have diverged,
and have 2 and 1 different commits each, respectively.
```

In short format: `## feature...origin/feature [ahead 2, behind 1]`

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git status` shows nothing but files exist | Files may be in `.gitignore` or are untracked in a subdirectory that isn't shown by default | Use `-u` to list untracked files recursively, or `--ignored` to check ignores |
| `git status` says "nothing to commit" but you edited files | The files might be in `.gitignore`, or you're in a subdirectory and only looking at untracked | Run `git status` from repo root, check `.gitignore`, or use `git status -u` |
| Confusing ` M` vs `M ` in short format | First column = staged (index vs HEAD), second column = unstaged (working tree vs index) | Read left-to-right: ` M` = unstaged, `M ` = staged, `MM` = both |
| `--porcelain` output differs from `--short` | They are identical in v1, but `--porcelain` is guaranteed stable; `--short` may change | Always use `--porcelain` in scripts |
| Renamed files show as delete + add | Rename detection may not trigger if files are too dissimilar or `--no-renames` is set | Use `--renames` or configure `diff.renames = true` |
| `--ignored` shows nothing | Only files matching `.gitignore` patterns are shown; if no files match, section is empty | Verify `.gitignore` patterns with `git check-ignore -v <file>` |
| Untracked directories shown as a group by default | `git status` shows untracked directories as a single entry to reduce noise | Use `-u` or `--untracked-files=all` to list individual files |
| `git status` is very slow in large repos | Git re-scans the entire working tree each time | Use `-uno` to skip untracked file scanning, or add common generated dirs to `.gitignore` |
| Branch info shows "up to date" but you expected differences | `git status` compares against the remote tracking branch (`origin/<branch>`), not the remote `main` | Run `git fetch` first to update remote tracking refs |
| `--porcelain=v2` produces unexpected extra columns | v2 adds entry type, submodule status, mode info, and object IDs | Parse carefully — see `git help status` for full v2 format spec |
