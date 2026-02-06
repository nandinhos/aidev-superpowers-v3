#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Release Module
# ============================================================================
# Automacao de bump de versao em todos os arquivos mapeados
#
# Uso: source lib/release.sh
# Dependencias: lib/core.sh
# ============================================================================

# Arquivos onde a versao aparece como fallback ou referencia
# Formato: "caminho_relativo:padrao_sed"
# O padrao usa CURRENT como placeholder para a versao atual
readonly RELEASE_VERSION_FILES=(
    "lib/core.sh"
    "lib/cli.sh"
    "lib/cache.sh"
    "README.md"
    "tests/unit/test-core.sh"
)

# ============================================================================
# Calculo de Versao
# ============================================================================

# Le a versao atual do SSOT (lib/core.sh)
# Uso: current=$(release_get_current_version "/path/to/project")
release_get_current_version() {
    local project_path="${1:-.}"
    local core_file="$project_path/lib/core.sh"

    if [ ! -f "$core_file" ]; then
        echo ""
        return 1
    fi

    grep "AIDEV_VERSION" "$core_file" | grep -oP '\d+\.\d+\.\d+' | head -1
}

# Calcula a proxima versao baseado no tipo de bump
# Uso: next=$(release_calc_next_version "3.5.0" "minor")
release_calc_next_version() {
    local current="$1"
    local bump_type="${2:-patch}"

    local major minor patch
    IFS='.' read -r major minor patch <<< "$current"

    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        current)
            # Nao incrementa, apenas sincroniza fallbacks
            ;;
        *)
            print_error "Tipo de bump invalido: $bump_type (use major, minor, patch, current)"
            return 1
            ;;
    esac

    echo "${major}.${minor}.${patch}"
}

# ============================================================================
# Discovery - Encontra todos os pontos de versao
# ============================================================================

# Busca todos os arquivos que contem a versao atual
# Uso: release_discover_version_points "3.5.0" "/path/to/project"
release_discover_version_points() {
    local version="$1"
    local project_path="${2:-.}"
    local escaped_version="${version//./\\.}"

    grep -rl "$escaped_version" "$project_path" \
        --include="*.sh" --include="*.md" --include="*.json" --include="*.yaml" --include="*.yml" \
        --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor \
        --exclude-dir=.aidev/backups --exclude-dir=.aidev/.cache \
        2>/dev/null || true
}

# ============================================================================
# Bump Automatico
# ============================================================================

# Atualiza a versao em todos os arquivos mapeados
# Uso: release_bump_version "3.5.0" "3.6.2" "/path/to/project"
release_bump_version() {
    local old_version="$1"
    local new_version="$2"
    local project_path="${3:-.}"
    local files_updated=0
    local files_failed=0
    local escaped_old="${old_version//./\\.}"

    print_section "Bump de Versao: $old_version -> $new_version"

    # 1. SSOT: lib/core.sh
    local core_file="$project_path/lib/core.sh"
    if [ -f "$core_file" ]; then
        if sed -i "s/AIDEV_VERSION:-${escaped_old}/AIDEV_VERSION:-${new_version}/" "$core_file"; then
            print_success "lib/core.sh (SSOT)"
            ((files_updated++)) || true
        else
            print_error "lib/core.sh"
            ((files_failed++)) || true
        fi
    fi

    # 2. Fallbacks: lib/cli.sh
    local cli_file="$project_path/lib/cli.sh"
    if [ -f "$cli_file" ]; then
        if sed -i "s/AIDEV_VERSION:-${escaped_old}/AIDEV_VERSION:-${new_version}/g" "$cli_file"; then
            print_success "lib/cli.sh (fallbacks)"
            ((files_updated++)) || true
        else
            print_error "lib/cli.sh"
            ((files_failed++)) || true
        fi
    fi

    # 3. Fallback: lib/cache.sh
    local cache_file="$project_path/lib/cache.sh"
    if [ -f "$cache_file" ]; then
        if sed -i "s/AIDEV_VERSION:-${escaped_old}/AIDEV_VERSION:-${new_version}/g" "$cache_file"; then
            print_success "lib/cache.sh (fallback)"
            ((files_updated++)) || true
        else
            print_error "lib/cache.sh"
            ((files_failed++)) || true
        fi
    fi

    # 4. README badge
    local readme_file="$project_path/README.md"
    if [ -f "$readme_file" ]; then
        if sed -i "s/version-${escaped_old}-blue/version-${new_version}-blue/g" "$readme_file"; then
            print_success "README.md (badge)"
            ((files_updated++)) || true
        else
            print_error "README.md"
            ((files_failed++)) || true
        fi
    fi

    # 5. Teste unitario
    local test_file="$project_path/tests/unit/test-core.sh"
    if [ -f "$test_file" ]; then
        # Atualiza qualquer versao hardcoded no assert de AIDEV_VERSION
        if sed -i "s/assert_equals \"[0-9]\+\.[0-9]\+\.[0-9]\+\" \"\$AIDEV_VERSION\"/assert_equals \"${new_version}\" \"\$AIDEV_VERSION\"/" "$test_file" && \
           sed -i "s/AIDEV_VERSION = [0-9]\+\.[0-9]\+\.[0-9]\+/AIDEV_VERSION = ${new_version}/" "$test_file"; then
            print_success "tests/unit/test-core.sh (assert)"
            ((files_updated++)) || true
        else
            print_error "tests/unit/test-core.sh"
            ((files_failed++)) || true
        fi
    fi

    # 6. Discovery: busca pontos que possam ter ficado para tras
    echo ""
    print_step "Discovery: verificando pontos adicionais..."
    local extra_files
    extra_files=$(release_discover_version_points "$old_version" "$project_path")

    if [ -n "$extra_files" ]; then
        print_warning "Arquivos ainda com versao antiga ($old_version):"
        echo "$extra_files" | while read -r f; do
            # Mostra caminho relativo
            local rel_path="${f#$project_path/}"
            echo "  - $rel_path"
        done
        echo ""
        print_info "Estes arquivos podem precisar de atualizacao manual (ex: CHANGELOG.md)"
    else
        print_success "Nenhum ponto residual encontrado"
    fi

    echo ""
    print_info "Arquivos atualizados: $files_updated | Falhas: $files_failed"

    if [ "$files_failed" -gt 0 ]; then
        return 1
    fi
    return 0
}

# ============================================================================
# Rebuild Cache
# ============================================================================

# Reconstroi o cache de ativacao apos bump
# Uso: release_rebuild_cache "/path/to/project"
release_rebuild_cache() {
    local project_path="${1:-.}"
    local cache_dir="$project_path/.aidev/.cache"
    local cache_file="$cache_dir/activation_cache.json"

    if [ -f "$cache_file" ]; then
        print_step "Reconstruindo cache de ativacao..."
        # Usa a funcao do modulo cache se disponivel
        if type generate_activation_cache &>/dev/null; then
            local cache_json
            cache_json=$(generate_activation_cache "$project_path")
            if [ -n "$cache_json" ] && [ "$cache_json" != '{"error": "no_aidev_dir"}' ]; then
                echo "$cache_json" > "$cache_file"
                print_success "Cache reconstruido"
                return 0
            fi
        fi
        # Fallback: remove cache para forcar reconstrucao
        rm -f "$cache_file"
        print_info "Cache removido (sera reconstruido no proximo 'aidev cache --build')"
    fi
}

# ============================================================================
# Fluxo Completo
# ============================================================================

# Executa o bump completo: calcula versao, atualiza arquivos, reconstroi cache
# Uso: release_execute_bump "minor" "/path/to/project"
# Retorna: 0 se sucesso, 1 se falha
release_execute_bump() {
    local bump_type="${1:-patch}"
    local project_path="${2:-.}"

    # 1. Le versao atual
    local current_version
    current_version=$(release_get_current_version "$project_path")
    if [ -z "$current_version" ]; then
        print_error "Nao foi possivel ler a versao atual de lib/core.sh"
        return 1
    fi

    # 2. Calcula nova versao
    local new_version
    new_version=$(release_calc_next_version "$current_version" "$bump_type")
    if [ -z "$new_version" ]; then
        print_error "Falha ao calcular nova versao"
        return 1
    fi

    print_info "Versao atual: $current_version"
    print_info "Nova versao:  $new_version ($bump_type)"
    echo ""

    # Exporta versoes para uso no prompt (inclusive em dry-run)
    export RELEASE_OLD_VERSION="$current_version"
    export RELEASE_NEW_VERSION="$new_version"

    # 3. Confirma se nao e dry-run
    if [ "${AIDEV_DRY_RUN:-false}" = true ]; then
        print_info "[DRY-RUN] Arquivos que seriam atualizados:"
        for f in "${RELEASE_VERSION_FILES[@]}"; do
            [ -f "$project_path/$f" ] && echo "  - $f"
        done
        return 0
    fi

    # 4. Bump em todos os arquivos
    release_bump_version "$current_version" "$new_version" "$project_path"
    local bump_result=$?

    # 5. Reconstroi cache
    load_module "cache" 2>/dev/null || true
    release_rebuild_cache "$project_path"

    return $bump_result
}
