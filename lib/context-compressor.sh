#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Context Compressor Module
# ============================================================================
# Gera resumos de contexto de ultra-baixa latência para ativação de LLMs
# ============================================================================

# Gera um markdown compacto com o estado atual
# Uso: context_compressor_generate [output_file]
context_compressor_generate() {
    local output_file="${1:-.aidev/.cache/activation_context.md}"
    local unified_file=".aidev/state/unified.json"
    
    mkdir -p "$(dirname "$output_file")"
    
    if [ ! -f "$unified_file" ]; then
        echo "⚠️ Estado não encontrado." > "$output_file"
        return 1
    fi
    
    # Limpa/Cria o arquivo
    : > "$output_file"
    
    # Carrega dados essenciais via jq (resiliente a falhas)
    local sprint_name=$(jq -r '.sprint_context.sprint_name // "Nenhuma"' "$unified_file")
    local sprint_pct=$(jq -r '.sprint_context.progress_percentage // 0' "$unified_file")
    local task_id=$(jq -r '.sprint_context.current_task_id // "Nenhuma"' "$unified_file")
    local version=$(jq -r '.version // "unknown"' "$unified_file")
    
    # Tenta obter descrição da task se disponível
    local task_desc="-"
    if [ "$task_id" != "Nenhuma" ] && [ "$task_id" != "null" ]; then
        # Tenta ler do sprint-status se unified não tiver detalhe
        local sprint_status=".aidev/state/sprints/current/sprint-status.json"
        if [ -f "$sprint_status" ]; then
            task_desc=$(jq -r --arg tid "$task_id" '.tasks[] | select(.task_id == $tid) | .name' "$sprint_status" | head -n 1)
        fi
    fi
    
    # Header
    echo "# 🚀 AI Dev v$version" >> "$output_file"


# Se detectado Antigravity ou MCP, adiciona instrução de leitura de memória
if [ -n "$ANTIGRAVITY_AGENT" ]; then
    echo "> 💡 **DICA**: Vejo que você é o Antigravity. Use `read_memory` e `build_context` para ler as memórias do projeto (`project_overview`, `kb_system`) e economizar tokens." >> "$output_file"
fi
    
    # Estado da Sprint
    echo "## 📊 Sprint Atual" >> "$output_file"
    echo "- **Nome**: $sprint_name" >> "$output_file"
    echo "- **Progresso**: ${sprint_pct}%" >> "$output_file"
    
    if [ "$task_id" != "Nenhuma" ] && [ "$task_id" != "null" ]; then
        echo "- **Task Ativa**: \`$task_id\`" >> "$output_file"
        echo "  - *$task_desc*" >> "$output_file"
    else
        echo "- **Task Ativa**: Nenhuma (Aguardando planejamento)" >> "$output_file"
    fi
    
    # Última Ação (Context Git)
    if command -v ctxgit_get_recent >/dev/null; then
        local last_log=$(ctxgit_get_recent 1)
        if [ -n "$last_log" ] && [ "$last_log" != "[]" ] && [ "$last_log" != "null" ]; then
            local action=$(echo "$last_log" | jq -r '.[0].action // "unknown"')
            local intent=$(echo "$last_log" | jq -r '.[0].intent // "no intent"')
            echo "## 🕒 Última Atividade" >> "$output_file"
            echo "- **$action**: $intent" >> "$output_file"
        fi
    fi
    
    # Instruções Críticas (Links)
    echo "## 🧠 Memória & Regras" >> "$output_file"
    echo "- **Regras**: Leia \`.aidev/rules/generic.md\` se tiver dúvidas." >> "$output_file"
    echo "- **Agentes**: Use \`aidev status\` para ver agentes disponíveis." >> "$output_file"
    
    return 0
}
