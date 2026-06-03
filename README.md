# swallow-git

A learning repo for Git practice.

## Git Learning Roadmap: From Beginner to Expert

### Phase 1: Fundamentals
- Repository initialization (`git init`, `git clone`)
- Core workflow: `add`, `commit`, `status`, `log`
- The three areas: working directory, staging area, repository
- Understanding commits (SHA hashes, immutable snapshots)
- Viewing history (`git log --oneline --graph --all`, `git diff`)

### Phase 2: Branching & Merging
- Creating and switching branches (`git branch`, `git switch`, `git checkout`)
- Merging: fast-forward vs three-way merge
- Merge conflict resolution
- Branch naming conventions

### Phase 3: Remotes & Collaboration
- Connecting to remotes (`git remote add`, `git push`, `git pull`, `git fetch`)
- Pull requests and code review workflows
- Fork workflow
- Tracking branches and upstream configuration

### Phase 4: Rewriting History
- `git rebase` — moving commits to a new base
- Interactive rebase (`git rebase -i`) — squash, fixup, reword, reorder, edit, drop
- Golden rule: never rebase shared branches
- `git cherry-pick` — copying specific commits
- `git commit --amend`

### Phase 5: Undoing & Recovery
- `git revert` — safe undo for shared history
- `git reset` — `--soft`, `--mixed`, `--hard`
- `git restore` — discarding/unstaging changes
- `git reflog` — Git's safety net (recover "lost" commits)

### Phase 6: Debugging & Exploration
- `git bisect` — binary search for bugs
- `git blame` — who changed what and when
- `git stash` — temporary work storage
- `git log` advanced filtering (author, date, range, `-S` pickaxe)

### Phase 7: Advanced Techniques
- `git worktree` — work on multiple branches simultaneously
- `git submodule` / `git subtree` — managing dependencies
- Git LFS — large file storage
- `git bundle` — offline transfer
- `git archive` — exporting files without Git metadata

### Phase 8: Automation & Hooks
- Git hooks: pre-commit, commit-msg, pre-push
- Tools: husky, lint-staged
- GitHub Actions — CI/CD automation
- Conventional Commits for automated changelogs

### Phase 9: Team Workflows
- **GitHub Flow** — simple, main is always deployable, short-lived feature branches, PRs
- **Trunk-Based Development** — commit to main or very short branches, feature flags
- **GitFlow** — main, develop, feature/, release/, hotfix/ branches (for versioned releases)
- Choosing the right strategy for your team

### Phase 10: Git Internals
- The .git directory structure
- Objects: blobs, trees, commits, tags
- The DAG (directed acyclic graph) of commits
- SHA-1 vs SHA-256 (Git 3.0)
- Reftable backend
- Plumbing vs porcelain commands

### Essential Commands Cheat Sheet
```
git init          # Initialize a repository
git clone <url>   # Clone a remote repo
git add <file>    # Stage changes
git commit -m ""  # Commit staged changes
git status        # Show working tree status
git log           # View commit history
git diff          # Show unstaged changes
git branch        # List/create branches
git switch -c     # Create and switch to branch
git merge <br>    # Merge a branch
git rebase <br>   # Rebase onto a branch
git push          # Push to remote
git pull          # Pull from remote
git fetch         # Fetch without merging
git stash         # Temporarily save changes
git cherry-pick   # Copy a commit
git bisect        # Binary search for bugs
git reflog        # View HEAD movements
git reset         # Move branch pointer
git revert        # Undo with a new commit
```

### Resources
- [Pro Git Book](https://git-scm.com/book)
- [Git Official Docs](https://git-scm.com/docs)
- [GitHub Skills](https://skills.github.com)
- [Oh My Git!](https://ohmygit.org) — interactive game
