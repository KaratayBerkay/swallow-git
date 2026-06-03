# Phase 2 — Undo & Restore

**Commands:** `git restore` → `git reset` → `git stash` → `git revert`

Mistakes happen. This phase teaches you to safely undo changes, recover files, stash work-in-progress, and revert commits without losing your mind.

---

## Setup

```bash
mkdir /tmp/git-phase2 && cd /tmp/git-phase2
git init
echo "Line 1" > file.txt
echo "Initial" > main.py
git add file.txt main.py
git commit -m "Initial commit"
```

---

## Step 1 — Unstage a file (`git restore --staged`)

```bash
echo "oops" >> file.txt
git add file.txt
git status
git restore --staged file.txt
git status
```

`file.txt` is back to *modified* but no longer staged. The change is still in the working tree.

---

## Step 2 — Discard working changes (`git restore`)

```bash
echo "junk" >> file.txt
git restore file.txt
cat file.txt
```

`git restore <file>` discards **unstaged** changes. The file reverts to the last staged or committed version.

---

## Step 3 — Undo the last commit, keep staged (`git reset --soft`)

```bash
echo "feature" >> main.py
git add main.py
git commit -m "feature work"
git reset --soft HEAD~1
git status
```

`--soft` moves `HEAD` back one commit but leaves everything staged. You can re-commit with a better message.

---

## Step 4 — Undo the last commit, keep working (`git reset --mixed`)

```bash
echo "fix" >> main.py
git add main.py
git commit -m "fix"
git reset --mixed HEAD~1
git status
```

`--mixed` (the default) moves `HEAD` back and unstages files. Changes stay **in the working tree** so you can re-edit first.

---

## Step 5 — Undo and destroy everything (`git reset --hard`)

```bash
echo "doomed" >> main.py
git add main.py
git commit -m "doomed"
git reset --hard HEAD~1
git status
git log --oneline
```

`--hard` is **destructive** — it removes the commit **and** discards working tree changes. Use only when you are sure.

---

## Step 6 — Stash work-in-progress (`git stash`)

```bash
echo "WIP change" >> file.txt
git stash push -m "saving WIP"
git stash list
git status
```

Working directory is now clean. The uncommitted change is saved away.

---

## Step 7 — Restore a stash (`git stash pop` / `git stash apply`)

```bash
git stash pop
```

`git stash pop` restores the latest stash and removes it from the list. Use `git stash apply` to restore without dropping it. Use `git stash drop` to delete a stash manually.

---

## Step 8 — Revert a commit safely (`git revert`)

```bash
echo "bad idea" >> file.txt
git add file.txt
git commit -m "bad commit"
git log --oneline
git revert HEAD --no-edit
git log --oneline
cat file.txt
```

`git revert HEAD` creates a **new commit** that undoes the previous one. History is preserved — safe for shared branches.

---

## Step 9 — Revert without auto-commit (`git revert --no-commit`)

```bash
echo "another change" >> file.txt
git add file.txt
git commit -m "another commit"
git revert --no-commit HEAD
git status
git diff --cached
git commit -m "Revert another commit"
```

`--no-commit` stages the reverse changes so you can inspect or amend them before committing.

---

## Practice Scenarios

### Scenario A — Unstage then discard

```bash
echo "data" > temp.txt
git add temp.txt
git restore --staged temp.txt
git restore temp.txt
git status
```

### Scenario B — Soft reset to amend a commit message

```bash
echo "real work" >> main.py
git add main.py
git commit -m "wip"
git reset --soft HEAD~1
git commit -m "feat: implement real work"
git log --oneline
```

### Scenario C — Stash multiple contexts

```bash
echo "context A" > a.txt
git stash push -m "work on feature A"
echo "context B" > b.txt
git stash push -m "work on feature B"
git stash list
git stash pop
git stash drop
```

### Scenario D — Revert a specific commit (not HEAD)

```bash
echo "alpha" > alpha.txt
git add alpha.txt
git commit -m "Add alpha"
echo "beta" > beta.txt
git add beta.txt
git commit -m "Add beta"
git revert HEAD --no-edit
git log --oneline
```

### Scenario E — Recover from a hard reset with reflog

```bash
echo "important" >> file.txt
git add file.txt
git commit -m "important work"
git reset --hard HEAD~1
git reflog
git reset --hard HEAD@{1}
cat file.txt
```

---

## Quick Reference

| Step | Command | What it does |
|------|---------|-------------|
| Unstage | `git restore --staged <file>` | Undo `git add` |
| Discard working | `git restore <file>` | Revert file to last committed/staged version |
| Soft reset | `git reset --soft HEAD~1` | Undo commit, keep changes staged |
| Mixed reset | `git reset --mixed HEAD~1` | Undo commit, keep working tree changes |
| Hard reset | `git reset --hard HEAD~1` | Destroy last commit **and** working changes |
| Stash save | `git stash push -m "msg"` | Save uncommitted changes aside |
| Stash list | `git stash list` | Show all stashes |
| Stash pop | `git stash pop` | Restore & remove latest stash |
| Stash apply | `git stash apply` | Restore without removing from stash list |
| Stash drop | `git stash drop` | Delete a specific stash |
| Revert | `git revert HEAD` | Undo a commit with a new commit |
| Revert no-commit | `git revert --no-commit HEAD` | Stage reverse changes without committing |

---

## Common Mistakes

- **Using `git reset --hard` on uncommitted work** — you will lose those changes permanently. Double-check with `git status` first.
- **Forgetting `--staged` in `git restore`** — `git restore <file>` discards working changes; add `--staged` to unstage only.
- **Reverting a public commit with `git reset`** — never rewrite history on shared branches. Use `git revert` instead.
- **Losing stashes** — `git stash pop` on a dirty working tree can cause merge conflicts. Use `git stash apply` if you want to inspect first.
- **Thinking `git revert` removes history** — it creates a *new* commit. All previous commits remain in the log.

---

**Next:** When comfortable, move to [Phase 3](../phase-3/how2.md) — Branch & Merge.
