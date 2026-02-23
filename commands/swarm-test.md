# /swarm-test — Integration Test the Swarm's Merged Work

Spin up a dedicated test agent that verifies everything the swarm built actually works
end-to-end — in the browser, across all merged features, against the live running app.

$ARGUMENTS

---

## Step 1: Build the Test Plan from Merged Specs

Read the following to understand what was built:
- `.swarm/state.json` — which workers ran and were merged
- `.swarm/specs/*.md` — the acceptance criteria for each task (these ARE the test cases)
- `AGENT.md` — how to run the app (dev server commands, ports)

If no merged workers are found in state, tell the user:
> No merged swarm work found. Run `/swarm-merge` first, then `/swarm-test`.

Extract from each merged spec:
- The **Objective** (what the feature does)
- The **Acceptance Criteria** (the exact test cases)
- The **files created/modified** (so you know what UI to look for)

Show the user the compiled test plan:
```
Test Plan — <N> features to verify
──────────────────────────────────
Feature 1: <task name>  →  <N> test cases
Feature 2: <task name>  →  <N> test cases
...

Apps to test:
  • localhost:3000  (desktop, admin/web app)
  • localhost:8081  (mobile dimensions)
```

## Step 2: Verify Apps Are Running

Automatically check both servers before proceeding:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081
```

- **Both up** → proceed to testing immediately, no confirmation needed
- **One or both down** → tell the user which server is not running, show the start command from `AGENT.md`, and **wait** until they confirm it's up before continuing

---

## Step 3: Spawn a Dedicated Test Agent

Use the Task tool to launch a general-purpose test agent with this instruction:

> You are a QA agent testing a web application after a parallel development swarm completed its work.
> You have access to browser tools. Test systematically and report precisely.
>
> **Test Plan:**
> [paste the full compiled test plan here — all features, all acceptance criteria]
>
> **Apps:**
> - Desktop: http://localhost:3000
> - Mobile: http://localhost:8081 (test at 390x844 viewport — iPhone 14 dimensions)
>
> **For each acceptance criterion:**
> 1. Navigate to the relevant screen or section
> 2. Perform the action that exercises the criterion
> 3. Record: PASS ✅ / FAIL ❌ / BLOCKED ⚠ (couldn't test — explain why)
>
> **Specifically test:**
> - Page load: does it render without errors or blank screens?
> - Navigation: do all links and tabs work?
> - Create flow: use any new forms to create a database entry — does it save and appear?
> - Edit flow: open an existing entry, modify it, save — does it persist?
> - Delete flow: delete an entry — is it removed from the list?
> - Mobile view at localhost:8081: do the same flows work at mobile dimensions?
> - Cross-check: create on desktop → verify it appears on mobile view (and vice versa)
>
> **Return a structured test report** with:
> - Pass/fail per acceptance criterion
> - Screenshot descriptions of any failures
> - Overall verdict: SHIP IT / NEEDS FIXES

---

## Step 4: Display the Test Report

Once the test agent returns, display the full report clearly:

```
SWARM TEST REPORT
══════════════════════════════════════════════════════
Feature: <task-name>
  ✅ <criterion> — PASS
  ❌ <criterion> — FAIL: <what happened>
  ✅ <criterion> — PASS

Feature: <task-name>
  ✅ <criterion> — PASS
  ✅ <criterion> — PASS

══════════════════════════════════════════════════════
Result: X/Y criteria passed

VERDICT: ✅ SHIP IT  /  ❌ NEEDS FIXES
```

---

## Step 5: On Failures

For each failing criterion, provide:
1. Which spec file owns it (`.swarm/specs/<task-slug>.md`)
2. Which worker branch introduced the change (`worker/<task-slug>`)
3. A suggested fix approach based on the spec's Technical Guidance

Ask the user:
> "Would you like me to fix these failures directly, or open the relevant worker branch for inspection?"
