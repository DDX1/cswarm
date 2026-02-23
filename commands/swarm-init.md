# /swarm-init — Initialize a Swarm Mission

You are initializing a Claude Code swarm mission using the Ralph Wiggum orchestration technique.
Parallel workers will each handle an independent slice of the work in isolated git worktrees.

**Mission:** $ARGUMENTS

---

## Step 1: Analyze the Project

Read and understand the current project:
- Check for `package.json`, `README.md`, existing `CLAUDE.md` or `AGENT.md`
- Identify the tech stack, key source directories, build/test commands
- Note which files are auto-generated or critical/fragile (should never be touched by workers)

## Step 2: Create Swarm Infrastructure

Create the following in the **current project root**:
- `.swarm/` directory
- `.swarm/specs/` directory
- `.swarm/prompts/` directory
- `.swarm/state.json` with initial content:
  ```json
  {
    "mission": "$ARGUMENTS",
    "status": "planning",
    "created": "<today's date>",
    "branch": "<current git branch>",
    "workers": []
  }
  ```

## Step 3: Create or Review AGENT.md

If `AGENT.md` does not exist in the project root, create it now based on your analysis.
It must contain exactly:

```markdown
# Agent Instructions

## Project
**Name**: <project name>
**Description**: <one-line description>

## Stack
<list key technologies and versions>

## Commands
```bash
# Install
<install command>
# Dev server
<dev command>
# Tests (if available)
<test command or "none configured">
```

## Key Structure
<3-6 most important directories and what they contain>

## Conventions
- Naming: <file/component naming patterns>
- Imports: <import style>
- Styling: <how styles are applied>

## Git
- Branch format: `worker/<task-slug>`
- Commit format: `<type>: <description>` (types: feat, fix, refactor, style)

## Off-Limits
Never modify: <list files/dirs workers must never touch>
```

If `AGENT.md` already exists, read it and note any gaps — do not overwrite unless asked.

## Step 4: Ask Clarifying Questions

Ask the user these questions **all at once** in a numbered list:

1. Which parts of the codebase are **completely off-limits** (workers must never touch)?
2. What does **"done" look like**? What is the acceptance criteria for the overall mission?
3. Are there **technical constraints** workers must follow? (specific libraries, patterns, APIs)
4. How many **parallel workers** should run? (2-4 is optimal for most tasks; max recommended: 6)
5. Should workers **commit their changes**, or just edit files for you to review?

Wait for the user's answers before continuing.

## Step 5: Propose Task Breakdown

Based on the mission, codebase, and user's answers, propose how to divide the work into parallel tasks.

**Rules for good task division:**
- Tasks must touch **different files** — no two workers should modify the same file
- Each task must be **independently completable** — minimal dependencies between workers
- Each task needs a **clear, verifiable end state**
- Prefer 2-4 tasks; more than 6 creates coordination overhead

Show the breakdown as a table:

| # | Task Slug | Objective (one sentence) | Primary Files | Depends On |
|---|-----------|--------------------------|---------------|------------|
| 1 | `task-slug` | What it accomplishes | `src/...` | none |

Then ask: **"Does this breakdown look right? Adjust any tasks before I create the spec files."**

Wait for approval or adjustments.

## Step 6: Save the Plan

Write `.swarm/mission.md` with:
- Mission description
- Agreed task breakdown table
- Constraints and acceptance criteria
- Date, git branch, number of workers

## Completion

Tell the user:
> ✓ Swarm initialized. Specs directory ready at `.swarm/specs/`.
>
> **Next:** Run `/swarm-spec` to create detailed spec files for each task.
> Then `/swarm-launch` to start the worker swarm.
