---
name: writing-plans
description: Cria planos de implementacao detalhados com tarefas de 2-5 minutos
triggers:
  - "criar plano"
  - "planejar implementacao"
  - "quebrar em tarefas"
  - "implementation plan"
globs:
  - "docs/plans/*-implementation.md"
steps: 4
checkpoints:
  - prerequisites_verified
  - tasks_defined
  - plan_documented
  - plan_approved
artifact: "docs/plans/YYYY-MM-DD-<topic>-implementation.md"
previous_skill: brainstorming
next_skill: test-driven-development
---

# Writing Plans Skill

## Metadata
- **Total de Steps**: 4
- **Tempo Estimado**: 20-40 minutos
- **Prerequisito**: Design aprovado (skill: brainstorming)
- **Artefato Final**: `docs/plans/YYYY-MM-DD-<topic>-implementation.md`
- **Proxima Skill**: `test-driven-development`

## Quando Usar
Apos aprovacao do design, antes de iniciar implementacao.

## Proposito
Quebrar o trabalho em tarefas que um "desenvolvedor junior entusiasmado, sem contexto e avesso a testes" consiga seguir sem errar.

## Principio-Chave
> Cada tarefa deve ter no maximo 2-5 minutos de trabalho focado.
> Se leva mais que isso, quebre em tarefas menores.

---

## Step 1: Verificar Prerequisitos
**Checkpoint**: `prerequisites_verified`

### Acoes
Antes de criar o plano, verificar:

```bash
validation_check "file_exists" "docs/plans/*-design.md"
validation_check "tests_pass"
```

### Checklist
- [ ] Design aprovado e documentado
- [ ] Dependencias identificadas e instaladas
- [ ] Baseline de testes limpa (todos passando)
- [ ] Branch de feature criada (se aplicavel)

### Criterios de Validacao
- [ ] Documento de design existe
- [ ] Nenhum teste falhando
- [ ] Ambiente de desenvolvimento funcional

---

## Step 2: Definir Tarefas
**Checkpoint**: `tasks_defined`

### Acoes
Para cada funcionalidade do design:

1. Identificar a menor unidade implementavel
2. Definir o teste que sera escrito PRIMEIRO
3. Definir o codigo minimo para passar o teste
4. Definir comando de verificacao
5. Definir mensagem de commit

### Formato de Cada Tarefa

```markdown
### Task N: [Descricao Breve]

**Arquivos:**
- `path/to/file.ext`

**Teste (escrever PRIMEIRO):**
```language
// Codigo do teste que deve falhar inicialmente
```

**Implementacao:**
```language
// Codigo minimo para fazer o teste passar
```

**Verificacao:**
```bash
npm test -- path/to/test.spec.js
```

**Resultado Esperado:**
Teste passa

**Commit:**
```
type(scope): descricao breve

- Adicionado teste para [feature]
- Implementado [feature] minimo
```
```

### Regras para Tarefas
- **Atomica**: Uma tarefa = uma mudanca completa
- **Testavel**: Sempre comeca com teste
- **Pequena**: 2-5 minutos no maximo
- **Independente**: Pode ser feita isoladamente (quando possivel)

### Criterios de Validacao
- [ ] Todas as funcionalidades do design tem tarefas
- [ ] Cada tarefa tem teste definido
- [ ] Cada tarefa tem tempo estimado <= 5 min
- [ ] Ordem de execucao faz sentido

---

## Step 3: Documentar Plano
**Checkpoint**: `plan_documented`

### Acoes
Criar documento em: `docs/plans/YYYY-MM-DD-<topic>-implementation.md`

### Template do Plano

```markdown
# [Nome da Feature] - Plano de Implementacao

**Data**: YYYY-MM-DD
**Design**: [link para documento de design]
**Autor**: AI Dev Superpowers
**Status**: Aguardando aprovacao

## Prerequisitos

- [ ] Design aprovado: `docs/plans/YYYY-MM-DD-<topic>-design.md`
- [ ] Dependencias instaladas
- [ ] Baseline de testes limpa
- [ ] Branch criada: `feature/<nome>`

## Tarefas

### Task 1: [Descricao]
[Detalhes conforme formato acima]

### Task 2: [Descricao]
[Detalhes conforme formato acima]

### Task 3: [Descricao]
[Detalhes conforme formato acima]

[... continuar para todas as tarefas]

## Criterios de Sucesso

- [ ] Todos os testes passando
- [ ] Cobertura >= 80%
- [ ] Code review aprovado
- [ ] Documentacao atualizada

## Estimativa Total

| Metrica | Valor |
|---------|-------|
| Total de tarefas | N |
| Tempo estimado | N x 5 min = X min |
| Complexidade | baixa/media/alta |

## Riscos Identificados

| Risco | Mitigacao |
|-------|-----------|
| ... | ... |

## Notas

[Observacoes adicionais]
```

### Criterios de Validacao
- [ ] Documento salvo no path correto
- [ ] Todas as secoes preenchidas
- [ ] Tarefas numeradas sequencialmente
- [ ] Estimativas realistas

---

## Step 4: Aprovar Plano
**Checkpoint**: `plan_approved`

### Acoes
1. Apresentar plano ao usuario
2. Revisar cada tarefa
3. Ajustar conforme feedback
4. Obter aprovacao explicita

### Perguntas de Revisao
- As tarefas estao pequenas o suficiente?
- A ordem de execucao faz sentido?
- Alguma dependencia foi esquecida?
- Os testes cobrem todos os casos?

### Criterios de Validacao
- [ ] Usuario revisou o plano
- [ ] Ajustes solicitados foram feitos
- [ ] Aprovacao explicita obtida
- [ ] Status atualizado para "Aprovado"

---

## Principios Enfatizados

### TDD Obrigatorio
Cada tarefa DEVE comecar com teste. Sem excecoes.

### YAGNI
Nao inclua tarefas para features "que podem ser uteis depois".

### DRY
Se perceber duplicacao entre tarefas, refatore o plano.

### Commits Atomicos
Uma tarefa = um commit completo e funcional.

---

## Transicoes

### Ao Completar com Sucesso
```bash
skill_add_artifact "writing-plans" "docs/plans/YYYY-MM-DD-<topic>-implementation.md" "plan"
skill_complete "writing-plans"
agent_handoff "architect" "backend" "Executar plano de implementacao" "<path>"
# Iniciar: test-driven-development
```

### Em Caso de Falha
```bash
skill_fail "writing-plans" "Motivo da falha"
# Voltar para brainstorming se design inadequado
```

---

## Exemplo de Uso com Orquestrador

```bash
skill_init "writing-plans"
skill_set_steps "writing-plans" 4

# Step 1: Verificar prerequisitos
skill_advance "writing-plans" "Verificar prerequisitos"
validation_check "file_exists" "docs/plans/*-design.md"
validation_check "tests_pass"
skill_validate_checkpoint "writing-plans"

# Step 2: Definir tarefas
skill_advance "writing-plans" "Definir tarefas"
# ... criar lista de tarefas ...
skill_validate_checkpoint "writing-plans"

# Step 3: Documentar plano
skill_advance "writing-plans" "Documentar plano"
# ... criar documento ...
skill_validate_checkpoint "writing-plans"

# Step 4: Aprovar plano
skill_advance "writing-plans" "Aprovar plano"
# ... apresentar e obter aprovacao ...
skill_add_artifact "writing-plans" "docs/plans/2024-01-15-login-implementation.md" "plan"
skill_validate_checkpoint "writing-plans"

skill_complete "writing-plans"
agent_handoff "architect" "backend" "Implementar conforme plano" "docs/plans/2024-01-15-login-implementation.md"
```