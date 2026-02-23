#!/usr/bin/env bash
# install.sh — Install cswarm into ~/.claude/
#
# Usage:
#   git clone https://github.com/DDX1/cswarm.git ~/.cswarm && ~/.cswarm/install.sh
#   ./install.sh              Install (with preview)
#   ./install.sh --yes        Install without confirmation
#   ./install.sh --check      Verify installation
#   ./install.sh --uninstall  Remove cswarm

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
REPO_URL="https://github.com/DDX1/cswarm.git"
INSTALL_DIR="$HOME/.cswarm"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/swarm-$(date +%Y%m%d-%H%M%S)"

# Also clean up legacy paths from older versions
LEGACY_DIR="$HOME/.claude-swarm"

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
  echo "  ┌─────────────────────────────────────┐"
  echo "  │  cswarm v${VERSION}                       │"
  echo "  │  parallel agents, one slash command  │"
  echo "  └─────────────────────────────────────┘"
  printf "${NC}"
  echo ""
}

# ── Help ─────────────────────────────────────────────────────────────────────
if [ "$MODE" = "help" ]; then
  banner
  echo "  Usage:"
  echo "    install.sh              Install cswarm (shows preview first)"
  echo "    install.sh --yes        Install without confirmation prompt"
  echo "    install.sh --check      Verify installation"
  echo "    install.sh --uninstall  Remove cswarm"
  echo ""
  exit 0
fi

# ── Uninstall ────────────────────────────────────────────────────────────────
if [ "$MODE" = "uninstall" ]; then
  banner
  step "Removing cswarm..."

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

  # Remove legacy directory symlinks (pre-v1.1.0 install locations)
  for link in "$CLAUDE_DIR/swarm/scripts" "$CLAUDE_DIR/swarm/templates"; do
    if [ -L "$link" ]; then
      rm "$link"
      ok "Removed legacy $link"
      REMOVED=$((REMOVED + 1))
    fi
  done
  rmdir "$CLAUDE_DIR/swarm" 2>/dev/null || true

  # Remove legacy ~/.claude-swarm symlink (v1.x path)
  if [ -L "$LEGACY_DIR" ]; then
    rm "$LEGACY_DIR"
    ok "Removed legacy $LEGACY_DIR"
    REMOVED=$((REMOVED + 1))
  fi

  # Remove primary path symlink
  if [ -L "$INSTALL_DIR" ]; then
    rm "$INSTALL_DIR"
    ok "Removed $INSTALL_DIR"
    REMOVED=$((REMOVED + 1))
  fi

  if [ $REMOVED -eq 0 ]; then
    info "No cswarm symlinks found. Nothing to remove."
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
  ok "cswarm uninstalled. Project .swarm/ directories are untouched."
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
      ok "/$cmd -> $(readlink "$target")"
    elif [ -f "$target" ]; then
      warn "/$cmd exists but is not a symlink"
      ERRORS=$((ERRORS + 1))
    else
      fail "/$cmd not found"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Check primary path symlink
  if [ -L "$INSTALL_DIR" ] && [ -e "$INSTALL_DIR" ]; then
    ok "~/.cswarm -> $(readlink "$INSTALL_DIR")"
  elif [ -d "$INSTALL_DIR" ]; then
    ok "~/.cswarm (directory)"
  else
    fail "~/.cswarm not found — scripts and templates won't be found"
    ERRORS=$((ERRORS + 1))
  fi

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
      git)    warn "$tool not found -> xcode-select --install (macOS) or apt install git" ;;
      tmux)   warn "$tool not found — required for /swarm-launch"
              TMUX_MISSING=1 ;;
      claude) warn "$tool not found -> npm install -g @anthropic-ai/claude-code" ;;
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
    info "Cloning cswarm..."
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

if [ "$SOURCE_DIR" != "$INSTALL_DIR" ] && [ ! -L "$INSTALL_DIR" ]; then
  printf "    ${GREEN}+${NC} ~/.cswarm -> $SOURCE_DIR  ${DIM}(primary path — required)${NC}\n"
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
printf "    ${DIM}o${NC} skills/commit-msg  ${DIM}— run: ln -sfn $SOURCE_DIR/skills/commit-msg ~/.claude/skills/commit-msg${NC}\n"
printf "    ${DIM}o${NC} config/COMMANDS.md ${DIM}— command reference doc${NC}\n"
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

# Primary path symlink ~/.cswarm -> source dir (required for swarm operations)
if [ "$SOURCE_DIR" != "$INSTALL_DIR" ]; then
  ln -sfn "$SOURCE_DIR" "$INSTALL_DIR"
  ok "~/.cswarm -> $SOURCE_DIR"
fi

# Clean up legacy ~/.claude-swarm symlink if it exists
if [ -L "$LEGACY_DIR" ]; then
  rm "$LEGACY_DIR"
  ok "Removed legacy ~/.claude-swarm symlink"
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

if [ -L "$INSTALL_DIR" ] && [ -e "$INSTALL_DIR" ]; then
  ok "~/.cswarm -> $(readlink "$INSTALL_DIR")"
elif [ -d "$INSTALL_DIR" ]; then
  ok "~/.cswarm"
else
  fail "~/.cswarm — not found"
  VERIFY_OK=0
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
if [ $VERIFY_OK -eq 1 ]; then
  printf "${BOLD}${GREEN}"
  echo "  ┌──────────────────────────────────────────┐"
  echo "  │                                          │"
  echo "  │  cswarm installed                        │"
  echo "  │                                          │"
  echo "  │  quick start:                            │"
  echo "  │    1. open any project in claude code    │"
  echo "  │    2. /swarm-init \"your mission\"         │"
  echo "  │    3. /swarm-spec                        │"
  echo "  │    4. /swarm-launch                      │"
  echo "  │                                          │"
  echo "  │  update:  cd ~/.cswarm && git pull       │"
  echo "  │  verify:  ~/.cswarm/install.sh --check   │"
  echo "  │  remove:  ~/.cswarm/install.sh --uninstall│"
  echo "  │                                          │"
  echo "  └──────────────────────────────────────────┘"
  printf "${NC}"
else
  fail "Installation completed with errors. Run with --check for details."
fi
echo ""
