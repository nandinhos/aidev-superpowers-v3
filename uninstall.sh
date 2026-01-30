#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Desinstalador
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="${AIDEV_INSTALL_DIR:-$HOME/.aidev-superpowers}"
BIN_DIR="${AIDEV_BIN_DIR:-$HOME/.local/bin}"

echo ""
echo -e "${CYAN}AI Dev Superpowers - Desinstalador${NC}"
echo ""

# Confirma
read -p "Deseja realmente desinstalar o AI Dev Superpowers? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelado."
    exit 0
fi

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
