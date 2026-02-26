#!/usr/bin/env bash
# rules-dashboard.sh — Dashboard de compliance do Rules Engine
# Parte do Rules Engine (Sprint 3: Sincronização + Dashboard)
#
# Uso:
#   source .aidev/engine/rules-dashboard.sh
#   rules_dashboard_show              # exibe dashboard da sessão atual
#   rules_dashboard_record <tipo> <regra> <resultado>  # registra evento
#   rules_dashboard_summary [n_days]  # resumo histórico (padrão: 7 dias)
#   rules_dashboard_reset             # reseta métricas da sessão
#
# Eventos registrados automaticamente por:
#   - commit-msg hook (via rules-validator.sh)
#   - rules-dedup.sh (detecção de arquivos fora do canônico)
#   - rules-loader.sh (carga de regras por sessão)

set -euo pipefail

RULES_DASHBOARD_VERSION="1.0.0"
AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="$AIDEV_ROOT/state"
SESSION_LOG="$STATE_DIR/compliance-session.log"
HISTORY_LOG="$STATE_DIR/compliance-history.log"
DASHBOARD_FILE="$STATE_DIR/compliance-dashboard.md"

# Formato de linha no log:
# <timestamp_iso> TAB <tipo> TAB <regra> TAB <resultado> TAB <contexto>
# tipo: commit | file-creation | code-edit | rules-loaded | doc-sync
# resultado: pass | warning | error | info

# ============================================================================
# rules_dashboard_record <tipo> <regra> <resultado> [contexto]
# Registra um evento de compliance no log da sessão
# ============================================================================
rules_dashboard_record() {
    local tipo="$1"
    local regra="$2"
    local resultado="$3"
    local contexto="${4:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    mkdir -p "$STATE_DIR"

    printf "%s\t%s\t%s\t%s\t%s\n" \
        "$timestamp" "$tipo" "$regra" "$resultado" "$contexto" \
        >> "$SESSION_LOG"
}

# ============================================================================
# rules_dashboard_show
# Exibe dashboard de compliance da sessão atual
# ============================================================================
rules_dashboard_show() {
    echo "=== Rules Engine — Dashboard de Compliance ==="
    echo ""

    # Regras carregadas na sessão
    if [ -f "$SESSION_LOG" ]; then
        local total pass warning error info
        total=$(wc -l < "$SESSION_LOG" 2>/dev/null || echo 0)
        pass=$(grep -c $'\tpass\t' "$SESSION_LOG" 2>/dev/null || echo 0)
        warning=$(grep -c $'\twarning\t' "$SESSION_LOG" 2>/dev/null || echo 0)
        error=$(grep -c $'\terror\t' "$SESSION_LOG" 2>/dev/null || echo 0)
        info=$(grep -c $'\tinfo\t' "$SESSION_LOG" 2>/dev/null || echo 0)

        echo "Sessão atual:"
        echo "  Eventos registrados: $total"
        echo "  ✓ pass:              $pass"
        echo "  ⚠ warning:           $warning"
        echo "  ✗ error:             $error"
        echo "  ℹ info:              $info"
        echo ""

        # Compliance rate
        local checks=$((pass + warning + error))
        if [ "$checks" -gt 0 ]; then
            local rate=$(( (pass * 100) / checks ))
            echo "  Taxa de compliance: ${rate}%"
            echo ""
        fi

        # Regras mais violadas
        if [ "$((warning + error))" -gt 0 ]; then
            echo "Violações desta sessão:"
            grep -E $'\t(warning|error)\t' "$SESSION_LOG" 2>/dev/null \
                | awk -F'\t' '{print "  ["$4"] "$3" — "$5}' \
                | head -10
            echo ""
        fi

        # Últimos eventos
        if [ "$total" -gt 0 ]; then
            echo "Últimos eventos:"
            tail -5 "$SESSION_LOG" \
                | awk -F'\t' '{
                    icon = ($4 == "pass") ? "✓" : (($4 == "warning") ? "⚠" : (($4 == "error") ? "✗" : "ℹ"))
                    print "  " icon " " $2 " | " $3 " | " $5
                  }'
            echo ""
        fi
    else
        echo "  Nenhum evento registrado nesta sessão."
        echo "  Os eventos são registrados automaticamente pelos hooks e validadores."
        echo ""
    fi

    # Histórico
    _rules_dashboard_show_history 7
}

# ============================================================================
# _rules_dashboard_show_history <n_days>
# Exibe resumo do histórico de N dias
# ============================================================================
_rules_dashboard_show_history() {
    local n_days="${1:-7}"

    if [ ! -f "$HISTORY_LOG" ]; then
        echo "Histórico: sem dados anteriores."
        return 0
    fi

    local since
    since=$(date -u -d "-${n_days} days" +"%Y-%m-%d" 2>/dev/null \
            || date -u -v"-${n_days}d" +"%Y-%m-%d" 2>/dev/null \
            || echo "1970-01-01")

    local h_total h_pass h_error h_warning
    h_total=$(awk -F'\t' -v since="$since" '$1 >= since' "$HISTORY_LOG" | wc -l)
    h_pass=$(awk -F'\t' -v since="$since" '$1 >= since && $4 == "pass"' "$HISTORY_LOG" | wc -l)
    h_warning=$(awk -F'\t' -v since="$since" '$1 >= since && $4 == "warning"' "$HISTORY_LOG" | wc -l)
    h_error=$(awk -F'\t' -v since="$since" '$1 >= since && $4 == "error"' "$HISTORY_LOG" | wc -l)

    echo "Histórico (últimos ${n_days} dias):"
    echo "  Eventos: $h_total | ✓ $h_pass | ⚠ $h_warning | ✗ $h_error"

    # Regra mais violada no histórico
    if [ "$((h_warning + h_error))" -gt 0 ]; then
        local top_violation
        top_violation=$(awk -F'\t' -v since="$since" \
            '$1 >= since && ($4 == "warning" || $4 == "error") {print $3}' \
            "$HISTORY_LOG" \
            | sort | uniq -c | sort -rn | head -1 \
            | awk '{$1=$1; print}')
        if [ -n "$top_violation" ]; then
            echo "  Regra mais violada: $top_violation"
        fi
    fi
    echo ""
}

# ============================================================================
# rules_dashboard_summary [n_days]
# Gera relatório markdown e exibe no terminal
# ============================================================================
rules_dashboard_summary() {
    local n_days="${1:-7}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Flush sessão atual para histórico
    rules_dashboard_flush

    # Exibir dashboard
    rules_dashboard_show

    # Gerar arquivo markdown
    {
        echo "# Rules Engine — Dashboard de Compliance"
        echo ""
        echo "**Gerado em**: $timestamp"
        echo "**Período**: últimos $n_days dias"
        echo ""
        echo "---"
        echo ""

        if [ -f "$HISTORY_LOG" ]; then
            local since
            since=$(date -u -d "-${n_days} days" +"%Y-%m-%d" 2>/dev/null \
                    || date -u -v"-${n_days}d" +"%Y-%m-%d" 2>/dev/null \
                    || echo "1970-01-01")

            echo "## Métricas"
            echo ""
            echo "| Métrica | Valor |"
            echo "|---------|-------|"

            local h_pass h_warning h_error h_total rate
            h_total=$(awk -F'\t' -v s="$since" '$1 >= s' "$HISTORY_LOG" | wc -l)
            h_pass=$(awk -F'\t' -v s="$since" '$1 >= s && $4 == "pass"' "$HISTORY_LOG" | wc -l)
            h_warning=$(awk -F'\t' -v s="$since" '$1 >= s && $4 == "warning"' "$HISTORY_LOG" | wc -l)
            h_error=$(awk -F'\t' -v s="$since" '$1 >= s && $4 == "error"' "$HISTORY_LOG" | wc -l)

            local checks=$((h_pass + h_warning + h_error))
            rate=0
            [ "$checks" -gt 0 ] && rate=$(( (h_pass * 100) / checks ))

            echo "| Total de eventos | $h_total |"
            echo "| Pass | $h_pass |"
            echo "| Warning | $h_warning |"
            echo "| Error | $h_error |"
            echo "| Taxa de compliance | ${rate}% |"
            echo ""

            # Top violações
            if [ "$((h_warning + h_error))" -gt 0 ]; then
                echo "## Top Violações"
                echo ""
                echo "| # | Regra | Ocorrências |"
                echo "|---|-------|------------|"
                awk -F'\t' -v s="$since" \
                    '$1 >= s && ($4 == "warning" || $4 == "error") {print $3}' \
                    "$HISTORY_LOG" \
                    | sort | uniq -c | sort -rn | head -10 \
                    | awk 'NR==1{i=1} {print "| " NR " | " $2 " | " $1 " |"}'
                echo ""
            fi
        else
            echo "Sem dados históricos disponíveis."
        fi

        echo "---"
        echo ""
        echo "*Gerado por: rules-dashboard.sh v$RULES_DASHBOARD_VERSION*"
    } > "$DASHBOARD_FILE"

    echo "Relatório salvo: $DASHBOARD_FILE"
}

# ============================================================================
# rules_dashboard_flush
# Move eventos da sessão atual para o histórico permanente
# ============================================================================
rules_dashboard_flush() {
    if [ -f "$SESSION_LOG" ] && [ -s "$SESSION_LOG" ]; then
        cat "$SESSION_LOG" >> "$HISTORY_LOG"
        rm -f "$SESSION_LOG"
        echo "✓ Sessão persistida no histórico."
    fi
}

# ============================================================================
# rules_dashboard_reset
# Limpa log da sessão atual (sem afetar histórico)
# ============================================================================
rules_dashboard_reset() {
    rm -f "$SESSION_LOG"
    echo "✓ Métricas da sessão resetadas."
}

# Executar diretamente se chamado como script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    CMD="${1:-show}"
    shift || true
    case "$CMD" in
        show)    rules_dashboard_show ;;
        record)  rules_dashboard_record "${1:-}" "${2:-}" "${3:-}" "${4:-}" ;;
        summary) rules_dashboard_summary "${1:-7}" ;;
        flush)   rules_dashboard_flush ;;
        reset)   rules_dashboard_reset ;;
        *)
            echo "Uso: $0 {show|record|summary|flush|reset} [args]" >&2
            exit 1
            ;;
    esac
fi
