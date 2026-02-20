# Fix: Versão Hardcoded e MCP Merge em aidev upgrade

> **Status:** Em execução
> **Prioridade:** Alta
> **Sprint:** v4.5.2
> **Data criação:** 2026-02-19

## Contexto e Problema

Relatório técnico em `backlog/relatorio_outro_projeto.md` identificou que o `aidev upgrade --force`
sobrescrevia o `.mcp.json` perdendo customizações (ex: servidor `laravel-boost` com Docker Sail).

Análise expandida revelou 3 bugs encadeados, todos com a mesma causa raiz: scripts em `.aidev/lib/`
são executados pelo LLM sem o CLI externo carregado, então `AIDEV_VERSION` nunca é populada.

## Bugs

| # | Prioridade | Arquivo | Problema |
|---|---|---|---|
| 1 | ALTA | `.aidev/lib/activation-snapshot.sh`, `lib/activation-snapshot.sh`, `*workflow-sync.sh` | `${AIDEV_VERSION:-4.4.2}` hardcoded — versão errada nos snapshots |
| 2 | MÉDIA | `lib/mcp.sh` | `.mcp.json` sobrescrito integralmente em `--force` sem merge de custom servers |
| 3 | BAIXA | `lib/migration.sh` | `migration_stamp()` grava `0.0.0` quando `AIDEV_VERSION` ausente |

## Escopo de Arquivos

- `.aidev/lib/activation-snapshot.sh` — 3 pontos (linhas 177, 200, 228)
- `lib/activation-snapshot.sh` — 3 pontos (linhas 177, 200, 228)
- `.aidev/lib/workflow-sync.sh` — 1 ponto (linha 96)
- `lib/workflow-sync.sh` — 1 ponto (linha 96)
- `lib/migration.sh` — 2 pontos (linhas 57, 146)
- `lib/mcp.sh` — nova função `_mcp_extract_custom_servers` + lógica de merge

## Critérios de Aceitação

- [ ] `env -i bash .aidev/lib/activation-snapshot.sh | jq '.version'` retorna `4.5.2`
- [ ] `env -i bash .aidev/lib/activation-snapshot.sh | jq '.framework_version'` retorna `4.5.2`
- [ ] `aidev upgrade --force` em projeto com custom MCP server preserva o servidor
- [ ] `MANIFEST.local.json.project_version` reflete versão correta após upgrade sem CLI
- [ ] Suite de testes não regride: `bash tests/test-runner.sh`

## Release

Bump para `v4.5.2` (patch) após implementação.
