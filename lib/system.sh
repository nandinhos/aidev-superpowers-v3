#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - System & Update Module
# ============================================================================
# Gestão de deploy, sincronização e linkagem da instalação global
# 
# Uso: source lib/system.sh
# Dependências: lib/core.sh, lib/file-ops.sh
# ============================================================================

# Detecta o diretório raiz da instalação global do aidev
system__get_global_root() {
    local global_default="$HOME/.aidev-superpowers"
    
    # Se o diretório padrão existe, ele é a raiz global independente do link
    if [ -d "$global_default" ]; then
        echo "$global_default"
        return
    fi

    # Fallback: tenta localizar via binário
    local aidev_bin=$(which aidev 2>/dev/null)
    if [ -n "$aidev_bin" ]; then
        local real_bin=$(readlink -f "$aidev_bin")
        echo "$(dirname "$(dirname "$real_bin")")"
    else
        echo "$global_default"
    fi
}

# Realiza o deploy (cópia) do projeto atual para o global
# Uso: system__deploy [force]
system__deploy() {
    local force="${1:-false}"
    local global_root=$(system__get_global_root)
    local local_root="$AIDEV_ROOT_DIR"

    if [ "$local_root" == "$global_root" ]; then
        print_error "O diretório local já é o diretório global ($global_root)."
        return 1
    fi

    # Criar Backup de Segurança antes de deploy
    local backup_tag=$(date +%Y%m%d%H%M%S)
    local backup_dir="${global_root}.bak.${backup_tag}"
    
    if [ -d "$global_root" ]; then
        print_info "Criando backup de segurança: $(basename "$backup_dir")"
        cp -r "$global_root" "$backup_dir"
    fi

    print_info "Iniciando deploy global em: $global_root"
    
    # Lista de diretórios/arquivos essenciais para deploy
    local targets=("bin" "lib" "templates" "agents" "skills" "rules")
    
    mkdir -p "$global_root"
    
    for item in "${targets[@]}"; do
        if [ -e "$local_root/$item" ]; then
            print_debug "Sincronizando $item..."
            cp -r "$local_root/$item" "$global_root/"
        fi
    done

    # Copia arquivos soltos da raiz e persiste a versão
    cp "$local_root/VERSION" "$global_root/" 2>/dev/null || true
    echo "$backup_tag" > "$global_root/.last_deploy_backup"

    print_success "Deploy global concluído com sucesso!"
    print_info "Para desfazer, use: aidev system rollback"
}

# Reverte para o último backup criado pelo deploy
# Uso: system__rollback
system__rollback() {
    local global_root=$(system__get_global_root)
    
    if [ ! -f "$global_root/.last_deploy_backup" ]; then
        print_error "Nenhum backup de deploy encontrado para restaurar."
        return 1
    fi

    local backup_tag=$(cat "$global_root/.last_deploy_backup")
    local backup_dir="${global_root}.bak.${backup_tag}"

    if [ ! -d "$backup_dir" ]; then
        print_error "Diretório de backup $backup_dir não encontrado."
        return 1
    fi

    print_warning "Iniciando ROLLBACK para a versão: $backup_tag"
    
    # Remove a instalação atual (preservando o backup)
    rm -rf "$global_root"
    
    # Restaura o backup
    cp -r "$backup_dir" "$global_root"
    
    print_success "Rollback concluído! A instalação global foi restaurada."
}

# Cria links simbólicos para modo de desenvolvimento
# Uso: system__link
system__link() {
    local global_root=$(system__get_global_root)
    local local_root="$AIDEV_ROOT_DIR"

    if [ "$local_root" == "$global_root" ]; then
        print_error "O diretório local já é o diretório global."
        return 1
    fi

    print_warning "⚠️  ENTRANDO EM MODO DE DESENVOLVIMENTO (LINK)"
    print_info "Links simbólicos serão criados de $global_root para este diretório."

    # Backup do global atual se não for link
    if [ ! -L "$global_root/lib" ] && [ -d "$global_root" ]; then
        local backup_tag=$(date +%Y%m%d%H%M%S)
        print_info "Criando backup da instalação global atual..."
        mv "$global_root" "${global_root}.bak.${backup_tag}"
    fi

    mkdir -p "$global_root"

    # Cria links para as pastas principais
    local targets=("bin" "lib" "templates" "agents" "skills" "rules")
    for item in "${targets[@]}"; do
        ln -snf "$local_root/$item" "$global_root/$item"
    done

    print_success "Modo Link ativado!"
}

# Mostra o estado atual da sincronização global
system__status() {
    local global_root=$(system__get_global_root)
    local local_root="$AIDEV_ROOT_DIR"
    local is_linked="false"

    if [ -L "$global_root/lib" ]; then
        is_linked="true"
    fi

    print_section "Sistema Global"
    echo "  Instalação Global: ${CYAN}$global_root${NC}"
    echo "  Projeto Local:     ${CYAN}$local_root${NC}"
    
    if [ "$is_linked" == "true" ]; then
        echo "  Modo:              ${YELLOW}LINK (Desenvolvimento)${NC}"
        local target=$(readlink -f "$global_root/lib")
        echo "  Apontando para:    ${MAGENTA}$target${NC}"
    else
        echo "  Modo:              ${GREEN}STANDALONE (Produção)${NC}"
    fi
    
    if [ -f "$global_root/.last_deploy_backup" ]; then
        local last_bak=$(cat "$global_root/.last_deploy_backup")
        echo "  Último Backup:     ${BLUE}$last_bak${NC}"
    fi
    echo ""
}
