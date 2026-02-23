# Troubleshooting

## Common issues

### tmux session won't start

**Symptoms:** `/swarm-launch` fails with "tmux not found" or hangs.

**Solutions:**
- Install tmux: `brew install tmux` (macOS) or `apt install tmux` (Linux)
- Kill any existing swarm session: `tmux kill-session -t swarm`
- Check for zombie sessions: `tmux list-sessions`

### Workers stop immediately

**Symptoms:** Workers launch but exit within seconds without doing any work.

**Solutions:**
- Verify the stop hook is configured. Check `templates/worker-settings.json` contains the Stop hook entry pointing to `ralph-stop-hook.sh`
- Ensure `scripts/ralph-stop-hook.sh` is executable: `chmod +x ~/.cswarm/scripts/ralph-stop-hook.sh`
- Check that `.claude/.ralph-worker-active` was written in the worktree

### Workers keep looping without progress

**Symptoms:** Worker has been running for a long time with few or no commits.

**Solutions:**
- Attach to tmux and check: `tmux attach -t swarm`, then `Ctrl+B` + arrow to the pane
- Check if the worker is stuck on a prompt or error
- If Claude is asking a question, it cannot proceed — stop the swarm and refine the spec

### Merge conflicts

**Symptoms:** `/swarm-merge` reports conflicts.

**Solutions:**
- This usually means two workers modified the same file. Resolve manually with standard git conflict resolution
- For future runs: redesign your task breakdown to give each worker exclusive file ownership
- The `/swarm-spec` command validates for file conflicts — pay attention to its warnings

### "No active swarm found"

**Symptoms:** `/swarm-status` says no swarm exists.

**Solutions:**
- Check that `.swarm/state.json` exists in your project root
- Verify the `workers` array is populated (it's empty after `/swarm-init`, populated after `/swarm-spec`)
- Run `/swarm-init` if starting fresh

### Worktree directory not found

**Symptoms:** `/swarm-status` shows "MISSING" for a worker.

**Solutions:**
- Worktrees live at `../<repo-name>-worker-<slug>` relative to your project
- They may have been cleaned up. Re-run `/swarm-launch` to recreate them
- Check with `git worktree list` to see all active worktrees

### Install symlinks are broken

**Symptoms:** Commands don't work after moving the repo.

**Solutions:**
- Run `~/.cswarm/install.sh --check` to see which links are broken
- Re-run `~/.cswarm/install.sh` to fix them
- If you moved the repo, the `~/.cswarm` symlink needs updating

## Diagnostics

### Verify installation
```bash
~/.cswarm/install.sh --check
```

### Check tmux session
```bash
tmux list-sessions
tmux list-panes -t swarm
```

### Check worktrees
```bash
git worktree list
```

### Check a specific worker's state
```bash
bash ~/.cswarm/scripts/worker-status.sh "../<repo>-worker-<slug>" "<slug>"
```

### Check stop hook registration
```bash
cat <worktree>/.claude/settings.json
```

## Windows

cswarm requires bash, tmux, and symlinks — none are available natively on Windows.

**Use WSL (Windows Subsystem for Linux):**

```bash
# install WSL if you haven't already
wsl --install

# inside WSL, install prerequisites
sudo apt install git tmux
npm install -g @anthropic-ai/claude-code

# then install cswarm normally
git clone https://github.com/DDX1/cswarm.git ~/.cswarm && ~/.cswarm/install.sh
```

Run `claude` from inside WSL. The swarm commands, tmux sessions, and worktrees all work unchanged in the WSL environment.

## Getting help

Open an issue at the GitHub repository with:
1. Your OS and version
2. Output of `~/.cswarm/install.sh --check`
3. The error message or unexpected behavior
4. Steps to reproduce
