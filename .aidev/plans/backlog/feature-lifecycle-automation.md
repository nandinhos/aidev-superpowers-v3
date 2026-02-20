# Ideia: Automação do Ciclo de Vida de Features

## Problema

O fluxo `backlog → features → current → history` existe documentado em `plans/README.md`,
mas **não está operacionalizado**. As transições dependem de ação manual e disciplina do
orquestrador — sem gatilhos explícitos, etapas são puladas (como ocorreu com a feature
`basic-memory-graceful-integration`, que foi criada direto no backlog e nunca passou por
`features/` nem por `current/` até ser corrigido manualmente).

## Objetivo

Tornar o fluxo de ciclo de vida de features **totalmente automático e supervisionado**:
a cada transição, status, conclusão de task/sprint/milestone — o sistema atualiza os
arquivos de gerenciamento sozinho, sem depender de memória ou disciplina do operador.

## Comportamento Desejado

### Comandos a implementar

| Comando | Ação | Transição |
|---|---|---|
| `aidev plan "titulo"` | Cria arquivo em `backlog/` com template | — → backlog |
| `aidev feature "id"` | Move backlog → features/, cria plano detalhado | backlog → features |
| `aidev start "id"` | Move features/ → current/, abre sprint, atualiza checkpoint | features → current |
| `aidev done "sprint"` | Marca sprint concluída, atualiza current/README, checkpoint | current (sprint concluída) |
| `aidev complete "id"` | Move current/ → history/YYYY-MM/, fecha feature, release notes | current → history |

### Atualizações automáticas a cada transição

- `current/README.md` — tabela de sprints atualizada (status, progresso)
- `features/README.md` — movida para "Em Execução" / "Concluídas"
- `backlog/README.md` — removida da lista de pendentes
- `.aidev/state/checkpoint.md` — estado real da sessão
- `.aidev/state/activation_snapshot.json` — sincronizado
- `ROADMAP.md` — sprint/feature marcada no roadmap
- `unified.json` — tasks e sprint atualizados

### Atualizações automáticas a cada conclusão de task/sprint

- Checkpoint atualizado com o que foi feito e próximo passo exato
- Snapshot regenerado
- Commit automático com mensagem padronizada: `chore(state): conclui sprint X de feature Y`

## Arquitetura Proposta

```
bin/aidev
├── cmd_plan()      → cria backlog/YYYY-MM-titulo.md com template
├── cmd_feature()   → move backlog → features/, valida plano completo
├── cmd_start()     → move features/ → current/, inicia sprint tracking
├── cmd_done()      → fecha sprint, atualiza todos os arquivos
└── cmd_complete()  → fecha feature, move para history/, sugere release

lib/feature-lifecycle.sh  ← já existe, expandir
├── feature_transition()  → função central de transição com validação
├── feature_update_readmes() → atualiza todos os READMEs afetados
└── feature_auto_checkpoint() → checkpoint + snapshot automático
```

## Regras de Negócio

1. **Máximo 1 feature em `current/`** — `cmd_start` bloqueia se já houver uma ativa
2. **Transições validadas** — não é possível pular etapas (backlog → current direto = erro)
3. **Checkpoint obrigatório** — toda transição gera checkpoint automático
4. **Commit automático** — toda transição faz commit padronizado (supervisionado: exibe e pede confirmação)
5. **README sempre atualizado** — qualquer mudança de status reflete imediatamente nos READMEs

## Critérios de Aceite

- [ ] `aidev plan "titulo"` cria arquivo em backlog/ com template padrão
- [ ] `aidev feature "id"` move para features/ e valida que plano está completo
- [ ] `aidev start "id"` bloqueia se já houver feature em current/
- [ ] `aidev start "id"` atualiza current/README com tabela de sprints
- [ ] `aidev done "sprint"` atualiza status na tabela do current/README
- [ ] `aidev complete "id"` move para history/YYYY-MM/ e limpa current/
- [ ] Todos os READMEs afetados são atualizados automaticamente em cada transição
- [ ] Checkpoint gerado automaticamente a cada transição
- [ ] Commit padronizado sugerido (com confirmação) a cada transição
- [ ] Fluxo funciona a partir do modo agente (orquestrador chama os comandos)

## Motivação

> "Sempre a cada término de task, sprint, milestone, AUTOMATICAMENTE deve-se atualizar
> os status e os arquivos de gerenciamento. Isso é o melhor dos mundos para mim!"

Este é o comportamento padrão e único de se trabalhar — não uma opção.

## Dependências

- `lib/feature-lifecycle.sh` (já existe — expandir)
- `cmd_upgrade()` e `create_base_structure()` (Pré-Sprint 0 da feature atual)
- Nenhuma dependência externa

## Estimativa Preliminar

~4 sprints de ~45min cada (~3h):
- Sprint 1: `cmd_plan` + `cmd_feature` + templates
- Sprint 2: `cmd_start` + tracking de sprints em `current/`
- Sprint 3: `cmd_done` + atualizações automáticas de READMEs + checkpoint
- Sprint 4: `cmd_complete` + history + integração com orquestrador

## Prioridade

**ALTA** — é a fundação do fluxo de desenvolvimento. Sem isso, toda organização
depende de disciplina manual e é frágil.

**Próximo passo:** Priorizar após conclusão da feature `basic-memory-graceful-integration`.
