# Análise Arquitetural: Fluxos de Execução (Sprints vs Plans)

**Data:** 23/02/2026
**Objetivo:** Avaliar a coexistência de duas dinâmicas de rastreamento de tarefas no framework AI Dev Superpowers (`.aidev/state/sprints` vs `.aidev/plans`) e propor um veredito para unificação.

---

## 1. O Cenário Atual (Arquitetura Dual)

O projeto atualmente mantém dois "motores" de estado operando em paralelo, com propósitos que se sobrepõem e acabam gerando confusão de contexto e débitos técnicos.

### A. Fluxo "Sprints" (`.aidev/state/sprints/`)
Gerenciado por `lib/sprint-manager.sh` e `sprint.sh`.
- **Mecânica:** Baseado inteiramente em JSON (`sprint-status.json`).
- **Características:**
  - Mantém o estado da sprint (`in_progress`, `completed`), progresso numérico (`completed` de `total`).
  - Indica a `next_action` e o `current_task`.
  - É fortemente integrado com o `unified.json` via a subrotina `sprint_sync_to_unified()`.
- **Vantagens:** Excelente para parser de máquina (fácil leitura pelo Orchestrator via JQ).
- **Desvantagens:** É uma "caixa preta" para o humano. Não tem rastreabilidade histórica natural (exige que arquivos JSON sejam movidos para uma pasta `history/`, escondendo o contexto semântico). Não é voltado a "Features" de produto, apenas a uma lista temporal de tarefas curtas.

### B. Fluxo "Plans / Feature Lifecycle" (`.aidev/plans/`)
Gerenciado por `lib/feature-lifecycle-cli.sh` (comandos `aidev plan`, `start`, `done`, `complete`).
- **Mecânica:** Baseado em movimentação de artefatos Markdown pelo File System.
- **Características:**
  - Pipeline claro de produto: `backlog` -> `features` -> `current` -> `history/YYYY-MM/`.
  - Garante visualização imediata por humanos via `README.md` autogerados e `ROADMAP.md`.
  - Dispara nativamente a engine de Checkpoints (`ckpt_create`) sempre que avança de fase.
- **Vantagens:** Perfeito para governança ágil. Muito amigável ao desenvolvedor. Mantém a história do que foi idealizado vs o que foi feito visível e pesquisável.
- **Desvantagens:** É predominantemente descritivo. Os LLMs precisam ler Markdown (gasto maior de tokens) em vez de um objeto JSON condensado para saber "o que fazer a seguir".

---

## 2. Diagnóstico de Conflito

Ter os dois ativos significa que:
1. **Redundância:** O orquestrador solicita tarefas à Sprint em JSON, mas o desenvolvedor move arquivos Markdown em `plans/`. Frequentemente, a Sprint JSON fica vazia enquanto o `plan/current` tem a feature real (como aconteceu no fechamento da Sprint 5).
2. **Ciclo de Vida Quebrado:** `sprint-manager.sh` não enxerga nativamente qual a "Feature" vinculada na pasta `current/`. Eles operam como silos isolados, unidos apenas pelo fato de que ambos cospem `checkpoints` na pasta `.aidev/state/checkpoints`.
3. **Complexidade Cognitiva:** Ter que rodar `aidev start-sprint` e depois `aidev start feature-X`.

---

## 3. Proposta de Unificação (O Padrão Ouro)

Como apontado, **o fluxo da pasta `plans` é imensamente superior** do ponto de vista de rastreabilidade, PDD (Plan-Driven Development) e clareza para o projeto, alinhado à filosofia do componente Conductor. O fluxo de Sprints JSON reflete um design mais antigo.

### Veredito Recomendado: Extinguir Sprints JSON autônomas em favor do Lifecycle Markdown

**Como deve funcionar a conversão:**
1. **Feature como Cidadão de Primeira Classe:** A pasta `plans/current` passa a ser a única e verdadeira "Sprint Ativa". O conceito de Sprint solta morre; uma Sprint passa a ser simplesmente "A execução da Feature X contida em `current/`".
2. **Adapter JSON (Proxy de Contexto):** Em vez de mantermos o arquivo `sprint-status.json` sendo alimentado manualmente por comandos, ele passará a ser um arquivo cache/gerado (`compiled-state.json`). O `feature-lifecycle-cli.sh` fará parsing do Markdown atual e ejetará automaticamente o progresso para o JSON unificado, servindo estritamente como "View Rápida" para os agentes IA pouparem tokens.
3. **Depreciação Controlada:** 
   - Remover comandos obsoletos: `aidev sprint status`, `sprint update-task`.
   - Adotar exclusivamente: `aidev plan`, `aidev feature start`, `aidev feature complete`.
   - Mover os artefatos históricos de Sprints para um log textual dentro de `archive/` e apagar o diretório `.aidev/state/sprints`.

### Conclusão
Manter o fluxo `plans/` como verdade canônica aproxima a IA do negócio. Eliminar a lógica duplicada no `sprint-manager.sh` reduzirá a base de código do framework, facilitará a injeção de contexto (pois o Orquestrador só precisará ler nativamente os arquivos Markdown dos planos) e evitará a dessincronização clássica onde a máquina acha que "não há tarefas" (sprint-status vazio) enquanto o humano tem uma funcionalidade arquitetônica parada no backlog.
