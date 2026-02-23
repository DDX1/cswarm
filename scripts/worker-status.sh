#!/bin/bash
# worker-status.sh — Report the status of a single swarm worker
#
# Usage: worker-status.sh <worktree-path> <task-slug>
# Output: STATUS|last-commit-message (time-ago)|notes
#
# STATUS values: COMPLETE | BLOCKED | WORKING | STALLED | MISSING

WORKER_DIR="${1:?Usage: worker-status.sh <worktree-path> <task-slug>}"
TASK_SLUG="${2:?Missing task-slug}"

# ── Worker directory not found ─────────────────────────────────────────────
if [ ! -d "$WORKER_DIR" ]; then
  echo "MISSING|Directory not found: $WORKER_DIR|"
  exit 0
fi

cd "$WORKER_DIR"

# ── Read git info ──────────────────────────────────────────────────────────
LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "no commits yet")
LAST_COMMIT_TIME=$(git log -1 --format="%ar" 2>/dev/null || echo "unknown")
LAST_COMMIT_EPOCH=$(git log -1 --format="%at" 2>/dev/null || echo "0")
NOW_EPOCH=$(date +%s)
MINUTES_SINCE=$(( (NOW_EPOCH - LAST_COMMIT_EPOCH) / 60 ))

# Count commits on this branch vs its parent
COMMIT_COUNT=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')

# ── Check completion file ──────────────────────────────────────────────────
if [ -f ".claude/.worker-done" ]; then
  DONE_SIGNAL=$(cat ".claude/.worker-done" 2>/dev/null)
  if echo "$DONE_SIGNAL" | grep -qi "BLOCKED"; then
    BLOCKERS=""
    if [ -f "BLOCKERS.md" ]; then
      BLOCKERS="$(head -3 BLOCKERS.md | tr '\n' ' ')"
    fi
    echo "BLOCKED|$LAST_COMMIT ($LAST_COMMIT_TIME)|$BLOCKERS"
  else
    echo "COMPLETE|$LAST_COMMIT ($LAST_COMMIT_TIME)|$COMMIT_COUNT commits"
  fi
  exit 0
fi

# ── Check git log for completion signal ───────────────────────────────────
COMPLETION_SIGNAL="${TASK_SLUG}_COMPLETE"
BLOCKED_SIGNAL="${TASK_SLUG}_BLOCKED"

if git log --oneline 2>/dev/null | grep -qF "$COMPLETION_SIGNAL"; then
  echo "COMPLETE|$LAST_COMMIT ($LAST_COMMIT_TIME)|$COMMIT_COUNT commits (via git log)"
  exit 0
fi

if git log --oneline 2>/dev/null | grep -qF "$BLOCKED_SIGNAL"; then
  echo "BLOCKED|$LAST_COMMIT ($LAST_COMMIT_TIME)|Check BLOCKERS.md"
  exit 0
fi

# ── Check for BLOCKERS.md ──────────────────────────────────────────────────
if [ -f "BLOCKERS.md" ]; then
  echo "BLOCKED|$LAST_COMMIT ($LAST_COMMIT_TIME)|BLOCKERS.md found"
  exit 0
fi

# ── Check if stalled (no commits in 20+ minutes) ──────────────────────────
if [ "$LAST_COMMIT_EPOCH" -gt 0 ] && [ "$MINUTES_SINCE" -gt 20 ]; then
  echo "STALLED|$LAST_COMMIT ($LAST_COMMIT_TIME)|No activity for ${MINUTES_SINCE}m"
  exit 0
fi

# ── Still working ─────────────────────────────────────────────────────────
echo "WORKING|$LAST_COMMIT ($LAST_COMMIT_TIME)|$COMMIT_COUNT commits"
