# `git bisect` — Binary search to find the commit that introduced a bug

`git bisect` performs a **binary search** through your commit history to find the exact commit that introduced a bug. Instead of checking commits one by one (linear search), it cuts the search space in half at each step. With 1024 commits, you only need ~10 checks.

```
git bisect start [--term-(bad|new)=<term> --term-(good|old)=<term>]
                 [--no-checkout] [--first-parent] [<bad> [<good>...]] [--] [<pathspecs>...]
git bisect (bad|new|<term-new>) [<rev>]
git bisect (good|old|<term-old>) [<rev>...]
git bisect terms [--term-(good|old) | --term-(bad|new)]
git bisect skip [(<rev>|<range>)...]
git bisect next
git bisect reset [<commit>]
git bisect (visualize|view)
git bisect replay <logfile>
git bisect log
git bisect run <cmd> [<arg>...]
```

## How Binary Search Works

Given a range of N commits, `git bisect` picks the middle one and asks: good or bad?

```
good (working) ←─────────┬─────────→ bad (broken)
                        mid
                  
  good ←─────┬─────→ bad           ← if mid was bad, search first half
            mid2
  
  good ←─┬─→ mid2                    ← if mid2 was good, search second half
         mid3  ← FIRST BAD COMMIT
```

Each step halves the remaining commits. In 10 steps you can search ~1000 commits.

---

## Manual Bisect — The 5-Command Workflow

### 1. Start

```bash
git bisect start
```

### 2. Mark the current commit as bad

```bash
git bisect bad
```

Or specify a specific bad commit:

```bash
git bisect bad HEAD
git bisect bad v2.0
```

### 3. Mark a known-good commit

```bash
git bisect good v1.0
```

You can give multiple good commits to narrow the range:

```bash
git bisect good v1.0 v1.1 v1.2
```

### 4. Test and mark each checked-out commit

Git checks out a commit halfway between good and bad. You test it, then:

```bash
git bisect good    # bug NOT present at this commit
# or
git bisect bad     # bug IS present at this commit
```

Repeat until Git identifies the first bad commit.

### 5. Reset when done

```bash
git bisect reset
```

This returns you to the original HEAD (before `start`).

---

## Shortcut: Start with endpoints in one command

```bash
git bisect start HEAD v1.0
#              bad   good
```

This is equivalent to:
```bash
git checkout HEAD
git bisect start
git bisect bad
git bisect good v1.0
```

You can combine with pathspec to narrow by file:

```bash
git bisect start HEAD v1.0 -- src/auth/
```

Only commits that touched `src/auth/` will be tested.

---

## Options

### `--no-checkout`

Don't checkout the commit — just update `BISECT_HEAD` reference. Useful when testing doesn't need a working tree (e.g., static analysis on committed objects):

```bash
git bisect start --no-checkout HEAD v1.0
```

Automatically assumed for bare repositories.

### `--first-parent`

Follow only the first parent of merge commits. Useful to avoid false positives when a merged branch contained broken intermediate commits:

```bash
git bisect start --first-parent HEAD v1.0
```

Without this, Git would traverse into merged branches and might find a bug in a side branch's broken intermediate commit rather than the merge itself.

### `<pathspec>`

Restrict bisect to commits that touched specific paths:

```bash
git bisect start HEAD v1.0 -- src/api/ tests/api/
```

---

## Alternate Terms

Sometimes you're looking for **any** change, not just a bug. Use `old`/`new` instead of `good`/`bad`:

```bash
git bisect start
git bisect new HEAD       # current commit has the property
git bisect old v1.0       # v1.0 does NOT have the property
```

**Finding a fix** (not a bug):

```bash
git bisect start --term-old broken --term-new fixed
git bisect fixed                  # HEAD has the fix
git bisect broken v1.0            # v1.0 doesn't have it
```

**Finding a performance regression:**

```bash
git bisect start --term-old fast --term-new slow
git bisect slow HEAD
git bisect fast v2.0
```

---

## Skipping Untestable Commits

If the current commit can't be tested (broken build, missing dependencies):

```bash
git bisect skip
```

Skip a range of commits:

```bash
git bisect skip v1.5..v1.7
```

Exit code **125** is used in automated scripts for "skip this commit."

---

## Visualize

See the remaining suspects in `gitk` (GUI) or `git log`:

```bash
git bisect visualize
git bisect visualize --stat
git bisect view
```

---

## Log and Replay

Save the session log to fix a mistake or share with a teammate:

```bash
git bisect log > bisect-session.log
```

Edit the log file to remove incorrect markings, then replay:

```bash
git bisect reset
git bisect replay bisect-session.log
```

---

## Automating with `git bisect run`

If you have a script that exits with a meaningful code, Git can run the entire bisect automatically:

```bash
git bisect start HEAD v1.0
git bisect run ./test-script.sh
```

### Exit code convention

| Exit code | Meaning |
|-----------|---------|
| `0` | Good — bug not present |
| `1`–`127` (except 125) | Bad — bug present |
| `125` | Skip — cannot test this commit |
| `126` | Command found but not executable (POSIX) |
| `127` | Command not found (POSIX) |

### Examples

**Build test (C project):**

```bash
git bisect start HEAD v1.2
git bisect run make
git bisect reset
```

If `make` succeeds (exit 0) → good. If it fails (non-zero) → bad.

**Test suite:**

```bash
git bisect start HEAD origin/main
git bisect run npm test
git bisect reset
```

**Specific test only (faster):**

```bash
git bisect start HEAD HEAD~20
git bisect run npx jest tests/checkout.test.ts
git bisect reset
```

**With skip for broken builds:**

```bash
# test.sh
#!/bin/sh
make || exit 125
./run-tests
```

```bash
git bisect start HEAD HEAD~10
git bisect run ./test.sh
git bisect reset
```

**One-liner inline script:**

```bash
git bisect run sh -c "make || exit 125; ./run-tests"
```

**With hot-fix applied during bisect:**

```bash
#!/bin/sh
# Apply a temporary hot-fix before testing older commits
git merge --no-commit --no-ff hot-fix-branch
if make && ./run-tests; then
  status=$?
else
  status=125
fi
git reset --hard    # undo the tweak
exit $status
```

---

## Real-World Scenarios

### Scenario 1: API regression

A production API endpoint started returning 401 errors. You know it worked at last week's release tag `v2.8.4`:

```bash
git bisect start HEAD v2.8.4
git bisect run sh -c "curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/api/profile | grep -q 200"
git bisect reset
```

### Scenario 2: Performance regression

Response time jumped from 200ms to 2s:

```bash
cat > ~/perf-test.sh << 'EOF'
#!/bin/sh
response=$(curl -s -o /dev/null -w '%{time_total}' http://localhost:4000/api/users)
awk "BEGIN { if ($response < 0.3) exit 0; else exit 1 }"
EOF
chmod +x ~/perf-test.sh

git bisect start HEAD v2.3.0
git bisect run ~/perf-test.sh
git bisect reset
```

### Scenario 3: Finding a fix (not a bug)

When a feature was broken for a while and now it's fixed — find which commit fixed it:

```bash
git bisect start --term-old broken --term-new fixed
git bisect fixed HEAD          # current: fixed
git bisect broken v1.0         # v1.0: broken
git bisect run ./test-feature.sh
git bisect reset
```

### Scenario 4: Large repository — use pathspec

If you know the bug is in a specific module:

```bash
git bisect start HEAD v1.0 -- src/module-x/
git bisect run make test-module-x
```

---

## Quick Reference

```bash
# Start and mark in one command
git bisect start HEAD v1.0

# Manual workflow
git bisect start
git bisect bad
git bisect good v1.0
# ... test, then repeat:
git bisect good   # or git bisect bad

# Automated workflow
git bisect start HEAD v1.0
git bisect run ./test.sh

# Skip a commit
git bisect skip

# Visualize remaining suspects
git bisect visualize

# Save and replay log
git bisect log > session.log
git bisect replay session.log

# Quit and return to original HEAD
git bisect reset

# Quit and stay at the bad commit
git bisect reset HEAD

# Custom terms for non-bug searches
git bisect start --term-old fast --term-new slow
git bisect start --term-old broken --term-new fixed

# Scope to specific paths
git bisect start HEAD v1.0 -- src/auth/

# Follow only first parent (avoid merge noise)
git bisect start --first-parent HEAD v1.0
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Forgetting `git bisect reset` | Leaves you in detached HEAD state | Always run `git bisect reset` when done |
| Wrong good/bad marks | If good commit actually has the bug, bisect gives wrong results | Verify both endpoints before starting |
| Test script in the repo | Git checks out old commits, your script disappears | Put scripts outside the repo (e.g., `~/test.sh`) |
| Running full test suite | Each step runs the full suite — very slow | Run a single focused test per step |
| Flaky tests | Tests that pass/fail inconsistently | Add retry logic to the test script |
| Merge commits confuse results | Bisect follows all parents of merges | Use `--first-parent` to stay on mainline |
| Bisect across branches | Branches with divergent history can confuse the range | Make sure good is an ancestor of bad |

---

## How Many Steps?

| Commits in range | Steps needed |
|-----------------|--------------|
| 10 | 4 |
| 100 | 7 |
| 1000 | 10 |
| 10000 | 14 |
| 100000 | 17 |

Formula: `ceil(log2(N))` where N is the number of commits between good and bad.

---

## Visual Summary

```
Full history:
  ┌───┬───┬───┬───┬───┬───┬───┬───┐
  │g  │   │   │   │   │   │   │b  │
  └───┴───┴───┴───┴───┴───┴───┴───┘
   ↑                           ↑
  good                        bad

Step 1: test middle → good
  ┌───┬───┬───┬───┬───┬───┬───┬───┐
  │g  │g  │g  │   │   │   │   │b  │
  └───┴───┴───┴───┴───┴───┴───┴───┘

Step 2: test middle → bad
  ┌───┬───┬───┬───┬───┬───┬───┬───┐
  │g  │g  │g  │   │b  │   │   │b  │
  └───┴───┴───┴───┴───┴───┴───┴───┘

Step 3: test middle → bad  ← FOUND!
  ┌───┬───┬───┬───┬───┬───┬───┬───┐
  │g  │g  │g  │★b★│   │   │   │   │
  └───┴───┴───┴───┴───┴───┴───┴───┘
```

`git bisect` transforms a tedious manual search into a fast, methodical process. For any reproducible bug with a known good state, it's the fastest way to find the root cause.
