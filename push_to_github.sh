#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/Users/kimaalanzi/Desktop/aaldma/aldlma"
REMOTE_URL="https://github.com/kkkrraamm/aldlma.git"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) not found. Installing via Homebrew..."
  if command -v brew >/dev/null 2>&1; then
    brew install gh
  else
    echo "Homebrew not found. Please install gh manually: https://cli.github.com/" && exit 1
  fi
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Logging in to GitHub (opens browser)..."
  gh auth login --hostname github.com --git-protocol https --web
fi

echo "Preparing repo at $REPO_DIR"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

if [ ! -d .git ]; then
  git init
fi

git add .
if ! git diff --cached --quiet; then
  git commit -m "chore: project state with dalma-api"
fi

git branch -M main || true

# Try to set remote, or create if missing
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

# Create the remote repo if it doesn't exist
if ! gh repo view kkkrraamm/aldlma >/dev/null 2>&1; then
  echo "Creating private repo kkkrraamm/aldlma on GitHub..."
  gh repo create kkkrraamm/aldlma --private --source . --remote origin --disable-wiki --disable-issues
fi

echo "Pushing to GitHub..."
git push -u origin main

echo "Done."
