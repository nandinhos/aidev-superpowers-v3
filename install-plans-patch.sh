#!/bin/bash
# ============================================================================
# AI Dev Superpowers V3 - Patch para Estrutura de Planos v4.3.0
# ============================================================================
# Aplica correção para instalações existentes adicionando templates de planos
# 
# Uso: 
#   curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install-plans-patch.sh | bash
#   OU
#   bash install-plans-patch.sh
# ============================================================================

set -euo pipefail

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}  AI Dev Superpowers - Patch v4.3.0 (Estrutura de Planos)      ${NC}"
    echo -e "${BLUE}================================================================${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

INSTALL_DIR="${INSTALL_DIR:-$HOME/.aidev-core}"
REPO_URL="https://github.com/nandinhos/aidev-superpowers-v3.git"

check_installation() {
    if [ ! -d "$INSTALL_DIR" ]; then
        print_error "Instalação não encontrada em: $INSTALL_DIR"
        print_info "Execute primeiro o instalador principal:"
        echo "  curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash"
        exit 1
    fi
    
    if [ ! -f "$INSTALL_DIR/bin/aidev" ]; then
        print_error "Instalação incompleta ou corrompida em: $INSTALL_DIR"
        print_info "Recomendado: reinstalar com o instalador principal"
        exit 1
    fi
}

apply_patch() {
    print_header
    print_info "Verificando instalação em: $INSTALL_DIR"
    check_installation
    
    print_info "Aplicando patch de estrutura de planos..."
    cd "$INSTALL_DIR"
    
    # 1. Atualiza o repositório
    print_info "Atualizando repositório..."
    git pull origin main
    
    # 2. Verifica se os templates de planos existem
    TEMPLATES_DIR="$INSTALL_DIR/templates/plans"
    
    if [ ! -f "$TEMPLATES_DIR/README.md.tmpl" ]; then
        print_info "Templates de planos não encontrados. Criando..."
        
        # Cria estrutura de diretórios
        mkdir -p "$TEMPLATES_DIR"/{backlog,features,current,history,archive}
        
        # Baixa templates do GitHub
        BASE_URL="https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/templates/plans"
        
        templates=(
            "README.md.tmpl"
            "backlog/README.md.tmpl"
            "features/README.md.tmpl"
            "current/README.md.tmpl"
            "history/README.md.tmpl"
            "archive/README.md.tmpl"
        )
        
        for template in "${templates[@]}"; do
            print_info "Baixando $template..."
            curl -sSL "$BASE_URL/$template" -o "$TEMPLATES_DIR/$template" || {
                print_warning "Falha ao baixar $template (pode já existir)"
            }
        done
        
        print_success "Templates criados com sucesso!"
    else
        print_info "Templates de planos já existem. Atualizando..."
        git checkout main -- templates/plans/ 2>/dev/null || true
    fi
    
    # 3. Sincroniza com instalação global (se existir)
    GLOBAL_DIR="$HOME/.aidev-superpowers"
    if [ -d "$GLOBAL_DIR" ]; then
        print_info "Sincronizando com instalação global..."
        mkdir -p "$GLOBAL_DIR/templates/plans"/{backlog,features,current,history,archive}
        cp -r "$TEMPLATES_DIR"/* "$GLOBAL_DIR/templates/plans/" 2>/dev/null || true
        print_success "Instalação global atualizada!"
    fi
    
    # 4. Atualiza versão no VERSION
    echo "4.3.0" > "$INSTALL_DIR/VERSION"
    
    # 5. Finalização
    echo ""
    print_success "Patch v4.3.0 aplicado com sucesso!"
    echo ""
    print_info "Novos recursos disponíveis:"
    echo "  • Estrutura completa de planos em novos projetos"
    echo "  • Templates README para backlog/, features/, current/, history/, archive/"
    echo "  • Suporte ao comando: aidev feature list"
    echo ""
    print_info "Para aplicar em projetos existentes:"
    echo "  cd /seu/projeto"
    echo "  aidev upgrade"
    echo ""
    
    # 6. Pergunta se deseja testar
    echo -n -e "${YELLOW}🤔 Deseja testar em um novo projeto temporário? [y/N]: ${NC}"
    read -r response </dev/tty 2>/dev/null || response="n"
    
    if [[ "$response" =~ ^[yY] ]]; then
        TEST_DIR=$(mktemp -d)
        print_info "Criando projeto de teste em: $TEST_DIR"
        cd "$TEST_DIR"
        "$INSTALL_DIR/bin/aidev" init --language pt-BR --no-mcp 2>&1 | tail -10
        echo ""
        print_info "Estrutura de planos criada:"
        ls -la "$TEST_DIR/.aidev/plans/"
        echo ""
        print_info "Para remover o diretório de teste:"
        echo "  rm -rf $TEST_DIR"
    fi
    
    print_header
}

# Execução principal
apply_patch
