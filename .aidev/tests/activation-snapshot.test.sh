#!/bin/bash
# activation-snapshot.test.sh - Testes para activation-snapshot.sh

set -e

AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SNAPSHOT_LIB="$AIDEV_ROOT/lib/activation-snapshot.sh"

# Carregar função sob teste
source "$SNAPSHOT_LIB" 2>/dev/null || {
    echo "SKIP: $SNAPSHOT_LIB não existe ainda"
    exit 0
}

# Limpar ambiente de teste
cleanup() {
    rm -rf /tmp/aidev_test_snapshot
    rm -f "$AIDEV_ROOT/state/activation_snapshot.json"
}

trap cleanup EXIT

echo "=== Testes: activation-snapshot.sh ==="

# Test 1: Gera snapshot com estrutura válida
test_snapshot_generates_valid_json() {
    echo "Test: Gera snapshot com estrutura válida"
    
    generate_activation_snapshot
    
    local snapshot_file="$AIDEV_ROOT/state/activation_snapshot.json"
    
    if [ ! -f "$snapshot_file" ]; then
        echo "FAIL: Snapshot não foi criado"
        return 1
    fi
    
    # Verificar campos obrigatórios
    if ! jq -e '.version' "$snapshot_file" >/dev/null 2>&1; then
        echo "FAIL: Campo 'version' ausente"
        return 1
    fi
    
    if ! jq -e '.git_context' "$snapshot_file" >/dev/null 2>&1; then
        echo "FAIL: Campo 'git_context' ausente"
        return 1
    fi
    
    echo "PASS: Snapshot gerado com estrutura válida"
}

# Test 2: Contém 6 commits recentes
test_snapshot_has_6_recent_commits() {
    echo "Test: Snapshot contém 6 commits recentes"
    
    local snapshot_file="$AIDEV_ROOT/state/activation_snapshot.json"
    local commits_count=$(jq '.git_context.recent_summaries | length' "$snapshot_file")
    
    if [ "$commits_count" -ne 6 ]; then
        echo "FAIL: Esperado 6 commits, encontrado: $commits_count"
        return 1
    fi
    
    echo "PASS: 6 commits presentes"
}

# Test 3: Commits categorizados corretamente
test_commits_categorized() {
    echo "Test: Commits categorizados corretamente"
    
    local snapshot_file="$AIDEV_ROOT/state/activation_snapshot.json"
    
    # Verificar que cada commit tem campos necessários
    local first_commit=$(jq '.git_context.recent_summaries[0]' "$snapshot_file")
    
    if ! echo "$first_commit" | jq -e '.hash' >/dev/null 2>&1; then
        echo "FAIL: Commit sem hash"
        return 1
    fi
    
    if ! echo "$first_commit" | jq -e '.type' >/dev/null 2>&1; then
        echo "FAIL: Commit sem tipo"
        return 1
    fi
    
    echo "PASS: Commits corretamente categorizados"
}

# Test 4: Checksums são gerados
test_checksums_generated() {
    echo "Test: Checksums são gerados"
    
    local snapshot_file="$AIDEV_ROOT/state/activation_snapshot.json"
    
    if ! jq -e '.checksums.orchestrator' "$snapshot_file" >/dev/null 2>&1; then
        echo "FAIL: Checksum do orchestrator ausente"
        return 1
    fi
    
    echo "PASS: Checksums presentes"
}

# Test 5: Issues observadas incluídas
test_issues_observed() {
    echo "Test: Issues observadas incluídas"
    
    local snapshot_file="$AIDEV_ROOT/state/activation_snapshot.json"
    
    if ! jq -e '.issues_observed' "$snapshot_file" >/dev/null 2>&1; then
        echo "FAIL: Campo issues_observed ausente"
        return 1
    fi
    
    echo "PASS: Issues observadas incluídas"
}

# Executar todos os testes
run_tests() {
    local failed=0
    
    test_snapshot_generates_valid_json || ((failed++))
    test_snapshot_has_6_recent_commits || ((failed++))
    test_commits_categorized || ((failed++))
    test_checksums_generated || ((failed++))
    test_issues_observed || ((failed++))
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo "=== TODOS TESTES PASSARAM ==="
        exit 0
    else
        echo "=== $failed TESTE(S) FALHOU(RAM) ==="
        exit 1
    fi
}

run_tests
