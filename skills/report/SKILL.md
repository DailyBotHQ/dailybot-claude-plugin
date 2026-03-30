---
name: report
description: Report meaningful work progress to DailyBot so your team has visibility. Use after completing features, fixing bugs, finishing major tasks, or at the end of a work session. Do not use for trivial changes like typo fixes, formatting, or file reads.
allowed-tools: Bash, Read, Grep, Glob
---

# DailyBot Progress Report

Report meaningful work to DailyBot so your team sees what was accomplished. Every report should read like a human giving their Daily Standup update.

## Step 1: Setup Check

Run these checks in order. Stop at the first failure and guide the user through resolution.

### 1a. Check DailyBot CLI is installed

```bash
command -v dailybot
```

If not found, tell the user:

> "To report progress to your team, I need the DailyBot CLI. You can install it with either:
> - `pip install dailybot-cli` (requires Python 3.9+)
> - `curl -sSL https://cli.dailybot.com/install.sh | bash`
>
> Let me know once it's installed and I'll continue."

**Do not attempt to install it yourself without the user's permission.** Wait for the user to confirm. After confirmation, re-check with `command -v dailybot`.

### 1b. Check authentication

```bash
dailybot status 2>&1
```

If output contains "not authenticated", "login required", "please log in", or similar — and `DAILYBOT_API_KEY` is not set — guide the user through login:

1. Ask the user: "What email address do you use for DailyBot?"
2. Run: `dailybot login --email=<their-email>`
3. Tell the user: "I've sent a verification code to your email. Please check your inbox — what's the code?"
4. Run: `dailybot login --email=<their-email> --code=<their-code>`
5. If multi-org response (output lists organizations): show the list and ask the user to pick one
6. If needed: `dailybot login --email=<their-email> --code=<their-code> --org=<selected-uuid>`
7. Verify with: `dailybot status`

**Authentication rules:**
- NEVER store or log the user's email or verification code in any file
- If any step fails, inform the user and suggest they run `dailybot login` manually
- If the user declines to authenticate now, respect that and skip reporting entirely
- Authentication issues must NEVER block your main work — always continue the task

## Step 2: Detect Context

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

## Step 3: Decide Whether to Report

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

## Step 4: Compose the Report

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

## Step 5: Send the Report

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

Do NOT add `--co-authors` by default. The DailyBot backend automatically credits the authenticated CLI user as a co-author when using CLI login.

Only add `--co-authors` if the user explicitly asks to credit additional collaborators:
```bash
dailybot agent update "<message>" \
  --name "<agent_name>" \
  --co-authors "alice@company.com,bob@company.com" \
  --metadata '<metadata_json>'
```

## Step 6: Confirm to User

After the command runs:

- **Success**: briefly confirm what was reported. Example: *"Reported to DailyBot: Implemented notification preferences with full test coverage."*
- **Failure**: warn the user briefly. Do NOT retry in a loop. Suggest `dailybot status` if it looks auth-related.
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
- **When the user explicitly asks** — "report this to DailyBot", "send an update", "let my team know"
- **At end of session** — if there is unreported significant work, aggregate and report

This skill should NOT activate:
- During exploratory work with no output
- When only reading or analyzing code
- When the user is still working (mid-task)
- For trivial changes that fail the standup test

## Additional Resources

For in-depth report writing standards and templates by work type, see [quality-guide.md](quality-guide.md).
For 15 side-by-side good vs bad report comparisons, see [examples.md](examples.md).
