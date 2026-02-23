# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
