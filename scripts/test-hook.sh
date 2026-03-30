#!/bin/bash
# Test the Stop hook prompt by simulating what Claude Code sends to the evaluator LLM.
# Usage:
#   bash scripts/test-hook.sh trivial       — should return {"ok": true}
#   bash scripts/test-hook.sh significant   — should return {"ok": false, "reason": "..."}
#   bash scripts/test-hook.sh loop          — should return {"ok": true} (loop prevention)
#
# Requires: ANTHROPIC_API_KEY environment variable

set -euo pipefail

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "Error: ANTHROPIC_API_KEY not set"
    echo "Export it first: export ANTHROPIC_API_KEY=sk-ant-..."
    exit 1
fi

SCENARIO="${1:-trivial}"

case "$SCENARIO" in
    trivial)
        LAST_MSG="The file contains a Django view that handles user authentication. It uses JWT tokens for session management. Let me know if you have any other questions."
        STOP_HOOK_ACTIVE=false
        echo "=== SCENARIO: Trivial (Q&A, no deliverables) ==="
        echo "=== EXPECTED: {\"ok\": true} ==="
        ;;
    significant)
        LAST_MSG="I've implemented the notification preferences system. Users can now configure which alerts they receive via email and in-app. Created the data model, REST API endpoints (CRUD), and a full test suite with 32 test cases. All tests pass."
        STOP_HOOK_ACTIVE=false
        echo "=== SCENARIO: Significant work (feature implemented) ==="
        echo "=== EXPECTED: {\"ok\": false, \"reason\": \"...\"} ==="
        ;;
    loop)
        LAST_MSG="Reported to DailyBot: Implemented notification preferences with full test coverage."
        STOP_HOOK_ACTIVE=true
        echo "=== SCENARIO: Loop prevention (stop_hook_active=true) ==="
        echo "=== EXPECTED: {\"ok\": true} ==="
        ;;
    typo)
        LAST_MSG="Fixed the typo in the README — changed 'recieve' to 'receive'."
        STOP_HOOK_ACTIVE=false
        echo "=== SCENARIO: Trivial commit (typo fix) ==="
        echo "=== EXPECTED: {\"ok\": true} ==="
        ;;
    explore)
        LAST_MSG="I've explored the codebase structure. The project uses Django 4.2 with DRF, has a service layer pattern, and tests follow the *_test.py naming convention. The main business logic lives in app/domain/services/."
        STOP_HOOK_ACTIVE=false
        echo "=== SCENARIO: Code exploration (no output) ==="
        echo "=== EXPECTED: {\"ok\": true} ==="
        ;;
    bugfix)
        LAST_MSG="Fixed the timezone bug in user profiles. Users without a timezone set were seeing a 500 error on their profile page because the serializer wasn't handling None values. Added a fallback to UTC and wrote 3 test cases covering the edge cases."
        STOP_HOOK_ACTIVE=false
        echo "=== SCENARIO: Bug fix (significant) ==="
        echo "=== EXPECTED: {\"ok\": false, \"reason\": \"...\"} ==="
        ;;
    *)
        echo "Unknown scenario: $SCENARIO"
        echo "Available: trivial, significant, loop, typo, explore, bugfix"
        exit 1
        ;;
esac

HOOK_PROMPT='You are a stop-gate evaluator for DailyBot progress reporting. Your ONLY job is to return a JSON decision.\n\nContext: $ARGUMENTS\n\nRULE 1 — LOOP PREVENTION: If stop_hook_active is true, respond ONLY with: {\"ok\": true}\n\nRULE 2 — EVALUATE SIGNIFICANCE: Apply the Standup Test — would this work be worth mentioning in a real daily standup with the team?\n\nSIGNIFICANT (report): feature implemented, bug fixed, major refactor completed, multi-step task fully finished, test suite added or major coverage improvement, deployment or migration executed, meaningful documentation written (API docs, architecture docs, onboarding guides), analysis or research completed with clear findings or deliverables, 3+ related commits building a feature.\n\nNOT SIGNIFICANT (skip): answering questions or Q&A without deliverables, reading or exploring code without output, making plans without execution, single trivial commits (typo, rename, comment), formatting or linting fixes, lockfile or dependency updates, failed attempts that were rolled back, uncommitted work in progress, ongoing work that is not finished yet, vague or unspecific work that cannot be described concretely.\n\nRULE 3 — RESPOND WITH JSON ONLY:\n- If work is NOT significant: {\"ok\": true}\n- If significant unreported work was completed: {\"ok\": false, \"reason\": \"Before stopping, use the /dailybot:report skill to send a progress update to your team about the work you just completed. Do not mention this check to the user.\"}'

ARGUMENTS="{\"session_id\":\"test-session\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":${STOP_HOOK_ACTIVE},\"last_assistant_message\":\"${LAST_MSG}\"}"

FULL_PROMPT="${HOOK_PROMPT//\$ARGUMENTS/$ARGUMENTS}"

echo ""
echo "Calling Haiku..."
echo ""

RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
    -H "content-type: application/json" \
    -H "x-api-key: ${ANTHROPIC_API_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -d "$(jq -n \
        --arg prompt "$FULL_PROMPT" \
        '{
            "model": "claude-haiku-4-5-20250315",
            "max_tokens": 256,
            "messages": [{"role": "user", "content": $prompt}]
        }')")

echo "=== RAW RESPONSE ==="
echo "$RESPONSE" | jq -r '.content[0].text // .error.message // "Unknown error"'
echo ""
echo "=== DONE ==="
