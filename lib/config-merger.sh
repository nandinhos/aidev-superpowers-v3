#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Config Merger Module
# ============================================================================
# Gerencia hierarquia de configurações: CLI > projeto > defaults
# 
# Uso: source lib/config-merger.sh
# Dependências: lib/core.sh, lib/yaml-parser.sh
# ============================================================================

# Prefixo para variáveis de configuração
readonly CONFIG_PREFIX="AIDEV_CFG_"

# ============================================================================
# Carregamento de Configuração
# ============================================================================

# Carrega configuração completa com hierarquia
# Uso: load_config [project_path]
load_config() {
    local project_path="${1:-.}"
    
    # 1. Carrega defaults
    load_defaults
    
    # 2. Carrega config do projeto (se existir)
    load_project_config "$project_path"
    
    # 3. CLI args já foram aplicados via parse_args
    # Eles sobrescrevem automaticamente via variáveis de ambiente
    
    print_debug "Configuração carregada com sucesso"
}

# Carrega apenas configurações padrão
load_defaults() {
    local defaults_file="$AIDEV_ROOT_DIR/config/defaults.yaml"
    
    if [ -f "$defaults_file" ]; then
        parse_yaml "$defaults_file" "$CONFIG_PREFIX"
        print_debug "Defaults carregados: $defaults_file"
    else
        print_warning "Arquivo de defaults não encontrado"
    fi
}

# Carrega configuração do projeto
load_project_config() {
    local project_path="$1"
    local config_file="$project_path/.aidev.yaml"
    
    if [ -f "$config_file" ]; then
        parse_yaml "$config_file" "$CONFIG_PREFIX"
        print_debug "Config do projeto carregada: $config_file"
        return 0
    fi
    
    # Tenta alternativas
    for alt in ".aidev.yml" ".aidevrc.yaml" ".aidevrc"; do
        if [ -f "$project_path/$alt" ]; then
            parse_yaml "$project_path/$alt" "$CONFIG_PREFIX"
            print_debug "Config alternativa carregada: $alt"
            return 0
        fi
    done
    
    print_debug "Nenhuma config de projeto encontrada (usando defaults)"
    return 0
}

# ============================================================================
# Acesso a Configurações
# ============================================================================

# Obtém valor de configuração
# Uso: value=$(config_get "mode")
config_get() {
    local key="$1"
    local default="${2:-}"
    
    yaml_get "$key" "$CONFIG_PREFIX" "$default"
}

# Obtém valor aninhado
# Uso: value=$(config_get_nested "platform" "name")
config_get_nested() {
    local section="$1"
    local key="$2"
    local default="${3:-}"
    
    yaml_get_nested "$section" "$key" "$CONFIG_PREFIX" "$default"
}

# Obtém lista
# Uso: IFS=',' read -ra agents <<< "$(config_get_list "agents")"
config_get_list() {
    local key="$1"
    yaml_get_list "$key" "$CONFIG_PREFIX"
}

# Verifica se valor é true
# Uso: config_is_true "debug_enabled" && echo "sim"
config_is_true() {
    local key="$1"
    local value
    value=$(config_get "$key" "false")
    
    [[ "$value" == "true" || "$value" == "1" || "$value" == "yes" ]]
}

# ============================================================================
# Aplicação de Configuração
# ============================================================================

# Aplica configurações globais do config ao ambiente
apply_config_to_env() {
    # Mode
    local mode
    mode=$(config_get "mode" "full")
    [ -z "$CLI_MODE" ] && CLI_MODE="$mode"
    
    # Debug
    if config_is_true "debug_enabled"; then
        AIDEV_DEBUG=true
    fi
    
    # Force
    if config_is_true "force"; then
        AIDEV_FORCE=true
    fi
    
    # Dry run
    if config_is_true "dry_run"; then
        AIDEV_DRY_RUN=true
    fi
    
    # Language
    local lang
    lang=$(config_get "language" "pt-BR")
    [ -z "$CLI_LANGUAGE" ] && CLI_LANGUAGE="$lang"
}

# ============================================================================
# Validação de Configuração
# ============================================================================

# Valida configuração atual
validate_config() {
    local errors=0
    
    # Valida mode
    local mode
    mode=$(config_get "mode" "full")
    if [[ ! "$mode" =~ ^(new|refactor|minimal|full)$ ]]; then
        print_error "Mode inválido na config: $mode"
        ((errors++)) || true
    fi
    
    # Valida language
    local lang
    lang=$(config_get "language" "pt-BR")
    if [[ ! "$lang" =~ ^(pt-BR|en)$ ]]; then
        print_error "Language inválido na config: $lang"
        ((errors++)) || true
    fi
    
    return $errors
}

# ============================================================================
# Geração de Config de Exemplo
# ============================================================================

# Gera arquivo .aidev.yaml de exemplo
generate_example_config() {
    local output_file="${1:-.aidev.yaml}"
    
    cat > "$output_file" << 'EOF'
# ============================================================================
# AI Dev Superpowers - Configuração do Projeto
# ============================================================================
# Este arquivo customiza o comportamento do AI Dev para este projeto.
# Valores aqui sobrescrevem os defaults do sistema.
# ============================================================================

# Modo de operação: new, refactor, minimal, full
mode: full

# Idioma: pt-BR, en
language: pt-BR

# Configurações de debug
debug:
  enabled: false
  verbose: false

# Plataforma
platform:
  name: auto
  mcp_enabled: true
  hooks_enabled: true

# Componentes a instalar
components:
  agents: true
  skills: true
  rules: true
  workflows: true
  mcp: true

# Agentes customizados (além dos padrão)
# custom_agents:
#   - meu-agente

# Skills customizadas (além das padrão)
# custom_skills:
#   - minha-skill

# Comandos personalizados para a stack
commands:
  test: ""
  lint: ""
  build: ""
EOF

    print_success "Arquivo de exemplo gerado: $output_file"
}

# Gera config baseada na detecção
generate_detected_config() {
    local install_path="${1:-.}"
    local output_file="$install_path/.aidev.yaml"
    
    local stack
    stack=$(detect_stack "$install_path")
    
    local project_name
    project_name=$(detect_project_name "$install_path")
    
    cat > "$output_file" << EOF
# AI Dev Superpowers - Configuração do Projeto
# Gerado automaticamente em $(date +%Y-%m-%d)

mode: full
language: pt-BR

# Projeto detectado
project:
  name: $project_name
  stack: $stack

# Plataforma
platform:
  name: auto
  mcp_enabled: true

# Componentes
components:
  agents: true
  skills: true
  rules: true
EOF

    print_success "Configuração gerada: $output_file"
}
