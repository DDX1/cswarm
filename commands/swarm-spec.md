# /swarm-spec — Create Worker Spec Files

You are creating detailed specification files for each task in the active swarm mission.
Each spec becomes the authoritative instruction set for one isolated worker agent.

$ARGUMENTS

---

## Step 1: Read Mission State

- Read `.swarm/mission.md` — the approved task breakdown and constraints
- Read `AGENT.md` — project context and conventions
- List files in `.swarm/specs/` to see if specs already exist

If `.swarm/mission.md` does not exist, stop and tell the user:
> Run `/swarm-init "<mission description>"` first to initialize the swarm.

## Step 2: Explore the Codebase

For each task in the mission, explore the relevant areas of the codebase:
- Use Glob to find relevant files for each task's domain
- Read key files to understand existing patterns, types, and component structure
- Identify which files need to be created vs modified
- Note any existing partial implementations to avoid duplication

## Step 3: Create Spec Files

For each task, create `.swarm/specs/<task-slug>.md` using this exact template:

```markdown
# Task: <Human-Readable Task Name>

## Objective
<2-3 sentences. What exactly must be accomplished. Be specific — vague objectives produce vague results.>

## Scope

### Create These Files
- `<path/to/new-file.ts>` — <purpose>

### Modify These Files
- `<path/to/existing-file.ts>` — <what specifically to add or change>

### Read for Patterns (do not modify)
- `<path/to/reference-file.ts>` — <what pattern to copy from here>

### Off-Limits (never touch)
- `<path>` — <reason why>

## Context
<Essential background this worker needs:>
- <Relevant data types/interfaces already defined>
- <API contracts or function signatures to follow>
- <Existing patterns to replicate>
- <What adjacent code already does that this task must connect to>

## Acceptance Criteria
- [ ] <Specific, testable criterion — concrete enough to verify without ambiguity>
- [ ] <Specific, testable criterion>
- [ ] <Specific, testable criterion>
- [ ] No TypeScript errors in scope files
- [ ] Follows existing code patterns (no new libraries introduced without explicit approval)

## Technical Guidance
<Specific implementation hints:>
- Use `<ExistingComponent>` as the base pattern for new components
- Data comes from `<source>` — the type is `<TypeName>` defined in `<file>`
- Follow the pattern in `<reference-file>` exactly
- <Any gotchas or non-obvious constraints>

## Dependencies
- **Requires output from**: none / `<other-task-slug>`: specifically needs `<what>`
- **Provides to**: none / `<other-task-slug>`: exports `<what>`

## Completion Signal
When **all acceptance criteria are met**, output:
`<promise><TASK_SLUG>_COMPLETE</promise>`

If blocked and unable to continue, write details to `BLOCKERS.md` then output:
`<promise><TASK_SLUG>_BLOCKED</promise>`
```

## Step 4: Interactive Refinement

After creating all spec files, show a summary:

| Task Slug | Objective | Files to Create | Files to Modify | Dependencies |
|-----------|-----------|-----------------|-----------------|--------------|

Then ask:
> "Review these specs. Tell me which to refine, or say 'looks good' to proceed to launch."

If user requests changes, update the relevant spec files.

## Step 5: Dependency Validation

Check for problems:
- **Circular dependencies** — warn if task A needs task B and vice versa
- **File conflicts** — warn if two tasks modify the same file (redesign needed)
- **Scope gaps** — warn if parts of the mission are uncovered by any spec

## Step 6: Update State

Update `.swarm/state.json` — add a `workers` array:
```json
"workers": [
  { "slug": "task-slug", "status": "ready", "branch": "worker/task-slug", "worktree": null }
]
```

## Completion

Tell the user:
> ✓ Specs created in `.swarm/specs/`. Review them — these are the exact instructions each worker will follow.
>
> **Next:** Run `/swarm-launch` to create git worktrees and start the parallel worker swarm.
