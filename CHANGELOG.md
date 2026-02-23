# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-02-23

### Added

- Native Claude Code plugin support (`claude plugin install claude-swarm`)
- `.claude-plugin/plugin.json` manifest and marketplace config
- `hooks/hooks.json` — SessionStart hook auto-creates `~/.claude-swarm` symlink in plugin mode
- Scripts now self-discover their root via `BASH_SOURCE` (install-method agnostic)

### Changed

- All script/template paths now use `~/.claude-swarm/` as the canonical root (was `~/.claude/swarm/`)
- `install.sh` no longer creates `~/.claude/swarm/scripts` or `~/.claude/swarm/templates` symlinks
- `~/.claude-swarm` symlink promoted from convenience to required path
- Uninstall mode cleans up legacy `~/.claude/swarm/` symlinks from v1.0.0

## [1.0.0] - 2026-02-23

### Added

- 8 slash commands: `/swarm-init`, `/swarm-spec`, `/swarm-launch`, `/swarm-status`, `/swarm-merge`, `/swarm-stop`, `/swarm-test`, `/swarm-commit`
- 5 orchestration scripts: `launch-swarm.sh`, `ralph-stop-hook.sh`, `worker-status.sh`, `merge-workers.sh`, `setup.sh`
- 4 worker templates: `AGENT.md.template`, `PROMPT.md.template`, `spec.md.template`, `worker-settings.json`
- `commit-msg` skill for structured git commit messages
- One-liner install with symlinks (`install.sh`)
- Uninstall and verification modes (`--uninstall`, `--check`)
- Idempotent installation with automatic backup of existing files
- Documentation: architecture, customization, troubleshooting
