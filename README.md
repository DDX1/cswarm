```
 ██████╗███████╗██╗    ██╗ █████╗ ██████╗ ███╗   ███╗
██╔════╝██╔════╝██║    ██║██╔══██╗██╔══██╗████╗ ████║
██║     ███████╗██║ █╗ ██║███████║██████╔╝██╔████╔██║
██║     ╚════██║██║███╗██║██╔══██║██╔══██╗██║╚██╔╝██║
╚██████╗███████║╚███╔███╔╝██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝
```

**parallel claude code agents, orchestrated through slash commands.**

one `/swarm-init`, one `/swarm-launch`, walk away. come back to merged branches.

---

## ▸ how it works

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  you> /swarm-init "Build auth, dashboard, and API"              │
│       Claude analyzes codebase, proposes 3 tasks                │
│                                                                 │
│  you> /swarm-spec                                               │
│       Claude writes detailed specs per task                     │
│                                                                 │
│  you> /swarm-launch                                             │
│       ┌───────────┬───────────┬───────────┐                     │
│       │ worker 1  │ worker 2  │ worker 3  │  <- tmux panes      │
│       │ auth-ui   │ dashboard │ api-crud  │                     │
│       │ done      │ working   │ working   │                     │
│       └───────────┴───────────┴───────────┘                     │
│       each worker: own git branch + own worktree                │
│       ralph loop keeps them going until done                    │
│                                                                 │
│  you> /swarm-status     <- check progress anytime               │
│  you> /swarm-merge      <- merge completed branches             │
│  you> /swarm-test       <- QA in the browser                    │
│  you> /swarm-commit     <- structured commit message, push      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

each worker is an isolated Claude Code instance running in its own **git worktree** on its own **branch**. workers follow a spec, commit incrementally, and signal when done. a [ralph wiggum](https://ghuntley.com/ralph/) stop hook re-injects the mission prompt each time a worker tries to stop before finishing.

---

## ▸ install

### plugin (recommended)

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│  $ claude plugin marketplace add DDX1/cswarm         │
│  $ claude plugin install cswarm                      │
│                                                      │
└──────────────────────────────────────────────────────┘
```

commands, skills, and hooks load automatically. start a new session for `~/.cswarm` to be configured.

### manual

```bash
$ git clone https://github.com/DDX1/cswarm.git ~/.cswarm && ~/.cswarm/install.sh
```

or from a local clone:

```bash
$ git clone https://github.com/DDX1/cswarm.git ~/projects/cswarm
$ ~/projects/cswarm/install.sh
```

the installer previews what it will do, asks once, then symlinks into `~/.claude/`. existing files are backed up. updates are just `git pull`.

### prerequisites

```
  git     xcode-select --install (macOS) / apt install git
  tmux    brew install tmux (macOS) / apt install tmux
  claude  npm install -g @anthropic-ai/claude-code
```

---

## ▸ commands

```
  /swarm-init    "mission"     analyze project, propose tasks, create .swarm/
  /swarm-spec    [task]        deep-dive codebase, generate per-worker specs
  /swarm-launch                create worktrees + tmux, start claude in each pane
  /swarm-status                report status: done / working / blocked / stalled
  /swarm-merge                 review diffs, merge completed branches one-by-one
  /swarm-stop                  kill tmux session, preserve worker branches
  /swarm-test                  spawn QA agent to verify merged features e2e
  /swarm-commit                generate structured commit for all swarm work
```

### extras (not auto-installed)

```
  commit-msg skill    /commit — structured git commits
                      $ ln -sfn ~/.cswarm/skills/commit-msg ~/.claude/skills/commit-msg

  COMMANDS.md         full command reference
                      $ cat ~/.cswarm/config/COMMANDS.md
```

---

## ▸ quick start

```bash
# open any project in claude code
$ cd ~/my-project && claude

# define the mission
> /swarm-init "Build user auth, admin dashboard, and REST API"

# generate detailed specs
> /swarm-spec

# launch — workers start automatically
> /swarm-launch

# watch workers in real time
$ tmux attach -t swarm
#   ctrl+b arrows  switch panes
#   ctrl+b z       zoom one pane
#   ctrl+b d       detach (swarm keeps running)

# check progress without attaching
> /swarm-status

# merge completed branches
> /swarm-merge

# test everything
> /swarm-test

# generate structured commit
> /swarm-commit

# stop workers if still running
> /swarm-stop
```

---

## ▸ architecture

```
  /swarm-init ──> task breakdown ──> /swarm-spec ──> spec files
                                                         │
                                                    /swarm-launch
                                                         │
                                          ┌──────────────┼──────────────┐
                                          │              │              │
                                      worker 1       worker 2       worker n
                                    claude+ralph   claude+ralph   claude+ralph
                                          │              │              │
                                    worker/task-1  worker/task-2  worker/task-n
                                          │              │              │
                                          └──────────────┼──────────────┘
                                                         │
                                                    /swarm-merge
                                                         │
                                                    /swarm-test
                                                         │
                                                   /swarm-commit
```

> **git worktrees** — each worker gets its own copy of the repo via `git worktree add`. they share the same `.git` but operate in isolated directories. no worker can interfere with another.

> **ralph loop** — when claude tries to stop before completing its task, the stop hook intercepts and re-injects the mission prompt. the worker sees its own previous commits and continues iterating. exits only when the completion signal is found.

> **spec-driven workers** — each worker reads a precise spec with explicit scope (files to create, modify, read, never touch). prevents scope creep and file conflicts.

> **completion signals** — workers signal done by writing to `.claude/.worker-done` and outputting `<promise>TASK_SLUG_COMPLETE</promise>`. the stop hook checks for this before allowing claude to exit.

---

## ▸ repo structure

```
cswarm/
├── .claude-plugin/    plugin manifest + marketplace config
├── commands/          8 slash commands (.md files)
├── scripts/           5 bash orchestration scripts
├── templates/         4 worker configuration templates
├── hooks/             SessionStart hook (plugin mode)
├── skills/            commit-msg skill
├── config/            COMMANDS.md reference, CLAUDE.md example
├── docs/              architecture, customization, troubleshooting
├── install.sh         manual installer (symlinks into ~/.claude/)
└── uninstall.sh       clean removal
```

### what gets installed where

**plugin install** — commands, skills, and hooks load automatically from the plugin cache. a `~/.cswarm` symlink is created on first session for script/template access.

**manual install:**

```
  commands/swarm-*.md  ->  ~/.claude/commands/     one symlink per file
  repo root            ->  ~/.cswarm               primary path for scripts + templates
```

---

## ▸ maintenance

```bash
# update
$ cd ~/.cswarm && git pull

# verify
$ ~/.cswarm/install.sh --check

# uninstall
$ ~/.cswarm/install.sh --uninstall
```

symlinks point to the repo — changes take effect immediately. uninstall removes all symlinks, offers to restore backups, leaves project `.swarm/` directories untouched.

---

## ▸ customization

commands are markdown files — edit them to change behavior. templates control how worker prompts are generated. see [docs/customization.md](docs/customization.md).

---

## ▸ troubleshooting

```
  tmux won't start        check tmux is installed, kill stale sessions:
                           $ tmux kill-session -t swarm

  workers stop instantly   ralph stop hook must be configured — check:
                           $ cat ~/.cswarm/templates/worker-settings.json

  merge conflicts          expected when workers touch same files.
                           redesign task breakdown for better isolation.
```

see [docs/troubleshooting.md](docs/troubleshooting.md) for full diagnostics.

---

## ▸ credits

- [ralph wiggum technique](https://ghuntley.com/ralph/) — geoffrey huntley
- [claude code](https://docs.anthropic.com/en/docs/claude-code) — anthropic
- [ralphy](https://github.com/michaelshimeles/ralphy) — michael shimeles

## ▸ license

[MIT](LICENSE)
