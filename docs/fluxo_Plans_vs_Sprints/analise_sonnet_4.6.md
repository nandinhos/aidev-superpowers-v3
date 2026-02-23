# Análise: Duplicação de Fluxos de Execução de Features

**Data**: 2026-02-23
**Participantes**: Orquestrador, Agente Arquiteto, Agente Backend/DevOps, Agente QA/Produto
**Método**: Exploração profunda do código + análise paralela por especialistas

---

## Contexto

O projeto apresenta uma situação crítica: existem **múltiplos sistemas de gestão de features** coexistindo no codebase. O usuário identificou duas dinâmicas — uma baseada em Sprints (`state/`) e outra baseada em Plans (`plans/`) — e solicitou análise para padronizar de uma vez por todas o fluxo de codificação.

---

## Descoberta Principal: Não são 2, são 3 Sistemas

A exploração do código revelou que o problema é maior do que o identificado inicialmente:

### Sistema 1 — `lib/feature-lifecycle-cli.sh` (720 linhas) — ATIVO
**Localização**: `/home/nandodev/projects/aidev-superpowers-v3-1/lib/feature-lifecycle-cli.sh`
**Namespace de funções**: `flc_*`
**Integração**: Chamado diretamente por `bin/aidev`

```
cmd_plan()     → flc_plan_create()      [ATIVO]
cmd_start()    → flc_feature_start()    [ATIVO]
cmd_done()     → flc_sprint_done()      [ATIVO]
cmd_complete() → flc_feature_complete() [ATIVO]
```

**O que faz de único**:
- Gerencia READMEs automáticos em cada pasta (backlog, features, current, history)
- Reconstrói `ROADMAP.md` dinamicamente
- Cria checkpoints automáticos a cada transição
- Faz staging automático via `git add`
- Tem testes unitários em `tests/unit/test-lifecycle-*.sh`

---

### Sistema 2 — `.aidev/lib/feature-lifecycle.sh` (549 linhas) — MORTO
**Localização**: `/home/nandodev/projects/aidev-superpowers-v3-1/.aidev/lib/feature-lifecycle.sh`
**Namespace de funções**: `feature_*`
**Integração**: Nunca chamado por `bin/aidev`

**Funções completamente inativas**:
- `feature_complete()` — duplica `flc_feature_complete()`
- `feature_list_active()` — nunca chamada
- `feature_get_file()` — nunca chamada
- `feature_get_metadata()` — nunca chamada
- `feature_on_skill_complete()` — hook sem listener
- `feature_cli()` — handler nunca invocado
- `feature_cmd_*()` — 5 subcomandos CLI sem uso

**Dead code confirmado**: ~44% do arquivo (240+ linhas) são funções de CLI nunca chamadas.

**Atenção**: Algumas funções são exportadas (`export -f feature_complete`). Pode haver chamadas externas em skills ou agentes não rastreadas.

---

### Sistema 3 — `lib/plans.sh` (163 linhas) — REDUNDANTE
**Localização**: `/home/nandodev/projects/aidev-superpowers-v3-1/lib/plans.sh`
**Namespace de funções**: `plans__*`
**Integração**: Chamado por `cmd_feature()` em `bin/aidev` (caminho alternativo)

**Problema**: `plans__feature_finish()` duplica `flc_feature_complete()` com 85% de sobreposição de lógica.

```bash
# Dois caminhos para o mesmo resultado:
aidev complete <id>         → flc_feature_complete()      [PRIMÁRIO]
aidev feature finish <id>   → plans__feature_finish()     [ALTERNATIVO]
```

---

## Mapeamento do Estado de Fluxo

### O que o `bin/aidev` (4.214 linhas) realmente usa

| Comando | Função chamada | Sistema | Status |
|---------|---|---|---|
| `aidev plan <título>` | `flc_plan_create()` | Sistema 1 | ATIVO |
| `aidev start <id>` | `flc_feature_start()` | Sistema 1 | ATIVO |
| `aidev done <sprint>` | `flc_sprint_done()` | Sistema 1 | ATIVO |
| `aidev complete <id>` | `flc_feature_complete()` | Sistema 1 | ATIVO |
| `aidev feature finish` | `plans__feature_finish()` | Sistema 3 | ALTERNATIVO |
| *(qualquer via LLM)* | `feature_complete()` | Sistema 2 | MORTO |

### Estado em `.aidev/state/`

| Arquivo | Tamanho | Status |
|---------|---|---|
| `unified.json` | 20.7 KB | ATIVO — lido por cmd_status, cmd_agent |
| `error-log.json` | 14.8 KB | ATIVO — usado por error_recovery |
| `context-log.json` | 3.4 KB | ATIVO — escrito por feature-lifecycle.sh (morto) |
| `activation_snapshot.json` | 753 B | ATIVO — cmd_agent_lite |
| `checksums.json` | 3.0 KB | ATIVO — upgrade_record_checksums |
| `checkpoint.md` | 2.2 KB | LEGADO — apenas humano, sem consumidor ativo |
| `session.json` | 137 B | MORTO — substituído por unified.json |
| `audit.log` | 162 B | MORTO — histórico sem consumidor |
| `passports/` | — | MORTO — context-passport.sh é legado |
| `triggers.json` | 137 B | LEGADO — triggers__load() |

---

## O que o Histórico Revela

Examinando `.aidev/plans/history/2026-02/` com 22 features concluídas:

- **100% das features estão em formato Markdown estruturado** (Plans-based)
- Nenhuma usa JSON puro como fonte de verdade
- O padrão real que acontece em produção:

```
1. Feature criada em Markdown → .aidev/plans/backlog/
2. Movida via `aidev start`   → .aidev/plans/current/
3. Executada com skills       → brainstorming → writing-plans → TDD
4. Concluída via `aidev complete` → .aidev/plans/history/2026-02/
5. JSON (unified.json) atualizado APÓS como registro auxiliar
```

**Conclusão verificada**: O fluxo Plans-based (Markdown) **é o fluxo real e ativo**. O JSON é suporte, não fonte de verdade.

---

## Veredito dos Especialistas

### Agente Arquiteto

**Diagnóstico**: O Sistema 1 (`feature-lifecycle-cli.sh`) é o único fluxo ativo. O Sistema 2 é pure legacy code abandonado. O Sistema 3 é uma abstração redundante criada por uma branch paralela não sincronizada com o sistema principal.

**Proposta**: Não manter 3 sistemas. Consolidar em 1 arquivo com nomenclatura unificada.

**Arquitetura proposta**:
```
ANTES (atual, confuso):
├─ bin/aidev
│  ├─ → lib/feature-lifecycle-cli.sh   (flc_*)    [PRIMÁRIO]
│  └─ → lib/plans.sh                   (plans__*) [ALTERNATIVO]
├─ .aidev/lib/feature-lifecycle.sh     (feature_*)[MORTO]

DEPOIS (proposto):
├─ bin/aidev
│  └─ → lib/feature-lifecycle.sh       (feature_*)[ÚNICO]
└─ (sem duplicação)
```

**Risco**: Muito baixo. Mudanças são localizadas e operações são idempotentes.

---

### Agente Backend / DevOps

**Diagnóstico**: São 3 sistemas, não 2. Caso clássico de branches desenvolvidas em paralelo sem sincronização — todas deram merge, editaram arquivos diferentes, sem conflito git, gerando triplicação silenciosa.

**Inventário de código removível**:

| Item | Linhas | Justificativa |
|------|---|---|
| `.aidev/lib/feature-lifecycle.sh` | -549 | Nunca chamado pelo CLI |
| Dead CLI funções internas | -240 | feature_cli + 6 subcomandos inativos |
| `lib/plans.sh` | -163 | Duplica flc_feature_complete() (85%) |
| `lib/auto-catalog.sh` | -323 | Não importado em load_essential_modules |
| `lib/backlog.sh` | -349 | Não no carregamento essencial |
| Estado obsoleto (passports, session.json, audit.log) | ~200 | Sem consumidores ativos |
| **Total estimado** | **~1.824 linhas** | |

**Armadilha crítica**: Funções `feature_complete()` e `feature_list_active()` são exportadas com `export -f`. Podem ser chamadas por scripts externos ou agentes não rastreados. Remoção exige verificação antes.

**Recomendação**: Manter wrapper de compatibilidade por 1 sprint antes de remover.

---

### Agente QA / Produto

**Diagnóstico**: O fluxo Plans-based é superior em todos os aspectos relevantes. O Sprint/State-based é complementar, não competitivo — fornece suporte de checkpoint e continuidade, não o fluxo principal.

**Comparativo de qualidade**:

| Aspecto | Plans-based (Markdown) | Sprint/State-based (JSON) | Vencedor |
|---------|---|---|---|
| Legibilidade | Markdown estruturado, versionável | JSON opaco, requer parser | Plans |
| Rastreabilidade git | Histórico completo no git | Log rotacionado, limitado | Plans |
| Code review | Design + plan + resultado visíveis | Estado escondido | Plans |
| Colaboração | Fácil compartilhar | Requer CLI para interpretar | Plans |
| Documentação | Artefato IS a documentação | Separada do estado | Plans |
| Lookup por ID | O(n) disk scan | O(1) jq lookup | State |
| Context cognitivo | Ausente | chain_of_thought, confidence | State |
| Multi-LLM tracking | Ausente | Registra qual LLM fez o quê | State |

**Capacidades do Sprint/State que NÃO podem ser perdidas**:

1. **Context-Log** — rastreia qual LLM fez qual ação e quando. Essencial para multi-agente.
2. **Rollback Stack** — permite reverter a estado anterior se skill falha.
3. **Session Metrics** — tokens usados, duração, versão do sistema.
4. **Cognitive Context** — chain_of_thought, hypothesis, confidence registrados por checkpoint.
5. **Sprint Guard** — validação de alinhamento da ação proposta com task ativa.
6. **Fallback Artifacts** — arquivos para quando MCPs estão indisponíveis.

---

## Síntese do Debate — Convergências e Divergências

### O que os 3 especialistas concordam

1. **Fluxo Plans-based é o canônico** e deve ser o único a sobreviver
2. **Sistema 2 (`.aidev/lib/feature-lifecycle.sh`) é dead code puro** — pode ser removido
3. **Sistema 1 (`feature-lifecycle-cli.sh`) é a implementação correta** — base para unificação
4. **Sistema 3 (`plans.sh`) é redundante** — deve ser depreciado
5. **~1.800+ linhas são removíveis** com a unificação

### Divergências e Vereditos Arbitrados

**Divergência 1 — Quantidade de sistemas**
- Arquiteto identificou 2 sistemas
- Backend/DevOps identificou 3 (revelando `lib/plans.sh` como terceiro)
- **Veredito**: Backend/DevOps está correto. São 3.

**Divergência 2 — Nível de risco**
- Arquiteto: risco muito baixo
- Backend/DevOps: risco médio-alto (funções exportadas podem ter consumidores externos)
- **Veredito**: Risco médio. Verificar consumidores de `feature_complete` antes de remover. Manter wrapper por 1 sprint.

**Divergência 3 — O que preservar do JSON**
- Arquiteto: eliminar tudo do sistema legado
- QA: preservar 6 capacidades únicas do Sprint/State
- **Veredito**: QA está correto. JSON continua existindo como espelho/suporte, não como fonte de verdade. As 6 capacidades são migradas para formatos mais simples e legíveis.

---

## Veredito Final

### Decisão: Plans-based é o fluxo único e canônico

**Confirmado pelos 3 especialistas**: O fluxo Markdown-based em `.aidev/plans/` é o que está sendo usado, é o mais compreensível, é o mais adequado para revisão de código e colaboração.

**Princípio estabelecido**: Markdown é a fonte de verdade. JSON é espelho/snapshot. Nunca o inverso.

---

### O que eliminar

| Item | Ação | Prioridade |
|------|---|---|
| `.aidev/lib/feature-lifecycle.sh` | Remover (após verificar exportações) | ALTA |
| `lib/plans.sh` | Deprecar com aviso; remover após 1 sprint | ALTA |
| `aidev feature finish` (cmd) | Deprecar → redirecionar para `aidev complete` | ALTA |
| `.aidev/state/session.json` | Remover (substituído por unified.json) | MÉDIA |
| `.aidev/state/passports/` | Remover (context-passport é legado) | MÉDIA |
| `.aidev/state/audit.log` | Arquivar e não criar novos | BAIXA |
| `lib/auto-catalog.sh` | Verificar se tem consumidor; remover se não | MÉDIA |
| `lib/backlog.sh` | Verificar se tem consumidor; remover se não | MÉDIA |

---

### O que preservar (migrado para formato canônico)

| Capacidade | Origem | Destino |
|---|---|---|
| Context-Log (qual LLM fez o quê) | `unified.json` → `context_log[]` | `.aidev/state/context-log.md` (tabela Markdown) |
| Rollback Stack | `unified.json` → `rollback_stack[]` | `.aidev/state/rollback-stack.json` (snapshot histórico, não editável) |
| Session Metrics | `unified.json` → `session{}` | `.aidev/state/session-metrics.json` (JSON simples) |
| Cognitive Context | checkpoints JSON | Seção em `checkpoint.md` |
| Sprint Guard | `sprint-guard.sh` | Mantido em `lib/`, integrado ao orchestrator |
| Fallback Artifacts | `.aidev/state/fallback/` | Mantidos no mesmo local |

---

### Arquitetura do Fluxo Unificado

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUXO CANÔNICO ÚNICO                         │
│                     (Plans-based)                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   .aidev/plans/backlog/     → Ideia em Markdown                 │
│         ↓ aidev plan "Título"                                    │
│                                                                  │
│   .aidev/plans/features/    → Feature planejada (com sprints)   │
│         ↓ aidev start <id>                                       │
│                                                                  │
│   .aidev/plans/current/     → Execução ativa (máx 1)           │
│         ↓ aidev done <sprint>   (repete por sprint)             │
│         ↓ aidev complete <id>                                    │
│                                                                  │
│   .aidev/plans/history/YYYY-MM/  → Concluída + snapshot         │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  SUPORTE (JSON como espelho, não fonte de verdade):             │
│  ├─ .aidev/state/checkpoint.md         (último estado legível)  │
│  ├─ .aidev/state/rollback-stack.json   (snapshots históricos)   │
│  ├─ .aidev/state/context-log.md        (quem fez o quê)         │
│  └─ .aidev/state/session-metrics.json  (tokens, duração)        │
│                                                                  │
│  IMPLEMENTAÇÃO:                                                  │
│  ├─ bin/aidev                          (CLI único)              │
│  └─ lib/feature-lifecycle.sh           (ÚNICO módulo de lifecycle│
│       funções: feature_plan, feature_start, feature_done,       │
│                feature_complete, + helpers)                      │
└─────────────────────────────────────────────────────────────────┘
```

---

### Sequência de Implementação Recomendada

**Sprint 1 — Verificação e Cleanup Seguro**
1. Auditar chamadas externas a `feature_complete()` e `feature_list_active()` (exportadas)
2. Adicionar deprecation warning em `aidev feature finish` → sugere `aidev complete`
3. Remover `.aidev/state/session.json`, `passports/`, `audit.log`
4. Verificar e remover `lib/auto-catalog.sh` e `lib/backlog.sh` se sem consumidores

**Sprint 2 — Consolidação de Código**
1. Remover `.aidev/lib/feature-lifecycle.sh` (após confirmar sem consumidores externos)
2. Absorver o que for único de `lib/plans.sh` em `lib/feature-lifecycle-cli.sh`
3. Remover `lib/plans.sh` e `cmd_feature()` de `bin/aidev`
4. Renomear `lib/feature-lifecycle-cli.sh` → `lib/feature-lifecycle.sh` (namespace unificado)
5. Padronizar funções de `flc_*` para `feature_*`
6. Atualizar `bin/aidev` para carregar novo módulo

**Sprint 3 — Migração do Estado de Suporte**
1. Migrar context-log de JSON para Markdown table em `.aidev/state/context-log.md`
2. Simplificar rollback-stack.json (manter estrutura, mas separar de unified.json)
3. Criar `session-metrics.json` como arquivo simples
4. Integrar cognitive_context como seção do `checkpoint.md`
5. Atualizar `checkpoint-manager.sh` para escrever no novo formato

**Sprint 4 — Validação e Documentação**
1. Executar suite completa de testes (`tests/unit/test-lifecycle-*.sh`)
2. Validar os 22 features históricos continuam acessíveis
3. Validar `aidev plan/start/done/complete` funcionam ponta a ponta
4. Atualizar `CLAUDE.md` com o fluxo único e obrigatório
5. Atualizar `orchestrator.md` com paths e comandos corretos
6. Criar `docs/feature-lifecycle.md` documentando decisão arquitetural

---

### Definição de Done para a Unificação

- [ ] Existe apenas **1 arquivo** de feature lifecycle (`lib/feature-lifecycle.sh`)
- [ ] `bin/aidev` carrega apenas **1 módulo** de lifecycle
- [ ] `aidev feature finish` foi removido ou redireciona com aviso
- [ ] Nenhuma função duplica outra com > 50% de sobreposição
- [ ] Todos os testes em `tests/unit/test-lifecycle-*.sh` passam
- [ ] `aidev plan/start/done/complete` funcionam ponta a ponta
- [ ] Context-log é legível em Markdown sem parser
- [ ] Rollback stack existe e `aidev rollback <id>` funciona
- [ ] Session metrics acessíveis via `aidev status`
- [ ] CLAUDE.md descreve apenas **1 fluxo** de execução

---

## Estimativas

| Métrica | Valor |
|---------|---|
| Sistemas identificados | 3 (não 2) |
| Linhas redundantes | ~1.824 |
| Funções duplicadas | 4 principais + 7 utilitárias |
| Arquivos a remover | 2 bibliotecas + 4 arquivos de state |
| Risco da unificação | MÉDIO (funções exportadas a verificar) |
| Sprints para unificação | 3-4 |
| Ganho líquido | ~1.800 linhas menos, 1 fonte de verdade |

---

*Documento gerado em 2026-02-23 via mesa de debates com Arquiteto, Backend/DevOps e QA/Produto.*
