# Report Quality Guide

Deep reference for writing high-quality DailyBot progress reports. This file supplements the main skill instructions with detailed writing standards, templates, and rules.

## The Human-First Principle

> AI agents are extensions of the human who orchestrates them.

A person working with an AI agent is amplifying their own productivity. When the agent reports progress, it reports **the human's accomplishment** — because the human decided what to build, assigned the work, and is accountable for the result.

**The reader should never be able to tell whether a human or an agent did the work.** Write every report as if the human is speaking at their daily standup.

## Report Writing Standards

### Sentence Structure

Lead with what was done, then explain why it matters or what it enables:

```
[Action verb] [what was built/fixed/changed] — [impact or purpose].
```

Examples:
- "Implemented notification preferences — users can now choose which alerts they receive via email vs. in-app."
- "Fixed the timezone bug in user profiles — dates now display correctly for all regions."
- "Refactored the payment flow to use idempotency keys — prevents duplicate charges on retry."

### Action Verbs by Work Type

| Work Type | Good Verbs |
|-----------|------------|
| New feature | Implemented, Built, Added, Shipped, Created |
| Bug fix | Fixed, Resolved, Corrected, Patched |
| Refactor | Refactored, Redesigned, Restructured, Simplified, Migrated |
| Tests | Added test coverage, Tested, Verified, Validated |
| Documentation | Documented, Updated docs for, Wrote documentation for |
| Performance | Optimized, Improved, Reduced, Accelerated |
| Configuration | Configured, Set up, Enabled, Integrated |
| Analysis | Analyzed, Investigated, Identified, Mapped out |

### What to Emphasize

**DO emphasize:**
- User-facing outcomes ("users can now...")
- Business value ("prevents duplicate charges...")
- What changed from the user's perspective
- Scope of the work ("12 endpoints", "full test suite")

**DO NOT emphasize:**
- Number of files changed
- Lines of code added/removed
- Internal technical implementation details
- Which tools or libraries were used (unless that IS the deliverable)

## Templates by Work Type

### Feature Implementation
```
Implemented/Built [feature description] — [what it enables or why it matters for users].
```
**Example:** "Implemented notification preferences — users can now choose which alerts they receive via email vs. in-app."

### Bug Fix
```
Fixed [user-facing problem description] — [brief cause or what was going wrong].
```
**Example:** "Fixed an issue where team members in different timezones would see incorrect standup deadlines."

### Refactoring
```
Refactored [component/system] to [improvement] — [benefit or what this enables].
```
**Example:** "Refactored the authentication flow to use JWT tokens — improves session management and enables cross-service auth."

### Test Coverage
```
Added test coverage for [what] — [N test cases / what scenarios are now covered].
```
**Example:** "Added test coverage for the webhook retry system — 12 test cases covering timeout, auth failure, and payload validation scenarios."

### Documentation
```
Documented [topic] — [what readers can now find or understand].
```
**Example:** "Documented the new API rate limiting system — including configuration options, default limits, and troubleshooting."

### Performance / Optimization
```
Optimized [what] — [measurable improvement or user-facing benefit].
```
**Example:** "Optimized the dashboard loading query — page now loads in under 500ms instead of 3 seconds for large teams."

### Configuration / Setup
```
Configured [what] for [purpose] — [what it enables].
```
**Example:** "Configured the CI pipeline for automated E2E tests — PRs now get browser test results before merge."

### Multiple Related Changes
```
Made several improvements to [area]: [most important change]. Also [secondary change].
```
**Example:** "Made several improvements to the standup flow: added timezone-aware scheduling and improved the reminder message formatting. Also fixed a minor layout issue on mobile."

### Non-Code Work (Analysis, Research, Data)
```
[Completed/Delivered] [what] — [key findings or what it enables].
```
**Example:** "Completed the performance audit for the API — identified 3 N+1 query issues and a missing index that accounts for 80% of the latency."

### Multi-Step Task Completion
```
Completed [what was achieved] — [user impact or business value].
```
**Example:** "Completed the auth refactor — JWT tokens now work across all services with centralized middleware validation, eliminating per-service token handling."

## Structured Data Guidelines

Use `--json-data` when a report covers multiple distinct deliverables.

### Standard Fields

| Field | Type | Content |
|-------|------|---------|
| `completed` | array of strings | Items finished in this work |
| `in_progress` | array of strings | Items still being worked on |
| `blockers` | array of strings | Things blocking further progress |

### Writing Good Structured Items

**Good items** — concise, outcome-oriented:
- "JWT authentication endpoint"
- "Token refresh logic with expiry handling"
- "Integration tests (24 cases)"
- "API documentation update"

**Bad items** — too vague or too technical:
- "Updated files"
- "Refactored code"
- "app/auth/middleware/jwt_validator.py"
- "Fixed the thing"

### When to Include Structured Data

- Multi-deliverable features (3+ distinct deliverables)
- Task or plan completions with multiple outputs
- When itemizing adds clarity beyond what the message alone conveys

### When NOT to Include Structured Data

- Single bug fix (plain message is clearer)
- One-item reports (structured data adds no value)
- When every item would just repeat the message in different words

## Milestone Guidelines

Milestones flag reports as significant accomplishments that stand out in the team's timeline.

### Use `--milestone` for:
- Feature fully shipped and ready for users
- Major refactor or migration completed
- Deployment to production
- Multi-step task or plan fully finished
- Critical bug fix with high user impact

### Do NOT use `--milestone` for:
- Regular per-commit updates
- Individual bug fixes (unless critical)
- Incremental progress within a larger effort
- Documentation updates
- Test additions (unless a major coverage milestone)

## Co-Author Rules

The DailyBot backend automatically credits the authenticated CLI user as a co-author. No action needed for the default case.

Only use `--co-authors` when:
- The user explicitly says "add X as co-author" or "I worked on this with Y"
- The user provides the collaborator's email address

Never:
- Add co-authors on your own initiative
- Guess email addresses
- Add co-authors just because someone is mentioned in conversation

## Rate Limiting

Prefer **1 rich report over 10 shallow ones**.

- If working on related changes, wait and aggregate into one report
- Maximum ~10 meaningful reports per day is a reasonable upper bound
- If the last report was sent less than 30 minutes ago, consider aggregating with the next one
- Back-to-back reports about the same feature should be combined

## The Anti-Pattern List

These are the most common mistakes. Avoid them:

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| "Completed a deep work plan with multiple tasks" | Describes process, not outcome | Describe WHAT was built |
| "Executed 6 tasks successfully" | Nobody cares about task counts | Describe the deliverables |
| "Completed development work" | Completely meaningless | Be specific or don't report |
| "3 files modified in app/auth/" | File counts aren't outcomes | Describe the change and its impact |
| "feat(api): add auth endpoint" | Raw commit message | Rewrite in human language |
| "Agent completed testing work" | Violates human-first principle | "Added test coverage for..." |
| "See git log for details" | Defers to another system | Report must be self-contained |
| Sending 5 reports in 10 minutes | Spam | Aggregate into one |
