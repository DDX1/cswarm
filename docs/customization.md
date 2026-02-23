# Customization

## Editing commands

Commands are markdown files in `commands/`. Each file is a prompt that Claude executes when you type the corresponding slash command.

To modify a command's behavior, edit the `.md` file directly. Changes take effect immediately — no restart needed.

### Command structure

Every command follows this pattern:

```markdown
# /command-name — Short description

Context and role-setting for Claude.

$ARGUMENTS

---

## Step 1: Do something
Instructions for Claude...

## Step 2: Do something else
More instructions...

## Completion
Final message to the user.
```

`$ARGUMENTS` is replaced with whatever text the user types after the command name.

## Editing templates

Templates in `templates/` control what gets generated for each project. They use placeholder syntax (`<angle brackets>`) that Claude fills in based on project analysis.

| Template | Edit to change... |
|----------|-------------------|
| `AGENT.md.template` | Project context structure given to workers |
| `PROMPT.md.template` | Worker mission prompt and working protocol |
| `spec.md.template` | Task specification format and sections |
| `worker-settings.json` | Stop hook configuration (rarely needs changing) |

## Editing scripts

Scripts in `scripts/` are bash. Key things you might want to change:

### launch-swarm.sh
- `SESSION="swarm"` — change the tmux session name
- `sleep 1` (line ~140) — increase stagger delay between worker launches if you hit API rate limits
- The `claude` invocation seed message — change what Claude reads first

### ralph-stop-hook.sh
- The re-injection message format (lines ~43-51)
- How many git log entries to check for completion (line ~30, currently 20)

### worker-status.sh
- Stall threshold: `MINUTES_SINCE -gt 20` — adjust the timeout before a worker is considered stalled

## Adding new commands

1. Create `commands/my-command.md`
2. Follow the structure above
3. Run `install.sh` (only needed if you didn't install via symlinks)
4. Use `/my-command` in any Claude Code session

## Changing the commit skill

Edit `skills/commit-msg/SKILL.md` to change the commit message format, conventions, or analysis steps.

## Global Claude config

Your `~/.claude/CLAUDE.md` file contains instructions that apply to every Claude Code session. This is separate from Claude Swarm — the installer never overwrites it.

See `config/CLAUDE.md.example` for suggested additions when using the swarm system.
