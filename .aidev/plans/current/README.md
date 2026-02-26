# Current - Em Execucao

> Feature sendo executada agora. Maximo 1 por vez.

---

## Fluxo

```
backlog/ (ideia) → features/ (planejada) → current/ (executando) → history/YYYY-MM/ (concluida)
```

**Regras:**
- Apenas 1 feature ativa aqui por vez
- Checkpoint atualizado a cada sprint concluida
- Ao concluir: usar `aidev complete <id>`

---

## Feature Ativa

### Feature - Gap no Fluxo de Lições Aprendidas

**Arquivo:** [learned-lesson-trigger-gap.md](learned-lesson-trigger-gap.md)
**Iniciada:** 2026-02-26
**Sprints:** 2 planejados

| Sprint | Objetivo | Status |
|---|---|---|
| Sprint 1 | Consolidação: triggers.sh + state machine + validador | Concluida (2026-02-26) |
| Sprint 2 | Testes de integração + finalização | Concluida (2026-02-26) |

**Proximo passo:** Executar Sprint 2 — testes de integração

---

## Workflow TDD Ativo

```
RED   → Escreva o teste que falha primeiro
GREEN → Implemente o mínimo para passar
REFACTOR → Limpe sem quebrar os testes
```

Ao concluir cada sprint: `aidev done sprint-N "descricao"`

---

*Ultima atualizacao: 2026-02-26*
