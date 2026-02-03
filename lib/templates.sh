#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Templates Module
# ============================================================================
# Sistema de processamento de templates com substituição de variáveis
# 
# Uso: source lib/templates.sh
# Dependências: lib/core.sh, lib/file-ops.sh
# ============================================================================

# ============================================================================
# Processamento de Templates
# ============================================================================

# Processa um template substituindo variáveis
# Uso: process_template "input.tmpl" "output.md"
# Variáveis: {{VAR}}, {{VAR:default}}, {{#if VAR}}...{{/if}}
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        print_error "Template não encontrado: $template_file"
        return 1
    fi
    
    local content
    content=$(cat "$template_file")
    
    # Processa variáveis simples: {{VAR}}
    while [[ "$content" =~ \{\{([A-Za-z_][A-Za-z0-9_]*)\}\} ]]; do
        local var_name="${BASH_REMATCH[1]}"
        local var_value="${!var_name:-}"
        content="${content//\{\{$var_name\}\}/$var_value}"
    done
    
    # Processa variáveis com default: {{VAR:default}}
    while [[ "$content" =~ \{\{([A-Za-z_][A-Za-z0-9_]*):([^}]*)\}\} ]]; do
        local var_name="${BASH_REMATCH[1]}"
        local default_value="${BASH_REMATCH[2]}"
        local var_value="${!var_name:-$default_value}"
        content="${content//\{\{$var_name:$default_value\}\}/$var_value}"
    done
    
    # Processa condicionais: {{#if VAR}}...{{/if}}
    content=$(process_conditionals "$content")
    
    # Escreve output
    if [ -n "$output_file" ]; then
        if [ "${AIDEV_DRY_RUN:-false}" = "true" ]; then
            print_info "[DRY-RUN] Criaria arquivo: $output_file"
            return 0
        fi
        ensure_dir "$(dirname "$output_file")"
        printf '%s' "$content" > "$output_file"
        increment_files
        print_debug "Template processado: $output_file"
    else
        printf '%s' "$content"
    fi
}

# Processa condicionais no conteúdo
# Uso: result=$(process_conditionals "$content")
process_conditionals() {
    local content="$1"
    local result="$content"
    
    # Processa condicional por condicional para evitar gulodice (greediness)
    # A regex [^{]* garante que pegamos o conteúdo até o PRÓXIMO {{, ou o mais curto possível
    # Nota: Bash não suporta non-greedy (.*?), então usamos exclusão de caracteres.
    while [[ "$result" =~ \{\{#if\ ([A-Za-z_][A-Za-z0-9_]*)\}\}([^\{\}]*)\{\{/if\}\} ]]; do
        local var_name="${BASH_REMATCH[1]}"
        local inner_content="${BASH_REMATCH[2]}"
        local var_value="${!var_name:-}"
        
        if [ -n "$var_value" ] && [ "$var_value" != "false" ] && [ "$var_value" != "0" ]; then
            # Variável está definida e não é false/0 - mantém conteúdo
            result="${result/\{\{#if $var_name\}\}$inner_content\{\{\/if\}\}/$inner_content}"
        else
            # Variável não definida ou false - remove conteúdo
            result="${result/\{\{#if $var_name\}\}$inner_content\{\{\/if\}\}/}"
        fi
    done
    
    # Caso para conteúdo que contenha chaves internas (um nível de profundidade)
    while [[ "$result" =~ \{\{#if\ ([A-Za-z_][A-Za-z0-9_]*)\}\}(.*)\{\{/if\}\} ]]; do
        local var_name="${BASH_REMATCH[1]}"
        # Se chegamos aqui, inner_content pode ser guloso. 
        # Vamos tentar encontrar o PRIMEIRO {{/if}} correspondente via sed
        local pattern="\{\{#if $var_name\}\}"
        # Extração via sed é mais confiável para "primeira ocorrência"
        local match_block=$(echo "$result" | sed -n "s/.*\($pattern.*{{\/if}}\).*/\1/p" | head -n 1)
        [ -z "$match_block" ] && break
        
        local inner_content=$(echo "$match_block" | sed "s/^$pattern//" | sed "s/{{\/if}}$//")
        local var_value="${!var_name:-}"

        if [ -n "$var_value" ] && [ "$var_value" != "false" ] && [ "$var_value" != "0" ]; then
            result="${result/"$match_block"/$inner_content}"
        else
            result="${result/"$match_block"/}"
        fi
    done
    
    printf '%s' "$result"
}

# Processa template para stdout (útil para capturar em variável)
# Uso: content=$(process_template_to_stdout "input.tmpl")
process_template_to_stdout() {
    local template_file="$1"
    process_template "$template_file" ""
}

# ============================================================================
# Listagem de Templates
# ============================================================================

# Lista todos os templates disponíveis
# Uso: list_templates [categoria]
list_templates() {
    local category="${1:-}"
    local templates_dir="${AIDEV_ROOT_DIR}/templates"
    
    if [ -n "$category" ]; then
        find "$templates_dir/$category" -name "*.tmpl" 2>/dev/null | while read -r f; do
            basename "$f" .tmpl
        done
    else
        find "$templates_dir" -name "*.tmpl" 2>/dev/null | while read -r f; do
            echo "${f#$templates_dir/}" | sed 's/\.tmpl$//'
        done
    fi
}

# Lista categorias de templates
# Uso: list_template_categories
list_template_categories() {
    local templates_dir="${AIDEV_ROOT_DIR}/templates"
    
    find "$templates_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r d; do
        basename "$d"
    done
}

# ============================================================================
# Validação de Templates
# ============================================================================

# Valida sintaxe de um template
# Uso: validate_template "input.tmpl"
validate_template() {
    local template_file="$1"
    local errors=0
    
    if [ ! -f "$template_file" ]; then
        print_error "Template não encontrado: $template_file"
        return 1
    fi
    
    local content
    content=$(cat "$template_file")
    
    # Verifica condicionais não fechadas
    local open_ifs=$(echo "$content" | grep -c "{{#if" || true)
    local close_ifs=$(echo "$content" | grep -c "{{/if}}" || true)
    
    if [ "$open_ifs" -ne "$close_ifs" ]; then
        print_error "Condicionais não balanceadas: $open_ifs aberturas, $close_ifs fechamentos"
        ((errors++))
    fi
    
    # Verifica variáveis malformadas
    if echo "$content" | grep -qE '\{\{[^}]*$'; then
        print_error "Variável não fechada encontrada"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "Template válido: $template_file"
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Geração de Templates
# ============================================================================

# Gera arquivo a partir de template com contexto
# Uso: generate_from_template "agents/orchestrator" "/path/to/output.md"
generate_from_template() {
    local template_name="$1"
    local output_file="$2"
    local templates_dir="${AIDEV_ROOT_DIR}/templates"
    
    local template_file="$templates_dir/${template_name}.md.tmpl"
    
    if [ ! -f "$template_file" ]; then
        print_error "Template não encontrado: $template_name"
        return 1
    fi
    
    process_template "$template_file" "$output_file"
}

# Gera todos os templates de uma categoria
# Uso: generate_category_templates "agents" "/path/to/output/dir"
generate_category_templates() {
    local category="$1"
    local output_dir="$2"
    local templates_dir="${AIDEV_ROOT_DIR}/templates"
    
    # Lógica de localização v3.3
    # 1. Tenta encontrar na pasta localizada (ex: templates/pt/agents)
    # 2. Se não existir, fallback para a pasta raiz (legado ou default)
    local lang_suffix=$(get_lang_suffix 2>/dev/null || echo "pt")
    local localized_dir="$templates_dir/$lang_suffix/$category"
    local legacy_dir="$templates_dir/$category"
    
    local source_dir=""
    
    if [ -d "$localized_dir" ]; then
        source_dir="$localized_dir"
        print_debug "Usando templates localizados: $localized_dir"
    elif [ -d "$legacy_dir" ]; then
        source_dir="$legacy_dir"
        print_debug "Usando templates legado: $legacy_dir"
    else
        print_error "Categoria não encontrada: $category (tentou $localized_dir e $legacy_dir)"
        return 1
    fi
    
    ensure_dir "$output_dir"
    
    for template in "$source_dir"/*.tmpl; do
        if [ -f "$template" ]; then
            local name
            name=$(basename "$template" .md.tmpl)
            name=${name%.tmpl}
            process_template "$template" "$output_dir/${name}.md"
        fi
    done
}

# ============================================================================
# Helpers
# ============================================================================

# Obtém valor de variável de template com fallback
# Uso: value=$(get_template_var "PROJECT_NAME" "default")
get_template_var() {
    local var_name="$1"
    local default="${2:-}"
    
    echo "${!var_name:-$default}"
}

# Define múltiplas variáveis de template
# Uso: set_template_vars "PROJECT_NAME=Test" "STACK=laravel"
set_template_vars() {
    for var in "$@"; do
        local name="${var%%=*}"
        local value="${var#*=}"
        export "$name"="$value"
    done
}
