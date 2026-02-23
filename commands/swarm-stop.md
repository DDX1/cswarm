# /swarm-stop — Stop All Swarm Workers

Halt all running worker processes and optionally clean up worktrees and branches.

$ARGUMENTS

---

## Step 1: Confirm

Read `.swarm/state.json` to list active workers.

Tell the user what will be stopped:
> This will kill all worker processes in the `swarm` tmux session.
> Workers will stop mid-task — their progress is preserved in their git branches.
>
> Active workers: task-slug-1 (🟡 Working), task-slug-2 (🟡 Working)
>
> **Continue?** (yes/no)

Wait for confirmation. Do not proceed without it.

## Step 2: Kill the tmux Session

```bash
tmux kill-session -t swarm 2>/dev/null && echo "Swarm stopped" || echo "No active swarm session found"
```

## Step 3: Update State

Update `.swarm/state.json`:
- Set top-level `"status"` to `"stopped"`
- For any workers without a `"merged"` or `"complete"` status, set status to `"stopped"`

## Step 4: Report Worker Progress

For each stopped worker, check how far they got:
```bash
bash ~/.claude-swarm/scripts/worker-status.sh "<worktree-path>" "<task-slug>"
```

Show:
> Worker progress at time of stop:
> - task-slug-1: 🟡 Partial — last commit: "feat: add voucher types" (8 commits)
> - task-slug-2: ✅ Done — completion signal found (can be merged)

## Step 5: Preserve Worker State

**Automatically keep all worktrees and branches** — stopped workers may have uncommitted or unmerged work. Do not ask about cleanup.

## Completion

Tell the user:
> ✓ Swarm stopped. All worker branches and worktrees are preserved.
>
> - To merge completed work: `/swarm-merge`
> - To restart from where workers left off: `/swarm-launch` (workers resume from last commit)
> - To clean up manually: `git worktree remove <path>` and `git branch -D worker/<slug>`
> - To start a completely fresh run: delete specs and run `/swarm-init` again
