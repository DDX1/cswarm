# cswarm — commands & skills reference

global slash commands and skills available in every claude code session.

---

## ▸ swarm orchestration

Divide large missions across parallel Claude workers using git worktrees + tmux.

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/swarm-init` | `"mission description"` | Analyze the project, ask clarifying questions, propose task breakdown, create `.swarm/` structure and `AGENT.md` |
| `/swarm-spec` | *(optional)* task to refine | Deep-dive the codebase and generate detailed spec files in `.swarm/specs/` — one per worker |
| `/swarm-launch` | *(none)* | Create git worktrees, open tmux session, start a Claude worker in each pane running a Ralph loop |
| `/swarm-status` | *(none)* | Report each worker's status: ✅ Done / 🟡 Working / 🔴 Blocked / ⚪ Stalled |
| `/swarm-merge` | *(none)* | Review diffs and merge completed worker branches one-by-one into the current branch |
| `/swarm-stop` | *(none)* | Kill the tmux swarm session with options to clean up worktrees and branches |
| `/swarm-test` | *(none)* | Spawn a dedicated QA agent that opens the live app in a browser, verifies every merged spec's acceptance criteria at localhost:3000 (desktop) and localhost:8081 (mobile), and returns a pass/fail report |
| `/swarm-commit` | *(none)* | Gather all commits from merged worker branches, group by task, and generate a single structured push-ready commit message summarising the entire mission |

### typical workflow

```
/swarm-init "Build the full vouchers and promotions feature"
/swarm-spec
/swarm-launch

tmux attach -t swarm        # watch workers in real time
Ctrl+B + arrows             # switch between worker panes
Ctrl+B + z                  # zoom into one pane
Ctrl+B + d                  # detach (swarm keeps running)

/swarm-status               # check progress without attaching
/swarm-merge                # pull in completed branches
/swarm-test                 # QA the merged result in the browser
/swarm-commit               # generate structured commit, then push
/swarm-stop                 # halt if workers still running
```

### infrastructure

| File | Purpose |
|------|---------|
| `~/.cswarm/scripts/launch-swarm.sh` | Creates worktrees, configures stop hooks, opens tmux |
| `~/.cswarm/scripts/ralph-stop-hook.sh` | Ralph loop engine — re-injects prompt until worker signals completion |
| `~/.cswarm/scripts/worker-status.sh` | Parses git logs + state files to determine worker status |
| `~/.cswarm/scripts/merge-workers.sh` | Clean `--no-ff` merge with conflict detection |
| `~/.cswarm/scripts/setup.sh` | Re-run anytime to verify the full install |
| `~/.cswarm/templates/AGENT.md.template` | Template for new project agent instructions |
| `~/.cswarm/templates/spec.md.template` | Template for per-task spec files |
| `~/.cswarm/templates/PROMPT.md.template` | Template for worker mission prompts |
| `~/.cswarm/templates/worker-settings.json` | Stop hook config written into each worktree |

---

## ▸ ralph wiggum (single-session loop)

Run a self-correcting Claude loop in the current session — no extra processes needed.
Each iteration sees its own previous work and improves incrementally.

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/ralph-loop` | `"task" [--max-iterations N] [--completion-promise TEXT]` | Start a Ralph loop in the current session |
| `/cancel-ralph` | *(none)* | Cancel the active Ralph loop |
| `/ralph-wiggum:help` | *(none)* | Explain the Ralph technique and show available commands |

### examples

```
/ralph-loop "Fix the token refresh in auth.ts" --completion-promise "FIXED" --max-iterations 10
/ralph-loop "Add TypeScript types to all files in src/features/vouchers/"
/cancel-ralph
```

### how it works

```
while task not complete:
    Claude reads PROMPT.md
    Claude works on files
    Claude tries to stop
    Stop hook intercepts → re-injects prompt
    Claude sees its previous commits
    Iterates toward completion
```

Completion is signalled by Claude outputting: `<promise>YOUR_TEXT</promise>`

---

## ▸ utilities

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/commit` | *(none)* | Analyze all git changes and generate a structured commit message |
| `/keybindings-help` | *(none)* | Customize keyboard shortcuts and chord bindings in `~/.claude/keybindings.json` |

---

## ▸ notes

- **Slash commands** are `.md` files in `~/.claude/commands/` — edit them to tune behaviour
- **Arguments** are passed as a string after the command name — quotes are optional
- **Re-run setup** anytime: `bash ~/.cswarm/scripts/setup.sh`
- **Add a new command**: create `~/.claude/commands/my-command.md` — available immediately in all sessions

---

## ▸ further reading

- Ralph Wiggum technique: https://ghuntley.com/ralph/
- Ralph Orchestrator (community): https://github.com/mikeyobrien/ralph-orchestrator
- Claude Code docs: https://docs.anthropic.com/en/docs/claude-code
