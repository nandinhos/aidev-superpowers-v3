#!/bin/bash
set -euo pipefail

AIDEV_ROOT="${AIDEV_ROOT:-.aidev}"
RULES_FILE="$AIDEV_ROOT/config/workthrees/complexity-rules.json"

usage() {
    cat <<EOF
USAGE: classify-complexity.sh [OPTIONS]

Classifica complexidade de uma tarefa automaticamente.

OPTIONS:
    --files-count N      Numero de arquivos afetados
    --languages N        Numero de linguagens envolvidas
    --type TYPE          Tipo: new|refactor|fix (default: new)
    --has-tests          Tem testes existentes
    --deps-external N   Numero de deps externas
    --breaking          Contem breaking changes
    --strategy RULES     Estrategia de scoring (default: standard)
    -h, --help           Mostra esta ajuda

EXEMPLO:
    classify-complexity.sh --files-count 5 --languages 1 --type new
EOF
    exit 1
}

FILES_COUNT=0
LANGUAGES=1
TYPE="new"
HAS_TESTS="false"
DEPS_EXTERNAL=0
BREAKING="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --files-count) FILES_COUNT="$2"; shift 2 ;;
        --languages) LANGUAGES="$2"; shift 2 ;;
        --type) TYPE="$2"; shift 2 ;;
        --has-tests) HAS_TESTS="true"; shift ;;
        --deps-external) DEPS_EXTERNAL="$2"; shift 2 ;;
        --breaking) BREAKING="true"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

score=0

if [[ $FILES_COUNT -gt 10 ]]; then
    score=$((score + 30))
elif [[ $FILES_COUNT -gt 5 ]]; then
    score=$((score + 20))
elif [[ $FILES_COUNT -gt 0 ]]; then
    score=$((score + 10))
fi

if [[ $LANGUAGES -gt 1 ]]; then
    score=$((score + 15))
fi

if [[ "$TYPE" == "refactor" ]]; then
    score=$((score + 25))
elif [[ "$TYPE" == "fix" ]]; then
    score=$((score + 5))
else
    score=$((score + 10))
fi

if [[ "$HAS_TESTS" == "false" ]]; then
    score=$((score + 15))
fi

if [[ $DEPS_EXTERNAL -gt 3 ]]; then
    score=$((score + 20))
elif [[ $DEPS_EXTERNAL -gt 0 ]]; then
    score=$((score + 10))
fi

if [[ "$BREAKING" == "true" ]]; then
    score=$((score + 30))
fi

if [[ $score -gt 100 ]]; then
    score=100
fi

if [[ $score -le 20 ]]; then
    complexity="low"
elif [[ $score -le 50 ]]; then
    complexity="medium"
elif [[ $score -le 80 ]]; then
    complexity="high"
else
    complexity="critical"
fi

cat <<EOF
{
  "score": $score,
  "complexity": "$complexity",
  "inputs": {
    "files_count": $FILES_COUNT,
    "languages": $LANGUAGES,
    "type": "$TYPE",
    "has_tests": $HAS_TESTS,
    "deps_external": $DEPS_EXTERNAL,
    "breaking": $BREAKING
  }
}
EOF
