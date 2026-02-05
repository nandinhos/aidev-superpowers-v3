#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Lessons & Knowledge Module
# ============================================================================
# Gestão unificada de lições aprendidas, padrões de sucesso e base de conhecimento.
#
# Uso: source lib/lessons.sh
# Dependencias: lib/core.sh, lib/file-ops.sh
# ============================================================================

# Caminhos padrão
LESSONS_KB_DIR=".aidev/memory/kb"
LEGACY_LESSONS_DIR="project-docs/lessons-learned"

# Sincroniza lições de locais legados para o KB oficial
# Uso: lessons_sync [force]
lessons_sync() {
    local force="${1:-false}"
    local install_path="${CLI_INSTALL_PATH:-.}"
    local target_dir="$install_path/$LESSONS_KB_DIR"
    local legacy_dir="$install_path/$LEGACY_LESSONS_DIR"

    ensure_dir "$target_dir"

    # 1. Migrar de caminhos legados
    if [ -d "$legacy_dir" ]; then
        print_step "Sincronizando lições de $LEGACY_LESSONS_DIR..."
        shopt -s nullglob
        for f in "$legacy_dir"/*.md; do
            local base=$(basename "$f")
            if [ ! -f "$target_dir/$base" ] || [ "$force" = "true" ]; then
                cp "$f" "$target_dir/"
                print_info "Migrada: $base"
            fi
        done
        shopt -u nullglob
    fi

    # 2. Ingerir regras genéricas se ainda não estiverem no KB
    local rules_file="$install_path/.aidev/rules/generic.md"
    if [ -f "$rules_file" ] && [ ! -f "$target_dir/0000-00-00-generic-rules.md" ]; then
        print_step "Ingerindo regras genéricas no KB..."
        cat > "$target_dir/0000-00-00-generic-rules.md" << EOF
# Padrão: Regras Genéricas de Desenvolvimento

**Data**: 2026-02-05
**Stack**: multi-stack
**Tags**: rules, patterns, tdd, clean-code

## Resumo
Este documento consolida as regras fundamentais do projeto AI Dev Superpowers.

## Padrões Identificados
$(grep "^## " "$rules_file" | sed 's/## /- /')

## Detalhes
$(cat "$rules_file")
EOF
        print_success "Regras genéricas integradas ao KB."
    fi
}

# Busca lições e padrões (Local + Global via MCP se disponível)
# Uso: result=$(lessons_search "termo")
lessons_search() {
    local query="$1"
    local install_path="${CLI_INSTALL_PATH:-.}"
    local target_dir="$install_path/$LESSONS_KB_DIR"
    
    local results="[]"

    # 1. Busca Local (grep simples por enquanto)
    if [ -d "$target_dir" ]; then
        shopt -s nullglob
        for f in "$target_dir"/*.md; do
            if grep -qi "$query" "$f"; then
                local title=$(basename "$f" .md)
                local summary=$(head -n 10 "$f" | tr '\n' ' ' | sed 's/"/\\"/g' | cut -c1-200)
                results=$(echo "$results" | jq --arg t "$title" --arg s "$summary" '. += [{"title": $t, "summary": $s, "source": "local"}]')
            fi
        done
        shopt -u nullglob
    fi

    echo "$results"
}

# Registra uma lição no Vault Global (basic-memory MCP)
# Uso: lessons_vault_store "titulo" "conteudo"
lessons_vault_store() {
    local title="$1"
    local content="$2"

    # Nota: Como este script roda no shell, ele não chama ferramentas MCP diretamente.
    # O agente chamará mcp__basic-memory__write_note baseado nas diretrizes da SKILL.md.
    # Esta função serve como placeholder ou helper se implementarmos via CLI externa.
    print_debug "Armazenando lição global: $title"
}
