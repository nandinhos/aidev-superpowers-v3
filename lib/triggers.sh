#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Triggers Module (Consolidado v2.0)
# ============================================================================
# Engine de detecção automática de contextos, gatilhos, state machine de
# lições aprendidas e validação pós-captura.
#
# Componentes:
#   1. Parser e carregamento de triggers YAML
#   2. Monitoramento de erros e intenções do usuário
#   3. State machine para rastreamento de lições
#   4. Validador de lições salvas (formato, seções, tags)
#
# Uso: source lib/triggers.sh (ou via load_module "triggers")
# Dependências: lib/core.sh, lib/kb.sh, jq, python3
# ============================================================================

# Arquivos de estado
readonly AIDEV_TRIGGERS_STATE="${CLI_INSTALL_PATH:-.}/.aidev/state/triggers.json"
readonly AIDEV_LESSON_STATE="${CLI_INSTALL_PATH:-.}/.aidev/state/lesson-state.json"
readonly AIDEV_LESSON_HISTORY="${CLI_INSTALL_PATH:-.}/.aidev/state/lesson-history.json"

# Estados válidos da state machine de lições
readonly LESSON_STATE_IDLE="idle"
readonly LESSON_STATE_KEYWORD_DETECTED="keyword_detected"
readonly LESSON_STATE_SKILL_SUGGESTED="skill_suggested"
readonly LESSON_STATE_SKILL_ACTIVATED="skill_activated"
readonly LESSON_STATE_LESSON_DRAFTED="lesson_drafted"
readonly LESSON_STATE_LESSON_VALIDATED="lesson_validated"
readonly LESSON_STATE_LESSON_SAVED="lesson_saved"

# Estado atual em memória
LESSON_CURRENT_STATE="$LESSON_STATE_IDLE"
LESSON_CURRENT_CONTEXT=""
LESSON_TRANSITION_COUNT=0

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

    if ! python3 -c "import yaml" 2>/dev/null; then
        print_debug "Módulo PyYAML não detectado. Processamento de triggers ignorado."
        return 0
    fi

    # Converte YAML para JSON usando Python (suporte a listas de objetos)
    # Cache do JSON em memória (variável global para a sessão)
    AIDEV_TRIGGERS_JSON=$(python3 -c "import yaml, json, sys; print(json.dumps(yaml.safe_load(sys.stdin)))" < "$yaml_file" 2>/dev/null)
    
    if [ -z "$AIDEV_TRIGGERS_JSON" ] || [ "$AIDEV_TRIGGERS_JSON" = "null" ]; then
        print_error "Falha ao processar arquivo de triggers (YAML inválido ou vazio)."
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

# ============================================================================
# State Machine — Rastreamento de Lições Aprendidas
# ============================================================================
# Rastreia o fluxo completo: detecção → sugestão → ativação → validação → salvo
# Transições são validadas, logadas e persistidas para diagnóstico.

# Valida se uma transição de estado é permitida
# Uso: triggers__validate_transition "from_state" "to_state"
triggers__validate_transition() {
    local from="$1"
    local to="$2"

    case "$from" in
        "$LESSON_STATE_IDLE")
            [[ "$to" == "$LESSON_STATE_KEYWORD_DETECTED" ]] && echo "valid" && return ;;
        "$LESSON_STATE_KEYWORD_DETECTED")
            [[ "$to" == "$LESSON_STATE_SKILL_SUGGESTED" || "$to" == "$LESSON_STATE_IDLE" ]] && echo "valid" && return ;;
        "$LESSON_STATE_SKILL_SUGGESTED")
            [[ "$to" == "$LESSON_STATE_SKILL_ACTIVATED" || "$to" == "$LESSON_STATE_IDLE" ]] && echo "valid" && return ;;
        "$LESSON_STATE_SKILL_ACTIVATED")
            [[ "$to" == "$LESSON_STATE_LESSON_DRAFTED" || "$to" == "$LESSON_STATE_IDLE" ]] && echo "valid" && return ;;
        "$LESSON_STATE_LESSON_DRAFTED")
            [[ "$to" == "$LESSON_STATE_LESSON_VALIDATED" || "$to" == "$LESSON_STATE_LESSON_SAVED" || "$to" == "$LESSON_STATE_IDLE" ]] && echo "valid" && return ;;
        "$LESSON_STATE_LESSON_VALIDATED")
            [[ "$to" == "$LESSON_STATE_LESSON_SAVED" || "$to" == "$LESSON_STATE_IDLE" ]] && echo "valid" && return ;;
        "$LESSON_STATE_LESSON_SAVED")
            [[ "$to" == "$LESSON_STATE_IDLE" ]] && echo "valid" && return ;;
    esac

    echo "invalid"
}

# Realiza transição de estado com validação e persistência
# Uso: triggers__lesson_transition "novo_estado" "contexto opcional"
triggers__lesson_transition() {
    local new_state="$1"
    local context="${2:-}"
    local old_state="$LESSON_CURRENT_STATE"

    local validation=$(triggers__validate_transition "$old_state" "$new_state")
    if [ "$validation" = "invalid" ]; then
        print_error "Transição inválida: $old_state → $new_state"
        return 1
    fi

    LESSON_CURRENT_STATE="$new_state"
    LESSON_CURRENT_CONTEXT="$context"
    LESSON_TRANSITION_COUNT=$((LESSON_TRANSITION_COUNT + 1))

    # Persistir estado
    mkdir -p "$(dirname "$AIDEV_LESSON_STATE")"
    cat > "$AIDEV_LESSON_STATE" <<EOF
{
  "state": "$LESSON_CURRENT_STATE",
  "context": "$LESSON_CURRENT_CONTEXT",
  "transition_count": $LESSON_TRANSITION_COUNT,
  "from_state": "$old_state",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

    # Adicionar ao histórico
    if command -v python3 &>/dev/null && [ -f "$AIDEV_LESSON_HISTORY" ]; then
        python3 -c "
import json
try:
    with open('$AIDEV_LESSON_HISTORY', 'r') as f:
        history = json.load(f)
except:
    history = {'transitions': [], 'total_lessons_saved': 0}

history['transitions'].append({
    'timestamp': '$(date -u +"%Y-%m-%dT%H:%M:%SZ")',
    'from': '$old_state',
    'to': '$new_state',
    'context': '$context',
    'transition_number': $LESSON_TRANSITION_COUNT
})

if '$new_state' == 'lesson_saved':
    history['total_lessons_saved'] = history.get('total_lessons_saved', 0) + 1

with open('$AIDEV_LESSON_HISTORY', 'w') as f:
    json.dump(history, f, indent=2)
" 2>/dev/null
    fi

    print_debug "Transição: $old_state → $LESSON_CURRENT_STATE"
    return 0
}

# Obtém estado atual da state machine
# Uso: triggers__lesson_state
triggers__lesson_state() {
    echo "=== State Machine de Lições ==="
    echo "Estado: $LESSON_CURRENT_STATE"
    echo "Contexto: $LESSON_CURRENT_CONTEXT"
    echo "Transições: $LESSON_TRANSITION_COUNT"
}

# Exibe histórico de transições
# Uso: triggers__lesson_history
triggers__lesson_history() {
    [ ! -f "$AIDEV_LESSON_HISTORY" ] && { echo "Nenhum histórico encontrado."; return 0; }

    python3 -c "
import json
with open('$AIDEV_LESSON_HISTORY') as f:
    data = json.load(f)

print(f\"Lições salvas: {data.get('total_lessons_saved', 0)}\")
print(f\"Total de transições: {len(data.get('transitions', []))}\")
print()
for t in data.get('transitions', [])[-10:]:
    print(f\"  [{t['timestamp']}] {t['from']} → {t['to']}\")
    if t.get('context'):
        print(f\"    Contexto: {t['context']}\")
" 2>/dev/null || echo "Erro ao ler histórico."
}

# Reseta a state machine para idle
triggers__lesson_reset() {
    LESSON_CURRENT_STATE="$LESSON_STATE_IDLE"
    LESSON_CURRENT_CONTEXT=""
    LESSON_TRANSITION_COUNT=0

    mkdir -p "$(dirname "$AIDEV_LESSON_STATE")"
    cat > "$AIDEV_LESSON_STATE" <<EOF
{
  "state": "$LESSON_STATE_IDLE",
  "context": "",
  "transition_count": 0,
  "initialized_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

    # Inicializar histórico se não existir
    if [ ! -f "$AIDEV_LESSON_HISTORY" ]; then
        echo '{"transitions": [], "total_lessons_saved": 0}' > "$AIDEV_LESSON_HISTORY"
    fi
}

# ============================================================================
# Validador de Lições — Validação Pós-Captura
# ============================================================================
# Garante que lições salvas cumprem o formato canônico:
#   - Diretório correto: .aidev/memory/kb/
#   - Nome: YYYY-MM-DD-{slug}.md
#   - Seções obrigatórias: Contexto, Problema, Causa Raiz, Solução, Prevenção
#   - Tags preenchidas

# Seções obrigatórias em lições
readonly LESSON_REQUIRED_SECTIONS="Contexto Problema Solução Prevenção"

# Valida uma lição salva
# Uso: triggers__validate_lesson "/caminho/para/licao.md"
# Retorno: 0 = válida, 1 = inválida (erros impressos)
triggers__validate_lesson() {
    local file="$1"
    local errors=0
    local warnings=0

    [ ! -f "$file" ] && {
        print_error "Arquivo não encontrado: $file"
        return 1
    }

    # 1. Verificar diretório correto
    local expected_dir="${CLI_INSTALL_PATH:-.}/.aidev/memory/kb"
    local file_dir=$(dirname "$(realpath "$file" 2>/dev/null || echo "$file")")
    if [[ "$file_dir" != *".aidev/memory/kb"* ]]; then
        print_warning "  ⚠ Diretório incorreto: $file_dir (esperado: .aidev/memory/kb/)"
        ((warnings++))
    fi

    # 2. Verificar formato do nome
    local basename=$(basename "$file")
    if ! echo "$basename" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+\.md$'; then
        print_warning "  ⚠ Nome fora do padrão: $basename (esperado: YYYY-MM-DD-slug.md)"
        ((warnings++))
    fi

    # 3. Verificar seções obrigatórias
    local content=$(cat "$file")
    for section in $LESSON_REQUIRED_SECTIONS; do
        if ! echo "$content" | grep -qiE "^#+.*$section"; then
            print_error "  ✗ Seção obrigatória ausente: $section"
            ((errors++))
        fi
    done

    # 4. Verificar tags
    if ! echo "$content" | grep -qiE '(tags|tags:|\*\*tags\*\*)'; then
        print_warning "  ⚠ Tags não encontradas"
        ((warnings++))
    fi

    # 5. Verificar referência a commit (recomendado, não obrigatório)
    if ! echo "$content" | grep -qiE '(commit|sha|hash)'; then
        print_debug "  ℹ Sem referência a commit (recomendado)"
    fi

    # Resultado
    if [ $errors -gt 0 ]; then
        print_error "Validação FALHOU: $errors erro(s), $warnings aviso(s)"
        return 1
    elif [ $warnings -gt 0 ]; then
        print_warning "Validação OK com $warnings aviso(s)"
        return 0
    else
        print_info "✓ Lição válida: $basename"
        return 0
    fi
}

# Valida todas as lições no KB
# Uso: triggers__validate_all_lessons
triggers__validate_all_lessons() {
    local kb_dir="${CLI_INSTALL_PATH:-.}/.aidev/memory/kb"
    [ ! -d "$kb_dir" ] && {
        print_info "Diretório KB não encontrado: $kb_dir"
        return 0
    }

    local total=0
    local valid=0
    local invalid=0

    echo "=== Validação do KB de Lições ==="
    for file in "$kb_dir"/*.md; do
        [ ! -f "$file" ] && continue
        ((total++))
        echo ""
        echo "--- $(basename "$file") ---"
        if triggers__validate_lesson "$file"; then
            ((valid++))
        else
            ((invalid++))
        fi
    done

    echo ""
    echo "=== Resumo ==="
    echo "Total: $total | Válidas: $valid | Inválidas: $invalid"
}

