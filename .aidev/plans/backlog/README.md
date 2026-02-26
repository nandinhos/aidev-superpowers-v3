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

### 2. [CONCLUÍDO] Rules Engine - Carregamento e Injeção

**Status:** ✅ CONCLUÍDO — Arquivado em `history/2026-02/`
**Fase:** 3
**Descrição:** rules-loader.sh, rules-validator.sh, rules-dedup.sh, rules-dashboard.sh, rules-taxonomy.yaml.

---

### 3. [CONCLUÍDO] Gap no Fluxo de Lições Aprendidas

**Status:** ✅ CONCLUÍDO — Arquivado em `history/2026-02/`
**Fase:** 3
**Descrição:** Módulo `lib/triggers.sh` v2.0 consolidado com state machine + validador. 14/14 testes passando.

---

### 8. [CONCLUÍDO] Avaliação e Evolução das Skills

**Arquivo:** [avaliacao-skills-ferramentas.md](avaliacao-skills-ferramentas.md)
**Status:** CONCLUÍDO
**Prioridade:** Média
**Fase:** 5
**Criado:** 2026-02-26

**Descrição:** Implementado: skill-runner.sh, comando `aidev skill`, inventory em .aidev/docs/skills-inventory.md.

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
| Gap no Fluxo de Lições Aprendidas | **CONCLUÍDO** | 2026-02-26 |
| Rules Engine - Carregamento e Injeção | **CONCLUÍDO** | 2026-02-26 |
| Avaliação e Evolução das Skills | **CONCLUÍDO** | 2026-02-26 |

---

## Legenda de Fases

| Fase | Descrição | Items |
|------|-----------|-------|
| 1 | Foundation (Instalação + Onboarding) | #4, #6 ✅ CONCLUÍDOS |
| 2 | Infraestrutura (Sync + Workflow) | #5, #7 ✅ CONCLUÍDOS |
| 3 | Base de Conhecimento (Rules + Triggers) | #2, #3 ✅ CONCLUÍDOS |
| 4 | Ciclo Virtuoso (Retroalimentação) | #1 ✅ CONCLUÍDO |
| 5 | Evolução (Skills Ferramentas) | #8 ✅ CONCLUÍDO |

---

## Resumo de Implementação

**Total de ideias no backlog:** 0 (todos concluídos!)

---

*Ultima atualizacao: 2026-02-26*
