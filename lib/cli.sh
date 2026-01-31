#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - CLI Module
# ============================================================================
# Funções para parsing de argumentos e interface de linha de comando
# 
# Uso: source lib/cli.sh
# Dependências: lib/core.sh
# ============================================================================

# Variáveis de CLI (defaults)
CLI_INSTALL_PATH=""
CLI_MODE="full"
CLI_STACK="generic"
CLI_PRD_PATH=""
CLI_PLATFORM="auto"
CLI_LANGUAGE="pt-BR"
CLI_AUTO_DETECT=true
CLI_NO_MCP=false
CLI_NO_HOOKS=false
AIDEV_COMMAND=""
AIDEV_FORCE=false
AIDEV_DRY_RUN=false

# Sincroniza estado da sessão se disponível
# Deve ser chamado após parse_args
sync_session_state() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    if has_aidev_installed "$install_path"; then
        # Variáveis globais de progresso (lidas do estado)
        current_fase=$(get_state_value "current_fase" "1")
        current_sprint=$(get_state_value "current_sprint" "0")
        current_task=$(get_state_value "current_task" "Pendente")
        initialized_at=$(get_state_value "initialized_at" "$(date -Iseconds)")
        
        # Exporta para subprocessos se necessário
        export current_fase current_sprint current_task initialized_at
    fi
}

# ============================================================================
# Exibição de Ajuda
# ============================================================================

# Exibe ajuda completa do comando aidev
# Uso: show_help
show_help() {
    cat << EOF
${CYAN:-}AI Dev Superpowers${NC:-} v${AIDEV_VERSION:-3.0.0}
${YELLOW:-}Sistema Unificado de Governança de IA para Desenvolvimento${NC:-}

${YELLOW:-}Uso:${NC:-}
  aidev <comando> [opções]

${YELLOW:-}Comandos:${NC:-}
  init              Inicializa AI Dev em um projeto
  upgrade           Atualiza instalação existente
  add-skill         Adiciona skill customizada
  add-rule          Adiciona regra customizada
  add-agent         Adiciona agente customizado
  status            Mostra status da instalação
  doctor            Diagnóstico da instalação

${YELLOW:-}Opções Globais:${NC:-}
  --install-in <path>   Diretório alvo (default: .)
  --force               Sobrescreve arquivos existentes
  --dry-run             Mostra o que seria criado sem executar
  -h, --help            Mostra esta ajuda
  -v, --version         Mostra versão

${YELLOW:-}Opções do 'init':${NC:-}
  --mode <modo>         Modo de operação: new, refactor, minimal, full
  --stack <stack>       Stack: laravel, filament, livewire, node, react, nextjs, python, generic
  --detect              Auto-detecta stack (padrão)
  --platform <plat>     Plataforma: antigravity, claude-code, gemini, opencode, codex, generic
  --prd <path>          Caminho para PRD (obrigatório em --mode new)
  --no-mcp              Não configura MCP Engine
  --no-hooks            Não configura hooks automáticos
  --language <lang>     Idioma: pt-BR, en (default: pt-BR)

${YELLOW:-}Modos de Operação:${NC:-}
  new       Sistema novo baseado em PRD (requer --prd)
  refactor  Sistema existente para refatoração
  minimal   Estrutura mínima para exploração
  full      Instalação completa (padrão)

${YELLOW:-}Stacks Suportadas:${NC:-}
  laravel, filament, livewire    PHP + Laravel
  node, react, nextjs, vue       JavaScript/TypeScript
  python, django, fastapi, flask Python
  ruby, rails                    Ruby
  go, rust                       Sistemas
  generic                        Regras base apenas

${YELLOW:-}Exemplos:${NC:-}
  # Novo projeto Laravel a partir de PRD
  aidev init --mode new --stack laravel --prd docs/prd.md

  # Refatoração de sistema legado
  aidev init --mode refactor --detect

  # Setup mínimo para exploração
  aidev init --mode minimal

  # Instalação completa com auto-detecção
  aidev init --detect

${YELLOW:-}Documentação:${NC:-}
  https://github.com/nandinhos/aidev-superpowers-v3

EOF
}

# Exibe versão
# Uso: show_version
show_version() {
    echo "aidev v${AIDEV_VERSION:-3.0.0}"
}

# ============================================================================
# Parsing de Argumentos
# ============================================================================

# Parse de argumentos da linha de comando
# Uso: parse_args "$@"
parse_args() {
    # Reset para defaults
    CLI_INSTALL_PATH=""
    CLI_MODE="full"
    CLI_STACK="generic"
    CLI_PRD_PATH=""
    CLI_PLATFORM="auto"
    CLI_LANGUAGE="pt-BR"
    CLI_AUTO_DETECT=true
    CLI_NO_MCP=false
    CLI_NO_HOOKS=false
    AIDEV_COMMAND=""
    AIDEV_FORCE=false
    AIDEV_DRY_RUN=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-in)
                CLI_INSTALL_PATH="$2"
                shift 2
                ;;
            --mode)
                CLI_MODE="$2"
                shift 2
                ;;
            --stack)
                CLI_STACK="$2"
                CLI_AUTO_DETECT=false
                shift 2
                ;;
            --prd)
                CLI_PRD_PATH="$2"
                shift 2
                ;;
            --platform)
                CLI_PLATFORM="$2"
                shift 2
                ;;
            --language)
                CLI_LANGUAGE="$2"
                shift 2
                ;;
            --detect)
                CLI_AUTO_DETECT=true
                shift
                ;;
            --force)
                AIDEV_FORCE=true
                shift
                ;;
            --dry-run)
                AIDEV_DRY_RUN=true
                shift
                ;;
            --no-mcp)
                CLI_NO_MCP=true
                shift
                ;;
            --no-hooks)
                CLI_NO_HOOKS=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -*)
                print_error "Opção desconhecida: $1"
                echo "Use 'aidev --help' para ver opções disponíveis"
                exit 1
                ;;
            *)
                # Argumento posicional (subcomando ou path)
                if [ -z "$AIDEV_COMMAND" ]; then
                    AIDEV_COMMAND="$1"
                elif [ -z "$CLI_INSTALL_PATH" ]; then
                    CLI_INSTALL_PATH="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Default install path
    if [ -z "$CLI_INSTALL_PATH" ]; then
        CLI_INSTALL_PATH="."
    fi
    export CLI_INSTALL_PATH
    
    # Sincroniza estado após determinar o path
    sync_session_state
}

# ============================================================================
# Validação de Argumentos
# ============================================================================

# Valida argumentos após parsing
# Uso: validate_args
validate_args() {
    local errors=0
    
    # Validar modo
    if [[ ! "$CLI_MODE" =~ ^(new|refactor|minimal|full)$ ]]; then
        print_error "Modo inválido: $CLI_MODE"
        echo "Modos válidos: new, refactor, minimal, full"
        ((errors++))
    fi
    
    # Validar PRD para modo new
    if [ "$CLI_MODE" = "new" ] && [ -z "$CLI_PRD_PATH" ]; then
        print_error "--mode new requer --prd <path>"
        ((errors++))
    fi
    
    # Validar PRD existe
    if [ -n "$CLI_PRD_PATH" ] && [ ! -f "$CLI_PRD_PATH" ]; then
        print_error "PRD não encontrado: $CLI_PRD_PATH"
        ((errors++))
    fi
    
    # Validar stack
    local valid_stacks="laravel|filament|livewire|node|react|nextjs|vue|express|python|django|fastapi|flask|ruby|rails|go|rust|php|generic"
    if [[ ! "$CLI_STACK" =~ ^($valid_stacks)$ ]]; then
        print_error "Stack inválida: $CLI_STACK"
        echo "Stacks válidas: laravel, filament, livewire, node, react, nextjs, python, generic, etc."
        ((errors++))
    fi
    
    # Validar plataforma
    local valid_platforms="auto|antigravity|claude-code|gemini|opencode|codex|rovo|aider|cursor|continue|generic"
    if [[ ! "$CLI_PLATFORM" =~ ^($valid_platforms)$ ]]; then
        print_error "Plataforma inválida: $CLI_PLATFORM"
        ((errors++))
    fi
    
    # Validar idioma
    if [[ ! "$CLI_LANGUAGE" =~ ^(pt-BR|en)$ ]]; then
        print_error "Idioma inválido: $CLI_LANGUAGE"
        echo "Idiomas válidos: pt-BR, en"
        ((errors++))
    fi
    
    if [ $errors -gt 0 ]; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# Confirmação Interativa
# ============================================================================

# Solicita confirmação do usuário
# Uso: confirm "Deseja continuar?" && echo "sim"
confirm() {
    local message="${1:-Deseja continuar?}"
    local default="${2:-n}"
    
    local prompt
    if [ "$default" = "y" ]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    read -r -p "$message $prompt " response
    
    case "$response" in
        [yY][eE][sS]|[yY]|[sS][iI][mM]|[sS])
            return 0
            ;;
        [nN][oO]|[nN]|[nN][ãÃ][oO])
            return 1
            ;;
        "")
            if [ "$default" = "y" ]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# Exibição de Status
# ============================================================================

# Exibe resumo de configuração antes de executar
# Uso: show_config_summary
show_config_summary() {
    print_section "Configuração"
    
    echo "  Diretório:     $CLI_INSTALL_PATH"
    echo "  Modo:          $CLI_MODE"
    echo "  Stack:         $CLI_STACK"
    echo "  Plataforma:    $CLI_PLATFORM"
    echo "  Idioma:        $CLI_LANGUAGE"
    echo "  Auto-detectar: $CLI_AUTO_DETECT"
    echo "  MCP Engine:    $([ "$CLI_NO_MCP" = true ] && echo "Desabilitado" || echo "Habilitado")"
    echo "  Hooks:         $([ "$CLI_NO_HOOKS" = true ] && echo "Desabilitado" || echo "Habilitado")"
    echo "  Force:         $AIDEV_FORCE"
    echo "  Dry-run:       $AIDEV_DRY_RUN"
    
    if [ -n "$CLI_PRD_PATH" ]; then
        echo "  PRD:           $CLI_PRD_PATH"
    fi
    
    echo ""
}
