# Documento Técnico - Workthrees
## Orquestrador Inteligente de Execução Assistida por IA

**Versão:** 1.0.0  
**Data:** 2026-02-23  
**Status:** Implementado

---

## 1. Visão Geral

O **Workthrees** é um sistema de orquestração inteligente para execução assistida por IA, desenvolvido como módulo do AI Dev Superpowers. Ele automatiza a análise de impacto, classificação de complexidade, seleção de LLM, gerenciamento de fila e controle de conflitos entre tarefas.

### 1.1 Objetivos

| Objetivo | Descrição |
|----------|-----------|
| Automatizar análise | Detectar arquivos afetados automaticamente |
| Classificar complexidade | Scoring automático para seleção de LLM |
| Otimizar recursos | Selecionar LLM ideal por complexidade |
| Controlar paralelismo | Impedir conflitos em arquivos compartilhados |
| Gerenciar fila | Executar tarefas respeitando dependências |

---

## 2. Arquitetura do Sistema

### 2.1 Componentes

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           WORKTHREES ORCHESTRATOR                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   INPUT     │───▶│  ANALYZER   │───▶│ CLASSIFIER  │───▶│   SELECTOR  │  │
│  │  (User)     │    │   IMPACT    │    │ COMPLEXITY  │    │    LLM      │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│         │                   │                   │                   │       │
│         ▼                   ▼                   ▼                   ▼       │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   QUEUE     │◀──▶│   DEPEND    │    │   LOCK      │    │   FALLBACK  │  │
│  │  MANAGER    │    │   GRAPH     │    │   MANAGER   │    │   (Future)  │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │         STATE STORE           │
                    │   (.aidev/state/workthrees/)  │
                    │   - queue.json               │
                    │   - locks.json               │
                    └───────────────────────────────┘
```

### 2.2 Estrutura de Arquivos

```
.aidev/
├── lib/workthrees/
│   ├── workthrees-run.sh      # Orquestrador principal
│   ├── analyze-impact.sh      # Análise de impacto
│   ├── classify-complexity.sh # Classificação
│   ├── dependency-graph.sh    # Grafo de dependências
│   ├── task-queue.sh          # Gerenciamento de fila
│   ├── select-llm.sh          # Seleção de LLM
│   └── file-lock.sh           # Lock de arquivos
├── config/workthrees/
│   ├── llm-strategies.json    # Estratégias de seleção
│   └── complexity-rules.json  # Regras de scoring
└── state/workthrees/
    ├── queue.json             # Fila de tarefas
    └── locks.json             # Locks ativos
```

---

## 3. Fluxos de Execução

### 3.1 Fluxo Completo (run)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        FLUXO COMPLETO (workthrees run)                        │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐           │
│   │  USUÁRIO │────▶│ ANALYZE  │────▶│ CLASSIFY │────▶│  SELECT  │           │
│   │          │     │  IMPACT  │     │COMPLEXITY│     │   LLM    │           │
│   └──────────┘     └──────────┘     └──────────┘     └──────────┘           │
│        │                                                    │                  │
│        │         PARÂMETROS                                │                  │
│        │    --task-id "feat-001"                           │                  │
│        │    --description "Criar login"                   ▼                  │
│        │    --files "src/auth/..."         ┌─────────────────────┐           │
│        │    --type new                     │      RESUMO         │           │
│        │    --priority 5                   │  - Complexidade    │           │
│        │    --strategy balanced            │  - LLM selecionada │           │
│        │                                   │  - Score: 35       │           │
│        │                                   └─────────────────────┘           │
│        │                                          │                         │
│        ▼                                          ▼                         │
│   ┌─────────────────────────────────────────────────────────────────┐       │
│   │                    ENQUEUE NA FILA                               │       │
│   │         Task adicionada com dependências e prioridade           │       │
│   └─────────────────────────────────────────────────────────────────┘       │
│                                                                              │
│   ⚠️  INTERAÇÃO MANUAL: Execute 'exec' para continuar                        │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Fluxo de Execução (exec)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                       FLUXO EXECUÇÃO (workthrees exec)                      │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐              │
│   │   DEQUEUE    │────▶│   IMPACT     │────▶│    LOCK      │              │
│   │  (prox task) │     │   ANALYZE    │     │   ACQUIRE    │              │
│   └──────────────┘     └──────────────┘     └──────────────┘              │
│         │                                            │                      │
│         │         Retorna próxima task               │                      │
│         │         executável (sem deps              │                      │
│         │         pendentes)                        │                      │
│         │                                            ▼                      │
│         │                                   ┌──────────────────┐             │
│         │                                   │   CONFLITO?      │             │
│         │                                   │   - SIM → FAIL  │             │
│         │                                   │   - NÃO → OK    │             │
│         │                                   └──────────────────┘             │
│         │                                            │                      │
│         ▼                                            │                      │
│   ┌──────────────┐                                   │                      │
│   │   EXECUTA   │◀──────────────────────────────────┘                      │
│   │   LLM TASK   │                                                        │
│   └──────────────┘                                                        │
│         │                                                                 │
│         │         ⚠️  INTERAÇÃO MANUAL:                                  │
│         │         Usuário executa a tarefa                               │
│         │         com a LLM selecionada                                   │
│         │                                                                 │
│         ▼                                                                 │
│   ┌──────────────┐     ┌──────────────┐                                  │
│   │   COMPLETE   │────▶│    LOCK      │                                  │
│   │              │     │   RELEASE    │                                  │
│   └──────────────┘     └──────────────┘                                  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Fluxo de Dependências

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          FLUXO DE DEPENDÊNCIAS                               │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Exemplo:                                                                   │
│   ┌────────┐         ┌────────┐         ┌────────┐                        │
│   │feat-002│         │feat-001│         │feat-003│                        │
│   │  (A)   │◀────────│  (B)   │────────▶│  (C)   │                        │
│   └────────┘         └────────┘         └────────┘                        │
│        │                  │                  │                             │
│        │                  │                  │                             │
│   [ready]           [blocked]            [blocked]                         │
│                     by feat-002         by feat-001                         │
│                                                                              │
│   Execution Order:                                                           │
│   1. feat-002 (ready)          → EXECUTAR                                  │
│   2. feat-001 (unblocked)     → EXECUTAR                                  │
│   3. feat-003 (unblocked)      → EXECUTAR                                  │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐   │
│   │                  dependency-graph.sh sort                             │   │
│   │                                                                       │   │
│   │  Input: { "tasks": [...] }                                           │   │
│   │  Output: ["feat-002", "feat-001", "feat-003"] (topological sort)     │   │
│   └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Funcionalidades

### 4.1 Análise de Impacto (`analyze-impact.sh`)

| Funcionalidade | Automático | Manual | Descrição |
|----------------|------------|--------|-----------|
| Detectar módulos por keywords | ✅ | | Analisa descrição e detecta áreas (auth, api, db, etc) |
| Mapear arquivos conhecidos | ✅ | | Usa arquivos fornecidos via `--files` |
| Detectar convenções de projeto | ✅ | | src/, lib/, app/, tests/, etc |
| Parse de código | ❌ | | Requer análise AST (futuro) |

**Entrada:**
```bash
--task-id "feat-001"
--description "Criar componente de login com JWT"
--files "src/auth/login.ts,src/auth/hooks.ts"
```

**Saída:**
```json
{
  "task_id": "feat-001",
  "files": ["src/auth/", "src/components/auth/"],
  "modules": ["auth", "components"],
  "detection_method": "keyword_files_input_mixed",
  "confidence": 0.8
}
```

### 4.2 Classificação de Complexidade (`classify-complexity.sh`)

| Funcionalidade | Automático | Manual | Descrição |
|----------------|------------|--------|-----------|
| Contagem de arquivos | ✅ | | Calcula score por quantidade |
| Tipo de tarefa | ✅ | | new/refactor/fix |
| Múltiplas linguagens | ✅ | | +15 pontos por linguagem |
| Dependências externas | ✅ | | +10-20 por deps |
| Breaking changes | ✅ | | +30 pontos |
| Testes existentes | ✅ | | +15 se sem testes |

**Scoring:**
| Score | Complexidade |
|-------|--------------|
| 0-20 | low |
| 21-50 | medium |
| 51-80 | high |
| 81+ | critical |

### 4.3 Seleção de LLM (`select-llm.sh`)

| Estratégia | low | medium | high | critical |
|------------|-----|--------|------|----------|
| balanced | haiku | sonnet | opus | opus |
| speed | haiku | haiku | haiku | haiku |
| quality | sonnet | opus | opus | opus |
| cost | haiku | sonnet | opus | opus |

### 4.4 Fila de Tarefas (`task-queue.sh`)

| Operação | Automático | Manual |
|----------|------------|--------|
| enqueue | ✅ | |
| dequeue | ✅ | |
| list | ✅ | |
| complete | ✅ | |
| fail | ✅ | |
| wait | ✅ | |

### 4.5 Lock de Arquivos (`file-lock.sh`)

| Operação | Automático | Manual |
|----------|------------|--------|
| acquire | ✅ | |
| release | ✅ | |
| check | ✅ | |
| conflicts | ✅ | |

---

## 5. Automação vs Interação Manual

### 5.1 Matriz de Responsabilidade

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MATRIZ: AUTOMAÇÃO vs INTERAÇÃO                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  FASES                    │ AUTOMAÇÃO │  INTERAÇÃO  │ RESPONSÁVEL          │
│  ─────────────────────────────────────────────────────────────────────────  │
│  1. Input (descrição)    │     ❌    │     ✅      │ Usuário              │
│  2. Análise de impacto   │     ✅    │     ❌      │ Sistema              │
│  3. Classificação        │     ✅    │     ❌      │ Sistema              │
│  4. Seleção de LLM        │     ✅    │     ❌      │ Sistema              │
│  5. Enqueue na fila       │     ✅    │     ❌      │ Sistema              │
│  ─────────────────────────────────────────────────────────────────────────  │
│  6. Execução da tarefa   │     ❌    │     ✅      │ Usuário + LLM        │
│  7. Lock de arquivos      │     ✅    │     ❌      │ Sistema              │
│  8. Completion            │     ✅    │     ✅*     │ Sistema + Usuário    │
│  9. Release de locks      │     ✅    │     ❌      │ Sistema              │
│                                                                             │
│  * O usuário deve digitar "done" para confirmar conclusão                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 pontos de Interação

| # | Ponto | O que o usuário faz |
|---|-------|---------------------|
| 1 | Início | Fornece descrição da tarefa |
| 2 | Execução | Executa a tarefa com LLM |
| 3 | Conclusão | Digita "done" para finalizar |

---

## 6. Análise de GAPs, Inconsistências e Oportunidades

### 6.1 GAPs Identificados

| GAP | Severidade | Descrição | Impacto |
|-----|------------|-----------|---------|
| **G1** | 🔴 Alta | Não detecta dependências reais via análise de código | Sistema usa apenas deps manuais |
| **G2** | 🔴 Alta | Lock via JSON não é atômico - race conditions | Conflitos em exec paralelo |
| **G3** | 🟡 Média | Sem fallback entre LLMs | Falha se LLM indisponível |
| **G4** | 🟡 Média | Sem retry automático | Task falha permanentemente |
| **G5** | 🟡 Média | Detecção de impacto por keywords é limitada | Falsos positivos/negativos |
| **G6** | 🟢 Baixa | Sem persistência de resultado de análise | Repete análise a cada run |

### 6.2 Inconsistências

| # | Inconsistência | Local | Correção |
|---|----------------|-------|----------|
| **I1** | `--files-count` não vem do analyze-impact | workthrees-run.sh:150 | Usar `files` do impact_result |
| **I2** | exec usa complexity hardcoded (5 arquivos) | workthrees-run.sh:220 | Usar análise real |
| **I3** | Semidação de cycle val no enqueue | task-queue.sh | Adicionar validate |
| **I4** | Lock não expira automaticamente | file-lock.sh | Adicionar TTL |

### 6.3 Oportunidades de Melhoria

| # | Oportunidade | Prioridade | Esforço |
|---|--------------|------------|---------|
| **M1** | Integrar com git diff para detecção automática | Alta | Médio |
| **M2** | Adicionar análise de imports (require/import) | Alta | Alto |
| **M3** | Cache de análise de impacto | Média | Baixo |
| **M4** | Interface interativa (wizard) | Média | Médio |
| **M5** | Histórico de execuções | Média | Baixo |
| **M6** | Métricas e observabilidade | Baixa | Alto |
| **M7** | TTL em locks (prevenir locks órfãos) | Alta | Baixo |
| **M8** | API REST para integrações | Baixa | Alto |

---

## 7. Comandos Disponíveis

### 7.1 Comandos Principais

```bash
# Dashboard - visualização geral
workthrees-run.sh dashboard

# Fluxo completo (analyze -> classify -> select -> enqueue)
workthrees-run.sh run \
  --task-id "feat-001" \
  --description "Criar componente de login" \
  --files "src/auth/login.ts" \
  --type new \
  --priority 5 \
  --strategy balanced

# Executar próxima tarefa da fila
workthrees-run.sh exec

# Status da fila
workthrees-run.sh status
```

### 7.2 Comandos Individuais

```bash
# Análise de impacto
workthrees-run.sh analyze --task-id "feat-001" --description "Criar login"

# Classificação
workthrees-run.sh classify --files-count 5 --type new

# Seleção de LLM
workthrees-run.sh select --complexity medium --strategy cost

# Gerenciamento de fila
workthrees-run.sh enqueue --task-id "feat-001" --priority 5

# Locks
workthrees-run.sh release --task-id "feat-001"
```

---

## 8. Limitações Conhecidas

| Limitação | Descrição |
|-----------|-----------|
| **L1** | Não é concorrência real - shell script não é thread-safe |
| **L2** | Estado em JSON não suporta写得 concorrente |
| **L3** | Análise de impacto por keywords tem precisão limitada |
| **L4** | Sem fallback automático entre LLMs |
| **L5** | Requer configuração manual inicial |

---

## 9. Roadmap de Evolução

### Fase 2 - Curto Prazo (1-2 semanas)

- [ ] Corrigir I1 e I2 (usar dados reais do impact)
- [ ] Adicionar TTL em locks (M7)
- [ ] Adicionar validação de ciclos no enqueue (I3)
- [ ] Cache de análise de impacto (M3)

### Fase 3 - Médio Prazo (1 mês)

- [ ] Detecção via git diff (M1)
- [ ] Análise de imports (M2)
- [ ] Interface interativa (M4)
- [ ] Histórico de execuções (M5)

### Fase 4 - Longo Prazo

- [ ] Fallback entre LLMs
- [ ] API REST
- [ ] Integração com Redis para concorrência real
- [ ] Observabilidade completa

---

## 10. Conclusão

O Workthrees fornece uma base funcional para orquestração inteligente de tarefas assistidas por IA. O sistema automatiza análise de impacto, classificação de complexidade e seleção de LLM, reduzindo significativamente a carga cognitiva do usuário.

**Principais forças:**
- Arquitetura modular e extensível
- Integração nativa com AI Dev Superpowers
- Estratégias configuráveis de LLM
- Controle de dependências

**Pontos de atenção:**
- Concorrência limitada (shell-based)
- Detecção de impacto dependente de keywords
- Requer evolução para produção em escala

---

*Documento gerado automaticamente em 2026-02-23*
