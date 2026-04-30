#!/bin/bash
# Test harness for Dailybot hook scripts. No API calls.
# Verifies exit codes and that stdout is either empty or one valid JSON object.
#
# Usage:
#   bash scripts/test-hook.sh              — run all scenarios
#   bash scripts/test-hook.sh <scenario>   — run one scenario

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACCUMULATOR="$ROOT/hooks/accumulator.sh"
GATE="$ROOT/hooks/gate.sh"
CLEANUP="$ROOT/hooks/cleanup.sh"
MARK_REPORTED="$ROOT/hooks/mark-reported.sh"

# Use an isolated storage root for tests.
export CLAUDE_PLUGIN_DATA="$(mktemp -d)"
trap 'rm -rf "$CLAUDE_PLUGIN_DATA"' EXIT

PASS=0
FAIL=0

assert_empty_or_json() {
  local label="$1" output="$2"
  if [ -z "$output" ]; then
    echo "  [PASS] $label: empty stdout"
    PASS=$((PASS+1))
    return 0
  fi
  if printf '%s' "$output" | jq -e . >/dev/null 2>&1; then
    if printf '%s' "$output" | grep -qE 'RULE [0-9]|evaluator|prompt'; then
      echo "  [FAIL] $label: stdout JSON contains forbidden tokens"
      echo "    >>> $output"
      FAIL=$((FAIL+1))
      return 1
    fi
    echo "  [PASS] $label: valid clean JSON"
    PASS=$((PASS+1))
    return 0
  fi
  echo "  [FAIL] $label: stdout is neither empty nor valid JSON"
  echo "    >>> $output"
  FAIL=$((FAIL+1))
  return 1
}

assert_exit() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "  [PASS] $label: exit=$actual"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $label: expected exit=$expected got $actual"
    FAIL=$((FAIL+1))
  fi
}

run_accumulator() {
  printf '%s' "$1" | bash "$ACCUMULATOR"
  return $?
}

run_gate() {
  printf '%s' "$1" | bash "$GATE"
}

scenario_trivial() {
  echo "=== trivial: empty log → gate exits silently ==="
  local sid="test-trivial-$$"
  local input
  input="$(jq -c -n --arg sid "$sid" '{session_id:$sid, hook_event_name:"Stop", stop_hook_active:false}')"
  local out; out="$(run_gate "$input")"
  local rc=$?
  assert_exit "exit code" 0 $rc
  assert_empty_or_json "stdout" "$out"
}

scenario_loop() {
  echo "=== loop: stop_hook_active=true → silent ==="
  local sid="test-loop-$$"
  local input
  input="$(jq -c -n --arg sid "$sid" '{session_id:$sid, hook_event_name:"Stop", stop_hook_active:true}')"
  local out; out="$(run_gate "$input")"
  local rc=$?
  assert_exit "exit code" 0 $rc
  assert_empty_or_json "stdout" "$out"
}

scenario_significant() {
  echo "=== significant: 3 edits + aged log → emits clean JSON ==="
  local sid="test-sig-$$"
  for f in src/a.py src/b.py src/c.py; do
    local tu
    tu="$(jq -c -n --arg sid "$sid" --arg fp "$f" '{session_id:$sid, tool_name:"Edit", tool_input:{file_path:$fp}}')"
    run_accumulator "$tu"
  done

  # Backdate first log entry to satisfy 60s session-age guard.
  local logf="$CLAUDE_PLUGIN_DATA/dailybot-${sid}.log"
  local old_ts; old_ts=$(date -u -r $(($(date +%s) - 120)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$(($(date +%s) - 120))" +%Y-%m-%dT%H:%M:%SZ)
  awk -v ts="$old_ts" 'NR==1{$1=ts; OFS="\t"; print; next}{print}' "$logf" > "$logf.tmp" && mv "$logf.tmp" "$logf"

  local input
  input="$(jq -c -n --arg sid "$sid" '{session_id:$sid, hook_event_name:"Stop", stop_hook_active:false}')"
  local out; out="$(run_gate "$input")"
  local rc=$?
  assert_exit "exit code" 0 $rc
  if [ -z "$out" ]; then
    echo "  [FAIL] expected non-empty JSON, got empty"
    FAIL=$((FAIL+1))
  else
    assert_empty_or_json "stdout" "$out"
    if printf '%s' "$out" | jq -e '.decision == "block" and .reason and .suppressOutput == true' >/dev/null 2>&1; then
      echo "  [PASS] payload structure"
      PASS=$((PASS+1))
    else
      echo "  [FAIL] payload missing required fields (expected decision/reason/suppressOutput)"
      FAIL=$((FAIL+1))
    fi
  fi
}

scenario_already_reported() {
  echo "=== already reported: .reported flag → silent ==="
  local sid="test-rep-$$"
  for f in src/a.py src/b.py src/c.py; do
    local tu
    tu="$(jq -c -n --arg sid "$sid" --arg fp "$f" '{session_id:$sid, tool_name:"Edit", tool_input:{file_path:$fp}}')"
    run_accumulator "$tu"
  done
  touch "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.reported"
  local input
  input="$(jq -c -n --arg sid "$sid" '{session_id:$sid, hook_event_name:"Stop", stop_hook_active:false}')"
  local out; out="$(run_gate "$input")"
  local rc=$?
  assert_exit "exit code" 0 $rc
  assert_empty_or_json "stdout" "$out"
  [ -z "$out" ] && { echo "  [PASS] no nudge after report"; PASS=$((PASS+1)); } || { echo "  [FAIL] nudged after report"; FAIL=$((FAIL+1)); }
}

scenario_rate_limited() {
  echo "=== rate limited: fresh .last-fired → silent ==="
  local sid="test-rate-$$"
  for f in src/a.py src/b.py src/c.py; do
    local tu
    tu="$(jq -c -n --arg sid "$sid" --arg fp "$f" '{session_id:$sid, tool_name:"Edit", tool_input:{file_path:$fp}}')"
    run_accumulator "$tu"
  done
  touch "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.last-fired"
  local input
  input="$(jq -c -n --arg sid "$sid" '{session_id:$sid, hook_event_name:"Stop", stop_hook_active:false}')"
  local out; out="$(run_gate "$input")"
  local rc=$?
  assert_exit "exit code" 0 $rc
  [ -z "$out" ] && { echo "  [PASS] rate-limit silenced"; PASS=$((PASS+1)); } || { echo "  [FAIL] fired despite rate limit"; FAIL=$((FAIL+1)); }
}

scenario_filtered() {
  echo "=== filtered: lockfile/node_modules paths not logged ==="
  local sid="test-filt-$$"
  for f in package-lock.json yarn.lock node_modules/lib/x.js dist/main.js .git/HEAD; do
    local tu
    tu="$(jq -c -n --arg sid "$sid" --arg fp "$f" '{session_id:$sid, tool_name:"Edit", tool_input:{file_path:$fp}}')"
    run_accumulator "$tu"
  done
  local logf="$CLAUDE_PLUGIN_DATA/dailybot-${sid}.log"
  if [ ! -f "$logf" ] || [ ! -s "$logf" ]; then
    echo "  [PASS] all trivial paths filtered"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] something leaked into log:"; cat "$logf"
    FAIL=$((FAIL+1))
  fi
}

scenario_filter_false_positive() {
  echo "=== filter: 'unlock.py' must NOT match '.lock' ==="
  local sid="test-fp-$$"
  local tu
  tu="$(jq -c -n --arg sid "$sid" '{session_id:$sid, tool_name:"Edit", tool_input:{file_path:"src/unlock.py"}}')"
  run_accumulator "$tu"
  local logf="$CLAUDE_PLUGIN_DATA/dailybot-${sid}.log"
  if [ -s "$logf" ] && grep -q "unlock.py" "$logf"; then
    echo "  [PASS] unlock.py logged correctly"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] unlock.py was filtered by mistake"
    FAIL=$((FAIL+1))
  fi
}

scenario_cleanup() {
  echo "=== cleanup: removes session files ==="
  local sid="test-clean-$$"
  touch "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.log"
  touch "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.reported"
  touch "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.last-fired"
  local input
  input="$(jq -c -n --arg sid "$sid" '{session_id:$sid, hook_event_name:"SessionEnd"}')"
  printf '%s' "$input" | bash "$CLEANUP"
  local rc=$?
  assert_exit "exit code" 0 $rc
  if [ ! -e "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.log" ] && \
     [ ! -e "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.reported" ] && \
     [ ! -e "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.last-fired" ]; then
    echo "  [PASS] all session files removed"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] session files remain"
    FAIL=$((FAIL+1))
  fi
}

scenario_llm_disabled() {
  echo "=== llm disabled: DAILYBOT_DETERMINISTIC_ONLY=1 → nudge fires, gate-llm.sh not invoked ==="
  local sid="test-llmoff-$$"
  for f in src/a.py src/b.py src/c.py; do
    local tu
    tu="$(jq -c -n --arg sid "$sid" --arg fp "$f" '{session_id:$sid, tool_name:"Edit", tool_input:{file_path:$fp}}')"
    run_accumulator "$tu"
  done
  local logf="$CLAUDE_PLUGIN_DATA/dailybot-${sid}.log"
  local old_ts; old_ts=$(date -u -r $(($(date +%s) - 120)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$(($(date +%s) - 120))" +%Y-%m-%dT%H:%M:%SZ)
  awk -v ts="$old_ts" 'NR==1{$1=ts; OFS="\t"; print; next}{print}' "$logf" > "$logf.tmp" && mv "$logf.tmp" "$logf"

  # Sentinel file: gate-llm.sh would touch this if invoked. We replace it
  # temporarily with a tracer to detect invocation.
  local tracer="$CLAUDE_PLUGIN_DATA/llm-invoked"
  local real_llm="$ROOT/hooks/gate-llm.sh"
  local backup="$CLAUDE_PLUGIN_DATA/gate-llm.sh.bak"
  cp "$real_llm" "$backup"
  cat > "$real_llm" <<EOF
#!/bin/bash
touch "$tracer"
exit 1
EOF
  chmod +x "$real_llm"

  local input
  input="$(jq -c -n --arg sid "$sid" '{session_id:$sid, hook_event_name:"Stop", stop_hook_active:false}')"
  local out
  out="$(DAILYBOT_DETERMINISTIC_ONLY=1 ANTHROPIC_API_KEY= bash -c "printf '%s' '$input' | bash '$GATE'")"
  local rc=$?

  # Restore original
  mv "$backup" "$real_llm"

  assert_exit "exit code" 0 $rc
  if [ -e "$tracer" ]; then
    echo "  [FAIL] gate-llm.sh was invoked despite DAILYBOT_DETERMINISTIC_ONLY=1"
    FAIL=$((FAIL+1))
    rm -f "$tracer"
  else
    echo "  [PASS] gate-llm.sh not invoked"
    PASS=$((PASS+1))
  fi
  if [ -n "$out" ] && printf '%s' "$out" | jq -e '.decision == "block" and .reason' >/dev/null 2>&1; then
    echo "  [PASS] deterministic nudge fired"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] expected deterministic nudge, got: $out"
    FAIL=$((FAIL+1))
  fi
}

scenario_llm_failure() {
  echo "=== llm failure: gate-llm.sh exits 1 → fall back to deterministic nudge ==="
  local sid="test-llmfail-$$"
  for f in src/a.py src/b.py src/c.py; do
    local tu
    tu="$(jq -c -n --arg sid "$sid" --arg fp "$f" '{session_id:$sid, tool_name:"Edit", tool_input:{file_path:$fp}}')"
    run_accumulator "$tu"
  done
  local logf="$CLAUDE_PLUGIN_DATA/dailybot-${sid}.log"
  local old_ts; old_ts=$(date -u -r $(($(date +%s) - 120)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$(($(date +%s) - 120))" +%Y-%m-%dT%H:%M:%SZ)
  awk -v ts="$old_ts" 'NR==1{$1=ts; OFS="\t"; print; next}{print}' "$logf" > "$logf.tmp" && mv "$logf.tmp" "$logf"

  # Force gate-llm.sh failure by unsetting ANTHROPIC_API_KEY (the real script
  # exits 1 immediately when the key is missing).
  local input
  input="$(jq -c -n --arg sid "$sid" '{session_id:$sid, hook_event_name:"Stop", stop_hook_active:false}')"
  local out
  out="$(unset DAILYBOT_DETERMINISTIC_ONLY; unset ANTHROPIC_API_KEY; printf '%s' "$input" | bash "$GATE")"
  local rc=$?
  assert_exit "exit code" 0 $rc
  if [ -n "$out" ] && printf '%s' "$out" | jq -e '.decision == "block" and .reason' >/dev/null 2>&1; then
    echo "  [PASS] deterministic fallback fired despite LLM failure"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] expected fallback nudge, got: $out"
    FAIL=$((FAIL+1))
  fi
}

run_mark_reported() {
  printf '%s' "$1" | bash "$MARK_REPORTED"
  return $?
}

scenario_mark_reported_cli() {
  echo "=== mark-reported: CLI report command → creates .reported flag ==="
  local sid="test-mrcli-$$"
  local input
  input="$(jq -c -n --arg sid "$sid" '{
    session_id: $sid,
    tool_name: "Bash",
    tool_input: { command: "dailybot agent update \"Fixed auth bug\" --name claude-code --metadata {}" },
    tool_response: "OK Report submitted (id: abc-123)"
  }')"
  run_mark_reported "$input"
  local rc=$?
  assert_exit "exit code" 0 $rc
  if [ -f "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.reported" ]; then
    echo "  [PASS] .reported flag created"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] .reported flag not created"
    FAIL=$((FAIL+1))
  fi
}

scenario_mark_reported_http() {
  echo "=== mark-reported: HTTP fallback report → creates .reported flag ==="
  local sid="test-mrhttp-$$"
  local input
  input="$(jq -c -n --arg sid "$sid" '{
    session_id: $sid,
    tool_name: "Bash",
    tool_input: { command: "curl -s -X POST https://api.dailybot.com/v1/agent-reports/ -H \"X-API-KEY: ...\" -d ..." },
    tool_response: "{\"id\": \"report-456\"}"
  }')"
  run_mark_reported "$input"
  local rc=$?
  assert_exit "exit code" 0 $rc
  if [ -f "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.reported" ]; then
    echo "  [PASS] .reported flag created"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] .reported flag not created"
    FAIL=$((FAIL+1))
  fi
}

scenario_mark_reported_non_report() {
  echo "=== mark-reported: non-report Bash command → no flag ==="
  local sid="test-mrnr-$$"
  local input
  input="$(jq -c -n --arg sid "$sid" '{
    session_id: $sid,
    tool_name: "Bash",
    tool_input: { command: "ls -la src/" },
    tool_response: "total 42"
  }')"
  run_mark_reported "$input"
  local rc=$?
  assert_exit "exit code" 0 $rc
  if [ ! -f "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.reported" ]; then
    echo "  [PASS] no flag for non-report command"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] flag created for non-report command"
    FAIL=$((FAIL+1))
  fi
}

scenario_mark_reported_failure() {
  echo "=== mark-reported: failed report → no flag ==="
  local sid="test-mrfail-$$"
  local input
  input="$(jq -c -n --arg sid "$sid" '{
    session_id: $sid,
    tool_name: "Bash",
    tool_input: { command: "dailybot agent update \"Fixed bug\" --name claude-code" },
    tool_response: "Error: authentication failed"
  }')"
  run_mark_reported "$input"
  local rc=$?
  assert_exit "exit code" 0 $rc
  if [ ! -f "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.reported" ]; then
    echo "  [PASS] no flag after failed report"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] flag created despite failure"
    FAIL=$((FAIL+1))
  fi
}

scenario_mark_reported_edit_tool() {
  echo "=== mark-reported: Edit tool (not Bash) → no flag ==="
  local sid="test-mredit-$$"
  local input
  input="$(jq -c -n --arg sid "$sid" '{
    session_id: $sid,
    tool_name: "Edit",
    tool_input: { file_path: "src/app.py" }
  }')"
  run_mark_reported "$input"
  local rc=$?
  assert_exit "exit code" 0 $rc
  if [ ! -f "$CLAUDE_PLUGIN_DATA/dailybot-${sid}.reported" ]; then
    echo "  [PASS] no flag for Edit tool"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] flag created for Edit tool"
    FAIL=$((FAIL+1))
  fi
}

ALL=(trivial loop significant already_reported rate_limited filtered filter_false_positive cleanup llm_disabled llm_failure mark_reported_cli mark_reported_http mark_reported_non_report mark_reported_failure mark_reported_edit_tool)
TARGET="${1:-all}"

if [ "$TARGET" = "all" ]; then
  for s in "${ALL[@]}"; do "scenario_$s"; done
else
  "scenario_$TARGET"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
