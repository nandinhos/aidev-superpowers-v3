#!/bin/bash
# skill-runner.sh - Interface CLI para gerenciar Skills
# Transforma skills de documentos .md em ferramentas acionáveis
#
# Uso:
#   source .aidev/lib/skill-runner.sh
#   skill list                    # Lista todas as skills
#   skill start <name>           # Inicia uma skill
#   skill step <n>               # Avança para step N
#   skill complete                # Finaliza skill
#   skill status                  # Ver estado atual
#   skill fail <reason>          # Marca falha
#   skill validate                # Valida checkpoint atual

AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SKILLS_DIR="$AIDEV_ROOT/skills"
STATE_FILE="$AIDEV_ROOT/state/skills.json"

# Estado atual
CURRENT_SKILL=""
CURRENT_STEP=0
SKILL_METADATA=""

# ============================================================================
# HELPERS
# ============================================================================

skill_log() {
    echo "[skill-runner] $1"
}

skill_error() {
    echo "[skill-runner ERROR] $1" >&2
}

# ============================================================================
# LISTAR SKILLS
# ============================================================================

skill_list() {
    echo "=== Skills Disponíveis ==="
    
    local count=0
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_name=$(basename "$skill_dir")
        
        # Verificar se tem SKILL.md
        if [ -f "$skill_dir/SKILL.md" ]; then
            local steps=$(grep -E "^steps:" "$skill_dir/SKILL.md" | head -1 | awk '{print $2}')
            local status="inativa"
            
            # Verificar se está ativa
            if [ "$CURRENT_SKILL" = "$skill_name" ]; then
                status="ativa (step $CURRENT_STEP/$steps)"
            fi
            
            printf "  %-25s | Steps: %s | %s\n" "$skill_name" "${steps:-?}" "$status"
            count=$((count + 1))
        fi
    done
    
    echo ""
    echo "Total: $count skills"
}

# ============================================================================
# CARREGAR METADATA DE SKILL
# ============================================================================

skill_load_metadata() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"
    
    if [ ! -f "$skill_file" ]; then
        skill_error "Skill '$skill_name' não encontrada"
        return 1
    fi
    
    SKILL_METADATA=$(cat "$skill_file")
    
    # Extrair informações
    local steps=$(echo "$SKILL_METADATA" | grep -E "^steps:" | head -1 | awk '{print $2}')
    local checkpoints=$(echo "$SKILL_METADATA" | grep -E "^checkpoints:" -A 10 | grep -E "^\s+-\s+" | wc -l)
    local artifact=$(echo "$SKILL_METADATA" | grep -E "^artifact:" | head -1 | awk -F': ' '{print $2}')
    
    echo "$steps|$checkpoints|$artifact"
}

# ============================================================================
# INICIAR SKILL
# ============================================================================

skill_start() {
    local skill_name="$1"
    
    if [ -z "$skill_name" ]; then
        skill_error "Uso: skill start <nome_da_skill>"
        return 1
    fi
    
    local skill_dir="$SKILLS_DIR/$skill_name"
    if [ ! -d "$skill_dir" ]; then
        skill_error "Skill '$skill_name' não encontrada em $SKILLS_DIR"
        echo "Execute 'skill list' para ver as skills disponíveis"
        return 1
    fi
    
    if [ ! -f "$skill_dir/SKILL.md" ]; then
        skill_error "Arquivo SKILL.md não encontrado para '$skill_name'"
        return 1
    fi
    
    # Carregar metadata
    local metadata=$(skill_load_metadata "$skill_name")
    local steps=$(echo "$metadata" | cut -d'|' -f1)
    
    # Atualizar estado
    CURRENT_SKILL="$skill_name"
    CURRENT_STEP=1
    
    # Salvar estado
    skill_save_state
    
    echo "✓ Skill '$skill_name' iniciada (Step 1/$steps)"
    echo ""
    echo "Para avançar: skill step <n>"
    echo "Para ver status: skill status"
}

# ============================================================================
# AVANÇAR STEP
# ============================================================================

skill_step() {
    local step_num="${1:-1}"
    
    if [ -z "$CURRENT_SKILL" ]; then
        skill_error "Nenhuma skill ativa. Execute 'skill start <nome>' primeiro."
        return 1
    fi
    
    # Carregar metadata
    local metadata=$(skill_load_metadata "$CURRENT_SKILL")
    local total_steps=$(echo "$metadata" | cut -d'|' -f1)
    
    if [ "$step_num" -gt "$total_steps" ]; then
        skill_error "Step $step_num inválido. Máximo: $total_steps"
        return 1
    fi
    
    CURRENT_STEP="$step_num"
    skill_save_state
    
    echo "✓ Avançado para Step $CURRENT_STEP/$total_steps"
    
    # Mostrar informações do step
    skill_show_step_info
}

# ============================================================================
# MOSTRAR INFO DO STEP
# ============================================================================

skill_show_step_info() {
    local skill_file="$SKILLS_DIR/$CURRENT_SKILL/SKILL.md"
    
    echo ""
    echo "=== Step $CURRENT_STEP ==="
    
    # Extrair título do step atual
    local step_title=$(awk -v step="$CURRENT_STEP" '
        /^## Step [0-9]+:/ {
            current = gsub(/.*## Step /, "").1
            gsub(/:.*/, "", current)
            if (current == step) {
                getline; getline
                print
                exit
            }
        }
    ' "$skill_file")
    
    if [ -n "$step_title" ]; then
        echo "$step_title"
    fi
}

# ============================================================================
# COMPLETAR SKILL
# ============================================================================

skill_complete() {
    if [ -z "$CURRENT_SKILL" ]; then
        skill_error "Nenhuma skill ativa"
        return 1
    fi
    
    echo "✓ Skill '$CURRENT_SKILL' completada!"
    
    # Limpar estado
    CURRENT_SKILL=""
    CURRENT_STEP=0
    skill_save_state
    
    echo ""
    echo "Próximas sugestões:"
    echo "  - Iniciar nova skill: skill start <nome>"
    echo "  - Listar skills: skill list"
}

# ============================================================================
# MARCAR FALHA
# ============================================================================

skill_fail() {
    local reason="$1"
    
    if [ -z "$CURRENT_SKILL" ]; then
        skill_error "Nenhuma skill ativa"
        return 1
    fi
    
    echo "✗ Skill '$CURRENT_SKILL' marcada como falha"
    echo "  Motivo: $reason"
    
    # Salvar falha
    skill_save_state "failed"
    
    # Limpar estado atual
    CURRENT_SKILL=""
    CURRENT_STEP=0
    skill_save_state
}

# ============================================================================
# VER STATUS
# ============================================================================

skill_status() {
    if [ -z "$CURRENT_SKILL" ]; then
        echo "=== Nenhuma skill ativa ==="
        echo "Execute 'skill start <nome>' para iniciar"
        return 0
    fi
    
    local metadata=$(skill_load_metadata "$CURRENT_SKILL")
    local total_steps=$(echo "$metadata" | cut -d'|' -f1)
    local checkpoints=$(echo "$metadata" | cut -d'|' -f2)
    local artifact=$(echo "$metadata" | cut -d'|' -f3)
    
    echo "=== Skill Ativa ==="
    echo "  Nome: $CURRENT_SKILL"
    echo "  Step: $CURRENT_STEP / $total_steps"
    echo "  Checkpoints: $checkpoints"
    echo "  Artefato: ${artifact:-N/A}"
    echo ""
    
    skill_show_step_info
}

# ============================================================================
# VALIDAR CHECKPOINT
# ============================================================================

skill_validate() {
    if [ -z "$CURRENT_SKILL" ]; then
        skill_error "Nenhuma skill ativa"
        return 1
    fi
    
    local metadata=$(skill_load_metadata "$CURRENT_SKILL")
    local checkpoints=$(echo "$metadata" | cut -d'|' -f2)
    
    echo "=== Validando Checkpoint ==="
    echo "Skill: $CURRENT_SKILL"
    echo "Step: $CURRENT_STEP"
    echo "Checkpoints definidos: $checkpoints"
    echo ""
    echo "✓ Validação simulada (implemente lógica real por skill)"
}

# ============================================================================
# SALVAR ESTADO
# ============================================================================

skill_save_state() {
    local status="${1:-active}"
    
    mkdir -p "$(dirname "$STATE_FILE")"
    
    cat > "$STATE_FILE" <<EOF
{
  "active_skill": "$CURRENT_SKILL",
  "current_step": $CURRENT_STEP,
  "status": "$status",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

# ============================================================================
# CARREGAR ESTADO ANTERIOR
# ============================================================================

skill_load_state() {
    if [ -f "$STATE_FILE" ]; then
        CURRENT_SKILL=$(grep -o '"active_skill": *"[^"]*"' "$STATE_FILE" | cut -d'"' -f4)
        CURRENT_STEP=$(grep -o '"current_step": *[0-9]*' "$STATE_FILE" | grep -o '[0-9]*')
    fi
}

# ============================================================================
# MAIN (quando executado diretamente)
# ============================================================================

skill_main() {
    local action="$1"
    shift
    
    case "$action" in
        list)
            skill_list
            ;;
        start)
            skill_start "$@"
            ;;
        step)
            skill_step "$@"
            ;;
        complete)
            skill_complete
            ;;
        fail)
            skill_fail "$@"
            ;;
        status)
            skill_status
            ;;
        validate)
            skill_validate
            ;;
        help|--help|-h)
            echo "Usage: skill <command> [options]"
            echo ""
            echo "Commands:"
            echo "  list                    List all available skills"
            echo "  start <name>           Start a skill"
            echo "  step <n>               Advance to step n"
            echo "  complete                Complete current skill"
            echo "  fail <reason>          Mark skill as failed"
            echo "  status                  Show current skill status"
            echo "  validate                Validate current checkpoint"
            ;;
        *)
            skill_error "Comando desconhecido: $action"
            echo "Execute 'skill help' para ver os comandos disponíveis"
            return 1
            ;;
    esac
}

# Carregar estado anterior ao iniciar
skill_load_state

# Se executado diretamente (não sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    skill_main "$@"
fi
