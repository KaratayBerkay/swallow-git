# Phase 5 — History & Debugging

**Commands:** `git tag` → `git blame` → `git bisect` → `git reflog` → `git cherry-pick`

Tag milestones, trace who wrote what, binary-search through history for bugs, recover lost commits, and pluck specific changes across branches.

---

## Setup

```bash
mkdir /tmp/git-phase5 && cd /tmp/git-phase5
git init

echo "print('Hello')" > app.py
git add app.py
git commit -m "Initial commit"
git tag v1.0

echo "print('Hello World')" > app.py
git add app.py
git commit -m "Update greeting"
git tag v2.0

echo "print('Hello World')" > app.py
echo "result = 1/0  # BUG" >> app.py
git add app.py
git commit -m "Add broken calculation"

echo "print('Hello World')" > app.py
echo "result = 1/0  # BUG" >> app.py
echo "data = [1,2,3]" >> app.py
git add app.py
git commit -m "Add data list"
```

---

## Step 1 — Create lightweight and annotated tags

```bash
git tag v3.0
git tag -a v4.0 -m "Release v4.0 — stable"
git tag -l
```

A **lightweight tag** (`v3.0`) is just a pointer to a commit. An **annotated tag** (`v4.0`) stores the tagger, date, and message — prefer this for releases.

---

## Step 2 — List and delete tags

```bash
git tag -l "v1.*"
git tag -d v3.0
git tag -l
```

`git tag -l` filters by glob. `git tag -d <name>` deletes a local tag.

---

## Step 3 — Push tags to a remote

```bash
git push origin v4.0
git push --tags
```

`git push origin <tag>` pushes one tag. `git push --tags` pushes all tags. *(Requires a configured remote.)*

---

## Step 4 — Blame a file

```bash
git blame app.py
```

Each line shows the commit hash, author, timestamp, and line content. Use it to find **who last touched each line** and in which commit.

---

## Step 5 — Blame a line range

```bash
git blame -L 1,3 app.py
```

Only shows lines 1-3. Useful for zooming in on a suspicious region.

---

## Step 6 — Bisect to find the bug

```bash
git bisect start
git bisect good v1.0
git bisect bad HEAD
cat app.py
git bisect good          # or: git bisect bad
git bisect reset
```

Mark the first known-good commit (`v1.0`) and the current bad commit (`HEAD`). Git checks out the midpoint. Inspect, mark `git bisect good` or `git bisect bad`, repeat until the faulty commit is identified. `git bisect reset` ends the session.

---

## Step 7 — Automate bisect with a script

```bash
cat > /tmp/test.sh << 'EOF'
#!/bin/bash
if grep -q "1/0" app.py; then
    exit 1   # bug present → bad
else
    exit 0   # bug absent → good
fi
EOF
chmod +x /tmp/test.sh

git bisect start
git bisect good v1.0
git bisect bad HEAD
git bisect run /tmp/test.sh
git bisect reset
```

`git bisect run <script>` automates the good/bad decisions. The script exits `0` for good and non-zero for bad.

---

## Step 8 — View the reflog

```bash
git reflog
```

The reflog records every `HEAD` movement — commits, resets, checkouts, merges. Even "lost" commits appear here. Each entry is labelled `HEAD@{n}`.

---

## Step 9 — Recover a lost commit from the reflog

```bash
git log --oneline
git reset --hard HEAD~1
git reflog
git reset --hard HEAD@{1}
git log --oneline
```

The `git reset --hard HEAD~1` discarded the last commit. `git reflog` shows it still exists (previous HEAD), and `git reset --hard HEAD@{1}` restores it.

---

## Step 10 — Cherry-pick a commit from another branch

```bash
git checkout -b feature
echo "print('feature work')" >> app.py
git add app.py
git commit -m "Feat: add feature line"
git log --oneline

git checkout main
git cherry-pick <commit-hash>
git log --oneline
```

Switch to the branch with the commit you want, note its hash, switch back, and `git cherry-pick <hash>` applies just that commit onto the current branch.

---

## Step 11 — Cherry-pick with source reference and abort

```bash
git log --oneline
git cherry-pick -x <commit-hash>
git log --oneline
```

`-x` appends a line `(cherry picked from commit ...)` to the commit message. If conflicts arise during a cherry-pick, use `git cherry-pick --abort` to stop cleanly.

---

## Practice Scenarios

### Scenario A — Tag and push a hotfix

```bash
git tag -a v2.1 -m "Hotfix: critical patch"
git tag -l "v2.*"
git push origin v2.1
```

### Scenario B — Find who changed a specific line

```bash
git blame -L 2,2 app.py
echo "print('new line')" >> app.py
git add app.py
git commit -m "Add new line"
git blame -L 2,4 app.py
```

### Scenario C — Bisect with a manual check

```bash
git bisect start
git bisect good v1.0
git bisect bad HEAD
cat app.py
git bisect good
cat app.py
git bisect bad
git bisect reset
```

### Scenario D — Recover from a mistaken reset

```bash
echo "important data" > secret.txt
git add secret.txt
git commit -m "Add secret"
git reset --hard HEAD~1
git reflog
git reset --hard HEAD@{1}
ls
```

### Scenario E — Cherry-pick multiple commits

```bash
git checkout -b experiment
echo "change A" >> app.py
git add app.py
git commit -m "Change A"
echo "change B" >> app.py
git add app.py
git commit -m "Change B"
git log --oneline --all

git checkout main
git cherry-pick <hash-A> <hash-B>
git log --oneline
```

---

## Quick Reference

| Step | Command | What it does |
|------|---------|-------------|
| Lightweight tag | `git tag <name>` | Create a simple tag at HEAD |
| Annotated tag | `git tag -a <name> -m "msg"` | Create a tag with metadata |
| List tags | `git tag -l` | Show all tags (with optional glob) |
| Delete tag | `git tag -d <name>` | Remove a local tag |
| Push one tag | `git push origin <tag>` | Push a single tag to remote |
| Push all tags | `git push --tags` | Push every local tag to remote |
| Blame file | `git blame <file>` | Show who last changed each line |
| Blame range | `git blame -L m,n <file>` | Blame only lines m–n |
| Start bisect | `git bisect start` | Begin a binary search session |
| Mark good | `git bisect good <ref>` | Mark a commit as bug-free |
| Mark bad | `git bisect bad <ref>` | Mark a commit as buggy |
| Auto bisect | `git bisect run <script>` | Automate good/bad decisions |
| End bisect | `git bisect reset` | Exit bisect and return to original HEAD |
| Show reflog | `git reflog` | List all HEAD movements |
| Recover reflog | `git reset --hard HEAD@{n}` | Reset to a reflog entry |
| Cherry-pick | `git cherry-pick <commit>` | Apply a single commit onto current branch |
| Cherry-pick with ref | `git cherry-pick -x <commit>` | Cherry-pick and annotate source in message |
| Abort cherry-pick | `git cherry-pick --abort` | Cancel a conflicted cherry-pick |

---

## Common Mistakes

- **Forgetting `-a` on tags** — lightweight tags lack metadata. Use `git tag -a` with `-m` for releases.
- **Not pushing tags** — tags are local only. Explicitly push with `git push origin <tag>` or `git push --tags`.
- **Blaming the wrong person** — `git blame` shows the *last modifier*, not necessarily the author who introduced the bug.
- **Bisecting without a clear good/bad** — both endpoints must be cleanly reproducible. Test each manually first.
- **Forgetting `git bisect reset`** — bisect leaves you on an old commit. Always run `git bisect reset` when done.
- **Relying only on `git log` for recovery** — `git reflog` is the safety net; `git log` won't show dangling commits.
- **Cherry-picking without the right base** — cherry-pick applies a diff. If the target branch already has similar changes, expect conflicts.
- **Running `git reset --hard` without checking `git status` first** — you will lose uncommitted work permanently.

---

**Next:** When comfortable, move to [Phase 6](../phase-6/how2.md) — Collaboration & Remotes.
