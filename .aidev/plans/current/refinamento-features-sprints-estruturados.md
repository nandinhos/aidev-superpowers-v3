# Backlog - Refinamento e Execução de Features com Sprints Estruturados

## Visão Geral

O fluxo atual de backlog → features → current → history não está sendo respeitado pelas LLMs, que "pulam" etapas, alucinam caminhos e não seguem a metodologia padronizada. O objetivo é criar um workflow rigoroso que force a obediência à estrutura, com snapshots frequentes para garantir continuidade em caso de rate limits.

**Origem**: Observação do usuário em 2026-02-25. LLMs estão desviando do fluxo estabelecido, causando inconsistência no desenvolvimento.

---

## Problema Atual

1. **LLMs pulam etapas**: Ideias saem do backlog sem passar por refinamento completo
2. **Falta validação**: Features não são validadas antes de irem para execução
3. **Sem sprints estruturados**: Features não são expandidas em sprints rápidas, lógicas e testáveis
4. **Arquivos temporários ausentes**: Não há geração dinâmica de arquivos de sprint em `current/`
5. **ROADMAP desatualizado**: Não há atualização dinâmica durante execução
6. **Checkpoint inadequado**: Snapshot não é feito com frequência suficiente para continuidade em rate limits

---

## Fluxo Proposto

```
backlog/ideia.md 
    ↓ [aidev refine <id>] → agente brainstorm
    ↓ refinamento com usuário
    ↓ [VALIDADA] → moves para features/
    ↓ [aidev start <id>] → documentação completa + expansão em sprints
    ↓ cria current/<sprint-1-titulo>.md
    ↓ execução com atualização dinâmica do ROADMAP
    ↓ [aidev done <sprint-id>] → snapshot + próximo sprint
    ↓ ...
    ↓ [aidev complete <id>] → history/YYYY-MM/
```

---

## Tarefas Prioritárias

### 1. [HIGH] Workflow de Refinamento com Brainstorm

**Descrição**: Criar processo formal de refinamento que transforma ideia brutas em features validadas

**Detalhes técnicos**:
- Comando: `aidev refine <backlog-id>`
- Aciona agente `brainstorm` para refinamento
- Processo iterativo com usuário até validação
- Gera documento de refinamento com:
  - Problema claramente definido
  - Solução proposta
  - Escopo definido
  - Critérios de aceitação
  - Estimativa de sprints
- Ao final: opção de mover para `features/` como [VALIDADA]

**Critério de sucesso**: Ideia passa por refinamento antes de se tornar feature

---

### 2. [HIGH] Expansão Automática de Feature em Sprints

**Descrição**: Ao mover feature para current, expandir automaticamente em sprints estruturados

**Detalhes técnicos**:
- Feature em `features/` deve ter meta-sprints planejados
- Ao executar `aidev start <id>`:
  - Criar arquivo temporário em `current/<sprint-1-titulo>.md`
  - Cada sprint deve ter: título, objetivo, tarefas (TDD), critérios de aceite
  - Sprints devem ser: rápidos (1-2h), lógicos, categorizáveis, testáveis
- Atualizar ROADMAP com status dinâmico

**Critério de sucesso**: Feature executada sprint a sprint com arquivos temporários

---

### 3. [HIGH] Atualização Dinâmica do ROADMAP

**Descrição**: ROADMAP deve atualizar automaticamente durante execução

**Detalhes técnicos**:
- A cada `aidev start`, `done`, `complete`: atualizar ROADMAP
- Mostrar: feature atual, progresso de sprints, próximas ações
- Histórico de sprints concluídos no período
- Status: backlog → features → current → history

**Critério de sucesso**: ROADMAP reflete estado real a qualquer momento

---

### 4. [HIGH] Snapshot Frequente (Rate Limit Protection)

**Descrição**: Snapshot automático após cada sprint para continuidade

**Detalhes técnicos**:
- A cada `aidev done <sprint-id>`:
  - Criar checkpoint completo
  - Atualizar unified.json
  - Gerar activation_snapshot.json
  - Registrar: sprints concluídos, próxima ação, estado dos artefatos
- Garantir que em caso de rate limit, próximo contexto Start com o estado exato

**Critério de sucesso**: Perda máxima de 1 sprint em caso de rate limit

---

### 5. [MEDIUM] Gate de Validação de Fluxo

**Descrição**: Impedir que LLMs pulem etapas do workflow

**Detalhes técnicos**:
- `aidev start` só funciona se feature está em `features/`
- `aidev done` só funciona se há sprint em execução em `current/`
- `aidev complete` só funciona se todos sprints concluídos
- Checkpoints de validação entre transições

**Critério de sucesso**: LLMs não conseguem pular etapas

---

### 6. [MEDIUM] Readme Dinâmico por Sessão

**Descrição**: Atualizar README de cada módulo (backlog, features, current, history) dinamicamente

**Detalhes técnicos**:
- `backlog/README.md`: lista ideias + status (bruta → refinando → validada)
- `features/README.md`: lista features + sprints planejados
- `current/README.md`: sprint atual + progresso + próximos passos
- `history/YYYY-MM/README.md`: consolidado do período

**Critério de sucesso**: READMEs sempre atualizados

---

## Dependências

- `bin/aidev` (comandos: refine, start, done, complete)
- `.aidev/plans/ROADMAP.md`
- `.aidev/skills/brainstorm/SKILL.md`
- `.aidev/lib/workflow-sync.sh`

---

## Critérios de Aceitação

1. ✅ Ideias passam por refinamento antes de se tornarem features
2. ✅ Features são expandidas em sprints estruturados com arquivos temporários
3. ✅ ROADMAP atualiza dinamicamente durante execução
4. ✅ Snapshot feito após cada sprint (proteção contra rate limits)
5. ✅ LLMs não conseguem pular etapas do workflow
6. ✅ READMEs atualizados automaticamente
7. ✅ Em rate limit, continuidade garantida com perda máxima de 1 sprint

---

## Observações

- **Fluxo atual**: Existe mas não é respeitado
- **Objetivo**: Fortalecer gates e automatizar transições
- **Proteção**: Foco em rate limit - snapshots frequentes
- **Obrigatório**: Toda LLM deve seguir o fluxo rigorosamente

---

## Referências

- Estrutura de planos: `.aidev/plans/`
- Feature lifecycle: `.aidev/lib/feature-lifecycle.sh`
- Workflow sync: `.aidev/lib/workflow-sync.sh`
- Skill brainstorm: `.aidev/skills/brainstorm/SKILL.md`
