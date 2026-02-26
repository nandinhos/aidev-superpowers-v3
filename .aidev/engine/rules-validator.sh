#!/usr/bin/env bash
# rules-validator.sh — Validação de conformidade com regras de codificação
# Parte do Rules Engine (Sprint 2: Enforcement)
#
# Uso:
#   source .aidev/engine/rules-validator.sh
#   validate_commit_format "feat(auth): adiciona login"   # → pass|warning|error
#   validate_file_count 8                                  # → pass|warning|error
#   validate_protected_path ".aidev/state/unified.json"   # → pass|warning|error
#
# Retorno: sempre imprime "pass", "warning" ou "error" em stdout
#          exit 0 em pass/warning, exit 1 em error (modo hook)

RULES_VALIDATOR_VERSION="1.0.0"

# Limites (podem ser sobrescritos por llm-limits.md)
MAX_FILES_PER_CYCLE="${MAX_FILES_PER_CYCLE:-10}"

# Tipos de commit permitidos (Conventional Commits)
VALID_COMMIT_TYPES="feat|fix|refactor|test|docs|chore|style|perf|ci|build|revert|release"

# Padrões de idioma português (palavras-chave comuns)
# Detecta mensagens claramente em inglês por ausência de padrões pt-BR
_ENGLISH_INDICATORS="^(add|update|fix|remove|delete|change|create|implement|refactor|improve|rename|move|merge|revert|bump|release|init|initial|setup|configure|enable|disable|support|allow|prevent|avoid|handle|include|exclude|skip|use|make|set|get|put|push|pull|fetch) "

# Caminhos protegidos contra edição direta pela LLM
_PROTECTED_PATHS_ERROR=(
    ".aidev/state/"
)

# Caminhos que exigem cuidado (warning)
_PROTECTED_PATHS_WARNING=(
    ".aidev/agents/orchestrator.md"
    ".aidev/agents/"
    ".aidev/lib/"
)

# ============================================================================
# validate_commit_format <mensagem>
# Verifica: tipo válido, idioma pt-BR, sem emoji, sem co-autoria, com escopo
# Retorna: pass | warning | error
# ============================================================================
validate_commit_format() {
    local msg="${1:-}"
    [ -z "$msg" ] && { echo "error"; return 0; }

    # --- Co-autoria proibida (erro crítico) ---
    if echo "$msg" | grep -qi "Co-Authored-By\|Co-authored-by"; then
        echo "error"
        return 0
    fi

    # --- Emojis proibidos (erro crítico) ---
    # 1. Shortcodes :name: (ex: :sparkles:, :bug:) — simples e confiável
    if echo "$msg" | grep -qE ':[a-z_]+:'; then
        echo "error"
        return 0
    fi
    # 2. Emojis unicode (acima de U+00FF — acima do Latin Extended)
    #    Letras acentuadas pt-BR ficam em U+00C0-U+00FF → são permitidas
    local first_line="${msg%%$'\n'*}"
    if command -v python3 &>/dev/null; then
        local has_emoji
        has_emoji=$(python3 -c "
import sys
line = sys.stdin.read()
emoji = any(ord(c) > 0x00FF for c in line)
print('yes' if emoji else 'no')
" <<< "$first_line" 2>/dev/null || echo "no")
        if [ "$has_emoji" = "yes" ]; then
            echo "error"
            return 0
        fi
    fi

    # --- Tipo de commit válido ---
    local first_line_clean="${msg%%$'\n'*}"
    if ! echo "$first_line_clean" | grep -qE "^($VALID_COMMIT_TYPES)(\(.+\))?: .+"; then
        echo "error"
        return 0
    fi

    # --- Detecta inglês na descrição ---
    local description
    description=$(echo "$first_line_clean" | sed 's/^[^:]*: //')
    if echo "$description" | grep -qiE "$_ENGLISH_INDICATORS"; then
        echo "error"
        return 0
    fi

    # --- Escopo opcional mas recomendado ---
    if ! echo "$first_line_clean" | grep -qE "^($VALID_COMMIT_TYPES)\(.+\): .+"; then
        echo "warning"
        return 0
    fi

    echo "pass"
}

# ============================================================================
# validate_file_count <count>
# Verifica MAX_FILES_PER_CYCLE
# Retorna: pass | warning | error
# ============================================================================
validate_file_count() {
    local count="${1:-0}"

    if [ "$count" -lt "$MAX_FILES_PER_CYCLE" ]; then
        echo "pass"
    elif [ "$count" -eq "$MAX_FILES_PER_CYCLE" ]; then
        echo "warning"
    else
        echo "error"
    fi
}

# ============================================================================
# validate_protected_path <file_path> [destination_path]
# Verifica se o arquivo está em caminho protegido
# Retorna: pass | warning | error
# ============================================================================
validate_protected_path() {
    local file_path="${1:-}"
    [ -z "$file_path" ] && { echo "pass"; return 0; }

    # Erro: caminhos de estado interno
    for protected in "${_PROTECTED_PATHS_ERROR[@]}"; do
        if [[ "$file_path" == $protected* ]]; then
            echo "error"
            return 0
        fi
    done

    # Warning: agentes e libs core
    for protected in "${_PROTECTED_PATHS_WARNING[@]}"; do
        if [[ "$file_path" == $protected* ]] || [[ "$file_path" == "$protected" ]]; then
            echo "warning"
            return 0
        fi
    done

    echo "pass"
}

# ============================================================================
# validate_no_manual_plan_move <file_path> [destination_context]
# Detecta movimentação manual de arquivos de plano
# Retorna: pass | error
# ============================================================================
validate_no_manual_plan_move() {
    local file_path="${1:-}"
    local destination="${2:-}"

    # Se não é arquivo de plano, pass
    if ! echo "$file_path" | grep -qE "^\.aidev/plans/(backlog|features|current|history)/.*\.md$"; then
        echo "pass"
        return 0
    fi

    # Se tem destino explícito, é movimento manual suspeito
    if [ -n "$destination" ]; then
        echo "error"
        return 0
    fi

    echo "pass"
}

# ============================================================================
# validate_all <commit_msg> <file_count> [file_path]
# Executa todas as validações e retorna resultado agregado
# Retorna: pass | warning | error (pior resultado vence)
# ============================================================================
validate_all() {
    local commit_msg="${1:-}"
    local file_count="${2:-0}"
    local file_path="${3:-}"

    local worst="pass"

    local r
    r=$(validate_commit_format "$commit_msg")
    [ "$r" = "error" ] && worst="error" || { [ "$r" = "warning" ] && [ "$worst" != "error" ] && worst="warning"; }

    r=$(validate_file_count "$file_count")
    [ "$r" = "error" ] && worst="error" || { [ "$r" = "warning" ] && [ "$worst" != "error" ] && worst="warning"; }

    if [ -n "$file_path" ]; then
        r=$(validate_protected_path "$file_path")
        [ "$r" = "error" ] && worst="error" || { [ "$r" = "warning" ] && [ "$worst" != "error" ] && worst="warning"; }
    fi

    echo "$worst"
}

# ============================================================================
# run_pre_commit_check
# Executado como git hook pre-commit
# ============================================================================
run_pre_commit_check() {
    local commit_msg_file="${1:-}"
    local commit_msg=""

    # Lê mensagem do commit
    if [ -n "$commit_msg_file" ] && [ -f "$commit_msg_file" ]; then
        commit_msg=$(cat "$commit_msg_file")
    elif [ -n "${GIT_COMMIT_MSG:-}" ]; then
        commit_msg="$GIT_COMMIT_MSG"
    else
        echo "⚠ rules-validator: sem mensagem de commit para validar" >&2
        return 0
    fi

    local result
    result=$(validate_commit_format "$commit_msg")

    # Registrar evento no dashboard de compliance
    _validator_dashboard_record "commit" "commit-format" "$result" "${commit_msg:0:60}"

    case "$result" in
        pass)
            echo "✓ rules-validator: formato de commit OK" >&2
            return 0
            ;;
        warning)
            echo "⚠ rules-validator: commit sem escopo (recomendado: tipo(escopo): msg)" >&2
            return 0  # warning não bloqueia
            ;;
        error)
            echo "" >&2
            echo "✗ rules-validator: COMMIT BLOQUEADO — formato inválido" >&2
            echo "" >&2
            echo "  Mensagem: $commit_msg" >&2
            echo "" >&2
            echo "  Regras:" >&2
            echo "    ✗ Idioma: PORTUGUÊS (Brasil) obrigatório" >&2
            echo "    ✗ Formato: tipo(escopo): descrição" >&2
            echo "    ✗ Emojis: PROIBIDOS" >&2
            echo "    ✗ Co-autoria: PROIBIDA" >&2
            echo "    ✓ Tipos: feat|fix|refactor|test|docs|chore|..." >&2
            echo "" >&2
            echo "  Exemplo válido: feat(auth): adiciona autenticação jwt" >&2
            echo "" >&2
            return 1
            ;;
    esac
}

# ============================================================================
# _validator_dashboard_record <tipo> <regra> <resultado> [contexto]
# Registra evento no log de compliance sem dependência circular com dashboard.sh
# ============================================================================
_validator_dashboard_record() {
    local tipo="$1"
    local regra="$2"
    local resultado="$3"
    local contexto="${4:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

    local session_log
    session_log="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/state/compliance-session.log"

    mkdir -p "$(dirname "$session_log")" 2>/dev/null || true
    printf "%s\t%s\t%s\t%s\t%s\n" \
        "$timestamp" "$tipo" "$regra" "$resultado" "$contexto" \
        >> "$session_log" 2>/dev/null || true
}
