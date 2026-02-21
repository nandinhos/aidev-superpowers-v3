#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Context Compressor Module
# ============================================================================
# Gera resumos de contexto de ultra-baixa latência e fixação de persona
# Sprint 4: enriquecimento com memória cross-session via Basic Memory
# ============================================================================

_SCRIPT_DIR_CTX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega detecção unificada de MCPs se disponível
if ! type mcp_detect_basic_memory &>/dev/null; then
    source "$_SCRIPT_DIR_CTX/../.aidev/lib/mcp-detect.sh" 2>/dev/null || true
fi

# ============================================================================
# Busca memória cross-session no Basic Memory (Sprint 4)
# Retorna até 3 lições/checkpoints relevantes ao projeto.
# Falha silenciosamente — nunca bloqueia a geração do contexto.
# ============================================================================
_ctx_fetch_cross_session_memory() {
    local project_name="$1"

    type mcp_detect_basic_memory &>/dev/null || return 1
    mcp_detect_basic_memory 2>/dev/null || return 1
    type mcp__basic-memory__search_notes &>/dev/null || return 1

    mcp__basic-memory__search_notes query="$project_name" 2>/dev/null | head -20 || return 1
}

# ============================================================================
# Gera um markdown compacto com o estado atual e identidade
# Uso: context_compressor_generate [output_file]
# ============================================================================
context_compressor_generate() {
    local output_file="${1:-.aidev/.cache/activation_context.md}"
    local passive_contract=".aidev/AI_INSTRUCTIONS.md"
    local unified_file=".aidev/state/unified.json"

    mkdir -p "$(dirname "$output_file")"
    mkdir -p ".aidev/state"

    if [ ! -f "$unified_file" ]; then
        local current_date
        current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        cat > "$unified_file" << 'EOF'
{
  "version": "4.5.6",
  "sprint_context": {
    "sprint_id": null,
    "sprint_name": "Inicial",
    "status": "pending",
    "progress_percentage": 0,
    "completed_tasks": 0,
    "total_tasks": 0,
    "current_task_id": null,
    "next_action": null,
    "session_metrics": {
      "checkpoints_created": 0,
      "sessions_count": 1,
      "tokens_used": 0
    },
    "context_log": []
  },
  "active_intent": "Aguardando comando",
  "active_skill": "Nenhuma",
  "unified": {
    "version": "4.5.6",
    "needs_sync": true
  },
  "metadata": {
    "created_at": "DATE_PLACEHOLDER",
    "updated_at": "DATE_PLACEHOLDER"
  }
}
EOF
        sed -i "s/DATE_PLACEHOLDER/$current_date/g" "$unified_file"
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

    # Tenta buscar memória cross-session (Sprint 4 — falha silenciosa)
    local project_name cross_session_memory bm_status
    project_name=$(basename "$PWD")
    cross_session_memory=$(_ctx_fetch_cross_session_memory "$project_name" 2>/dev/null) || true
    if type mcp_detect_basic_memory &>/dev/null && mcp_detect_basic_memory 2>/dev/null; then
        bm_status="ativo"
    else
        bm_status="indisponivel"
    fi

    # --- GERAÇÃO DO CONTEÚDO ---
    {
        echo "# IDENTIDADE DO SISTEMA"
        echo "Você é o **AI Dev Orquestrador v$version**."
        echo "Sua missão é coordenar o desenvolvimento seguindo **TDD, YAGNI e DRY**."
        echo "Comportamento mestre: \`.aidev/agents/orchestrator.md\`"
        echo ""
        echo "# RESUMO EXECUTIVO"
        echo "Estamos no projeto \`$project_name\`."
        echo "- **Intenção Ativa**: $intent"
        echo "- **Skill em Uso**: $skill"
        echo "- **Último Pensamento**: $last_thoughts"
        echo "- **Basic Memory**: $bm_status"
        echo ""
        echo "## Estado da Sprint"
        echo "- **Sprint**: $sprint_name"
        echo "- **Progresso**: ${sprint_pct}%"
        echo "- **Tarefa Atual**: \`$task_id\`"
        echo ""

        if [ -n "$ANTIGRAVITY_AGENT" ]; then
            echo "> ANTIGRAVITY DETECTADO: Use \`read_memory\` e \`build_context\` para detalhes técnicos."
            echo ""
        fi

        # Seção de memória cross-session (apenas quando Basic Memory disponível e com resultados)
        if [ -n "$cross_session_memory" ]; then
            echo "## Memoria Cross-Session (Basic Memory)"
            echo "$cross_session_memory"
            echo ""
        fi

        echo "## Próximos Passos"
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
    cp "$output_file" "$passive_contract" 2>/dev/null || true

    return 0
}
