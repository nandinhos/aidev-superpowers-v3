# Feature: Workthrees - Orquestrador Inteligente de Execução Assistida

**Status:** Concluido
**Prioridade:** Alta
**Criado:** 2026-02-23

---

## Contexto

Analisei a viabilidade de implementar um agente orquestrador inteligente para execução assistida por IA, focado em:
- Detecção de impacto por arquivo/módulo
- Identificação de dependências entre tarefas
- Controle de paralelismo seguro
- Classificação automática de complexidade
- Seleção dinâmica de LLM
- Gerenciamento de fila com dependências
- Lock manager por arquivo

**Resultado da Análise:** Viabilidade ALTA para 5 componentes usando infraestrutura shell+JSON existente.

---

## Escopo Proposto

### Componentes a Implementar

| # | Componente | Descrição |
|---|------------|-----------|
| 1 | **Análise de Impacto** | Detectar arquivos afetados antes da execução |
| 2 | **Grafo de Dependências** | Identificar e validar dependências entre tasks |
| 3 | **Classificação de Complexidade** | Scoring automático (low/medium/high/critical) |
| 4 | **Seleção Dinâmica de LLM** | Strategy pattern para escolha de modelo |
| 5 | **Sistema de Fila** | Fila com prioridade e dependências |
| 6 | **Lock Manager** | Impedir conflitos em arquivos compartilhados |

---

## Estrutura Proposta

```
.aidev/
├── lib/
│   ├── analyze-impact.sh      # Etapa 1
│   ├── dependency-graph.sh   # Etapa 2
│   ├── classify-complexity.sh # Etapa 3
│   ├── select-llm.sh          # Etapa 4
│   ├── task-queue.sh          # Etapa 5
│   └── file-lock.sh           # Etapa 6
├── state/
│   ├── queue.json             # Fila de tasks
│   └── locks.json            # Locks de arquivo
└── config/
    ├── llm-strategies.json   # Estratégias de seleção
    └── complexity-rules.json # Regras de scoring
```

---

## Pré-Requisitos

- Manter compatibilidade com CLI atual (`aidev plan`, `aidev start`, etc.)
- Usar infraestrutura existente (shell + JSON state)
- Sem necessidade de Redis ou message broker nesta fase

---

## Limitações Esperadas

- Não é concorrência real (shell-based)
- Race conditions possíveis em estado JSON
- Sem fallback entre LLMs (infraestrutura externa necessária)

---

## Referência

Análise completa disponível em: `.aidev/docs/workthrees-viability-analysis.md`
