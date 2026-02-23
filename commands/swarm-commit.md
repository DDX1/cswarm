# /swarm-commit — Generate a Comprehensive Swarm Commit

Summarize all changes from the swarm's merged worker branches into a single structured,
push-ready commit message. Covers every task, every file, with full context.

$ARGUMENTS

---

## Step 1: Read Swarm Context

- Read `.swarm/state.json` — get the list of merged workers and their task slugs
- Read `.swarm/mission.md` — the overall mission description
- Read each `.swarm/specs/<task-slug>.md` — the objective for each worker

If no merged workers found, tell the user:
> No merged work to commit. Complete `/swarm-merge` first.

---

## Step 2: Gather All Changes

Find the base commit before any worker work was merged:
```bash
git merge-base HEAD main 2>/dev/null || git log --oneline | tail -1 | awk '{print $1}'
```

Get the full diff stat from base to HEAD:
```bash
git diff <base-commit>...HEAD --stat
```

Get all commits introduced since the base:
```bash
git log <base-commit>..HEAD --oneline --reverse
```

Group commits by worker branch using the merge commit messages:
```bash
git log <base-commit>..HEAD --merges --oneline
```

---

## Step 3: Analyze Changes Per Task

For each merged worker:
1. Find its merge commit: `git log --oneline --merges | grep "worker/<task-slug>"`
2. List its commits: `git log <merge-base>..<merge-commit> --oneline`
3. List its changed files: `git diff <merge-base>..<merge-commit> --name-status`
4. Cross-reference with the spec's **Objective** and **Acceptance Criteria**

Build a mental model: what did this task actually deliver vs what was planned?

---

## Step 4: Generate the Commit Message

Compose a structured commit message using this format:

```
feat(<scope>): <mission title — concise, imperative, max 72 chars>

## Mission
<1-2 sentences from .swarm/mission.md describing the overall goal>

## Changes by Task

### <Task Name> (`worker/<slug>`)
<Objective from spec — one sentence>
- <key file created/modified>: <what it does>
- <key file created/modified>: <what it does>

### <Task Name> (`worker/<slug>`)
<Objective from spec — one sentence>
- <key file created/modified>: <what it does>

## Files Changed
<N files changed, N insertions(+), N deletions(-)>

## Test Status
<Paste verdict from /swarm-test if available, or "untested — run /swarm-test">

Co-Authored-By: Claude <noreply@anthropic.com>
```

Show the full commit message to the user for review.

---

## Step 5: Commit Automatically

Show the full commit message for reference, then **commit immediately** without asking:

```bash
git add -A
git commit -m "<the generated message>"
```

After the commit succeeds, show:
```
✓ Committed: <short hash> <first line of message>

Ready to push:
  git push origin <current-branch>

Or open a PR:
  gh pr create --title "<mission title>" --body "..."
```

Do NOT push automatically — show the commands and let the user decide.

---

## Step 7: Update Swarm State

Update `.swarm/state.json`:
- Set top-level `"status"` to `"committed"`
- Record the commit hash: `"commit": "<hash>"`
