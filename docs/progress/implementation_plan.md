# Implementation Plan: Metrics & Telemetry Module

**Contexto**: Piloto de Validação (Dogfooding).
**Objetivo**: Implementar sistema de observabilidade para medir performance de agentes e skills.

## 🧠 Meta-Planning Analysis

### Desconstrução do Pedido
*   **Goal**: "Medir performance".
*   **Implicit Needs**: Baixo overhead (não deixar o sistema lento), armazenamento persistente mas simples, visualização rápida via CLI.
*   **Constraints**: Bash-based (manter consistência com o core), dependência apenas de `jq`.

### Decisões Estratégicas
1.  **Storage Agnostic**: Usar formato **JSONL (JSON Lines)** em `.aidev/state/metrics.log`.
    *   *Por que?* Append-only é atômico e rápido em filesystem. Fácil de parsear com `jq` linha a linha sem carregar arquivo todo na memória.
2.  **Instrumentation Points (Hooks)**:
    *   `lib/agents.sh`: Registrar start/finish de agentes.
    *   `lib/skills.sh`: Registrar uso de skills e sucesso/falha.
    *   `lib/mcp.sh`: (Futuro) Medir latência de chamadas MCP.
3.  **Visualization**: Novo comando `aidev metrics` que agrega os dados on-the-fly usando `jq`.

## 🏗️ Proposed Changes

### 1. Novo Módulo Core: `lib/metrics.sh`
*   **Função**: `metrics_track_event(type, name, duration, status, metadata)`
*   **Função**: `metrics_start_timer(event_id)` -> retorna timestamp
*   **Função**: `metrics_stop_timer(event_id)` -> calcula delta e grava

### 2. Instrumentação (Modify Existing Files)
#### [MODIFY] `lib/orchestration.sh`
*   Adicionar chamadas de métricas nas funções `agent_activate`, `skill_run`.
*   Capturar falhas de recuperação (`try_with_recovery`) como eventos de métrica.

### 3. Nova Interface CLI
#### [MODIFY] `bin/aidev`
*   Novo subcomando `metrics`.
*   Flags: `--summary` (padrão), `--agent <name>`, `--skill <name>`.

## 🧪 Verification Plan (TDD First)

### Automated Tests (`tests/unit/test-metrics.sh`)
1.  **Test Storage**: Gravar um evento e verificar se o JSONL está válido.
2.  **Test Performance**: Gravar 1000 eventos e medir impacto (deve ser < 50ms).
3.  **Test Aggregation**: Simular logs e verificar se o cálculo de "sucesso %" bate.

### Manual Verification
1.  Rodar `aidev start` (modo simulação).
2.  Verificar se `.aidev/state/metrics.log` foi criado.
3.  Rodar `aidev metrics` e ver o dashboard.
