#!/bin/bash
# launch-swarm.sh — Create git worktrees and start a tmux swarm session
#
# Usage: launch-swarm.sh <project-path> "<task-slug-1> <task-slug-2> ..."
#
# Creates:
#   - One git worktree per task at ../<repo>-worker-<slug>
#   - A tmux session named "swarm" with one pane per worker
#   - Claude running in each pane with the Ralph stop hook configured

set -euo pipefail

PROJECT_PATH="${1:?Usage: launch-swarm.sh <project-path> \"<task-slug-1> <task-slug-2>...\"}"
TASKS_STRING="${2:?No tasks provided}"
IFS=' ' read -ra TASKS <<< "$TASKS_STRING"

REPO_NAME=$(basename "$PROJECT_PATH")
SESSION="swarm"

# ── Resolve swarm root via BASH_SOURCE ────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWARM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKER_SETTINGS_FILE="$SWARM_ROOT/templates/worker-settings.json"

# Resolve absolute path
PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  cswarm launcher"
echo "  Project : $REPO_NAME"
echo "  Workers : ${TASKS[*]}"
echo "  Session : $SESSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Validate prerequisites ──────────────────────────────────────────────────
if ! command -v tmux &>/dev/null; then
  echo "✗ tmux not found. Install: brew install tmux" && exit 1
fi
if ! command -v claude &>/dev/null; then
  echo "✗ claude CLI not found. Install: npm install -g @anthropic/claude-code" && exit 1
fi
if [ ! -f "$WORKER_SETTINGS_FILE" ]; then
  echo "✗ Worker settings template not found at $WORKER_SETTINGS_FILE"
  echo "  Run the setup script: bash $SCRIPT_DIR/setup.sh" && exit 1
fi

# ── Kill any existing swarm session ────────────────────────────────────────
tmux kill-session -t "$SESSION" 2>/dev/null && echo "↻ Killed previous swarm session" || true

# ── Setup each worker worktree ─────────────────────────────────────────────
WORKER_DIRS=()

for TASK in "${TASKS[@]}"; do
  BRANCH="worker/${TASK}"
  WORKER_DIR="${PROJECT_PATH}/../${REPO_NAME}-worker-${TASK}"
  # Resolve to absolute path (portable — works on macOS without GNU coreutils)
  PARENT_DIR="${WORKER_DIR%/*}"
  if [ -d "$PARENT_DIR" ]; then
    WORKER_DIR="$(cd "$PARENT_DIR" && pwd)/${WORKER_DIR##*/}"
  fi
  WORKER_DIRS+=("$WORKER_DIR")

  echo "  Setting up: $TASK → $WORKER_DIR"

  # Remove existing worktree if it exists
  cd "$PROJECT_PATH"
  git worktree remove --force "$WORKER_DIR" 2>/dev/null || true
  git branch -D "$BRANCH" 2>/dev/null || true

  # Create fresh worktree on a new branch
  git worktree add -b "$BRANCH" "$WORKER_DIR"

  # Copy AGENT.md
  if [ -f "$PROJECT_PATH/AGENT.md" ]; then
    cp "$PROJECT_PATH/AGENT.md" "$WORKER_DIR/AGENT.md"
  fi

  # Copy task prompt → PROMPT.md
  PROMPT_SRC="$PROJECT_PATH/.swarm/prompts/${TASK}-PROMPT.md"
  if [ -f "$PROMPT_SRC" ]; then
    cp "$PROMPT_SRC" "$WORKER_DIR/PROMPT.md"
  else
    echo "  ⚠ Warning: No prompt file at $PROMPT_SRC"
    echo "# Worker: $TASK\nRead .swarm-specs/${TASK}.md and complete the task." > "$WORKER_DIR/PROMPT.md"
  fi

  # Copy specs directory so worker can reference them
  if [ -d "$PROJECT_PATH/.swarm/specs" ]; then
    mkdir -p "$WORKER_DIR/.swarm-specs"
    cp "$PROJECT_PATH/.swarm/specs/"*.md "$WORKER_DIR/.swarm-specs/" 2>/dev/null || true
  fi

  # Configure .claude directory with Ralph stop hook
  mkdir -p "$WORKER_DIR/.claude"

  # Write stop hook settings
  cp "$WORKER_SETTINGS_FILE" "$WORKER_DIR/.claude/settings.json"

  # Activate the Ralph loop — file content is the expected completion signal
  echo "${TASK}_COMPLETE" > "$WORKER_DIR/.claude/.ralph-worker-active"

  # Add .claude state files to .gitignore
  if ! grep -q "^\.claude/" "$WORKER_DIR/.gitignore" 2>/dev/null; then
    echo ".claude/" >> "$WORKER_DIR/.gitignore"
  fi

  echo "  ✓ $TASK ready"
done

echo ""

# ── Create tmux session ─────────────────────────────────────────────────────
FIRST_TASK="${TASKS[0]}"
FIRST_DIR="${WORKER_DIRS[0]}"

echo "  Creating tmux session: $SESSION"

# Create session with the first worker's directory
tmux new-session -d -s "$SESSION" -n "workers" -c "$FIRST_DIR"

# Add panes for remaining workers
for i in "${!TASKS[@]}"; do
  [ $i -eq 0 ] && continue
  WORKER_DIR="${WORKER_DIRS[$i]}"
  tmux split-window -t "${SESSION}:0" -c "$WORKER_DIR"
done

# Use tiled layout so all panes are visible and evenly sized
tmux select-layout -t "${SESSION}:0" tiled

# ── Start Claude in each pane ───────────────────────────────────────────────
echo "  Starting workers..."

for i in "${!TASKS[@]}"; do
  TASK="${TASKS[$i]}"
  WORKER_DIR="${WORKER_DIRS[$i]}"

  # Label the pane
  tmux select-pane -t "${SESSION}:0.$i" -T "$TASK"

  # Start Claude with the initial seed message
  SEED="You are a swarm worker. Your task is described in PROMPT.md — read it now and begin immediately. Work through each step, commit incrementally, and output your completion signal when done."

  tmux send-keys -t "${SESSION}:0.$i" "cd '$WORKER_DIR' && claude '$SEED'" Enter

  # Stagger launches slightly to avoid overwhelming the API
  sleep 1
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Swarm launched with ${#TASKS[@]} worker(s)"
echo ""
echo "  Attach:  tmux attach -t $SESSION"
echo "  Switch panes: Ctrl+B + arrow keys"
echo "  Zoom pane:    Ctrl+B + z"
echo "  Detach:       Ctrl+B + d"
echo ""
echo "  Workers:"
for i in "${!TASKS[@]}"; do
  echo "    Pane $i  →  ${TASKS[$i]}  (${WORKER_DIRS[$i]})"
done
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
