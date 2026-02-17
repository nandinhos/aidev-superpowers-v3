#!/bin/bash

# ============================================================================
# Antigravity Bootstrap - Script Unificado
# ============================================================================
# Combina os melhores aspectos de:
# - bootstrap-antigravity.sh (CLI rico, detecção de stack, templates)
# - setup_antigravity.sh (hooks, skills, state)
# - antigravity-init.sh (integração MCP Engine)
#
# Uso: ./antigravity-bootstrap.sh [OPTIONS]
#
# Modos de Operação:
#   --mode new       Sistema novo (PRD-based) - context.md extraído do PRD
#   --mode refactor  Sistema existente - context.md da análise estrutural
#   --mode minimal   Estrutura básica apenas
#   --mode full      Instalação completa (padrão)
#
# Configuração:
#   --stack <stack>  laravel|filament|livewire|node|react|nextjs|python|generic
#   --prd <path>     Caminho para PRD (modo new)
#   --detect         Auto-detecta stack (padrão)
#
# Comportamento:
#   --force          Sobrescreve existentes
#   --dry-run        Mostra sem executar
#   --no-mcp         Não configura MCP Engine
#   --no-hooks       Não configura Claude hooks
#   -h, --help       Ajuda
# ============================================================================

# Não usar set -e pois (( var++ )) retorna 1 quando var=0
# set -e

# ============================================================================
# Cores para Output
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ============================================================================
# Configurações Padrão
# ============================================================================

MODE="full"
STACK="generic"
FORCE=false
DRY_RUN=false
AUTO_DETECT=true
NO_MCP=false
NO_HOOKS=false
PRD_PATH=""
PROJECT_NAME=$(basename "$(pwd)")
SCRIPT_VERSION="2.0.0"

# Contadores de arquivos
FILES_CREATED=0
FILES_SKIPPED=0
DIRS_CREATED=0

# ============================================================================
# Funções de Output
# ============================================================================

print_header() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}Antigravity Bootstrap${NC} v${SCRIPT_VERSION}                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}Sistema Unificado de Governança de IA${NC}                             ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_step() {
    echo -e "\n${CYAN}━━━${NC} $1 ${CYAN}━━━${NC}"
}

print_mode() {
    local mode_color=""
    case "$MODE" in
        "new")     mode_color="${GREEN}" ;;
        "refactor") mode_color="${YELLOW}" ;;
        "minimal") mode_color="${BLUE}" ;;
        "full")    mode_color="${MAGENTA}" ;;
    esac
    echo -e "  ${CYAN}Mode:${NC} ${mode_color}${MODE}${NC}"
}

# ============================================================================
# Funções de Ajuda
# ============================================================================

show_help() {
    echo -e "${CYAN}Antigravity Bootstrap${NC} v${SCRIPT_VERSION}"
    echo -e "${YELLOW}Sistema Unificado de Governança de IA${NC}"
    echo ""
    echo -e "${YELLOW}Uso:${NC}"
    echo "  ./antigravity-bootstrap.sh [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Modos de Operação (mutuamente exclusivos):${NC}"
    echo "  --mode new        Sistema novo baseado em PRD"
    echo "                    - Cria context.md extraído do PRD"
    echo "                    - project-docs/ com templates vazios"
    echo "                    - Workflows de criação"
    echo ""
    echo "  --mode refactor   Sistema existente para refatoração"
    echo "                    - Analisa código existente"
    echo "                    - context.md da análise estrutural"
    echo "                    - Agentes especializados (legacy-analyzer, security-guardian)"
    echo ""
    echo "  --mode minimal    Estrutura mínima"
    echo "                    - Apenas diretórios e arquivos essenciais"
    echo "                    - Sem regras específicas de stack"
    echo ""
    echo "  --mode full       Instalação completa (padrão)"
    echo "                    - Todos os agentes, rules, workflows, skills"
    echo "                    - MCP Engine configurado"
    echo ""
    echo -e "${YELLOW}Configuração:${NC}"
    echo "  --stack <stack>   Especifica stack manualmente"
    echo "  --prd <path>      Caminho para PRD (obrigatório para --mode new)"
    echo "  --detect          Auto-detecta stack (padrão)"
    echo ""
    echo -e "${YELLOW}Comportamento:${NC}"
    echo "  --force           Sobrescreve arquivos existentes"
    echo "  --dry-run         Mostra o que seria criado sem executar"
    echo "  --no-mcp          Não configura MCP Engine"
    echo "  --no-hooks        Não configura Claude hooks"
    echo "  -h, --help        Mostra esta ajuda"
    echo ""
    echo -e "${YELLOW}Stacks suportadas:${NC}"
    echo "  laravel           PHP + Laravel"
    echo "  filament          PHP + Laravel + Filament"
    echo "  livewire          PHP + Laravel + Livewire"
    echo "  node              Node.js genérico"
    echo "  react             Node + React"
    echo "  nextjs            Node + Next.js"
    echo "  python            Python"
    echo "  generic           Apenas regras base"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  ./antigravity-bootstrap.sh --mode new --prd docs/prd.md"
    echo "  ./antigravity-bootstrap.sh --mode refactor"
    echo "  ./antigravity-bootstrap.sh --mode full --stack laravel"
    echo "  ./antigravity-bootstrap.sh --dry-run"
    echo ""
}

# ============================================================================
# Parse de Argumentos
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                MODE="$2"
                shift 2
                ;;
            --stack)
                STACK="$2"
                AUTO_DETECT=false
                shift 2
                ;;
            --prd)
                PRD_PATH="$2"
                shift 2
                ;;
            --detect)
                AUTO_DETECT=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-mcp)
                NO_MCP=true
                shift
                ;;
            --no-hooks)
                NO_HOOKS=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Opção desconhecida: $1"
                echo "Use --help para ver opções disponíveis"
                exit 1
                ;;
        esac
    done

    # Validar modo
    case "$MODE" in
        "new"|"refactor"|"minimal"|"full")
            ;;
        *)
            print_error "Modo inválido: $MODE"
            echo "Modos válidos: new, refactor, minimal, full"
            exit 1
            ;;
    esac

    # Validar stack se especificada
    if [ "$AUTO_DETECT" = false ]; then
        case "$STACK" in
            "laravel"|"filament"|"livewire"|"node"|"react"|"nextjs"|"python"|"generic")
                ;;
            *)
                print_error "Stack inválida: $STACK"
                echo "Stacks válidas: laravel, filament, livewire, node, react, nextjs, python, generic"
                exit 1
                ;;
        esac
    fi

    # Validar PRD para modo new
    if [ "$MODE" = "new" ] && [ -z "$PRD_PATH" ]; then
        print_warning "Modo 'new' sem --prd especificado"
        print_info "Será criado um template de PRD em docs/prd-template.md"
    fi
}

# ============================================================================
# Detecção de Stack
# ============================================================================

detect_stack() {
    print_step "Detectando stack do projeto"

    # Função auxiliar para buscar em composer.json
    check_composer_for() {
        local pattern="$1"
        grep -rq "$pattern" composer.json */composer.json 2>/dev/null
    }

    # Função auxiliar para buscar em package.json
    check_package_for() {
        local pattern="$1"
        grep -rq "$pattern" package.json */package.json 2>/dev/null
    }

    if [ -f "composer.json" ]; then
        STACK="php"
        print_info "Detectado: composer.json (PHP)"

        if check_composer_for "laravel/framework"; then
            STACK="laravel"
            print_info "Detectado: Laravel Framework"

            if check_composer_for '"filament"'; then
                STACK="filament"
                print_info "Detectado: Filament Admin Panel"
            elif check_composer_for '"livewire"'; then
                STACK="livewire"
                print_info "Detectado: Livewire"
            fi
        fi
    elif [ -f "package.json" ]; then
        STACK="node"
        print_info "Detectado: package.json (Node.js)"

        if check_package_for '"next"'; then
            STACK="nextjs"
            print_info "Detectado: Next.js"
        elif check_package_for '"react"'; then
            STACK="react"
            print_info "Detectado: React"
        fi
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        STACK="python"
        print_info "Detectado: Python"
    else
        STACK="generic"
        print_warning "Nenhuma stack específica detectada, usando generic"
    fi

    print_success "Stack detectada: ${YELLOW}$STACK${NC}"
}

# ============================================================================
# Detecção de Contexto do Projeto
# ============================================================================

detect_project_context() {
    print_step "Analisando contexto do projeto"

    local has_code=false
    local code_lines=0
    local has_prd=false

    # Contar linhas de código
    if [ -f "composer.json" ] || [ -f "package.json" ]; then
        code_lines=$(find . -type f \( -name "*.php" -o -name "*.js" -o -name "*.ts" -o -name "*.py" \) \
            -not -path "./vendor/*" -not -path "./node_modules/*" \
            2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")

        if [ "$code_lines" -gt 1000 ]; then
            has_code=true
        fi
    fi

    # Verificar se existe PRD
    if [ -f "docs/prd.md" ] || [ -f "docs/PRD.md" ] || [ -f "PRD.md" ]; then
        has_prd=true
    fi

    print_info "Linhas de código: $code_lines"
    print_info "PRD encontrado: $has_prd"

    # Sugerir modo se não especificado
    if [ "$MODE" = "full" ] && [ "$has_code" = true ] && [ "$code_lines" -gt 5000 ]; then
        print_warning "Projeto com muito código existente ($code_lines linhas)"
        print_info "Considere usar: --mode refactor"
    fi
}

# ============================================================================
# Detecção de Módulos Existentes (para modo refactor)
# ============================================================================

detect_existing_modules() {
    print_step "Mapeando módulos existentes"

    local modules=()

    # Detectar estrutura Laravel
    if [ -d "app/Http/Controllers" ]; then
        local controllers=$(ls app/Http/Controllers/*.php 2>/dev/null | wc -l)
        print_info "Controllers encontrados: $controllers"
    fi

    if [ -d "app/Models" ]; then
        local models=$(ls app/Models/*.php 2>/dev/null | wc -l)
        print_info "Models encontrados: $models"
    fi

    # Detectar estrutura PHP legado
    if [ -d "app" ] && [ ! -d "app/Http" ]; then
        local php_files=$(find app -name "*.php" 2>/dev/null | wc -l)
        print_info "Arquivos PHP (legado): $php_files"
    fi

    # Detectar módulos por pasta
    for dir in app/Modules app/Domain modules src/modules; do
        if [ -d "$dir" ]; then
            local module_count=$(ls -d $dir/*/ 2>/dev/null | wc -l)
            print_info "Módulos em $dir: $module_count"
        fi
    done

    # Contar arquivos por extensão
    local php_count=$(find . -name "*.php" -not -path "./vendor/*" 2>/dev/null | wc -l)
    local js_count=$(find . -name "*.js" -not -path "./node_modules/*" 2>/dev/null | wc -l)
    local ts_count=$(find . -name "*.ts" -not -path "./node_modules/*" 2>/dev/null | wc -l)
    local py_count=$(find . -name "*.py" -not -path "./.venv/*" 2>/dev/null | wc -l)

    echo ""
    print_info "Resumo de arquivos:"
    [ "$php_count" -gt 0 ] && echo "  - PHP: $php_count"
    [ "$js_count" -gt 0 ] && echo "  - JS: $js_count"
    [ "$ts_count" -gt 0 ] && echo "  - TS: $ts_count"
    [ "$py_count" -gt 0 ] && echo "  - Python: $py_count"
}

# ============================================================================
# Funções de Escrita de Arquivos
# ============================================================================

should_write_file() {
    local file_path="$1"

    if [ -f "$file_path" ]; then
        if [ "$FORCE" = true ]; then
            print_warning "Sobrescrevendo: $file_path"
            return 0
        else
            ((FILES_SKIPPED++))
            return 1
        fi
    fi
    return 0
}

write_file() {
    local file_path="$1"
    local content="$2"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Criando: $file_path"
        return
    fi

    if should_write_file "$file_path"; then
        # Criar diretório pai se não existir
        mkdir -p "$(dirname "$file_path")"
        echo "$content" > "$file_path"
        print_success "Criado: $file_path"
        ((FILES_CREATED++))
    fi
}

create_dir() {
    local dir_path="$1"

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] mkdir -p $dir_path"
        return
    fi

    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        print_success "Diretório: $dir_path"
        ((DIRS_CREATED++))
    fi
}

# ============================================================================
# Criação de Estrutura de Diretórios
# ============================================================================

create_directories() {
    print_step "Criando estrutura de diretórios"

    local base_dirs=(
        ".antigravity"
        ".antigravity/agents"
        ".antigravity/rules"
        ".antigravity/workflows"
        ".antigravity/skills"
        ".antigravity/state"
        ".antigravity/lessons"
        ".antigravity/logs"
        ".antigravity/config"
        ".claude"
        "project-docs"
        "project-docs/modules"
    )

    # Adicionar diretórios específicos por modo
    case "$MODE" in
        "new")
            base_dirs+=("docs")
            ;;
        "refactor")
            base_dirs+=(".antigravity/skills/orchestrator")
            base_dirs+=(".antigravity/skills/code-analyzer")
            base_dirs+=(".antigravity/skills/debug-assistant")
            ;;
        "full")
            base_dirs+=(".antigravity/engine")
            base_dirs+=(".antigravity/skills/orchestrator")
            base_dirs+=(".antigravity/skills/code-analyzer")
            base_dirs+=(".antigravity/skills/debug-assistant")
            base_dirs+=(".antigravity/skills/test-generator")
            base_dirs+=(".antigravity/skills/task-planner")
            ;;
    esac

    for dir in "${base_dirs[@]}"; do
        create_dir "$dir"
    done
}

# ============================================================================
# Templates: context.md
# ============================================================================

extract_prd_info() {
    local prd_file="$1"
    local section="$2"

    if [ -f "$prd_file" ]; then
        # Extrair seção do PRD usando sed
        sed -n "/^##.*$section/,/^##/p" "$prd_file" | head -n -1 | tail -n +2
    fi
}

create_context_md_new() {
    local content
    local prd_title=""
    local prd_vision=""
    local prd_features=""
    local timestamp=$(date '+%Y-%m-%d %H:%M')

    # Tentar extrair informações do PRD
    if [ -n "$PRD_PATH" ] && [ -f "$PRD_PATH" ]; then
        prd_title=$(head -1 "$PRD_PATH" | sed 's/^#\s*//')
        prd_vision=$(extract_prd_info "$PRD_PATH" "Objetivo\|Visão\|Vision\|Goal")
        prd_features=$(extract_prd_info "$PRD_PATH" "Features\|Funcionalidades\|Requisitos\|Requirements")
    fi

    [ -z "$prd_title" ] && prd_title="$PROJECT_NAME"
    [ -z "$prd_vision" ] && prd_vision="[Extraído automaticamente do PRD quando fornecido]"
    [ -z "$prd_features" ] && prd_features="[Extraído automaticamente do PRD quando fornecido]"

    read -r -d '' content << HEREDOC || true
# Project Dynamics - ${prd_title}

## Origem: PRD
- **PRD Path:** ${PRD_PATH:-"[Nenhum PRD especificado]"}
- **Stack:** ${STACK}
- **Data:** ${timestamp}
- **Estado:** SETUP

---

## Visão do Sistema

${prd_vision}

---

## Features Planejadas

${prd_features}

---

## Stack Tecnológica

| Camada | Tecnologia |
|--------|------------|
| Backend | ${STACK} |
| Frontend | [A definir] |
| Database | [A definir] |
| Infrastructure | [A definir] |

---

## Fluxo: PRD-First

- [x] PRD definido
- [ ] Arquitetura validada
- [ ] Contratos definidos
- [ ] Implementação iniciada
- [ ] Testes escritos
- [ ] Documentação completa

---

## Agentes Ativos

Para este projeto novo, os agentes recomendados são:

1. **Architect Agent** - Definir arquitetura inicial
2. **Backend Agent** - Implementar domínio e serviços
3. **Frontend Agent** - Criar interfaces
4. **QA Agent** - Garantir qualidade desde o início

---

## Princípios Fundamentais

> **Documentação vem antes do código.**
> Nenhuma camada deve ser implementada sem o documento correspondente existir.

> **Validar antes de implementar.**

---

**Este documento é vivo e deve ser atualizado conforme o projeto evolui.**
HEREDOC

    write_file "context.md" "$content"
}

create_context_md_refactor() {
    local content
    local timestamp=$(date '+%Y-%m-%d %H:%M')

    # Análise estrutural básica
    local php_count=$(find . -name "*.php" -not -path "./vendor/*" 2>/dev/null | wc -l)
    local js_count=$(find . -name "*.js" -not -path "./node_modules/*" 2>/dev/null | wc -l)
    local ts_count=$(find . -name "*.ts" -not -path "./node_modules/*" 2>/dev/null | wc -l)
    local py_count=$(find . -name "*.py" -not -path "./.venv/*" 2>/dev/null | wc -l)

    # Listar diretórios principais
    local main_dirs=$(ls -d */ 2>/dev/null | grep -v "vendor\|node_modules\|.git" | head -10 | tr '\n' ', ' | sed 's/,$//')

    # Detectar frameworks do composer.json/package.json
    local frameworks=""
    if [ -f "composer.json" ]; then
        frameworks=$(grep -oP '"[^"]+/[^"]+"' composer.json | head -5 | tr '\n' ', ' | sed 's/,$//')
    fi
    if [ -f "package.json" ]; then
        local pkg_deps=$(grep -oP '"[^"]+": "[^"]+"' package.json | head -5 | tr '\n' ', ' | sed 's/,$//')
        frameworks="${frameworks}${pkg_deps}"
    fi

    read -r -d '' content << HEREDOC || true
# Project Dynamics - ${PROJECT_NAME}

## Origem: Análise Estrutural
- **Data:** ${timestamp}
- **Stack Detectada:** ${STACK}
- **Estado:** ANÁLISE

---

## Inventário de Arquivos

| Tipo | Quantidade |
|------|------------|
| PHP | ${php_count} |
| JavaScript | ${js_count} |
| TypeScript | ${ts_count} |
| Python | ${py_count} |

---

## Estrutura Detectada

Diretórios principais:
\`\`\`
${main_dirs}
\`\`\`

---

## Frameworks/Dependências

${frameworks:-"[Nenhuma dependência detectada]"}

---

## Próximos Passos

> **Para análise profunda, execute:**
> \`mcp__antigravity__classify_intent("analisar código legado")\`
> Isso ativará o **Legacy Analyzer Agent** com modelo Sonnet.

### Fluxo: Strangler Fig Pattern

1. [x] Análise estrutural (bootstrap)
2. [ ] Análise profunda (Legacy Analyzer Agent)
3. [ ] Mapeamento de dependências
4. [ ] Estratégia de migração definida
5. [ ] Migração gradual
6. [ ] Testes de regressão
7. [ ] Descomissionamento do legado

---

## Agentes Especializados para Refatoração

1. **Legacy Analyzer Agent** - Análise profunda do código legado
2. **Security Guardian Agent** - Validação de segurança durante migração
3. **Refactoring Specialist** - Execução das refatorações
4. **QA Agent** - Garantir que comportamento é preservado

---

## Riscos Identificados

> **Atenção:** Esta análise é superficial (bash puro).
> Para identificar riscos reais, use o Legacy Analyzer Agent.

- [ ] Código sem testes
- [ ] Dependências desatualizadas
- [ ] Padrões inconsistentes
- [ ] Documentação ausente

---

## Princípios de Refatoração

> **Nunca altere comportamento durante refatoração.**
> Primeiro migre, depois melhore.

> **Testes são obrigatórios antes de refatorar.**

> **Commits pequenos e frequentes.**

---

**Este documento é vivo e deve ser atualizado conforme a refatoração evolui.**
HEREDOC

    write_file "context.md" "$content"
}

create_context_md_full() {
    local content
    local timestamp=$(date '+%Y-%m-%d %H:%M')

    read -r -d '' content << HEREDOC || true
# Project Dynamics - ${PROJECT_NAME}

## Propósito

Este documento define a dinâmica geral do projeto, a organização da documentação,
a arquitetura conceitual e o papel de cada agente de IA envolvido no desenvolvimento.

**Leia este arquivo antes de qualquer geração de código.**

---

## Visão Resumida

| Aspecto | Valor |
|---------|-------|
| **Nome** | ${PROJECT_NAME} |
| **Stack** | ${STACK} |
| **Bootstrap** | ${timestamp} |
| **Estado** | ATIVO |

---

## Stack Tecnológica

| Camada | Tecnologia |
|--------|------------|
| Backend | ${STACK} |
| Frontend | [Definir] |
| Database | [Definir] |
| Infrastructure | [Definir] |

---

## Estrutura do Repositório

\`\`\`
${PROJECT_NAME}/
├── AGENTS.md                 # Entry point para IAs
├── context.md                # Este arquivo
├── .antigravity/             # Governança de IA
│   ├── agents/               # Definição dos agentes
│   ├── rules/                # Regras por tecnologia
│   ├── workflows/            # Fluxos de trabalho
│   ├── skills/               # Skills especializados
│   ├── engine/               # MCP Server
│   ├── state/                # Estado da sessão
│   └── lessons/              # Lições aprendidas
├── .claude/                  # Configuração Claude Code
│   └── hooks.json            # Triggers automáticos
├── project-docs/             # Documentação do domínio
│   └── modules/              # Um arquivo por módulo
└── [código fonte]
\`\`\`

---

## Agentes Disponíveis

| Agente | Responsabilidade |
|--------|-----------------|
| **Architect** | Decisões arquiteturais, contratos, camadas |
| **Backend** | Domínio, serviços, persistência |
| **Frontend** | UI/UX, componentes |
| **DevOps** | Infraestrutura, Docker, build |
| **QA** | Qualidade, testes, validação |

---

## Princípios Fundamentais

> **Documentação vem antes do código.**

> **Sempre validar antes de implementar.**

> **Sempre refinar o código antes de finalizar.**

---

## Estado da Implementação

### Concluído
- [x] Bootstrap do Antigravity System

### Em Progresso
- [ ] [Adicione tarefas aqui]

### Backlog
- [ ] [Adicione tarefas futuras]

---

## Convenções

- **Código:** inglês
- **Documentação:** português
- **Commits:** Conventional Commits
- **Branches:** feature/, fix/, refactor/

---

**Este documento é vivo e deve ser atualizado conforme o projeto evolui.**
HEREDOC

    write_file "context.md" "$content"
}

# ============================================================================
# Templates: AGENTS.md
# ============================================================================

create_agents_md() {
    local content
    read -r -d '' content << HEREDOC || true
# BOOTSTRAP - Leia este arquivo primeiro

> **Para qualquer LLM ou assistente de IA:**
> Este arquivo contém instruções para ativar o modo agente deste projeto.

---

## Ativacao Rapida

1. Leia \`context.md\` para entender o projeto
2. Leia os agentes em \`.antigravity/agents/\`
3. Leia as regras em \`.antigravity/rules/\`
4. Confirme ativacao ao desenvolvedor

---

## Sobre este Projeto

| Aspecto | Valor |
|---------|-------|
| **Nome** | ${PROJECT_NAME} |
| **Stack** | ${STACK} |
| **Modo** | ${MODE} |

---

## Arquivos Importantes

| Arquivo | Proposito |
|---------|-----------|
| \`context.md\` | Contexto completo do projeto |
| \`.antigravity/agents/\` | Definicao dos agentes |
| \`.antigravity/rules/\` | Regras de codificacao |
| \`.antigravity/workflows/\` | Workflows disponiveis |
| \`project-docs/\` | Documentacao do dominio |

---

## Principio Fundamental

> **Documentacao vem antes do codigo.**
> Sempre valide antes de implementar.
> Sempre consulte os agentes apropriados.

---

**Apos ler este arquivo, leia \`context.md\`**
HEREDOC

    write_file "AGENTS.md" "$content"
}

# ============================================================================
# Templates: source-index.json
# ============================================================================

create_source_index() {
    local content
    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S')

    read -r -d '' content << HEREDOC || true
{
  "version": "2.0.0",
  "mode": "${MODE}",
  "stack": "${STACK}",
  "project": "${PROJECT_NAME}",
  "generated_at": "${timestamp}",

  "documentation": {
    "architecture": "project-docs/architecture.md",
    "business_rules": "project-docs/business-rules.md",
    "decisions": "project-docs/decisions.md"
  },

  "agents": {
    "architect": {
      "playbook": ".antigravity/agents/architect.md"
    },
    "backend": {
      "playbook": ".antigravity/agents/backend.md"
    },
    "frontend": {
      "playbook": ".antigravity/agents/frontend.md"
    },
    "devops": {
      "playbook": ".antigravity/agents/devops.md"
    },
    "qa": {
      "playbook": ".antigravity/agents/qa.md"
    }
  },

  "workflows": {
    "bootstrap": ".antigravity/workflows/bootstrap.md",
    "feature_development": ".antigravity/workflows/feature-development.md",
    "refactor": ".antigravity/workflows/refactor.md",
    "error_recovery": ".antigravity/workflows/error-recovery.md",
    "validation_commit": ".antigravity/workflows/validation-and-commit.md"
  },

  "skills": {
    "orchestrator": ".antigravity/skills/orchestrator/SKILL.md",
    "code_analyzer": ".antigravity/skills/code-analyzer/SKILL.md",
    "debug_assistant": ".antigravity/skills/debug-assistant/SKILL.md",
    "test_generator": ".antigravity/skills/test-generator/SKILL.md",
    "task_planner": ".antigravity/skills/task-planner/SKILL.md"
  },

  "governance": {
    "rules": "context.md",
    "agents_registry": "AGENTS.md"
  },

  "patterns": {
    "refactor_query": {
      "pattern": "refatorar?|refactor|reorganizar|reestruturar",
      "sources": ["agents.refactoring", "workflows.refactor"]
    },
    "bug_query": {
      "pattern": "bug|erro|error|fix|corrigir|problema",
      "sources": ["workflows.error_recovery"]
    },
    "test_query": {
      "pattern": "teste?s?|test|tdd|coverage",
      "sources": ["skills.test_generator"]
    }
  }
}
HEREDOC

    write_file ".antigravity/source-index.json" "$content"
}

# ============================================================================
# Templates: Agentes
# ============================================================================

create_agent_architect() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Architect Agent

## Role
Responsible for high-level system design, architecture decisions, and ensuring technical consistency.

## Responsibilities
- Define system architecture and component boundaries
- Create and maintain ADRs (Architecture Decision Records)
- Review structural changes for consistency
- Guide domain modeling and entity relationships
- Ensure scalability and maintainability patterns

## Context Files
- `project-docs/architecture.md`
- `project-docs/decisions.md`

## Guidelines
- Always consider long-term maintainability
- Document decisions with rationale
- Prefer composition over inheritance
- Follow SOLID principles
- Validate architectural changes against project requirements

## Can
- Create contracts (interfaces)
- Define layers and responsibilities
- Suggest patterns and abstractions
- Validate technical decisions

## Cannot
- Implement UI details
- Create final code without defined contracts
HEREDOC

    write_file ".antigravity/agents/architect.md" "$content"
}

create_agent_backend() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Backend Agent

## Role
Responsible for server-side application development, API implementation, and business logic.

## Responsibilities
- Implement controllers, services, and repositories
- Create and maintain data models and migrations
- Develop API endpoints following conventions
- Write unit and feature tests
- Handle database operations and optimizations

## Context Files
- `project-docs/business-rules.md`
- `.antigravity/rules/`

## Guidelines
- Follow framework best practices and conventions
- Write clean, testable code
- Use dependency injection
- Apply appropriate design patterns
- Validate all inputs

## Can
- Create models and repositories
- Implement services defined in contracts
- Create internal APIs
- Implement business rules

## Cannot
- Change contracts without Architect approval
- Create direct dependency with UI
HEREDOC

    write_file ".antigravity/agents/backend.md" "$content"
}

create_agent_frontend() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Frontend Agent

## Role
Responsible for UI/UX implementation and frontend development.

## Responsibilities
- Implement views and components
- Create responsive and accessible interfaces
- Manage CSS/styling
- Handle JavaScript interactions
- Ensure cross-browser compatibility

## Guidelines
- Ensure accessibility (WCAG compliance)
- Use consistent styling approach
- Keep components reusable
- Test across browsers
- Follow UI/UX best practices

## Can
- Create pages and components
- Implement interactions
- Create real component previews

## Cannot
- Create business rules
- Create direct persistence
- Change domain
HEREDOC

    write_file ".antigravity/agents/frontend.md" "$content"
}

create_agent_devops() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# DevOps Agent

## Role
Responsible for infrastructure, CI/CD pipelines, and deployment.

## Responsibilities
- Maintain Docker configurations
- Configure CI/CD pipelines
- Manage environment configurations
- Handle deployment automation
- Monitor application health

## Guidelines
- Keep containers minimal and secure
- Use multi-stage builds when applicable
- Document all environment variables
- Automate repetitive tasks
- Follow security best practices

## Can
- Create environment configurations
- Define build pipeline
- Manage containers

## Cannot
- Change business code
- Create undocumented dependencies
HEREDOC

    write_file ".antigravity/agents/devops.md" "$content"
}

create_agent_qa() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# QA Agent

## Role
Responsible for quality assurance, testing strategies, and ensuring code quality.

## Responsibilities
- Write and maintain test suites (unit, feature, integration)
- Review code for quality and standards compliance
- Identify edge cases and potential bugs
- Validate user acceptance criteria
- Ensure documentation accuracy

## Guidelines
- Test behavior, not implementation
- Aim for meaningful coverage
- Use factories/fixtures for test data
- Document test scenarios
- Automate regression tests

## Can
- Validate contracts
- Identify inconsistencies
- Suggest improvements
- Write tests

## Cannot
- Implement production code
- Change architecture
HEREDOC

    write_file ".antigravity/agents/qa.md" "$content"
}

# Agentes específicos para modo refactor
create_agent_legacy_analyzer() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Legacy Analyzer Agent

## Role
Specialized agent for analyzing legacy codebases and creating migration strategies.

## Responsibilities
- Deep analysis of legacy code structure
- Identify coupling and dependencies
- Map technical debt
- Create refactoring roadmap
- Document legacy patterns and anti-patterns

## Activation
This agent is activated when:
- `--mode refactor` is used
- Intent matches: "legacy", "migração", "análise profunda"

## Model Tier
Recommended: **Sonnet** (for deep analysis)

## Workflow
1. Structural analysis (file counts, dependencies)
2. Pattern detection (MVC, procedural, mixed)
3. Risk assessment
4. Migration strategy proposal
5. Incremental refactoring plan

## Guidelines
- Never change behavior during analysis
- Document everything discovered
- Create actionable recommendations
- Prioritize by risk/value
HEREDOC

    write_file ".antigravity/agents/legacy-analyzer.md" "$content"
}

create_agent_security_guardian() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Security Guardian Agent

## Role
Validates all changes for security implications before allowing commits.

## Responsibilities
- Review code changes for security vulnerabilities
- Validate environment variable handling
- Check for sensitive data exposure
- Verify authentication/authorization patterns
- Ensure OWASP compliance

## Actions
- **ALLOW**: Change is safe to proceed
- **BLOCK**: Change has security issues (must fix)
- **ROLLBACK**: Change introduced vulnerability (revert)

## Checks Performed
1. SQL Injection patterns
2. XSS vulnerabilities
3. CSRF protection
4. Sensitive data in logs
5. Hardcoded credentials
6. Insecure dependencies

## Guidelines
- Security is non-negotiable
- Block silently is never acceptable - always explain
- Provide fix suggestions with blocks
HEREDOC

    write_file ".antigravity/agents/security-guardian.md" "$content"
}

# ============================================================================
# Templates: Rules
# ============================================================================

create_rule_global() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Global Rules

## General Principles
- Write clean, readable, and maintainable code
- Follow DRY (Don't Repeat Yourself) principle
- KISS (Keep It Simple, Stupid)
- YAGNI (You Aren't Gonna Need It)

## Documentation
- Document all public APIs
- Keep README files updated
- Use meaningful commit messages
- Update CHANGELOG for significant changes

## Version Control
- Use conventional commits
- Create feature branches
- Review code before merging
- Keep commits atomic and focused

## Communication
- Be explicit about assumptions
- Ask for clarification when needed
- Document decisions and rationale

## Agent Protocols
- **Commits**: Follow project's commit message convention
- **Knowledge Sync**: Document lessons learned
- **State Updates**: Update session-state.md after significant work
HEREDOC

    write_file ".antigravity/rules/global.md" "$content"
}

create_rule_coding_standards() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Coding Standards

## Naming Conventions
- Classes: PascalCase
- Methods/Functions: camelCase
- Variables: camelCase
- Constants: UPPER_SNAKE_CASE
- Database tables: snake_case (plural)
- Database columns: snake_case

## File Organization
- One class per file (when applicable)
- Namespace matches directory structure
- Group related code in directories

## Comments
- Use docstrings/documentation comments for public APIs
- Avoid obvious comments
- Explain "why", not "what"

## Testing
- Test file mirrors source structure
- Use descriptive test method names
- Follow Arrange-Act-Assert pattern

## Code Quality
- Maximum line length: 120 characters
- Use meaningful variable and function names
- Keep functions small and focused
- Avoid deep nesting
HEREDOC

    write_file ".antigravity/rules/coding-standards.md" "$content"
}

create_rule_stack_specific() {
    case "$STACK" in
        "laravel"|"filament"|"livewire")
            create_rule_laravel
            [ "$STACK" = "filament" ] && create_rule_filament
            [ "$STACK" = "livewire" ] && create_rule_livewire
            ;;
        "node"|"react"|"nextjs")
            create_rule_node
            [ "$STACK" = "react" ] && create_rule_react
            [ "$STACK" = "nextjs" ] && create_rule_nextjs
            ;;
        "python")
            create_rule_python
            ;;
    esac
}

create_rule_laravel() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Laravel Rules

## Architecture
- Use service classes for business logic
- Controllers should be thin
- Use form requests for validation
- Apply repository pattern for data access

## Eloquent
- Define relationships explicitly
- Use scopes for reusable queries
- Avoid N+1 queries (use eager loading)
- Use model factories for testing

## Migrations
- Never modify existing migrations in production
- Use descriptive migration names
- Include rollback logic

## Routes
- Use route model binding
- Group routes logically
- Apply middleware at group level
- Use named routes

## PHP Standards
- Follow PSR-12 coding style
- Use strict types: `declare(strict_types=1);`
- Type hint all parameters and return values
HEREDOC

    write_file ".antigravity/rules/laravel.md" "$content"
}

create_rule_filament() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Filament Rules

## Resources
- Use resource classes for CRUD operations
- Define forms and tables in resource classes
- Use relation managers for related data
- Apply proper authorization

## Components
- Extend Filament components properly
- Use slots for customization
- Register custom components in service provider

## Forms
- Use appropriate field types
- Group related fields in sections
- Add helpful descriptions and hints
- Validate on both client and server

## Tables
- Use appropriate column types
- Add filters for common queries
- Enable search on relevant columns
- Optimize queries for performance
HEREDOC

    write_file ".antigravity/rules/filament.md" "$content"
}

create_rule_livewire() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Livewire Rules

## Components
- Keep components focused and small
- Use wire:model for two-way binding
- Implement lifecycle hooks appropriately

## State Management
- Minimize public properties
- Use computed properties for derived state
- Protect sensitive data

## Performance
- Use lazy loading for heavy components
- Implement pagination for lists
- Debounce rapid user inputs

## Security
- Validate all inputs
- Use authorization checks
- Sanitize output
HEREDOC

    write_file ".antigravity/rules/livewire.md" "$content"
}

create_rule_node() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Node.js Rules

## Project Structure
- Use meaningful directory structure
- Separate concerns (routes, controllers, services)
- Keep configuration in dedicated files
- Use environment variables for secrets

## Async/Await
- Always handle promise rejections
- Use async/await over callbacks
- Avoid mixing callbacks and promises
- Handle errors at appropriate levels

## Security
- Validate and sanitize all inputs
- Use parameterized queries
- Implement rate limiting
- Follow OWASP guidelines

## Testing
- Write unit tests for business logic
- Write integration tests for APIs
- Mock external dependencies
- Use test coverage tools
HEREDOC

    write_file ".antigravity/rules/node.md" "$content"
}

create_rule_react() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# React Rules

## Components
- Use functional components with hooks
- Keep components small and focused
- Extract reusable logic into custom hooks
- Use TypeScript for type safety

## State Management
- Use local state for component-specific data
- Use context for shared state
- Avoid prop drilling

## Performance
- Use React.memo for expensive renders
- Lazy load routes and components
- Monitor bundle size

## Accessibility
- Use semantic HTML
- Add ARIA labels where needed
- Ensure keyboard navigation
HEREDOC

    write_file ".antigravity/rules/react.md" "$content"
}

create_rule_nextjs() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Next.js Rules

## Routing
- Use App Router for new projects
- Organize routes logically
- Use dynamic routes appropriately

## Data Fetching
- Use Server Components by default
- Fetch data at the lowest level needed
- Implement proper caching strategies

## Performance
- Use Image component for images
- Implement proper caching
- Lazy load components
- Monitor Core Web Vitals

## SEO
- Use metadata API
- Implement proper Open Graph tags
- Create sitemap.xml
HEREDOC

    write_file ".antigravity/rules/nextjs.md" "$content"
}

create_rule_python() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Python Rules

## Code Style
- Follow PEP 8 style guide
- Use type hints (PEP 484)
- Use docstrings (PEP 257)
- Maximum line length: 88 characters (Black default)

## Project Structure
- Use virtual environments
- Organize code in packages
- Separate concerns appropriately

## Testing
- Use pytest for testing
- Write unit and integration tests
- Use fixtures for test data

## Documentation
- Document all public APIs
- Use type hints as documentation
- Keep README updated
HEREDOC

    write_file ".antigravity/rules/python.md" "$content"
}

# ============================================================================
# Templates: Workflows
# ============================================================================

create_workflow_bootstrap() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Bootstrap Workflow

## Purpose
Initial project setup and environment configuration.

## Steps

### 1. Clone Repository
```bash
git clone <repository-url>
cd <project-name>
```

### 2. Copy Environment File
```bash
cp .env.example .env
```

### 3. Install Dependencies
Install according to your stack.

### 4. Configure Environment
- Update `.env` with appropriate values
- Generate application keys if needed
- Configure database connection

### 5. Setup Database
Run migrations and seeders if applicable.

### 6. Verify Installation
- Access the application
- Check that all features work correctly
HEREDOC

    write_file ".antigravity/workflows/bootstrap.md" "$content"
}

create_workflow_feature_development() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Feature Development Workflow

## Purpose
Standard workflow for implementing new features.

## Steps

### 1. Create Feature Branch
```bash
git checkout -b feature/<feature-name>
```

### 2. Understand Requirements
- Review related documentation
- Identify affected components
- List acceptance criteria

### 3. Plan Implementation
- Define interfaces/contracts first
- Break down into small tasks
- Identify dependencies

### 4. Implement
- Write tests first (TDD when possible)
- Implement the feature
- Follow coding standards
- Keep commits atomic

### 5. Test
Run all tests to ensure nothing is broken.

### 6. Submit
- Create pull request
- Request code review

## Checklist
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Coding standards followed
HEREDOC

    write_file ".antigravity/workflows/feature-development.md" "$content"
}

create_workflow_refactor() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Refactor Workflow

## Purpose
Safe refactoring while maintaining functionality.

## Golden Rules
- Never refactor and add features simultaneously
- Tests must pass at every step
- If unsure, discuss first

## Steps

### 1. Ensure Test Coverage
- Run existing tests
- Add missing tests for current behavior
- All tests must pass before refactoring

### 2. Create Refactor Branch
```bash
git checkout -b refactor/<scope>
```

### 3. Refactor Incrementally
- Make small, focused changes
- Run tests after each change
- Commit frequently

### 4. Verify Behavior
- Ensure no behavioral changes
- Compare before/after outputs

### 5. Update Documentation
- Update affected documentation
- Add ADR if architectural change
HEREDOC

    write_file ".antigravity/workflows/refactor.md" "$content"
}

create_workflow_error_recovery() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Error Recovery Workflow

## Purpose
Systematic approach to debugging and fixing errors.

## Steps

### 1. Reproduce
- Confirm the error exists
- Document steps to reproduce
- Capture error messages and stack traces

### 2. Isolate
- Identify the affected component
- Check recent changes
- Review logs

### 3. Diagnose
- Understand the root cause
- Check related code
- Search for similar issues

### 4. Fix
- Implement the fix
- Add test to prevent regression
- Document the solution

### 5. Verify
- Run all tests
- Manually verify fix works
- Check for side effects

### 6. Document
- Add lesson learned to `.antigravity/lessons/`
- Update documentation if needed
HEREDOC

    write_file ".antigravity/workflows/error-recovery.md" "$content"
}

create_workflow_validation_commit() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Validation and Commit Workflow

## Purpose
Ensure quality before committing changes.

## Pre-Commit Checklist

### Code Quality
- [ ] Code follows project standards
- [ ] No debugging code left
- [ ] No console.log/print statements
- [ ] Error handling is appropriate

### Tests
- [ ] All tests pass
- [ ] New tests added for new code
- [ ] Coverage is acceptable

### Security
- [ ] No sensitive data exposed
- [ ] Inputs are validated
- [ ] No SQL injection risks

### Documentation
- [ ] Code comments where needed
- [ ] README updated if needed
- [ ] API docs updated if needed

## Commit Message Format
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: feat, fix, docs, style, refactor, test, chore
HEREDOC

    write_file ".antigravity/workflows/validation-and-commit.md" "$content"
}

create_workflow_legacy() {
    local content
    read -r -d '' content << 'HEREDOC' || true
# Legacy Migration Workflow

## Purpose
Strangler Fig Pattern for gradual legacy migration.

## Principles
- Never break existing functionality
- Migrate incrementally
- Test everything
- Document as you go

## Steps

### 1. Analysis
- Map legacy code structure
- Identify dependencies
- Document current behavior

### 2. Create Facade
- Build new interface
- Route through facade
- Keep legacy working

### 3. Implement New
- Build new implementation
- Match existing behavior exactly
- Write comprehensive tests

### 4. Migrate
- Switch routes gradually
- Monitor for issues
- Keep rollback ready

### 5. Cleanup
- Remove legacy code
- Update documentation
- Celebrate!

## Risk Mitigation
- Feature flags for gradual rollout
- A/B testing when possible
- Comprehensive logging
HEREDOC

    write_file ".antigravity/workflows/legacy.md" "$content"
}

# ============================================================================
# Templates: Skills
# ============================================================================

create_skill_orchestrator() {
    local content
    read -r -d '' content << 'HEREDOC' || true
---
name: orchestrator
description: Central brain of the Antigravity system
triggers:
  - "modo agente"
  - "agent mode"
  - "ativar agentes"
globs:
  - "context.md"
  - ".antigravity/**/*.md"
---

# Orchestrator Skill

## Purpose
Coordinates all agents and ensures proper context loading.

## Activation
Triggered when user says "modo agente" or similar.

## Workflow
1. Load `context.md`
2. Identify appropriate agents
3. Load agent definitions
4. Load relevant rules
5. Confirm activation to user

## Dependencies
- `.antigravity/source-index.json`
- All agent definitions
- All rule files
HEREDOC

    write_file ".antigravity/skills/orchestrator/SKILL.md" "$content"
}

create_skill_code_analyzer() {
    local content
    read -r -d '' content << 'HEREDOC' || true
---
name: code-analyzer
description: Analyzes code structure and quality
triggers:
  - "analisar codigo"
  - "analyze code"
  - "code review"
globs:
  - "**/*.php"
  - "**/*.js"
  - "**/*.ts"
  - "**/*.py"
---

# Code Analyzer Skill

## Purpose
Provides deep analysis of code structure, patterns, and quality.

## Capabilities
- Identify code smells
- Detect anti-patterns
- Measure complexity
- Find duplications

## Output
Structured report with findings and recommendations.
HEREDOC

    write_file ".antigravity/skills/code-analyzer/SKILL.md" "$content"
}

create_skill_debug_assistant() {
    local content
    read -r -d '' content << 'HEREDOC' || true
---
name: debug-assistant
description: Helps debug errors and issues
triggers:
  - "debug"
  - "erro"
  - "error"
  - "bug"
globs:
  - "**/*.log"
  - ".antigravity/lessons/**"
---

# Debug Assistant Skill

## Purpose
Assists in debugging by analyzing errors and suggesting solutions.

## Workflow
1. Capture error information
2. Search lessons learned
3. Analyze stack trace
4. Suggest potential fixes

## Integration
Uses `.antigravity/lessons/` to avoid repeating past mistakes.
HEREDOC

    write_file ".antigravity/skills/debug-assistant/SKILL.md" "$content"
}

create_skill_test_generator() {
    local content
    read -r -d '' content << 'HEREDOC' || true
---
name: test-generator
description: Generates tests for code
triggers:
  - "gerar testes"
  - "generate tests"
  - "criar testes"
globs:
  - "tests/**"
  - "**/*.test.*"
  - "**/*.spec.*"
---

# Test Generator Skill

## Purpose
Generates appropriate tests for given code.

## Capabilities
- Unit tests
- Integration tests
- Feature tests
- Edge case identification

## Guidelines
- Follow existing test patterns
- Use appropriate assertions
- Mock external dependencies
HEREDOC

    write_file ".antigravity/skills/test-generator/SKILL.md" "$content"
}

create_skill_task_planner() {
    local content
    read -r -d '' content << 'HEREDOC' || true
---
name: task-planner
description: Plans and breaks down tasks
triggers:
  - "planejar"
  - "plan"
  - "dividir tarefa"
globs:
  - "context.md"
  - "project-docs/**"
---

# Task Planner Skill

## Purpose
Breaks down complex tasks into manageable steps.

## Workflow
1. Understand the goal
2. Identify components involved
3. Create ordered task list
4. Estimate complexity

## Output
Structured task list with dependencies.
HEREDOC

    write_file ".antigravity/skills/task-planner/SKILL.md" "$content"
}

# ============================================================================
# Templates: Session State
# ============================================================================

create_session_state() {
    local content
    local timestamp=$(date '+%Y-%m-%d %H:%M')

    read -r -d '' content << HEREDOC || true
# Session State - ${PROJECT_NAME}

## Current State
- **Status:** INITIALIZED
- **Mode:** ${MODE}
- **Stack:** ${STACK}
- **Last Update:** ${timestamp}

---

## Recent Actions
- Bootstrap executed

---

## Active Context
- Agents: All available
- Rules: ${STACK} specific

---

## Notes for Next Session
- [Add notes here]

---

**Update this file after significant work.**
HEREDOC

    write_file ".antigravity/state/session-state.md" "$content"
}

# ============================================================================
# Templates: README
# ============================================================================

create_antigravity_readme() {
    local content
    read -r -d '' content << HEREDOC || true
# Antigravity Agent System

> Sistema de Governanca de IA para ${PROJECT_NAME}

## Quick Start

1. Leia \`context.md\` para entender o projeto
2. Execute \`modo agente\` para ativar os agentes
3. Use os workflows em \`.antigravity/workflows/\`

## Estrutura

\`\`\`
.antigravity/
├── agents/           # Definicao dos agentes
├── rules/            # Regras por tecnologia
├── workflows/        # Fluxos de trabalho
├── skills/           # Skills especializados
├── engine/           # MCP Server (se habilitado)
├── state/            # Estado da sessao
├── lessons/          # Licoes aprendidas
├── config/           # Configuracoes
└── source-index.json # Indice de fontes
\`\`\`

## Agentes

| Agente | Responsabilidade |
|--------|-----------------|
| Architect | Decisoes arquiteturais |
| Backend | Dominio e servicos |
| Frontend | UI/UX |
| DevOps | Infraestrutura |
| QA | Qualidade e testes |

## Versao

**Bootstrap:** ${SCRIPT_VERSION}
**Stack:** ${STACK}
**Mode:** ${MODE}
HEREDOC

    write_file ".antigravity/README.md" "$content"
}

# ============================================================================
# Templates: project-docs
# ============================================================================

create_project_docs() {
    local content

    # architecture.md
    read -r -d '' content << 'HEREDOC' || true
# Architecture

## Overview
[Describe the system architecture]

## Components
[List main components]

## Data Flow
[Describe how data flows through the system]

## Decisions
See `decisions.md` for ADRs.
HEREDOC
    write_file "project-docs/architecture.md" "$content"

    # business-rules.md
    read -r -d '' content << 'HEREDOC' || true
# Business Rules

## Domain Rules
[Document business rules here]

## Validation Rules
[Document validation requirements]

## Workflows
[Document business workflows]
HEREDOC
    write_file "project-docs/business-rules.md" "$content"

    # decisions.md
    read -r -d '' content << 'HEREDOC' || true
# Architecture Decision Records

## Template

### ADR-XXX: Title
- **Date:** YYYY-MM-DD
- **Status:** Proposed | Accepted | Deprecated
- **Context:** [Why this decision is needed]
- **Decision:** [What was decided]
- **Consequences:** [What are the implications]

---

## Decisions

[Add ADRs here]
HEREDOC
    write_file "project-docs/decisions.md" "$content"
}

# ============================================================================
# MCP Engine Setup
# ============================================================================

setup_mcp_engine() {
    if [ "$NO_MCP" = true ]; then
        print_info "MCP Engine desabilitado (--no-mcp)"
        return
    fi

    print_step "Configurando MCP Engine"

    # Verificar se engine já existe
    if [ -d ".antigravity/engine" ] && [ -f ".antigravity/engine/package.json" ]; then
        print_info "MCP Engine já existe"
        return
    fi

    # Criar package.json
    local package_json
    read -r -d '' package_json << 'HEREDOC' || true
{
  "name": "@antigravity/engine",
  "version": "2.0.0",
  "description": "Antigravity MCP Engine - Token-efficient agent orchestration",
  "type": "module",
  "main": "mcp-server.ts",
  "scripts": {
    "start": "npx tsx mcp-server.ts",
    "dev": "npx tsx watch mcp-server.ts",
    "typecheck": "npx tsc --noEmit"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsx": "^4.0.0",
    "typescript": "^5.0.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
HEREDOC

    write_file ".antigravity/engine/package.json" "$package_json"

    # Criar tsconfig.json
    local tsconfig
    read -r -d '' tsconfig << 'HEREDOC' || true
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
HEREDOC

    write_file ".antigravity/engine/tsconfig.json" "$tsconfig"

    # Criar placeholder para mcp-server.ts (usuário pode copiar do existente)
    if [ ! -f ".antigravity/engine/mcp-server.ts" ]; then
        local mcp_placeholder
        read -r -d '' mcp_placeholder << 'HEREDOC' || true
// MCP Server Placeholder
// Copy your mcp-server.ts implementation here
// Or run: npm install && npm run start

import { Server } from "@modelcontextprotocol/sdk/server/index.js";

console.log("Antigravity MCP Engine v2.0.0");
console.log("Configure your MCP server implementation.");
HEREDOC
        write_file ".antigravity/engine/mcp-server.ts" "$mcp_placeholder"
    fi
}

create_mcp_config() {
    if [ "$NO_MCP" = true ]; then
        return
    fi

    print_step "Criando configuração MCP"

    local mcp_config
    local has_laravel=false

    case "$STACK" in
        "laravel"|"filament"|"livewire")
            has_laravel=true
            ;;
    esac

    if [ "$has_laravel" = true ]; then
        read -r -d '' mcp_config << 'HEREDOC' || true
{
  "mcpServers": {
    "antigravity": {
      "command": "npx",
      "args": ["tsx", ".antigravity/engine/mcp-server.ts"]
    },
    "serena": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--context",
        "ide-assistant",
        "--project",
        "."
      ]
    },
    "laravel-boost": {
      "command": "npx",
      "args": ["-y", "@nickarellano/laravel-boost-mcp"]
    }
  }
}
HEREDOC
    else
        read -r -d '' mcp_config << 'HEREDOC' || true
{
  "mcpServers": {
    "antigravity": {
      "command": "npx",
      "args": ["tsx", ".antigravity/engine/mcp-server.ts"]
    },
    "serena": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/oraios/serena",
        "serena",
        "start-mcp-server",
        "--context",
        "ide-assistant",
        "--project",
        "."
      ]
    }
  }
}
HEREDOC
    fi

    write_file ".mcp.json" "$mcp_config"
}

# ============================================================================
# Claude Hooks Setup
# ============================================================================

setup_claude_hooks() {
    if [ "$NO_HOOKS" = true ]; then
        print_info "Claude hooks desabilitados (--no-hooks)"
        return
    fi

    print_step "Configurando Claude hooks"

    local hooks_config
    read -r -d '' hooks_config << 'HEREDOC' || true
{
  "version": "2.0.0",
  "hooks": [
    {
      "trigger": "modo agente|agent mode",
      "intent": "agent_mode",
      "action": "activate_orchestrator"
    },
    {
      "trigger": "refatorar|refactor|refactoring",
      "intent": "refactoring",
      "agent": "refactoring-specialist",
      "required_context": [
        ".antigravity/agents/",
        ".antigravity/rules/"
      ]
    },
    {
      "trigger": "bug|erro|corrigir|fix",
      "intent": "debugging",
      "required_context": [
        ".antigravity/workflows/error-recovery.md",
        ".antigravity/lessons/"
      ]
    },
    {
      "trigger": "implementar|criar|feature",
      "intent": "implementation",
      "required_context": [
        ".antigravity/workflows/feature-development.md"
      ]
    },
    {
      "trigger": "testar|test|testes",
      "intent": "testing",
      "required_context": [
        ".antigravity/skills/test-generator/SKILL.md"
      ]
    }
  ],
  "auto_orchestration": {
    "enabled": true,
    "instruction": "When triggers are detected, load required context before responding."
  }
}
HEREDOC

    write_file ".claude/hooks.json" "$hooks_config"
}

# ============================================================================
# Bootstrap Lock
# ============================================================================

create_bootstrap_lock() {
    if [ "$DRY_RUN" = true ]; then
        return
    fi

    local lock_content
    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S')

    read -r -d '' lock_content << HEREDOC || true
# Antigravity Bootstrap Lock
version: ${SCRIPT_VERSION}
mode: ${MODE}
stack: ${STACK}
timestamp: ${timestamp}
project: ${PROJECT_NAME}
HEREDOC

    echo "$lock_content" > ".antigravity/bootstrap.lock"
    print_success "Bootstrap lock criado"
}

# ============================================================================
# PRD Template (para modo new sem PRD)
# ============================================================================

create_prd_template() {
    if [ "$MODE" != "new" ] || [ -n "$PRD_PATH" ]; then
        return
    fi

    local content
    read -r -d '' content << HEREDOC || true
# PRD - ${PROJECT_NAME}

## Objetivo
[Descreva o objetivo principal do projeto]

## Visao
[Descreva a visao de longo prazo]

## Stack Tecnologica
- **Backend:** ${STACK}
- **Frontend:** [Definir]
- **Database:** [Definir]

## Features

### MVP (v1.0)
- [ ] Feature 1
- [ ] Feature 2
- [ ] Feature 3

### Futuras
- [ ] Feature 4
- [ ] Feature 5

## Requisitos Nao-Funcionais
- Performance: [Definir]
- Seguranca: [Definir]
- Escalabilidade: [Definir]

## Timeline
- [ ] Fase 1: [Descricao]
- [ ] Fase 2: [Descricao]

---

**Preencha este PRD e execute novamente:**
\`./antigravity-bootstrap.sh --mode new --prd docs/prd-template.md\`
HEREDOC

    write_file "docs/prd-template.md" "$content"
    print_info "Template de PRD criado em docs/prd-template.md"
}

# ============================================================================
# Handlers por Modo
# ============================================================================

handle_new_mode() {
    print_step "Modo: NEW (PRD-based)"

    create_directories
    create_prd_template
    create_context_md_new
    create_agents_md
    create_source_index
    create_antigravity_readme
    create_session_state

    # Agentes base
    create_agent_architect
    create_agent_backend
    create_agent_frontend
    create_agent_devops
    create_agent_qa

    # Rules
    create_rule_global
    create_rule_coding_standards
    create_rule_stack_specific

    # Workflows
    create_workflow_bootstrap
    create_workflow_feature_development
    create_workflow_refactor
    create_workflow_validation_commit

    # Skills
    create_skill_orchestrator
    create_skill_task_planner

    # project-docs
    create_project_docs

    # MCP e Hooks
    setup_mcp_engine
    create_mcp_config
    setup_claude_hooks
    create_bootstrap_lock
}

handle_refactor_mode() {
    print_step "Modo: REFACTOR (Legacy Analysis)"

    detect_existing_modules

    create_directories
    create_context_md_refactor
    create_agents_md
    create_source_index
    create_antigravity_readme
    create_session_state

    # Agentes base + especializados
    create_agent_architect
    create_agent_backend
    create_agent_frontend
    create_agent_devops
    create_agent_qa
    create_agent_legacy_analyzer
    create_agent_security_guardian

    # Rules
    create_rule_global
    create_rule_coding_standards
    create_rule_stack_specific

    # Workflows
    create_workflow_bootstrap
    create_workflow_feature_development
    create_workflow_refactor
    create_workflow_error_recovery
    create_workflow_validation_commit
    create_workflow_legacy

    # Skills
    create_skill_orchestrator
    create_skill_code_analyzer
    create_skill_debug_assistant
    create_skill_task_planner

    # project-docs
    create_project_docs

    # MCP e Hooks
    setup_mcp_engine
    create_mcp_config
    setup_claude_hooks
    create_bootstrap_lock
}

handle_minimal_mode() {
    print_step "Modo: MINIMAL"

    create_directories
    create_context_md_full
    create_agents_md
    create_source_index
    create_antigravity_readme
    create_session_state

    # Apenas agentes e rules base
    create_agent_architect
    create_agent_backend
    create_agent_qa
    create_rule_global
    create_rule_coding_standards

    # Workflows mínimos
    create_workflow_bootstrap
    create_workflow_feature_development

    # Skill base
    create_skill_orchestrator

    create_bootstrap_lock
}

handle_full_mode() {
    print_step "Modo: FULL (Complete Installation)"

    create_directories
    create_context_md_full
    create_agents_md
    create_source_index
    create_antigravity_readme
    create_session_state

    # Todos os agentes
    create_agent_architect
    create_agent_backend
    create_agent_frontend
    create_agent_devops
    create_agent_qa
    create_agent_legacy_analyzer
    create_agent_security_guardian

    # Todas as rules
    create_rule_global
    create_rule_coding_standards
    create_rule_stack_specific

    # Todos os workflows
    create_workflow_bootstrap
    create_workflow_feature_development
    create_workflow_refactor
    create_workflow_error_recovery
    create_workflow_validation_commit
    create_workflow_legacy

    # Todos os skills
    create_skill_orchestrator
    create_skill_code_analyzer
    create_skill_debug_assistant
    create_skill_test_generator
    create_skill_task_planner

    # project-docs
    create_project_docs

    # MCP e Hooks
    setup_mcp_engine
    create_mcp_config
    setup_claude_hooks
    create_bootstrap_lock
}

# ============================================================================
# Sumário Final
# ============================================================================

print_summary() {
    print_step "Bootstrap Concluido"

    echo -e "\n${GREEN}Antigravity Bootstrap v${SCRIPT_VERSION} instalado com sucesso!${NC}\n"

    echo -e "${CYAN}Configuracao:${NC}"
    echo -e "  ${YELLOW}Projeto:${NC} $PROJECT_NAME"
    echo -e "  ${YELLOW}Stack:${NC} $STACK"
    echo -e "  ${YELLOW}Modo:${NC} $MODE"

    echo -e "\n${CYAN}Estatisticas:${NC}"
    echo -e "  Arquivos criados: ${GREEN}$FILES_CREATED${NC}"
    echo -e "  Arquivos pulados: ${YELLOW}$FILES_SKIPPED${NC}"
    echo -e "  Diretorios criados: ${GREEN}$DIRS_CREATED${NC}"

    echo -e "\n${CYAN}Estrutura criada:${NC}"
    echo "  AGENTS.md                    # Entry point"
    echo "  context.md                   # Contexto do projeto"
    echo "  .antigravity/"
    echo "  ├── agents/                  # Agentes especializados"
    echo "  ├── rules/                   # Regras de codigo"
    echo "  ├── workflows/               # Fluxos de trabalho"
    echo "  ├── skills/                  # Skills"
    echo "  ├── state/                   # Estado da sessao"
    echo "  └── source-index.json        # Indice de fontes"

    if [ "$NO_MCP" = false ]; then
        echo "  .mcp.json                    # Configuracao MCP"
    fi

    if [ "$NO_HOOKS" = false ]; then
        echo "  .claude/hooks.json           # Hooks do Claude"
    fi

    echo -e "\n${CYAN}Proximos passos:${NC}"
    echo -e "  1. Revise ${YELLOW}context.md${NC} e preencha os detalhes"
    echo -e "  2. Adicione documentacao em ${YELLOW}project-docs/${NC}"
    echo -e "  3. Diga ao assistente: ${CYAN}\"modo agente\"${NC}"

    if [ "$MODE" = "new" ] && [ -z "$PRD_PATH" ]; then
        echo -e "\n${YELLOW}Nota:${NC} Edite ${CYAN}docs/prd-template.md${NC} com seu PRD"
    fi

    if [ "$MODE" = "refactor" ]; then
        echo -e "\n${YELLOW}Nota:${NC} Para analise profunda, execute:"
        echo -e "  ${CYAN}mcp__antigravity__classify_intent(\"analisar codigo legado\")${NC}"
    fi

    echo -e "\n${GREEN}Done!${NC}\n"
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header

    parse_args "$@"

    if [ "$DRY_RUN" = true ]; then
        print_warning "Modo DRY-RUN: nenhum arquivo sera criado"
    fi

    echo -e "${CYAN}Configuracao:${NC}"
    print_mode
    echo -e "  ${CYAN}Stack:${NC} ${STACK}"
    echo -e "  ${CYAN}Projeto:${NC} ${PROJECT_NAME}"

    # Auto-detectar stack se necessário
    if [ "$AUTO_DETECT" = true ]; then
        detect_stack
    else
        print_info "Stack especificada manualmente: $STACK"
    fi

    # Detectar contexto do projeto
    detect_project_context

    # Executar handler do modo
    case "$MODE" in
        "new")
            handle_new_mode
            ;;
        "refactor")
            handle_refactor_mode
            ;;
        "minimal")
            handle_minimal_mode
            ;;
        "full")
            handle_full_mode
            ;;
    esac

    if [ "$DRY_RUN" = false ]; then
        print_summary
    else
        echo -e "\n${YELLOW}Modo DRY-RUN concluido.${NC}"
        echo -e "Execute sem ${CYAN}--dry-run${NC} para criar os arquivos.\n"
    fi
}

main "$@"
