# `git commit` — Record changes to the repository

The `git commit` command captures a snapshot of the staged changes and saves it to the repository's history. Each commit has a unique hash, an author, a timestamp, and a message describing what changed.

```
git commit [-a | --interactive | --patch] [-s] [-v] [-u<mode>] [--amend]
           [--dry-run] [(-c | -C | --squash) <commit> | --fixup [<commit>]]
           [-F <file> | -m <msg>] [--reset-author] [--allow-empty]
           [--allow-empty-message] [--no-verify] [-e] [--author=<author>]
           [--date=<date>] [--cleanup=<mode>] [--[no-]status]
           [-i | -o] [--pathspec-from-file=<file> [--pathspec-file-nul]]
           [-S[<keyid>]] [--] [<pathspec>...]
```

## Description

`git commit` creates a new commit containing the currently staged content (the index) plus the given log message. If nothing is staged and `-a` is not given, the commit is aborted (unless `--allow-empty` is used).

The commit stores:
- A **tree object** — a snapshot of the staged files
- A **parent pointer** — the previous commit(s)
- The **author** and **committer** metadata
- A **commit message** describing the change

By default, Git opens your editor to write the message. You can supply it inline with `-m`.

---

## Basic Usage

### `git commit`

Commit staged changes. Opens an editor for the commit message:

```bash
git add main.py
git commit
```

### `git commit -m "message"`

Commit with an inline message — no editor opens:

```bash
git commit -m "Initial implementation of login flow"
```

### `git commit -a -m "message"`

Stage **all tracked files** (modified and deleted) and commit in one step. Does **not** add untracked (new) files:

```bash
git commit -a -m "fix: handle empty input edge case"
```

Shortcut form:

```bash
git commit -am "refactor: extract validation helper"
```

### `git commit -v`

Commit with the diff shown in the editor. The diff appears after the message, commented out — you can review exactly what you're committing before saving:

```bash
git commit -v
```

---

## Commit Messages

### `-m <msg>` (or `--message`)

Supply the message inline:

```bash
git commit -m "Add user authentication"
```

Multiple `-m` flags create a multi-line message:

```bash
git commit -m "Add user authentication" -m "Implements JWT-based auth with refresh tokens"
```

### `-F <file>` (or `--file`)

Read the commit message from a file (or stdin with `-`):

```bash
git commit -F commit-msg.txt
git commit -F -    # from stdin
```

### `-e` (or `--edit`)

Edit the message provided by `-F` or `-m` before committing:

```bash
git commit -e -F generated-msg.txt
```

### `--cleanup=<mode>`

Control how the message is cleaned before committing:

| Mode | Behavior |
|------|----------|
| `strip` | Strip comments and trailing whitespace (default when using editor) |
| `whitespace` | Only remove trailing whitespace |
| `verbatim` | Keep the message exactly as-is |
| `scissors` | Strip everything below a `# ------------------------ >8 ------------------------` line |
| `default` | Strip comments unless message is provided via `-m` or `-F` |

```bash
git commit --cleanup=verbatim -m "code: 0x4A  # do not strip this"
```

### `--allow-empty-message`

Allow a commit with an empty message string:

```bash
git commit --allow-empty-message -m ""
```

---

## Author and Date

### `--author=<author>`

Override the commit author. Format: `Name <email>`:

```bash
git commit --author="Jane Doe <jane@example.com>"
```

This does **not** change the committer field — only the author. Useful for:
- Pair programming (credit your partner)
- Committing on behalf of someone who contributed a patch
- Fixing an incorrect author in an amend

### `--date=<date>`

Override the commit timestamp. Accepts many date formats:

```bash
git commit --date="2026-01-15 14:30:00"
git commit --date="now"             # current time
git commit --date="2 days ago"      # relative
git commit --date="Wed Jan 15 14:30:00 2026 +0200"  # full RFC 2822
```

### `--reset-author`

When used with `--amend` or `-c`/`-C`, reset the author to the committer (you) and update the timestamp to now:

```bash
git commit --amend --reset-author
```

This is useful when you're amending someone else's commit (e.g., from a patch or squash merge) and want to claim authorship.

---

## Amend

### `--amend`

Replace the tip of the current branch with a new commit. This **rewrites history** — the old commit is replaced:

```bash
# Oops — forgot to include a file
git add forgotten-file.py
git commit --amend
```

This opens the editor with the previous commit message. You can change it or save as-is.

### `--amend --no-edit`

Amend without changing the commit message:

```bash
git add missing-file.js
git commit --amend --no-edit
```

### `--amend -m "new message"`

Amend and replace the commit message:

```bash
git commit --amend -m "fix: better description of the actual fix"
```

### `-c <commit>` / `-C <commit>`

Reuse commit message from an existing commit:
- `-c <commit>` — reuse message and open editor
- `-C <commit>` — reuse message verbatim (no editor)

```bash
git commit -c abc123       # reuse message from abc123, edit it
git commit -C abc123       # reuse message verbatim
```

**When to amend:**

| Situation | Example |
|-----------|---------|
| Forgot to stage a file | `git add file && git commit --amend --no-edit` |
| Typo in commit message | `git commit --amend -m "fix: correct message"` |
| Need to change author | `git commit --amend --author="Name <email>" --no-edit` |
| Multiple small fixes | Accumulate changes, then amend once |

**Never amend commits that have been pushed to a shared branch** — it creates divergent history for everyone else.

---

## Interactive Staging

### `-i` (or `--interactive`)

Launch the interactive staging menu before committing. Same interface as `git add -i`:

```bash
git commit -i
```

This shows the interactive menu where you can select which changes to stage. Useful when you want to selectively stage while writing the commit message in one step.

### `-p` (or `--patch`)

Commit hunk-by-hunk interactively. Git shows each diff section and asks whether to include it:

```bash
git commit -p
```

You can also target specific files:

```bash
git commit -p src/main.py
```

This combines `git add -p` and `git commit` into a single command. See `git add -p` for the full list of hunk commands (y/n/q/a/d/s/e etc.).

---

## Sign-off and GPG

### `-s` (or `--signoff`)

Add a `Signed-off-by` trailer to the commit message. This is a developer certificate of origin indicating you have the right to submit the work:

```bash
git commit -s -m "chore: update dependencies"
```

The resulting commit message:
```
chore: update dependencies

Signed-off-by: Your Name <you@example.com>
```

### `-S[<keyid>]` (or `--gpg-sign`)

Cryptographically sign the commit using GPG. The commit will be marked as **verified** on GitHub/GitLab:

```bash
git commit -S -m "release: v2.0.0"
git commit -S=ABC123DEF -m "sign with specific key"
```

To sign every commit by default:

```bash
git config --global commit.gpgSign true
```

---

## Pathspec

### Committing specific files

Pass paths directly to commit only those files — Git stages them temporarily just for this commit:

```bash
git commit src/main.py tests/test_main.py -m "fix: resolve login bug"
```

This is equivalent to:

```bash
git add src/main.py tests/test_main.py
git commit -m "fix: resolve login bug"
```

### `-i` (or `--include`)

Include pathspec patterns **in addition to** whatever is already staged:

```bash
git commit -i src/ -m "update source files"
```

### `-o` (or `--only`)

Commit **only** the pathspec patterns, ignoring everything else in the index. This is the default when paths are given:

```bash
git commit -o src/ -m "update source files only"
```

### `--pathspec-from-file=<file>`

Read pathspec from a file (or stdin with `-`):

```bash
git commit --pathspec-from-file=files-to-commit.txt -m "batch update"
```

With `--pathspec-file-nul`, entries are NUL-separated (handles filenames with spaces).

---

## Fixup and Squash

### `--fixup=<commit>`

Create a **fixup commit** — a commit marked as a fix for a specific commit. When you later run `git rebase --autosquash`, it is automatically squashed into the target commit:

```bash
git commit --fixup abc123
```

The commit message is auto-generated: `fixup! original commit message of abc123`.

### `--squash=<commit>`

Similar to `--fixup`, but the message is prepended for editing during rebase:

```bash
git commit --squash abc123
```

The message starts with `squash! original commit message of abc123`.

### Autosquash workflow

```bash
# 1. Make a commit
git commit -m "feat: add search bar"

# 2. Realize you forgot a style tweak
# 3. Create a fixup commit targeting the original
git commit --fixup HEAD

# 4. Later, rebase with autosquash
git rebase -i --autosquash main
# Git automatically reorders: feat commit → fixup! commit
```

---

## Dry-run and Verify

### `--dry-run`

Simulate the commit. Show what would be committed, who the author would be, and whether it would succeed — without actually creating a commit:

```bash
git commit --dry-run
git commit --dry-run --short   # compact status
git commit --dry-run --porcelain  # machine-readable
```

### `--no-verify`

Skip the pre-commit and commit-msg hooks. Useful when a hook is blocking a commit for reasons you disagree with, or as a temporary workaround:

```bash
git commit --no-verify -m "wip: quick save"
```

### `--status` / `--no-status`

Include or exclude the `git status` output (commented out) from the commit message template in the editor:

```bash
git commit --no-status   # editor template is cleaner
git commit --status      # default — show status in template
```

---

## Allow Empty

### `--allow-empty`

Create a commit that contains no changes. Usually used to trigger CI pipelines, mark milestones, or create a starting point:

```bash
git commit --allow-empty -m "chore: trigger CI build"
git commit --allow-empty -m "chore: start feature flag for dark mode"
```

### `--allow-empty-message`

Allow creating a commit with no message at all:

```bash
git commit --allow-empty-message --allow-empty -m ""
```

---

## Quick Reference

```bash
# Basic commits
git commit                                          # Commit staged (opens editor)
git commit -m "message"                             # Commit with inline message
git commit -am "message"                            # Stage tracked + commit

# Amend
git commit --amend                                  # Edit last commit (message + content)
git commit --amend --no-edit                        # Amend without changing message
git commit --amend --reset-author                   # Take authorship of last commit

# Messages
git commit -m "title" -m "body"                     # Multi-line message
git commit -F msg.txt                               # Message from file
git commit -e -F msg.txt                            # Edit message from file
git commit --cleanup=verbatim -m "exact message"    # No cleanup
git commit --allow-empty-message -m ""              # Empty message

# Author and date
git commit --author="Name <email>"                  # Override author
git commit --date="2 days ago"                      # Override date
git commit --amend --author="Name <email>"          # Fix author on last commit

# Interactive
git commit -p                                       # Hunk-by-hunk commit
git commit -i                                       # Interactive menu then commit

# Signing
git commit -s -m "message"                          # Sign-off (DCO)
git commit -S -m "message"                          # GPG sign
git commit -S=KEYID -m "message"                    # GPG with specific key

# Safety
git commit --dry-run                                # Preview only
git commit --no-verify                              # Skip hooks

# Special commits
git commit --allow-empty -m "trigger CI"            # Empty commit
git commit --fixup abc123                           # Fixup for rebase
git commit --squash abc123                          # Squash for rebase

# Pathspec
git commit src/main.py -m "fix"                     # Commit specific files only
git commit -i src/ -m "update"                      # Include pathspec
git commit -o src/ -m "update"                      # Only pathspec (default)
```

---

## Real-World Examples

```bash
# Standard feature commit
git commit -m "feat: add user login"

# Quick fix (stage all tracked + message)
git commit -am "fix: resolve null pointer in user service"

# Fix the last commit (forgot a file)
git add src/forgot.js
git commit --amend --no-edit

# Keep the same message when amending
git commit --amend --no-edit

# Mark a commit as needing fixup during rebase
git commit --fixup abc123

# Sign off a commit (DCO)
git commit -s -m "chore: update dependencies"

# Review the diff in the editor before committing
git commit -v

# Create an empty commit to trigger CI
git commit --allow-empty -m "trigger CI build"

# GPG sign a release commit
git commit -S -m "release v2.0"

# Commit only specific files, ignoring other staged changes
git commit src/api.py src/models.py -m "refactor API layer"

# Fix author on the last commit
git commit --amend --author="Correct Name <correct@example.com>" --no-edit

# Reuse message from another commit
git commit -C abc123

# Multi-line message
git commit -m "feat: add dark mode" -m "- Toggle in settings" -m "- Persists to localStorage"
```

---

## Commit Message Conventions

### Conventional Commits

A widely-adopted standard for commit messages:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

| Type | Usage |
|------|-------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `chore` | Maintenance, tooling, deps |
| `docs` | Documentation only |
| `style` | Formatting, linting (no code change) |
| `refactor` | Code restructuring (no behavior change) |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `build` | Build system or CI changes |
| `ci` | CI configuration changes |
| `revert` | Revert a previous commit |

```bash
git commit -m "feat: add user authentication"
git commit -m "fix(api): handle null response from payment gateway"
git commit -m "docs: update README with installation steps"
git commit -m "refactor: extract validation logic into helper module"
```

Breaking changes are indicated with `!` or a `BREAKING CHANGE` footer:

```bash
git commit -m "feat!: drop support for Node 14"
git commit -m "refactor(core)!: migrate to new event system" -m "BREAKING CHANGE: old API removed"
```

---

## Comparison: `git commit` vs `git commit -a` vs `git commit <path>`

| Command | Stages modified | Stages new files | Stages deletions | Scope |
|---------|----------------|------------------|------------------|-------|
| `git commit` | No | No | No | Only already-staged content |
| `git commit -a` | Yes | No | Yes | All tracked files |
| `git commit <path>` | Only `<path>` | Only `<path>` | Only `<path>` | Specified paths only |
| `git commit -i <path>` | Staged + `<path>` | Staged + `<path>` | Staged + `<path>` | Adds to staged |
| `git commit -o <path>` | Only `<path>` | Only `<path>` | Only `<path>` | Replaces staged with paths |

**Workflow comparison:**

```bash
# Usually need two steps
git add .
git commit -m "message"

# One step, but only tracked files
git commit -am "message"

# One step, include new files too
git add -A && git commit -m "message"

# Committing specific files when other changes are staged
git commit src/main.py -m "partial commit"
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git commit` without `-a` does nothing | Only staged changes are committed — unstaged changes are left behind | Use `git add` first, or `git commit -a` |
| Amended a pushed commit | `--amend` rewrites history — push becomes rejected | Never amend commits on shared branches. Use `git revert` instead |
| Committed with wrong author | Forgot to set `user.name`/`user.email` globally | `git commit --amend --author="Name <email>" --no-edit` |
| Message says "please enter the commit message" | Closed editor without saving — Git aborts | Write a message and save. Or `git commit -m "msg"` to skip editor |
| Fixed a bug but committed debug code too | Staged everything with `git add .` including debug logging | Use `git commit -p` to stage only the fix hunks |
| `git commit -a` didn't include new files | `-a` only affects **tracked** files — untracked are ignored | Use `git add newfile && git commit -m "msg"` |
| Forgot `-m` and got launched into Vim | No message flag given — Git opens the default editor | Type message, `:wq`. Or `git commit --amend -m "new msg"` |
| GPG signing fails | No GPG key configured or agent not running | `git config --global user.signingkey KEYID` and start `gpg-agent` |
| Hook rejected the commit | pre-commit hook found issues (lint, tests) | Fix issues, or use `--no-verify` to skip temporarily |

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Always GPG sign commits
[commit]
    gpgSign = true

# Default template for commit messages
    template = ~/.git-commit-template.txt

# Cleanup mode
    cleanup = strip

# Use verbose mode by default (show diff in editor)
    verbose = true
```

Environment variables:

| Variable | Effect |
|----------|--------|
| `GIT_AUTHOR_NAME` | Override author name |
| `GIT_AUTHOR_EMAIL` | Override author email |
| `GIT_AUTHOR_DATE` | Override author date |
| `GIT_COMMITTER_NAME` | Override committer name |
| `GIT_COMMITTER_EMAIL` | Override committer email |
| `GIT_COMMITTER_DATE` | Override committer date |

---

## Visual Summary

```
Working Directory          Staging Area (Index)          Repository
     │                          │                            │
     │    git add               │                            │
     ├─────────────────────────►│                            │
     │                          │                            │
     │    git add + git commit  │                            │
     ├──────────────────────────►───────────────────────────►│
     │                          │                            │
     │    git commit -a         │                            │
     ├──────────────────────────►───────────────────────────►│
     │  (stages tracked +       │                            │
     │   commits in one step)   │                            │
     │                          │                            │
     │    git commit <file>     │                            │
     ├──────────────────────────►───────────────────────────►│
     │  (stages just <file> +   │                            │
     │   commits in one step)   │                            │
     │                          │                            │
     │    git commit --amend    │                            │
     │                          │        replaces HEAD ◄────┤
     │                          │                            │
     │    git commit -p         │                            │
     ├──── (hunk by hunk) ─────►───────────────────────────►│
     │                          │                            │
```

`git commit` is the heart of Git — it's how you save your work, document your progress, and build the project's history. Master the staging area, write clear messages, and use amend/fixup for a clean history.
