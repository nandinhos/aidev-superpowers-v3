# Protocolo de Inicialização do Agente - v3.9.0

**Documento de Inicialização Unificada**  
**Versão**: 1.0  
**Data**: 2026-02-11  
**Status**: Ativo  

---

## Visão Geral

Este protocolo garante que qualquer LLM (Claude, GPT, etc.) possa continuar o desenvolvimento exatamente de onde parou, mantendo contexto completo entre sessões.

### Fluxo de Inicialização

```
┌─────────────────────────────────────────────────────────────┐
│  1. VERIFICAÇÃO DE VERSÃO                                    │
│     └── Ler VERSION → Confirmar compatibilidade             │
├─────────────────────────────────────────────────────────────┤
│  2. CARREGAMENTO DE ESTADO                                   │
│     ├── Ler unified.json → Estado completo do sistema       │
│     ├── Ler sprint-status.json → Sprint atual               │
│     └── Verificar checkpoints → Último estado salvo         │
├─────────────────────────────────────────────────────────────┤
│  3. ANÁLISE DE CONTEXTO                                      │
│     ├── Feature ativa? → .aidev/plans/features/             │
│     ├── Sprint em andamento? → sprint-status.json           │
│     └── Task atual? → next_action em sprint_context         │
├─────────────────────────────────────────────────────────────┤
│  4. APRESENTAÇÃO DO DASHBOARD                                │
│     ├── Versão do sistema                                   │
│     ├── Sprint atual + progresso                            │
│     ├── Task em execução                                    │
│     └── Próxima ação recomendada                            │
├─────────────────────────────────────────────────────────────┤
│  5. SINCRONIZAÇÃO                                            │
│     └── Atualizar timestamps → unified.json + session.json  │
└─────────────────────────────────────────────────────────────┘
```

---

## Arquivos de Estado Obrigatórios

### Ordem de Leitura (NUNCA pular)

1. **`.aidev/state/unified.json`**
   - Propósito: Estado consolidado do sistema
   - Campos críticos: `version`, `session`, `sprint_context`, `active_intent`
   - Se não existir: Criar a partir do template

2. **`.aidev/state/sprints/current/sprint-status.json`**
   - Propósito: Sprint em execução
   - Campos críticos: `sprint_id`, `status`, `current_task`, `next_action`
   - Se não existir: Verificar em `history/` ou iniciar nova

3. **`.aidev/state/session.json`**
   - Propósito: Contexto da sessão atual
   - Campos críticos: `last_activity`, `agent_mode_active`
   - Se não existir: Criar com timestamp atual

4. **`.aidev/plans/features/`** (se aplicável)
   - Propósito: Features em desenvolvimento
   - Buscar: Arquivo relacionado à sprint atual

5. **`.aidev/plans/ROADMAP.md`**
   - Propósito: Visão macro do projeto
   - Usar para: Validar consistência com sprint atual

---

## Protocolo de Recuperação

### Cenário 1: Inicialização Normal

```bash
# Passos automáticos:
1. Ler VERSION
2. Ler unified.json
3. Ler sprint-status.json
4. Extrair sprint_context
5. Renderizar dashboard
6. Atualizar last_activity
```

### Cenário 2: Troca de LLM (Nova Janela)

```bash
# Passos obrigatórios:
1. Verificar unified.json existe
2. Se não existir:
   - Procurar em .aidev/backups/
   - Restaurar último backup válido
3. Verificar sprint-status.json
4. Se sprint "in_progress":
   - Carregar task atual
   - Mostrar resumo do que foi feito
   - Perguntar: "Continuar de onde parou?"
5. Se sprint "completed":
   - Mover para history/
   - Propor próxima sprint do ROADMAP
```

### Cenário 3: Checkpoint de Emergência

```bash
# Detectado arquivo .aidev/state/.emergency-checkpoint.json
1. Ler checkpoint
2. Mostrar mensagem: "⚠️ Sessão anterior interrompida"
3. Exibir:
   - Último arquivo editado
   - Linha exata
   - Contexto (o que estava fazendo)
4. Perguntar:
   - [1] Restaurar checkpoint
   - [2] Ignorar e começar novo
   - [3] Ver diff das mudanças
```

---

## Dashboard de Inicialização

### Formato Padrão (v3.9.0)

```
╔══════════════════════════════════════════════════════════════════════════╗
║  AI DEV SUPERPOWERS v3.9.0                                               ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  📊 SPRINT ATUAL                                                         ║
║  ════════════════════════════════════════════════════════════════════   ║
║  Sprint 3: Context Monitor & Auto-Checkpoint                    [ 0% ]  ║
║  Status: 🟢 in_progress                                                  ║
║  Período: 2026-02-11 → 2026-02-18                                       ║
║                                                                          ║
║  📋 TAREFAS                                                              ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    ║
║  ⏳ Task 3.1: lib/context-monitor.sh                          [RED]     ║
║  ⚪ Task 3.2: lib/checkpoint-manager.sh                      [PEND]     ║
║  ⚪ Task 3.3: Comando aidev restore                          [PEND]     ║
║  ⚪ Task 3.4: Integração Basic Memory                        [PEND]     ║
║                                                                          ║
║  🎯 PRÓXIMA AÇÃO                                                         ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    ║
║  Task: task-3.1-context-monitor                                          ║
║  Step: RED (TDD)                                                         ║
║  Descrição: Escrever testes para lib/context-monitor.sh                 ║
║  Estimativa: ~4.000 tokens                                              ║
║                                                                          ║
║  💡 COMANDOS DISPONÍVEIS                                                 ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    ║
║  "continuar"  → Retomar task atual                                      ║
║  "status"     → Ver detalhes completos                                  ║
║  "dashboard"  → Visualização gráfica                                    ║
║  "historico"  → Ver sprints anteriores                                  ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
```

---

## Estrutura de Fonte de Verdade

### Hierarquia de Dados

```
FONTE DE VERDADE (em ordem de prioridade):

1. sprint-status.json
   └── Sprint atual, task em execução, progresso
   
2. unified.json
   └── Estado consolidado, contexto da sessão
   
3. ROADMAP.md
   └── Planejamento estratégico, sprints futuras
   
4. features/*.md
   └── Especificações técnicas detalhadas

REGRA DE OURO:
→ sprint-status.json decide O QUE fazer agora
→ unified.json decide COMO continuar
→ ROADMAP.md decide PARA ONDE ir
```

### Sincronização Obrigatória

A cada ação, atualizar:

```bash
# 1. Sprint-status.json (sempre)
last_updated: "ISO-8601 timestamp"
session_metrics.tokens_used: +n

# 2. Unified.json (a cada 5 min ou ação crítica)
session.last_activity: "ISO-8601 timestamp"
sprint_context.last_sync: "ISO-8601 timestamp"

# 3. Checkpoint (a cada 10 min ou antes de operação arriscada)
.aidev/state/sprints/current/checkpoints/cp-{timestamp}.json
```

---

## Comandos de Inicialização Rápida

### Para LLMs (Automação)

```bash
# Inicialização completa
aidev init --full

# Verificar estado apenas
aidev init --check

# Forçar recuperação de checkpoint
aidev init --restore

# Ignorar estado anterior (cuidado!)
aidev init --fresh
```

### Para Usuários

```bash
# Status rápido
aidev status

# Dashboard completo
aidev dashboard

# Retomar de onde parou
aidev continue

# Ver histórico de checkpoints
aidev checkpoints
```

---

## Validações de Inicialização

### Checklist Obrigatório

Antes de aceitar o estado como válido:

```markdown
- [ ] unified.json existe e é JSON válido
- [ ] unified.json.version == VERSION
- [ ] sprint-status.json existe e é JSON válido
- [ ] sprint-status.json.status é válido (in_progress|completed|blocked)
- [ ] sprint-status.json.current_task existe
- [ ] sprint-status.json.next_action está preenchido
- [ ] unified.json.sprint_context.sprint_id == sprint-status.json.sprint_id
- [ ] session.json existe e tem last_activity recente (< 24h)
- [ ] Não há .emergency-checkpoint.json pendente
```

### Se Validação Falhar

```bash
# Tentar auto-recuperação:
1. Procurar backups em .aidev/backups/
2. Restaurar último backup válido
3. Se não houver backup:
   - Iniciar fresh (perde contexto)
   - Registrar no confidence_log
   - Notificar usuário
```

---

## Continuidade entre LLMs

### Cenário: Claude → GPT → Claude

```
Sessão 1 (Claude):
├── Implementa função X
├── Cria checkpoint cp-001
└── Rate limit atingido

Sessão 2 (GPT):
├── Lê unified.json
├── Lê sprint-status.json
├── Lê checkpoint cp-001
├── Continua implementação
├── Cria checkpoint cp-002
└── Usuário encerra

Sessão 3 (Claude):
├── Lê unified.json (atualizado pelo GPT)
├── Lê sprint-status.json
├── Lê checkpoint cp-002
└── Continua sem perder contexto
```

### Requisitos para Continuidade

1. **Formato padronizado** - JSON estruturado
2. **Timestamp UTC** - Sem ambiguidade de timezone
3. **Checkpoints frequentes** - A cada 5-10 minutos
4. **Mensagens claras** - Descrição do que foi feito
5. **Artefatos rastreáveis** - Lista de arquivos modificados

---

## Resumo para Desenvolvedores

### Quando Iniciar Nova Sessão

1. **Sempre** ler `.aidev/state/unified.json` primeiro
2. **Sempre** verificar `.aidev/state/sprints/current/sprint-status.json`
3. **Sempre** mostrar dashboard antes de executar qualquer ação
4. **Sempre** atualizar `last_activity` após leitura
5. **NUNCA** assumir que estado está atualizado sem verificar

### Prioridade de Ações

```
SE existe emergency-checkpoint.json:
   → RESTAURAR CHECKPOINT
   
SENÃO SE sprint em andamento:
   → CONTINUAR TASK ATUAL
   
SENÃO SE sprint completa:
   → MOVER PARA HISTORY
   → INICIAR PRÓXIMA SPRINT
   
SENÃO:
   → CONSULTAR ROADMAP
   → CRIAR NOVA SPRINT
```

---

## Próximos Passos

1. Implementar este protocolo em `lib/agent-init.sh`
2. Criar testes de integração para inicialização
3. Documentar APIs de checkpoint
4. Criar visualização do dashboard

---

**Última atualização**: 2026-02-11  
**Versão do sistema**: 3.9.0  
**Sprint atual**: Sprint 3 - Context Monitor & Auto-Checkpoint
