#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Plans & Roadmap Module
# ============================================================================
# Gestão de Roadmaps, Sprints e Features baseada na metodologia SGAITI
# ============================================================================

# Inicializa a estrutura de planos no projeto
plans__init_structure() {
    local project_path="${1:-.}"
    mkdir -p "$project_path/.aidev/plans/features"
    mkdir -p "$project_path/.aidev/plans/history"
    
    if [ ! -f "$project_path/.aidev/plans/ROADMAP.md" ]; then
        plans__generate_from_template "ROADMAP.md.tmpl" "$project_path/.aidev/plans/ROADMAP.md"
        print_success "Estrutura de planos inicializada em .aidev/plans/"
    fi
}

# Gera arquivo a partir de template com substituição simples
plans__generate_from_template() {
    local template_name="$1"
    local target_path="$2"
    local template_file="$AIDEV_TEMPLATES_DIR/plans/$template_name"
    
    if [ ! -f "$template_file" ]; then
        # Fallback para o diretório de templates do source
        template_file="$(dirname "$0")/../templates/plans/$template_name"
    fi

    if [ -f "$template_file" ]; then
        sed "s/{{PROJECT_NAME}}/$(basename "$PWD")/g; s/{{DATE}}/$(date +%Y-%m-%d)/g" "$template_file" > "$target_path"
    else
        print_error "Template não encontrado: $template_name"
        return 1
    fi
}

# Adiciona uma nova funcionalidade (Feature)
plans__feature_add() {
    local feature_name="$1"
    local sprint_num="${2:-1}"
    
    if [ -z "$feature_name" ]; then
        print_error "Uso: aidev feature add <nome-da-feature> [sprint]"
        return 1
    fi

    local safe_name=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local target_file=".aidev/plans/features/$safe_name.md"

    # Garante que o diretório exista (v3.7)
    mkdir -p ".aidev/plans/features"

    if [ -f "$target_file" ]; then
        print_warning "Feature '$feature_name' já existe em $target_file"
        return 0
    fi

    plans__generate_from_template "FEATURE.md.tmpl" "$target_file"
    
    # Customização específica para feature
    sed -i "s/{{FEATURE_NAME}}/$feature_name/g" "$target_file"
    sed -i "s/{{SPRINT_NUMBER}}/$sprint_num/g" "$target_file"
    
    print_success "Feature '$feature_name' criada em $target_file"
}

# Finaliza uma feature e move para o histórico
plans__feature_finish() {
    local feature_name="$1"
    
    if [ -z "$feature_name" ]; then
        print_error "Uso: aidev feature finish <nome-da-feature>"
        return 1
    fi

    local safe_name=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local source_file=".aidev/plans/features/$safe_name.md"
    local history_dir=".aidev/plans/history/$(date +%Y-%m)"

    if [ ! -f "$source_file" ]; then
        print_error "Feature '$feature_name' não encontrada em .aidev/plans/features/"
        return 1
    fi

    mkdir -p "$history_dir"
    mv "$source_file" "$history_dir/$safe_name-$(date +%d).md"
    
    print_success "Feature '$feature_name' finalizada e movida para o histórico."
    print_info "Não esqueça de atualizar o ROADMAP.md!"
}
