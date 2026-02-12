#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Context Monitor Module
# ============================================================================
# Monitoramento de janela de contexto para sessoes LLM
# Detecta uso de tokens e dispara checkpoints automaticos
#
# Uso: source lib/context-monitor.sh
# Dependencias: lib/core.sh (opcional)
# ============================================================================

# Thresholds padrao (percentual de uso de tokens)
CTX_THRESHOLD_WARNING=${CTX_THRESHOLD_WARNING:-70}
CTX_THRESHOLD_AUTO_CHECKPOINT=${CTX_THRESHOLD_AUTO_CHECKPOINT:-85}
CTX_THRESHOLD_FORCE_SAVE=${CTX_THRESHOLD_FORCE_SAVE:-95}

# Heuristica: ~4 caracteres por token (conservador)
CTX_CHARS_PER_TOKEN=${CTX_CHARS_PER_TOKEN:-4}

# ============================================================================
# ESTIMATIVA DE TOKENS
# ============================================================================

# Estima numero de tokens a partir de uma string
# Uso: ctx_estimate_tokens "texto"
# Retorna: numero inteiro de tokens estimados
ctx_estimate_tokens() {
    local text="$1"

    if [ -z "$text" ]; then
        echo "0"
        return 0
    fi

    local char_count=${#text}
    local tokens=$(( char_count / CTX_CHARS_PER_TOKEN ))

    # Minimo de 1 token se ha conteudo
    if [ "$tokens" -eq 0 ] && [ "$char_count" -gt 0 ]; then
        tokens=1
    fi

    echo "$tokens"
}

# Estima tokens a partir de um arquivo
# Uso: ctx_estimate_tokens_file "/path/to/file"
# Retorna: numero inteiro de tokens estimados
ctx_estimate_tokens_file() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "0"
        return 0
    fi

    local char_count=$(wc -c < "$file_path" 2>/dev/null || echo "0")
    char_count=$(echo "$char_count" | tr -d '[:space:]')
    local tokens=$(( char_count / CTX_CHARS_PER_TOKEN ))

    if [ "$tokens" -eq 0 ] && [ "$char_count" -gt 0 ]; then
        tokens=1
    fi

    echo "$tokens"
}

# ============================================================================
# PERCENTUAL DE USO
# ============================================================================

# Calcula percentual de uso da janela de contexto
# Uso: ctx_get_usage_percent <tokens_usados> <max_tokens>
# Retorna: inteiro 0-100
ctx_get_usage_percent() {
    local used="${1:-0}"
    local max="${2:-0}"

    if [ "$max" -eq 0 ]; then
        echo "100"
        return 0
    fi

    local percent=$(( (used * 100) / max ))

    if [ "$percent" -gt 100 ]; then
        percent=100
    fi

    echo "$percent"
}

# Calcula tokens restantes na janela
# Uso: ctx_get_remaining_capacity <tokens_usados> <max_tokens>
# Retorna: inteiro >= 0
ctx_get_remaining_capacity() {
    local used="${1:-0}"
    local max="${2:-0}"

    local remaining=$(( max - used ))

    if [ "$remaining" -lt 0 ]; then
        remaining=0
    fi

    echo "$remaining"
}

# ============================================================================
# DECISAO DE CHECKPOINT
# ============================================================================

# Determina acao baseada no percentual de uso
# Uso: ctx_should_checkpoint <percent>
# Retorna: "none" | "warning" | "auto_checkpoint" | "force_save"
ctx_should_checkpoint() {
    local percent="${1:-0}"

    if [ "$percent" -ge "$CTX_THRESHOLD_FORCE_SAVE" ]; then
        echo "force_save"
    elif [ "$percent" -ge "$CTX_THRESHOLD_AUTO_CHECKPOINT" ]; then
        echo "auto_checkpoint"
    elif [ "$percent" -ge "$CTX_THRESHOLD_WARNING" ]; then
        echo "warning"
    else
        echo "none"
    fi
}

# Retorna valor de um threshold especifico
# Uso: ctx_get_threshold "warning" | "auto_checkpoint" | "force_save"
ctx_get_threshold() {
    local name="$1"

    case "$name" in
        warning)         echo "$CTX_THRESHOLD_WARNING" ;;
        auto_checkpoint) echo "$CTX_THRESHOLD_AUTO_CHECKPOINT" ;;
        force_save)      echo "$CTX_THRESHOLD_FORCE_SAVE" ;;
        *)               echo "0" ;;
    esac
}

# ============================================================================
# FORMATACAO DE STATUS
# ============================================================================

# Formata status legivel com nivel de severidade
# Uso: ctx_format_status <percent>
# Retorna: string formatada "[LEVEL] X% de contexto utilizado"
ctx_format_status() {
    local percent="${1:-0}"

    if [ "$percent" -ge "$CTX_THRESHOLD_FORCE_SAVE" ]; then
        echo "[EMERGENCY] ${percent}% de contexto utilizado"
    elif [ "$percent" -ge "$CTX_THRESHOLD_AUTO_CHECKPOINT" ]; then
        echo "[CRITICAL] ${percent}% de contexto utilizado"
    elif [ "$percent" -ge "$CTX_THRESHOLD_WARNING" ]; then
        echo "[WARNING] ${percent}% de contexto utilizado"
    else
        echo "[SAFE] ${percent}% de contexto utilizado"
    fi
}

# ============================================================================
# ATUALIZACAO DE METRICAS
# ============================================================================

# Atualiza tokens usados no sprint-status.json
# Uso: ctx_update_session_metrics <install_path> <tokens_used>
ctx_update_session_metrics() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local tokens_used="${2:-0}"
    local sprint_file="$install_path/.aidev/state/sprints/current/sprint-status.json"

    if [ ! -f "$sprint_file" ]; then
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        local tmp_file=$(mktemp)
        jq --argjson tokens "$tokens_used" \
            '.session_context.tokens_used_in_sprint = $tokens' \
            "$sprint_file" > "$tmp_file" && mv "$tmp_file" "$sprint_file"
    fi
}
