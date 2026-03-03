# Checkpoint — 2026-03-02

## Status: REESTRUTURAÇÃO EM ANDAMENTO

---

## Contexto

Iniciou-se uma reestruturação arquitetural do framework AI Dev Superpowers baseada na análise criteriosa do documento `analise-de-requisitos.md` que estava no backlog.

O plano completo está em: `.claude/plans/zippy-mixing-crane.md` (no diretório home do usuário)

---

## Concluído nesta sessão

### Fase 1 — Pasta brainstorm/ (COMPLETA)
- [x] Criada `.aidev/plans/brainstorm/README.md` com documentação completa do novo fluxo
- [x] Atualizado `.aidev/plans/README.md`:
  - Adicionado `brainstorm/` na tabela de navegação (entre backlog/ e features/)
  - Atualizado diagrama de fluxo: `backlog → brainstorm → features → current → history`
  - Atualizada seção de regras com 6 regras (era 5)
  - Atualizada seção de convenções de nomenclatura
  - Status atual atualizado (1 ideia no backlog)

### Fase 2 — Renomeação backlog.sh → error-tracker.sh (PARCIAL)
- [x] Criado `.aidev/lib/error-tracker.sh` como cópia renomeada de `backlog.sh`
  - Header atualizado para identificar o novo nome e propósito
  - Variável `BACKLOG_FILE` apontando para `error-tracker.json`
- [ ] PENDENTE: Deletar `.aidev/lib/backlog.sh` original
- [ ] PENDENTE: Atualizar `.aidev/lib/validation-pipeline.sh` (referencia `backlog.sh`)
- [ ] PENDENTE: Renomear `.aidev/tests/backlog.test.sh` → `error-tracker.test.sh`

---

## Pendente (próximas fases)

### Fase 2 — Completar renomeação backlog.sh
- Deletar `.aidev/lib/backlog.sh`
- Atualizar source em `validation-pipeline.sh`
- Renomear e atualizar `tests/backlog.test.sh`

### Fase 3 — `lib/feature-lifecycle.sh`
- Adicionar variável `_FLC_BRAINSTORM_DIR=".aidev/plans/brainstorm"`
- Adicionar função `flc_brainstorm_create(backlog_id, [--auto])`
- Adicionar função `flc_feature_from_brainstorm(brainstorm_id)`
- Atualizar `flc_feature_start` com gate para brainstorm/backlog
- Implementar limpeza de checkpoints JSON (máx. 5)

### Fase 4 — `bin/aidev`
- Adicionar case `brainstorm)` e `create-feature)`

### Fase 5 — Skills (paths de artefatos)
- `brainstorming/SKILL.md`: `docs/plans/` → `.aidev/plans/brainstorm/`
- `writing-plans/SKILL.md`: `docs/plans/` → `.aidev/plans/features/`

### Fase 6 — orchestrator.md
- Atualizar checklist de início de sessão (verificar current/ primeiro)
- Adicionar intents backlog_add e brainstorm

### Fase 7 — CLAUDE.md
- Atualizar Feature Lifecycle Rules com fluxo de 5 passos
- Adicionar regra "verificar current/ ao iniciar sessão"

### Fase 8 — Regras e Índice
- Atualizar `rules/generic.md`
- Criar `rules/INDEX.md` (índice leve de regras)

### Fase 9 — Ativação
- Atualizar `.activation-triggers.json` (adicionar "backlog", "brainstorm")
- Atualizar `QUICKSTART.md`

### Fase 10 — Limpeza
- Atualizar `docs/feature-lifecycle.md` (remover deprecated `aidev feature`)
- Limpar 54 checkpoints JSON em `current/checkpoints/` (manter últimos 5)

---

## Próximo Passo Exato para Retomada

Iniciar **Fase 2 — Completar renomeação**:
1. Deletar `.aidev/lib/backlog.sh`
2. Abrir `.aidev/lib/validation-pipeline.sh` e atualizar a linha `source .../backlog.sh`
3. Renomear `tests/backlog.test.sh` → `tests/error-tracker.test.sh` e atualizar source interno

Depois prosseguir para **Fase 3 — lib/feature-lifecycle.sh** (maior esforço).

---

## Decisões Tomadas

1. `aidev brainstorm` tem dois modos: interativo (padrão) e `--auto` (template automático)
2. Backlog = somente ideias brutas (sem gerenciamento de erros)
3. `lib/backlog.sh` renomeado para `lib/error-tracker.sh` (escopo claro)
4. Checkpoints JSON: máximo 5, o resto é apagado; `.md` é o checkpoint canônico
5. Skills salvam artefatos em `.aidev/plans/` (não em `docs/plans/`)
6. `aidev feature` (deprecated) será removido de `docs/feature-lifecycle.md`

---

## Contexto Necessário para Retomada (não re-ler)

- `lib/feature-lifecycle.sh` — lido, ~796 linhas, funções: `flc_plan_create`, `flc_feature_start`, `flc_sprint_done`, `flc_feature_complete`
- `lib/validation-pipeline.sh` — referencia `backlog.sh` via source (linha com `source "${BASH_SOURCE%/*}/backlog.sh"`)
- `tests/backlog.test.sh` — testa `lib/backlog.sh` diretamente
- `bin/aidev` — 43 subcomandos, adicionar `brainstorm` e `create-feature`
- `.activation-triggers.json` — estrutura conhecida, adicionar triggers
- `orchestrator.md` — checklist de sessão e classificação de intent conhecidos
