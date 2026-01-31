#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Detection Module
# ============================================================================
# Funções para detecção de stack, plataforma e contexto do projeto
# 
# Uso: source lib/detection.sh
# Dependências: lib/core.sh
# ============================================================================

# Variáveis de resultado de detecção
DETECTED_STACK=""
DETECTED_PLATFORM=""
DETECTED_LANGUAGE=""
DETECTED_PROJECT_NAME=""

# ============================================================================
# Detecção de Stack
# ============================================================================

# Detecta stack do projeto baseado em arquivos de configuração
# Uso: detect_stack "/path/to/project"
# Retorna: nome da stack detectada
detect_stack() {
    local path="${1:-.}"
    
    if [ ! -d "$path" ]; then
        echo "generic"
        return
    fi
    
    # Salva diretório atual
    local original_dir="$PWD"
    cd "$path" || { echo "generic"; return; }
    
    # Laravel/PHP
    if [ -f "composer.json" ]; then
        if grep -q "laravel/framework" composer.json 2>/dev/null; then
            if grep -q "filament" composer.json 2>/dev/null; then
                cd "$original_dir"
                echo "filament"
                return
            elif grep -q "livewire" composer.json 2>/dev/null; then
                cd "$original_dir"
                echo "livewire"
                return
            else
                cd "$original_dir"
                echo "laravel"
                return
            fi
        fi
        # PHP genérico
        cd "$original_dir"
        echo "php"
        return
    fi
    
    # Node.js
    if [ -f "package.json" ]; then
        if grep -q "\"next\"" package.json 2>/dev/null; then
            cd "$original_dir"
            echo "nextjs"
            return
        elif grep -q "\"react\"" package.json 2>/dev/null; then
            cd "$original_dir"
            echo "react"
            return
        elif grep -q "\"vue\"" package.json 2>/dev/null; then
            cd "$original_dir"
            echo "vue"
            return
        elif grep -q "\"express\"" package.json 2>/dev/null; then
            cd "$original_dir"
            echo "express"
            return
        else
            cd "$original_dir"
            echo "node"
            return
        fi
    fi
    
    # Python
    if [ -f "pyproject.toml" ]; then
        if grep -q "django" pyproject.toml 2>/dev/null; then
            cd "$original_dir"
            echo "django"
            return
        elif grep -q "fastapi" pyproject.toml 2>/dev/null; then
            cd "$original_dir"
            echo "fastapi"
            return
        elif grep -q "flask" pyproject.toml 2>/dev/null; then
            cd "$original_dir"
            echo "flask"
            return
        fi
        cd "$original_dir"
        echo "python"
        return
    fi
    
    if [ -f "requirements.txt" ]; then
        if grep -q "django" requirements.txt 2>/dev/null; then
            cd "$original_dir"
            echo "django"
            return
        elif grep -q "fastapi" requirements.txt 2>/dev/null; then
            cd "$original_dir"
            echo "fastapi"
            return
        fi
        cd "$original_dir"
        echo "python"
        return
    fi
    
    if [ -f "setup.py" ]; then
        cd "$original_dir"
        echo "python"
        return
    fi
    
    # Ruby
    if [ -f "Gemfile" ]; then
        if grep -q "rails" Gemfile 2>/dev/null; then
            cd "$original_dir"
            echo "rails"
            return
        fi
        cd "$original_dir"
        echo "ruby"
        return
    fi
    
    # Go
    if [ -f "go.mod" ]; then
        cd "$original_dir"
        echo "go"
        return
    fi
    
    # Rust
    if [ -f "Cargo.toml" ]; then
        cd "$original_dir"
        echo "rust"
        return
    fi
    
    cd "$original_dir"
    echo "generic"
}

# ============================================================================
# Detecção de Plataforma
# ============================================================================

# Detecta plataforma de IA disponível
# Uso: detect_platform
# Retorna: nome da plataforma detectada
detect_platform() {
    # Antigravity (prioridade - ambiente atual)
    if [ -d "$HOME/.gemini/antigravity" ]; then
        echo "antigravity"
        return
    fi
    
    # Claude Code
    if command -v claude &> /dev/null; then
        echo "claude-code"
        return
    fi
    
    # Gemini CLI
    if command -v gemini &> /dev/null; then
        echo "gemini"
        return
    fi
    
    # OpenCode
    if [ -d "$HOME/.config/opencode" ] || command -v opencode &> /dev/null; then
        echo "opencode"
        return
    fi
    
    # Rovo
    if command -v rovo &> /dev/null; then
        echo "rovo"
        return
    fi
    
    # Codex
    if [ -d "$HOME/.codex" ] || command -v codex &> /dev/null; then
        echo "codex"
        return
    fi
    
    # Aider
    if command -v aider &> /dev/null; then
        echo "aider"
        return
    fi
    
    # Cursor (verificando processo ou instalação)
    if [ -d "/Applications/Cursor.app" ] || [ -d "$HOME/.cursor" ]; then
        echo "cursor"
        return
    fi
    
    # Continue.dev
    if [ -d "$HOME/.continue" ]; then
        echo "continue"
        return
    fi
    
    echo "generic"
}

# ============================================================================
# Detecção de Linguagem Principal
# ============================================================================

# Detecta linguagem principal do projeto
# Uso: detect_language "/path/to/project"
detect_language() {
    local path="${1:-.}"
    
    # Baseado nos arquivos de configuração
    if [ -f "$path/composer.json" ]; then
        echo "php"
        return
    fi
    
    if [ -f "$path/package.json" ]; then
        if [ -f "$path/tsconfig.json" ]; then
            echo "typescript"
        else
            echo "javascript"
        fi
        return
    fi
    
    if [ -f "$path/pyproject.toml" ] || [ -f "$path/requirements.txt" ] || [ -f "$path/setup.py" ]; then
        echo "python"
        return
    fi
    
    if [ -f "$path/Gemfile" ]; then
        echo "ruby"
        return
    fi
    
    if [ -f "$path/go.mod" ]; then
        echo "go"
        return
    fi
    
    if [ -f "$path/Cargo.toml" ]; then
        echo "rust"
        return
    fi
    
    if [ -f "$path/pom.xml" ] || [ -f "$path/build.gradle" ]; then
        echo "java"
        return
    fi
    
    if [ -f "$path/*.csproj" ] || [ -f "$path/*.sln" ]; then
        echo "csharp"
        return
    fi
    
    echo "unknown"
}

# ============================================================================
# Detecção de Nome do Projeto
# ============================================================================

# Detecta nome do projeto
# Uso: detect_project_name "/path/to/project"
detect_project_name() {
    local path="${1:-.}"
    
    # Tenta extrair de package.json
    if [ -f "$path/package.json" ]; then
        local name=$(grep -o '"name":[[:space:]]*"[^"]*"' "$path/package.json" | head -1 | sed 's/.*"name":[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -n "$name" ]; then
            echo "$name"
            return
        fi
    fi
    
    # Tenta extrair de composer.json
    if [ -f "$path/composer.json" ]; then
        local name=$(grep -o '"name":[[:space:]]*"[^"]*"' "$path/composer.json" | head -1 | sed 's/.*"name":[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -n "$name" ]; then
            # Remove prefixo vendor/ se existir
            echo "${name##*/}"
            return
        fi
    fi
    
    # Tenta extrair de pyproject.toml
    if [ -f "$path/pyproject.toml" ]; then
        local name=$(grep -o '^name[[:space:]]*=[[:space:]]*"[^"]*"' "$path/pyproject.toml" | sed 's/.*"\([^"]*\)".*/\1/')
        if [ -n "$name" ]; then
            echo "$name"
            return
        fi
    fi
    
    # Fallback: nome do diretório
    basename "$(cd "$path" && pwd)"
}

# ============================================================================
# Detecção de Contexto Completo
# ============================================================================

# Detecta todo o contexto do projeto e popula variáveis globais
# Uso: detect_project_context "/path/to/project"
detect_project_context() {
    local path="${1:-.}"
    
    DETECTED_STACK=$(detect_stack "$path")
    DETECTED_PLATFORM=$(detect_platform)
    DETECTED_LANGUAGE=$(detect_language "$path")
    DETECTED_PROJECT_NAME=$(detect_project_name "$path")
    
    print_debug "Stack detectada: $DETECTED_STACK"
    print_debug "Plataforma detectada: $DETECTED_PLATFORM"
    print_debug "Linguagem detectada: $DETECTED_LANGUAGE"
    print_debug "Nome do projeto: $DETECTED_PROJECT_NAME"
}

# ============================================================================
# Detecção de Módulos Existentes
# ============================================================================

# Verifica se projeto já tem aidev instalado
# Uso: has_aidev_installed "/path/to/project"
has_aidev_installed() {
    local path="${1:-.}"
    [ -d "$path/.aidev" ]
}

# Lista agentes instalados
# Uso: list_installed_agents "/path/to/project"
list_installed_agents() {
    local path="${1:-.}"
    local agents_dir="$path/.aidev/agents"
    
    if [ -d "$agents_dir" ]; then
        find "$agents_dir" -name "*.md" -exec basename {} .md \;
    fi
}

# Lista skills instaladas
# Uso: list_installed_skills "/path/to/project"
list_installed_skills() {
    local path="${1:-.}"
    local skills_dir="$path/.aidev/skills"
    
    if [ -d "$skills_dir" ]; then
        find "$skills_dir" -name "SKILL.md" -exec dirname {} \; | xargs -I{} basename {}
    fi
}
