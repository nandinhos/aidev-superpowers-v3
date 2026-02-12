#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Fallback Generator Module
# ============================================================================
# Gera artefatos de fallback em Markdown puro para LLMs sem acesso a MCP
# Permite que Gemini CLI, Antigravity e outras LLMs sem MCP leiam o estado
#
# Artefatos gerados em .aidev/state/fallback/:
#   - last-checkpoint.md       Checkpoint legivel
#   - sprint-context.md        Sprint status formatado
#   - active-files.md          Arquivos em trabalho com snippets
#   - reconstruction-guide.md  Guia completo de retomada
#
# Uso: source lib/fallback-generator.sh
# Dependencias: lib/checkpoint-manager.sh
# ============================================================================

# ============================================================================
# CHECKPOINT TO MARKDOWN
# ============================================================================

# Converte um checkpoint JSON para Markdown legivel por qualquer LLM
# Uso: fallback_checkpoint_to_md <checkpoint_file>
# Retorna: Conteudo Markdown via stdout
fallback_checkpoint_to_md() {
    local ckpt_file="$1"

    if [ ! -f "$ckpt_file" ]; then
        echo "Erro: arquivo de checkpoint nao encontrado: $ckpt_file" >&2
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "Erro: jq necessario" >&2
        return 1
    fi

    local ckpt_id trigger desc created
    ckpt_id=$(jq -r '.checkpoint_id // "unknown"' "$ckpt_file")
    trigger=$(jq -r '.trigger // "unknown"' "$ckpt_file")
    desc=$(jq -r '.description // ""' "$ckpt_file")
    created=$(jq -r '.created_at // "unknown"' "$ckpt_file")

    # Sprint info
    local sprint_id sprint_name sprint_status current_task completed total
    sprint_id=$(jq -r '.sprint_snapshot.sprint_id // "none"' "$ckpt_file")
    sprint_name=$(jq -r '.sprint_snapshot.sprint_name // "N/A"' "$ckpt_file")
    sprint_status=$(jq -r '.sprint_snapshot.status // "unknown"' "$ckpt_file")
    current_task=$(jq -r '.sprint_snapshot.current_task // "none"' "$ckpt_file")
    completed=$(jq -r '.sprint_snapshot.overall_progress.completed // 0' "$ckpt_file")
    total=$(jq -r '.sprint_snapshot.overall_progress.total_tasks // 0' "$ckpt_file")

    # Cognitive context
    local cot hypothesis mental_model observations
    cot=$(jq -r '.cognitive_context.chain_of_thought // ""' "$ckpt_file")
    hypothesis=$(jq -r '.cognitive_context.current_hypothesis // ""' "$ckpt_file")
    mental_model=$(jq -r '.cognitive_context.mental_model // ""' "$ckpt_file")
    observations=$(jq -r '.cognitive_context.observations // ""' "$ckpt_file")

    # Project info
    local project
    project=$(jq -r '.state_snapshot.session.project_name // "unknown"' "$ckpt_file")

    cat << EOF
# Checkpoint: $ckpt_id

**Data**: $created
**Trigger**: $trigger
**Projeto**: $project

## Descricao
$desc

## Sprint
- **ID**: $sprint_id
- **Nome**: $sprint_name
- **Status**: $sprint_status
- **Task Atual**: $current_task
- **Progresso**: $completed/$total tasks
EOF

    if [ -n "$cot" ] || [ -n "$hypothesis" ] || [ -n "$mental_model" ]; then
        echo ""
        echo "## Contexto Cognitivo"
        [ -n "$cot" ] && echo "- **Raciocinio**: $cot"
        [ -n "$hypothesis" ] && echo "- **Hipotese**: $hypothesis"
        [ -n "$mental_model" ] && echo "- **Modelo Mental**: $mental_model"
        [ -n "$observations" ] && echo "- **Observacoes**: $observations"
    fi

    cat << EOF

---
*Gerado por AI Dev Superpowers - Fallback Artifact*
EOF
}

# ============================================================================
# SPRINT TO MARKDOWN
# ============================================================================

# Converte sprint-status.json para Markdown legivel
# Uso: fallback_sprint_to_md <install_path>
# Retorna: Conteudo Markdown via stdout
fallback_sprint_to_md() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file="$install_path/.aidev/state/sprints/current/sprint-status.json"

    if [ ! -f "$sprint_file" ]; then
        echo "Erro: sprint-status.json nao encontrado" >&2
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "Erro: jq necessario" >&2
        return 1
    fi

    local sprint_id sprint_name status description current_task
    local completed total in_progress pending blocked
    sprint_id=$(jq -r '.sprint_id // "unknown"' "$sprint_file")
    sprint_name=$(jq -r '.sprint_name // "N/A"' "$sprint_file")
    status=$(jq -r '.status // "unknown"' "$sprint_file")
    description=$(jq -r '.description // ""' "$sprint_file")
    current_task=$(jq -r '.current_task // "none"' "$sprint_file")
    completed=$(jq -r '.overall_progress.completed // 0' "$sprint_file")
    total=$(jq -r '.overall_progress.total_tasks // 0' "$sprint_file")
    in_progress=$(jq -r '.overall_progress.in_progress // 0' "$sprint_file")
    pending=$(jq -r '.overall_progress.pending // 0' "$sprint_file")
    blocked=$(jq -r '.overall_progress.blocked // 0' "$sprint_file")

    local progress_pct=0
    if [ "$total" -gt 0 ]; then
        progress_pct=$(( (completed * 100) / total ))
    fi

    cat << EOF
# Sprint: $sprint_name

**ID**: $sprint_id
**Status**: $status
**Descricao**: $description

## Progresso
- **Completadas**: $completed/$total ($progress_pct%)
- **Em Progresso**: $in_progress
- **Pendentes**: $pending
- **Bloqueadas**: $blocked
- **Task Atual**: $current_task

## Tasks
EOF

    # Lista tasks do JSON
    local task_count
    task_count=$(jq '.tasks | length' "$sprint_file" 2>/dev/null || echo 0)

    local i=0
    while [ "$i" -lt "$task_count" ]; do
        local task_id task_name task_status task_feature
        task_id=$(jq -r ".tasks[$i].task_id // \"\"" "$sprint_file")
        task_name=$(jq -r ".tasks[$i].name // \"\"" "$sprint_file")
        task_status=$(jq -r ".tasks[$i].status // \"pending\"" "$sprint_file")
        task_feature=$(jq -r ".tasks[$i].feature // \"\"" "$sprint_file")

        local status_icon="[ ]"
        case "$task_status" in
            completed) status_icon="[x]" ;;
            in_progress) status_icon="[~]" ;;
            blocked) status_icon="[!]" ;;
        esac

        echo "- $status_icon **$task_id** ($task_status) - $task_name [Feature $task_feature]"
        ((i++))
    done

    cat << EOF

---
*Gerado por AI Dev Superpowers - Fallback Artifact*
EOF
}

# ============================================================================
# ACTIVE FILES TO MARKDOWN
# ============================================================================

# Lista arquivos em trabalho baseado nas tasks ativas da sprint
# Uso: fallback_files_to_md <install_path>
# Retorna: Conteudo Markdown via stdout
fallback_files_to_md() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file="$install_path/.aidev/state/sprints/current/sprint-status.json"

    if [ ! -f "$sprint_file" ]; then
        echo "Erro: sprint-status.json nao encontrado" >&2
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "Erro: jq necessario" >&2
        return 1
    fi

    cat << 'EOF'
# Arquivos em Trabalho

Arquivos associados as tasks ativas da sprint atual.

EOF

    # Extrai arquivos das tasks in_progress e da task atual
    local task_count
    task_count=$(jq '.tasks | length' "$sprint_file" 2>/dev/null || echo 0)

    local i=0
    local files_found=0
    while [ "$i" -lt "$task_count" ]; do
        local task_id task_status task_file task_name
        task_id=$(jq -r ".tasks[$i].task_id // \"\"" "$sprint_file")
        task_status=$(jq -r ".tasks[$i].status // \"pending\"" "$sprint_file")
        task_file=$(jq -r ".tasks[$i].file // \"\"" "$sprint_file")
        task_name=$(jq -r ".tasks[$i].name // \"\"" "$sprint_file")

        if [ "$task_status" = "in_progress" ] || [ "$task_status" = "completed" ]; then
            if [ -n "$task_file" ]; then
                local full_path="$install_path/$task_file"
                echo "## $task_file"
                echo "- **Task**: $task_id"
                echo "- **Status**: $task_status"
                echo "- **Descricao**: $task_name"

                if [ -f "$full_path" ]; then
                    local line_count
                    line_count=$(wc -l < "$full_path" 2>/dev/null || echo 0)
                    echo "- **Linhas**: $line_count"
                    echo ""
                    echo '```bash'
                    head -20 "$full_path" 2>/dev/null
                    if [ "$line_count" -gt 20 ]; then
                        echo "# ... ($line_count linhas total)"
                    fi
                    echo '```'
                else
                    echo "- **Arquivo**: nao encontrado no filesystem"
                fi
                echo ""
                ((files_found++))
            fi
        fi
        ((i++))
    done

    if [ "$files_found" -eq 0 ]; then
        echo "Nenhum arquivo em trabalho ativo."
    fi

    cat << 'EOF'
---
*Gerado por AI Dev Superpowers - Fallback Artifact*
EOF
}

# ============================================================================
# RECONSTRUCTION GUIDE TO MARKDOWN
# ============================================================================

# Gera um guia completo de retomada para qualquer LLM
# Uso: fallback_guide_to_md <install_path> <checkpoint_file>
# Retorna: Conteudo Markdown via stdout
fallback_guide_to_md() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local ckpt_file="$2"
    local sprint_file="$install_path/.aidev/state/sprints/current/sprint-status.json"

    if ! command -v jq >/dev/null 2>&1; then
        echo "Erro: jq necessario" >&2
        return 1
    fi

    # Sprint info
    local sprint_name current_task sprint_status
    if [ -f "$sprint_file" ]; then
        sprint_name=$(jq -r '.sprint_name // "N/A"' "$sprint_file")
        current_task=$(jq -r '.current_task // "none"' "$sprint_file")
        sprint_status=$(jq -r '.status // "unknown"' "$sprint_file")
    else
        sprint_name="N/A"
        current_task="none"
        sprint_status="unknown"
    fi

    # Checkpoint info
    local ckpt_id desc cot hypothesis mental_model
    if [ -n "$ckpt_file" ] && [ -f "$ckpt_file" ]; then
        ckpt_id=$(jq -r '.checkpoint_id // "none"' "$ckpt_file")
        desc=$(jq -r '.description // ""' "$ckpt_file")
        cot=$(jq -r '.cognitive_context.chain_of_thought // ""' "$ckpt_file")
        hypothesis=$(jq -r '.cognitive_context.current_hypothesis // ""' "$ckpt_file")
        mental_model=$(jq -r '.cognitive_context.mental_model // ""' "$ckpt_file")
    else
        ckpt_id="none"
        desc=""
        cot=""
        hypothesis=""
        mental_model=""
    fi

    cat << EOF
# Guia de Retomada - AI Dev Superpowers

Este guia foi gerado automaticamente para permitir que qualquer LLM
(com ou sem acesso a MCP) retome o trabalho de onde a sessao anterior parou.

## Estado Atual

- **Sprint**: $sprint_name
- **Status da sprint**: $sprint_status
- **Task em execucao**: $current_task
- **Checkpoint**: $ckpt_id

## Instrucoes de Retomada

1. Leia este guia completo antes de agir
2. Consulte os arquivos de fallback em \`.aidev/state/fallback/\`:
   - \`last-checkpoint.md\` - Estado do ultimo checkpoint
   - \`sprint-context.md\` - Contexto completo da sprint
   - \`active-files.md\` - Arquivos em trabalho
3. Retome a task ativa: **$current_task**
EOF

    if [ -n "$desc" ]; then
        echo ""
        echo "## Ultimo Checkpoint"
        echo "$desc"
    fi

    if [ -n "$cot" ] || [ -n "$hypothesis" ] || [ -n "$mental_model" ]; then
        echo ""
        echo "## Modelo Mental da Sessao Anterior"
        [ -n "$cot" ] && echo "- **Raciocinio**: $cot"
        [ -n "$hypothesis" ] && echo "- **Hipotese**: $hypothesis"
        [ -n "$mental_model" ] && echo "- **Modelo**: $mental_model"
    fi

    cat << 'EOF'

## Arquivos de Referencia

| Arquivo | Conteudo |
|---------|----------|
| `.aidev/state/fallback/last-checkpoint.md` | Checkpoint mais recente |
| `.aidev/state/fallback/sprint-context.md` | Contexto da sprint |
| `.aidev/state/fallback/active-files.md` | Arquivos em trabalho |
| `.aidev/state/fallback/reconstruction-guide.md` | Este guia |
| `.aidev/state/sprints/current/sprint-status.json` | Estado da sprint (JSON) |
| `.aidev/state/unified.json` | Estado unificado (JSON) |

---
*Gerado por AI Dev Superpowers - Fallback Artifact*
EOF
}

# ============================================================================
# GENERATE ALL FALLBACK ARTIFACTS
# ============================================================================

# Gera todos os artefatos de fallback de uma vez
# Uso: fallback_generate_all <install_path> <checkpoint_file>
# Cria 4 arquivos em .aidev/state/fallback/
fallback_generate_all() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local ckpt_file="$2"
    local fallback_dir="$install_path/.aidev/state/fallback"

    mkdir -p "$fallback_dir"

    local count=0

    # 1. Checkpoint
    if [ -n "$ckpt_file" ] && [ -f "$ckpt_file" ]; then
        if fallback_checkpoint_to_md "$ckpt_file" > "$fallback_dir/last-checkpoint.md" 2>/dev/null; then
            ((count++)) || true
        fi
    else
        printf "# Checkpoint\n\nNenhum checkpoint disponivel.\n" > "$fallback_dir/last-checkpoint.md"
        ((count++)) || true
    fi

    # 2. Sprint context
    if fallback_sprint_to_md "$install_path" > "$fallback_dir/sprint-context.md" 2>/dev/null; then
        ((count++)) || true
    fi

    # 3. Active files
    if fallback_files_to_md "$install_path" > "$fallback_dir/active-files.md" 2>/dev/null; then
        ((count++)) || true
    fi

    # 4. Reconstruction guide
    if fallback_guide_to_md "$install_path" "$ckpt_file" > "$fallback_dir/reconstruction-guide.md" 2>/dev/null; then
        ((count++)) || true
    fi

    echo "Artefatos de fallback gerados: $count/4 em $fallback_dir"
}
