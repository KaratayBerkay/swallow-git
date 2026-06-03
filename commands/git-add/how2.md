# `git add` — Add file contents to the staging area

The `git add` command moves changes from your working directory into the **staging area** (also called the **index**). This tells Git which changes you want to include in the next commit.

```
git add [options] [<pathspec>...]
```

## The Staging Area (Index)

Git has three zones:

| Zone | Description |
|------|-------------|
| Working Directory | The files on your disk — where you edit |
| Staging Area (Index) | A snapshot of what will go into the next commit |
| Repository (HEAD) | The last committed state |

`git add` moves changes from **Working Directory → Staging Area**.

You can run `git add` multiple times before committing. It only captures the state of files **at the moment you run it** — if you edit a file again after adding, you must `git add` again to include the new changes.

---

## Pathspec

A **pathspec** tells Git which files to add. It can be:

- A filename: `git add main.py`
- A directory: `git add src/`
- A glob pattern: `git add "*.js"` (quoted to let Git handle the expansion)
- A combination: `git add src/main.py tests/ "*.md"`

If you use an unquoted wildcard, the shell expands it before Git sees it:

```bash
git add *.sh         # shell expands: only .sh files in current directory
git add "*.sh"       # Git expands: includes .sh files in subdirectories too
```

---

## Beginner Options

### `git add <file>`

Stage a single file:

```bash
git add README.md
```

### `git add <directory>/`

Stage all changes inside a directory (including subdirectories):

```bash
git add src/
```

### `git add .`

Stage all changes in the **current directory** and its subdirectories:

```bash
git add .
```

### `git add -A` (or `--all`, or `--no-ignore-removal`)

Stage **all changes across the entire repo**, regardless of your current directory. This includes new files, modified files, and deleted files:

```bash
git add -A
```

**Difference between `.` and `-A`:**

| Command | New files | Modified | Deleted | Works outside current dir? |
|---------|-----------|----------|---------|---------------------------|
| `git add .` | Yes | Yes | Yes | No |
| `git add -A` | Yes | Yes | Yes | Yes |

### `git add -u` (or `--update`)

Stage only **modified and deleted** files that were already tracked. Does **not** add new (untracked) files:

```bash
git add -u
```

Useful when you want to commit updates without accidentally including new scratch files.

### `git add -n` (or `--dry-run`)

Preview what would be staged without actually staging anything:

```bash
git add -n .
```

Combine with `--ignore-missing` to check if specific files would be ignored:

```bash
git add -n --ignore-missing config.yml
```

### `git add -v` (or `--verbose`)

Show each file as it is staged:

```bash
git add -v .
```

Example output:
```
add 'src/main.py'
add 'tests/test_main.py'
```

---

## Intermediate Options

### `git add -f` (or `--force`)

Stage files that are normally ignored (e.g., listed in `.gitignore`):

```bash
git add -f secrets.env
```

Normally `git add` silently skips ignored files. With `-f`, you can force them in.

### `git add -N` (or `--intent-to-add`)

Record that a file **will** be added later. Places an empty entry in the index without staging content:

```bash
git add -N newfile.py
```

This is useful for:
- Seeing unstaged changes with `git diff` for a new file
- Using `git diff --cached` to see what would be committed
- Enabling `git add -p` on a new file

### `git add --no-all` (or `--ignore-removal`)

Add new and modified files, but **ignore deleted files**:

```bash
git add --no-all .
```

This was the default behavior in older versions of Git (`<2.0`).

### `git add --refresh`

Don't add any files — just refresh the stat() information in the index:

```bash
git add --refresh
```

Useful when you know files haven't changed but the index metadata is stale.

### `git add --ignore-errors`

Continue adding files even if some fail due to indexing errors:

```bash
git add --ignore-errors .
```

The command exits with non-zero status but doesn't stop mid-way.

---

## Advanced Options

### `git add -p` (or `--patch`)

Stage changes **hunk by hunk**. Git shows each section of diff and asks what to do:

```bash
git add -p
```

You can target a specific file:

```bash
git add -p src/main.py
```

**Available keys in patch mode:**

| Key | Action |
|-----|--------|
| `y` | Stage this hunk |
| `n` | Do not stage this hunk |
| `q` | Quit — don't stage this or any remaining hunks |
| `a` | Stage this hunk and all later hunks in this file |
| `d` | Don't stage this hunk or any later hunks in this file |
| `g` | Select a hunk to go to |
| `/` | Search for a hunk matching a regex |
| `j` | Go to the next undecided hunk |
| `J` | Go to the next hunk (even if decided) |
| `k` | Go to the previous undecided hunk |
| `K` | Go to the previous hunk (even if decided) |
| `s` | Split the current hunk into smaller hunks |
| `e` | Manually edit the current hunk |
| `p` | Print the current hunk |
| `P` | Print the current hunk using the pager |
| `?` | Print help |

**Real-world scenario:**
You fixed a bug and added debug logging in the same file. You want to commit only the bug fix:

```bash
git add -p src/bugfix.py
# y for the bug fix hunks
# n for the debug logging hunks
git commit -m "fix: null pointer in user lookup"
```

### `git add -i` (or `--interactive`)

Open a full interactive menu for staging:

```bash
git add -i
```

Menu options:

| # | Subcommand | Description |
|---|------------|-------------|
| 1 | status | Show staged vs unstaged changes per path |
| 2 | update | Select files to stage (supports ranges: `2-5 7,9` or `*`) |
| 3 | revert | Unstage selected files (back to HEAD) |
| 4 | add untracked | Stage untracked files |
| 5 | patch | Hunk-by-hunk staging (same as `-p`) |
| 6 | diff | Review diff between HEAD and index |
| 7 | quit | Exit |
| 8 | help | Show help |

The prompt `Update>>` (double `>>`) means you can make multiple selections using ranges like `1-3 5,7-`.

### `git add -e` (or `--edit`)

Open the staged diff in your text editor for manual editing:

```bash
git add -e src/main.py
```

This lets you:
- Delete `+` lines to prevent staging that addition
- Change `-` to space to prevent staging that removal
- Add new `+` lines to stage content not in the working tree

**Warning:** The patch is applied to the index only, not the working tree. Your working tree will appear to "undo" changes you made in the index.

### `git add --chmod=(+/-)x`

Set or remove the executable bit in the index without changing the file on disk:

```bash
git add --chmod=+x script.sh
git add --chmod=-x config.yml
```

Useful when the filesystem doesn't support executable bits (e.g., Windows) but you need them in the repo.

### `git add --renormalize`

Re-apply the "clean" filter to all tracked files. Used after changing line-ending configuration:

```bash
git add --renormalize .
```

Common scenario: you changed `.gitattributes` to fix CRLF/LF issues and need to fix already-committed files. This implies `-u` (only affects already tracked files).

### `git add --pathspec-from-file=<file>`

Read pathspec from a file (or stdin with `-`):

```bash
git add --pathspec-from-file=files-to-stage.txt
```

Using stdin:

```bash
find src -name "*.py" | git add --pathspec-from-file=-
```

With `--pathspec-file-nul`, entries are NUL-separated (useful for filenames with spaces/newlines):

```bash
find src -name "*.py" -print0 | git add --pathspec-from-file=- --pathspec-file-nul
```

### `git add -U<n>` (or `--unified=<n>`)

When used with `-p`, controls the number of context lines shown around each hunk:

```bash
git add -U0 -p   # zero context = max granularity (most, smallest hunks)
git add -U5 -p   # 5 lines of context
```

### `git add --inter-hunk-context=<n>`

Fuse hunks that are close together by showing more context between them:

```bash
git add --inter-hunk-context=5 -p
```

Defaults to 0 (each hunk shown separately).

### `git add --sparse <path>`

Allow staging files outside the sparse-checkout cone:

```bash
git add --sparse config/deploy.yaml
```

Normally, `git add` refuses to update paths outside the sparse-checkout cone because those files may be removed from disk without warning.

### `git add --no-warn-embedded-repo`

Suppress the warning when adding a sub-repository (embedded repo) without using `git submodule add`:

```bash
git add --no-warn-embedded-repo vendor/plugin/
```

---

## Quick Reference

### Basic usage
```bash
git add file              # Stage a single file
git add src/              # Stage a directory
git add .                 # Stage everything in current directory tree
git add -A                # Stage everything in entire repo
git add -u                # Stage only tracked (modified/deleted) files
```

### Dry-run & safety
```bash
git add -n .              # Preview what would be staged
git add -n --ignore-missing file   # Check if file would be ignored
git add -v .              # Verbose: print each staged file
git add --refresh         # Refresh index metadata only
git add --ignore-errors . # Continue even if some files fail
```

### Ignored & untracked files
```bash
git add -f ignored.conf   # Force-add an ignored file
git add -N newfile.py     # Intent to add (placeholder in index)
```

### Interactive staging
```bash
git add -p                # Hunk-by-hunk patch mode
git add -p src/main.py    # Patch mode for one file
git add -i                # Full interactive menu
git add -e src/main.py    # Edit the diff manually
```

### Advanced
```bash
git add --chmod=+x script.sh       # Set executable bit
git add --chmod=-x data.csv        # Remove executable bit
git add --renormalize .            # Fix line endings
git add --pathspec-from-file=list  # Stage files from a list
git add -U0 -p                     # Patch mode with zero context
git add --sparse <path>            # Add outside sparse cone
git add --no-warn-embedded-repo    # Suppress submodule warning
```

### Staging behavior comparison

| Command | New files | Modified files | Deleted files | Scope |
|---------|-----------|----------------|---------------|-------|
| `git add <file>` | Yes | Yes | Yes | Specific file |
| `git add .` | Yes | Yes | Yes | Current dir tree |
| `git add -A` | Yes | Yes | Yes | Entire repo |
| `git add -u` | No | Yes | Yes | Entire repo |
| `git add --no-all` | Yes | Yes | No | Current dir tree |
| `git add -N` | Placeholder | No | No | Specific file |

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Forgot to add after editing | `git add` captures state at the moment you run it. Edits after that won't be staged | Run `git add` again |
| `.gitignore` files are skipped | `git add` ignores ignored files by default | Use `git add -f` |
| `git add .` vs `git add -A` confusion | `.` is scope-limited to current directory; `-A` covers the whole repo | Use `-A` when you want repo-wide staging from any location |
| Committed debug code | Staged entire files with debug logging alongside fixes | Use `git add -p` to stage only the fix hunks |
| `git add -N` then forgot to actually add | `-N` only creates a placeholder, content isn't staged | Follow up with `git add` or use `git commit -a` |

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Continue adding even if some files fail (like --ignore-errors always on)
[add]
    ignoreErrors = true
```

```ini
# Skip Enter key confirmation in interactive mode
[interactive]
    singleKey = true
```

---

## Visual Workflow

```
Working Directory       Staging Area (Index)      Repository (HEAD)
    file.c  ──git add──→  file.c (staged)  ──git commit──→  file.c (committed)
    file.py ──git add -p→  (only hunk 1)    ──git commit──→  (partial commit)

    edit → git add → edit again → git add again → git commit
    (only the second edit is committed — first was already staged)
```

The staging area is your **preparation zone**. Use `git add` to craft exactly what each commit contains, keeping related changes together and unrelated changes separate.
