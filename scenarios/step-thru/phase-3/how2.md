# Phase 3 — Branching

**Commands:** `git branch` → `git switch` → `git merge` → `git rebase`

Branching lets you diverge from the main line of work, experiment, and reintegrate. Master these four commands and you'll navigate branches like a pro.

---

## Setup

```bash
$ mkdir -p /tmp/git-phase3 && cd /tmp/git-phase3

$ git init

$ echo "line 1" > file.txt && git add file.txt && git commit -m "Commit 1"

$ echo "line 2" >> file.txt && git add file.txt && git commit -m "Commit 2"

$ echo "line 3" >> file.txt && git add file.txt && git commit -m "Commit 3"
```

---

## Step 1 — Create, list, and rename

```bash
$ git branch

$ git branch feature-a

$ git branch

$ git branch -m feature-a feature-awesome

$ git branch
```

`git branch` lists local branches (the `*` marks your current one). `git branch <name>` creates a branch at the current commit. `git branch -m <old> <new>` renames a branch.

---

## Step 2 — Switch to another branch

```bash
$ git switch feature-awesome

$ git branch
```

`git switch <branch>` moves `HEAD` to that branch. Your working tree updates to match.

---

## Step 3 — Create and switch in one command

```bash
$ git switch -c feature-b

$ git branch
```

`git switch -c <name>` is shorthand for `git branch <name>` followed by `git switch <name>`.

---

## Step 4 — Fast-forward merge

```bash
$ git switch main

$ git merge feature-awesome
```

If the target branch is directly ahead of your current branch, Git simply moves the pointer forward — a *fast-forward* merge.

---

## Step 5 — Three-way merge

```bash
$ git switch -c dev

$ echo "dev content" > dev.txt && git add dev.txt && git commit -m "Dev commit"

$ git switch main

$ echo "main content" > main.txt && git add main.txt && git commit -m "Main commit"

$ git merge dev
```

When branches have diverged, Git creates a new *merge commit* with two parents.

---

## Step 6 — No-fast-forward merge

```bash
$ git switch -c noff

$ echo "noff content" > noff.txt && git add noff.txt && git commit -m "NOFF commit"

$ git switch main

$ git merge --no-ff noff
```

`git merge --no-ff` forces a merge commit even when a fast-forward is possible. Keeps history explicit.

---

## Step 7 — Abort a conflicted merge

```bash
$ git switch -c conflict

$ echo "conflict" >> file.txt && git add file.txt && git commit -m "Conflict branch"

$ git switch main

$ echo "conflict" >> file.txt && git add file.txt && git commit -m "Main branch"

$ git merge conflict

$ git merge --abort
```

When both branches modify the same lines, Git reports a *conflict*. `git merge --abort` undoes the merge and returns to the pre-merge state.

---

## Step 8 — Rebase

```bash
$ git switch -c rebase-work

$ echo "rebase line" > rebase.txt && git add rebase.txt && git commit -m "Rebase commit"

$ git switch main

$ echo "main line" >> file.txt && git add file.txt && git commit -m "Another main commit"

$ git switch rebase-work

$ git rebase main

$ git log --oneline --graph
```

`git rebase <branch>` replays commits from the current branch onto the tip of `<branch>`, creating a linear history. Unlike merge, no extra commit is created.

---

## Step 9 — Interactive rebase

```bash
$ git rebase -i HEAD~3
```

An editor opens listing the last 3 commits. Change `pick` to `squash` to combine, `reword` to edit the message, or reorder lines to rearrange history. Save and close to apply.

---

## Step 10 — Abort a conflicted rebase

```bash
$ git switch -c rebase-conflict

$ echo "conflict line" >> file.txt && git add file.txt && git commit -m "RC1"

$ git switch main

$ echo "conflict line" >> file.txt && git add file.txt && git commit -m "MC1"

$ git switch rebase-conflict

$ git rebase main

$ git rebase --abort
```

If a rebase hits a conflict, `git rebase --abort` returns everything to the state before the rebase started.

---

## Step 11 — Delete a branch

```bash
$ git branch -d feature-awesome

$ git branch -d noff

$ git branch -d dev

$ git branch
```

`git branch -d <name>` deletes a merged branch. Use `-D` to force-delete an unmerged branch.

---

## Practice Scenarios

### Scenario A — Start a feature branch

```bash
$ git switch main

$ git switch -c feature-login

$ echo "login page" > login.html && git add login.html && git commit -m "Add login page"

$ git switch main

$ git merge feature-login

$ git branch -d feature-login
```

### Scenario B — Three-way with conflict

```bash
$ git switch -c fix-a

$ echo "fix" >> file.txt && git add file.txt && git commit -m "Fix A"

$ git switch main

$ echo "fix" >> file.txt && git add file.txt && git commit -m "Fix B"

$ git merge fix-a
```

Resolve the conflict manually, then `git add file.txt && git commit`.

### Scenario C — Rebase a branch onto main

```bash
$ git switch -c feature-rebase

$ echo "feature work" > feature.txt && git add feature.txt && git commit -m "Feature commit"

$ git switch main

$ echo "main update" >> file.txt && git add file.txt && git commit -m "Main update"

$ git switch feature-rebase

$ git rebase main

$ git log --oneline --graph
```

### Scenario D — Squash commits with interactive rebase

```bash
$ echo "fix 1" > fix1.txt && git add fix1.txt && git commit -m "WIP fix 1"

$ echo "fix 2" > fix2.txt && git add fix2.txt && git commit -m "WIP fix 2"

$ echo "fix 3" > fix3.txt && git add fix3.txt && git commit -m "WIP fix 3"

$ git rebase -i HEAD~3
```

In the editor, change the last two `pick` lines to `squash`.

### Scenario E — Rename current branch

```bash
$ git branch -m feature-rebase polished-feature

$ git branch
```

---

## Quick Reference

| Step | Command | What it does |
|------|---------|-------------|
| List | `git branch` | Show local branches |
| Create | `git branch <name>` | Create a new branch |
| Rename | `git branch -m <old> <new>` | Rename a branch |
| Delete | `git branch -d <name>` | Delete a merged branch |
| Switch | `git switch <branch>` | Move to a branch |
| Create+switch | `git switch -c <name>` | Create and switch |
| Merge (ff) | `git merge <branch>` | Fast-forward merge |
| Merge (3-way) | `git merge <branch>` | Merge with a merge commit |
| No-ff | `git merge --no-ff <branch>` | Force merge commit |
| Abort merge | `git merge --abort` | Cancel a conflicted merge |
| Rebase | `git rebase <branch>` | Reapply commits onto another tip |
| Interactive | `git rebase -i <ref>` | Squash, reword, reorder |
| Abort rebase | `git rebase --abort` | Cancel a conflicted rebase |

---

## Common Mistakes

- **Merging while on the wrong branch** — always `git switch` to the target first (e.g., `main`), then merge the feature in.
- **Rebasing shared branches** — never rebase commits that others have already pulled. Use merge instead.
- **Forgetting to delete branches** — stale branches clutter `git branch`. Clean up with `git branch -d` after merging.
- **Merge vs Rebase:** merge preserves history as-is (creates a merge commit); rebase rewrites history for a clean linear line.
- **Force-pushing after rebase** — if you rebase a pushed branch, the next push needs `--force-with-lease`.

---

**Next:** When comfortable, move to [Phase 4](../phase-4/how2.md) — Remotes & Collaboration.
