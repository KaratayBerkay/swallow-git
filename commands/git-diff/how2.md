# `git diff` — Show changes between commits, commit and working tree, etc.

`git diff` shows changes between various states in your repository — the working tree, the staging area (index), and commit objects. It's the primary tool for inspecting **what changed** before committing, reviewing, or merging.

```
git diff [<options>] [<commit>] [--] [<path>...]
git diff [<options>] --cached [<commit>] [--] [<path>...]
git diff [<options>] <commit> <commit> [--] [<path>...]
git diff [<options>] <commit>..<commit> [--] [<path>...]
git diff [<options>] <commit>...<commit> [--] [<path>...]
```

## Description

`git diff` compares two points in Git's three-zone system:

| Comparison | Command | What you see |
|------------|---------|-------------|
| Working Tree vs Index | `git diff` | Unstaged changes |
| Index vs HEAD | `git diff --cached` (or `--staged`) | Staged changes (what will be committed) |
| Working Tree vs HEAD | `git diff HEAD` | Both staged and unstaged changes |
| Two commits | `git diff A B` | Changes between commits |
| Diverged branch | `git diff A...B` | Changes in B since it diverged from A |

### Three-Zone Model

```
Working Tree          Index (Staging)         HEAD (Last Commit)
   │                       │                       │
   │    git diff           │   git diff --cached    │
   └───────────────────────┴───────────────────────┘
   │                                                
   └───────────── git diff HEAD ────────────────────┘
```

---

## Basic Usage

### `git diff` — Unstaged changes

Shows what you've changed but **not yet staged**:

```bash
git diff
```

Example output:

```diff
diff --git a/src/main.py b/src/main.py
index e69de29..d95f3ad 100644
--- a/src/main.py
+++ b/src/main.py
@@ -0,0 +1,3 @@
+def hello():
+    print("hello world")
```

Only tracked files appear. New (untracked) files are not shown — use `git status` to see those.

### `git diff --staged` (or `--cached`) — Staged changes

Shows what's in the staging area that will go into the next commit:

```bash
git diff --staged
git diff --cached         # identical to --staged
```

This compares the **index** against **HEAD**.

### `git diff HEAD` — Both staged and unstaged

Shows the combined diff of all changes since the last commit (staged + unstaged):

```bash
git diff HEAD
```

This compares the **working tree** against **HEAD**.

### `git diff <commit>` — Changes since a commit

Show all changes (staged and unstaged) since a specific commit:

```bash
git diff HEAD~3              # changes since 3 commits ago
git diff abc123              # changes since commit abc123
git diff v1.0                # changes since tag v1.0
git diff origin/main         # changes since remote branch
```

---

## Comparing Commits

### `git diff A B` — Between two commits

```bash
git diff HEAD~3 HEAD                   # last 3 commits
git diff main feature                  # compare branch tips
git diff abc123 def456                 # compare arbitrary commits
git diff v1.0..v1.1                    # same as above
```

### `git diff A..B` — Same as `A B`

The two-dot form is equivalent to the space-separated form:

```bash
git diff main..feature
# same as:
git diff main feature
```

### `git diff A...B` — Merge-base comparison

This shows the changes in **B** that were made since it diverged from **A**:

```bash
git diff main...feature
```

Internally this is `git diff $(git merge-base main feature) feature`.

**Use case:** When reviewing a feature branch, this shows only the changes on the feature branch — not the commits that are already in `main`:

```
main:      ──A──B──C──D──E──F
                          \
feature:                   G──H──I
                           ^^^^--- diff main...feature shows only G, H, I
```

Compare with `git diff main feature` which shows E, F, G, H, I (everything different between the two tips):

```
main:      ──A──B──C──D──E──F
                          \──G──H──I
                          ^^^^^^^^^-- diff main feature shows E, F, G, H, I
```

---

## Path Filtering

Limit the diff to specific files or directories:

```bash
git diff -- src/                          # all files in src/ directory
git diff -- src/main.py tests/test_main.py  # specific files
git diff HEAD -- README.md                # changes to README since HEAD
git diff HEAD~2..HEAD -- "*.py"           # Python files in last 2 commits
git diff -- . ':!node_modules/'           # exclude node_modules
```

The `--` separator tells Git everything after it is a path, not a commit or option. It's needed when a filename could be confused with a branch or tag name.

---

## Diff Algorithms

Git provides four diff algorithms that trade off speed for quality:

| Algorithm | Flag | Description |
|-----------|------|-------------|
| Myers | `--myers` (default) | Greedy algorithm — fast, reasonably good output |
| Minimal | `--minimal` | Produce the smallest possible diff (can be slow) |
| Patience | `--patience` | More legible diffs — better at matching unique lines |
| Histogram | `--histogram` | Extension of patience — often the best output for code |

```bash
git diff --patience                     # slower but often better diffs
git diff --histogram                    # best for code with repeated patterns
git diff --minimal                      # smallest diff possible
git diff --patience -- src/main.py      # patience on a specific file
```

**When to use each:**

- **Myers** — default, fine for most work
- **Patience** — when you see bad hunk alignment (e.g., long functions matched incorrectly)
- **Histogram** — similar to patience but better handles formatted code with repeated patterns
- **Minimal** — rarely needed; can produce confusing output

---

## Context and Format

### Context lines: `-U<n>` (or `--unified=<n>`)

Control how many lines of context surround each hunk:

```bash
git diff -U5                    # 5 lines of context (default is 3)
git diff -U0                    # 0 lines — minimal output
git diff -U10 -- src/           # 10 lines for a directory
```

### `--stat` — Summary statistics

Show a compact summary of which files changed and how many lines:

```bash
git diff --stat HEAD~5 HEAD
```

Output:

```
 src/main.py    | 10 +++++-----
 src/utils.py   |  3 ++-
 tests/test.py  | 21 +++++++++++++++++++++
 3 files changed, 28 insertions(+), 6 deletions(-)
```

### `--shortstat` — Even shorter

Only show the summary line:

```bash
git diff --shortstat HEAD~5 HEAD
# 3 files changed, 28 insertions(+), 6 deletions(-)
```

### `--numstat` — Machine-readable

Tab-separated format: `added deleted filename`:

```bash
git diff --numstat HEAD~5 HEAD
# 10      5       src/main.py
# 3       1       src/utils.py
# 21      0       tests/test.py
```

Useful for scripts and CI pipelines.

### `--name-only` and `--name-status`

Show only the filenames, optionally with their change status:

```bash
git diff --name-only HEAD~5 HEAD        # just filenames
git diff --name-status HEAD~5 HEAD      # filenames with status letter
```

`--name-status` output:

```
M       src/main.py
M       src/utils.py
A       tests/test.py
```

### `--compact-summary`

Extended summary that also notes new/deleted files, symlink changes, and mode changes:

```bash
git diff --compact-summary HEAD~5 HEAD
```

---

## Word and Color

### `--word-diff`

Show differences **within a line** instead of line-by-line:

```bash
git diff --word-diff
```

Output:
```
diff --git a/src/main.py b/src/main.py
--- a/src/main.py
+++ b/src/main.py
@@ -1,4 +1,4 @@
[-old-word-]{+new-word+} other unchanged text
```

Optionally with a render mode:

```bash
git diff --word-diff=color              # use color (default)
git diff --word-diff=plain              # use {+ +} and [- -]
git diff --word-diff=porcelain          # machine-readable format
```

### `--color-words`

Combines `--word-diff` with color highlighting. Equivalent to `--word-diff=color`:

```bash
git diff --color-words
```

### `--color-moved`

Highlight moved blocks of code in different colors:

```bash
git diff --color-moved                  # default mode
git diff --color-moved=zebra            # alternate colors for adjacent blocks
git diff --color-moved=blocks           # show blocks with dimmed text
git diff --color-moved=plain            # no special coloring for moves
```

### `--color-moved-ws`

Control whitespace handling when detecting moved code:

```bash
git diff --color-moved --color-moved-ws=ignore-all-space
git diff --color-moved-ws=allow-indentation-change
```

| Value | Effect |
|-------|--------|
| `no` | Treat whitespace as significant (default) |
| `ignore-space-at-eol` | Ignore changes at end of line |
| `ignore-space-change` | Ignore amount of whitespace |
| `ignore-all-space` | Ignore all whitespace |
| `allow-indentation-change` | Allow indentation to change (very useful for refactoring) |

---

## File Filtering

### `--diff-filter`

Show only files with specific change status:

```bash
git diff --diff-filter=A                # added files only
git diff --diff-filter=M                # modified files only
git diff --diff-filter=D                # deleted files only
git diff --diff-filter=R                # renamed files only
git diff --diff-filter=C                # copied files only
git diff --diff-filter=U                # unmerged files only
```

Combine letters (no spaces):

```bash
git diff --diff-filter=AM               # added or modified
git diff --diff-filter=DR               # deleted or renamed
```

Exclude by using lowercase:

```bash
git diff --diff-filter=m                # everything EXCEPT modified
```

**Status letters:**

| Letter | Meaning |
|--------|---------|
| `A` | Added |
| `M` | Modified |
| `D` | Deleted |
| `R` | Renamed |
| `C` | Copied |
| `U` | Unmerged |
| `T` | Type changed (file → symlink, etc.) |
| `X` | Unknown |

### `-S<string>` — Pickaxe search

Show diffs that introduce or remove a specific string (the **pickaxe**):

```bash
git diff -S"TODO"                      # commits that changed use of "TODO"
git diff -S"function_name" -- src/     # within src/ directory
git diff HEAD~10..HEAD -S"bug_fix"    # search last 10 commits
```

`-S` counts occurrences — a file is shown if the **number of occurrences** of the string changed.

### `-G<regex>` — Regex pickaxe

Like `-S`, but with regex matching:

```bash
git diff -G"TODO|FIXME|HACK"           # changes touching any of these
git diff -G"def \w+\("                 # changes touching function definitions
```

`-G` shows a file if any added/removed line matches the regex.

**Difference between `-S` and `-G`:**

| Flag | Matches |
|------|---------|
| `-S"foo"` | File where count of "foo" lines changed |
| `-G"foo"` | File where any line containing "foo" was added or removed |

---

## Binary and Text

### `--binary`

Output a binary diff that can be applied with `git apply`:

```bash
git diff --binary > changes.patch
```

Includes binary file content (not just "Binary files differ").

### `--text` (or `-a`)

Treat all files as text, even if Git detects them as binary:

```bash
git diff --text
git diff -a
```

Useful when you know a file is effectively text despite Git's binary detection (e.g., certain generated files).

### `--ignore-space-change` (or `-b`)

Ignore changes in the **amount** of whitespace:

```bash
git diff -b                            # ignore indentation changes
```

"Amount" means a tab vs. spaces, or 2 spaces vs. 4 spaces — but not complete removal.

### `--ignore-all-space` (or `-w`)

Ignore **all** whitespace changes entirely:

```bash
git diff -w                            # ignore all whitespace
```

Useful for reviewing logical changes after a reformatting commit.

### `--ignore-blank-lines`

Ignore changes that only add or remove blank lines:

```bash
git diff --ignore-blank-lines
```

---

## Inter-Hunk and Function Context

### `--inter-hunk-context=<n>`

Fuse hunks that are close together by showing extra context between them:

```bash
git diff --inter-hunk-context=5
```

Default is 0 (each hunk is separate). A value of 5 means "if two hunks are within 5 lines of each other, merge them into one."

### `--function-context` (or `-W`)

Show the entire surrounding function around each change:

```bash
git diff -W
git diff --function-context
```

This is language-aware — it finds function boundaries using Git's built-in hunk header patterns for languages like C, Python, Java, etc.

---

## Submodules

### `--submodule`

Show submodule changes inline:

```bash
git diff --submodule                   # default — short format
```

Output:

```
Submodule lib/somelib a1b2c3d..e4f5g6h:
  > New feature added
  < Bug fix removed
```

### `--submodule=log`

Show the git log of submodule changes:

```bash
git diff --submodule=log
```

Output:

```
Submodule lib/somelib a1b2c3d..e4f5g6h (3 commits):
  > Fix null pointer in validate()
  > Add user authentication
  < Remove deprecated API
```

Other submodule diff modes:

| Mode | Description |
|------|-------------|
| `--submodule=short` | Default — just the old/new commit hash |
| `--submodule=log` | Show commit log messages for submodule changes |
| `--submodule=diff` | Show full diff of the submodule content |

---

## Quick Reference

```bash
# Working tree comparisons
git diff                          # unstaged changes (working tree vs index)
git diff --staged                 # staged changes (index vs HEAD)
git diff --cached                 # same as --staged
git diff HEAD                     # all changes since last commit (staged + unstaged)

# Commit comparisons
git diff A B                      # between two commits
git diff A..B                     # same as above
git diff A...B                    # changes in B since diverging from A
git diff HEAD~3 HEAD              # last 3 commits
git diff main feature             # between branch tips

# Path filtering
git diff -- src/                  # limit to a directory
git diff HEAD -- README.md        # specific file vs HEAD
git diff HEAD..HEAD~3 -- "*.py"  # Python files in last 3 commits

# Summary formats
git diff --stat                   # summary statistics
git diff --shortstat              # even shorter
git diff --numstat                # machine-readable
git diff --name-only              # filenames only
git diff --name-status            # filenames with status (A/M/D/R)
git diff --compact-summary        # extended summary

# Diff algorithms
git diff --patience               # more legible diffs
git diff --histogram              # best for repeated patterns
git diff --minimal                # smallest diff possible

# Context control
git diff -U5                      # 5 context lines
git diff -W                       # show entire function context

# Word-level diffs
git diff --word-diff              # word-by-word (not line-by-line)
git diff --color-words            # color word diff

# Color and moves
git diff --color-moved            # highlight moved blocks
git diff --color-moved=zebra      # alternating colors for adjacent blocks
git diff --color-moved-ws=allow-indentation-change

# File filtering
git diff --diff-filter=A          # only added files
git diff --diff-filter=AM         # added or modified
git diff -S"pattern"              # pickaxe search
git diff -G"regex"                # regex pickaxe

# Whitespace and binary
git diff -b                       # ignore indentation changes
git diff -w                       # ignore all whitespace
git diff --ignore-blank-lines     # ignore blank line changes
git diff --binary                 # include binary diffs
git diff -a                       # treat all files as text

# Inter-hunk merging
git diff --inter-hunk-context=5   # merge close hunks

# Submodules
git diff --submodule              # show submodule changes
git diff --submodule=log          # with commit log
```

---

## Real-World Examples

### Unstaged changes (code review before staging)

```bash
git diff
```

Review all working tree changes before deciding what to stage.

### Staged changes — verify before committing

```bash
git add src/main.py
git diff --staged
git commit -m "feat: add user login"
```

Always review what you're about to commit.

### Files changed in the last 5 commits

```bash
git diff --name-only HEAD~5 HEAD
```

Useful for understanding the scope of recent work.

### Summary of changes between branches

```bash
git diff --stat main..feature
```

Shows which files differ between `main` and `feature` branches with line counts.

### Pickaxe — find when a string was introduced

```bash
git diff -S"api_key" -- config.js
```

Shows diffs in `config.js` that touched the string `api_key`.

### Moved code detection

```bash
git diff --color-moved --diff-filter=M
```

Show only modified files and highlight any moved/relocated blocks.

### Word diff for staged changes

```bash
git diff --cached --word-diff
```

See exactly which words within a line were changed — very useful for prose or long strings.

### Changes in the last 3 commits, src/ only

```bash
git diff HEAD~3..HEAD -- src/
```

### Ignore whitespace while reviewing real changes

```bash
git diff -w HEAD~1 HEAD -- src/
```

When the latest commit includes both reformatting and logic changes, `-w` strips the noise.

### See the entire function context

```bash
git diff -W -- src/app.py
```

When fixing a small part of a function, `-W` shows the whole function.

### Analyze test files only

```bash
git diff --diff-filter=AM HEAD~10 -- tests/
```

Show only added and modified files under `tests/` in the last 10 commits.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git diff` shows nothing for new files | Untracked files are not in the index — `git diff` only compares tracked content | Use `git status` or `git diff -N` (intent-to-add) |
| Confusing `A..B` with `A...B` | The three-dot form is subtle — it means "merge-base diff" | Remember: `A..B` = all changes between tips; `A...B` = changes in B since divergence |
| `git diff` vs `git diff HEAD` confusion | `git diff` shows only unstaged changes; `git diff HEAD` shows everything | Use `git diff` to see what's uncommitted, `git diff --staged` for what's staged |
| `--diff-filter` returns nothing | The letter case matters — uppercase includes, lowercase excludes | Use uppercase for specific types: `--diff-filter=AM` |
| `--name-only` and `--name-status` ignore path filtering order | The `--` must come after options when combined | Put `--` last: `git diff --name-only HEAD -- src/` |
| `-S` pickaxe misses the change | `-S` counts occurrences, not line matches | Use `-G"regex"` for pattern matching on changed lines |
| `--stat` shows nothing for large diffs | Output may be in the pager | Use `--stat` with pager disabled: `git --no-pager diff --stat` |
| Forgetting `--` before a path | If a path matches a branch name, Git interprets it as a commit | `git diff HEAD -- filename` not `git diff HEAD filename` |
| `git diff A B` vs `git diff A -- B` | Without `--`, B is a commit; with `--`, B is a path | Use `--` to disambiguate paths from commits |

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Default is 3 context lines
[diff]
    context = 5

# Detect renames (default: true)
    renames = true

# Copy detection (default: false — expensive)
    renames = copies

# Algorithm: myers, patience, histogram, minimal
    algorithm = histogram

# Show word-level diffs by default
    wordRegex = .

# Submodule diff format (short, log, diff)
    submodule = log

# Color settings
[color]
    diff = auto
[color "diff"]
    meta = yellow
    frag = cyan
    old = red bold
    new = green bold
    whitespace = red reverse
[color "diff-highlight"]
    oldNormal = red bold
    oldHighlight = red bold 52
    newNormal = green bold
    newHighlight = green bold 22

# External diff tool (e.g., vimdiff, meld)
[diff]
    tool = vimdiff
[difftool]
    prompt = false
```

---

## Visual Summary

```
Working Tree              Index (Staging)            HEAD (Last Commit)
    │                          │                          │
    │    git diff              │   git diff --cached       │
    ├──── unstaged ───────────►├──── staged ─────────────►│
    │                          │                          │
    │◄──────── git diff HEAD ─────────────────────────────┤
    │                          │                          │
    │◄──── git diff A B ───────┤──────────────────────────┤  (A vs B)
    │                          │                          │
    │◄── git diff A...B ──────┤──────────────────────────┤  (B since merge-base A)
```


| State | Command | Use case |
|-------|---------|----------|
| Working tree vs index | `git diff` | Review unstaged changes before `git add` |
| Index vs HEAD | `git diff --staged` | Verify staged changes before `git commit` |
| Working tree vs HEAD | `git diff HEAD` | See everything not yet committed |
| Commit vs commit | `git diff A B` | Review what changed between two points |
| Branch divergence | `git diff A...B` | Review only new work on branch B |

`git diff` is the most frequently used command for inspection in Git. Master it to understand exactly what changes you're about to stage, commit, or merge.
