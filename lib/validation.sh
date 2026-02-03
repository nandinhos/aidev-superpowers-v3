#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3.2 - Validation Module
# ============================================================================
# Sistema de validacao de pre-requisitos para skills e acoes.
#
# Uso: source lib/validation.sh
# Dependencias: lib/core.sh, lib/file-ops.sh, lib/detection.sh
# ============================================================================

# ============================================================================
# CONFIGURACAO
# ============================================================================

# Modo de validacao: "strict" (bloqueia) ou "warning" (apenas avisa)
VALIDATION_MODE="${VALIDATION_MODE:-warning}"

# ============================================================================
# VALIDACOES DE ARQUIVOS/ARTEFATOS
# ============================================================================

# Verifica se documento de design existe
# Uso: if validate_design_exists; then ...; fi
validate_design_exists() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    local design_found=false
    
    # Procura por arquivos de design em locais comuns
    local design_patterns=(
        "$install_path/docs/plans/*-design.md"
        "$install_path/docs/design.md"
        "$install_path/docs/architecture.md"
        "$install_path/design.md"
        "$install_path/DESIGN.md"
    )
    
    for pattern in "${design_patterns[@]}"; do
        # shellcheck disable=SC2086
        if ls $pattern 1>/dev/null 2>&1; then
            design_found=true
            break
        fi
    done
    
    if [ "$design_found" = true ]; then
        validation_log "design_exists" "docs/" "passed"
        return 0
    else
        validation_log "design_exists" "docs/" "failed"
        _validation_handle_failure "Design document not found" \
            "Crie um documento de design em docs/plans/*-design.md ou docs/design.md"
        return 1
    fi
}

# Verifica se plano de implementacao existe
# Uso: if validate_plan_exists; then ...; fi
validate_plan_exists() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    local plan_found=false
    
    local plan_patterns=(
        "$install_path/docs/plans/*-implementation.md"
        "$install_path/docs/plans/*-plan.md"
        "$install_path/implementation_plan.md"
        "$install_path/task.md"
        "$install_path/docs/plan.md"
    )
    
    for pattern in "${plan_patterns[@]}"; do
        # shellcheck disable=SC2086
        if ls $pattern 1>/dev/null 2>&1; then
            plan_found=true
            break
        fi
    done
    
    if [ "$plan_found" = true ]; then
        validation_log "plan_exists" "docs/" "passed"
        return 0
    else
        validation_log "plan_exists" "docs/" "failed"
        _validation_handle_failure "Implementation plan not found" \
            "Crie um plano em docs/plans/*-implementation.md ou task.md"
        return 1
    fi
}

# Verifica se PRD existe
# Uso: if validate_prd_exists; then ...; fi
validate_prd_exists() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    
    if [ -f "$install_path/docs/PRD.md" ] || [ -f "$install_path/PRD.md" ]; then
        validation_log "prd_exists" "PRD.md" "passed"
        return 0
    else
        validation_log "prd_exists" "PRD.md" "failed"
        _validation_handle_failure "PRD not found" \
            "Crie um PRD em docs/PRD.md para projetos greenfield"
        return 1
    fi
}

# ============================================================================
# VALIDACOES DE CODIGO/TESTES
# ============================================================================

# Verifica se testes passam
# Uso: if validate_tests_green; then ...; fi
validate_tests_green() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    local test_cmd=""
    local test_result=0
    
    # Detecta comando de teste baseado na stack
    if [ -f "$install_path/package.json" ]; then
        # Verifica se tem script de test
        if grep -q '"test"' "$install_path/package.json" 2>/dev/null; then
            test_cmd="npm test --silent"
        fi
    elif [ -f "$install_path/composer.json" ]; then
        if [ -f "$install_path/artisan" ]; then
            test_cmd="php artisan test --parallel"
        else
            test_cmd="./vendor/bin/phpunit"
        fi
    elif [ -f "$install_path/pytest.ini" ] || [ -f "$install_path/pyproject.toml" ]; then
        test_cmd="pytest -q"
    elif [ -f "$install_path/Cargo.toml" ]; then
        test_cmd="cargo test --quiet"
    elif [ -f "$install_path/go.mod" ]; then
        test_cmd="go test ./... -v"
    fi
    
    if [ -z "$test_cmd" ]; then
        validation_log "tests_green" "no_tests_configured" "skipped"
        print_warning "Nenhum framework de testes detectado"
        return 0  # Nao bloqueia se nao tem testes
    fi
    
    print_info "Executando testes: $test_cmd"
    
    if (cd "$install_path" && eval "$test_cmd" >/dev/null 2>&1); then
        validation_log "tests_green" "$test_cmd" "passed"
        print_success "Testes passando"
        return 0
    else
        validation_log "tests_green" "$test_cmd" "failed"
        _validation_handle_failure "Tests are failing" \
            "Execute '$test_cmd' para ver os erros"
        return 1
    fi
}

# Verifica cobertura de testes (se disponivel)
# Uso: if validate_test_coverage 80; then ...; fi
validate_test_coverage() {
    local min_coverage="${1:-80}"
    local install_path="${CLI_INSTALL_PATH:-.}"
    
    # Por enquanto, apenas verifica se existe arquivo de cobertura
    local coverage_files=(
        "$install_path/coverage/lcov.info"
        "$install_path/coverage/coverage.xml"
        "$install_path/htmlcov/index.html"
        "$install_path/.coverage"
    )
    
    for file in "${coverage_files[@]}"; do
        if [ -f "$file" ]; then
            validation_log "test_coverage" "$file" "passed"
            return 0
        fi
    done
    
    validation_log "test_coverage" "no_coverage" "skipped"
    print_warning "Arquivo de cobertura nao encontrado"
    return 0  # Nao bloqueia
}

# ============================================================================
# VALIDACOES DE GIT
# ============================================================================

# Verifica se nao ha mudancas nao commitadas
# Uso: if validate_git_clean; then ...; fi
validate_git_clean() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    
    if [ ! -d "$install_path/.git" ]; then
        validation_log "git_clean" "not_a_repo" "skipped"
        return 0
    fi
    
    local status
    status=$(git -C "$install_path" status --porcelain 2>/dev/null)
    
    if [ -z "$status" ]; then
        validation_log "git_clean" "clean" "passed"
        return 0
    else
        validation_log "git_clean" "dirty" "failed"
        _validation_handle_failure "Uncommitted changes detected" \
            "Commit ou stash suas mudancas antes de prosseguir"
        return 1
    fi
}

# Verifica se esta na branch correta
# Uso: if validate_git_branch "main"; then ...; fi
validate_git_branch() {
    local expected_branch="$1"
    local install_path="${CLI_INSTALL_PATH:-.}"
    
    if [ ! -d "$install_path/.git" ]; then
        return 0
    fi
    
    local current_branch
    current_branch=$(git -C "$install_path" branch --show-current 2>/dev/null)
    
    if [ "$current_branch" = "$expected_branch" ]; then
        validation_log "git_branch" "$current_branch" "passed"
        return 0
    else
        validation_log "git_branch" "$current_branch" "failed"
        _validation_handle_failure "Wrong branch: $current_branch (expected: $expected_branch)" \
            "Execute 'git checkout $expected_branch'"
        return 1
    fi
}

# ============================================================================
# VALIDACOES DE AMBIENTE
# ============================================================================

# Verifica se dependencias estao instaladas
# Uso: if validate_dependencies_installed; then ...; fi
validate_dependencies_installed() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    local deps_ok=true
    
    # Node.js
    if [ -f "$install_path/package.json" ]; then
        if [ ! -d "$install_path/node_modules" ]; then
            _validation_handle_failure "node_modules not found" \
                "Execute 'npm install'"
            deps_ok=false
        fi
    fi
    
    # PHP/Composer
    if [ -f "$install_path/composer.json" ]; then
        if [ ! -d "$install_path/vendor" ]; then
            _validation_handle_failure "vendor directory not found" \
                "Execute 'composer install'"
            deps_ok=false
        fi
    fi
    
    # Python
    if [ -f "$install_path/requirements.txt" ] || [ -f "$install_path/pyproject.toml" ]; then
        if ! command -v python3 >/dev/null 2>&1; then
            _validation_handle_failure "Python not found" \
                "Instale Python 3"
            deps_ok=false
        fi
    fi
    
    if [ "$deps_ok" = true ]; then
        validation_log "dependencies" "all" "passed"
        return 0
    else
        validation_log "dependencies" "missing" "failed"
        return 1
    fi
}

# ============================================================================
# VALIDACAO POR SKILL
# ============================================================================

# Valida pre-requisitos para uma skill especifica
# Uso: if validate_prerequisites "writing-plans"; then ...; fi
validate_prerequisites() {
    local skill="$1"
    local all_passed=true
    
    print_info "Validando pre-requisitos para skill: $skill"
    
    case "$skill" in
        "brainstorming")
            # Nenhum pre-requisito obrigatorio
            print_success "Skill brainstorming: nenhum pre-requisito"
            ;;
        
        "meta-planning")
            # Nenhum pre-requisito obrigatorio
            print_success "Skill meta-planning: nenhum pre-requisito"
            ;;
        
        "writing-plans")
            # Requer design aprovado
            if ! validate_design_exists; then
                all_passed=false
            fi
            ;;
        
        "test-driven-development")
            # Requer plano de implementacao
            if ! validate_plan_exists; then
                all_passed=false
            fi
            # Dependencias instaladas
            if ! validate_dependencies_installed; then
                all_passed=false
            fi
            ;;
        
        "code-review")
            # Requer testes passando
            if ! validate_tests_green; then
                all_passed=false
            fi
            # Requer implementacao completa (verificar git)
            # Nao requer git clean, pois pode haver mudancas a revisar
            ;;
        
        "systematic-debugging")
            # Requer dependencias instaladas para rodar
            if ! validate_dependencies_installed; then
                all_passed=false
            fi
            ;;
        
        "learned-lesson")
            # Nenhum pre-requisito
            print_success "Skill learned-lesson: nenhum pre-requisito"
            ;;
        
        *)
            print_warning "Skill desconhecida: $skill (sem validacao de pre-requisitos)"
            ;;
    esac
    
    if [ "$all_passed" = true ]; then
        print_success "Todos os pre-requisitos atendidos para: $skill"
        return 0
    else
        print_error "Pre-requisitos nao atendidos para: $skill"
        return 1
    fi
}

# ============================================================================
# VALIDACAO ANTES DE ACAO
# ============================================================================

# Valida antes de operacoes perigosas
# Uso: if validate_before_action "delete" "/path/to/file"; then ...; fi
validate_before_action() {
    local action="$1"
    local target="$2"
    
    case "$action" in
        "delete"|"remove"|"rm")
            # Verifica path seguro
            if ! _validate_safe_path "$target"; then
                return 1
            fi
            # Verifica se arquivo existe
            if [ ! -e "$target" ]; then
                print_warning "Target does not exist: $target"
                return 1
            fi
            ;;
        
        "modify"|"edit"|"write")
            # Verifica path seguro
            if ! _validate_safe_path "$target"; then
                return 1
            fi
            ;;
        
        "deploy")
            # Requer testes passando
            if ! validate_tests_green; then
                return 1
            fi
            # Requer git clean
            if ! validate_git_clean; then
                return 1
            fi
            ;;
        
        "commit")
            # Nenhuma validacao especial (usuario decide o que commitar)
            ;;
        
        *)
            print_debug "Acao sem validacao especifica: $action"
            ;;
    esac
    
    return 0
}

# ============================================================================
# FUNCOES AUXILIARES
# ============================================================================

# Verifica se path e seguro
_validate_safe_path() {
    local target="$1"
    local dangerous_paths=("/" "$HOME" "/etc" "/usr" "/var" "/bin" "/sbin" "/root")
    local resolved_path
    resolved_path=$(realpath "$target" 2>/dev/null || echo "$target")
    
    for dangerous in "${dangerous_paths[@]}"; do
        if [ "$resolved_path" = "$dangerous" ]; then
            print_error "BLOQUEADO: Operacao em path perigoso: $target"
            validation_log "safe_path" "$target" "blocked"
            return 1
        fi
    done
    
    validation_log "safe_path" "$target" "passed"
    return 0
}

# Trata falha de validacao baseado no modo
_validation_handle_failure() {
    local message="$1"
    local suggestion="$2"
    
    if [ "$VALIDATION_MODE" = "strict" ]; then
        print_error "VALIDACAO FALHOU: $message"
        [ -n "$suggestion" ] && print_info "Sugestao: $suggestion"
        return 1
    else
        print_warning "VALIDACAO: $message"
        [ -n "$suggestion" ] && print_info "Sugestao: $suggestion"
        return 1  # Ainda retorna falha, mas chamador pode ignorar
    fi
}

# Registra validacao no log (reusa de orchestration.sh se disponivel)
validation_log() {
    local validation_type="$1"
    local target="$2"
    local result="$3"
    local install_path="${CLI_INSTALL_PATH:-.}"
    local validation_file="$install_path/.aidev/state/validations.json"
    
    ensure_dir "$(dirname "$validation_file")" 2>/dev/null || mkdir -p "$(dirname "$validation_file")"
    
    if [ ! -f "$validation_file" ]; then
        echo '{"validations": []}' > "$validation_file"
    fi
    
    local timestamp
    timestamp=$(date -Iseconds)
    
    if command -v jq >/dev/null 2>&1; then
        local tmp_file
        tmp_file=$(mktemp)
        jq --arg type "$validation_type" \
           --arg target "$target" \
           --arg result "$result" \
           --arg ts "$timestamp" \
           '.validations += [{"type": $type, "target": $target, "result": $result, "timestamp": $ts}]' \
           "$validation_file" > "$tmp_file" && mv "$tmp_file" "$validation_file"
    fi
    
    print_debug "Validacao registrada: $validation_type -> $result"
}

# ============================================================================
# UTILITARIOS DE CONVENIENCIA
# ============================================================================

# Executa todas as validacoes basicas
# Uso: validate_all_basic
validate_all_basic() {
    local all_passed=true
    
    print_section "Validacoes Basicas"
    
    validate_dependencies_installed || all_passed=false
    validate_git_clean || all_passed=false
    
    if [ "$all_passed" = true ]; then
        print_success "Todas as validacoes basicas passaram"
    else
        print_warning "Algumas validacoes falharam"
    fi
    
    return 0  # Nao bloqueia
}

# Mostra status de todas as validacoes
# Uso: validate_show_status
validate_show_status() {
    local install_path="${CLI_INSTALL_PATH:-.}"
    
    print_section "Status de Validacoes"
    
    echo -n "  Design:       "
    validate_design_exists >/dev/null 2>&1 && echo "✓" || echo "✗"
    
    echo -n "  Plano:        "
    validate_plan_exists >/dev/null 2>&1 && echo "✓" || echo "✗"
    
    echo -n "  PRD:          "
    validate_prd_exists >/dev/null 2>&1 && echo "✓" || echo "✗"
    
    echo -n "  Testes:       "
    validate_tests_green >/dev/null 2>&1 && echo "✓" || echo "✗"
    
    echo -n "  Git Clean:    "
    validate_git_clean >/dev/null 2>&1 && echo "✓" || echo "✗"
    
    echo -n "  Dependencias: "
    validate_dependencies_installed >/dev/null 2>&1 && echo "✓" || echo "✗"
    
    echo ""
}
