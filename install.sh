#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - One-Liner Installer
# ============================================================================
# Uso: curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash
# ============================================================================

set -euo pipefail

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/.aidev-core"
REPO_URL="https://github.com/nandinhos/aidev-superpowers-v3.git"

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}  AI Dev Superpowers - Instalador Profissional                  ${NC}"
    echo -e "${BLUE}================================================================${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 1. Verificações Iniciais
print_header
print_info "Iniciando instalação em: $INSTALL_DIR"

if ! command -v git >/dev/null 2>&1; then
    print_error "Git não encontrado. Por favor, instale o Git e tente novamente."
    exit 1
fi

# 2. Clonagem/Atualização
if [ -d "$INSTALL_DIR" ]; then
    print_info "Diretório já existe. Atualizando núcleo..."
    cd "$INSTALL_DIR"
    
    # Protecao: limpar arquivos nao rastreados que dao conflito com o remote
    if git status --porcelain | grep -q '^[?]'; then
        print_info "Limpando arquivos nao rastreados que dao conflito..."
        for untracked in $(git status --porcelain | grep '^??' | cut -c4-); do
            if [ -f "$untracked" ]; then
                rm -f "$untracked" 2>/dev/null || true
            fi
        done
    fi
    
    git pull origin main || {
        print_warning "Conflito ao atualizar. Forcando reset..."
        git reset --hard origin/main
    }
else
    print_info "Clonando repositório..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 3. Configuração do PATH
BIN_PATH="$INSTALL_DIR/bin"
PATH_LINE="export PATH=\"\$PATH:$BIN_PATH\""

update_shell_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        if ! grep -q "$BIN_PATH" "$config_file"; then
            echo -e "\n# AI Dev Superpowers" >> "$config_file"
            echo "$PATH_LINE" >> "$config_file"
            print_success "PATH adicionado ao $config_file"
            return 0
        else
            print_info "PATH já configurado em $config_file"
            return 1
        fi
    fi
    return 1
}

# Tenta atualizar configs comuns
UPDATED_PATH=false
update_shell_config "$HOME/.bashrc" && UPDATED_PATH=true || true
update_shell_config "$HOME/.zshrc" && UPDATED_PATH=true || true

# 4. Finalização e Interatividade
export PATH="$PATH:$BIN_PATH"

echo ""
print_success "Ambiente configurado com sucesso!"
echo ""

# Pergunta se deseja inicializar no diretório atual
echo -n -e "${YELLOW}🤔 Deseja inicializar o orquestrador no diretório atual agora? [y/N]: ${NC}"
read -r response </dev/tty || response="n"

if [[ "$response" =~ ^[yY] ]]; then
    echo ""
    "$BIN_PATH/aidev" init --install-in "$PWD"
else
    echo ""
    print_info "Instalação concluída!"
    echo -e "Para ativar o orquestrador mais tarde neste projeto, use:"
    echo -e "  ${GREEN}aidev init${NC}"
    echo ""
    if [ "$UPDATED_PATH" = "true" ]; then
        print_warning "Reinicie seu terminal ou rode: source ~/.bashrc (ou ~/.zshrc)"
    fi
fi

print_header
