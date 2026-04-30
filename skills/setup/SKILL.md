---
name: setup
description: Set up the Dailybot plugin — install the CLI, authenticate, and configure the agent profile. Use on first install or when setup needs to be redone.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Dailybot Setup

Walk the user through first-time setup for the Dailybot plugin. This skill handles CLI installation, authentication, and agent profile configuration in one guided flow.

## When to Use

- The user just installed the plugin and wants to get started
- The user says "set up Dailybot", "connect Dailybot", or "configure Dailybot"
- Another skill failed because the CLI is missing or auth is broken and the user wants to fix it

## Setup Flow

Read and follow **every step** in [`${CLAUDE_PLUGIN_ROOT}/shared/auth.md`](${CLAUDE_PLUGIN_ROOT}/shared/auth.md). That file covers:

1. **CLI installation** — check if `dailybot` is installed, guide through `pip install dailybot-cli` if not
2. **Authentication** — OTP login flow, API key alternative, or self-registration
3. **Agent profile** — ensure a default agent profile exists

Present **one step at a time**. Do not dump all instructions at once.

## After Setup Completes

Once all three steps pass, confirm:

> "Dailybot is ready. Here's what you can do:
>
> - `/dailybot:report` — send a progress update to your team
> - `/dailybot:messages` — check for pending messages
> - `/dailybot:email` — send an email through Dailybot
> - `/dailybot:health` — announce agent status
>
> Progress reports are also sent automatically when you complete significant work."

## If Setup Fails

If any step fails and the user can't or won't resolve it:

1. Tell them what's missing (CLI, auth, or profile)
2. Let them know the plugin's skills won't work until setup is complete
3. Offer to try again later — don't loop

## Non-Blocking Rule

Setup should never block the user's primary work. If they came here from another task, get back to it after setup completes or is skipped.
