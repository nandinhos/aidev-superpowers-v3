# Feature: Unificação de Fluxos de Execução

**Status:** Concluido
**Prioridade:** ALTA
**Sprint Estimado:** 3-4
**Feature ID:** unificacao-fluxos

---

## Problema

3 sistemas redundantes coexistem no codebase:
1. `lib/feature-lifecycle-cli.sh` (720 linhas) - ATIVO
2. `.aidev/lib/feature-lifecycle.sh` (549 linhas) - MORTO
3. `lib/plans.sh` (163 linhas) - REDUNDANTE

~1.800 linhas são removíveis com a unificação.

---

## Decisões Arquiteturais (Consensadas)

### 1. Orchestrator = Hooks Pontuais
- **Não** logging estruturado de toda conversa (tokens)
- **Sim** interceptação em momentos específicos: fim de skill, checkpoint, commit, handoff entre agentes
- O Orchestrator é um guia comportamental, não um logger onisciente

### 2. Capacidades Cognitivas
| Capacidade | Classificação | Ação |
|-----------|---------------|------|
| Rollback stack | **Estratégica** | Manter e priorizar |
| Chain of thought | Operacional | Manter como suporte leve |
| Checkpoint | Operacional | Manter para continuidade |
| Context-log | Operacional | Manter para auditoria |

### 3. Multi-LLM Real
- Framework deve ser **runtime-agnostic**
- Não hardcodear "Claude" em lugar nenhum
- JSON espelho deve ser genérico

### 4. JSON Espelho = Híbrido
```
.unified.json           → Cache simples (estado atual)
.state/rollback-stack.json  → Snapshots versionados (máx 5)
.state/context-log.json     → Event log (últimos 50 eventos)
```

### 5. Backward Compatibility
| Tipo de mudança | Compatibilidade | Ação |
|-----------------|-----------------|------|
| API pública (`aidev plan`, `start`) | **MAJOR** | 2 releases, depois deprecada |
| Formato de dados (Markdown) | **MINOR** | Migrador automático |
| Scripts internos | **PATCH** | Livre, documentar |
| Local de arquivos | **MINOR** | Symlink/redirect |

---

## Escopo Refinado

### Fase 1: Eliminar Código Morto
- [ ] `.aidev/lib/feature-lifecycle.sh` - verificar consumidores externos (funções exportadas)
- [ ] Adicionar wrapper de compatibilidade (se necessário)
- [ ] `lib/auto-catalog.sh` - verificar se tem consumidor
- [ ] `lib/backlog.sh` - verificar se tem consumidor

### Fase 2: Deprecar Redundâncias
- [ ] `lib/plans.sh` - deprecar com aviso → redirecionar para `flc_feature_complete()`
- [ ] `aidev feature finish` - deprecar → sugere `aidev complete`
- [ ] Remover `cmd_feature()` de `bin/aidev`

### Fase 3: Unificar Namespace
- [ ] Renomear `lib/feature-lifecycle-cli.sh` → `lib/feature-lifecycle.sh`
- [ ] Padronizar `flc_*` → `feature_*` (manter aliases para compatibilidade)
- [ ] Atualizar `bin/aidev` para carregar novo módulo

### Fase 4: Reformar JSON Espelho
- [ ] `.unified.json` = cache simples (apenas estado atual)
- [ ] `.state/rollback-stack.json` = snapshots versionados (máx 5)
- [ ] `.state/context-log.json` = event log (últimos 50 eventos, depois arquiva)
- [ ] Migrar capacidades cognitivas para novos formatos

### Fase 5: Validar
- [ ] Suite completa de testes (`tests/unit/test-lifecycle-*.sh`)
- [ ] `aidev plan/start/done/complete` funcionam ponta a ponta
- [ ] Atualizar `CLAUDE.md` com fluxo único

---

## Arquitetura Final

```
FLUXO CANÔNICO (Plans-based):
.aidev/plans/backlog/     → Ideia em Markdown
        ↓ aidev plan      
.aidev/plans/features/    → Feature planejada
        ↓ aidev start     
.aidev/plans/current/     → Execução ativa (máx 1)
        ↓ aidev done      
        ↓ aidev complete  
.aidev/plans/history/YYYY-MM/  → Concluída

SUPORTE (JSON como espelho):
.aidev/state/
├── unified.json           → Cache simples
├── rollback-stack.json   → Snapshots (máx 5)
└── context-log.json      → Event log (50 eventos)
```

---

## Comportamento Desejado

- Plans-based (Markdown) é a **fonte de verdade**
- JSON é **espelho/suporte**, nunca o inverso
- Orchestrator opera via **hooks pontuais**, não logging total
- Rollback é **estratégico**; outras capacidades são **operacionais**
- Multi-LLM: arquitetura **runtime-agnostic**
- Backward compatibility: **política clara** definida

---

## Critérios de Aceite

- [ ] `.aidev/lib/feature-lifecycle.sh` removido ou com wrapper compatibilidade
- [ ] `lib/plans.sh` depreciado
- [ ] `aidev feature finish` redireciona com aviso
- [ ] `lib/feature-lifecycle-cli.sh` renomeado para `lib/feature-lifecycle.sh`
- [ ] Funções padronizadas (`flc_*` → `feature_*` com aliases)
- [ ] JSON espelho em formato híbrido implementado
- [ ] Rollback stack funcional
- [ ] Todos os testes passam
- [ ] `CLAUDE.md` atualizado

---

## Dependências

Nenhuma dependência externa.

---

## Estimativa

3-4 sprints

---

## Fonte

Consolidação de debates: `.aidev/plans/backlog/consolidated-debates-2026-02.md`
Decisões arquiteturais: Conversa em 2026-02-23
