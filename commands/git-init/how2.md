# `git init` — Create an empty Git repository

The `git init` command creates a new Git repository. It sets up the `.git` directory with all the internal data structures Git needs to start tracking changes. This is the **first command you run** when starting a new project.

```
git init [-q | --quiet] [--bare] [--template=<template-directory>]
         [--separate-git-dir <git-dir>] [--object-format=<format>]
         [--ref-format=<format>]
         [-b <branch-name> | --initial-branch=<branch-name>]
         [--shared[=<permissions>]] [<directory>]
```

## What `git init` Creates

Running `git init` generates a `.git` directory with this structure:

```
.git/
├── HEAD            # Points to the current branch (e.g., ref: refs/heads/main)
├── config          # Repository-specific Git configuration
├── description     # Used by GitWeb, ignored otherwise
├── hooks/          # Sample hook scripts (pre-commit, post-commit, etc.)
├── info/           # Additional repo metadata
│   └── exclude     # Local-only .gitignore patterns (not committed)
├── objects/        # All your data (commits, trees, blobs)
│   ├── info/
│   └── pack/
└── refs/           # Pointers to commits (branches, tags)
    ├── heads/      # Local branch pointers
    └── tags/       # Tag pointers
```

No files are tracked yet — you need `git add` and `git commit` to create the first commit.

**Safety:** Running `git init` in an existing repository is safe. It will not overwrite anything. The main reason to re-run it is to pick up newly added templates or move the repo with `--separate-git-dir`.

---

## Beginner Usage

### `git init` — Initialize in current directory

```bash
cd /path/to/my/project
git init
```

Output:
```
Initialized empty Git repository in /path/to/my/project/.git/
```

From here, the workflow is:
```bash
git add .             # Stage all files
git commit -m "Initial commit"   # Create first commit
```

### `git init <directory>` — Create directory and initialize

Creates the directory if it doesn't exist, then initializes a repo inside it:

```bash
git init my-new-project
```

This is equivalent to:
```bash
mkdir my-new-project && cd my-new-project && git init
```

You can use a full path too:

```bash
git init /home/user/projects/my-app
```

---

## Intermediate Options

### `-b <name>` (or `--initial-branch=<name>`)

Set the initial branch name. Overrides the default (`master` or `main`):

```bash
git init -b main
git init -b develop
git init -b trunk
```

**Set a global default** so every future `git init` uses your preferred name:

```bash
git config --global init.defaultBranch main
```

### `-q` (or `--quiet`)

Suppress all non-error output:

```bash
git init -q my-project
```

Useful in scripts where you don't want status messages.

### `--template=<template-directory>`

Copy files from a template directory into the new `.git` folder. Used to pre-populate hooks, config, or custom files:

```bash
git init --template=~/my-git-templates my-project
```

**How Git finds the template (in order of precedence):**

1. `--template=<dir>` command-line argument
2. `$GIT_TEMPLATE_DIR` environment variable
3. `init.templateDir` config variable
4. Default system template (`/usr/share/git-core/templates`)

**Example — custom hook template:**

```bash
# Create a template with a custom pre-commit hook
mkdir -p ~/my-git-templates/hooks
cat > ~/my-git-templates/hooks/pre-commit << 'EOF'
#!/bin/sh
echo "Running pre-commit checks..."
EOF
chmod +x ~/my-git-templates/hooks/pre-commit

# Every new repo will now have this hook
git init --template=~/my-git-templates my-project
```

**Set a global template:**

```bash
git config --global init.templateDir ~/my-git-templates
```

### `--no-template`

Skip the template directory entirely, even if a global template is configured:

```bash
git init --no-template my-clean-repo
```

### `--separate-git-dir=<git-dir>`

Store the `.git` directory in a separate location. Creates a text file at the standard path that points to the real Git directory:

```bash
git init --separate-git-dir=/mnt/ssd/repos/my-project.git my-project
```

**Use case — dotfiles in your home directory:**

```bash
git init --separate-git-dir=$HOME/.dotfiles.git $HOME
```

This keeps a single Git repo tracking `~/.bashrc`, `~/.vimrc`, etc., while the `.git` directory lives elsewhere.

**On reinitialization**, the repository is moved to the new path.

---

## Advanced Options

### `--bare`

Create a **bare repository** — no working directory, only Git data (the contents of `.git` directly in the folder). Used for **remote/central repositories** that receive pushes:

```bash
git init --bare my-project.git
```

By convention, bare repositories end in `.git`.

**Why bare?** Normal repos have a working directory. If you push to a non-bare repo, Git doesn't know where to put the files. Bare repos have no working directory — they exist only to store history and accept pushes.

**Real-world usage — setting up a central repo on a server:**

```bash
ssh user@server
mkdir -p /srv/git/my-app.git
cd /srv/git/my-app.git
git init --bare
```

Then from your local machine:
```bash
git remote add origin user@server:/srv/git/my-app.git
git push -u origin main
```

### `--shared[=<permissions>]`

Configure repository permissions for multi-user access. Git adjusts file permissions so that users in the same group can push safely:

```bash
git init --bare --shared=group /srv/git/team-project.git
```

**Permission values:**

| Value | Effect |
|-------|--------|
| `umask` or `false` | Use umask permissions (default) |
| `group` or `true` | Group-writable, setgid bit on directories |
| `all` or `world` or `everybody` | Group-writable + world-readable |
| `0xxx` (octal) | Exact permission mode (e.g., `0640`, `0660`) |

The `0xxx` form overrides umask entirely:

```bash
git init --bare --shared=0660 /srv/git/restricted.git
```

This creates files with `0660` and directories with `0770` — readable/writable by user and group, inaccessible to others.

**Note:** Shared repos have `receive.denyNonFastForwards` enabled by default (no force-push allowed).

### `--object-format=<format>`

Set the hash algorithm. Valid values:

- `sha1` — 40-character hex hashes (default, universally compatible)
- `sha256` — 64-character hex hashes (stronger, Git 3.0 default in future)

```bash
git init --object-format=sha256 my-project
```

**Important:** There is no interoperability between SHA-256 and SHA-1 repos. All collaborators must use the same format.

### `--ref-format=<format>`

Set the reference storage format:

| Format | Description |
|--------|-------------|
| `files` | Loose files with packed-refs (default, universally compatible) |
| `reftable` | Binary format (faster for large repos, experimental in Git 2.x) |

```bash
git init --ref-format=reftable my-project
```

### `--no-template`

Skip template files entirely, even if `init.templateDir` is configured globally:

```bash
git init --no-template my-project
```

---

## Quick Reference

### Basic initialization
```bash
git init                           # Init in current directory
git init my-project                # Create dir and init
git init -b main my-project        # Init with branch name
git init -q my-project             # Quiet mode (no output)
```

### Bare repos (for servers)
```bash
git init --bare my-project.git     # Bare repo (no working tree)
git init --bare --shared=group     # Shared bare repo for team
git init --bare --shared=0660      # Bare repo with exact permissions
```

### Templates
```bash
git init --template=~/templates    # Init with custom template
git init --no-template             # Init without any template
git config --global init.templateDir ~/templates   # Set global template
```

### Advanced
```bash
git init --separate-git-dir=/path/to/git-dir    # Separate .git location
git init --object-format=sha256   # Use SHA-256 hashing
git init --ref-format=reftable    # Use reftable storage (experimental)
```

### Combined examples
```bash
# Personal project (most common)
git init -b main my-project

# Company project with shared hooks
git init -b main --template=~/.company-template my-project

# Team server repository
git init --bare --shared=group project.git

# Modern project with SHA-256
git init --object-format=sha256 -b main my-project

# Script-friendly
git init -q -b main "$PROJECT_DIR"

# Dotfiles
git init --separate-git-dir=$HOME/.dotfiles.git $HOME
```

---

## Reinitializing an Existing Repository

Running `git init` on an already-initialized repo is **safe** — nothing is overwritten. It's useful for:

- Picking up newly added templates
- Moving the repo with `--separate-git-dir`
- Re-creating hooks that were deleted

```bash
# Re-init to pick up new templates
git init --template=~/new-templates .
```

**Caveat:** Don't mix bare and non-bare. If you run `git init --bare` on a non-bare repo, you'll get confusing results.

---

## Complete Workflow: Starting Fresh

```bash
# 1. Create the repo
git init -b main my-app
cd my-app

# 2. Set up identity (if not already set globally)
git config user.name "Your Name"
git config user.email "you@example.com"

# 3. Create initial files
echo "# My App" > README.md
echo "node_modules/" > .gitignore

# 4. Stage and commit
git add .
git commit -m "Initial commit"

# 5. Connect to remote and push
git remote add origin https://github.com/you/my-app.git
git push -u origin main
```

---

## Common Pitfalls

| Mistake | Why | Solution |
|---------|-----|----------|
| `git init` inside an already-initialized subdirectory | Creates a nested Git repo — outer repo ignores it | Use `git submodule` instead |
| Forgetting `--bare` on a server repo | Can't push to a non-bare repo with a working tree | Re-init with `git init --bare` or convert |
| Running `git init --bare` on a non-bare repo | Confusing state — mix of bare and non-bare settings | Use the same type as the original init |
| Not setting `init.defaultBranch` globally | Inconsistent branch names across projects | `git config --global init.defaultBranch main` |
| Expecting `git init` to start tracking files | `git init` only creates the `.git` directory — it doesn't track anything yet | Run `git add` and `git commit` |

---

## Configuration

Set in `.gitconfig` or repo `.git/config`:

```ini
# Default branch name for new repos
[init]
    defaultBranch = main

# Default template directory
    templateDir = ~/my-git-templates

# Default object format (sha1 or sha256)
    defaultObjectFormat = sha1

# Default ref storage format
    defaultRefFormat = files
```

Environment variables also affect `git init`:

| Variable | Effect |
|----------|--------|
| `GIT_DIR` | Path to use instead of `./.git` |
| `GIT_OBJECT_DIRECTORY` | Path for object storage |
| `GIT_TEMPLATE_DIR` | Path to template directory |
| `GIT_DEFAULT_HASH` | Override default hash algorithm |
| `GIT_DEFAULT_REF_FORMAT` | Override default ref storage format |

---

## Visual Summary

```
git init my-project
         │
         ▼
  my-project/
    ├── (your files go here)
    └── .git/                         ◄── Created by git init
         ├── HEAD          → ref: refs/heads/main
         ├── config         → Local config settings
         ├── description
         ├── hooks/         → Sample hook scripts
         ├── info/
         │   └── exclude   → Local gitignore
         ├── objects/      → Empty (no commits yet)
         │   ├── info/
         │   └── pack/
         └── refs/
             ├── heads/    → Will store branch pointers
             └── tags/     → Will store tag pointers

  Then:  git add .  →  git commit -m "Initial commit"
```

`git init` is the birth of your repository. Everything else comes after.
