# `git submodule` — Manage submodules (external repositories inside a repository)

`git submodule` lets you incorporate and track one Git repository as a subdirectory inside another repository. The superproject records a **commit hash** for each submodule, pinning it to a specific version. Submodules are Git repositories in their own right — they have their own history, branches, and remotes.

```
git submodule [--quiet] [--cached]
git submodule [--] add [-b <branch>] [-f|--force] [--name <name>]
             [--reference <repository>] [--depth <depth>] [--] <repository> [<path>]
git submodule [--] status [--cached] [--recursive] [--] [<path>...]
git submodule [--] init [-q|--quiet] [--] [<path>...]
git submodule [--] deinit [-f|--force] [--all] [--] [<path>...]
git submodule [--] update [-q|--quiet] [--init] [--remote] [-N|--no-fetch]
             [-f|--force] [--checkout|--rebase|--merge] [--reference <repository>]
             [--depth <depth>] [--recursive] [--jobs <n>] [--] [<path>...]
git submodule [--] set-url [--] <path> <newurl>
git submodule [--] set-branch [-b|--branch <branch>] [--default] [--] <path>
git submodule [--] summary [--cached|--files] [--summary-limit <n>] [<commit>] [--] [<path>...]
git submodule [--] foreach [--recursive] <command>
git submodule [--] absorbgitdirs
```

---

## Description

A **submodule** is a Git repository embedded inside another Git repository. The superproject (outer repo) stores the submodule's URL and the exact commit checked out in the `.gitmodules` file and the index.

```
Superproject
├── .git/
├── .gitmodules            ← submodule config (URLs, paths, branches)
├── src/
├── README.md
└── libs/
    └── lib-a/             ← submodule (separate Git repo)
        ├── .git           ← (or in superproject's .git/modules/)
        ├── src/
        └── README.md
```

Key points:
- The superproject **pins** the submodule to a specific commit — not a branch
- Running `git submodule update` checks out the recorded commit in the submodule
- Changes inside a submodule are tracked by its own Git repo, not the superproject
- The superproject sees the submodule as a single **gitlink** entry (mode `160000`)

---

## Basic Usage

### `git submodule add <url> <path>`

Add a new submodule:

```bash
git submodule add https://github.com/user/lib.git libs/lib
```

This:
1. Clones the repository into `libs/lib`
2. Records the URL and path in `.gitmodules`
3. Stages both `.gitmodules` and the submodule commit in the index

The `.gitmodules` file looks like:

```ini
[submodule "libs/lib"]
    path = libs/lib
    url = https://github.com/user/lib.git
```

Commit the result:

```bash
git add .gitmodules libs/lib
git commit -m "add libs/lib submodule"
```

**With a specific branch:**

```bash
git submodule add -b main https://github.com/user/lib.git libs/lib
```

The branch is recorded in `.gitmodules` and used by `--remote` updates.

### `git submodule init`

Register submodules in `.git/config` from `.gitmodules`:

```bash
git submodule init
```

This reads `.gitmodules` and copies the URL configuration into `.git/config`. Without `init`, `git submodule update` does not know where to fetch from.

Initialize specific submodules only:

```bash
git submodule init libs/lib
```

### `git submodule update`

Fetch and check out the recorded commit for each submodule:

```bash
git submodule update
```

This reads the commit hash from the superproject's index and checks it out in the submodule.

**Most common combination — init + update in one step:**

```bash
git submodule update --init
```

**Recursive (nested submodules):**

```bash
git submodule update --init --recursive
```

### `git submodule status`

Show the current pinned commit of each submodule:

```bash
git submodule status
```

Output format:

```
 3b9c7a2f5a1e4c8d0f3b6a9c1e2d4f5a6b7c8d9e libs/lib (v1.2.3)
-3b9c7a2f5a1e4c8d0f3b6a9c1e2d4f5a6b7c8d9e libs/lib (v1.2.3)
+3b9c7a2f5a1e4c8d0f3b6a9c1e2d4f5a6b7c8d9e libs/lib (HEAD)
U3b9c7a2f5a1e4c8d0f3b6a9c1e2d4f5a6b7c8d9e libs/lib (v1.2.3)
```

| Prefix | Meaning |
|--------|---------|
| (none) | Submodule matches the index |
| `-` | Submodule is not initialized |
| `+` | Submodule has uncommitted changes |
| `U` | Submodule has merge conflicts |

**Only specific submodules:**

```bash
git submodule status libs/lib
```

**Recursive:**

```bash
git submodule status --recursive
```

### `git submodule deinit`

Unregister and remove a submodule (does not delete the remote repository):

```bash
git submodule deinit libs/lib
```

This removes the submodule's working tree, clears its entry from `.git/config`, and removes the gitlink from the index. The `.gitmodules` entry is **not** removed.

**Force (remove even with local changes):**

```bash
git submodule deinit -f libs/lib
```

**Deinitialize all submodules:**

```bash
git submodule deinit --all
```

### `git submodule foreach`

Run a command in each submodule:

```bash
git submodule foreach 'git status'
```

The command runs inside each submodule's working directory.

Available variables:
- `$name` — submodule name (from `.gitmodules`)
- `$path` — path relative to superproject
- `$sha` — recorded commit SHA
- `$toplevel` — absolute path to superproject root

**Recursive (also runs in nested submodules):**

```bash
git submodule foreach --recursive 'git status'
```

**Pull all submodules:**

```bash
git submodule foreach 'git checkout main && git pull'
```

### `git submodule summary`

Show a summary of changes between the current submodule commit and the superproject's recorded commit:

```bash
git submodule summary
```

Output:

```
* libs/lib v1.2.0..v1.2.3 (3):
  < fix: handle edge case
  < feat: add new API endpoint
  < chore: update dependencies
```

**Limit the number of entries:**

```bash
git submodule summary --summary-limit 5
```

**Compare against a specific commit:**

```bash
git submodule summary HEAD~3
```

**Compare using the index (`--cached`) or working tree (`--files`):**

```bash
git submodule summary --cached
git submodule summary --files
```

### `git submodule set-url`

Change a submodule's remote URL:

```bash
git submodule set-url libs/lib https://new-url.com/lib.git
```

This updates the URL in both `.gitmodules` and `.git/config`. Commit the `.gitmodules` change afterwards.

### `git submodule set-branch`

Change or clear the tracked branch for a submodule:

```bash
git submodule set-branch -b develop libs/lib
git submodule set-branch --default libs/lib    # clear branch (use any commit)
```

Updates the `branch` field in `.gitmodules`.

### `git submodule absorbgitdirs`

Move each submodule's `.git` directory into the superproject's `.git/modules/`:

```bash
git submodule absorbgitdirs
```

Before:
```
libs/lib/.git   ← standalone Git directory inside the submodule
```

After:
```
.git/modules/libs/lib   ← centralized in superproject
libs/lib/.git           ← now a file containing "gitdir: ../.git/modules/libs/lib"
```

This is the modern layout — it protects submodule data from accidental deletion and is required for some operations to work correctly.

---

## Cloning with Submodules

### `git clone --recurse-submodules`

Clone a repository and all its submodules in one step:

```bash
git clone --recurse-submodules https://github.com/user/project.git
```

This is equivalent to:

```bash
git clone https://github.com/user/project.git
cd project
git submodule update --init --recursive
```

### Dealing with an already-cloned repo

If you forgot `--recurse-submodules`:

```bash
git clone https://github.com/user/project.git
cd project
git submodule update --init --recursive
```

---

## Updating Submodules

### `git submodule update` (default: checkout)

Fetches the submodule and checks out the **recorded commit** (detached HEAD):

```bash
git submodule update
```

The submodule ends up in a **detached HEAD** state at the pinned commit.

### `git submodule update --remote`

Update each submodule to the latest commit on the branch specified by `.gitmodules` (or the default remote's `HEAD`):

```bash
git submodule update --remote
```

This fetches from the submodule's remote and checks out the **tip of the tracked branch** (not the superproject's pinned commit). The superproject's reference is **not** updated — you must commit the new submodule hash:

```bash
git add libs/lib
git commit -m "update libs/lib to latest"
```

**With a specific branch:**

```bash
git submodule set-branch -b main libs/lib
git submodule update --remote libs/lib
```

### `git submodule update --rebase`

Rebase the current branch in the submodule onto the newly fetched commit:

```bash
git submodule update --rebase
```

Useful when you have local submodule commits and want to replay them on top of the updated version.

### `git submodule update --merge`

Merge the newly fetched commit into the submodule's current branch:

```bash
git submodule update --merge
```

Safer than `--rebase` — preserves your local submodule commits as a merge.

### `git submodule update --remote --merge`

Update to the latest remote tip and merge local changes:

```bash
git submodule update --remote --merge
```

Common workflow for keeping submodules up-to-date while preserving local modifications.

### `git submodule update --force`

Discard local changes in the submodule and force it to match the recorded commit:

```bash
git submodule update --force
```

---

## Config

Set in `.gitconfig` or repo `.git/config`:

```ini
# Automatically recurse into submodules for most commands
[submodule]
    recurse = true

# Parallel fetch jobs for submodule updates
    fetchJobs = 4
```

### `submodule.recurse`

When `true`, commands like `git status`, `git diff`, `git pull`, `git push`, `git checkout` automatically recurse into submodules:

```bash
git config --global submodule.recurse true
```

### `submodule.fetchJobs`

Fetch submodules in parallel during `git submodule update`:

```bash
git config submodule.fetchJobs 4
```

This significantly speeds up repos with many submodules.

### `.gitmodules` file format

The `.gitmodules` file lives in the root of the superproject and is version-controlled:

```ini
[submodule "libs/lib"]
    path = libs/lib
    url = https://github.com/user/lib.git
    branch = main
    update = rebase
    shallow = true
```

| Key | Description |
|-----|-------------|
| `path` | Relative path in the superproject |
| `url` | Remote URL to clone from |
| `branch` | Branch for `--remote` updates (optional) |
| `update` | Default update strategy: `checkout`, `rebase`, `merge`, `none` |
| `shallow` | `true` to make shallow submodule clones |
| `fetchRecurseSubmodules` | `true`/`false` to control recursive fetch |

---

## Nested Submodules

Submodules can themselves contain submodules. The `--recursive` flag recurses into all nested levels:

```bash
git submodule update --init --recursive
git submodule status --recursive
git submodule foreach --recursive 'git status'
```

Without `--recursive`, operations only affect the top-level submodules.

---

## Quick Reference

```bash
# Add a submodule
git submodule add https://github.com/user/lib.git libs/lib
git submodule add -b main https://github.com/user/lib.git libs/lib

# Clone with submodules
git clone --recurse-submodules https://github.com/user/project.git
git clone --recurse-submodules --jobs 4 https://github.com/user/project.git

# Init and update
git submodule init
git submodule update
git submodule update --init
git submodule update --init --recursive

# Update to latest remote (tracked branch)
git submodule update --remote
git submodule update --remote --merge
git submodule update --remote --rebase

# Force update (discard local changes)
git submodule update --force

# Status
git submodule status
git submodule status --recursive

# Deinit (remove)
git submodule deinit libs/lib
git submodule deinit -f libs/lib

# Foreach
git submodule foreach 'git status'
git submodule foreach 'git checkout main && git pull'
git submodule foreach --recursive 'git clean -fd'

# Summary
git submodule summary
git submodule summary --summary-limit 5

# Set URL
git submodule set-url libs/lib https://new-url.com/lib.git

# Set branch
git submodule set-branch -b develop libs/lib
git submodule set-branch --default libs/lib

# Absorb gitdirs
git submodule absorbgitdirs
```

---

## Real-World Examples

### 1. Add a library as a submodule

```bash
git submodule add https://github.com/user/lib.git libs/lib
git add .gitmodules libs/lib
git commit -m "add libs/lib submodule"
```

Adds an external library pinned to a specific version.

### 2. Clone a project with submodules

```bash
git clone --recurse-submodules https://github.com/user/project.git
```

One command to get the full project including all dependencies.

### 3. Initialize and update all submodules (existing clone)

```bash
git submodule update --init --recursive
```

The standard command after cloning a repo that has submodules.

### 4. Update all submodules to their latest commit

```bash
git submodule update --remote --merge
```

Fetches the latest commit on each submodule's tracked branch and merges it.

### 5. Pull latest changes in all submodules

```bash
git submodule foreach 'git checkout main && git pull'
```

Switches each submodule to `main` and pulls the latest changes.

### 6. Check status of all submodules recursively

```bash
git submodule status --recursive
```

Shows the pinned commit and dirty state of every submodule at every nesting level.

### 7. Remove a submodule completely

```bash
git submodule deinit -f libs/lib
git rm libs/lib
rm -rf .git/modules/libs/lib
git commit -m "remove libs/lib submodule"
```

Fully removes the submodule from the working tree, index, and `.gitmodules`.

### 8. Change a submodule's remote URL

```bash
git submodule set-url libs/lib https://new-url.com/lib.git
git add .gitmodules
git commit -m "update libs/lib URL"
```

Updates the remote URL and commits the change.

### 9. Move submodule Git data to superproject

```bash
git submodule absorbgitdirs
```

Should be run after checking out or adding submodules. Centralizes all submodule Git directories under `.git/modules/`.

### 10. Update to latest with merge (safe local changes)

```bash
git submodule update --remote --merge libs/lib
```

Updates `libs/lib` to the latest remote commit, merging any local changes you have in the submodule.

### 11. Run a command in every submodule

```bash
git submodule foreach 'git log --oneline -5'
```

Shows the last 5 commits in each submodule's history.

### 12. Parallel submodule fetch

```bash
git submodule update --init --recursive --jobs 8
```

Clones and updates submodules in parallel using 8 concurrent jobs.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Submodule directory is empty after clone | Forgot `--recurse-submodules` or `git submodule update --init` | Run `git submodule update --init --recursive` |
| Detached HEAD in submodule | `git submodule update` checks out the pinned commit, not a branch | Use `--remote` to track a branch, or `git checkout <branch>` inside the submodule |
| `git submodule update` fails with "No URL found" | Submodule not initialized | Run `git submodule init` first, or use `git submodule update --init` |
| Need to commit after `--remote` update | `--remote` updates the submodule but does not update the superproject's pointer | `git add <submodule-path> && git commit` |
| Submodule shows as modified (`+` prefix) but you didn't change it | The submodule's checked-out commit differs from what the index expects | `git submodule update` to sync, or commit the new hash |
| `git pull` does not update submodules | `submodule.recurse` is not set | `git config submodule.recurse true` or `git submodule update --init --recursive` after pull |
| Accidental submodule changes lost during checkout | `git checkout` in the superproject can overwrite dirty submodules | Use `--recurse-submodules` or stash submodule changes first |
| `git submodule deinit` does not remove `.gitmodules` entry | `deinit` only removes the working tree and config, not the `.gitmodules` file | Manually remove the section from `.gitmodules` and `git add .gitmodules` |
| Cloning behind a proxy fails for submodules | Submodule URLs may use a different protocol | Use relative URLs in `.gitmodules` or configure `insteadOf` for the submodule's remote |
| `error: git-submodule is not a git command` | Git version too old | Update Git to 1.7+ (submodules have existed since 1.5.3) |
| Conflicts when pulling superproject with submodule updates | Someone else updated the submodule pin | Resolve like a normal file conflict — choose the correct submodule commit |
| Submodule contains nested submodules that aren't fetched | Missing `--recursive` flag | Add `--recursive` to `git submodule update` and `git clone` |

(End of file - total 506 lines)
