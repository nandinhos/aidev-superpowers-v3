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

### Backlog - Rules Engine: Carregamento, Injeção e Validação de Regras por LLM

**Arquivo:** [rules-engine-standardization.md](rules-engine-standardization.md)
**Iniciada:** 2026-02-26
**Sprints:** 3 planejados

| Sprint | Objetivo | Status |
|---|---|---|
| Sprint 1 | Fundação: Taxonomia de regras + Loader por LLM | Em andamento |
| Sprint 2 | Enforcement: Validação pós-ação + Anti-duplicação | Pendente |
| Sprint 3 | Inteligência: Sync com docs oficiais + Dashboard de compliance | Pendente |

**Proximo passo:** Executar Sprint 1 — RED → GREEN → REFACTOR

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
