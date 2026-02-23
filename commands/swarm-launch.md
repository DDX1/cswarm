# /swarm-launch — Launch the Worker Swarm

You are launching a Claude Code swarm. This creates one git worktree per task and opens
a tmux session with one Claude Code worker running a Ralph loop in each pane.

$ARGUMENTS

---

## Step 1: Pre-Flight Checks

Run these checks and abort (with a helpful message) if any fail:

1. `.swarm/specs/` exists and contains at least one `.md` file
2. `AGENT.md` exists in the project root
3. Current directory is a git repository (`git status` succeeds)
4. `tmux` is installed (`which tmux`)
5. `claude` CLI is installed (`which claude`)
6. `~/.claude/swarm/scripts/launch-swarm.sh` exists
7. Working tree is not mid-merge or mid-rebase (`git status` should be clean or have only untracked files)

If the working tree has uncommitted changes to tracked files, ask:
> "There are uncommitted changes. Commit or stash them before launching workers? (y/n)"

## Step 2: Read Specs and Generate Worker Prompts

For each file in `.swarm/specs/*.md`:
1. Read the spec file completely
2. Extract the `task-slug` from the filename (e.g., `vouchers-ui` from `vouchers-ui.md`)
3. Generate a worker prompt at `.swarm/prompts/<task-slug>-PROMPT.md` using this template:

```markdown
# Worker Mission: <Task Name>

You are a focused Claude Code agent with one specific task to complete as part of a
parallel development effort. Read your spec carefully. Stay in scope. Commit your work.

## Your Task Spec
@.swarm-specs/<task-slug>.md

## Project Context
@AGENT.md

## Working Protocol

### Before You Write Any Code
1. Read your task spec completely (it is in `.swarm-specs/<task-slug>.md`)
2. Read all files listed under "Read for Patterns"
3. Search before implementing: use grep/glob to check if anything already exists
4. Understand the full picture before touching files

### While Coding
1. Only touch files listed in your spec's Scope section
2. Follow patterns from the reference files exactly — do not invent new patterns
3. Keep changes focused and incremental
4. After each logical unit of work: `git add <specific files> && git commit -m "feat: <what you did>"`

### After Each Change
1. Check for obvious errors (TypeScript types, missing imports)
2. Verify the change matches your acceptance criteria
3. Commit with a descriptive message

### Signaling Completion
When ALL acceptance criteria in your spec are met:
1. Run: `touch .claude/.worker-done && echo "<task-slug>_COMPLETE" > .claude/.worker-done`
2. Output: `<promise><TASK_SLUG>_COMPLETE</promise>`

If you are blocked and cannot continue:
1. Write details to `BLOCKERS.md`: what you tried, what failed, what's needed to unblock
2. Run: `echo "<task-slug>_BLOCKED" > .claude/.worker-done`
3. Output: `<promise><TASK_SLUG>_BLOCKED</promise>`
```

## Step 3: Update State

Update `.swarm/state.json` to set status `"launching"` and record the worktree path for each worker:
```json
{ "slug": "task-slug", "status": "launching", "branch": "worker/task-slug", "worktree": "../<repo>-worker-task-slug" }
```

## Step 4: Launch the Swarm

Run the launch script:
```bash
TASKS=$(ls .swarm/specs/*.md | xargs -I{} basename {} .md | tr '\n' ' ')
bash ~/.claude/swarm/scripts/launch-swarm.sh "$(pwd)" "$TASKS"
```

The script will:
- Create a git worktree for each task at `../<repo-name>-worker-<task-slug>`
- Copy `AGENT.md`, the task prompt, and specs to each worktree
- Configure the Ralph stop hook in each worker's `.claude/settings.json`
- Open a tmux session named `swarm` with one pane per worker (tiled layout)
- Start `claude` in each pane, seeded with the worker's mission

## Step 5: Post-Launch Instructions

Tell the user:
> ✓ Swarm launched with N workers.
>
> **Watch the swarm:**
> ```bash
> tmux attach -t swarm
> ```
> Use `Ctrl+B` + arrow keys to move between worker panes.
> Use `Ctrl+B` + `z` to zoom into a single pane.
>
> **Monitor progress** (without attaching): `/swarm-status`
> **Stop all workers**: `/swarm-stop`
> **Merge completed work**: `/swarm-merge`
>
> Workers will loop automatically via the Ralph stop hook until they output their completion signal.
