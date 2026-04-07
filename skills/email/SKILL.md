---
name: email
description: Send emails to any address via Dailybot. Use for notifications, summaries, or follow-ups the user asks you to send.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Dailybot Email

Send emails on behalf of the user's agent through Dailybot. Useful for notifications, summaries, follow-ups, weekly reports, or any communication that should be delivered as email.

---

## When to Use

- The user asks "email this to Alice" or "send a summary to the team"
- After completing a task that warrants email notification
- For sending reports, digests, or follow-ups to specific people

---

## Step 1 — Verify Setup

Read and follow the authentication steps in [`${CLAUDE_PLUGIN_ROOT}/shared/auth.md`](${CLAUDE_PLUGIN_ROOT}/shared/auth.md). That file covers CLI installation, login, API key setup, and agent profile configuration.

If auth fails or the user declines, skip and continue with your primary task.

---

## Step 2 — Detect Agent Name

Run the bundled context detection script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/detect-context.sh"
```

Capture the `agent_name` value from the JSON output.

**Fallback** — if the script fails, use the default agent name `"claude-code"`.

---

## Step 3 — Choose Execution Path

```bash
command -v dailybot
```

- **CLI found** → Step 4A
- **CLI not found** → Step 4B (see [`${CLAUDE_PLUGIN_ROOT}/shared/http-fallback.md`](${CLAUDE_PLUGIN_ROOT}/shared/http-fallback.md) for base curl patterns)

---

## Step 4A — Send Email via CLI

> **Timeout**: Allow at least 30 seconds for CLI commands to complete. Do not use a shorter timeout.

```bash
dailybot agent email send \
  --to alice@company.com \
  --to bob@company.com \
  --subject "Weekly build report" \
  --body-html "<h2>Build Report</h2><p>All 142 tests passing. Deployed to staging.</p>" \
  --name "<agent_name>"
```

### CLI flags

| Flag | Description |
|------|-------------|
| `--to` | Recipient email address (repeatable for multiple recipients) |
| `--subject` | Email subject line (max 512 characters) |
| `--body-html` | HTML email body |
| `--name` | Agent name (omit if default profile configured) |

---

## Step 4B — Send Email via HTTP API

```bash
curl -s -X POST https://api.dailybot.com/v1/agent-email/send/ \
  -H "X-API-KEY: $DAILYBOT_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_name": "<agent_name>",
    "to": ["alice@company.com", "bob@company.com"],
    "subject": "Weekly build report",
    "body_html": "<h2>Build Report</h2><p>All 142 tests passing. Deployed to staging.</p>"
  }'
```

### Request fields

| Field | Required | Description |
|-------|----------|-------------|
| `agent_name` | Yes | Your consistent agent identifier |
| `to` | Yes | Array of recipient email addresses (max 50 per request) |
| `subject` | Yes | Email subject line (max 512 characters) |
| `body_html` | Yes | HTML email body |
| `metadata` | No | Arbitrary key-value pairs for tracking context |

### Response (201)

```json
{
  "sent_count": 2,
  "total_recipients": 2,
  "reply_to": "ag-5kkdZFjG@mail.dailybot.co"
}
```

---

## Rate Limiting

Agents are rate-limited to a number of emails per hour (default: 50, configurable per organization plan). If you exceed the limit, you'll receive a `429` response:

```json
{
  "detail": "Agent email hourly limit exceeded.",
  "limit": 50,
  "current": 50
}
```

Wait for the hourly window to reset before retrying. Do not retry in a tight loop.

---

## Reply-to Inbox

Every agent has a dedicated email inbox (the `reply_to` address in the send response, e.g. `ag-5kkdZFjG@mail.dailybot.co`). When someone replies to an email sent by the agent, the reply is automatically delivered as a message to the agent's inbox.

Fetch replies using the `/dailybot:messages` skill or directly:

```bash
dailybot agent message list --name "<agent_name>" --pending
```

Email replies appear as messages with `"message_type": "email"` and include the sender's email address and subject in the message metadata.

---

## Composing Good Emails

- **Subject lines** should be clear and specific — "Weekly Build Report: March 24-28" not "Update"
- **Body** should be well-structured HTML — use headings, paragraphs, and lists
- **Keep it professional** — the email comes from the agent's address on behalf of the team
- **Never include secrets, tokens, or API keys** in email content
- **Ask the user for recipients** if they haven't specified — never guess email addresses

---

## Step 5 — Confirm

After the command runs:

- **Success** — briefly confirm. Example: *"Email sent to alice@company.com and bob@company.com: 'Weekly build report'."*
- **Failure** — warn briefly. If rate limited, mention the limit. If auth fails, reference the auth steps.
- **429 Rate Limited** — tell the user the hourly limit was reached and suggest waiting.

---

## Non-Blocking Rule

Sending email must **never block your primary work**. If the CLI is missing, auth fails, the network is down, or the command errors:

1. Warn the user briefly
2. Continue with the primary task
3. Do not retry automatically
4. Do not enter a diagnostic loop
