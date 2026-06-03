# `git blame` — Show what revision and author last modified each line of a file

The `git blame` command annotates every line of a file with the commit hash, author, and timestamp of the last modification. It's the fastest way to find *who* wrote a piece of code, *when*, and in *which commit* — invaluable for tracking down bugs, understanding unfamiliar code, and auditing changes.

```
git blame [-c] [-b] [-l] [--root] [-t] [-f] [-n] [-s] [-e] [-p] [-w] [--incremental]
          [-L <range>] [-S <revs-file>] [-M] [-C] [-C] [-C] [--since=<date>]
          [--ignore-rev <rev>] [--ignore-revs-file <file>]
          [--color-lines] [--color-by-age] [--progress] [--abbrev=<n>]
          [--contents <file>] [<rev> | --reverse <rev>..<rev>] [--] <file>
```

## How Blame Works

Each line of a file was introduced by some commit. `git blame` walks backwards through history, commit by commit, to determine when each line last changed. For every line, it reports:

```
<hash> (<author> <timestamp> <line-number>) <content>
```

```
commit abc1234 (Jane Doe 2026-01-15 14:30:00 +0000 42) def connect():
```

If a commit only touched a subset of lines, only those lines update — the rest keep their previous attribution.

**Limitation:** Blame only shows the *most recent* change to each line. If the same line was changed five times, you only see the last one. For the full history of a line, use `git log -L`.

---

## Basic Usage

### Blame a file

```bash
git blame main.py
```

Output:
```
abc1234d (Jane Doe       2026-01-15 14:30:00 +0000  1) #!/usr/bin/env python3
def5678a (John Smith     2025-11-20 09:15:42 +0000  2) """Main entry point"""
abc1234d (Jane Doe       2026-01-15 14:30:00 +0000  3) 
```

### Blame a file at a specific revision

```bash
git blame v1.0 -- main.py
git blame a1b2c3d -- src/server.js
git blame main -- README.md
```

The `<rev>` can be any commit-ish: a tag, branch name, or commit hash.

### Blame specific lines with `-L`

```bash
git blame -L 10,20 main.py     # Lines 10 through 20
git blame -L 15 main.py         # Lines 15 to end of file
git blame -L 10,10 main.py      # Just line 10
```

Multiple `-L` ranges are allowed:

```bash
git blame -L 10,20 -L 50,60 main.py
```

### Show email instead of name

```bash
git blame -e main.py
```

Output:
```
abc1234d (<jane@example.com> 2026-01-15 14:30:00 +0000  1) #!/usr/bin/env python3
```

---

## Line Range Options

### Absolute line numbers

```bash
git blame -L 42,42 buggy.py     # Just line 42
git blame -L 1,100 main.py      # First 100 lines
```

### Regex ranges (`/regex/`)

Find lines by content pattern. Git blames from the matching line onward:

```bash
# From the line matching "def " to end of file
git blame -L '/def /' main.py

# From the line matching "class" to line 100
git blame -L '/^class /',100 main.py

# Range between two regex matches
git blame -L '/def connect/,/^def send/' src/client.py
```

The second regex is exclusive (stops *before* the matching line).

### Function context ranges (`:<funcname>`)

Blame the function that contains a given line:

```bash
# Blame the function containing line 42
git blame -L :42 src/app.py

# Blame the function named "connect"
git blame -L ':connect' src/app.py
```

Git uses language-specific heuristics or a custom `diff=<driver>.xfuncname` config to find function boundaries.

---

## Author Display

### `-s` — Suppress author and timestamp

```bash
git blame -s main.py
```

Output:
```
abc1234d 1) #!/usr/bin/env python3
def5678a 2) """Main entry point"""
```

Useful when you only care about the commit hash.

### `-e` — Show email instead of name

```bash
git blame -e main.py
```

### `-n` — Show line numbers in the original commit

Instead of the current line number, show what the line number was in the commit that last changed it:

```bash
git blame -n main.py
```

### `-f` — Show filenames

Prefix each line with the source filename (useful with `-C` where lines may come from other files):

```bash
git blame -f main.py
```

### `--show-stats` — Show statistics at the end

```bash
git blame --show-stats main.py
```

Prints a summary of commits and authors found.

---

## Whitespace and Diff Algorithm

### `-w` — Ignore whitespace changes

Lines that only differ in whitespace (spaces, tabs, indentation) are attributed to the commit that *introduced meaningful content*, not the one that reformatted it:

```bash
git blame -w src/styles.css
```

Essential when examining files with mixed indentation history.

### `--diff-algorithm=<algorithm>`

Control how Git determines line matches. Affects accuracy when code has been moved or reformatted:

```bash
git blame --diff-algorithm=histogram main.py
```

Available algorithms: `patience`, `minimal`, `histogram`, `myers` (default). `histogram` and `patience` are better at detecting moved lines.

### `--indent-heuristic`

Use an experimental heuristic to improve blame alignment by diff boundaries:

```bash
git blame --indent-heuristic main.py
```

---

## Copy and Move Detection

Git can detect lines that were *copied or moved* from elsewhere and attribute them to the original commit, not the copy commit.

### `-M` — Detect moved lines within a file

Detect lines that were moved within the **same file**:

```bash
git blame -M main.py
```

### `-C` — Detect copied lines across files

Detect lines that were copied from **other files in the same commit**:

```bash
git blame -C src/new_file.py
```

If a function was duplicated from `src/old_file.py`, `-C` attributes it to the original commit in `old_file.py`.

### `-C -C` — Cross-file, cross-commit copy detection

Two `-C` flags look for copies from files that existed in **parent commits** (not just the same commit):

```bash
git blame -C -C src/new_file.py
```

### `-C -C -C` — Aggressive cross-file, cross-commit copy detection

Three `-C` flags enable the most aggressive copy detection, which also looks in files that were **modified** (not just new) in parent commits:

```bash
git blame -C -C -C src/app.py
```

**Performance note:** More `-C` flags make blame slower as it searches more candidates. Use the minimum needed.

### `--find-copies-harder`

Equivalent to extra `-C` flags for even more thorough copy detection.

---

## Ignoring Commits

Some commits change every line (formatting, linting, renaming). You can tell blame to skip them.

### `--ignore-rev <rev>`

Skip a single commit. Lines last changed by this commit will be attributed to the *previous* meaningful change:

```bash
git blame --ignore-rev a1b2c3d main.py
```

### `--ignore-revs-file <file>`

Load a list of commits to ignore from a file (one per line, `#` comments):

```bash
# .git-blame-ignore-revs
# Formatting-only commits
a1b2c3d                   # Ran prettier on entire codebase
e5f6g7h8                  # Converted tabs to spaces
```

```bash
git blame --ignore-revs-file .git-blame-ignore-revs main.py
```

| `<rev>` | `<rev>` | `<rev>` | ...
|---------|---------|---------|---
| Each line is a full or abbreviated commit hash.

Blank lines and lines starting with `#` are ignored.

### `--ignore-revs-file` with a URL

```bash
git blame --ignore-revs-file https://example.com/ignored-revs.txt main.py
```

### Mark ignored lines in the output

Combined with `blame.markIgnoredLines` config (see Configuration section), lines attributed to ignored commits can be visually highlighted.

**Setup for a team:**

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs
echo "a1b2c3d" > .git-blame-ignore-revs
git add .git-blame-ignore-revs
```

Now everyone on the team gets clean blame output without formatting noise.

---

## Color Output

### `--color-lines`

Color each line based on the commit that last modified it. Lines from the same commit share a color:

```bash
git blame --color-lines main.py
```

### `--color-by-age`

Color each line based on how recently it was changed:

- **Blue** — recent (changed recently)
- **Red** — older (hasn't changed in a while)

```bash
git blame --color-by-age main.py
```

The gradient goes from blue (newest) through green/yellow to red (oldest).

Both color options require a terminal that supports ANSI colors.

---

## Date and Time

### `-t` — Raw timestamp

Show timestamps as Unix epoch seconds + timezone:

```bash
git blame -t main.py
```

Output:
```
abc1234d (Jane Doe 1736937000 +0000  1) #!/usr/bin/env python3
```

### `--date=<format>`

Override the date display format:

```bash
git blame --date=short main.py        # 2026-01-15
git blame --date=relative main.py     # 3 weeks ago
git blame --date=iso-strict main.py   # 2026-01-15T14:30:00+00:00
git blame --date=rfc2822 main.py      # Thu, 15 Jan 2026 14:30:00 +0000
git blame --date=unix main.py         # 1736937000
git blame --date=format:%Y-%m-%d main.py  # Custom strftime
```

### `--since=<date>`

Ignore commits older than a given date. Lines that haven't changed since the cutoff keep their original attribution but the author/date isn't shown for them:

```bash
git blame --since=2025-01-01 main.py
git blame --since="3 months ago" main.py
git blame --since="2025-06-01T00:00:00Z" main.py
```

---

## Reverse Blame

Normally blame shows when each line was *introduced*. With `--reverse` it shows when each line was *removed* (using a range of commits):

```bash
git blame --reverse v1.0..v2.0 main.py
```

Lines that are *still present* at `v2.0` show as `Not Yet Committed`. Lines that were removed within the range show the commit that removed them.

**Use case:** Find when a feature was deleted:

```bash
git blame --reverse v1.0..HEAD -- src/old-feature.py
```

---

## Contents Mode

### `--contents <file>`

Blame against **arbitrary file content** rather than the committed version. The file is treated as the current file content and tested against the given revision:

```bash
git blame --contents working-copy.py main.py
```

This shows who would be blamed if `working-copy.py` were committed — useful for previewing blame before committing.

### `--contents -` (stdin)

Read content from stdin:

```bash
echo "def new_func():\n    pass" | git blame --contents - main.py
```

---

## Porcelain and Machine Output

For scripting and tools, Git provides stable, parseable output formats.

### `-p` or `--porcelain`

Output in a format designed for machine consumption. Each line group starts with the commit hash in a header block followed by line content:

```bash
git blame -p main.py
```

Output structure:
```
<commit-hash> <source-line> <result-line>
author <author-name>
author-mail <<email>>
author-time <unix-timestamp>
author-tz <timezone>
committer <committer-name>
committer-mail <<email>>
committer-time <unix-timestamp>
committer-tz <timezone>
summary <commit-message>
boundary
filename <source-filename>
	<line-content>
```

### `--line-porcelain`

Like `--porcelain` but repeats the commit header for *every* line (not just when the commit changes). Useful when you want to process each line independently:

```bash
git blame --line-porcelain main.py
```

### `--incremental`

Stream blame results as they are computed, rather than waiting for the entire file. Each commit header is printed once, then lines are emitted as they're resolved:

```bash
git blame --incremental main.py
```

### `-b` — Suppress boundary commits

Boundary commits are commits at the edge of the search range (e.g., the oldest reached). By default they are shown with `^` prefix. `-b` hides them:

```bash
git blame -b main.py
```

### `-l` — Show long commit hashes

Show the full 40-character (or 64-character for SHA-256) commit hash instead of the default abbreviated form:

```bash
git blame -l main.py
```

### `--abbrev=<n>`

Set the number of hex digits shown for commit hashes:

```bash
git blame --abbrev=12 main.py
```

### `--root`

Do not treat root commits as boundary commits (blame can walk past the initial commit of a project):

```bash
git blame --root main.py
```

### `-c` — Use the same output mode as `git-annotate`

```bash
git blame -c main.py
```

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Highlight lines attributed to ignored commits (requires --color-lines or --color-by-age)
[blame]
    markIgnoredLines = true

# Dim lines attributed to boundary commits
    markBoundaryLines = true

# Show author email by default (like -e always on)
    showEmail = true

# Path to file listing commits to ignore (like --ignore-revs-file always on)
    ignoreRevsFile = .git-blame-ignore-revs

# Default coloring mode: "auto" (detect if colors are supported), "never", "always"
    coloring = auto

# Blank lines (uncommitted, whitespace-only) are treated as boundary
    blankBoundary = true

# Default date format
    blameDate = short
```

### `blame.coloring` values

| Value | Effect |
|-------|--------|
| `auto` | Use color if terminal supports it (default) |
| `never` | Never color output |
| `always` | Always color output, even when piping |

---

## Quick Reference

```bash
# Basic usage
git blame main.py                                 # Blame entire file
git blame -L 42,42 main.py                        # Single line
git blame -L 10,50 main.py                        # Line range
git blame v1.0 -- main.py                         # Blame at a specific revision

# Line range variants
git blame -L '/def /' main.py                     # From regex match
git blame -L '/def connect/,/^def send/' api.py   # Between two regex matches
git blame -L :42 src/app.py                       # Function containing line 42

# Author display
git blame -s main.py                              # Suppress author/timestamp
git blame -e main.py                              # Show email
git blame -n main.py                              # Show original line numbers
git blame -f main.py                              # Show source filename

# Whitespace
git blame -w main.py                              # Ignore whitespace
git blame --diff-algorithm=histogram main.py      # Better diff algorithm

# Copy/move detection
git blame -M main.py                              # Detect moves within file
git blame -C src/new.py                           # Detect copies in same commit
git blame -C -C src/new.py                        # Cross-commit copies
git blame -C -C -C src/new.py                     # Aggressive cross-commit copies

# Ignoring commits
git blame --ignore-rev a1b2c3d main.py            # Ignore one commit
git blame --ignore-revs-file .blame-ignore main.py# Ignore list from file

# Color
git blame --color-lines main.py                   # Color by commit
git blame --color-by-age main.py                  # Color by recency

# Date/time
git blame -t main.py                              # Raw timestamp
git blame --date=short main.py                    # YYYY-MM-DD format
git blame --since=2025-06-01 main.py              # Only recent changes

# Reverse blame
git blame --reverse v1.0..v2.0 main.py            # Find when lines disappeared

# Contents mode
git blame --contents draft.py main.py             # Blame against arbitrary content
git blame --contents - main.py < input.txt        # Blame against stdin

# Machine output
git blame -p main.py                              # Porcelain format
git blame --line-porcelain main.py                # Per-line porcelain
git blame --incremental main.py                   # Streaming output

# Misc
git blame -l main.py                              # Full commit hashes
git blame --abbrev=12 main.py                     # Custom hash length
git blame --root main.py                          # Don't stop at root commit
git blame -b main.py                              # Hide boundary commits
git blame -c main.py                              # Annotate-compatible mode
```

---

## Real-World Examples

### "Who wrote this bug?"

```bash
git blame -L 42,42 src/main.py
```

Line 42 has a null-pointer dereference? Blame shows the exact commit and author.

### "Find what commit introduced this function"

```bash
git blame -L '/^def connect/,/^def/' src/client.py
```

Blame the range from `def connect` to the next function definition.

### "Ignore formatting commits"

```bash
echo "e5f6g7h8" > .git-blame-ignore-revs  # Formatting commit
echo "i9j0k1l2" >> .git-blame-ignore-revs # Linting commit
git blame --ignore-revs-file .git-blame-ignore-revs main.py
```

### "Find lines copied from another file"

```bash
git blame -C -C src/app.py
```

Lines that were copied from `src/utils.py` (in any parent commit) show the original commit from `utils.py`, not the copy commit.

### "Show email instead of name"

```bash
git blame -e src/app.py
```

### "Who changed this recently?"

```bash
git blame --since="2 weeks ago" -- src/app.py
```

Only shows lines that changed in the last two weeks. Older lines show the original author info.

### "Preview blame before committing"

```bash
git blame --contents main.py HEAD -- src/app.py
```

Shows what blame *would* look like if `main.py` (a draft) were committed.

### "Find when a deleted feature was removed"

```bash
git blame --reverse v1.0..v2.0 src/deleted-feature.py
```

Lines still present at v2.0 show `Not Yet Committed`. Lines removed within the range show the commit that deleted them.

### "Blame across a rename"

```bash
git blame -C -C src/renamed-file.js
```

Even if the file was renamed, `-C -C` follows the copy and attributes lines to the original file's commit.

### "Scripting: get blame info in a script"

```bash
git blame --line-porcelain -L 5,5 config.yml | grep "^author " | cut -d' ' -f2-
```

Outputs just the author name for line 5.

### "Find all lines by a specific author"

```bash
git blame --line-porcelain main.py | grep "^author Jane" -B 1 | grep "^[a-f0-9]"
```

Find which lines Jane last modified.

### "Blame with diffulter — show the commit content"

```bash
git show $(git blame -L 42,42 -s main.py | awk '{print $1}')
```

Show the full commit that last touched line 42, including the diff.

### "Use blame.ignoreRevsFile for the whole team"

```bash
# Create the ignore file
echo "# Mass reformatting commits" > .git-blame-ignore-revs
echo "a1b2c3d4" >> .git-blame-ignore-revs
echo "e5f6g7h8" >> .git-blame-ignore-revs

# Configure Git to always use it
git config blame.ignoreRevsFile .git-blame-ignore-revs

# Commit the config
git add .git-blame-ignore-revs
git commit -m "Add blame ignore file for formatting commits"
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Blame shows the wrong person | A formatting commit touched every line and now all lines blame the formatter | Use `--ignore-rev` or `--ignore-revs-file` to skip formatting commits |
| **Blame is slow on large files** | Walking history for thousands of lines is expensive | Narrow with `-L` range, or use `--since` to limit history |
| **Lines show as `Not Yet Committed`** | Working tree has uncommitted changes, or the commit boundary was reached | Commit first, or use `--contents` for preview |
| **Blame doesn't see renames** | Default blame doesn't follow renamed files | Use `-C` or `-C -C` to enable copy/rename detection |
| **Confusing results after merge** | Merge commits change blame attribution in unexpected ways | Use `-C` to follow the original source through merges |
| **Wrong line numbers in blame output** | `-n` shows *original* line numbers, not current ones | Omit `-n` to see current line numbers |
| **Blame returns exit code 141** | Broken pipe from `head` or `less` — not an actual error | Ignore, or use `--no-pager` |
| **Color output lost when piping** | Git disables color when stdout is not a TTY | Use `--color-lines` or `git -c color.ui=always blame` |
| **Boundary commits confuse results** | Blame stops at root commits or explicit boundaries | Use `--root` to continue past root commits |
| **Lines from different files not tracked** | Copy detection is off by default | Use `-C`, `-C -C`, or `-C -C -C` depending on aggressiveness needed |

---

## Visual Summary

```
git blame main.py

     Commit        Author              Timestamp          Line  Content
     ┌──────┐   ┌─────────┐   ┌───────────────────┐   ┌──┐  ┌──────────┐
     │abc1234│   │Jane Doe │   │2026-01-15 14:30:00│   │ 1│  │#!/usr/bin│
     └──────┘   └─────────┘   └───────────────────┘   └──┘  └──────────┘
     ┌──────┐   ┌─────────┐   ┌───────────────────┐   ┌──┐  ┌──────────┐
     │def5678│   │John Smith│   │2025-11-20 09:15:42│   │ 2│  │import sys│
     └──────┘   └─────────┘   └───────────────────┘   └──┘  └──────────┘

Each line = commit + author + timestamp + line number + content.

Copy/move detection (-C -C):
    src/new.py ──copy from──→ src/old.py
    blame shows commit from old.py, not the copy commit.

Ignore formatting commits (--ignore-rev):
    Format commit ──skip──→ Original meaningful commit is shown instead.
```

`git blame` turns any line of code into a question with an answer: "Who wrote this, when, and why?" It's the first tool to reach for when debugging unfamiliar code.
