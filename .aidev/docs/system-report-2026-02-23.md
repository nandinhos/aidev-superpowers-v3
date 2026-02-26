# Relatório do Sistema — AI Dev Superpowers v4.7.0

**Data:** 2026-02-23
**Versão do sistema:** 4.7.0
**Status:** Para revisão e validação

---

## Sumário

1. [O que é o sistema](#1-o-que-é-o-sistema)
2. [Arquitetura geral](#2-arquitetura-geral)
3. [Os 12 Agentes](#3-os-12-agentes)
4. [As 8 Skills](#4-as-8-skills)
5. [Capacidades e limitações](#5-capacidades-e-limitações)
6. [O que é autônomo vs. dependente de interação](#6-o-que-é-autônomo-vs-dependente-de-interação)
7. [Fluxos de trabalho principais](#7-fluxos-de-trabalho-principais)
8. [Fluxo de desenvolvimento (lifecycle de feature)](#8-fluxo-de-desenvolvimento-lifecycle-de-feature)
9. [Exemplo completo — do zero à entrega](#9-exemplo-completo--do-zero-à-entrega)

---

## 1. O que é o sistema

O **AI Dev Superpowers** é um framework de governança de desenvolvimento assistido por IA. Ele não é um agente único — é um **meta-sistema** composto por:

- Um **Orquestrador** (o cérebro) que coordena tudo
- **12 agentes especializados** (cada um com um papel definido)
- **8 skills** (workflows estruturados com passos, checkpoints e artefatos)
- Um **CLI** (`aidev`) que automatiza operações de ciclo de vida
- Um **sistema de estado persistente** que garante continuidade entre sessões
- Um módulo **Workthrees** para orquestração de tarefas paralelas

O sistema foi projetado para funcionar com **qualquer LLM** (Claude, Gemini, GPT), com a premissa de que o estado do projeto deve estar documentado e versionado de forma que uma nova IA possa retomar sem perda de contexto.

### Filosofia central

| Princípio | Significado prático |
|-----------|-------------------|
| **TDD obrigatório** | Nunca escrever código sem um teste que falhe primeiro (RED → GREEN → REFACTOR) |
| **YAGNI** | Implementar apenas o que foi solicitado, sem melhorias não pedidas |
| **Evidence Over Claims** | Provar que funciona com testes, não apenas afirmar |
| **Debugging Lock** | Ao depurar, seguir rigorosamente as 4 fases — nunca chutar a causa |
| **Estado como verdade** | Se não está no estado persistente, não aconteceu |

---

## 2. Arquitetura geral

```
┌────────────────────────────────────────────────────────────────┐
│                    AI DEV SUPERPOWERS v4.7.0                   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ENTRADA DO USUÁRIO                                            │
│  (chat, comando CLI, ativação de skill)                        │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────────┐                                       │
│  │    ORQUESTRADOR     │  ← Lê estado (unified.json,          │
│  │  (Classificador de  │    checkpoint.md, snapshot.json)      │
│  │    intent + roteio) │                                       │
│  └─────────────────────┘                                       │
│           │                                                    │
│     ┌─────┴──────────────┐                                     │
│     │ Sistema de         │                                     │
│     │ Confiança (0-1.0)  │  → Define se executa ou pergunta    │
│     └─────┬──────────────┘                                     │
│           │                                                    │
│    ┌──────▼──────────────────────────────────────┐            │
│    │              SKILL ATIVADA                  │            │
│    │  brainstorming → writing-plans → TDD        │            │
│    │  systematic-debugging → learned-lesson      │            │
│    │  code-review → release-management           │            │
│    └──────┬──────────────────────────────────────┘            │
│           │                                                    │
│    ┌──────▼────────────────────────────┐                      │
│    │     CADEIA DE AGENTES             │                      │
│    │  Architect → Backend/Frontend     │                      │
│    │  → Code-Reviewer → QA             │                      │
│    │  → Security-Guardian → DevOps     │                      │
│    └──────┬────────────────────────────┘                      │
│           │                                                    │
│    ┌──────▼────────────────────────────┐                      │
│    │     ESTADO PERSISTENTE            │                      │
│    │  unified.json, checkpoint.md      │                      │
│    │  activation_snapshot.json         │                      │
│    │  audit.log, context-log.json      │                      │
│    └───────────────────────────────────┘                      │
│                                                                │
│    ┌──────────────────────────────────────────────────┐       │
│    │            CLI: aidev                            │       │
│    │  plan / start / done / complete / commit / sync  │       │
│    └──────────────────────────────────────────────────┘       │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Estrutura de arquivos no disco

```
.aidev/
├── agents/          # Definições dos 12 agentes (prompts + protocolos)
├── skills/          # 8 workflows com SKILL.md, steps e checkpoints
├── lib/             # Scripts shell de automação
│   ├── workthrees/  # Módulo de orquestração de fila e locks
│   ├── workflow-commit.sh
│   ├── workflow-release.sh
│   ├── workflow-sync.sh
│   ├── activation-snapshot.sh
│   ├── validation-engine.sh
│   └── ...
├── config/          # Regras de complexidade, estratégias de LLM
├── docs/            # Documentação técnica e relatórios
├── plans/
│   ├── ROADMAP.md   # Roadmap mestre (atualizado automaticamente)
│   ├── backlog/     # Ideias e features não iniciadas
│   ├── current/     # Feature ativa (em execução)
│   ├── features/    # Features planejadas aguardando início
│   └── history/     # Features concluídas, organizadas por YYYY-MM/
├── rules/           # Convenções por stack (generic.md, etc.)
└── state/
    ├── activation_snapshot.json  # Cache de ativação (< 1h válido)
    ├── unified.json              # Estado unificado completo
    ├── checkpoint.md             # Checkpoint de retomada
    ├── session.json              # Contexto da sessão atual
    ├── audit.log                 # Log de auditoria
    ├── context-log.json          # Log de transições
    ├── workthrees/               # Estado de fila e locks
    │   ├── queue.json
    │   └── locks.json
    └── sprints/                  # Estado por sprint
```

---

## 3. Os 12 Agentes

Cada agente é um papel especializado, definido por um arquivo `.md` que descreve: role, responsabilidades, protocolo de handoff (o que recebe, o que entrega) e quais skills pode executar.

| # | Agente | Papel | Recebe de | Entrega para | Skills |
|---|--------|-------|-----------|--------------|--------|
| 1 | **Orchestrator** | Cérebro / coordenador geral | Usuário | Todos | meta-planning |
| 2 | **Architect** | Design de sistema e arquitetura | Orchestrator, Legacy-Analyzer | Backend, Frontend, DevOps | brainstorming, writing-plans, meta-planning |
| 3 | **Backend** | Implementação server-side com TDD | Architect, Orchestrator | QA, Frontend, Security | test-driven-development |
| 4 | **Frontend** | Implementação client-side | Architect, Backend, Orchestrator | QA, Security | test-driven-development |
| 5 | **QA Specialist** | Qualidade e validação por testes | Backend, Frontend | Security, DevOps, Orchestrator | test-driven-development, systematic-debugging |
| 6 | **Code Reviewer** | Review de código e PR | Backend, Frontend, Architect | QA, Security, Orchestrator | code-review |
| 7 | **Security Guardian** | Auditoria de segurança (OWASP) | Backend, Frontend, QA | DevOps, Orchestrator | — |
| 8 | **DevOps** | CI/CD, deploy, infraestrutura | Architect, Backend, Security | Orchestrator | — |
| 9 | **Release Manager** | Versionamento semântico e changelog | Orchestrator | Orchestrator | release-management |
| 10 | **Legacy Analyzer** | Análise de código legado e débito técnico | Orchestrator | Architect, Backend, QA | systematic-debugging, learned-lesson |
| 11 | **State Manager** | Integridade e sincronia do estado | Qualquer agente | — | — |
| 12 | **Knowledge Manager** | Base de conhecimento (lições aprendidas) | Orchestrator, QA, Skills | Orchestrator, Architect, Backend, Frontend | learned-lesson, systematic-debugging |

### Como os agentes se comunicam

Os agentes não são processos separados — são **papéis assumidos pela IA** em sequência. A comunicação se dá por **handoffs documentados** em JSON:

```json
{
  "from": "architect",
  "to": "backend",
  "task": "Implementar endpoint POST /auth/login",
  "artifact": "docs/plans/2026-02-23-login-design.md",
  "validation": {
    "design_approved": true,
    "tests_exist": false
  },
  "confidence": 0.85,
  "timestamp": "2026-02-23T10:00:00Z"
}
```

---

## 4. As 8 Skills

Skills são **workflows estruturados** com número fixo de passos, checkpoints rastreados e um artefato de saída definido. Cada skill tem um estado (`idle → active → step_N → completed/failed`) registrado no estado persistente.

### Mapa de skills e conexões

```
brainstorming ──────────────▶ writing-plans ──────────────▶ test-driven-development
     │                              │                               │
     │                              │                               ▼
     │                              │                         code-review
     │                              │                               │
     ▼                              ▼                               ▼
meta-planning               (artefato: plan.md)             learned-lesson
                                                                    │
systematic-debugging ─────────────────────────────────────▶ learned-lesson

release-management (skill independente, pós-feature)
```

### Detalhamento de cada skill

#### 4.1 brainstorming
- **Quando usar:** Antes de qualquer nova feature ou projeto
- **Passos (4):** Entender problema → Explorar alternativas → Apresentar design → Documentar
- **Artefato:** `docs/plans/YYYY-MM-DD-<topico>-design.md`
- **Próxima skill:** writing-plans

#### 4.2 writing-plans
- **Quando usar:** Após design aprovado
- **Passos (4):** Verificar pré-requisitos → Definir tarefas → Documentar plano → Aprovar plano
- **Artefato:** `docs/plans/YYYY-MM-DD-<topico>-implementation.md`
- **Próxima skill:** test-driven-development

#### 4.3 test-driven-development
- **Quando usar:** Para toda implementação de código
- **Passos (3):** RED (escrever teste que falha) → GREEN (código mínimo) → REFACTOR
- **Ciclo:** Repetido para cada unidade de funcionalidade
- **Próxima skill:** code-review

#### 4.4 systematic-debugging
- **Quando usar:** Para qualquer bug reportado
- **Passos (4):** REPRODUCE → ISOLATE → ROOT CAUSE → FIX & PREVENT
- **Artefato:** `.aidev/memory/kb/YYYY-MM-DD-<bug>-lesson.md`
- **Próxima skill:** learned-lesson
- **Regra rígida:** Nunca chuta a causa. Se o mesmo fix falhar 2x, para e muda abordagem

#### 4.5 code-review
- **Quando usar:** Após implementação completa com testes passando
- **Passos (4):** Contextualização → Análise de código → Documentar findings → Decisão (APPROVE/REQUEST_CHANGES)
- **Artefato:** `.aidev/reviews/YYYY-MM-DD-<topico>-review.md`

#### 4.6 learned-lesson
- **Quando usar:** Após bug fix, decisão arquitetural ou padrão de sucesso
- **Passos (4):** Capturar contexto → Identificar causa raiz → Documentar solução → Armazenar na KB
- **Artefato:** `.aidev/memory/kb/YYYY-MM-DD-<topico>.md`

#### 4.7 meta-planning
- **Quando usar:** Para decompor tarefas complexas em sprints e roadmaps
- **Passos:** Análise → Decomposição em sprints → Gestão de ROADMAP.md → Ativação de features

#### 4.8 release-management
- **Quando usar:** Para criar uma nova versão do sistema
- **Passos (4):** Pre-release check → Version analysis → Content updates → Finalization (tag git)

---

## 5. Capacidades e limitações

### O que o sistema consegue fazer

| Capacidade | Como funciona |
|-----------|--------------|
| Classificar automaticamente a intenção do usuário | O Orquestrador analisa o texto e mapeia para 10 tipos de intent |
| Selecionar agentes e skills adequados | Matriz de roteamento agente-skill no orchestrator |
| Rastrear estado entre sessões e diferentes LLMs | Arquivos JSON persistentes + checkpoint.md |
| Garantir continuidade ao trocar de IA | State Manager gera snapshot estruturado para retomada |
| Automatizar lifecycle de features | CLI `aidev plan/start/done/complete` com atualização automática de README e ROADMAP |
| Controle de confiança para ações autônomas | Sistema de score 0-1.0; abaixo de 0.5 pede confirmação |
| Detectar e prevenir conflitos em tarefas paralelas | Workthrees: file-lock.sh + queue.json |
| Selecionar LLM por complexidade de tarefa | Workthrees: classify-complexity.sh + select-llm.sh |
| Catalogar lições aprendidas automaticamente | Knowledge Manager + learned-lesson skill |
| Validar conformidade de commits | Padrão Conventional Commits em português, sem emojis |
| Proteger branches críticas | Sprint Guard verifica alinhamento com a task ativa no Roadmap |

### Limitações conhecidas

| Limitação | Descrição |
|-----------|-----------|
| **Não executa código automaticamente** | A IA sugere, o usuário confirma antes de commits/deploys |
| **Sem paralelismo real de agentes** | Os agentes são papéis da mesma IA, não processos paralelos independentes |
| **Estado pode desincronizar** | Se comandos manuais (`cp`, `mv`) forem usados, o estado fica inconsistente |
| **Workthrees é uma camada de recomendação** | A seleção de LLM é sugerida, não executada automaticamente |
| **TDD depende de stack** | O sistema orienta TDD mas não sabe automaticamente quais frameworks de teste usar |

---

## 6. O que é autônomo vs. dependente de interação

### Totalmente autônomo (sem precisar perguntar ao usuário)

| Ação | Quando ocorre |
|------|--------------|
| Ler e recuperar contexto ao iniciar sessão | Sempre ao ativar modo agente |
| Atualizar `activation_snapshot.json` | Após cada tarefa concluída |
| Atualizar READMEs de backlog/current/history | Ao executar `aidev start`, `aidev done`, `aidev complete` |
| Executar `workflow-sync.sh sync` | Ao final de cada task |
| Gerar checkpoint de estado | Antes de operações de risco |
| Registrar handoffs entre agentes | Durante a execução de skills |
| Validar conformidade (snapshot, git, branch) | Na ativação do modo agente |
| Catalogar lições aprendidas após bug fix | Automaticamente após `systematic-debugging` completa |

### Autônomo com confidence alto (>= 0.8) — executa sem confirmar

| Ação | Exemplo |
|------|---------|
| Refatorar código simples com testes existentes | Renomear variável com testes cobrindo |
| Adicionar teste unitário isolado | Teste para função pura sem efeitos |
| Criar arquivo de configuração menor | `.eslintrc`, `jest.config.js` |

### Requer confirmação do usuário (confidence médio 0.5-0.79)

| Ação | Exemplo |
|------|---------|
| Modificar código crítico com testes existentes | Alterar lógica de autenticação |
| Instalar dependências | `npm install nova-lib` |
| Criar novo módulo ou serviço | Criar `src/services/payments.ts` |

### Sempre requer interação do usuário

| Ação | Por que é bloqueado |
|------|-------------------|
| `git push` | Ação que afeta repositório remoto compartilhado |
| `git commit` (final) | Usuário aprova o diff antes do commit |
| Mover feature entre estados no lifecycle | CLI `aidev start/complete` precisa de intenção explícita |
| Aprovar design no brainstorming | O design é apresentado e o usuário valida |
| Aprovar plano de implementação | O plano é apresentado antes da implementação |
| Deploy em produção | Sempre confirmar com usuário |
| Alterar CI/CD pipelines | Alta criticidade = confirmação obrigatória |

### Sistema de confiança resumido

```
Score 0.8-1.0  → Executa autonomamente + registra no log
Score 0.5-0.79 → Executa com logging verbose + notifica usuário
Score 0.3-0.49 → Apresenta plano ao usuário + aguarda confirmação
Score 0.0-0.29 → Faz perguntas clarificadoras + NÃO executa nada
```

---

## 7. Fluxos de trabalho principais

### 7.1 Feature Request (nova funcionalidade)

```
Usuário diz "criar X"
        │
        ▼
Orchestrator classifica: intent = feature_request
        │
        ▼
Avalia confiança (PRD existe? Requisitos claros?)
        │
   ┌────┴────┐
score >= 0.5  score < 0.5
   │              │
   ▼              ▼
Executa    Faz perguntas
   │
   ▼
Skill: brainstorming (Architect)
  → Step 1: Entende o problema
  → Step 2: Explora alternativas
  → Step 3: Apresenta design para o usuário
  → Step 4: [USUÁRIO APROVA] → Documenta em design.md
        │
        ▼
Skill: writing-plans (Architect)
  → Quebra em tarefas de 2-5 minutos
  → Apresenta plano para o usuário
  → [USUÁRIO APROVA] → Documenta em implementation.md
        │
        ▼
Skill: test-driven-development (Backend/Frontend)
  Repete para cada tarefa:
  → RED: Escreve teste que falha
  → GREEN: Implementa código mínimo que passa
  → REFACTOR: Limpa sem quebrar testes
        │
        ▼
Skill: code-review (Code Reviewer)
  → Analisa código implementado
  → Documenta findings
  → APPROVE / REQUEST_CHANGES
        │
        ▼
QA → Security Guardian → DevOps → Deploy
```

### 7.2 Bug Fix

```
Usuário reporta bug
        │
        ▼
Orchestrator: intent = bug_fix
Debugging Lock ativado (bloqueia tudo que não são as 4 fases)
        │
        ▼
Skill: systematic-debugging (QA)
  → REPRODUCE: Cria teste que reproduz o bug
  → ISOLATE: Binary search para isolar o componente
  → ROOT CAUSE: 5 whys até a causa raiz
  → FIX & PREVENT: Corrige + adiciona proteção
        │
        ▼
Skill: learned-lesson (Knowledge Manager)
  → Documenta a lição em .aidev/memory/kb/
        │
        ▼
Knowledge Manager atualiza base de conhecimento
```

### 7.3 Code Review (PR)

```
Usuário pede review do código
        │
        ▼
Orchestrator: intent = code_review
Verifica: implementação completa + testes passando
        │
        ▼
Skill: code-review (Code Reviewer)
  → Step 1: Contextualização (entende as mudanças)
  → Step 2: Análise de código (checklist completo)
  → Step 3: Documenta findings
  → Step 4: Decisão
        │
   ┌────┴────┐
APPROVE   REQUEST_CHANGES
   │              │
   ▼              ▼
QA → Security   Retorna ao
Guardian         desenvolvedor
```

### 7.4 Release

```
Usuário pede "release minor/patch/major"
        │
        ▼
Release Manager
        │
        ▼
Skill: release-management
  → Phase 1: Git clean check + testes passando
  → Phase 2: Identificar versão atual, analisar commits
  → Phase 3: Atualizar arquivos de versão + CHANGELOG.md
  → Phase 4: Commit de release + tag git
        │
        ▼
[USUÁRIO CONFIRMA] → push da tag
```

---

## 8. Fluxo de desenvolvimento (lifecycle de feature)

O lifecycle de uma feature é **totalmente controlado pelo CLI** e não pode ser executado manualmente (cp, mv são proibidos).

```
ESTADOS POSSÍVEIS:
  backlog/ → features/ → current/ → history/YYYY-MM/
  (ideia)    (planejada)  (em exec)   (concluída)
```

### Comandos e o que fazem automaticamente

```bash
aidev plan "Título da Feature"
```
- Cria arquivo `.aidev/plans/backlog/<slug>.md` com template
- Atualiza `backlog/README.md`
- NÃO move para features ainda (só é uma ideia)

```bash
aidev start <feature-id>
```
- Move o arquivo de `backlog/` ou `features/` → `current/`
- Atualiza `current/README.md`
- Cria checkpoint de estado
- Faz `git add` dos arquivos afetados
- Exibe diff para revisão antes do commit

```bash
aidev done <sprint-id> "Descrição do que foi feito"
```
- Marca sprint como concluída dentro do arquivo em `current/`
- Atualiza `current/README.md`
- Cria checkpoint de progresso
- Faz `git add` automático

```bash
aidev complete <feature-id>
```
- Move de `current/` → `history/YYYY-MM/` com data no nome
- Adiciona seção de conclusão com checklist
- Atualiza `ROADMAP.md`
- Registra em `context-log.json`
- Faz `git add` dos arquivos afetados

### Estrutura de um arquivo de feature

```markdown
# Nome da Feature

**ID:** nome-da-feature
**Status:** Em Progresso
**Prioridade:** Alta
**Sprint estimado:** 2-3

## Objetivo
...

## Critérios de Aceitação
- [ ] Critério 1
- [ ] Critério 2

## Plano de Sprints
### Sprint 1: ...
- [ ] Tarefa 1 (2-5 min)
- [ ] Tarefa 2 (2-5 min)

---
## ✅ Conclusão         ← adicionada automaticamente pelo aidev complete
**Status:** Concluído
**Data:** 2026-02-23
**Checklist:**
- [x] Implementação completa
- [x] Testes passando
- [x] Documentação atualizada
```

---

## 9. Exemplo completo — do zero à entrega

**Cenário:** O usuário quer adicionar autenticação JWT ao sistema.

---

### Passo 0 — Entrada do usuário

```
Usuário: "quero adicionar autenticação JWT"
```

**O que acontece internamente:**

O Orquestrador lê `activation_snapshot.json` e `unified.json` para recuperar contexto. Classifica o intent como `feature_request`. Avalia confiança:
- Pedido claro? Parcialmente (+0.1)
- PRD existe? Não (0)
- Projeto tem testes? Desconhecido (+0.1)

Score resultante: ~0.2 → Muito baixo → **faz perguntas clarificadoras**.

---

### Passo 1 — Clarificação (interação com usuário)

**Sistema pergunta:**
- "Qual stack? (Node.js, Python, Go...)"
- "Onde ficam os usuários? (banco local, OAuth externo, LDAP...)"
- "Quais rotas precisam de proteção?"
- "Tempo de expiração do token?"

**Usuário responde:** Node.js, banco local PostgreSQL, todas as rotas `/api/*`, 24h.

Score agora: ~0.75 → **Executa com logging verbose.**

---

### Passo 2 — Criação da feature no lifecycle

**Sistema sugere:**
```bash
aidev plan "autenticacao-jwt"
```

**O que é criado automaticamente:**

Arquivo `.aidev/plans/backlog/autenticacao-jwt.md`:
```markdown
# Autenticação JWT

**ID:** autenticacao-jwt
**Status:** Backlog
**Criado em:** 2026-02-23

## Objetivo
Proteger rotas /api/* com tokens JWT, usuários em PostgreSQL, expiração 24h.
```

`backlog/README.md` é atualizado com o novo item.

---

### Passo 3 — Início da execução

**Sistema executa:**
```bash
aidev start autenticacao-jwt
```

**O que acontece automaticamente:**
- Arquivo movido de `backlog/` → `current/autenticacao-jwt.md`
- Status atualizado para "Em Progresso"
- `current/README.md` atualizado
- Checkpoint criado em `checkpoint.md`
- `git add` nos arquivos afetados
- Diff exibido para revisão

---

### Passo 4 — Skill: brainstorming (Architect)

**Step 1 — Entender o problema:**
O Architect faz perguntas técnicas adicionais sobre o design:
- Refresh tokens necessários?
- Blacklist de tokens (logout)?
- Rate limiting por IP?

**Interação com usuário.** Usuário decide: sim refresh tokens, não blacklist, não rate limit agora.

**Step 2 — Explorar alternativas:**
O Architect apresenta 3 abordagens:
1. JWT stateless puro (mais simples)
2. JWT + refresh token em banco (escolhida)
3. OAuth2 completo (exagero para agora)

**Interação:** Usuário aprova opção 2.

**Step 3 — Apresentar design:**
O Architect apresenta o design técnico:
```
POST /auth/login         → retorna accessToken (1h) + refreshToken (7d)
POST /auth/refresh       → renova accessToken
POST /auth/logout        → invalida refreshToken no banco
Middleware: validateJWT  → aplicado em /api/*
Tabelas: users, refresh_tokens
```

**Interação:** Usuário aprova o design.

**Step 4 — Documentar:**
Criado automaticamente: `docs/plans/2026-02-23-autenticacao-jwt-design.md`

---

### Passo 5 — Skill: writing-plans (Architect)

O Architect quebra o design em tarefas de 2-5 minutos cada:

**Sprint 1 — Infraestrutura**
1. Criar migration: tabela `refresh_tokens`
2. Criar `src/services/jwt.service.ts` (sign, verify)
3. Criar `src/middleware/auth.middleware.ts`

**Sprint 2 — Endpoints**
4. Implementar `POST /auth/login`
5. Implementar `POST /auth/refresh`
6. Implementar `POST /auth/logout`

**Sprint 3 — Integração e proteção**
7. Aplicar middleware em `/api/*`
8. Testes de integração end-to-end

**Interação:** Usuário aprova o plano.

Criado automaticamente: `docs/plans/2026-02-23-autenticacao-jwt-implementation.md`

---

### Passo 6 — Skill: test-driven-development (Backend)

O Backend executa o ciclo TDD para cada tarefa. Exemplo com a tarefa 2 (jwt.service.ts):

**RED — Escreve teste que falha:**
```typescript
// src/services/jwt.service.test.ts
describe('JwtService', () => {
  it('deve gerar token com userId e role', () => {
    const token = JwtService.sign({ userId: 1, role: 'user' });
    expect(token).toBeDefined();
    expect(token.split('.')).toHaveLength(3); // formato JWT
  });

  it('deve verificar token válido', () => {
    const token = JwtService.sign({ userId: 1, role: 'user' });
    const payload = JwtService.verify(token);
    expect(payload.userId).toBe(1);
  });
});
```

Sistema confirma: teste falha (`Cannot find module './jwt.service'`). ✅ RED confirmado.

**GREEN — Código mínimo:**
```typescript
// src/services/jwt.service.ts
import jwt from 'jsonwebtoken';

export const JwtService = {
  sign: (payload: object) =>
    jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: '1h' }),

  verify: (token: string) =>
    jwt.verify(token, process.env.JWT_SECRET!) as any,
};
```

Sistema confirma: testes passam. ✅ GREEN confirmado.

**REFACTOR — Melhoria sem quebrar testes:**
- Adiciona tipagem forte
- Extrai `JWT_SECRET` para constante validada
- Testes continuam passando. ✅ REFACTOR confirmado.

Este ciclo se repete para cada uma das 8 tarefas.

---

### Passo 7 — Skill: code-review (Code Reviewer)

Após todas as tarefas implementadas com testes passando:

**Step 1 — Contextualização:**
Code Reviewer lê todos os arquivos criados/modificados.

**Step 2 — Análise:**
Verifica:
- Padrões do projeto seguidos?
- Sem code smells?
- Testes cobrem edge cases?
- Sem segredos hardcoded?
- Acessibilidade de erros (mensagens úteis)?

**Step 3 — Findings:**
Exemplo de finding encontrado:
> "O endpoint `/auth/login` retorna a mesma mensagem para 'usuário não existe' e 'senha incorreta', o que é correto para não vazar informação (security by design)."

Criado automaticamente: `.aidev/reviews/2026-02-23-autenticacao-jwt-review.md`

**Step 4 — Decisão:** APPROVE

---

### Passo 8 — Security Guardian

Verifica OWASP Top 10 aplicado:
- ✅ Sem SQL injection (ORM parameterizado)
- ✅ Tokens com expiração adequada
- ✅ Sem log de senha em claro
- ✅ Refresh tokens com rotação

Resultado: aprovado com nota de monitoramento de rate limiting para o backlog.

---

### Passo 9 — Commit

**Sistema sugere:**
```bash
aidev commit "feat(auth): adiciona autenticacao JWT com refresh tokens"
```

O `workflow-commit.sh` executa automaticamente:
1. `git status` para ver arquivos modificados
2. Valida formato da mensagem (Conventional Commits + português)
3. Exibe diff completo para o usuário revisar
4. **Aguarda aprovação do usuário**
5. Após aprovação: `git add` + `git commit`

**Interação:** Usuário confirma o commit.

O `workflow-sync.sh sync` é executado automaticamente após o commit, atualizando o `activation_snapshot.json`.

---

### Passo 10 — Conclusão da feature

```bash
aidev done "sprint-1" "Infraestrutura JWT implementada com TDD"
aidev done "sprint-2" "Endpoints de auth implementados"
aidev done "sprint-3" "Middleware e testes e2e concluídos"
aidev complete autenticacao-jwt
```

**O que acontece automaticamente no `aidev complete`:**
- Feature movida: `current/autenticacao-jwt.md` → `history/2026-02/autenticacao-jwt-23.md`
- Seção de conclusão adicionada com checklist
- `ROADMAP.md` atualizado marcando a feature como concluída
- Entrada registrada em `context-log.json`
- `git add` dos arquivos de estado
- `activation_snapshot.json` regenerado

---

### Passo 11 — Lição aprendida (Knowledge Manager)

Automaticamente após o complete, o Knowledge Manager verifica se há lição a registrar. Neste caso, o padrão de refresh token rotacional é um padrão de sucesso:

Criado em: `.aidev/memory/kb/2026-02-23-jwt-refresh-rotation-lesson.md`

Na próxima vez que alguém pedir "autenticação", o Knowledge Manager consulta a KB e apresenta a solução anterior como base, economizando o ciclo de brainstorming.

---

### Resumo do exemplo — O que foi criado e onde

| Artefato | Localização | Criado por | Quando |
|---------|-------------|-----------|--------|
| Feature backlog | `.aidev/plans/backlog/autenticacao-jwt.md` | `aidev plan` | Passo 2 |
| Feature current | `.aidev/plans/current/autenticacao-jwt.md` | `aidev start` | Passo 3 |
| Design doc | `docs/plans/2026-02-23-autenticacao-jwt-design.md` | Architect (brainstorming) | Passo 4 |
| Implementation plan | `docs/plans/2026-02-23-autenticacao-jwt-implementation.md` | Architect (writing-plans) | Passo 5 |
| Arquivos de código | `src/services/jwt.service.ts` etc. | Backend (TDD) | Passo 6 |
| Testes | `src/services/jwt.service.test.ts` etc. | Backend (TDD) | Passo 6 |
| Review doc | `.aidev/reviews/2026-02-23-autenticacao-jwt-review.md` | Code Reviewer | Passo 7 |
| Commit no git | `feat(auth): adiciona autenticacao JWT` | `aidev commit` | Passo 9 |
| Feature history | `.aidev/plans/history/2026-02/autenticacao-jwt-23.md` | `aidev complete` | Passo 10 |
| Lição aprendida | `.aidev/memory/kb/2026-02-23-jwt-*.md` | Knowledge Manager | Passo 11 |
| Snapshot atualizado | `.aidev/state/activation_snapshot.json` | `workflow-sync.sh` | Automático |
| ROADMAP atualizado | `.aidev/plans/ROADMAP.md` | `aidev complete` | Automático |

---

### Resumo de quem faz o quê no exemplo

| # | Passo | Responsável | Autônomo? | Interação necessária |
|---|-------|-------------|-----------|---------------------|
| 0 | Receber pedido | Usuário → Orchestrator | Autônomo | Só a entrada inicial |
| 1 | Clarificação de requisitos | Orchestrator | Não | Usuário responde perguntas |
| 2 | Criar feature no backlog | CLI + Orchestrator | Sugerido | Usuário confirma o comando |
| 3 | Iniciar feature | CLI | Parcialmente | Usuário executa `aidev start` |
| 4 | Design (brainstorming) | Architect | Parcialmente | Usuário aprova design |
| 5 | Plano de implementação | Architect | Parcialmente | Usuário aprova plano |
| 6 | Implementação TDD | Backend | Autônomo | Usuário vê resultado ao final |
| 7 | Code review | Code Reviewer | Autônomo | Usuário vê o review |
| 8 | Auditoria de segurança | Security Guardian | Autônomo | Usuário vê resultado |
| 9 | Commit | CLI + Workflow | Parcialmente | Usuário aprova diff e confirma |
| 10 | Conclusão da feature | CLI | Parcialmente | Usuário executa `aidev complete` |
| 11 | Lição aprendida | Knowledge Manager | Autônomo | Nenhuma |

---

## Referências

| Arquivo | Descrição |
|---------|-----------|
| [orchestrator.md](../agents/orchestrator.md) | Definição completa do Orquestrador |
| [feature-lifecycle.md](feature-lifecycle.md) | Sistema de lifecycle de features |
| [workthrees-technical-docs.md](workthrees-technical-docs.md) | Orquestração de tarefas e fila |
| `.aidev/agents/*.md` | Definição de cada agente |
| `.aidev/skills/*/SKILL.md` | Definição de cada skill |

---

*Relatório gerado em 2026-02-23. Para validação e aprovação.*
