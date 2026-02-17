# Checklist de Validação e Evolução

Fase atual: **Stress Test (Cenário Completo)**

O objetivo é validar se o sistema cumpre seu propósito (apoio inteligente, robusto e padronizado) através da execução de um fluxo complexo e análise de telemetria.

- [x] **Definição do Piloto de Validação**
    - [x] Definição de métricas e arquitetura
- [x] **Implementação do Módulo de Métricas**
    - [x] Arquitetura (Meta-Planning) e Core (TDD)
    - [x] Integração no Orquestrador e CLI
- [x] **Cenário de Validação: "The Legacy Calculator"** (Stress Test)
    - [x] **1. Orquestração e Design**: Agente Architect define estrutura de uma Calculadora de ROI (Node.js).
    - [x] **2. Execução com Falha Planejada**: Agente Backend cria código com bug (divisão por zero ou input não tratado).
    - [x] **3. Auto-Cura e Memória**: 
        - [x] Sistema detecta falha nos testes.
        - [x] Aciona skill `systematic-debugging`.
        - [x] Corrige e salva `learned-lesson`.
    - [x] **4. Finalização**: Agente Frontend cria interface.
    - [x] **5. Auditoria de Métricas**: Verificar se `aidev metrics` registrou os agentes, falhas e tempos corretamente.
- [x] **Refinamento Final (Smart Context)**
    - [x] **Detecção de Maturidade**: Implementar `detect_maturity` e `detect_style` na lib.
    - [x] **Lógica de Inicialização**: Atualizar `aidev init` (Checar PRD em Greenfield / Diagnostics em Brownfield).
    - [x] **Refinamento de Prompts**: Atualizar templates (`orchestrator.md.tmpl`) com injeção de `CONTEXT_INSTRUCTIONS`.
    - [x] **Validação**: Script `tests/manual_verify_smart_context.sh` criado e executado.
