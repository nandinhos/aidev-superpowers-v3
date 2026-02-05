---
name: meta-planning
description: Estrategia deliberada, priorizacao e planejamento de multiplas tarefas
triggers:
  - "planejar"
  - "estrategia"
  - "analisar pedido"
  - "priorizar"
  - "multiplas tarefas"
  - "roadmap"
  - "backlog"
globs:
  - "**/*"
---

# Meta-Planning Skill

## Proposito

Evitar execucao robotica ("Task-List Driven") e promover entendimento estrategico ("Goal Driven"). Esta skill deve ser ativada:

1. **SEMPRE** antes de qualquer implementacao complexa
2. Quando o usuario menciona **multiplas tarefas** ou features
3. Quando ha necessidade de **priorizar** trabalho
4. No inicio de um novo **sprint** ou **fase**

## Quando Usar

| Cenario | Ativar Meta-Planning? |
|---------|----------------------|
| Usuario pede uma feature simples | Nao (ir direto para brainstorming) |
| Usuario pede multiplas features | **Sim** |
| Usuario menciona "priorizar" ou "roadmap" | **Sim** |
| Inicio de projeto/sprint | **Sim** |
| Bug report simples | Nao (ir para systematic-debugging) |
| Refatoracao ampla | **Sim** |

## Processo (4 Steps)

### Step 1: DECONSTRUCT (Decompor)
**Checkpoint**: `deconstruct_complete`

Quebre o pedido do usuario em componentes:

```markdown
## Decomposicao do Pedido

### Objetivos Explicitos
- [ ] O que o usuario pediu diretamente
- [ ] Features mencionadas
- [ ] Requisitos especificos

### Objetivos Implicitos
- [ ] O que o usuario espera mas nao disse
- [ ] Qualidade esperada (testes, docs)
- [ ] Padroes a seguir

### Restricoes
- [ ] Tempo disponivel
- [ ] Tecnologias obrigatorias
- [ ] Limitacoes conhecidas
```

**Perguntas Clarificadoras** (se necessario):
- Qual a prioridade relativa entre as tarefas?
- Ha dependencias entre elas?
- Qual o prazo esperado?

### Step 2: CONTEXTUALIZE (Contextualizar)
**Checkpoint**: `contextualize_complete`

Relacione com o conhecimento existente:

```markdown
## Contextualizacao

### Licoes Aprendidas Relevantes
<!-- Consultar .aidev/state/lessons/ -->
- Licao 1: [resumo]
- Licao 2: [resumo]

### Arquitetura Atual
- Stack: generic
- Patterns em uso: [listar]
- Areas de risco: [identificar]

### Codigo Relacionado
- Arquivos que serao impactados: [listar]
- Testes existentes: [verificar cobertura]
```

**Integracao com Basic-Memory**:
```bash
# Buscar licoes similares
memory_search "contexto do pedido"
memory_get_similar "descricao da tarefa"
```

### Step 3: STRATEGIZE (Estrategizar)
**Checkpoint**: `strategize_complete`

Defina a abordagem antes de executar:

```markdown
## Estrategia

### Abordagem Escolhida
[Descrever a estrategia geral]

### Alternativas Consideradas
1. Alternativa A: [pros/cons]
2. Alternativa B: [pros/cons]
3. **Escolhida**: [justificativa]

### Trade-offs Aceitos
- [Trade-off 1]
- [Trade-off 2]

### Riscos Identificados
| Risco | Probabilidade | Impacto | Mitigacao |
|-------|---------------|---------|-----------|
| ... | Alta/Media/Baixa | Alto/Medio/Baixo | ... |
```

### Step 4: PLAN (Planejar)
**Checkpoint**: `plan_complete`

Gere a lista de tarefas priorizadas:

```markdown
## Roadmap de Implementacao

### Matriz de Priorizacao (Impacto x Esforco)

        Alto Impacto
             |
    [FAZER]  |  [PLANEJAR]
    PRIMEIRO |  COM CUIDADO
             |
 ----------------------------- Esforco
             |
    [QUICK]  |  [EVITAR OU]
    [WINS]   |  [DELEGAR]
             |
        Baixo Impacto

### Tarefas Priorizadas

#### P1 - Critico (Fazer Primeiro)
- [ ] Tarefa 1 (Impacto: Alto, Esforco: Baixo)
- [ ] Tarefa 2 (Impacto: Alto, Esforco: Medio)

#### P2 - Importante (Fazer em Seguida)
- [ ] Tarefa 3 (Impacto: Medio, Esforco: Baixo)
- [ ] Tarefa 4 (Impacto: Alto, Esforco: Alto)

#### P3 - Desejavel (Se Houver Tempo)
- [ ] Tarefa 5 (Impacto: Baixo, Esforco: Baixo)

### Dependencias entre Tarefas

```
Tarefa 1 ──► Tarefa 2 ──► Tarefa 4
                │
                ▼
            Tarefa 3
```

### Estimativa por Sprint/Fase
| Sprint | Tarefas | Objetivo |
|--------|---------|----------|
| Sprint 1 | T1, T2 | MVP funcional |
| Sprint 2 | T3, T4 | Feature completa |
| Sprint 3 | T5 | Polish |
```

## Checkpoints de Validacao

```bash
# Registrar inicio da skill
skill_init "meta-planning"
skill_set_steps "meta-planning" 4

# Step 1: Deconstruct
skill_advance "meta-planning" "DECONSTRUCT: Decompor pedido"
# ... executar decomposicao ...
skill_validate_checkpoint "meta-planning"

# Step 2: Contextualize
skill_advance "meta-planning" "CONTEXTUALIZE: Relacionar com contexto"
# ... executar contextualizacao ...
skill_validate_checkpoint "meta-planning"

# Step 3: Strategize
skill_advance "meta-planning" "STRATEGIZE: Definir abordagem"
# ... executar estrategia ...
skill_validate_checkpoint "meta-planning"

# Step 4: Plan
skill_advance "meta-planning" "PLAN: Gerar roadmap"
# ... gerar plano ...
skill_add_artifact "meta-planning" "docs/plans/YYYY-MM-DD-roadmap.md" "roadmap"
skill_validate_checkpoint "meta-planning"

# Finalizar
skill_complete "meta-planning"
```

## Transicoes para Outras Skills

Apos concluir meta-planning, transicionar baseado no tipo de tarefa:

| Tipo de Tarefa | Proxima Skill | Agente |
|----------------|---------------|--------|
| Nova Feature | `brainstorming` | Architect |
| Bug Fix | `systematic-debugging` | QA |
| Refatoracao | `writing-plans` | Architect |
| Multiplas Features | Loop: `brainstorming` para cada | Architect |

```bash
# Exemplo de transicao
agent_handoff "orchestrator" "architect" "Iniciar brainstorming para Feature 1" "docs/plans/roadmap.md"
```

## Output Esperado

### Artefato Principal
`docs/plans/YYYY-MM-DD-<projeto>-roadmap.md`

### Estrutura do Artefato
```markdown
# Roadmap: [Nome do Projeto/Iniciativa]

## Resumo Executivo
[1-2 paragrafos]

## Objetivos
- Explicito 1
- Explicito 2
- Implicito 1

## Estrategia
[Abordagem escolhida e justificativa]

## Roadmap
### Fase 1: [Nome]
- [ ] Tarefa 1.1
- [ ] Tarefa 1.2

### Fase 2: [Nome]
- [ ] Tarefa 2.1

## Riscos e Mitigacoes
[Tabela de riscos]

## Proximos Passos
1. Iniciar brainstorming para Tarefa 1.1
2. ...
```

## Principios

1. **Pensar antes de agir** - Nunca comece a codar sem estrategia
2. **Priorizar por valor** - Impacto > Esforco
3. **Identificar dependencias** - Evitar bloqueios
4. **Documentar decisoes** - Para referencia futura
5. **Validar com usuario** - Antes de prosseguir

## Anti-Patterns a Evitar

- ❌ Pular direto para implementacao
- ❌ Aceitar todas as tarefas sem priorizar
- ❌ Ignorar dependencias entre tarefas
- ❌ Nao consultar licoes aprendidas
- ❌ Planejar sem validar com usuario


## Stack: generic
Considere patterns e convencoes especificas da stack ao planejar.