#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Triggers Module
# ============================================================================
# Engine de detecção automática de contextos e gatilhos
#
# Uso: source lib/triggers.sh
# Dependências: lib/core.sh, lib/kb.sh, jq, python3
# ============================================================================

# Arquivo de estado para cooldowns
readonly AIDEV_TRIGGERS_STATE="${CLI_INSTALL_PATH:-.}/.aidev/state/triggers.json"

# ============================================================================
# Parser e Carregamento
# ============================================================================

# Carrega triggers do arquivo YAML e converte para JSON temporário para processamento rápido
# Uso: triggers__load
triggers__load() {
    local yaml_file="${CLI_INSTALL_PATH:-.}/.aidev/triggers/lesson-capture.yaml"
    
    if [ ! -f "$yaml_file" ]; then
        print_debug "Arquivo de triggers não encontrado: $yaml_file"
        return 1
    fi

    # Converte YAML para JSON usando Python (suporte a listas de objetos)
    # Cache do JSON em memória (variável global para a sessão)
    AIDEV_TRIGGERS_JSON=$(python3 -c "import yaml, json, sys; print(json.dumps(yaml.safe_load(sys.stdin)))" < "$yaml_file" 2>/dev/null)
    
    if [ -z "$AIDEV_TRIGGERS_JSON" ] || [ "$AIDEV_TRIGGERS_JSON" = "null" ]; then
        print_error "Falha ao processar arquivo de triggers (YAML inválido?)"
        return 1
    fi

    return 0
}

# ============================================================================
# Monitoramento
# ============================================================================

# Verifica se uma string de erro dispara algum trigger
# Uso: triggers__watch_errors "mensagem de erro"
triggers__watch_errors() {
    local error_msg="$1"
    [ -z "$error_msg" ] && return 0
    [ -z "$AIDEV_TRIGGERS_JSON" ] && triggers__load || true
    [ -z "$AIDEV_TRIGGERS_JSON" ] && return 0

    # Itera sobre triggers do tipo error_pattern
    echo "$AIDEV_TRIGGERS_JSON" | jq -c '.triggers[] | select(.type == "error_pattern" and .enabled == true)' | while read -r trigger; do
        local id=$(echo "$trigger" | jq -r '.id')
        local patterns=$(echo "$trigger" | jq -r '.patterns[]')
        
        # Verifica cooldown
        if triggers__is_on_cooldown "$id"; then
            print_debug "Trigger $id em cooldown. Ignorando..."
            continue
        fi

        while read -r pattern; do
            if [[ "$error_msg" =~ $pattern ]]; then
                local message=$(echo "$trigger" | jq -r '.message')
                local action=$(echo "$trigger" | jq -r '.action')
                
                print_debug "Trigger matched: $id (Pattern: $pattern)"
                triggers__handle_match "$id" "$message" "$action" "$error_msg"
                return 0 # Para no primeiro match de erro
            fi
        done <<< "$patterns"
    done
}

# Detecta intenção do usuário baseada em palavras-chave
# Uso: triggers__detect_intent "input do usuário"
triggers__detect_intent() {
    local input="$1"
    [ -z "$input" ] && return 0
    [ -z "$AIDEV_TRIGGERS_JSON" ] && triggers__load || true
    [ -z "$AIDEV_TRIGGERS_JSON" ] && return 0

    # Itera sobre triggers do tipo user_intent
    echo "$AIDEV_TRIGGERS_JSON" | jq -c '.triggers[] | select(.type == "user_intent" and .enabled == true)' | while read -r trigger; do
        local id=$(echo "$trigger" | jq -r '.id')
        local keywords=$(echo "$trigger" | jq -r '.keywords[]')
        local threshold=$(echo "$trigger" | jq -r '.confidence_threshold // 0.7')
        
        local match_count=0
        local total_keywords=0
        while read -r kw; do
            ((total_keywords++)) || true
            if [[ "${input,,}" == *"${kw,,}"* ]]; then
                ((match_count++)) || true
            fi
        done <<< "$keywords"

        local confidence=$(echo "scale=2; $match_count / $total_keywords" | bc 2>/dev/null || echo 0)
        
        if (( $(echo "$confidence >= $threshold" | bc -l) )); then
            local action=$(echo "$trigger" | jq -r '.action')
            local message=$(echo "$trigger" | jq -r '.message // "Detectado intenção relevante."')
            
            print_debug "Intent matched: $id (Confidence: $confidence)"
            triggers__handle_match "$id" "$message" "$action" "$input"
            return 0
        fi
    done
}

# ============================================================================
# Helpers de Execução
# ============================================================================

# Verifica se um trigger está em período de cooldown
triggers__is_on_cooldown() {
    local id="$1"
    [ ! -f "$AIDEV_TRIGGERS_STATE" ] && return 1

    local last_executed=$(jq -r --arg id "$id" '.[$id].last_executed // 0' "$AIDEV_TRIGGERS_STATE")
    local cooldown=$(echo "$AIDEV_TRIGGERS_JSON" | jq -r --arg id "$id" '.triggers[] | select(.id == $id) | .cooldown // 300')
    local now=$(date +%s)
    
    if (( now - last_executed < cooldown )); then
        return 0 # Está em cooldown
    fi
    return 1
}

# Registra execução para cooldown
triggers__register_execution() {
    local id="$1"
    local now=$(date +%s)
    
    mkdir -p "$(dirname "$AIDEV_TRIGGERS_STATE")"
    if [ ! -f "$AIDEV_TRIGGERS_STATE" ]; then
        echo "{}" > "$AIDEV_TRIGGERS_STATE"
    fi

    local tmp_file=$(mktemp)
    jq --arg id "$id" --arg now "$now" '.[$id].last_executed = ($now|tonumber)' "$AIDEV_TRIGGERS_STATE" > "$tmp_file" && mv "$tmp_file" "$AIDEV_TRIGGERS_STATE"
}

# Lida com o match de um trigger
triggers__handle_match() {
    local id="$1"
    local message="$2"
    local action="$3"
    local context="$4"

    echo ""
    print_warning "[TRIGGER: $id] $message"
    
    case "$action" in
        "suggest_learned_lesson")
            triggers__suggest_lesson_capture "$context"
            ;;
        "search_similar_lesson")
            triggers__search_similar "$context"
            ;;
        "activate_learned_lesson_skill")
            print_info "Ativando skill 'learned-lesson'..."
            # Nota: A ativação real acontece via export de variáveis ou sinalização para o orquestrador
            export AIDEV_FORCE_SKILL="learned-lesson"
            ;;
        *)
            print_info "Ação '$action' executada."
            ;;
    esac

    triggers__register_execution "$id"
}

# Sugere documentar uma nova lição
triggers__suggest_lesson_capture() {
    local context="$1"
    print_info "Deseja documentar esta lição agora? (y/N)"
    
    # Verifica se stdin é um terminal
    if [ -t 0 ] && [ "${AIDEV_INTERACTIVE:-true}" = "true" ]; then
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            aidev agent --skill learned-lesson --context "$context"
        fi
    else
        print_debug "Pulando prompt interativo (não é um TTY ou AIDEV_INTERACTIVE=false)"
    fi
}

# Busca lições similares no KB
triggers__search_similar() {
    local query="$1"
    print_section "Buscando lições similares..."
    
    # Usa o módulo kb.sh para busca
    if type search_lessons &>/dev/null; then
        search_lessons "$query"
    else
        print_error "Módulo KB não disponível para busca."
    fi
}
