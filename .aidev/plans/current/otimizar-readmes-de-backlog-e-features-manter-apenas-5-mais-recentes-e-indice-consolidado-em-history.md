# Feature: Otimizar READMEs de backlog/ e features/

**Status:** Backlog
**Prioridade:** Média
**Criado:** 2026-02-20

## Problema

Os READMEs de `backlog/` e `features/` acumulam tabelas de "Ideias Concluídas/Removidas"
e "Features Concluídas" indefinidamente. Em projetos longos isso gera custo
desnecessário de contexto a cada leitura.

`history/` já contém os arquivos reais — manter histórico duplicado nos READMEs
de transição é redundante.

## Objetivo

- `backlog/README.md`: manter apenas as 5 ideias concluídas/removidas mais recentes
- `features/README.md`: manter apenas as 5 features concluídas mais recentes
- `history/README.md`: índice consolidado e atualizado com todos os itens concluídos,
  organizado por mês (já existe estrutura `history/YYYY-MM/`)

## Implementação Sugerida

### Em `flc_feature_complete()` (lib/feature-lifecycle-cli.sh)

Ao atualizar `features/README.md` seção "Concluídas":
1. Adicionar nova entrada
2. Contar linhas da tabela — se > 5, remover a mais antiga

### Em `flc_plan_create()` ao remover do backlog:

Mesma lógica — limitar seção "Concluídas/Removidas" a 5 entradas.

### `history/README.md` — índice consolidado

Função `_flc_history_index_rebuild()` que:
1. Varre `history/YYYY-MM/*.md`
2. Extrai título e data de cada arquivo
3. Reconstrói tabela completa ordenada por data desc

Chamada automaticamente em `flc_feature_complete()` e `_flc_roadmap_rebuild()`.

## Arquivos a Modificar

| Arquivo | Mudança |
|---|---|
| `lib/feature-lifecycle-cli.sh` | Limitar seções "Concluídas" a 5 entradas + índice history/ |
| `_flc_update_features_readme_complete()` | Adicionar truncagem após inserção |
| `_flc_update_backlog_readme_complete()` | Idem |
| `_flc_roadmap_rebuild()` ou novo `_flc_history_index_rebuild()` | Gerar índice em history/ |

## Critérios de Aceite

- [ ] `backlog/README.md` nunca tem mais de 5 entradas na seção "Concluídas"
- [ ] `features/README.md` nunca tem mais de 5 entradas na seção "Concluídas"
- [ ] `history/README.md` tem índice completo e atualizado de todos os itens
- [ ] Testes unitários cobrem truncagem e reconstrução do índice
