#!/usr/bin/env bash
# rules-doc-sync.sh — Sincroniza regras de stack com documentação oficial via Context7 MCP
# Parte do Rules Engine (Sprint 3: Sincronização + Dashboard)
#
# Uso:
#   source .aidev/engine/rules-doc-sync.sh
#   rules_doc_sync_prepare [stack]    # prepara lista de regras para validação
#   rules_doc_sync_report             # gera relatório de regras potencialmente desatualizadas
#   rules_doc_sync_run [stack]        # fluxo completo (requer LLM com Context7 MCP ativo)
#
# Dependências: Context7 MCP (resolve-library-id, get-library-docs)
# Saída: .aidev/state/doc-sync-report.md

set -euo pipefail

RULES_DOC_SYNC_VERSION="1.0.0"
AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RULES_DIR="$AIDEV_ROOT/rules"
TAXONOMY_FILE="$AIDEV_ROOT/config/rules-taxonomy.yaml"
DOC_SYNC_REPORT="$AIDEV_ROOT/state/doc-sync-report.md"
DOC_SYNC_LOG="$AIDEV_ROOT/state/doc-sync.log"

# ============================================================================
# rules_doc_sync_prepare [stack]
# Extrai regras de stack do arquivo .md e gera checklist de validação Context7
# ============================================================================
rules_doc_sync_prepare() {
    local stack="${1:-}"
    local rules_file=""

    if [ -z "$stack" ]; then
        # Auto-detectar stack
        if [ -f "$AIDEV_ROOT/engine/rules-loader.sh" ]; then
            # shellcheck source=/dev/null
            source "$AIDEV_ROOT/engine/rules-loader.sh"
            stack=$(rules_detect_stack "$(pwd)")
        else
            stack="generic"
        fi
    fi

    # Mapear stack para arquivo de regras
    case "$stack" in
        livewire|laravel) rules_file="$RULES_DIR/livewire.md" ;;
        nextjs)           rules_file="$RULES_DIR/nextjs.md" ;;
        django)           rules_file="$RULES_DIR/django.md" ;;
        *)                rules_file="$RULES_DIR/generic.md" ;;
    esac

    if [ ! -f "$rules_file" ]; then
        echo "⚠ Arquivo de regras não encontrado: $rules_file" >&2
        echo "  Stack detectada: $stack — sem regras específicas para sincronizar." >&2
        return 1
    fi

    echo "=== Preparação para Sync com Documentação Oficial ==="
    echo "Stack: $stack"
    echo "Arquivo de regras: $rules_file"
    echo ""
    echo "=== Regras Extraídas para Validação ==="
    echo ""

    # Extrair seções com padrão ## do arquivo de regras
    local section=""
    local rules_count=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]] ]]; then
            section="${line#\#\# }"
            rules_count=$((rules_count + 1))
            echo "[$rules_count] $section"
        fi
    done < "$rules_file"

    echo ""
    echo "Total de seções extraídas: $rules_count"
    echo ""
    echo "=== Consultas Context7 Sugeridas ==="
    echo ""
    echo "Para cada regra acima, o LLM deve:"
    echo "  1. Usar resolve-library-id para identificar a biblioteca (ex: livewire, laravel)"
    echo "  2. Usar get-library-docs para buscar a documentação atual"
    echo "  3. Comparar a regra local com a documentação oficial"
    echo "  4. Registrar: ATUAL | DESATUALIZADA | INCONCLUSIVA"
    echo ""

    # Gerar contexto para o LLM
    _rules_doc_sync_generate_context "$stack" "$rules_file"
}

# ============================================================================
# _rules_doc_sync_generate_context <stack> <rules_file>
# Gera payload de contexto para LLM executar a sincronização
# ============================================================================
_rules_doc_sync_generate_context() {
    local stack="$1"
    local rules_file="$2"

    # Mapear stack para identificador Context7
    local lib_query=""
    case "$stack" in
        livewire) lib_query="livewire laravel" ;;
        nextjs)   lib_query="next.js react" ;;
        django)   lib_query="django python" ;;
        *)        lib_query="" ;;
    esac

    echo "=== Contexto para LLM ==="
    echo ""
    echo "Stack: $stack"
    if [ -n "$lib_query" ]; then
        echo "Buscar no Context7: \"$lib_query\""
    fi
    echo "Arquivo local de regras: $rules_file"
    echo ""
    echo "Conteúdo atual das regras:"
    echo "---"
    cat "$rules_file"
    echo "---"
    echo ""
    echo "Instrução: Compare cada regra acima com a documentação atual do Context7."
    echo "Classifique cada uma como: ATUAL | DESATUALIZADA | SEM_DOCUMENTACAO"
    echo "Documente a versão/fonte consultada e justifique mudanças sugeridas."
}

# ============================================================================
# rules_doc_sync_report
# Lê o relatório gerado e exibe resumo
# ============================================================================
rules_doc_sync_report() {
    if [ ! -f "$DOC_SYNC_REPORT" ]; then
        echo "⚠ Relatório não encontrado: $DOC_SYNC_REPORT" >&2
        echo "  Execute rules_doc_sync_run para gerar um relatório." >&2
        return 1
    fi

    echo "=== Relatório de Sincronização de Regras ==="
    echo ""

    # Extrair métricas do relatório
    local total atual desatualizada sem_doc
    total=$(grep -c "^|" "$DOC_SYNC_REPORT" 2>/dev/null || echo 0)
    atual=$(grep -c "ATUAL" "$DOC_SYNC_REPORT" 2>/dev/null || echo 0)
    desatualizada=$(grep -c "DESATUALIZADA" "$DOC_SYNC_REPORT" 2>/dev/null || echo 0)
    sem_doc=$(grep -c "SEM_DOCUMENTACAO" "$DOC_SYNC_REPORT" 2>/dev/null || echo 0)

    echo "Regras verificadas: $((atual + desatualizada + sem_doc))"
    echo "  ✓ Atuais:          $atual"
    echo "  ✗ Desatualizadas:  $desatualizada"
    echo "  ? Sem documentação: $sem_doc"
    echo ""
    echo "Relatório completo: $DOC_SYNC_REPORT"
    echo ""

    if [ "$desatualizada" -gt 0 ]; then
        echo "⚠ Há $desatualizada regra(s) potencialmente desatualizada(s)."
        echo "  Revise o relatório e atualize os arquivos em .aidev/rules/ conforme necessário."
    else
        echo "✓ Todas as regras verificadas estão alinhadas com a documentação oficial."
    fi
}

# ============================================================================
# rules_doc_sync_write_report <stack> <resultado_llm>
# Persiste relatório de sincronização em state/
# ============================================================================
rules_doc_sync_write_report() {
    local stack="$1"
    local resultado="${2:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    mkdir -p "$(dirname "$DOC_SYNC_REPORT")"

    cat > "$DOC_SYNC_REPORT" << REPORT_EOF
# Relatório de Sincronização de Regras com Documentação Oficial

**Gerado em**: $timestamp
**Stack**: $stack
**Ferramenta**: Context7 MCP

---

## Resultado

$resultado

---

*Gerado por: rules-doc-sync.sh v$RULES_DOC_SYNC_VERSION*
REPORT_EOF

    # Registrar no log
    echo "[$timestamp] doc-sync executado — stack: $stack" >> "$DOC_SYNC_LOG"

    echo "✓ Relatório salvo: $DOC_SYNC_REPORT"
}

# ============================================================================
# rules_doc_sync_run [stack]
# Fluxo completo: prepara contexto, instrui LLM, salva resultado
# Nota: a execução das consultas Context7 é feita pelo LLM durante a sessão.
#       Este script prepara o payload e orienta o processo.
# ============================================================================
rules_doc_sync_run() {
    local stack="${1:-}"

    echo "=== Rules Doc Sync — Fluxo Completo ==="
    echo ""
    echo "IMPORTANTE: Este script prepara o contexto para sincronização."
    echo "O LLM (com Context7 MCP ativo) deve executar as consultas manualmente."
    echo ""

    # Preparar
    rules_doc_sync_prepare "$stack"

    echo ""
    echo "=== Próximos Passos ==="
    echo ""
    echo "1. O LLM deve usar Context7 para consultar a documentação de: $stack"
    echo "2. Comparar cada regra extraída acima com o que a documentação diz"
    echo "3. Classificar: ATUAL | DESATUALIZADA | SEM_DOCUMENTACAO"
    echo "4. Chamar rules_doc_sync_write_report \"$stack\" \"<resultado>\" para persistir"
    echo ""
    echo "Skill disponível: .aidev/skills/rules-doc-sync/SKILL.md"
}

# Executar diretamente se chamado como script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    CMD="${1:-run}"
    STACK_ARG="${2:-}"
    case "$CMD" in
        prepare) rules_doc_sync_prepare "$STACK_ARG" ;;
        report)  rules_doc_sync_report ;;
        run)     rules_doc_sync_run "$STACK_ARG" ;;
        *)
            echo "Uso: $0 {prepare|report|run} [stack]" >&2
            exit 1
            ;;
    esac
fi
