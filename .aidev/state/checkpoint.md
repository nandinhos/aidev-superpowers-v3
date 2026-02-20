# Checkpoint - 2026-02-20

## Status Geral

- Projeto: aidev-superpowers-v3-1
- Versao: v4.5.2
- Branch: main
- Suite de testes: 24 passed, 1 fail pre-existente (ckpt_sync_to_basic_memory — resolvido no Sprint 3)

---

## Sessao Atual — O que foi feito

### Refinamento do Plano: basic-memory-graceful-integration

Sessao dedicada a **estruturar e refinar o planejamento** da feature de integracao graceful
do Basic Memory. Nenhum codigo foi implementado — apenas planejamento e correcao de premissas.

#### Descobertas da exploracao

| Componente | Premissa original | Realidade descoberta |
|---|---|---|
| `checkpoint-manager.sh` | "em `.aidev/lib/`" | Em `lib/` (raiz, 491 linhas) + `~/.aidev-superpowers/lib/` |
| `cmd_status` / `cmd_doctor` | "atualizar" | NAO EXISTEM — precisam ser criados do zero |
| Guards do Sprint 2 | "so bash" | Duas camadas: bash (.sh) + instrucoes LLM (.md) |
| Deteccao via `type mcp__*` | abordagem principal | So funciona no Claude Code — invalido para outros runtimes |
| `.aidev/lib/` no self-upgrade | incluida | NAO incluida — lacuna critica descoberta |

#### Novo Pré-Sprint 0 adicionado

**Problema critico**: `.aidev/lib/` nao e sincronizada pelo self-upgrade nem pelo `aidev upgrade`.
Qualquer arquivo novo em `.aidev/lib/` existe so no projeto-fonte. Evidencia imediata:
`~/.aidev-superpowers/.aidev/lib/` esta desatualizado — faltam `activation-snapshot.sh`,
`workflow-commit.sh`, `workflow-release.sh`, `workflow-sync.sh`.

**Solucao**: Criar `install_aidev_lib()` em `bin/aidev` e integrar no self-upgrade,
`create_base_structure()` e `cmd_upgrade()`.

#### Multi-runtime esclarecido

O usuario usa 5 runtimes: Claude Code CLI, Antigravity (Claude), Antigravity (Gemini),
Gemini CLI, OpenCode. O Sprint 1 precisa de deteccao multi-camada:
1. Variavel de ambiente explicita (`BASIC_MEMORY_ENABLED`, `MCP_BASIC_MEMORY_AVAILABLE`)
2. Presenca em `.mcp.json` + mapa de capacidades por runtime
3. CLI como fallback (`command -v basic-memory`)

#### Fluxo aidev self-upgrade clarificado

O projeto `aidev-superpowers-v3-1` e o **projeto-fonte** do framework. O usuario
desenvolve aqui, faz self-upgrade para `~/.aidev-superpowers/`, publica no GitHub,
e os projetos recebem upgrade automatico com sugestao no primeiro comando.

---

## Feature em Execucao (current/)

**Arquivo**: `.aidev/plans/current/basic-memory-graceful-integration.md`

| Sprint | Objetivo | Status |
|--------|----------|--------|
| Pré-Sprint 0 | Pipeline de distribuicao — `install_aidev_lib()` | **PROXIMO** |
| Sprint 1 | `mcp-detect.sh` — deteccao multi-runtime | pendente |
| Sprint 2 | `basic-memory-guard.sh` — wrappers bash + .md LLM | pendente |
| Sprint 3 | `ckpt_sync_to_basic_memory()` em checkpoint-manager | pendente |
| Sprint 4 | `context_compressor_generate()` enriquecido | pendente |
| Sprint 5 | `cmd_status`, `cmd_doctor`, QUICKSTART | pendente |

**Estimativa total**: ~305min (~5h05)

---

## Proximo Passo EXATO para Retomar

1. Dizer "modo agente" para ativar o orquestrador
2. Iniciar **Pre-Sprint 0**: adicionar `install_aidev_lib()` em `bin/aidev`
   - Funcao que copia todos os `.sh` de `.aidev/lib/` para o projeto destino
   - Integrar em `create_base_structure()` (substituir if manual do feature-lifecycle)
   - Integrar em `cmd_upgrade()` (junto com install_agents/skills/rules)
   - Adicionar rsync `.aidev/lib/` no self-upgrade (apos rsync `lib/`)
   - Atualizar dry-run para listar os arquivos
3. Rodar testes: `bash tests/test-runner.sh`
4. Commit + push + self-upgrade para validar que `.aidev/lib/` chega no global

---

## Analise do Fluxo de Plans (problema identificado e corrigido)

**Problema observado**: A feature foi criada diretamente em `backlog/` e nunca passou
por `features/` (planejamento) nem por `current/` (execucao). Isso viola o fluxo:

```
backlog/ → features/ → current/ → history/YYYY-MM/
```

**Correcao aplicada nesta sessao**:
- Feature copiada para `current/basic-memory-graceful-integration.md` ← em execucao
- `backlog/basic-memory-graceful-integration.md` ← permanece como referencia ate conclusao
- Ao concluir todos os sprints: mover para `history/2026-02/` e remover do backlog

**Causa raiz**: O `feature_cli` ou o orquestrador nao esta fazendo a transicao automatica
backlog → features → current. Isso e um gap a documentar para correcao futura.

---

## Contexto Tecnico Util

### Estrutura das instalacoes

```
aidev-superpowers-v3-1/    ← projeto-fonte (desenvolvimento)
    lib/                   ← modulos CLI (distribuidos via rsync no self-upgrade)
    .aidev/lib/            ← modulos runtime do orquestrador (GAP: nao distribuidos ainda)
    bin/aidev              ← binario principal

~/.aidev-superpowers/      ← instalacao global ativa (v4.5.1, desatualizada)
    lib/                   ← copia de lib/ do projeto-fonte
    .aidev/lib/            ← DESATUALIZADO — faltam 4 arquivos vs projeto-fonte
    bin/aidev              ← binario ativo (via symlink ~/.local/bin/aidev)
```

### Arquivos ausentes no global vs projeto-fonte

```bash
# Faltam em ~/.aidev-superpowers/.aidev/lib/:
activation-snapshot.sh
workflow-commit.sh
workflow-release.sh
workflow-sync.sh
```

### Padroes de leitura de VERSION

- Scripts em `.aidev/lib/`: `$AIDEV_ROOT/../VERSION`
- Scripts em `lib/` (CLI): `$AIDEV_ROOT/VERSION`

### Comandos uteis

```bash
# Validar sistema
AIDEV_ROOT=.aidev .aidev/lib/workflow-sync.sh validate

# Rodar suite de testes
bash tests/test-runner.sh

# Ver versao atual
cat VERSION

# Self-upgrade (apos Pre-Sprint 0 implementado)
aidev self-upgrade
```
