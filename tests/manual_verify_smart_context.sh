#!/bin/bash
PROJECT_ROOT=$(pwd)
AIDEV_BIN="$PROJECT_ROOT/bin/aidev"
export CLI_INSTALL_PATH="."
export TERM=xterm-256color

# Greenfield Test
echo "=== Testing Greenfield ==="
rm -rf /tmp/greenfield_test
mkdir -p /tmp/greenfield_test
cd /tmp/greenfield_test

# Simulating clean install
AIDEV_INTERACTIVE=false "$AIDEV_BIN" init --language en > init.log 2>&1

echo "Log Output:"
cat init.log | grep -E "Contexto|Greenfield|Brownfield"

if grep -q "Greenfield detectado: PRD ausente" init.log; then
    echo "✅ CLI Output Verified (PRD Warning)"
else
    echo "❌ CLI Output Failed"
    cat init.log
fi

if [ -f ".aidev/agents/orchestrator.md" ]; then
    if grep -q "Modo: Greenfield" .aidev/agents/orchestrator.md; then
        echo "✅ Template Verified (Greenfield Section Present)"
    else
        echo "❌ Template Failed (Greenfield Section Missing)"
    fi

    if grep -q "Modo: Brownfield" .aidev/agents/orchestrator.md; then
        echo "❌ Template Failed (Brownfield Section Present in Greenfield)"
    else
        echo "✅ Template Verified (No Brownfield Section)"
    fi
else
    echo "❌ Template Failed (File not created)"
fi


# Brownfield Test
echo -e "\n=== Testing Brownfield ==="
rm -rf /tmp/brownfield_test
mkdir -p /tmp/brownfield_test
cd /tmp/brownfield_test
git init >/dev/null
git config user.email "test@example.com"
git config user.name "Test"

# Create fake history
for i in {1..12}; do
    touch "file$i"
    git add .
    git commit -m "commit $i" >/dev/null
done

AIDEV_INTERACTIVE=false "$AIDEV_BIN" init --language en > init.log 2>&1

echo "Log Output:"
cat init.log | grep -E "Contexto|Greenfield|Brownfield"

if grep -q "Brownfield detectado" init.log; then
    echo "✅ CLI Output Verified (Brownfield Detected)"
else
    echo "❌ CLI Output Failed"
    cat init.log
fi

if [ -f ".aidev/agents/orchestrator.md" ]; then
    if grep -q "Modo: Brownfield" .aidev/agents/orchestrator.md; then
        echo "✅ Template Verified (Brownfield Section Present)"
    else
        echo "❌ Template Failed (Brownfield Section Missing)"
    fi
else
    echo "❌ Template Failed (File not created)"
fi
