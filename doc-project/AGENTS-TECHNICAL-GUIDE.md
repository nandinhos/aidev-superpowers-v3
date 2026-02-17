# AI Dev Superpowers V3 - Guia Técnico dos Agentes

## Sumário

1. [Visão Geral do Sistema](#visão-geral-do-sistema)
2. [Ciclo de Vida dos Agentes](#ciclo-de-vida-dos-agentes)
3. [Processo de Inicialização](#processo-de-inicialização)
4. [Comportamento por Tipo de Projeto](#comportamento-por-tipo-de-projeto)
   - [Greenfield (Projeto Novo)](#greenfield-projeto-novo)
   - [Brownfield (Projeto Existente)](#brownfield-projeto-existente)
   - [Refatoração de Legado](#refatoração-de-legado)
5. [Catálogo de Agentes](#catálogo-de-agentes)
6. [Sistema de Skills](#sistema-de-skills)
7. [Protocolo de Handoff](#protocolo-de-handoff)
8. [Sistema de Confiança](#sistema-de-confiança)
9. [Arquivos de Estado](#arquivos-de-estado)
10. [Referência Rápida](#referência-rápida)

---

## Visão Geral do Sistema

O AI Dev Superpowers V3 é um sistema de orquestração inteligente que coordena múltiplos agentes especializados para auxiliar no desenvolvimento de software. O sistema funciona como uma "equipe virtual" de desenvolvedores, cada um com responsabilidades específicas.

### Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              ORCHESTRATOR                                │
│                    (Cérebro do Sistema - Meta-Agente)                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  ARCHITECT  │  │   BACKEND   │  │  FRONTEND   │  │    DEVOPS   │     │
│  │  (Design)   │  │   (API)     │  │   (UI)      │  │  (Infra)    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │CODE-REVIEWER│  │  SECURITY   │  │      QA     │  │   LEGACY    │     │
│  │  (Review)   │  │  GUARDIAN   │  │  (Testes)   │  │  ANALYZER   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                              SKILLS ENGINE                               │
│   brainstorming | writing-plans | TDD | debugging | code-review | ...   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Componentes Principais

| Componente | Localização | Função |
|------------|-------------|--------|
| **Instalador** | `install.sh` | One-liner para instalação global |
| **CLI** | `bin/aidev` + `lib/cli.sh` | Interface de comandos |
| **Core** | `lib/core.sh` | Funções utilitárias base |
| **Detection** | `lib/detection.sh` | Detecção de stack, plataforma e maturidade |
| **Orchestration** | `lib/orchestration.sh` | Máquina de estados de skills e agentes |
| **Templates** | `lib/templates.sh` + `templates/` | Sistema de templates dos agentes |

---

## Ciclo de Vida dos Agentes

### Estados de um Agente

```
┌────────────┐     ┌────────────┐     ┌────────────┐     ┌────────────┐
│   IDLE     │ ──► │   ACTIVE   │ ──► │ EXECUTING  │ ──► │ COMPLETED  │
│ (Dormindo) │     │ (Ativado)  │     │ (Skills)   │     │  (Pronto)  │
└────────────┘     └────────────┘     └────────────┘     └────────────┘
                         │                                      │
                         │          ┌────────────┐              │
                         └─────────►│   FAILED   │◄─────────────┘
                                    │  (Erro)    │
                                    └────────────┘
```

### Fluxo de Ativação

1. **Usuário faz request** → CLI recebe comando
2. **Orchestrator classifica intent** → Determina tipo de tarefa
3. **Orchestrator seleciona agentes** → Define pipeline de agentes
4. **Agentes são ativados** → Em sequência conforme dependências
5. **Skills são executadas** → Cada agente usa skills apropriadas
6. **Handoffs ocorrem** → Passagem de contexto entre agentes
7. **Ciclo completa** → Deploy ou entrega final

---

## Processo de Inicialização

### Instalação Global (One-Time)

```bash
# Comando de instalação
curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash
```

**O que acontece:**

1. **Verificação de pré-requisitos**
   - Git instalado
   - Permissões adequadas

2. **Clonagem/Atualização**
   ```bash
   # Diretório de instalação
   $HOME/.aidev-core
   ```

3. **Configuração do PATH**
   - Adiciona `$HOME/.aidev-core/bin` ao `.bashrc`/`.zshrc`

4. **Pergunta interativa**
   - "Deseja inicializar no diretório atual?"

### Inicialização em um Projeto (`aidev init`)

```bash
cd /seu/projeto
aidev init
```

**O que acontece:**

1. **Detecção Automática**
   - Stack tecnológica (Laravel, React, Python, etc.)
   - Plataforma de IA (Antigravity, Claude Code, etc.)
   - Linguagem principal
   - Nome do projeto
   - **Maturidade** (Greenfield vs Brownfield)
   - Estilo de código (ESLint, Pint, Black, etc.)

2. **Criação da Estrutura `.aidev/`**
   ```
   .aidev/
   ├── agents/          # Agentes gerados para o projeto
   │   ├── orchestrator.md
   │   ├── architect.md
   │   ├── backend.md
   │   └── ...
   ├── skills/          # Skills disponíveis
   │   ├── brainstorming/
   │   ├── writing-plans/
   │   ├── test-driven-development/
   │   └── ...
   ├── rules/           # Regras específicas da stack
   │   └── [stack].md
   ├── state/           # Estado persistido
   │   ├── session.json
   │   ├── skills.json
   │   ├── agents.json
   │   └── unified.json
   └── memory/          # Base de conhecimento
       └── kb/
   ```

3. **Processamento de Templates**
   - Templates em `templates/agents/*.md.tmpl` são processados
   - Variáveis como `{{STACK}}`, `{{PROJECT_NAME}}` são substituídas
   - Arquivos finais são gerados em `.aidev/agents/`

4. **Configuração Específica da Plataforma**
   - Claude Code: `.claude/settings.json`
   - Antigravity: `.agent/workflows/`
   - etc.

---

## Comportamento por Tipo de Projeto

O sistema detecta automaticamente o tipo de projeto e ajusta seu comportamento:

### Detecção de Maturidade

```bash
# Função em lib/detection.sh
detect_maturity() {
    # Greenfield se:
    # - Diretório não existe
    # - Menos de 5 arquivos
    # - Menos de 10 commits no git
    
    # Brownfield:
    # - Mais de 10 commits
    # - Estrutura de projeto existente
}
```

---

## Greenfield (Projeto Novo)

### Características

- Menos de 10 commits ou projeto vazio
- Liberdade para definir arquitetura
- Foco em planejamento inicial

### Fluxo Típico

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        FLUXO GREENFIELD                                   │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  1. ORCHESTRATOR                                                          │
│     └── Classifica: feature_request                                       │
│     └── Verifica PRD existente                                           │
│         └── Se não existe → Solicita PRD ou inicia brainstorming         │
│                                                                           │
│  2. ARCHITECT (Skill: brainstorming)                                      │
│     └── Step 1: Entender problema (perguntas clarificadoras)             │
│     └── Step 2: Explorar alternativas (2-3 opções)                       │
│     └── Step 3: Apresentar design (chunks digeríveis)                    │
│     └── Step 4: Documentar → docs/plans/YYYY-MM-DD-design.md             │
│                                                                           │
│  3. ARCHITECT (Skill: writing-plans)                                      │
│     └── Quebrar em tarefas de 2-5 minutos                                │
│     └── Cada tarefa com teste primeiro                                   │
│     └── Documentar → docs/plans/YYYY-MM-DD-implementation.md             │
│                                                                           │
│  4. BACKEND/FRONTEND (Skill: test-driven-development)                     │
│     └── RED: Escrever teste que falha                                    │
│     └── GREEN: Código mínimo para passar                                 │
│     └── REFACTOR: Melhorar qualidade                                     │
│     └── Commit atômico                                                   │
│                                                                           │
│  5. CODE-REVIEWER (Skill: code-review)                                    │
│     └── Revisar qualidade e padrões                                      │
│     └── APPROVE / REQUEST_CHANGES                                        │
│                                                                           │
│  6. QA                                                                    │
│     └── Validar cobertura de testes                                      │
│     └── Verificar edge cases                                             │
│                                                                           │
│  7. SECURITY-GUARDIAN                                                     │
│     └── Análise OWASP                                                    │
│     └── ALLOW / BLOCK / ROLLBACK                                         │
│                                                                           │
│  8. DEVOPS                                                                │
│     └── Configurar pipeline CI/CD                                        │
│     └── Deploy                                                           │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### Skills Priorizadas

| Skill | Uso em Greenfield |
|-------|-------------------|
| `brainstorming` | **Alto** - Definir arquitetura do zero |
| `writing-plans` | **Alto** - Planejar implementação |
| `meta-planning` | **Médio** - Múltiplas features |
| `test-driven-development` | **Obrigatório** - Base sólida desde início |

### Agentes Mais Ativos

1. **Architect** - Protagonista inicial
2. **Backend/Frontend** - Implementação
3. **DevOps** - Configurar infraestrutura inicial

### Exemplo de Inicialização Greenfield

```bash
# Usuário cria novo projeto
mkdir meu-novo-projeto && cd meu-novo-projeto
aidev init

# Detecção: greenfield, stack não identificada
# Pergunta: "Qual stack você pretende usar?"
# Resposta: Laravel + Filament

# Gera estrutura com prompts específicos para novo projeto
# Orchestrator inclui seção sobre PRD
```

---

## Brownfield (Projeto Existente)

### Características

- Mais de 10 commits
- Código existente para respeitar
- Foco em extensão e manutenção

### Fluxo Típico

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        FLUXO BROWNFIELD                                   │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  1. ORCHESTRATOR                                                          │
│     └── Classifica intent (feature, bug, refactor)                       │
│     └── Executa health check do projeto                                  │
│     └── Identifica padrões existentes                                    │
│                                                                           │
│  2. PARA NOVAS FEATURES:                                                  │
│     └── ARCHITECT analisa código existente                               │
│     └── Design alinhado com arquitetura atual                            │
│     └── BACKEND/FRONTEND seguem padrões existentes                       │
│                                                                           │
│  3. PARA BUG FIXES:                                                       │
│     └── QA (Skill: systematic-debugging)                                 │
│         └── Phase 1: REPRODUCE (teste que falha)                         │
│         └── Phase 2: ISOLATE (binary search)                             │
│         └── Phase 3: ROOT CAUSE (5 whys)                                 │
│         └── Phase 4: FIX & PREVENT                                       │
│     └── BACKEND/FRONTEND implementam fix                                 │
│     └── Skill: learned-lesson → Documentar                               │
│                                                                           │
│  4. PARA CODE REVIEW (PR/MR):                                            │
│     └── CODE-REVIEWER (Skill: code-review)                               │
│     └── SECURITY-GUARDIAN                                                │
│     └── QA valida testes                                                 │
│                                                                           │
│  5. VALIDAÇÃO E DEPLOY                                                   │
│     └── Garantir não-regressão                                           │
│     └── Respeitar changelog existente                                    │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### Skills Priorizadas

| Skill | Uso em Brownfield |
|-------|-------------------|
| `systematic-debugging` | **Alto** - Correção de bugs |
| `code-review` | **Alto** - PRs frequentes |
| `test-driven-development` | **Obrigatório** - Manter cobertura |
| `learned-lesson` | **Médio** - Documentar descobertas |

### Agentes Mais Ativos

1. **Code-Reviewer** - Garantir qualidade
2. **QA** - Validar não-regressão
3. **Backend/Frontend** - Extensões incrementais

### Health Check Automático

Ao inicializar em brownfield, o sistema executa:

```bash
# Detecta dívida técnica
detect_technical_debt() {
    # Conta TODOs e FIXMEs
    # Verifica existência de testes
    # Analisa dependências desatualizadas
}

# Detecta estilo de código
detect_style() {
    # ESLint, Prettier, Biome (JS/TS)
    # Pint, PHP-CS-Fixer (PHP)
    # Black, Ruff (Python)
}
```

---

## Refatoração de Legado

### Características

- Código antigo sem testes
- Possível arquitetura obsoleta
- Alto risco de regressão
- Necessidade de análise antes de ação

### Fluxo Típico

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     FLUXO REFATORAÇÃO LEGADO                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  1. LEGACY-ANALYZER (Protagonista)                                        │
│     └── Fase DISCOVERY:                                                   │
│         └── Mapear estrutura de arquivos                                 │
│         └── Identificar pontos de entrada                                │
│         └── Encontrar dependências                                       │
│         └── Localizar testes existentes                                  │
│                                                                           │
│     └── Fase ASSESSMENT:                                                  │
│         └── Métricas de qualidade                                        │
│         └── Análise de complexidade ciclomática                          │
│         └── Identificar vulnerabilidades                                 │
│         └── Calcular dívida técnica                                      │
│                                                                           │
│     └── Fase PLANNING:                                                    │
│         └── Priorizar módulos a refatorar                                │
│         └── Definir estratégia (Strangler Pattern)                       │
│         └── TESTES PRIMEIRO para código legado                           │
│                                                                           │
│     Artefatos:                                                            │
│         .aidev/analysis/structure.md                                      │
│         .aidev/analysis/technical-debt.md                                 │
│         .aidev/analysis/refactoring-plan.md                               │
│         .aidev/analysis/risks.md                                          │
│                                                                           │
│  2. ARCHITECT                                                             │
│     └── Validar plano de refatoração                                     │
│     └── Definir nova arquitetura alvo                                    │
│     └── Aplicar Anti-Corruption Layer se necessário                      │
│                                                                           │
│  3. QA (Skill: systematic-debugging)                                      │
│     └── Criar testes de caracterização                                   │
│     └── Documentar comportamento atual                                   │
│                                                                           │
│  4. BACKEND/FRONTEND (Skill: TDD)                                         │
│     └── Aplicar Strangler Pattern:                                        │
│         ┌─────────────────────────────────────────────────────────────┐  │
│         │  [Cliente] ──► [Facade] ──► [Novo Código]                   │  │
│         │                       └──► [Código Legado] (gradual)        │  │
│         └─────────────────────────────────────────────────────────────┘  │
│     └── Substituir incrementalmente                                      │
│     └── Manter testes verdes                                             │
│                                                                           │
│  5. CODE-REVIEWER + SECURITY-GUARDIAN                                    │
│     └── Validar cada incremento                                          │
│     └── Garantir não-regressão                                           │
│                                                                           │
│  6. LEARNED-LESSON                                                        │
│     └── Documentar descobertas importantes                               │
│     └── Atualizar base de conhecimento                                   │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### Skills Priorizadas

| Skill | Uso em Refatoração |
|-------|-------------------|
| `systematic-debugging` | **Crítico** - Entender comportamento |
| `writing-plans` | **Alto** - Plano detalhado de migração |
| `test-driven-development` | **Crítico** - Testes de caracterização |
| `learned-lesson` | **Alto** - Documentar descobertas |

### Agentes Mais Ativos

1. **Legacy-Analyzer** - Protagonista inicial absoluto
2. **QA** - Testes de caracterização
3. **Architect** - Nova arquitetura

### Strangler Pattern (Padrão Recomendado)

```
Fase 1:        Fase 2:        Fase 3:        Fase 4:
┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐
│  Legacy   │  │  Legacy   │  │  Legacy   │  │    New    │
│  System   │  │  System   │  │  (small)  │  │  System   │
│           │  │  ▼ ▼ ▼   │  │     ▼     │  │           │
│           │  │ ┌─────┐  │  │  ┌─────┐  │  │           │
│           │  │ │ New │  │  │  │ New │  │  │           │
│           │  │ └─────┘  │  │  │(big)│  │  │           │
└───────────┘  └───────────┘  └───────────┘  └───────────┘
```

### Anti-Corruption Layer

```
┌─────────────────┐         ┌─────────────────┐         ┌───────────────┐
│                 │         │                 │         │               │
│   New System    │◄───────►│      ACL        │◄───────►│ Legacy System │
│   (Clean Model) │         │  (Translation)  │         │ (Old Model)   │
│                 │         │                 │         │               │
└─────────────────┘         └─────────────────┘         └───────────────┘
```

---

## Catálogo de Agentes

### 1. Orchestrator (Meta-Agente)

| Atributo | Valor |
|----------|-------|
| **ID** | `orchestrator` |
| **Papel** | Cérebro do sistema, coordena todos os agentes |
| **Recebe de** | Usuário, qualquer agente |
| **Entrega para** | Qualquer agente |
| **Skills** | Todas (coordenação) |

**Responsabilidades:**
- Gestão de estado e continuidade entre sessões
- Classificação de intent do usuário
- Seleção de agentes e skills apropriados
- Sistema de confiança para decisões
- Validação pré-ação
- Recovery e rollback

**Classificação de Intent:**

| Intent | Indicadores | Agentes | Skill |
|--------|-------------|---------|-------|
| `feature_request` | "criar", "adicionar", "novo" | Architect → Backend → QA | brainstorming |
| `bug_fix` | "bug", "erro", "fix" | QA → Backend | systematic-debugging |
| `refactor` | "refatorar", "melhorar" | Legacy-Analyzer → Architect | writing-plans |
| `testing` | "teste", "tdd" | QA → Backend | test-driven-development |
| `code_review` | "review", "PR" | Code-Reviewer → QA | code-review |
| `deployment` | "deploy", "release" | DevOps → Security | - |
| `security_review` | "segurança", "vulnerabilidade" | Security-Guardian → QA | - |

---

### 2. Architect

| Atributo | Valor |
|----------|-------|
| **ID** | `architect` |
| **Papel** | Design de sistema e decisões arquiteturais |
| **Recebe de** | Orchestrator, Legacy-Analyzer |
| **Entrega para** | Backend, Frontend, DevOps |
| **Skills** | brainstorming, writing-plans, meta-planning |

**Responsabilidades:**
- Analisar requisitos (PRD, user stories)
- Projetar arquitetura do sistema
- Escolher tecnologias e padrões
- Documentar ADRs (Architectural Decision Records)
- Avaliar trade-offs técnicos

**Artefatos Produzidos:**
- `docs/plans/YYYY-MM-DD-<topic>-design.md`
- `docs/plans/YYYY-MM-DD-<topic>-implementation.md`
- `docs/adr/NNNN-<decision>.md`

---

### 3. Backend Developer

| Atributo | Valor |
|----------|-------|
| **ID** | `backend` |
| **Papel** | Implementação server-side com TDD |
| **Recebe de** | Architect, Orchestrator |
| **Entrega para** | QA, Frontend, Security-Guardian |
| **Skills** | test-driven-development |

**Responsabilidades:**
- Implementar features com TDD obrigatório
- Design de banco de dados e migrations
- Desenvolvimento de APIs (REST, GraphQL)
- Lógica de negócio e validações
- Error handling e logging estruturado

**Ciclo TDD Obrigatório:**
```
RED ──► GREEN ──► REFACTOR ──► COMMIT
```

---

### 4. Frontend Developer

| Atributo | Valor |
|----------|-------|
| **ID** | `frontend` |
| **Papel** | Implementação client-side |
| **Recebe de** | Architect, Backend, Orchestrator |
| **Entrega para** | QA, Security-Guardian |
| **Skills** | test-driven-development |

**Responsabilidades:**
- Implementar componentes UI
- Gerenciamento de estado
- Design responsivo (mobile-first)
- Acessibilidade (WCAG 2.1)
- Performance optimization

---

### 5. DevOps

| Atributo | Valor |
|----------|-------|
| **ID** | `devops` |
| **Papel** | Infraestrutura e deploy |
| **Recebe de** | Architect, Backend, Security-Guardian |
| **Entrega para** | Orchestrator (deploy completo) |
| **Skills** | - |

**Responsabilidades:**
- Pipelines CI/CD
- Containerização (Docker, K8s)
- Automação de deploy
- Monitoramento e logging
- Disaster recovery

**Estratégias de Deploy:**
- Blue-Green Deployment
- Canary Deployment
- Rolling Update

---

### 6. Code Reviewer

| Atributo | Valor |
|----------|-------|
| **ID** | `code-reviewer` |
| **Papel** | Revisão de qualidade de código |
| **Recebe de** | Backend, Frontend, Architect |
| **Entrega para** | QA, Security-Guardian, Orchestrator |
| **Skills** | code-review |

**Responsabilidades:**
- Revisão de qualidade e estilo
- Verificação de padrões
- Detecção de code smells
- Sugestões de melhoria
- Review de PRs

**Ações Possíveis:**
- `APPROVE` - Código aprovado
- `REQUEST_CHANGES` - Precisa correções
- `COMMENT` - Apenas sugestões

---

### 7. Security Guardian

| Atributo | Valor |
|----------|-------|
| **ID** | `security-guardian` |
| **Papel** | Validação de segurança |
| **Recebe de** | Backend, Frontend, QA |
| **Entrega para** | DevOps, Orchestrator |
| **Skills** | learned-lesson |

**Responsabilidades:**
- Code review de segurança
- Checklist OWASP Top 10
- Detecção de vulnerabilidades
- Validação de compliance

**Ações Possíveis:**
- `ALLOW` - Seguro para deploy
- `BLOCK` - Vulnerabilidade encontrada
- `ROLLBACK` - Vulnerabilidade crítica

---

### 8. QA Specialist

| Atributo | Valor |
|----------|-------|
| **ID** | `qa` |
| **Papel** | Garantia de qualidade |
| **Recebe de** | Backend, Frontend, Legacy-Analyzer |
| **Entrega para** | Security-Guardian, DevOps, Orchestrator |
| **Skills** | test-driven-development, systematic-debugging |

**Responsabilidades:**
- Estratégias de teste
- Validar cobertura (>= 80%)
- Identificar edge cases
- Garantir conformidade TDD
- "Integrity Sentinel" - buscar gaps e furos

---

### 9. Legacy Analyzer

| Atributo | Valor |
|----------|-------|
| **ID** | `legacy-analyzer` |
| **Papel** | Análise e refatoração de código legado |
| **Recebe de** | Orchestrator |
| **Entrega para** | Architect, Backend, QA |
| **Skills** | systematic-debugging, learned-lesson |

**Responsabilidades:**
- Análise de estrutura de código
- Identificar dívida técnica
- Planejar estratégia de refatoração
- Avaliação de risco
- Roadmap de modernização

**Artefatos Produzidos:**
- `.aidev/analysis/structure.md`
- `.aidev/analysis/technical-debt.md`
- `.aidev/analysis/refactoring-plan.md`
- `.aidev/analysis/risks.md`

---

## Sistema de Skills

Skills são capacidades especializadas que os agentes podem executar. Cada skill possui estados rastreados:

```
idle ──► active ──► step_1 ──► step_2 ──► ... ──► completed/failed
```

### Skills Disponíveis

| Skill | Descrição | Agentes que Usam |
|-------|-----------|------------------|
| **brainstorming** | Exploração de ideias e alternativas | Architect |
| **writing-plans** | Criação de planos de implementação | Architect |
| **meta-planning** | Planejamento de múltiplas tarefas | Orchestrator, Architect |
| **test-driven-development** | Ciclo RED-GREEN-REFACTOR | Backend, Frontend |
| **systematic-debugging** | Debug estruturado (5 whys, binary search) | QA, Backend |
| **code-review** | Revisão estruturada de código | Code-Reviewer |
| **learned-lesson** | Documentar descobertas na KB | QA, qualquer agente |
| **release-management** | Gerenciamento de releases | DevOps |

### Funções de Orquestração de Skills

```bash
# Inicializar skill
skill_init "brainstorming"

# Definir total de steps
skill_set_steps "brainstorming" 4

# Avançar para próximo step
skill_advance "brainstorming" "Explorar alternativas"

# Validar checkpoint
skill_validate_checkpoint "brainstorming"

# Registrar artefato produzido
skill_add_artifact "brainstorming" "docs/design.md" "design"

# Completar skill
skill_complete "brainstorming"

# Falha na skill
skill_fail "brainstorming" "Motivo da falha"
```

---

## Protocolo de Handoff

Handoff é a transferência de trabalho de um agente para outro.

### Formato de Handoff

```json
{
  "from": "architect",
  "to": "backend",
  "task": "Implementar API conforme design",
  "artifact": "docs/plans/2024-01-15-login-design.md",
  "validation": {
    "design_approved": true,
    "tests_pass": true
  },
  "confidence": 0.85,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Fluxos de Handoff por Intent

#### Feature Request
```
Orchestrator ──► Architect ──► Backend/Frontend ──► Code-Reviewer ──► QA ──► Security ──► DevOps
```

#### Bug Fix
```
Orchestrator ──► QA ──► Backend ──► QA ──► Security
```

#### Code Review (PR)
```
Orchestrator ──► Code-Reviewer ──► QA ──► Security-Guardian
```

### Funções de Handoff

```bash
# Ativar agente
agent_activate "architect" "Projetar arquitetura do módulo X"

# Registrar output
agent_output "architect" "docs/design.md" "design_document"

# Transferir para próximo agente
agent_handoff "architect" "backend" "Implementar conforme design" "docs/design.md"

# Processar próximo handoff da fila
next_task=$(agent_process_handoff)
```

---

## Sistema de Confiança

O sistema de confiança determina o nível de autonomia para decisões.

### Níveis de Confiança

| Nível | Score | Ação | Exemplo |
|-------|-------|------|---------|
| **high** | 0.8-1.0 | Executa autonomamente | "Adicione um botão de logout" |
| **medium** | 0.5-0.79 | Executa com log detalhado | Refatoração com testes existentes |
| **low** | 0.3-0.49 | Pede confirmação | Mudança em código sem testes |
| **very_low** | 0-0.29 | Solicita mais contexto | Pedido ambíguo |

### Fatores de Confiança

| Fator | Peso |
|-------|------|
| Clareza do pedido | 0-0.3 |
| Existência de PRD/contexto | 0-0.2 |
| Histórico de ações similares | 0-0.2 |
| Riscos potenciais | 0-0.3 |

### Protocolo por Nível

```
HIGH (0.8+):
  ├── Executar skill/agente diretamente
  ├── Registrar em confidence.json
  └── Prosseguir para próximo step

MEDIUM (0.5-0.79):
  ├── Executar com logging verbose
  ├── Criar checkpoint antes
  └── Notificar usuário do progresso

LOW (0.3-0.49):
  ├── Apresentar plano ao usuário
  ├── Aguardar confirmação explícita
  └── Documentar riscos identificados

VERY_LOW (0-0.29):
  ├── Fazer perguntas clarificadoras
  ├── NÃO executar nenhuma ação
  └── Sugerir opções ao usuário
```

---

## Arquivos de Estado

### Estrutura de Estado

```
.aidev/state/
├── session.json      # Estado geral da sessão
├── skills.json       # Estado das skills ativas
├── agents.json       # Estado e handoffs de agentes
├── unified.json      # Estado unificado (v3.2+)
├── confidence.json   # Histórico de decisões
└── validations.json  # Log de validações pré-ação
```

### session.json

```json
{
  "current_fase": 1,
  "current_sprint": 0,
  "current_task": "Pendente",
  "initialized_at": "2024-01-15T10:00:00Z",
  "stack": "laravel",
  "platform": "antigravity",
  "maturity": "brownfield"
}
```

### skills.json

```json
{
  "active_skill": "brainstorming",
  "skill_states": {
    "brainstorming": {
      "status": "active",
      "current_step": 2,
      "total_steps": 4,
      "started_at": "2024-01-15T10:30:00Z",
      "checkpoints": [
        {"step": 1, "description": "Entender problema", "validated": true},
        {"step": 2, "description": "Explorar alternativas", "validated": false}
      ],
      "artifacts": []
    }
  }
}
```

### agents.json

```json
{
  "active_agent": "architect",
  "handoff_queue": [
    {
      "from": "orchestrator",
      "to": "architect",
      "task": "Projetar feature de login",
      "artifact": "",
      "timestamp": "2024-01-15T10:30:00Z",
      "processed": true
    }
  ],
  "agent_states": {
    "architect": {
      "status": "active",
      "task": "Projetar feature de login",
      "started_at": "2024-01-15T10:30:00Z",
      "outputs": []
    }
  }
}
```

---

## Referência Rápida

### Comandos CLI Principais

```bash
# Inicialização
aidev init                    # Inicializa no diretório atual
aidev init --stack laravel    # Força stack específica
aidev upgrade                 # Atualiza instalação do projeto
aidev self-upgrade            # Atualiza CLI global

# Status e Diagnóstico
aidev status                  # Mostra status da instalação
aidev doctor                  # Diagnóstico completo

# Fluxos de Trabalho
aidev new-feature "desc"      # brainstorming → writing-plans → TDD
aidev fix-bug "desc"          # systematic-debugging → learned-lesson
aidev refactor "desc"         # legacy-analyzer → architect → TDD
aidev suggest                 # Análise e sugestão contextual

# Memória e Conhecimento
aidev lessons                 # Gerencia base de conhecimento
aidev snapshot                # Gera Context Passport
aidev metrics                 # Visualiza telemetria
aidev cache                   # Gerencia cache de ativação

# Customização
aidev add-skill <nome>        # Adiciona skill customizada
aidev add-rule <nome>         # Adiciona regra customizada
aidev add-agent <nome>        # Adiciona agente customizado
```

### Checklist de Início de Sessão (Orchestrator)

```markdown
1. [ ] Ler `session.json` - recuperar contexto
2. [ ] Verificar `skills.json` - skill pendente?
3. [ ] Processar `agents.json` - handoff na fila?
4. [ ] Verificar `.env` - API Keys configuradas?
5. [ ] Verificar testes - baseline limpa?
6. [ ] Consultar `unified.json` - estado consolidado
7. [ ] Saudar usuário com contexto recuperado
```

### Princípios Inegociáveis (Superpowers)

| Princípio | Descrição |
|-----------|-----------|
| **TDD Obrigatório** | NUNCA escreva código de produção sem teste primeiro |
| **YAGNI** | Só implemente o que foi solicitado |
| **DRY** | Extraia duplicação quando >= 3 ocorrências |
| **Evidence Over Claims** | Prove que funciona, não apenas afirme |

---

## Comparativo por Dinâmica

| Aspecto | Greenfield | Brownfield | Refatoração Legado |
|---------|------------|------------|-------------------|
| **Foco Inicial** | Arquitetura | Extensão | Análise |
| **Agente Principal** | Architect | Code-Reviewer | Legacy-Analyzer |
| **Skill Primária** | brainstorming | code-review | systematic-debugging |
| **Risco** | Baixo | Médio | Alto |
| **TDD** | Desde o início | Manter cobertura | Testes de caracterização |
| **PRD** | Obrigatório | Desejável | N/A |
| **Documentação** | Criar do zero | Atualizar existente | Descobrir e documentar |

---

## Diagrama de Decisão do Orchestrator

```
                              ┌──────────────────────┐
                              │   Usuário Solicita   │
                              └──────────┬───────────┘
                                         │
                              ┌──────────▼───────────┐
                              │  Classificar Intent  │
                              └──────────┬───────────┘
                                         │
        ┌──────────────┬─────────────────┼─────────────────┬──────────────┐
        │              │                 │                 │              │
        ▼              ▼                 ▼                 ▼              ▼
   ┌─────────┐   ┌─────────┐       ┌─────────┐       ┌─────────┐   ┌─────────┐
   │ feature │   │ bug_fix │       │ refactor│       │  review │   │  deploy │
   └────┬────┘   └────┬────┘       └────┬────┘       └────┬────┘   └────┬────┘
        │              │                 │                 │              │
        ▼              ▼                 ▼                 ▼              ▼
   Architect      QA (debug)       Legacy-Analyzer   Code-Reviewer    DevOps
                                                                          
```

---

## Conclusão

O AI Dev Superpowers V3 oferece uma abordagem flexível e contextual para desenvolvimento assistido por IA. A detecção automática de maturidade do projeto garante que os agentes se comportem de forma apropriada para cada contexto:

- **Greenfield**: Foco em planejamento e arquitetura sólida desde o início
- **Brownfield**: Foco em qualidade e não-regressão
- **Refatoração**: Foco em análise, compreensão e migração segura

Os princípios de TDD, YAGNI e Evidence Over Claims garantem entregas de qualidade, enquanto o sistema de confiança e handoffs coordena a colaboração entre agentes de forma inteligente e rastreável.
