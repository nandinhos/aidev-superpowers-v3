# Initial Concept
O AI Dev Superpowers é um framework que configura agentes especializados, skills e regras para guiar IAs de código (Claude Code, Antigravity, Gemini, Cursor, etc.) a trabalharem com TDD Mandatório, YAGNI, DRY e Evidências.

# AI Dev Superpowers V3

## Visão do Produto
O AI Dev Superpowers é um framework de código aberto projetado para transformar assistentes de IA em desenvolvedores seniores altamente eficientes. Ele foca na aplicação rigorosa de padrões de engenharia de software e na otimização da interação entre humanos e IAs.

## Público-Alvo
- **Desenvolvedores:** Que buscam elevar a qualidade do código produzido com auxílio de IA.
- **AI Power Users:** Usuários avançados de ferramentas como Claude Code e Gemini CLI que necessitam de fluxos de trabalho otimizados e consistentes.

## Objetivos Estratégicos
1. **Aplicação de TDD (Test-Driven Development):** Garantir que o desenvolvimento siga o ciclo RED-GREEN-REFACTOR, resultando em código testado e resiliente.
2. **Arquitetura de Agentes Modulares:** Prover uma estrutura onde diferentes especialistas (backend, frontend, qa, devops) possam colaborar de forma coordenada.
3. **Eficiência de Tokens:** Minimizar o consumo de tokens e reduzir o tempo de latência através de técnicas avançadas de compressão de contexto e snapshots de ativação.

## Funcionalidades Principais
- **Ativação Ultra-Rápida:** Uso de snapshots (`activation_snapshot.json`) para inicializar o contexto do agente em milissegundos.
- **Gestão de Estado Persistente:** Manutenção de sessões e histórico entre diferentes execuções e tipos de agentes.
- **Ecossistema de Skills e Triggers:** Automação de tarefas repetitivas e resposta inteligente a eventos do repositório.

## Princípios de Design e UX
- **Customização e Flexibilidade:** O framework deve ser adaptável a diferentes linguagens e stacks, permitindo que o usuário ajuste regras e comportamentos.
- **Comunicação em Português (PT-BR):** Toda a interação e documentação de suporte prioriza o idioma local para facilitar a adoção e clareza.
