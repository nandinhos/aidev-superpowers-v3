#!/bin/bash
set -euo pipefail

AIDEV_ROOT="${AIDEV_ROOT:-.aidev}"
STRATEGIES_FILE="$AIDEV_ROOT/config/workthrees/llm-strategies.json"

usage() {
    cat <<EOF
USAGE: select-llm.sh [OPTIONS]

Seleciona LLM dinamicamente baseada em complexidade (Strategy Pattern).

OPTIONS:
    --complexity LEVEL   Complexidade: low|medium|high|critical (obrigatorio)
    --score N           Score numerico (0-100)
    --strategy NAME     Estrategia: balanced|speed|cost|quality (default: balanced)
    --list              Lista estrategias disponiveis
    -h, --help          Mostra esta ajuda

EXEMPLOS:
    select-llm.sh --complexity medium
    select-llm.sh --score 35 --strategy cost
    select-llm.sh --list
EOF
    exit 1
}

COMPLEXITY=""
SCORE=""
STRATEGY="balanced"

while [[ $# -gt 0 ]]; do
    case $1 in
        --complexity) COMPLEXITY="$2"; shift 2 ;;
        --score) SCORE="$2"; shift 2 ;;
        --strategy) STRATEGY="$2"; shift 2 ;;
        --list) STRATEGY="list" ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [[ "$STRATEGY" == "list" ]]; then
    jq '.strategies' "$STRATEGIES_FILE"
    exit 0
fi

if [[ -z "$COMPLEXITY" && -z "$SCORE" ]]; then
    echo "ERROR: --complexity ou --score e obrigatorio" >&2
    usage
fi

if [[ -z "$COMPLEXITY" ]]; then
    if [[ $SCORE -le 20 ]]; then
        COMPLEXITY="low"
    elif [[ $SCORE -le 50 ]]; then
        COMPLEXITY="medium"
    elif [[ $SCORE -le 80 ]]; then
        COMPLEXITY="high"
    else
        COMPLEXITY="critical"
    fi
fi

score_for_complexity() {
    case "$COMPLEXITY" in
        low) echo 10 ;;
        medium) echo 35 ;;
        high) echo 65 ;;
        critical) echo 95 ;;
        *) echo 50 ;;
    esac
}

if [[ -z "$SCORE" ]]; then
    SCORE=$(score_for_complexity "$COMPLEXITY")
fi

select_model() {
    local strategy="$1"
    local score="$2"
    
    local rules=$(jq ".strategies.\"$strategy\".rules" "$STRATEGIES_FILE" 2>/dev/null | jq -c '.[]' || echo "[]")
    
    if [[ "$rules" == "[]" ]]; then
        echo "claude-sonnet-4-20250514"
        return
    fi
    
    local model="claude-opus-4-20250514"
    while read -r rule; do
        if [[ "$rule" == "[]" ]] || [[ -z "$rule" ]]; then
            continue
        fi
        local max_complexity=$(echo "$rule" | jq -r '.max_complexity' 2>/dev/null || echo "100")
        local model_candidate=$(echo "$rule" | jq -r '.model' 2>/dev/null || echo "claude-sonnet-4-20250514")
        
        if [[ $score -le $max_complexity ]]; then
            model="$model_candidate"
            break
        fi
    done <<< "$rules"
    
    echo "$model"
}

MODEL=$(select_model "$STRATEGY" "$SCORE")

cat <<EOF
{
  "complexity": "$COMPLEXITY",
  "score": $SCORE,
  "strategy": "$STRATEGY",
  "model": "$MODEL",
  "selected_at": "$(date -Iseconds)"
}
EOF
