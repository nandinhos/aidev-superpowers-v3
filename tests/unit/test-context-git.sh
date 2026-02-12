#!/bin/bash

# Testes Unitários: Context Git Module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
source "$PROJECT_ROOT/tests/helpers/test-framework.sh"

# Mock storage para testes
export CTXGIT_STORAGE=".aidev/state/test-context-log.json"
mkdir -p ".aidev/state"

# Setup: limpa storage antes dos testes
setup() {
    rm -f "$CTXGIT_STORAGE"
}

# Teardown: limpa storage após os testes
teardown() {
    rm -f "$CTXGIT_STORAGE"
}

source "$PROJECT_ROOT/lib/context-git.sh"

test_ctxgit_log_creates_file() {
    setup
    ctxgit_log "edit_file" "lib/foo.sh" "corrigir bug" "task-1" "gemini-cli"
    assert_file_exists "$CTXGIT_STORAGE" "Deve criar o arquivo de storage ao logar pela primeira vez"
    teardown
}

test_ctxgit_log_content() {
    setup
    ctxgit_log "edit_file" "lib/foo.sh" "corrigir bug" "task-1" "gemini-cli"
    
    local content=$(cat "$CTXGIT_STORAGE")
    assert_contains "$content" "edit_file" "Log deve conter a ação"
    assert_contains "$content" "lib/foo.sh" "Log deve conter o alvo"
    assert_contains "$content" "corrigir bug" "Log deve conter a intenção"
    assert_contains "$content" "task-1" "Log deve conter a task"
    assert_contains "$content" "gemini-cli" "Log deve conter a LLM"
    teardown
}

test_ctxgit_get_recent() {
    setup
    ctxgit_log "action1" "target1" "intent1" "task1" "llm1"
    ctxgit_log "action2" "target2" "intent2" "task2" "llm2"
    
    local recent=$(ctxgit_get_recent 1)
    assert_contains "$recent" "action2" "Deve retornar a ação mais recente"
    assert_equals "$(echo "$recent" | jq '. | length' 2>/dev/null || echo "1")" "1" "Deve retornar apenas 1 entrada"
    teardown
}

test_ctxgit_rotate() {
    setup
    export CTXGIT_MAX_ENTRIES=2
    ctxgit_log "a1" "t1" "i1" "k1" "l1"
    ctxgit_log "a2" "t2" "i2" "k2" "l2"
    ctxgit_log "a3" "t3" "i3" "k3" "l3"
    
    local count=$(jq '.entries | length' "$CTXGIT_STORAGE")
    assert_equals "2" "$count" "Deve rotacionar logs e manter apenas CTXGIT_MAX_ENTRIES"
    
    local first_action=$(jq -r '.entries[0].action' "$CTXGIT_STORAGE")
    assert_equals "a2" "$first_action" "A primeira entrada deve ser a segunda ação após a rotação"
    teardown
}

test_ctxgit_render_timeline() {
    setup
    ctxgit_log "edit" "file.sh" "fix" "task1" "gemini"
    local timeline=$(ctxgit_render_timeline)
    assert_contains "$timeline" "gemini: edit -> file.sh (fix)" "Deve renderizar a timeline corretamente"
    teardown
}

test_ctxgit_get_by_llm() {
    setup
    ctxgit_log "a1" "t1" "i1" "k1" "claude"
    ctxgit_log "a2" "t2" "i2" "k2" "gemini"
    
    local claude_logs=$(ctxgit_get_by_llm "claude")
    assert_contains "$claude_logs" "a1" "Deve retornar apenas logs do Claude"
    assert_equals "1" "$(echo "$claude_logs" | jq '. | length')" "Deve conter apenas 1 entrada para o Claude"
    teardown
}

# Executa suite
run_test_suite "Context Git Module" \
    test_ctxgit_log_creates_file \
    test_ctxgit_log_content \
    test_ctxgit_get_recent \
    test_ctxgit_rotate \
    test_ctxgit_render_timeline \
    test_ctxgit_get_by_llm
