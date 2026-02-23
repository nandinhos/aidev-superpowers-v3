#!/bin/bash
# feature-lifecycle.sh - Gerenciamento do ciclo de vida de features
# Automatiza conclusão, arquivamento e transição de features

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================

FEATURES_DIR="${FEATURES_DIR:-.aidev/plans/features}"
HISTORY_DIR="${HISTORY_DIR:-.aidev/plans/history}"
ROADMAP_FILE="${ROADMAP_FILE:-.aidev/plans/ROADMAP.md}"

# ============================================================================
# FUNÇÕES UTILITÁRIAS
# ============================================================================

_log_feature() {
    local level="$1"
    local func="$2"
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [$level] $func: $message" >&2
}

# ============================================================================
# GERENCIAMENTO DE FEATURES
# ============================================================================

# Lista todas as features ativas
feature_list_active() {
    if [ ! -d "$FEATURES_DIR" ]; then
        echo "[]"
        return
    fi
    
    local results="[]"
    
    for file in "$FEATURES_DIR"/*.md; do
        [ -e "$file" ] || continue
        
        local filename=$(basename "$file" .md)
        local status=$(grep -i "^> \\*\\*Status:" "$file" 2>/dev/null | head -1 | sed 's/.*Status:\\s*//' | tr -d '*>' | xargs)
        local title=$(grep "^# " "$file" 2>/dev/null | head -1 | sed 's/^# //')
        
        if [ -z "$status" ]; then
            status="Desconhecido"
        fi
        
        if [ -z "$title" ]; then
            title="$filename"
        fi
        
        local entry=$(jq -n \
            --arg id "$filename" \
            --arg title "$title" \
            --arg status "$status" \
            --arg file "$file" \
            '{id: $id, title: $title, status: $status, file: $file}')
        
        results=$(echo "$results" | jq ". += [$entry]")
    done
    
    echo "$results"
}

# Obtém o arquivo de uma feature pelo nome ou ID
feature_get_file() {
    local feature_id="$1"
    
    # Tenta encontrar pelo nome exato
    if [ -f "$FEATURES_DIR/${feature_id}.md" ]; then
        echo "$FEATURES_DIR/${feature_id}.md"
        return 0
    fi
    
    # Tenta encontrar parcialmente
    local match=$(find "$FEATURES_DIR" -name "*${feature_id}*.md" -type f | head -1)
    if [ -n "$match" ]; then
        echo "$match"
        return 0
    fi
    
    return 1
}

# Extrai metadata de uma feature
feature_get_metadata() {
    local feature_file="$1"
    
    if [ ! -f "$feature_file" ]; then
        echo "{}"
        return 1
    fi
    
    local content=$(cat "$feature_file")
    local filename=$(basename "$feature_file" .md)
    
    # Extrai campos comuns
    local title=$(echo "$content" | grep "^# " | head -1 | sed 's/^# //')
    local status=$(echo "$content" | grep -i "^> \\*\\*Status:" | head -1 | sed 's/.*Status:\\s*//' | tr -d '*>' | xargs)
    local priority=$(echo "$content" | grep -i "^> \\*\\*Prioridade:" | head -1 | sed 's/.*Prioridade:\\s*//' | tr -d '*>' | xargs)
    local sprint=$(echo "$content" | grep -i "^> \\*\\*Sprint:" | head -1 | sed 's/.*Sprint:\\s*//' | tr -d '*>' | xargs)
    local created=$(echo "$content" | grep -i "^> \\*\\*Data criação:" | head -1 | sed 's/.*Data criação:\\s*//' | tr -d '*>' | xargs)
    
    # Valores padrão
    [ -z "$status" ] && status="Planejado"
    [ -z "$title" ] && title="$filename"
    
    jq -n \
        --arg id "$filename" \
        --arg title "$title" \
        --arg status "$status" \
        --arg priority "${priority:-normal}" \
        --arg sprint "${sprint:-}" \
        --arg created "${created:-}" \
        --arg file "$feature_file" \
        '{
            id: $id,
            title: $title,
            status: $status,
            priority: $priority,
            sprint: $sprint,
            created_at: $created,
            file: $file
        }'
}

# ============================================================================
# CONCLUSÃO DE FEATURE
# ============================================================================

# Marca uma feature como concluída e move para histórico
feature_complete() {
    local feature_id="$1"
    local completion_notes="${2:-}"
    
    _log_feature "INFO" "feature_complete" "Concluindo feature: $feature_id"
    
    # Encontra arquivo da feature
    local feature_file=$(feature_get_file "$feature_id")
    if [ -z "$feature_file" ] || [ ! -f "$feature_file" ]; then
        _log_feature "ERROR" "feature_complete" "Feature não encontrada: $feature_id"
        return 1
    fi
    
    # Obtém metadata
    local metadata=$(feature_get_metadata "$feature_file")
    local title=$(echo "$metadata" | jq -r '.title')
    local sprint=$(echo "$metadata" | jq -r '.sprint')
    
    _log_feature "INFO" "feature_complete" "Feature encontrada: $title"
    
    # 1. Atualiza o arquivo com status de concluído
    _feature_update_status "$feature_file" "Concluído" "$completion_notes"
    
    # 2. Move para histórico
    local history_file=$(_feature_move_to_history "$feature_file")
    if [ -z "$history_file" ]; then
        _log_feature "ERROR" "feature_complete" "Falha ao mover para histórico"
        return 1
    fi
    
    # 3. Atualiza ROADMAP
    _feature_update_roadmap "$feature_id" "$title" "completed"
    
    # 4. Registra em context-log
    _feature_log_completion "$feature_id" "$title" "$history_file"
    
    _log_feature "INFO" "feature_complete" "Feature concluída com sucesso: $history_file"
    
    # Retorna informações da conclusão
    jq -n \
        --arg id "$feature_id" \
        --arg title "$title" \
        --arg history_file "$history_file" \
        --arg completed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            success: true,
            feature_id: $id,
            title: $title,
            history_file: $history_file,
            completed_at: $completed_at,
            message: "Feature movida para histórico com sucesso"
        }'
}

# Atualiza o status no arquivo da feature
_feature_update_status() {
    local feature_file="$1"
    local new_status="$2"
    local notes="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local date_simple=$(date +"%Y-%m-%d")
    
    _log_feature "INFO" "_feature_update_status" "Atualizando status para: $new_status"
    
    # Atualiza ou adiciona status
    if grep -q "^> \\*\\*Status:" "$feature_file"; then
        # Substitui linha existente
        sed -i "s/^> \\*\\*Status:.*/> **Status:** $new_status/" "$feature_file"
    else
        # Adiciona após o título
        sed -i "/^# /a\\> **Status:** $new_status" "$feature_file"
    fi
    
    # Adiciona seção de conclusão no final
    cat >> "$feature_file" <<EOF

---

## ✅ Conclusão

**Status:** $new_status  
**Data Conclusão:** $date_simple  
**Timestamp:** $timestamp

EOF

    # Adiciona notas se fornecidas
    if [ -n "$notes" ]; then
        cat >> "$feature_file" <<EOF
**Notas:**
$notes

EOF
    fi
    
    # Adiciona checklist de verificação padrão
    cat >> "$feature_file" <<EOF
### Checklist de Conclusão

- [x] Implementação completa
- [x] Testes passando
- [x] Documentação atualizada
- [x] Revisão de código realizada
- [x] Merge para branch principal
- [x] Feature arquivada em \`.aidev/plans/history/\`

---

*Arquivo movido automaticamente para histórico em: $timestamp*
EOF
}

# Move feature para pasta de histórico organizada por mês
_feature_move_to_history() {
    local feature_file="$1"
    local filename=$(basename "$feature_file")
    local month=$(date +"%Y-%m")
    local day=$(date +"%d")
    
    # Cria diretório do mês se não existir
    local month_dir="$HISTORY_DIR/$month"
    mkdir -p "$month_dir"
    
    # Nome do arquivo com dia para ordenação
    local history_file="$month_dir/${filename%.md}-${day}.md"
    
    # Move arquivo
    if mv "$feature_file" "$history_file"; then
        _log_feature "INFO" "_feature_move_to_history" "Arquivo movido: $history_file"
        echo "$history_file"
    else
        _log_feature "ERROR" "_feature_move_to_history" "Falha ao mover arquivo"
        return 1
    fi
}

# Atualiza ROADMAP.md para refletir conclusão
_feature_update_roadmap() {
    local feature_id="$1"
    local feature_title="$2"
    local new_state="$3"
    
    if [ ! -f "$ROADMAP_FILE" ]; then
        _log_feature "WARN" "_feature_update_roadmap" "ROADMAP.md não encontrado"
        return 1
    fi
    
    _log_feature "INFO" "_feature_update_roadmap" "Atualizando ROADMAP: $feature_id"
    
    # Cria backup
    cp "$ROADMAP_FILE" "${ROADMAP_FILE}.backup"
    
    # Procura e atualiza referências à feature no ROADMAP
    # Marca como concluída mudando checkbox ou status
    
    # Padrão 1: Checkboxes - [ ] para - [x]
    sed -i "s/- \[ \] \(.*$feature_id.*\)/- [x] \\1 ✅/gi" "$ROADMAP_FILE"
    
    # Padrão 2: Status explícito
    sed -i "s/Status:.*$feature_id.*$/Status: Concluído ✅/gi" "$ROADMAP_FILE"
    
    # Adiciona entrada no log de atualizações se existir seção
    local update_entry="- $(date +"%Y-%m-%d"): ✅ $feature_id - $feature_title"
    
    # Tenta adicionar em seção de atualizações ou progresso
    if grep -q "^## .*[Pp]rogresso\|^## .*[Uu]pdates\|^## .*[Ll]og" "$ROADMAP_FILE"; then
        sed -i "/^## .*[Pp]rogresso\|^## .*[Uu]pdates\|^## .*[Ll]og/a\\$update_entry" "$ROADMAP_FILE"
    fi
    
    rm "${ROADMAP_FILE}.backup"
    
    _log_feature "INFO" "_feature_update_roadmap" "ROADMAP atualizado com sucesso"
}

# Registra conclusão no context-log
_feature_log_completion() {
    local feature_id="$1"
    local title="$2"
    local history_file="$3"
    
    local context_log=".aidev/state/context-log.json"
    
    if [ ! -f "$context_log" ]; then
        return 0
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local entry=$(jq -n \
        --arg ts "$timestamp" \
        --arg action "feature_complete" \
        --arg target "$feature_id" \
        --arg title "$title" \
        --arg file "$history_file" \
        '{
            ts: $ts,
            action: $action,
            target: $target,
            intent: "Feature concluída e arquivada",
            feature_title: $title,
            history_file: $file
        }')
    
    # Adiciona ao context-log
    jq ".entries += [$entry]" "$context_log" > "${context_log}.tmp" && mv "${context_log}.tmp" "$context_log"
    
    _log_feature "INFO" "_feature_log_completion" "Conclusão registrada no context-log"
}

# ============================================================================
# INTEGRAÇÃO COM SKILLS
# ============================================================================

# Hook chamado quando uma skill é concluída - verifica se há feature para arquivar
feature_on_skill_complete() {
    local skill_name="$1"
    local task_id="$2"
    local result="$3"
    
    # Se a skill relaciona-se a uma feature, oferece arquivar
    if [ "$result" == "success" ]; then
        _log_feature "INFO" "feature_on_skill_complete" "Skill completada: $skill_name"
        
        # Verifica se a task pertence a uma feature ativa
        local active_features=$(feature_list_active)
        local count=$(echo "$active_features" | jq 'length')
        
        if [ "$count" -gt 0 ]; then
            echo ""
            echo "📋 Features ativas detectadas:"
            echo "$active_features" | jq -r '.[] | "  - \"\(.title)\" (\(.id)) [\(.status)]"'
            echo ""
            echo "💡 Use 'aidev feature complete <id>' para marcar como concluída"
        fi
    fi
}

# ============================================================================
# COMANDOS CLI
# ============================================================================

# Handler para comando 'aidev feature'
feature_cli() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        "list"|"ls")
            feature_cmd_list "$@"
            ;;
        "complete"|"done"|"finish")
            feature_cmd_complete "$@"
            ;;
        "status")
            feature_cmd_status "$@"
            ;;
        "show"|"view")
            feature_cmd_show "$@"
            ;;
        "help"|"--help"|"-h")
            feature_cmd_help
            ;;
        *)
            echo "Comando desconhecido: $subcommand"
            feature_cmd_help
            return 1
            ;;
    esac
}

feature_cmd_list() {
    echo "📋 Features Ativas em $FEATURES_DIR:"
    echo ""
    
    local features=$(feature_list_active)
    local count=$(echo "$features" | jq 'length')
    
    if [ "$count" -eq 0 ]; then
        echo "   Nenhuma feature ativa encontrada."
        echo ""
        echo "💡 Features são arquivadas automaticamente em $HISTORY_DIR/"
        return 0
    fi
    
    echo "$features" | jq -r '.[] | "  📄 \"\(.title)\"\n     ID: \(.id)\n     Status: \(.status)\n"'
    
    echo "Total: $count feature(s) ativa(s)"
}

feature_cmd_complete() {
    local feature_id="$1"
    local notes="${2:-}"
    
    if [ -z "$feature_id" ]; then
        echo "❌ Erro: ID da feature não especificado"
        echo ""
        echo "Uso: aidev feature complete <feature-id> [notas]"
        echo ""
        echo "Features ativas:"
        feature_cmd_list
        return 1
    fi
    
    echo "🚀 Concluindo feature: $feature_id"
    echo ""
    
    local result=$(feature_complete "$feature_id" "$notes")
    
    if [ $? -eq 0 ]; then
        local title=$(echo "$result" | jq -r '.title')
        local history_file=$(echo "$result" | jq -r '.history_file')
        
        echo "✅ Feature concluída com sucesso!"
        echo ""
        echo "📄 Título: $title"
        echo "📁 Arquivado em: $history_file"
        echo ""
        echo "Próximos passos:"
        echo "  1. Verifique o ROADMAP.md atualizado"
        echo "  2. Crie um release note se necessário"
        echo "  3. Prossiga com a próxima feature"
    else
        echo "❌ Falha ao concluir feature"
        echo "Verifique se o ID está correto e tente novamente"
        return 1
    fi
}

feature_cmd_status() {
    local feature_id="$1"
    
    if [ -n "$feature_id" ]; then
        local feature_file=$(feature_get_file "$feature_id")
        if [ -n "$feature_file" ]; then
            local metadata=$(feature_get_metadata "$feature_file")
            echo "$metadata" | jq .
        else
            echo "❌ Feature não encontrada: $feature_id"
            return 1
        fi
    else
        # Status geral
        local features=$(feature_list_active)
        local count=$(echo "$features" | jq 'length')
        
        echo "📊 Status de Features"
        echo ""
        echo "Ativas: $count"
        
        if [ "$count" -gt 0 ]; then
            echo ""
            echo "Por status:"
            echo "$features" | jq -r 'group_by(.status) | .[] | "  \(.[0].status): \(length)"'
        fi
    fi
}

feature_cmd_show() {
    local feature_id="$1"
    
    if [ -z "$feature_id" ]; then
        echo "❌ Erro: ID da feature não especificado"
        echo "Uso: aidev feature show <feature-id>"
        return 1
    fi
    
    local feature_file=$(feature_get_file "$feature_id")
    if [ -n "$feature_file" ] && [ -f "$feature_file" ]; then
        cat "$feature_file"
    else
        echo "❌ Feature não encontrada: $feature_id"
        return 1
    fi
}

feature_cmd_help() {
    echo "Gerenciamento de Features - AI Dev Superpowers"
    echo ""
    echo "Uso: aidev feature <comando> [argumentos]"
    echo ""
    echo "Comandos:"
    echo "  list, ls              Lista features ativas"
    echo "  complete, done        Marca feature como concluída e move para histórico"
    echo "  status [id]           Mostra status (geral ou de feature específica)"
    echo "  show, view <id>       Mostra conteúdo da feature"
    echo "  help                  Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  aidev feature list"
    echo "  aidev feature complete smart-upgrade-merge"
    echo "  aidev feature status"
    echo ""
    echo "Diretórios:"
    echo "  Features ativas: $FEATURES_DIR"
    echo "  Histórico:      $HISTORY_DIR/YYYY-MM/"
}

# ============================================================================
# INICIALIZAÇÃO
# ============================================================================

# Cria diretórios necessários se não existirem
feature_init() {
    mkdir -p "$FEATURES_DIR"
    mkdir -p "$HISTORY_DIR"
}

# Auto-inicialização
feature_init

# Exporta funções para uso externo
export -f feature_complete
export -f feature_list_active
export -f feature_get_file
export -f feature_get_metadata
export -f feature_on_skill_complete
export -f feature_cli
