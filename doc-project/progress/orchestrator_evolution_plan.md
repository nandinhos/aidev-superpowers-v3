# Plano de Evolução: Orquestrador Incrível

Este documento apresenta a análise do sistema atual e a proposta de transformação do Orquestrador do AI Dev Superpowers V3 para um nível "Extremamente Incrível".

## 1. Diagnóstico do Estado Atual

O orquestrador atual (`lib/orchestration.sh`) é **funcional e determinístico**, mas **reativo e estático**.

| Característica | Estado Atual | Limitação |
|----------------|--------------|-----------|
| **Classificação de Intent** | Regex (`grep "fix|bug"`) | Não entende nuances ou solicitações complexas/híbridas. |
| **Seleção de Skills** | Mapeamento 1:1 (`feature -> brainstorming`) | Rigidez. Não permite fluxos customizados (ex: "pesquise antes de codar"). |
| **Contexto** | Raso (Stack, Plataforma, Fase) | "Amnésia" de curto prazo. Não usa lições aprendidas proativamente. |
| **Resiliência** | Passiva (Falha e para) | O usuário precisa intervir a cada erro de comando. |
| **Personalidade** | Robótica | Apenas coordena, não "opina" ou "lidera". |

## 2. A Visão: "Extremamente Incrível"

Um orquestrador incrível não apenas segue ordens; ele **antecipa necessidades**, **recupera-se sozinho** e **aprende**.

### Pilares da Evolução

#### 1. 🧠 Dynamic Strategy Engine (O Estrategista)
Em vez de um mapeamento fixo (Intent -> Skill), o orquestrador gera um **Plano de Execução Dinâmico**.
*   **Como funciona**: Ao receber um pedido, ele desenha um grafo de steps.
*   **Exemplo**: "Criar login com OAuth" -> "Padrão detectado: Auth" -> "Passos: 1. Verificar libs existentes, 2. Design de dados, 3. TDD".

#### 2. 🛡️ Auto-Recovery Reflex (O Resiliente)
Se um comando falha, o orquestrador tenta consertar *antes* de reportar erro.
*   **Loop Autônomo**: Falha no teste? -> Tenta ler o erro -> Aplica correção óbvia -> Retesta. Só escala para o usuário se falhar 2x.

#### 3. 📚 Deep Context & Memory (O Sábio)
Injeção proativa de conhecimento.
*   **Memory Injection**: Ao entrar em um arquivo, o orquestrador avisa: "Cuidado, você já teve bugs de concorrência neste módulo semana passada (Lição #12)."
*   **Project Awareness**: Entende a arquitetura macro, não apenas o arquivo aberto.

#### 4. ⚡ "Flash" Actions (O Proativo)
Execução paralela de tarefas de "zeladoria".
*   Enquanto o usuário pensa/digita, o orquestrador roda linters, atualiza índices ou verifica dependências em background.

## 3. Plano de Implementação

### Fase 1: Inteligência de Contexto (Deep Context)
*   [ ] **Melhoria no `orchestrator_get_context`**: Incluir resumo de `lessons/` relevantes (busca vetorial ou keyword matching simples).
*   [ ] **Snapshot Inteligente**: Incluir árvore de arquivos e "pontos de calor" (arquivos muito editados).

### Fase 2: Robustez (Auto-Recovery)
*   [ ] **Wrapper de Execução**: Criar função `try_with_recovery` que captura exit codes.
*   [ ] **Agente "Doctor" Integrado**: Se `npm install` falha, o orquestrador roda `aidev doctor` ou limpa cache automaticamente.

### Fase 3: Dinamismo (Strategic Planner)
*   [ ] **Novo Prompt do Orquestrador**: Substituir a tabela estática por instruções de "Drafting a Plan".
*   [ ] **Skill "Meta-Planning"**: Uma skill rápida de 1 step para definir a estratégia antes de executar.

## 4. Exemplo de Fluxo "Incrível"

**Usuário**: "O login via Google parou de funcionar."

**Orquestrador Atual**:
1. Detecta "parou de funcionar".
2. Ativa skill `systematic-debugging`.
3. Pede para você criar teste de reprodução.

**Orquestrador Incrível**:
1. Analisa pedido + Contexto.
2. *Pensamento*: "Login Google envolve API Keys e Callbacks. Verifiquei `.env` e parece ok."
3. **Ação Proativa**: "Rodei os testes de auth e vi que o endpoint `/callback` está retornando 500. Parece erro de parsing."
4. **Proposta**: "Já ativei o `systematic-debugging` e criei um harness de teste para esse endpoint. Quer que eu tente corrigir o parsing do JSON?"

---

Este plano transforma o Orquestrador de um "Capa-tarefas" para um **Parceiro Sênior**.
