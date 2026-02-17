# FASE 4 - Automação: Especificação Técnica Completa

> Documentação técnica para validação da implementação da FASE 4
> Versão: 1.0 | AI Dev Superpowers

---

## 📋 VISÃO GERAL

A FASE 4 implementa **detecção automática** de contextos que indicam necessidade de documentar uma lição aprendida, através de triggers YAML e integração com MCP.

---

## 🏗️ COMPONENTES OBRIGATÓRIOS

### 1. ARQUIVO DE TRIGGERS

**Localização:** `.aidev/triggers/lesson-capture.yaml`

**Estrutura mínima:**
```yaml
version: "1.0"
triggers:
  # Trigger 1: Padrões de erro crítico
  - id: error-pattern-critical
    type: error_pattern
    enabled: true
    patterns:
      - "SQLSTATE\\[.*\\]"           # Erros SQL
      - "Exception|Error|Failed"     # Exceções
      - "TypeError.*undefined"       # Erros JS
      - "Connection refused"         # Problemas de rede
    severity: high
    action: suggest_learned_lesson
    message: "Detectei um erro crítico. Deseja documentar esta lição?"
    cooldown: 300  # segundos entre sugestões

  # Trigger 2: Palavras-chave de sucesso
  - id: debug-success-keywords
    type: user_intent
    enabled: true
    keywords:
      - "corrigimos"
      - "funciona agora"
      - "resolvido"
      - "bug fix"
      - "aprendi"
      - "lição"
      - "memorizar"
      - "documentar"
    action: activate_learned_lesson_skill
    auto_suggest: true
    confidence_threshold: 0.8

  # Trigger 3: Feature complexa completada
  - id: complex-feature-complete
    type: workflow_state
    enabled: true
    state: "feature_complete"
    conditions:
      - steps > 3
      - duration > 30min
    action: prompt_lesson_capture
    message: "Feature complexa completada. Documentar aprendizados?"

  # Trigger 4: Refatoração significativa
  - id: major-refactor
    type: file_change
    enabled: true
    patterns:
      - "*.php"
      - "*.tsx"
      - "*.ts"
    threshold: 10  # arquivos alterados
    action: suggest_lesson

  # Trigger 5: Testes falhando → passando
  - id: tests-fixed
    type: test_state
    enabled: true
    from: "failing"
    to: "passing"
    action: suggest_lesson
    message: "Testes agora passam! Deseja documentar o que foi corrigido?"
```

---

## 🎯 TIPOS DE TRIGGERS

### Type: `error_pattern`
**Descrição:** Detecta padrões de erro no output/logs

**Campos obrigatórios:**
- `patterns`: Array de regex patterns
- `action`: `suggest_learned_lesson` | `search_similar_lesson`
- `message`: Texto exibido ao usuário

**Comportamento esperado:**
1. Sistema monitora stdout/stderr/logs
2. Quando pattern matcha, dispara ação
3. Se `action: search_similar_lesson`, busca lições similares automaticamente
4. Se `action: suggest_learned_lesson`, sugere documentar

---

### Type: `user_intent`
**Descrição:** Detecta intenção do usuário via palavras-chave

**Campos obrigatórios:**
- `keywords`: Array de strings/palavras-chave
- `action`: `activate_learned_lesson_skill` | `suggest_lesson`
- `confidence_threshold`: 0.0 a 1.0

**Comportamento esperado:**
1. Analisa input do usuário em tempo real
2. Calcula confidence score baseado em keywords
3. Se score >= threshold, dispara ação
4. `activate_learned_lesson_skill`: Inicia skill learned-lesson automaticamente

---

### Type: `workflow_state`
**Descrição:** Detecta mudanças de estado no workflow

**Campos obrigatórios:**
- `state`: Nome do estado (ex: "feature_complete")
- `conditions`: Regras adicionais (steps, duration)
- `action`: Ação a executar

**Comportamento esperado:**
1. Sistema mantém estado da sessão
2. Quando transição de estado ocorre, verifica conditions
3. Se conditions atendidas, dispara ação

---

### Type: `file_change`
**Descrição:** Detecta mudanças significativas no filesystem

**Campos obrigatórios:**
- `patterns`: Glob patterns (ex: "*.php")
- `threshold`: Número mínimo de arquivos
- `action`: Ação a executar

**Comportamento esperado:**
1. Monitora git status/diff
2. Conta arquivos alterados por pattern
3. Se >= threshold, dispara ação

---

### Type: `test_state`
**Descrição:** Detecta transições de estado de testes

**Campos obrigatórios:**
- `from`: Estado anterior ("failing", "pending")
- `to`: Estado atual ("passing")
- `action`: Ação a executar

**Comportamento esperado:**
1. Monitora execução de testes
2. Detecta quando testes passam após falharem
3. Dispara ação sugerindo documentar correção

---

## 🔄 FLUXO DE AUTOMAÇÃO

### Fluxo 1: Erro Detectado → Sugestão

```
Erro ocorre (ex: "SQLSTATE[HY000] [2002] Connection refused")
                ↓
    ┌──────────────────────┐
    │ 1. PATTERN MATCHING  │ → Busca em triggers/error_pattern
    └──────────┬───────────┘
               ↓
    ┌──────────────────────┐
    │ 2. SEARCH SIMILAR    │ → mcp__basic-memory__search_notes
    │    (se configurado)  │ → Query: "SQLSTATE Connection refused"
    └──────────┬───────────┘
               ↓
    ┌──────────────────────┐
    │ 3. FOUND SIMILAR?    │
    └──────────┬───────────┘
               ↓
        ┌──────┴──────┐
       SIM            NÃO
        ↓              ↓
   ┌─────────┐    ┌─────────┐
   │SUGERE   │    │SUGERE   │
   │CONSULTAR│    │DOCUMENTAR│
   │LIÇÃO    │    │NOVA     │
   │EXISTENTE│    │LIÇÃO    │
   └─────────┘    └─────────┘
```

### Fluxo 2: Palavra-chave Detectada → Ativação

```
Usuário digita: "corrigimos o bug de conexão"
                ↓
    ┌──────────────────────┐
    │ 1. INTENT ANALYSIS   │ → keywords: ["corrigimos"]
    │    Confidence: 0.85  │
    └──────────┬───────────┘
               ↓
    ┌──────────────────────┐
    │ 2. CHECK THRESHOLD   │ → 0.85 >= 0.8 ✓
    └──────────┬───────────┘
               ↓
    ┌──────────────────────┐
    │ 3. ACTIVATE SKILL    │ → learned-lesson
    │    "Modo documentar  │    automaticamente
    │     ativado"         │    ativado
    └──────────────────────┘
```

### Fluxo 3: Feature Completa → Prompt

```
Workflow: feature-development
                ↓
    ┌──────────────────────┐
    │ 1. STATE CHANGE      │ → "in_progress" → "complete"
    └──────────┬───────────┘
               ↓
    ┌──────────────────────┐
    │ 2. CHECK CONDITIONS  │ → steps: 5 > 3 ✓
    │                       │ → duration: 45min > 30min ✓
    └──────────┬───────────┘
               ↓
    ┌──────────────────────┐
    │ 3. PROMPT USER       │ → "Feature complexa completada.
    │                       │    Documentar aprendizados?"
    └──────────────────────┘
```

---

## 🛠️ IMPLEMENTAÇÃO TÉCNICA

### Estrutura de Diretórios

```
.aidev/
├── triggers/
│   └── lesson-capture.yaml       # Arquivo principal
├── lib/
│   └── triggers.sh               # Engine de triggers
├── mcp/
│   └── memory-sync.json          # Config MCP
└── memory/
    └── kb/
        └── .index/
            └── lessons-index.json # Índice de busca
```

### Funções Obrigatórias (lib/triggers.sh)

```bash
# 1. Carregar triggers
triggers__load() {
    # Lê .aidev/triggers/lesson-capture.yaml
    # Valida estrutura
    # Retorna array de triggers ativos
}

# 2. Monitorar erros
triggers__watch_errors() {
    # Hook em stdout/stderr
    # Aplica regex patterns
    # Dispara callbacks
}

# 3. Detectar intenção
triggers__detect_intent() {
    # Analisa input do usuário
    # Calcula confidence
    # Retorna matched triggers
}

# 4. Buscar lições similares
triggers__search_similar() {
    # Query: error message
    # Busca em lessons-index.json
    # Retorna matches ordenados por relevância
}

# 5. Sugerir ação
triggers__suggest_action() {
    # Exibe mensagem ao usuário
    # Aguarda confirmação (Y/n)
    # Executa ação correspondente
}
```

### Integração com CLI

```bash
# Comandos obrigatórios
aidev triggers status              # Status dos triggers
aidev triggers list               # Lista triggers ativos
aidev triggers test [id]          # Testa trigger específico
aidev triggers enable [id]        # Habilita trigger
aidev triggers disable [id]       # Desabilita trigger
```

---

## ✅ CHECKLIST DE VALIDAÇÃO

### Configuração
- [ ] Arquivo `.aidev/triggers/lesson-capture.yaml` existe
- [ ] YAML é válido (sem erros de sintaxe)
- [ ] Pelo menos 3 triggers configurados
- [ ] Todos os triggers têm `id` único
- [ ] Todos os triggers têm `enabled` definido
- [ ] Todos os triggers têm `action` válido

### Tipos de Triggers
- [ ] Trigger tipo `error_pattern` configurado
- [ ] Trigger tipo `user_intent` configurado
- [ ] Trigger tipo `workflow_state` configurado (opcional)
- [ ] Trigger tipo `file_change` configurado (opcional)
- [ ] Trigger tipo `test_state` configurado (opcional)

### Funcionalidades
- [ ] Sistema detecta erros automaticamente
- [ ] Sistema sugere consultar lição similar quando encontra
- [ ] Sistema sugere documentar quando não encontra similar
- [ ] Sistema ativa skill learned-lesson por keywords
- [ ] Sistema respeita cooldown entre sugestões
- [ ] Sistema calcula confidence corretamente
- [ ] Comando `aidev triggers status` funciona
- [ ] Comando `aidev triggers list` funciona
- [ ] Comando `aidev triggers test [id]` funciona

### Integração
- [ ] Busca em lessons-index.json funciona
- [ ] Integração com MCP basic-memory funciona
- [ ] Mensagens são exibidas ao usuário
- [ ] Ações são executadas após confirmação
- [ ] Logs de triggers são gerados

---

## 🧪 TESTES DE VALIDAÇÃO

### Teste 1: Error Pattern
```bash
# Simular erro SQL
echo "SQLSTATE[HY000] [2002] Connection refused" >&2

# Esperado:
# [TRIGGER] Detectei um erro crítico. Deseja documentar esta lição? [Y/n]
```

### Teste 2: User Intent
```bash
# Digitar no chat
"corrigimos o bug de conexão com o banco"

# Esperado:
# [TRIGGER] Palavras-chave detectadas. Ativar skill learned-lesson? [Y/n]
```

### Teste 3: Busca Similar
```bash
# Trigger detecta erro SQLSTATE
# Sistema busca em lessons-index.json
# Encontra: 2025-11-06-mysql-docker-host-config.md

# Esperado:
# [TRIGGER] Encontrei uma lição similar!
# Deseja consultar: "Erro de Conexão MySQL Docker - Hostname vs IP"? [Y/n]
```

### Teste 4: Cooldown
```bash
# Erro ocorre → Sugestão exibida
# Usuário ignora (não responde ou diz não)
# Mesmo erro ocorre novamente em 60 segundos

# Esperado:
# [TRIGGER] Cooldown ativo. Ignorando...
# (Não sugere novamente até passar 300s)
```

---

## 📊 MÉTRICAS ESPERADAS

| Métrica | Valor Mínimo | Descrição |
|---------|--------------|-----------|
| Triggers ativos | 3 | Mínimo de triggers funcionando |
| Tempo de resposta | < 500ms | Latência entre erro e sugestão |
| Precisão busca | > 80% | Lições relevantes encontradas |
| Cooldown respeitado | 100% | Não sugere durante cooldown |
| Confidence accuracy | > 75% | Keywords detectadas corretamente |

---

## 🚨 COMPORTAMENTOS CRÍTICOS

### Deve Acontecer ✅
- Sugerir imediatamente após erro detectado
- Buscar lições similares antes de sugerir nova
- Respeitar cooldown configurado
- Mostrar preview da lição similar encontrada
- Permitir usuário recusar sugestão
- Logar todas as interações

### Não Deve Acontecer ❌
- Sugerir mesmo lição 2x em menos de 5 minutos
- Ativar skill sem confirmação do usuário
- Sugerir quando usuário está no meio de outra tarefa
- Ignorar palavras-chave de alta confidence
- Falhar silenciosamente sem log

---

## 📝 EXEMPLO COMPLETO DE USO

```bash
# 1. Usuário roda comando que falha
$ php artisan migrate

# Output:
# SQLSTATE[HY000] [2002] Connection refused

# 2. TRIGGER ATIVADO
# [TRIGGER] Detectei um erro crítico.
# Buscando lições similares...

# 3. BUSCA AUTOMÁTICA
# [TRIGGER] Encontrei 1 lição similar:
# → "Erro de Conexão MySQL Docker - Hostname vs IP"

# 4. SUGESTÃO AO USUÁRIO
# Deseja:
# [1] Consultar lição existente
# [2] Documentar nova lição
# [3] Ignorar

# 5. USUÁRIO ESCOLHE [1]
# [TRIGGER] Abrindo lição...
# (Exibe conteúdo de 2025-11-06-mysql-docker-host-config.md)

# 6. PROBLEMA RESOLVIDO
# Usuário corrige baseado na lição
# Erro não ocorre mais
```

---

## 🔗 REFERÊNCIAS

- **Plano Original:** `.aidev/plans/PLANO_IMPLEMENTACAO.md` (FASE 4)
- **Template Triggers:** `templates/triggers/lesson-capture.yaml.tmpl`
- **Engine Triggers:** `lib/triggers.sh`
- **Documentação MCP:** `.aidev/mcp/README.md`

---

**Versão:** 1.0  
**Criado em:** 2026-02-05  
**Status:** Especificação para validação
