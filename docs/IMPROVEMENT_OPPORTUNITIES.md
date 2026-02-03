# AI Dev Superpowers v3.2 - Oportunidades de Melhoria

> Documento gerado para continuidade do desenvolvimento com outra LLM.
> Data: 2026-02-02 | Versao atual: v3.2.0

## Status Atual

### Sprints Completos
- [x] Sprint 1: Fundacao (Orchestrator, State Manager, CLI Commands)
- [x] Sprint 2: Agentes Senior (Architect, Backend, Frontend, DevOps)

### Sprints Pendentes
- [ ] Sprint 3: Skills Robustas
- [ ] Sprint 4: UX Intuitiva

---

## Oportunidades de Melhoria por Prioridade

### P1 - Criticos (Bugs/Problemas)

#### 1. Fix: Rollback para checkpoint especifico retorna duplicado
**Arquivo**: `lib/state.sh`
**Funcao**: `state_rollback()`
**Problema**: Quando faz rollback para um checkpoint especifico (nao o ultimo), a funcao retorna ambos os valores em vez de apenas o do checkpoint solicitado.
**Teste falhou**: `test_state_rollback_to_specific_checkpoint`
**Solucao sugerida**: Revisar a query jq que busca o checkpoint especifico na rollback_stack.

```bash
# Linha ~185 - revisar esta query
snapshot=$(jq -r --arg id "$checkpoint_id" \
    '.rollback_stack[] | select(.id == $id) | .state_snapshot' "$STATE_FILE")
```

#### 2. Fix: Checkpoint IDs nao sao unicos
**Arquivo**: `lib/state.sh`
**Problema**: Todos os checkpoints criados no mesmo segundo tem o mesmo ID (`cp-TIMESTAMP`).
**Solucao sugerida**: Adicionar contador ou usar nanosegundos.

```bash
# Atual
local checkpoint_id="cp-$(date +%s)"

# Sugerido
local checkpoint_id="cp-$(date +%s%N | cut -c1-13)"
# ou
local checkpoint_id="cp-$(date +%s)-$RANDOM"
```

---

### P2 - Sprint 3: Skills Robustas

#### 3. Criar: Meta-Planning Skill
**Arquivo a criar**: `templates/skills/meta-planning/SKILL.md.tmpl`
**Descricao**: Skill para priorizar e planejar multiplas tarefas simultaneas.
**Requisitos**:
- Coletar tarefas pendentes do estado
- Analisar dependencias entre tarefas
- Priorizar por matriz impacto/esforco
- Criar roadmap visual
- Checkpoints de validacao

#### 4. Criar: Validacao de Pre-Requisitos Expandida
**Arquivo**: `lib/validation.sh` (expandir ou criar)
**Funcoes a adicionar**:
```bash
validate_design_exists()      # Verifica se doc de design existe
validate_plan_exists()        # Verifica se plano de implementacao existe
validate_tests_green()        # Verifica se testes passam
validate_git_clean()          # Verifica sem mudancas pendentes
validate_prerequisites(skill) # Valida pre-req por skill
```

**Matriz de pre-requisitos por skill**:
| Skill | Pre-requisito |
|-------|---------------|
| brainstorming | Nenhum |
| writing-plans | design_exists |
| test-driven-development | plan_exists |
| code-review | tests_green |
| systematic-debugging | bug_reproducible |

#### 5. Criar: Integracao Basic-Memory
**Arquivo a criar**: `lib/memory.sh`
**Descricao**: Integrar com MCP basic-memory para consultar licoes passadas.
**Funcoes sugeridas**:
```bash
memory_search(query)          # Busca em licoes passadas
memory_get_similar(context)   # Encontra casos similares
memory_suggest(task)          # Sugere baseado em historico
```
**Dependencia**: Requer MCP server basic-memory configurado.

---

### P3 - Sprint 4: UX Intuitiva

#### 6. Criar: Smart Suggestion Mode Expandido
**Arquivo a criar**: `lib/suggest.sh`
**Descricao**: Expandir o `cmd_suggest` atual com mais inteligencia.
**Melhorias**:
- Integrar com basic-memory para sugestoes contextuais
- Analisar padroes de commits recentes
- Detectar testes falhando automaticamente
- Sugerir baseado em TODOs/FIXMEs no codigo

#### 7. Criar: Dashboard Visual
**Arquivo a criar**: `lib/dashboard.sh`
**Descricao**: Dashboard ASCII/Unicode para terminal.
**Output esperado**:
```
┌─ PROJETO: my-app (nextjs)
├─ FASE: 3/4 | SPRINT: 4
├─ SKILL ATIVA: brainstorming (2/4)
│  └─ Checkpoint 1: ✓ | Checkpoint 2: ◐
├─ AGENTE: architect
└─ PROXIMO: backend
```
**Consideracoes**:
- Suportar terminais sem Unicode (fallback ASCII)
- Respeitar variavel NO_COLOR
- Mostrar progresso de checkpoints

#### 8. Expandir: Help Contextual
**Arquivo**: `lib/help.sh` ou `lib/cli.sh`
**Novos comandos**:
```bash
aidev help agents        # Lista agentes com descricao
aidev help skills        # Lista skills com quando usar
aidev help feature-flow  # Mostra fluxo de feature
aidev help bug-flow      # Mostra fluxo de bug fix
aidev help refactor-flow # Mostra fluxo de refatoracao
```

---

### P4 - Melhorias de Qualidade

#### 9. Padronizar Profundidade de Agentes Restantes
**Arquivos**:
- `templates/agents/qa.md.tmpl` - Adicionar patterns de teste
- `templates/agents/security-guardian.md.tmpl` - Adicionar OWASP, pentest patterns
- `templates/agents/code-reviewer.md.tmpl` - Adicionar code review checklist detalhado
- `templates/agents/legacy-analyzer.md.tmpl` - Adicionar patterns de analise

**Meta**: Minimo 150 linhas por agente com:
- Patterns detalhados
- Trade-offs
- Exemplos de codigo
- Checklist de qualidade

#### 10. Implementar Maturity Models
**Descricao**: Cada agente deve avaliar o nivel de maturidade do projeto.
**Niveis sugeridos**:
```
Level 1: Basico       - Sem testes, sem CI
Level 2: Intermediario - Alguns testes, CI basico
Level 3: Avancado     - Boa cobertura, CI/CD
Level 4: Expert       - TDD, code review, observabilidade
Level 5: Reference    - Tudo acima + metricas de qualidade
```

#### 11. Metricas de Sucesso por Skill
**Arquivo**: Expandir `lib/metrics.sh`
**Metricas a adicionar**:
- Taxa de sucesso por skill (completed vs failed)
- Tempo medio por skill
- Numero de rollbacks por sessao
- Frequencia de uso de cada agente

---

### P5 - Refatoracoes Tecnicas

#### 12. Consolidar Estado (Migration Path)
**Problema**: Existem 3+ arquivos de estado legado que ainda sao usados em alguns lugares.
**Arquivos legados**:
- `.aidev/state/session.json`
- `.aidev/state/skills.json`
- `.aidev/state/agents.json`

**Solucao**: 
1. `state_migrate_legacy()` ja existe mas nao e chamada automaticamente
2. Adicionar chamada automatica na inicializacao
3. Deprecar funcoes antigas em `lib/orchestration.sh` que usam arquivos separados

#### 13. Melhorar Tratamento de Erros no CLI
**Arquivo**: `bin/aidev`
**Problema**: `set -eEo pipefail` pode causar saidas inesperadas.
**Solucao**: Revisar todas as operacoes aritmeticas para usar `|| true`:
```bash
# Ja corrigido em alguns lugares, verificar consistencia
((counter++)) || true
```

#### 14. Adicionar Testes de Integracao
**Arquivo a criar**: `tests/integration/test-cli-commands.sh`
**Testes sugeridos**:
- `aidev new-feature` cria estado correto
- `aidev fix-bug` ativa skill correta
- `aidev suggest` funciona em diferentes cenarios
- `aidev refactor` funciona em diferentes cenarios

#### 15. Adicionar Testes E2E
**Arquivo a criar**: `tests/e2e/test-feature-flow.sh`
**Cenarios**:
- Fluxo completo de nova feature (mock de interacao)
- Fluxo de bug fix
- Rollback de estado

---

### P6 - Documentacao

#### 16. Atualizar CHANGELOG.md
**Adicionar**: Entrada para v3.2.0 com todas as mudancas.

#### 17. Atualizar README.md
**Adicionar**:
- Novos comandos CLI (new-feature, fix-bug, suggest, refactor)
- Diagrama do fluxo de estado
- Exemplos de uso

#### 18. Criar ADRs (Architectural Decision Records)
**Local**: `docs/adr/`
**ADRs sugeridos**:
- ADR-001: Escolha de estado unificado vs arquivos separados
- ADR-002: Sistema de confianca para decisoes autonomas
- ADR-003: Padrao de checkpoints e rollback

---

## Arquivos de Referencia

### Planos de Sprint Detalhados
```
.aidev/state/plans/sprint-1-fundacao.md      # COMPLETO
.aidev/state/plans/sprint-2-agentes-senior.md # COMPLETO
.aidev/state/plans/sprint-3-skills-robustas.md # PENDENTE
.aidev/state/plans/sprint-4-ux-intuitiva.md   # PENDENTE
```

### Testes Existentes
```
tests/unit/test-state.sh      # 28/29 passando
tests/unit/test-core.sh       # Existente
tests/unit/test-detection.sh  # Existente
tests/unit/test-metrics.sh    # Existente
```

### Modulos Principais
```
lib/state.sh        # NOVO - Estado unificado
lib/orchestration.sh # Orquestracao de skills/agentes
lib/core.sh         # Funcoes base (v3.2.0)
lib/cli.sh          # Parsing de argumentos e help
lib/detection.sh    # Deteccao de stack/plataforma
lib/metrics.sh      # Telemetria
```

---

## Como Continuar o Desenvolvimento

1. **Corrigir bugs P1** antes de adicionar novas features
2. **Executar testes** apos cada mudanca: `./tests/unit/test-state.sh`
3. **Seguir TDD** - escrever teste antes de implementar
4. **Manter consistencia** com padroes existentes nos agentes
5. **Atualizar versao** em `lib/core.sh` para releases

## Comandos Uteis

```bash
# Rodar testes
./tests/unit/test-state.sh

# Verificar CLI
./bin/aidev --help
./bin/aidev suggest
./bin/aidev doctor

# Status do projeto
./bin/aidev status
```

---

*Documento gerado automaticamente por Claude Opus 4.5*
