#!/bin/bash

# ============================================================================
# AI Dev Superpowers - Instalador Unificado
# ============================================================================
# Combina o melhor de Antigravity e Superpowers:
# - Detecção de stack e templates (Antigravity)
# - Skills maduras e TDD rigoroso (Superpowers)
# - MCP Engine + Cross-platform support
#
# Uso: ./aidev-installer.sh [OPTIONS]
#
# Exemplos:
#   ./aidev-installer.sh --install-in ./my-project --mode new --prd docs/prd.md
#   ./aidev-installer.sh --install-in ./legacy-app --mode refactor --stack laravel
#   ./aidev-installer.sh --install-in . --mode full --detect
# ============================================================================

set -euo pipefail

# ============================================================================
# Configurações
# ============================================================================

SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="AI Dev Superpowers Installer"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Defaults
INSTALL_PATH=""
MODE="full"
STACK="generic"
PRD_PATH=""
FORCE=false
DRY_RUN=false
AUTO_DETECT=true
NO_MCP=false
NO_HOOKS=false
PLATFORM="auto"

# Contadores
FILES_CREATED=0
DIRS_CREATED=0

# ============================================================================
# Funções de Output
# ============================================================================

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}${SCRIPT_NAME}${NC} v${SCRIPT_VERSION}${CYAN}                          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}Instalação Concluída com Sucesso!${NC}${CYAN}                           ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  Diretórios criados: ${DIRS_CREATED}${CYAN}                                    ║${NC}"
    echo -e "${CYAN}║${NC}  Arquivos criados:   ${FILES_CREATED}${CYAN}                                   ║${NC}"
    echo -e "${CYAN}║${NC}  Modo:               ${MODE}${CYAN}                                      ║${NC}"
    echo -e "${CYAN}║${NC}  Stack:              ${STACK}${CYAN}                                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================================
# Funções de Ajuda
# ============================================================================

show_help() {
    cat << EOF
${CYAN}${SCRIPT_NAME}${NC} v${SCRIPT_VERSION}
${YELLOW}Sistema Unificado de Governança de IA para Desenvolvimento${NC}

${YELLOW}Uso:${NC}
  ./aidev-installer.sh --install-in <path> [OPTIONS]

${YELLOW}Opções Principais:${NC}
  --install-in <path>   Diretório onde instalar (obrigatório)

${YELLOW}Modos de Operação:${NC}
  --mode new           Sistema novo baseado em PRD
                       • Cria context.md do PRD
                       • Templates vazios em project-docs/
                       • Workflows de criação
                       • Requer: --prd <path>

  --mode refactor      Sistema existente para refatoração
                       • Analisa código existente
                       • context.md da análise estrutural
                       • Agentes de refactoring e segurança
                       • Skills de análise de legado

  --mode minimal       Estrutura mínima
                       • Core essencial apenas
                       • Sem regras específicas de stack
                       • Ideal para exploração

  --mode full          Instalação completa (padrão)
                       • Todos agentes, rules, workflows, skills
                       • MCP Engine configurado
                       • Hooks automáticos

${YELLOW}Configuração de Stack:${NC}
  --stack <stack>      Especifica stack manualmente
  --detect             Auto-detecta stack (padrão)

${YELLOW}Stacks Suportadas:${NC}
  laravel              PHP + Laravel
  filament             PHP + Laravel + Filament
  livewire             PHP + Laravel + Livewire
  node                 Node.js genérico
  react                Node + React
  nextjs               Node + Next.js
  python               Python
  generic              Regras base apenas

${YELLOW}Plataformas:${NC}
  --platform <name>    claude-code, opencode, codex, rovo, gemini, antigravity
  auto                 Detecta automaticamente (padrão)

${YELLOW}Comportamento:${NC}
  --prd <path>         Caminho para PRD (obrigatório em --mode new)
  --force              Sobrescreve arquivos existentes
  --dry-run            Mostra o que seria criado sem executar
  --no-mcp             Não configura MCP Engine
  --no-hooks           Não configura hooks automáticos
  -h, --help           Mostra esta ajuda

${YELLOW}Exemplos:${NC}
  # Novo projeto Laravel a partir de PRD
  ./aidev-installer.sh --install-in ./my-app --mode new --stack laravel --prd docs/prd.md

  # Refatoração de sistema legado
  ./aidev-installer.sh --install-in ./legacy-system --mode refactor --detect

  # Setup mínimo para exploração
  ./aidev-installer.sh --install-in . --mode minimal

  # Instalação completa com auto-detecção
  ./aidev-installer.sh --install-in . --mode full --detect

${YELLOW}Estrutura Criada:${NC}
  .aidev/                      # Diretório principal
  ├── core/                    # Core compartilhado
  │   └── skills-core.js       # Engine de skills
  ├── agents/                  # Agentes especializados
  │   ├── architect.md
  │   ├── backend.md
  │   ├── frontend.md
  │   └── ...
  ├── skills/                  # Skills compostas
  │   ├── superpowers/         # Do Superpowers
  │   │   ├── brainstorming/
  │   │   ├── test-driven-development/
  │   │   └── ...
  │   └── orchestrator/        # Do Antigravity
  │       ├── code-analyzer/
  │       └── ...
  ├── rules/                   # Regras por stack
  │   ├── global.md
  │   └── [stack].md
  ├── workflows/               # Fluxos de trabalho
  │   ├── feature-development.md
  │   └── tdd-cycle.md
  ├── engine/                  # MCP Server
  │   └── mcp-server.ts
  ├── state/                   # Estado da sessão
  │   └── session-state.md
  └── config/                  # Configurações
      └── platform-config.json

${YELLOW}Pós-Instalação:${NC}
  1. Configure .env se necessário
  2. Leia .aidev/README.md
  3. Execute testes: npm test (se aplicável)
  4. Inicie desenvolvimento com TDD rigoroso

${YELLOW}Documentação:${NC}
  - Superpowers: https://github.com/obra/superpowers
  - Issues: https://github.com/obra/superpowers/issues

EOF
}

# ============================================================================
# Funções de Sistema
# ============================================================================

ensure_dir() {
    local dir="$1"
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Criaria diretório: $dir"
        return
    fi
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        ((DIRS_CREATED++)) || true
    fi
}

write_file() {
    local file="$1"
    local content="$2"

    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Criaria arquivo: $file"
        return
    fi

    if [ -f "$file" ] && [ "$FORCE" = false ]; then
        print_warning "Arquivo existe (use --force): $file"
        return
    fi

    ensure_dir "$(dirname "$file")"
    echo "$content" > "$file"
    ((FILES_CREATED++)) || true
}

# ============================================================================
# Detecção de Stack
# ============================================================================

detect_stack() {
    local path="$1"
    
    if [ ! -d "$path" ]; then
        echo "generic"
        return
    fi
    
    cd "$path" || return
    
    # Laravel/PHP
    if [ -f "composer.json" ]; then
        if grep -q "laravel/framework" composer.json 2>/dev/null; then
            if grep -q "filament" composer.json 2>/dev/null; then
                echo "filament"
                return
            elif grep -q "livewire" composer.json 2>/dev/null; then
                echo "livewire"
                return
            else
                echo "laravel"
                return
            fi
        fi
    fi
    
    # Node.js
    if [ -f "package.json" ]; then
        if grep -q "next" package.json 2>/dev/null; then
            echo "nextjs"
            return
        elif grep -q "react" package.json 2>/dev/null; then
            echo "react"
            return
        else
            echo "node"
            return
        fi
    fi
    
    # Python
    if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "python"
        return
    fi
    
    echo "generic"
}

# ============================================================================
# Detecção de Plataforma
# ============================================================================

detect_platform() {
    # Verifica Claude Code
    if command -v claude &> /dev/null; then
        echo "claude-code"
        return
    fi
    
    # Verifica OpenCode
    if [ -d "$HOME/.config/opencode" ]; then
        echo "opencode"
        return
    fi
    
    # Verifica Rovo
    if command -v rovo &> /dev/null; then
        echo "rovo"
        return
    fi
    
    # Verifica Codex
    if [ -d "$HOME/.codex" ]; then
        echo "codex"
        return
    fi
    
    # Verifica Gemini
    if command -v gemini &> /dev/null; then
        echo "gemini"
        return
    fi
    
    # Default
    echo "generic"
}

# ============================================================================
# Parse de Argumentos
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-in)
                INSTALL_PATH="$2"
                shift 2
                ;;
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
            --platform)
                PLATFORM="$2"
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
}

# ============================================================================
# Validação
# ============================================================================

validate_args() {
    # Validar --install-in
    if [ -z "$INSTALL_PATH" ]; then
        print_error "--install-in é obrigatório"
        echo "Use --help para ver opções disponíveis"
        exit 1
    fi
    
    # Validar modo
    if [[ ! "$MODE" =~ ^(new|refactor|minimal|full)$ ]]; then
        print_error "Modo inválido: $MODE"
        echo "Modos válidos: new, refactor, minimal, full"
        exit 1
    fi
    
    # Validar PRD para modo new
    if [ "$MODE" = "new" ] && [ -z "$PRD_PATH" ]; then
        print_error "--mode new requer --prd <path>"
        exit 1
    fi
    
    # Validar PRD existe
    if [ -n "$PRD_PATH" ] && [ ! -f "$PRD_PATH" ]; then
        print_error "PRD não encontrado: $PRD_PATH"
        exit 1
    fi
    
    # Validar stack
    if [[ ! "$STACK" =~ ^(laravel|filament|livewire|node|react|nextjs|python|generic)$ ]]; then
        print_error "Stack inválida: $STACK"
        echo "Stacks válidas: laravel, filament, livewire, node, react, nextjs, python, generic"
        exit 1
    fi
}

# ============================================================================
# Criação de Estrutura Base
# ============================================================================

create_base_structure() {
    print_step "Criando estrutura base"
    
    local base_dirs=(
        ".aidev"
        ".aidev/core"
        ".aidev/agents"
        ".aidev/skills"
        ".aidev/skills/superpowers"
        ".aidev/skills/orchestrator"
        ".aidev/rules"
        ".aidev/workflows"
        ".aidev/state"
        ".aidev/state/lessons"
        ".aidev/config"
    )
    
    # Adicionar engine se MCP habilitado
    if [ "$NO_MCP" = false ]; then
        base_dirs+=(".aidev/engine")
    fi
    
    # Adicionar diretórios específicos do modo
    case "$MODE" in
        new)
            base_dirs+=("project-docs" "project-docs/modules")
            ;;
        refactor)
            base_dirs+=(".aidev/analysis")
            ;;
    esac
    
    for dir in "${base_dirs[@]}"; do
        ensure_dir "$INSTALL_PATH/$dir"
    done
    
    print_success "Estrutura base criada"
}

# ============================================================================
# Core: skills-core.js
# ============================================================================

create_skills_core() {
    print_step "Criando skills-core.js"
    
    local content
    read -r -d '' content << 'EOF' || true
/**
 * AI Dev Superpowers - Skills Core Module
 * Unified skill discovery and parsing engine
 * Compatible with Claude Code, OpenCode, Codex, Rovo, Gemini
 */

import fs from 'fs/promises';
import path from 'path';

export class SkillsCore {
  constructor(rootPath = '.aidev') {
    this.rootPath = rootPath;
    this.skillsCache = new Map();
  }

  /**
   * Discover all available skills
   */
  async discoverSkills() {
    const skillsPaths = [
      path.join(this.rootPath, 'skills/superpowers'),
      path.join(this.rootPath, 'skills/orchestrator'),
    ];

    const skills = [];

    for (const skillsPath of skillsPaths) {
      try {
        const entries = await fs.readdir(skillsPath, { withFileTypes: true });
        
        for (const entry of entries) {
          if (entry.isDirectory()) {
            const skillFile = path.join(skillsPath, entry.name, 'SKILL.md');
            try {
              await fs.access(skillFile);
              const skill = await this.parseSkill(skillFile);
              if (skill) {
                skills.push(skill);
              }
            } catch {
              // Skill file doesn't exist, skip
            }
          }
        }
      } catch {
        // Path doesn't exist, skip
      }
    }

    return skills;
  }

  /**
   * Parse a SKILL.md file
   */
  async parseSkill(skillPath) {
    try {
      const content = await fs.readFile(skillPath, 'utf-8');
      
      // Parse frontmatter
      const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
      let metadata = {};
      
      if (frontmatterMatch) {
        const yaml = frontmatterMatch[1];
        metadata = this.parseYaml(yaml);
      }

      return {
        name: metadata.name || path.basename(path.dirname(skillPath)),
        description: metadata.description || '',
        triggers: metadata.triggers || [],
        globs: metadata.globs || [],
        content: content,
        path: skillPath,
      };
    } catch (error) {
      console.error(`Error parsing skill ${skillPath}:`, error);
      return null;
    }
  }

  /**
   * Simple YAML parser for frontmatter
   */
  parseYaml(yaml) {
    const result = {};
    const lines = yaml.split('\n');
    let currentKey = null;
    let currentArray = null;

    for (const line of lines) {
      const trimmed = line.trim();
      
      if (!trimmed) continue;

      // Array item
      if (trimmed.startsWith('-')) {
        const value = trimmed.substring(1).trim().replace(/^["']|["']$/g, '');
        if (currentArray) {
          currentArray.push(value);
        }
      }
      // Key-value
      else if (trimmed.includes(':')) {
        const [key, ...valueParts] = trimmed.split(':');
        const value = valueParts.join(':').trim().replace(/^["']|["']$/g, '');
        
        currentKey = key.trim();
        
        if (value) {
          result[currentKey] = value;
          currentArray = null;
        } else {
          // Start of array
          result[currentKey] = [];
          currentArray = result[currentKey];
        }
      }
    }

    return result;
  }

  /**
   * Find skills matching triggers or context
   */
  async findMatchingSkills(userInput, fileContext = []) {
    const skills = await this.discoverSkills();
    const matches = [];

    for (const skill of skills) {
      let score = 0;

      // Check triggers
      for (const trigger of skill.triggers) {
        if (userInput.toLowerCase().includes(trigger.toLowerCase())) {
          score += 10;
        }
      }

      // Check file globs
      for (const glob of skill.globs) {
        for (const file of fileContext) {
          if (this.matchGlob(file, glob)) {
            score += 5;
          }
        }
      }

      if (score > 0) {
        matches.push({ skill, score });
      }
    }

    // Sort by score descending
    matches.sort((a, b) => b.score - a.score);

    return matches.map(m => m.skill);
  }

  /**
   * Simple glob matching
   */
  matchGlob(filePath, pattern) {
    const regex = pattern
      .replace(/\./g, '\\.')
      .replace(/\*/g, '.*')
      .replace(/\?/g, '.');
    
    return new RegExp(`^${regex}$`).test(filePath);
  }

  /**
   * Load a specific skill by name
   */
  async loadSkill(skillName) {
    if (this.skillsCache.has(skillName)) {
      return this.skillsCache.get(skillName);
    }

    const skills = await this.discoverSkills();
    const skill = skills.find(s => s.name === skillName);

    if (skill) {
      this.skillsCache.set(skillName, skill);
    }

    return skill;
  }
}

export default SkillsCore;
EOF

    write_file "$INSTALL_PATH/.aidev/core/skills-core.js" "$content"
    print_success "skills-core.js criado"
}

# ============================================================================
# Criar Agents
# ============================================================================

create_agents() {
    print_step "Criando agentes"
    
    # Source templates
    source "$(dirname "$0")/aidev-templates.sh" 2>/dev/null || true
    
    local agents=()
    
    case "$MODE" in
        minimal)
            agents=("orchestrator" "architect")
            ;;
        new)
            agents=("orchestrator" "architect" "backend" "frontend" "qa")
            ;;
        refactor)
            agents=("orchestrator" "architect" "backend" "legacy_analyzer" "security_guardian")
            ;;
        full)
            agents=("orchestrator" "architect" "backend" "frontend" "qa" "devops" "legacy_analyzer" "security_guardian")
            ;;
    esac
    
    for agent in "${agents[@]}"; do
        local func_name="create_agent_${agent}"
        if type "$func_name" &>/dev/null; then
            write_file "$INSTALL_PATH/.aidev/agents/${agent}.md" "$(${func_name})"
        fi
    done
    
    print_success "${#agents[@]} agentes criados"
}

# ============================================================================
# Criar Skills
# ============================================================================

create_skills() {
    print_step "Criando skills"
    
    # Source templates
    source "$(dirname "$0")/aidev-templates.sh" 2>/dev/null || true
    
    # Superpowers skills
    local superpowers_skills=()
    local orchestrator_skills=()
    
    case "$MODE" in
        minimal)
            superpowers_skills=("brainstorming" "test_driven_development")
            orchestrator_skills=()
            ;;
        new)
            superpowers_skills=("brainstorming" "writing_plans" "test_driven_development")
            orchestrator_skills=("task_planner")
            ;;
        refactor)
            superpowers_skills=("systematic_debugging" "test_driven_development")
            orchestrator_skills=("code_analyzer" "task_planner")
            ;;
        full)
            superpowers_skills=("brainstorming" "writing_plans" "test_driven_development" "systematic_debugging")
            orchestrator_skills=("code_analyzer" "task_planner")
            ;;
    esac
    
    # Criar Superpowers skills
    for skill in "${superpowers_skills[@]}"; do
        local func_name="create_skill_${skill}"
        if type "$func_name" &>/dev/null; then
            ensure_dir "$INSTALL_PATH/.aidev/skills/superpowers/${skill}"
            write_file "$INSTALL_PATH/.aidev/skills/superpowers/${skill}/SKILL.md" "$(${func_name})"
        fi
    done
    
    # Criar Orchestrator skills
    for skill in "${orchestrator_skills[@]}"; do
        local func_name="create_skill_${skill}"
        if type "$func_name" &>/dev/null; then
            ensure_dir "$INSTALL_PATH/.aidev/skills/orchestrator/${skill}"
            write_file "$INSTALL_PATH/.aidev/skills/orchestrator/${skill}/SKILL.md" "$(${func_name})"
        fi
    done
    
    local total=$((${#superpowers_skills[@]} + ${#orchestrator_skills[@]}))
    print_success "$total skills criadas"
}

# ============================================================================
# Criar Rules por Stack
# ============================================================================

create_global_rules() {
    local language="${1:-pt-BR}"

    if [ "$language" = "pt-BR" ]; then
        cat << 'GLOBALEOF'
# Global Rules

---

## REGRA DE IDIOMA (PRIORIDADE MAXIMA)

**OBRIGATORIO:** TODO o codigo e documentacao DEVE estar em Portugues BR.

### Comentarios em Codigo
- **Proibido:** Comentarios em ingles
- **Obrigatorio:** Todos os comentarios em Portugues BR
- **DocBlocks:** Descricoes, `@param`, `@return`, `@throws` em portugues
- **TODOs/FIXMEs:** Sempre em portugues

### Exemplos

```php
// ❌ ERRADO
// Calculate commission based on service price
public function calculate($price) {}

// ✅ CORRETO
// Calcula comissao baseada no preco do servico
public function calculate($price) {}

// ❌ ERRADO
/**
 * Create a new appointment
 * @param array $data Appointment data
 * @return Appointment
 */

// ✅ CORRETO
/**
 * Cria um novo agendamento
 * @param array $data Dados do agendamento
 * @return Appointment
 */
```

---

## REGRA ZERO - PROTOCOLO DE INICIALIZACAO (PRIORIDADE MAXIMA)

**OBRIGATORIO:** Antes de QUALQUER atividade, executar o protocolo de inicializacao.

### Gatilhos de Ativacao
- `aidev`, `/aidev`, `ativar aidev`, `modo agente`, `superpowers`

### Checklist Obrigatorio
1. **Verificar MCPs:** Confirmar que MCPs configurados estao ativos
2. **Carregar Contexto:** Via sistema de memoria configurado
3. **Verificar Estado:** Ler `.aidev/state/session-state.md`
4. **Carregar Regras:** Confirmar conhecimento das regras do projeto

**Protocolo completo:** `.aidev/config/startup-protocol.md`

---

## Regras de Commit (OBRIGATORIO)

### Formato das Mensagens

```
<tipo>(<escopo>): <descricao>

[corpo opcional]

[rodape opcional]
```

### Tipos Permitidos

| Tipo | Uso |
|------|-----|
| `feat` | Nova funcionalidade |
| `fix` | Correcao de bug |
| `refactor` | Refatoracao de codigo |
| `test` | Adicao ou correcao de testes |
| `docs` | Documentacao |
| `style` | Formatacao (sem mudanca de logica) |
| `chore` | Tarefas de manutencao |
| `perf` | Melhorias de performance |

### Restricoes

1. **Idioma:** Mensagens no idioma configurado do projeto
2. **Sem co-autoria:** Nunca adicionar Co-Authored-By
3. **Sem emojis:** Nunca usar emojis nas mensagens

### Exemplos

```bash
feat(auth): adicionar autenticacao de dois fatores
fix(booking): corrigir validacao de horario duplicado
refactor(models): extrair logica de comissao para service
test(loyalty): adicionar testes para LoyaltyService
```

---

## REGRA PRE-COMMIT - SINCRONIZACAO OBRIGATORIA (PRIORIDADE ALTA)

**OBRIGATORIO:** Antes de QUALQUER commit, executar o protocolo de sincronizacao.

### Checklist Pre-Commit

1. **Atualizar Session State:** Editar `.aidev/state/session-state.md`
   - Marcar tarefas concluidas em `Work Completed`
   - Adicionar hash do commit quando disponivel
   - Atualizar `Next Actions` se necessario

2. **Registrar Licoes Aprendidas:** Se houve erro/bug corrigido
   - Adicionar entrada em `.aidev/state/lessons/lessons-index.md`
   - Formato: `[ERRO-XXX]` + descricao + solucao

3. **Sugerir Atualizacao de Memorias:** Se houve mudanca estrutural
   - Sugerir gravacao com tag apropriada (#projeto ou #global)
   - Aguardar confirmacao do usuario antes de gravar

### Template de Atualizacao

```markdown
## Work Completed (Data)
- [x] Tipo: Descricao breve (commit HASH)
```

---

## Atividades Fora do Escopo

Quando surgir uma atividade nao planejada, documentar no session-state.md:

### Formato

```markdown
## [OUT-OF-SCOPE] Nome da Atividade (Data)
- **Origem:** Como surgiu (pedido do usuario, bug encontrado, etc)
- **Impacto:** Afetou o cronograma? Como?
- **Resolucao:** Concluido? Adiado? Descartado?
```

---

## Test-Driven Development (OBRIGATORIO)

### O Ciclo

1. **RED:** Escrever teste que falha
2. **Verificar RED:** Rodar teste, confirmar que falha pelo motivo correto
3. **GREEN:** Escrever codigo minimo para passar
4. **Verificar GREEN:** Rodar teste, confirmar que passa
5. **REFACTOR:** Melhorar qualidade do codigo
6. **COMMIT:** Commit atomico com testes + codigo

### Regra Critica

**Se codigo existe sem testes: DELETE e comece de novo!**

---

## Principios

### YAGNI (You Aren't Gonna Need It)
- Nao adicione features "por precaucao"
- Implemente apenas o necessario AGORA
- Refatore quando a necessidade real surgir

### DRY (Don't Repeat Yourself)
- Elimine duplicacao
- Extraia padroes comuns
- Reutilize, nao recrie

### KISS (Keep It Simple, Stupid)
- Simplicidade e o objetivo principal
- Solucao mais simples que funciona
- Complexidade e inimiga da manutencao

---

## REGRA DE MEMORIA - ECONOMIA DE TOKENS (PRIORIDADE ALTA)

### Hierarquia de Sistemas de Memoria

1. **Sistema Permanente** (conhecimento do projeto)
   - Memorias de projeto: tag `#projeto`
   - Memorias globais: tag `#global`
   - Consultado via busca semantica

2. **Sistema de Sessao** (fluxo de desenvolvimento)
   - Estado de sessao: `session-state.md`
   - Licoes aprendidas: `lessons/`
   - Usado para tarefas locais e commits

### Protocolo de Consulta

1. **Inicio de sessao:** Carregar contexto do projeto
2. **Busca especifica:** Buscar por keyword/tag
3. **Fluxo de trabalho:** Sistema de sessao para estado local

### Proibicoes

- NAO ler memorias inteiras sem filtro
- NAO usar sistema de sessao para conhecimento permanente
- NAO ignorar tags na organizacao

---

## REGRA DE GRAVACAO DE MEMORIAS (HIBRIDO)

### Modo de Operacao
- Agente sugere gravacao → Usuario confirma
- NUNCA gravar automaticamente sem confirmacao

### Gatilhos para Sugerir

1. **Aprendizado:** Problema novo resolvido, padrao descoberto
2. **Conclusao:** Final de tarefa significativa
3. **Correcao:** Memoria desatualizada detectada

### Formato de Sugestao

Ao detectar gatilho, perguntar:
"Identifiquei [tipo]: [resumo]. Salvar na memoria? (#tag)"

### Tags Obrigatorias

- `#projeto` - Especifico deste projeto
- `#global` - Conhecimento reutilizavel em outros projetos

---

## Qualidade de Codigo

### Convencoes de Nomenclatura
- **Variaveis:** descritivas, camelCase
- **Funcoes:** baseadas em verbos, camelCase
- **Classes:** PascalCase
- **Constantes:** UPPER_SNAKE_CASE

### Comentarios
- Explique o PORQUE, nao o QUE
- Codigo deve ser auto-documentado
- Logica complexa precisa explicacao

### Tratamento de Erros
- Trate erros graciosamente
- Forneca mensagens significativas
- Registre erros apropriadamente
- Nunca engula excecoes silenciosamente

---

## Seguranca

### Nunca Commitar
- Chaves de API
- Senhas
- Segredos
- Credenciais

### Sempre
- Use variaveis de ambiente
- Valide todas as entradas
- Sanitize saidas
- Siga diretrizes OWASP

GLOBALEOF
    else
        cat << 'GLOBALEOF'
# Global Rules

---

## LANGUAGE RULE (MAXIMUM PRIORITY)

**REQUIRED:** All code and documentation MUST be in the configured language.

---

## RULE ZERO - STARTUP PROTOCOL (MAXIMUM PRIORITY)

**REQUIRED:** Before ANY activity, execute the startup protocol.

### Activation Triggers
- `aidev`, `/aidev`, `activate aidev`, `agent mode`, `superpowers`

### Required Checklist
1. **Verify MCPs:** Confirm configured MCPs are active
2. **Load Context:** Via configured memory system
3. **Verify State:** Read `.aidev/state/session-state.md`
4. **Load Rules:** Confirm knowledge of project rules

**Full protocol:** `.aidev/config/startup-protocol.md`

---

## Commit Rules (REQUIRED)

### Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Allowed Types

| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code refactoring |
| `test` | Test addition or fix |
| `docs` | Documentation |
| `style` | Formatting (no logic change) |
| `chore` | Maintenance tasks |
| `perf` | Performance improvements |

### Restrictions

1. **Language:** Messages in project's configured language
2. **No co-authorship:** Never add Co-Authored-By
3. **No emojis:** Never use emojis in messages

---

## PRE-COMMIT RULE - REQUIRED SYNC (HIGH PRIORITY)

**REQUIRED:** Before ANY commit, execute sync protocol.

### Pre-Commit Checklist

1. **Update Session State:** Edit `.aidev/state/session-state.md`
2. **Register Lessons Learned:** If error/bug was fixed
3. **Suggest Memory Update:** If structural change occurred

---

## Out-of-Scope Activities

When unplanned activity occurs, document in session-state.md:

```markdown
## [OUT-OF-SCOPE] Activity Name (Date)
- **Origin:** How it came up
- **Impact:** Did it affect schedule?
- **Resolution:** Completed? Postponed? Discarded?
```

---

## Test-Driven Development (REQUIRED)

### The Cycle

1. **RED:** Write failing test
2. **GREEN:** Minimal code to pass
3. **REFACTOR:** Improve quality
4. **COMMIT:** Atomic commit

### Critical Rule

**If code exists without tests: DELETE and start over!**

---

## Principles

- **YAGNI:** You Aren't Gonna Need It
- **DRY:** Don't Repeat Yourself
- **KISS:** Keep It Simple

---

## MEMORY RULE - TOKEN ECONOMY (HIGH PRIORITY)

### Memory System Hierarchy

1. **Permanent System** (project knowledge)
2. **Session System** (development flow)

### Prohibitions

- DO NOT read entire memories without filter
- DO NOT use session system for permanent knowledge
- DO NOT ignore tags in organization

---

## MEMORY WRITING RULE (HYBRID)

### Operation Mode
- Agent suggests → User confirms
- NEVER write automatically without confirmation

### Trigger Points

1. **Learning:** New problem solved, pattern discovered
2. **Conclusion:** End of significant task
3. **Correction:** Outdated memory detected

GLOBALEOF
    fi
}

create_rules() {
    print_step "Criando rules para stack: $STACK"

    # Global rules (sempre)
    local global_rules
    global_rules=$(create_global_rules "pt-BR")

    write_file "$INSTALL_PATH/.aidev/rules/global.md" "$global_rules"
    
    # Stack-specific rules
    if [ "$STACK" = "laravel" ] || [ "$STACK" = "filament" ] || [ "$STACK" = "livewire" ]; then
        local laravel_rules='# Laravel Rules

## Structure
- Follow Laravel conventions
- Controllers in `app/Http/Controllers`
- Models in `app/Models`
- Tests in `tests/Feature` and `tests/Unit`

## Eloquent Models
- Use proper relationships
- Mass assignment protection
- Mutators and Accessors for data transformation
- Scopes for reusable queries

## Testing
- Feature tests for HTTP requests
- Unit tests for business logic
- Database: use transactions or RefreshDatabase
- Factories for test data

## Best Practices
- Form Requests for validation
- Resources for API responses
- Jobs for async processing
- Events for decoupled logic
- Policies for authorization

## Performance
- Eager loading to avoid N+1
- Query optimization
- Cache frequently accessed data
- Queue long-running tasks
'
        write_file "$INSTALL_PATH/.aidev/rules/laravel.md" "$laravel_rules"
    fi
    
    if [ "$STACK" = "node" ] || [ "$STACK" = "react" ] || [ "$STACK" = "nextjs" ]; then
        local node_rules='# Node.js Rules

## Structure
- Modular architecture
- Separate concerns (routes, controllers, services)
- Config in environment variables

## Async/Await
- Prefer async/await over callbacks
- Always handle promise rejections
- Use try/catch blocks

## Testing
- Jest or Vitest for unit tests
- Supertest for API tests
- Testing Library for React components

## Best Practices
- Use ESLint and Prettier
- Type checking with TypeScript
- Proper error middleware
- Input validation (Joi, Zod)

## Performance
- Caching strategies
- Connection pooling
- Proper error handling
- Memory leak prevention
'
        write_file "$INSTALL_PATH/.aidev/rules/node.md" "$node_rules"
    fi
    
    print_success "Rules criadas"
}

# ============================================================================
# Criar README
# ============================================================================

create_readme() {
    print_step "Criando README"

    local readme="# AI Dev Superpowers

Sistema de governanca de IA para desenvolvimento com TDD rigoroso.

---

## Estrutura Criada

\`\`\`
.aidev/
├── core/               # Skills core engine
├── agents/             # Agentes especializados (8)
├── skills/             # Skills compostas (6)
│   ├── superpowers/    # brainstorming, writing-plans, tdd, debugging
│   └── orchestrator/   # code-analyzer, task-planner
├── rules/              # Regras por stack
│   ├── global.md       # Regras globais (idioma, commits, memoria)
│   └── [stack].md      # Regras especificas da stack
├── workflows/          # Fluxos de trabalho
│   ├── feature-development.md
│   ├── tdd-cycle.md
│   ├── bug-fix-workflow.md
│   └── refactor-workflow.md
├── state/              # Estado persistente
│   ├── session-state.md
│   └── lessons/
│       └── lessons-index.md
└── config/
    ├── platform-config.json
    └── startup-protocol.md
\`\`\`

---

## Configuracao

| Item | Valor |
|------|-------|
| **Modo** | $MODE |
| **Stack** | $STACK |
| **Plataforma** | $PLATFORM |
| **Idioma** | pt-BR |

---

## Ciclo de Vida de uma Sessao

\`\`\`
[ATIVACAO]
    │ Gatilhos: aidev, /aidev, ativar aidev, superpowers
    ▼
[PROTOCOLO DE INICIALIZACAO]
    │ ├── Verificar MCPs
    │ ├── Carregar Contexto (memoria)
    │ ├── Verificar Session State
    │ └── Carregar Regras
    ▼
[CLASSIFICAR TAREFA]
    │ Orchestrator agent classifica intent
    ▼
[SELECIONAR WORKFLOW]
    │ ├── feature-development
    │ ├── bug-fix-workflow
    │ ├── refactor-workflow
    │ └── tdd-cycle
    ▼
[EXECUTAR COM TDD]
    │ RED → GREEN → REFACTOR
    ▼
[PRE-COMMIT]
    │ ├── Atualizar session-state
    │ ├── Registrar licoes
    │ └── Sugerir memorias
    ▼
[COMMIT]
    │ <tipo>(<escopo>): <descricao>
    ▼
[DETECTAR GATILHO DE MEMORIA?]
    │ ├── Sim → Sugerir ao usuario
    │ └── Nao → Continuar
    ▼
[PROXIMA TAREFA OU FIM]
\`\`\`

---

## Ativacao do Orquestrador

Use um dos comandos:
- \`aidev\`
- \`/aidev\`
- \`ativar aidev\`
- \`modo agente\`
- \`superpowers\`

O sistema executara automaticamente o protocolo de inicializacao.

---

## Agentes Disponiveis (8)

| Agente | Responsabilidade |
|--------|------------------|
| **orchestrator** | Meta-agente, classifica intents, despacha subagentes |
| **architect** | Design, arquitetura, brainstorming |
| **backend** | Implementacao server-side com TDD |
| **frontend** | Implementacao UI com TDD |
| **qa** | Estrategia de testes, validacao |
| **devops** | CI/CD, deploy, infra |
| **legacy-analyzer** | Analise de codigo, divida tecnica |
| **security-guardian** | Validacao OWASP, vulnerabilidades |

---

## Skills Disponiveis (6)

### Superpowers
| Skill | Gatilhos |
|-------|----------|
| **brainstorming** | novo projeto, nova feature, design |
| **writing-plans** | criar plano, planejar implementacao |
| **test-driven-development** | implementar, codigo, desenvolver |
| **systematic-debugging** | bug, erro, debug, nao funciona |

### Orchestrator
| Skill | Gatilhos |
|-------|----------|
| **code-analyzer** | analisar codigo, revisar estrutura |
| **task-planner** | planejar, dividir tarefa |

---

## Regras Principais

### TDD (OBRIGATORIO)
1. **RED:** Escrever teste que falha
2. **GREEN:** Codigo minimo para passar
3. **REFACTOR:** Melhorar qualidade
4. **COMMIT:** Commit atomico

**Se codigo existe sem testes: DELETE!**

### Commits
- Formato: \`<tipo>(<escopo>): <descricao>\`
- Idioma: Portugues BR
- Sem emojis, sem co-autoria

### Memoria
- Basic Memory: conhecimento permanente (#projeto, #global)
- Serena: fluxo de sessao (session-state, lessons)
- Gravacao hibrida: agente sugere, usuario confirma

---

## Arquivos de Estado

### session-state.md
Mantido em \`.aidev/state/session-state.md\`
- Tarefa atual
- Workflow ativo
- Trabalho concluido
- Proximas acoes

### lessons-index.md
Mantido em \`.aidev/state/lessons/lessons-index.md\`
- Erros encontrados
- Solucoes aplicadas
- Prevencao futura

---

## Proximos Passos

1. Ative o orquestrador: \`aidev\`
2. Descreva o que quer fazer
3. Siga o workflow TDD
4. Faca commits atomicos

---

**Instalado em:** $(date)
**Versao:** 1.0.0
**Stack:** $STACK
**Plataforma:** $PLATFORM
"

    write_file "$INSTALL_PATH/.aidev/README.md" "$readme"
    print_success "README criado"
}

# ============================================================================
# Criar Config Files
# ============================================================================

create_config_files() {
    print_step "Criando arquivos de configuração"

    # Source templates
    source "$(dirname "$0")/aidev-templates.sh" 2>/dev/null || true

    # Obter nome do projeto do diretório
    local project_name
    project_name=$(basename "$INSTALL_PATH")

    # Startup Protocol
    if type "create_startup_protocol" &>/dev/null; then
        local startup_content
        startup_content=$(create_startup_protocol "pt-BR")
        write_file "$INSTALL_PATH/.aidev/config/startup-protocol.md" "$startup_content"
    fi

    # Platform Config JSON
    if type "create_platform_config" &>/dev/null; then
        local config_content
        config_content=$(create_platform_config "$project_name" "$STACK" "$STACK" "$MODE" "$PLATFORM" "pt-BR" "basic-memory")
        write_file "$INSTALL_PATH/.aidev/config/platform-config.json" "$config_content"
    fi

    print_success "Arquivos de configuração criados"
}

# ============================================================================
# Criar State Templates
# ============================================================================

create_state_templates() {
    print_step "Criando templates de estado"

    # Source templates
    source "$(dirname "$0")/aidev-templates.sh" 2>/dev/null || true

    # Obter nome do projeto do diretório
    local project_name
    project_name=$(basename "$INSTALL_PATH")

    # Session State Template
    if type "create_session_state_template" &>/dev/null; then
        local session_content
        session_content=$(create_session_state_template "$project_name" "$STACK")
        write_file "$INSTALL_PATH/.aidev/state/session-state.md" "$session_content"
    fi

    # Lessons Index Template
    if type "create_lessons_index_template" &>/dev/null; then
        local lessons_content
        lessons_content=$(create_lessons_index_template)
        write_file "$INSTALL_PATH/.aidev/state/lessons/lessons-index.md" "$lessons_content"
    fi

    print_success "Templates de estado criados"
}

# ============================================================================
# Criar Workflows
# ============================================================================

create_workflows() {
    print_step "Criando workflows"

    # Feature Development Workflow
    local feature_workflow='# Feature Development Workflow

## Ciclo Completo

```
[DISCOVERY]
    ↓ Brainstorming Skill
[DESIGN]
    ↓ Writing Plans Skill
[RED]
    ↓ TDD Skill - Escrever teste que falha
[GREEN]
    ↓ TDD Skill - Código mínimo para passar
[REFACTOR]
    ↓ Melhorar qualidade
[SECURITY]
    ↓ Security Guardian Agent
[DOCUMENTATION]
    ↓ Atualizar docs
[COMMIT]
```

## Fases

### 1. DISCOVERY
- Ativar skill `brainstorming`
- Fazer perguntas clarificadoras
- Explorar alternativas (2-3 abordagens)
- Documentar decisões

### 2. DESIGN
- Ativar skill `writing-plans`
- Quebrar em tarefas de 2-5 minutos
- Cada tarefa com teste primeiro
- Obter aprovação antes de implementar

### 3. RED (TDD)
- Escrever teste que falha
- Verificar que falha pelo motivo certo
- Commitar teste separadamente (opcional)

### 4. GREEN (TDD)
- Código MÍNIMO para passar
- Sem features extras
- Sem otimização prematura

### 5. REFACTOR
- Melhorar qualidade
- Remover duplicação
- Testes devem continuar passando

### 6. SECURITY
- Security Guardian valida mudanças
- OWASP checklist
- Nenhuma vulnerabilidade permitida

### 7. DOCUMENTATION
- Atualizar session-state.md
- Registrar lições aprendidas
- Sugerir gravação de memórias

### 8. COMMIT
- Commit atômico
- Mensagem em português
- Formato: `<tipo>(<escopo>): <descrição>`
'
    write_file "$INSTALL_PATH/.aidev/workflows/feature-development.md" "$feature_workflow"

    # TDD Cycle Workflow
    local tdd_workflow='# TDD Cycle Workflow

## O Ciclo

```
[RED]
  │
  ▼
Escrever teste que falha
  │
  ▼
Verificar que falha (motivo correto)
  │
  ▼
[GREEN]
  │
  ▼
Código mínimo para passar
  │
  ▼
Verificar que passa
  │
  ▼
[REFACTOR]
  │
  ▼
Melhorar qualidade
  │
  ▼
Verificar que ainda passa
  │
  ▼
[COMMIT]
```

## Regra de Ouro

**Código sem teste = DELETE e recomeçar!**

## Cada Fase = 1 Commit (opcional)

- `test: adicionar teste para X`
- `feat: implementar X`
- `refactor: melhorar estrutura de X`

## Coverage Mínimo

- Models: 100%
- Services: 100%
- Controllers: 80%
- Livewire: 80%
- Total: 85%
'
    write_file "$INSTALL_PATH/.aidev/workflows/tdd-cycle.md" "$tdd_workflow"

    # Bug Fix Workflow
    local bugfix_workflow='# Bug Fix Workflow

## Ciclo de Correção

```
[REPRODUCE]
    ↓ Reproduzir o bug
[ISOLATE]
    ↓ Isolar a causa
[ROOT CAUSE]
    ↓ Entender o porquê
[FIX]
    ↓ TDD - teste primeiro, depois correção
[VALIDATE]
    ↓ Verificar que não regrediu
[DOCUMENT]
    ↓ Registrar lição aprendida
[COMMIT]
```

## Fases

### 1. REPRODUCE
- Criar caso de teste mínimo
- Documentar passos exatos
- Capturar evidências (logs, screenshots)

### 2. ISOLATE
- Busca binária no código
- Adicionar logs estratégicos
- Verificar suposições

### 3. ROOT CAUSE
- Perguntar "Por quê?" 5 vezes
- Traçar fluxo de dados
- Documentar descobertas

### 4. FIX (TDD)
- Escrever teste que expõe o bug
- Implementar correção mínima
- Verificar que teste passa

### 5. VALIDATE
- Rodar suite completa de testes
- Verificar que nada regrediu
- Testar cenários relacionados

### 6. DOCUMENT
- Adicionar em lessons-index.md
- Formato: `[ERRO-XXX]`
- Incluir: sintoma, causa, solução, prevenção

### 7. COMMIT
- `fix(<escopo>): <descrição>`
- Referenciar issue se existir
'
    write_file "$INSTALL_PATH/.aidev/workflows/bug-fix-workflow.md" "$bugfix_workflow"

    # Refactor Workflow
    local refactor_workflow='# Refactor Workflow

## Ciclo de Refatoração

```
[ANALYZE]
    ↓ Analisar código existente
[TEST]
    ↓ Garantir cobertura de testes
[PLAN]
    ↓ Planejar mudanças
[EXECUTE]
    ↓ Pequenas mudanças incrementais
[VERIFY]
    ↓ Testes passando a cada passo
[COMMIT]
```

## Regras de Segurança

1. **NUNCA** refatorar sem testes
2. **SEMPRE** rodar testes após cada mudança
3. **PEQUENOS** passos incrementais
4. **COMMITS** frequentes e atômicos

## Fases

### 1. ANALYZE
- Identificar code smells
- Mapear dependências
- Avaliar impacto

### 2. TEST
- Verificar cobertura atual
- Adicionar testes faltantes
- Garantir comportamento documentado

### 3. PLAN
- Listar mudanças necessárias
- Ordenar por segurança
- Identificar pontos de rollback

### 4. EXECUTE
- Uma mudança por vez
- Manter testes passando
- Não mudar comportamento

### 5. VERIFY
- Rodar suite completa
- Verificar performance
- Code review

### 6. COMMIT
- `refactor(<escopo>): <descrição>`
- Commits pequenos e frequentes
'
    write_file "$INSTALL_PATH/.aidev/workflows/refactor-workflow.md" "$refactor_workflow"

    print_success "Workflows criados"
}

# ============================================================================
# Main
# ============================================================================

main() {
    print_header

    parse_args "$@"
    validate_args

    # Auto-detect stack se habilitado
    if [ "$AUTO_DETECT" = true ]; then
        print_step "Detectando stack"
        STACK=$(detect_stack "$INSTALL_PATH")
        print_info "Stack detectada: $STACK"
    fi

    # Auto-detect platform se auto
    if [ "$PLATFORM" = "auto" ]; then
        PLATFORM=$(detect_platform)
        print_info "Plataforma detectada: $PLATFORM"
    fi

    # Criar estrutura
    create_base_structure
    create_skills_core
    create_agents
    create_skills
    create_rules
    create_workflows
    create_config_files
    create_state_templates
    create_readme

    print_summary

    # Próximos passos
    echo -e "${YELLOW}Próximos Passos:${NC}"
    echo "1. cd $INSTALL_PATH"
    echo "2. Leia .aidev/README.md para guia completo"
    echo "3. Configure sua plataforma de IA"
    echo "4. Comece com TDD rigoroso!"
    echo ""
}

main "$@"
