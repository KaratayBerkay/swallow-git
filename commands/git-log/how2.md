# `git log` — Show commit logs

`git log` displays committed snapshots, letting you explore your project's history with powerful filtering, formatting, and display options. It is the most versatile command for understanding what happened, when, and why.

```
git log [<options>] [<revision-range>] [[--] <path>...]
```

---

## Basic Usage

### Default — full log

```bash
git log
```

Shows every commit reachable from `HEAD`, one entry with full hash, author, date, and message. The output is piped through a pager (usually `less`).

### One line per commit

```bash
git log --oneline
```

Each commit is shown as a short hash and subject line. The most frequently used mode after plain `git log`.

### Full branch graph

```bash
git log --oneline --graph --all --decorate
```

The "everything" view — a compact graph of all branches, tags, and HEAD. Ideal for understanding the repo's topology at a glance.

---

## Format Options

### `--oneline`

Shorthand for `--pretty=oneline --abbrev-commit`. Each commit fits on one line:

```
a1b2c3d Fix null pointer in user lookup
e5f6g7a Add tests for auth module
```

### `--format="..."` / `--pretty=format:"..."`

Define exactly what each log entry looks like using placeholders:

```bash
git log --format="%h %an %ar: %s"
```

### `--pretty=<style>`

Pre-built formatting presets:

| Style | Description |
|-------|-------------|
| `oneline` | Hash and subject on one line |
| `short` | Hash, author, subject |
| `medium` | Hash, author, date, subject (default) |
| `full` | Hash, author, committer, subject |
| `fuller` | Hash, author, committer, date, subject |
| `reference` | Like `--oneline` but with `<hash> (<titleline>)` format |
| `email` | Patch-style with email headers |
| `raw` | Raw Git internal format |
| `format:"..."` | Custom format string |
| `tformat:"..."` | Like `format` but with line terminators (default for `format:`) |

```bash
git log --pretty=fuller
git log --pretty=format:"%h %an %ad %s" --date=short
```

### `--abbrev-commit`

Show abbreviated commit hashes (default 7 characters, unique minimum):

```bash
git log --abbrev-commit
```

Use `--abbrev=<n>` to control the length: `--abbrev=12`.

### `--no-abbrev-commit`

Show full 40-character (SHA-1) or 64-character (SHA-256) hashes.

---

## Diff Stats in Log

Show summary of changes alongside the log:

### `--stat`

Show changed files and the number of insertions/deletions:

```bash
git log --stat
```

Output:
```
 src/main.py | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)
```

### `--shortstat`

Show only the summary line (no file list):

```bash
git log --shortstat
```

### `--numstat`

Show machine-parsable stat — tab-separated added, deleted, filename:

```bash
git log --numstat
```

```
10      1       src/main.py
```

### `--name-only`

List only the names of changed files:

```bash
git log --name-only
```

### `--name-status`

List changed files with a status letter:

```bash
git log --name-status
```

| Letter | Meaning |
|--------|---------|
| `A` | Added |
| `C` | Copied |
| `D` | Deleted |
| `M` | Modified |
| `R` | Renamed |
| `T` | Type changed |
| `U` | Unmerged |
| `X` | Unknown |

---

## Patch Display

### `-p` (or `--patch`)

Show the full diff for each commit:

```bash
git log -p
git log -p -2        # Last 2 commits with full diff
```

### `--patch-with-stat`

Shorthand for `-p --stat` — diff summary plus full patch:

```bash
git log --patch-with-stat
```

### `-U<n>` / `--unified=<n>`

Control the number of context lines in the patch:

```bash
git log -p -U5       # 5 lines of context
git log -p -U0       # Zero context — only changed lines
```

### `--word-diff`

Show word-level diff instead of line-level:

```bash
git log -p --word-diff
```

---

## Filtering by Commit History

### Revision Ranges

**Two-dot range** — commits reachable from B but not from A:

```bash
git log A..B
```

Think: "What's in B that isn't in A?" Most common use:

```bash
git log main..feature     # Commits in feature not in main
git log origin/main..HEAD # What I've done since last push
```

**Three-dot symmetric difference** — commits in A or B but not in both:

```bash
git log A...B
```

Combined with `--left-right` to annotate which side each commit belongs to (`<` for left, `>` for right):

```bash
git log --left-right A...B
```

### Date Filtering

```bash
git log --after="2025-01-01"
git log --since="2 weeks ago"
git log --until="yesterday"
git log --before="2025-06-01"
git log --since="2025-01-01" --until="2025-03-01"
```

Accepts most date formats: `"2025-01-15"`, `"2 weeks ago"`, `"yesterday"`, `"3 months ago"`, `"January 15 2025"`.

### Author and Committer

```bash
git log --author="John"
git log --author="john@example.com"
git log --committer="Jane"
```

The `--author` filter is a regex — partial matches work. Use `--author="^John"` for exact starts-with.

### Commit Message Search

```bash
git log --grep="fix:"
git log --grep="security" --all
```

Use `--all-match` with multiple `--grep` to require all patterns:

```bash
git log --grep="fix:" --grep="auth" --all-match
```

Case-insensitive: `git log --grep="bug" -i`

### Pickaxe — Search Code Changes

**`-S<string>`** — Show commits that changed the number of occurrences of a string:

```bash
git log -S"functionName" --oneline
git log -S"TODO" --oneline
```

This is the fastest way to find when a specific function or constant was added or removed. It tracks the **number of occurrences**, not the content of the line.

**`-G<regex>`** — Show commits whose patch text contains lines matching a regex:

```bash
git log -G"def \w+\(.*\):" --oneline
```

`-S` counts occurrences; `-G` matches the patch text. `-S` is faster; `-G` is more flexible.

**`--pickaxe-all`** — Show all diff lines in matching commits, not just the ones that match:

```bash
git log -S"buggyFunc" --pickaxe-all -p
```

---

## Filtering by File or Directory

```bash
git log -- src/main.py                    # Commits touching this file
git log -- src/ tests/                    # Commits touching these dirs
git log v1.0..v2.0 -- src/main.py         # Range + file filter
git log main -- src/main.py               # From a specific commit
```

The `--` separates revisions from paths. If you're already specifying a path, Git can usually infer the intent:

```bash
git log src/main.py                       # Usually works without --
git log -- src/main.py                    # Explicit — always correct
```

### History Including Renames

```bash
git log --follow -- src/main.py
```

`--follow` continues tracking the file across renames. Only works for a **single file**.

---

## Limiting Output

```bash
git log -5                         # Last 5 commits
git log --max-count=10             # At most 10 commits
git log --skip=5                   # Skip first 5, then show rest
git log -5 --skip=10               # Skip 10, then show 5
```

Time-based limits (uses committer date):

```bash
git log --since="2025-01-01"
git log --until="2025-06-01"
git log --after="2025-01-01" --before="2025-06-01"
```

The `--since`/`--after` and `--until`/`--before` pairs are interchangeable.

### `--min-age` / `--max-age`

Filter by Unix timestamp (seconds since epoch):

```bash
git log --min-age=1700000000
git log --max-age=1705000000
```

---

## Graph and Branches

### `--graph`

Draw a text-based commit graph on the left side:

```bash
git log --oneline --graph
git log --oneline --graph --all --decorate   # The classic
```

### `--all`

Show commits from **all refs** (branches, tags, remotes), not just the current branch:

```bash
git log --oneline --graph --all
```

### `--branches[=<pattern>]`

Show commits from all branches (optionally filtered by name):

```bash
git log --oneline --branches="feature/*"
```

### `--remotes[=<pattern>]`

Show commits from all remote-tracking branches:

```bash
git log --oneline --remotes
git log --oneline --remotes="origin/*"
```

### `--tags[=<pattern>]`

Show commits from all tags:

```bash
git log --oneline --tags="v2.*"
```

### `--glob=<pattern>`

Show commits from refs matching a glob pattern:

```bash
git log --oneline --glob="refs/heads/release/*"
```

### `--simplify-by-decoration`

Show only commits that are referenced by a branch or tag:

```bash
git log --oneline --simplify-by-decoration --all
```

Useful for getting a high-level view of tagged releases or branch points without every intermediate commit.

---

## Merge Filtering

### `--merges`

Show only merge commits:

```bash
git log --oneline --merges
```

### `--no-merges`

Show only non-merge commits:

```bash
git log --oneline --no-merges
```

### `--first-parent`

Follow only the first parent of merge commits. This flattens the history to the mainline, ignoring side branches:

```bash
git log --oneline --first-parent
```

Without `--first-parent`, merges show commits from all merged branches. With it, you see only what happened on the main branch, treating merges as single events.

### `--ancestry-path`

Show only commits that are descendants of one ref and ancestors of another. Used with range `A...B`:

```bash
git log --oneline --ancestry-path A..B
```

This limits output to commits that lie on the path between A and B, excluding commits from unrelated branches that happen to be in the range.

### `--no-min-parents` / `--min-parents=<n>` / `--max-parents=<n>`

Filter by number of parents:

```bash
git log --min-parents=2                    # Merge commits
git log --max-parents=1                    # No merge commits (root + regular)
git log --min-parents=1 --max-parents=1    # Only regular commits (no root, no merges)
```

---

## Custom Format Placeholders

The `--format` option accepts placeholders prefixed with `%`:

```bash
git log --format="%h %an %ar %s"
```

Common placeholders:

| Placeholder | Description |
|-------------|-------------|
| `%H` | Full commit hash |
| `%h` | Abbreviated commit hash |
| `%T` | Full tree hash |
| `%t` | Abbreviated tree hash |
| `%P` | Full parent hashes |
| `%p` | Abbreviated parent hashes |
| `%an` | Author name |
| `%ae` | Author email |
| `%ad` | Author date (respects `--date=`) |
| `%aD` | Author date, RFC2822 style |
| `%ar` | Author date, relative ("2 weeks ago") |
| `%at` | Author date, Unix timestamp |
| `%ai` | Author date, ISO 8601-like |
| `%cn` | Committer name |
| `%ce` | Committer email |
| `%cd` | Committer date |
| `%cD` | Committer date, RFC2822 style |
| `%cr` | Committer date, relative |
| `%ct` | Committer date, Unix timestamp |
| `%ci` | Committer date, ISO 8601-like |
| `%s` | Subject (commit message first line) |
| `%b` | Body (rest of commit message) |
| `%B` | Raw body (subject + body) |
| `%d` | Ref names (decorations like `(HEAD -> main, tag: v1.0)`) |
| `%D` | Ref names without parentheses |
| `%e` | Encoding |
| `%G?` | GPG signature status |
| `%GG` | Raw GPG verification message |
| `%GS` | GPG signer name |
| `%GK` | GPG key used to sign |
| `%gD` | Reflog selector (for `git log -g`) |
| `%gd` | Shortened reflog selector |
| `%gn` | Reflog identity name |
| `%ge` | Reflog identity email |
| `%gs` | Reflog subject |
| `%N` | Notes |
| `%(describe)` | Describe-style name |
| `%(describe:tags=true)` | Describe using tags only |
| `%aN` | Author name (respecting `.mailmap`) |
| `%aE` | Author email (respecting `.mailmap`) |
| `%cN` | Committer name (respecting `.mailmap`) |
| `%cE` | Committer email (respecting `.mailmap`) |

Color placeholders:

```bash
git log --format="%C(yellow)%h%C(reset) %C(green)%an%C(reset) %s"
```

Available colors: `normal`, `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `bold`, `dim`, `ul`, `blink`, `reverse`, `italic`, `strike`, `reset`.

### `--date=<format>`

Controls how dates appear with `%ad`, `%cd`:

| Format | Example |
|--------|---------|
| `relative` | "2 weeks ago" |
| `short` | "2025-01-15" |
| `iso` or `iso-strict` | "2025-01-15 10:30:00 +0000" |
| `rfc2822` | "Wed, 15 Jan 2025 10:30:00 +0000" |
| `unix` | 1705312200 |
| `format:...` | `--date=format:%Y-%m-%d` |
| `raw` | Unix timestamp + offset |
| `default` | "Wed Jan 15 10:30:00 2025 +0000" |
| `human` | "15 Jan 2025 10:30" (smart relative) |
| `auto` | Respects `--relative-date` if enabled |

```bash
git log --format="%h %ad %s" --date=short
git log --format="%h %ad %s" --date=format:"%Y-%m-%d %H:%M"
```

---

## Ordering

| Option | Description |
|--------|-------------|
| `--date-order` | Sort by committer date (parents shown after all their children) |
| `--author-date-order` | Sort by author date (parents shown after all their children) |
| `--topo-order` | Topological order — no commit shown before all its parents (strict DAG order) |
| `--reverse` | Reverse the output order (oldest first). Combine with `--topo-order` for chronological history |

```bash
git log --oneline --topo-order --all            # Strict DAG order
git log --oneline --reverse                     # Oldest commits first
git log --oneline --author-date-order           # Author date order
```

Default ordering: commits are shown in reverse chronological order (by committer date), with children shown before parents. `--topo-order` is useful when you need to guarantee parent-before-child display.

---

## Reflog View

Show the **reflog** (local record of HEAD movements) instead of commit history:

```bash
git log -g                   # git log --walk-reflogs
git log -g --oneline
```

The reflog tracks where HEAD has been, even if those commits are no longer reachable from any branch — your safety net for "I lost a commit."

---

## Quiet Mode and Machine Output

### `--quiet`

Suppress all output. Useful in scripts to check if a commit range is empty (exit code is non-zero for empty):

```bash
if git log --quiet main..feature; then
  echo "No new commits"
fi
```

### `--raw`

Show the raw internal format of each commit:

```bash
git log --raw
```

### JSON-style output

```bash
git log --format="%H" --stdin   # Read commit list from stdin
```

---

## Quick Reference

```bash
# Basic viewing
git log                               # Default log
git log --oneline                     # Compact one-line format
git log --oneline --graph --all --decorate   # Full topology

# Formatting
git log --format="%h %an %ar %s"      # Custom format
git log --pretty=fuller               # Full metadata
git log --format="%h %s" --date=short # Short hash + subject + date
git log --format="%C(yellow)%h%Creset %s"  # Colored output

# Diff stats
git log --stat                        # File change summary
git log --shortstat                   # Total insertions/deletions
git log --numstat                     # Machine-parsable stats
git log --name-only                   # Just file names
git log --name-status                 # File names with status letters

# Patch display
git log -p                            # Full diff per commit
git log -p -U5                        # More context lines
git log --word-diff                   # Word-level diff

# Filtering by range
git log main..feature                 # In feature, not in main
git log origin/main..HEAD             # My unpushed commits
git log A...B --left-right            # Symmetric diff with markers

# Filtering by author/date/message
git log --author="Alice"              # Alice's commits
git log --since="2 weeks ago"         # Recent commits
git log --grep="bugfix"               # Search commit messages
git log --author="Bob" --since="2025-01-01" --grep="auth"  # Combined

# Filtering by code change
git log -S"functionName"              # Pickaxe: when was function changed
git log -G"regex_pattern"             # Pickaxe with regex
git log -S"TODO" --all                # Across all branches

# Filtering by file
git log -- src/main.py                # Commits touching this file
git log --follow -- src/main.py       # History including renames
git log -p -- src/main.py             # Diffs for one file

# Limiting output
git log -5                            # Last 5 commits
git log --skip=10 -5                  # Skip 10, show 5
git log --max-count=20                # At most 20 commits

# Branch and graph views
git log --all                         # All refs
git log --graph --all                 # Graph of everything
git log --branches="feature/*"        # Feature branches only
git log --simplify-by-decoration      # Only decorated commits

# Merge filtering
git log --merges                      # Only merges
git log --no-merges                   # No merges
git log --first-parent                # Mainline only
git log --min-parents=2               # Merges and only merges

# Ordering
git log --reverse                     # Oldest first
git log --topo-order                  # Strict DAG order
git log --date-order                  # Committer date order

# Reflog
git log -g                            # Show reflog
git log -g --oneline                  # Compact reflog

# Check if range has commits (scripting)
git log --quiet main..feature         # Exit code: 1 = empty, 0 = has commits
```

### Placeholder reference

| `%H` | `%h` | `%T` | `%t` | `%P` | `%p` | `%an` | `%ae` | `%ad` | `%ar` | `%s` | `%b` | `%d` | `%D` |
|------|------|------|------|------|------|-------|-------|-------|-------|------|------|------|------|
| full hash | short hash | full tree | short tree | full parents | short parents | author name | author email | author date | author relative | subject | body | decorations | decorations (no parens) |

### Date format reference

| `--date=short` | `--date=iso` | `--date=rfc2822` | `--date=relative` | `--date=unix` | `--date=format:%Y-%m` |
|----------------|--------------|-------------------|-------------------|---------------|----------------------|
| 2025-01-15 | 2025-01-15 10:30:00 +0000 | Wed, 15 Jan 2025 | 2 months ago | 1736937000 | 2025-01 |

---

## Real-World Examples

### Last 10 commits

```bash
git log --oneline -10
```

### Full branch topology

```bash
git log --oneline --graph --all --decorate
```

Visualize all branches, tags, and HEAD — essential before merges, rebases, or cleanup.

### Commits by a specific author in a time window

```bash
git log --author="John" --since="2 weeks ago" --oneline
```

### Diff of unreviewed commits on a feature branch

```bash
git log -p main..feature
```

Shows the full diff of every commit that's in `feature` but not yet in `main`. Perfect for code review preparation.

### Find when a function was added or changed

```bash
git log -S"calculateTotal" --oneline -- *.py
```

When was `calculateTotal` introduced or removed? The pickaxe (`-S`) finds commits where the count of matching lines changed. `-- *.py` limits to Python files.

### All fix commits

```bash
git log --grep="fix:" --oneline
```

### Files modified in a range

```bash
git log --diff-filter=M --name-only --oneline v1.0..v2.0
```

Shows only modified (not added or deleted) files. Combine letters: `--diff-filter=ACMR` for added, copied, modified, renamed.

### Custom format with graph

```bash
git log --format="%h %an %ar %s" --graph
```

### Merge commits only on the mainline

```bash
git log --merges --first-parent
```

Shows only merge commits, and only those on the main branch (no side-branch merge internals). Great for seeing when features were integrated.

### History including renames

```bash
git log --follow -- src/main.py
```

`--follow` tracks a single file across renames. Without it, the history stops at the rename commit.

### Commits that touch two files

```bash
git log --all -- src/api.py src/db.py
```

Commits that touched either file. For commits that touched **both**, pipe through `git log --all -- src/api.py -- src/db.py` (Git doesn't have a built-in AND filter for paths).

### Custom format with colors

```bash
git log --format="%C(red bold)%h%Creset %C(yellow)%d%Creset %C(cyan)%an%Creset %s"
```

### Compare two tags

```bash
git log --oneline v1.0..v2.0
```

### Show local commits not yet pushed

```bash
git log --oneline origin/main..HEAD
```

Everything you've committed locally that hasn't been pushed.

### Show commits by a contributor, sorted by author date

```bash
git log --author="Jane" --author-date-order --format="%ai %s"
```

### Verbose merge review

```bash
git log --oneline --first-parent --merges -10
```

Last 10 merge commits on the mainline — a quick changelog-style summary.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git log` shows nothing | No commits in the current range or the branch is unborn | Check `git branch -a` and `git log --all` |
| `git log` shows commits from other branches | Without `--all`, `git log` only shows ancestors of HEAD. If HEAD is behind, you're missing recent commits | Use `git log --all` or a ref like `origin/main` |
| `git log main..feature` is empty | You ran `git log feature..main` by accident — the order is `left..right` (commits in right not in left) | `git log main..feature` for "what's in feature?" |
| `--grep` returns unexpected results | `--grep` matches any commit message in the range, not just the first line | Use `--grep="^fix:"` for anchored search |
| `-S"text"` finds too many or too few commits | `-S` tracks count changes — if text appears and disappears in the same commit, that commit is detected. Renames count as add+delete | Use `-G"text"` for content-based matching instead |
| `--follow` only works with one file | It's a limitation — `--follow` uses rename detection internally, which is file-pair based | Run `git log --follow` separately for each file you care about |
| `--graph` with hundreds of branches is unreadable | The ASCII graph becomes a tangled mess | Narrow with `--branches="pattern"` or `--simplify-by-decoration` |
| `git log -p -- file` still shows renames | Even with a file filter, `-p` shows the rename header | Add `--diff-filter=M` to limit to modifications only, or use `--follow` |
| `git log` is slow in large repos with many refs | Git enumerates all refs to check reachability | Use `git log HEAD` explicitly, or limit with `--max-count`, `--since`, or `--skip` |
| `--format` with `%d` produces empty output for some commits | `%d` only shows decorations (branch/tag names). Commits with no refs get nothing | Use `%D` (never empty) or add a separator: `"format:%h %d %s"` — the space is still there |
| `git log A...B` shows all commits from both branches (not symmetric diff) | `A...B` shows commits in either A or B, but not both. Can be a lot of output | Use `--left-right` to label commits, or add `--ancestry-path` to restrict to the merge base path |
