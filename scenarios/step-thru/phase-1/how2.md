# Phase 1 — The Core Loop

**Commands:** `git status` → `git add` → `git diff` → `git commit` → `git log` → `git push`

This is the **daily Git workflow**. Master it, and you know 80% of what you'll do day-to-day.

---

## Setup

Create a throwaway repo to practise in:

```bash
mkdir /tmp/git-phase1 && cd /tmp/git-phase1
git init
echo "Hello Git" > README.md
```

---

## Step 1 — Check the state

```bash
git status
```

See `README.md` listed as *untracked* — Git sees it but isn't tracking it.

---

## Step 2 — Stage the file

```bash
git add README.md
git status
```

`README.md` moves to *Changes to be committed* (staged). The file is now in the staging area.

---

## Step 3 — See what's staged

```bash
git diff --cached
```

Shows the exact diff that will go into the next commit. Use `git diff` (without `--cached`) to compare working tree vs staging.

**Try this:** edit `README.md`, run `git diff`, then `git diff --cached`, then `git add .`, then `git diff --cached` again.

---

## Step 4 — Commit

```bash
git commit -m "Initial commit"
```

A snapshot is saved. The staging area is now empty.

---

## Step 5 — View history

```bash
git log --oneline
```

Shows your one commit. Try `git log --oneline --graph` for a visual.

---

## Step 6 — Push (if you have a remote)

```bash
git remote add origin <your-repo-url>
git push -u origin main
```

Only if you set up a remote repo (GitHub, GitLab, etc.).

---

## Practice Scenarios

### Scenario A — Add another file

```bash
echo "Some content" > file.txt
git status
git add file.txt
git commit -m "Add file.txt"
git log --oneline
```

### Scenario B — Edit and commit

```bash
echo "More content" >> README.md
git diff
git add README.md
git commit -m "Update README"
git log --oneline
```

### Scenario C — Multiple edits, one commit

```bash
echo "alpha" > a.txt
echo "beta"  > b.txt
git add a.txt
git add b.txt
git status
git commit -m "Add a.txt and b.txt"
```

### Scenario D — Review before staging

```bash
echo "change" >> a.txt
git diff              # unstaged diff
git add a.txt
git diff --cached     # staged diff
git commit -m "Change a.txt"
```

### Scenario E — Undo a bad add

```bash
echo "junk" > junk.txt
git add junk.txt                          # staged by mistake
git restore --staged junk.txt             # unstage (undo add)
git status                                # junk.txt is untracked again
```

---

## Quick Reference

| Step | Command | What it does |
|------|---------|-------------|
| Inspect | `git status` | Show working tree and staging state |
| Stage | `git add <file>` | Move file to staging area |
| Diff working | `git diff` | Show unstaged changes |
| Diff staged | `git diff --cached` | Show staged changes |
| Commit | `git commit -m "msg"` | Snapshot staged changes |
| History | `git log --oneline` | Show commit history |
| Unstage | `git restore --staged <file>` | Undo `git add` |
| Push | `git push` | Upload commits to remote |

---

## Common Mistakes

- **Editing after `git add`** — the staged version is stale. Run `git add` again.
- **Committing without `git add`** — only staged changes are committed.
- **Forgetting `-m`** — Git opens an editor. Save and close to finish.
- **Pushing before pulling** — if the remote has new commits, you need `git pull` first.

---

**Next:** When comfortable, move to [Phase 2](../phase-2/how2.md) — Undo & Restore.
