# `git bundle` — Move objects and refs via archive (for offline transfer, sneaker-net)

The `git bundle` command packages Git objects and refs into a single binary file. It is the primary mechanism for **offline transfer** — moving commits between repositories without a network connection ("sneaker-net"). A bundle file is essentially a portable Git repository that can be transported via USB drive, email attachment, or any other offline medium.

```
git bundle create <file> <git-rev-list-args>
git bundle verify <file>
git bundle list-heads <file> [<refname>...]
git bundle unbundle <file> [<refname>...]
```

The bundle file format is a packed Git object database with an appended ref list. It is **forward and backward compatible** — a bundle created by an older Git version can be read by a newer one and vice versa.

---

## Description

`git bundle` serves one core purpose: **transporting Git data without a network**.

- A bundle file (`.bundle` suffix by convention) contains **compressed Git objects** and **reference mappings**
- Bundles can be **incremental** — you can bundle only the commits since a given point
- Bundles can be **thin** (exclude prerequisite objects) for smaller sizes
- The receiving side fetches from the bundle file as if it were a remote

**When to use bundles:**
- Air-gapped environments (no network access to Git servers)
- Very large repositories where a full clone over the network is impractical
- Sneaking changes between machines via USB drive
- Distributing patches to teams without shared Git hosting

---

## Create

### `git bundle create <file> <git-rev-list-args>`

Create a bundle file containing the objects reachable from the given revision arguments:

```bash
git bundle create repo.bundle HEAD main
```

This creates `repo.bundle` containing everything reachable from `HEAD` and `main`.

### Bundle all branches

```bash
git bundle create repo.bundle --all
```

### Bundle a range of commits

```bash
git bundle create update.bundle HEAD~5..HEAD
```

Only the last 5 commits (and their objects) are included.

### Bundle with multiple refs

```bash
git bundle deploy.bundle origin/main..main
```

The range spec `A..B` bundles commits in `B` that are not in `A`. The prerequisite (`A`) is recorded in the bundle so the receiver knows what they need.

### Incremental bundle

```bash
git bundle create week2.bundle --since="2026-05-27" --all
```

Only commits newer than the specified date. Combine with `--max-age` or `--until` for time-based incremental backups.

### Thin bundle (shallow)

```bash
git bundle create thin.bundle --thin HEAD~10..HEAD
```

The `--thin` flag creates a **thin pack** — deltas are computed against objects assumed to exist on the receiving side. Smaller file size, but only usable if the receiver has the prerequisite objects.

### Bundle a single tag

```bash
git bundle create v1.0.bundle v1.0
```

Creates a bundle containing the tagged commit and all its history.

---

## Verify

### `git bundle verify <file>`

Check that a bundle file is valid and can be applied:

```bash
git bundle verify repo.bundle
```

Output:
```
The bundle contains these 2 refs:
<hash> refs/heads/main
<hash> refs/heads/develop
The bundle requires these 2 prereqs:
<hash>
<hash>
```

If the bundle requires prerequisite commits that the receiver does not have, `git bundle verify` prints them. The receiver must obtain those prerequisites before unbundling.

### Verbose verify

```bash
git bundle verify -v repo.bundle
```

Prints additional detail about the bundle contents.

---

## List-heads

### `git bundle list-heads <file> [<refname>...]`

List the refs (branches, tags) available in a bundle:

```bash
git bundle list-heads repo.bundle
```

Output:
```
<hash> refs/heads/main
<hash> refs/heads/develop
<hash> refs/tags/v1.0
```

### Filter by specific ref

```bash
git bundle list-heads repo.bundle main
```

Only shows the `main` ref if it exists in the bundle.

---

## Unbundle

### `git bundle unbundle <file> [<refname>...]`

Restore objects and refs from a bundle into the current repository:

```bash
git bundle unbundle repo.bundle
```

This writes all bundled objects into the repository's object store and creates/updates the refs contained in the bundle.

### Unbundle specific refs

```bash
git bundle unbundle repo.bundle main
```

Only the `main` ref is updated.

### Fetch from bundle (modern approach)

```bash
git fetch repo.bundle main:main
```

Treats the bundle file as a remote. Fetches `main` from the bundle into the local `main` branch.

```bash
git fetch repo.bundle '+refs/heads/*:refs/remotes/origin/*'
```

Fetches all bundle refs as remote-tracking branches.

---

## Clone from Bundle

### `git clone <bundle-file> <directory>`

Clone a repository directly from a bundle file:

```bash
git clone repo.bundle repo-clone
```

This creates a new repository `repo-clone` with the full history from the bundle. Git automatically sets up the bundle as the `origin` remote's URL.

### Clone from bundle with a real remote

```bash
git clone repo.bundle repo-clone
cd repo-clone
git remote set-url origin https://github.com/user/repo.git
git fetch --all
```

Useful when you used a bundle for the initial clone (to save bandwidth) but want a real remote for ongoing work.

### `--bundle-uri` (Git 2.32+)

```bash
git clone --bundle-uri=https://example.com/repo.bundle https://github.com/user/repo.git
```

Downloads the bundle first (often from a CDN) to speed up the initial clone, then fetches remaining deltas from the remote.

---

## Incremental Bundles

Bundles excel at incremental offline transport. The key is using **revision range specifications** that only include new commits.

### Time-based increment

```bash
# Week 1
git bundle create week1.bundle --since="2026-06-01" --until="2026-06-07" --all

# Week 2
git bundle create week2.bundle --since="2026-06-07" --until="2026-06-14" --all
```

### Range-based increment

```bash
# Initial bundle
git bundle create base.bundle --all

# Later: bundle only new commits since the last bundle
git bundle create update.bundle --since=refs/bundled/last --all
```

### Using tags to track bundle state

```bash
# On source machine
git bundle create update.bundle HEAD~10..HEAD
git tag -f last-bundled HEAD

# Transfer update.bundle via USB

# On target machine
cd repo
git fetch /path/to/update.bundle main:main
```

### Incremental with `git rev-list`

```bash
# Bundle everything after a known commit
git bundle create incremental.bundle abc123..HEAD
```

The receiver must already have commit `abc123`. `git bundle verify` will confirm this.

---

## Thin Bundles

A **thin bundle** is a bundle that excludes objects the receiver is expected to already have. This makes the bundle file significantly smaller.

```bash
git bundle create --thin update.bundle origin/main..main
```

- The `--thin` flag creates deltas against the prerequisite objects
- The bundle records prerequisite commit hashes
- The receiver must have those prerequisites for the bundle to work
- Thin bundles are only valid for incremental transfers, not standalone clones

---

## Quick Reference

```bash
# Create
git bundle create repo.bundle HEAD main                # Bundle specific refs
git bundle create repo.bundle --all                    # Bundle all refs
git bundle create update.bundle HEAD~5..HEAD           # Last 5 commits
git bundle create backup.bundle --since="2026-01-01"   # Commits since date

# Verify
git bundle verify repo.bundle                          # Check validity
git bundle verify -v repo.bundle                       # Verbose verification

# List heads
git bundle list-heads repo.bundle                      # List all refs in bundle
git bundle list-heads repo.bundle main                 # Check specific ref

# Unbundle
git bundle unbundle repo.bundle                        # Restore all refs
git bundle unbundle repo.bundle main                   # Restore specific ref

# Clone/fetch
git clone repo.bundle new-repo                         # Clone from bundle
git fetch repo.bundle main:main                        # Fetch specific branch
git fetch repo.bundle '+refs/heads/*:refs/remotes/origin/*'  # All branches

# Incremental
git bundle create --thin update.bundle HEAD~5..HEAD    # Thin (small) bundle
git bundle create week2.bundle --since="1 week ago"    # Time-based increment
```

---

## Real-World Examples

### 1. Full backup of a repository

```bash
git bundle create backup.bundle --all
```

Creates a complete snapshot of all refs and reachable objects. A full backup of the repository in a single portable file.

### 2. Bundle the last 5 commits for review

```bash
git bundle create update.bundle HEAD~5..HEAD
```

Packages only the most recent 5 commits. Useful for sending a small update to a colleague.

### 3. Verify a received bundle

```bash
git bundle verify update.bundle
```

Before unbundling, check that the bundle is valid and that you have all prerequisite commits. If prerequisites are missing, the verify output lists them.

### 4. List available refs in a bundle

```bash
git bundle list-heads update.bundle
```

Shows what branches, tags, or refs are inside the bundle. Useful when you receive a bundle from someone else and need to know what's in it.

### 5. Clone a repository from a bundle

```bash
git clone backup.bundle new-repo
```

Creates a fully functional repository from the bundle, exactly as if you had cloned over the network.

### 6. Fetch a specific branch from a bundle

```bash
git fetch update.bundle main:main
```

Updates your local `main` branch with the commits from the bundle's `main` branch.

### 7. Incremental bundle for offline transport

**On the source machine (has network):**

```bash
# Initial full bundle
git bundle create project.bundle --all

# Two weeks later: create incremental bundle
git tag -f bundle-base HEAD
# ... do more work ...

# Bundle only new commits
git bundle create update-1.bundle bundle-base..HEAD
git tag -f bundle-base HEAD
```

**On the target machine (air-gapped, no network):**

```bash
# Initial clone from USB
git clone /mnt/usb/project.bundle project
cd project

# Apply incremental update
git fetch /mnt/usb/update-1.bundle main:main
git fetch /mnt/usb/update-1.bundle --tags
```

### 8. Deploy to an air-gapped server

```bash
# On development machine
git bundle create deploy.bundle main
scp deploy.bundle user@airgap-server:/tmp/

# On air-gapped server
cd /var/www/app
git fetch /tmp/deploy.bundle main:main
git checkout main
```

### 9. Bundle including tags

```bash
git bundle create release.bundle --tags main develop
```

Bundle the `main` and `develop` branches plus all tags. Useful for distributing a complete release snapshot.

### 10. Split a large bundle across multiple files

```bash
git bundle create part1.bundle HEAD~100
git tag bundle-split-1 HEAD~100
git bundle create part2.bundle bundle-split-1..HEAD
```

For extremely large repositories, split the history into multiple bundle files that can be applied sequentially.

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| Bundle missing prerequisite commits | The bundle only contains the range specified — the receiver may not have the base | Use `git bundle verify` on the receiving end, and transfer prerequisites too |
| `git bundle verify` fails on receiving side | Bundle was created with `--thin` and receiver lacks base objects | Apply the base bundle first, then apply the thin bundle |
| Bundle is very large | Including all history with `--all` | Use incremental bundles with `--since=`, `--max-age`, or range specs |
| Forgot to include a branch | `git bundle create repo.bundle main` only includes `main` | Use `--all` or explicitly list all refs: `main develop feature-x` |
| `git clone repo.bundle` fails with "not a git repository" | Bundle file is corrupt or not a valid bundle | Run `git bundle verify` to check, or recreate the bundle |
| Bundle lacks all tags | `--tags` must be explicitly requested | Use `--tags` flag with `git bundle create`, or bundle refs/tags/* |
| Thin bundle used for a standalone clone | Thin bundles assume prerequisite objects exist — a fresh clone has none | Create a non-thin bundle for clones, or use a thick initial bundle + thin increments |
| Pushing to a bundle doesn't work | Bundle files are **read-only** after creation — you cannot push to them | Create a new bundle with `git bundle create` instead |
| Bundle created on Windows has wrong line endings | The bundle stores Git objects faithfully, but checkout on different platforms may apply CRLF | Check `core.autocrlf` settings on both sides |
| Bundle created with `--depth` (shallow) is incomplete | Shallow bundles truncate history | Deepen the source repo first, or use full history for bundles |

---

## Configuration

```ini
# Bundle-specific config is minimal — most settings come from pack and transfer config
[pack]
    # Compression level for bundle contents (1-9, default 0 for speed-size balance)
    compression = 9

    # Threads for delta compression during bundle creation
    threads = 4

    # Window size for delta search (higher = better compression, slower)
    window = 250

[transfer]
    # Unpack limit for received bundle objects (0 = always unpack)
    unpackLimit = 100
```

---

## Visual Summary

```
Source Repository        Bundle File               Target Repository
─────────────────       ────────────              ──────────────────

  main ──► a1b2c3d       repo.bundle               git clone/repack
  dev  ──► e5f6g7a       ┌─────────────────┐
  v1.0 ──► h8i9j0k       │ Packed Objects   │     new-repo/
                          │   a1b2c3d        │     ├── .git/
 git bundle create        │   e5f6g7a        │     │   ├── objects/ ←──
   repo.bundle --all      │   h8i9j0k        │     │   ├── refs/   ←──
                          │                  │     │   │   ├── heads/main
                          │ Ref List         │     │   │   ├── heads/dev
                          │   a1b2c3d main   │     │   │   └── tags/v1.0
                          │   e5f6g7a dev    │     │   └── ...
                          │   h8i9j0k v1.0   │     └── src/
                          └─────────────────┘         └── ...
                              │
                              │ USB drive, email,
                              │ file share, etc.
                              │
                              ▼
                        git verify / git fetch / git clone

Incremental Bundles:

  Week 1         Week 2         Week 3
  ┌────────┐    ┌────────┐    ┌────────┐
  │ base   │    │ inc-1  │    │ inc-2  │
  │ ─────► │ +  │ ─────► │ +  │ ─────► │ = Full history
  │ a1..c3 │    │ c3..f7 │    │ f7..k9 │
  └────────┘    └────────┘    └────────┘
      │             │             │
      └─────────────┴─────────────┘
                    │
              Apply sequentially:
              1. git clone base.bundle repo
              2. git fetch inc-1.bundle
              3. git fetch inc-2.bundle
```

`git bundle` is the **offline transport layer** of Git. It turns any set of commits into a single file that can be moved by any means — USB, email, carrier pigeon — and applied to any other Git repository. Essential for air-gapped workflows, disaster recovery, and bandwidth-constrained environments.
