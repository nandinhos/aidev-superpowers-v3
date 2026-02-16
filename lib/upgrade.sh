#!/usr/bin/env bash

# ============================================================================
# AI Dev Superpowers V3 - Upgrade Module
# ============================================================================
# Motor de upgrade seguro com checksum, dry-run e backup expandido.
# Usa o manifesto (lib/manifest.sh) para decisoes de escrita.
# ============================================================================

# ============================================================================
# upgrade_compute_checksum - SHA256 de um arquivo
# ============================================================================
# Uso: upgrade_compute_checksum "/path/to/file"
# Retorna: hash SHA256 (stdout), exit 0 sucesso, 1 falha
upgrade_compute_checksum() {
    local filepath="$1"

    if [ ! -f "$filepath" ]; then
        return 1
    fi

    if command -v sha256sum &>/dev/null; then
        sha256sum "$filepath" | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$filepath" | cut -d' ' -f1
    else
        # Fallback: md5
        md5sum "$filepath" 2>/dev/null | cut -d' ' -f1 || return 1
    fi
    return 0
}

# ============================================================================
# upgrade_compare_with_template - Compara arquivo com output do template
# ============================================================================
# Uso: upgrade_compare_with_template "project_file" "template_output"
# Retorna: "identical", "modified" ou "missing" (stdout)
upgrade_compare_with_template() {
    local project_file="$1"
    local template_output="$2"

    if [ ! -f "$project_file" ]; then
        echo "missing"
        return 0
    fi

    if [ ! -f "$template_output" ]; then
        echo "modified"
        return 0
    fi

    local hash_project hash_template
    hash_project=$(upgrade_compute_checksum "$project_file")
    hash_template=$(upgrade_compute_checksum "$template_output")

    if [ "$hash_project" = "$hash_template" ]; then
        echo "identical"
    else
        echo "modified"
    fi
    return 0
}

# ============================================================================
# upgrade_backup_full - Backup expandido de todos os dirs relevantes
# ============================================================================
# Uso: backup_dir=$(upgrade_backup_full "/path/to/project")
# Retorna: path do backup criado (stdout)
upgrade_backup_full() {
    local install_path="$1"
    local aidev_dir="$install_path/.aidev"
    local backup_dir="$aidev_dir/backups/$(date +%Y%m%d%H%M%S)"

    mkdir -p "$backup_dir"

    # Backup de agents, skills, rules e mcp
    # NAO faz backup de state (runtime) nem plans (conteudo do usuario, nao eh tocado)
    for dir_name in agents skills rules mcp; do
        if [ -d "$aidev_dir/$dir_name" ]; then
            cp -r "$aidev_dir/$dir_name" "$backup_dir/" 2>/dev/null || true
        fi
    done

    echo "$backup_dir"
    return 0
}

# ============================================================================
# upgrade_should_overwrite - Decisao inteligente de escrita
# ============================================================================
# Usa manifesto + checksum para decidir se um arquivo deve ser sobrescrito.
# Uso: upgrade_should_overwrite "filepath" "project_root" ["template_output"]
# Retorna: 0 pode sobrescrever, 1 nao sobrescrever
upgrade_should_overwrite() {
    local filepath="$1"
    local project_root="$2"
    local template_output="${3:-}"

    # Extrair path relativo
    local relative_path="${filepath#$project_root/}"

    # Consultar manifesto se disponivel
    if type manifest_get_policy &>/dev/null && [ "$MANIFEST_LOADED" = "true" ]; then
        local policy
        policy=$(manifest_get_policy "$relative_path")

        case "$policy" in
            never_overwrite|never_touch|never_modify_in_project)
                return 1
                ;;
        esac
    fi

    # Arquivo nao existe: pode escrever
    if [ ! -f "$filepath" ]; then
        return 0
    fi

    # Force ativo: sempre sobrescreve
    if [ "$AIDEV_FORCE" = "true" ]; then
        return 0
    fi

    # Se temos o output do template, comparar checksums
    if [ -n "$template_output" ] && [ -f "$template_output" ]; then
        local comparison
        comparison=$(upgrade_compare_with_template "$filepath" "$template_output")

        case "$comparison" in
            identical)
                # Arquivo identico ao template: pode sobrescrever (atualizar)
                return 0
                ;;
            modified)
                # Usuario customizou: nao sobrescrever
                return 1
                ;;
        esac
    fi

    # Sem template para comparar: comportamento conservador (nao sobrescrever)
    return 1
}

# ============================================================================
# upgrade_dry_run - Preview de mudancas sem aplicar
# ============================================================================
# Uso: upgrade_dry_run "/path/to/project"
# Retorna: lista de acoes que seriam executadas (stdout)
upgrade_dry_run() {
    local install_path="$1"
    local aidev_dir="$install_path/.aidev"

    echo "=== DRY RUN: Upgrade Preview ==="
    echo ""

    # Listar agents
    echo "Agents:"
    shopt -s nullglob
    for f in "$aidev_dir"/agents/*.md; do
        local basename_f
        basename_f=$(basename "$f")
        if upgrade_should_overwrite "$f" "$install_path" 2>/dev/null; then
            echo "  [ATUALIZAR] $basename_f"
        else
            echo "  [PRESERVAR] $basename_f (customizado)"
        fi
    done

    # Listar skills
    echo "Skills:"
    for d in "$aidev_dir"/skills/*/; do
        local skill_file="$d/SKILL.md"
        if [ -f "$skill_file" ]; then
            local skill_name
            skill_name=$(basename "$d")
            if upgrade_should_overwrite "$skill_file" "$install_path" 2>/dev/null; then
                echo "  [ATUALIZAR] $skill_name/SKILL.md"
            else
                echo "  [PRESERVAR] $skill_name/SKILL.md (customizado)"
            fi
        fi
    done

    # Listar rules
    echo "Rules:"
    for f in "$aidev_dir"/rules/*.md; do
        local basename_r
        basename_r=$(basename "$f")
        if upgrade_should_overwrite "$f" "$install_path" 2>/dev/null; then
            echo "  [ATUALIZAR] $basename_r"
        else
            echo "  [PRESERVAR] $basename_r (customizado)"
        fi
    done
    shopt -u nullglob

    echo ""
    echo "=== FIM DRY RUN ==="
    return 0
}

# ============================================================================
# upgrade_record_checksums - Registra checksums pos-upgrade
# ============================================================================
# Uso: upgrade_record_checksums "/path/to/project"
# Cria: .aidev/state/checksums.json
upgrade_record_checksums() {
    local install_path="$1"
    local aidev_dir="$install_path/.aidev"
    local checksums_file="$aidev_dir/state/checksums.json"

    # Garantir diretorio
    mkdir -p "$aidev_dir/state"

    # Iniciar JSON
    local json='{'
    json+='"generated_at":"'"$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)"'",'
    json+='"aidev_version":"'"${AIDEV_VERSION:-unknown}"'",'
    json+='"files":{'

    local first=true

    shopt -s nullglob

    # Agents
    for f in "$aidev_dir"/agents/*.md; do
        local rel_path=".aidev/agents/$(basename "$f")"
        local hash
        hash=$(upgrade_compute_checksum "$f")
        if [ "$first" = true ]; then
            first=false
        else
            json+=','
        fi
        json+='"'"$rel_path"'":{"checksum":"'"$hash"'"}'
    done

    # Skills
    for d in "$aidev_dir"/skills/*/; do
        local skill_file="$d/SKILL.md"
        if [ -f "$skill_file" ]; then
            local skill_name
            skill_name=$(basename "$d")
            local rel_path=".aidev/skills/$skill_name/SKILL.md"
            local hash
            hash=$(upgrade_compute_checksum "$skill_file")
            if [ "$first" = true ]; then
                first=false
            else
                json+=','
            fi
            json+='"'"$rel_path"'":{"checksum":"'"$hash"'"}'
        fi
    done

    # Rules
    for f in "$aidev_dir"/rules/*.md; do
        local rel_path=".aidev/rules/$(basename "$f")"
        local hash
        hash=$(upgrade_compute_checksum "$f")
        if [ "$first" = true ]; then
            first=false
        else
            json+=','
        fi
        json+='"'"$rel_path"'":{"checksum":"'"$hash"'"}'
    done

    shopt -u nullglob

    json+='}}'

    # Escrever com jq se disponivel (para formatacao), senao raw
    if command -v jq &>/dev/null; then
        echo "$json" | jq '.' > "$checksums_file"
    else
        echo "$json" > "$checksums_file"
    fi

    return 0
}
