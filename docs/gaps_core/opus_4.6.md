# Mesa de Debates — Análise das 3 Novas Ideias do Backlog

**Data**: 2026-02-23
**Participantes**: Orquestrador, Agente Arquiteto, Agente QA/TDD, Agente Backend/DevOps
**Método**: Análise paralela com síntese final

---

## As 3 Ideias Analisadas

### Ideia 1 — Trigger Engine para Lições Aprendidas
- **Arquivo de origem**: `.aidev/plans/backlog/learned-lesson-trigger-gap.md`
- **Gap**: `.aidev/triggers/lesson-capture.yaml` existe com regras declarativas, mas nenhum runtime o lê ou aciona o skill `learned-lesson`.
- **Componentes propostos**: parser YAML, event listener, matching engine, dispatcher, state machine, hook de validação pós-lesson.

### Ideia 2 — Rules Engine: Carregamento e Injeção de Regras
- **Arquivo de origem**: `.aidev/plans/backlog/rules-engine-standardization.md`
- **Gap**: `.aidev/rules/` tem regras (generic.md, livewire.md, llm-limits.md) mas nenhum mecanismo as injeta no contexto da LLM nem valida cumprimento pós-ação.
- **Componentes propostos**: taxonomia 3 camadas, loader de regras, validação pós-ação, anti-duplicação, dashboard de compliance.

### Ideia 3 — MCP Standardized Activation
- **Arquivo de origem**: `.aidev/plans/backlog/mcp-standardized-activation.md`
- **Gap**: MCPs são configurados manualmente via `.mcp.json`, sem orquestrador detectando stack e gerando configuração automaticamente.
- **Componentes propostos**: classificação universal/conditional, detector de stack, gerador de `.mcp.json`, health check, workflow de onboarding.

---

## Veredito — Agente Arquiteto

### Diagnóstico

As 3 ideias têm causa raiz unificada: **configuração declarativa sem runtime que a consuma**. Não são 3 problemas isolados — são 3 manifestações do mesmo padrão arquitetural ausente.

### Proposta Central

Não implementar 3 engines separadas. Implementar **1 Universal Declarative Consumer Framework** com 3 extensões, aproveitando 80% de código compartilhado.

```
┌─────────────────────────────────────────────────────┐
│       Universal Declarative Consumer Framework      │
│  (YAML Parser + State Machine + Context Injector)  │
└─────────────────────────────────────────────────────┘
       ↓              ↓              ↓
  MCP Engine    Rules Engine   Trigger Engine
  (Ideia 3)     (Ideia 2)      (Ideia 1)
       ↓              ↓              ↓
  .mcp.json    Rules Injection  Skill Activation
```

### Componentes Compartilhados Identificados

```
.aidev/engine/
├── yaml-parser.sh              (serve aos 3)
├── fsm-base.sh                 (state machine base)
├── context-injector.md         (injector genérico)
└── declarative-consumer-core.md

.aidev/config/
├── mcp-registry.yaml           (Ideia 3)
├── rules-taxonomy.yaml         (Ideia 2)
└── triggers-schema.yaml        (Ideia 1)

.aidev/skills/
└── stack-detector.md           (compartilhado: Ideias 2 e 3)
```

### Complexidade por Ideia

| Ideia | Complexidade | Estimativa |
|-------|---|---|
| Trigger Engine | MÉDIA-ALTA | 40-50h |
| Rules Engine | ALTA | 50-70h |
| MCP Standardized | MÉDIA | 30-40h |
| Core Foundation | — | 15-20h |
| **Total consolidado** | | **~110-135h** |

### Riscos Identificados

- **Trigger Engine**: race conditions (múltiplos triggers simultâneos), false positives em keyword matching, confidence scoring é heurístico
- **Rules Engine**: injeção LLM-específica requer adapter pattern, context window explosion se todas as regras carregadas, stale rules vs documentação oficial
- **MCP Standardized**: merge conflict ao sobrescrever `.mcp.json` manual, health check falso positivo (container lento)
- **Cross-cutting**: state consistency entre 3 engines — mitigado com core state machine centralizado em `unified.json`

### Sequência Proposta

1. **Core Foundation** — YAML parser + FSM (base compartilhada)
2. **MCP Standardized** — menor risco, resultado imediato, desbloqueador
3. **Rules Engine** — usa Stack Detector da etapa 2
4. **Trigger Engine** — depende das etapas anteriores

### Recomendação Final

> **NÃO implemente 3 ideias isoladas. Implemente 1 framework com 3 extensões.** Economia de 20-30% no esforço total e código muito mais manutenível.

---

## Veredito — Agente QA / TDD

### Testabilidade por Ideia

| Ideia | Testabilidade | Complexidade TDD | Esforço |
|-------|---|---|---|
| Trigger Engine | MÉDIO-ALTO | 6/10 | 60-80h |
| Rules Engine | ALTO | 7/10 | 80-100h |
| MCP Standardized | MÉDIO | 6/10 | 70-90h |
| **Total** | | | **210-270h** |

### O que é difícil de testar (por ideia)

**Trigger Engine**:
- Timing de cooldown entre triggers — flaky sem fake timers
- Interação com LLM em tempo real
- Race conditions em triggers simultâneos

**Rules Engine**:
- Injeção no contexto da LLM (integração com API Claude)
- Validação de ações semânticas humanas
- Performance em larga escala (1k+ regras)

**MCP Standardized**:
- Conectividade real com MCPs (requer servidores ativos)
- Variabilidade de respostas de MCPs
- Timeout/retry em rede ruim

### Sequência TDD-safe

- **Sprint 1**: MCP (Stack Detector) + Trigger (Parser YAML) — isolados, sem dependências
- **Sprint 2**: MCP (Gerador `.mcp.json`) + Trigger (Pattern Matcher)
- **Sprint 3**: Rules (Loader) + Trigger (Event Listener + State Machine)
- **Sprint 4**: MCP (Health Check + Onboarding) + Rules (Validação + Anti-dedup)
- **Sprint 5**: Testes E2E + mutation testing + regressão completa

### Pontos Cegos — O que outros especialistas vão ignorar

1. **Flakiness em timing**: Cooldown no Trigger Engine → testes frágeis. Solução: fake timers obrigatório.
2. **Schema validation ausente**: Rules Engine aceita YAML inválido sem sinalizar. Solução: JSON Schema.
3. **Memory leaks em Event Listeners**: Listeners globais sem cleanup. Solução: testes de heap.
4. **Race conditions**: Dois triggers simultâneos sem política de precedência.
5. **Backdoor de validação**: Ação já executada quando validação falha — estado corrompido. Solução: testes de rollback.
6. **MCP config outdated**: `.mcp.json` gerado uma vez, stack muda depois.
7. **Saturação**: Rules Engine com 10k regras sem benchmark.
8. **Prioridade vs Precedência**: Feature priority=100 sobrescreve global? Política não definida.

### Definição de Done

**Trigger Engine**: Parser YAML 100% validado, matcher 90%+ cobertura, cooldown com fake timers, state machine 95%+, teste E2E Output → Trigger → Skill.

**Rules Engine**: Loader sem exceções, 3 camadas com todos os combos de precedência, validação detecta 100% das violações, performance < 100ms para 1.000 regras.

**MCP Standardized**: Detector identifica 90%+ das stacks, `.mcp.json` válido por JSON Schema, health check < 5s, backup obrigatório antes de sobrescrever.

---

## Veredito — Agente Backend / DevOps

### Diagnóstico Crítico

A "facilidade de consumo" difere muito entre as 3 ideias:
- **MCP**: filesystem-based → **fácil**
- **Rules**: context-injection → **médio**
- **Triggers**: LLM-listening → **difícil/impossível com shell puro**

### Problema Crítico — Trigger Engine (não identificado pelo Arquiteto)

> Shell script **não consegue "escutar"** o que a LLM está processando em tempo real. O trigger YAML define `type: user_intent` (detecta mensagens do usuário) e `type: error_pattern` (detecta outputs de LLM). O primeiro é **impossível** sem middleware; o segundo é viável apenas com hook em pontos específicos do output. Isso não é problema de engine — é problema arquitetural.

### Infraestrutura Existente Reutilizável

| Script | Reuso | Relevante para |
|--------|-------|---|
| `mcp-detect.sh` | 95% | MCP Standardized (já detecta Basic Memory) |
| `workflow-commit.sh` | 80% | Rules Engine (já valida tipo de commit) |
| `validation-engine.sh` | 100% | Rules Engine (validação pós-ação) |
| `auto-catalog.sh` | 60% | Trigger Engine (já tem detecção de erros) |
| `activation-snapshot.sh` | 70% | Trigger Engine (padrão state + JSON) |

### Viabilidade e Estimativas

| Ideia | Viabilidade | Linhas estimadas | Prazo | ROI |
|-------|---|---|---|---|
| MCP Standardized | **9/10** | ~480 linhas | 6-8 dias | Altíssimo |
| Rules Engine | **8/10** | ~600 linhas | 12-16 dias | Alto |
| Trigger Engine | **7/10** | ~270 linhas | 8-12 dias | Médio |
| **Total** | | | **~38 dias seq.** | |

### Armadilhas Específicas

**MCP Standardized**:
- Docker socket inacessível em WSL2 — fallback obrigatório
- Container renomeado pelo usuário — usar filter por image, não por nome
- Smart merge de `.mcp.json` — diff + union, jamais sobrescrever direto

**Rules Engine**:
- Multi-runtime é pântano: Claude Code usa `.claude.md`, Cursor usa `.cursorrules`. Começar **apenas** com Claude Code.
- Injeção não garante leitura — LLM pode ignorar regras injetadas
- Dashboard de compliance é vanidade — métrica real: "quantas violações foram bloqueadas?"

**Trigger Engine**:
- Regex matching quebrado para português conjugado ("resolveu/resolvemos/resolvido") — YAML só lista infinitivo
- Skill activation sem contexto: quando trigger aciona `learned-lesson`, o contexto (qual erro foi resolvido?) não é passado automaticamente
- Cooldown global vs por-trigger sem política de precedência definida no YAML atual

### Anti-recomendações

1. Não implementar Trigger Engine sem antes definir padrão de interceptação do output da LLM
2. Não suportar todos os runtimes simultaneamente no Rules Engine — começar com Claude Code
3. Não usar `@latest` em MCPs no template — pinnar versões
4. Não mergear Trigger Engine com Rules Engine — são ortogonais

---

## Síntese da Mesa — Convergências e Divergências

### O que os 3 especialistas concordam

1. **Causa raiz única**: Configuração declarativa sem runtime. Não são 3 problemas — são 3 manifestações do mesmo gap.
2. **MCP Standardized primeiro**: Menor risco, maior reuso, resultado imediato, desbloqueador para as outras 2.
3. **Stack Detector como componente compartilhado**: Ideias 2 e 3 dependem dele. Implementar uma vez.
4. **Rules Engine segundo**: Alto impacto em compliance, complexidade moderada.
5. **Trigger Engine terceiro**: Mais frágil, mais acoplado ao LLM, menor ROI imediato.

### Divergências e Vereditos Arbitrados

**Divergência 1 — Framework unificado vs módulos independentes**
- Arquiteto: Um Universal Declarative Consumer monolítico (80% código compartilhado)
- Backend/DevOps: Não mergear Trigger com Rules — são ortogonais, acoplamento perigoso
- **Veredito**: Meio-termo. Utilitários compartilhados (YAML parser, Stack Detector, FSM base) existem como biblioteca interna. Cada engine mantém lógica própria. Sem monolito.

**Divergência 2 — Trigger Engine é implementável hoje?**
- Arquiteto: Sim, com matching engine e dispatcher
- Backend/DevOps: Não com shell puro — LLM é inacessível via stdout
- QA: Viável mas risco alto de flakiness
- **Veredito**: APROVADO COM CONDICIONANTE. Implementar apenas após definir explicitamente o padrão de interceptação. Hoje é bloqueante.

**Divergência 3 — Estimativas de esforço**
- Arquiteto: 110-135h total (subestima testes)
- QA: 210-270h apenas de testes (não inclui desenvolvimento)
- Backend: 38 dias sequencial (desenvolvimento + testes + integração)
- **Veredito**: Adotar estimativa do Backend como referência de planejamento.

---

## Veredito Final

### Ideia 3 — MCP Standardized Activation: APROVADO — PRIORIDADE 1

**Justificativa**: `mcp-detect.sh` já existe com 95% do código. Determinístico (filesystem), sem dependência de LLM. Desbloqueador para as outras 2. ROI altíssimo.

**Escopo MVP**:
1. Registry de MCPs em YAML (universal vs conditional)
2. Estender `mcp-detect.sh` com detector de stack completo
3. Gerador de `.mcp.json` com smart merge
4. Health check (timeout < 5s, retry)
5. Integrar ao `aidev start <feature>` como passo automático

**Condicionantes**:
- Backup obrigatório antes de sobrescrever `.mcp.json`
- Fallback quando Docker socket inacessível (WSL2)
- JSON Schema validation no arquivo gerado

---

### Ideia 2 — Rules Engine: APROVADO — PRIORIDADE 2

**Justificativa**: Alto impacto em compliance. Reutiliza Stack Detector da Ideia 3. `workflow-commit.sh` e `validation-engine.sh` já existem — incremento real é menor do que parece.

**Escopo MVP**:
1. Taxonomia de regras em YAML (global / stack / projeto)
2. Rules Loader: carrega `.aidev/rules/generic.md` + regras de stack detectado
3. Injeção — **apenas Claude Code** (`CLAUDE.md`) na v1
4. Validação pré-commit: português obrigatório, sem emoji, sem co-autoria
5. Anti-duplicação básica

**Condicionantes**:
- Começar com Claude Code apenas. Outros runtimes ficam para v2.
- Política de precedência (global vs stack vs feature) documentada antes de implementar.
- Dashboard de compliance é nice-to-have, não bloqueia lançamento.

---

### Ideia 1 — Trigger Engine: APROVADO COM CONDICIONANTE — PRIORIDADE 3

**Justificativa**: Aprovado como feature, mas bloqueado até resolução arquitetural obrigatória.

**Condicionante obrigatória antes de iniciar**:
> Definir como o Trigger Engine intercepta o output da LLM. Shell puro não consegue "ouvir" o que a LLM processa. Opções a avaliar: (a) hook no output do CLI, (b) middleware de interceptação, (c) limitar ao tipo `error_pattern` em arquivos de log, descartando `user_intent` por ora.

**Escopo MVP (após condicionante resolvida)**:
1. Parser YAML para `.aidev/triggers/lesson-capture.yaml`
2. Keyword matcher com regex (sem confidence scoring na v1)
3. **Modo suggest** — exibir sugestão ao usuário, não auto-ativar skill
4. State machine básico (idle → detected → suggested → accepted/rejected)
5. Integrar ao skill `learned-lesson` com passagem de contexto

**Descartado da v1**:
- Confidence scoring (0.8 threshold) — implementar após validar recall/precision real
- `type: user_intent` — impossível via shell sem middleware
- Cooldown por-trigger — implementar após identificar casos reais de conflito

---

## Arquitetura Aprovada

### Componentes Compartilhados (pré-requisitos)

```
.aidev/lib/
├── stack-detector.sh     (NOVO — compartilhado Ideias 2 e 3)
├── yaml-to-json.sh       (NOVO — compartilhado pelos 3)
└── fsm-base.sh           (NOVO — state machine base Ideias 1 e 2)
```

### Sequência de Implementação

```
Pré-req: Componentes compartilhados
  → stack-detector.sh
  → yaml-to-json.sh

Sprint 1-2: Ideia 3 (MCP Standardized)
Sprint 3-5: Ideia 2 (Rules Engine)
Sprint 6+:  Ideia 1 (Trigger) — após condicionante resolvida
```

---

*Documento gerado em 2026-02-23 via mesa de debates com Arquiteto, QA/TDD e Backend/DevOps.*
