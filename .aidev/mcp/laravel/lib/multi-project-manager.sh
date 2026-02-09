#!/usr/bin/env bash
#
# Multi-Project Manager
# Gerencia múltiplos containers Laravel simultaneamente
#

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# Diretórios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MCP_DIR="$(dirname "$SCRIPT_DIR")"
readonly LIB_DIR="$MCP_DIR/lib"
readonly STATE_DIR="$MCP_DIR/state"
readonly CONFIG_DIR="$MCP_DIR/config"

# Arquivo de registro de projetos
readonly PROJECTS_REGISTRY="$STATE_DIR/projects.json"

# ============================================
# Logging
# ============================================

ensure_state() {
    mkdir -p "$STATE_DIR" "$CONFIG_DIR"
    
    # Inicializar registry se não existir
    if [ ! -f "$PROJECTS_REGISTRY" ]; then
        echo '{"projects": {}}' > "$PROJECTS_REGISTRY"
    fi
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_project() {
    echo -e "${PURPLE}[PROJECT]${NC} $1"
}

# ============================================
# Gerenciamento de Projetos
# ============================================

register_project() {
    local container_name="$1"
    local project_name="${2:-$container_name}"
    local project_path="${3:-}"
    local description="${4:-}"
    
    ensure_state
    
    log_info "Registrando projeto: $project_name ($container_name)"
    
    # Criar entrada do projeto
    local project_entry
    project_entry=$(cat <<EOF
{
  "name": "$project_name",
  "container": "$container_name",
  "path": "$project_path",
  "description": "$description",
  "registered_at": "$(date -Iseconds)",
  "last_seen": "$(date -Iseconds)",
  "status": "registered",
  "active": true,
  "config_file": "${container_name}.json"
}
EOF
)
    
    # Atualizar registry
    local updated_registry
    updated_registry=$(jq --arg name "$project_name" --argjson entry "$project_entry" '.projects[$name] = $entry' "$PROJECTS_REGISTRY")
    
    echo "$updated_registry" | jq '.' > "$PROJECTS_REGISTRY"
    
    log_success "Projeto '$project_name' registrado"
}

unregister_project() {
    local project_name="$1"
    
    ensure_state
    
    if ! jq -e ".projects[\"$project_name\"]" "$PROJECTS_REGISTRY" > /dev/null 2>&1; then
        log_warn "Projeto '$project_name' não encontrado"
        return 1
    fi
    
    # Marcar como inativo ao invés de remover
    local updated_registry
    updated_registry=$(jq --arg name "$project_name" '.projects[$name].active = false | .projects[$name].unregistered_at = "'"$(date -Iseconds)"'"' "$PROJECTS_REGISTRY")
    
    echo "$updated_registry" | jq '.' > "$PROJECTS_REGISTRY"
    
    log_success "Projeto '$project_name' desregistrado"
}

update_project_status() {
    local project_name="$1"
    local status="$2"
    local extra_data="${3:-{}}"
    
    ensure_state
    
    if ! jq -e ".projects[\"$project_name\"]" "$PROJECTS_REGISTRY" > /dev/null 2>&1; then
        return 1
    fi
    
    local updated_registry
    updated_registry=$(jq --arg name "$project_name" --arg status "$status" --argjson extra "$extra_data" \
        '.projects[$name].status = $status | .projects[$name].last_seen = "'"$(date -Iseconds)"'" | .projects[$name] += $extra' \
        "$PROJECTS_REGISTRY")
    
    echo "$updated_registry" | jq '.' > "$PROJECTS_REGISTRY"
}

get_project_info() {
    local project_name="$1"
    
    ensure_state
    
    jq ".projects[\"$project_name\"]" "$PROJECTS_REGISTRY" 2>/dev/null || echo "null"
}

list_projects() {
    ensure_state
    
    log_info "Projetos registrados:"
    echo ""
    
    local projects
    projects=$(jq -r '.projects | keys[]' "$PROJECTS_REGISTRY" 2>/dev/null)
    
    if [ -z "$projects" ]; then
        echo "  Nenhum projeto registrado"
        return 0
    fi
    
    printf "%-20s %-20s %-15s %-10s\n" "NOME" "CONTAINER" "STATUS" "ATIVO"
    printf "%-20s %-20s %-15s %-10s\n" "----" "---------" "------" "-----"
    
    while IFS= read -r project_name; do
        local project_info
        project_info=$(get_project_info "$project_name")
        
        local container status active
        container=$(echo "$project_info" | jq -r '.container // "N/A"')
        status=$(echo "$project_info" | jq -r '.status // "unknown"')
        active=$(echo "$project_info" | jq -r '.active // false')
        
        local active_icon="❌"
        [ "$active" = "true" ] && active_icon="✅"
        
        printf "%-20s %-20s %-15s %-10s\n" "$project_name" "$container" "$status" "$active_icon"
    done <<< "$projects"
}

# ============================================
# Detecção e Sincronização
# ============================================

sync_with_containers() {
    log_info "Sincronizando projetos com containers..."
    
    # Listar todos containers Laravel
    local containers_json
    containers_json=$("$LIB_DIR/docker-discovery.sh" discover 2>/dev/null || echo '[]')
    
    # Para cada container detectado
    local container_names
    container_names=$(echo "$containers_json" | jq -r '.[].name' 2>/dev/null)
    
    while IFS= read -r container_name; do
        [ -z "$container_name" ] && continue
        
        # Verificar se já está registrado
        local project_name
        project_name=$(jq -r ".projects | to_entries[] | select(.value.container == \"$container_name\") | .key" "$PROJECTS_REGISTRY" 2>/dev/null | head -1)
        
        if [ -n "$project_name" ]; then
            # Atualizar última visualização
            update_project_status "$project_name" "active"
            log_info "  Atualizado: $project_name ($container_name)"
        else
            # Registrar novo projeto
            local project_path
            project_path=$(echo "$containers_json" | jq -r ".[] | select(.name == \"$container_name\") | .project_path")
            
            register_project "$container_name" "$container_name" "$project_path" "Auto-detectado"
            log_success "  Novo: $container_name"
        fi
    done <<< "$container_names"
    
    # Verificar containers que não estão mais rodando
    local registered_containers
    registered_containers=$(jq -r '.projects[] | select(.active == true) | .container' "$PROJECTS_REGISTRY" 2>/dev/null)
    
    while IFS= read -r registered_container; do
        [ -z "$registered_container" ] && continue
        
        if ! echo "$container_names" | grep -q "^${registered_container}$"; then
            # Container não está mais rodando
            local project_name
            project_name=$(jq -r ".projects | to_entries[] | select(.value.container == \"$registered_container\") | .key" "$PROJECTS_REGISTRY" 2>/dev/null | head -1)
            
            if [ -n "$project_name" ]; then
                update_project_status "$project_name" "stopped"
                log_warn "  Parado: $project_name ($registered_container)"
            fi
        fi
    done <<< "$registered_containers"
    
    log_success "Sincronização completa"
}

# ============================================
# Configurações por Projeto
# ============================================

generate_project_config() {
    local project_name="$1"
    
    local project_info
    project_info=$(get_project_info "$project_name")
    
    if [ "$project_info" = "null" ]; then
        log_error "Projeto '$project_name' não encontrado"
        return 1
    fi
    
    local container_name
    container_name=$(echo "$project_info" | jq -r '.container')
    
    log_info "Gerando configuração para projeto: $project_name"
    
    # Usar config generator
    local config_file
    config_file=$("$LIB_DIR/mcp-config-generator.sh" save "$container_name" "$project_name")
    
    if [ -n "$config_file" ]; then
        # Atualizar projeto com path do config
        local updated_registry
        updated_registry=$(jq --arg name "$project_name" --arg config "$config_file" \
            '.projects[$name].config_file = $config | .projects[$name].config_generated_at = "'"$(date -Iseconds)"'"' \
            "$PROJECTS_REGISTRY")
        
        echo "$updated_registry" | jq '.' > "$PROJECTS_REGISTRY"
        
        log_success "Configuração gerada: $config_file"
        echo "$config_file"
        return 0
    else
        log_error "Falha ao gerar configuração"
        return 1
    fi
}

generate_combined_config() {
    log_info "Gerando configuração combinada..."
    
    ensure_state
    
    # Obter todos projetos ativos
    local active_projects
    active_projects=$(jq -r '.projects | to_entries[] | select(.value.active == true) | .value.container' "$PROJECTS_REGISTRY" 2>/dev/null)
    
    if [ -z "$active_projects" ]; then
        log_warn "Nenhum projeto ativo encontrado"
        echo '{"mcpServers": {}}' > "$CONFIG_DIR/combined-mcp.json"
        return 0
    fi
    
    # Iniciar com objeto vazio
    local merged='{"mcpServers": {}}'
    
    # Para cada projeto ativo
    while IFS= read -r container_name; do
        [ -z "$container_name" ] && continue
        
        local config_file="$CONFIG_DIR/${container_name}.json"
        
        if [ -f "$config_file" ]; then
            log_info "  Adicionando: $container_name"
            merged=$(echo "$merged" | jq --slurpfile new "$config_file" '.mcpServers += $new[0].mcpServers')
        else
            log_warn "  Config não encontrada: $container_name"
        fi
    done <<< "$active_projects"
    
    # Salvar configuração combinada
    local combined_file="$CONFIG_DIR/combined-mcp.json"
    echo "$merged" | jq '.' > "$combined_file"
    
    log_success "Configuração combinada salva: $combined_file"
    echo "$combined_file"
}

# ============================================
# Switch de Contexto
# ============================================

set_active_project() {
    local project_name="$1"
    
    ensure_state
    
    local project_info
    project_info=$(get_project_info "$project_name")
    
    if [ "$project_info" = "null" ]; then
        log_error "Projeto '$project_name' não encontrado"
        return 1
    fi
    
    # Desativar todos projetos primeiro
    local updated_registry
    updated_registry=$(jq '.projects |= map_values(.is_primary = false)' "$PROJECTS_REGISTRY")
    echo "$updated_registry" | jq '.' > "$PROJECTS_REGISTRY"
    
    # Ativar projeto selecionado
    updated_registry=$(jq --arg name "$project_name" '.projects[$name].is_primary = true' "$PROJECTS_REGISTRY")
    echo "$updated_registry" | jq '.' > "$PROJECTS_REGISTRY"
    
    log_success "Projeto ativo definido: $project_name"
    
    # Mostrar info
    local container
    container=$(echo "$project_info" | jq -r '.container')
    log_info "Container: $container"
}

get_active_project() {
    ensure_state
    
    local active_project
    active_project=$(jq -r '.projects | to_entries[] | select(.value.is_primary == true) | .key' "$PROJECTS_REGISTRY" 2>/dev/null | head -1)
    
    if [ -n "$active_project" ]; then
        echo "$active_project"
    else
        # Retornar primeiro projeto ativo
        jq -r '.projects | to_entries[] | select(.value.active == true) | .key' "$PROJECTS_REGISTRY" 2>/dev/null | head -1
    fi
}

# ============================================
# Importacao de Configs Existentes
# ============================================

import_existing_configs() {
    log_info "Procurando configuracoes Laravel Boost existentes..."

    ensure_state

    # Locais comuns de config MCP por IDE
    local mcp_locations=(
        "$HOME/.config/mcp/mcp.json"
        "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
        "$HOME/.config/Claude/claude_desktop_config.json"
        "$HOME/.cursor/mcp.json"
        "$HOME/.vscode/mcp.json"
    )

    local found_count=0

    for mcp_file in "${mcp_locations[@]}"; do
        [ -f "$mcp_file" ] || continue

        # Verificar se tem laravel-boost ou similar configurado
        local laravel_servers
        laravel_servers=$(jq -r '.mcpServers | to_entries[] | select(.key | test("laravel|boost")) | .key' "$mcp_file" 2>/dev/null || true)

        [ -z "$laravel_servers" ] && continue

        log_success "Encontrado em: $mcp_file"

        while IFS= read -r server_name; do
            [ -z "$server_name" ] && continue

            local container artisan_path
            container=$(jq -r ".mcpServers[\"$server_name\"].args[3] // empty" "$mcp_file" 2>/dev/null || echo "")

            if [ -z "$container" ]; then
                continue
            fi

            # Tentar extrair artisan path dos args
            artisan_path=$(jq -r ".mcpServers[\"$server_name\"].args[5] // empty" "$mcp_file" 2>/dev/null || echo "")

            log_info "  Server: $server_name"
            log_info "  Container: $container"
            [ -n "$artisan_path" ] && log_info "  Artisan: $artisan_path"

            # Derivar nome do projeto pelo container
            local project_name
            project_name=$(echo "$container" | sed 's/-laravel.test-[0-9]*//; s/-app$//; s/_/-/g')

            register_project "$container" "$project_name" "" "Importado de $mcp_file"
            ((found_count++))
        done <<< "$laravel_servers"
    done

    echo ""
    if [ "$found_count" -gt 0 ]; then
        log_success "$found_count configuracao(oes) importada(s)"
    else
        log_warn "Nenhuma configuracao existente encontrada"
    fi
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  list                  Lista todos projetos
  register <container>  Registra novo projeto
  unregister <name>     Remove projeto
  sync                  Sincroniza com containers
  config <name>         Gera config para projeto
  combine               Gera config combinada
  active [name]         Mostra/define projeto ativo
  info <name>           Mostra info do projeto
  import                Importa configs existentes de IDEs
  cleanup               Remove projetos inativos

Opções:
  -n, --name <name>     Nome do projeto
  -p, --path <path>     Path do projeto
  -d, --desc <desc>     Descrição
  -h, --help            Mostra esta ajuda

Exemplos:
  $0 list                          Lista projetos
  $0 register my-app-php           Registra container
  $0 register my-app-php --name my-project
  $0 sync                          Sincroniza tudo
  $0 config my-project             Gera config
  $0 combine                       Gera config combinada
  $0 active my-project             Define projeto ativo

EOF
}

main() {
    local command="${1:-help}"
    shift || true
    
    local project_name=""
    local container_name=""
    local project_path=""
    local description=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                project_name="$2"
                shift 2
                ;;
            -p|--path)
                project_path="$2"
                shift 2
                ;;
            -d|--desc|--description)
                description="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$container_name" ]; then
                    container_name="$1"
                fi
                shift
                ;;
        esac
    done
    
    case "$command" in
        list|ls)
            list_projects
            ;;
        register|add)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            register_project "$container_name" "${project_name:-$container_name}" "$project_path" "$description"
            ;;
        unregister|remove|rm)
            if [ -z "$container_name" ]; then
                log_error "Nome do projeto não especificado"
                show_help
                exit 1
            fi
            unregister_project "$container_name"
            ;;
        sync|refresh|update)
            sync_with_containers
            ;;
        config|generate)
            if [ -z "$container_name" ]; then
                log_error "Nome do projeto não especificado"
                show_help
                exit 1
            fi
            generate_project_config "$container_name"
            ;;
        combine|merge|all)
            generate_combined_config
            ;;
        active|switch)
            if [ -n "$container_name" ]; then
                set_active_project "$container_name"
            else
                local active
                active=$(get_active_project)
                if [ -n "$active" ]; then
                    log_info "Projeto ativo: $active"
                else
                    log_warn "Nenhum projeto ativo definido"
                fi
            fi
            ;;
        info|show)
            if [ -z "$container_name" ]; then
                log_error "Nome do projeto não especificado"
                show_help
                exit 1
            fi
            get_project_info "$container_name" | jq '.'
            ;;
        import|scan)
            import_existing_configs
            ;;
        cleanup|prune)
            log_info "Limpando projetos inativos..."
            local registry_backup
            registry_backup=$(jq '.projects |= with_entries(select(.value.active == true))' "$PROJECTS_REGISTRY")
            echo "$registry_backup" | jq '.' > "$PROJECTS_REGISTRY"
            log_success "Projetos inativos removidos"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Comando desconhecido: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
