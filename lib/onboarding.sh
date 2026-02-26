#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Onboarding Interativo
# ============================================================================
# Coleta contexto do projeto via perguntas interativas após aidev init.
# Salva em .aidev/state/onboarding.json e gera project-handbook.md.
# Personaliza docs conforme stack detectada.
# ============================================================================

# ============================================================================
# QUESTÕES INTERATIVAS
# ============================================================================

# Roda o fluxo completo de onboarding
# Uso: run_onboarding "/path/to/project" "stack" "maturity"
run_onboarding() {
    local project_path="$1"
    local stack="${2:-generic}"
    local maturity="${3:-unknown}"
    local state_dir="$project_path/.aidev/state"
    local onboarding_file="$state_dir/onboarding.json"

    # Não re-executa se já existe (pode ser sobrescrito com --force)
    if [ -f "$onboarding_file" ] && [ "$AIDEV_FORCE" != "true" ]; then
        print_info "Onboarding já realizado. Use --force para refazer."
        return 0
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Vamos personalizar sua experiência! (Enter para pular)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local objective="" features="" restrictions="" integrations="" team_level="" code_patterns=""

    # Q1: Objetivo principal
    printf "  %s\n  → " "$(print_info "1/6 Qual o objetivo principal deste projeto?" 2>&1 || echo "1/6 Qual o objetivo principal deste projeto?")"
    read -r objective </dev/tty || objective=""

    # Q2: Funcionalidades prioritárias
    printf "  %s\n  → " "$(print_info "2/6 Quais funcionalidades são prioritárias? (ex: autenticação, dashboard, API)" 2>&1 || echo "2/6 Quais funcionalidades são prioritárias?")"
    read -r features </dev/tty || features=""

    # Q3: Restrições técnicas ou de negócio
    printf "  %s\n  → " "$(print_info "3/6 Há restrições técnicas ou de negócio? (ex: LGPD, sem banco NoSQL)" 2>&1 || echo "3/6 Há restrições técnicas ou de negócio?")"
    read -r restrictions </dev/tty || restrictions=""

    # Q4: Integrações necessárias
    printf "  %s\n  → " "$(print_info "4/6 Quais integrações são necessárias? (ex: Stripe, AWS S3, SendGrid)" 2>&1 || echo "4/6 Quais integrações são necessárias?")"
    read -r integrations </dev/tty || integrations=""

    # Q5: Nível da equipe
    echo ""
    print_info "5/6 Qual o nível de experiência da equipe?"
    echo "    [1] Junior  [2] Misto  [3] Senior  [4] Solo dev"
    printf "  → "
    read -r team_choice </dev/tty || team_choice=""
    case "$team_choice" in
        1) team_level="junior" ;;
        3) team_level="senior" ;;
        4) team_level="solo" ;;
        *) team_level="mixed" ;;
    esac

    # Q6: Padrões de código já estabelecidos
    printf "  %s\n  → " "$(print_info "6/6 Há padrões de código estabelecidos? (ex: PSR-12, Airbnb, deixe vazio se nenhum)" 2>&1 || echo "6/6 Há padrões de código estabelecidos?")"
    read -r code_patterns </dev/tty || code_patterns=""

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Salva JSON
    _onboarding_save_json "$onboarding_file" \
        "$stack" "$maturity" \
        "$objective" "$features" "$restrictions" \
        "$integrations" "$team_level" "$code_patterns"

    # Gera project-handbook.md
    _onboarding_generate_handbook "$project_path" \
        "$stack" "$maturity" \
        "$objective" "$features" "$restrictions" \
        "$integrations" "$team_level" "$code_patterns"

    # Personaliza CLAUDE.md com contexto do projeto
    _onboarding_customize_claude_md "$project_path" \
        "$stack" "$objective" "$features" "$restrictions" "$integrations"

    print_success "Projeto configurado! Contexto salvo em .aidev/state/onboarding.json"
    print_info  "Handbook em: .aidev/docs/project-handbook.md"
}

# ============================================================================
# PERSISTÊNCIA
# ============================================================================

_onboarding_save_json() {
    local file="$1"
    local stack="$2" maturity="$3"
    local objective="$4" features="$5" restrictions="$6"
    local integrations="$7" team_level="$8" code_patterns="$9"
    local date_now
    date_now=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)

    mkdir -p "$(dirname "$file")"
    cat > "$file" <<EOF
{
  "version": "1.0",
  "collected_at": "$date_now",
  "project": {
    "stack": "$stack",
    "maturity": "$maturity"
  },
  "answers": {
    "objective": "$(_onboarding_escape_json "$objective")",
    "priority_features": "$(_onboarding_escape_json "$features")",
    "restrictions": "$(_onboarding_escape_json "$restrictions")",
    "integrations": "$(_onboarding_escape_json "$integrations")",
    "team_level": "$team_level",
    "code_patterns": "$(_onboarding_escape_json "$code_patterns")"
  }
}
EOF
    print_debug "onboarding.json salvo em: $file"
}

_onboarding_escape_json() {
    local s="$1"
    # Escapa aspas duplas e barras invertidas para JSON válido
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    echo -n "$s"
}

# ============================================================================
# GERAÇÃO DO PROJECT HANDBOOK
# ============================================================================

_onboarding_generate_handbook() {
    local project_path="$1"
    local stack="$2" maturity="$3"
    local objective="$4" features="$5" restrictions="$6"
    local integrations="$7" team_level="$8" code_patterns="$9"
    local docs_dir="$project_path/.aidev/docs"
    local handbook="$docs_dir/project-handbook.md"
    local date_now
    date_now=$(date +%Y-%m-%d)
    local project_name
    project_name=$(basename "$project_path")

    mkdir -p "$docs_dir"

    # Define orientações específicas por nível de equipe
    local team_guidance=""
    case "$team_level" in
        junior)
            team_guidance="- Prefira soluções simples e bem documentadas
- Explique decisões arquiteturais nos comentários
- TDD obrigatório para garantir confiança
- Code review detalhado antes de cada merge" ;;
        senior)
            team_guidance="- Pode adotar padrões avançados e abstrações
- Foco em performance e escalabilidade desde o início
- Autonomia para decisões arquiteturais
- Code review focado em trade-offs estratégicos" ;;
        solo)
            team_guidance="- Documente decisões para seu eu futuro
- Checkpoints frequentes para não perder contexto
- Prefira soluções bem conhecidas ao invés de experimentais" ;;
        *)
            team_guidance="- Balance complexidade com acessibilidade
- Documentação clara para nivelamento
- Pair programming em partes críticas" ;;
    esac

    # Define contexto de stack
    local stack_context=""
    stack_context=$(_onboarding_stack_context "$stack")

    cat > "$handbook" <<EOF
# Project Handbook — $project_name

> Documento vivo gerado pelo onboarding do AI Dev Superpowers.
> Atualizado automaticamente em milestones e lições aprendidas.

**Gerado em:** $date_now | **Stack:** $stack | **Maturidade:** $maturity

---

## Objetivo do Projeto

${objective:-*Não informado. Atualize este campo em `.aidev/state/onboarding.json`.*}

---

## Funcionalidades Prioritárias

${features:-*Não informado.*}

---

## Restrições e Constraints

${restrictions:-*Nenhuma restrição específica informada.*}

---

## Integrações

${integrations:-*Nenhuma integração específica informada.*}

---

## Equipe e Padrões

**Nível:** ${team_level}
${code_patterns:+**Padrões de código:** $code_patterns}

**Orientações para este nível:**
$team_guidance

---

## Stack e Contexto Técnico

**Stack detectada:** $stack

$stack_context

---

## Decisões Arquiteturais

> *Registre aqui as decisões arquiteturais importantes.*
> Formato sugerido: [DATA] Decisão — Motivo

---

## Armadilhas Conhecidas

> *Lições aprendidas durante o desenvolvimento.*
> Alimentado automaticamente pela skill \`learned-lesson\`.

---

## Referências Rápidas

| Recurso | Caminho |
|---------|---------|
| Agentes | \`.aidev/agents/\` |
| Regras de código | \`.aidev/rules/\` |
| Lições aprendidas | \`.aidev/memory/kb/\` |
| Estado atual | \`.aidev/state/unified.json\` |
| Este handbook | \`.aidev/docs/project-handbook.md\` |

---

*Última atualização: $date_now — AI Dev Superpowers v${AIDEV_VERSION:-3}*
EOF

    print_debug "project-handbook.md gerado em: $handbook"
}

# ============================================================================
# PERSONALIZAÇÃO DO CLAUDE.MD POR STACK
# ============================================================================

_onboarding_customize_claude_md() {
    local project_path="$1"
    local stack="$2" objective="$3" features="$4"
    local restrictions="$5" integrations="$6"
    local claude_md="$project_path/CLAUDE.md"

    [ ! -f "$claude_md" ] && return 0

    # Só adiciona seção se ainda não existe
    if grep -q "## Contexto do Projeto" "$claude_md" 2>/dev/null; then
        return 0
    fi

    local stack_hints=""
    stack_hints=$(_onboarding_stack_hints "$stack")

    # Append da seção de contexto ao final do CLAUDE.md
    cat >> "$claude_md" <<EOF

---

## Contexto do Projeto (gerado pelo onboarding)

**Stack:** $stack
**Objetivo:** ${objective:-não informado}
${features:+**Funcionalidades prioritárias:** $features}
${restrictions:+**Restrições:** $restrictions}
${integrations:+**Integrações:** $integrations}

### Convenções Específicas da Stack

$stack_hints

EOF
    print_debug "CLAUDE.md atualizado com contexto do projeto"
}

# ============================================================================
# CONTEXTO POR STACK (handbook)
# ============================================================================

_onboarding_stack_context() {
    local stack="$1"
    case "$stack" in
        laravel|php)
            echo "- **Framework:** Laravel — siga PSR-12 e convenções do Eloquent
- **Testes:** PHPUnit / Pest — TDD com Feature Tests para rotas
- **Padrões:** Repository Pattern, Service Layer, Form Requests
- **Deploy:** Forge, Vapor, ou Docker" ;;
        node|nodejs|express)
            echo "- **Runtime:** Node.js — prefira async/await sobre callbacks
- **Testes:** Jest ou Vitest
- **Padrões:** MVC ou Clean Architecture
- **Deploy:** Railway, Render, ou Docker" ;;
        react|nextjs|vue|nuxt)
            echo "- **Framework Frontend:** $(echo "$stack" | tr '[:lower:]' '[:upper:]')
- **Testes:** Vitest + Testing Library
- **Padrões:** Componentização, Custom Hooks, composição
- **Deploy:** Vercel, Netlify, ou CDN" ;;
        python|django|fastapi|flask)
            echo "- **Linguagem:** Python — PEP 8 obrigatório
- **Testes:** pytest
- **Padrões:** DRY, camadas bem definidas, type hints
- **Deploy:** Railway, Render, Heroku, ou Docker" ;;
        go|golang)
            echo "- **Linguagem:** Go — idiomatic Go, use gofmt
- **Testes:** go test com tabela de casos
- **Padrões:** interfaces pequenas, composição
- **Deploy:** binário único, Docker" ;;
        *)
            echo "- Stack genérica detectada — configure regras específicas em \`.aidev/rules/\`
- Siga os padrões estabelecidos no projeto" ;;
    esac
}

# ============================================================================
# HINTS POR STACK (CLAUDE.md)
# ============================================================================

_onboarding_stack_hints() {
    local stack="$1"
    case "$stack" in
        laravel|php)
            echo "- Use \`php artisan make:\` para scaffolding
- Valide sempre com Form Requests, nunca no controller
- Transactions obrigatórias em operações multi-tabela
- Factories e Seeders para todos os models (testes dependem disso)" ;;
        node|nodejs|express)
            echo "- Trate erros assíncronos com try/catch em todos os async handlers
- Valide input com zod ou joi na camada de rotas
- Nunca use process.env diretamente — sempre via módulo de config" ;;
        react|nextjs)
            echo "- Componentes devem ser puros quando possível (sem side effects)
- useEffect com dependency array explícito — sem array vazio sem justificativa
- Data fetching no Server Component quando usar Next.js App Router" ;;
        python|django|fastapi|flask)
            echo "- Nunca faça queries no template (N+1)
- Type hints em todas as funções públicas
- Virtual environment obrigatório — documente versão do Python" ;;
        *)
            echo "- Adicione convenções específicas conforme o projeto evolui" ;;
    esac
}

# ============================================================================
# LEITURA DO ONBOARDING (para uso por outros módulos)
# ============================================================================

# Lê um campo do onboarding.json
# Uso: onboarding_get "objective" "/path/to/project"
onboarding_get() {
    local field="$1"
    local project_path="${2:-.}"
    local file="$project_path/.aidev/state/onboarding.json"

    [ -f "$file" ] || return 0
    grep "\"$field\":" "$file" 2>/dev/null | head -1 | sed 's/.*": *"\(.*\)".*/\1/'
}

export -f run_onboarding
export -f onboarding_get
