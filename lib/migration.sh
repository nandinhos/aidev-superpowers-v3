#!/usr/bin/env bash

# ============================================================================
# AI Dev Superpowers V3 - Migration Module
# ============================================================================
# Motor de migracao incremental. Rastreia qual versao do CLI gerou cada
# projeto e executa scripts de migracao quando necessario.
#
# Uso: source lib/migration.sh
# Dependencias: lib/core.sh, lib/state.sh
# ============================================================================

# Diretorio de scripts de migracao (pode ser overridden para testes)
AIDEV_MIGRATIONS_DIR="${AIDEV_MIGRATIONS_DIR:-${AIDEV_ROOT_DIR:-}/migrations}"

# ============================================================================
# migration_get_project_version - Le versao do projeto
# ============================================================================
# Le de .aidev/MANIFEST.local.json
# Uso: version=$(migration_get_project_version "/path/to/project")
# Retorna: string da versao ou "unknown"
migration_get_project_version() {
    local install_path="${1:-.}"
    local manifest_local="$install_path/.aidev/MANIFEST.local.json"

    if [ ! -f "$manifest_local" ]; then
        echo "unknown"
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        echo "unknown"
        return 0
    fi

    local version
    version=$(jq -r '.project_version // "unknown"' "$manifest_local" 2>/dev/null)
    echo "${version:-unknown}"
}

# ============================================================================
# migration_needed - Verifica se migracao eh necessaria
# ============================================================================
# Compara versao do projeto vs versao do CLI
# Uso: if migration_needed "/path"; then echo "precisa migrar"; fi
# Retorna: 0 se precisa migrar, 1 se nao precisa
migration_needed() {
    local install_path="${1:-.}"
    local project_version
    project_version=$(migration_get_project_version "$install_path")

    # Se nao tem MANIFEST.local.json, precisa migrar (init nunca rodou stamp)
    if [ "$project_version" = "unknown" ]; then
        return 0
    fi

    local _lib_root="${AIDEV_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/..}"
    local cli_version="${AIDEV_VERSION:-$(cat "$_lib_root/VERSION" 2>/dev/null | tr -d '[:space:]')}"
    cli_version="${cli_version:-0.0.0}"

    # Se versoes sao iguais, nao precisa migrar
    if [ "$project_version" = "$cli_version" ]; then
        return 1
    fi

    # Versoes diferentes = precisa migrar
    return 0
}

# ============================================================================
# migration_list_steps - Lista scripts de migracao aplicaveis
# ============================================================================
# Percorre migrations/ e retorna os que se aplicam entre from e to
# Scripts seguem naming: VERSION-descricao.sh (ex: 4.2.0-add-feature.sh)
# Uso: steps=$(migration_list_steps "4.0.0" "4.3.0")
migration_list_steps() {
    local from_version="$1"
    local to_version="$2"
    local migrations_dir="${AIDEV_MIGRATIONS_DIR}"

    if [ ! -d "$migrations_dir" ]; then
        return 0
    fi

    local script_file script_version
    for script_file in "$migrations_dir"/*.sh; do
        [ -f "$script_file" ] || continue

        # Extrai versao do nome do arquivo (ex: 4.2.0-desc.sh -> 4.2.0)
        script_version=$(basename "$script_file" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
        [ -z "$script_version" ] && continue

        # Verifica se esta no range (from < script_version <= to)
        if _migration_version_gt "$script_version" "$from_version" && \
           ! _migration_version_gt "$script_version" "$to_version"; then
            echo "$script_file"
        fi
    done | sort
}

# ============================================================================
# migration_execute - Executa migracoes com checkpoint entre cada
# ============================================================================
# Uso: migration_execute "/path/to/project" "4.0.0" "4.3.0"
migration_execute() {
    local install_path="${1:-.}"
    local from_version="$2"
    local to_version="$3"

    local steps
    steps=$(migration_list_steps "$from_version" "$to_version")

    if [ -z "$steps" ]; then
        return 0
    fi

    local script_file
    while IFS= read -r script_file; do
        [ -z "$script_file" ] && continue
        [ -f "$script_file" ] || continue

        local script_name
        script_name=$(basename "$script_file")

        # Exporta path para uso dentro do script de migracao
        export MIGRATION_INSTALL_PATH="$install_path"

        # Executa migracao
        if bash "$script_file" 2>/dev/null; then
            print_debug "Migracao executada: $script_name" 2>/dev/null || true
        else
            print_warning "Migracao falhou: $script_name" 2>/dev/null || true
            return 1
        fi
    done <<< "$steps"

    return 0
}

# ============================================================================
# migration_stamp - Grava versao atual no MANIFEST.local.json
# ============================================================================
# Cria ou atualiza .aidev/MANIFEST.local.json com versao do CLI
# Uso: migration_stamp "/path/to/project"
migration_stamp() {
    local install_path="${1:-.}"
    local manifest_local="$install_path/.aidev/MANIFEST.local.json"
    local _lib_root="${AIDEV_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/..}"
    local cli_version="${AIDEV_VERSION:-$(cat "$_lib_root/VERSION" 2>/dev/null | tr -d '[:space:]')}"
    cli_version="${cli_version:-0.0.0}"
    local timestamp
    timestamp=$(date -Iseconds 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")

    mkdir -p "$(dirname "$manifest_local")" 2>/dev/null || true

    if [ -f "$manifest_local" ] && command -v jq &>/dev/null; then
        # Atualiza existente
        local tmp_file
        tmp_file=$(mktemp)
        jq --arg pv "$cli_version" \
           --arg lu "$timestamp" \
           '.project_version = $pv | .last_upgrade = $lu' \
           "$manifest_local" > "$tmp_file" && mv "$tmp_file" "$manifest_local"
    else
        # Cria novo
        cat > "$manifest_local" << EOF
{
  "project_version": "$cli_version",
  "cli_version_at_init": "$cli_version",
  "last_upgrade": "$timestamp",
  "files": {}
}
EOF
    fi
}

# ============================================================================
# Helper interno: compara versoes (v1 > v2)
# ============================================================================
_migration_version_gt() {
    local v1="$1"
    local v2="$2"

    local a1 a2
    IFS='.' read -r -a a1 <<< "$v1"
    IFS='.' read -r -a a2 <<< "$v2"

    while [ ${#a1[@]} -lt 3 ]; do a1+=(0); done
    while [ ${#a2[@]} -lt 3 ]; do a2+=(0); done

    for i in 0 1 2; do
        if [ "${a1[$i]}" -gt "${a2[$i]}" ]; then
            return 0
        elif [ "${a1[$i]}" -lt "${a2[$i]}" ]; then
            return 1
        fi
    done

    return 1  # iguais = nao eh maior
}
