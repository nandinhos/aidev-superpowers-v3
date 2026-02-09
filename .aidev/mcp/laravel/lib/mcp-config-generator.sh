#!/usr/bin/env bash
#
# MCP Config Generator for Laravel Boost
# Gera configuração MCP dinâmica baseada em container detectado
#

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Diretórios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MCP_DIR="$(dirname "$SCRIPT_DIR")"
readonly CONFIG_DIR="$MCP_DIR/config"
readonly BACKUP_DIR="$MCP_DIR/backups"

# ============================================
# Logging
# ============================================

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

# ============================================
# Funções de Detecção
# ============================================

detect_php_executable() {
    local container_name="$1"
    local php_path
    
    # Tentar encontrar PHP no container
    php_path=$(docker exec "$container_name" sh -c 'which php' 2>/dev/null || echo "")
    
    if [ -z "$php_path" ]; then
        # Tentar caminhos comuns
        for path in "/usr/local/bin/php" "/usr/bin/php" "/usr/local/sbin/php"; do
            if docker exec "$container_name" test -x "$path" 2>/dev/null; then
                php_path="$path"
                break
            fi
        done
    fi
    
    echo "${php_path:-/usr/local/bin/php}"
}

detect_artisan_path() {
    local container_name="$1"
    local project_path="${2:-/var/www/html}"

    # Usar artisan-detector.sh se disponível
    if [ -x "$SCRIPT_DIR/artisan-detector.sh" ]; then
        "$SCRIPT_DIR/artisan-detector.sh" detect "$container_name" 2>/dev/null
        return $?
    fi

    # Fallback: deteccao inline simplificada
    local common_paths=(
        "$project_path/artisan"
        "/var/www/html/artisan"
        "/var/www/artisan"
        "/app/artisan"
    )

    for path in "${common_paths[@]}"; do
        if docker exec "$container_name" test -f "$path" 2>/dev/null; then
            echo "$path"
            return 0
        fi
    done

    # Busca recursiva
    local found
    found=$(docker exec "$container_name" sh -c 'find /var/www -name artisan -type f 2>/dev/null | head -1' || echo "")
    if [ -n "$found" ]; then
        echo "$found"
        return 0
    fi

    # Fallback
    echo "$project_path/artisan"
}

detect_boost_command() {
    local container_name="$1"
    local artisan_path="${2:-artisan}"

    # Usar artisan-detector.sh se disponível
    if [ -x "$SCRIPT_DIR/artisan-detector.sh" ]; then
        "$SCRIPT_DIR/artisan-detector.sh" command "$container_name" 2>/dev/null
        return $?
    fi

    # Fallback: deteccao inline
    local possible_commands=("boost:mcp" "mcp:serve" "mcp:start laravel-boost" "boost:serve")

    for cmd in "${possible_commands[@]}"; do
        local cmd_name="${cmd%% *}"
        if docker exec "$container_name" php "$artisan_path" list 2>/dev/null | grep -q "$cmd_name"; then
            echo "$cmd"
            return 0
        fi
    done

    # Fallback padrao
    echo "boost:mcp"
    return 1
}

get_container_workdir() {
    local container_name="$1"
    local workdir
    
    workdir=$(docker inspect --format='{{.Config.WorkingDir}}' "$container_name" 2>/dev/null || echo "")
    
    if [ -z "$workdir" ]; then
        workdir="/var/www/html"
    fi
    
    echo "$workdir"
}

# ============================================
# Geração de Config
# ============================================

generate_mcp_config() {
    local container_name="$1"
    local project_name="${2:-$container_name}"
    local server_name="${3:-laravel-boost-$container_name}"

    # Redirecionar logs para stderr para nao misturar com JSON output
    log_info "Gerando configuração MCP para '$container_name'..." >&2

    # Detectar informacoes do container
    local workdir artisan_path boost_command

    workdir=$(get_container_workdir "$container_name")

    # Detectar caminho do artisan
    artisan_path=$(detect_artisan_path "$container_name" "$workdir")
    log_info "  Artisan: $artisan_path" >&2

    # Detectar comando Boost disponivel
    boost_command=$(detect_boost_command "$container_name" "$artisan_path")
    log_info "  Comando: $boost_command" >&2

    log_info "  Container: $container_name" >&2
    log_info "  Server name: $server_name" >&2

    # Separar boost_command em partes (ex: "mcp:start laravel-boost" -> 2 args)
    local args_json
    args_json=$(printf '        "exec",\n        "-i",\n        "%s",\n        "php",\n        "%s"' "$container_name" "$artisan_path")

    # Adicionar cada parte do boost_command como argumento separado
    local cmd_part
    for cmd_part in $boost_command; do
        args_json=$(printf '%s,\n        "%s"' "$args_json" "$cmd_part")
    done

    # Criar configuracao MCP
    cat <<EOF
{
  "mcpServers": {
    "$server_name": {
      "command": "docker",
      "args": [
$args_json
      ],
      "env": {
        "LARAVEL_CONTAINER": "$container_name"
      }
    }
  }
}
EOF
}

# ============================================
# Validação e Salvamento
# ============================================

validate_config() {
    local config_file="$1"
    
    # Verificar se é JSON válido
    if ! jq empty "$config_file" 2>/dev/null; then
        log_error "Configuração gerada não é JSON válido"
        return 1
    fi
    
    # Verificar estrutura mínima
    if ! jq -e '.mcpServers' "$config_file" > /dev/null 2>&1; then
        log_error "Configuração não contém mcpServers"
        return 1
    fi
    
    return 0
}

backup_existing_config() {
    local config_file="$1"
    
    if [ -f "$config_file" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_name
        backup_name="$(basename "$config_file").$(date +%Y%m%d%H%M%S).bak"
        cp "$config_file" "$BACKUP_DIR/$backup_name"
        log_info "Backup criado: $BACKUP_DIR/$backup_name"
    fi
}

save_config() {
    local container_name="$1"
    local project_name="${2:-$container_name}"
    local output_file="${3:-}"
    
    # Determinar arquivo de saída
    if [ -z "$output_file" ]; then
        mkdir -p "$CONFIG_DIR"
        output_file="$CONFIG_DIR/${container_name}.json"
    fi
    
    # Backup da config existente
    backup_existing_config "$output_file"
    
    # Gerar nova config
    local config_json
    config_json=$(generate_mcp_config "$container_name" "$project_name")
    
    # Salvar arquivo temporário
    local temp_file
    temp_file=$(mktemp)
    echo "$config_json" > "$temp_file"
    
    # Validar
    if validate_config "$temp_file"; then
        mv "$temp_file" "$output_file"
        log_success "Configuração salva em: $output_file"
        echo "$output_file"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# ============================================
# Merge de Configs
# ============================================

merge_configs() {
    local output_file="$1"
    shift
    
    mkdir -p "$CONFIG_DIR"
    
    log_info "Mesclando configurações..."
    
    # Iniciar com objeto vazio
    local merged='{"mcpServers": {}}'
    
    # Para cada arquivo de config
    for config_file in "$@"; do
        if [ -f "$config_file" ]; then
            log_info "  Adicionando: $config_file"
            # Merge usando jq
            merged=$(echo "$merged" | jq --slurpfile new "$config_file" '.mcpServers += $new[0].mcpServers')
        fi
    done
    
    # Salvar resultado
    backup_existing_config "$output_file"
    echo "$merged" | jq '.' > "$output_file"
    
    log_success "Configuração mesclada salva em: $output_file"
}

generate_combined_config() {
    local output_file="${1:-$CONFIG_DIR/combined-mcp.json}"
    
    mkdir -p "$CONFIG_DIR"
    
    # Encontrar todas as configs individuais
    local configs=()
    while IFS= read -r -d '' config; do
        configs+=("$config")
    done < <(find "$CONFIG_DIR" -name "*.json" -not -name "combined-mcp.json" -print0 2>/dev/null || true)
    
    if [ ${#configs[@]} -eq 0 ]; then
        log_warn "Nenhuma configuração individual encontrada"
        echo '{"mcpServers": {}}' > "$output_file"
        return 0
    fi
    
    merge_configs "$output_file" "${configs[@]}"
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  generate <container> [project]  Gera config para container
  save <container> [project]      Gera e salva config
  merge [output]                  Mescla todas configs individuais
  validate <file>                 Valida arquivo de config
  show <container>                Mostra config sem salvar

Opções:
  -o, --output <file>             Arquivo de saída específico
  -n, --name <name>               Nome do servidor MCP
  -h, --help                      Mostra esta ajuda

Exemplos:
  $0 generate my-app-php
  $0 generate my-app-php my-project --output ./custom.json
  $0 save my-app-php
  $0 merge ~/.config/mcp/laravel-servers.json
  $0 validate ./config.json

EOF
}

main() {
    local command="${1:-}"
    shift || true
    
    local container_name=""
    local project_name=""
    local output_file=""
    local server_name=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -n|--name)
                server_name="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$container_name" ]; then
                    container_name="$1"
                elif [ -z "$project_name" ]; then
                    project_name="$1"
                fi
                shift
                ;;
        esac
    done
    
    case "$command" in
        generate|gen)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            generate_mcp_config "$container_name" "${project_name:-$container_name}" "${server_name:-laravel-boost-$container_name}"
            ;;
        save)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            save_config "$container_name" "${project_name:-$container_name}" "$output_file"
            ;;
        merge|combine)
            generate_combined_config "${output_file:-$CONFIG_DIR/combined-mcp.json}"
            ;;
        validate|check)
            if [ -z "$container_name" ]; then
                log_error "Arquivo de config não especificado"
                show_help
                exit 1
            fi
            if validate_config "$container_name"; then
                log_success "Configuração válida"
                exit 0
            else
                exit 1
            fi
            ;;
        show|preview)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            generate_mcp_config "$container_name" "${project_name:-$container_name}" "${server_name:-laravel-boost-$container_name}" | jq '.'
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
