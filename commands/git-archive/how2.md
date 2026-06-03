# `git archive` — Create an archive of files from a named tree

The `git archive` command creates a compressed archive (tar, zip, tar.gz, etc.) of your repository's files at any commit, branch, or tag — **without the `.git` directory or history**. It's Git's built-in export tool for deployments, releases, and sharing clean code snapshots.

```
git archive [--format=<fmt>] [--list] [--prefix=<prefix>/] [<extra>]
            [-o <file> | --output=<file>] [--worktree-attributes]
            [--remote=<repo> [--exec=<git-upload-archive>]] <tree-ish>
            [<path>...]
```

## How It Works

`git archive` reads the Git object database directly — it doesn't touch your working tree. This means:

- Archives are created from **committed** history only (uncommitted changes are not included)
- No `.git` directory in the output
- Fast — it reads objects, doesn't checkout files
- Works with **local** and **remote** repositories

**When a commit or tag** is given, file timestamps use the committer time. When a **tree ID** is given, the current time is used.

---

## Basic Usage

### Archive HEAD (current commit) to stdout

```bash
git archive --format=tar HEAD > project.tar
git archive --format=zip HEAD > project.zip
```

### Archive to a file with `-o`

```bash
git archive -o project.tar HEAD
git archive -o project.zip HEAD
git archive -o project.tar.gz HEAD
```

The format is inferred from the file extension if `--format` is not given:
- `.tar` → tar
- `.zip` → zip
- `.tar.gz` or `.tgz` → tar.gz

### Archive a specific branch

```bash
git archive -o feature.zip feature-branch
```

### Archive a specific tag (release)

```bash
git archive -o myapp-v1.0.0.tar.gz v1.0.0
```

### Archive a specific commit by hash

```bash
git archive -o snapshot.zip a1b2c3d
```

---

## Key Options

### `--format=<fmt>`

Specify the output format. Available formats:

```bash
git archive --list   # Show all available formats
```

Common formats: `tar`, `zip`, `tar.gz`, `tgz`. Custom formats can be defined via config (see below).

```bash
git archive --format=zip -o release.zip HEAD
git archive --format=tar.gz -o release.tar.gz HEAD
```

### `--prefix=<prefix>/`

Prepend a directory to every path in the archive. This is essential for releases so files extract into a named folder:

```bash
git archive --prefix=myapp-v1.0.0/ -o myapp-v1.0.0.tar.gz v1.0.0
```

Extraction creates:
```
myapp-v1.0.0/
├── src/
├── README.md
└── ...
```

Without `--prefix`, files extract into the current directory, which can cause file clutter.

You can repeat `--prefix` — the rightmost value before a `--add-file` applies to that file.

### `-o <file>` / `--output=<file>`

Write directly to a file instead of stdout:

```bash
git archive -o release.zip HEAD
```

### `--add-file=<file>`

Include an **untracked file** in the archive. Useful for build artifacts or config files that aren't committed:

```bash
git archive --prefix=build/ --add-file=configure --prefix= -o latest.tar HEAD
```

The path in the archive is `prefix + basename`. Multiple `--add-file` flags can be used.

### `--add-virtual-file=<path>:<content>`

Add a file with arbitrary content directly, without creating it on disk:

```bash
git archive --add-virtual-file="version.txt:v1.0.0" -o archive.tar HEAD
```

If `<path>` contains a colon, quote the path:
```bash
git archive --add-virtual-file='"path:with:colons.txt":content' -o archive.tar HEAD
```

### `--mtime=<time>`

Override modification time of all archive entries:

```bash
git archive --mtime="2026-01-15 12:00:00" -o release.tar HEAD
```

### `--remote=<repo>`

Create an archive from a **remote repository** without cloning it locally. The remote must have `git-upload-archive` enabled:

```bash
git archive --remote=ssh://user@server/path/to/repo.git HEAD > project.tar
```

**Note:** GitHub does not support `--remote`. Use the GitHub API instead:
```bash
curl -L https://api.github.com/repos/user/repo/tarball/main | tar xz
```

### `--exec=<git-upload-archive>`

Used with `--remote` to specify a custom path to `git-upload-archive` on the remote server.

### `--worktree-attributes`

Look for `.gitattributes` in the working tree instead of only in the archived tree. Useful when you want to apply export rules that haven't been committed yet.

### `-v` / `--verbose`

Report progress to stderr:

```bash
git archive -v -o release.tar HEAD
```

---

## Backend-Specific Options

### zip compression level

```bash
git archive --format=zip -0 -o store-only.zip HEAD    # No compression (fastest)
git archive --format=zip -6 -o default.zip HEAD        # Default level
git archive --format=zip -9 -o best.zip HEAD           # Best compression (slowest)
```

### tar compression level

Passed to the compression command (e.g., gzip):

```bash
git archive --format=tar.gz -1 -o fast.tar.gz HEAD     # Fastest compression
git archive --format=tar.gz -9 -o best.tar.gz HEAD     # Best compression
```

---

## Path Filtering

Archive only specific files or directories:

```bash
# Archive only the src/ directory
git archive -o src-only.tar HEAD src/

# Archive multiple paths
git archive -o partial.tar HEAD src/ docs/ README.md

# Using pathspec exclusions
git archive -o no-tests.tar HEAD -- . ':!tests/' ':!*.test.js'
```

---

## `.gitattributes` — Export Control

Control what gets included in archives without changing your command:

```
# .gitattributes
tests/           export-ignore
.github/         export-ignore
.editorconfig    export-ignore
.gitignore       export-ignore
*.test.js        export-ignore
```

Now `git archive` automatically skips these files:

```bash
git archive -o release.tar HEAD
# No tests/, .github/, .editorconfig, .gitignore, or *.test.js files
```

### `export-subst` — Variable expansion

Files with the `export-subst` attribute get Git placeholders expanded:

```
# .gitattributes
version.txt      export-subst
```

Content in `version.txt`:
```
$Format:%H$ - $Format:%d$ - $Format:%ct$
```

When archived, this expands to:
```
a1b2c3d4... - (tag: v1.0.0) - 1700000000
```

---

## Real-World Scenarios

### Release packaging

```bash
#!/bin/bash
# release.sh - Create release archives
VERSION=$(git describe --tags --abbrev=0)
git archive --prefix="myapp-$VERSION/" -o "myapp-$VERSION.tar.gz" "$VERSION"
git archive --prefix="myapp-$VERSION/" -o "myapp-$VERSION.zip" "$VERSION"
echo "Released $VERSION"
```

### Deploy to production over SSH

```bash
# Stream directly to a server and extract
git archive --format=tar HEAD | ssh user@prod-server 'cd /var/www/app && tar -xf -'
```

### Docker build context

```bash
# Create archive and pipe directly to Docker
git archive --format=tar HEAD | docker build -t myapp:latest -
```

### Extract to a specific directory

```bash
# Archive and extract in one pipeline
git archive --format=tar HEAD | tar -xC /tmp/staging
```

### Create a dated backup

```bash
DATE=$(date +%Y%m%d)
git archive --prefix="backup-$DATE/" -o "backup-$DATE.tar.gz" HEAD
```

### Include a generated file (e.g., build info)

```bash
git archive \
  --add-virtual-file="build-info.txt:$(git describe --tags) built on $(date)" \
  -o release.tar HEAD
```

### Custom format with xz compression

```bash
git config tar.tar.xz.command "xz -c"
git archive --format=tar.xz -o release.tar.xz HEAD
```

---

## Quick Reference

```bash
# Basic archives
git archive -o archive.tar HEAD                  # Tar archive
git archive -o archive.zip HEAD                  # Zip archive
git archive -o archive.tar.gz HEAD               # Gzipped tar (inferred)

# Specific refs
git archive -o main.zip main                     # Branch
git archive -o v1.0.tar.gz v1.0                  # Tag
git archive -o snapshot.zip a1b2c3d              # Commit hash
git archive -o tree.tar HEAD^{tree}              # Tree (no commit metadata)

# With prefix (releases)
git archive --prefix=project-v1.0/ -o project-v1.0.tar.gz v1.0

# Partial archives
git archive -o src.zip HEAD src/                 # Single directory
git archive -o partial.tar HEAD src/ docs/       # Multiple paths
git archive -o no-tests.tar HEAD -- . ':!tests/'  # Exclude paths

# Include untracked files
git archive --add-file=config.prod -o deploy.tar HEAD

# Remote archive
git archive --remote=ssh://server/repo.git HEAD > repo.tar

# Pipeline patterns
git archive --format=tar HEAD | tar -xC /tmp/extract   # Extract to dir
git archive --format=tar HEAD | ssh user@host 'tar -xC /deploy'  # Deploy
git archive --format=tar HEAD | docker build -t app .   # Docker context
```

---

## Common Pitfalls

| Mistake | Why | Solution |
|---------|-----|----------|
| Uncommitted changes missing | `git archive` reads committed objects, not the working tree | Commit first, or use `git add` + `git stash` tricks |
| No prefix → files extract into current dir | Without `--prefix`, archive root is the repo root | Always use `--prefix=name/` for releases |
| `--remote` fails on GitHub | GitHub disables `git-upload-archive` | Use `curl -L https://api.github.com/repos/user/repo/tarball` |
| Archive includes `.gitignore`, `.editorconfig` | These are tracked files | Use `.gitattributes export-ignore` to exclude them |
| Submodule content missing | `git archive` does not include submodules | Use `git-archive-all` script or archive submodules separately |
| Wrong timestamps in archive | Tree objects use current time, commits use committer time | Use `--mtime` to override |

---

## Configuration

```ini
# Set default umask for tar archive permissions (default 0002)
[tar]
    umask = 0002

# Custom "user" umask means use the archiving user's umask
    umask = user

# Define a custom format
[tar "tar.xz"]
    command = xz -c

# Enable custom format for remote clients
[tar "tar.xz"]
    remote = true
```

---

## Visual Summary

```
Repository (committed history)
│
├── HEAD  ──┐
├── v1.0   ─┤
├── main   ─┤
└── abc123 ─┘
             │
    git archive --prefix=app/ -o app.zip HEAD
             │
             ▼
       app.zip
       └── app/
           ├── src/
           ├── README.md
           └── ...
           (no .git/)
```

`git archive` is the cleanest way to distribute code — just files, no history, no metadata. Essential for releases, deployments, and client deliveries.
