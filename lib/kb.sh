#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Knowledge Base Manager
# ============================================================================
# Sistema automatizado de catalogacao de erros/resolucoes e consulta pre-planejamento.
# Integra com Serena memories e Basic Memory MCP para persistencia cross-session.
#
# Uso: source lib/kb.sh
# Dependencias: lib/core.sh, lib/memory.sh, lib/state.sh
# ============================================================================

# ============================================================================
# CONFIGURACAO
# ============================================================================

KB_LOCAL_DIR="${CLI_INSTALL_PATH:-.}/.aidev/memory/kb"
KB_INDEX_FILE="${KB_LOCAL_DIR}/index.json"
KB_FAILURES_LOG="${CLI_INSTALL_PATH:-.}/.aidev/state/kb_failures.log"

# ============================================================================
# INICIALIZACAO
# ============================================================================

# Inicializa estrutura da Knowledge Base
# Uso: kb_init
kb_init() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    KB_LOCAL_DIR="$install_path/.aidev/memory/kb"
    KB_INDEX_FILE="${KB_LOCAL_DIR}/index.json"
    KB_FAILURES_LOG="$install_path/.aidev/state/kb_failures.log"

    ensure_dir "$KB_LOCAL_DIR"
    ensure_dir "$(dirname "$KB_FAILURES_LOG")"

    # Cria indice se nao existir
    if [ ! -f "$KB_INDEX_FILE" ]; then
        cat > "$KB_INDEX_FILE" << 'EOF'
{
  "lessons": [],
  "last_indexed": null,
  "stats": {
    "total": 0,
    "by_category": {},
    "by_skill": {}
  }
}
EOF
        print_debug "Indice da KB inicializado: $KB_INDEX_FILE"
    fi
}

# ============================================================================
# CATALOGACAO AUTOMATICA
# ============================================================================

# Cataloga uma resolucao de erro (chamada automaticamente via hook)
# Uso: kb_catalog_resolution "systematic-debugging" "$context_json"
kb_catalog_resolution() {
    local skill_name="$1"
    local context_json="${2:-}"

    kb_init

    local install_path="${CLI_INSTALL_PATH:-.}"
    local skills_file="$install_path/.aidev/state/skills.json"

    # Extrai dados do estado da skill
    local exception=""
    local symptoms=""
    local root_cause=""
    local correction=""
    local checkpoints_json="[]"
    local artifacts_json="[]"

    if command -v jq >/dev/null 2>&1 && [ -f "$skills_file" ]; then
        # Extrai checkpoints e artifacts da skill
        checkpoints_json=$(jq -r --arg skill "$skill_name" '.skill_states[$skill].checkpoints // []' "$skills_file" 2>/dev/null || echo "[]")
        artifacts_json=$(jq -r --arg skill "$skill_name" '.skill_states[$skill].artifacts // []' "$skills_file" 2>/dev/null || echo "[]")

        # Tenta extrair informacoes estruturadas do contexto JSON se fornecido
        if [ -n "$context_json" ] && [ "$context_json" != "{}" ]; then
            exception=$(echo "$context_json" | jq -r '.exception // .error // .failure_reason // empty' 2>/dev/null || echo "")
            symptoms=$(echo "$context_json" | jq -r '.symptoms // empty' 2>/dev/null || echo "")
            root_cause=$(echo "$context_json" | jq -r '.root_cause // empty' 2>/dev/null || echo "")
            correction=$(echo "$context_json" | jq -r '.correction // .solution // empty' 2>/dev/null || echo "")
        fi

        # Se nao tem exception, tenta extrair do ultimo checkpoint
        if [ -z "$exception" ]; then
            exception=$(echo "$checkpoints_json" | jq -r '.[0].description // "Problema resolvido via skill"' 2>/dev/null || echo "Problema resolvido")
        fi

        # Formata sintomas a partir dos checkpoints
        if [ -z "$symptoms" ]; then
            symptoms=$(echo "$checkpoints_json" | jq -r '[.[] | .description] | join("\n- ")' 2>/dev/null || echo "")
            [ -n "$symptoms" ] && symptoms="- $symptoms"
        fi
    fi

    # Gera ID unico para a licao
    local lesson_id="KB-$(date +%Y-%m-%d)-$(printf '%03d' $((RANDOM % 1000)))"
    local timestamp=$(date -Iseconds)

    # Gera slug a partir da exception
    local slug
    slug=$(echo "$exception" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | head -c 50 | sed 's/-$//')
    [ -z "$slug" ] && slug="lesson-$(date +%H%M%S)"

    local filename="$(date +%Y-%m-%d)-${slug}.md"
    local filepath="$KB_LOCAL_DIR/$filename"

    # Evita duplicatas (mesmo arquivo no mesmo dia)
    if [ -f "$filepath" ]; then
        filepath="$KB_LOCAL_DIR/$(date +%Y-%m-%d)-${slug}-$(date +%H%M%S).md"
    fi

    # Formata e salva a licao
    kb_format_lesson "$lesson_id" "$exception" "$symptoms" "$root_cause" "$correction" "$skill_name" "$checkpoints_json" "$artifacts_json" > "$filepath"

    # Atualiza indice
    _kb_update_index "$filepath" "$lesson_id" "$exception" "$skill_name"

    # Sincroniza com MCPs em background (nao bloqueia)
    if [ "${BASIC_MEMORY_ENABLED:-false}" = "true" ]; then
        kb_sync_to_basic_memory "$filepath" &
    fi
    kb_sync_to_serena "$filepath" &

    print_success "Licao catalogada automaticamente: $filepath"
    echo "$filepath"
}

# Formata licao no padrao estruturado
# Uso: kb_format_lesson "id" "exception" "symptoms" "root_cause" "correction" "skill" "checkpoints" "artifacts"
kb_format_lesson() {
    local id="$1"
    local exception="$2"
    local symptoms="$3"
    local root_cause="$4"
    local correction="$5"
    local skill_context="$6"
    local checkpoints_json="${7:-[]}"
    local artifacts_json="${8:-[]}"

    local timestamp=$(date -Iseconds)
    local date_human=$(date '+%Y-%m-%d %H:%M')
    local stack=$(detect_stack "${CLI_INSTALL_PATH:-.}" 2>/dev/null || echo "generic")

    # Determina categoria baseada no skill
    local category="bug"
    case "$skill_context" in
        "systematic-debugging") category="bug" ;;
        "learned-lesson") category="lesson" ;;
        *) category="general" ;;
    esac

    cat << EOF
---
id: $id
type: learned-lesson
category: $category
exception: "$exception"
stack: $stack
tags: [$stack, $category, $skill_context]
resolved_at: $timestamp
skill_context: $skill_context
---

# Licao: ${exception:-Resolucao de Problema}

**Data**: $date_human
**Stack**: $stack
**Skill**: $skill_context
**ID**: $id

## Sintomas

${symptoms:-Nenhum sintoma especifico documentado.}

## Causa Raiz

${root_cause:-Causa raiz a ser documentada.}

## Correcao

\`\`\`
${correction:-Correcao aplicada durante o debugging.}
\`\`\`

## Checkpoints da Resolucao

$(echo "$checkpoints_json" | jq -r '.[] | "- [\(.timestamp // "N/A")] \(.description // "Checkpoint")"' 2>/dev/null || echo "- Nenhum checkpoint registrado")

## Artefatos Produzidos

$(echo "$artifacts_json" | jq -r '.[] | "- \(.path) (\(.type // "documento"))"' 2>/dev/null || echo "- Nenhum artefato registrado")

## Prevencao

- [ ] Adicionar validacao para evitar este caso
- [ ] Criar teste de regressao
- [ ] Documentar no README se relevante
- [ ] Revisar codigo similar no projeto
EOF
}

# ============================================================================
# BUSCA E CONSULTA
# ============================================================================

# Consulta KB antes de codificar (OBRIGATORIA antes de planejamento)
# Uso: result=$(kb_consult_before_coding "implementar autenticacao JWT")
kb_consult_before_coding() {
    local task_description="$1"

    if [ -z "$task_description" ]; then
        print_warning "Descricao da tarefa obrigatoria para consulta KB"
        return 1
    fi

    kb_init

    print_section "Consultando Knowledge Base"
    print_info "Tarefa: $task_description"
    echo ""

    local found_count=0

    # 1. Busca local
    print_step "Buscando licoes locais..."
    local local_results
    local_results=$(_kb_search_local "$task_description" 3)

    if [ -n "$local_results" ]; then
        print_success "Licoes encontradas na KB local:"
        echo "$local_results"
        found_count=$((found_count + 1))
    fi

    # 2. Instrucoes para busca em MCPs (executadas pelo agente LLM)
    if [ "${BASIC_MEMORY_ENABLED:-false}" = "true" ]; then
        echo ""
        print_step "Para buscar em Basic Memory, execute:"
        echo "  mcp__basic-memory__search_notes query=\"$task_description\""
    fi

    echo ""
    print_step "Para buscar em Serena memories, execute:"
    echo "  mcp__serena__list_memories"
    echo "  # Procure por memorias com prefixo 'kb_'"

    # 3. Retorna resultado
    echo ""
    if [ "$found_count" -gt 0 ]; then
        print_success "Consulta concluida. Verifique licoes relevantes antes de codificar."
        return 0
    else
        print_info "Nenhuma licao local encontrada. Prossiga com fluxo normal."
        print_info "Se resolver um novo problema, sera catalogado automaticamente."
        return 1
    fi
}

# Busca semantica unificada na KB
# Uso: kb_search "null pointer" 5
kb_search() {
    local query="$1"
    local max_results="${2:-5}"

    if [ -z "$query" ]; then
        print_error "Query de busca obrigatoria"
        return 1
    fi

    kb_init

    _kb_search_local "$query" "$max_results"
}

# Busca local em arquivos da KB
_kb_search_local() {
    local query="$1"
    local max_results="${2:-5}"
    local found=0

    if [ ! -d "$KB_LOCAL_DIR" ]; then
        return 0
    fi

    # Extrai keywords da query
    local keywords
    keywords=$(echo "$query" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' ' ')

    while IFS= read -r file; do
        if [ "$found" -ge "$max_results" ]; then
            break
        fi

        # Verifica se alguma keyword esta no arquivo
        local matched=false
        for keyword in $keywords; do
            if [ ${#keyword} -gt 2 ] && grep -l -i "$keyword" "$file" >/dev/null 2>&1; then
                matched=true
                break
            fi
        done

        if [ "$matched" = true ]; then
            # Extrai metadados do frontmatter
            local id=$(grep "^id:" "$file" 2>/dev/null | head -1 | sed 's/id: *//')
            local exception=$(grep "^exception:" "$file" 2>/dev/null | head -1 | sed 's/exception: *//' | tr -d '"')
            local category=$(grep "^category:" "$file" 2>/dev/null | head -1 | sed 's/category: *//')
            local resolved=$(grep "^resolved_at:" "$file" 2>/dev/null | head -1 | sed 's/resolved_at: *//' | cut -d'T' -f1)

            echo "---"
            echo "  ID: ${id:-N/A}"
            echo "  Excecao: ${exception:-N/A}"
            echo "  Categoria: ${category:-N/A}"
            echo "  Resolvido: ${resolved:-N/A}"
            echo "  Arquivo: $(basename "$file")"
            echo ""

            ((found++)) || true
        fi
    done < <(find "$KB_LOCAL_DIR" -name "*.md" -type f 2>/dev/null | head -20)

    return 0
}

# Lista licoes recentes da KB
# Uso: kb_list_recent 10
kb_list_recent() {
    local limit="${1:-10}"

    kb_init

    if [ ! -d "$KB_LOCAL_DIR" ]; then
        print_warning "Knowledge Base vazia"
        return 0
    fi

    print_section "Licoes Recentes na KB"
    echo ""

    local count=0
    while IFS= read -r file; do
        if [ "$count" -ge "$limit" ]; then
            break
        fi

        local title=$(head -n 20 "$file" | grep "^# " | head -1 | sed 's/^# //')
        local date=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)

        printf "  %s  %s\n" "$date" "${title:-$(basename "$file")}"

        ((count++)) || true
    done < <(find "$KB_LOCAL_DIR" -name "*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f2-)

    echo ""
    print_info "Total: $count licoes"
}

# ============================================================================
# SINCRONIZACAO COM MCPs
# ============================================================================

# Sincroniza licao com Basic Memory MCP
# Uso: kb_sync_to_basic_memory "/path/to/lesson.md"
kb_sync_to_basic_memory() {
    local filepath="$1"

    if [ ! -f "$filepath" ]; then
        return 1
    fi

    local title=$(head -n 20 "$filepath" | grep "^# " | head -1 | sed 's/^# //')
    local filename=$(basename "$filepath" .md)

    # Instrucao para o agente LLM sincronizar
    print_debug "Para sincronizar '$title' com Basic Memory:"
    print_debug "  mcp__basic-memory__write_note title=\"$title\" content=\"...\" directory=\"kb\""
}

# Sincroniza licao com Serena memories
# Uso: kb_sync_to_serena "/path/to/lesson.md"
kb_sync_to_serena() {
    local filepath="$1"

    if [ ! -f "$filepath" ]; then
        return 1
    fi

    local filename=$(basename "$filepath" .md)
    local memory_name="kb_${filename}"

    # Instrucao para o agente LLM sincronizar
    print_debug "Para sincronizar com Serena:"
    print_debug "  mcp__serena__write_memory memory_file_name=\"$memory_name\" content=\"...\""
}

# ============================================================================
# HOOKS INTERNOS (chamados por orchestration.sh)
# ============================================================================

# Hook chamado automaticamente quando skill de resolucao completa
# Uso: _kb_on_resolution_complete "systematic-debugging"
_kb_on_resolution_complete() {
    local skill_name="$1"

    print_debug "KB Hook: Skill '$skill_name' completou - iniciando catalogacao automatica"

    # Coleta contexto do estado da skill
    local context="{}"
    local install_path="${CLI_INSTALL_PATH:-.}"
    local skills_file="$install_path/.aidev/state/skills.json"

    if command -v jq >/dev/null 2>&1 && [ -f "$skills_file" ]; then
        context=$(jq --arg skill "$skill_name" '.skill_states[$skill] // {}' "$skills_file" 2>/dev/null || echo "{}")
    fi

    # Cataloga a resolucao
    kb_catalog_resolution "$skill_name" "$context"
}

# Hook chamado quando skill falha (registra para correlacao futura)
# Uso: _kb_on_failure "brainstorming" "Motivo da falha"
_kb_on_failure() {
    local skill_name="$1"
    local reason="$2"

    kb_init

    local timestamp=$(date -Iseconds)

    # Registra falha em log para correlacao
    echo "$timestamp|$skill_name|$reason" >> "$KB_FAILURES_LOG"

    print_debug "KB: Falha registrada para correlacao futura: $skill_name - $reason"
}

# ============================================================================
# INDICE E ESTATISTICAS
# ============================================================================

# Atualiza indice da KB
_kb_update_index() {
    local filepath="$1"
    local lesson_id="$2"
    local exception="$3"
    local skill_context="$4"

    if command -v jq >/dev/null 2>&1 && [ -f "$KB_INDEX_FILE" ]; then
        local tmp_file=$(mktemp)
        local timestamp=$(date -Iseconds)
        local category="bug"

        case "$skill_context" in
            "systematic-debugging") category="bug" ;;
            "learned-lesson") category="lesson" ;;
            *) category="general" ;;
        esac

        jq --arg file "$(basename "$filepath")" \
           --arg id "$lesson_id" \
           --arg exc "$exception" \
           --arg ctx "$skill_context" \
           --arg cat "$category" \
           --arg ts "$timestamp" \
           '.lessons += [{
               "id": $id,
               "file": $file,
               "exception": $exc,
               "skill": $ctx,
               "category": $cat,
               "indexed_at": $ts
           }] |
           .last_indexed = $ts |
           .stats.total += 1 |
           .stats.by_category[$cat] = ((.stats.by_category[$cat] // 0) + 1) |
           .stats.by_skill[$ctx] = ((.stats.by_skill[$ctx] // 0) + 1)' \
           "$KB_INDEX_FILE" > "$tmp_file" && mv "$tmp_file" "$KB_INDEX_FILE"

        print_debug "Indice KB atualizado: $lesson_id"
    fi
}

# Mostra estatisticas da KB
# Uso: kb_stats
kb_stats() {
    kb_init

    print_section "Estatisticas da Knowledge Base"

    if command -v jq >/dev/null 2>&1 && [ -f "$KB_INDEX_FILE" ]; then
        local total=$(jq -r '.stats.total // 0' "$KB_INDEX_FILE")
        local last=$(jq -r '.last_indexed // "Nunca"' "$KB_INDEX_FILE")

        echo "  Total de licoes:     $total"
        echo "  Ultima indexacao:    $last"
        echo "  Diretorio:           $KB_LOCAL_DIR"
        echo ""

        echo "  Por categoria:"
        jq -r '.stats.by_category | to_entries[] | "    - \(.key): \(.value)"' "$KB_INDEX_FILE" 2>/dev/null || echo "    Nenhuma"
        echo ""

        echo "  Por skill:"
        jq -r '.stats.by_skill | to_entries[] | "    - \(.key): \(.value)"' "$KB_INDEX_FILE" 2>/dev/null || echo "    Nenhuma"
    else
        local count=$(find "$KB_LOCAL_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
        echo "  Total de arquivos:   $count"
        echo "  Diretorio:           $KB_LOCAL_DIR"
    fi

    echo ""
}

# ============================================================================
# EXPORTACAO
# ============================================================================

# Exporta KB para formato consolidado
# Uso: kb_export > kb-export.json
kb_export() {
    kb_init

    if command -v jq >/dev/null 2>&1; then
        echo "{"
        echo "  \"exported_at\": \"$(date -Iseconds)\","
        echo "  \"index\": $(cat "$KB_INDEX_FILE"),"
        echo "  \"lessons\": ["

        local first=true
        while IFS= read -r file; do
            if [ "$first" = false ]; then
                echo ","
            fi
            first=false

            local content=$(cat "$file" | jq -Rs '.')
            echo "    {\"file\": \"$(basename "$file")\", \"content\": $content}"
        done < <(find "$KB_LOCAL_DIR" -name "*.md" -type f 2>/dev/null)

        echo ""
        echo "  ]"
        echo "}"
    fi
}
