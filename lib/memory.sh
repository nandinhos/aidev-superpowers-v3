#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3.2 - Memory Integration Module
# ============================================================================
# Integracao com basic-memory MCP para consulta de licoes aprendidas
# e sugestoes baseadas em historico.
#
# Uso: source lib/memory.sh
# Dependencias: lib/core.sh
# MCP Server: basic-memory (opcional, funciona em modo degradado sem ele)
# ============================================================================

# ============================================================================
# CONFIGURACAO
# ============================================================================

# Diretorio de memorias local (fallback quando MCP nao disponivel)
MEMORY_LOCAL_DIR="${MEMORY_LOCAL_DIR:-${CLI_INSTALL_PATH:-.}/.aidev/memories}"

# Projeto do basic-memory (se configurado)
MEMORY_PROJECT="${MEMORY_PROJECT:-}"

# Timeout para operacoes de memoria (ms)
MEMORY_TIMEOUT="${MEMORY_TIMEOUT:-5000}"

# ============================================================================
# VERIFICACAO DE DISPONIBILIDADE
# ============================================================================

# Verifica se basic-memory MCP esta disponivel
# Uso: if memory_mcp_available; then ...; fi
memory_mcp_available() {
    # Verifica se estamos em ambiente com MCP (Claude Code, etc)
    # Nao ha forma direta de verificar, entao assumimos disponivel
    # se BASIC_MEMORY_ENABLED estiver setado
    [ "${BASIC_MEMORY_ENABLED:-false}" = "true" ]
}

# Inicializa sistema de memoria local
# Uso: memory_init
memory_init() {
    local install_path="${CLI_INSTALL_PATH:-.}"

    # Cria diretorio de memorias se nao existir
    if [ ! -d "$MEMORY_LOCAL_DIR" ]; then
        mkdir -p "$MEMORY_LOCAL_DIR"
        print_debug "Diretorio de memorias criado: $MEMORY_LOCAL_DIR"
    fi

    # Cria indice se nao existir
    local index_file="$MEMORY_LOCAL_DIR/index.json"
    if [ ! -f "$index_file" ]; then
        echo '{"memories": [], "last_updated": null}' > "$index_file"
    fi

    print_debug "Sistema de memoria inicializado"
}

# ============================================================================
# BUSCA DE MEMORIAS
# ============================================================================

# Busca em licoes passadas
# Uso: memory_search "erro de autenticacao"
memory_search() {
    local query="$1"
    local max_results="${2:-5}"

    if [ -z "$query" ]; then
        print_error "Query de busca obrigatoria"
        return 1
    fi

    print_debug "Buscando memorias: $query"

    # Tenta busca via MCP primeiro
    if memory_mcp_available; then
        _memory_search_mcp "$query" "$max_results"
        return $?
    fi

    # Fallback: busca local
    _memory_search_local "$query" "$max_results"
}

# Busca via MCP basic-memory
_memory_search_mcp() {
    local query="$1"
    local max_results="$2"

    # Esta funcao e um placeholder - a integracao real acontece
    # quando o agente usa as ferramentas MCP diretamente
    print_info "Para buscar com basic-memory MCP, use:"
    echo "  mcp__basic-memory__search_notes query=\"$query\""
    return 0
}

# Busca local em arquivos de memoria
_memory_search_local() {
    local query="$1"
    local max_results="$2"
    local found=0

    if [ ! -d "$MEMORY_LOCAL_DIR" ]; then
        print_warning "Nenhuma memoria local encontrada"
        return 0
    fi

    print_info "Resultados da busca local:"
    echo ""

    # Busca em arquivos .md dentro do diretorio de memorias
    while IFS= read -r file; do
        if [ "$found" -ge "$max_results" ]; then
            break
        fi

        if grep -l -i "$query" "$file" >/dev/null 2>&1; then
            local title
            title=$(head -n 1 "$file" | sed 's/^#\+ *//')
            local match
            match=$(grep -i -m 1 "$query" "$file" | head -c 100)

            echo "  - $title"
            echo "    $(basename "$file")"
            echo "    ...${match}..."
            echo ""

            ((found++)) || true
        fi
    done < <(find "$MEMORY_LOCAL_DIR" -name "*.md" -type f 2>/dev/null)

    if [ "$found" -eq 0 ]; then
        print_info "Nenhuma memoria encontrada para: $query"
    else
        print_success "Encontradas $found memorias"
    fi

    return 0
}

# ============================================================================
# CASOS SIMILARES
# ============================================================================

# Encontra casos similares baseado em contexto
# Uso: memory_get_similar "implementando autenticacao JWT"
memory_get_similar() {
    local context="$1"
    local similarity_threshold="${2:-0.5}"

    if [ -z "$context" ]; then
        print_error "Contexto obrigatorio"
        return 1
    fi

    print_debug "Buscando casos similares: $context"

    # Extrai keywords do contexto
    local keywords
    keywords=$(_memory_extract_keywords "$context")

    # Busca por cada keyword
    local results=""
    for keyword in $keywords; do
        local search_result
        search_result=$(_memory_search_local "$keyword" 3 2>/dev/null)
        if [ -n "$search_result" ]; then
            results="${results}${search_result}\n"
        fi
    done

    if [ -n "$results" ]; then
        print_info "Casos similares encontrados:"
        echo -e "$results"
    else
        print_info "Nenhum caso similar encontrado"
    fi

    return 0
}

# Extrai keywords relevantes de um contexto
_memory_extract_keywords() {
    local context="$1"

    # Remove palavras comuns (stopwords basicas)
    local stopwords="a o e de da do em para com que um uma os as no na"

    # Converte para lowercase e extrai palavras
    local words
    words=$(echo "$context" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alpha:]' '\n' | sort -u)

    # Filtra stopwords e palavras muito curtas
    for word in $words; do
        if [ ${#word} -gt 3 ]; then
            local is_stopword=false
            for stop in $stopwords; do
                if [ "$word" = "$stop" ]; then
                    is_stopword=true
                    break
                fi
            done
            if [ "$is_stopword" = false ]; then
                echo "$word"
            fi
        fi
    done
}

# ============================================================================
# SUGESTOES BASEADAS EM HISTORICO
# ============================================================================

# Sugere acoes baseado em tarefa e historico
# Uso: memory_suggest "debug de memory leak"
memory_suggest() {
    local task="$1"

    if [ -z "$task" ]; then
        print_error "Descricao da tarefa obrigatoria"
        return 1
    fi

    print_info "Buscando sugestoes para: $task"
    echo ""

    # Categoriza a tarefa
    local task_type
    task_type=$(_memory_classify_task "$task")

    # Busca memorias relacionadas
    local related
    related=$(_memory_search_local "$task" 3 2>/dev/null)

    # Gera sugestoes baseadas no tipo de tarefa
    case "$task_type" in
        "debug")
            _memory_suggest_debug "$task"
            ;;
        "feature")
            _memory_suggest_feature "$task"
            ;;
        "refactor")
            _memory_suggest_refactor "$task"
            ;;
        "test")
            _memory_suggest_test "$task"
            ;;
        *)
            _memory_suggest_generic "$task"
            ;;
    esac

    # Mostra memorias relacionadas se encontradas
    if [ -n "$related" ]; then
        echo ""
        print_info "Memorias relacionadas:"
        echo -e "$related"
    fi

    return 0
}

# Classifica tipo de tarefa
_memory_classify_task() {
    local task="$1"
    local task_lower
    task_lower=$(echo "$task" | tr '[:upper:]' '[:lower:]')

    if echo "$task_lower" | grep -qE "bug|erro|fix|debug|crash|fail"; then
        echo "debug"
    elif echo "$task_lower" | grep -qE "feature|implementar|criar|adicionar|novo"; then
        echo "feature"
    elif echo "$task_lower" | grep -qE "refactor|limpar|organizar|melhorar|otimizar"; then
        echo "refactor"
    elif echo "$task_lower" | grep -qE "test|testar|cobertura|tdd"; then
        echo "test"
    else
        echo "generic"
    fi
}

# Sugestoes especificas para debug
_memory_suggest_debug() {
    local task="$1"

    print_info "Sugestoes para debugging:"
    echo "  1. Reproduza o erro de forma consistente"
    echo "  2. Colete logs e stack traces"
    echo "  3. Isole o componente com problema"
    echo "  4. Use a skill 'systematic-debugging'"
    echo "  5. Documente a solucao como learned-lesson"
}

# Sugestoes especificas para feature
_memory_suggest_feature() {
    local task="$1"

    print_info "Sugestoes para nova feature:"
    echo "  1. Documente requisitos no PRD"
    echo "  2. Crie design antes de codar"
    echo "  3. Use skill 'brainstorming' para explorar"
    echo "  4. Escreva testes antes (TDD)"
    echo "  5. Faca code review antes de merge"
}

# Sugestoes especificas para refactor
_memory_suggest_refactor() {
    local task="$1"

    print_info "Sugestoes para refatoracao:"
    echo "  1. Garanta testes cobrindo codigo atual"
    echo "  2. Faca mudancas incrementais"
    echo "  3. Mantenha funcionalidade intacta"
    echo "  4. Use metricas de qualidade"
    echo "  5. Documente decisoes arquiteturais"
}

# Sugestoes especificas para testes
_memory_suggest_test() {
    local task="$1"

    print_info "Sugestoes para testes:"
    echo "  1. Cubra casos de borda"
    echo "  2. Use mocks para dependencias externas"
    echo "  3. Mantenha testes isolados"
    echo "  4. Prefira TDD para codigo novo"
    echo "  5. Monitore cobertura de codigo"
}

# Sugestoes genericas
_memory_suggest_generic() {
    local task="$1"

    print_info "Sugestoes gerais:"
    echo "  1. Entenda o contexto do problema"
    echo "  2. Quebre em tarefas menores"
    echo "  3. Use o agente apropriado"
    echo "  4. Documente decisoes importantes"
    echo "  5. Faca commits incrementais"
}

# ============================================================================
# SALVAR MEMORIAS
# ============================================================================

# Salva uma nova memoria/licao aprendida
# Uso: memory_save "titulo" "conteudo" "tags"
memory_save() {
    local title="$1"
    local content="$2"
    local tags="${3:-}"

    if [ -z "$title" ] || [ -z "$content" ]; then
        print_error "Titulo e conteudo obrigatorios"
        return 1
    fi

    memory_init

    # Gera nome do arquivo
    local filename
    filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local filepath="$MEMORY_LOCAL_DIR/${timestamp}-${filename}.md"

    # Cria arquivo de memoria
    {
        echo "# $title"
        echo ""
        echo "**Data:** $(date '+%Y-%m-%d %H:%M')"
        [ -n "$tags" ] && echo "**Tags:** $tags"
        echo ""
        echo "---"
        echo ""
        echo "$content"
    } > "$filepath"

    # Atualiza indice
    _memory_update_index "$filepath" "$title" "$tags"

    print_success "Memoria salva: $filepath"
    return 0
}

# Atualiza indice de memorias
_memory_update_index() {
    local filepath="$1"
    local title="$2"
    local tags="$3"
    local index_file="$MEMORY_LOCAL_DIR/index.json"

    if command -v jq >/dev/null 2>&1; then
        local tmp_file
        tmp_file=$(mktemp)
        local timestamp
        timestamp=$(date -Iseconds)

        jq --arg file "$(basename "$filepath")" \
           --arg title "$title" \
           --arg tags "$tags" \
           --arg ts "$timestamp" \
           '.memories += [{"file": $file, "title": $title, "tags": $tags, "created": $ts}] | .last_updated = $ts' \
           "$index_file" > "$tmp_file" && mv "$tmp_file" "$index_file"
    fi
}

# ============================================================================
# INTEGRACAO COM WORKFLOWS
# ============================================================================

# Consulta memorias no inicio de debugging
# Uso: memory_on_debug_start "descricao do bug"
memory_on_debug_start() {
    local bug_description="$1"

    print_section "Consultando Memorias de Debugging"

    # Busca bugs similares
    memory_search "$bug_description" 3

    # Sugere baseado no contexto
    memory_suggest "$bug_description"
}

# Consulta memorias no inicio de feature
# Uso: memory_on_feature_start "descricao da feature"
memory_on_feature_start() {
    local feature_description="$1"

    print_section "Consultando Memorias de Features"

    # Busca features similares
    memory_search "$feature_description" 3

    # Sugere baseado no contexto
    memory_suggest "$feature_description"
}

# Salva licao aprendida apos resolucao
# Uso: memory_on_resolution "titulo" "o que foi feito" "tags"
memory_on_resolution() {
    local title="$1"
    local content="$2"
    local tags="${3:-}"

    print_section "Salvando Licao Aprendida"

    memory_save "$title" "$content" "$tags"
}

# ============================================================================
# LISTAGEM E ESTATISTICAS
# ============================================================================

# Lista memorias recentes
# Uso: memory_list_recent 10
memory_list_recent() {
    local limit="${1:-10}"

    if [ ! -d "$MEMORY_LOCAL_DIR" ]; then
        print_warning "Nenhuma memoria local encontrada"
        return 0
    fi

    print_info "Memorias recentes:"
    echo ""

    local count=0
    while IFS= read -r file; do
        if [ "$count" -ge "$limit" ]; then
            break
        fi

        local title
        title=$(head -n 1 "$file" | sed 's/^#\+ *//')
        local date
        date=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)

        printf "  %s  %s\n" "$date" "$title"

        ((count++)) || true
    done < <(find "$MEMORY_LOCAL_DIR" -name "*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f2-)

    echo ""
    print_info "Total: $count memorias"
}

# Mostra estatisticas de memorias
# Uso: memory_stats
memory_stats() {
    if [ ! -d "$MEMORY_LOCAL_DIR" ]; then
        print_warning "Nenhuma memoria local encontrada"
        return 0
    fi

    local total
    total=$(find "$MEMORY_LOCAL_DIR" -name "*.md" -type f 2>/dev/null | wc -l)

    local this_month
    this_month=$(find "$MEMORY_LOCAL_DIR" -name "*.md" -type f -mtime -30 2>/dev/null | wc -l)

    print_section "Estatisticas de Memorias"
    echo "  Total de memorias:    $total"
    echo "  Ultimos 30 dias:      $this_month"
    echo "  Diretorio:            $MEMORY_LOCAL_DIR"
    echo ""
}
