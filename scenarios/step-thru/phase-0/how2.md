# Phase 0 — Foundation

**Commands:** `git init`

The very first step with any Git project: initialise a repository. `git init` creates the `.git/` directory that Git uses to store metadata, objects, and refs.

---

## Setup

No prior repo needed. You only need an empty directory:

```bash
mkdir /tmp/git-phase0 && cd /tmp/git-phase0
```

---

## Step 1 — Basic init

```bash
git init
```

Git replies `Initialized empty Git repository in /tmp/git-phase0/.git/`. The `.git/` folder now exists.

---

## Step 2 — Inspect `.git/`

```bash
ls -F .git
```

You'll see subdirectories like `objects/`, `refs/`, and files like `HEAD`, `config`, `description`. This is the engine room of Git.

---

## Step 3 — Init with a name

```bash
cd /tmp
git init my-project
```

Creates `my-project/` and runs `git init` inside it in one shot. No `mkdir` needed.

---

## Step 4 — Reinit an existing repo

```bash
cd /tmp/git-phase0
git init
```

Running `git init` on an already-initialised repo is safe — Git prints `Reinitialized existing Git repository` and updates any missing templates without destroying existing data.

---

## Step 5 — Bare repo

```bash
cd /tmp
git init --bare my-project.git
```

A bare repo has no working tree — only the `.git/` internals (stored directly in the top-level directory). Used for central/server-side remotes.

---

## Practice Scenarios

### Scenario A — Init and verify

```bash
cd /tmp
mkdir scenario-a && cd scenario-a
git init
ls -a
```

### Scenario B — Named init

```bash
cd /tmp
git init scenario-b
ls scenario-b/.git
```

### Scenario C — Bare repo for a remote

```bash
cd /tmp
git init --bare scenario-c.git
git ls-tree HEAD   # empty, no commits yet
```

### Scenario D — Reinit is harmless

```bash
cd /tmp
mkdir scenario-d && cd scenario-d
git init
echo "data" > file.txt
git add file.txt && git commit -m "first"
git init
git log --oneline    # commits preserved
```

---

## Quick Reference

| Step | Command | What it does |
|------|---------|-------------|
| Init | `git init` | Create a new Git repo in current directory |
| Named init | `git init <dir>` | Create directory and init repo inside it |
| Bare init | `git init --bare <dir>` | Create bare repo (no working tree) |
| Reinit | `git init` | Safe to re-run; updates templates |
| Inspect | `ls -F .git` | View the Git metadata directory |

---

## Common Mistakes

- **Running `git init` inside an already-tracked project** — harmless, but unnecessary. Git will just reinit.
- **Forgetting `--bare` on a server repo** — you'll get a working tree you don't need.
- **Expecting a `.git` folder in a bare repo** — bare repos *are* the `.git` folder; there is no separate `.git/` inside.
- **Using `git init` as root** — never run Git commands as root. File ownership issues will bite you later.

---

**Next:** When comfortable, move to [Phase 1](../phase-1/how2.md) — The Core Loop.
