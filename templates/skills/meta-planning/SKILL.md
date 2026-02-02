---
name: meta-planning
description: Estrategia deliberada e analise de requisitos antes da execucao
triggers:
  - "planejar"
  - "estrategia"
  - "analisar pedido"
globs:
  - "**/*"
---

# Meta-Planning Skill

## Propósito
Evitar execucao robotica ("Task-List Driven") e promover entendimento estrategico ("Goal Driven").
Esta skill deve ser rodada SEMPRE antes de qualquer implementacao complexa.

## Processo

1. **Deconstruct**: Quebre o pedido do usuario em Objetivos Implicitos e Explicitos.
2. **Contextualize**: Relacione o pedido com licoes aprendidas e arquitetura atual.
3. **Strategize**: Defina a abordagem.
   - *Exemplo*: "Em vez de criar arquivo X, vou refatorar Y para evitar duplicacao."
4. **Plan**: Gere a lista de tarefas.

## Output
Gere um `implementation_plan.md` ou atualize o `task.md` com uma secao de estrategia clara.
