# Validation Scenario: "The Broken Calculator"

**Objetivo**: Exercitar todos os músculos do sistema (Orquestrador, Memória, Agentes, Métricas) em um único fluxo contínuo.

## 🎭 O Roteiro

Vamos simular a criação de uma **Calculadora de ROI (Return on Investment)** simples, mas com uma "armadilha" para testar a resiliência.

### Passo 1: O Pedido (Trigger)
*   **User Request**: "Crie uma ferramenta CLI em Node.js para calcular ROI, arquitetada pelo Architect, codada pelo Backend."
*   **Expectativa**: Orquestrador aloca `architect` para planejar e depois `backend` para executar.

### Passo 2: A Falha Planejada (The Trap)
*   **Ação**: Pediremos explicitamente que o código *não* trate validação de inputs inicialmente.
*   **Bug**: Rodaremos um teste passando `cost = 0`.
*   **Expectativa**:
    1.  O teste falha (Erro: DivisionByZero ou Infinity).
    2.  O Orquestrador percebe o status `failed` na skill `test-driven-development`.
    3.  O Orquestrador ativa a skill `systematic-debugging`.

### Passo 3: A Recuperação e Memória (The Fix)
*   **Ação**: O agente deve diagnosticar, corrigir (adicionar `if cost === 0 return error`) e passar no teste.
*   **Memória**: O sistema deve gerar uma lição aprendida: "Sempre validar denominador em cálculos financeiros".

### Passo 4: Verificação de Telemetria (The Proof)
*   Ao final, rodaremos `aidev metrics`.
*   **Devemos ver:**
    *   `agent_activate`: Architect (1x), Backend (1x), QA (talvez).
    *   `skill_execution`:
        *   `writing-plans` (Architect) -> Status: `completed`
        *   `test-driven-development` (Backend) -> Status: `failed` (primeira tentativa)
        *   `systematic-debugging` -> Status: `completed`
        *   `test-driven-development` -> Status: `completed` (segunda tentativa)

## 🛠️ Comandos de Execução

1.  **Reset de Métricas (Opcional)**: `rm .aidev/state/metrics.log` (para ver limpo).
2.  **Prompt Inicial**:
    ```text
    Atuar como Architect. Crie o plano para uma CLI 'roi-calc' em Node.js.
    Depois, atue como Backend e implemente seguindo TDD, mas NÃO valide divisão por zero ainda.
    ```
3.  **Prompt de Correção (se não for automático)**:
    ```text
    O teste falhou com cost=0. Corrija usando systematic-debugging e salve a lição.
    ```
4.  **Auditoria**: `aidev metrics`.
