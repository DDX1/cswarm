#!/bin/bash
# setup.sh — Install Claude Code Swarm infrastructure
#
# Run once after cloning or setting up on a new machine:
#   bash ~/.claude-swarm/scripts/setup.sh

set -euo pipefail

# ── Resolve swarm root via BASH_SOURCE ────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWARM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMANDS_DIR="$HOME/.claude/commands"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Code Swarm — Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Verify core tools ─────────────────────────────────────────────────────
echo "Checking prerequisites..."

check() {
  if command -v "$1" &>/dev/null; then
    echo "  ✓ $1 ($(command -v "$1"))"
  else
    echo "  ✗ $1 not found → $2"
    MISSING=1
  fi
}

MISSING=0
check git    "install via: xcode-select --install"
check tmux   "install via: brew install tmux"
check claude "install via: npm install -g @anthropic/claude-code"

if [ "${MISSING:-0}" -eq 1 ]; then
  echo ""
  echo "⚠ Some prerequisites are missing. Install them and re-run this script."
  echo ""
fi

echo ""

# ── Make scripts executable ───────────────────────────────────────────────
echo "Making scripts executable..."
for script in "$SWARM_ROOT"/scripts/*.sh; do
  if [ -f "$script" ]; then
    chmod +x "$script"
    echo "  ✓ $(basename "$script")"
  fi
done

echo ""

# ── Verify commands are in place ──────────────────────────────────────────
echo "Verifying slash commands..."
COMMANDS=(swarm-init swarm-spec swarm-launch swarm-status swarm-merge swarm-stop)
for cmd in "${COMMANDS[@]}"; do
  if [ -f "$COMMANDS_DIR/${cmd}.md" ]; then
    echo "  ✓ /$cmd"
  else
    echo "  ✗ /$cmd  (missing: $COMMANDS_DIR/${cmd}.md)"
  fi
done

echo ""

# ── Verify templates are in place ────────────────────────────────────────
echo "Verifying templates..."
TEMPLATES=(AGENT.md.template spec.md.template PROMPT.md.template worker-settings.json)
for tpl in "${TEMPLATES[@]}"; do
  if [ -f "$SWARM_DIR/templates/$tpl" ]; then
    echo "  ✓ $tpl"
  else
    echo "  ✗ $tpl  (missing: $SWARM_DIR/templates/$tpl)"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup complete."
echo ""
echo "  Workflow:"
echo "    1. /swarm-init \"your mission\"  — define the mission + task breakdown"
echo "    2. /swarm-spec                  — generate detailed spec files per task"
echo "    3. /swarm-launch                — start the parallel worker swarm"
echo "    4. /swarm-status                — monitor worker progress"
echo "    5. /swarm-merge                 — merge completed branches"
echo "    6. /swarm-stop                  — halt the swarm"
echo ""
echo "  tmux quick reference:"
echo "    tmux attach -t swarm    — attach to the running swarm"
echo "    Ctrl+B + arrows         — switch between worker panes"
echo "    Ctrl+B + z              — zoom/unzoom a pane"
echo "    Ctrl+B + d              — detach (swarm keeps running)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
