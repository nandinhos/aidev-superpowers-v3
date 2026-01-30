#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Core Module
# ============================================================================
# Funções utilitárias de output e formatação
# 
# Uso: source lib/core.sh
# ============================================================================

readonly AIDEV_VERSION="${AIDEV_VERSION:-3.0.0}" 2>/dev/null || true

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
