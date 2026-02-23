#!/usr/bin/env bash
# uninstall.sh — Remove cswarm from ~/.claude/
#
# This is a convenience wrapper. You can also run:
#   ~/.cswarm/install.sh --uninstall

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
exec "$SCRIPT_DIR/install.sh" --uninstall
