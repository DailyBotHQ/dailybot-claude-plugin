#!/bin/bash
# Qualitative LLM gate. Invoked by gate.sh after deterministic gates pass,
# unless DAILYBOT_DETERMINISTIC_ONLY=1.
#
# Input: path to accumulator log file as $1.
#
# Exit codes (gate.sh distinguishes these):
#   0 + stdout "report"  → LLM judges work as report-worthy
#   0 + stdout "skip"    → LLM judges work as not report-worthy
#   1                    → failure (missing key, network, malformed JSON, timeout)
#                          gate.sh falls back to the deterministic verdict.
#
# The prompt and reasoning never reach stdout: only the literal "report"
# or "skip" token after JSON validation passes.

set -u

LOG_FILE="${1:-}"
[ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ] && exit 1
[ -z "${ANTHROPIC_API_KEY:-}" ] && exit 1
command -v jq >/dev/null 2>&1 || exit 1
command -v curl >/dev/null 2>&1 || exit 1

# Take last 50 log entries — bounded context.
LOG_TAIL="$(tail -n 50 "$LOG_FILE" 2>/dev/null)"
[ -z "$LOG_TAIL" ] && exit 1

PROMPT='You evaluate whether a coding session produced work worth reporting in a daily standup. Reply with ONLY a JSON object: {"report": true} or {"report": false}. No prose.

Report-worthy: shipped feature, fixed bug, completed refactor, added tests, finished a discrete task.
Not report-worthy: exploration only, formatting, lockfile bumps, abandoned attempts, Q&A.

Tool-use log:
'"$LOG_TAIL"

REQ_BODY="$(jq -c -n --arg p "$PROMPT" '{
  model: "claude-haiku-4-5-20251001",
  max_tokens: 32,
  messages: [{role:"user", content:$p}]
}' 2>/dev/null)"
[ -z "$REQ_BODY" ] && exit 1

RESPONSE="$(timeout 8 curl -s https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -d "$REQ_BODY" 2>/dev/null)"
[ -z "$RESPONSE" ] && exit 1

TEXT="$(printf '%s' "$RESPONSE" | jq -r '.content[0].text // empty' 2>/dev/null)"
[ -z "$TEXT" ] && exit 1

DECISION="$(printf '%s' "$TEXT" | jq -r '.report // empty' 2>/dev/null)"
case "$DECISION" in
  true)  printf 'report'; exit 0 ;;
  false) printf 'skip';   exit 0 ;;
  *)     exit 1 ;;
esac
