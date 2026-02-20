# Fix: AIDEV_ROOT — Fonte Única de Verdade

## Problema

Existem dois arquivos `activation_snapshot.json` gerados em locais diferentes:

| Arquivo | Quando é gerado |
|---|---|
| `.aidev/state/activation_snapshot.json` | Invocação com `AIDEV_ROOT=.aidev` explícito |
| `state/activation_snapshot.json` | Invocação sem `AIDEV_ROOT` — script deriva do `BASH_SOURCE` |

**Causa raiz**: `activation-snapshot.sh` calcula `AIDEV_ROOT` dinamicamente:
```bash
AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="$AIDEV_ROOT/state"
```
Se `AIDEV_ROOT` não está setado no ambiente, o fallback resolve para o diretório pai
do script (`.aidev/`) — mas em contextos de invocação direta ou via `source` sem prefixo,
o `BASH_SOURCE` pode resolver diferente, gerando `state/` na raiz do projeto.

## Impacto

- Dois snapshots com dados diferentes (o da raiz está desatualizado)
- Confusão sobre qual é a fonte de verdade
- Risco de o orquestrador ler o snapshot errado na inicialização

## Solução

**1. Fixar `AIDEV_ROOT` de forma robusta em `activation-snapshot.sh`:**
```bash
# Sempre derivar do script, nunca do CWD
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$_SCRIPT_DIR/.." && pwd)}"
STATE_DIR="$AIDEV_ROOT/state"
```

**2. Padronizar todas as invocações do `workflow-sync.sh`** para sempre passar `AIDEV_ROOT`:
```bash
# Correto (sempre assim):
AIDEV_ROOT=.aidev .aidev/lib/workflow-sync.sh sync true

# Nunca assim (sem prefixo):
.aidev/lib/workflow-sync.sh sync true
```

**3. Adicionar `state/` ao `.gitignore`** (na raiz do projeto) para garantir
que o artefato espúrio nunca seja commitado acidentalmente.

**4. Validar no `workflow-sync.sh validate`** que existe apenas um snapshot
e que está em `.aidev/state/`.

## Critérios de Aceite

- [ ] Apenas `.aidev/state/activation_snapshot.json` é gerado — nunca `state/` na raiz
- [ ] `aidev validate` detecta e reporta se houver snapshot fora do lugar
- [ ] `state/` na raiz adicionado ao `.gitignore`
- [ ] Todas as invocações de `workflow-sync.sh` passam `AIDEV_ROOT` explicitamente

## Estimativa

~20min — fix cirúrgico em 2-3 arquivos.

## Prioridade

**Média** — não quebra funcionalidade, mas é ruído e risco de inconsistência.
Resolver junto com ou logo após o Pré-Sprint 0 da feature `basic-memory-graceful-integration`.
