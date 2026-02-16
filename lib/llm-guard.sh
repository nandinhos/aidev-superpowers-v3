#!/usr/bin/env bash

# ============================================================================
# AI Dev Superpowers V3 - LLM Guard Module
# ============================================================================
# Motor de validacao pre-execucao para controlar escopo, limites e auditoria
# das acoes das LLMs. Usa manifesto para classificar arquivos e enforce limits.
#
# Uso: source lib/llm-guard.sh
# Dependencias: lib/core.sh, lib/file-ops.sh, lib/manifest.sh, lib/state.sh
# ============================================================================

# Defaults para limites
LLM_GUARD_MAX_FILES=${LLM_GUARD_MAX_FILES:-10}
LLM_GUARD_MAX_LINES=${LLM_GUARD_MAX_LINES:-200}

# ============================================================================
# llm_guard_validate_scope - Valida escopo de arquivos propostos
# ============================================================================
# Rejeita modificacoes em arquivos core ou state via manifesto.
# Uso: llm_guard_validate_scope '["file1.js", "file2.js"]'
# Retorna: 0 se todos permitidos, 1 se algum protegido
llm_guard_validate_scope() {
    local proposed_files_json="$1"

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    # Garante que manifesto esta carregado
    if [ "$MANIFEST_LOADED" != "true" ]; then
        manifest_load 2>/dev/null || return 0
    fi

    local file
    local blocked_files=""

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        local policy
        policy=$(manifest_get_policy "$file" 2>/dev/null)
        # Bloqueia apenas core e state; user (never_touch) eh permitido para LLM
        case "$policy" in
            never_modify_in_project|never_overwrite)
                blocked_files="${blocked_files}${file} "
                ;;
        esac
    done < <(echo "$proposed_files_json" | jq -r '.[]' 2>/dev/null)

    if [ -n "$blocked_files" ]; then
        echo "[LLM GUARD] Bloqueado: arquivos protegidos: $blocked_files" >&2
        return 1
    fi

    return 0
}

# ============================================================================
# llm_guard_enforce_limits - Le e retorna limites configurados
# ============================================================================
# Le limites de .aidev/rules/llm-limits.md ou retorna defaults.
# Uso: limits=$(llm_guard_enforce_limits "/path/to/project")
# Stdout: linhas KEY=VALUE
llm_guard_enforce_limits() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local limits_file="$install_path/.aidev/rules/llm-limits.md"

    local max_files="$LLM_GUARD_MAX_FILES"
    local max_lines="$LLM_GUARD_MAX_LINES"

    if [ -f "$limits_file" ]; then
        local parsed
        parsed=$(grep -oP 'MAX_FILES_PER_CYCLE=\K[0-9]+' "$limits_file" 2>/dev/null)
        [ -n "$parsed" ] && max_files="$parsed"

        parsed=$(grep -oP 'MAX_LINES_PER_FILE=\K[0-9]+' "$limits_file" 2>/dev/null)
        [ -n "$parsed" ] && max_lines="$parsed"
    fi

    echo "MAX_FILES_PER_CYCLE=$max_files"
    echo "MAX_LINES_PER_FILE=$max_lines"
}

# ============================================================================
# llm_guard_log_decision - Registra decisao no confidence_log
# ============================================================================
# Reutiliza state_log_confidence() de lib/state.sh
# Uso: llm_guard_log_decision "decisao" "reasoning" "score"
llm_guard_log_decision() {
    local decision="$1"
    local reasoning="$2"
    local score="${3:-0.5}"

    # Usa state_log_confidence se disponivel
    if type state_log_confidence &>/dev/null; then
        state_log_confidence "[LLM-GUARD] $decision: $reasoning" "$score"
    fi
}

# ============================================================================
# llm_guard_audit - Append entrada de auditoria em audit.log
# ============================================================================
# Uso: llm_guard_audit "session_id" "action" "result"
llm_guard_audit() {
    local session_id="$1"
    local action="$2"
    local result="$3"
    local install_path="${CLI_INSTALL_PATH:-.}"
    local audit_file="$install_path/.aidev/state/audit.log"

    # Garante diretorio existe
    mkdir -p "$(dirname "$audit_file")" 2>/dev/null || true

    local timestamp
    timestamp=$(date -Iseconds 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")

    echo "$timestamp | session=$session_id | action=$action | result=$result" >> "$audit_file"
}

# ============================================================================
# llm_guard_pre_check - Gate unificado pre-execucao
# ============================================================================
# Combina: validate_scope + enforce_limits
# Uso: llm_guard_pre_check "action" '["file1.js"]'
# Retorna: 0 se permitido, 1 se bloqueado
llm_guard_pre_check() {
    local action="$1"
    local target_files_json="$2"
    local install_path="${CLI_INSTALL_PATH:-.}"

    # 1. Validar escopo (arquivos protegidos)
    if ! llm_guard_validate_scope "$target_files_json" 2>/dev/null; then
        llm_guard_audit "${LLM_GUARD_SESSION_ID:-unknown}" "$action" "blocked:scope" 2>/dev/null
        llm_guard_log_decision "Bloqueado por escopo" "$action em arquivos protegidos" "0.1" 2>/dev/null
        return 1
    fi

    # 2. Validar limites (numero de arquivos)
    if command -v jq &>/dev/null; then
        local file_count
        file_count=$(echo "$target_files_json" | jq 'length' 2>/dev/null)
        file_count="${file_count:-0}"

        local limits
        limits=$(llm_guard_enforce_limits "$install_path")
        local max_files
        max_files=$(echo "$limits" | grep -oP 'MAX_FILES_PER_CYCLE=\K[0-9]+')
        max_files="${max_files:-$LLM_GUARD_MAX_FILES}"

        if [ "$file_count" -gt "$max_files" ]; then
            echo "[LLM GUARD] Bloqueado: $file_count arquivos excedem limite de $max_files" >&2
            llm_guard_audit "${LLM_GUARD_SESSION_ID:-unknown}" "$action" "blocked:limit_files" 2>/dev/null
            llm_guard_log_decision "Bloqueado por limite" "$file_count arquivos > $max_files" "0.2" 2>/dev/null
            return 1
        fi
    fi

    # 3. Tudo ok
    llm_guard_audit "${LLM_GUARD_SESSION_ID:-unknown}" "$action" "allowed" 2>/dev/null
    llm_guard_log_decision "Permitido" "$action" "0.9" 2>/dev/null
    return 0
}
