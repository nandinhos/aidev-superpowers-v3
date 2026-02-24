#!/bin/bash
set -euo pipefail

AIDEV_ROOT="${AIDEV_ROOT:-.aidev}"
LIB_DIR="$AIDEV_ROOT/lib/workthrees"

COMPLEXITY_SCRIPT="$LIB_DIR/classify-complexity.sh"
IMPACT_SCRIPT="$LIB_DIR/analyze-impact.sh"
QUEUE_SCRIPT="$LIB_DIR/task-queue.sh"
LLM_SCRIPT="$LIB_DIR/select-llm.sh"
LOCK_SCRIPT="$LIB_DIR/file-lock.sh"

usage() {
    cat <<EOF
USAGE: workthrees-run.sh [COMMAND] [OPTIONS]

Orquestrador inteligente de execucao assistida por IA.
Executa o fluxo completo: analise -> classificacao -> selecao LLM -> fila -> lock.

COMMANDS:
    analyze     Analisa impacto de uma tarefa
    classify    Classifica complexidade
    select      Seleciona LLM
    enqueue     Adiciona tarefa a fila
    run         Executa tarefa completa (analyze -> classify -> select -> enqueue -> lock)
    exec        Executa tarefa da fila (pega prox executavel, faz lock, executa)
    release     Libera lock apos execucao
    status      Status da fila
    dashboard   Dashboard completo

OPTIONS:
    --task-id ID         ID da tarefa
    --description TEXT   Descricao da tarefa
    --files FILE1,FILE2 Arquivos afetados
    --type TYPE          Tipo: new|refactor|fix (default: new)
    --priority N         Prioridade (1-10)
    --depends-on IDS     IDs dependentes
    --strategy STRAT     Estrategia LLM: balanced|speed|cost|quality
    -h, --help          Mostra esta ajuda

EXEMPLOS:
    # Analisar impacto
    workthrees-run.sh analyze --task-id "feat-001" --description "Criar login"

    # Classificar complexidade
    workthrees-run.sh classify --files-count 5 --type new

    # Executar fluxo completo
    workthrees-run.sh run --task-id "feat-001" --description "Criar componente de login" --files "src/auth/login.ts"

    # Executar da fila
    workthrees-run.sh exec

    # Dashboard
    workthrees-run.sh dashboard
EOF
    exit 1
}

COMMAND="${1:-}"
shift || true

case "$COMMAND" in
    analyze|classify|select|enqueue|run|exec|release|status|dashboard) ;;
    *) usage ;;
esac

TASK_ID=""
DESCRIPTION=""
FILES_INPUT=""
TYPE="new"
PRIORITY=5
DEPENDS_ON=""
STRATEGY="balanced"

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-id) TASK_ID="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --files) FILES_INPUT="$2"; shift 2 ;;
        --type) TYPE="$2"; shift 2 ;;
        --priority) PRIORITY="$2"; shift 2 ;;
        --depends-on) DEPENDS_ON="$2"; shift 2 ;;
        --strategy) STRATEGY="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

cmd_analyze() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    local args="--task-id $TASK_ID"
    [[ -n "$DESCRIPTION" ]] && args="$args --description \"$DESCRIPTION\""
    [[ -n "$FILES_INPUT" ]] && args="$args --files \"$FILES_INPUT\""
    
    eval "$IMPACT_SCRIPT $args"
}

cmd_classify() {
    local files_count=0
    [[ -n "$FILES_INPUT" ]] && files_count=$(echo "$FILES_INPUT" | tr ',' '\n' | wc -l)
    
    $COMPLEXITY_SCRIPT \
        --files-count "$files_count" \
        --type "$TYPE" \
        --has-tests
}

cmd_select() {
    local complexity_result
    complexity_result=$(cmd_classify)
    local score=$(echo "$complexity_result" | jq -r '.score')
    local complexity=$(echo "$complexity_result" | jq -r '.complexity')
    
    $LLM_SCRIPT --score "$score" --strategy "$STRATEGY"
}

cmd_enqueue() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    local args="enqueue --task-id \"$TASK_ID\" --priority $PRIORITY"
    [[ -n "$DESCRIPTION" ]] && args="$args --description \"$DESCRIPTION\""
    [[ -n "$DEPENDS_ON" ]] && args="$args --depends-on \"$DEPENDS_ON\""
    
    eval "$QUEUE_SCRIPT $args"
}

cmd_run() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    echo "=== Workthrees Execution Flow ==="
    echo ""
    
    echo "1. Analisando impacto..."
    local impact_result
    impact_result=$($IMPACT_SCRIPT --task-id "$TASK_ID" --description "$DESCRIPTION" --files "$FILES_INPUT" 2>/dev/null || echo '{"files":[],"modules":[]}')
    echo "$impact_result" | jq .
    echo ""
    
    local files_count=$(echo "$impact_result" | jq '.files | length')
    local modules=$(echo "$impact_result" | jq -r '.modules | join(", ")')
    
    echo "2. Classificando complexidade..."
    local complexity_result
    complexity_result=$($COMPLEXITY_SCRIPT \
        --files-count "$files_count" \
        --type "$TYPE" \
        --has-tests)
    echo "$complexity_result" | jq .
    echo ""
    
    local score=$(echo "$complexity_result" | jq -r '.score')
    local complexity=$(echo "$complexity_result" | jq -r '.complexity')
    
    echo "3. Selecionando LLM..."
    local llm_result
    llm_result=$($LLM_SCRIPT --score "$score" --strategy "$STRATEGY")
    echo "$llm_result" | jq .
    echo ""
    
    local model=$(echo "$llm_result" | jq -r '.model')
    
    echo "4. Adicionando a fila..."
    local queue_args="enqueue --task-id \"$TASK_ID\" --priority $PRIORITY"
    [[ -n "$DESCRIPTION" ]] && queue_args="$queue_args --description \"$DESCRIPTION\""
    [[ -n "$DEPENDS_ON" ]] && queue_args="$queue_args --depends-on \"$DEPENDS_ON\""
    
    eval "$QUEUE_SCRIPT $queue_args"
    echo ""
    
    echo "=== Resumo ==="
    echo "Task: $TASK_ID"
    echo "Arquivos afetados: $files_count ($modules)"
    echo "Complexidade: $complexity (score: $score)"
    echo "LLM: $model"
    echo "Estratégia: $STRATEGY"
    echo ""
    echo "Execute 'workthrees-run.sh exec' para executar"
}

cmd_exec() {
    echo "=== Buscando proxima tarefa executavel ==="
    
    local task
    task=$($QUEUE_SCRIPT dequeue 2>/dev/null)
    
    if [[ -z "$task" ]] || [[ "$task" == "ERROR:"* ]]; then
        echo "Nenhuma tarefa executavel"
        exit 1
    fi
    
    local task_id=$(echo "$task" | jq -r '.id')
    local description=$(echo "$task" | jq -r '.description // "Sem descricao"')
    local priority=$(echo "$task" | jq -r '.priority')
    
    echo "Executando: $task_id"
    echo "Descricao: $description"
    echo "Prioridade: $priority"
    echo ""
    
    local impact_result=$($IMPACT_SCRIPT --task-id "$task_id" --description "$description" 2>/dev/null || echo '{"files":[]}')
    local files=$(echo "$impact_result" | jq -r '.files | join(",")')
    local files_count=$(echo "$impact_result" | jq '.files | length')
    
    if [[ -n "$files" ]]; then
        echo "Adquirindo locks em: $files"
        $LOCK_SCRIPT acquire --task-id "$task_id" --files "$files" || {
            echo "ERROR: Falha ao adquirir lock"
            $QUEUE_SCRIPT fail --task-id "$task_id"
            exit 1
        }
    fi
    
    echo ""
    echo "=== Classificando complexidade..."
    local complexity_result=$($COMPLEXITY_SCRIPT --files-count "$files_count" --type new)
    local score=$(echo "$complexity_result" | jq -r '.score')
    local complexity=$(echo "$complexity_result" | jq -r '.complexity')
    echo "$complexity_result" | jq .
    echo ""
    
    echo "=== Selecionando LLM..."
    local llm_result=$($LLM_SCRIPT --score "$score" --strategy "$STRATEGY")
    local model=$(echo "$llm_result" | jq -r '.model')
    echo "$llm_result" | jq .
    echo ""
    
    echo "=============================================="
    echo "  Execute a tarefa com a LLM selecionada"
    echo "  Model: $model"
    echo "  Descricao: $description"
    echo "=============================================="
    echo ""
    echo "Pressione [Enter] quando concluir..."
    
    read -r response
    
    $QUEUE_SCRIPT complete --task-id "$task_id"
    
    if [[ -n "$files" ]]; then
        $LOCK_SCRIPT release --task-id "$task_id"
    fi
    
    echo "Tarefa $task_id concluida!"
}

cmd_release() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    $LOCK_SCRIPT release --task-id "$TASK_ID"
}

cmd_status() {
    echo "=== Fila de Tarefas ==="
    $QUEUE_SCRIPT list
    
    echo ""
    echo "=== Locks Ativos ==="
    $LOCK_SCRIPT list
}

cmd_dashboard() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            WORKTHREES DASHBOARD v1.0.0                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "--- FILA DE TAREFAS ---"
    $QUEUE_SCRIPT list | jq -c '.[]' 2>/dev/null | while read -r task; do
        local id=$(echo "$task" | jq -r '.id')
        local status=$(echo "$task" | jq -r '.status')
        local priority=$(echo "$task" | jq -r '.priority')
        printf "  [%s] %s (priority: %s)\n" "$status" "$id" "$priority"
    done
    
    echo ""
    echo "--- LOCKS ATIVOS ---"
    local locks=$($LOCK_SCRIPT list)
    if [[ "$locks" == "[]" ]]; then
        echo "  Nenhum lock ativo"
    else
        echo "$locks" | jq -c '.[]' 2>/dev/null | while read -r lock; do
            local task_id=$(echo "$lock" | jq -r '.task_id')
            local files=$(echo "$lock" | jq -r '.files | join(", ")')
            printf "  %s: %s\n" "$task_id" "$files"
        done
    fi
    
    echo ""
    echo "--- PROXIMA TAREFA EXECUTAVEL ---"
    $QUEUE_SCRIPT dequeue 2>/dev/null | jq -c '.' || echo "  Nenhuma tarefa executavel"
}

case "$COMMAND" in
    analyze) cmd_analyze ;;
    classify) cmd_classify ;;
    select) cmd_select ;;
    enqueue) cmd_enqueue ;;
    run) cmd_run ;;
    exec) cmd_exec ;;
    release) cmd_release ;;
    status) cmd_status ;;
    dashboard) cmd_dashboard ;;
esac
