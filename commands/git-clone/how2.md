# `git clone` — Clone a repository into a new directory

The `git clone` command copies an existing Git repository from a remote URL (or local path) to your machine. It sets up a full local repository with all the remote's history, creates remote-tracking branches for every branch on the remote, and checks out an initial branch (usually `main` or `master`).

```
git clone [--template=<template-directory>] [-l] [-s] [--no-hardlinks] [-q] [-n] [--bare] [--mirror]
          [-o <name>] [-b <name>] [-u <upload-pack>] [--reference <repository>]
          [--dissociate] [--separate-git-dir <git-dir>]
          [--depth <depth>] [--[no-]single-branch] [--[no-]tags]
          [--recurse-submodules[=<pathspec>]] [--[no-]shallow-submodules]
          [--[no-]remote-submodules] [--jobs <n>] [--sparse] [--[no-]reject-shallow]
          [--filter=<filter-spec> [--also-filter-submodules]] [--] <repository> [<directory>]
```

Think of `git clone` as a two-step process:
1. **Download** all objects and refs from the remote (like `git fetch`)
2. **Check out** the default branch into the working directory (like `git checkout`)

The source is called the **remote** and is given the name `origin` by default.

---

## Description

When you run `git clone`, Git:

1. Creates a new directory at the specified path (or uses the repo name from the URL)
2. Initializes a new `.git` directory inside it
3. Adds a remote called `origin` pointing to the source URL
4. Fetches all objects and refs from that remote
5. Sets up **remote-tracking branches** for every branch on the remote (e.g., `refs/remotes/origin/main`)
6. Checks out the initial branch (usually the one `HEAD` points to on the remote, or the branch specified by `-b`)

**Key difference from `git init` + `git remote add` + `git fetch`:** `git clone` does all of this in one command. The result is a fully functional repository with a working tree.

**Remote-tracking branches** are local read-only copies of the remote's branches. They update on `git fetch`/`git pull` and are named `origin/branch-name`. You cannot check them out directly — to work on one, create a local branch from it:

```bash
git switch feature-x
# Creates a local branch tracking origin/feature-x
```

---

## Basic Usage

### `git clone <url>` — Clone into default directory

```bash
git clone https://github.com/user/repo.git
```

Creates a directory named `repo` (derived from the URL) containing the repository.

Output:
```
Cloning into 'repo'...
remote: Enumerating objects: 100, done.
remote: Counting objects: 100% (100/100), done.
Receiving objects: 100% (100/100), 1.2 MiB | 2.5 MiB/s, done.
Resolving deltas: 100% (45/45), done.
```

### `git clone <url> <directory>` — Clone into a specific directory

```bash
git clone https://github.com/user/repo.git my-project
```

Creates a directory named `my-project` instead of `repo`.

### `git clone <url> .` — Clone into current directory

```bash
git clone https://github.com/user/repo.git .
```

Clones into the current (already empty) directory. The directory must be empty.

---

## Protocol URLs

Git supports several transport protocols for cloning:

| Protocol | URL Format | Auth | Use Case |
|----------|------------|------|----------|
| **HTTPS** | `https://github.com/user/repo.git` | Password/token | Most common, works through firewalls |
| **SSH** | `ssh://git@github.com/user/repo.git` | SSH key | No password prompts, faster auth |
| **SCP-style** | `git@github.com:user/repo.git` | SSH key | Shorthand, very common for GitHub |
| **Git** | `git://example.com/repo.git` | None | Fast, unencrypted. Port 9418. |
| **Local** | `/path/to/repo.git` or `file:///path/to/repo.git` | Filesystem | Local filesystem clones |
| **HTTP** | `http://example.com/repo.git` | None | Unencrypted, not recommended |

**SCP-style URLs** (`git@github.com:user/repo.git`) are syntactic sugar — Git converts them to `ssh://git@github.com/user/repo.git` internally.

**When to use which:**

- **HTTPS** is the most portable and works everywhere, including behind corporate proxies. You'll need a personal access token for private repos.
- **SSH** is preferred for frequent interaction — once your key is set up, no passwords needed.

---

## Shallow Clones

A shallow clone downloads only a **partial history** — useful for large repos where you only need recent commits.

### `--depth=<depth>`

Limit the clone to `<depth>` commits from the tip of each branch:

```bash
git clone --depth 1 https://github.com/user/repo.git
# Only the latest commit (no history)
```

```bash
git clone --depth 5 https://github.com/user/repo.git
# Latest 5 commits of each branch
```

**Trade-offs:**
- ✅ Much faster clone (downloads less data)
- ✅ Less disk space
- ❌ No access to older history (cannot `git log` before the depth)
- ❌ Cannot `git push` from a shallow clone to a new remote without unshallowing
- ❌ Some Git operations (`git describe`, `git bisect` over full range) are limited

### `--shallow-since=<date>`

Clone all commits newer than a date:

```bash
git clone --shallow-since="2025-01-01" https://github.com/user/repo.git
```

### `--shallow-exclude=<revision>`

Clone history excluding commits reachable from a given ref (tag, branch, commit):

```bash
git clone --shallow-exclude=v1.0 https://github.com/user/repo.git
```

### `--[no-]reject-shallow`

Control whether to refuse cloning from a shallow source:

```bash
git clone --reject-shallow https://github.com/user/repo.git
# Fail if the source is itself a shallow clone

git clone --no-reject-shallow https://github.com/user/repo.git
# Allow cloning from a shallow source (default for unshallowing)
```

### Unshallowing later

A shallow clone can be deepened later with `git fetch --depth=<new-depth>` or unshallowed completely with `git fetch --unshallow`:

```bash
git clone --depth 1 https://github.com/user/repo.git
cd repo
git fetch --unshallow    # Fetch full history
```

---

## Branch Control

### `-b <name>` (or `--branch=<name>`)

Check out a specific branch instead of the remote's `HEAD`:

```bash
git clone -b develop https://github.com/user/repo.git
git clone -b v1.0 https://github.com/user/repo.git   # Tag works too
```

Without `-b`, Git checks out the branch that `HEAD` points to on the remote (usually `main` or `master`).

### `--single-branch`

Clone only the history of one branch (default when `--depth` is used):

```bash
git clone --single-branch -b main https://github.com/user/repo.git
```

Only `main` is cloned. No remote-tracking branches are created for other branches. Combine with `--depth` for maximum efficiency:

```bash
git clone --depth 1 --single-branch -b main https://github.com/user/repo.git
```

Use `--no-single-branch` to force cloning all branches even with `--depth`:

```bash
git clone --depth 1 --no-single-branch https://github.com/user/repo.git
# All branches, each truncated to 1 commit
```

### `--[no-]tags`

Control whether tags are fetched:

- `--tags` — fetch **all** tags (Git normally only fetches tags reachable from cloned branches)
- `--no-tags` — fetch **no** tags

```bash
git clone --no-tags https://github.com/user/repo.git
# No tags in the local repo
```

```bash
git clone --tags https://github.com/user/repo.git
# Every tag from the remote
```

### `-o <name>` (or `--origin=<name>`)

Rename the remote from the default `origin` to something else:

```bash
git clone -o upstream https://github.com/user/repo.git
git remote -v
# upstream  https://github.com/user/repo.git (fetch)
# upstream  https://github.com/user/repo.git (push)
```

Useful when you're cloning someone else's repo and plan to also add your own fork as `origin`.

### `-b <name>` combined with `--single-branch`

Clone only one specific branch:

```bash
git clone -b develop --single-branch https://github.com/user/repo.git
```

---

## Bare and Mirror

### `--bare`

Clone without a working directory — only the Git data (the contents of `.git` directly in the target folder):

```bash
git clone --bare https://github.com/user/repo.git repo.git
```

Creates `repo.git/` containing:
```
repo.git/
├── HEAD
├── config
├── description
├── hooks/
├── info/
├── objects/
├── packed-refs
└── refs/
```

**Use case:** Setting up a **server-side mirror** or **central repository** that receives pushes. No one will work directly in this repo.

### `--mirror`

A more complete bare clone. Like `--bare` but also copies all refs exactly as they are on the remote (including refs from `refs/pull/`, `refs/notes/`, etc.):

```bash
git clone --mirror https://github.com/user/repo.git repo.git
```

**Difference between `--bare` and `--mirror`:**

| Aspect | `--bare` | `--mirror` |
|--------|----------|------------|
| Remote config | `origin` with fetch = `+refs/heads/*:refs/heads/*` | `origin` with fetch = `+refs/*:refs/*` |
| Refs copied | Heads (branches) only | All refs: heads, tags, pull requests, notes, etc. |
| Re-cloning | Re-fetches everything | Use `git remote update` to stay in sync |
| `git fetch` behavior | Fetches new branches | Fetches all refs (full mirror) |
| Typical use | Server repo that receives pushes | Full backup/mirror of a remote |

**Updating a mirror:**

```bash
git clone --mirror https://github.com/user/repo.git repo.git
cd repo.git
git remote update   # Fetch everything again to stay mirrored
```

---

## Local Optimization

### `-l` (or `--local`)

Clone from a local filesystem path. Git will use **hardlinks** instead of copying object files when possible (much faster, saves disk space):

```bash
git clone -l /path/to/local/repo.git my-clone
```

Automatically implied when cloning with a local path without `file://`:

```bash
git clone /path/to/local/repo.git my-clone   # Same as -l
git clone file:///path/to/local/repo.git my-clone   # Full copy (no hardlinks)
```

### `-s` (or `--shared`)

Clone using the source's object store — creates the `.git/objects/info/alternates` file pointing to the source. The clone and source **share objects**:

```bash
git clone -s /path/to/local/repo.git my-clone
```

**Warning:** If the source repo is deleted or pruned, the clone becomes corrupt. Use with caution.

### `--no-hardlinks`

Force a full copy even when cloning locally (override `-l`):

```bash
git clone --no-hardlinks /path/to/local/repo.git my-clone
```

### `--reference <repository>`

Use objects from an existing local repository to speed up the clone. Git adds the reference repo as an alternate object store:

```bash
git clone --reference /existing/repo.git https://github.com/user/repo.git
```

Objects that exist in the reference repo are borrowed (not copied). Only objects missing from the reference are downloaded.

**Multiple reference repos:**

```bash
git clone --reference /repo-a.git --reference /repo-b.git https://github.com/user/repo.git
```

### `--dissociate`

Borrow objects from `--reference` during the clone, then copy them locally afterwards (break the alternate link):

```bash
git clone --reference /existing/repo.git --dissociate https://github.com/user/repo.git
```

The result is a standalone repo (no dependency on the reference). Slower than `--reference` alone but safer.

---

## Submodules

### `--recurse-submodules[=<pathspec>]`

After cloning, also initialize and clone all submodules (or submodules matching the pathspec):

```bash
git clone --recurse-submodules https://github.com/user/repo-with-submodules.git
```

This is equivalent to:
```bash
git clone https://github.com/user/repo-with-submodules.git
cd repo-with-submodules
git submodule update --init --recursive
```

**With pathspec filter:**

```bash
git clone --recurse-submodules=vendor/ https://github.com/user/repo.git
# Only clones submodules under vendor/
```

### `--shallow-submodules`

Clone submodules with `--depth=1` (shallow submodules):

```bash
git clone --recurse-submodules --shallow-submodules https://github.com/user/repo.git
```

### `--no-remote-submodules`

Don't update submodules from their remotes during the clone — use the committed SHA:

```bash
git clone --recurse-submodules --no-remote-submodules https://github.com/user/repo.git
```

### `--jobs <n>`

Clone submodules in parallel. Significantly speeds up repos with many submodules:

```bash
git clone --recurse-submodules --jobs 4 https://github.com/user/repo.git
```

### `--also-filter-submodules`

Apply the `--filter` specification to submodules as well:

```bash
git clone --filter=blob:none --also-filter-submodules https://github.com/user/repo.git
```

---

## Partial Clone

Partial clones download objects on demand instead of fetching everything at clone time. They drastically reduce initial download size for large repos.

### `--filter=blob:none`

Omit all blob objects (file contents) during clone. Blobs are fetched lazily when you check out files:

```bash
git clone --filter=blob:none https://github.com/user/repo.git
```

The clone downloads **commit and tree objects** only — file contents are fetched only when a file is actually needed.

### `--filter=tree:0`

Omit all tree and blob objects. The most aggressive filter — only commits and their metadata are downloaded:

```bash
git clone --filter=tree:0 https://github.com/user/repo.git
```

Every `git checkout`, `git log -p`, or `git diff` that needs tree data will trigger a fetch.

### `--filter=object:type=promisor`

Advanced: use with custom promisor remotes for on-demand object fetching.

### `--filter=sparse:oid=<blob-oid>`

Use a sparse-checkout specification from a blob object in the repository.

**Use cases for partial clone:**

| Scenario | Filter | Result |
|----------|--------|--------|
| Large monorepo, just need to build | `blob:none` | Clone in seconds, fetch files as needed |
| CI/CD pipeline, needs commit graph only | `tree:0` | Minimal data, fetch on demand |
| Exploring history (no checkout needed) | `blob:none` | `git log` works, file access triggers fetch |

**Restoring missing objects later:**

```bash
git fetch --refetch    # Refetch all objects (undoes partial clone)
```

---

## Other Options

### `-q` (or `--quiet`)

Suppress all non-error output:

```bash
git clone -q https://github.com/user/repo.git
```

Useful in scripts where you don't want progress messages.

### `-v` (or `--verbose`)

Show more detail, including progress messages (default):

```bash
git clone -v https://github.com/user/repo.git
```

### `-n` (or `--no-checkout`)

Fetch all objects but **do not check out HEAD**. The repo exists but the working directory is empty:

```bash
git clone -n https://github.com/user/repo.git
cd repo
git status
# On branch main
# No commits yet (working tree is empty)
```

Useful when you want to fetch the full history but only check out specific files later, or when setting up a repo for CI.

### `--sparse`

Initialize the working directory using **sparse-checkout** — only files matching the sparse-checkout patterns appear on disk:

```bash
git clone --sparse https://github.com/user/repo.git
cd repo
git sparse-checkout set src/   # Only files in src/ checked out
```

The initial checkout after `--sparse` only checks out the top-level directory. You then configure which subdirectories to include.

### `--separate-git-dir=<git-dir>`

Store the `.git` directory in a separate location (creates a `.git` file pointing to it):

```bash
git clone --separate-git-dir=/mnt/ssd/git-storage/repo.git https://github.com/user/repo.git my-project
```

Useful for:
- Keeping the `.git` directory on a fast SSD while the working tree is on a larger HDD
- Dotfile management (e.g., clone into `$HOME` with `--separate-git-dir=$HOME/.dotfiles.git`)

### `--config <key>=<value>` (or `-c`)

Set a config value on the cloned repo:

```bash
git clone --config user.name="My Name" --config user.email="me@example.com" https://github.com/user/repo.git
```

This is equivalent to running `git config` after the clone completes.

### `--template=<template-directory>`

Apply a template directory to the new `.git` directory (same as `git init --template`):

```bash
git clone --template=~/my-git-templates https://github.com/user/repo.git
```

### `-u <upload-pack>` (or `--upload-pack=<upload-pack>`)

Pass a path to `git-upload-pack` on the remote. Rarely needed unless the remote has Git installed in a non-standard location:

```bash
git clone -u /usr/local/git/libexec/git-core/git-upload-pack ssh://server/repo.git
```

### `--bundle-uri=<uri>`

Optimize initial clone by downloading a **bundle file** first (a pre-packaged snapshot), then fetching deltas from the remote:

```bash
git clone --bundle-uri=https://example.com/repo.bundle https://github.com/user/repo.git
```

Speeds up clone for large repos by using a CDN-optimized bundle. Supported when the server advertises bundle URIs or you provide one manually.

### `--server-option=<option>`

Send a server option to the remote (protocol v2 only):

```bash
git clone --server-option="feature=blobless" https://github.com/user/repo.git
```

---

## Quick Reference

### Basic clones
```bash
git clone https://github.com/user/repo.git        # Default dir
git clone https://github.com/user/repo.git my-app  # Custom dir
git clone https://github.com/user/repo.git .       # Current dir (must be empty)
```

### Shallow & partial clones
```bash
git clone --depth 1 https://github.com/user/repo.git              # Latest commit only
git clone --depth 5 https://github.com/user/repo.git              # Last 5 commits
git clone --shallow-since="2025-01-01" https://github.com/user/repo.git
git clone --filter=blob:none https://github.com/user/repo.git     # Blobless partial clone
git clone --filter=tree:0 https://github.com/user/repo.git        # Treeless partial clone
```

### Branch control
```bash
git clone -b develop https://github.com/user/repo.git             # Checkout specific branch
git clone --single-branch https://github.com/user/repo.git        # Only default branch
git clone -b main --single-branch https://github.com/user/repo.git
git clone --no-tags https://github.com/user/repo.git              # Skip tags
git clone -o upstream https://github.com/user/repo.git            # Rename origin remote
```

### Bare & mirror
```bash
git clone --bare https://github.com/user/repo.git repo.git        # Bare (server) clone
git clone --mirror https://github.com/user/repo.git repo.git      # Full mirror (all refs)
```

### Submodules
```bash
git clone --recurse-submodules https://github.com/user/repo.git   # Clone with submodules
git clone --recurse-submodules --shallow-submodules https://github.com/user/repo.git
git clone --recurse-submodules --jobs 4 https://github.com/user/repo.git
```

### Local optimization
```bash
git clone -l /local/path/repo.git my-clone                        # Local + hardlinks
git clone -s /local/path/repo.git my-clone                        # Shared object store
git clone --reference /existing/repo.git https://github.com/user/repo.git
git clone --reference /repo.git --dissociate https://github.com/user/repo.git
```

### Other useful options
```bash
git clone -n https://github.com/user/repo.git                     # No checkout
git clone -q https://github.com/user/repo.git                     # Quiet
git clone --sparse https://github.com/user/repo.git                # Sparse checkout
git clone --separate-git-dir=/path/to/git-dir https://github.com/user/repo.git
git clone --config core.autocrlf=false https://github.com/user/repo.git
```

### Combined examples (most common patterns)
```bash
# Quick shallow clone (CI, experimenting)
git clone --depth 1 --single-branch https://github.com/user/repo.git

# Full project with submodules
git clone --recurse-submodules --jobs 4 https://github.com/user/repo.git

# Minimal — partial clone, no checkout
git clone --filter=blob:none -n https://github.com/user/repo.git

# Mirror (full backup)
git clone --mirror https://github.com/user/repo.git repo.git

# Server-ready bare clone
git clone --bare https://github.com/user/repo.git repo.git

# Large monorepo optimization
git clone --filter=blob:none --sparse https://github.com/user/repo.git
cd repo && git sparse-checkout set packages/my-package/
```

---

## Real-World Examples

### 1. Standard clone

```bash
git clone https://github.com/user/repo.git
```

Clones the repo into a directory named `repo`. Most common pattern.

### 2. Shallow clone for CI

```bash
git clone --depth 1 --single-branch https://github.com/user/repo.git
```

Only fetches the latest commit of the default branch. Minimal data transfer. Ideal for CI pipelines that only need to build/test the latest commit.

### 3. Mirror for backup

```bash
git clone --bare --mirror https://github.com/user/repo.git repo.git
```

Creates a full mirror including branches, tags, pull request refs, and notes. Update it periodically with `git remote update`.

### 4. Clone with submodules

```bash
git clone --recurse-submodules https://github.com/user/repo.git
```

Clones the repo and all submodules in one step. For large projects with many submodules, add `--jobs 4` for parallel cloning.

### 5. Partial clone (blobless)

```bash
git clone --filter=blob:none https://github.com/user/repo.git
```

Downloads commits and trees only. File contents arrive on demand when you check out files. Ideal for monorepos where you only need a small subset of files.

### 6. Clone a specific branch

```bash
git clone -b develop --single-branch https://github.com/user/repo.git
```

Only the `develop` branch is cloned. No other remote-tracking branches are created.

### 7. Clone with reference repo

```bash
git clone --reference /local/repo.git https://github.com/user/repo.git
```

Borrows objects from an existing local clone. Only new objects are downloaded. **Warning:** If the reference repo is moved or deleted, the clone may break. Add `--dissociate` to copy the borrowed objects and make the clone standalone.

### 8. Sparse clone of a monorepo

```bash
git clone --sparse --filter=blob:none https://github.com/user/monorepo.git
cd monorepo
git sparse-checkout set packages/my-service/
```

The combination of `--sparse` and `--filter` gives you a minimal footprint: only the directory you need is checked out, and non-blob objects are fetched on demand.

### 9. Dotfiles management

```bash
git clone --separate-git-dir=$HOME/.dotfiles.git --bare https://github.com/user/dotfiles.git $HOME/dotfiles-tmp
mv $HOME/dotfiles-tmp/.git $HOME/.dotfiles.git
rmdir $HOME/dotfiles-tmp
git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME checkout
```

Clones dotfiles into a separate `.git` directory, then checks out the files directly into your home directory.

### 10. Clone via SSH (no password prompts)

```bash
git clone git@github.com:user/repo.git
```

Uses SSH key authentication. No password or token needed once your SSH key is configured.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Permission denied (publickey) | SSH key not configured or wrong key | Generate and add an SSH key: `ssh-keygen && ssh-add` |
| `repository not found` on HTTPS | Token expired or no access | Use `git clone https://user:token@github.com/user/repo.git` or configure credential helper |
| Cloning into a non-empty directory | `git clone <url> .` requires empty target | Use a different directory, or remove existing files first |
| Forgot `--recurse-submodules` | Submodules are empty by default | Run `git submodule update --init --recursive` after clone |
| Shallow clone can't push | Shallow repos lack history for the remote | Use `git fetch --unshallow` to deepen before pushing |
| Mirror clone can't be used for development | `--mirror` creates a bare repo with no working tree | Use a regular clone for development; mirrors are for backup |
| `--reference` repo moved or deleted | The clone references another repo's objects | Use `--dissociate` to break the dependency after clone |
| Large clone is very slow | Downloading full history of a huge repo | Use `--depth 1` or `--filter=blob:none` to reduce data |
| Wrong default branch checked out | Remote `HEAD` points to a different branch | Use `-b <branch>` to specify which branch to checkout |
| `git clone` asks for password repeatedly | Credential caching not configured | `git config --global credential.helper store` (or `cache`) |
| Object format mismatch (SHA-1 vs SHA-256) | Cannot clone between repos with different hash algorithms | Both repos must use the same `--object-format` |

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Default clone directory (unset = use URL basename)
[clone]
    defaultRemoteName = origin

# Use --recurse-submodules by default for all clones
    recurseSubmodules = true

# Parallel submodule fetch jobs
    submoduleFetchJobs = 4

# Set default filter for all clones (partial clone)
    filter = blob:none

# Reject shallow sources by default
    rejectShallow = false
```

Environment variables also affect `git clone`:

| Variable | Effect |
|----------|--------|
| `GIT_TERMINAL_PROMPT` | `0` = never prompt for credentials |
| `GIT_SSH` | Path to SSH binary (default: `ssh`) |
| `GIT_SSH_VARIANT` | `ssh`, `plink`, `tortoiseplink`, `simple` |
| `GIT_SSL_NO_VERIFY` | `1` = skip SSL certificate verification |
| `GIT_CONFIG_PARAMETERS` | Pass additional config to the clone |
| `GIT_PROTOCOL_FROM_USER` | `1` = user-initiated (all protocols), `0` = restricted |
| `GIT_DEFAULT_HASH` | Override hash algorithm for the cloned repo |
| `GIT_TRACE` / `GIT_TRACE_PACKET` | Debug Git protocol communication |

---

## Visual Summary

```
Remote repository (GitHub, GitLab, self-hosted)
│
│  git clone https://github.com/user/repo.git
│
▼
Local: my-repo/
├── .git/                          ◄── Full Git database
│   ├── objects/                   ◄── Commits, trees, blobs
│   ├── refs/
│   │   ├── heads/
│   │   │   └── main              ◄── Local branch
│   │   └── remotes/
│   │       └── origin/
│   │           ├── main          ◄── Remote-tracking branch
│   │           ├── develop
│   │           └── feature-x
│   ├── config                    ◄── remote.origin.url = ...
│   ├── HEAD                      ◄── ref: refs/heads/main
│   └── packed-refs
│
├── src/                          ◄── Working tree (checked out files)
├── README.md
└── ...
```

`git clone` is your gateway to collaborative development — it's almost always the first command you run when joining an existing project. Everything else — branching, committing, pushing — comes after.
