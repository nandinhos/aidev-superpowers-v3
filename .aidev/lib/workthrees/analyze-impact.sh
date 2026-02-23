#!/bin/bash
set -euo pipefail

AIDEV_ROOT="${AIDEV_ROOT:-.aidev}"

usage() {
    cat <<EOF
USAGE: analyze-impact.sh [OPTIONS]

Analisa impacto de uma tarefa, detectando arquivos afetados.

OPTIONS:
    --task-id ID          ID da tarefa (obrigatorio)
    --description TEXT   Descricao da tarefa
    --files FILE1,FILE2  Arquivos ja conhecidos (opcional)
    -h, --help           Mostra esta ajuda

EXEMPLO:
    analyze-impact.sh --task-id "feat-001" --description "Criar componente de login"
    analyze-impact.sh --task-id "feat-001" --files "src/auth/login.ts,src/auth/hooks.ts"
EOF
    exit 1
}

TASK_ID=""
DESCRIPTION=""
FILES_INPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-id) TASK_ID="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --files) FILES_INPUT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [[ -z "$TASK_ID" ]]; then
    echo "ERROR: --task-id e obrigatorio" >&2
    usage
fi

PROJECT_ROOT="$(pwd)"
MODULES=()
DETECTED_FILES=()

detect_modules() {
    local base_dirs=("src/" "lib/" "app/" "packages/" "modules/")
    
    for dir in "${base_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            for module in "$PROJECT_ROOT/$dir"/*/; do
                if [[ -d "$module" ]]; then
                    MODULES+=("$(basename "$module")")
                fi
            done
        fi
    done
}

parse_description() {
    local desc="$1"
    local keywords=("auth" "login" "user" "dashboard" "api" "config" "database" "db" "test" "component" "service" "model" "controller" "route" "middleware" "hook" "context" "store" "state")
    
    for keyword in "${keywords[@]}"; do
        if echo "$desc" | grep -qi "$keyword"; then
            case "$keyword" in
                auth|login|user)
                    DETECTED_FILES+=("src/auth/" "src/users/" "src/components/auth/")
                    MODULES+=("auth" "users")
                    ;;
                dashboard)
                    DETECTED_FILES+=("src/dashboard/" "src/pages/dashboard")
                    MODULES+=("dashboard")
                    ;;
                api|route|controller)
                    DETECTED_FILES+=("src/api/" "src/routes/" "src/controllers/")
                    MODULES+=("api" "routes")
                    ;;
                config)
                    DETECTED_FILES+=("config/" ".env" "src/config/")
                    MODULES+=("config")
                    ;;
                database|db)
                    DETECTED_FILES+=("src/database/" "prisma/" "migrations/")
                    MODULES+=("database")
                    ;;
                test)
                    DETECTED_FILES+=("tests/" "__tests__/" "spec/")
                    MODULES+=("tests")
                    ;;
                component)
                    DETECTED_FILES+=("src/components/")
                    MODULES+=("components")
                    ;;
                service)
                    DETECTED_FILES+=("src/services/")
                    MODULES+=("services")
                    ;;
                model)
                    DETECTED_FILES+=("src/models/")
                    MODULES+=("models")
                    ;;
                middleware)
                    DETECTED_FILES+=("src/middleware/")
                    MODULES+=("middleware")
                    ;;
                hook|context|store|state)
                    DETECTED_FILES+=("src/hooks/" "src/context/" "src/store/")
                    MODULES+=("hooks" "context" "store")
                    ;;
            esac
        fi
    done
}

build_file_list() {
    local all_files=()
    
    if [[ -n "$FILES_INPUT" ]]; then
        IFS=',' read -ra ADDR <<< "$FILES_INPUT"
        for f in "${ADDR[@]}"; do
            all_files+=("$f")
        done
    fi
    
    for f in "${DETECTED_FILES[@]}"; do
        all_files+=("$f")
    done
    
    if [[ ${#all_files[@]} -eq 0 ]]; then
        all_files=("src/" "lib/")
    fi
    
    local unique_files=($(printf '%s\n' "${all_files[@]}" | sort -u))
    DETECTED_FILES=("${unique_files[@]}")
}

detect_modules
[[ -n "$DESCRIPTION" ]] && parse_description "$DESCRIPTION"
build_file_list

UNIQUE_MODULES=($(printf '%s\n' "${MODULES[@]}" | sort -u | tr '\n' ' '))

cat <<EOF
{
  "task_id": "$TASK_ID",
  "files": $(printf '%s\n' "${DETECTED_FILES[@]}" | jq -R . | jq -s .),
  "modules": $(printf '%s\n' "${MODULES[@]}" | sort -u | jq -R . | jq -s .),
  "detection_method": "${DESCRIPTION:+keyword}${FILES_INPUT:+files_input}${DESCRIPTION:+_}${FILES_INPUT:+_}mixed",
  "confidence": $([ ${#DETECTED_FILES[@]} -gt 0 ] && echo "0.8" || echo "0.3")
}
EOF
