---
name: messages
description: Check for pending messages and instructions from your team via Dailybot. Use when starting a session, checking what to work on, or reviewing team input.
allowed-tools: Bash, Read
---

# Dailybot Messages

Check for pending messages and instructions from the user's team. Messages are sent by humans (or other agents) through Dailybot and represent tasks, priorities, context, or feedback that should influence your current work.

---

## When to Check Messages

- At the start of a work session
- When the user asks "do I have any messages?" or "what should I work on?"
- When idle between tasks
- Periodically during long sessions (health checks also deliver messages — see the `/dailybot:health` skill)

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

This outputs JSON with `agent_name` among other fields. Capture the `agent_name` value for use in the next step.

**Fallback** — if the script fails, use the default agent name `"claude-code"`.

---

## Step 3 — Choose Execution Path

```bash
command -v dailybot
```

- **CLI found** → Step 4A
- **CLI not found** → Step 4B (see [`${CLAUDE_PLUGIN_ROOT}/shared/http-fallback.md`](${CLAUDE_PLUGIN_ROOT}/shared/http-fallback.md) for base curl patterns)

---

## Step 4A — Fetch Messages via CLI

> **Timeout**: Allow at least 30 seconds for CLI commands to complete. Do not use a shorter timeout.

```bash
dailybot agent message list --name "<agent_name>" --pending
```

This returns all undelivered messages for the agent. Each message includes:
- Content (the instruction or context)
- Sender name and type (human or agent)
- Timestamp
- Message type (`text` or `email`)

---

## Step 4B — Fetch Messages via HTTP API

```bash
curl -s -X GET "https://api.dailybot.com/v1/agent-messages/?agent_name=<agent_name>&delivered=false" \
  -H "X-API-KEY: $DAILYBOT_API_KEY"
```

**Response:**

```json
[
  {
    "id": "msg-uuid",
    "content": "Please prioritize the auth bug fix before the feature work",
    "message_type": "text",
    "sender_type": "human",
    "sender_name": "Alice",
    "metadata": {},
    "created_at": "2026-02-11T09:30:00Z"
  }
]
```

---

## Step 5 — Act on Messages

Messages from the team are **instructions that should influence your work**. When you receive messages:

1. **Read all pending messages** — understand the full context before acting
2. **Prioritize accordingly** — if a message asks you to change priorities, adjust your plan
3. **Incorporate context** — use information from messages to inform your current task
4. **Acknowledge receipt** — mention what you received in your next progress report (via the `/dailybot:report` skill)

### Message types

| Type | Source | How to handle |
|------|--------|---------------|
| `text` | Human or agent via Dailybot | Direct instruction or context — act on it |
| `email` | Reply to an agent-sent email | Follow-up from a previous email — respond or act accordingly |

### Presenting messages to the user

When messages are found, summarize them clearly:

> "You have **2 messages** from your team via Dailybot:
>
> 1. **Alice** (2 hours ago): *Please prioritize the auth bug fix before the feature work*
> 2. **Bob** (30 min ago): *The staging deploy is blocked — can you check the Docker config?*
>
> Want me to start with the auth bug fix?"

When no messages are found:

> "No pending messages from your team. What would you like to work on?"

---

## Non-Blocking Rule

Checking messages must **never block your primary work**. If the CLI is missing, auth fails, the network is down, or the command errors:

1. Warn the user briefly
2. Continue with the primary task
3. Do not retry automatically
4. Do not enter a diagnostic loop
