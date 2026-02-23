#!/bin/bash
# Ralph Wiggum Stop Hook for Swarm Workers
#
# Runs when a worker Claude instance is about to stop.
# If the worker has not yet fulfilled its completion signal,
# this hook re-injects PROMPT.md to continue the Ralph loop.
#
# Exit code 2 + stdout content = block stop, feed content back to Claude
# Exit code 0 = allow Claude to stop normally

LOOP_ACTIVE_FILE=".claude/.ralph-worker-active"
WORKER_DONE_FILE=".claude/.worker-done"
PROMPT_FILE="PROMPT.md"

# ── No active loop → let Claude stop ──────────────────────────────────────────
if [ ! -f "$LOOP_ACTIVE_FILE" ]; then
  exit 0
fi

# ── Worker already signaled completion → let Claude stop ──────────────────────
if [ -f "$WORKER_DONE_FILE" ]; then
  DONE_CONTENT=$(cat "$WORKER_DONE_FILE" 2>/dev/null)
  echo "✓ Worker loop complete: $DONE_CONTENT"
  rm -f "$LOOP_ACTIVE_FILE"
  exit 0
fi

# ── Check git log for completion signal ───────────────────────────────────────
EXPECTED_SIGNAL=$(cat "$LOOP_ACTIVE_FILE" 2>/dev/null)
if [ -n "$EXPECTED_SIGNAL" ] && git log --oneline -20 2>/dev/null | grep -qF "$EXPECTED_SIGNAL"; then
  echo "✓ Worker loop complete: $EXPECTED_SIGNAL found in git history"
  rm -f "$LOOP_ACTIVE_FILE"
  exit 0
fi

# ── No PROMPT.md → can't continue, let Claude stop ────────────────────────────
if [ ! -f "$PROMPT_FILE" ]; then
  echo "Warning: No PROMPT.md found in $(pwd). Worker stopping."
  exit 0
fi

# ── Loop is active and not complete → re-inject the prompt ────────────────────
echo "━━━ Ralph Loop: Re-injecting worker mission ━━━"
echo ""
echo "You have not yet completed your task. Your progress so far:"
echo ""
git log --oneline -5 2>/dev/null | sed 's/^/  ✓ /' || echo "  (no commits yet)"
echo ""
echo "Continue working on your mission:"
echo ""
cat "$PROMPT_FILE"

# Exit code 2 signals Claude Code to treat stdout as a new user message
exit 2
