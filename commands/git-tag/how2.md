# `git tag` — Create, list, delete, or verify a tag object signed with GPG

`git tag` manages tags — named references to specific commits (or objects). Tags are typically used to mark release points (v1.0, v2.0, etc.). Git supports lightweight tags (simple pointers) and annotated tags (full objects with message, tagger, and date).

```
git tag [-a | -s | -u <keyid>] [-f] [-m <msg> | -F <file>] [-e] <tagname> [<commit> | <object>]
git tag -d <tagname>...
git tag [-n[<n>]] -l [--contains <commit>] [--no-contains <commit>] [--points-at <object>]
        [--column[=<options>] | --no-column] [--create-reflog] [--sort=<key>]
        [--format=<format>] [--merged <commit>] [--no-merged <commit>] [<pattern>...]
git tag -v [--format=<format>] <tagname>...
```

---

## Description

A tag in Git is a **named reference** to a specific commit (or other object). Unlike branches, tags do not move when new commits are made — they are permanent markers.

```
       v1.0        v1.1
        ▼           ▼
a1b2c3d ─── e5f6g7a ─── h8i9j0k (main)
```

There are three types of tags:

---

## Tag Types

### Lightweight Tag

A lightweight tag is just a **simple pointer** to a commit — nothing more than a ref in `refs/tags/`. It has no message, no tagger, no date, no GPG signature. It's essentially a branch that never moves.

```bash
git tag v1.0                                 # Simple pointer at HEAD
git tag v1.0 abc1234                         # Simple pointer at a specific commit
```

Use lightweight tags for **private** or **temporary** markers where you don't need metadata.

### Annotated Tag

An annotated tag is a **full object** in Git's object database. It stores:
- A tag message (like a commit message)
- The tagger's name, email, and date
- Optionally, a GPG signature

```bash
git tag -a v1.0 -m "Release 1.0"            # Create annotated tag at HEAD
git tag -a v1.0 abc1234 -m "Release 1.0"    # Create at a specific commit
git tag -a v1.0                              # Editor opens for message
```

Annotated tags are the **recommended** default for public releases.

### Signed Tag

A signed tag is an annotated tag that is cryptographically signed with GPG, allowing others to verify that the tag was created by you and hasn't been tampered with.

```bash
git tag -s v1.0 -m "Release 1.0"            # Sign with default GPG key
git tag -u ABCDEF1234567890 v1.0 -m "Release 1.0"  # Sign with specific key
```

---

### Lightweight vs Annotated

| Aspect | Lightweight | Annotated |
|--------|-------------|-----------|
| Git object type | Ref only (`refs/tags/`) | Full object in `.git/objects` |
| Message | No | Yes |
| Tagger info | No | Yes (name, email, date) |
| GPG signing | No | Yes (`-s` / `-u`) |
| Size | Minimal | Larger (stores metadata) |
| `git tag -v` | Not possible | Possible (if signed) |
| `git describe` | Not included by default | Included |
| `git push` behavior | Pushed with `--tags` only | Pushed automatically with reachable commits |
| Use case | Private, temporary markers | Public releases |

**Rule of thumb:** use annotated tags (`-a`) for everything public-facing. Use lightweight tags for quick private bookmarks.

---

## Create

### `git tag <tagname>`

Create a **lightweight** tag at HEAD:

```bash
git tag v1.0
```

### `git tag <tagname> <commit>`

Create a lightweight tag at a specific commit:

```bash
git tag v1.0-rc1 abc1234
```

### `git tag -a <tagname> -m "<msg>"`

Create an **annotated** tag at HEAD:

```bash
git tag -a v1.0 -m "Release 1.0"
```

Without `-m`, Git opens the editor for the tag message:

```bash
git tag -a v1.0
```

### `git tag -a <tagname> -m "<msg>" <commit>`

Create an annotated tag at a specific commit:

```bash
git tag -a v1.0 abc1234 -m "Release 1.0"
```

### `git tag -s <tagname> -m "<msg>"`

Create a **signed** annotated tag with GPG:

```bash
git tag -s v2.0.0 -m "Release 2.0.0"
```

### `git tag -u <keyid> <tagname> -m "<msg>"`

Create a signed tag with a **specific GPG key**:

```bash
git tag -u ABCDEF1234567890 v2.0.0 -m "Release 2.0.0"
```

### `git tag -a -f <tagname>`

Force-create a tag, overwriting an existing tag with the same name:

```bash
git tag -a -f v1.0 -m "Release 1.0 (fixed)"
```

Without `-f`, Git refuses to create a tag that already exists.

### `git tag -a -e <tagname>`

Create an annotated tag and open the editor to write the message (same as `-a` without `-m`):

```bash
git tag -a -e v1.0
```

### `git tag -a -F <file> <tagname>`

Read the tag message from a file:

```bash
git tag -a -F release-notes.txt v1.0
```

### `git tag <tagname> <object>`

Tag a **non-commit object** (e.g., a tree or blob):

```bash
git tag my-tree abc1234  # abc1234 is a tree object
```

---

## List

### `git tag`

List all tags alphabetically:

```bash
git tag
```

Output:
```
v1.0
v1.1
v2.0
```

### `git tag -l <pattern>`

List tags matching a glob pattern:

```bash
git tag -l "v1.*"
git tag -l "*-rc*"
```

### `git tag -n`

Show tags with the first line of their annotation (or the commit subject for lightweight tags):

```bash
git tag -n
```

Output:
```
v1.0        Release 1.0
v1.1        Release 1.1
v2.0        Release 2.0
```

### `git tag -n<n>`

Show `<n>` lines of annotation:

```bash
git tag -n3                       # Show 3 lines of annotation per tag
git tag -n1 -l "v2.*"            # 1 line, filtered by pattern
```

### `git tag --sort=<key>`

Sort tags by a specific field. Prefix with `-` for descending:

```bash
git tag --sort=-v:refname         # Natural version sort (v1.9 before v1.10)
git tag --sort=-creatordate       # Most recently created first
git tag --sort=refname            # Alphabetical
```

Common sort keys:

| Key | Description |
|-----|-------------|
| `refname` | Tag name (alphabetical) |
| `version:refname` (or `v:refname`) | Natural version sort (`v1.2` < `v1.10`) |
| `creatordate` | Date the tag was created |
| `taggerdate` | Date the tag was created (annotated tags only) |

### `git tag --contains <commit>`

List tags that contain a specific commit (the tag's commit is an ancestor of the named commit, or vice versa in reachability terms):

```bash
git tag --contains abc123         # Which tags contain this commit?
git tag --contains v1.0           # Which tags are ancestors of or contain v1.0's commit?
```

### `git tag --no-contains <commit>`

List tags that do **not** contain a specific commit:

```bash
git tag --no-contains abc123
```

### `git tag --merged <commit>`

List tags that are reachable from (merged into) `<commit>`:

```bash
git tag --merged main             # Tags reachable from main
```

### `git tag --no-merged <commit>`

List tags that are not reachable from `<commit>`:

```bash
git tag --no-merged main          # Tags not reachable from main
```

### `git tag --points-at <object>`

List tags that point to a specific commit or object:

```bash
git tag --points-at abc1234
git tag --points-at v1.0          # Show other tags pointing to the same commit
```

### `git tag --column[=<options>]`

Display tags in columns:

```bash
git tag --column                  # Columnar display (auto)
git tag --column=always,row       # Always use columns, fill rows first
git tag --no-column               # Single column
```

### `git tag --sort` for semver

Sort tags in semantic versioning order (highest version first):

```bash
git tag --sort=-v:refname
```

Output:
```
v2.3.0
v2.2.0
v2.10.0
v2.1.0
v2.0.0
v1.9.0
```

Without `version:refname`, string sorting puts `v2.10.0` before `v2.2.0`.

---

## Format

### `--format="..."`

Customize tag output with format placeholders:

```bash
git tag --format="%(refname:short) %(objectname:short) %(taggerdate:short)"
```

Output:
```
v1.0 abc1234 2025-01-15
v1.1 def5678 2025-03-20
v2.0 ghi9012 2025-06-01
```

### Common placeholders

| Placeholder | Description |
|-------------|-------------|
| `%(refname)` | Full ref name (e.g., `refs/tags/v1.0`) |
| `%(refname:short)` | Short name (e.g., `v1.0`) |
| `%(objectname)` | Full hash of the tagged object |
| `%(objectname:short)` | Abbreviated hash |
| `%(objecttype)` | Type of object (commit, tag, blob, tree) |
| `%(contents)` | Full tag message |
| `%(contents:subject)` | First line of the tag message |
| `%(contents:body)` | Body of the tag message (rest after first line) |
| `%(contents:signature)` | GPG signature of the tag |
| `%(taggername)` | Name of the tagger (annotated tags) |
| `%(taggeremail)` | Email of the tagger |
| `%(taggerdate)` | Date the tag was created |
| `%(taggerdate:relative)` | Relative date (`3 weeks ago`) |
| `%(taggerdate:short)` | Short date (`2025-01-15`) |
| `%(taggerdate:iso)` | ISO date |
| `%(creator)` | Who created the ref (different from tagger for lightweight) |
| `%(creatordate)` | When the ref was created |
| `%(subject)` | Tag message subject (same as `%(contents:subject)`) |
| `%(body)` | Tag message body (same as `%(contents:body)`) |
| `%(color:<color>)` | Change color |
| `%(color:reset)` | Reset color |

### Colorized tag list

```bash
git tag --format="%(color:bold yellow)%(refname:short)%(color:reset) %(color:cyan)%(taggerdate:short)%(color:reset)"
```

### Conditional formatting

Show tagger name only if the tag is annotated:

```bash
git tag --format="%(refname:short)%(if:%(taggername))%(then) (%(taggername))%(end)"
```

---

## Verify

### `git tag -v <tagname>`

Verify the GPG signature of a signed tag:

```bash
git tag -v v2.0.0
```

If the signature is valid:
```
object abc1234...
type commit
tag v2.0.0
tagger Alice <alice@example.com> 1712345678 +0000

Release 2.0.0
gpg: Signature made Mon Apr 5 14:22:00 2025 UTC
gpg:                using RSA key ABCDEF1234567890
gpg: Good signature from "Alice <alice@example.com>"
```

If the signature is invalid or the tag is unsigned:
```
gpg: Signature made Mon Apr 5 14:22:00 2025 UTC
gpg:                using RSA key ABCDEF1234567890
gpg: BAD signature from "Alice <alice@example.com>"
```

Lightweight tags cannot be verified — `git tag -v` returns an error.

### `git tag -v --format="..."`

Verify and show formatted output:

```bash
git tag -v --format="%(refname:short) signed by %(taggername) (%(taggeremail))" v2.0.0
```

---

## Delete

### `git tag -d <tagname>`

Delete a local tag:

```bash
git tag -d v1.0
```

### Delete multiple local tags

```bash
git tag -d v1.0 v1.1 v1.2
```

### Delete all local tags matching a pattern

```bash
git tag -d $(git tag -l "v1.*")
```

### Force-delete a tag

`-d` works whether or not the tag has been pushed. Use `-f` with creation to overwrite, `-d` to delete.

---

## Push Tags

### `git push origin <tagname>`

Push a specific tag to the remote:

```bash
git push origin v1.0
```

### `git push origin --tags`

Push **all** tags (both lightweight and annotated) to the remote:

```bash
git push --tags origin
```

### `git push origin --follow-tags`

Push only annotated tags that are **reachable** from the pushed commits (safer than `--tags`):

```bash
git push --follow-tags origin main
```

### `git push origin --follow-tags` (default behavior)

With `push.followTags = true` in config:
```bash
git config --global push.followTags true
git push origin main          # Also pushes reachable annotated tags
```

### Push tags to a specific remote

```bash
git push upstream v1.0
```

### Push tags atomically

```bash
git push --atomic origin v1.0 v2.0
```

Either both tags are created on the remote, or neither is.

---

## Delete Remote Tag

### `git push origin --delete <tagname>`

Delete a tag from the remote:

```bash
git push --delete origin v1.0
```

### `git push origin :refs/tags/<tagname>`

Older syntax — push "nothing" to the remote tag ref:

```bash
git push origin :refs/tags/v1.0
```

### Delete multiple remote tags

```bash
git push --delete origin v1.0 v1.1 v1.2
git push origin :refs/tags/v1.0 :refs/tags/v1.1
```

### Delete remote tags matching a pattern

```bash
git push origin --delete $(git tag -l "v1.*")
# Then clean up locally
git tag -d $(git tag -l "v1.*")
```

---

## Config

Set in `.gitconfig` or repo `.git/config`:

```ini
# Always sign newly created tags
[tag]
    gpgSign = true

# Force signing annotated tags (even those created by merge, etc.)
    forceSignAnnotated = true

# Default sort order for tag listings
    sort = -v:refname

# Auto-follow tags on push
[push]
    followTags = true

# Sorting tags
[tag]
    sort = -version:refname
```

| Config | Values | Description |
|--------|--------|-------------|
| `tag.gpgSign` | `true`, `false` | Automatically sign all tags created with `-a` (no need for `-s`) |
| `tag.forceSignAnnotated` | `true`, `false` | Sign annotated tags even from porcelain commands (merge, am) |
| `tag.sort` | sort key | Default sort order for `git tag` listings |
| `push.followTags` | `true`, `false` | Push reachable annotated tags by default |

### GPG configuration

```ini
# Specify the default GPG signing key
[user]
    signingKey = ABCDEF1234567890

# Equivalent for tags specifically
[tag]
    gpgSign = true
```

### `git config` commands

```bash
git config --global tag.gpgSign true
git config --global tag.sort "-v:refname"
git config --global push.followTags true
```

---

## Quick Reference

```bash
# Create
git tag v1.0                                    # Lightweight tag at HEAD
git tag v1.0 abc1234                            # Lightweight tag at commit
git tag -a v1.0 -m "Release 1.0"               # Annotated tag
git tag -s v2.0.0 -m "Release 2.0.0"           # Signed tag (default key)
git tag -u KEYID v2.0.0 -m "Release 2.0.0"     # Signed tag (specific key)
git tag -a -f v1.0 -m "Release 1.0 (fixed)"    # Force (overwrite existing)
git tag -a -e v1.0                              # Open editor for message
git tag -a -F msg.txt v1.0                      # Read message from file

# List
git tag                                         # List all tags
git tag -l "v1.*"                               # List tags matching pattern
git tag -n                                       # Show annotations (1 line)
git tag -n3                                      # Show 3 lines of annotation
git tag --sort=-v:refname                       # Semver sort (descending)
git tag --sort=creatordate                       # Sort by creation date
git tag --contains abc123                       # Tags containing commit
git tag --no-contains abc123                    # Tags NOT containing commit
git tag --merged main                           # Tags reachable from main
git tag --no-merged main                        # Tags NOT reachable from main
git tag --points-at abc123                      # Tags pointing at object
git tag --column                                # Columnar display

# Delete
git tag -d v1.0                                 # Delete local tag
git tag -d v1.0 v1.1                            # Delete multiple local tags

# Verify
git tag -v v2.0.0                               # Verify GPG signature

# Push
git push origin v1.0                            # Push a specific tag
git push --tags origin                          # Push all tags
git push --follow-tags origin main              # Push reachable annotated tags

# Delete remote
git push --delete origin v1.0                   # Delete remote tag
git push origin :refs/tags/v1.0                 # Delete remote tag (older syntax)

# Format
git tag --format="%(refname:short) %(taggerdate:short) %(contents:subject)"
```

---

## Real-World Examples

```bash
# Mark a lightweight release (quick, no metadata)
git tag v1.0.0

# Mark an annotated release (recommended for public use)
git tag -a v1.0.0 -m "Release 1.0.0"

# Mark a signed release (cryptographically verified)
git tag -s v2.0.0 -m "Release 2.0.0"

# List all tags matching a major version
git tag -l "v2.*"

# Show tags with their annotation messages inline
git tag -n

# Push a specific tag to remote
git push origin v1.0.0

# Push all tags to remote
git push --tags

# Delete a local tag
git tag -d v1.0.0

# Delete a tag on the remote
git push --delete origin v1.0.0

# Verify a signed tag
git tag -v v2.0.0

# List tags sorted by semver (natural version order)
git tag --sort=-v:refname

# Find tags containing a specific commit
git tag --contains abc123

# Create a tag for an older commit
git tag -a v0.9 -m "Pre-release 0.9" 9f8e7d6

# Create a tag on a branch other than the current one
git tag -a v1.0-rc main -m "Release candidate 1"

# Annotate a tag with a multi-line message from a file
git tag -a -F RELEASE_NOTES.md v1.0.0

# List tags with formatted output (tag name + date + message)
git tag --format="%(color:green)%(refname:short)%(color:reset) %(color:yellow)%(taggerdate:short)%(color:reset) %(contents:subject)"

# Show only lightweight tags (no taggerdate means lightweight)
git tag --format="%(refname:short)%(if:%(taggerdate))%(then)%(end)" | grep -v "^$"

# Show only annotated tags
git tag --format="%(refname:short)%(if:%(taggerdate))%(then) %(taggerdate:short)%(end)" | grep " "

# Update a tag to point to a new commit (use with caution)
git tag -a -f v1.0 -m "Release 1.0 (fixed)"

# Push a tag update to remote (requires --force on remote too)
git push origin v1.0 --force

# Fetch tags from remote
git fetch --tags

# Fetch only specific tags from remote
git fetch origin tag v1.0

# List tags that are NOT on any remote
comm -23 <(git tag | sort) <(git ls-remote --tags origin | cut -f2 | sed 's|refs/tags/||' | sort)

# Find the tag that introduced a commit
git tag --contains abc123

# Count the number of tags matching a pattern
git tag -l "v1.*" | wc -l

# Export tagged commit contents
git archive --format=zip v1.0 > release-v1.0.zip

# Describe a commit in terms of the nearest tag
git describe                               # e.g., v1.0-5-gabc1234
git describe --tags                        # Use lightweight tags too
git describe --abbrev=0                    # Just the tag name (no commit suffix)

# Create a release branch from a tag
git checkout -b release-v1.0 v1.0

# Sign all tags by default
git config --global tag.gpgSign true

# Set default tag sort to semver
git config --global tag.sort "-v:refname"
```

---

## Common Pitfalls

| Mistake | Why it happens | Solution |
|---------|---------------|----------|
| `git push` didn't push tags | Tags are not included in `git push` by default | Use `git push --tags`, `git push --follow-tags`, or push each tag explicitly |
| Forgot `-a` — created lightweight instead of annotated | `git tag v1.0` without `-a` makes a lightweight tag | Use `git tag -a v1.0 -m "msg"` or delete and recreate: `git tag -d v1.0 && git tag -a v1.0 -m "msg"` |
| `git tag -d` fails because tag doesn't exist | Typo in the tag name | Check with `git tag` or use tab completion |
| `git tag -v` says "not a signed tag" | Tag is lightweight or unsigned annotated | Lightweight tags cannot be signed; annotated tags need `-s` |
| `git push --delete origin` deletes the wrong tag | Name collision with a branch | Git prioritizes branches over tags. Use full ref: `git push origin :refs/tags/v1.0` |
| Tags are not sorted correctly (v2.10 before v2.2) | Default is alphabetical, not semver | Use `--sort=-v:refname` for natural version sort |
| Force-pushed a tag and remote rejected | Remote has tag protection | Use `git push origin v1.0 --force` or update remote tag protection settings |
| `git describe` doesn't see lightweight tags | `git describe` ignores lightweight tags by default | Add `--tags` flag: `git describe --tags` |
| Moved a tag that others rely on | Tags are meant to be permanent — moving them is bad practice | Communicate with the team; use `--no-tags` or a new tag name for corrections |
| `git fetch` doesn't fetch tags | `git fetch` only fetches tags reachable from fetched branches | Use `git fetch --tags` to fetch all tags |
| Annotated tag message is empty | `-m ""` or `-m` without text | Use `git tag -a -f v1.0 -m "real message"` to rewrite |
| Deleted a local tag but remote still has it | Local delete does not affect remote | `git push --delete origin v1.0` to delete the remote copy |
| GPG signing fails with "no secret key" | GPG key not configured or not found | Configure with `git config --global user.signingKey KEYID` and check `gpg --list-secret-keys` |
| Duplicate tag name on remote | A tag with the same name already exists on the remote | Delete the remote tag first, then push, or use a different tag name |
| `git tag --contains` on a tag that is not an ancestor | `--contains` checks reachability, not tag object pointing | Use `--points-at` for exact pointer matching |



---

## Visual Summary

```
Create                                 Delete
─────────────────                     ─────────────────
                                       ┌──────────────┐
  git tag v1.0                 ───────►│ v1.0         │
  (lightweight, at HEAD)       ───────►│ abc1234 Fix  │
                                       └──────────────┘
                                                         git tag -d v1.0 ────► ✗ removed
                                       ┌──────────────┐
  git tag -a v1.0 -m "Release" ───────►│ v1.0 (obj)   │
  (annotated, with metadata)   ───────►│ tagger, msg  │  ──► git tag -d v1.0 ──► ✗ removed
                                       └──────────────┘
                                       ┌──────────────┐
  git tag -s v2.0 -m "Release" ───────►│ v2.0 (obj)   │
  (GPG signed)                 ───────►│ tagger, msg  │
                                       │ GPG sig      │
                                       └──────────────┘

List / Filter
─────────────────
  git tag                         v1.0
                                  v1.1
                                  v2.0

  git tag -l "v1.*"               v1.0
                                  v1.1

  git tag -n                      v1.0        Release 1.0
                                  v1.1        Release 1.1

  git tag --sort=-v:refname       v2.10.0
                                  v2.5.0
                                  v1.9.0

Push / Delete Remote
─────────────────
  Local                                Remote
  v1.0 ── git push origin v1.0 ────►  v1.0
  v1.1 ── git push --tags ─────────►  v1.1
  v2.0 ── git push origin v2.0 ────►  v2.0

  git push --delete origin v1.0 ───►  (removed from remote)
  git push origin :refs/tags/v1.0 ──► (removed from remote)
```
