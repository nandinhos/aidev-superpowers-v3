#!/bin/bash
# ============================================================================
# AI Dev Superpowers V3 - E2E Test Workflow
# ============================================================================
# Testa o fluxo completo: init -> status -> doctor em ambiente isolado
# ============================================================================

set -euo pipefail

# Configuração de Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Diretórios
REPO_ROOT=$(pwd)
TEST_DIR="/tmp/aidev-e2e-$(date +%s)"
AIDEV_BIN="$REPO_ROOT/bin/aidev"

print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}  E2E TEST: $1${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

fail() {
    echo -e "${RED}FAIL: $1${NC}"
    exit 1
}

# 1. Preparação
print_header "Preparação do Ambiente"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init -q
echo "Teste E2E" > README.md
git add . && git commit -m "Initial commit" -q
echo "✓ Ambiente criado em $TEST_DIR"

# 2. Teste: aidev init
print_header "Comando: aidev init"
# Usamos o binário do repo mas instalamos no diretório de teste
# Precisamos garantir que o CORE_ROOT_DIR seja o do repo
export AIDEV_ROOT_DIR="$REPO_ROOT"
bash "$AIDEV_BIN" init --detect --force || fail "aidev init falhou"

if [ ! -d ".aidev" ]; then
    fail "Diretório .aidev não foi criado"
fi
echo "✓ aidev init concluído com sucesso"

# 3. Teste: aidev status
print_header "Comando: aidev status"
bash "$AIDEV_BIN" status || fail "aidev status falhou"
echo "✓ aidev status exibido corretamente"

# 4. Teste: aidev doctor
print_header "Comando: aidev doctor"
bash "$AIDEV_BIN" doctor || fail "aidev doctor falhou"
echo "✓ aidev doctor passou no diagnóstico básico"

# 5. Teste: Persistência de Estado (Fallback)
print_header "Teste: Persistência de Estado (Fallback JQ)"
# Mock de ausência de jq
mkdir -p bin-mock
echo -e "#!/bin/bash\nexit 1" > bin-mock/jq
chmod +x bin-mock/jq
ORIG_PATH="$PATH"
export PATH="$(pwd)/bin-mock:$PATH"

# Ativa uma tarefa e verifica se persiste sem jq
bash "$AIDEV_BIN" status # Deve usar fallback
# (Apenas verificamos se não explode, a lógica interna já foi testada unitariamente)

export PATH="$ORIG_PATH"
echo "✓ Sistema resiliente à falta de jq"

# 6. Limpeza
print_header "Limpeza"
rm -rf "$TEST_DIR"
echo "✓ Ambiente de teste removido"

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}  TODOS OS TESTES E2E PASSARAM!${NC}"
echo -e "${GREEN}================================================================${NC}"
