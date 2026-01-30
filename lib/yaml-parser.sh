#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - YAML Parser Module
# ============================================================================
# Parser YAML minimalista para configurações
# Suporta: chaves simples, listas, e aninhamento de 2 níveis
# 
# Uso: source lib/yaml-parser.sh
# Dependências: lib/core.sh
# ============================================================================

# ============================================================================
# Parser Principal
# ============================================================================

# Parseia arquivo YAML para variáveis de ambiente
# Uso: parse_yaml "config.yaml" "PREFIX_"
# Resultado: Define variáveis PREFIX_key=value
parse_yaml() {
    local yaml_file="$1"
    local prefix="${2:-}"
    
    if [ ! -f "$yaml_file" ]; then
        print_error "Arquivo YAML não encontrado: $yaml_file"
        return 1
    fi
    
    local current_section=""
    local line_num=0
    
    while IFS= read -r line || [ -n "$line" ]; do
        ((line_num++)) || true
        
        # Remove comentários
        line="${line%%#*}"
        
        # Ignora linhas vazias
        [[ -z "${line// }" ]] && continue
        
        # Detecta seção (key:)
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Detecta par chave: valor (simples)
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):\ *(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove aspas
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            
            # Define variável
            local var_name="${prefix}${key}"
            var_name="${var_name//-/_}"
            export "$var_name"="$value"
            
            print_debug "YAML: $var_name=$value"
            continue
        fi
        
        # Detecta par com indentação (dentro de seção)
        if [[ "$line" =~ ^[[:space:]]+([a-zA-Z_][a-zA-Z0-9_-]*):\ *(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove aspas
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            
            # Define variável com seção
            local full_key="${current_section}_${key}"
            local var_name="${prefix}${full_key}"
            var_name="${var_name//-/_}"
            export "$var_name"="$value"
            
            print_debug "YAML: $var_name=$value"
            continue
        fi
        
        # Detecta item de lista (- value)
        if [[ "$line" =~ ^[[:space:]]*-\ +(.+)$ ]]; then
            local value="${BASH_REMATCH[1]}"
            
            # Remove aspas
            value="${value#\"}"
            value="${value%\"}"
            
            # Adiciona ao array da seção atual
            if [ -n "$current_section" ]; then
                local var_name="${prefix}${current_section}"
                var_name="${var_name//-/_}"
                local current_val="${!var_name:-}"
                
                if [ -z "$current_val" ]; then
                    export "$var_name"="$value"
                else
                    export "$var_name"="${current_val},${value}"
                fi
            fi
            continue
        fi
        
    done < "$yaml_file"
    
    return 0
}

# ============================================================================
# Leitura de Valores
# ============================================================================

# Obtém valor de uma chave YAML (após parse)
# Uso: value=$(yaml_get "STACK")
yaml_get() {
    local key="$1"
    local prefix="${2:-AIDEV_}"
    local default="${3:-}"
    
    local var_name="${prefix}${key}"
    var_name="${var_name//-/_}"
    
    echo "${!var_name:-$default}"
}

# Obtém valor aninhado
# Uso: value=$(yaml_get_nested "platform" "name")
yaml_get_nested() {
    local section="$1"
    local key="$2"
    local prefix="${3:-AIDEV_}"
    local default="${4:-}"
    
    local var_name="${prefix}${section}_${key}"
    var_name="${var_name//-/_}"
    
    echo "${!var_name:-$default}"
}

# Obtém lista como array
# Uso: IFS=',' read -ra items <<< "$(yaml_get_list "stacks")"
yaml_get_list() {
    local key="$1"
    local prefix="${2:-AIDEV_}"
    
    yaml_get "$key" "$prefix" ""
}

# ============================================================================
# Escrita de YAML
# ============================================================================

# Gera YAML a partir de variáveis
# Uso: generate_yaml "PREFIX_" > output.yaml
generate_yaml() {
    local prefix="$1"
    
    # Lista variáveis com o prefixo
    env | grep "^${prefix}" | while IFS='=' read -r name value; do
        # Remove prefixo
        local key="${name#$prefix}"
        # Converte underscores de volta
        key="${key//_/-}"
        
        echo "$key: $value"
    done
}

# ============================================================================
# Validação
# ============================================================================

# Valida sintaxe básica de arquivo YAML
# Uso: validate_yaml "config.yaml"
validate_yaml() {
    local yaml_file="$1"
    local errors=0
    local line_num=0
    
    if [ ! -f "$yaml_file" ]; then
        print_error "Arquivo não encontrado: $yaml_file"
        return 1
    fi
    
    while IFS= read -r line || [ -n "$line" ]; do
        ((line_num++)) || true
        
        # Remove comentários
        local clean_line="${line%%#*}"
        
        # Ignora linhas vazias
        [[ -z "${clean_line// }" ]] && continue
        
        # Verifica tabs (YAML usa espaços)
        if [[ "$line" =~ ^$'\t' ]]; then
            print_warning "Linha $line_num: Tab detectado (use espaços)"
            ((errors++))
        fi
        
        # Verifica indentação inconsistente
        if [[ "$clean_line" =~ ^[[:space:]]+ ]]; then
            local indent="${BASH_REMATCH[0]}"
            local indent_len=${#indent}
            
            if (( indent_len % 2 != 0 )); then
                print_warning "Linha $line_num: Indentação ímpar ($indent_len espaços)"
            fi
        fi
        
    done < "$yaml_file"
    
    if [ $errors -eq 0 ]; then
        print_success "YAML válido: $yaml_file"
        return 0
    else
        print_error "$errors problemas encontrados"
        return 1
    fi
}
