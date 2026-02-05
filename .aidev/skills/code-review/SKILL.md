---
name: code-review
description: Revisao sistematica de codigo focada em qualidade, padroes e manutencao
triggers:
  - "revisar codigo"
  - "code review"
  - "review PR"
  - "revisar PR"
  - "analise de codigo"
globs:
  - ".aidev/reviews/*.md"
  - "docs/reviews/*.md"
steps: 4
checkpoints:
  - context_gathered
  - code_analyzed
  - findings_documented
  - decision_made
artifact: ".aidev/reviews/YYYY-MM-DD-<topic>-review.md"
previous_skill: test-driven-development
next_skill: null
---

# Code Review Skill

## Metadata
- **Total de Steps**: 4
- **Tempo Estimado**: 15-45 minutos (dependendo do tamanho)
- **Prerequisito**: Codigo implementado com testes
- **Artefato Final**: `.aidev/reviews/YYYY-MM-DD-<topic>-review.md`
- **Agente Principal**: code-reviewer

## Quando Usar
Ativa quando:
- Um PR/MR precisa ser revisado
- Codigo novo foi implementado e precisa de validacao
- Refatoracao foi concluida
- Antes de merge em branch principal

## Proposito
Garantir qualidade, manutencao e aderencia a padroes atraves de revisao sistematica.

---

## Step 1: Coletar Contexto
**Checkpoint**: `context_gathered`

### Acoes
Antes de revisar, entender o contexto completo:

1. **Entender a Mudanca**
   - Qual o objetivo do PR/mudanca?
   - Quais problemas resolve?
   - Ha breaking changes?

2. **Verificar Escopo**
   - Quais arquivos foram modificados?
   - Quantas linhas adicionadas/removidas?
   - Ha testes correspondentes?

3. **Verificar Prerequisitos**
   ```bash
   # Verificar que testes passam
   validation_check "tests_pass"

   # Verificar lint
   # npm run lint / composer lint / etc
   ```

### Formato de Contexto

```markdown
## Contexto do Review

**PR/Branch**: #123 / feature/nova-funcionalidade
**Autor**: developer
**Data**: YYYY-MM-DD

### Objetivo
[Descricao do que a mudanca faz]

### Arquivos Modificados
| Arquivo | Adicoes | Remocoes | Tipo |
|---------|---------|----------|------|
| src/auth.ts | +45 | -12 | Modificado |
| src/auth.test.ts | +30 | -0 | Novo |

### Prerequisitos
- [x] Testes passando
- [x] Lint passando
- [ ] Documentacao atualizada
```

### Criterios de Validacao
- [ ] Objetivo da mudanca claramente entendido
- [ ] Lista de arquivos identificada
- [ ] Testes verificados
- [ ] Contexto documentado

---

## Step 2: Analisar Codigo
**Checkpoint**: `code_analyzed`

### Acoes
Revisar cada arquivo sistematicamente usando o checklist completo:

### Checklist de Analise

#### Corretude
- [ ] Logica esta correta?
- [ ] Edge cases tratados?
- [ ] Erros tratados apropriadamente?
- [ ] Tipos estao corretos?

#### Design
- [ ] Segue padroes do projeto?
- [ ] Principio da responsabilidade unica?
- [ ] Acoplamento baixo?
- [ ] Abstracoes apropriadas?

#### Legibilidade
- [ ] Nomes claros e descritivos?
- [ ] Funcoes pequenas (< 20 linhas)?
- [ ] Complexidade aceitavel (< 10)?
- [ ] Codigo auto-documentado?

#### Performance
- [ ] Algoritmos eficientes?
- [ ] Sem loops desnecessarios?
- [ ] Queries otimizadas?
- [ ] Cache utilizado onde apropriado?

#### Testes
- [ ] Testes existem?
- [ ] Cobertura >= 80%?
- [ ] Edge cases testados?
- [ ] Testes sao legiveis?

#### Seguranca (Basico)
- [ ] Input validado?
- [ ] Sem dados sensiveis expostos?
- [ ] Autorizacao verificada?

### Code Smells a Procurar

| Categoria | Smells |
|-----------|--------|
| Estrutural | Long Method, Large Class, Long Parameter List |
| Logico | Duplicated Code, Dead Code, Feature Envy |
| Nomenclatura | Magic Numbers, Cryptic Names |

### Metricas a Verificar

| Metrica | Ideal | Aceitavel | Critico |
|---------|-------|-----------|---------|
| Complexidade ciclomatica | <= 5 | 6-10 | > 10 |
| Linhas por funcao | <= 20 | 21-50 | > 50 |
| Cobertura de testes | >= 80% | 60-79% | < 60% |

### Criterios de Validacao
- [ ] Todos os arquivos revisados
- [ ] Checklist aplicado em cada arquivo
- [ ] Code smells identificados
- [ ] Metricas verificadas

---

## Step 3: Documentar Findings
**Checkpoint**: `findings_documented`

### Acoes
Documentar todos os achados de forma clara e construtiva:

### Formato de Findings

```markdown
## Findings

### Issues Criticos (BLOCK)
| # | Arquivo | Linha | Issue | Impacto | Sugestao |
|---|---------|-------|-------|---------|----------|
| 1 | auth.ts | 45 | SQL Injection | Seguranca | Usar prepared statements |

### Issues Maiores (REQUEST_CHANGES)
| # | Arquivo | Linha | Issue | Impacto | Sugestao |
|---|---------|-------|-------|---------|----------|
| 2 | utils.ts | 78 | Funcao com 85 linhas | Manutencao | Dividir em funcoes menores |

### Issues Menores (COMMENT)
| # | Arquivo | Linha | Issue | Sugestao |
|---|---------|-------|-------|----------|
| 3 | api.ts | 12 | Nome pouco descritivo | Renomear `x` para `userId` |

### Nitpicks (Opcional)
| # | Arquivo | Linha | Sugestao |
|---|---------|-------|----------|
| 4 | index.ts | 5 | Ordenar imports alfabeticamente |
```

### Formato de Comentarios

#### Para Issues
```markdown
**[ISSUE:SEVERITY]** Descricao do problema.

Explicacao do impacto e por que e importante.

**Sugestao:**
```code
// Exemplo de como corrigir
```
```

#### Para Sugestoes
```markdown
**[SUGGESTION]** Considere fazer X.

Isso melhoraria Y porque Z.
```

#### Para Elogios
```markdown
**[PRAISE]** Otima escolha usar pattern X aqui!

Isso facilita Y.
```

### Resumo de Findings

```markdown
## Resumo

| Severidade | Quantidade |
|------------|------------|
| CRITICAL | 0 |
| MAJOR | 2 |
| MINOR | 5 |
| NITPICK | 3 |

### Pontos Positivos
- Boa cobertura de testes (85%)
- Codigo bem organizado
- Tratamento de erros adequado

### Areas de Melhoria
- Algumas funcoes muito longas
- Nomes poderiam ser mais descritivos
```

### Criterios de Validacao
- [ ] Todos os findings documentados
- [ ] Severidade atribuida corretamente
- [ ] Sugestoes de correcao incluidas
- [ ] Pontos positivos destacados

---

## Step 4: Tomar Decisao
**Checkpoint**: `decision_made`

### Acoes
Com base nos findings, tomar uma decisao:

### Criterios de Decisao

| Decisao | Criterio | Acao Seguinte |
|---------|----------|---------------|
| **APPROVE** | 0 criticos, 0 maiores | Handoff para QA |
| **REQUEST_CHANGES** | >= 1 critico OU >= 1 maior | Retorna para desenvolvedor |
| **COMMENT** | Apenas menores/nitpicks | Handoff para QA (nao bloqueia) |

### Template de Decisao

```markdown
## Decisao

**Veredito**: APPROVE | REQUEST_CHANGES | COMMENT

### Justificativa
[Explicacao da decisao]

### Proximos Passos
1. [ ] [Se REQUEST_CHANGES] Corrigir issues criticos/maiores
2. [ ] [Se APPROVE/COMMENT] Handoff para QA
3. [ ] [Sempre] Atualizar documentacao se necessario

### Condicoes para Re-review
[Se REQUEST_CHANGES, listar o que precisa ser corrigido]
```

### Registro de Decisao

```bash
# Registrar decisao
validation_log "code-review" "PR #123" "APPROVE|REQUEST_CHANGES|COMMENT"

# Atualizar confianca
confidence_log "code-review" "PR #123" "Descricao" "0.9"
```

### Criterios de Validacao
- [ ] Decisao tomada com base nos findings
- [ ] Justificativa documentada
- [ ] Proximos passos definidos
- [ ] Handoff apropriado configurado

---

## Transicoes

### Ao Completar com APPROVE
```bash
skill_add_artifact "code-review" ".aidev/reviews/2024-01-15-pr123.md" "review"
skill_complete "code-review"
agent_handoff "code-reviewer" "qa" "Review aprovado, validar comportamento" "src/feature.ts"
```

### Ao Completar com REQUEST_CHANGES
```bash
skill_add_artifact "code-review" ".aidev/reviews/2024-01-15-pr123.md" "review"
skill_complete "code-review"
agent_handoff "code-reviewer" "backend" "Corrigir issues do code review" ".aidev/reviews/2024-01-15-pr123.md"
```

### Ao Completar com COMMENT
```bash
skill_add_artifact "code-review" ".aidev/reviews/2024-01-15-pr123.md" "review"
skill_complete "code-review"
agent_handoff "code-reviewer" "qa" "Review com sugestoes, validar comportamento" "src/feature.ts"
```

---

## Template Completo do Artefato

```markdown
# Code Review - [PR/Branch Name]

**Revisor**: code-reviewer
**Data**: YYYY-MM-DD
**PR/Branch**: #123 / feature/nome
**Autor**: developer

## Contexto
[Do Step 1]

## Arquivos Revisados
[Lista de arquivos]

## Findings

### Criticos
[Issues criticos - BLOCK]

### Maiores
[Issues maiores - REQUEST_CHANGES]

### Menores
[Issues menores - COMMENT]

### Nitpicks
[Sugestoes opcionais]

## Metricas

| Metrica | Valor | Status |
|---------|-------|--------|
| Complexidade max | X | OK/WARN/FAIL |
| Cobertura | X% | OK/WARN/FAIL |
| Linhas adicionadas | X | - |

## Pontos Positivos
- [Destacar boas praticas]

## Decisao

**Veredito**: APPROVE | REQUEST_CHANGES | COMMENT

**Justificativa**: [Explicacao]

## Proximos Passos
1. [ ] [Acao]
2. [ ] [Acao]
```

---

## Exemplo de Uso com Orquestrador

```bash
skill_init "code-review"
skill_set_steps "code-review" 4

# Step 1: Coletar contexto
skill_advance "code-review" "Coletar contexto"
# ... entender mudanca, verificar prerequisitos ...
skill_validate_checkpoint "code-review"

# Step 2: Analisar codigo
skill_advance "code-review" "Analisar codigo"
# ... aplicar checklist em cada arquivo ...
skill_validate_checkpoint "code-review"

# Step 3: Documentar findings
skill_advance "code-review" "Documentar findings"
# ... registrar issues e sugestoes ...
skill_validate_checkpoint "code-review"

# Step 4: Tomar decisao
skill_advance "code-review" "Tomar decisao"
# ... APPROVE/REQUEST_CHANGES/COMMENT ...
skill_add_artifact "code-review" ".aidev/reviews/2024-01-15-pr123.md" "review"
skill_validate_checkpoint "code-review"

skill_complete "code-review"
agent_handoff "code-reviewer" "qa" "Review concluido" ".aidev/reviews/2024-01-15-pr123.md"
```

---

## Principios do Code Review

1. **Seja Construtivo** - Sugira solucoes, nao apenas aponte problemas
2. **Seja Especifico** - Indique linha, arquivo e exemplo de correcao
3. **Seja Respeitoso** - Critique o codigo, nao a pessoa
4. **Seja Educativo** - Compartilhe conhecimento e referencias
5. **Seja Pragmatico** - Nem tudo precisa ser perfeito agora
6. **Documente Tudo** - Reviews sao conhecimento compartilhado