---
name: commit-msg
description: Analyze all git changes and generate a comprehensive, structured, professional commit message
argument-hint: "[optional: additional context]"
---

# Git Commit Message Generator

Generate a comprehensive, structured, and professional git commit message by analyzing all staged and unstaged changes.

## Instructions

1. **Gather Git Information** - Run these commands in parallel:
   - `git status` to see all modified, added, and deleted files
   - `git diff --stat` to see a summary of changes
   - `git diff` to see the actual code changes (unstaged)
   - `git diff --cached` to see staged changes
   - `git log --oneline -5` to understand recent commit style

2. **Analyze the Changes**
   - Identify the type of change (feat, fix, refactor, style, docs, test, chore, perf, build, ci)
   - Determine the scope (which module/feature/component is affected)
   - Understand the impact and purpose of the changes
   - Note any breaking changes

3. **Generate Commit Message** following this structure:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Format Rules:

**Type** (required): One of:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring (no functional change)
- `style`: Formatting, missing semicolons, etc.
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependencies
- `perf`: Performance improvements
- `build`: Build system changes
- `ci`: CI/CD changes

**Scope** (optional but recommended): The module, component, or feature affected

**Subject** (required):
- Imperative mood ("Add" not "Added" or "Adds")
- No period at the end
- Max 50 characters
- Lowercase first letter

**Body** (required for non-trivial changes):
- Explain WHAT changed and WHY
- Wrap at 72 characters
- Use bullet points for multiple changes
- Reference related issues if applicable

**Footer** (optional):
- Breaking changes: `BREAKING CHANGE: <description>`
- Issue references: `Closes #123`, `Fixes #456`

4. **Present the Commit Message**

Display the generated commit message in a code block and ask the user if they want to:
- Use this message as-is
- Modify the message
- Stage specific files first
- Cancel

5. **User Provided Context**

If the user provides additional context via $ARGUMENTS, incorporate it into the commit message analysis.

## Example Output

```
feat(auth): Add OAuth2 social login support

- Implement Google and GitHub OAuth providers
- Add token refresh mechanism with automatic retry
- Create user session management with secure cookies
- Add login/logout UI components with loading states

This enables users to sign in with their existing social accounts,
reducing friction in the onboarding flow.

Closes #142
```

## Important Notes

- Do NOT automatically commit - always propose and wait for user approval
- If there are no changes to commit, inform the user
- If changes span multiple unrelated features, suggest splitting into multiple commits
- Highlight any sensitive files (like .env) that should NOT be committed
- Consider the project's existing commit history style when generating messages
