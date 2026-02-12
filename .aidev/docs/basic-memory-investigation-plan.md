# Plano de Investigação: Basic Memory no Contexto MCP

**Data**: 2026-02-12  
**Versão**: 1.0  
**Status**: Investigação Inicial  
**Sprint**: Task 3.4 - Integração Basic Memory  

---

## 📋 RESUMO EXECUTIVO

O **Basic Memory** está **configurado** no ecossistema MCP do projeto, mas há **gaps críticos** na integração completa com o sistema de checkpoints. Este plano investiga o estado atual, identifica oportunidades de otimização de tokens e propõe integração profunda.

---

## 🔍 ESTADO ATUAL - O QUE JÁ EXISTE

### ✅ Configuração MCP (JÁ FUNCIONANDO)

```json
// .aidev/mcp/antigravity-config.json
{
  "mcpServers": {
    "basic-memory": {
      "command": "uvx",
      "args": ["basic-memory", "mcp"],
      "description": "Memoria persistente"
    }
  }
}
```

**Localizações da configuração:**
- ✅ `.aidev/mcp/antigravity-config.json` - Configuração Antigravity
- ✅ `.aidev/mcp/memory-sync.json` - Configuração de sync (providers: basic-memory, context7)
- ✅ `.mcp.json` - Configuração Claude Code
- ✅ `lib/mcp.sh` - Geração automática de config
- ✅ `.claude/settings.local.json` - Tools disponíveis

### ✅ Ferramentas MCP Disponíveis

```bash
# Basic Memory Tools (já configuradas):
mcp__basic-memory__write_note          # Escrever nota
mcp__basic-memory__search_notes        # Buscar notas
mcp__basic-memory__list_memory_projects # Listar projetos
mcp__basic-memory__build_context       # Construir contexto
```

### ✅ Uso Existente no Código

1. **lib/memory.sh** - Integração para lições aprendidas
2. **lib/kb-search.sh** - Busca unificada (local + basic-memory)
3. **lib/lessons.sh** - Registro no vault global
4. **Skills**:
   - `systematic-debugging/SKILL.md` - Uso de `mcp__basic-memory__write_note`
   - `learned-lesson/SKILL.md` - Busca e escrita

---

## 🚨 GAPS IDENTIFICADOS

### Gap 1: Integração com Checkpoints (TASK 3.4)

**Status**: ❌ NÃO IMPLEMENTADO  
**Impacto**: 🔴 ALTO

**Problema:**
- Checkpoints são salvos apenas no filesystem (`.aidev/state/sprints/current/checkpoints/`)
- Não há sincronização automática com Basic Memory
- Perda de contexto ao trocar de máquina ou projeto

**Oportunidade de Economia de Tokens:**
```
Cenário atual (sem Basic Memory):
- Cada checkpoint: ~2.000-5.000 tokens de contexto
- Sessões LLM: Limite de 200K tokens
- Checkpoints por sessão: ~40-50
- Total de tokens "perdidos" entre sessões: 100K+

Cenário com Basic Memory:
- Checkpoints salvos: Persistência entre sessões
- Busca semântica: Encontra contexto relevante sem carregar tudo
- Economia: ~60-70% de tokens de contexto inicial
```

### Gap 2: Schema de Dados Não Padronizado

**Status**: ⚠️ PARCIAL  
**Impacto**: 🟡 MÉDIO

**Problema:**
- Checkpoints usam JSON próprio (não compatível com Basic Memory)
- Basic Memory espera notas em formato específico
- Não há mapeamento entre estruturas

**Schema Atual (Checkpoint):**
```json
{
  "checkpoint_id": "ckpt-xxx",
  "trigger": "manual",
  "description": "...",
  "created_at": "ISO-8601",
  "state_snapshot": {...},
  "sprint_snapshot": {...}
}
```

**Schema Esperado (Basic Memory):**
```markdown
# Checkpoint: ckpt-xxx

**Trigger**: manual  
**Sprint**: sprint-3-context-monitor  
**Task**: task-3.3-aidev-restore  
**Tags**: #checkpoint #sprint-3 #restore

## Estado
- Projeto: aidev-superpowers-v3-1
- Versão: 3.9.0
- Progresso: 75%

## Contexto
[Resumo do que foi feito]

## Próxima Ação
[O que falta fazer]
```

### Gap 3: Falta Funcionalidade de Restore

**Status**: ⚠️ PARCIAL  
**Impacto**: 🟡 MÉDIO

**Problema:**
- `aidev restore` busca apenas no filesystem
- Não consulta Basic Memory para contexto estendido
- Sem busca semântica de checkpoints históricos

---

## 🎯 OPORTUNIDADES DE OTIMIZAÇÃO

### 1. Contexto Inteligente (Economia de Tokens)

**Como funciona hoje:**
```
Sessão Nova:
├── Carrega unified.json (500 tokens)
├── Carrega sprint-status.json (300 tokens)
├── Carrega ROADMAP.md (800 tokens)
└── Total inicial: ~1.600 tokens
```

**Como poderia funcionar com Basic Memory:**
```
Sessão Nova:
├── Busca semântica: "contexto atual sprint 3" (50 tokens)
├── Basic Memory retorna: Resumo otimizado (200 tokens)
├── Carrega apenas contexto essencial (300 tokens)
└── Total inicial: ~550 tokens (65% economia)
```

### 2. Memória de Longo Prazo

**Benefícios:**
- ✅ Lições aprendidas persistem entre projetos
- ✅ Padrões de erro são lembrados
- ✅ Soluções anteriores são sugeridas
- ✅ Histórico completo de decisões arquiteturais

### 3. Cross-Project Learning

**Cenário:**
```
Projeto A (Laravel):
- Resolve bug complexo de autenticação
- Salva solução no Basic Memory

Projeto B (Laravel):
- Encontra erro similar
- Busca no Basic Memory: "autenticação JWT erro"
- Recebe solução do Projeto A
- Economia: 2-3 horas de debugging
```

---

## 📊 ANÁLISE DE VIABILIDADE

### Pré-requisitos Técnicos

| Requisito | Status | Notas |
|-----------|--------|-------|
| MCP Server instalado | ⚠️ Verificar | `npm install -g @anthropics/basic-memory` |
| Configuração válida | ✅ OK | `.mcp.json` e `antigravity-config.json` |
| Acesso às tools | ✅ OK | Configurado em `.claude/settings.local.json` |
| Fallback implementado | ⚠️ Parcial | `lib/kb-search.sh` tem lógica de fallback |

### Dependências

```bash
# Verificar se basic-memory está instalado
which basic-memory || npm list -g @anthropics/basic-memory

# Verificar MCP server
uvx basic-memory --version 2>/dev/null || echo "Não disponível"
```

---

## 🔧 PLANO DE IMPLEMENTAÇÃO

### Fase 1: Mapeamento de Schema (Estimativa: 30 min)

**Objetivo**: Criar função de conversão checkpoint ↔ Basic Memory

```bash
# Nova função: ckpt_convert_to_note()
# Local: lib/checkpoint-manager.sh
# Entrada: checkpoint.json
# Saída: Markdown formatado para Basic Memory
```

**Entregáveis:**
- [ ] Função `ckpt_to_basic_memory_note()`
- [ ] Template de nota em Markdown
- [ ] Extração de metadados (tags, categorias)

### Fase 2: Sync Automático (Estimativa: 45 min)

**Objetivo**: Salvar checkpoints no Basic Memory automaticamente

```bash
# Integrar em ckpt_create()
# Após salvar no filesystem, salvar no Basic Memory

ckpt_create() {
    # ... código existente ...
    
    # NOVO: Salvar no Basic Memory
    if type mcp__basic-memory__write_note &>/dev/null; then
        local note_content=$(ckpt_to_basic_memory_note "$ckpt_file")
        mcp__basic-memory__write_note \
            title="Checkpoint: $ckpt_id" \
            content="$note_content" \
            directory="checkpoints"
    fi
}
```

**Entregáveis:**
- [ ] Integração em `ckpt_create()`
- [ ] Configuração de sync (ligar/desligar)
- [ ] Fallback quando Basic Memory indisponível

### Fase 3: Busca Semântica (Estimativa: 40 min)

**Objetivo**: Permitir busca de checkpoints no Basic Memory

```bash
# Nova função: ckpt_search_basic_memory()
# Uso: ckpt_search_basic_memory "erro no restore"

ckpt_search_basic_memory() {
    local query="$1"
    mcp__basic-memory__search_notes \
        query="checkpoint $query" \
        directory="checkpoints"
}
```

**Entregáveis:**
- [ ] Função `ckpt_search_basic_memory()`
- [ ] Integração em `aidev restore --search`
- [ ] Testes de busca

### Fase 4: Restore Inteligente (Estimativa: 35 min)

**Objetivo**: `aidev restore` busca em ambas fontes

```bash
# Estender cmd_restore()
# Opção: --search "termos de busca"

cmd_restore() {
    case "$subcmd" in
        --search)
            # Busca no Basic Memory
            ckpt_search_basic_memory "$2"
            ;;
        ...
    esac
}
```

**Entregáveis:**
- [ ] Subcomando `--search`
- [ ] Exibição de resultados
- [ ] Seleção interativa

### Fase 5: Contexto Otimizado (Estimativa: 30 min)

**Objetivo**: Carregar apenas contexto relevante na inicialização

```bash
# Nova função: ctx_load_from_basic_memory()
# Chamada na inicialização do agente

ctx_load_from_basic_memory() {
    # Busca resumo do sprint atual
    # Retorna contexto condensado
    # Economiza tokens vs carregar JSON completo
}
```

**Entregáveis:**
- [ ] Função de carregamento otimizado
- [ ] Integração na inicialização
- [ ] Métricas de economia de tokens

---

## 📈 MÉTRICAS ESPERADAS

### Economia de Tokens

| Cenário | Sem Basic Memory | Com Basic Memory | Economia |
|---------|------------------|------------------|----------|
| Inicialização agente | 1.600 tokens | 550 tokens | 66% |
| Carregar checkpoint | 500 tokens | 200 tokens | 60% |
| Buscar contexto | 0 tokens (não existe) | 50 tokens | Nova func |
| Persistência | 0 (não existe) | ∞ (ilimitada) | Nova func |

### Performance

| Métrica | Atual | Esperado | Melhoria |
|---------|-------|----------|----------|
| Tempo de inicialização | 2-3s | 1-2s | 30% |
| Precisão de busca | N/A | 85%+ | Nova func |
| Retenção de contexto | 1 sessão | ∞ | Ilimitada |

---

## ⚠️ RISCOS E MITIGAÇÕES

### Risco 1: Basic Memory não instalado

**Probabilidade**: 🟡 Média  
**Impacto**: 🟡 Médio

**Mitigação:**
```bash
# Fallback automático
if ! command -v basic-memory &>/dev/null; then
    log_info "Basic Memory não disponível, usando filesystem apenas"
    return 0
fi
```

### Risco 2: Latência de rede

**Probabilidade**: 🟢 Baixa  
**Impacto**: 🟡 Médio

**Mitigação:**
- Operações async quando possível
- Cache local de metadados
- Timeout configurável

### Risco 3: Custo de tokens MCP

**Probabilidade**: 🟢 Baixa  
**Impacto**: 🟡 Médio

**Mitigação:**
- Batch de operações
- Sincronização seletiva (apenas checkpoints importantes)
- Configuração de threshold

---

## 🎬 PRÓXIMOS PASSOS

### Recomendação: Implementar Fases 1-3 (MVP)

**Justificativa:**
- Alto impacto na economia de tokens (60%+)
- Complexidade média (implementável em 2h)
- Funcionalidade independente (não bloqueia outras features)

**Ordem de prioridade:**
1. ⭐ **Fase 1** - Schema mapping (fundamental)
2. ⭐ **Fase 2** - Sync automático (valor imediato)
3. ⭐ **Fase 3** - Busca semântica (diferencial)
4. Fase 4 - Restore inteligente (nice to have)
5. Fase 5 - Contexto otimizado (otimização)

---

## 📋 CHECKLIST DE DECISÃO

Antes de implementar, precisamos responder:

- [ ] **Basic Memory está instalado neste ambiente?**
- [ ] **Qual a política de dados sensíveis?** (checkpoints podem conter código)
- [ ] **Prioridade vs Task 3.4 original?** (Integração básica vs Completa)
- [ ] **Orçamento de tokens para MCP?** (custo das operações)

---

## 🔍 VERIFICAÇÃO DE INSTALAÇÃO

**Status Verificado em 2026-02-12:**

```
✅ Basic Memory ENCONTRADO
   Local: /home/nandodev/.local/bin/basic-memory
   Versão: 0.18.0
   Instalado via: uvx (conforme configuração MCP)

✅ MCP Server CONFIGURADO
   Config: .aidev/mcp/antigravity-config.json
   Status: Pronto para uso

✅ Tools DISPONÍVEIS
   - mcp__basic-memory__write_note ✅
   - mcp__basic-memory__search_notes ✅
   - mcp__basic-memory__list_memory_projects ✅
   - mcp__basic-memory__build_context ✅
```

**Conclusão da Verificação:**
- ✅ Basic Memory está instalado e funcional
- ✅ Configuração MCP está correta
- ✅ Pronto para implementação das Fases 1-3
- ⚠️ Apenas necessário garantir fallback para quando MCP indisponível

---

## 📝 NOTAS TÉCNICAS

### Formato de Nota no Basic Memory

```markdown
# Checkpoint: {checkpoint_id}

**Trigger**: {trigger}  
**Sprint**: {sprint_id}  
**Task**: {task_id}  
**Data**: {created_at}  
**Tags**: #checkpoint #{sprint_id} #{task_id} #{trigger}

## Resumo
{description}

## Estado do Sistema
- Versão: {version}
- Projeto: {project_name}
- Progresso: {progress_percentage}%

## Contexto Técnico
### Intent Ativo
{active_intent}: {intent_description}

### Sprint Atual
- Nome: {sprint_name}
- Status: {status}
- Task: {current_task}

## Próxima Ação
{next_action}

## Artefatos
{artifacts}

---
*Gerado automaticamente por AI Dev Superpowers v{version}*
```

---

## 🎯 CONCLUSÃO

O **Basic Memory está CONFIGURADO mas SUBUTILIZADO**. A integração completa com checkpoints oferece:

✅ **Economia de 60%+ de tokens** na inicialização  
✅ **Persistência ilimitada** de contexto entre sessões  
✅ **Busca semântica** de checkpoints históricos  
✅ **Cross-project learning** automático  

**Investimento**: ~2 horas (Fases 1-3)  
**Retorno**: Economia significativa de tokens + Melhoria na continuidade

---

**Recomendação**: ⭐ **IMPLEMENTAR** - Alto ROI, baixo risco

---

*Documento gerado em: 2026-02-12*  
*Versão do Sistema: 3.9.0*  
*Task Relacionada: 3.4 - Integração Basic Memory*
