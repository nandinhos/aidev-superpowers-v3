# Sistema de Validação Automática e Gestão de Conhecimento

**Documento Técnico de Implementação**  
**Versão**: 1.0  
**Data**: 2026-02-11  
**Status**: Pronto para Implementação  

---

## Resumo Executivo

Este documento consolida a implementação de um sistema híbrido de validação automática e gestão de conhecimento que resolve 4 gaps críticos do AI Dev Superpowers:

1. **Automação da catalogação** - Elimina dependência de memória humana
2. **Busca automática em KB** - Consulta obrigatória antes de cada ação
3. **Validação automática de regras** - Garante TDD, commits em pt, segurança
4. **Sistema de backlog de erros** - Previne perda de bugs críticos

O sistema aproveita conceitos avançados de multi-LLM (validação com retry/fallback, Context Passport, MCP integration) mantendo a arquitetura atual e economizando tokens.

---

## Estratégia de Validação: Warning → Bloqueio

### Fase 1: Warning (Modo Educativo)
```
Ação detectada: Commit sem teste
⚠️  WARNING: TDD obrigatório - Arquivo X não possui teste correspondente

Opções:
[1] Corrigir agora (recomendado)
[2] Prosseguir mesmo assim (será bloqueado em modo estrito)
[3] Ver documentação sobre TDD
```

### Fase 2: Bloqueio (Modo Estrito)
Após período de adaptação (configurável), validações críticas bloqueiam ação:
- Path crítico (`/etc`, `/usr`): BLOQUEADO
- Commit em inglês: BLOQUEADO  
- Código sem teste: BLOQUEADO
- Padrões proibidos: BLOQUEADO

### Configuração por Ambiente
```bash
# .aidev/config/validation.conf
VALIDATION_MODE=warning  # warning | strict
WARNING_TO_BLOCK_AFTER_DAYS=7
OVERRIDE_ALLOWED=true    # Permitir --force em casos especiais
```

---

## Arquitetura do Sistema

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                    Orchestrator (Você)                       │
└──────────────┬──────────────────────────────────────────────┘
               │
       ┌───────┴───────┬──────────────┬──────────────┐
       ▼               ▼              ▼              ▼
┌────────────┐ ┌────────────┐ ┌──────────┐ ┌────────────┐
│ Validators │ │  Context   │ │   KB     │ │  Backlog   │
│   Engine   │ │  Passport  │ │  Search  │ │   System   │
└─────┬──────┘ └─────┬──────┘ └────┬─────┘ └─────┬──────┘
      │              │             │             │
      ▼              ▼             ▼             ▼
┌────────────┐ ┌────────────┐ ┌──────────┐ ┌────────────┐
│ Auto-Cat   │ │ Validation │ │  MCP     │ │ Escalation │
│  alog      │ │  Pipeline  │ │  Bridge  │ │   Log      │
└────────────┘ └────────────┘ └──────────┘ └────────────┘
```

---

## Especificação Técnica

### 1. Validators Engine (validators.sh)

**Local**: `.aidev/lib/validators.sh`

```bash
#!/bin/bash
# Funções determinísticas de validação
# Todas retornam: 0 (válido) ou 1 (inválido)

validate_safe_path() {
    local path="$1"
    local forbidden_paths=("/etc" "/usr" "/var" "/root" "~" "/" "/sys" "/proc")
    
    for forbidden in "${forbidden_paths[@]}"; do
        if [[ "$path" == "$forbidden" ]] || [[ "$path" == "$forbidden"/* ]]; then
            log_validation "ERROR" "validate_safe_path" "Path crítico detectado: $path"
            return 1
        fi
    done
    return 0
}

validate_commit_format() {
    local msg="$1"
    # Regex: tipo(escopo): descrição em português
    local pattern="^(feat|fix|refactor|test|docs|chore)\([a-z0-9-]+\):\s+[a-záàâãéêíóôõúç].+$"
    
    if [[ "$msg" =~ $pattern ]]; then
        return 0
    else
        log_validation "ERROR" "validate_commit_format" "Formato inválido: $msg"
        return 1
    fi
}

validate_no_emoji() {
    local text="$1"
    # Remove emojis com regex Unicode
    local cleaned=$(echo "$text" | LC_ALL=UTF-8 sed 's/[😀-🿿]//g')
    
    if [ "$cleaned" == "$text" ]; then
        return 0
    else
        log_validation "ERROR" "validate_no_emoji" "Emoji detectado no texto"
        return 1
    fi
}

validate_test_exists() {
    local file="$1"
    local ext="${file##*.}"
    local base="${file%.*}"
    
    # Padrões de teste por extensão
    case "$ext" in
        js|ts)
            test_files=("${base}.test.${ext}" "${base}.spec.${ext}" "__tests__/${base}.${ext}")
            ;;
        py)
            test_files=("test_${file}" "${base}_test.py" "tests/${base}_test.py")
            ;;
        php)
            test_files=("${base}Test.php" "tests/${base}Test.php")
            ;;
        *)
            # Tenta padrões genéricos
            test_files=("${base}.test.${ext}" "test_${file}")
            ;;
    esac
    
    for test_file in "${test_files[@]}"; do
        if [ -f "$test_file" ]; then
            return 0
        fi
    done
    
    log_validation "ERROR" "validate_test_exists" "Teste não encontrado para: $file"
    return 1
}

validate_portuguese_language() {
    local text="$1"
    # Palavras comuns em inglês que indicam violação
    local english_words=("add" "fix" "update" "remove" "create" "implement")
    
    local first_word=$(echo "$text" | awk '{print tolower($1)}')
    for word in "${english_words[@]}"; do
        if [ "$first_word" == "$word" ]; then
            log_validation "ERROR" "validate_portuguese_language" "Texto parece estar em inglês: $first_word"
            return 1
        fi
    done
    return 0
}

validate_no_forbidden_patterns() {
    local content="$1"
    local forbidden=("eval(" "innerHTML" "exec(" "system(" "rm -rf /")
    
    for pattern in "${forbidden[@]}"; do
        if echo "$content" | grep -qF "$pattern"; then
            log_validation "CRITICAL" "validate_no_forbidden_patterns" "Padrão proibido: $pattern"
            return 1
        fi
    done
    return 0
}

# Logging interno
log_validation() {
    local level="$1"
    local validator="$2"
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[$timestamp] [$level] $validator: $message" >&2
}
```

---

### 2. Validation Engine (validation-engine.sh)

**Local**: `.aidev/lib/validation-engine.sh`

```bash
#!/bin/bash
# Engine de validação com retry e fallback

source "${BASH_SOURCE%/*}/validators.sh"

VALIDATION_MAX_RETRIES=5
VALIDATION_RETRY_DELAY=1
VALIDATION_MODE="${VALIDATION_MODE:-warning}"  # warning | strict

validation_with_retry() {
    local validator="$1"
    local input="$2"
    local max_retries="${3:-$VALIDATION_MAX_RETRIES}"
    local attempt=1
    
    while [ $attempt -le $max_retries ]; do
        if $validator "$input"; then
            return 0
        fi
        
        log_validation "WARN" "validation_with_retry" "Tentativa $attempt/$max_retries falhou: $validator"
        
        if [ $attempt -lt $max_retries ]; then
            sleep $VALIDATION_RETRY_DELAY
        fi
        
        ((attempt++))
    done
    
    return 1
}

validation_with_fallback() {
    local primary_validator="$1"
    local fallback_validator="$2"
    local input="$3"
    local context="$4"
    
    # Tenta validação primária com retry
    if validation_with_retry "$primary_validator" "$input"; then
        return 0
    fi
    
    log_validation "INFO" "validation_with_fallback" "Primária falhou, tentando fallback: $fallback_validator"
    
    # Fallback: tenta abordagem alternativa
    if validation_with_retry "$fallback_validator" "$input"; then
        return 0
    fi
    
    # Ambas falharam - escalar para humano
    _log_escalation "$primary_validator" "$fallback_validator" "$input" "$context"
    return 1
}

_log_escalation() {
    local primary="$1"
    local fallback="$2"
    local input="$3"
    local context="$4"
    
    local log_file=".aidev/state/escalations.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local id="esc-$(date +%s%N)"
    
    mkdir -p "$(dirname "$log_file")"
    
    local entry=$(cat <<EOF
{
  "id": "$id",
  "timestamp": "$timestamp",
  "primary_validator": "$primary",
  "fallback_validator": "$fallback",
  "input": $(echo "$input" | jq -R -s .),
  "context": "$context",
  "status": "pending_human_review",
  "auto_retry_count": $VALIDATION_MAX_RETRIES
}
EOF
)
    
    if [ -f "$log_file" ]; then
        jq ". += [$entry]" "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
    else
        echo "[$entry]" > "$log_file"
    fi
    
    log_validation "ESCALATION" "_log_escalation" "Validação escalonada: $id"
}

# Função principal para decisão Warning vs Bloqueio
validation_enforce() {
    local validator="$1"
    local input="$2"
    local description="$3"
    
    if $validator "$input"; then
        return 0
    fi
    
    case "$VALIDATION_MODE" in
        "strict")
            echo "❌ BLOQUEADO: $description"
            echo "   Validação falhou: $validator"
            echo "   Use --force para override (registrado em auditoria)"
            return 1
            ;;
        "warning"|*)
            echo "⚠️  WARNING: $description"
            echo "   Sugestão: Corrija antes de prosseguir"
            echo "   Validação: $validator"
            # Retorna 0 mas loga o warning
            log_validation "WARN" "validation_enforce" "Warning emitido: $description"
            return 0
            ;;
    esac
}
```

---

### 3. Context Passport System (context-passport.sh)

**Local**: `.aidev/lib/context-passport.sh`

```bash
#!/bin/bash
# Sistema de Context Passport padronizado

PASSPORT_VERSION="1.0"
PASSPORT_DIR=".aidev/state/passports"

passport_create() {
    local task_id="$1"
    local agent_role="$2"
    local parent_task_id="${3:-}"
    
    local passport_id="pp-$(date +%s%N | cut -c1-16)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Carrega contexto da sessão
    local session_data='{}'
    if [ -f ".aidev/state/session.json" ]; then
        session_data=$(cat ".aidev/state/session.json")
    fi
    
    local project_name=$(echo "$session_data" | jq -r '.current_platform // "unknown"')
    local stack=$(echo "$session_data" | jq -r '.current_stack // "generic"')
    local language=$(echo "$session_data" | jq -r '.language // "pt-BR"')
    
    cat <<EOF
{
  "passport_version": "$PASSPORT_VERSION",
  "passport_id": "$passport_id",
  "task_id": "$task_id",
  "parent_task_id": "$parent_task_id",
  "agent_role": "$agent_role",
  "created_at": "$timestamp",
  "session_context": {
    "project_name": "$project_name",
    "stack": "$stack",
    "language": "$language",
    "maturity": "$(echo "$session_data" | jq -r '.maturity // "brownfield"')"
  },
  "constraints": {
    "max_tokens": 2000,
    "max_time_minutes": 30,
    "style_guide": ".aidev/rules/${stack}.md",
    "test_required": true,
    "commit_language": "$language",
    "forbidden_patterns": ["eval(", "innerHTML", "exec(", "system("]
  },
  "context_files": [],
  "output_format": "markdown",
  "handoff_chain": [],
  "kb_references": [],
  "validation_rules": {
    "enforce_safe_paths": true,
    "enforce_commit_format": true,
    "enforce_tdd": true,
    "enforce_no_emoji": true
  }
}
EOF
}

passport_add_context_file() {
    local passport_file="$1"
    local file_path="$2"
    local relevance="${3:-0.5}"
    local summary="${4:-}"
    
    if [ ! -f "$passport_file" ]; then
        echo "ERRO: Passport não encontrado" >&2
        return 1
    fi
    
    local last_modified=$(stat -c %Y "$file_path" 2>/dev/null || echo "0")
    local modified_iso=$(date -u -d "@$last_modified" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    
    local file_obj=$(jq -n \
        --arg path "$file_path" \
        --argjson relevance "$relevance" \
        --arg summary "$summary" \
        --arg modified "$modified_iso" \
        '{path: $path, relevance: $relevance, summary: $summary, last_modified: $modified}')
    
    jq ".context_files += [$file_obj]" "$passport_file" > "${passport_file}.tmp" && mv "${passport_file}.tmp" "$passport_file"
}

passport_add_kb_reference() {
    local passport_file="$1"
    local lesson_id="$2"
    local lesson_file="$3"
    local relevance_score="${4:-0.5}"
    
    local ref_obj=$(jq -n \
        --arg lesson_id "$lesson_id" \
        --arg file "$lesson_file" \
        --argjson score "$relevance_score" \
        '{lesson_id: $lesson_id, file: $file, relevance_score: $score}')
    
    jq ".kb_references += [$ref_obj]" "$passport_file" > "${passport_file}.tmp" && mv "${passport_file}.tmp" "$passport_file"
}

passport_add_handoff() {
    local passport_file="$1"
    local from_agent="$2"
    local to_agent="$3"
    local artifact="$4"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local handoff_obj=$(jq -n \
        --arg from "$from_agent" \
        --arg to "$to_agent" \
        --arg timestamp "$timestamp" \
        --arg artifact "$artifact" \
        '{from: $from, to: $to, timestamp: $timestamp, artifact: $artifact}')
    
    jq ".handoff_chain += [$handoff_obj]" "$passport_file" > "${passport_file}.tmp" && mv "${passport_file}.tmp" "$passport_file"
}

passport_save() {
    local passport_content="$1"
    local task_id=$(echo "$passport_content" | jq -r '.task_id')
    
    mkdir -p "$PASSPORT_DIR"
    local file_path="$PASSPORT_DIR/${task_id}.json"
    
    echo "$passport_content" > "$file_path"
    echo "$file_path"
}

passport_load() {
    local task_id="$1"
    local file_path="$PASSPORT_DIR/${task_id}.json"
    
    if [ -f "$file_path" ]; then
        cat "$file_path"
    else
        echo "{}"
    fi
}

passport_compact() {
    local passport_file="$1"
    
    # Versão econômica em tokens - mantém apenas essencial
    jq '{
        passport_version,
        task_id,
        agent_role,
        constraints: {
            style_guide,
            test_required,
            forbidden_patterns
        },
        context_files: [.context_files[] | {path, relevance}],
        kb_references: [.kb_references[] | {lesson_id, file, relevance_score}]
    }' "$passport_file"
}

passport_get_token_estimate() {
    local passport_file="$1"
    
    # Estimativa simples: 1 token ≈ 4 caracteres
    local chars=$(wc -c < "$passport_file")
    local tokens=$((chars / 4))
    
    echo "$tokens"
}
```

---

### 4. Knowledge Base Search (kb-search.sh)

**Local**: `.aidev/lib/kb-search.sh`

```bash
#!/bin/bash
# Motor de busca em Knowledge Base com relevance scoring

KB_DIR=".aidev/memory/kb"

# Verifica se MCPs estão disponíveis
_kb_check_mcp_availability() {
    local available_mcp=()
    
    # Verifica Basic Memory
    if command -v basic-memory &> /dev/null || [ -n "$MCP_BASIC_MEMORY_AVAILABLE" ]; then
        available_mcp+=("basic-memory")
    fi
    
    # Verifica Serena
    if command -v serena &> /dev/null || [ -n "$MCP_SERENA_AVAILABLE" ]; then
        available_mcp+=("serena")
    fi
    
    echo "${available_mcp[@]}"
}

kb_search() {
    local query="$1"
    local max_results="${2:-3}"
    local use_mcp="${3:-true}"
    
    local all_results="[]"
    
    # 1. Busca local (sempre executa)
    local local_results=$(kb_search_local "$query" "$max_results")
    all_results=$(echo "$all_results" | jq --argjson local "$local_results" '. + $local')
    
    # 2. Busca em MCPs (se disponível e permitido)
    if [ "$use_mcp" == "true" ]; then
        local mcp_list=$(_kb_check_mcp_availability)
        
        if [[ "$mcp_list" == *"basic-memory"* ]]; then
            local mcp_results=$(kb_search_basic_memory "$query" "$max_results")
            all_results=$(echo "$all_results" | jq --argjson mcp "$mcp_results" '. + $mcp')
            echo "[KB-SEARCH] MCP Basic Memory: ✓ Tokens economizados com busca semântica" >&2
        fi
        
        if [[ "$mcp_list" == *"serena"* ]]; then
            local serena_results=$(kb_search_serena "$query" "$max_results")
            all_results=$(echo "$all_results" | jq --argjson serena "$serena_results" '. + $serena')
            echo "[KB-SEARCH] MCP Serena: ✓ Contexto de sessão recuperado" >&2
        fi
        
        if [ -z "$mcp_list" ]; then
            echo "[KB-SEARCH] ℹ️  MCPs não disponíveis. Instale para economizar tokens:" >&2
            echo "    - Basic Memory: npm install -g @anthropics/basic-memory" >&2
            echo "    - Serena: pip install serena-mcp" >&2
            echo "    💡 Sem MCPs, busca é local apenas (mais tokens consumidos)" >&2
        fi
    fi
    
    # Remove duplicados, ordena por score e limita
    echo "$all_results" | jq 'group_by(.id) | map(first) | sort_by(.score) | reverse | .[0:'"$max_results"']'
}

kb_search_local() {
    local query="$1"
    local max_results="$2"
    
    local normalized=$(echo "$query" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/ /g')
    local keywords=($normalized)
    local results="[]"
    
    if [ ! -d "$KB_DIR" ]; then
        echo "$results"
        return
    fi
    
    for file in "$KB_DIR"/*.md; do
        [ -e "$file" ] || continue
        
        local filename=$(basename "$file")
        local content=$(cat "$file" | tr '[:upper:]' '[:lower:]')
        local score=0
        
        # Score por keywords
        for keyword in "${keywords[@]}"; do
            local count=$(echo "$content" | grep -o "$keyword" | wc -l)
            score=$((score + count * 10))
        done
        
        # Bônus por campos
        if echo "$content" | grep -q "type:.*bug"; then
            score=$((score + 20))
        fi
        if echo "$content" | grep -q "category:.*critical"; then
            score=$((score + 30))
        fi
        
        # Extrai metadata
        local title=$(grep "^# " "$file" | head -1 | sed 's/^# //')
        local id=$(grep "^id:" "$file" | cut -d: -f2 | tr -d ' ')
        local category=$(grep "^category:" "$file" | cut -d: -f2 | tr -d ' ')
        
        if [ $score -gt 0 ]; then
            local entry=$(jq -n \
                --arg id "${id:-$filename}" \
                --arg title "$title" \
                --arg file "$filename" \
                --argjson score "$score" \
                --arg source "local" \
                --arg category "$category" \
                '{id: $id, title: $title, file: $file, score: $score, source: $source, category: $category}')
            results=$(echo "$results" | jq ". += [$entry]")
        fi
    done
    
    echo "$results"
}

kb_search_basic_memory() {
    local query="$1"
    local max_results="$2"
    
    # Simulação - em produção usaria MCP real
    # mcp__basic-memory__search_notes query="$query"
    
    # Placeholder para quando MCP estiver disponível
    echo "[]"
}

kb_search_serena() {
    local query="$1"
    local max_results="$2"
    
    # Simulação - em produção usaria MCP real
    # mcp__serena__search_memories query="$query"
    
    # Placeholder para quando MCP estiver disponível
    echo "[]"
}

kb_search_by_category() {
    local category="$1"
    
    local results="[]"
    
    for file in "$KB_DIR"/*.md; do
        [ -e "$file" ] || continue
        
        if grep -q "category:.*$category" "$file"; then
            local filename=$(basename "$file")
            local title=$(grep "^# " "$file" | head -1 | sed 's/^# //')
            local id=$(grep "^id:" "$file" | cut -d: -f2 | tr -d ' ')
            
            local entry=$(jq -n \
                --arg id "${id:-$filename}" \
                --arg title "$title" \
                --arg file "$filename" \
                --arg category "$category" \
                '{id: $id, title: $title, file: $file, score: 100, source: "local", category: $category}')
            results=$(echo "$results" | jq ". += [$entry]")
        fi
    done
    
    echo "$results"
}

# Hook principal para consulta automática antes de codificação
kb_pre_coding_search() {
    local task_description="$1"
    local passport_file="${2:-}"
    
    echo "[KB-SEARCH] 🔍 Consultando base de conhecimento..." >&2
    
    local start_time=$(date +%s)
    local results=$(kb_search "$task_description" 3 true)
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local count=$(echo "$results" | jq 'length')
    
    if [ "$count" -gt 0 ]; then
        echo "[KB-SEARCH] ✅ Encontradas $count lições relevantes (${duration}s):" >&2
        echo "$results" | jq -r '.[] | "  📄 \(.title) [\(.source)] (score: \(.score))"' >&2
        
        # Adiciona referências ao passport se fornecido
        if [ -n "$passport_file" ] && [ -f "$passport_file" ]; then
            source "${BASH_SOURCE%/*}/context-passport.sh"
            
            echo "$results" | jq -c '.[]' | while read -r result; do
                local file=$(echo "$result" | jq -r '.file')
                local score=$(echo "$result" | jq -r '.score')
                local id=$(echo "$result" | jq -r '.id')
                
                passport_add_kb_reference "$passport_file" "$id" "$file" "$score"
            done
        fi
    else
        echo "[KB-SEARCH] ℹ️  Nenhuma lição relevante encontrada (${duration}s)" >&2
    fi
    
    echo "$results"
}

# Verifica se há lições aplicáveis antes de prosseguir
kb_check_lessons_before_action() {
    local action_description="$1"
    local min_relevance="${2:-50}"
    
    local results=$(kb_search "$action_description" 1)
    local top_score=$(echo "$results" | jq '.[0].score // 0')
    
    if [ "$top_score" -ge "$min_relevance" ]; then
        local lesson=$(echo "$results" | jq -r '.[0]')
        local title=$(echo "$lesson" | jq -r '.title')
        local file=$(echo "$lesson" | jq -r '.file')
        
        echo "⚠️  ATENÇÃO: Lição relevante encontrada para esta ação!" >&2
        echo "   📄 $title" >&2
        echo "   📂 $KB_DIR/$file" >&2
        echo "   💡 Recomendado: Leia esta lição antes de prosseguir" >&2
        
        return 0  # Encontrou lição relevante
    fi
    
    return 1  # Nenhuma lição relevante
}
```

---

### 5. Backlog System (backlog.sh)

**Local**: `.aidev/lib/backlog.sh`

```bash
#!/bin/bash
# Sistema de backlog de erros e tarefas pendentes

BACKLOG_FILE=".aidev/state/backlog.json"

backlog_init() {
    if [ ! -f "$BACKLOG_FILE" ]; then
        mkdir -p "$(dirname "$BACKLOG_FILE")"
        cat > "$BACKLOG_FILE" <<'EOF'
{
  "errors": [],
  "tasks": [],
  "last_updated": "",
  "metadata": {
    "version": "1.0",
    "total_resolved": 0,
    "total_open": 0
  }
}
EOF
    fi
}

backlog_add_error() {
    local title="$1"
    local description="$2"
    local severity="${3:-medium}"  # low, medium, high, critical
    local tags="${4:-[]}"
    local related_files="${5:-[]}"
    
    backlog_init
    
    local id="err-$(date +%s%N | cut -c1-12)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Valida severidade
    case "$severity" in
        low|medium|high|critical) ;;
        *) severity="medium" ;;
    esac
    
    local entry=$(jq -n \
        --arg id "$id" \
        --arg title "$title" \
        --arg description "$description" \
        --arg severity "$severity" \
        --argjson tags "$tags" \
        --argjson files "$related_files" \
        --arg created "$timestamp" \
        '{
            id: $id,
            type: "error",
            title: $title,
            description: $description,
            severity: $severity,
            status: "open",
            tags: $tags,
            related_files: $files,
            created_at: $created,
            updated_at: $created,
            resolved_at: null,
            resolution_notes: null
        }')
    
    _backlog_update "$entry"
    
    echo "[BACKLOG] ✅ Erro adicionado: $id [$severity]" >&2
    echo "$id"
}

backlog_add_task() {
    local title="$1"
    local description="$2"
    local priority="${3:-medium}"  # low, medium, high, urgent
    local estimated_minutes="${4:-30}"
    
    backlog_init
    
    local id="task-$(date +%s%N | cut -c1-12)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local entry=$(jq -n \
        --arg id "$id" \
        --arg title "$title" \
        --arg description "$description" \
        --arg priority "$priority" \
        --argjson estimated "$estimated_minutes" \
        --arg created "$timestamp" \
        '{
            id: $id,
            type: "task",
            title: $title,
            description: $description,
            priority: $priority,
            estimated_minutes: $estimated,
            status: "pending",
            created_at: $created,
            started_at: null,
            completed_at: null
        }')
    
    _backlog_update_task "$entry"
    
    echo "[BACKLOG] ✅ Tarefa adicionada: $id [$priority]" >&2
    echo "$id"
}

backlog_list_open_errors() {
    backlog_init
    jq '.errors | map(select(.status == "open")) | sort_by(
        if .severity == "critical" then 4
        elif .severity == "high" then 3
        elif .severity == "medium" then 2
        else 1 end
    ) | reverse' "$BACKLOG_FILE"
}

backlog_list_pending_tasks() {
    backlog_init
    jq '.tasks | map(select(.status == "pending")) | sort_by(
        if .priority == "urgent" then 4
        elif .priority == "high" then 3
        elif .priority == "medium" then 2
        else 1 end
    ) | reverse' "$BACKLOG_FILE"
}

backlog_resolve_error() {
    local error_id="$1"
    local resolution_notes="${2:-Resolvido}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local temp_file="${BACKLOG_FILE}.tmp"
    
    jq "
        .errors = [.errors[] | 
            if .id == \"$error_id\" then 
                .status = \"resolved\" | 
                .resolved_at = \"$timestamp\" | 
                .resolution_notes = \"$resolution_notes\" |
                .updated_at = \"$timestamp\"
            else . end
        ] |
        .metadata.total_resolved += 1
    " "$BACKLOG_FILE" > "$temp_file" && mv "$temp_file" "$BACKLOG_FILE"
    
    _backlog_update_metadata
    
    echo "[BACKLOG] ✅ Erro resolvido: $error_id" >&2
}

backlog_complete_task() {
    local task_id="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local temp_file="${BACKLOG_FILE}.tmp"
    
    jq "
        .tasks = [.tasks[] | 
            if .id == \"$task_id\" then 
                .status = \"completed\" | 
                .completed_at = \"$timestamp\"
            else . end
        ]
    " "$BACKLOG_FILE" > "$temp_file" && mv "$temp_file" "$BACKLOG_FILE"
    
    echo "[BACKLOG] ✅ Tarefa concluída: $task_id" >&2
}

backlog_get_critical() {
    backlog_init
    jq '.errors | map(select(.severity == "critical" and .status == "open"))' "$BACKLOG_FILE"
}

backlog_get_by_tag() {
    local tag="$1"
    jq ".errors | map(select(.tags[] == \"$tag\" and .status == \"open\"))" "$BACKLOG_FILE"
}

backlog_stats() {
    backlog_init
    
    local total_errors=$(jq '.errors | length' "$BACKLOG_FILE")
    local open_errors=$(jq '.errors | map(select(.status == "open")) | length' "$BACKLOG_FILE")
    local critical=$(jq '.errors | map(select(.severity == "critical" and .status == "open")) | length' "$BACKLOG_FILE")
    local high=$(jq '.errors | map(select(.severity == "high" and .status == "open")) | length' "$BACKLOG_FILE")
    
    local total_tasks=$(jq '.tasks | length' "$BACKLOG_FILE")
    local pending_tasks=$(jq '.tasks | map(select(.status == "pending")) | length' "$BACKLOG_FILE")
    
    jq -n \
        --argjson total_errors "$total_errors" \
        --argjson open "$open_errors" \
        --argjson critical "$critical" \
        --argjson high "$high" \
        --argjson total_tasks "$total_tasks" \
        --argjson pending "$pending_tasks" \
        '{
            errors: {total: $total_errors, open: $open, critical: $critical, high_priority: $high},
            tasks: {total: $total_tasks, pending: $pending}
        }'
}

backlog_export() {
    local format="${1:-json}"  # json, markdown
    
    case "$format" in
        markdown)
            _backlog_export_markdown
            ;;
        *)
            cat "$BACKLOG_FILE"
            ;;
    esac
}

_backlog_update() {
    local entry="$1"
    local temp_file="${BACKLOG_FILE}.tmp"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --argjson entry "$entry" --arg updated "$timestamp" \
        '.errors += [$entry] | .last_updated = $updated' \
        "$BACKLOG_FILE" > "$temp_file" && mv "$temp_file" "$BACKLOG_FILE"
    
    _backlog_update_metadata
}

_backlog_update_task() {
    local entry="$1"
    local temp_file="${BACKLOG_FILE}.tmp"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --argjson entry "$entry" --arg updated "$timestamp" \
        '.tasks += [$entry] | .last_updated = $updated' \
        "$BACKLOG_FILE" > "$temp_file" && mv "$temp_file" "$BACKLOG_FILE"
}

_backlog_update_metadata() {
    local temp_file="${BACKLOG_FILE}.tmp"
    
    jq '
        .metadata.total_open = (.errors | map(select(.status == "open")) | length)
    ' "$BACKLOG_FILE" > "$temp_file" && mv "$temp_file" "$BACKLOG_FILE"
}

_backlog_export_markdown() {
    echo "# Backlog de Erros e Tarefas"
    echo ""
    echo "*Gerado em: $(date)*"
    echo ""
    
    echo "## Erros Abertos"
    echo ""
    backlog_list_open_errors | jq -r '.[] | "### \(.id) [\(.severity | ascii_upcase)]\n**\(.title)**\n\(.description)\n\n- Tags: \(.tags | join(", "))\n- Criado: \(.created_at)"'
    
    echo ""
    echo "## Tarefas Pendentes"
    echo ""
    backlog_list_pending_tasks | jq -r '.[] | "### \(.id) [\(.priority | ascii_upcase)]\n**\(.title)**\n\(.description)\n\n- Estimado: \(.estimated_minutes) min\n- Criado: \(.created_at)"'
}
```

---

### 6. Validation Pipeline (validation-pipeline.sh)

**Local**: `.aidev/lib/validation-pipeline.sh`

```bash
#!/bin/bash
# Pipeline automático de validação de regras globais

source "${BASH_SOURCE%/*}/validators.sh"
source "${BASH_SOURCE%/*}/validation-engine.sh"
source "${BASH_SOURCE%/*}/backlog.sh"

VALIDATION_CONFIG=".aidev/config/validation.conf"

_load_validation_config() {
    if [ -f "$VALIDATION_CONFIG" ]; then
        source "$VALIDATION_CONFIG"
    fi
    
    # Defaults
    VALIDATION_MODE="${VALIDATION_MODE:-warning}"
    ENFORCE_TDD="${ENFORCE_TDD:-true}"
    ENFORCE_COMMIT_PT="${ENFORCE_COMMIT_PT:-true}"
    ENFORCE_NO_EMOJI="${ENFORCE_NO_EMOJI:-true}"
    AUTO_BACKLOG_ERRORS="${AUTO_BACKLOG_ERRORS:-true}"
}

# Validação pré-commit completa
validate_pre_commit() {
    local commit_msg="$1"
    local files_changed="$2"
    
    _load_validation_config
    
    echo "[VALIDATION] 🔍 Iniciando validação pré-commit..." >&2
    
    local warnings=0
    local errors=0
    
    # 1. Valida formato do commit
    if ! validate_commit_format "$commit_msg"; then
        ((errors++))
        echo "   ❌ Formato de commit inválido" >&2
        echo "      Esperado: tipo(escopo): descrição em português" >&2
        echo "      Exemplo: feat(auth): adiciona login" >&2
    else
        echo "   ✅ Formato de commit válido" >&2
    fi
    
    # 2. Valida idioma (português)
    if [ "$ENFORCE_COMMIT_PT" == "true" ]; then
        if ! validate_portuguese_language "$commit_msg"; then
            ((warnings++))
            echo "   ⚠️  Commit pode estar em inglês" >&2
        else
            echo "   ✅ Idioma correto (português)" >&2
        fi
    fi
    
    # 3. Valida ausência de emoji
    if [ "$ENFORCE_NO_EMOJI" == "true" ]; then
        if ! validate_no_emoji "$commit_msg"; then
            ((errors++))
            echo "   ❌ Emojis não são permitidos em commits" >&2
        else
            echo "   ✅ Sem emojis" >&2
        fi
    fi
    
    # 4. Valida TDD (testes para arquivos modificados)
    if [ "$ENFORCE_TDD" == "true" ]; then
        local tdd_errors=0
        for file in $files_changed; do
            if [[ "$file" =~ \.(js|ts|py|php|java|go|rs)$ ]]; then
                if ! validate_test_exists "$file"; then
                    ((tdd_errors++))
                    if [ "$VALIDATION_MODE" == "strict" ]; then
                        echo "   ❌ TDD: $file não possui teste" >&2
                    else
                        echo "   ⚠️  TDD: $file não possui teste (recomendado adicionar)" >&2
                    fi
                fi
            fi
        done
        
        if [ $tdd_errors -eq 0 ]; then
            echo "   ✅ TDD: Todos os arquivos possuem testes" >&2
        else
            errors=$((errors + tdd_errors))
        fi
    fi
    
    # Resumo
    echo "" >&2
    if [ $errors -gt 0 ]; then
        echo "[VALIDATION] ❌ Validação FALHOU: $errors erro(s), $warnings warning(s)" >&2
        if [ "$VALIDATION_MODE" == "strict" ]; then
            return 1
        else
            echo "[VALIDATION] ⚠️  Modo WARNING: Prosseguindo mesmo assim" >&2
            return 0
        fi
    else
        echo "[VALIDATION] ✅ Todas as validações passaram" >&2
        return 0
    fi
}

# Validação pré-escrita de arquivo
validate_pre_write() {
    local file_path="$1"
    local content="$2"
    
    _load_validation_config
    
    # Valida path seguro
    if ! validate_safe_path "$file_path"; then
        echo "[VALIDATION] ❌ Path não seguro: $file_path" >&2
        
        # Adiciona ao backlog se for erro crítico
        if [ "$AUTO_BACKLOG_ERRORS" == "true" ]; then
            backlog_add_error \
                "Tentativa de acesso a path crítico" \
                "Validação detectou tentativa de operação em: $file_path" \
                "high" \
                '["security", "validation"]'
        fi
        
        return 1
    fi
    
    # Valida padrões proibidos no conteúdo
    if ! validate_no_forbidden_patterns "$content"; then
        echo "[VALIDATION] ❌ Padrões proibidos detectados no conteúdo" >&2
        return 1
    fi
    
    return 0
}

# Hook completo para ação de codificação
validate_coding_action() {
    local action="$1"  # create, edit, delete
    local file_path="$2"
    local content="${3:-}"
    local context="$4"
    
    _load_validation_config
    
    echo "[VALIDATION] 🔍 Validando ação: $action em $file_path" >&2
    
    case "$action" in
        "create"|"edit")
            if ! validate_pre_write "$file_path" "$content"; then
                _handle_validation_failure "$action" "$file_path" "$context"
                return 1
            fi
            ;;
        "delete")
            if ! validate_safe_path "$file_path"; then
                echo "[VALIDATION] ❌ Tentativa de deletar path crítico" >&2
                _handle_validation_failure "$action" "$file_path" "$context"
                return 1
            fi
            ;;
    esac
    
    echo "[VALIDATION] ✅ Validação aprovada" >&2
    return 0
}

_handle_validation_failure() {
    local action="$1"
    local file_path="$2"
    local context="$3"
    
    if [ "$AUTO_BACKLOG_ERRORS" == "true" ]; then
        backlog_add_error \
            "Falha de validação em $action" \
            "Ação: $action\nArquivo: $file_path\nContexto: $context" \
            "medium" \
            '["validation", "quality"]'
    fi
}

# Validação de arquivo de configuração
validate_config_file() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        echo "[VALIDATION] ⚠️  Arquivo de configuração não encontrado: $config_file" >&2
        return 1
    fi
    
    # Verifica sintaxe JSON
    if [[ "$config_file" == *.json ]]; then
        if ! jq empty "$config_file" 2>/dev/null; then
            echo "[VALIDATION] ❌ JSON inválido: $config_file" >&2
            return 1
        fi
    fi
    
    # Verifica sintaxe YAML
    if [[ "$config_file" == *.yaml ]] || [[ "$config_file" == *.yml ]]; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
            echo "[VALIDATION] ❌ YAML inválido: $config_file" >&2
            return 1
        fi
    fi
    
    echo "[VALIDATION] ✅ Configuração válida: $config_file" >&2
    return 0
}
```

---

### 7. Integração com Orchestration

**Modificações em `.aidev/lib/orchestration.sh`**:

```bash
#!/bin/bash
# Adições ao orchestration.sh existente

source "${BASH_SOURCE%/*}/validation-pipeline.sh"
source "${BASH_SOURCE%/*}/kb-search.sh"
source "${BASH_SOURCE%/*}/context-passport.sh"
source "${BASH_SOURCE%/*}/backlog.sh"

# ============================================================================
# HOOKS DE VALIDAÇÃO
# ============================================================================

# Hook chamado antes de qualquer codificação
pre_coding_hook() {
    local task_description="$1"
    local passport_file="$2"
    
    echo "[ORCHESTRATOR] 🎯 Iniciando hook pré-codificação..." >&2
    
    # 1. Verifica lições aprendidas relevantes
    if kb_check_lessons_before_action "$task_description"; then
        echo "[ORCHESTRATOR] 💡 Encontradas lições relevantes. Recomendo revisão." >&2
    fi
    
    # 2. Busca automática em KB
    local kb_results=$(kb_pre_coding_search "$task_description" "$passport_file")
    
    # 3. Verifica backlog crítico
    local critical_errors=$(backlog_get_critical)
    local critical_count=$(echo "$critical_errors" | jq 'length')
    
    if [ "$critical_count" -gt 0 ]; then
        echo "[ORCHESTRATOR] 🚨 ATENÇÃO: $critical_count erro(s) crítico(s) no backlog!" >&2
        echo "$critical_errors" | jq -r '.[] | "   - \(.id): \(.title)"' >&2
        echo "[ORCHESTRATOR] Considere resolver antes de prosseguir." >&2
    fi
    
    echo "$kb_results"
}

# Hook chamado após completar skill
post_skill_hook() {
    local skill_name="$1"
    local task_id="$2"
    local result="$3"
    
    # Se skill foi de debugging e teve sucesso, cataloga automaticamente
    if [[ "$skill_name" == *"debug"* ]] && [ "$result" == "success" ]; then
        echo "[ORCHESTRATOR] 📝 Detectada resolução de erro. Catalogando..." >&2
        # Chama auto-catalogação
        source "${BASH_SOURCE%/*}/auto-catalog.sh"
        auto_catalog_on_skill_complete "$skill_name" "$task_id"
    fi
}

# ============================================================================
# FUNÇÕES DE ESCRITA SEGURA (substituem as existentes)
# ============================================================================

orchestrator_safe_write() {
    local file_path="$1"
    local content="$2"
    local context="${3:-write operation}"
    
    # Valida antes de escrever
    if ! validate_coding_action "create" "$file_path" "$content" "$context"; then
        echo "[ORCHESTRATOR] ❌ Escrita bloqueada pela validação" >&2
        return 1
    fi
    
    # Prossegue com escrita
    echo "$content" > "$file_path"
    echo "[ORCHESTRATOR] ✅ Arquivo criado: $file_path" >&2
    return 0
}

orchestrator_safe_edit() {
    local file_path="$1"
    local old_string="$2"
    local new_string="$3"
    local context="${4:-edit operation}"
    
    # Valida antes de editar
    if ! validate_coding_action "edit" "$file_path" "$new_string" "$context"; then
        echo "[ORCHESTRATOR] ❌ Edição bloqueada pela validação" >&2
        return 1
    fi
    
    # Prossegue com edição
    sed -i "s/$old_string/$new_string/g" "$file_path"
    echo "[ORCHESTRATOR] ✅ Arquivo editado: $file_path" >&2
    return 0
}

orchestrator_safe_commit() {
    local commit_msg="$1"
    local files="$2"
    
    # Valida commit antes de executar
    if ! validate_pre_commit "$commit_msg" "$files"; then
        echo "[ORCHESTRATOR] ❌ Commit bloqueado pela validação" >&2
        return 1
    fi
    
    # Prossegue com commit
    git add $files
    git commit -m "$commit_msg"
    echo "[ORCHESTRATOR] ✅ Commit realizado" >&2
    return 0
}

# ============================================================================
# FLUXO PRINCIPAL ORQUESTRADOR (atualizado)
# ============================================================================

orchestrator_execute_task() {
    local task_id="$1"
    local task_description="$2"
    local agent_role="$3"
    
    # 1. Cria Context Passport
    local passport=$(passport_create "$task_id" "$agent_role")
    local passport_file=$(passport_save "$passport")
    
    echo "[ORCHESTRATOR] 📋 Context Passport criado: $passport_file" >&2
    
    # 2. Hook pré-codificação (KB search, backlog check)
    pre_coding_hook "$task_description" "$passport_file"
    
    # 3. Executa tarefa (simulação - código real varia por agente)
    echo "[ORCHESTRATOR] 🚀 Executando tarefa: $task_description" >&2
    
    # 4. Validações durante execução (via hooks nas funções de escrita)
    
    # 5. Hook pós-execução (catalogação automática)
    post_skill_hook "execution" "$task_id" "success"
    
    echo "[ORCHESTRATOR] ✅ Tarefa concluída: $task_id" >&2
}
```

---

## CLI Commands (aidev)

**Extensão do comando `aidev`**:

```bash
#!/bin/bash
# Trechos adicionais ao bin/aidev

case "$1" in
    # ... comandos existentes ...
    
    "validate")
        source "$LIB_DIR/validation-pipeline.sh"
        case "$2" in
            "commit")
                validate_pre_commit "$3" "$4"
                ;;
            "path")
                validate_safe_path "$3"
                echo "Path ${path}: $(validate_safe_path "$3" && echo '✅ SEGURO' || echo '❌ INSEGURO')"
                ;;
            "config")
                validate_config_file "$3"
                ;;
            *)
                echo "Uso: aidev validate [commit|path|config] <argumentos>"
                ;;
        esac
        ;;
    
    "backlog")
        source "$LIB_DIR/backlog.sh"
        case "$2" in
            "add")
                backlog_add_error "$3" "$4" "$5" "$6"
                ;;
            "list")
                echo "=== Erros Abertos ==="
                backlog_list_open_errors | jq -r '.[] | "[\(.severity | ascii_upcase)] \(.id): \(.title)"'
                echo ""
                echo "=== Tarefas Pendentes ==="
                backlog_list_pending_tasks | jq -r '.[] | "[\(.priority | ascii_upcase)] \(.id): \(.title)"'
                ;;
            "resolve")
                backlog_resolve_error "$3" "$4"
                ;;
            "stats")
                backlog_stats | jq -r '
                    "📊 Estatísticas do Backlog:",
                    "   Erros: \(.errors.open)/\(.errors.total) abertos (\(.errors.critical) críticos)",
                    "   Tarefas: \(.tasks.pending)/\(.tasks.total) pendentes"
                '
                ;;
            "export")
                backlog_export "${3:-json}"
                ;;
            *)
                echo "Uso: aidev backlog [add|list|resolve|stats|export]"
                ;;
        esac
        ;;
    
    "kb")
        source "$LIB_DIR/kb-search.sh"
        case "$2" in
            "search")
                kb_search "$3" "${4:-5}"
                ;;
            "lessons")
                echo "=== Lições Aprendidas ==="
                for file in .aidev/memory/kb/*.md; do
                    [ -e "$file" ] || continue
                    local title=$(grep "^# " "$file" | head -1)
                    echo "📄 $(basename "$file"): $title"
                done
                ;;
            *)
                echo "Uso: aidev kb [search|lessons] <argumentos>"
                ;;
        esac
        ;;
    
    "passport")
        source "$LIB_DIR/context-passport.sh"
        case "$2" in
            "create")
                local pp=$(passport_create "$3" "$4")
                passport_save "$pp"
                ;;
            "show")
                passport_load "$3" | jq .
                ;;
            "compact")
                local file=$(passport_load "$3" | jq -r '.file')
                passport_compact "$file" | jq .
                ;;
            *)
                echo "Uso: aidev passport [create|show|compact] <task_id>"
                ;;
        esac
        ;;
esac
```

---

## Configuração

**`.aidev/config/validation.conf`**:

```bash
# Modo de validação: warning | strict
VALIDATION_MODE=warning

# Tempo em dias antes de warning virar bloqueio
WARNING_TO_BLOCK_AFTER_DAYS=7

# Permite override com --force (registrado em auditoria)
OVERRIDE_ALLOWED=true

# Regras a serem validadas
ENFORCE_TDD=true
ENFORCE_COMMIT_PT=true
ENFORCE_COMMIT_FORMAT=true
ENFORCE_NO_EMOJI=true
ENFORCE_SAFE_PATHS=true

# Integrações
AUTO_BACKLOG_ERRORS=true
AUTO_CATALOG_LESSONS=true
USE_MCP_IF_AVAILABLE=true

# Limites
VALIDATION_MAX_RETRIES=5
VALIDATION_RETRY_DELAY=1
MAX_WARNINGS_BEFORE_BLOCK=3
```

---

## Cronograma de Implementação

### Sprint 1: Foundation (Semanas 1-2)
- [ ] Task 1.1: validators.sh
- [ ] Task 1.2: validation-engine.sh
- [ ] Task 2.1: Schema Context Passport
- [ ] Task 2.2: context-passport.sh
- [ ] Task 7.1: Documentação

### Sprint 2: Knowledge Management (Semanas 3-4)
- [ ] Task 3.1: error-detector.sh
- [ ] Task 3.2: auto-catalog.sh
- [ ] Task 4.1: kb-search.sh (com MCP)
- [ ] Task 4.2: Integração KB

### Sprint 3: Backlog & Pipeline (Semanas 5-6)
- [ ] Task 5.1: backlog.sh
- [ ] Task 5.2: CLI backlog
- [ ] Task 6.1: validation-pipeline.sh
- [ ] Task 6.2: Integração orchestration.sh

### Sprint 4: Testing & Polish (Semanas 7-8)
- [ ] Task 7.2: Testes de integração
- [ ] Configuração e tuning
- [ ] Documentação final
- [ ] Treinamento/adaptação

---

## Critérios de Sucesso

### Métricas Quantitativas
- ✅ 100% dos commits no formato `tipo(escopo): descrição`
- ✅ 95%+ dos commits em português (após período de adaptação)
- ✅ 90%+ dos erros resolvidos catalogados automaticamente
- ✅ 100% de consulta KB antes de codificação
- ✅ 0 bugs críticos perdidos (todos no backlog)
- ✅ 30%+ economia de tokens com reutilização de lições

### Métricas Qualitativas
- Zero regressões por erros já conhecidos
- Código consistente entre diferentes sessões
- Rastreabilidade completa de decisões
- Transparência nas validações (usuário entende o porquê)

---

## Notas de Implementação

### MCP Integration
O sistema é híbrido - funciona 100% sem MCPs, mas recomenda instalação:

```bash
# Sem MCPs: Busca local apenas (funciona, mas mais tokens)
[KB-SEARCH] ℹ️  MCPs não disponíveis. Instale para economizar tokens:
    - Basic Memory: npm install -g @anthropics/basic-memory
    - Serena: pip install serena-mcp
    💡 Sem MCPs, busca é local apenas (mais tokens consumidos)

# Com MCPs: Busca semântica e contexto de sessão
[KB-SEARCH] MCP Basic Memory: ✓ Tokens economizados com busca semântica
[KB-SEARCH] MCP Serena: ✓ Contexto de sessão recuperado
```

### Fallback Strategy
Cada validador tem fallback definido:
- `validate_commit_format` → fallback para `validate_portuguese_language`
- `validate_test_exists` → fallback para verificação de pasta `/tests`
- Se ambos falharem após 5 retries → escala para humano

### Estado Persistente
Todos os estados são JSON em `.aidev/state/`:
- `backlog.json`: Erros e tarefas
- `escalations.json`: Validações que falharam
- `passports/`: Context passports ativos
- `error-detector.json`: Erros detectados/resolvidos

---

## Próximos Passos

1. **Review deste documento** - Você revisa e aprova
2. **Criação das Sprints** - Quebrar em issues/tarefas
3. **Implementação Sprint 1** - Começar por validators e engine
4. **Testes Incrementais** - Validar cada componente
5. **Deploy Gradual** - Ativar feature por feature

**Documento pronto para implementação!** 🚀
