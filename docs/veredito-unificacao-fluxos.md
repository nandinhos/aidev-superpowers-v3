# Veredito Arquitetural: Unificação de Fluxos de Execução (Sprints vs Plans)

**Data:** 23/02/2026
**Status:** Veredito do Orquestrador (via Conductor)

---

## 1. Análise Comparativa de Dinâmicas

Após análise direta da estrutura do framework e dos motores de lógica (`lib/`), identifiquei a coexistência de dois paradigmas distintos para a gestão de progresso:

### A. Fluxo de Sprints (`.aidev/state/sprints`)
*   **Paradigma:** Orientado a Dados (JSON-centric).
*   **Vantagem:** Precisão absoluta para consumo por agentes (baixo consumo de tokens, parsing determinístico via `jq`).
*   **Desvantagem:** Alta fricção e invisibilidade humana. Exige manutenção manual de um estado JSON complexo que frequentemente dessincroniza da realidade do código. No estado atual do projeto, este fluxo encontra-se frequentemente vazio, operando como um "motor fantasma".

### B. Fluxo de Lifecycle/Plans (`.aidev/plans`)
*   **Paradigma:** Orientado a Documento/Semântica (Markdown-centric).
*   **Vantagem:** Governança e Transparência. O progresso é representado pela movimentação física de arquivos e atualizações em tabelas Markdown. Segue o ciclo de vida do produto (`backlog` -> `features` -> `current` -> `history`).
*   **Desvantagem:** Maior verbosidade para a IA, exigindo parsing de texto para extrair tarefas e status.

---

## 2. O Diagnóstico de Conflito

Atualmente existe um **conflito de soberania**:
- O `unified.json` (memória de curto prazo da IA) busca o contexto de sprint no JSON.
- O desenvolvedor e a governança do projeto utilizam o Markdown de planos.
- **Resultado:** A IA frequentemente "alucina" que não há tarefas (pois o JSON está vazio) enquanto há uma funcionalidade ativa no diretório `current/`.

---

## 3. O Veredito: Soberania do Lifecycle Markdown

**A Fonte Única de Verdade (SSOT) do framework deve ser a pasta `.aidev/plans`.**

A dinâmica de "Sprints" baseada em JSON autônomo deve ser extinta como um fluxo independente. A unificação deve seguir os seguintes pilares:

1.  **Markdown como Input:** Toda e qualquer definição de tarefa nasce e reside nos arquivos Markdown de planos.
2.  **Estado como Output Automatizado:** O sistema de estado JSON deve tornar-se um **subproduto automático** das ferramentas CLI. O `lib/feature-lifecycle-cli.sh` deve ser evoluído para, ao ler o Markdown, "ejetar" o estado compilado para a IA.
3.  **Eliminação de Redundância:** O script `sprint.sh` e as subrotinas manuais do `sprint-manager.sh` devem ser removidos. Isso reduzirá a base de código em aproximadamente 300-500 linhas de lógica redundante.
4.  **Interface Unificada:** O comando `aidev` deve ser a única interface para o ciclo de vida (`plan`, `start`, `done`, `complete`), abstraindo toda a complexidade de sincronização de estado.

---

## 4. Conclusão

A unificação proposta trará **Unicidade de Contexto**. Ao forçar o Orquestrador a derivar seu estado a partir dos planos semânticos, garantimos que ele entenda o *valor de negócio* (Feature) e não apenas o *índice técnico* (Task ID). Isso elimina a dessincronização clássica onde a IA termina uma tarefa técnica mas perde o fio da meada da funcionalidade arquitetônica.

---
*Veredito emitido pelo Orquestrador em modo Agente, fundamentado na análise isenta de fluxos e na economia de tokens.*
