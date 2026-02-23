#!/bin/bash
# merge-workers.sh — Merge a completed worker branch into the current branch
#
# Usage: merge-workers.sh <project-path> <task-slug> "<objective>"
# Returns: 0 on success, 1 on conflict, 2 on error

PROJECT_PATH="${1:?Usage: merge-workers.sh <project-path> <task-slug> [objective]}"
TASK_SLUG="${2:?Missing task-slug}"
OBJECTIVE="${3:-$TASK_SLUG}"

BRANCH="worker/${TASK_SLUG}"

cd "$PROJECT_PATH"

# ── Verify branch exists ──────────────────────────────────────────────────
if ! git branch --list "$BRANCH" | grep -q "$BRANCH"; then
  echo "✗ Branch '$BRANCH' not found" && exit 2
fi

# ── Show diff stats before merging ───────────────────────────────────────
echo "Diff summary for $BRANCH:"
git diff HEAD..."$BRANCH" --stat 2>/dev/null || echo "(unable to compute diff)"
echo ""

# ── Perform the merge ─────────────────────────────────────────────────────
echo "Merging $BRANCH..."
if git merge --no-ff "$BRANCH" -m "feat: merge $BRANCH

Swarm worker task: $OBJECTIVE
Branch: $BRANCH"; then
  echo "✓ Successfully merged $BRANCH"
  exit 0
else
  echo "✗ Merge conflict in $BRANCH"
  echo ""
  echo "Conflicting files:"
  git diff --name-only --diff-filter=U 2>/dev/null | sed 's/^/  • /'
  echo ""
  echo "Resolve conflicts manually, then run 'git merge --continue'"
  echo "Or abort with: git merge --abort"
  exit 1
fi
