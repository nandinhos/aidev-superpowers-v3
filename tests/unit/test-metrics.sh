#!/bin/bash
# Tests for Metrics Module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Load modules (needed if run standalone or to ensure dependencies)
source "$ROOT_DIR/lib/core.sh"
source "$ROOT_DIR/lib/file-ops.sh"
source "$ROOT_DIR/lib/metrics.sh"

TEST_BASE_DIR="/tmp/aidev-metrics-test"
METRICS_FILE="$TEST_BASE_DIR/.aidev/state/metrics.log"

setup() {
    rm -rf "$TEST_BASE_DIR"
    mkdir -p "$TEST_BASE_DIR/.aidev/state"
    # Override global install path for testing
    CLI_INSTALL_PATH="$TEST_BASE_DIR" 
}

teardown() {
    rm -rf "$TEST_BASE_DIR"
}

# ============================================================================
# Execution
# ============================================================================

setup

test_section "Metrics - Criação de Arquivo"
# Expectation: calling track_event should create the log file if missing
metrics_track_event "agent_start" "orchestrator" 0 "success"
assert_file_exists "$METRICS_FILE" "Metrics file should be created"

test_section "Metrics - Conteúdo e Formato"
metrics_track_event "skill_run" "brainstorming" 120 "success"

content=$(cat "$METRICS_FILE")
assert_contains "$content" "skill_run" "Log should contain event type"
assert_contains "$content" "brainstorming" "Log should contain event name"
assert_contains "$content" "120" "Log should contain duration"

# Validate JSON structure if jq is available
if command -v jq >/dev/null 2>&1; then
    is_valid_json=$(echo "$content" | tail -n 1 | jq empty > /dev/null 2>&1 && echo "yes" || echo "no")
    assert_equals "yes" "$is_valid_json" "Log entry should be valid JSON"
fi

test_section "Metrics - Timer Workflow"
# Expectation: start timer returns an ID, stop timer uses that ID to log duration

timer_id=$(metrics_start_timer "test_event")
assert_not_empty "$timer_id" "Start timer should return an ID"

sleep 1

metrics_stop_timer "$timer_id" "test_event_timer" "test_workflow" "success"

content=$(cat "$METRICS_FILE" | grep "test_event_timer")
# We expect duration to be approx 1000ms (we slept 1s)
# Using regex to check if duration is present and numeric
# Note: grep in bash return 0 if found
echo "$content" | grep -E '"duration":[[:space:]]*[0-9]+' > /dev/null
found_duration=$?
assert_equals "0" "$found_duration" "Log should contain numeric duration"

teardown
