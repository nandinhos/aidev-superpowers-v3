#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Core Module
# ============================================================================
# Funções utilitárias de output e formatação
# 
# Uso: source lib/core.sh
# ============================================================================

readonly AIDEV_VERSION="${AIDEV_VERSION:-3.3.0}" 2>/dev/null || true

# ============================================================================
# Cores (declaração segura para múltiplos sources)
# ============================================================================

[[ -z "${RED:-}" ]] && readonly RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && readonly GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && readonly YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && readonly BLUE='\033[0;34m'
[[ -z "${CYAN:-}" ]] && readonly CYAN='\033[0;36m'
[[ -z "${MAGENTA:-}" ]] && readonly MAGENTA='\033[0;35m'
[[ -z "${BOLD:-}" ]] && readonly BOLD='\033[1m'
[[ -z "${NC:-}" ]] && readonly NC='\033[0m' # No Color

# ============================================================================
# Contadores (inicializados em cada operação)
# ============================================================================

AIDEV_FILES_CREATED=0
AIDEV_DIRS_CREATED=0

# ============================================================================
# Funções de Output
# ============================================================================

# Exibe header do script
# Uso: print_header "Título Opcional"
print_header() {
    local title="${1:-AI Dev Superpowers}"
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}${title}${NC} v${AIDEV_VERSION}${CYAN}                              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Exibe etapa de progresso
# Uso: print_step "Descrição da etapa"
print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

# Exibe mensagem de sucesso
# Uso: print_success "Operação concluída"
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Exibe informação
# Uso: print_info "Informação adicional"
print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Exibe aviso
# Uso: print_warning "Algo precisa de atenção"
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Exibe erro (envia para stderr)
# Uso: print_error "Algo deu errado"
print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Exibe modo de operação
# Uso: print_mode "new" "Criando novo projeto"
print_mode() {
    local mode="$1"
    local description="${2:-}"
    echo -e "${MAGENTA}◆${NC} Modo: ${BOLD}${mode}${NC} ${description}"
}

# Exibe sumário final de operação
# Uso: print_summary "modo" "stack"
print_summary() {
    local mode="${1:-full}"
    local stack="${2:-generic}"
    
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}Operação Concluída com Sucesso!${NC}${CYAN}                             ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
    printf "${CYAN}║${NC}  Diretórios criados: %-42s${CYAN}║${NC}\n" "$AIDEV_DIRS_CREATED"
    printf "${CYAN}║${NC}  Arquivos criados:   %-42s${CYAN}║${NC}\n" "$AIDEV_FILES_CREATED"
    printf "${CYAN}║${NC}  Modo:               %-42s${CYAN}║${NC}\n" "$mode"
    printf "${CYAN}║${NC}  Stack:              %-42s${CYAN}║${NC}\n" "$stack"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Exibe separador visual
# Uso: print_separator
print_separator() {
    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
}

# Exibe seção com título
# Uso: print_section "Nome da Seção"
print_section() {
    echo ""
    echo -e "${BOLD}${CYAN}▸ $1${NC}"
    echo ""
}

# ============================================================================
# Funções de Debug (opcional)
# ============================================================================

# Exibe mensagem de debug (somente se AIDEV_DEBUG=true)
# Uso: print_debug "Mensagem de debug"
print_debug() {
    if [ "${AIDEV_DEBUG:-false}" = "true" ]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $1" >&2
    fi
}

# ============================================================================
# Reset de contadores
# ============================================================================

# Reseta contadores para nova operação
# Uso: reset_counters
reset_counters() {
    AIDEV_FILES_CREATED=0
    AIDEV_DIRS_CREATED=0
}

# Incrementa contador de arquivos
# Uso: increment_files
increment_files() {
    ((AIDEV_FILES_CREATED++)) || true
}

# Incrementa contador de diretórios
# Uso: increment_dirs
increment_dirs() {
    ((AIDEV_DIRS_CREATED++)) || true
}
# ============================================================================
# Persistência de Estado (Sessão)
# ============================================================================

# Define um valor no estado persistente (JSON)
# Uso: set_state_value "key" "value"
set_state_value() {
    local key="$1"
    local value="$2"
    local install_path="${CLI_INSTALL_PATH:-.}"
    local state_file="$install_path/.aidev/state/session.json"
    
    mkdir -p "$(dirname "$state_file")"
    
    # Inicializa arquivo se não existir
    if [ ! -f "$state_file" ]; then
        echo "{}" > "$state_file"
    fi
    
    # Atualiza via jq ou fallback
    if command -v jq >/dev/null 2>&1; then
        local tmp_file
        tmp_file=$(mktemp)
        jq --arg key "$key" --arg val "$value" '.[$key] = $val' "$state_file" > "$tmp_file" && mv "$tmp_file" "$state_file"
    else
        # Fallback via sed/grep para casos ultra-mínimos (apenas para strings simples)
        # ALERTA: Não suporta arrays ou objetos complexos, apenas pares chave-valor simples
        local tmp_file=$(mktemp)
        if grep -q "\"$key\":" "$state_file"; then
            # Atualiza existente
            sed "s/\"$key\": \".*\"/\"$key\": \"$value\"/" "$state_file" > "$tmp_file"
        else
            # Adiciona novo (antes do último })
            sed "s/}$/  \"$key\": \"$value\",\n}/" "$state_file" > "$tmp_file"
            # Limpa vírgula extra se for o caso
            sed -i 's/,\n}/\n}/g' "$tmp_file"
        fi
        mv "$tmp_file" "$state_file"
        print_warning "JQ não encontrado. Usando fallback básico para persistência."
    fi
    
    print_debug "Estado atualizado: $key=$value"
}

# Obtém um valor do estado persistente (JSON)
# Uso: value=$(get_state_value "key" ["default"])
get_state_value() {
    local key="$1"
    local default="${2:-}"
    local install_path="${CLI_INSTALL_PATH:-.}"
    local state_file="$install_path/.aidev/state/session.json"
    
    if [ ! -f "$state_file" ]; then
        echo "$default"
        return 0
    fi
    
    local value=""
    if command -v jq >/dev/null 2>&1; then
        value=$(jq -r --arg key "$key" '.[$key] // empty' "$state_file" 2>/dev/null || echo "")
    fi
    
    # Se JQ falhou ou não retornou nada, tenta o fallback
    if [ -z "$value" ]; then
        # Fallback simples via grep/sed
        value=$(grep "\"$key\":" "$state_file" | sed "s/.*\"$key\": \"\(.*\)\".*/\1/" | head -n 1 || echo "")
    fi
    
    if [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# ============================================================================
# Gestão de Segredos (.env)
# ============================================================================

# Carrega variáveis de um arquivo .env se ele existir
# Uso: load_env ["path/to/.env"]
load_env() {
    local env_file="${1:-${CLI_INSTALL_PATH:-.}/.env}"
    
    if [ -f "$env_file" ]; then
        print_debug "Carregando variáveis de $env_file"
        # Lê linha por linha ignorando comentários e exportando
        while IFS='=' read -r key value || [ -n "$key" ]; do
            # Remove whitespace
            key=$(echo "$key" | xargs)
            # Ignora linhas vazias ou comentários
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            
            # Remove aspas do valor se existirem
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            
            export "$key"="$value"
        done < "$env_file"
    fi
}

# Define ou atualiza uma variável no arquivo .env
# Uso: set_env_value "KEY" "VALUE" ["path/to/.env"]
set_env_value() {
    local key="$1"
    local value="$2"
    local env_file="${3:-${CLI_INSTALL_PATH:-.}/.env}"
    
    mkdir -p "$(dirname "$env_file")"
    [ ! -f "$env_file" ] && touch "$env_file"
    
    if grep -q "^$key=" "$env_file"; then
        # Atualiza existente
        sed -i "s|^$key=.*|$key=\"$value\"|" "$env_file"
    else
        # Adiciona novo
        echo "$key=\"$value\"" >> "$env_file"
    fi
    
    # Exporta para a sessão atual também
    export "$key"="$value"
    print_debug "Variável $key definida em $env_file"
}
