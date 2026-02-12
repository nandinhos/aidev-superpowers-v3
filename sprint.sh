#!/bin/bash
# Sprint Management Helper
# Comandos simplificados para gestão de sprints

SPRINT_DIR=".aidev/state/sprints"
CURRENT_SPRINT="$SPRINT_DIR/current/sprint-status.json"

# Carrega módulos do AI Dev se disponíveis
if [ -f "lib/context-git.sh" ]; then
    source lib/context-git.sh
fi

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função auxiliar para detectar task atual ou próxima
_detect_current_or_next_task() {
    local sprint_file="$1"
    
    # Primeiro verifica se há task em progresso
    local in_progress=$(jq -r '.tasks[] | select(.status == "in_progress") | .task_id' "$sprint_file" | head -1)
    if [ -n "$in_progress" ]; then
        echo "🔄 $in_progress"
        return 0
    fi
    
    # Se não há em progresso, pega a primeira pendente
    local pending=$(jq -r '.tasks[] | select(.status == "pending") | .task_id' "$sprint_file" | head -1)
    if [ -n "$pending" ]; then
        echo "⏸️  $pending (próxima)"
        return 0
    fi
    
    # Se não há pendentes, verifica se todas estão completadas
    local total=$(jq '.tasks | length' "$sprint_file")
    local completed=$(jq '[.tasks[] | select(.status == "completed")] | length' "$sprint_file")
    
    if [ "$completed" -eq "$total" ]; then
        echo "✅ Todas completadas"
    else
        echo "Nenhuma"
    fi
}

# Função para mostrar status atual
show_status() {
    if [ ! -f "$CURRENT_SPRINT" ]; then
        echo -e "${RED}❌ Nenhuma sprint ativa${NC}"
        echo "   Use: ./sprint.sh start"
        return 1
    fi
    
    local sprint_name=$(jq -r '.sprint_name' "$CURRENT_SPRINT")
    local status=$(jq -r '.status' "$CURRENT_SPRINT")
    local progress=$(jq -r '.overall_progress.percentage // (.overall_progress.completed * 100 / .overall_progress.total_tasks)' "$CURRENT_SPRINT")
    local current_task=$(_detect_current_or_next_task "$CURRENT_SPRINT")
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${YELLOW}$sprint_name${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════╣${NC}"
    
    case "$status" in
        "in_progress")
            echo -e "${BLUE}║${NC}  Status: ${GREEN}🟢 Em Execução${NC}"
            ;;
        "ready_to_start")
            echo -e "${BLUE}║${NC}  Status: ${YELLOW}⏸️  Pronta para Iniciar${NC}"
            ;;
        "completed")
            echo -e "${BLUE}║${NC}  Status: ${GREEN}✅ Concluída${NC}"
            ;;
        "blocked")
            echo -e "${BLUE}║${NC}  Status: ${RED}🚨 Bloqueada${NC}"
            ;;
        "paused")
            echo -e "${BLUE}║${NC}  Status: ${YELLOW}⏸️  Pausada${NC}"
            ;;
        *)
            echo -e "${BLUE}║${NC}  Status: ${YELLOW}⚪ ${status}${NC}"
            ;;
    esac
    
    printf "${BLUE}║${NC}  Progresso: ${GREEN}%d%%${NC}\n" "$progress"
    echo -e "${BLUE}║${NC}  Task Atual: ${YELLOW}$current_task${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
    
    # Mostrar lista de tasks
    echo ""
    echo -e "${YELLOW}📋 Tasks:${NC}"
    jq -r '.tasks[] | select(.status == "completed") | "   ✅ " + .task_id + ": " + .name' "$CURRENT_SPRINT"
    jq -r '.tasks[] | select(.status == "in_progress") | "   🔄 " + .task_id + ": " + .name' "$CURRENT_SPRINT"
    jq -r '.tasks[] | select(.status == "pending") | "   ⏸️  " + .task_id + ": " + .name' "$CURRENT_SPRINT"
    jq -r '.tasks[] | select(.status == "blocked") | "   🚫 " + .task_id + ": " + .name' "$CURRENT_SPRINT"
}

# Função para iniciar sprint
start_sprint() {
    if [ ! -f "$CURRENT_SPRINT" ]; then
        echo -e "${RED}❌ Sprint não encontrada em $CURRENT_SPRINT${NC}"
        return 1
    fi
    
    local status=$(jq -r '.status' "$CURRENT_SPRINT")
    
    if [ "$status" == "in_progress" ]; then
        echo -e "${YELLOW}⚠️  Sprint já está em execução${NC}"
        show_status
        return 0
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Atualiza status
    jq --arg date "$timestamp" \
       '.status = "in_progress" | .start_date = $date | .last_updated = $date' \
       "$CURRENT_SPRINT" > "${CURRENT_SPRINT}.tmp" && mv "${CURRENT_SPRINT}.tmp" "$CURRENT_SPRINT"
    
    # Log de contexto
    if command -v ctxgit_log >/dev/null; then
        local sprint_id=$(jq -r '.sprint_id' "$CURRENT_SPRINT")
        ctxgit_log "start_sprint" "$sprint_id" "Iniciando sprint de desenvolvimento" "" "gemini-cli"
    fi

    echo -e "${GREEN}✅ Sprint iniciada!${NC}"
    echo ""
    show_status
}

# Função para listar próxima ação
next_action() {
    if [ ! -f "$CURRENT_SPRINT" ]; then
        echo -e "${RED}❌ Nenhuma sprint ativa${NC}"
        return 1
    fi
    
    local next_task=$(jq -r '.next_action.task_id' "$CURRENT_SPRINT")
    local next_step=$(jq -r '.next_action.step' "$CURRENT_SPRINT")
    local description=$(jq -r '.next_action.description' "$CURRENT_SPRINT")
    
    echo -e "${YELLOW}📍 Próxima Ação:${NC}"
    echo "   Task: $next_task"
    echo "   Step: $next_step"
    echo "   Descrição: $description"
}

# Função para atualizar progresso de task
update_task() {
    local task_id="$1"
    local new_status="$2"
    local notes="${3:-}"
    
    if [ -z "$task_id" ] || [ -z "$new_status" ]; then
        echo -e "${RED}❌ Uso: ./sprint.sh update-task <task-id> <status> [notas]${NC}"
        echo "   Status possíveis: pending, in_progress, completed, blocked"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Atualiza task
    jq --arg task "$task_id" \
       --arg status "$new_status" \
       --arg notes "$notes" \
       --arg date "$timestamp" \
       '.tasks = [.tasks[] | if .task_id == $task then .status = $status | .notes = $notes | .last_updated = $date else . end] | .last_updated = $date' \
       "$CURRENT_SPRINT" > "${CURRENT_SPRINT}.tmp" && mv "${CURRENT_SPRINT}.tmp" "$CURRENT_SPRINT"
    
    # Se iniciou, atualiza current_task
    if [ "$new_status" == "in_progress" ]; then
        jq --arg task "$task_id" \
           '.current_task = $task' \
           "$CURRENT_SPRINT" > "${CURRENT_SPRINT}.tmp" && mv "${CURRENT_SPRINT}.tmp" "$CURRENT_SPRINT"
        
        # Log de contexto
        if command -v ctxgit_log >/dev/null; then
            ctxgit_log "start_task" "$task_id" "Iniciando execução da tarefa" "$task_id" "gemini-cli"
        fi
    fi
    
    # Se completou, atualiza contadores e limpa current_task se for a atual
    if [ "$new_status" == "completed" ]; then
        local completed=$(jq '[.tasks[] | select(.status == "completed")] | length' "$CURRENT_SPRINT")
        local total=$(jq '.tasks | length' "$CURRENT_SPRINT")
        local current=$(jq -r '.current_task' "$CURRENT_SPRINT")
        
        # Se a task completada é a atual, limpa current_task
        if [ "$current" == "$task_id" ]; then
            jq --argjson completed "$completed" \
               --argjson total "$total" \
               '.overall_progress.completed = $completed | .overall_progress.pending = ($total - $completed) | .current_task = null' \
               "$CURRENT_SPRINT" > "${CURRENT_SPRINT}.tmp" && mv "${CURRENT_SPRINT}.tmp" "$CURRENT_SPRINT"
        else
            jq --argjson completed "$completed" \
               --argjson total "$total" \
               '.overall_progress.completed = $completed | .overall_progress.pending = ($total - $completed)' \
               "$CURRENT_SPRINT" > "${CURRENT_SPRINT}.tmp" && mv "${CURRENT_SPRINT}.tmp" "$CURRENT_SPRINT"
        fi

        # Log de contexto
        if command -v ctxgit_log >/dev/null; then
            ctxgit_log "complete_task" "$task_id" "Tarefa concluída com sucesso" "$task_id" "gemini-cli"
        fi
    fi
    
    echo -e "${GREEN}✅ Task $task_id atualizada para: $new_status${NC}"
}

# Função para criar checkpoint
checkpoint() {
    local message="${1:-Checkpoint automático}"
    local task_id=$(jq -r '.current_task // "unknown"' "$CURRENT_SPRINT")
    local timestamp=$(date +%s%N | cut -c1-16)
    local checkpoint_id="cp-$timestamp"
    
    mkdir -p "$SPRINT_DIR/current/checkpoints"
    
    cat > "$SPRINT_DIR/current/checkpoints/$checkpoint_id.json" <<EOF
{
  "checkpoint_id": "$checkpoint_id",
  "task_id": "$task_id",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "message": "$message",
  "git_commit": "$(git rev-parse --short HEAD 2>/dev/null || echo 'none')",
  "files_modified": $(git diff --name-only 2>/dev/null | jq -R . | jq -s . || echo '[]')
}
EOF
    
    # Atualiza contador
    jq '.session_context.checkpoints_created += 1' "$CURRENT_SPRINT" > "${CURRENT_SPRINT}.tmp" && mv "${CURRENT_SPRINT}.tmp" "$CURRENT_SPRINT"
    
    # Log de contexto
    if command -v ctxgit_log >/dev/null; then
        ctxgit_log "checkpoint" "$checkpoint_id" "$message" "$task_id" "gemini-cli"
    fi

    echo -e "${GREEN}✅ Checkpoint criado: $checkpoint_id${NC}"
}

# Função para mostrar handoffs pendentes
show_handoffs() {
    local pending_dir="$SPRINT_DIR/handoffs/pending"
    
    if [ ! -d "$pending_dir" ] || [ -z "$(ls -A $pending_dir 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ Nenhum handoff pendente${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🚨 Handoffs Pendentes:${NC}"
    for file in "$pending_dir"/*.md; do
        [ -e "$file" ] || continue
        local task_id=$(basename "$file" .md)
        echo "   📄 $task_id"
        head -5 "$file" | sed 's/^/      /'
    done
}

# Função para pausar sprint (rate limit / interrupção)
pause_sprint() {
    local reason="${1:-Interrupção manual}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Cria checkpoint de emergência
    checkpoint "Pausa: $reason"
    
    # Atualiza status
    jq --arg reason "$reason" \
       --arg date "$timestamp" \
       '.status = "paused" | .pause_reason = $reason | .last_updated = $date' \
       "$CURRENT_SPRINT" > "${CURRENT_SPRINT}.tmp" && mv "${CURRENT_SPRINT}.tmp" "$CURRENT_SPRINT"
    
    echo -e "${YELLOW}⏸️  Sprint pausada${NC}"
    echo "   Motivo: $reason"
    echo ""
    echo -e "${BLUE}💡 Para retomar:${NC} ./sprint.sh resume"
}

# Função para retomar sprint
resume_sprint() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Atualiza status
    jq --arg date "$timestamp" \
       '.status = "in_progress" | del(.pause_reason) | .last_updated = $date | .session_context.sessions_count += 1' \
       "$CURRENT_SPRINT" > "${CURRENT_SPRINT}.tmp" && mv "${CURRENT_SPRINT}.tmp" "$CURRENT_SPRINT"
    
    echo -e "${GREEN}✅ Sprint retomada!${NC}"
    echo ""
    
    # Mostra onde parou
    local current_task=$(jq -r '.current_task // "Nenhuma"' "$CURRENT_SPRINT")
    echo -e "${YELLOW}📍 Você estava trabalhando em:${NC} $current_task"
    echo ""
    
    show_status
}

# Função para bloquear task
block_task() {
    local task_id="$1"
    local reason="${2:-Bloqueio sem especificação}"
    
    update_task "$task_id" "blocked" "$reason"
    
    # Cria arquivo de bloqueio detalhado
    mkdir -p "$SPRINT_DIR/blocked"
    cat > "$SPRINT_DIR/blocked/$task_id.json" <<EOF
{
  "task_id": "$task_id",
  "blocked_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "reason": "$reason",
  "escalated": true
}
EOF
    
    echo -e "${RED}🚫 Task bloqueada e escalonada para revisão${NC}"
}

# Função para mostrar ajuda
show_help() {
    echo "Sprint Management Helper"
    echo ""
    echo "Uso: ./sprint.sh [comando] [argumentos]"
    echo ""
    echo "Comandos:"
    echo "  status                    Mostrar status atual da sprint"
    echo "  start                     Iniciar sprint"
    echo "  next                      Mostrar próxima ação"
    echo "  update-task <id> <status> [notas]  Atualizar status de task"
    echo "  checkpoint [mensagem]     Criar checkpoint"
    echo "  handoffs                  Mostrar handoffs pendentes"
    echo "  pause [motivo]            Pausar sprint (rate limit, etc)"
    echo "  resume                    Retomar sprint pausada"
    echo "  block <task-id> [motivo]  Bloquear task"
    echo "  help                      Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  ./sprint.sh start"
    echo "  ./sprint.sh update-task task-1.1 in_progress 'Implementando validação'"
    echo "  ./sprint.sh checkpoint 'Antes de refatorar'"
    echo "  ./sprint.sh pause 'Rate limit atingido'"
}

# Main
case "${1:-status}" in
    "status")
        show_status
        ;;
    "start")
        start_sprint
        ;;
    "next")
        next_action
        ;;
    "update-task")
        update_task "$2" "$3" "$4"
        ;;
    "checkpoint")
        checkpoint "$2"
        ;;
    "handoffs")
        show_handoffs
        ;;
    "pause")
        pause_sprint "$2"
        ;;
    "resume")
        resume_sprint
        ;;
    "block")
        block_task "$2" "$3"
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando desconhecido: $1${NC}"
        show_help
        exit 1
        ;;
esac
