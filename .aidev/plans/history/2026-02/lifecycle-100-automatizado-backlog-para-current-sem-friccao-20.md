# Feature: lifecycle 100% automatizado - backlog para current sem fricção

**Status:** Concluido
**Prioridade:** Alta
**Criado:** 2026-02-20
**Concluido:** 2026-02-20

## Objetivo

Eliminar fricção no lifecycle de features. Antes era necessário mover arquivos
manualmente de backlog/ para features/ antes de executar `aidev start`.

## Problema

`aidev start <id>` falhava com erro "Feature nao encontrada em features/" quando
o arquivo estava em backlog/, obrigando passo manual de git mv.

## Solução Implementada

1. `flc_feature_start()` em lib/feature-lifecycle-cli.sh agora busca em backlog/
   como fallback quando não encontra em features/, promovendo automaticamente.
2. Corrigido cabeçalho duplicado na tabela de sprints do current/README.md.

## Sprints

| Sprint | Objetivo | Status |
|---|---|---|
| Sprint 1 | Implementar fallback backlog em flc_feature_start | Concluida (2026-02-20) |
| Sprint 2 | Corrigir regex sprints no current/README.md | Concluida (2026-02-20) |

## Resultado

- 3 novos testes RED→GREEN
- Suite lifecycle completa: 38/38 PASS
- Fluxo: `aidev plan` → `aidev start` (busca backlog automaticamente) → `aidev done` → `aidev complete`
