#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Instalador Global
# ============================================================================
# Instala o aidev globalmente no sistema
# 
# Uso: curl -fsSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash
# ============================================================================

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuração
REPO_URL="https://github.com/nandinhos/aidev-superpowers-v3"
INSTALL_DIR="${AIDEV_INSTALL_DIR:-$HOME/.aidev-superpowers}"
BIN_DIR="${AIDEV_BIN_DIR:-$HOME/.local/bin}"
VERSION="3.0.0"

# ============================================================================
# Funções
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  AI Dev Superpowers V3 - Instalador                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_dependencies() {
    print_step "Verificando dependências..."
    
    local missing=()
    
    # Git
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    # Bash 4+
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        print_error "Bash 4.0+ é necessário (atual: ${BASH_VERSION})"
        exit 1
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Dependências faltando: ${missing[*]}"
        echo "Por favor, instale as dependências e tente novamente."
        exit 1
    fi
    
    print_success "Todas as dependências encontradas"
}

install_from_git() {
    print_step "Baixando AI Dev Superpowers v$VERSION..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Instalação existente encontrada, atualizando..."
        cd "$INSTALL_DIR"
        git fetch --all --quiet
        git reset --hard origin/main --quiet
    else
        git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    fi
    
    print_success "Download concluído"
}

create_symlink() {
    print_step "Criando link simbólico..."
    
    # Cria diretório bin se não existir
    mkdir -p "$BIN_DIR"
    
    # Remove link antigo se existir
    rm -f "$BIN_DIR/aidev"
    
    # Cria link
    ln -sf "$INSTALL_DIR/bin/aidev" "$BIN_DIR/aidev"
    
    # Torna executável
    chmod +x "$INSTALL_DIR/bin/aidev"
    
    print_success "Link criado: $BIN_DIR/aidev"
}

configure_path() {
    print_step "Configurando PATH..."
    
    local shell_rc=""
    local path_line="export PATH=\"\$PATH:$BIN_DIR\""
    
    # Detecta shell
    case "$SHELL" in
        */bash)
            shell_rc="$HOME/.bashrc"
            ;;
        */zsh)
            shell_rc="$HOME/.zshrc"
            ;;
        */fish)
            shell_rc="$HOME/.config/fish/config.fish"
            path_line="set -gx PATH \$PATH $BIN_DIR"
            ;;
        *)
            print_warning "Shell não reconhecido. Adicione manualmente ao PATH:"
            echo "  $path_line"
            return
            ;;
    esac
    
    # Adiciona ao PATH se não existir
    if ! grep -q "aidev" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# AI Dev Superpowers" >> "$shell_rc"
        echo "$path_line" >> "$shell_rc"
        print_success "PATH configurado em $shell_rc"
    else
        print_success "PATH já configurado"
    fi
}

verify_installation() {
    print_step "Verificando instalação..."
    
    if [[ -f "$BIN_DIR/aidev" ]]; then
        print_success "aidev instalado com sucesso!"
    else
        print_error "Falha na instalação"
        exit 1
    fi
}

print_next_steps() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Instalação Concluída!                                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Próximos passos:"
    echo ""
    echo "  1. Recarregue seu shell:"
    echo -e "     ${CYAN}source ~/.bashrc${NC}  # ou ~/.zshrc"
    echo ""
    echo "  2. Inicialize em seu projeto:"
    echo -e "     ${CYAN}cd seu-projeto${NC}"
    echo -e "     ${CYAN}aidev init${NC}"
    echo ""
    echo "  3. Verifique a instalação:"
    echo -e "     ${CYAN}aidev --version${NC}"
    echo ""
    echo "Documentação: https://github.com/nandinhos/aidev-superpowers-v3"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header
    check_dependencies
    install_from_git
    create_symlink
    configure_path
    verify_installation
    print_next_steps
}

main "$@"
