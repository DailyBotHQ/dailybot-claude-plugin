# DailyBot Plugin for Claude Code

Report your work progress to [DailyBot](https://www.dailybot.com) automatically as you work with Claude Code. Your team gets visibility into what you accomplished — written as standup-style updates, not robotic agent logs.

## What it does

When you complete meaningful work with Claude Code — shipping a feature, fixing a bug, finishing a task — this plugin sends a progress report to DailyBot. Your teammates see it in their DailyBot feed alongside everyone else's updates, both human and AI.

Reports are written in a human-first style: they describe what was accomplished and why it matters, not which files changed or how many commits were made.

## Install

From Claude Code:

```
/plugin install dailybot@claude-plugins-official
```

Or test locally during development:

```bash
claude --plugin-dir ./path/to/dailybot-plugin
```

## Setup (one time)

### 1. DailyBot CLI

The plugin requires the DailyBot CLI. If it's not installed, Claude will guide you through it on first use. Or install it yourself:

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

This sends a verification code to your email. Any DailyBot team member can log in — you don't need to be an admin.

### 3. Agent name (optional)

When you enable the plugin, Claude Code asks for an agent name. This is how your reports appear in DailyBot. Default is `claude-code`. You can change it to anything descriptive like `my-backend-agent` or `deploy-bot`.

## How it works

### Automatic reporting

Claude detects when you've completed significant work and sends a report automatically. You don't need to do anything — just work as usual.

Significant work includes: features implemented, bugs fixed, major refactors, deployments, test suites added, documentation written, analysis completed.

Trivial changes are skipped: typo fixes, lockfile updates, formatting, code exploration without output.

### Manual reporting

You can also trigger a report explicitly:

```
/dailybot:report
```

Or use natural language:

```
"Send an update to DailyBot about what we did"
"Report this to my team"
"Let my team know what I accomplished"
```

### Co-authoring

When you're logged in via CLI, DailyBot automatically credits you as a co-author on every report. The agent's work shows up in your daily standup — because you directed it.

## Report examples

**Simple bug fix:**
> "Fixed a bug where users without a timezone set would see errors on their profile page."

**Feature with structured data:**
> "Built the notification preferences system — users can now configure which alerts they receive and through which channels."
> + completed: ["Preferences model", "REST API", "Email integration", "Test suite (32 cases)"]

**Milestone:**
> "Shipped the new billing dashboard — managers can now view usage, invoices, and plan details in one place."

## Configuration

| Setting | How to set | Default |
|---------|-----------|---------|
| Agent name | Prompted at plugin enable time | `claude-code` |
| Authentication | `dailybot login` (one time) | — |
| API key (advanced) | `export DAILYBOT_API_KEY=...` | Not needed if using CLI login |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "DailyBot CLI not found" | Install with `pip install dailybot-cli` or `curl -sSL https://cli.dailybot.com/install.sh \| bash` |
| "Not authenticated" | Run `dailybot login` and follow the email verification flow |
| Reports not appearing | Check `dailybot status` to verify authentication. Ensure you're a member of a DailyBot organization. |
| Wrong agent name | Run `/plugin` in Claude Code, find the DailyBot plugin, and update the agent name setting |

## Links

- [DailyBot](https://www.dailybot.com)
- [DailyBot CLI on PyPI](https://pypi.org/project/dailybot-cli/)
- [DailyBot Agent API docs](https://api.dailybot.com/skill.md)
- [Plugin source code](https://github.com/AiDailyBot/dailybot-claude-plugin)
