#!/bin/bash
# version-check.sh - Sistema de verificação de versão
# Detecta se versão local está desatualizada vs GitHub

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================

# URL do repositório GitHub
readonly GITHUB_VERSION_URL="https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/VERSION"
readonly GITHUB_RELEASES_URL="https://github.com/nandinhos/aidev-superpowers-v3/releases"

# Timeout para requisições (segundos)
readonly VERSION_CHECK_TIMEOUT=5

# ============================================================================
# FUNÇÕES CORE
# ============================================================================

# Obtém versão remota do GitHub
# Retorna: string da versão ou "unknown"
version_check_get_remote() {
    local version="unknown"
    
    # Tenta obter versão do GitHub com timeout
    if command -v curl &>/dev/null; then
        version=$(curl -s --max-time "$VERSION_CHECK_TIMEOUT" "$GITHUB_VERSION_URL" 2>/dev/null | tr -d '[:space:]')
    elif command -v wget &>/dev/null; then
        version=$(wget -q --timeout="$VERSION_CHECK_TIMEOUT" -O - "$GITHUB_VERSION_URL" 2>/dev/null | tr -d '[:space:]')
    fi
    
    # Valida formato (X.Y.Z)
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$version"
    else
        echo "unknown"
    fi
}

# Compara duas versões semânticas
# Uso: version_check_compare "4.1.1" "4.2.0"
# Retorna: -1 (v1 < v2), 0 (iguais), 1 (v1 > v2)
version_check_compare() {
    local v1="$1"
    local v2="$2"
    
    # Converte para arrays
    local a1 a2
    IFS='.' read -r -a a1 <<< "$v1"
    IFS='.' read -r -a a2 <<< "$v2"
    
    # Padding para garantir mesmo tamanho
    while [ ${#a1[@]} -lt 3 ]; do a1+=(0); done
    while [ ${#a2[@]} -lt 3 ]; do a2+=(0); done
    
    # Compara major, minor, patch
    for i in 0 1 2; do
        if [ "${a1[$i]}" -lt "${a2[$i]}" ]; then
            echo "-1"
            return
        elif [ "${a1[$i]}" -gt "${a2[$i]}" ]; then
            echo "1"
            return
        fi
    done
    
    echo "0"
}

# Verifica se há atualização disponível
# Retorna: 0 (atualizado), 1 (desatualizado), 2 (erro)
version_check_is_outdated() {
    local local_version="${1:-$(cat "$AIDEV_ROOT_DIR/VERSION" 2>/dev/null || echo "0.0.0")}"
    local remote_version
    
    remote_version=$(version_check_get_remote)
    
    if [ "$remote_version" = "unknown" ]; then
        return 2
    fi
    
    local cmp
    cmp=$(version_check_compare "$local_version" "$remote_version")
    
    if [ "$cmp" -eq "-1" ]; then
        return 1  # Desatualizado
    else
        return 0  # Atualizado
    fi
}

# ============================================================================
# ALERTAS E OUTPUT
# ============================================================================

# Mostra alerta se versão estiver desatualizada
version_check_alert() {
    local local_version="${1:-$(cat "$AIDEV_ROOT_DIR/VERSION" 2>/dev/null || echo "0.0.0")}"
    local remote_version
    
    remote_version=$(version_check_get_remote)
    
    if [ "$remote_version" = "unknown" ]; then
        # Silencioso em caso de erro de rede
        return 0
    fi
    
    local cmp
    cmp=$(version_check_compare "$local_version" "$remote_version")
    
    if [ "$cmp" -eq "-1" ]; then
        echo ""
        echo "⚠️  NOVA VERSÃO DISPONÍVEL"
        echo ""
        echo "   Versão local:  $local_version"
        echo "   Versão remota: $remote_version"
        echo ""
        echo "   Para atualizar execute:"
        echo "   aidev self-upgrade"
        echo ""
        echo "   Ou visite: $GITHUB_RELEASES_URL"
        echo ""
        return 1
    fi
    
    return 0
}

# Mostra informações detalhadas de versão
version_check_info() {
    local local_version="${1:-$(cat "$AIDEV_ROOT_DIR/VERSION" 2>/dev/null || echo "0.0.0")}"
    local remote_version
    
    remote_version=$(version_check_get_remote)
    
    echo "📦 AI Dev Superpowers"
    echo ""
    echo "   Versão local:  $local_version"
    
    if [ "$remote_version" = "unknown" ]; then
        echo "   Versão remota: (não foi possível verificar)"
    else
        echo "   Versão remota: $remote_version"
        
        local cmp
        cmp=$(version_check_compare "$local_version" "$remote_version")
        
        case "$cmp" in
            -1)
                echo "   Status:        ⬆️  Atualização disponível"
                ;;
            0)
                echo "   Status:        ✅ Na versão mais recente"
                ;;
            1)
                echo "   Status:        ⚡ Versão local é mais recente (development)"
                ;;
        esac
    fi
    
    echo ""
    echo "   Repositório: $GITHUB_RELEASES_URL"
}

# ============================================================================
# CLI HANDLER
# ============================================================================

version_check_cli() {
    local subcommand="${1:-check}"
    
    case "$subcommand" in
        check)
            version_check_alert
            ;;
        info)
            version_check_info
            ;;
        --quiet|-q)
            # Silencioso, apenas retorna código
            version_check_is_outdated
            exit $?
            ;;
        *)
            echo "Uso: aidev version [check|info]"
            echo ""
            echo "Comandos:"
            echo "  check    Verifica se há atualização disponível"
            echo "  info     Mostra informações detalhadas de versão"
            echo ""
            return 1
            ;;
    esac
}

# ============================================================================
# INICIALIZAÇÃO
# ============================================================================

# Exporta funções para uso externo
export -f version_check_get_remote
export -f version_check_compare
export -f version_check_is_outdated
export -f version_check_alert
export -f version_check_info
export -f version_check_cli
