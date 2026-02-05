---
name: brainstorming
description: Refina ideias atraves de perguntas antes de implementar
triggers:
  - "novo projeto"
  - "nova feature"
  - "design"
  - "arquitetura"
  - "ideia"
globs:
  - "docs/plans/*.md"
  - "project-docs/**"
steps: 4
checkpoints:
  - problem_understood
  - alternatives_explored
  - design_presented
  - design_documented
artifact: "docs/plans/YYYY-MM-DD-<topic>-design.md"
next_skill: writing-plans
---

# Brainstorming Skill

## Metadata
- **Total de Steps**: 4
- **Tempo Estimado**: 15-30 minutos
- **Artefato Final**: `docs/plans/YYYY-MM-DD-<topic>-design.md`
- **Proxima Skill**: `writing-plans`

## Quando Usar
Ativa ANTES de escrever qualquer codigo quando construindo algo novo.

## Proposito
Transformar ideias brutas em especificacoes validadas atraves de:
- Questionamento socratico
- Exploracao de alternativas
- Validacao incremental
- Documentacao de design

---

## Step 1: Entender o Problema
**Checkpoint**: `problem_understood`

### Acoes
Fazer perguntas clarificadoras:
- Qual problema estamos resolvendo?
- Quem sao os usuarios?
- Quais sao as restricoes (tempo, tecnologia, budget)?
- Como e o sucesso? Quais metricas?

### Criterios de Validacao
- [ ] Problema claramente definido em 1-2 frases
- [ ] Usuarios/personas identificados
- [ ] Restricoes documentadas
- [ ] Criterios de sucesso estabelecidos

### Saida Esperada
Resumo do problema em 2-3 paragrafos com todos os pontos acima.

---

## Step 2: Explorar Alternativas
**Checkpoint**: `alternatives_explored`

### Acoes
Apresentar 2-3 abordagens diferentes:

| Abordagem | Descricao | Pros | Contras | Complexidade |
|-----------|-----------|------|---------|--------------|
| A | ... | ... | ... | baixa/media/alta |
| B | ... | ... | ... | baixa/media/alta |
| C | ... | ... | ... | baixa/media/alta |

### Criterios de Validacao
- [ ] Pelo menos 2 alternativas apresentadas
- [ ] Pros/contras documentados para cada
- [ ] Recomendacao clara com justificativa
- [ ] Usuario aprovou a abordagem escolhida

### Saida Esperada
Tabela comparativa + recomendacao aprovada.

---

## Step 3: Apresentar Design em Chunks
**Checkpoint**: `design_presented`

### Acoes
Quebrar o design em secoes digeríveis, apresentando UMA de cada vez:

1. **Visao Geral** - Diagrama de alto nivel
   - Aguardar aprovacao antes de continuar

2. **Modelo de Dados** - Entidades e relacionamentos
   - Aguardar aprovacao antes de continuar

3. **Design de API/Interface** - Endpoints ou componentes
   - Aguardar aprovacao antes de continuar

4. **Consideracoes de UI/UX** (se aplicavel)
   - Aguardar aprovacao antes de continuar

5. **Decisoes Tecnicas** - Stack, bibliotecas, padroes
   - Aguardar aprovacao antes de continuar

### Criterios de Validacao
- [ ] Cada secao apresentada separadamente
- [ ] Cada secao aprovada antes de avancar
- [ ] Feedback do usuario incorporado
- [ ] Nenhuma secao importante pulada

### Saida Esperada
Design completo aprovado incrementalmente.

---

## Step 4: Documentar Design
**Checkpoint**: `design_documented`

### Acoes
Criar documento em: `docs/plans/YYYY-MM-DD-<topic>-design.md`

### Template do Documento
```markdown
# [Nome da Feature] Design

**Data**: YYYY-MM-DD
**Autor**: AI Dev Superpowers
**Status**: Aprovado

## Declaracao do Problema
[Descricao clara do problema - do Step 1]

## Solucao Proposta
[Abordagem escolhida com justificativa - do Step 2]

## Detalhes Tecnicos
[Especificacoes de implementacao - do Step 3]

### Modelo de Dados
[Entidades e relacionamentos]

### API/Interface
[Endpoints ou componentes]

### Stack e Bibliotecas
[Tecnologias escolhidas]

## Alternativas Consideradas
[Outras abordagens e porque nao escolhidas - do Step 2]

## Riscos e Mitigacoes
| Risco | Probabilidade | Impacto | Mitigacao |
|-------|---------------|---------|-----------|
| ... | ... | ... | ... |

## Proximos Passos
1. [ ] Criar plano de implementacao (skill: writing-plans)
2. [ ] Implementar com TDD (skill: test-driven-development)
3. [ ] Revisao de seguranca (agent: security-guardian)
```

### Criterios de Validacao
- [ ] Documento salvo no path correto
- [ ] Todas as secoes preenchidas
- [ ] Usuario revisou e aprovou documento final

### Saida Esperada
Artefato salvo e registrado em `skills.json`.

---

## Transicoes

### Ao Completar com Sucesso
1. Registrar artefato: `skill_add_artifact("brainstorming", "<path>", "design")`
2. Marcar completa: `skill_complete("brainstorming")`
3. Handoff para Architect: `agent_handoff("orchestrator", "architect", "Criar plano de implementacao", "<path>")`
4. Iniciar proxima skill: `writing-plans`

### Em Caso de Falha ou Abandono
1. Registrar motivo: `skill_fail("brainstorming", "<motivo>")`
2. Salvar estado parcial para retomar depois
3. Notificar usuario sobre como retomar

---

## Principios-Chave

1. **Pergunte antes de assumir** - Nunca assuma requisitos
2. **Explore antes de comprometer** - Sempre mostre alternativas
3. **Valide antes de implementar** - Aprovacao em cada step
4. **Documente antes de codificar** - Artefato obrigatorio

---

## Exemplo de Uso com Orquestrador

```bash
# Inicio
skill_init "brainstorming"
skill_set_steps "brainstorming" 4

# Step 1: Entender problema
skill_advance "brainstorming" "Entender o problema"
# ... fazer perguntas, obter respostas ...
skill_validate_checkpoint "brainstorming"

# Step 2: Explorar alternativas
skill_advance "brainstorming" "Explorar alternativas"
# ... apresentar opcoes, obter escolha ...
skill_validate_checkpoint "brainstorming"

# Step 3: Apresentar design
skill_advance "brainstorming" "Apresentar design em chunks"
# ... apresentar secao por secao ...
skill_validate_checkpoint "brainstorming"

# Step 4: Documentar
skill_advance "brainstorming" "Documentar design"
# ... criar documento ...
skill_add_artifact "brainstorming" "docs/plans/2024-01-15-login-design.md" "design"
skill_validate_checkpoint "brainstorming"

# Finalizar
skill_complete "brainstorming"
agent_handoff "orchestrator" "architect" "Criar plano de implementacao" "docs/plans/2024-01-15-login-design.md"
```