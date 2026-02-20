# Ideia: Fix checkpoint-manager — campos "unknown" em project/sprint/version

**Status:** Concluido
**Prioridade:** Baixa
**Criado:** 2026-02-20

---

## Problema

Checkpoints gerados por `ckpt_create` (via `aidev complete`, `aidev done`, `aidev start`)
apresentam campos com valor `"unknown"` nos metadados:

```yaml
project: unknown
sprint: unknown
task: none
version: 4.5.4   # versão desatualizada no momento do checkpoint
```

Exemplo observado: `ckpt-1771612914-23719.md` gerado pelo `aidev complete`.

### Causa Raiz (Análise)

O `checkpoint-manager.sh` lê os campos de contexto do `unified.json`:
- `project_name` → campo pode estar ausente ou vazio
- `sprint_context.sprint_name` → ausente quando não há sprint ativa (entre features)
- `current_task_id` → ausente quando não há task ativa
- `version` → lido do `unified.json` que pode estar desatualizado vs o `VERSION` file

**Situação que dispara:** checkpoints gerados em transições de lifecycle
(fora de uma sprint TDD ativa) não têm sprint/task no `unified.json` porque
o estado está "entre features" — o que é correto, mas o fallback para "unknown"
é pouco informativo.

**Problema secundário:** `version` é lido do `unified.json` que não é atualizado
atomicamente com o `VERSION` file durante o bump de versão.

## Objetivo

Checkpoints sempre terem metadados úteis, mesmo quando gerados fora de sprints ativas:
- `project` → sempre ter o nome real do projeto (`basename "$PWD"` como fallback)
- `sprint` → fallback descritivo: `"Entre features"` ou `"Lifecycle transition"`
- `task` → fallback descritivo: descrição passada ao `ckpt_create` como contexto
- `version` → sempre ler do `VERSION` file diretamente (fonte primária), não do `unified.json`

## Comportamento Desejado

```yaml
# Antes (problema)
project: unknown
sprint: unknown
task: none
version: 4.5.4

# Depois (correto)
project: aidev-superpowers-v3-1
sprint: lifecycle-transition
task: Feature concluida - feature-lifecycle-automation
version: 4.5.6
```

## Localização do Código

- **`lib/checkpoint-manager.sh`** — função `ckpt_create()`:
  - Campo `project_name`: adicionar fallback `$(basename "$PWD")`
  - Campo `sprint_name`: fallback `"lifecycle-transition"` quando null/empty
  - Campo `version`: ler de `VERSION` file em vez de `unified.json`
  - Campo `description`: usar o `$description` passado como arg (já existe, verificar)

- **`lib/feature-lifecycle-cli.sh`** — chamadas a `ckpt_create`:
  - Passar `description` mais descritiva incluindo o `feature_id`

## Criterios de Aceite

- [ ] `ckpt_create` nunca gera `project: unknown` — usa `basename "$PWD"` como fallback
- [ ] `ckpt_create` nunca gera `sprint: unknown` — usa fallback descritivo
- [ ] `ckpt_create` lê `version` do `VERSION` file diretamente
- [ ] Checkpoints gerados por `aidev complete/start/done` têm todos os campos preenchidos
- [ ] Testes unitários em `test-checkpoint-sync.sh` verificam fallbacks

## Dependencias

- `lib/checkpoint-manager.sh` (existente)
- `lib/feature-lifecycle-cli.sh` (existente — chamador)
- Sem dependências externas

## Estimativa Preliminar

~1 sprint de ~30min (fix cirúrgico em checkpoint-manager.sh + testes)

## Prioridade

**BAIXA** — cosmético/qualidade. Não impede fluxo nem gera dados incorretos,
apenas reduz legibilidade dos checkpoints entre features.

**Próximo passo:** Detalhar e mover para features/ quando houver oportunidade.
