# /swarm-status — Check Swarm Worker Progress

Report the current status of all swarm workers without attaching to the tmux session.

$ARGUMENTS

---

## Step 1: Read State

Read `.swarm/state.json` to get the list of workers and their worktree paths.

If the state file does not exist or `workers` is empty, tell the user:
> No active swarm found. Run `/swarm-init` to start a new mission.

## Step 2: Check Each Worker

For each worker in the state file, run:
```bash
bash ~/.claude-swarm/scripts/worker-status.sh "<worktree-path>" "<task-slug>"
```

Also check if the tmux session is running:
```bash
tmux list-panes -t swarm 2>/dev/null | wc -l
```

## Step 3: Display Status Table

Show a summary table:

```
SWARM STATUS — <mission from state.json>
────────────────────────────────────────────────────────
 Worker          Status      Last Commit              Notes
────────────────────────────────────────────────────────
 task-slug-1    ✅ Done     "feat: add voucher card"  2m ago
 task-slug-2    🟡 Working  "feat: wip - types"       5m ago
 task-slug-3    🔴 Blocked  "fix: attempt 2"          12m ago · see BLOCKERS.md
────────────────────────────────────────────────────────
 tmux session: active (3 panes)
```

Status indicators:
- ✅ **Done** — completion signal found in `.claude/.worker-done`
- 🟡 **Working** — no completion signal, recent commits visible
- 🔴 **Blocked** — blocked signal found or `BLOCKERS.md` exists
- ⚪ **Stalled** — no commits in 15+ minutes, no completion signal (may need human intervention)
- ❓ **Unknown** — worktree path not found on disk

## Step 4: Recommendations

Based on status, give specific next-step guidance:

- If **all done**: "All workers complete! Run `/swarm-merge` to merge branches."
- If **some done**: "Workers X and Y are ready. Run `/swarm-merge` to merge completed ones while others continue."
- If **any blocked**: "Worker X is blocked. Read `../<repo>-worker-<slug>/BLOCKERS.md` and decide whether to unblock manually or re-assign the task."
- If **any stalled**: "Worker X has had no commits for a while. Attach to check: `tmux attach -t swarm` then `Ctrl+B <pane number>`"
- If **tmux session dead but workers incomplete**: "tmux session ended. Re-launch with `/swarm-launch` — workers will resume from their last commit."
