# `git lfs` — Git Large File Storage

Git LFS replaces large files (binaries, archives, datasets, etc.) with **text pointers** in the repository while storing the actual file contents on a remote server. This keeps your repo lean and clones fast.

```
git lfs <command> [<args>]
```

---

## Description

Instead of storing large binary files directly in Git objects (blobs), Git LFS records a tiny **pointer file** (less than 200 bytes) in the repository. The real content is stored on an LFS server (e.g., GitHub, GitLab, self-hosted). When you check out a commit, LFS downloads the actual files transparently.

```
Working tree:   design.psd (200 MB)    ← real file on disk
Git index:      design.psd (130 B)     ← pointer file in .gitattributes
LFS server:     design.psd (200 MB)    ← stored remotely
```

Benefits:
- **Smaller clones** — pointer files instead of multi-GB blobs
- **Faster fetch/push** — only the LFS files you need are transferred
- **Transparent** — `git checkout`, `git diff`, etc. work normally once configured

---

## Install

Set up Git LFS filters in your Git configuration. Run once per user/machine (or once per repo if you omit `--system`/`--global`):

```bash
git lfs install
```

This adds filter config to your Git config:

```ini
[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true
```

Verify with:

```bash
git lfs env
```

---

## Track

Tell Git LFS which file patterns to manage. Patterns are stored in `.gitattributes`:

```bash
git lfs track "*.psd"
git lfs track "*.zip"
git lfs track "*.tar.gz"
git lfs track "*.mp4"
```

Each command appends a line to `.gitattributes`:

```
*.psd filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
```

View all tracked patterns:

```bash
git lfs track
```

**Important:** Always commit the `.gitattributes` file so everyone on the team uses the same LFS patterns.

```bash
git add .gitattributes
git commit -m "Add LFS tracking for binary files"
```

---

## Untrack

Stop tracking a pattern. This removes the pattern from `.gitattributes` but does **not** clean previously tracked files:

```bash
git lfs untrack "*.psd"
git lfs untrack "*.zip"
```

After untracking, commit the updated `.gitattributes`:

```bash
git add .gitattributes
git commit -m "Stop tracking PSD files with LFS"
```

---

## Status

Show the status of LFS files in the working tree — which files are modified, which are staged, and which LFS objects are missing:

```bash
git lfs status
```

Output:

```
On branch main
Objects to be pushed to origin/main:

    design.psd (LFS: 200 MB)
    archive.zip (LFS: 512 MB)

Objects to be fetched from origin/main:

    logo.svg -> (not available)
```

---

## List

List LFS files tracked in the current commit:

```bash
git lfs ls-files
```

Output:

```
3b21a7f1a8 * design.psd
9c8d2e3f1b * archive.zip
```

List LFS files across all commits (scans the full history):

```bash
git lfs ls-files --all
```

Options:

| Option | Description |
|--------|-------------|
| `--all` | Show files from all commits, not just HEAD |
| `--long` | Show full OID (object ID) |
| `--size` | Show file size |
| `--name <pattern>` | Filter by filename glob |
| `--deleted` | Include files deleted in recent commits |

---

## Pull

Download LFS files for the current checkout. This runs automatically on `git checkout` when LFS is installed, but you can trigger it explicitly:

```bash
git lfs pull
```

Download LFS files for a specific ref:

```bash
git lfs pull origin main
```

After a shallow clone or when LFS files were skipped during clone:

```bash
git clone --depth 1 repo.git
cd repo
git lfs pull    # Fetch LFS content for the checked-out files
```

---

## Fetch

Download LFS objects from the remote server without checking them out. Useful for prefetching:

```bash
git lfs fetch
```

Fetch LFS objects for all refs (all branches, tags, etc.):

```bash
git lfs fetch --all
```

Fetch LFS objects for a specific ref:

```bash
git lfs fetch origin main
```

Options:

| Option | Description |
|--------|-------------|
| `--all` | Fetch LFS objects for all refs and commits |
| `--recent` | Also fetch LFS objects for recently modified refs |
| `--include="*.psd"` | Only fetch files matching pattern |
| `--exclude="*.zip"` | Skip files matching pattern |
| `origin main` | Fetch only for a specific remote/ref combo |

---

## Push

Upload LFS objects to the remote server:

```bash
git lfs push origin main
```

Push LFS objects for all refs:

```bash
git lfs push origin main --all
```

Push LFS objects from a specific commit range:

```bash
git lfs push origin main --object-id <oid>
```

---

## Migrate

Convert existing repository history to or from LFS. These commands rewrite history — **use with extreme care on shared branches**.

### `migrate import` — Convert existing files to LFS

```bash
git lfs migrate import --everything --above=100MB
```

This rewrites repo history, replacing all files over 100 MB with LFS pointers:

```bash
git lfs migrate import --include="*.psd,*.zip" --everything
```

| Option | Description |
|--------|-------------|
| `--everything` | Migrate all refs (branches, tags) |
| `--above=<size>` | Only migrate files larger than `<size>` (e.g., `5MB`, `100MB`) |
| `--include=<pattern>` | Only migrate files matching glob pattern(s) |
| `--exclude=<pattern>` | Skip files matching glob pattern(s) |
| `--yes` | Skip confirmation prompt |

### `migrate info` — Show LFS migration stats

```bash
git lfs migrate info --everything --above=10MB
```

Output:

```
*.psd   1.2 GB    12 files
*.zip   850 MB    4 files
*.mp4   2.1 GB    3 files
```

### `migrate export` — Convert LFS files back to regular Git objects

```bash
git lfs migrate export --everything --include="*.psd"
```

This reverses `migrate import` — LFS pointer files become real Git blobs again.

---

## Env

Display the current LFS environment configuration:

```bash
git lfs env
```

Output:

```
Endpoint=https://github.com/user/repo.git/info/lfs (auth=none)
LocalWorkingDir=/home/user/repo
LocalGitDir=/home/user/repo/.git
LocalGitStorageDir=/home/user/repo/.git
LocalMediaDir=/home/user/repo/.git/lfs/objects
LocalReferenceDir=
TempDir=/home/user/repo/.git/lfs/tmp
ConcurrentTransfers=3
TusTransfers=false
BasicTransfersOnly=false
SkipDownloadErrors=false
FetchProcesses=1
...

git config filter.lfs.smudge = "git-lfs smudge -- %f"
git config filter.lfs.clean = "git-lfs clean -- %f"
```

Useful for debugging connectivity, endpoint configuration, and storage paths.

---

## Configuration

### Git config keys

| Config | Description |
|--------|-------------|
| `filter.lfs.smudge` | Command to convert LFS pointer → real file (`git-lfs smudge -- %f`) |
| `filter.lfs.clean` | Command to convert real file → LFS pointer (`git-lfs clean -- %f`) |
| `filter.lfs.process` | Long-running filter process for performance |
| `filter.lfs.required` | Must be `true` — fail if LFS filter is not available |
| `lfs.url` | Override the LFS server endpoint URL |
| `lfs.fetchinclude` | Glob pattern for files to include when fetching (e.g., `*.psd`) |
| `lfs.fetchexclude` | Glob pattern for files to exclude when fetching (e.g., `*.zip`) |
| `lfs.concurrenttransfers` | Number of parallel LFS uploads/downloads (default: 3) |
| `lfs.batchsize` | Max objects per batch request |
| `lfs.contenttype` | Content type for LFS requests (default: `application/vnd.git-lfs+json`) |
| `lfs.allowincompletepush` | Allow push even if some LFS objects are missing |

Example `.gitconfig`:

```ini
[filter "lfs"]
    smudge = git-lfs smudge -- %f
    clean = git-lfs clean -- %f
    process = git-lfs filter-process
    required = true
[lfs]
    fetchinclude = *.psd
    fetchexclude = *.zip
    concurrenttransfers = 5
```

For LFS over SSH, configure the endpoint:

```bash
git config lfs.url "https://git-lfs.example.com/repo.git/info/lfs"
```

### `.lfsconfig`

You can also commit an `.lfsconfig` file in the repository root to share LFS configuration with the team:

```ini
[lfs]
    url = https://git-lfs.example.com/repo.git/info/lfs
```

---

## Lock / Unlock

File locking prevents merge conflicts on binary files by letting users **lock** files they are actively editing. Only supported on LFS-enabled remotes (GitHub, GitLab, etc.).

### Lock a file

```bash
git lfs lock design.psd
```

Output:

```
Locked design.psd by user@example.com
```

### Unlock a file

```bash
git lfs unlock design.psd
```

Force unlock (if you locked it but lost the lock ID):

```bash
git lfs unlock design.psd --force
```

### List locks

```bash
git lfs locks
```

Output:

```
design.psd    user@example.com    ID: 123
logo.svg      user@example.com    ID: 456
```

### Verify locks before push

```bash
git lfs locks --verify
```

Locks are per-user per-file. If someone else has a file locked and you try to modify it, you'll get a warning on push.

---

## Quick Reference

```bash
# Install
git lfs install                                        # Set up LFS filters

# Track / untrack
git lfs track "*.psd"                                  # Track PSD files
git lfs track "*.zip"                                  # Track ZIP files
git lfs untrack "*.psd"                                # Stop tracking PSDs

# Status & list
git lfs status                                         # Show LFS file status
git lfs ls-files                                       # List LFS files in HEAD
git lfs ls-files --all                                 # List LFS files in all commits
git lfs ls-files --size --long                         # Show sizes and full OIDs

# Fetch / pull / push
git lfs fetch                                          # Download LFS objects
git lfs fetch --all                                    # Download all LFS objects
git lfs pull                                           # Download & checkout LFS files
git lfs push origin main                               # Upload LFS objects
git lfs push origin main --all                         # Upload all LFS objects

# Migrate
git lfs migrate import --everything --above=100MB      # Convert large files to LFS
git lfs migrate info --everything --above=10MB         # Show migration stats
git lfs migrate export --everything                    # Convert LFS files back to Git

# Locks
git lfs lock design.psd                                # Lock a file
git lfs unlock design.psd                              # Unlock a file
git lfs locks                                          # List all locks

# Environment
git lfs env                                            # Show LFS configuration

# Config
git config lfs.url https://lfs.example.com/info/lfs    # Override LFS endpoint
git config lfs.fetchinclude "*.psd"                    # Only fetch PSDs
git config lfs.fetchexclude "*.zip"                    # Never fetch ZIPs
git config lfs.concurrenttransfers 5                   # Parallel transfers
```

---

## Real-World Examples

### Initialize LFS on a new project

```bash
git lfs install
git lfs track "*.psd"
git lfs track "*.zip"
git add .gitattributes
git commit -m "Configure LFS for design files and archives"
```

### Convert an existing repository to use LFS

```bash
# Analyze which files would be migrated
git lfs migrate info --everything --above=5MB

# Migrate all files over 100 MB
git lfs migrate import --everything --above=100MB

# Update the remote (force push needed — history changed!)
git push origin --force --all
git push origin --force --tags
```

**Warning:** `migrate import` rewrites commit SHAs. Coordinate with your team before running.

### Fetch all LFS objects for offline work

```bash
git lfs fetch --all
```

This downloads every LFS object from every commit so you can work offline.

### Pull LFS files after a shallow clone

```bash
git clone --depth 1 https://github.com/user/repo.git
cd repo
git lfs pull
```

After a shallow clone, LFS files are not automatically downloaded. Run `git lfs pull` to fetch them.

### Lock a file before editing

```bash
git lfs lock design.psd
# ... edit design.psd ...
git add design.psd
git commit -m "Update homepage mockup"
git push
git lfs unlock design.psd
```

Prevents others from modifying the same PSD file while you are working on it.

### Download only certain LFS file types

```bash
git config lfs.fetchinclude "*.psd"
git config lfs.fetchexclude "*.zip"
git lfs pull
```

Only PSD files are fetched; ZIP files remain as pointer files.

### Check what LFS objects a commit needs

```bash
git lfs ls-files --all --long
```

Useful before migrating or archiving — see every LFS object in the entire history.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Forgot to commit `.gitattributes` | LFS patterns are only effective when `.gitattributes` is tracked | Always `git add .gitattributes` after `git lfs track` |
| LFS files not downloaded after clone | LFS pull is automatic only if `git-lfs` was installed before cloning | Run `git lfs pull` after clone to fetch missing files |
| Pushing large files directly into Git instead of LFS | File was committed before LFS tracking was set up | Use `git lfs migrate import` to rewrite history |
| `git lfs migrate` broke everyone's clones | History rewrite changes all commit SHAs | Coordinate with team, force push, and have everyone re-clone |
| "Object does not exist on the server" on push | LFS objects were not uploaded before the Git ref | Run `git lfs push origin main --all` to upload missing objects |
| Can't lock a file — "locking not supported" | Remote server (e.g., plain Git hosting) does not support LFS locking | Use a hosting provider that supports LFS locks (GitHub, GitLab, Bitbucket) |
| Disk full from `.git/lfs/objects` | LFS caches all fetched objects locally | Run `git lfs prune` to remove unreferenced LFS objects |
| Pointer files committed instead of real content | LFS filter is not installed or not configured correctly | Run `git lfs install` and verify `git lfs env` shows the filter |
| `git lfs migrate` did not update the working tree | Migrate rewrites history but you may need to reset | Run `git checkout --force` to refresh the working tree after migrate |
| Huge LFS transfer on every fetch | Pure Git clones fetch all LFS files by default | Configure `lfs.fetchinclude` and `lfs.fetchexclude` to limit |
| LFS push fails with "batch response: Repository or object not found" | LFS endpoint is misconfigured or credentials are missing | Check `git lfs env` for the endpoint URL, then `git config lfs.url` if needed |
| `git lfs prune` deleted files I still need | Prune removes LFS objects not referenced by recent commits | Use `git lfs pull` to re-download pruned objects |
