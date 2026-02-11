#!/bin/bash
# context-passport.sh - Sistema de Context Passport padronizado
# Gerencia passagem de contexto entre agentes com economia de tokens

PASSPORT_VERSION="1.0"
PASSPORT_DIR="${PASSPORT_DIR:-.aidev/state/passports}"

# ============================================================================
# CRIAR PASSPORT
# ============================================================================
passport_create() {
    local task_id="$1"
    local agent_role="$2"
    local parent_task_id="${3:-}"
    
    # Gera IDs únicos
    local passport_id="pp-$(date +%s%N | cut -c1-16)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Carrega contexto da sessão
    local session_file=".aidev/state/session.json"
    local session_data='{}'
    if [ -f "$session_file" ]; then
        session_data=$(cat "$session_file")
    fi
    
    # Extrai dados da sessão
    local project_name=$(echo "$session_data" | jq -r '.current_platform // "unknown"')
    local stack=$(echo "$session_data" | jq -r '.current_stack // "generic"')
    local language=$(echo "$session_data" | jq -r '.language // "pt-BR"')
    local maturity=$(echo "$session_data" | jq -r '.maturity // "brownfield"')
    
    # Monta JSON do passport
    jq -n \
        --arg version "$PASSPORT_VERSION" \
        --arg pp_id "$passport_id" \
        --arg task "$task_id" \
        --arg parent "${parent_task_id:-null}" \
        --arg role "$agent_role" \
        --arg date "$timestamp" \
        --arg project "$project_name" \
        --arg stack "$stack" \
        --arg lang "$language" \
        --arg maturity "$maturity" \
        '{
            passport_version: $version,
            passport_id: $pp_id,
            task_id: $task,
            parent_task_id: (if $parent == "null" then null else $parent end),
            agent_role: $role,
            created_at: $date,
            session_context: {
                project_name: $project,
                stack: $stack,
                language: $lang,
                maturity: $maturity
            },
            constraints: {
                max_tokens: 2000,
                max_time_minutes: 30,
                style_guide: ".aidev/rules/\($stack).md",
                test_required: true,
                commit_language: $lang,
                forbidden_patterns: ["eval(", "innerHTML", "exec(", "system(", "rm -rf /"]
            },
            context_files: [],
            output_format: "markdown",
            handoff_chain: [],
            kb_references: [],
            validation_rules: {
                enforce_safe_paths: true,
                enforce_commit_format: true,
                enforce_tdd: true,
                enforce_no_emoji: true,
                enforce_portuguese: true
            },
            metadata: {}
        }'
}

# ============================================================================
# ADICIONAR ARQUIVO DE CONTEXTO
# ============================================================================
passport_add_context_file() {
    local passport_file="$1"
    local file_path="$2"
    local relevance="${3:-0.5}"
    local summary="${4:-}"
    
    if [ ! -f "$passport_file" ]; then
        echo "❌ ERRO: Passport não encontrado: $passport_file" >&2
        return 1
    fi
    
    if [ ! -f "$file_path" ]; then
        echo "⚠️  AVISO: Arquivo de contexto não existe: $file_path" >&2
        # Continua mesmo assim - arquivo pode ser criado depois
    fi
    
    # Obtém timestamp de modificação
    local last_modified=$(stat -c %Y "$file_path" 2>/dev/null || echo "0")
    local modified_iso=$(date -u -d "@$last_modified" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    
    # Cria objeto do arquivo
    local file_obj=$(jq -n \
        --arg path "$file_path" \
        --argjson relevance "$relevance" \
        --arg summary "$summary" \
        --arg modified "$modified_iso" \
        '{
            path: $path,
            relevance: $relevance,
            summary: $summary,
            last_modified: $modified
        }')
    
    # Adiciona ao array
    jq --argjson file "$file_obj" \
       '.context_files += [$file]' \
       "$passport_file" > "${passport_file}.tmp" && mv "${passport_file}.tmp" "$passport_file"
    
    echo "✅ Arquivo adicionado: $file_path (relevance: $relevance)"
}

# ============================================================================
# ADICIONAR REFERÊNCIA AO KB
# ============================================================================
passport_add_kb_reference() {
    local passport_file="$1"
    local lesson_id="$2"
    local lesson_file="$3"
    local relevance_score="${4:-50}"
    
    if [ ! -f "$passport_file" ]; then
        echo "❌ ERRO: Passport não encontrado" >&2
        return 1
    fi
    
    local ref_obj=$(jq -n \
        --arg id "$lesson_id" \
        --arg file "$lesson_file" \
        --argjson score "$relevance_score" \
        '{
            lesson_id: $id,
            file: $file,
            relevance_score: $score,
            applied: false
        }')
    
    jq --argjson ref "$ref_obj" \
       '.kb_references += [$ref]' \
       "$passport_file" > "${passport_file}.tmp" && mv "${passport_file}.tmp" "$passport_file"
    
    echo "✅ Referência KB adicionada: $lesson_id (score: $relevance_score)"
}

# ============================================================================
# REGISTRAR HANDOFF
# ============================================================================
passport_add_handoff() {
    local passport_file="$1"
    local from_agent="$2"
    local to_agent="$3"
    local artifact="${4:-}"
    local notes="${5:-}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local handoff_obj=$(jq -n \
        --arg from "$from_agent" \
        --arg to "$to_agent" \
        --arg date "$timestamp" \
        --arg artifact "$artifact" \
        --arg notes "$notes" \
        '{
            from: $from,
            to: $to,
            timestamp: $date,
            artifact: $artifact,
            notes: $notes
        }')
    
    jq --argjson handoff "$handoff_obj" \
       '.handoff_chain += [$handoff]' \
       "$passport_file" > "${passport_file}.tmp" && mv "${passport_file}.tmp" "$passport_file"
    
    echo "✅ Handoff registrado: $from_agent → $to_agent"
}

# ============================================================================
# SALVAR PASSPORT
# ============================================================================
passport_save() {
    local passport_content="$1"
    local task_id=$(echo "$passport_content" | jq -r '.task_id')
    
    mkdir -p "$PASSPORT_DIR"
    local file_path="$PASSPORT_DIR/${task_id}.json"
    
    echo "$passport_content" > "$file_path"
    echo "$file_path"
}

# ============================================================================
# CARREGAR PASSPORT
# ============================================================================
passport_load() {
    local task_id="$1"
    local file_path="$PASSPORT_DIR/${task_id}.json"
    
    if [ -f "$file_path" ]; then
        cat "$file_path"
    else
        echo "{}"
        return 1
    fi
}

# ============================================================================
# COMPACTAR PASSPORT (Economia de Tokens)
# ============================================================================
passport_compact() {
    local passport_file="$1"
    
    if [ ! -f "$passport_file" ]; then
        echo "❌ ERRO: Passport não encontrado" >&2
        return 1
    fi
    
    # Versão econômica em tokens - mantém apenas essencial
    jq '{
        passport_version,
        task_id,
        agent_role,
        constraints: {
            max_tokens,
            test_required,
            forbidden_patterns
        },
        context_files: [.context_files[]? | {path, relevance}],
        kb_references: [.kb_references[]? | {lesson_id, relevance_score}]
    }' "$passport_file"
}

# ============================================================================
# ESTIMATIVA DE TOKENS
# ============================================================================
passport_estimate_tokens() {
    local passport_file="$1"
    
    if [ ! -f "$passport_file" ]; then
        echo "0"
        return 1
    fi
    
    # Estimativa simples: 1 token ≈ 4 caracteres (média conservadora)
    local chars=$(wc -c < "$passport_file")
    local tokens=$((chars / 4))
    
    echo "$tokens"
}

# ============================================================================
# VERIFICAR LIMITE DE TOKENS
# ============================================================================
passport_check_token_limit() {
    local passport_file="$1"
    local max_tokens="${2:-2000}"
    
    local current_tokens=$(passport_estimate_tokens "$passport_file")
    local limit=$(jq -r '.constraints.max_tokens // 2000' "$passport_file")
    
    # Usa o menor limite
    if [ "$max_tokens" -lt "$limit" ]; then
        limit="$max_tokens"
    fi
    
    if [ "$current_tokens" -gt "$limit" ]; then
        echo "⚠️  ALERTA: Passport usa $current_tokens tokens (limite: $limit)"
        echo "   Sugestão: Use passport_compact ou remova arquivos de baixa relevância"
        return 1
    else
        echo "✅ Passport OK: $current_tokens/$limit tokens ($(($current_tokens * 100 / $limit))%)"
        return 0
    fi
}

# ============================================================================
# LISTAR PASSPORTS
# ============================================================================
passport_list() {
    if [ ! -d "$PASSPORT_DIR" ]; then
        echo "Nenhum passport encontrado"
        return 0
    fi
    
    echo "📋 Passports disponíveis:"
    for file in "$PASSPORT_DIR"/*.json; do
        [ -e "$file" ] || continue
        
        local task_id=$(basename "$file" .json)
        local agent=$(jq -r '.agent_role // "unknown"' "$file")
        local date=$(jq -r '.created_at // "unknown"' "$file")
        local files_count=$(jq '.context_files | length' "$file")
        
        echo "   📄 $task_id"
        echo "      Agente: $agent | Arquivos: $files_count | Criado: $date"
    done
}

# ============================================================================
# REMOVER PASSPORT
# ============================================================================
passport_remove() {
    local task_id="$1"
    local file_path="$PASSPORT_DIR/${task_id}.json"
    
    if [ -f "$file_path" ]; then
        rm "$file_path"
        echo "✅ Passport removido: $task_id"
    else
        echo "⚠️  Passport não encontrado: $task_id"
        return 1
    fi
}

# ============================================================================
# CLONAR PASSPORT (para nova tarefa)
# ============================================================================
passport_clone() {
    local source_task="$1"
    local new_task="$2"
    local new_agent="${3:-}"
    
    local source_file="$PASSPORT_DIR/${source_task}.json"
    
    if [ ! -f "$source_file" ]; then
        echo "❌ ERRO: Passport fonte não encontrado: $source_task" >&2
        return 1
    fi
    
    # Gera novo passport baseado no antigo
    local new_pp=$(cat "$source_file" | jq \
        --arg new_id "pp-$(date +%s%N | cut -c1-16)" \
        --arg new_task "$new_task" \
        --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --arg parent "$source_task" \
        --arg agent "${new_agent:-$(jq -r '.agent_role' "$source_file")}" \
        '{
            passport_version,
            passport_id: $new_id,
            task_id: $new_task,
            parent_task_id: $parent,
            agent_role: $agent,
            created_at: $date,
            session_context,
            constraints,
            context_files: [],
            output_format,
            handoff_chain: [],
            kb_references,
            validation_rules,
            metadata: {}
        }')
    
    passport_save "$new_pp"
    echo "✅ Passport clonado: $source_task → $new_task"
}

# ============================================================================
# CLI / EXPORTAÇÃO
# ============================================================================
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Foi sourced
    :
else
    # Executado diretamente
    echo "context-passport.sh - Sistema de Context Passport"
    echo ""
    echo "Funções disponíveis:"
    echo "  passport_create <task_id> <agent_role> [parent_task_id]"
    echo "  passport_add_context_file <file> <path> [relevance] [summary]"
    echo "  passport_add_kb_reference <file> <lesson_id> <lesson_file> [score]"
    echo "  passport_add_handoff <file> <from> <to> [artifact] [notes]"
    echo "  passport_save <content>"
    echo "  passport_load <task_id>"
    echo "  passport_compact <file>"
    echo "  passport_estimate_tokens <file>"
    echo "  passport_list"
    echo "  passport_remove <task_id>"
    echo ""
    echo "Diretório de passports: $PASSPORT_DIR"
fi
