# Sprint 5: Orquestracao por Estado Ubiquo

**Versao Alvo**: v4.0.0 (Major)
**Status**: Planejada
**Data Planejamento**: 2026-02-12
**Decisoes do PO**: Todas aprovadas

---

## Objetivo

Transformar o aidev na "Ancora de Verdade" para colaboracao entre diferentes LLMs (Claude Code, Gemini CLI, Antigravity) atraves de persistencia de estado agnostica e reconstrucao cognitiva.

---

## Decisoes de Design (Aprovadas pelo PO)

| Feature | Decisao | Alternativas Descartadas |
|---------|---------|--------------------------|
| 5.1 Contexto Cognitivo | **Hibrido** (JSON + campo livre) | Schema puro, String livre |
| 5.2 Micro-logs | **Log rotacionado** (ultimas N entradas) | Append-only, Basic Memory |
| 5.4 Sprint Guard | **Scoring + warning** (nao bloqueia) | Warning simples, Bloqueio |
| Ordem | **5.1 -> 5.3 -> 5.2 -> 5.4** | Outras sequencias |

---

## Feature 5.1: Protocolo Universal de Handoff

### Problema
Checkpoints atuais guardam *estado* (JSON), mas nao guardam *intencao* nem *raciocinio*. Quando outra LLM assume, perde o "modelo mental" do que estava sendo feito.

### Solucao
Enriquecer checkpoints com `cognitive_context` hibrido:

```json
{
  "checkpoint_id": "ckpt-...",
  "cognitive_context": {
    "chain_of_thought": "string livre - raciocinio em andamento",
    "current_hypothesis": "string - hipotese ativa",
    "mental_model": "string - como o fluxo funciona",
    "decisions_pending": ["array de decisoes em aberto"],
    "blocked_by": "string ou null",
    "confidence": 0.8,
    "observations": "campo livre para notas adicionais"
  },
  "reconstruction_prompt": "Prompt gerado automaticamente para proxima LLM"
}
```

### Tasks

#### Task 5.1.1: Extender schema do checkpoint
- **Arquivo**: `lib/checkpoint-manager.sh`
- **Acao**: Adicionar campo `cognitive_context` ao JSON gerado por `ckpt_create()`
- **Parametros novos**: `cot` (chain of thought), `hypothesis`, `mental_model`
- **Testes**: 8-10 testes unitarios
- **Tempo estimado**: 30 min

#### Task 5.1.2: Enriquecer prompt de restauracao
- **Arquivo**: `lib/checkpoint-manager.sh`
- **Acao**: Atualizar `ckpt_generate_restore_prompt()` para incluir contexto cognitivo
- **Output**: Prompt mais rico com "Voce estava pensando em X, sua hipotese era Y"
- **Testes**: 5-6 testes
- **Tempo estimado**: 20 min

#### Task 5.1.3: Comando CLI para handoff
- **Arquivo**: `bin/aidev`
- **Acao**: Novo subcomando `aidev handoff` que cria checkpoint enriquecido
- **Subcomandos**: `aidev handoff create`, `aidev handoff resume`, `aidev handoff status`
- **Testes**: 10-12 testes de integracao
- **Tempo estimado**: 40 min

#### Task 5.1.4: Integracao com Basic Memory
- **Arquivo**: `lib/checkpoint-manager.sh`
- **Acao**: Extender `ckpt_to_basic_memory_note()` com campos cognitivos
- **Testes**: 5 testes
- **Tempo estimado**: 15 min

---

## Feature 5.3: Handoff Agnostico de Tooling

### Problema
Claude Code tem MCP (Basic Memory, Serena), Gemini CLI nao. Artefatos em MCP sao inacessiveis para LLMs sem MCP.

### Solucao
Gerar "Fallback Artifacts" em Markdown puro automaticamente:

```
.aidev/state/fallback/
├── last-checkpoint.md          # Checkpoint legivel
├── sprint-context.md           # Sprint status formatado
├── active-files.md             # Arquivos em trabalho com snippets
└── reconstruction-guide.md     # Guia completo de retomada
```

### Tasks

#### Task 5.3.1: Criar modulo fallback-generator
- **Arquivo novo**: `lib/fallback-generator.sh`
- **Funcoes**: `fallback_generate_all()`, `fallback_checkpoint_to_md()`, `fallback_sprint_to_md()`, `fallback_files_to_md()`, `fallback_guide_to_md()`
- **Testes**: 15-18 testes unitarios
- **Tempo estimado**: 45 min

#### Task 5.3.2: Integrar com checkpoint-manager
- **Arquivo**: `lib/checkpoint-manager.sh`
- **Acao**: Chamar `fallback_generate_all()` dentro de `ckpt_create()`
- **Config**: `CKPT_GENERATE_FALLBACK=true` (ativavel)
- **Testes**: 5 testes
- **Tempo estimado**: 15 min

#### Task 5.3.3: Comando CLI para fallback
- **Arquivo**: `bin/aidev`
- **Acao**: `aidev fallback` - gera/mostra artefatos de fallback
- **Subcomandos**: `aidev fallback generate`, `aidev fallback show`, `aidev fallback clean`
- **Testes**: 8-10 testes de integracao
- **Tempo estimado**: 30 min

---

## Feature 5.2: Sync de Roadmap em Tempo Real

### Problema
Progresso so e atualizado no fim de tasks. Outra LLM nao sabe o que aconteceu *durante* a execucao.

### Solucao
"Context Git" - micro-logs rotacionados por acao:

```json
{
  "context_log": {
    "max_entries": 50,
    "entries": [
      {
        "ts": "2026-02-12T10:00:00Z",
        "llm": "claude-code",
        "action": "edit_file",
        "target": "lib/foo.sh:45",
        "intent": "corrigir bug na funcao X",
        "sprint_task": "task-5.1.1"
      }
    ]
  }
}
```

### Tasks

#### Task 5.2.1: Criar modulo context-git
- **Arquivo novo**: `lib/context-git.sh`
- **Funcoes**: `ctxgit_log()`, `ctxgit_get_recent()`, `ctxgit_rotate()`, `ctxgit_render_timeline()`, `ctxgit_get_by_llm()`
- **Config**: `CTXGIT_MAX_ENTRIES=50`, `CTXGIT_ENABLED=true`
- **Storage**: `.aidev/state/context-log.json`
- **Testes**: 15-18 testes unitarios
- **Tempo estimado**: 45 min

#### Task 5.2.2: Integrar com sprint-manager
- **Arquivo**: `lib/sprint-manager.sh`
- **Acao**: Chamar `ctxgit_log()` em pontos chave (start_task, complete_task, checkpoint)
- **Testes**: 5-6 testes
- **Tempo estimado**: 20 min

#### Task 5.2.3: Integrar com unified.json
- **Arquivo**: `lib/sprint-manager.sh` ou `lib/state.sh`
- **Acao**: Adicionar `context_log_summary` ao sync do unified.json
- **Testes**: 5 testes
- **Tempo estimado**: 15 min

#### Task 5.2.4: Comando CLI para context-git
- **Arquivo**: `bin/aidev`
- **Acao**: `aidev log` - visualizar timeline de acoes
- **Subcomandos**: `aidev log show`, `aidev log clear`, `aidev log --llm claude`
- **Testes**: 8 testes de integracao
- **Tempo estimado**: 25 min

---

## Feature 5.4: Autonomia de Alinhamento de Sprint

### Problema
LLM pode desviar da task ativa sem que ninguem perceba.

### Solucao
"Sprint Guard" com scoring de alinhamento:

```bash
sprint_guard_check() {
    local action_description="$1"
    local score=$(calculate_alignment_score "$action_description")
    
    if (( $(echo "$score < $GUARD_THRESHOLD" | bc -l) )); then
        warn "[SPRINT GUARD] Score: $score - Acao pode estar desalinhada"
        warn "Task ativa: $(sprint_get_current_task)"
        warn "Acao proposta: $action_description"
    fi
}
```

### Tasks

#### Task 5.4.1: Criar modulo sprint-guard
- **Arquivo novo**: `lib/sprint-guard.sh`
- **Funcoes**: `guard_check()`, `guard_calculate_score()`, `guard_get_threshold()`, `guard_get_active_keywords()`, `guard_render_status()`
- **Config**: `GUARD_THRESHOLD=0.3`, `GUARD_ENABLED=true`
- **Testes**: 12-15 testes unitarios
- **Tempo estimado**: 40 min

#### Task 5.4.2: Integrar com orchestrator agent
- **Arquivo**: `.aidev/agents/orchestrator.md`
- **Acao**: Adicionar instrucao para consultar sprint guard antes de acoes
- **Testes**: 3-4 testes
- **Tempo estimado**: 15 min

#### Task 5.4.3: Comando CLI para guard
- **Arquivo**: `bin/aidev`
- **Acao**: `aidev guard` - status do alinhamento
- **Subcomandos**: `aidev guard status`, `aidev guard check "descricao"`, `aidev guard threshold 0.5`
- **Testes**: 6-8 testes de integracao
- **Tempo estimado**: 25 min

---

## Resumo de Estimativas

| Feature | Tasks | Testes Estimados | Tempo Estimado |
|---------|-------|------------------|----------------|
| 5.1 Handoff Universal | 4 | ~30 | ~1h45 |
| 5.3 Handoff Agnostico | 3 | ~30 | ~1h30 |
| 5.2 Sync Tempo Real | 4 | ~35 | ~1h45 |
| 5.4 Sprint Guard | 3 | ~25 | ~1h20 |
| **Total** | **14 tasks** | **~120 testes** | **~6h20** |

## Arquivos Novos

| Arquivo | Feature |
|---------|---------|
| `lib/fallback-generator.sh` | 5.3 |
| `lib/context-git.sh` | 5.2 |
| `lib/sprint-guard.sh` | 5.4 |
| `tests/unit/test-fallback-generator.sh` | 5.3 |
| `tests/unit/test-context-git.sh` | 5.2 |
| `tests/unit/test-sprint-guard.sh` | 5.4 |

## Arquivos Modificados

| Arquivo | Features |
|---------|----------|
| `lib/checkpoint-manager.sh` | 5.1, 5.3 |
| `lib/sprint-manager.sh` | 5.2 |
| `bin/aidev` | 5.1, 5.2, 5.3, 5.4 |
| `.aidev/agents/orchestrator.md` | 5.4 |
| `.aidev/state/unified.json` | 5.2 |

## Dependencias entre Features

```
5.1 Handoff Universal ──→ 5.3 Handoff Agnostico (usa schema de 5.1)
                      └──→ 5.2 Sync Tempo Real (independente, pode paralelizar)
5.4 Sprint Guard ──→ independente (pode comecar em paralelo com 5.2)
```

## Criterios de Aceitacao

- [ ] Todos os testes passando (120+ novos)
- [ ] Checkpoint com cognitive_context funcional
- [ ] Fallback artifacts gerados em Markdown
- [ ] Context-git registrando e rotacionando logs
- [ ] Sprint Guard calculando score de alinhamento
- [ ] Novos comandos CLI (`handoff`, `fallback`, `log`, `guard`)
- [ ] Documentacao atualizada no ROADMAP.md
- [ ] Compatibilidade retroativa com checkpoints existentes

---

**Proximo Passo**: Aprovacao do PO -> Iniciar Task 5.1.1
