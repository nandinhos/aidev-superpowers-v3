# Sprint 4: UX Intuitiva

**Status**: PENDENTE
**Prioridade**: MEDIA
**Dependencia**: Sprint 1 completo
**Versao**: v3.2.0

## Objetivo

Tornar a ferramenta mais intuitiva e visual.

## Tarefas

### 4.1 Smart Suggestion Mode
**Arquivo**: `lib/suggest.sh` (NOVO)

Criar:
- [ ] analyze_project_state() - Analisa estado atual
- [ ] get_recommendations() - Gera recomendacoes
- [ ] format_suggestions() - Formata output
- [ ] Integracao com basic-memory
- [ ] Integracao com git status

Output exemplo:
"Detectei brownfield com tests failing. Recomendo: systematic-debugging"

**NOTA**: Funcionalidade basica ja implementada em `cmd_suggest()` no bin/aidev.
Este sprint expande com modulo dedicado e mais inteligencia.

### 4.2 Dashboard Visual
**Arquivo**: `lib/dashboard.sh` (NOVO)

Criar:
- [ ] render_header() - Nome do projeto, stack
- [ ] render_progress() - Fase, Sprint atual
- [ ] render_active_skill() - Skill ativa com checkpoints
- [ ] render_next_steps() - Proximos passos sugeridos
- [ ] Cores e formatacao terminal

Output exemplo:
```
┌─ PROJETO: my-app (nextjs)
├─ FASE: 3/4 | SPRINT: 4
├─ SKILL ATIVA: brainstorming (2/4)
│  └─ Checkpoint 1: ok | Checkpoint 2: em progresso
└─ PROXIMO: architect
```

### 4.3 Help Contextual
**Arquivo**: `lib/help.sh` (expandir)

Adicionar:
- [ ] help_agents() - Lista agentes com descricao
- [ ] help_skills() - Lista skills com quando usar
- [ ] help_flow(type) - Mostra fluxo por tipo
  - feature-flow
  - bug-flow
  - refactor-flow
- [ ] help_commands() - Lista comandos disponiveis

Novos comandos:
- [ ] `aidev help agents`
- [ ] `aidev help skills`
- [ ] `aidev help feature-flow`
- [ ] `aidev help bug-flow`

## Verificacao

- [ ] `aidev suggest` com inteligencia expandida
- [ ] `aidev status --dashboard` renderizando
- [ ] `aidev help agents/skills/flow` respondendo
- [ ] Output visual agradavel

## Arquivos a Modificar

| Arquivo | Acao |
|---------|------|
| lib/suggest.sh | CRIAR |
| lib/dashboard.sh | CRIAR |
| lib/help.sh | EDITAR |
| bin/aidev | EDITAR |

## Notas

- Dashboard deve funcionar em terminais com e sem suporte a Unicode
- Cores devem respeitar a variavel NO_COLOR
- Help contextual deve ser conciso mas informativo
