#!/usr/bin/env bash
# uninstall.sh — Remove Claude Swarm from ~/.claude/
#
# This is a convenience wrapper. You can also run:
#   ~/.claude-swarm/install.sh --uninstall

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
exec "$SCRIPT_DIR/install.sh" --uninstall
