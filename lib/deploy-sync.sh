#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Deploy Sync Module
# ============================================================================
# Gerencia sincronização entre instalação local e global
# Previne divergências e esquecimentos em releases
#
# Uso: source lib/deploy-sync.sh
# Dependencias: lib/core.sh
# ============================================================================

# Diretório de instalação global
AIDEV_GLOBAL_DIR="${AIDEV_GLOBAL_DIR:-$HOME/.aidev-superpowers}"

# Arquivos críticos que devem estar sincronizados
AIDEV_SYNC_FILES=(
    "bin/aidev"
    "lib/core.sh"
    "lib/context-monitor.sh"
    "lib/checkpoint-manager.sh"
    "lib/sprint-manager.sh"
    "lib/loader.sh"
    "lib/cli.sh"
    "lib/state.sh"
    "lib/templates.sh"
    "lib/detection.sh"
    "lib/file-ops.sh"
    "lib/memory.sh"
    "lib/kb.sh"
    "lib/lessons.sh"
    "lib/metrics.sh"
    "lib/mcp.sh"
    "lib/mcp-bridge.sh"
    "lib/release.sh"
    "lib/i18n.sh"
    "lib/triggers.sh"
    "lib/cache.sh"
    "lib/config-merger.sh"
    "lib/orchestration.sh"
    "lib/plans.sh"
    "lib/system.sh"
    "lib/validation.sh"
    "lib/yaml-parser.sh"
    "lib/deploy-sync.sh"
    "lib/feature-lifecycle.sh"
    "lib/version-check.sh"
    "VERSION"
    "CHANGELOG.md"
    "README.md"
)

# ============================================================================
# VERIFICAÇÃO DE DIVERGÊNCIA
# ============================================================================

# Verifica se instalação local está diferente da global
# Uso: deploy_sync_check_divergence [local_path]
# Retorna: 0 (sincronizado) ou 1 (divergente)
deploy_sync_check_divergence() {
    local local_path="${1:-.}"
    local has_divergence=0
    local divergent_files=()
    
    # Verifica se diretório global existe
    if [ ! -d "$AIDEV_GLOBAL_DIR" ]; then
        echo "❌ Instalação global não encontrada: $AIDEV_GLOBAL_DIR"
        return 1
    fi
    
    # Verifica se é o mesmo diretório
    local local_real global_real
    local_real=$(cd "$local_path" && pwd)
    global_real=$(cd "$AIDEV_GLOBAL_DIR" && pwd)
    
    if [ "$local_real" = "$global_real" ]; then
        # Mesmo diretório, não há divergência
        return 0
    fi
    
    echo "🔍 Verificando sincronização local → global..."
    echo ""
    
    # Verifica cada arquivo crítico
    for file in "${AIDEV_SYNC_FILES[@]}"; do
        local local_file="$local_path/$file"
        local global_file="$AIDEV_GLOBAL_DIR/$file"
        
        # Se arquivo não existe em local, ignora
        if [ ! -f "$local_file" ]; then
            continue
        fi
        
        # Se não existe em global, é divergência
        if [ ! -f "$global_file" ]; then
            divergent_files+=("$file (novo)")
            has_divergence=1
            continue
        fi
        
        # Compara conteúdo (usa md5sum ou diff)
        if command -v md5sum >/dev/null 2>&1; then
            local local_hash global_hash
            local_hash=$(md5sum "$local_file" | cut -d' ' -f1)
            global_hash=$(md5sum "$global_file" | cut -d' ' -f1)
            
            if [ "$local_hash" != "$global_hash" ]; then
                divergent_files+=("$file (modificado)")
                has_divergence=1
            fi
        else
            # Fallback: usa diff
            if ! diff -q "$local_file" "$global_file" >/dev/null 2>&1; then
                divergent_files+=("$file (modificado)")
                has_divergence=1
            fi
        fi
    done
    
    # Relatório
    if [ $has_divergence -eq 1 ]; then
        echo "⚠️  DIVERGÊNCIA DETECTADA!"
        echo ""
        echo "Arquivos diferentes:"
        for f in "${divergent_files[@]}"; do
            echo "  • $f"
        done
        echo ""
        echo "💡 Execute: aidev system sync"
        return 1
    else
        echo "✅ Instalação local está sincronizada com a global"
        return 0
    fi
}

# ============================================================================
# SINCRONIZAÇÃO
# ============================================================================

# Sincroniza instalação local com a global
# Uso: deploy_sync_to_global [local_path] [--dry-run]
# Retorna: 0 (sucesso) ou 1 (falha)
deploy_sync_to_global() {
    local local_path="${1:-.}"
    local dry_run=false
    
    # Verifica flag --dry-run
    if [ "$2" = "--dry-run" ]; then
        dry_run=true
        echo "🔍 MODO SIMULAÇÃO - Nenhuma alteração será feita"
        echo ""
    fi
    
    # Verifica se diretório global existe
    if [ ! -d "$AIDEV_GLOBAL_DIR" ]; then
        echo "❌ Instalação global não encontrada: $AIDEV_GLOBAL_DIR"
        echo "💡 Execute: aidev system deploy (primeira instalação)"
        return 1
    fi
    
    # Verifica se é o mesmo diretório
    local local_real global_real
    local_real=$(cd "$local_path" && pwd)
    global_real=$(cd "$AIDEV_GLOBAL_DIR" && pwd)
    
    if [ "$local_real" = "$global_real" ]; then
        echo "ℹ️  Diretório local é o mesmo que o global"
        echo "   Não é necessário sincronizar"
        return 0
    fi
    
    echo "🔄 Sincronizando local → global..."
    echo "   Local: $local_real"
    echo "   Global: $global_real"
    echo ""
    
    local synced_count=0
    local skipped_count=0
    local error_count=0
    
    for file in "${AIDEV_SYNC_FILES[@]}"; do
        local local_file="$local_path/$file"
        local global_file="$AIDEV_GLOBAL_DIR/$file"
        
        # Se arquivo não existe em local, ignora
        if [ ! -f "$local_file" ]; then
            ((skipped_count++)) || true
            continue
        fi
        
        # Cria diretório global se necessário
        local global_dir
        global_dir=$(dirname "$global_file")
        if [ "$dry_run" = false ]; then
            mkdir -p "$global_dir" 2>/dev/null || {
                echo "  ❌ Erro ao criar diretório: $global_dir"
                ((error_count++)) || true
                continue
            }
        fi
        
        # Compara antes de copiar (otimização)
        local needs_update=true
        if [ -f "$global_file" ]; then
            if command -v md5sum >/dev/null 2>&1; then
                local local_hash global_hash
                local_hash=$(md5sum "$local_file" | cut -d' ' -f1)
                global_hash=$(md5sum "$global_file" | cut -d' ' -f1)
                
                if [ "$local_hash" = "$global_hash" ]; then
                    needs_update=false
                fi
            fi
        fi
        
        if [ "$needs_update" = true ]; then
            if [ "$dry_run" = true ]; then
                echo "  [SIMULAR] $file"
                ((synced_count++)) || true
            else
                if cp "$local_file" "$global_file" 2>/dev/null; then
                    echo "  ✅ $file"
                    ((synced_count++)) || true
                else
                    echo "  ❌ $file (erro ao copiar)"
                    ((error_count++)) || true
                fi
            fi
        else
            ((skipped_count++)) || true
        fi
    done
    
    echo ""
    
    if [ "$dry_run" = true ]; then
        echo "📊 Simulação concluída"
        echo "   Arquivos a sincronizar: $synced_count"
        return 0
    fi
    
    if [ $error_count -eq 0 ]; then
        echo "✅ Sincronização concluída!"
        echo "   Sincronizados: $synced_count"
        echo "   Ignorados (já atualizados): $skipped_count"
        
        # Atualiza timestamp de último sync
        date +%s > "$AIDEV_GLOBAL_DIR/.last_sync_timestamp"
        
        return 0
    else
        echo "⚠️  Sincronização concluída com erros"
        echo "   Sincronizados: $synced_count"
        echo "   Erros: $error_count"
        return 1
    fi
}

# ============================================================================
# VERIFICAÇÃO NA INICIALIZAÇÃO
# ============================================================================

# Verifica divergência e alerta se necessário (uso na inicialização)
# Uso: deploy_sync_check_on_init
deploy_sync_check_on_init() {
    # Só verifica se estamos em um projeto aidev (não no global)
    local current_dir
    current_dir=$(pwd)
    
    if [ "$current_dir" = "$AIDEV_GLOBAL_DIR" ] || [ "$current_dir" = "$HOME/.aidev-superpowers" ]; then
        # Estamos no diretório global, não precisa verificar
        return 0
    fi
    
    # Verifica se há divergência (silenciosamente)
    local has_divergence=0
    
    for file in "bin/aidev" "VERSION" "lib/core.sh"; do
        local local_file="$current_dir/$file"
        local global_file="$AIDEV_GLOBAL_DIR/$file"
        
        if [ ! -f "$local_file" ] || [ ! -f "$global_file" ]; then
            continue
        fi
        
        # Compara versões usando md5
        if command -v md5sum >/dev/null 2>&1; then
            local local_hash global_hash
            local_hash=$(md5sum "$local_file" 2>/dev/null | cut -d' ' -f1)
            global_hash=$(md5sum "$global_file" 2>/dev/null | cut -d' ' -f1)
            
            if [ "$local_hash" != "$global_hash" ]; then
                has_divergence=1
                break
            fi
        fi
    done
    
    if [ $has_divergence -eq 1 ]; then
        echo ""
        echo "⚠️  ALERTA: Instalação local diferente da global"
        echo "   Execute 'aidev system sync' para sincronizar"
        echo ""
    fi
}

# ============================================================================
# INTEGRAÇÃO COM RELEASE
# ============================================================================

# Hook para ser chamado após release
# Uso: deploy_sync_after_release
deploy_sync_after_release() {
    echo ""
    echo "🔄 Sincronizando release com instalação global..."
    
    if deploy_sync_to_global "."; then
        echo "✅ Release v$(cat VERSION) sincronizado com sucesso!"
        
        # Cria checkpoint de sync
        if type ckpt_create &>/dev/null; then
            ckpt_create "." "release" "Release sincronizado com instalação global" >/dev/null 2>&1 || true
        fi
        
        return 0
    else
        echo "❌ Falha na sincronização"
        echo "💡 Execute manualmente: aidev system sync"
        return 1
    fi
}

# ============================================================================
# STATUS DO SYNC
# ============================================================================

# Mostra status da sincronização
# Uso: deploy_sync_status
deploy_sync_status() {
    echo "📊 Status da Sincronização"
    echo "=========================="
    echo ""
    echo "Diretório Global: $AIDEV_GLOBAL_DIR"
    echo "Diretório Local:  $(pwd)"
    echo ""
    
    if [ ! -d "$AIDEV_GLOBAL_DIR" ]; then
        echo "❌ Instalação global não encontrada"
        return 1
    fi
    
    # Verifica último sync
    if [ -f "$AIDEV_GLOBAL_DIR/.last_sync_timestamp" ]; then
        local last_sync
        last_sync=$(cat "$AIDEV_GLOBAL_DIR/.last_sync_timestamp")
        local last_sync_date
        last_sync_date=$(date -d "@$last_sync" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Desconhecido")
        echo "Último sync: $last_sync_date"
    else
        echo "Último sync: Nunca"
    fi
    
    echo ""
    
    # Verifica divergência
    if deploy_sync_check_divergence "." 2>/dev/null; then
        echo "Status: ✅ Sincronizado"
    else
        echo "Status: ⚠️  Divergente"
    fi
}
