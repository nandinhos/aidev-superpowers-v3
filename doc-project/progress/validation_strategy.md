# Estratégia de Validação: Projeto "Espelho" (Dogfooding)

Para validar a **robustez** e o **agnosticismo** do sistema, não basta rodar testes unitários. Precisamos construir algo complexo usando o próprio processo que criamos.

## 🎯 Objetivo
Implementar um novo módulo **completo** no `aidev-superpowers` utilizando estritamente o fluxo do Orquestrador V3 (Meta-Planning -> TDD -> Review).

## 🧪 O Candidato: Módulo de Métricas e Telemetria (`lib/metrics.sh`)

Para "validar se o sistema cumpre o propósito", nada melhor que o sistema **se medir**.

### Por que esse módulo?
1.  **Complexidade Moderada**: Envolve I/O, persistência (JSON/SQLite?), e integração com todos os outros módulos (para medir uso).
2.  **Valor Real**: Responde à pergunta "O sistema está eficiente?" com dados (ex: tempo médio por task, taxa de erro de skills).
3.  **Teste de Stress**: Exige que o Orquestrador planeje uma arquitetura não-trivial (Event Bus vs Direct Calls).

## 📋 Plano de Execução (O Teste)

### 1. Meta-Planning (O Teste do Estrategista)
*   **Input**: "Crie um sistema para medir a performance dos agentes."
*   **Expectativa**: O Orquestrador deve identificar que precisa de:
    *   Estrutura de dados para logs estruturados.
    *   Hooks nos comandos existentes (`orchestrator_select_skill`, etc).
    *   Dashboard simples (`aidev stats`).

### 2. Agnostic Check (O Teste de Modelo)
*   Durante o desenvolvimento, revisaremos os prompts gerados.
*   *Pergunta*: "Esse prompt funcionaria no Claude 3.5? No GPT-4o? No Gemini 1.5 Pro?"
*   *Ação*: Refinar templates (`.tmpl`) para remover "sotaques" de modelos específicos, focando em instruções lógicas claras e contexto purificado.

### 3. Resilience Check (O Teste de Auto-Cura)
*   Introduziremos falhas propositais (ex: permissão negada ao gravar log) para ver se o `try_with_recovery` atua corretamente num fluxo complexo.

## 🔄 Ciclo de Melhoria Contínua
Para cada fricção encontrada durante esse piloto:
1.  **Diagnosticar**: É falha do Prompt? Do Processo? Da Ferramenta?
2.  **Corrigir**: Atualizar `templates/` ou `lib/`.
3.  **Padronizar**: Criar uma nova `Rule` ou `Skill` para evitar recorrência.

---
**Status**: Aguardando aprovação para iniciar o Meta-Planning do Módulo de Métricas.
