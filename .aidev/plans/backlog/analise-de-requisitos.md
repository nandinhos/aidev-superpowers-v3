 Análise de requisitos para aplicação no Projeto Base — Aidev Agent

## Orquestrador de Desenvolvimento Assistido por IA

---

# 1️⃣ Objetivo Geral

Padronizar o comportamento do orquestrador para que qualquer interação do usuário siga um fluxo estruturado, previsível e rastreável, garantindo:

* Organização automática do backlog
* Estruturação formal de features
* Planejamento baseado em memória e lições aprendidas
* Execução incremental por sprints
* Continuidade segura do processo
* Redução de falhas operacionais

---

# 2️⃣ Fluxo Estruturado de Backlog

## 2.1 Problema Atual

Quando o usuário solicita a inclusão de um item no backlog:

* O item não está sendo salvo automaticamente na pasta correta
* Não segue o template padrão
* Não atualiza regime/registro automaticamente
* Não dispara fluxo posterior de refinamento

Isso quebra a padronização e compromete o processo.

---

## 2.2 Novo Fluxo Obrigatório

Sempre que o usuário mencionar **backlog**, o sistema deve:

### 🔹 Etapa 1 — Captura Estruturada

* Converter automaticamente a solicitação do usuário que solicitou salvamento em "backlog" utilizando do template padrão de backlog com detalhamento
* Salvar o arquivo na pasta:

```
/.aidev/plans/backlog
```

* Nomear conforme padrão definido

---

### 🔹 Etapa 2 — Confirmação

Após salvar:

* Exibir backlog estruturado ao usuário
* Perguntar:

  * O backlog está correto?
  * Deseja fazer alguma correção/alteração específica?
  * Deseja converter em feature agora?

---

### 🔹 Etapa 3 — Conversão para Feature

Se aprovado:

* Executar processo de brainstorm refinado, executanto perguntas para criar uma feature de auto padrão
* Acionar agente de refinamento
* Gerar arquivo na pasta:

```
.aidev/plans/features
```

A feature já deve conter:

* Visão geral
* Objetivo
* Escopo
* Sprints previamente estruturadas
* Critérios de aceite

---

# 3️⃣ Estrutura de Pastas e Movimentação de Arquivos

## 📂 .aidev/plans/

* backlog/
* features/
* current/ (Current Execution)
* history/ (local onde as tarefas concluidas são armazenadas de forma orzanizada conforme já estabelicido no projeto
* archive/ (para documentos que geram historico documental opcional)
* REAMDE.md (definição do estado do fluxo do momento, orientações conforme já existem no projeto)
* ROADMAP.md (aqui ficam as sprints que foram quebradas da feature, e onde temos uma visão daas tarefas realizadas das não atualizadas)


---

## 🔁 Regras de Movimentação

| Situação         | Ação                 |
| ---------------- | -------------------- |
| Backlog aprovado | Mover para Feature   |
| Feature iniciada | Criar entrada em Cge |
| Sprint ativa     | Atualizar Cge        |
| Sprint concluída | Atualizar histórico  |

Se necessário:

* Renomear arquivo
* Atualizar metadados
* Ajustar configurações internas

---

# 4️⃣ Execução por Sprint

A cada execução:

* Registrar progresso na pasta Cge
* Registrar:

  * O que foi feito
  * O que falta
  * Onde parou
  * Próximo passo

Objetivo:

> Garantir retomada segura mesmo após interrupções.

---

# 5️⃣ Validação Prévia Antes de Qualquer Execução

Antes de qualquer codificação, o orquestrador deve:

### 🔍 5.1 Verificação de Memória

Consultar:

* Basic Memory
* Memória semântica (Serena / MCPs)
* Lições aprendidas
* Histórico do projeto
* Últimos commits
* Pasta Plans

---

### 🎯 5.2 Objetivo

* Evitar retrabalho
* Aplicar lições aprendidas
* Garantir aderência a padrões
* Planejar antes de executar
* Reduzir falhas

---

# 6️⃣ Modo de Acionamento do Agente

## 6.1 Modo Agente Principal

Nome padrão:

```
Idev Agent
```

Função:

* Carregar orquestrador
* Inicializar ambiente
* Executar varredura inicial

---

## 6.2 Processo de Inicialização

Ao iniciar:

1. Verificar regras do orquestrador
2. Consultar índice de regras (não ler tudo)
3. Analisar:

   * Últimos commits
   * Pasta Plans
   * Backlog ativo
   * Feature ativa
   * Cge atual

---

# 7️⃣ Sistema de Índice de Regras

Problema:

* Leitura completa consome muitos tokens

Solução:

* Criar índice resumido de regras
* Consultar apenas a seção necessária
* Carregar regras sob demanda

---

# 8️⃣ Padronização de Fluxo

O sistema deve sempre:

1. Seguir o mesmo padrão de captura
2. Seguir o mesmo fluxo de organização
3. Fazer movimentação automática correta
4. Atualizar arquivos estruturados
5. Garantir rastreabilidade

Sem variações ad-hoc.

---

# 9️⃣ Novo Backlog: Auditoria de Conformidade

Criar backlog separado para:

## 🔎 Análise Global de Conformidade

### Escopo:

* Varredura completa:

  * Todos os projetos
  * Todas as memórias do Basic Memory
  * Memórias do Serena
  * Templates consolidados

### Objetivo:

* Confrontar lições aprendidas com documentação vigente
* Verificar conformidade
* Atualizar templates oficiais

---

# 10️⃣ Evolução dos Templates

Após validação:

* Incorporar lições aprendidas
* Atualizar templates padrão
* Transformar em regra formal
* Integrar nas skills do agente

Resultado esperado:

> Templates inteligentes, auto-evolutivos e alinhados com documentação real.

---

# 11️⃣ Resultado Final Esperado

Um orquestrador que:

* Estrutura backlog automaticamente
* Converte ideias em features refinadas
* Planeja antes de executar
* Consulta memória antes de codificar
* Trabalha com sprints organizadas
* Permite retomada segura
* Evolui seus próprios templates
* Reduz drasticamente falhas

DEVE SER FEITAR UMA ANALISE CRITERIOSA para que não tenhamos dois processos semelhentas existem no sistema. Considerando que estamos a cada dia refinando o projeto PODE EXISTIR alguma quebra nos fluxos, que contenha débitos técnicos que precisam ser corrigidos.

os comportamentos anomalos ou fora do que ele foi projetado, eu venho documentando e colocando para apreciação e verificação, com a expectativa de uma curadoria detalhada para tornar o orquestrador a melhor ferramenta para o desenvolvedor utilizar 