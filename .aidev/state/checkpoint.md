# Checkpoint - 2026-02-20

## Status Geral

- Projeto: aidev-superpowers-v3-1
- Versao: v4.5.2 (tag publicada no GitHub)
- Branch: main (sincronizado com origin)
- Suite de testes: 24 passed, 1 fail pre-existente (ckpt_sync_to_basic_memory)

---

## Sessao Atual — O que foi feito

### Fix v4.5.2 (concluido e publicado)

Tres bugs corrigidos originados de relatorio do projeto check-print:

| Bug | Arquivos | Fix |
|-----|----------|-----|
| Versao hardcoded `4.4.2` em `.aidev/lib/` | activation-snapshot.sh (x2), workflow-sync.sh (x2) | Le `$AIDEV_ROOT/../VERSION` antes do fallback |
| JSON hardcoded `"version": "4.5.0"` no snapshot | activation-snapshot.sh linha 228 | Usa variavel `$framework_version` |
| `migration_stamp` gravava `0.0.0` sem CLI | lib/migration.sh (linhas 57 e 146) | Mesmo padrao: le VERSION antes do fallback |
| `.mcp.json` sobrescrito em `--force` | lib/mcp.sh | Nova funcao `_mcp_extract_custom_servers` + merge via jq |

Commits desta sessao:
- `39d8d47` fix(lib): le versao do arquivo VERSION antes do fallback hardcoded
- `6855a43` fix(mcp): preserva servidores customizados ao sobrescrever .mcp.json com --force
- `def96f3` chore(session): conclui feature fix-version-hardcoded-mcp-merge
- `925adb2` chore(state): sincroniza estado apos conclusao de feature
- `d083b1a` release(patch): bump versao para v4.5.2
- `7d2906d` chore(backlog): organiza backlog removendo itens concluidos e fora de escopo

### Organizacao do Backlog (concluido)

Movidos para `history/2026-02/` via `feature_cli complete`:
- `refinamento-framework-v4.4` — 5 sprints todos implementados (manifest, upgrade-safety, llm-guard, testes+bugfixes, migration)
- `sistema-atualizacao-interativa` — version_check_prompt + upgrade_project_if_needed implementados

Removidos do backlog:
- `relatorio_outro_projeto.md` — evidencia consumida (bugs resolvidos na v4.5.2)
- `mcp-universal-install.md` — fora de escopo (era para o projeto check-print/Laravel)

---

## Estado Atual do Backlog

```
.aidev/plans/backlog/
├── README.md
└── basic-memory-graceful-integration.md   ← UNICO ITEM PENDENTE
```

---

## Proximo Passo — basic-memory-graceful-integration.md

Feature completa com 5 sprints (~3h45 estimados). Pré-requisitos em ordem:

| Sprint | Objetivo | Dependencia |
|--------|----------|-------------|
| 1 | `lib/mcp-detect.sh` — deteccao unificada de MCPs | nenhuma |
| 2 | `lib/basic-memory-guard.sh` — wrappers com fallback local | Sprint 1 |
| 3 | `ckpt_sync_to_basic_memory()` em checkpoint-manager.sh | Sprint 2 |
| 4 | Contexto inteligente na ativacao (context-compressor.sh) | Sprint 2 |
| 5 | Dashboard + docs (cmd_status, cmd_doctor, QUICKSTART) | Sprints 3+4 |

**Para retomar:** dizer "modo agente" ou "iniciar basic-memory integration".
O Sprint 1 e o desbloqueador — arquivo `lib/mcp-detect.sh` ainda nao existe.

**Teste com falha ativa:** `ckpt_sync_to_basic_memory nao existe` — resolvido pelo Sprint 3.

---

## Contexto Tecnico Util para Proxima Sessao

### Padroes de leitura de VERSION

- Scripts em `.aidev/lib/`: `$AIDEV_ROOT/../VERSION`
- Scripts em `lib/` (CLI): `$AIDEV_ROOT/VERSION`
- `lib/migration.sh`: `$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../VERSION`

### Ciclo de desenvolvimento do aidev

```
backlog/  →  features/ (criar com feature_cli)
          →  implementar (TDD quando aplicavel)
          →  feature_cli complete "id" "notas"   → history/YYYY-MM/
          →  release patch/minor/major
          →  workflow-sync.sh sync true
```

### Comandos uteis de verificacao

```bash
# Validar sistema
AIDEV_ROOT=.aidev .aidev/lib/workflow-sync.sh validate

# Rodar suite de testes
bash tests/test-runner.sh

# Gerar snapshot atualizado
AIDEV_ROOT=.aidev .aidev/lib/activation-snapshot.sh

# Ver versao atual
cat VERSION
```
