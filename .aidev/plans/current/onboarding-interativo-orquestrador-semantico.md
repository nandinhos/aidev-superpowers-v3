# Backlog - Onboarding Interativo e Orquestrador Semântico

## Visão Geral

Dois pontos críticos precisam ser addressed:

**Ponto A - Orquestrador Semântico:** O orquestrador atual classifica intents de forma limitada. Necessita aumentar a capacidade semântica para delegation correta, entendendo nuances do pedido do usuário e direcionando para os agentes/skills apropriados.

**Ponto B - Onboarding Interativo:** Após instalação (`aidev init`), o sistema deve fazer um onboarding interativo com o usuário para personalizar templates, entender necessidades específicas e configurar o ambiente. O agente de brainstorm deve fazer perguntas estruturadas após detectar stack e tipo de projeto (greenfield/brownfield).

**Origem**: Observações do usuário em 2026-02-25. O sistema não personaliza a experiência inicial e o orquestrador tem capacidade limitada de avaliação semântica.

---

## Problema Atual

### Ponto A - Orquestrador
1. Intent classification é baseada em keywords simples
2. Não entende contexto nuances (ex: "melhorar" pode ser refactor OU performance)
3. Delegação nem sempre é otimizada para o caso específico
4. Falta capacidade de追问 (follow-up questions)

### Ponto B - Onboarding
1. Após `aidev init`, sistema está "mudo" - não interage proativamente
2. Não detecta necessidades específicas do usuário
3. Templates são genéricos, não personalizados
4. Perda de oportunidade de coletar contexto valioso

---

## Solução Proposta

### Ponto A: Orquestrador Semântico Enhanced

```
Entrada do usuário → Análise Semântica Profunda → Classification + Confidence → Delegação Otimizada
```

**Melhorias:**
- Análise de contexto (projeto, stack, histórico)
- Intent Ambiguity Detection (detectar quando pedir clarification)
- Multi-intent Recognition (múltiplas intenções simultâneas)
- Context-aware routing (baseado em estado atual)
- Learning from feedback (adaptar baseado em confirmações do usuário)

### Ponto B: Onboarding Interativo

```
aidev init → Detectar Stack → Detectar Tipo (Greenfield/Brownfield) → Brainstorm Questions → Personalizar Templates → Salvar Contexto
```

**Fluxo de Perguntas (Brainstorm):**
1. Qual o objetivo principal do projeto?
2. Quais funcionalidades são prioritárias?
3. Há restrições técnicas ou de negócio?
4. Qual o nível de experiência da equipe?
5. Quais integrações são necessárias?
6. Há padrões de código estabelecidos?

---

## Tarefas Prioritárias

### 1. [HIGH] Análise Semântica para Intent Classification

**Descrição**: Aumentar capacidade do orquestrador de entender nuances

**Detalhes técnicos**:
- Substituir keyword-matching por análise semântica
- Adicionar "multi-intent" detection
- Calcular confidence score mais robusto
- Detectar ambiguidade e solicitar clarification
- Registrar padrões para learning

**Critério de sucesso**: Orquestrador entende variações de intent com >80% accuracy

---

### 2. [HIGH] Sistema de Clarification Automática

**Descrição**: Quando intent é ambíguo, orquestrador faz perguntas

**Detalhes técnicos**:
- Definir "ambiguity threshold" (ex: confidence < 0.6)
- Criar template de perguntas por tipo de ambiguidade
- Interativo: await resposta do usuário
- Atualizar intent após clarification

**Critério de sucesso**: Usuário nunca precisa corrigir delegação

---

### 3. [HIGH] Onboarding Interativo Pós-Instalação

**Descrição**: Após `aidev init`, rodar processo de descoberta

**Detalhes técnicos**:
- Novo comando ou flag: `aidev init --onboarding`
- Detectar stack (já existe)
- Detectar tipo: greenfield vs brownfield (já existe)
- Acionar agente brainstorm com questions customizadas
- Coletar respostas e salvar em `.aidev/state/onboarding.json`
- Usar respostas para personalizar templates

**Critério de sucesso**: Cada novo projeto tem configuração personalizada

---

### 4. [MEDIUM] Personalização Dinâmica de Templates

**Descrição**: Usar respostas do onboarding para gerar templates customizados

**Detalhes técnicos**:
- Ler `.aidev/state/onboarding.json`
- Para cada template em `templates/`:
  - Aplicar variáveis de personalização
  - Gerar versão customizada em `.aidev/`
- Criar arquivo de contexto: `.aidev/state/project-context.md`

**Critério de sucesso**: Templates refletem necessidades específicas do projeto

---

### 5. [MEDIUM] Documentação Viva do Projeto

**Descrição**: Criar documento que evolui com o projeto

**Detalhes técnicos**:
- `.aidev/docs/project-handbook.md`
- Seções: stack, padrões, integrações, decisões arquiteturais
- Atualizado automaticamente via onboarding + lições aprendidas
- Referência para novos membros (humanos ou IAs)

**Critério de sucesso**: Documento existe e é atualizado em milestones

---

## Fluxo Proposto - Onboarding

```
1. Usuario executa: curl -sSL ... | bash
2. Instalador pergunta: "Deseja inicializar agora? [y/N]"
3. Se sim:
   a. aidev init --onboarding
   b. Detectar stack → exibir
   c. Detectar tipo (greenfield/brownfield) → exibir
   d. "Vamos personalizar sua experiência?"
   e. Brainstorm questions:
      - Objetivo do projeto?
      - Features prioritárias?
      - Restrições técnicas?
      - Integrações necessárias?
   f. Salvar respostas em onboarding.json
   g. Gerar project-handbook.md
   h. Personalizar templates
   i. Exibir resumo: "Projeto configurado para: [resumo]"
4. Pronto para usar!
```

---

## Dependências

- `bin/aidev` (cmd_init)
- `.aidev/agents/orchestrator.md`
- `.aidev/skills/brainstorm/SKILL.md`
- `.aidev/state/onboarding.json` (novo)
- `.aidev/docs/project-handbook.md` (novo)
- `templates/agents/`

---

## Critérios de Aceitação

### Ponto A - Orquestrador
1. ✅ Intent classification com análise semântica (não só keywords)
2. ✅ Detecção de ambiguidade com clarification automática
3. ✅ Multi-intent recognition
4. ✅ Delegação otimizada baseada em contexto

### Ponto B - Onboarding
1. ✅ Após `aidev init`, processo de perguntas ao usuário
2. ✅ Respostas salvas em formato consultável
3. ✅ Templates personalizados baseados nas respostas
4. ✅ Documentação inicial do projeto criada

---

## Observações

- ** Diferencial competitivo**: O sistema não é "mais um" - é personalizado desde o primeiro uso
- **Documentação viva**: Tudo que é aprendido no onboarding vira referência
- **Onboarding como feature**: Não é "setup" - é descoberta de necessidades
- **Conexão com ideia 1**: Respostas do onboarding alimentam templates globais

---

## Referências

- Orquestrador atual: `.aidev/agents/orchestrator.md`
- Skill brainstorm: `.aidev/skills/brainstorm/SKILL.md`
- Template agents: `templates/agents/*.md.tmpl`
- Comando init: `bin/aidev` (cmd_init)
