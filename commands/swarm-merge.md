# /swarm-merge — Merge Completed Worker Branches

Merge completed worker branches back into the current branch, one at a time with review.

$ARGUMENTS

---

## Step 1: Identify Completed Workers

Read `.swarm/state.json` and check the completion status of each worker:
```bash
bash ~/.claude-swarm/scripts/worker-status.sh "<worktree-path>" "<task-slug>"
```

If none are complete, tell the user:
> No workers have completed yet. Run `/swarm-status` for a progress update.

If there are completed workers, list them and **proceed to merge all of them automatically** — do not ask for confirmation:
> Merging N completed worker(s) into `<current-branch>`...

## Step 2: Merge Each Completed Worker

Work through them **one at a time**, automatically:

### 2a. Show a brief diff summary
```bash
git diff HEAD...worker/<task-slug> --stat
```
Show the one-line stat summary (N files, N insertions, N deletions). Do NOT offer to show the full diff.

### 2b. Merge
```bash
git merge --no-ff worker/<task-slug> -m "feat: merge worker/<task-slug>

Swarm task: <objective from spec>
Worker branch: worker/<task-slug>"
```

### 2c. Handle conflicts (STOP and ask only here)
If the merge fails due to conflicts:
1. Show the conflicting files: `git diff --name-only --diff-filter=U`
2. Tell the user which files conflict
3. Ask: "Resolve conflicts manually then run `/swarm-merge` again, or abort this merge? (resolve/abort)"
4. If abort: `git merge --abort`
5. Do NOT attempt to resolve conflicts automatically — conflicts need human judgment
6. **Stop processing remaining workers** — conflicts must be resolved first

### 2d. Post-merge verification
After a successful merge, run any available build/test command from `AGENT.md` and report the result.

## Step 3: Update State

After each successful merge, update `.swarm/state.json` — set that worker's status to `"merged"`.

## Step 4: Auto-Cleanup

After all merges complete successfully, **automatically clean up merged workers** without asking:

For each merged worker:
```bash
# Remove the worktree (no longer needed — code is merged)
git worktree remove --force ../<repo>-worker-<slug>

# Delete the worker branch (already merged via --no-ff)
git branch -d worker/<slug>
```

Report what was cleaned up. If any cleanup step fails, warn but continue with the rest.

## Step 5: Summary

Report:
> ✓ Merge complete:
> - ✅ Merged and cleaned up: task-slug-1, task-slug-2
> - ⏳ Still running: task-slug-3
>
> Run `/swarm-status` to monitor remaining workers.
