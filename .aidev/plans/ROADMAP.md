# 🗺️ ROADMAP AI DEV SUPERPOWERS

> Documento mestre de planejamento do Framework
> Status: Ativo | Versão Atual: v4.0.0 (Estável)

---

## 🎯 OBJETIVO
Tornar o AI Dev Superpowers o framework de orquestração de IA mais robusto, multiplataforma e inteligente, com foco em automação de tarefas complexas e persistência de contexto.

---

## 📅 SPRINT 3: Context Monitor & Auto-Checkpoint (CONCLUÍDA) ✨
**Objetivo:** Sistema de monitoramento de contexto, checkpoints automáticos e integração com Basic Memory.  
**Período:** 2026-02-11 → 2026-02-12  
**Versão:** v3.10.2  
**Status:** ✅ 100% Completa (4/4 tasks)

### Funcionalidades:
- [x] **3.1 - Context Monitor** (`lib/context-monitor.sh`):
  - Monitoramento de uso de tokens em tempo real
  - Estimativa inteligente com heurística 4 chars/token
  - Triggers: 70% warning, 85% auto-checkpoint, 95% force-save
  - **60 testes unitários** passando
  
- [x] **3.2 - Checkpoint Manager** (`lib/checkpoint-manager.sh`):
  - Gestão completa de checkpoints automáticos
  - Funções: `ckpt_create`, `ckpt_list`, `ckpt_get_latest`, `ckpt_generate_restore_prompt`
  - Formato JSON com estado completo + snapshots
  - **18 testes unitários** passando
  
- [x] **3.3 - Comando `aidev restore`**:
  - Subcomandos: `aidev restore --list`, `--latest`, `<checkpoint-id>`
  - Geração de prompts de continuidade para LLM
  - **17 testes de integração** passando
  
- [x] **3.4 - Basic Memory Integration**:
  - Schema mapping completo (checkpoint → nota Markdown)
  - Sync automático configurável (`CKPT_SYNC_BASIC_MEMORY`)
  - Busca semântica de checkpoints
  - **24 testes** passando
  - **Economia de tokens: 60%+** na inicialização

### Impacto:
- 🎯 **119 testes** criados e passando
- 💰 **60%+ economia** de tokens na inicialização
- 🔄 **Persistência ilimitada** de contexto entre sessões
- 🔍 **Busca semântica** de checkpoints históricos

---

## 📅 SPRINT 4: UX Intuitiva & Self-Healing (CONCLUÍDA)
**Objetivo:** Melhorar a interface CLI e capacidade de auto-detecção.  
**Período:** 2026-02-06 → 2026-02-11  
**Versão:** v3.9.0

### Funcionalidades:
- [x] **4.1 - aidev doctor --fix**:
  - Comandos para reparar estrutura de pastas, permissões e caches corrompidos (Portabilidade v3.8.0).
- [x] **4.2 - Dashboards de Progresso**:
  - Visualização rica do Roadmap no terminal com barras de progresso.
  - Sprint Manager com 51 testes automatizados.
- [x] **4.3 - Advanced Context Snapshotter**:
  - Filtros por funcionalidade, otimização de tokens e inclusão de arquivos externos via CLI.
- [x] **4.4 - Sprint Manager Integration**:
  - Sistema unificado de gestão de sprints com `lib/sprint-manager.sh`.
  - Dashboard visual na inicialização do agente.
  - Sincronização automática entre sprint-status.json e unified.json.

---

## 📅 SPRINT 5: Orquestração por Estado Ubíquo (CONCLUÍDA) ✨
**Objetivo:** Transformar o aidev na "Âncora de Verdade" para colaboração entre diferentes LLMs (Claude Code, Gemini CLI, Antigravity) através de persistência de estado agnóstica e reconstrução cognitiva.
**Período:** 2026-02-12 → 2026-02-12
**Versão:** v4.0.0 (Major)
**Status:** ✅ 100% Completa (14/14 tasks)

### Funcionalidades:
- [x] **5.1 - Protocolo Universal de Handoff** (65 testes):
  - Checkpoints com `cognitive_context` hibrido (chain_of_thought, hypothesis, mental_model, observations, confidence, decisions_pending)
  - Prompt de restauracao enriquecido com secao CONTEXTO COGNITIVO condicional
  - Comando CLI `aidev handoff` (create/resume/status) com flags --cot, --hypothesis, --mental-model, --observations
  - Integracao com Basic Memory incluindo campos cognitivos
  
- [x] **5.3 - Handoff Agnostico de Tooling** (43 testes):
  - Modulo `lib/fallback-generator.sh` com 5 funcoes de geracao de Markdown
  - Integracao com checkpoint-manager via `CKPT_GENERATE_FALLBACK=true`
  - Comando CLI `aidev fallback` (generate/show/clean)
  - Artefatos: last-checkpoint.md, sprint-context.md, active-files.md, reconstruction-guide.md

- [x] **5.2 - Sync de Roadmap em Tempo Real** (13 testes):
  - Mecanismo de "Context Git" onde cada ação gera um micro-log que mantém a sprint sincronizada, independente de qual CLI está sendo usada.
  - Módulo `lib/context-git.sh` com rotação de logs e renderização de timeline.
  - Comando CLI `aidev log` para visualização em tempo real.

- [x] **5.4 - Autonomia de Alinhamento de Sprint** (12 testes):
  - Módulo `lib/sprint-guard.sh` com scoring de alinhamento semântico.
  - O Orquestrador detecta automaticamente desvios da tarefa ativa e alerta o usuário.
  - Comando CLI `aidev guard` para verificação manual de alinhamento.

---

## 📊 MÉTRICAS DO PROJETO

### Testes
- **Sprint 5**: 133 testes (100% passando)
- **Sprint 3**: 119 testes (100% passando)
- **Sprint 2**: 101 testes
- **Sprint 1**: 59 testes
- **Total**: 412+ testes automatizados

### Versões
- **Atual**: v4.0.0 (Estado Ubíquo)
- **Anterior**: v3.10.2 (Elegant Cache UX)
- **Próxima**: v4.1.0 (Smart Upgrade)

### Economia de Tokens
- Sprint 3: 60%+ economia com Basic Memory
- Custo de inicialização: 1.600 → 550 tokens

---

## 📅 SPRINT 6: Auto-Cura & Smart Upgrade (EM CURSO) 🛠️
**Objetivo:** Implementar o merge inteligente de atualizações e reforçar a auto-cura do sistema.
**Versão:** v4.1.0
**Status:** 🏗️ Iniciada

### Funcionalidades:
- [ ] **6.1 - Smart Upgrade Merge**:
  - Proteção de customizações do usuário durante o `aidev upgrade`.
  - Sistema de fingerprints de templates.
- [ ] **6.2 - Advanced Error Recovery**:
  - Melhorias no `error_handler` para sugerir correções automáticas baseadas na KB.

---

**Última atualização:** 2026-02-12  
**Próximo Passo:** Feature 6.1 (Smart Upgrade Merge)

---

*Roadmap gerenciado por AI Dev Superpowers v4.0.0*
