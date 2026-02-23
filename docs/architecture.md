# Architecture

## Overview

Claude Swarm orchestrates parallel Claude Code instances using three core technologies:
- **Git worktrees** for file isolation
- **tmux** for session management
- **Ralph Wiggum stop hooks** for autonomous looping

## Worker lifecycle

```
launch-swarm.sh
  ├── git worktree add -b worker/<slug>
  ├── Copy AGENT.md, PROMPT.md, specs into worktree
  ├── Configure .claude/settings.json with stop hook
  ├── Write completion signal to .claude/.ralph-worker-active
  └── Start Claude in tmux pane

Worker loop (per Claude instance):
  ├── Read PROMPT.md → orient → implement → commit
  ├── Claude tries to stop
  ├── ralph-stop-hook.sh intercepts
  │   ├── Check .claude/.worker-done → allow stop
  │   ├── Check git log for completion signal → allow stop
  │   └── Neither found → re-inject PROMPT.md (exit code 2)
  └── Repeat until complete or blocked
```

## State machine

Each worker progresses through these states:

| State | How detected | Source |
|-------|-------------|--------|
| `ready` | Spec created, not yet launched | `.swarm/state.json` |
| `launching` | Worktree created, tmux pane starting | `.swarm/state.json` |
| `WORKING` | Recent commits, no completion signal | `worker-status.sh` (inferred) |
| `COMPLETE` | `.claude/.worker-done` contains completion signal | `worker-status.sh` |
| `BLOCKED` | `.claude/.worker-done` contains "BLOCKED" or `BLOCKERS.md` exists | `worker-status.sh` |
| `STALLED` | No commits in 20+ minutes | `worker-status.sh` (inferred) |
| `merged` | Branch successfully merged into main branch | `.swarm/state.json` |
| `stopped` | tmux session killed before completion | `.swarm/state.json` |

## File isolation model

Workers are scoped through their spec files:

- **Files to Create** — new files the worker creates
- **Files to Modify** — existing files to change
- **Read for Patterns** — reference files (read-only)
- **Off-Limits** — files the worker must never touch

The spec is the worker's contract. If two specs list the same file under "Modify", the swarm will likely produce merge conflicts — this is caught during `/swarm-spec` validation.

## Script reference

| Script | Purpose | Called by |
|--------|---------|-----------|
| `launch-swarm.sh` | Create worktrees, open tmux, start Claude | `/swarm-launch` |
| `ralph-stop-hook.sh` | Stop hook — re-inject prompt if not complete | Claude's stop event |
| `worker-status.sh` | Report single worker status | `/swarm-status`, `/swarm-merge` |
| `merge-workers.sh` | Merge one worker branch with `--no-ff` | `/swarm-merge` |
| `setup.sh` | Verify prerequisites and file structure | Manual / post-install |

## Stop hook protocol

The Ralph stop hook (`ralph-stop-hook.sh`) uses Claude Code's hook system:

- **Exit code 0** — allow Claude to stop normally
- **Exit code 2** — block the stop, feed stdout back as a new user message

The hook checks three things in order:
1. Is `.claude/.ralph-worker-active` present? (If not, allow stop)
2. Is `.claude/.worker-done` present? (If yes, allow stop)
3. Is the completion signal in git log? (If yes, allow stop)
4. Otherwise, re-inject `PROMPT.md` contents and block the stop

## Template system

Templates in `templates/` are used by the slash commands (not the scripts) to generate per-project files:

| Template | Generated as | When |
|----------|-------------|------|
| `AGENT.md.template` | `AGENT.md` in project root | `/swarm-init` |
| `spec.md.template` | `.swarm/specs/<slug>.md` | `/swarm-spec` |
| `PROMPT.md.template` | `.swarm/prompts/<slug>-PROMPT.md` | `/swarm-launch` |
| `worker-settings.json` | `.claude/settings.json` in each worktree | `launch-swarm.sh` |
