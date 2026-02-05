# Sprint 3: Skills Robustas

**Status**: PENDENTE
**Prioridade**: MEDIA
**Dependencia**: Sprint 1 completo
**Versao**: v3.2.0

## Objetivo

Completar skills faltantes e adicionar robustez com validacao e integracao.

## Tarefas

### 3.1 Meta-Planning Skill
**Arquivo**: `templates/skills/meta-planning/SKILL.md.tmpl`

Criar skill completa:
- [ ] Metadata (id, name, triggers)
- [ ] Proposito: Priorizar e planejar multiplas tarefas
- [ ] Steps:
  1. Coletar tarefas pendentes
  2. Analisar dependencias
  3. Priorizar por impacto/esforco
  4. Criar roadmap
- [ ] Checkpoints de validacao
- [ ] Transicoes para outras skills

### 3.2 Validacao de Pre-Requisitos
**Arquivo**: `lib/validation.sh` (expandir)

Adicionar:
- [ ] validate_design_exists() - Verifica doc de design
- [ ] validate_plan_exists() - Verifica plano de implementacao
- [ ] validate_tests_green() - Verifica testes passando
- [ ] validate_git_clean() - Verifica sem mudancas pendentes
- [ ] validate_prerequisites(skill) - Valida pre-req por skill

### 3.3 Integracao Basic-Memory
**Arquivo**: `lib/memory.sh` (NOVO)

Criar:
- [ ] memory_search(query) - Busca em licoes passadas
- [ ] memory_get_similar(context) - Encontra casos similares
- [ ] memory_suggest(task) - Sugere baseado em historico
- [ ] Integracao automatica no inicio de debugging
- [ ] Integracao automatica no inicio de feature

## Verificacao

- [ ] Meta-planning skill funcional
- [ ] Validacao de pre-requisitos bloqueando quando necessario
- [ ] Basic-memory respondendo consultas
- [ ] Testes de integracao passando

## Arquivos a Modificar

| Arquivo | Acao |
|---------|------|
| templates/skills/meta-planning/SKILL.md.tmpl | CRIAR |
| lib/validation.sh | EDITAR |
| lib/memory.sh | CRIAR |
| tests/integration/test-skills.sh | CRIAR |

## Notas

- A skill meta-planning deve ser ativada automaticamente quando usuario menciona multiplas tarefas
- Validacoes devem ser nao-bloqueantes por padrao (warning), mas configuravel para bloquear
- Integracao com basic-memory requer MCP server configurado
