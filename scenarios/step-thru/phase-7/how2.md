# Phase 7 — Power Tools

**Commands:** `git worktree` → `git bundle` → `git archive` → `git lfs`

Beyond everyday commits and branches, Git ships with a set of specialised tools for sharing snapshots, working on multiple branches at once, archiving projects, and handling large files.

---

## Setup

```bash
mkdir /tmp/git-phase7 && cd /tmp/git-phase7
git init
echo "README content" > README.md
git add README.md && git commit -m "Initial commit"
git branch feature-a
git branch feature-b
echo "Feature A work" > a.txt
git add a.txt && git commit -m "Work on feature-a"
```

---

## Step 1 — Add a worktree for another branch

```bash
git worktree add ../phase7-feature-a feature-a
```

Creates `../phase7-feature-a/` with `feature-a` checked out. You can work on both directories simultaneously without stashing or switching branches.

---

## Step 2 — List and remove worktrees

```bash
git worktree list
git worktree remove ../phase7-feature-a
git worktree prune
```

`git worktree list` shows every linked working tree. `remove` deletes one (after you're done). `prune` cleans up stale worktree metadata.

---

## Step 3 — Lock a worktree

```bash
git worktree add ../phase7-locked feature-b
git worktree lock ../phase7-locked --reason "In progress"
git worktree list
```

Locking prevents accidental pruning of a worktree still in use. The `--reason` flag attaches a note visible in the list output.

---

## Step 4 — Create a bundle

```bash
git bundle create ../repo.bundle feature-a
```

Bundles a branch into a single file (`.bundle`) that can be transferred offline or via USB. The recipient can clone or fetch from it.

---

## Step 5 — Verify and clone from a bundle

```bash
git bundle verify ../repo.bundle
git bundle list-heads ../repo.bundle
cd /tmp
git clone ../repo.bundle phase7-clone
cd phase7-clone
git log --oneline
```

`verify` checks bundle integrity. `list-heads` shows available refs. `git clone` from a bundle works like cloning from a remote URL.

---

## Step 6 — Create an archive (tarball)

```bash
cd /tmp/git-phase7
git archive -o ../project.tar HEAD
```

Produces a `project.tar` containing the files at `HEAD`. No Git metadata — just the source tree.

---

## Step 7 — Create a ZIP archive

```bash
git archive --format=zip -o ../project.zip HEAD
```

Same as above but in ZIP format. Useful for distributing releases to non-Git users.

---

## Step 8 — Install and track with Git LFS

```bash
git lfs install
git lfs track "*.psd"
git lfs status
```

`git lfs install` sets up LFS hooks. `track` tells Git to store `*.psd` files as pointers (the real content lives on the LFS server). `status` shows tracked patterns.

---

## Step 9 — Migrate existing large files to LFS

```bash
git lfs migrate import --everything --above=100MB
```

Rewrites history so that any blob larger than 100 MB is stored as an LFS pointer. This is a destructive operation — never run it on a shared branch without coordination.

---

## Practice Scenarios

### Scenario A — Worktree isolation

```bash
cd /tmp && rm -rf git-phase7 && mkdir git-phase7 && cd git-phase7
git init
echo "init" > f.txt && git add f.txt && git commit -m "init"
git branch side
git worktree add ../side-repo side
echo "side change" > ../side-repo/f.txt
cat f.txt        # still "init" — unchanged
git worktree remove ../side-repo
```

### Scenario B — Bundle up a feature branch

```bash
cd /tmp/git-phase7
echo "feature" > feat.txt
git add feat.txt && git commit -m "Feature commit"
git bundle create ../feature.bundle main
cd /tmp
git clone feature.bundle clone-bundle
cd clone-bundle
git log --oneline
```

### Scenario C — Archive and extract

```bash
cd /tmp/git-phase7
git archive -o ../release.tar HEAD
cd /tmp
tar xf release.tar
ls          # project files — no .git
```

### Scenario D — Archive as ZIP

```bash
cd /tmp/git-phase7
git archive --format=zip -o ../release.zip HEAD
cd /tmp
unzip -l release.zip
```

### Scenario E — Track a pattern with LFS

```bash
cd /tmp/git-phase7
git lfs install
git lfs track "*.iso"
echo "fake" > big.iso
git add big.iso .gitattributes
git commit -m "Track ISO files with LFS"
git lfs status
```

---

## Quick Reference

| Step | Command | What it does |
|------|---------|-------------|
| Add worktree | `git worktree add <path> <branch>` | Checkout branch in a new directory |
| List worktrees | `git worktree list` | Show all linked working trees |
| Remove worktree | `git worktree remove <path>` | Delete a linked worktree |
| Lock worktree | `git worktree lock <path>` | Prevent pruning of a worktree |
| Prune worktrees | `git worktree prune` | Clean stale worktree metadata |
| Create bundle | `git bundle create <file> <ref>` | Pack a branch into a single file |
| Verify bundle | `git bundle verify <file>` | Check bundle integrity |
| List bundle refs | `git bundle list-heads <file>` | Show available refs in a bundle |
| Clone from bundle | `git clone <file> <dir>` | Clone from a bundle file |
| Archive tarball | `git archive -o <file>.tar HEAD` | Create a tar archive of HEAD |
| Archive ZIP | `git archive --format=zip -o <file>.zip HEAD` | Create a ZIP archive of HEAD |
| Install LFS | `git lfs install` | Set up Git LFS hooks |
| Track pattern | `git lfs track "<pattern>"` | Store matching files via LFS |
| LFS status | `git lfs status` | Show tracked patterns and files |
| Migrate to LFS | `git lfs migrate import --everything --above=<size>` | Rewrite history to use LFS for large blobs |

---

## Common Mistakes

- **Forgetting to `git add .gitattributes`** — `git lfs track` writes to `.gitattributes`, but if you don't commit it, other clones won't know the pattern.
- **Using `git worktree add` inside an existing worktree** — the path must not exist or be empty. Git will refuse to create a worktree over existing files.
- **Trying to remove a worktree without cleaning it first** — `git worktree remove` rejects dirty worktrees. Commit or stash changes first.
- **Archiving without excluding build artifacts** — `git archive` respects `.gitattributes` export-ignore settings. Use `export-ignore` to strip `node_modules/`, `target/`, etc.
- **Running `git lfs migrate` on a shared branch** — migration rewrites commit SHAs. Coordinate with the team or do it before sharing.
- **Forgetting `git lfs install` in a fresh clone** — LFS hooks aren't active until you run `install`. Files will look like pointer text instead of real content.

---

**Next:** When comfortable, loop back to [Phase 1](../phase-1/how2.md) and build your core workflow again with these power tools in your belt.
