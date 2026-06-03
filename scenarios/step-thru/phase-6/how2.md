# Phase 6 — Submodules & Subtrees

**Commands:** `git submodule` → `git subtree`

Submodules embed a pointer to another Git repo; subtrees copy its files directly into your tree. Both let you manage external dependencies, but with very different trade-offs.

---

## Setup

Create a bare "library" repo (acts as a remote) and a worktree clone to push initial content. Then create a main project repo.

```bash
$ git init --bare /tmp/git-phase6-lib.git

$ git clone /tmp/git-phase6-lib.git /tmp/git-phase6-lib-work

$ cd /tmp/git-phase6-lib-work

$ echo '#!/usr/bin/env bash' > greet.sh

$ echo 'echo "Hello from lib!"' >> greet.sh

$ git add greet.sh && git commit -m "initial library commit"

$ git push origin main
```

```bash
$ mkdir -p /tmp/git-phase6 && cd /tmp/git-phase6

$ git init

$ echo "# My App" > README.md

$ git add README.md && git commit -m "initial commit"
```

---

## Step 1 — Add a submodule

Point to the library repo from your main project. The submodule records a **commit pointer**, not the files themselves.

```bash
$ git submodule add /tmp/git-phase6-lib.git lib

$ git status

$ git diff --cached

$ git commit -m "add lib submodule"
```

A new file `.gitmodules` tracks the mapping. The `lib/` directory now contains the library's files at the pinned commit.

---

## Step 2 — Clone a repo with submodules

When someone clones your project, the submodule directories are empty unless they opt in.

```bash
$ cd /tmp

$ git clone --recurse-submodules /tmp/git-phase6 phase6-clone

$ cd phase6-clone

$ ls lib/greet.sh
```

If you already cloned without `--recurse-submodules`, initialise submodules manually:

```bash
$ git submodule update --init --recursive
```

---

## Step 3 — Update a submodule to the latest commit

Make a change in the library, then pull it into the main project.

```bash
$ cd /tmp/git-phase6-lib-work

$ echo 'echo "v2 feature"' >> greet.sh

$ git add greet.sh && git commit -m "v2 feature"

$ git push origin main
```

Back in the main repo:

```bash
$ cd /tmp/git-phase6

$ git submodule update --remote lib

$ git status

$ git add lib && git commit -m "update lib submodule to latest"
```

---

## Step 4 — Run a command in every submodule

`git submodule foreach` runs a shell command inside each submodule directory.

```bash
$ git submodule foreach 'git pull'

$ git submodule foreach 'git status'

$ git submodule foreach 'echo "--- $name ---"'
```

---

## Step 5 — Remove a submodule

Deinitialise, remove from the tree, and scrub Git's metadata.

```bash
$ git submodule deinit lib

$ git rm lib

$ rm -rf .git/modules/lib

$ git commit -m "remove lib submodule"
```

---

## Step 6 — Add a subtree

A subtree **copies** the library's files into your repo with a squashed merge history.

```bash
$ cd /tmp/git-phase6

$ git subtree add --prefix=lib /tmp/git-phase6-lib.git main --squash

$ git log --oneline

$ ls lib/greet.sh
```

---

## Step 7 — Pull from the subtree source

Update the subtree with upstream changes.

```bash
$ cd /tmp/git-phase6-lib-work

$ echo 'echo "v3 feature"' >> greet.sh

$ git add greet.sh && git commit -m "v3 feature"

$ git push origin main
```

```bash
$ cd /tmp/git-phase6

$ git subtree pull --prefix=lib /tmp/git-phase6-lib.git main --squash
```

---

## Step 8 — Push subtree changes back upstream

If you modify files inside the subtree, push those changes back to the source repo.

```bash
$ echo 'echo "fix from main project"' >> lib/greet.sh

$ git add lib/greet.sh && git commit -m "fix greet.sh in subtree"

$ git subtree push --prefix=lib /tmp/git-phase6-lib.git main
```

---

## Practice Scenarios

### Scenario A — Add a submodule from an external URL

```bash
$ git submodule add https://github.com/org/some-lib.git vendor/some-lib

$ git add .gitmodules vendor/some-lib

$ git commit -m "add vendor/some-lib submodule"

$ git clone --recurse-submodules <your-repo-url>
```

### Scenario B — Pin a submodule to an older commit

```bash
$ cd lib

$ git checkout abc1234

$ cd ..

$ git add lib

$ git commit -m "pin lib to abc1234"
```

### Scenario C — Add a dependency as a subtree

```bash
$ git subtree add --prefix=vendor/colors https://github.com/example/colors.git main --squash

$ git log --oneline

$ git diff --stat vendor/colors/
```

### Scenario D — Compare submodule vs subtree workflows

```bash
$ git submodule add /tmp/somelib.git modules/lib

$ git commit -m "submodule approach"

$ git subtree add --prefix=modules/lib /tmp/somelib.git main --squash

$ git commit -m "subtree approach"
```

---

## Quick Reference

| Step | Command | What it does |
|------|---------|-------------|
| Add submodule | `git submodule add <url> <path>` | Record a submodule pointer |
| Clone with submodules | `git clone --recurse-submodules <url>` | Clone repo and init all submodules |
| Init submodules | `git submodule update --init --recursive` | Fetch submodule content on existing clone |
| Update to latest | `git submodule update --remote` | Pull latest commit into submodule |
| Run command in all | `git submodule foreach '<cmd>'` | Run shell command in each submodule |
| Remove submodule | `git submodule deinit <path>`; `git rm <path>` | Deinit and delete submodule |
| Add subtree | `git subtree add --prefix=<path> <url> <branch> --squash` | Copy remote branch as subtree |
| Pull subtree | `git subtree pull --prefix=<path> <url> <branch>` | Update subtree from source |
| Push subtree | `git subtree push --prefix=<path> <url> <branch>` | Send subtree changes upstream |

### Submodule vs Subtree

| Aspect | Submodule | Subtree |
|--------|-----------|---------|
| How content is stored | Commit pointer (`.gitmodules`) | Actual files in your tree |
| Clone experience | Needs `--recurse-submodules` or init | Included automatically |
| Modify upstream | Separate repo, manual sync | Files are local; push back |
| History | Separate history per submodule | Squashed or full history merged in |
| Ease of use | Harder for beginners, more precise | Simpler for consumers, less precise |
| Best for | Large / many dependencies | Few / small dependencies you may edit |

---

## Common Mistakes

- **Forgetting `--recurse-submodules` on clone** — submodule directories are empty; run `git submodule update --init --recursive`.
- **Committing without `git add` after `update --remote`** — the new pointer isn't recorded in the superproject.
- **Not removing `.git/modules/<name>`** — stale metadata lingers after submodule removal.
- **Using URLs only you can reach** — collaborators get fetch errors; use a shared remote.
- **Forgetting `--squash` on subtree add** — the full source history floods your commit log.
- **Editing subtree files without pushing back** — changes stay local; use `git subtree push` to upstream them.

---

**Next:** When comfortable, move to [Phase 7](../phase-7/how2.md) — Power Tools.
