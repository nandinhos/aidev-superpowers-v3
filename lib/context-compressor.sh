#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Context Compressor Module
# ============================================================================
# Gera resumos de contexto de ultra-baixa latência e fixação de persona
# ============================================================================

# Gera um markdown compacto com o estado atual e identidade
# Uso: context_compressor_generate [output_file]
context_compressor_generate() {
    local output_file="${1:-.aidev/.cache/activation_context.md}"
    local passive_contract=".aidev/AI_INSTRUCTIONS.md"
    local unified_file=".aidev/state/unified.json"
    
    mkdir -p "$(dirname "$output_file")"
    
    if [ ! -f "$unified_file" ]; then
        echo "⚠️ Estado não encontrado." > "$output_file"
        return 1
    fi
    
    # Carrega dados via jq
    local version=$(jq -r '.version // "4.1.1"' "$unified_file")
    local sprint_name=$(jq -r '.sprint_context.sprint_name // "Nenhuma"' "$unified_file")
    [[ "$sprint_name" == "null" ]] && sprint_name="Sprint 5 (Concluída)"
    
    local sprint_pct=$(jq -r '.sprint_context.progress_percentage // 0' "$unified_file")
    local task_id=$(jq -r '.sprint_context.current_task_id // "Nenhuma"' "$unified_file")
    [[ "$task_id" == "null" ]] && task_id="Nenhuma"
    
    local intent=$(jq -r '.active_intent // "Aguardando comando"' "$unified_file")
    local skill=$(jq -r '.active_skill // "Nenhuma"' "$unified_file")

    # Tenta obter o último pensamento (Cognitive Context) do último checkpoint
    local last_thoughts="Nenhum registro recente."
    local last_ckpt_file=$(ls -t .aidev/state/sprints/current/checkpoints/ckpt-*.json 2>/dev/null | head -n 1)
    if [ -f "$last_ckpt_file" ]; then
        last_thoughts=$(jq -r '.cognitive_context.chain_of_thought // .description // "Retomada de sessão."' "$last_ckpt_file")
    fi

    # --- GERAÇÃO DO CONTEÚDO ---
    {
        echo "# 🧠 IDENTIDADE DO SISTEMA"
        echo "Você é o **AI Dev Orquestrador v$version**."
        echo "Sua missão é coordenar o desenvolvimento seguindo **TDD, YAGNI e DRY**."
        echo "Comportamento mestre: \`.aidev/agents/orchestrator.md\`"
        echo ""
        echo "# 🚀 RESUMO EXECUTIVO"
        echo "Estamos no projeto \`$(basename "$PWD")\`."
        echo "- **Intenção Ativa**: $intent"
        echo "- **Skill em Uso**: $skill"
        echo "- **Último Pensamento**: $last_thoughts"
        echo ""
        echo "## 📊 Estado da Sprint"
        echo "- **Sprint**: $sprint_name"
        echo "- **Progresso**: ${sprint_pct}%"
        echo "- **Tarefa Atual**: \`$task_id\`"
        echo ""
        
        if [ -n "$ANTIGRAVITY_AGENT" ]; then
            echo "> 💡 **ANTIGRAVITY DETECTADO**: Use \`read_memory\` e \`build_context\` para detalhes técnicos."
            echo ""
        fi

        echo "## 🛠️ Próximos Passos"
        if [ "$sprint_pct" -eq 100 ]; then
            echo "1. Arquivar Sprint atual."
            echo "2. Iniciar Sprint 6 (Smart Upgrade)."
        else
            echo "1. Continuar tarefa \`$task_id\`."
        fi
        
        echo ""
        echo "---"
        echo "*(Este resumo foi gerado passivamente para economizar tokens. Use as ferramentas para investigar arquivos específicos.)*"
    } > "$output_file"

    # Espelha para o contrato passivo (v4.1.1)
    cp "$output_file" "$passive_contract"
    
    return 0
}
