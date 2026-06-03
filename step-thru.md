# Git Learning Step-Thru

Commands are organized by **prerequisites** — you must be comfortable with earlier phases before moving on. Each phase builds on the previous.

---

## Phase 0: Foundation

| # | Command | Why first |
|---|---------|-----------|
| 1 | `git init` | Creates the repo. Nothing works without a repo. |

No dependencies. Run once per project.

---

## Phase 1: The Core Loop

This is the **daily workflow** — the cycle you repeat dozens of times a day.

| # | Command | Prerequisite | Runs without? |
|---|---------|-------------|---------------|
| 2 | `git status` | — | Yes, shows current state anytime |
| 3 | `git add` | — | Yes, stages files for commit |
| 4 | `git diff` | — | Yes, compares working tree / staging / commits |
| 5 | `git commit` | `git add` (staged changes) | No — nothing to commit without staged files |
| 6 | `git log` | `git commit` | Partially — shows empty history without commits |
| 7 | `git push` | `git commit` + remote | No — nothing to push without commits |

**Dependency chain:**
```
git status (inspect) → git add (stage) → git commit (snapshot) → git push (share)
```

`git diff` and `git log` are read-only inspectors — safe to run anytime.

---

## Phase 2: Undo & Restore

These fix mistakes made during the core loop.

| # | Command | Prerequisite | What it undoes |
|---|---------|-------------|----------------|
| 8 | `git restore` | `git add` (staged changes) | Unstages files or discards working-tree changes |
| 9 | `git reset` | `git commit` | Moves branch pointer back (un-commits) |
| 10 | `git stash` | `git add` (working changes) | Temporarily shelves changes |
| 11 | `git revert` | `git commit` | Creates a new commit that undoes a past commit |

**Order matters:**
```
git restore  ← undoes git add (staging mistakes)
git reset    ← undoes git commit (commit mistakes, local only)
git revert   ← undoes git commit (safe for shared history)
git stash    ← shelves work-in-progress (switch branches without committing)
```

---

## Phase 3: Branching

Multi-branch workflows unlock Git's real power.

| # | Command | Prerequisite | Notes |
|---|---------|-------------|-------|
| 12 | `git branch` | `git commit` | Lists/creates/deletes branches. Needs at least one commit. |
| 13 | `git switch` | `git branch` | Changes the current branch. Target branch must exist. |
| 14 | `git merge` | `git branch` + `git commit` on each branch | Joins two branches. Needs divergent history. |
| 15 | `git rebase` | `git branch` + `git commit` | Re-applies commits on top of another base. **Do not rebase pushed commits.** |

**Dependency chain:**
```
git commit (at least 1) → git branch (create feature) → git switch (move to it)
                                                       → git merge (join back)
                                                       → git rebase (reapply on top)
```

Learn `git merge` first, then `git rebase` once you understand the difference.

---

## Phase 4: Remote Collaboration

Working with others — fetch, pull, clone, and push.

| # | Command | Prerequisite | Notes |
|---|---------|-------------|-------|
| 16 | `git clone` | — | Copies a remote repo (alternative to `init`) |
| 17 | `git fetch` | `git clone` or `git remote add` | Downloads remote objects without merging |
| 18 | `git pull` | `git fetch` | `git fetch` + `git merge` (or `git rebase` with config) |
| 19 | `git push` | `git commit` | Uploads local commits to remote |

**Flow:**
```
git clone (get repo) → git fetch (check for updates)
                     → git pull (fetch + merge)
git commit (local)   → git push (share)
```

`git fetch` is safe — it never changes your working tree. `git pull` is `fetch` + `merge`.

---

## Phase 5: History & Debugging

Explore and diagnose the commit graph.

| # | Command | Prerequisite | Notes |
|---|---------|-------------|-------|
| 20 | `git tag` | `git commit` | Marks a specific commit (releases, versions) |
| 21 | `git blame` | `git commit` (file with history) | Shows who last modified each line |
| 22 | `git bisect` | `git commit` (many commits) | Binary search to find the commit that introduced a bug |
| 23 | `git reflog` | Any repo activity | Local diary of HEAD movements — recovers "lost" commits |
| 24 | `git cherry-pick` | `git commit` (on another branch) | Applies a specific commit onto current branch |

**Prerequisite chain:**
```
git log (understand history) → git blame (drill into a file)
                             → git bisect (hunt a bug across commits)
                             → git tag (label important commits)
                             → git cherry-pick (pluck commits between branches)
                             → git reflog (recover from mistakes)
```

`git reflog` is a **safety net** — learn it early in this phase.

---

## Phase 6: Submodules & Subtrees

Managing external dependencies inside your repo.

| # | Command | Prerequisite | Notes |
|---|---------|-------------|-------|
| 25 | `git submodule` | Host repo with commits | Embeds another repo as a subdirectory (linked) |
| 26 | `git subtree` | Host repo with commits | Merges another repo's history into a subdirectory |

**Comparison:**
```
git submodule — external repo stays separate (link), needs --recurse-submodules on clone
git subtree   — external repo merged into your history (no link), no special clone needed
```

Learn `git submodule` first (more common), then `git subtree` (simpler for some cases).

---

## Phase 7: Power Tools

Advanced utilities for specific workflows.

| # | Command | Prerequisite | Notes |
|---|---------|-------------|-------|
| 27 | `git worktree` | `git commit` | Multiple working directories from one repo |
| 28 | `git bundle` | `git commit` | Package objects/refs into a single file (offline transfer) |
| 29 | `git archive` | `git commit` | Create a tar/zip of the repo |
| 30 | `git lfs` | Installed Git LFS extension | Large file storage (binaries, assets) |

No strict ordering within this phase — all assume a working repo with commits.

---

## Full Dependency Graph

```
git init
   │
   ├── git status (always available)
   ├── git diff   (always available)
   ├── git add
   │    ├── git commit ─── git log
   │    │    ├── git push
   │    │    ├── git tag
   │    │    ├── git reset
   │    │    ├── git revert
   │    │    ├── git branch ─── git switch
   │    │    │                 ├── git merge
   │    │    │                 └── git rebase
   │    │    ├── git blame
   │    │    ├── git bisect
   │    │    ├── git cherry-pick
   │    │    ├── git worktree
   │    │    ├── git bundle
   │    │    ├── git archive
   │    │    └── git lfs
   │    │
   │    ├── git restore
   │    └── git stash
   │
   └── git clone
        └── (same tree as init, plus...)
            └── git fetch ─── git pull
                            └── git push (needs remote + commits)
```

---

## Recommended Learning Order

| Step | Command | Why this order |
|------|---------|----------------|
| 1 | `git init` | Start here — create a repo |
| 2 | `git status` | Learn to inspect state |
| 3 | `git add` | Stage changes |
| 4 | `git diff` | See changes before staging |
| 5 | `git commit` | Save a snapshot |
| 6 | `git log` | View history you just created |
| 7 | `git push` | Share commits |
| 8 | `git restore` | Fix staging mistakes |
| 9 | `git reset` | Undo local commits |
| 10 | `git stash` | Shelve WIP |
| 11 | `git revert` | Safe undo for shared history |
| 12 | `git branch` | Create branches |
| 13 | `git switch` | Move between branches |
| 14 | `git merge` | Join branches |
| 15 | `git rebase` | Reapply commits |
| 16 | `git clone` | Get a remote repo |
| 17 | `git fetch` | Download updates |
| 18 | `git pull` | Fetch + merge |
| 19 | `git tag` | Label releases |
| 20 | `git blame` | Find who wrote what |
| 21 | `git bisect` | Find bug origins |
| 22 | `git reflog` | Recover from anything |
| 23 | `git cherry-pick` | Pick specific commits |
| 24 | `git submodule` | Embed repos |
| 25 | `git subtree` | Merge external projects |
| 26 | `git worktree` | Work on multiple branches at once |
| 27 | `git bundle` | Offline transfer |
| 28 | `git archive` | Export snapshots |
| 29 | `git lfs` | Large files |

---

*Created as a companion to the `commands/` directory — each command's full docs are at `commands/<git-command>/how2.md`.*
