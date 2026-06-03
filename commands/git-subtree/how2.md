# `git subtree` — Merge external projects as subdirectories

`git subtree` lets you include another Git repository as a subdirectory of your own repository, merge back changes, and extract history. It is an alternative to `git submodule` — no metadata files, no special clone steps, and nested trees are just regular directories tracked in the parent repo.

```
git subtree [<options>] -P <prefix> add <repository> <ref>
git subtree [<options>] -P <prefix> merge <commit>
git subtree [<options>] -P <prefix> pull <repository> <ref>
git subtree [<options>] -P <prefix> push <repository> <ref>
git subtree [<options>] -P <prefix> split [--onto <commit>]
             [--annotate=<annotation>] [--rejoin] [--ignore-joins]
             [--branch=<branch>]
```

---

## Description

`git subtree` grafts a subproject into your repo as a regular directory. Unlike `git submodule`, the contents are fully committed into the parent repo — there is no separate `.gitmodules` file, no `git submodule init` step, and the subproject history is embedded (optionally squashed). Anyone cloning the parent repo gets the subdirectory contents immediately.

```
Main Repository (parent)
       │
       ├── src/
       ├── libs/lib/          ← subtree from github.com/user/lib.git
       ├── plugins/theme/     ← subtree from github.com/user/theme.git
       └── README.md

All subdirectory files live in the parent repo's object store.
No `git submodule update --init` needed.
```

### How subtree works

1. **Add** — Pulls a remote project into a prefix directory, optionally squashing the history
2. **Pull** — Fetches the latest remote changes and merges them into the subtree
3. **Merge** — Merges a subtree commit into the prefix (useful after a manual fetch)
4. **Push** — Splits out the subtree history and pushes it to the remote
5. **Split** — Extracts the subtree's history into a separate branch (for pushing upstream)

---

## Add

### `git subtree add -P <prefix> <repository> <ref>`

Pull an external repository into a subdirectory of your project:

```bash
git subtree add --prefix=libs/lib https://github.com/user/lib.git main
```

This fetches the remote's `main` branch and merges it into the `libs/lib` directory. The subtree history is embedded in your repo.

### `--squash`

Collapse the subtree's commit history into a single commit:

```bash
git subtree add --prefix=vendor/lib https://github.com/user/lib.git main --squash
```

The squash commit message looks like:

```
Add 'vendor/lib/' from commit 'abc123def456...'

git-subtree-dir: vendor/lib
git-subtree-split: abc123def456...
```

Use `--squash` when you don't need the subproject's full history in your repo.

---

## Pull

### `git subtree pull -P <prefix> <repository> <ref>

Fetch and merge the latest changes from the external project into the subtree prefix:

```bash
git subtree pull --prefix=libs/lib https://github.com/user/lib.git main
```

This is equivalent to `git fetch <url>` followed by `git subtree merge`. If the subtree was added with `--squash`, you should also pull with `--squash`:

```bash
git subtree pull --prefix=vendor/lib https://github.com/user/lib.git main --squash
```

---

## Merge

### `git subtree merge -P <prefix> <commit>

Merge a specific commit into the subtree prefix (after fetching manually):

```bash
git fetch https://github.com/user/lib.git main
git subtree merge --prefix=libs/lib FETCH_HEAD
```

This is the lower-level operation that `subtree pull` performs automatically.

---

## Push

### `git subtree push -P <prefix> <repository> <ref>

Split the subtree from your repo and push it to its own remote:

```bash
git subtree push --prefix=src/lib https://github.com/user/lib.git main
```

This runs `git subtree split` internally and pushes the result to the remote. Equivalent to:

```bash
git subtree split --prefix=src/lib --branch=split-lib
git push https://github.com/user/lib.git split-lib:main
```

---

## Split

### `git subtree split -P <prefix> [options]

Extract the subtree's history into a separate branch, mapping the subdirectory to the root:

```bash
git subtree split --prefix=libs/lib --branch=lib-main
```

This creates a new branch `lib-main` containing only the commits that touched `libs/lib/`, rewritten as if they were at the root. Useful for:

- Pushing changes back to the upstream project
- Extracting a module into its own repository

### `--onto <commit>`

Base the splits on a specific commit instead of the initial subtree commit:

```bash
git subtree split --prefix=libs/lib --onto=refs/tags/v1.0 --branch=lib-main
```

### `--annotate=<annotation>`

Prefix commit messages in the split branch with an annotation:

```bash
git subtree split --prefix=libs/lib --annotate="lib: " --branch=lib-main
```

Each split commit gets the annotation prepended: `"lib: fix edge case in parser"`.

### `--rejoin`

After splitting, merge the split branch back into your main branch to record the split point:

```bash
git subtree split --prefix=libs/lib --branch=lib-main --rejoin
```

This creates a merge commit that tells future `split` operations where the last split occurred, making subsequent splits faster (avoids re-processing commits the tree already has).

### `--ignore-joins`

Ignore previous split rejoin markers and re-split from scratch:

```bash
git subtree split --prefix=libs/lib --ignore-joins --branch=lib-main
```

Useful when the rejoin markers are corrupted or you want a fresh split.

---

## Options

| Option | Short | Description |
|--------|-------|-------------|
| `--prefix=<prefix>` | `-P <prefix>` | The subdirectory for the subtree (required for all commands) |
| `--message=<msg>` | `-m <msg>` | Custom commit message for the subtree operation |
| `--squash` | | Collapse subtree history into a single commit (add/pull only) |
| `--annotate=<annotation>` | | Prepend text to each split commit message |
| `--onto=<commit>` | | Start split from a specific commit |
| `--rejoin` | | Merge split branch back after split (marks split point) |
| `--ignore-joins` | | Skip rejoin markers and split from scratch |

### `-m <msg>` / `--message`

Provide a custom commit message for the subtree operation:

```bash
git subtree add --prefix=vendor/lib -m "feat: add lib v2.1.0" https://github.com/user/lib.git main
```

### `-P <prefix>` / `--prefix`

The only positional option — specifies which directory the subtree lives in. All `git subtree` commands require it.

---

## Comparison: `git subtree` vs `git submodule`

| Aspect | `git subtree` | `git submodule` |
|--------|---------------|-----------------|
| **Storage** | Full contents in parent repo | Pointer (commit SHA) stored in parent |
| **Clone** | Works immediately — no extra steps | Requires `git submodule init && git submodule update` |
| **Version pinning** | Pinned at the added/merged commit | Pinned by commit SHA in `.gitmodules` |
| **History** | Embedded in parent (optionally squashed) | Separate — stored in submodule repo |
| **Editing** | Edit in-place, commit to parent, push with split | Edit inside submodule dir, commit to submodule repo |
| **Conflicts** | Regular merge conflicts in parent | Conflicts possible in `.gitmodules` or submodule pointer |
| **Partial clone** | Not possible — subtree is always fetched | Submodules are fetched on demand |
| **Cross-repo collaboration** | Complicated (needs split + push to upstream) | Natural — each submodule is its own repo |
| **Repo size** | Larger (subtree content duplicated) | Smaller (only pointers) |
| **Commit count** | Inflated by subtree history (unless squashed) | Unaffected |

**When to use `git subtree`:**
- You want a self-contained clone with no init steps
- You don't want to teach collaborators about submodules
- The subproject changes infrequently and can be squashed
- You need to modify the subproject and push changes back

**When to use `git submodule`:**
- The subproject is large and most contributors don't need it
- You want precise SHA pinning with easy version bumps
- You collaborate with the upstream project regularly
- You want to avoid inflating your repo size

---

## Quick Reference

```bash
# Add a subtree
git subtree add -P libs/lib <url> main                      # Add with full history
git subtree add -P libs/lib <url> main --squash             # Add with squashed history
git subtree add -P libs/lib <url> main --squash -m "msg"    # Add with custom message

# Pull upstream changes
git subtree pull -P libs/lib <url> main                     # Pull latest
git subtree pull -P libs/lib <url> main --squash            # Pull (squashed)

# Merge a fetched commit
git fetch <url> main
git subtree merge -P libs/lib FETCH_HEAD                    # Merge fetched commit

# Push changes back upstream
git subtree push -P libs/lib <url> main                     # Split + push

# Split into a separate branch
git subtree split -P libs/lib --branch=lib-main             # Extract into branch
git subtree split -P libs/lib --branch=lib-main --rejoin    # Split and mark
git subtree split -P libs/lib --branch=lib-main --annotate="lib: "  # Annotated
git subtree split -P libs/lib --ignore-joins --branch=lib-main     # Fresh split

# Multiple subtrees in one repo
git subtree add -P vendor/lib-a <url-a> main
git subtree add -P vendor/lib-b <url-b> main
git subtree add -P plugins/theme <url-c> main
```

---

## Real-World Examples

### Add a vendor library with squashed history

```bash
git subtree add --prefix=vendor/lib https://github.com/user/lib.git main --squash
```

Result: `vendor/lib/` contains the library's files. A single squash commit records the addition. The parent repo stays small.

### Pull upstream changes into a vendor library

```bash
git subtree pull --prefix=vendor/lib https://github.com/user/lib.git main
```

Fetches the latest `main` from the remote and merges it into `vendor/lib/`. If you added with `--squash`, include `--squash` on pull too.

### Push local changes back to the upstream project

```bash
git subtree push --prefix=vendor/lib https://github.com/user/lib.git main
```

Splits out the `vendor/lib` history and pushes it to the remote's `main` branch. After this, the upstream repo contains your changes.

### Extract a utility module into its own branch

```bash
git subtree split --prefix=src/utils --branch=utils-only
```

Creates branch `utils-only` with only the commits that touched `src/utils/`, rewritten as a standalone repository root. You can then push this branch as a new repo:

```bash
git push https://github.com/user/utils.git utils-only:main
```

### Add a private plugin from GitHub with SSH

```bash
git subtree add --prefix=plugins/theme git@github.com:user/theme.git main
```

Works exactly the same as the HTTPS variant — just uses an SSH remote URL.

### Maintain multiple subtrees in a monorepo

```bash
git subtree add --prefix=packages/core git@github.com:org/core.git main --squash
git subtree add --prefix=packages/cli  git@github.com:org/cli.git  main --squash
git subtree add --prefix=packages/web  git@github.com:org/web.git  main --squash

# Later: update all subtrees
git subtree pull --prefix=packages/core git@github.com:org/core.git main
git subtree pull --prefix=packages/cli  git@github.com:org/cli.git  main
git subtree pull --prefix=packages/web  git@github.com:org/web.git  main
```

### Split, rejoin, and push in one workflow

```bash
# Extract changes and rejoin to mark the split
git subtree split --prefix=libs/mylib --branch=lib-changes --rejoin

# Push extracted branch to the upstream remote
git push https://github.com/user/mylib.git lib-changes:main

# The rejoin merge commit makes future splits faster
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git subtree add` fails with "prefix already exists" | The target directory already exists | Remove or rename the existing directory before adding |
| `git subtree pull` shows conflicts on every file | The subtree was added with `--squash` but pull doesn't use `--squash` | Use `git subtree pull --squash` to match the add mode |
| `git subtree push` pushes unrelated commits | The split picked up commits that touched the prefix before it was a subtree | Use `--onto` to start the split at the subtree add commit |
| Split takes an extremely long time | Large repository with many commits touching the prefix | Use `--rejoin` after split to mark split points and speed up future runs |
| "Could not find a common ancestor" on pull | The remote's history doesn't share a common base with your subtree | Use `git subtree pull --squash` or fetch + `git subtree merge --allow-unrelated-histories` |
| `git subtree push` says nothing to push | Your local subtree changes match what's already upstream, or the split produced an empty branch | Check `git subtree split --prefix=<dir>` output; verify you have uncommitted changes in the prefix |
| Merge conflicts inside the subtree directory | Both the parent repo and subtree remote modified the same files in the prefix | Resolve conflicts normally with `git mergetool` or manual editing — subtree files are regular files |
| Workspace is dirty when running subtree commands | `git subtree` may refuse to operate with uncommitted changes | Commit or stash your changes first, or use `--autostash` (not supported directly by subtree — do `git stash` manually) |
| The prefix appears twice in history after split/rejoin | The rejoin merge creates a commit that touches the prefix | This is expected and harmless — `--rejoin` intentionally creates a merge commit to mark the split point |
