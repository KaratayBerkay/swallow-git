# `git reflog` — Manage and inspect the reference log (local history of HEAD and branch tip changes)

`git reflog` tracks every movement of `HEAD` and branch tips in your local repository. When you commit, switch branches, rebase, reset, or amend, the reflog records where you were before and after. This makes it your **safety net** — even if you lose a commit from the branch history, the reflog can find it. Reflog entries expire after 90 days by default (30 days for unreachable commits).

```
git reflog [<subcommand> [<options>]] [<ref>]
git reflog show [<options>] [<ref>]
git reflog expire [--expire=<time>] [--expire-unreachable=<time>] [--rewrite] [--stale-fix] [--all] [<ref>...]
git reflog delete [--rewrite] [--updateref] [<ref>]@{<specifier>}...
git reflog exists <ref>
```

## Description

Every time `HEAD` or a branch tip moves (commits, checkouts, resets, rebases, merges, amends, stashes), Git writes an entry to that ref's reflog. Each entry records:
- The **old** and **new** commit hashes
- Who made the change
- When it happened
- What action caused it

The reflog is purely **local** — it is never pushed, fetched, or cloned. It lives in `.git/logs/`. If that directory is deleted, the reflog is gone.

```
Format of a reflog entry:
abc123def456 HEAD@{0}: commit: fix: handle edge case in parser
                      ^         ^
                      |         └── action and description
                      └── new commit hash
```

### Reference specifiers

A reflog entry is referenced as `<ref>@{<specifier>}`:

| Specifier | What it means | Example |
|-----------|--------------|---------|
| `<n>` | The nth previous position (0 = current) | `HEAD@{0}` (current), `HEAD@{3}` (three moves ago) |
| `--<n>` | The nth previous position (same as `<n>` on older Git) | `HEAD@{-1}` (previous branch) |
| `<date>` | The state at a specific date/time | `HEAD@{yesterday}`, `HEAD@{2.weeks.ago}`, `HEAD@{2024-01-15}` |
| `<relative>` | Relative time | `HEAD@{5.minutes.ago}`, `main@{3.hours.ago}` |

---

## Subcommands

### `show` (default subcommand)

Display the reflog of a reference (defaults to `HEAD`):

```bash
git reflog                  # same as git reflog show HEAD
git reflog show             # show HEAD reflog
git reflog show main        # show main branch reflog
git reflog show --all       # show reflog for all refs
```

When called without arguments, `git reflog` defaults to `git reflog show HEAD`. The output shows entries in reverse chronological order (newest first).

### `expire`

Prune old reflog entries. Entries older than the specified time are removed:

```bash
git reflog expire --expire=30.days --all
git reflog expire --expire=now --all                 # clear all reflog entries
git reflog expire --expire=now --expire-unreachable=now --all
```

`--expire` removes entries older than the given time. `--expire-unreachable` removes entries whose commits are no longer reachable from the ref's current tip (orphaned). `--all` applies to every ref.

### `delete`

Delete specific reflog entries:

```bash
git reflog delete HEAD@{2}
git reflog delete main@{1} HEAD@{3}
```

Only the specified entries are removed — other entries remain.

### `exists`

Check whether a ref has a reflog. Exits with status 0 if it exists, 1 if not:

```bash
git reflog exists HEAD          # 0 (yes)
git reflog exists main          # 0 (yes)
git reflog exists nonexistent   # 1 (no)
```

Useful in scripts to verify a branch has a reflog before operating on it.

---

## Reflog for Recovery

The most common use of the reflog is recovering from mistakes:

```bash
# Oops — reset too far back
git reset --hard HEAD~5
# Wait, I needed those commits!
git reflog                     # find the commit you lost
git reset --hard HEAD@{5}     # go back to where HEAD was 5 moves ago
```

```bash
# Accidentally dropped a stash
git stash drop
# The stash commit is still in the reflog
git reflog show stash
# Look for "stash@{0}: ..." or the drop action
# Find the commit hash, then:
git stash apply <hash>
```

```bash
# Undo a rebase
git rebase main
# Rebase went wrong — commits are messy
git reflog                     # find HEAD before rebase
# Look for "rebase finished" or check the entry before the rebase started
git reset --hard HEAD@{<n>}   # restore to pre-rebase state
```

```bash
# Recover a deleted branch
git branch -D feature-x
# The branch's commits are still reachable via HEAD reflog
git reflog
# Find the last commit on feature-x
git checkout -b feature-x <hash>
```

---

## Config

| Setting | Default | Description |
|---------|---------|-------------|
| `gc.reflogExpire` | `90.days` | How long to keep reflog entries for reachable commits |
| `gc.reflogExpireUnreachable` | `30.days` | How long to keep reflog entries for unreachable (orphaned) commits |
| `core.logAllRefUpdates` | `true` for repos with working tree | Whether to log ref updates automatically |

```bash
# Keep reflog entries for 6 months
git config gc.reflogExpire 180.days

# Keep unreachable entries for 7 days
git config gc.reflogExpireUnreachable 7.days

# Disable automatic reflog (not recommended)
git config core.logAllRefUpdates false
```

The `gc.reflogExpire` setting controls how long entries survive before `git gc` prunes them. Unreachable entries expire faster because orphaned commits are less likely to be needed.

---

## Quick Reference

```bash
# Basic inspection
git reflog                              # Show HEAD reflog (default)
git reflog show                         # Same as above
git reflog show main                    # Reflog for main branch
git reflog show --all                   # Reflog for all refs

# Access specific entries
git show HEAD@{0}                       # Show the current HEAD commit
git show HEAD@{1}                       # Show what HEAD pointed to before
git diff HEAD@{1} HEAD@{0}              # Diff between two reflog entries
git log HEAD@{yesterday}..HEAD          # Commits since yesterday

# Recovery
git reset --hard HEAD@{5}              # Restore HEAD to 5 moves ago
git checkout HEAD@{yesterday}           # Check out yesterday's HEAD (detached)
git cherry-pick HEAD@{2.weeks.ago}      # Cherry-pick a commit from two weeks ago

# Expiration
git reflog expire --expire=30.days --all            # Expire entries older than 30 days
git reflog expire --expire=now --all                # Clear all reflog entries
git reflog expire --expire=now --expire-unreachable=now --all  # Full cleanup

# Delete specific entries
git reflog delete HEAD@{2}                          # Delete one entry
git reflog delete main@{1} HEAD@{3}                 # Delete multiple entries

# Existence check
git reflog exists HEAD                              # Check if reflog exists

# Internal Git
git reflog --format='%H %gD %gs'                   # Custom format output
git reflog --date=iso                               # Show entries with ISO dates
```

---

## Real-World Examples

### See all HEAD movements

```bash
git reflog
```

```
abc123 HEAD@{0}: commit: fix typo in docs
def456 HEAD@{1}: reset: moving to HEAD~3
789abc HEAD@{2}: commit: add caching layer
def456 HEAD@{3}: commit: refactor api module
123def HEAD@{4}: checkout: moving from main to feature-x
```

Each line shows the commit hash, the reflog selector, the action, and the description.

### See specific branch reflog

```bash
git reflog show main
```

Shows all movements of `main` (not HEAD). Useful when you want to see what happened on a specific branch.

### Recover a lost commit after `git reset --hard`

```bash
git reflog
# abc123 HEAD@{0}: reset: moving to HEAD~3
# def456 HEAD@{1}: commit: implement payment processing   <-- need this
# 789abc HEAD@{2}: commit: add validation
git reset --hard HEAD@{1}
# HEAD is now at def456 implement payment processing
```

The commit is restored as if the reset never happened.

### Check out yesterday's HEAD

```bash
git checkout HEAD@{yesterday}
```

Puts you in detached HEAD state at the commit that HEAD pointed to yesterday. Useful for a quick look at what the repo looked like.

### Clear the entire reflog

```bash
git reflog expire --expire=now --all
```

All reflog entries are removed immediately. After this, recovery via reflog is impossible (but the commits themselves may still be reachable from refs).

### Delete a specific reflog entry

```bash
git reflog delete HEAD@{2}
```

Removes only entry `HEAD@{2}`. Other entries shift down (what was `HEAD@{3}` becomes `HEAD@{2}`).

### Check if a ref has a reflog

```bash
git reflog exists main && echo "main has a reflog"
```

Used in scripts to avoid errors when accessing reflog entries of refs that don't have one.

### Recover a dropped stash

```bash
git stash drop
# Dropped stash was stash@{0}
git reflog show stash
#  abc123 stash@{0}: WIP on main: 123abc fix typo
# The stash commit is still in the reflog
git stash apply abc123
```

Dropping a stash removes it from `git stash list`, but the commit is preserved in the stash reflog for 30 days (by default).

### Undo a rebase

```bash
# Before: main ~ A ~ B ~ C ~ D
# git rebase main (but it went wrong)
git reflog
# abc123 HEAD@{0}: rebase finished: returning to refs/heads/feature
# def456 HEAD@{1}: rebase: apply fixup
# 789abc HEAD@{2}: checkout: moving from feature to feature
# 111aaa HEAD@{3}: commit: D                 <-- pre-rebase HEAD
# 222bbb HEAD@{4}: commit: C
git reset --hard HEAD@{3}
# Back to pre-rebase state
```

The reflog shows the exact sequence of rebase operations. Find the entry just before `"rebase finished"` — that is your pre-rebase HEAD.

### Diff between two reflog entries

```bash
git diff HEAD@{2.weeks.ago} HEAD@{yesterday}
```

Shows all changes made in the last two weeks (minus the last day). This is a quick way to review a period of work.

### List only certain types of events

```bash
git reflog --grep-reflog="reset"
git reflog --grep-reflog="rebase"
git reflog --grep-reflog="commit"
```

Filters the reflog to entries whose description matches the pattern.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git reflog` shows nothing useful | Branch was created recently or reflog has been pruned | Check `.git/logs/HEAD` exists; use `git reflog show --all` to see every ref |
| Reflog entry says "commit (amend)" — can't find the old commit | Amending rewrites the commit, but the old commit is still in the reflog | Look one entry before the amend: `git show HEAD@{1}` or `git reset --hard HEAD@{1}` |
| `git reset --hard HEAD@{5}` says "unknown revision" | The entry expired or was deleted | Keep reflogs longer with `gc.reflogExpire`. Use `git fsck --lost-found` as a last resort |
| `git reflog expire --expire=now --all` didn't free disk space | Expiring reflog entries only removes the logs — commits stay until `git gc` | Follow with `git gc --prune=now` to actually remove orphaned commits |
| Reflog shows detached HEAD states | You checked out a commit directly or did a rebase/amend without being on a branch | The reflog is working correctly — use it to find where you were and `git switch -c <branch> <hash>` to create a branch there |
| `git reflog delete HEAD@{0}` removes the current entry | Deletion shifts entries — `HEAD@{0}` is removed and `HEAD@{1}` becomes the new `HEAD@{0}` | The current HEAD commit is still the same — only the reflog entry is gone. The ref itself is unaffected |
| Can't find a commit from yesterday in the reflog | `gc.reflogExpireUnreachable` might have pruned it if the commit became orphaned | Use `git fsck --lost-found` to find dangling commits that outlived their reflog entry |
| `git reflog exists HEAD` returns false in a bare repo | Bare repos don't log ref updates by default unless `core.logAllRefUpdates` is set | Set `core.logAllRefUpdates true` to enable reflog in bare repos |
| Reflog entries are missing after `git clone` | Reflog is local-only and never transferred | Clone creates a new reflog from scratch — only the clone operation itself is recorded |

(End of file - total 264 lines)
