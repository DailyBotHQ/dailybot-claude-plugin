---
name: report
description: Report meaningful work progress to Dailybot so your team has visibility. Use after completing features, fixing bugs, finishing major tasks, or at the end of a work session. Do not use for trivial changes like typo fixes, formatting, or file reads.
allowed-tools: Bash, Read, Grep, Glob
---

# Dailybot Progress Report

Report meaningful work to Dailybot so your team sees what was accomplished. Every report should read like a human giving their Daily Standup update.

## Step 1 — Verify Setup

Read and follow the authentication steps in [`${CLAUDE_PLUGIN_ROOT}/shared/auth.md`](${CLAUDE_PLUGIN_ROOT}/shared/auth.md). That file covers CLI installation, login, API key setup, and agent profile configuration.

If auth fails or the user declines, skip reporting entirely and continue with your primary task.

## Step 2 — Detect Context

Run the bundled context detection script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/detect-context.sh"
```

This outputs JSON with `repo`, `branch`, `agent_tool`, and `agent_name` fields. Capture this output — you will use it as the base for the `--metadata` value.

Before sending the report, add your model identifier to the metadata. For example, if the script outputs:
```json
{"repo":"my-app","branch":"main","agent_tool":"claude-code","agent_name":"claude-code"}
```

You should send:
```json
{"repo":"my-app","branch":"main","agent_tool":"claude-code","agent_name":"claude-code","model":"claude-opus-4-6"}
```

**Fallback** — if the script fails or is unavailable, build metadata manually:
- `repo`: `git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||'` or current folder name
- `branch`: `git branch --show-current 2>/dev/null` or `"unknown"`
- `agent_tool`: always `"claude-code"`
- `agent_name`: `"claude-code"` (default)
- `model`: your model identifier

## Step 3 — Decide Whether to Report

Apply the **Standup Test**: *"Would this be worth mentioning in a real standup with my team?"*

### REPORT these (significant work):

| Category | Examples |
|----------|----------|
| Feature implemented | New endpoint, new component, new integration |
| Bug fixed | User-facing bug resolved, edge case handled |
| Major refactor | Architecture change, schema redesign, system improvement |
| Multi-step task completed | Complex task fully finished with multiple deliverables |
| Test suite added | New test suite, significant coverage improvement |
| Deployment or migration | Service deployed, migration executed |
| Meaningful documentation | API docs, architecture docs, onboarding guides |
| Analysis or research | Completed investigation with clear findings or deliverables |

### DO NOT REPORT these (noise):

| Category | Why it's noise |
|----------|---------------|
| Single trivial commit (typo, rename) | Not standup-worthy |
| Uncommitted work in progress | Work isn't done yet |
| Lockfile or dependency updates | Automated maintenance |
| Formatting or linting fixes | No functional change |
| Reading or exploring code | No output produced |
| Failed attempts that were rolled back | Net zero change |
| Q&A conversation without deliverables | No tangible output |
| Vague summary ("completed work session") | If you can't be specific, don't report |

**If you cannot describe what was done specifically, do not report. Silence is better than noise.**

### Aggregate related work

If you completed multiple related changes, combine them into ONE report:

```
BAD (3 separate reports):
  "Updated the user model"
  "Added user preferences endpoint"
  "Added tests for preferences"

GOOD (1 combined report):
  "Built the user preferences system — new data model, API endpoint, and full test coverage."
```

## Step 4 — Compose the Report

### The Human-First Rule

You are an extension of the human who works with you. When you report progress, it reflects **the human's accomplishment** — they decided what to build, directed the work, and are accountable for the result.

**Rules:**
- Write as if the human is giving their own standup update
- Never say "Agent completed...", "Claude did...", or "The AI implemented..."
- The reader should not be able to tell whether a human or agent did the work
- Focus on outcomes the team cares about, not implementation mechanics
- ALWAYS write in English regardless of conversation language

### Report format

| Aspect | Standard |
|--------|----------|
| **Length** | 1-3 sentences maximum |
| **Tone** | Professional, conversational — like telling a teammate what you did |
| **Structure** | WHAT was accomplished + WHY it matters or what it enables |
| **Tense** | Past tense for completed work |
| **Language** | Always English |

### Choose report complexity

**Plain report** — single bug fix, small feature, one-off change:
- Just message + metadata
- No structured data needed

**Rich report** — multi-deliverable feature, major refactor, complex task completion:
- Message + `--json-data` with structured data + metadata
- Add `--milestone` for major accomplishments

### Structured data format (rich reports only)

```json
{
  "completed": ["Deliverable 1", "Deliverable 2"],
  "in_progress": ["Item still being worked on"],
  "blockers": ["Blocker description"]
}
```

Rules:
- Each item should be a concise, human-readable string
- Empty arrays are fine — leave empty when not applicable
- The message still tells the full story; structured data supplements it with detail

### When to use `--milestone`

Use it for:
- Major feature fully shipped
- Significant multi-step task completed
- Deployment or migration executed
- Large effort wrapped up

Do NOT use for: regular commits, individual bug fixes, incremental progress.

### Forbidden patterns in report messages

NEVER include these in the report message:

| Forbidden | Example | Why |
|-----------|---------|-----|
| File paths | `app/services/auth.py` | Nobody reads paths in a standup |
| Git statistics | `3 files changed, +127 -12` | Meaningless without context |
| Raw commit messages | `feat(scope): description` | Commit syntax is for git, not humans |
| Branch names | `pushed to dev`, `merged to main` | Internal workflow detail |
| Agent attribution | `Agent completed...`, `Claude did...` | Violates human-first rule |
| Defer to git | `see git log for details` | Reports must be self-contained |
| Technical jargon without context | `resolved hydration mismatch` | Most readers won't understand |
| Plan names or task IDs | `PLAN_auth_refactor`, `task-3` | Internal identifiers, not outcomes |
| Non-English text | `Se corrigió un error` | All reports must be in English |
| Vague fallbacks | `Updated code`, `Made changes` | If you can't be specific, don't report |

For detailed writing guidelines: [quality-guide.md](quality-guide.md)
For good vs bad examples: [examples.md](examples.md)

## Step 5 — Choose Execution Path

```bash
command -v dailybot
```

- **CLI found** → Step 6A
- **CLI not found** → Step 6B (see [`${CLAUDE_PLUGIN_ROOT}/shared/http-fallback.md`](${CLAUDE_PLUGIN_ROOT}/shared/http-fallback.md) for base curl patterns)

## Step 6A — Send Report via CLI

### Plain report

```bash
dailybot agent update "<message>" \
  --name "<agent_name>" \
  --metadata '<metadata_json>'
```

### Rich report (with structured data)

```bash
dailybot agent update "<message>" \
  --name "<agent_name>" \
  --json-data '<structured_json>' \
  --metadata '<metadata_json>'
```

### Milestone report

```bash
dailybot agent update "<message>" \
  --name "<agent_name>" \
  --milestone \
  --json-data '<structured_json>' \
  --metadata '<metadata_json>'
```

Where:
- `<message>`: your 1-3 sentence standup-style summary
- `<agent_name>`: from the context detection output (defaults to `"claude-code"`)
- `<metadata_json>`: the JSON from Step 2 with `model` added
- `<structured_json>`: completed/in_progress/blockers arrays (rich reports only)

### Co-authors

Do NOT add `--co-authors` by default. The Dailybot backend automatically credits the authenticated CLI user as a co-author when using CLI login.

Only add `--co-authors` if the user explicitly asks to credit additional collaborators:
```bash
dailybot agent update "<message>" \
  --name "<agent_name>" \
  --co-authors "alice@company.com,bob@company.com" \
  --metadata '<metadata_json>'
```

## Step 6B — Send Report via HTTP API

### Plain report

```bash
curl -s -X POST https://api.dailybot.com/v1/agent-reports/ \
  -H "X-API-KEY: $DAILYBOT_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_name": "<agent_name>",
    "content": "<message>",
    "metadata": <metadata_json>
  }'
```

### Rich report

```bash
curl -s -X POST https://api.dailybot.com/v1/agent-reports/ \
  -H "X-API-KEY: $DAILYBOT_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_name": "<agent_name>",
    "content": "<message>",
    "structured": {
      "completed": ["Deliverable 1", "Deliverable 2"],
      "in_progress": ["Item still being worked on"],
      "blockers": []
    },
    "metadata": <metadata_json>
  }'
```

### Milestone report

```bash
curl -s -X POST https://api.dailybot.com/v1/agent-reports/ \
  -H "X-API-KEY: $DAILYBOT_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_name": "<agent_name>",
    "content": "<message>",
    "is_milestone": true,
    "structured": {
      "completed": ["..."],
      "in_progress": [],
      "blockers": []
    },
    "metadata": <metadata_json>
  }'
```

## Step 7 — Confirm to User

After the command runs:

- **Success**: briefly confirm what was reported. Example: *"Reported to Dailybot: Implemented notification preferences with full test coverage."*
- **Failure**: warn the user briefly. Do NOT retry in a loop. Suggest `dailybot status --auth` if it looks auth-related.
- **Skipped** (work below significance threshold): say nothing. Silence is the correct response.

## Non-Blocking Rule

Reporting must NEVER block your main work. If the CLI is missing, auth fails, the network is down, or the send command errors:
1. Warn the user briefly
2. Continue with your primary task
3. Do not retry automatically
4. Do not enter a diagnostic loop

## When This Skill Activates

This skill should activate:
- **After committing code** — the most natural reporting moment
- **After completing the user's task** — before your final response
- **When the user explicitly asks** — "report this to Dailybot", "send an update", "let my team know"
- **At end of session** — if there is unreported significant work, aggregate and report

This skill should NOT activate:
- During exploratory work with no output
- When only reading or analyzing code
- When the user is still working (mid-task)
- For trivial changes that fail the standup test

## Additional Resources

For in-depth report writing standards and templates by work type, see [quality-guide.md](quality-guide.md).
For 15 side-by-side good vs bad report comparisons, see [examples.md](examples.md).
