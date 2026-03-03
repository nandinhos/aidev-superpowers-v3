#!/bin/bash
# validation-pipeline.sh - Pipeline de validação integrado
# Validações automáticas em todas as ações críticas

source "${BASH_SOURCE%/*}/validators.sh" 2>/dev/null || true
source "${BASH_SOURCE%/*}/validation-engine.sh" 2>/dev/null || true
source "${BASH_SOURCE%/*}/error-tracker.sh" 2>/dev/null || true
source "${BASH_SOURCE%/*}/kb-search.sh" 2>/dev/null || true

VALIDATION_CONFIG="${VALIDATION_CONFIG:-.aidev/config/validation.conf}"

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================

_load_validation_config() {
    # Defaults
    VALIDATION_MODE="${VALIDATION_MODE:-warning}"
    ENFORCE_TDD="${ENFORCE_TDD:-true}"
    ENFORCE_COMMIT_PT="${ENFORCE_COMMIT_PT:-true}"
    ENFORCE_COMMIT_FORMAT="${ENFORCE_COMMIT_FORMAT:-true}"
    ENFORCE_NO_EMOJI="${ENFORCE_NO_EMOJI:-true}"
    ENFORCE_SAFE_PATHS="${ENFORCE_SAFE_PATHS:-true}"
    AUTO_BACKLOG_ERRORS="${AUTO_BACKLOG_ERRORS:-true}"
    
    # Carrega config se existir
    if [ -f "$VALIDATION_CONFIG" ]; then
        source "$VALIDATION_CONFIG" 2>/dev/null || true
    fi
}

# ============================================================================
# VALIDAÇÃO PRÉ-COMMIT
# ============================================================================

validate_pre_commit() {
    local commit_msg="$1"
    local files_changed="$2"
    
    _load_validation_config
    
    echo "[VALIDATION] 🔍 Iniciando validação pré-commit..." >&2
    
    local errors=0
    local warnings=0
    
    # 1. Valida formato do commit
    if [ "$ENFORCE_COMMIT_FORMAT" == "true" ]; then
        if ! validate_commit_format "$commit_msg" 2>/dev/null; then
            ((errors++))
            echo "   ❌ Formato de commit inválido" >&2
            echo "      Esperado: tipo(escopo): descrição em português" >&2
        else
            echo "   ✅ Formato de commit válido" >&2
        fi
    fi
    
    # 2. Valida idioma (português)
    if [ "$ENFORCE_COMMIT_PT" == "true" ]; then
        if ! validate_portuguese_language "$commit_msg" 2>/dev/null; then
            ((warnings++))
            echo "   ⚠️  Commit pode estar em inglês" >&2
        else
            echo "   ✅ Idioma correto (português)" >&2
        fi
    fi
    
    # 3. Valida ausência de emoji
    if [ "$ENFORCE_NO_EMOJI" == "true" ]; then
        if ! validate_no_emoji "$commit_msg" 2>/dev/null; then
            ((errors++))
            echo "   ❌ Emojis não são permitidos em commits" >&2
        else
            echo "   ✅ Sem emojis" >&2
        fi
    fi
    
    # 4. Valida TDD (testes para arquivos modificados)
    if [ "$ENFORCE_TDD" == "true" ]; then
        local tdd_errors=0
        for file in $files_changed; do
            if [[ "$file" =~ \.(js|ts|py|php|java|go|rs)$ ]]; then
                if ! validate_test_exists "$file" 2>/dev/null; then
                    ((tdd_errors++))
                    if [ "$VALIDATION_MODE" == "strict" ]; then
                        echo "   ❌ TDD: $file não possui teste" >&2
                    else
                        echo "   ⚠️  TDD: $file não possui teste (recomendado adicionar)" >&2
                    fi
                fi
            fi
        done
        
        if [ $tdd_errors -eq 0 ]; then
            echo "   ✅ TDD: Todos os arquivos possuem testes" >&2
        else
            errors=$((errors + tdd_errors))
        fi
    fi
    
    # Resumo
    echo "" >&2
    if [ $errors -gt 0 ]; then
        echo "[VALIDATION] ❌ Validação FALHOU: $errors erro(s), $warnings warning(s)" >&2
        if [ "$VALIDATION_MODE" == "strict" ]; then
            return 1
        else
            echo "[VALIDATION] ⚠️  Modo WARNING: Prosseguindo mesmo assim" >&2
            return 0
        fi
    else
        echo "[VALIDATION] ✅ Todas as validações passaram" >&2
        return 0
    fi
}

# ============================================================================
# VALIDAÇÃO PRÉ-ESCRITA DE ARQUIVO
# ============================================================================

validate_pre_write() {
    local file_path="$1"
    local content="$2"
    
    _load_validation_config
    
    # Valida path seguro
    if [ "$ENFORCE_SAFE_PATHS" == "true" ]; then
        if ! validate_safe_path "$file_path" 2>/dev/null; then
            echo "[VALIDATION] ❌ Path não seguro: $file_path" >&2
            
            # Adiciona ao backlog se for erro crítico
            if [ "$AUTO_BACKLOG_ERRORS" == "true" ] && command -v backlog_add_error &> /dev/null; then
                backlog_add_error \
                    "Tentativa de acesso a path crítico" \
                    "Validação detectou tentativa de operação em: $file_path" \
                    "high" \
                    '["security", "validation"]'
            fi
            
            return 1
        fi
    fi
    
    # Valida padrões proibidos no conteúdo
    if ! validate_no_forbidden_patterns "$content" 2>/dev/null; then
        echo "[VALIDATION] ❌ Padrões proibidos detectados no conteúdo" >&2
        return 1
    fi
    
    return 0
}

# ============================================================================
# HOOK DE CÓDIGO
# ============================================================================

validate_coding_action() {
    local action="$1"  # create, edit, delete
    local file_path="$2"
    local content="${3:-}"
    local context="$4"
    
    _load_validation_config
    
    echo "[VALIDATION] 🔍 Validando ação: $action em $file_path" >&2
    
    case "$action" in
        "create"|"edit")
            if ! validate_pre_write "$file_path" "$content"; then
                _handle_validation_failure "$action" "$file_path" "$context"
                return 1
            fi
            ;;
        "delete")
            if ! validate_safe_path "$file_path" 2>/dev/null; then
                echo "[VALIDATION] ❌ Tentativa de deletar path crítico" >&2
                _handle_validation_failure "$action" "$file_path" "$context"
                return 1
            fi
            ;;
    esac
    
    echo "[VALIDATION] ✅ Validação aprovada" >&2
    return 0
}

_handle_validation_failure() {
    local action="$1"
    local file_path="$2"
    local context="$3"
    
    if [ "$AUTO_BACKLOG_ERRORS" == "true" ] && command -v backlog_add_error &> /dev/null; then
        backlog_add_error \
            "Falha de validação em $action" \
            "Ação: $action\nArquivo: $file_path\nContexto: $context" \
            "medium" \
            '["validation", "quality"]'
    fi
}

# ============================================================================
# HOOKS DE ORQUESTRAÇÃO
# ============================================================================

# Hook pré-codificação
pre_coding_hook() {
    local task_description="$1"
    local passport_file="${2:-}"
    
    echo "[ORCHESTRATOR] 🎯 Hook pré-codificação..." >&2
    
    # 1. Verifica lições aprendidas relevantes
    if command -v kb_check_lessons_before_action &> /dev/null; then
        if kb_check_lessons_before_action "$task_description" 30 >/dev/null 2>&1; then
            echo "[ORCHESTRATOR] 💡 Lições relevantes encontradas. Recomendo revisão." >&2
        fi
    fi
    
    # 2. Busca automática em KB
    if command -v kb_pre_coding_search &> /dev/null; then
        kb_pre_coding_search "$task_description" "$passport_file" >/dev/null 2>&1
    fi
    
    # 3. Verifica backlog crítico
    if command -v backlog_get_critical &> /dev/null; then
        local critical_errors=$(backlog_get_critical)
        local critical_count=$(echo "$critical_errors" | jq 'length')
        
        if [ "$critical_count" -gt 0 ]; then
            echo "[ORCHESTRATOR] 🚨 ATENÇÃO: $critical_count erro(s) crítico(s) no backlog!" >&2
            echo "$critical_errors" | jq -r '.[] | "   - \(.id): \(.title)"' >&2
            echo "[ORCHESTRATOR] Considere resolver antes de prosseguir." >&2
        fi
    fi
}

# Hook pós-skill
post_skill_hook() {
    local skill_name="$1"
    local task_id="$2"
    local result="$3"
    
    # Se skill foi de debugging e teve sucesso, cataloga automaticamente
    if [[ "$skill_name" == *"debug"* ]] && [ "$result" == "success" ]; then
        echo "[ORCHESTRATOR] 📝 Detectada resolução de erro. Catalogando..." >&2
        
        if command -v auto_catalog_on_skill_complete &> /dev/null; then
            auto_catalog_on_skill_complete "$skill_name" "$task_id"
        fi
    fi
}

# ============================================================================
# FUNÇÕES DE ESCRITA SEGURA
# ============================================================================

orchestrator_safe_write() {
    local file_path="$1"
    local content="$2"
    local context="${3:-write operation}"
    
    # Valida antes de escrever
    if ! validate_coding_action "create" "$file_path" "$content" "$context"; then
        echo "[ORCHESTRATOR] ❌ Escrita bloqueada pela validação" >&2
        return 1
    fi
    
    # Prossegue com escrita
    echo "$content" > "$file_path"
    echo "[ORCHESTRATOR] ✅ Arquivo criado: $file_path" >&2
    return 0
}

orchestrator_safe_edit() {
    local file_path="$1"
    local old_string="$2"
    local new_string="$3"
    local context="${4:-edit operation}"
    
    # Valida edição
    if ! validate_coding_action "edit" "$file_path" "$new_string" "$context"; then
        echo "[ORCHESTRATOR] ❌ Edição bloqueada pela validação" >&2
        return 1
    fi
    
    # Prossegue com edição
    sed -i "s/$old_string/$new_string/g" "$file_path"
    echo "[ORCHESTRATOR] ✅ Arquivo editado: $file_path" >&2
    return 0
}

orchestrator_safe_commit() {
    local commit_msg="$1"
    local files="$2"
    
    # Valida commit antes de executar
    if ! validate_pre_commit "$commit_msg" "$files"; then
        echo "[ORCHESTRATOR] ❌ Commit bloqueado pela validação" >&2
        return 1
    fi
    
    # Prossegue com commit
    git add $files
    git commit -m "$commit_msg"
    echo "[ORCHESTRATOR] ✅ Commit realizado" >&2
    return 0
}

# ============================================================================
# FLUXO PRINCIPAL
# ============================================================================

orchestrator_execute_task() {
    local task_id="$1"
    local task_description="$2"
    local agent_role="$3"
    
    echo "[ORCHESTRATOR] 🚀 Iniciando execução da task: $task_id" >&2
    
    # 1. Cria Context Passport
    local passport_file=""
    if command -v passport_create &> /dev/null; then
        local passport=$(passport_create "$task_id" "$agent_role")
        passport_file=$(passport_save "$passport")
        echo "[ORCHESTRATOR] 📋 Context Passport: $passport_file" >&2
    fi
    
    # 2. Hook pré-codificação
    pre_coding_hook "$task_description" "$passport_file"
    
    # 3. Validações durante execução (via hooks nas funções de escrita)
    echo "[ORCHESTRATOR] 🔧 Executando task..." >&2
    
    # 4. Hook pós-execução
    post_skill_hook "execution" "$task_id" "success"
    
    echo "[ORCHESTRATOR] ✅ Task concluída: $task_id" >&2
}

# ============================================================================
# CLI
# ============================================================================

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Foi sourced
    :
else
    echo "validation-pipeline.sh - Pipeline de Validação Integrado"
    echo ""
    echo "Funções disponíveis:"
    echo "  validate_pre_commit <mensagem> <arquivos>"
    echo "  validate_pre_write <arquivo> <conteudo>"
    echo "  validate_coding_action <acao> <arquivo> <conteudo> [contexto]"
    echo "  pre_coding_hook <descricao> [passport]"
    echo "  post_skill_hook <skill> <task_id> <resultado>"
    echo "  orchestrator_safe_write <arquivo> <conteudo> [contexto]"
    echo "  orchestrator_safe_edit <arquivo> <old> <new> [contexto]"
    echo "  orchestrator_safe_commit <mensagem> <arquivos>"
    echo "  orchestrator_execute_task <task_id> <descricao> <agent_role>"
    echo ""
    echo "Modo de validação atual: ${VALIDATION_MODE:-warning}"
fi
