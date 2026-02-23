#!/usr/bin/env bash
# install.sh — Install Claude Swarm into ~/.claude/
#
# Usage:
#   git clone https://github.com/USER/claude-swarm.git ~/.claude-swarm && ~/.claude-swarm/install.sh
#   ./install.sh              Install (with preview)
#   ./install.sh --yes        Install without confirmation
#   ./install.sh --check      Verify installation
#   ./install.sh --uninstall  Remove Claude Swarm

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────────────
info()    { printf "${BLUE}   info${NC}  %s\n" "$1"; }
ok()      { printf "${GREEN}     ok${NC}  %s\n" "$1"; }
warn()    { printf "${YELLOW}   warn${NC}  %s\n" "$1"; }
fail()    { printf "${RED}   fail${NC}  %s\n" "$1"; }
step()    { printf "\n${BOLD}  %s${NC}\n" "$1"; }

# ── Constants ────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/USER/claude-swarm.git"
INSTALL_DIR="$HOME/.claude-swarm"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/swarm-$(date +%Y%m%d-%H%M%S)"

# ── What gets installed (single source of truth) ─────────────────────────────
SWARM_COMMANDS=(swarm-init swarm-spec swarm-launch swarm-status swarm-merge swarm-stop swarm-test swarm-commit)

# ── Parse arguments ─────────────────────────────────────────────────────────
MODE="install"
AUTO_YES=0
for arg in "$@"; do
  case "$arg" in
    --check)     MODE="check" ;;
    --uninstall) MODE="uninstall" ;;
    --yes|-y)    AUTO_YES=1 ;;
    --help|-h)   MODE="help" ;;
  esac
done

# ── Determine repo root ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ -f "$SCRIPT_DIR/VERSION" ] && [ -d "$SCRIPT_DIR/commands" ]; then
  SOURCE_DIR="$SCRIPT_DIR"
else
  SOURCE_DIR="$INSTALL_DIR"
fi

VERSION="0.0.0"
if [ -f "$SOURCE_DIR/VERSION" ]; then
  VERSION=$(cat "$SOURCE_DIR/VERSION")
fi

# ── Banner ───────────────────────────────────────────────────────────────────
banner() {
  echo ""
  printf "${BOLD}"
  echo "  ┌──────────────────────────────────────────┐"
  echo "  │                                          │"
  echo "  │          Claude Swarm v${VERSION}             │"
  echo "  │   Parallel agents, one slash command.    │"
  echo "  │                                          │"
  echo "  └──────────────────────────────────────────┘"
  printf "${NC}"
  echo ""
}

# ── Help ─────────────────────────────────────────────────────────────────────
if [ "$MODE" = "help" ]; then
  banner
  echo "  Usage:"
  echo "    install.sh              Install Claude Swarm (shows preview first)"
  echo "    install.sh --yes        Install without confirmation prompt"
  echo "    install.sh --check      Verify installation"
  echo "    install.sh --uninstall  Remove Claude Swarm"
  echo ""
  exit 0
fi

# ── Uninstall ────────────────────────────────────────────────────────────────
if [ "$MODE" = "uninstall" ]; then
  banner
  step "Removing Claude Swarm..."

  REMOVED=0

  # Remove command symlinks
  for cmd in "${SWARM_COMMANDS[@]}"; do
    target="$CLAUDE_DIR/commands/${cmd}.md"
    if [ -L "$target" ]; then
      rm "$target"
      ok "Removed $target"
      REMOVED=$((REMOVED + 1))
    fi
  done

  # Remove directory symlinks
  for link in "$CLAUDE_DIR/swarm/scripts" "$CLAUDE_DIR/swarm/templates"; do
    if [ -L "$link" ]; then
      rm "$link"
      ok "Removed $link"
      REMOVED=$((REMOVED + 1))
    fi
  done

  # Remove convenience symlink
  if [ -L "$INSTALL_DIR" ]; then
    rm "$INSTALL_DIR"
    ok "Removed $INSTALL_DIR"
    REMOVED=$((REMOVED + 1))
  fi

  if [ $REMOVED -eq 0 ]; then
    info "No Claude Swarm symlinks found. Nothing to remove."
  else
    ok "Removed $REMOVED symlinks."
  fi

  # Check for backup to restore
  LATEST_BACKUP=$(ls -dt "$CLAUDE_DIR/backups/swarm-"* 2>/dev/null | head -1 || true)
  if [ -n "$LATEST_BACKUP" ] && [ -d "$LATEST_BACKUP" ]; then
    echo ""
    printf "  Restore backup from ${DIM}$(basename "$LATEST_BACKUP")${NC}? [y/N] "
    read -r RESTORE </dev/tty 2>/dev/null || RESTORE="n"
    if [[ "$RESTORE" =~ ^[Yy]$ ]]; then
      cp -r "$LATEST_BACKUP"/* "$CLAUDE_DIR/" 2>/dev/null || true
      ok "Backup restored."
    fi
  fi

  echo ""
  ok "Claude Swarm uninstalled. Project .swarm/ directories are untouched."
  echo ""
  exit 0
fi

# ── Check mode ───────────────────────────────────────────────────────────────
if [ "$MODE" = "check" ]; then
  banner
  step "Verifying installation..."

  ERRORS=0

  # Check command symlinks
  for cmd in "${SWARM_COMMANDS[@]}"; do
    target="$CLAUDE_DIR/commands/${cmd}.md"
    if [ -L "$target" ] && [ -e "$target" ]; then
      ok "/$cmd → $(readlink "$target")"
    elif [ -f "$target" ]; then
      warn "/$cmd exists but is not a symlink"
      ERRORS=$((ERRORS + 1))
    else
      fail "/$cmd not found"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check directory symlinks
  for link in "$CLAUDE_DIR/swarm/scripts" "$CLAUDE_DIR/swarm/templates"; do
    if [ -L "$link" ] && [ -e "$link" ]; then
      ok "$(basename "$(dirname "$link")")/$(basename "$link") → $(readlink "$link")"
    else
      fail "$link not found or broken"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check prerequisites
  echo ""
  step "Prerequisites..."
  for tool in git tmux claude; do
    if command -v "$tool" &>/dev/null; then
      ok "$tool ($(command -v "$tool"))"
    else
      warn "$tool not found"
    fi
  done

  echo ""
  if [ $ERRORS -eq 0 ]; then
    ok "All checks passed."
  else
    fail "$ERRORS issue(s) found."
  fi
  echo ""
  exit $ERRORS
fi

# ══════════════════════════════════════════════════════════════════════════════
# ── Install mode ─────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════

banner

# ── Step 1: Check prerequisites ──────────────────────────────────────────────
step "Checking prerequisites..."

PREREQ_OK=1
TMUX_MISSING=0

for tool in git tmux claude; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool ($(command -v "$tool"))"
  else
    case "$tool" in
      git)    warn "$tool not found → xcode-select --install (macOS) or apt install git" ;;
      tmux)   warn "$tool not found — required for /swarm-launch"
              TMUX_MISSING=1 ;;
      claude) warn "$tool not found → npm install -g @anthropic-ai/claude-code" ;;
    esac
    PREREQ_OK=0
  fi
done

# Offer to install tmux if missing (the only unusual dependency)
if [ $TMUX_MISSING -eq 1 ]; then
  CAN_INSTALL=""
  if command -v brew &>/dev/null; then
    CAN_INSTALL="brew"
  elif command -v apt-get &>/dev/null; then
    CAN_INSTALL="apt"
  fi

  if [ -n "$CAN_INSTALL" ]; then
    echo ""
    printf "  tmux is required for parallel workers. Install it now? [Y/n] "
    read -r INSTALL_TMUX </dev/tty 2>/dev/null || INSTALL_TMUX="y"
    if [[ ! "$INSTALL_TMUX" =~ ^[Nn]$ ]]; then
      case "$CAN_INSTALL" in
        brew) brew install tmux ;;
        apt)  sudo apt-get install -y tmux ;;
      esac
      if command -v tmux &>/dev/null; then
        ok "tmux installed ($(command -v tmux))"
        TMUX_MISSING=0
      else
        fail "tmux installation failed"
      fi
    fi
  else
    info "Install tmux manually: brew install tmux (macOS) or apt install tmux (Linux)"
  fi
fi

if [ $PREREQ_OK -eq 0 ] && [ $TMUX_MISSING -eq 1 ]; then
  warn "tmux is missing. Swarm commands will be installed, but /swarm-launch won't work until tmux is available."
fi

# ── Step 2: Get the source ──────────────────────────────────────────────────
step "Setting up source..."

if [ "$SOURCE_DIR" = "$INSTALL_DIR" ]; then
  # Need to clone
  if [ -d "$INSTALL_DIR/.git" ]; then
    info "Found existing clone at $INSTALL_DIR"
    cd "$INSTALL_DIR" && git pull --quiet
    ok "Updated to latest version"
  else
    info "Cloning claude-swarm..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    ok "Cloned to $INSTALL_DIR"
  fi
  SOURCE_DIR="$INSTALL_DIR"
else
  ok "Using local source: $SOURCE_DIR"
fi

# Re-read version from source
if [ -f "$SOURCE_DIR/VERSION" ]; then
  VERSION=$(cat "$SOURCE_DIR/VERSION")
fi

# ── Step 3: Preview what will happen ─────────────────────────────────────────
step "Install preview..."

echo ""
printf "  ${BOLD}Symlinks to create in ~/.claude/:${NC}\n"
WILL_CREATE=0
WILL_BACKUP=0
ALREADY_OK=0

for cmd in "${SWARM_COMMANDS[@]}"; do
  target="$CLAUDE_DIR/commands/${cmd}.md"
  src="$SOURCE_DIR/commands/${cmd}.md"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    ALREADY_OK=$((ALREADY_OK + 1))
  elif [ -e "$target" ] && [ ! -L "$target" ]; then
    printf "    ${YELLOW}~${NC} commands/${cmd}.md  ${DIM}(existing file will be backed up)${NC}\n"
    WILL_BACKUP=$((WILL_BACKUP + 1))
    WILL_CREATE=$((WILL_CREATE + 1))
  else
    printf "    ${GREEN}+${NC} commands/${cmd}.md\n"
    WILL_CREATE=$((WILL_CREATE + 1))
  fi
done

for pair in "scripts:swarm/scripts" "templates:swarm/templates"; do
  src_name="${pair%%:*}"
  dst_rel="${pair##*:}"
  target="$CLAUDE_DIR/$dst_rel"
  src="$SOURCE_DIR/$src_name"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
    ALREADY_OK=$((ALREADY_OK + 1))
  elif [ -e "$target" ] && [ ! -L "$target" ]; then
    printf "    ${YELLOW}~${NC} ${dst_rel}/  ${DIM}(existing dir will be backed up)${NC}\n"
    WILL_BACKUP=$((WILL_BACKUP + 1))
    WILL_CREATE=$((WILL_CREATE + 1))
  else
    printf "    ${GREEN}+${NC} ${dst_rel}/\n"
    WILL_CREATE=$((WILL_CREATE + 1))
  fi
done

if [ "$SOURCE_DIR" != "$INSTALL_DIR" ] && [ ! -L "$INSTALL_DIR" ]; then
  printf "    ${GREEN}+${NC} ~/.claude-swarm → $SOURCE_DIR  ${DIM}(convenience symlink)${NC}\n"
  WILL_CREATE=$((WILL_CREATE + 1))
fi

if [ $ALREADY_OK -gt 0 ]; then
  printf "    ${DIM}($ALREADY_OK symlink(s) already correct — no change)${NC}\n"
fi

echo ""
if [ $WILL_BACKUP -gt 0 ]; then
  printf "  ${YELLOW}Existing files will be backed up to:${NC}\n"
  printf "    ${DIM}$BACKUP_DIR${NC}\n"
  echo ""
fi

printf "  ${BOLD}Not installed${NC} ${DIM}(available in repo if you want them):${NC}\n"
printf "    ${DIM}○${NC} skills/commit-msg  ${DIM}— run: ln -sfn $SOURCE_DIR/skills/commit-msg ~/.claude/skills/commit-msg${NC}\n"
printf "    ${DIM}○${NC} config/COMMANDS.md ${DIM}— command reference doc${NC}\n"
echo ""

# Ask for confirmation unless --yes
if [ $WILL_CREATE -eq 0 ]; then
  ok "Already installed — nothing to do."
  echo ""
  exit 0
fi

if [ $AUTO_YES -eq 0 ]; then
  printf "  Proceed with install? [Y/n] "
  read -r CONFIRM </dev/tty 2>/dev/null || CONFIRM="y"
  if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    info "Cancelled."
    echo ""
    exit 0
  fi
fi

# ── Step 4: Create target directories ───────────────────────────────────────
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/swarm"

# ── Step 5: Backup existing files ───────────────────────────────────────────
BACKED_UP=0

backup_if_real() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    local rel="${target#$CLAUDE_DIR/}"
    local backup_path="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$backup_path")"
    mv "$target" "$backup_path"
    info "Backed up: $rel"
    BACKED_UP=$((BACKED_UP + 1))
  fi
}

for cmd in "${SWARM_COMMANDS[@]}"; do
  backup_if_real "$CLAUDE_DIR/commands/${cmd}.md"
done
backup_if_real "$CLAUDE_DIR/swarm/scripts"
backup_if_real "$CLAUDE_DIR/swarm/templates"

# ── Step 6: Create symlinks ─────────────────────────────────────────────────
step "Installing..."

LINKED=0
SKIPPED=0

create_link() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [ -L "$dst" ]; then
    local existing
    existing=$(readlink "$dst")
    if [ "$existing" = "$src" ]; then
      SKIPPED=$((SKIPPED + 1))
      return
    fi
    rm "$dst"
  fi

  ln -sfn "$src" "$dst"
  ok "$label"
  LINKED=$((LINKED + 1))
}

# Command files (individual symlinks — safe, won't touch non-swarm commands)
for cmd in "${SWARM_COMMANDS[@]}"; do
  create_link "$SOURCE_DIR/commands/${cmd}.md" "$CLAUDE_DIR/commands/${cmd}.md" "/$cmd"
done

# Directory symlinks for scripts and templates
create_link "$SOURCE_DIR/scripts"   "$CLAUDE_DIR/swarm/scripts"   "swarm/scripts/"
create_link "$SOURCE_DIR/templates" "$CLAUDE_DIR/swarm/templates" "swarm/templates/"

# Convenience symlink ~/.claude-swarm → source dir (for updates and uninstall)
if [ "$SOURCE_DIR" != "$INSTALL_DIR" ]; then
  ln -sfn "$SOURCE_DIR" "$INSTALL_DIR"
  ok "~/.claude-swarm → $SOURCE_DIR"
fi

if [ $SKIPPED -gt 0 ]; then
  info "$SKIPPED symlink(s) already correct — skipped"
fi

# ── Step 7: Handle CLAUDE.md ────────────────────────────────────────────────
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  if [ -f "$SOURCE_DIR/config/CLAUDE.md.example" ]; then
    cp "$SOURCE_DIR/config/CLAUDE.md.example" "$CLAUDE_DIR/CLAUDE.md"
    ok "Created ~/.claude/CLAUDE.md from example template"
  fi
else
  info "~/.claude/CLAUDE.md already exists — not modified"
fi

# ── Step 8: Make scripts executable ─────────────────────────────────────────
chmod +x "$SOURCE_DIR/scripts/"*.sh

# ── Step 9: Verify ──────────────────────────────────────────────────────────
step "Verifying..."

VERIFY_OK=1
for cmd in "${SWARM_COMMANDS[@]}"; do
  target="$CLAUDE_DIR/commands/${cmd}.md"
  if [ -L "$target" ] && [ -e "$target" ]; then
    ok "/$cmd"
  else
    fail "/$cmd — symlink broken"
    VERIFY_OK=0
  fi
done

for link in "$CLAUDE_DIR/swarm/scripts" "$CLAUDE_DIR/swarm/templates"; do
  name="$(basename "$(dirname "$link")")/$(basename "$link")"
  if [ -L "$link" ] && [ -e "$link" ]; then
    ok "$name"
  else
    fail "$name — symlink broken"
    VERIFY_OK=0
  fi
done

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
if [ $VERIFY_OK -eq 1 ]; then
  printf "${BOLD}${GREEN}"
  echo "  ┌──────────────────────────────────────────────────┐"
  echo "  │                                                  │"
  echo "  │          Claude Swarm installed! ✓               │"
  echo "  │                                                  │"
  echo "  ├──────────────────────────────────────────────────┤"
  echo "  │                                                  │"
  echo "  │  Quick start:                                    │"
  echo "  │    1. Open any project in Claude Code            │"
  echo "  │    2. /swarm-init \"your mission\"                 │"
  echo "  │    3. /swarm-spec                                │"
  echo "  │    4. /swarm-launch                              │"
  echo "  │                                                  │"
  echo "  ├──────────────────────────────────────────────────┤"
  echo "  │                                                  │"
  echo "  │  Update:   cd ~/.claude-swarm && git pull        │"
  echo "  │  Verify:   ~/.claude-swarm/install.sh --check    │"
  echo "  │  Remove:   ~/.claude-swarm/install.sh --uninstall│"
  echo "  │                                                  │"
  echo "  │  Extras:                                         │"
  echo "  │   commit skill: see README for opt-in install    │"
  echo "  │   command ref:  cat ~/.claude-swarm/config/COMMANDS.md│"
  echo "  │                                                  │"
  echo "  └──────────────────────────────────────────────────┘"
  printf "${NC}"
else
  fail "Installation completed with errors. Run with --check for details."
fi
echo ""
