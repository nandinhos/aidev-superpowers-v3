#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Desinstalador
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="${AIDEV_INSTALL_DIR:-$HOME/.aidev-superpowers}"
BIN_DIR="${AIDEV_BIN_DIR:-$HOME/.local/bin}"
DRY_RUN="${AIDEV_DRY_RUN:-0}"

# ============================================================================
# Função de validação de segurança
# ============================================================================

validate_install_dir() {
    local dir="$1"

    # Verifica se está vazio
    if [[ -z "$dir" ]]; then
        echo -e "${RED}ERRO: Diretório de instalação está vazio ou não definido${NC}" >&2
        echo "Defina AIDEV_INSTALL_DIR ou use o padrão." >&2
        return 1
    fi

    # Verifica se é raiz
    if [[ "$dir" == "/" ]]; then
        echo -e "${RED}ERRO: Não é permitido desinstalar de '/' (diretório raiz)${NC}" >&2
        echo "Isso destruiria todo o sistema!" >&2
        return 1
    fi

    # Lista de paths críticos do sistema (blacklist)
    local critical_paths=(
        "/usr"
        "/bin"
        "/sbin"
        "/etc"
        "/home"
        "/var"
        "/opt"
        "/boot"
        "/lib"
        "/lib64"
        "/root"
        "/sys"
        "/proc"
        "/dev"
    )

    # Verifica se é um path crítico
    for critical in "${critical_paths[@]}"; do
        if [[ "$dir" == "$critical" ]]; then
            echo -e "${RED}ERRO: Não é permitido desinstalar de diretórios do sistema${NC}" >&2
            echo "Path não permitido: $dir" >&2
            echo "Paths críticos não podem ser removidos por segurança." >&2
            return 1
        fi
    done

    # PROTEÇÃO EXTRA: Diretório contendo múltiplos projetos git
    # Detecta dinamicamente se é um "diretório de projetos" (contém múltiplos repos)
    if [[ -d "$dir" ]]; then
        local git_subdirs=0
        for subdir in "$dir"/*/; do
            if [[ -d "${subdir}.git" ]]; then
                ((git_subdirs++))
            fi
        done
        
        if [[ $git_subdirs -ge 2 ]]; then
            echo -e "${RED}ERRO: Não é permitido desinstalar diretório que contém projetos${NC}" >&2
            echo "Path não permitido: $dir" >&2
            echo "Este diretório contém $git_subdirs repositórios git." >&2
            echo "Diretórios com múltiplos projetos são protegidos por segurança." >&2
            return 1
        fi
    fi

    # PROTEÇÃO EXTRA: Repositórios git
    if [[ -d "$dir/.git" ]] && [[ "${AIDEV_FORCE_GIT:-0}" != "1" ]]; then
        echo -e "${RED}ERRO: Não é permitido desinstalar diretórios com repositório git${NC}" >&2
        echo "Path não permitido: $dir (contém .git)" >&2
        echo "Repositórios git são protegidos por segurança." >&2
        return 1
    fi

    # PROTEÇÃO EXTRA: Deve conter .aidev
    if [[ -d "$dir" ]] && [[ ! -d "$dir/.aidev" ]] && [[ "$dir" != *".aidev-superpowers"* ]]; then
        echo -e "${YELLOW}AVISO: Diretório não parece ser uma instalação aidev${NC}" >&2
        echo "Path: $dir" >&2
        echo "Esperado: $dir/.aidev ou nome contendo .aidev-superpowers" >&2
        return 1
    fi

    return 0
}

# ============================================================================
# Início do Desinstalador
# ============================================================================

echo ""
if [[ "$DRY_RUN" == "1" ]]; then
    echo -e "${YELLOW}AI Dev Superpowers - Desinstalador (DRY-RUN MODE)${NC}"
    echo -e "${YELLOW}Modo simulação: nenhum arquivo será deletado${NC}"
else
    echo -e "${CYAN}AI Dev Superpowers - Desinstalador${NC}"
fi
echo ""

# Valida diretório de instalação ANTES de confirmar
if ! validate_install_dir "$INSTALL_DIR"; then
    echo ""
    echo -e "${RED}Desinstalação abortada por segurança.${NC}"
    exit 1
fi

# Mostra o que será removido
echo "Os seguintes itens serão removidos:"
echo "  - Link: $BIN_DIR/aidev"
echo "  - Diretório: $INSTALL_DIR"
echo ""

# Confirma
read -p "Deseja realmente desinstalar o AI Dev Superpowers? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelado."
    exit 0
fi

# ============================================================================
# Execução da Desinstalação
# ============================================================================

if [[ "$DRY_RUN" == "1" ]]; then
    # Modo dry-run: apenas mostra o que seria feito
    echo -e "${YELLOW}[DRY-RUN]${NC} O que seria removido:"
    echo ""
    
    if [[ -L "$BIN_DIR/aidev" ]]; then
        echo -e "${YELLOW}  → Seria removido:${NC} link $BIN_DIR/aidev"
    fi
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}  → Seria removido:${NC} diretório $INSTALL_DIR"
        file_count=$(find "$INSTALL_DIR" -type f 2>/dev/null | wc -l)
        echo -e "${YELLOW}    (contém $file_count arquivos)${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Nenhum arquivo foi removido (modo dry-run).${NC}"
    echo ""
else
    # Modo normal: remove de fato
    
    # Remove link
    if [[ -L "$BIN_DIR/aidev" ]]; then
        rm "$BIN_DIR/aidev"
        echo -e "${GREEN}✓${NC} Link removido: $BIN_DIR/aidev"
    fi

    # Remove instalação
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}✓${NC} Diretório removido: $INSTALL_DIR"
    fi

    echo ""
    echo -e "${GREEN}AI Dev Superpowers desinstalado com sucesso!${NC}"
    echo ""
    echo "Nota: As linhas adicionadas ao seu .bashrc/.zshrc não foram removidas."
    echo "Você pode removê-las manualmente se desejar."
    echo ""
fi
