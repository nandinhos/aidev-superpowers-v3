# 🚀 Guia Rápido: Gestão de Sprints

## Estrutura Criada

```
.aidev/state/sprints/
├── current/
│   ├── sprint-status.json     # Status da Sprint 1
│   └── checkpoints/           # Checkpoints automáticos
├── history/                   # Sprints concluídas
├── blocked/                   # Tasks bloqueadas
├── handoffs/
│   └── pending/              # Handoffs para sua revisão
└── abandoned/                # Sprints canceladas
```

## Comandos Principais

### 1. Ver Status
```bash
./sprint.sh status
```
Mostra progresso geral, tasks completadas/em andamento/pendentes.

### 2. Iniciar Sprint
```bash
./sprint.sh start
```
Marca sprint como "in_progress" e inicia tracking.

### 3. Durante Execução

**Criar checkpoint** (a cada 10-15 min ou decisão importante):
```bash
./sprint.sh checkpoint "Antes de implementar função X"
```

**Atualizar task**:
```bash
./sprint.sh update-task task-1.1 in_progress "Implementando validação"
./sprint.sh update-task task-1.1 completed "Todos os testes passando"
```

**Ver próxima ação**:
```bash
./sprint.sh next
```

### 4. Em Caso de Interrupção (Rate Limit)

**Pausar automaticamente**:
```bash
./sprint.sh pause "Rate limit atingido, aguardando reset"
```

**Retomar depois**:
```bash
./sprint.sh resume
```
Mostra exatamente onde parou (task, arquivo, linha).

### 5. Gestão de Problemas

**Bloquear task** (quando precisar da sua decisão):
```bash
./sprint.sh block task-1.3 "Decisão arquitetural necessária"
```

**Ver handoffs pendentes**:
```bash
./sprint.sh handoffs
```

## Fluxo Típico de Uso

### Início de Sessão
```bash
./sprint.sh status      # Ver onde estamos
./sprint.sh next        # Ver o que fazer agora
```

### Durante Trabalho
```bash
# A cada 10-15 minutos ou decisão:
./sprint.sh checkpoint "Descrição do que foi feito"

# Ao completar uma parte:
./sprint.sh update-task task-XXX in_progress "Progresso X%"
```

### Fim de Sessão (Rate Limit)
```bash
./sprint.sh checkpoint "Último checkpoint antes de parar"
./sprint.sh pause "Rate limit - retornando em X min"
```

### Retomada
```bash
./sprint.sh resume      # Restaura contexto
./sprint.sh status      # Mostra resumo
```

## Controle Total para Você

### Você será notificado quando:

1. **Task completada** → Ver `./sprint.sh status`
2. **Handoff necessário** → Ver `./sprint.sh handoffs`
3. **Task bloqueada** → Arquivo em `.aidev/state/sprints/blocked/`
4. **Sprint pausada** → Status muda para "paused"

### Você pode intervir:

```bash
# Aprovar handoff (quando implementado):
# Mover arquivo de pending/ para approved/

# Priorizar task:
./sprint.sh update-task task-1.5 in_progress "Prioridade alterada pelo PO"

# Abortar sprint (emergência):
# Editar sprint-status.json e mudar status para "aborted"
```

## Recuperação de Desastres

**Se eu ficar indisponível (rate limit longo):**
1. Último checkpoint salvo em `.aidev/state/sprints/current/checkpoints/`
2. Status completo em `sprint-status.json`
3. Você pode continuar manualmente ou esperar retorno

**Se precisar parar no meio:**
1. Eu crio checkpoint automático
2. Sprint fica em estado "paused"
3. Você pode retomar com `./sprint.sh resume`

## Documentos Relacionados

- **Plano Mestre**: `.aidev/plans/features/validation-system-master-plan.md`
- **Protocolo de Execução**: `.aidev/plans/features/sprint-execution-protocol.md`
- **Status Atual**: `.aidev/state/sprints/current/sprint-status.json`

## Próximo Passo

Para começar a Sprint 1:

```bash
./sprint.sh start
```

Ou se preferir revisar antes:

```bash
cat .aidev/state/sprints/current/sprint-status.json | jq '.tasks[]'
```

---

**Sistema pronto para gestão robusta de sprints!** 🎯
