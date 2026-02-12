#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Sprint Guard Module
# ============================================================================
# Scoring de alinhamento para evitar desvios da task ativa
# ============================================================================

GUARD_THRESHOLD=${GUARD_THRESHOLD:-0.3}
GUARD_ENABLED=${GUARD_ENABLED:-true}

guard_check() {
    local proposed_action="$1"
    local active_task_name="$2"
    
    [[ "$GUARD_ENABLED" != "true" ]] && return 0
    
    local score=$(guard_calculate_score "$proposed_action" "$active_task_name")
    local threshold=$(guard_get_threshold)
    
    if (( $(echo "$score < $threshold" | bc -l) )); then
        echo "${YELLOW}[SPRINT GUARD] Aviso: Ação proposta pode estar desalinhada (Score: $score)${NC}" >&2
        echo "${YELLOW}Tarefa ativa: $active_task_name${NC}" >&2
        echo "${YELLOW}Ação proposta: $proposed_action${NC}" >&2
        return 1
    fi
    
    return 0
}

guard_calculate_score() {
    local action="${1,,}"
    local target="${2,,}"
    
    if [[ -z "$action" || -z "$target" ]]; then
        echo "0.00"
        return 0
    fi
    
    if [[ "$action" == "$target" ]]; then
        echo "1.00"
        return 0
    fi
    
    local stop_words="o a os as um uma uns umas de do da dos das em no na nos nas por para com para e ou mas se como"
    
    # Função interna para limpar e extrair palavras significativas
    local action_sig=""
    local target_sig=""
    
    # Limpeza manual sem xargs para evitar disparar traps de erro
    local action_clean=$(echo "$action" | sed 's/[[:punct:]]/ /g')
    for w in $action_clean; do
        if [[ ${#w} -gt 2 ]]; then
            if [[ ! " $stop_words " == *" $w "* ]]; then
                action_sig="$action_sig $w"
            fi
        fi
    done
    
    local target_clean=$(echo "$target" | sed 's/[[:punct:]]/ /g')
    for w in $target_clean; do
        if [[ ${#w} -gt 2 ]]; then
            if [[ ! " $stop_words " == *" $w "* ]]; then
                target_sig="$target_sig $w"
            fi
        fi
    done
    
    if [[ -z "$target_sig" ]]; then
        echo "0.00"
        return 0
    fi
    
    local matches=0
    local target_count=0
    local unique_target_words=$(echo "$target_sig" | tr ' ' '\n' | sort -u)
    
    for tw in $unique_target_words; do
        if [[ -n "$tw" ]]; then
            ((target_count++)) || true
            if [[ " $action_sig " == *" $tw "* ]]; then
                ((matches++)) || true
            fi
        fi
    done
    
    if [ "$target_count" -eq 0 ]; then
        echo "0.00"
    else
        local res=$(echo "scale=2; $matches / $target_count" | bc -l)
        # Garante formato 0.XX
        echo "$res" | sed 's/^\./0./' | cut -c1-4
    fi
}

guard_get_threshold() {
    echo "$GUARD_THRESHOLD"
}

guard_get_active_keywords() {
    local text="$1"
    local stop_words="o a os as um uma uns umas de do da dos das em no na nos nas por para com para e ou mas se como"
    
    # Remove pontuação básica mantendo acentos
    local clean_text=$(echo "${text,,}" | sed 's/[[:punct:]]/ /g')
    local words=$(echo "$clean_text" | xargs)
    local sig_words=""
    for w in $words; do
        if [[ ${#w} -gt 2 ]] && [[ ! " $stop_words " =~ " $w " ]]; then
            sig_words="$sig_words $w"
        fi
    done
    echo "$sig_words" | xargs | tr ' ' '\n' | sort -u | xargs
}

guard_render_status() {
    local score="${1:-1.0}"
    local threshold=$(guard_get_threshold)
    
    echo "Sprint Guard Status:"
    echo "  Threshold: $threshold"
    echo "  Score atual: $score"
    
    if (( $(echo "$score >= $threshold" | bc -l) )); then
        echo "  Estado: 🟢 Alinhado"
    else
        echo "  Estado: 🔴 Desalinhado"
    fi
}
