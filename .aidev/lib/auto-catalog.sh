#!/bin/bash
# auto-catalog.sh - Sistema de auto-catalogação de lições aprendidas
# Detecta automaticamente quando erros são resolvidos e cataloga no KB

source "${BASH_SOURCE%/*}/validators.sh" 2>/dev/null || true

# Configurações
AUTO_CATALOG_ENABLED="${AUTO_CATALOG_ENABLED:-true}"
KB_DIR="${KB_DIR:-.aidev/memory/kb}"
ERROR_DETECTOR_STATE=".aidev/state/error-detector.json"

# ============================================================================
# DETECTOR DE ERROS
# ============================================================================

# Inicializa detector de erros para uma task
error_detector_init() {
    local task_id="$1"
    local error_pattern="$2"
    local context="${3:-}"
    
    mkdir -p "$(dirname "$ERROR_DETECTOR_STATE")"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local entry=$(jq -n \
        --arg task "$task_id" \
        --arg pattern "$error_pattern" \
        --arg context "$context" \
        --arg date "$timestamp" \
        '{
            task_id: $task,
            error_pattern: $pattern,
            context: $context,
            detected_at: $date,
            status: "detected",
            resolution_attempts: 0,
            last_check: $date
        }')
    
    if [ -f "$ERROR_DETECTOR_STATE" ]; then
        # Verifica se já existe entry para esta task
        local exists=$(jq "map(select(.task_id == \"$task_id\")) | length" "$ERROR_DETECTOR_STATE")
        if [ "$exists" -eq 0 ]; then
            jq ". += [$entry]" "$ERROR_DETECTOR_STATE" > "${ERROR_DETECTOR_STATE}.tmp" && \
                mv "${ERROR_DETECTOR_STATE}.tmp" "$ERROR_DETECTOR_STATE"
            log_auto_catalog "INFO" "error_detector_init" "Erro registrado: $task_id"
        fi
    else
        echo "[$entry]" > "$ERROR_DETECTOR_STATE"
        log_auto_catalog "INFO" "error_detector_init" "Detector inicializado com erro: $task_id"
    fi
}

# Verifica se erro foi resolvido
error_detector_check_resolution() {
    local task_id="$1"
    local test_command="${2:-}"
    
    if [ ! -f "$ERROR_DETECTOR_STATE" ]; then
        echo "NO_STATE"
        return 1
    fi
    
    # Busca entry da task
    local entry=$(jq "map(select(.task_id == \"$task_id\")) | .[0]" "$ERROR_DETECTOR_STATE")
    
    if [ "$entry" == "null" ] || [ -z "$entry" ]; then
        echo "NOT_FOUND"
        return 1
    fi
    
    # Verifica se já está resolvido
    local status=$(echo "$entry" | jq -r '.status // "detected"')
    if [ "$status" == "resolved" ]; then
        echo "ALREADY_RESOLVED"
        return 0
    fi
    
    # Incrementa tentativas
    local attempts=$(echo "$entry" | jq -r '.resolution_attempts // 0')
    ((attempts++))
    
    jq "map(if .task_id == \"$task_id\" then .resolution_attempts = $attempts | .last_check = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\" else . end)" \
        "$ERROR_DETECTOR_STATE" > "${ERROR_DETECTOR_STATE}.tmp" && \
        mv "${ERROR_DETECTOR_STATE}.tmp" "$ERROR_DETECTOR_STATE"
    
    # Se forneceu comando de teste, executa
    if [ -n "$test_command" ]; then
        if eval "$test_command" > /dev/null 2>&1; then
            # Teste passou = erro resolvido
            error_detector_mark_resolved "$task_id"
            echo "RESOLVED"
            return 0
        fi
    fi
    
    echo "STILL_FAILING"
    return 1
}

# Marca erro como resolvido
error_detector_mark_resolved() {
    local task_id="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq "map(if .task_id == \"$task_id\" then .status = \"resolved\" | .resolved_at = \"$timestamp\" else . end)" \
        "$ERROR_DETECTOR_STATE" > "${ERROR_DETECTOR_STATE}.tmp" && \
        mv "${ERROR_DETECTOR_STATE}.tmp" "$ERROR_DETECTOR_STATE"
    
    log_auto_catalog "INFO" "error_detector_mark_resolved" "Erro resolvido: $task_id"
}

# Lista erros resolvidos não catalogados
error_detector_get_uncataloged() {
    if [ ! -f "$ERROR_DETECTOR_STATE" ]; then
        echo "[]"
        return
    fi
    
    # Filtra entries resolvidas que não têm cataloged=true
    jq '[.[] | select(.status == "resolved" and .cataloged != true)]' "$ERROR_DETECTOR_STATE"
}

# Marca erro como catalogado
error_detector_mark_cataloged() {
    local task_id="$1"
    
    jq "map(if .task_id == \"$task_id\" then .cataloged = true else . end)" \
        "$ERROR_DETECTOR_STATE" > "${ERROR_DETECTOR_STATE}.tmp" && \
        mv "${ERROR_DETECTOR_STATE}.tmp" "$ERROR_DETECTOR_STATE"
}

# ============================================================================
# AUTO-CATALOG
# ============================================================================

# Hook chamado após completar skill
auto_catalog_on_skill_complete() {
    local skill_name="$1"
    local task_id="${2:-}"
    
    if [ "$AUTO_CATALOG_ENABLED" != "true" ]; then
        return 0
    fi
    
    # Se skill for debugging ou resolução de erro
    if [[ "$skill_name" == *"debug"* ]] || [[ "$skill_name" == *"fix"* ]] || [[ "$skill_name" == *"error"* ]]; then
        log_auto_catalog "INFO" "auto_catalog_on_skill_complete" "Verificando catálogo automático para: $task_id"
        
        # Verifica se há erros resolvidos não catalogados
        local uncataloged=$(error_detector_get_uncataloged)
        local count=$(echo "$uncataloged" | jq 'length')
        
        if [ "$count" -gt 0 ]; then
            log_auto_catalog "INFO" "auto_catalog_on_skill_complete" "Detectados $count erros para catalogar"
            
            # Cataloga cada erro
            echo "$uncataloged" | jq -c '.[]' | while read -r error_entry; do
                local error_task_id=$(echo "$error_entry" | jq -r '.task_id')
                local error_pattern=$(echo "$error_entry" | jq -r '.error_pattern')
                local context=$(echo "$error_entry" | jq -r '.context // "Sem contexto"')
                
                _create_lesson_from_error "$error_task_id" "$error_pattern" "$context"
                error_detector_mark_cataloged "$error_task_id"
            done
        fi
    fi
}

# Hook chamado antes de iniciar codificação
auto_catalog_pre_coding() {
    local task_description="$1"
    
    if [ "$AUTO_CATALOG_ENABLED" != "true" ]; then
        return 0
    fi
    
    # Detecta padrões de erro na descrição
    if echo "$task_description" | grep -qiE "(erro|bug|falha|crash|exception|error|fix)"; then
        log_auto_catalog "INFO" "auto_catalog_pre_coding" "Potencial erro detectado na descrição da task"
        
        # Extrai padrão de erro (simplificado)
        local error_pattern=$(echo "$task_description" | grep -oE "[A-Z][a-z]+Error|Exception|falha ao [^ ]+|erro de [^ ]+" | head -1)
        
        if [ -n "$error_pattern" ]; then
            # Gera task_id se não fornecido
            local task_id="auto-$(date +%s%N | cut -c1-12)"
            error_detector_init "$task_id" "$error_pattern" "$task_description"
        fi
    fi
}

# Cria lição a partir de erro resolvido
_create_lesson_from_error() {
    local task_id="$1"
    local error_pattern="$2"
    local context="${3:-}"
    
    local date_str=$(date +%Y-%m-%d)
    local slug=$(echo "$error_pattern" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-30)
    local lesson_id="KB-${date_str}-$(date +%s%N | cut -c1-3)"
    local lesson_file="$KB_DIR/${date_str}-${slug}.md"
    
    mkdir -p "$KB_DIR"
    
    cat > "$lesson_file" <<EOF
---
id: ${lesson_id}
type: learned-lesson
category: bug
exception: "${error_pattern}"
stack: [generic]
tags: [auto-generated, error-resolution, ${task_id}]
resolved_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
skill_context: systematic-debugging
task_id: "${task_id}"
---

# Lição: ${error_pattern}

## Contexto
**Data**: ${date_str}
**Tarefa**: ${task_id}
**Tipo**: Resolução automática de erro

### Descrição
${context}

## Sintomas
- ${error_pattern}

## Causa Raiz
[Para completar manualmente - analisar logs e contexto]

### Análise (5 Whys)
1. **Por que falhou?** [Resposta]
2. **Por que?** [Resposta]
3. **Por que?** [Resposta]
4. **Por que?** [Resposta]
5. **Por que?** [Causa raiz]

## Solução
\`\`\`bash
# Comando ou código que resolveu
[Cole aqui a solução aplicada]
\`\`\`

### Por Que Funciona
[Explique por que esta solução resolve a causa raiz]

## Prevenção
Como evitar no futuro:
- [ ] Adicionar teste de regressão
- [ ] Atualizar documentação
- [ ] Adicionar validação preventiva
- [ ] Revisar código similar

## Referências
- Task: ${task_id}
- [Link para PR/commit]

---
*Esta lição foi gerada automaticamente. Requer revisão e completude manual.*
EOF

    log_auto_catalog "INFO" "_create_lesson_from_error" "Lição criada: $lesson_file"
    echo "$lesson_file"
}

# ============================================================================
# UTILITÁRIOS
# ============================================================================

log_auto_catalog() {
    local level="$1"
    local function="$2"
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[$timestamp] [$level] [$function] $message" >&2
}

# Estatísticas de auto-catalog
auto_catalog_stats() {
    if [ ! -f "$ERROR_DETECTOR_STATE" ]; then
        echo "📊 Auto-Catalog: Nenhum dado registrado"
        return
    fi
    
    local total=$(jq 'length' "$ERROR_DETECTOR_STATE")
    local detected=$(jq '[.[] | select(.status == "detected")] | length' "$ERROR_DETECTOR_STATE")
    local resolved=$(jq '[.[] | select(.status == "resolved")] | length' "$ERROR_DETECTOR_STATE")
    local cataloged=$(jq '[.[] | select(.cataloged == true)] | length' "$ERROR_DETECTOR_STATE")
    local pending_catalog=$(jq '[.[] | select(.status == "resolved" and (.cataloged // false) == false)] | length' "$ERROR_DETECTOR_STATE")
    
    echo "📊 Estatísticas de Auto-Catalogação"
    echo "════════════════════════════════════"
    echo "Total de erros registrados: $total"
    echo "  🟡 Detectados: $detected"
    echo "  🟢 Resolvidos: $resolved"
    echo "  ✅ Catalogados: $cataloged"
    echo "  ⏳ Pendentes de catalogação: $pending_catalog"
}

# ============================================================================
# EXPORTAÇÃO
# ============================================================================
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Foi sourced
    :
else
    echo "auto-catalog.sh - Sistema de Auto-Catalogação de Lições"
    echo ""
    echo "Funções disponíveis:"
    echo "  error_detector_init <task_id> <error_pattern> [context]"
    echo "  error_detector_check_resolution <task_id> [test_command]"
    echo "  error_detector_get_uncataloged"
    echo "  auto_catalog_on_skill_complete <skill_name> [task_id]"
    echo "  auto_catalog_pre_coding <task_description>"
    echo "  auto_catalog_stats"
    echo ""
    echo "Status: $(auto_catalog_stats)"
fi
