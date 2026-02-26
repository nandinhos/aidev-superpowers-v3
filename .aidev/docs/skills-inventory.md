# Inventário de Skills - AI Dev Superpowers

> Última atualização: 2026-02-26

## Total de Skills: 10

| # | Skill | Caminho | Steps | Checkpoints | Triggers | Status |
|---|-------|---------|-------|-------------|----------|--------|
| 1 | brainstorming | `.aidev/skills/brainstorming/SKILL.md` | 4 | ? | "brainstorm", "ideia" | documentação |
| 2 | code-review | `.aidev/skills/code-review/SKILL.md` | 4 | ? | "review", "pr" | documentação |
| 3 | learned-lesson | `.aidev/skills/learned-lesson/SKILL.md` | 4 | 4 | "licao", "aprendi" | documentação |
| 4 | meta-planning | `.aidev/skills/meta-planning/SKILL.md` | 3 | ? | "planejar", "roadmap" | documentação |
| 5 | release-management | `.aidev/skills/release-management/SKILL.md` | ? | ? | "release", "deploy" | documentação |
| 6 | rules-doc-sync | `.aidev/skills/rules-doc-sync/SKILL.md` | ? | ? | ? | documentação |
| 7 | rules-injection | `.aidev/skills/rules-injection/SKILL.md` | ? | ? | ? | documentação |
| 8 | systematic-debugging | `.aidev/skills/systematic-debugging/SKILL.md` | 4 | 4 | "debug", "bug" | documentação |
| 9 | test-driven-development | `.aidev/skills/test-driven-development/SKILL.md` | 3 | 3 | "tdd", "teste" | documentação |
| 10 | writing-plans | `.aidev/skills/writing-plans/SKILL.md` | 4 | ? | "plano", "implementar" | documentação |

---

## Detalhamento por Skill

### 1. brainstorming

- **Caminho**: `.aidev/skills/brainstorming/SKILL.md`
- **Steps**: 4
- **Checkpoints**: ?
- **Triggers**: "brainstorm", "ideia", "criar", "novo"
- **Artefato**: ?
- **Próxima skill**: ?
- **Status**: Documentação existente

### 2. code-review

- **Caminho**: `.aidev/skills/code-review/SKILL.md`
- **Steps**: 4
- **Checkpoints**: ?
- **Triggers**: "review", "pr", "revisar", "merge"
- **Artefato**: ?
- **Próxima skill**: ?
- **Status**: Documentação existente

### 3. learned-lesson

- **Caminho**: `.aidev/skills/learned-lesson/SKILL.md`
- **Steps**: 4
- **Checkpoints**: 4 (context_captured, root_cause_identified, solution_documented, lesson_stored)
- **Triggers**: "licao", "aprendi", "memorizar", "learned"
- **Artefato**: `.aidev/memory/kb/YYYY-MM-DD-<topic>.md`
- **Próxima skill**: ?
- **Status**: Documentação completa

### 4. meta-planning

- **Caminho**: `.aidev/skills/meta-planning/SKILL.md`
- **Steps**: 3
- **Checkpoints**: ?
- **Triggers**: "planejar", "roadmap", "sprint"
- **Artefato**: ?
- **Próxima skill**: ?
- **Status**: Documentação existente

### 5. release-management

- **Caminho**: `.aidev/skills/release-management/SKILL.md`
- **Steps**: ?
- **Checkpoints**: ?
- **Triggers**: "release", "deploy", "publicar"
- **Artefato**: ?
- **Próxima skill**: ?
- **Status**: Documentação existente

### 6. rules-doc-sync

- **Caminho**: `.aidev/skills/rules-doc-sync/SKILL.md`
- **Steps**: ?
- **Checkpoints**: ?
- **Triggers**: ?
- **Artefato**: ?
- **Próxima skill**: ?
- **Status**: Documentação existente

### 7. rules-injection

- **Caminho**: `.aidev/skills/rules-injection/SKILL.md`
- **Steps**: ?
- **Checkpoints**: ?
- **Triggers**: ?
- **Artefato**: ?
- **Próxima skill**: ?
- **Status**: Documentação existente

### 8. systematic-debugging

- **Caminho**: `.aidev/skills/systematic-debugging/SKILL.md`
- **Steps**: 4 (REPRODUCE, ISOLATE, ROOT CAUSE, FIX)
- **Checkpoints**: 4
- **Triggers**: "debug", "bug", "erro", "corrigir"
- **Artefato**: ?
- **Próxima skill**: learned-lesson
- **Status**: Documentação completa

### 9. test-driven-development

- **Caminho**: `.aidev/skills/test-driven-development/SKILL.md`
- **Steps**: 3 (RED, GREEN, REFACTOR)
- **Checkpoints**: 3 (red_phase_complete, green_phase_complete, refactor_phase_complete)
- **Triggers**: "tdd", "teste", "implementar"
- **Artefato**: ?
- **Próxima skill**: ?
- **Status**: Documentação completa

### 10. writing-plans

- **Caminho**: `.aidev/skills/writing-plans/SKILL.md`
- **Steps**: 4
- **Checkpoints**: ?
- **Triggers**: "plano", "implementar", "design"
- **Artefato**: ?
- **Próxima skill**: test-driven-development
- **Status**: Documentação existente

---

## Gaps Identificados

### Itens Faltantes

1. **Steps**: 3 skills não têm steps definidos (release-management, rules-doc-sync, rules-injection)
2. **Checkpoints**: 7 skills não têm checkpoints definidos
3. **Triggers**: 3 skills não têm triggers definidos (rules-doc-sync, rules-injection, ?)
4. **Próxima skill**: Nenhuma skill define próxima skill corretamente
5. **Artefato**: Apenas learned-lesson define artefato

### Skills Completas (tem tudo)

- learned-lesson ✅
- systematic-debugging ✅
- test-driven-development ✅

---

## Ações Recomendadas

### Prioridade Alta

1. **Padronizar metadata**: Todas skills devem ter:
   - steps (número)
   - checkpoints (lista)
   - triggers (lista)
   - artifact (caminho)
   - next_skill (nome)

2. **Criar skill-runner.sh**: Interface CLI para gerenciar skills

3. **Adicionar comando `aidev skill`**: Para listar, iniciar, avançar, completar skills

---

## Referências

- Template de skill: `.aidev/skills/learned-lesson/SKILL.md`
- Código existente: `lib/triggers.sh` (referência de implementação)
