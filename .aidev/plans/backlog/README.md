# Backlog - Ideias Futuras

> Ideias brutas que aguardam refinamento e priorização para se tornarem features.

---

## Fluxo

```
backlog/ (ideia) → features/ (planejada) → current/ (executando) → history/YYYY-MM/ (concluída)
```

**Regras:**
- Backlog contém ideias sem sprint definida
- Ao priorizar: criar plano completo em `features/` e remover daqui
- Nunca iniciar implementação a partir do backlog diretamente

---

## Ideias Pendentes

### Fix: AIDEV_ROOT — Fonte Única de Verdade

**Arquivo:** [fix-aidev-root-single-source.md](fix-aidev-root-single-source.md)
**Status:** Ideia
**Prioridade:** Média
**Criado:** 2026-02-20

**Descrição:** Eliminar a geração de `state/activation_snapshot.json` na raiz do projeto.
Fix cirúrgico em `activation-snapshot.sh` para que `AIDEV_ROOT` seja sempre derivado
do `BASH_SOURCE` e nunca do CWD. Resolver junto com o Pré-Sprint 0.

---

### Automação do Ciclo de Vida de Features

**Arquivo:** [feature-lifecycle-automation.md](feature-lifecycle-automation.md)
**Status:** Ideia
**Prioridade:** Alta
**Criado:** 2026-02-20

**Descrição:** Implementar comandos `aidev plan`, `aidev start` e `aidev done` para automatizar
as transições entre backlog → features → current → history, com atualização automática de READMEs,
checkpoint e snapshot a cada transição e conclusão de task/sprint/milestone.

---


## Ideias Concluídas / Removidas

| Ideia | Status | Data |
|---|---|---|
| Sistema de Atualização Interativa | Concluído em `history/2026-02/` | 2026-02-18 |
| MCP Universal Install | Removido (fora de escopo) | 2026-02-18 |
| Basic Memory Graceful Integration | Movido para `features/` → `current/` | 2026-02-20 |
| Ideia: Automação do Ciclo de Vida de Features | Concluido em history/ | 2026-02-20 |

---

*Ultima atualizacao: 2026-02-20*
