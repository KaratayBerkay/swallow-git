# Phase 4 — Remote Collaboration

**Commands:** `git clone` → `git fetch` → `git pull` → `git push`

Remote repos let you share work across machines and with other people. This phase covers the full cycle: cloning a repo, syncing changes from others, and publishing your own.

---

## Setup

Create a bare "remote" repo and clone it to simulate collaboration on a single machine:

```bash
$ mkdir -p /tmp/git-phase4

$ cd /tmp/git-phase4

$ git init --bare remote.git

$ cd /tmp/git-phase4

$ git clone remote.git local

$ cd local

$ git config user.name "You"

$ git config user.email "you@example.com"

$ echo "# Hello" > README.md

$ git add README.md

$ git commit -m "Initial commit"

$ git push -u origin main
```

---

## Step 1 — Clone a repo

```bash
$ cd /tmp/git-phase4

$ git clone remote.git clone2

$ cd clone2

$ git log --oneline
```

`git clone <url>` copies the entire repo, including all history. Add `--depth 1` for a shallow clone (only the latest snapshot):

```bash
$ cd /tmp/git-phase4

$ git clone --depth 1 remote.git shallow

$ cd shallow

$ git log --oneline
```

---

## Step 2 — List and add remotes

```bash
$ cd /tmp/git-phase4/local

$ git remote -v

$ git remote add upstream https://example.com/upstream.git

$ git remote -v
```

`git remote -v` lists all remotes. `git remote add <name> <url>` adds a new one. The first remote is conventionally called `origin`.

---

## Step 3 — Fetch changes (download, no merge)

Simulate a change from another clone:

```bash
$ cd /tmp/git-phase4/clone2

$ echo "Feature" > feature.txt

$ git add feature.txt

$ git commit -m "Add feature"

$ git push
```

Now fetch in `local`:

```bash
$ cd /tmp/git-phase4/local

$ git fetch origin

$ git log --oneline origin/main

$ git log --oneline main
```

`git fetch` downloads data but leaves your working tree untouched. Use `git fetch -p` to prune references to deleted remote branches:

```bash
$ git fetch -p
```

---

## Step 4 — Pull (fetch + merge)

```bash
$ git pull origin main

$ git log --oneline
```

`git pull` is shorthand for `git fetch` followed by `git merge`. For a linear history, use rebase instead:

```bash
$ git pull --rebase origin main
```

---

## Step 5 — Push (upload)

Make a local commit and send it:

```bash
$ echo "Another file" > data.txt

$ git add data.txt

$ git commit -m "Add data.txt"

$ git push origin main
```

First push of a new branch needs `-u` to set upstream tracking:

```bash
$ git checkout -b dev

$ echo "dev work" > dev.txt

$ git add dev.txt

$ git commit -m "Start dev branch"

$ git push -u origin dev
```

---

## Step 6 — Delete a remote branch

```bash
$ git push --delete origin dev
```

---

## Step 7 — Push tags

```bash
$ git tag v1.0

$ git push --tags
```

---

## Step 8 — Safe force push

When you need to rewrite remote history (e.g., after an interactive rebase), use `--force-with-lease` instead of `--force`:

```bash
$ git commit --amend -m "Better message"

$ git push --force-with-lease origin main
```

`--force-with-lease` checks that your remote-tracking branch matches the remote, preventing you from overwriting someone else's work.

---

## Practice Scenarios

### Scenario A — Full cycle with two clones

```bash
$ cd /tmp/git-phase4

$ git clone remote.git alice

$ cd alice

$ echo "alice change" >> README.md

$ git add README.md && git commit -m "Alice's change"

$ git push

$ cd /tmp/git-phase4

$ git clone remote.git bob

$ cd bob

$ echo "bob change" >> README.md

$ git add README.md && git commit -m "Bob's change"

$ git pull --rebase

$ git push
```

### Scenario B — Fetch and inspect before merging

```bash
$ cd /tmp/git-phase4/alice

$ echo "experiment" > exp.txt

$ git add exp.txt && git commit -m "Experiment"

$ git push

$ cd /tmp/git-phase4/bob

$ git fetch origin

$ git log --oneline origin/main

$ git merge origin/main
```

### Scenario C — Shallow clone for CI

```bash
$ git clone --depth 1 remote.git ci-build

$ cd ci-build

$ git log --oneline
```

### Scenario D — Add a second remote

```bash
$ git remote add backup /tmp/git-phase4/backup.git

$ git remote -v
```

### Scenario E — Delete a remote branch and prune

```bash
$ git push --delete origin exp

$ git fetch -p

$ git branch -a
```

---

## Quick Reference

| Step | Command | What it does |
|------|---------|-------------|
| Clone | `git clone <url>` | Full copy of a remote repo |
| Shallow clone | `git clone --depth 1 <url>` | Only the latest commit |
| List remotes | `git remote -v` | Show fetch/push URLs |
| Add remote | `git remote add <name> <url>` | Register a new remote |
| Fetch | `git fetch <remote>` | Download commits, no merge |
| Fetch prune | `git fetch -p` | Remove stale remote-tracking refs |
| Pull | `git pull <remote> <branch>` | Fetch + merge |
| Pull rebase | `git pull --rebase <remote> <branch>` | Fetch + rebase |
| Push | `git push <remote> <branch>` | Upload commits |
| Push set upstream | `git push -u <remote> <branch>` | Push + track branch |
| Delete remote branch | `git push --delete <remote> <branch>` | Remove branch on remote |
| Push tags | `git push --tags` | Upload all local tags |
| Safe force push | `git push --force-with-lease <remote> <branch>` | Force push with safety check |

---

## Common Mistakes

- **Pushing before pulling** — if the remote has new commits, Git rejects your push. Always `git pull` (or `git pull --rebase`) first.
- **Using `git push --force` instead of `--force-with-lease`** — `--force` overwrites blindly and can destroy a collaborator's work. Prefer `--force-with-lease`.
- **Forgetting `-u` on first push** — without it, Git doesn't set upstream tracking and you'll need to spell out the remote/branch every time.
- **Fetching but never merging** — `git fetch` alone doesn't update your working tree. You must `git merge` or `git pull` to integrate.
- **Cloning without `--depth` for CI** — full clones take longer and use more disk. Use `--depth 1` in automated builds unless you need full history.

---

**Next:** When comfortable, move to [Phase 5](../phase-5/how2.md) — Branching Strategies.
