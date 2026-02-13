# Protocolo de Execução de Sprints - AI Dev Superpowers

**Documento de Gestão e Continuidade**  
**Versão**: 1.0  
**Data**: 2026-02-11  
**Status**: Ativo  

---

## Visão Geral

Este protocolo estabelece a dinâmica de execução das sprints de implementação do Sistema de Validação Automática, garantindo:

- ✅ **Continuidade** mesmo com rate limits ou interrupções
- ✅ **Rastreabilidade** total do progresso
- ✅ **Handoffs** claros entre sessões
- ✅ **Recuperação** automática de estado
- ✅ **Controle** granular por você (Product Owner)

---

## Arquitetura de Gestão

### 1. Estrutura de Arquivos de Status

```
.aidev/state/sprints/
├── current/                          # Sprint ativa
│   ├── sprint-status.json            # Status geral
│   ├── task-001/                     # Diretório por task
│   │   ├── status.json               # Status da task
│   │   ├── checkpoint-001.json       # Checkpoints
│   │   └── decisions.md              # Decisões tomadas
│   ├── task-002/
│   └── ...
├── history/                          # Sprints concluídas
│   ├── sprint-2026-02-11-foundation/
│   └── ...
└── blocked/                          # Tasks bloqueadas
    └── task-XXX-blocked.json
```

### 2. Formato de Status da Sprint

**`.aidev/state/sprints/current/sprint-status.json`**:

```json
{
  "sprint_id": "sprint-1-foundation",
  "sprint_name": "Sprint 1: Foundation",
  "status": "in_progress",
  "start_date": "2026-02-11T10:00:00Z",
  "target_end_date": "2026-02-25T10:00:00Z",
  "last_updated": "2026-02-11T15:30:00Z",
  "current_task": "task-1.1-validators",
  "overall_progress": {
    "total_tasks": 5,
    "completed": 2,
    "in_progress": 1,
    "pending": 2,
    "blocked": 0
  },
  "session_context": {
    "last_llm_session": "2026-02-11T15:30:00Z",
    "tokens_used_in_session": 45000,
    "rate_limit_hits": 0,
    "checkpoints_created": 8
  },
  "next_action": {
    "task_id": "task-1.1-validators",
    "step": "implement_validate_safe_path",
    "description": "Implementar função validate_safe_path",
    "estimated_tokens": 2000
  },
  "risks": [],
  "notes": "Progresso normal, dentro do prazo"
}
```

### 3. Formato de Status por Task

**`.aidev/state/sprints/current/task-001/status.json`**:

```json
{
  "task_id": "task-1.1-validators",
  "task_name": "Criar estrutura de validadores",
  "status": "in_progress",
  "priority": "high",
  "estimated_time": "40 min",
  "actual_time": "25 min",
  "progress": {
    "total_steps": 6,
    "completed_steps": 4,
    "current_step": 5,
    "percentage": 67
  },
  "steps": [
    {
      "step_id": 1,
      "name": "setup_test_structure",
      "status": "completed",
      "completed_at": "2026-02-11T10:15:00Z",
      "artifacts": [".aidev/tests/validators.test.sh"]
    },
    {
      "step_id": 2,
      "name": "implement_validate_safe_path",
      "status": "in_progress",
      "started_at": "2026-02-11T10:30:00Z",
      "notes": "Implementando lista de paths proibidos"
    },
    {
      "step_id": 3,
      "name": "implement_validate_commit_format",
      "status": "pending"
    }
  ],
  "artifacts": {
    "created": [".aidev/tests/validators.test.sh"],
    "modified": [],
    "deleted": []
  },
  "blockers": [],
  "decisions": [
    {
      "timestamp": "2026-02-11T10:20:00Z",
      "decision": "Usar array de paths proibidos em vez de regex",
      "rationale": "Maior legibilidade e manutenção"
    }
  ]
}
```

---

## Fluxo de Execução

### Ciclo de Vida de uma Task

```
PENDING → IN_PROGRESS → [CHECKPOINTS...] → REVIEW → COMPLETED
              ↓
         BLOCKED (se necessário)
              ↓
         RESUME (quando desbloqueado)
```

### 1. Início de Task

**Ações automáticas:**
1. Atualiza `current_task` no sprint-status.json
2. Cria diretório `task-XXX/` com status.json inicial
3. Registra timestamp de início
4. Atualiza ROADMAP.md com progresso

**Comando:**
```bash
aidev sprint start-task task-1.1-validators
```

### 2. Durante Execução (a cada 10 min ou ação crítica)

**Criação de Checkpoint:**
```bash
aidev sprint checkpoint \
  --task task-1.1-validators \
  --step "implement_validate_safe_path" \
  --status "completed" \
  --artifacts ".aidev/lib/validators.sh" \
  --notes "Função implementada, testes passando"
```

**O que é salvo no checkpoint:**
- Estado atual do código
- Tokens utilizados
- Testes executados e resultados
- Decisões tomadas
- Próximo passo planejado

### 3. Fim de Task

**Ações:**
```bash
aidev sprint complete-task task-1.1-validators \
  --artifacts ".aidev/lib/validators.sh,.aidev/tests/validators.test.sh" \
  --tests-passed true \
  --time-actual "40min"
```

**Atualizações automáticas:**
- Move task para "completed"
- Atualiza progresso geral
- Gera resumo da task
- Propõe próxima task

---

## Sistema de Continuidade (Rate Limit / Interrupção)

### Cenário 1: Rate Limit Atingido

**Detecção automática:**
```bash
# Quando detecta rate limit:
1. Cria checkpoint de emergência
2. Salva estado exato (arquivo sendo editado, linha atual)
3. Atualiza sprint-status.json com:
   - "interruption_reason": "rate_limit"
   - "resume_point": "exact location"
   - "estimated_resume": "time when limit resets"
```

**Recuperação:**
```bash
# Na próxima sessão:
aidev sprint resume
# ou
aidev sprint status  # Mostra onde parou

# Saída:
# 🔄 Sprint 1: Foundation (67% completa)
# 📍 Última task: task-1.1-validators
# ⏸️  Interrompido em: implement_validate_commit_format
# 📄 Arquivo: .aidev/lib/validators.sh (linha 45)
# 💡 Ação: Continuar implementação da função
```

### Cenário 2: Nova Sessão (dia seguinte)

**Protocolo de Retomada:**
```bash
aidev sprint resume

1. Lê sprint-status.json
2. Identifica task atual
3. Lê último checkpoint
4. Mostra resumo:
   - O que foi feito ontem
   - O que falta fazer
   - Arquivos em modificação
   - Testes pendentes

5. Pergunta: "Continuar de onde paramos ou revisar primeiro?"
```

### Cenário 3: Handoff para Você (Product Owner)

**Quando necessário:**
- Decisão arquitetural complexa
- Validação de abordagem
- Priorização de tarefas
- Resolução de conflito

**Formato do handoff:**
```markdown
# Handoff: Sprint 1 - Task 1.3

## Contexto
Implementando Context Passport, cheguei em decisão sobre schema.

## Opções
1. **Opção A**: Schema flat (mais simples, menos tokens)
2. **Opção B**: Schema nested (mais organizado, extensível)

## Recomendação
Opção B, pois permite evolução sem breaking changes.

## Código Atual
[link para arquivo ou diff]

## Próximo Passo
Aguardando sua decisão para continuar.

---
Checkpoint: cp-2026-02-11-143022
```

---

## Comandos CLI de Gestão

### Status e Visibilidade

```bash
# Status geral da sprint
aidev sprint status
# Saída:
# 📊 Sprint 1: Foundation
# Progresso: 67% (2/5 tasks)
# Status: 🟢 On Track
# Próxima: task-1.3-context-passport

# Status detalhado de task
aidev sprint status --task task-1.1

# Lista todas as tasks
aidev sprint list-tasks

# Tasks bloqueadas
aidev sprint list-blocked

# Histórico de checkpoints
aidev sprint history --task task-1.1
```

### Gestão de Execução

```bash
# Iniciar task
aidev sprint start-task task-1.1

# Criar checkpoint manual
aidev sprint checkpoint --message "Antes de refatorar função X"

# Pausar task (sem concluir)
aidev sprint pause-task task-1.1 --reason "aguardando-review"

# Retomar task pausada
aidev sprint resume-task task-1.1

# Bloquear task
aidev sprint block-task task-1.1 --reason "dependencia-task-1.2"

# Desbloquear task
aidev sprint unblock-task task-1.1

# Completar task
aidev sprint complete-task task-1.1

# Abortar task (com registro)
aidev sprint abort-task task-1.1 --reason "abordagem-incorreta"
```

### Recuperação e Continuidade

```bash
# Retomar de onde parou
aidev sprint resume

# Ver último estado salvo
aidev sprint last-state

# Listar checkpoints disponíveis
aidev sprint checkpoints

# Restaurar para checkpoint específico
aidev sprint restore cp-2026-02-11-143022

# Exportar progresso (para backup)
aidev sprint export --format markdown
```

---

## Dashboard de Acompanhamento

### Visualização em Tempo Real

```bash
aidev sprint dashboard

# Saída:
# ╔════════════════════════════════════════════════════════════╗
# ║  SPRINT 1: FOUNDATION                              67%   ║
# ╠════════════════════════════════════════════════════════════╣
# ║  🟢 Task 1.1: Validators        [████████░░] 100%       ║
# ║  🟢 Task 1.2: Validation Engine [████████░░] 100%       ║
# ║  🟡 Task 1.3: Context Passport  [████░░░░░░]  40%       ║
# ║     └─ Step: Implementar schema JSON                     ║
# ║  ⏸️  Task 1.4: Auto-Catalog     [░░░░░░░░░░]   0%       ║
# ║  ⚪ Task 1.5: Documentation     [░░░░░░░░░░]   0%       ║
# ╠════════════════════════════════════════════════════════════╣
# ║  Tokens: 45K/200K (22%)  |  Tempo: 3h/8h (38%)          ║
# ║  Próxima ação: Continuar task 1.3                        ║
# ║  Riscos: Nenhum                                          ║
# ╚════════════════════════════════════════════════════════════╝
```

### Relatórios

```bash
# Relatório diário
aidev sprint report --daily

# Relatório de sprint
aidev sprint report --sprint

# Comparação planejado vs real
aidev sprint report --variance

# Exportar para ROADMAP
aidev sprint sync-roadmap
```

---

## Protocolos Especiais

### Protocolo de Rate Limit

**Quando detectado:**

1. **Imediato (últimos 30 segundos):**
   ```bash
   # Cria checkpoint de emergência
   aidev sprint emergency-checkpoint
   ```

2. **Salvamento do estado:**
   - Arquivo atual sendo editado
   - Posição exata (linha/código)
   - Buffer de mudanças pendentes
   - Contexto mental (comentários sobre o que estava pensando)

3. **Mensagem para você:**
   ```
   ⚠️  RATE LIMIT DETECTADO
   
   ⏸️  Execução pausada automaticamente
   📍 Progresso salvo: Task 1.3, Step 4/6
   📝 Última ação: Implementando função passport_create()
   📄 Arquivo: .aidev/lib/context-passport.sh (linha 23)
   
   💡 Para retomar:
      aidev sprint resume
   
   ⏱️  Estimativa de retorno: ~5 minutos
   ```

### Protocolo de Erro Crítico

**Se erro impedir continuidade:**

1. **Registra erro no backlog:**
   ```bash
   aidev backlog add \
     "Erro em task-1.3" \
     "Falha ao implementar schema JSON" \
     "high" \
     '["sprint-1", "blocking"]'
   ```

2. **Bloqueia task:**
   ```bash
   aidev sprint block-task task-1.3 \
     --reason "erro-implementacao" \
     --escalate
   ```

3. **Notifica você:**
   ```
   🚨 ERRO CRÍTICO NA SPRINT
   
   Task 1.3 bloqueada devido a erro.
   
   Opções:
   1. Tentar abordagem alternativa (fallback)
   2. Pular para próxima task
   3. Escalar para revisão manual
   4. Abortar sprint e replanejar
   
   Detalhes em: .aidev/state/sprints/blocked/task-1.3.json
   ```

---

## Checklist de Execução por Task

### Task 1.1: Validators (exemplo)

```markdown
# Task 1.1: Criar estrutura de validadores

## Checklist de Execução

### Preparação
- [ ] Ler especificação técnica (seção 1 do plano)
- [ ] Verificar prerequisitos (jq instalado?)
- [ ] Criar branch se necessário
- [ ] Backup do estado atual

### Implementação
- [ ] Criar arquivo .aidev/lib/validators.sh
- [ ] Implementar validate_safe_path()
  - [ ] Definir array de paths proibidos
  - [ ] Implementar loop de verificação
  - [ ] Adicionar logging
- [ ] Implementar validate_commit_format()
  - [ ] Definir regex do padrão
  - [ ] Testar com exemplos válidos
  - [ ] Testar com exemplos inválidos
- [ ] Implementar validate_no_emoji()
- [ ] Implementar validate_test_exists()
- [ ] Implementar validate_portuguese_language()
- [ ] Implementar validate_no_forbidden_patterns()

### Testes
- [ ] Criar .aidev/tests/validators.test.sh
- [ ] Testar validate_safe_path
- [ ] Testar validate_commit_format
- [ ] Testar validate_no_emoji
- [ ] Testar validate_test_exists
- [ ] Executar suite completa
- [ ] Verificar cobertura

### Validação
- [ ] Rodar validators em código existente
- [ ] Verificar falsos positivos
- [ ] Ajustar thresholds se necessário

### Finalização
- [ ] Commit: feat(validators): adiciona funções de validação
- [ ] Atualizar documentação
- [ ] Criar checkpoint final
- [ ] Marcar task como completa
```

---

## Sistema de Decisões

### Registro de Decisões

Toda decisão arquitetural ou de design é registrada:

**`.aidev/state/sprints/current/decisions.md`**:

```markdown
# Decisões da Sprint 1

## 2026-02-11 10:20 - validate_safe_path
**Decisão**: Usar array de strings em vez de regex
**Por quê**: Maior legibilidade e fácil manutenção
**Alternativas consideradas**: Regex complexo (rejeitado - difícil debugar)
**Impacto**: Performance ligeiramente menor, mas aceitável

## 2026-02-11 14:30 - validation retry
**Decisão**: 5 tentativas com backoff linear
**Por quê**: Balance entre resiliência e tempo de resposta
**Alternativas**: Exponential backoff (rejeitado - overkill para validação)
```

### Escalonamento para Você

**Critérios de escalonamento:**
1. Decisão arquitetural com impacto > 3 tasks
2. Conflito entre requisitos
3. Escolha de biblioteca/framework
4. Mudança de escopo
5. Erro que impede progresso por > 15 min

**Formato:**
```markdown
# 🚨 ESCALONAMENTO REQUERIDO

## Task
Task 1.4: Auto-Catalogação

## Problema
Duas abordagens possíveis para detectar resolução de erro:

### Opção A: Hook em skill_complete
- Prós: Simples, integrado ao fluxo existente
- Contras: Não detecta erros resolvidos fora de skills

### Opção B: Daemon monitorando logs
- Prós: Detecta todos os erros
- Contras: Complexo, requer processo background

## Recomendação
Opção A para MVP, considerar B na v2.

## Bloqueio
Task 1.4 pausada aguardando decisão.
```

---

## Recuperação de Desastres

### Cenário: Perda de Estado

**Se arquivos de status forem corrompidos:**

```bash
# Restaurar do último backup
aidev sprint restore-backup

# Ou reconstruir do git
aidev sprint rebuild-from-git \
  --since "2026-02-11T10:00:00Z"
```

### Cenário: Sprint Abandonada

**Se sprint precisar ser abortada:**

```bash
# Documenta motivo
aidev sprint abort \
  --sprint sprint-1 \
  --reason "mudanca-prioridade" \
  --create-lesson true

# Arquiva artifacts criados
aidev sprint archive \
  --sprint sprint-1 \
  --destination .aidev/state/sprints/abandoned/
```

---

## Métricas e KPIs

### Coletadas Automaticamente

```json
{
  "sprint_metrics": {
    "velocity": {
      "planned_tasks": 5,
      "completed_tasks": 4,
      "velocity": "80%"
    },
    "quality": {
      "tests_pass_rate": "98%",
      "rollback_count": 1,
      "escalation_count": 2
    },
    "efficiency": {
      "estimated_hours": 8,
      "actual_hours": 10,
      "efficiency": "80%"
    },
    "continuity": {
      "session_count": 3,
      "avg_session_duration": "2.5h",
      "rate_limit_interruptions": 1,
      "recovery_time_avg": "5min"
    }
  }
}
```

### Relatório Final de Sprint

```bash
aidev sprint report --final

# Gera:
# - Resumo executivo
# - Lista de entregáveis
# - Métricas de qualidade
# - Lições aprendidas
# - Recomendações para próxima sprint
```

---

## Resumo para Você (Product Owner)

### Comandos Essenciais

```bash
# Ver status rápido
aidev sprint status

# Ver o que está sendo feito agora
aidev sprint current

# Ver bloqueios
aidev sprint blockers

# Ver métricas
aidev sprint metrics

# Aprovar handoff pendente
aidev sprint approve-handoff <id>

# Rejeitar com feedback
aidev sprint reject-handoff <id> --feedback "..."
```

### Pontos de Controle Obrigatórios

Você será consultado em:

1. **Início de cada sprint** - Aprovar escopo e prioridades
2. **Handoffs de decisão** - Quando eu precisar de direção
3. **Bloqueios** - Quando task não puder continuar
4. **Fim de sprint** - Review e aceitação
5. **Mudanças de escopo** - Se precisar ajustar plano

### Comunicação

**Canais:**
- Dashboard: `aidev sprint dashboard` (a qualquer momento)
- Notificações: Handoffs aparecem em `.aidev/state/sprints/handoffs/pending/`
- Relatórios: Automáticos a cada 2 horas de execução

---

## Checklist de Preparação para Sprint

Antes de iniciar cada sprint:

```markdown
- [ ] Revisar plano mestre
- [ ] Verificar disponibilidade de recursos
- [ ] Backup do estado atual
- [ ] Configurar ambiente (se necessário)
- [ ] Definir horários de checkpoint
- [ ] Estabelecer critérios de aceitação
- [ ] Confirmar prioridades com PO
- [ ] Preparar templates de decisão
```

---

**Próximo Passo:** Iniciar Sprint 1 com `aidev sprint start sprint-1-foundation`
