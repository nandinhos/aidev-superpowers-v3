#!/bin/bash
# validation-engine.sh - Engine de validação com retry e fallback
# Implementa política de 5 tentativas com backoff e escalonamento humano

# Configurações
VALIDATION_MAX_RETRIES=5
VALIDATION_RETRY_DELAY=1
VALIDATION_MODE="${VALIDATION_MODE:-warning}"  # warning | strict

# ============================================================================
# VALIDAÇÃO COM RETRY
# ============================================================================
validation_with_retry() {
    local validator="$1"
    local input="$2"
    local max_retries="${3:-$VALIDATION_MAX_RETRIES}"
    local attempt=1
    
    log_validation "INFO" "validation_with_retry" "Iniciando validação: $validator (max $max_retries tentativas)"
    
    while [ $attempt -le $max_retries ]; do
        # Tenta validação
        if $validator "$input" 2>/dev/null; then
            log_validation "INFO" "validation_with_retry" "✅ Validação passou na tentativa $attempt"
            return 0
        fi
        
        # Falhou - log e tenta novamente
        if [ $attempt -lt $max_retries ]; then
            log_validation "WARN" "validation_with_retry" "⚠️  Tentativa $attempt/$max_retries falhou: $validator. Retentando em ${VALIDATION_RETRY_DELAY}s..."
            sleep $VALIDATION_RETRY_DELAY
        else
            log_validation "ERROR" "validation_with_retry" "❌ Todas as $max_retries tentativas falharam: $validator"
        fi
        
        ((attempt++))
    done
    
    return 1
}

# ============================================================================
# VALIDAÇÃO COM FALLBACK
# ============================================================================
validation_with_fallback() {
    local primary_validator="$1"
    local fallback_validator="$2"
    local input="$3"
    local context="$4"
    
    log_validation "INFO" "validation_with_fallback" "🔄 Iniciando validação com fallback"
    log_validation "INFO" "validation_with_fallback" "   Primária: $primary_validator"
    log_validation "INFO" "validation_with_fallback" "   Fallback: $fallback_validator"
    
    # Tenta validação primária com retry
    if validation_with_retry "$primary_validator" "$input"; then
        log_validation "INFO" "validation_with_fallback" "✅ Validação primária bem-sucedida"
        return 0
    fi
    
    log_validation "WARN" "validation_with_fallback" "⚠️  Primária falhou, tentando fallback..."
    
    # Fallback: tenta abordagem alternativa
    if validation_with_retry "$fallback_validator" "$input"; then
        log_validation "INFO" "validation_with_fallback" "✅ Fallback bem-sucedido"
        return 0
    fi
    
    # Ambas falharam - escalar para humano
    log_validation "ERROR" "validation_with_fallback" "🚨 Primária e fallback falharam. Escalonando..."
    _log_escalation "$primary_validator" "$fallback_validator" "$input" "$context"
    return 1
}

# ============================================================================
# LOG DE ESCALONAMENTO
# ============================================================================
_log_escalation() {
    local primary="$1"
    local fallback="$2"
    local input="$3"
    local context="$4"
    
    local log_file=".aidev/state/escalations.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local id="esc-$(date +%s%N)"
    
    # Cria diretório se não existir
    mkdir -p "$(dirname "$log_file")"
    mkdir -p ".aidev/state/sprints/handoffs/pending"
    
    # Cria entrada de escalonamento
    local entry=$(cat <<EOF
{
  "id": "$id",
  "timestamp": "$timestamp",
  "primary_validator": "$primary",
  "fallback_validator": "$fallback",
  "input": $(echo "$input" | jq -R -s .),
  "context": "$context",
  "status": "pending_human_review",
  "auto_retry_count": $VALIDATION_MAX_RETRIES,
  "type": "validation_failure"
}
EOF
)
    
    # Salva no arquivo de escalations
    if [ -f "$log_file" ]; then
        jq ". += [$entry]" "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
    else
        echo "[$entry]" > "$log_file"
    fi
    
    # Cria handoff para PO
    local handoff_file=".aidev/state/sprints/handoffs/pending/${id}.md"
    cat > "$handoff_file" <<EOF
# 🚨 Handoff: Falha de Validação

**ID**: $id  
**Timestamp**: $timestamp  
**Tipo**: Validação Automática Falhou

## Contexto
Tentativa de validação falhou após $VALIDATION_MAX_RETRIES retries e fallback.

## Validadores
- **Primário**: $primary
- **Fallback**: $fallback

## Input
\`\`\`
$input
\`\`\`

## Contexto Adicional
$context

## Possíveis Causas
1. Input realmente inválido (ação correta)
2. Falso positivo do validador
3. Bug na lógica de validação
4. Caso edge não coberto

## Ações Sugeridas
- [ ] Revisar input manualmente
- [ ] Ajustar validador se for falso positivo
- [ ] Aprovar/rejeitar ação
- [ ] Documentar decisão

---
*Gerado automaticamente pelo validation-engine.sh*
EOF
    
    log_validation "ESCALATION" "_log_escalation" "📝 Handoff criado: $handoff_file"
    echo "🚨 ESCALONAMENTO: Revisão humana necessária"
    echo "   ID: $id"
    echo "   Handoff: $handoff_file"
}

# ============================================================================
# DECISÃO WARNING vs BLOQUEIO
# ============================================================================
validation_enforce() {
    local validator="$1"
    local input="$2"
    local description="$3"
    local force="${4:-false}"
    
    # Tenta validação
    if $validator "$input" 2>/dev/null; then
        return 0
    fi
    
    # Falhou - decide ação baseado no modo
    case "$VALIDATION_MODE" in
        "strict")
            if [ "$force" == "true" ]; then
                echo "⚠️  OVERRIDE: $description"
                echo "    Validação ignorada com --force (registrado em auditoria)"
                _log_validation_override "$validator" "$input" "$description"
                return 0
            else
                echo "❌ BLOQUEADO: $description"
                echo "    Validação falhou: $validator"
                echo "    Use --force para ignorar (com cuidado)"
                return 1
            fi
            ;;
        "warning"|*)
            echo "⚠️  WARNING: $description"
            echo "    Sugestão: Corrija antes de prosseguir"
            echo "    Validação: $validator"
            echo "    Modo atual: WARNING (não bloqueia)"
            log_validation "WARN" "validation_enforce" "Warning emitido: $description"
            # Em modo warning, retorna 0 mas loga
            return 0
            ;;
    esac
}

# ============================================================================
# LOG DE OVERRIDE
# ============================================================================
_log_validation_override() {
    local validator="$1"
    local input="$2"
    local description="$3"
    
    local log_file=".aidev/state/validation_overrides.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    mkdir -p "$(dirname "$log_file")"
    
    local entry=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "validator": "$validator",
  "description": "$description",
  "input": $(echo "$input" | jq -R -s .)
}
EOF
)
    
    if [ -f "$log_file" ]; then
        jq ". += [$entry]" "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
    else
        echo "[$entry]" > "$log_file"
    fi
    
    log_validation "AUDIT" "_log_validation_override" "Override registrado: $description"
}

# ============================================================================
# PIPELINE DE VALIDAÇÃO
# ============================================================================
validation_pipeline() {
    local description="$1"
    shift
    local validators=("$@")
    local failed=0
    local warnings=0
    
    echo "🔍 Pipeline de Validação: $description"
    echo "   ${#validators[@]} validadores configurados"
    echo ""
    
    for validator_info in "${validators[@]}"; do
        # Formato: "nome|input|descricao"
        IFS='|' read -r validator input validator_desc <<< "$validator_info"
        
        echo "   ▶️  $validator_desc"
        
        if validation_with_retry "$validator" "$input"; then
            echo "      ✅ PASS"
        else
            echo "      ❌ FAIL"
            ((failed++))
            
            # Em modo strict, falha imediatamente
            if [ "$VALIDATION_MODE" == "strict" ]; then
                echo ""
                echo "❌ PIPELINE BLOQUEADO: $validator_desc falhou"
                return 1
            fi
        fi
    done
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo "✅ PIPELINE COMPLETO: Todas as validações passaram"
        return 0
    else
        echo "⚠️  PIPELINE COMPLETO COM AVISOS: $failed falha(s)"
        return 0
    fi
}

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================
set_validation_mode() {
    local mode="$1"
    
    case "$mode" in
        "strict"|"warning")
            VALIDATION_MODE="$mode"
            echo "✅ Modo de validação alterado para: $mode"
            ;;
        *)
            echo "❌ Modo inválido. Use: strict ou warning"
            return 1
            ;;
    esac
}

get_validation_mode() {
    echo "$VALIDATION_MODE"
}

# ============================================================================
# ESTATÍSTICAS
# ============================================================================
validation_stats() {
    local log_file=".aidev/state/escalations.json"
    
    echo "📊 Estatísticas de Validação"
    echo "═══════════════════════════════════════"
    echo "Modo atual: $VALIDATION_MODE"
    echo "Max retries: $VALIDATION_MAX_RETRIES"
    echo "Retry delay: ${VALIDATION_RETRY_DELAY}s"
    echo ""
    
    if [ -f "$log_file" ]; then
        local total=$(jq 'length' "$log_file")
        local pending=$(jq '[.[] | select(.status == "pending_human_review")] | length' "$log_file")
        local resolved=$(jq '[.[] | select(.status == "resolved")] | length' "$log_file")
        
        echo "Escalonamentos:"
        echo "  Total: $total"
        echo "  Pendentes: $pending"
        echo "  Resolvidos: $resolved"
    else
        echo "Escalonamentos: Nenhum registrado"
    fi
}

# ============================================================================
# EXPORTAÇÃO
# ============================================================================
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Foi sourced
    :
else
    # Executado diretamente
    echo "validation-engine.sh - Engine de Validação com Retry"
    echo ""
    echo "Funções disponíveis:"
    echo "  validation_with_retry <validator> <input> [max_retries]"
    echo "  validation_with_fallback <primary> <fallback> <input> <context>"
    echo "  validation_enforce <validator> <input> <description> [force]"
    echo "  validation_pipeline <desc> <validator1|input1|desc1> ..."
    echo "  set_validation_mode <strict|warning>"
    echo "  validation_stats"
    echo ""
    echo "Modo atual: $VALIDATION_MODE"
fi
