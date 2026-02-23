# Veredito Arquitetural: Evolução do Runtime AI Dev Superpowers

**Data:** 23/02/2026
**Status:** Aprovado pela Mesa de Debates (Orquestrador, Conductor, Architect, Backend, QA, DevOps, Security)

## 1. Visão Geral
Este documento consolida o entendimento técnico e o plano de ação para sanar os gaps de execução declarativa identificados no backlog do projeto. A premissa central é que **configuração sem runtime é dead code**.

## 2. Pontos de Decisão: Tríade de Integração

### 2.1 MCP Standardized Activation
- **Decisão:** Implementar detecção dinâmica de stack antes de gerar/carregar o `.mcp.json`.
- **Mecanismo:** `stack-detector.sh` -> `mcp-config-generator.sh`.
- **Health Check:** Bloqueio preventivo de ferramentas caso o container/serviço dependente esteja offline.

### 2.2 Rules Engine (Taxonomia e Injeção)
- **Decisão:** Adotar a hierarquia `Projeto > Stack > Global`.
- **Injeção:** O `rules-loader.sh` gerará payloads específicos para cada LLM (Claude, Gemini, etc.), garantindo que as regras estejam sempre no topo do contexto.
- **Validação:** Implementar hooks obrigatórios de pré-commit para validar padrões de linguagem e formato.

### 2.3 Trigger Engine (Lessons Learned Loop)
- **Decisão:** Transformar o YAML estático em uma Engine ativa (`trigger-processor.sh`).
- **Ação:** O processador será acionado nos milestones de cada sprint (Checkpoints), monitorando keywords de sucesso/erro para disparar proativamente a captura de lições.

## 3. Contribuição do Conductor: Ciclo de Vida e Rastreabilidade
O Conductor atua como o framework de governança que sustenta este veredito através de:
- **Gestão de Tracks:** Cada fase deste roadmap é convertida em uma Track oficial no `conductor/tracks.md`, garantindo que a evolução técnica seja rastreável e auditável.
- **Protocolo de Verificação:** O Conductor exigirá a validação de cada tarefa através de seus planos de implementação (`plan.md`), impedindo o avanço para a próxima fase sem o cumprimento rigoroso dos critérios de aceitação.
- **Ponto de Verdade Canônica:** O Conductor reforça o uso de `.aidev/rules/` como o único repositório de padrões, utilizando sua autoridade de orquestração para bloquear desvios ad-hoc.

## 4. Arquitetura de Precedência e Anti-Duplicação
- **Local Canônico:** `.aidev/rules/` é o único local permitido para definições de padrões.
- **Intervenção:** O orquestrador deve bloquear a criação de pastas como `standards/` ou `conventions/` ad-hoc, realizando o merge automático para o local canônico.

## 5. Roadmap de Execução (Sprints)

1. **Sprint 1 (Fundação):** 
   - Implementação do `stack-detector.sh`.
   - Implementação do `rules-loader.sh` (Injeção via System Instruction).
2. **Sprint 2 (Percepção):**
   - Desenvolvimento da Engine de Triggers (`trigger-processor.sh`).
   - Automação do skill `learned-lesson`.
3. **Sprint 3 (Governança):**
   - Hooks de validação pré-commit.
   - Dashboard de Compliance e métricas de aderência.

---
*Documento gerado e validado pelo Orchestrator em modo Agente, sob a governança do Conductor.*
