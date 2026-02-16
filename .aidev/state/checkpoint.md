# Checkpoint - 2026-02-16

## Concluido
- Refinamento v1: CLAUDE.md, generic.md, orchestrator.md, AI_INSTRUCTIONS.md, writing-plans (commit c8d3e46)
- Sprint 1 do plano v4.4: Sistema de Manifesto (commit b9b565e)
- Sprint 2 do plano v4.4: Motor de Upgrade seguro com checksum e dry-run (commit a49145c)
- Sprint 3 do plano v4.4: Guardrails de Execucao LLM
  - lib/llm-guard.sh criado (5 funcoes publicas: validate_scope, enforce_limits, log_decision, audit, pre_check)
  - templates/rules/llm-limits.md.tmpl criado (template de limites imutaveis)
  - tests/unit/test-llm-guard.sh criado (27 assertions, todas passando)
  - lib/loader.sh integrado (llm-guard no mapa de deps com core, file-ops, manifest, state)
  - lib/sprint-guard.sh integrado (hook para llm_guard_pre_check no final de guard_check)
  - bin/aidev cmd_init() integrado (install_llm_limits chamado apos install_rules)

## Em Progresso
- Plano de refinamento v4.4: Sprint 3 concluido, Sprint 4 pendente

## Proximo Passo
- Commit do Sprint 3
- Iniciar Sprint 4: Cobertura de Testes + Bugfixes Criticos

## Contexto Necessario
- .aidev/plans/backlog/refinamento-framework-v4.4.md (plano completo)
- bin/aidev linha ~2243 e ~3705 (cmd_feature duplicado - bug a corrigir no Sprint 4)
- bin/aidev linha ~283 (cmd_upgrade nao reinstala rules - bug a corrigir no Sprint 4)

## Decisoes Tomadas
- llm_guard_validate_scope bloqueia apenas core (never_modify_in_project) e state (never_overwrite)
- user (never_touch) NAO eh bloqueado pela LLM - a LLM cria planos e escreve em plans/
- enforce_limits le MAX_FILES_PER_CYCLE e MAX_LINES_PER_FILE de llm-limits.md
- Defaults: MAX_FILES=10, MAX_LINES=200 (quando arquivo nao existe)
- audit.log usa formato texto (append), nao JSON, para simplicidade e performance
- Hook no sprint-guard eh graceful (|| true) - nao bloqueia se llm-guard falhar
- test-runner.sh tem bug pre-existente: basic-memory test interrompe execucao dos demais
