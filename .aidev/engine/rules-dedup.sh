#!/usr/bin/env bash
# rules-dedup.sh — Detecta arquivos de regras em locais não-canônicos
# Parte do Rules Engine (Sprint 2: Enforcement)
#
# Previne o "incidente DAS": LLM criou standards/Regras Frontend.md
# duplicando conteúdo que já existia em .aidev/rules/livewire.md
#
# Uso:
#   source .aidev/engine/rules-dedup.sh
#   rules_dedup_scan [project_root]    # escaneia e reporta duplicatas
#   rules_dedup_check [file_path]      # verifica arquivo específico

RULES_DEDUP_VERSION="1.0.0"

# Padrões de nome de arquivo suspeito de conter regras
_DEDUP_SUSPICIOUS_NAMES=(
    "regras"
    "rules"
    "standards"
    "conventions"
    "guidelines"
    "padroes"
    "normas"
    "coding-style"
    "code-style"
    "style-guide"
)

# Padrões de conteúdo que indicam arquivo de regras
_DEDUP_CONTENT_PATTERNS=(
    "## Regras"
    "## Rules"
    "## Convenções"
    "## Padrões"
    "## Standards"
    "# Coding"
    "PROIBIDO"
    "OBRIGATÓRIO"
    "MANDATORY"
    "FORBIDDEN"
    "deve seguir"
    "must follow"
)

# Diretório canônico para regras
_RULES_CANONICAL_DIR=".aidev/rules"

# ============================================================================
# _dedup_is_suspicious_name <file_path>
# Retorna 0 se o nome do arquivo corresponde a padrão suspeito
# ============================================================================
_dedup_is_suspicious_name() {
    local file_path="$1"
    local basename_lower
    basename_lower=$(basename "$file_path" | tr '[:upper:]' '[:lower:]')

    for pattern in "${_DEDUP_SUSPICIOUS_NAMES[@]}"; do
        if echo "$basename_lower" | grep -qi "$pattern"; then
            return 0
        fi
    done
    return 1
}

# ============================================================================
# _dedup_has_rules_content <file_path>
# Retorna 0 se o arquivo contém padrões típicos de arquivo de regras
# ============================================================================
_dedup_has_rules_content() {
    local file_path="$1"
    [ ! -f "$file_path" ] && return 1

    for pattern in "${_DEDUP_CONTENT_PATTERNS[@]}"; do
        if grep -qi "$pattern" "$file_path" 2>/dev/null; then
            return 0
        fi
    done
    return 1
}

# ============================================================================
# rules_dedup_check <file_path>
# Verifica se um arquivo específico está em local não-canônico
# Retorna: "canonical" | "suspicious" | "violation"
# ============================================================================
rules_dedup_check() {
    local file_path="${1:-}"
    [ -z "$file_path" ] && { echo "canonical"; return 0; }

    # Normaliza caminho
    local normalized="${file_path#./}"

    # Está no diretório canônico? → OK
    if [[ "$normalized" == $_RULES_CANONICAL_DIR/* ]]; then
        echo "canonical"
        return 0
    fi

    # Tem nome suspeito?
    local name_suspicious=false
    _dedup_is_suspicious_name "$normalized" && name_suspicious=true

    # Tem conteúdo de regras?
    local content_suspicious=false
    _dedup_has_rules_content "$normalized" && content_suspicious=true

    # Ambos suspeitos → violação
    if [ "$name_suspicious" = true ] && [ "$content_suspicious" = true ]; then
        echo "violation"
        return 0
    fi

    # Só nome suspeito → investigar
    if [ "$name_suspicious" = true ]; then
        echo "suspicious"
        return 0
    fi

    echo "canonical"
}

# ============================================================================
# rules_dedup_scan [project_root]
# Escaneia o projeto inteiro e reporta arquivos suspeitos
# ============================================================================
rules_dedup_scan() {
    local project_root="${1:-$(pwd)}"
    local violations=()
    local suspicious=()

    echo "" >&2
    echo "=== Rules Anti-Dedup Scan ===" >&2
    echo "Projeto: $project_root" >&2
    echo "" >&2

    # Procura arquivos .md excluindo o diretório canônico e node_modules/vendor
    local md_files
    mapfile -t md_files < <(find "$project_root" -name "*.md" \
        ! -path "*/$_RULES_CANONICAL_DIR/*" \
        ! -path "*/node_modules/*" \
        ! -path "*/vendor/*" \
        ! -path "*/.git/*" \
        ! -path "*/history/*" \
        2>/dev/null | sort)

    for file in "${md_files[@]:-}"; do
        [ -z "$file" ] && continue
        local rel_path="${file#$project_root/}"
        local result
        result=$(rules_dedup_check "$rel_path")

        case "$result" in
            violation)
                violations+=("$rel_path")
                echo "  ✗ VIOLAÇÃO: $rel_path" >&2
                echo "    → Conteúdo de regras fora de $_RULES_CANONICAL_DIR/" >&2
                echo "    → Mova/merge para: $_RULES_CANONICAL_DIR/$(basename "$rel_path")" >&2
                ;;
            suspicious)
                suspicious+=("$rel_path")
                echo "  ⚠ SUSPEITO:  $rel_path (nome sugere regras, verifique conteúdo)" >&2
                ;;
        esac
    done

    echo "" >&2

    if [ ${#violations[@]} -eq 0 ] && [ ${#suspicious[@]} -eq 0 ]; then
        echo "  ✓ Nenhuma duplicata detectada" >&2
    else
        echo "  Resumo: ${#violations[@]} violação(ões), ${#suspicious[@]} suspeito(s)" >&2
    fi

    echo "" >&2

    # Retorna número de violações para uso programático
    echo "${#violations[@]}"
    return ${#violations[@]}
}

# ============================================================================
# rules_dedup_alert <file_path>
# Formata alerta para exibição ao usuário quando LLM cria arquivo suspeito
# ============================================================================
rules_dedup_alert() {
    local file_path="${1:-}"
    local result
    result=$(rules_dedup_check "$file_path")

    if [ "$result" = "violation" ]; then
        # Registrar no dashboard de compliance
        _dedup_dashboard_record "file-creation" "no-rules-outside-canonical" "error" "$file_path"

        echo ""
        echo "⚠️  ALERTA — Rules Anti-Dedup"
        echo ""
        echo "  Arquivo de regras detectado fora do local canônico:"
        echo "  Local: $file_path"
        echo "  Canônico: $_RULES_CANONICAL_DIR/"
        echo ""
        echo "  Ação recomendada:"
        echo "  1. Verificar se conteúdo já existe em $_RULES_CANONICAL_DIR/"
        echo "  2. Se não existir: mv \"$file_path\" \"$_RULES_CANONICAL_DIR/\""
        echo "  3. Se existir: merge e remova o duplicado"
        echo ""
        echo "  Aguardando autorização antes de executar qualquer ação."
        return 1
    fi
    return 0
}

# ============================================================================
# _dedup_dashboard_record <tipo> <regra> <resultado> [contexto]
# Registra evento no log de compliance sem dependência circular com dashboard.sh
# ============================================================================
_dedup_dashboard_record() {
    local tipo="$1"
    local regra="$2"
    local resultado="$3"
    local contexto="${4:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

    local session_log
    session_log="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/state/compliance-session.log"

    mkdir -p "$(dirname "$session_log")" 2>/dev/null || true
    printf "%s\t%s\t%s\t%s\t%s\n" \
        "$timestamp" "$tipo" "$regra" "$resultado" "$contexto" \
        >> "$session_log" 2>/dev/null || true
}
