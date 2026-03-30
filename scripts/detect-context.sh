#!/bin/bash
# DailyBot Context Detection Script
# Outputs JSON metadata for DailyBot agent reports.
# Called by the dailybot:report skill before each report.
#
# Output: {"repo":"...","branch":"...","agent_tool":"claude-code","agent_name":"..."}
#
# Environment:
#   CLAUDE_PLUGIN_OPTION_AGENT_NAME — set by Claude Code from userConfig (optional)

AGENT_NAME="${CLAUDE_PLUGIN_OPTION_AGENT_NAME:-claude-code}"
REPO="unknown"
BRANCH="unknown"

if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [ -n "$REMOTE_URL" ]; then
        REPO=$(echo "$REMOTE_URL" | sed 's|.*/||;s|\.git$||')
    else
        REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")")
    fi
    BRANCH=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
else
    REPO=$(basename "$PWD")
fi

echo "{\"repo\":\"${REPO}\",\"branch\":\"${BRANCH}\",\"agent_tool\":\"claude-code\",\"agent_name\":\"${AGENT_NAME}\"}"
