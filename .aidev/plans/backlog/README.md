# Backlog - Ideias Futuras

> Ideias brutas que aguardam refinamento e priorização para se tornarem features.

---

## Fluxo

```
backlog/ (ideia) → refine (brainstorm) → features/ (planejada) → current/ (executando) → history/YYYY-MM/ (concluída)
```

**Regras:**
- Backlog contém ideias sem sprint definida
- Ao priorizar: criar plano completo em `features/` e remover daqui
- Nunca iniciar implementação a partir do backlog diretamente

---

## Priorização por Dependência e Complexidade

### Análise de Dependências

| Item | Depende de | Bloqueia |
|------|------------|----------|
| 1. Retroalimentação Templates | #2, #3 | nenhuma |
| 2. Rules Engine | - | #1, #5 |
| 3. Learned Lesson Trigger | - | #1 |
| 4. Instalador Global | - | #6 |
| 5. Refinamento Features | - | #7, #8 |
| 6. Onboarding Interativo | #4 (corrigir install) | - |
| 7. Automação Sync | - | #5 |
| 8. Avaliação Skills | - | #1 |

### Ordem de Implementação Proposta

| Fase | Item | Motivo |
|------|------|--------|
| **Fase 1** | #4 (Instalador) | Bug crítico, Blocker para #6 |
| **Fase 1** | #6 (Onboarding) | Experiência inicial, depende de #4 |
| **Fase 2** | #7 (Sync Unificado) | Infraestrutura base, suporta #5 |
| **Fase 2** | #5 (Refinamento Features) | Workflow, depende de #7 |
| **Fase 3** | #2 (Rules Engine) | Base para retroalimentação |
| **Fase 3** | #3 (Trigger Gap) | Complementa rules engine |
| **Fase 4** | #1 (Retroalimentação) | Integra tudo, ciclo virtuoso |
| **Fase 5** | #8 (Skills Ferramentas) | Evolução das skills |

---

## Ideias Pendentes

### 1. [PRIORIDADE ALTA] Sistema de Retroalimentação de Templates

**Arquivo:** [retroalimentacao-templates-curadoria-licoes.md](retroalimentacao-templates-curadoria-licoes.md)
**Status:** backlog
**Prioridade:** Alta
**Fase:** 4 (depende de #2, #3)
**Criado:** 2026-02-26

**Descrição:** Ciclo virtuoso onde lições aprendidas são classificadas (local/global), passam por curadoria (MCPs) e são promotionadas a regras/templates globais.

---

### 2. [PRIORIDADE ALTA] Rules Engine - Carregamento e Injeção

**Arquivo:** [rules-engine-standardization.md](rules-engine-standardization.md)
**Status:** backlog
**Prioridade:** Alta
**Fase:** 3
**Criado:** 2026-02-20

**Descrição:** Mecanismo que carrega, injeta no contexto da LLM e valida o cumprimento de regras de codificação definidas em `.aidev/rules/`.

---

### 3. [CONCLUÍDO] Gap no Fluxo de Lições Aprendidas

**Arquivo:** [learned-lesson-trigger-gap.md](learned-lesson-trigger-gap.md)
**Status:** CONCLUÍDO
**Prioridade:** Alta
**Fase:** 3
**Criado:** 2026-02-26

**Descrição:** Engine de triggers implementada em `lib/triggers.sh` (já existente). Integração com bin/aidev via `triggers__detect_intent` e `triggers__watch_errors`.

---

### 8. [PRIORIDADE MÉDIA] Avaliação e Evolução das Skills

**Arquivo:** [avaliacao-skills-ferramentas.md](avaliacao-skills-ferramentas.md)
**Status:** backlog
**Prioridade:** Média
**Fase:** 5
**Criado:** 2026-02-26

**Descrição:** Transformar skills de arquivos .md passivos em ferramentas CLI acionáveis (skill start, skill step, skill complete).

---

## Ideias Concluídas / Removidas

| Ideia | Status | Data |
|-------|--------|------|
| Sistema de Atualização Interativa | Concluído em `history/2026-02/` | 2026-02-18 |
| MCP Universal Install | Removido (fora de escopo) | 2026-02-18 |
| Basic Memory Graceful Integration | Movido para `features/` | 2026-02-20 |
| Automação do Ciclo de Vida de Features | Concluido em history/ | 2026-02-20 |
| Workthrees - Orquestrador Inteligente | Concluido em history/ | 2026-02-23 |
| Fix: AIDEV_ROOT single source | Concluido em history/ | 2026-02-23 |
| Bug: Instalador Global Não Instala no Projeto | **CONCLUÍDO** | 2026-02-26 |
| Onboarding Interativo + Orquestrador Semântico | **CONCLUÍDO** | 2026-02-26 |
| Automatização do Sync de Estado Unificado | **CONCLUÍDO** | 2026-02-26 |
| Refinamento Features com Sprints Estruturados | **CONCLUÍDO** | 2026-02-26 |
| Sistema de Retroalimentação Templates | **CONCLUÍDO** | 2026-02-26 |

---

## Legenda de Fases

| Fase | Descrição | Items |
|------|-----------|-------|
| 1 | Foundation (Instalação + Onboarding) | #4, #6 ✅ CONCLUÍDOS |
| 2 | Infraestrutura (Sync + Workflow) | #5, #7 ✅ CONCLUÍDOS |
| 3 | Base de Conhecimento (Rules + Triggers) | #2, #3 Pendentes |
| 4 | Ciclo Virtuoso (Retroalimentação) | #1 ✅ CONCLUÍDO |
| 5 | Evolução (Skills Ferramentas) | #8 Pendente |

---

## Resumo de Implementação

**Total de ideias no backlog:** 4 (antes: 8)
**Implementadas nesta sessão:** 5

### Items Remanescentes:
- #2 Rules Engine
- #3 Learned Lesson Trigger  
- #8 Avaliação Skills

---

*Ultima atualizacao: 2026-02-26*
