# Dailybot Plugin for Claude Code

Connect [Claude Code](https://code.claude.com) to your team via [Dailybot](https://www.dailybot.com). Report progress, check messages, send emails, and announce agent status — all integrated into your coding workflow.

## What it does

This plugin gives Claude Code four capabilities for team collaboration through Dailybot:

**Progress Reporting** — When you complete meaningful work (shipping a feature, fixing a bug, finishing a task), the plugin sends a standup-style progress report to Dailybot. Reports are written in a human-first style: they describe what was accomplished and why it matters, not which files changed.

**Team Messages** — Check for pending messages and instructions from your team. Messages represent tasks, priorities, context, or feedback that should influence your current work.

**Email** — Send emails to anyone through Dailybot. Useful for notifications, summaries, follow-ups, or weekly reports. Replies are delivered back as messages to your agent inbox.

**Health Status** — Announce your agent's status (online, working, offline, degraded) so the team knows what's happening. Health checks also deliver any pending messages from the team.

## Install

From Claude Code:

```
/plugin install dailybot@claude-plugins-official
```

Or test locally during development:

```bash
claude --plugin-dir ./path/to/dailybot-claude-plugin
```

## Setup (one time)

### 1. Dailybot CLI

The plugin requires the Dailybot CLI. If it's not installed, Claude will guide you through it on first use. Or install it yourself:

```bash
# Option A: pip
pip install dailybot-cli

# Option B: install script
curl -sSL https://cli.dailybot.com/install.sh | bash
```

Requires Python 3.9+.

### 2. Authentication

Claude will guide you through login on first use. Or do it yourself:

```bash
dailybot login
```

This sends a verification code to your email. Any Dailybot team member can log in — you don't need to be an admin.

**Don't have a Dailybot account yet?** No problem — Claude can create a new Dailybot organization for you right from the terminal. Just tell Claude you don't have an account and it will handle the setup. You'll get a link to share with your team so they can connect Dailybot to Slack, Teams, Discord, or Google Chat.

### 3. Agent name (optional)

When you enable the plugin, Claude Code asks for an agent name. This is how your reports appear in Dailybot. Default is `claude-code`. You can change it to anything descriptive like `my-backend-agent` or `deploy-bot`.

## Usage

### Slash commands

| Command | What it does |
|---------|-------------|
| `/dailybot:report` | Send a progress report to your team |
| `/dailybot:messages` | Check for pending messages from your team |
| `/dailybot:email` | Send an email through Dailybot |
| `/dailybot:health` | Announce agent status and pick up messages |

### Natural language

You can also use natural language:

- "Send an update to Dailybot about what we did"
- "Report this to my team"
- "Do I have any messages?"
- "What should I work on next?"
- "Email this summary to alice@company.com"
- "Go online" / "Check in with the team"

### Automatic behavior

- **Progress reporting**: Claude detects when you've completed significant work and sends a report automatically. Trivial changes (typo fixes, lockfile updates, formatting) are skipped.
- **Stop gate**: When you stop a session with unreported significant work, Claude reminds you to report before exiting.
- **Message check**: At the start of each session, pending messages from your team are fetched automatically.

## Report examples

**Simple bug fix:**
> "Fixed a bug where users without a timezone set would see errors on their profile page."

**Feature with structured data:**
> "Built the notification preferences system — users can now configure which alerts they receive and through which channels."
> + completed: ["Preferences model", "REST API", "Email integration", "Test suite (32 cases)"]

**Milestone:**
> "Shipped the new billing dashboard — managers can now view usage, invoices, and plan details in one place."

## Co-authoring

When you're logged in via CLI, Dailybot automatically credits you as a co-author on every report. The agent's work shows up in your daily standup — because you directed it.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Dailybot CLI not found" | Install with `pip install dailybot-cli` or `curl -sSL https://cli.dailybot.com/install.sh \| bash` |
| "Not authenticated" | Run `dailybot login` and follow the email verification flow |
| No Dailybot account | Tell Claude you don't have an account — it can create a new organization for you on the spot |
| Reports not appearing | Check `dailybot status` to verify authentication. Ensure you're a member of a Dailybot organization. |
| Wrong agent name | Run `/plugin` in Claude Code, find the Dailybot plugin, and update the agent name setting |
| Messages not loading | Check `dailybot agent message list --name claude-code --pending` manually to verify |
| Email rate limited | Dailybot limits agent emails per hour (default: 50). Wait for the hourly window to reset. |

## Links

- [Dailybot](https://www.dailybot.com)
- [Dailybot CLI on PyPI](https://pypi.org/project/dailybot-cli/)
- [Dailybot Agent API docs](https://api.dailybot.com/skill.md)
- [Plugin source code](https://github.com/DailyBotHQ/dailybot-claude-plugin)
