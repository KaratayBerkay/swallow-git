# .gitkeep Cleanup Rule

`.gitkeep` files exist only to keep empty directories tracked by Git.

**Rule:** Whenever a directory gains at least 2 meaningful entries (files or subdirectories), remove its `.gitkeep`.

### Why

- `.gitkeep` is a placeholder — once real content exists, it's clutter.
- Keeping stale `.gitkeep` files around makes it harder to spot truly empty directories.

### How

```bash
# Manual check
find <dir> -name '.gitkeep' -exec sh -c 'test -f "$(dirname {})/how2.md" && rm -v "{}"' \;

# General cleanup — remove .gitkeep from any dir with 3+ total entries
find . -name '.gitkeep' -exec sh -c \
  'd=$(dirname "$1"); count=$(ls -1q "$d" | wc -l); [ "$count" -ge 3 ] && rm -v "$1"' _ {} \;
```

### Example

```
commands/git-add/
├── .gitkeep     ← Remove this (how2.md exists)
└── how2.md

scenarios/
├── .gitkeep     ← Remove this (instructions.md + step-thru/ exist)
├── instructions.md
└── step-thru/
```
