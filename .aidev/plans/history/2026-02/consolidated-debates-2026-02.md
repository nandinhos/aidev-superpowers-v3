# Consolidação de Debates — Fevereiro 2026

## Sumário Executivo

Este documento consolida as análises de 5 rodadas de debate com múltiplos LLMs sobre a arquitetura do AI Dev Superpowers v3. Os debates abordaram dois temas principais: a unificação dos fluxos de execução (Plans vs Sprints) e a avaliação de 3 ideias do backlog. A convergência alcançada indica que o sistema possui configuração declarativa (~70% do código existente) mas falta runtime que a consuma. A recomendação unânime é implementar um Stack Detector como fundação compartilhada, seguido por MCP Standardized Activation, Rules Engine e, condicionadamente, Trigger Engine.

## Rodadas de Debate

### Rodada 1-3: Fluxos de Execução (Plans vs Sprints)

**Participantes**: Sonnet 4.6, Gemini 3.1 Pro, Gemini CLI Conductor

**Tema**: Unificação de fluxos de execução redundantes

**Problema identificado**: 3 sistemas coexistem no codebase:
- `lib/feature-lifecycle-cli.sh` (720 linhas) — ATIVO
- `.aidev/lib/feature-lifecycle.sh` (549 linhas) — MORTO
- `lib/plans.sh` (163 linhas) — REDUNDANTE

**Conclusão**: Plans-based (Markdown) é o fluxo canônico e fonte de verdade. JSON é suporte/espelho, não fonte. ~1.800 linhas são removíveis com a unificação.

---

### Rodada 4-8: Gaps do Core

**Participantes**: Opus 4.6, Gemini 3.1 Pro, MiniMax 2.5, GLM-5, Gemini CLI

**Tema**: Avaliação de 3 ideias do backlog

**Ideia 1 - Learned Lesson Trigger Gap**
- Trigger YAML existe mas não há engine que consuma
- Complexidade: ALTA
- Veredito: APROVADO COM CONDICIONANTE (bloqueado até definir padrão de interceptação de output LLM)

**Ideia 2 - Rules Engine Standardization**
- Regras em `.aidev/rules/` não são injetadas no contexto da LLM
- Complexidade: ALTA
- Veredito: APROVADO — PRIORIDADE 2

**Ideia 3 - MCP Standardized Activation**
- Detecção de stack e ativação de MCPs é manual
- Complexidade: MÉDIA
- Veredito: APROVADO — PRIORIDADE 1
- Já existe ~70% do código (mcp-detect.sh, mcp-config-generator.sh, docker-discovery.sh)

**Convergência crítica**: Todas as 3 ideias compartilham a mesma causa raiz: **configuração declarativa existe, mas não há runtime que a consuma**.

## Vereditos Consolidados

### Veredicto 1: Arquitetura de Fluxos

**Decisão final**:
- Eliminar `.aidev/lib/feature-lifecycle.sh` (dead code)
- Deprecar `lib/plans.sh` e `aidev feature finish`
- Renomear `feature-lifecycle-cli.sh` → `feature-lifecycle.sh`
- Preservar capacidades do JSON (context-log, rollback, session metrics)
- **Sequência estimada**: 3-4 sprints

### Veredicto 2: Priorização de Features

**Decisão final com ordem**:

1. **Stack Detector** (fundação compartilhada) — 2-4h
2. **MCP Standardized Activation** (menor risco, maior ROI) — 6-8 dias
3. **Rules Engine** (usa Stack Detector) — 12-16 dias
4. **Trigger Engine** (bloqueado até condicionante resolvida) — 8-12 dias

**Total estimado**: ~38 dias

## Features Priorizadas para Backlog

| # | Feature | Prioridade | Sprint Estimado |
|---|---------|-----------|-----------------|
| 1 | Unificação de Fluxos | ALTA | 3-4 |
| 2 | MCP Standardized Activation | 1 | 1-2 |
| 3 | Rules Engine | 2 | 3-5 |
| 4 | Trigger Engine | 3 (condicional) | 6+ |

## Próximos Passos

1. Executar `aidev start` para Feature 1: Unificação de Fluxos
2. Implementar Stack Detector como fundação compartilhada
3. Executar `aidev start` para Feature 2: MCP Standardized Activation
4. Resolver condicionante para Trigger Engine (padrão de interceptação LLM)
5. Consolidar arquivos de análise em `.aidev/docs/debates/`
