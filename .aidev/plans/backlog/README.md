# Backlog - Ideias Futuras

> Ideias brutas que aguardam refinamento e priorização para se tornarem features.

---

## Fluxo

```
backlog/ (ideia) → refine (brainstorm) → features/ (planejada) → current/ (executando) → history/YYYY-MM/ (concluída)
```

**Regras:**
- Backlog contém ideias sem sprint definida
- Ao priorizar: criar plano completo em `features/` e remover daqui
- Nunca iniciar implementação a partir do backlog diretamente

---

## Priorização por Dependência e Complexidade

### Análise de Dependências

| Item | Depende de | Bloqueia |
|------|------------|----------|
| 1. Retroalimentação Templates | #2, #3 | nenhuma |
| 2. Rules Engine | - | #1, #5 |
| 3. Learned Lesson Trigger | - | #1 |
| 4. Instalador Global | - | #6 |
| 5. Refinamento Features | - | #7, #8 |
| 6. Onboarding Interativo | #4 (corrigir install) | - |
| 7. Automação Sync | - | #5 |
| 8. Avaliação Skills | - | #1 |

### Order de Implementação Proposta

| Fase | Item | Motivo |
|------|------|--------|
| **Fase 1** | #4 (Instalador) | Bug crítico, Blocker para #6 |
| **Fase 1** | #6 (Onboarding) | Experiência inicial, depende de #4 |
| **Fase 2** | #7 (Sync Unificado) | Infraestrutura base, suporta #5 |
| **Fase 2** | #5 (Refinamento Features) | Workflow, depende de #7 |
| **Fase 3** | #2 (Rules Engine) | Base para retroalimentação |
| **Fase 3** | #3 (Trigger Gap) | Complementa rules engine |
| **Fase 4** | #1 (Retroalimentação) | Integra tudo, ciclo virtuoso |
| **Fase 5** | #8 (Skills Ferramentas) | Evolução das skills |

---

## Ideias Pendentes

### 1. [PRIORIDADE ALTA] Sistema de Retroalimentação de Templates

**Arquivo:** [retroalimentacao-templates-curadoria-licoes.md](retroalimentacao-templates-curadoria-licoes.md)
**Status:** backlog
**Prioridade:** Alta
**Fase:** 4 (depende de #2, #3)
**Criado:** 2026-02-26

**Descrição:** Ciclo virtuoso onde lições aprendidas são classificadas (local/global), passam por curadoria (MCPs) e são promotionadas a regras/templates globais.

---

### 2. [PRIORIDADE ALTA] Rules Engine - Carregamento e Injeção

**Arquivo:** [rules-engine-standardization.md](rules-engine-standardization.md)
**Status:** backlog
**Prioridade:** Alta
**Fase:** 3
**Criado:** 2026-02-20

**Descrição:** Mecanismo que carrega, injeta no contexto da LLM e valida o cumprimento de regras de codificação definidas em `.aidev/rules/`.

---

### 3. [PRIORIDADE ALTA] Gap no Fluxo de Lições Aprendidas

**Arquivo:** [learned-lesson-trigger-gap.md](learned-lesson-trigger-gap.md)
**Status:** backlog
**Prioridade:** Alta
**Fase:** 3
**Criado:** 2026-02-20

**Descrição:** Trigger YAML existe mas não há runtime que o consuma. Engine de triggers para ativar skill `learned-lesson` automaticamente.

---

### 4. [PRIORIDADE CRÍTICA] Bug: Instalador Global Não Instala no Projeto

**Arquivo:** [instalador-global-nao-instala-projeto.md](instalador-global-nao-instala-projeto.md)
**Status:** backlog
**Prioridade:** CRÍTICA
**Fase:** 1
**Criado:** 2026-02-26

**Descrição:** Ao executar `curl | bash` e aceitar inicializar, output mostra "0 Diretórios" mas nada é criado. Apenas `aidev init` manual funciona.

---

### 5. [PRIORIDADE ALTA] Refinamento e Execução de Features com Sprints Estruturados

**Arquivo:** [refinamento-features-sprints-estruturados.md](refinamento-features-sprints-estruturados.md)
**Status:** backlog
**Prioridade:** Alta
**Fase:** 2
**Criado:** 2026-02-26

**Descrição:** Workflow rigoroso que força LLMs a seguir: backlog → refine (brainstorm) → features → current/sprints → history. Com snapshots frequentes para rate limit protection.

---

### 6. [PRIORIDADE ALTA] Onboarding Interativo + Orquestrador Semântico

**Arquivo:** [onboarding-interativo-orquestrador-semantico.md](onboarding-interativo-orquestrador-semantico.md)
**Status:** backlog
**Prioridade:** Alta
**Fase:** 1 (depende de #4)
**Criado:** 2026-02-26

**Descrição:** Após instalação, processo interativo de descoberta com perguntas ao usuário. + Aumento da capacidade semântica do orquestrador para delegation correta.

---

### 7. [PRIORIDADE MÉDIA] Automatização do Sync de Estado Unificado

**Arquivo:** [automatizacao-sync-unified.md](automatizacao-sync-unified.md)
**Status:** backlog
**Prioridade:** Média
**Fase:** 2
**Criado:** 2026-02-26

**Descrição:** Hooks automáticos para sync após done/complete/checkpoint. Alertas quando estado desatualizado.

---

### 8. [PRIORIDADE MÉDIA] Avaliação e Evolução das Skills

**Arquivo:** [avaliacao-skills-ferramentas.md](avaliacao-skills-ferramentas.md)
**Status:** backlog
**Prioridade:** Média
**Fase:** 5
**Criado:** 2026-02-26

**Descrição:** Transformar skills de arquivos .md passivos em ferramentas CLI acionáveis (skill start, skill step, skill complete).

---

## Ideias Concluídas / Removidas

| Ideia | Status | Data |
|-------|--------|------|
| Sistema de Atualização Interativa | Concluído em `history/2026-02/` | 2026-02-18 |
| MCP Universal Install | Removido (fora de escopo) | 2026-02-18 |
| Basic Memory Graceful Integration | Movido para `features/` | 2026-02-20 |
| Automação do Ciclo de Vida de Features | Concluido em history/ | 2026-02-20 |
| Workthrees - Orquestrador Inteligente | Concluido em history/ | 2026-02-23 |
| Fix: AIDEV_ROOT single source | Concluido em history/ | 2026-02-23 |

---

## Legenda de Fases

| Fase | Descrição | Items |
|------|-----------|-------|
| 1 | Foundation (Instalação + Onboarding) | #4, #6 |
| 2 | Infraestrutura (Sync + Workflow) | #5, #7 |
| 3 | Base de Conhecimento (Rules + Triggers) | #2, #3 |
| 4 | Ciclo Virtuoso (Retroalimentação) | #1 |
| 5 | Evolução (Skills Ferramentas) | #8 |

---

*Ultima atualizacao: 2026-02-26*
