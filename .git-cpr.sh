#!/usr/bin/env bash
git add .
changed=$(git diff --cached --name-only)
if [ -z "$changed" ]; then
  echo "nothing to commit"
elif echo "$changed" | grep -qv "\.gitkeep$"; then
  msg=$(git diff --cached --stat | tail -1 | xargs)
  git commit -m "$msg" && git push
else
  git commit -m "chore: add command practice folders" && git push
fi
