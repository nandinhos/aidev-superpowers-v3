# Blueprint: Fase 4 - Automação e Inteligência

A Fase 4 foca em transformar o **AI Dev Superpowers** de um framework passivo para um sistema proativo que antecipa necessidades do desenvolvedor e garante continuidade perfeita entre diferentes LLMs.

## 🎯 Objetivos Principais

1.  **Bridging Contextual (Multi-LLM)**: Criar um mecanismo de "Snapshot de Contexto" para migração instantânea entre Claude, Gemini e Antigravity.
2.  **Auto-Cura (Self-Healing)**: O CLI deve detectar falhas de ambiente e sugerir correções antes mesmo do usuário notar.
3.  **Proatividade Agêntica**: Agentes que sugerem o próximo Sprint ou Tarefa baseados no estado do repositório.

---

## 📅 Roadmap Detalhado

### Sprint 1: Context Snapshotter (O "Salto Quântico")
*   **Problema**: Ao trocar de chat (ex: atingiu limite no Claude e vai para o Gemini), perde-se o fio da meada.
*   **Solução**: `aidev snapshot`.
    *   Gera um bloco de Markdown denso contendo:
        - Meta-contexto (Fase/Sprint atual).
        - Resumo dos últimos 5 planos de implementação.
        - Grafo de dependências atualizado.
        - "Lições aprendidas" da sessão atual.
*   **Resultado**: O usuário cola esse snapshot no novo chat e a IA assume o controle imediatamente.

### Sprint 2: Doctor Autônomo e Reparo Proativo
*   **Problema**: O usuário roda um comando, falha por falta de dependência, e ele tem que lembrar de rodar o `doctor`.
*   **Solução**: Integração do `doctor` no loop de feedback do CLI.
    *   Monitoramento de permissões em tempo de execução.
    *   Comando `aidev doctor --fix` para aplicar correções automáticas (ex: criar pastas faltando, injetar gitignore).

### Sprint 3: Inteligência de Orquestração (Multi-Agent V2)
*   **Problema**: O Orquestrador às vezes é genérico demais.
*   **Solução**: "Skills Dinâmicas".
    *   O Orquestrador pode "aprender" novos fluxos a partir de arquivos `.agent/workflows/*.md`.
    *   Injeção automática de regras contextuais baseada nos arquivos abertos no editor.

---

## ✍️ Filosofia de Documentação (Antes vs Depois)

### 1. Documentação "Antes" (Contrato)
*   **O que**: `implementation_plan.md` e `task.md`.
*   **Por que**: Define o "O Quê" e o "Como" sem ambiguidade. Evita desperdício de tokens em caminhos errados.
*   **Onde**: Salvo em `docs/plans/` para histórico de design.

### 2. Documentação "Acompanhamento" (Pulso)
*   **O que**: `aidev status` e `session.json`.
*   **Por que**: Mantém a verdade única sobre o progresso em tempo real.

### 3. Documentação "Depois" (História)
*   **O que**: `walkthrough.md`, `README.md` e `CHANGELOG.md`.
*   **Por que**: Serve como prova de trabalho e manual para o "Eu" do futuro (ou para outros desenvolvedores/IAs).
