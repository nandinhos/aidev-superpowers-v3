#!/usr/bin/env bash
# rules-loader.sh — Carrega e injeta regras no contexto da LLM
# Parte do Rules Engine (Sprint 1: Fundação)
#
# Uso:
#   source .aidev/engine/rules-loader.sh
#   rules_load_all           # carrega todas as regras aplicáveis
#   rules_get_payload        # retorna payload formatado para injeção
#   rules_detect_stack       # detecta stack do projeto
#   rules_inject_claude_md   # injeta no CLAUDE.md (Claude Code)

set -euo pipefail

RULES_LOADER_VERSION="1.0.0"
AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RULES_DIR="$AIDEV_ROOT/rules"
TAXONOMY_FILE="$AIDEV_ROOT/config/rules-taxonomy.yaml"

# ============================================================================
# DETECÇÃO DE STACK
# ============================================================================

rules_detect_stack() {
    local project_root="${1:-$(pwd)}"

    # Livewire / Laravel
    if [ -f "$project_root/composer.json" ]; then
        if grep -qi "livewire" "$project_root/composer.json" 2>/dev/null; then
            echo "livewire"
            return 0
        fi
        echo "laravel"
        return 0
    fi

    # Next.js
    if [ -f "$project_root/package.json" ]; then
        if grep -qi '"next"' "$project_root/package.json" 2>/dev/null; then
            echo "nextjs"
            return 0
        fi
    fi

    # Django
    if [ -f "$project_root/manage.py" ] || grep -qi "django" "$project_root/requirements.txt" 2>/dev/null; then
        echo "django"
        return 0
    fi

    # aidev-superpowers (self-referencial)
    if [ -f "$project_root/.aidev/agents/orchestrator.md" ] 2>/dev/null; then
        echo "generic"
        return 0
    fi

    echo "generic"
}

# ============================================================================
# CARREGAMENTO DE CAMADAS
# ============================================================================

_rules_load_file() {
    local file="$1"
    local layer="$2"
    if [ -f "$file" ]; then
        echo "<!-- rules:layer=$layer source=$file -->"
        cat "$file"
        echo ""
        return 0
    fi
    return 1
}

rules_load_all() {
    local project_root="${1:-$(pwd)}"
    local _RULES_PAYLOAD=""
    local _RULES_LOADED=()

    # Camada: limits (precedência 0 — sempre carregada primeiro)
    local limits_file="$RULES_DIR/llm-limits.md"
    if [ -f "$limits_file" ]; then
        _RULES_PAYLOAD+=$(_rules_load_file "$limits_file" "limits")
        _RULES_LOADED+=("limits:$limits_file")
    fi

    # Camada: global (sempre carregada)
    local global_file="$RULES_DIR/generic.md"
    if [ -f "$global_file" ]; then
        _RULES_PAYLOAD+=$(_rules_load_file "$global_file" "global")
        _RULES_LOADED+=("global:$global_file")
    fi

    # Camada: stack (condicional por detecção)
    local detected_stack
    detected_stack=$(rules_detect_stack "$project_root")
    if [ -n "$detected_stack" ] && [ "$detected_stack" != "generic" ]; then
        local stack_file="$RULES_DIR/${detected_stack}.md"
        if [ -f "$stack_file" ]; then
            _RULES_PAYLOAD+=$(_rules_load_file "$stack_file" "stack:$detected_stack")
            _RULES_LOADED+=("stack:$stack_file")
        fi
    fi

    # Camada: project (override — maior precedência)
    local project_file="$RULES_DIR/project.md"
    if [ -f "$project_file" ]; then
        _RULES_PAYLOAD+=$(_rules_load_file "$project_file" "project")
        _RULES_LOADED+=("project:$project_file")
    fi

    # Exporta para uso externo
    export RULES_PAYLOAD="$_RULES_PAYLOAD"
    export RULES_LOADED=("${_RULES_LOADED[@]}")
    export RULES_STACK="$detected_stack"

    echo "✓ Rules Engine: ${#_RULES_LOADED[@]} camada(s) carregada(s) [stack: $detected_stack]" >&2
}

# ============================================================================
# PAYLOAD FORMATADO
# ============================================================================

rules_get_payload() {
    if [ -z "${RULES_PAYLOAD:-}" ]; then
        rules_load_all "$(pwd)"
    fi
    echo "$RULES_PAYLOAD"
}

# ============================================================================
# INJEÇÃO NO CLAUDE.md
# ============================================================================

rules_inject_claude_md() {
    local project_root="${1:-$(pwd)}"
    local claude_md="$project_root/CLAUDE.md"
    local marker="## Regras Injetadas pelo Rules Engine"

    if [ ! -f "$claude_md" ]; then
        echo "⚠ CLAUDE.md não encontrado em $project_root" >&2
        return 1
    fi

    # Carrega regras se ainda não carregadas
    if [ -z "${RULES_PAYLOAD:-}" ]; then
        rules_load_all "$project_root"
    fi

    local inject_block
    inject_block=$(cat <<INJECT_EOF

---

$marker
> Gerado automaticamente por rules-loader.sh v${RULES_LOADER_VERSION} em $(date +%Y-%m-%d)
> Stack detectada: ${RULES_STACK:-generic}
> Camadas: ${RULES_LOADED[*]:-nenhuma}
> NÃO edite esta seção manualmente — será sobrescrita pelo Rules Engine.

$RULES_PAYLOAD

---
INJECT_EOF
)

    # Remove bloco anterior se existir
    if grep -q "$marker" "$claude_md" 2>/dev/null; then
        # Extrai conteúdo antes do marker
        local before_marker
        before_marker=$(sed "/^---$/{/^$marker$/,/^---$/d}" "$claude_md" 2>/dev/null || \
                        awk "/$marker/{found=1} !found{print}" "$claude_md")
        echo "$before_marker" > "$claude_md"
    fi

    # Appenda o novo bloco
    echo "$inject_block" >> "$claude_md"
    echo "✓ Regras injetadas em $claude_md" >&2
}

# ============================================================================
# RESUMO DE REGRAS CARREGADAS
# ============================================================================

rules_summary() {
    if [ -z "${RULES_LOADED:-}" ]; then
        echo "⚠ Nenhuma regra carregada. Execute: rules_load_all" >&2
        return 1
    fi

    echo ""
    echo "=== Rules Engine — Resumo ==="
    echo "Stack:   ${RULES_STACK:-generic}"
    echo "Versão:  $RULES_LOADER_VERSION"
    echo ""
    echo "Camadas carregadas:"
    for entry in "${RULES_LOADED[@]:-}"; do
        local layer="${entry%%:*}"
        local file="${entry#*:}"
        local rule_count
        rule_count=$(grep -c "^## " "$file" 2>/dev/null || echo "?")
        echo "  [$layer] $file ($rule_count seções)"
    done
    echo ""
}
