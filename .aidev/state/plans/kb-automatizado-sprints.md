# Plano: Sistema de Knowledge Base Automatizado

**Data**: 2026-02-04
**Objetivo**: Catalogacao automatica de erros/resolucoes com consulta obrigatoria pre-planejamento

---

## Diagnostico: Gaps Atuais

| Aspecto | Status Atual | Gap Critico |
|---------|-------------|-------------|
| **Captura de Erros** | Manual via skill learned-lesson | Nao ha automacao |
| **Hook de Resolucao** | `memory_on_resolution()` existe | NAO e chamado automaticamente |
| **Consulta Pre-Codigo** | Nao existe | KB ignorada antes de codificar |
| **Indexacao** | JSON local basico | Sem busca semantica cross-project |
| **Integracao MCP** | Placeholder em lib/memory.sh | Sincronizacao inativa |

---

## Arquitetura Proposta

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLUXO AUTOMATIZADO                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [Erro Ocorre]                                                  │
│       │                                                         │
│       ▼                                                         │
│  skill_init("systematic-debugging")                             │
│       │                                                         │
│       ▼                                                         │
│  [REPRODUCE → ISOLATE → ROOT CAUSE → FIX]                      │
│       │                                                         │
│       ▼                                                         │
│  skill_complete() ─────► _kb_on_resolution_complete()          │
│                          [HOOK AUTOMATICO]                      │
│       │                                                         │
│       ▼                                                         │
│  kb_catalog_resolution()                                        │
│       │                                                         │
│       ├── Extrai Exception/Erro do estado                       │
│       ├── Coleta Sintomas (checkpoints)                         │
│       ├── Documenta Causa Raiz                                  │
│       ├── Registra Correcao (artifacts)                         │
│       │                                                         │
│       ▼                                                         │
│  [Sincronizacao Paralela]                                       │
│       ├── .aidev/memory/kb/*.md (local)                        │
│       ├── Basic Memory MCP (cross-project)                      │
│       └── Serena memories (kb_*)                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                 CONSULTA PRE-PLANEJAMENTO                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [Nova Tarefa] ──► orchestrator_classify_intent()               │
│       │                                                         │
│       ▼                                                         │
│  OBRIGATORIO: kb_consult_before_coding("$task")                │
│       │                                                         │
│       ├── Busca Local (.aidev/memory/kb/)                      │
│       ├── Busca Basic Memory                                    │
│       └── Busca Serena memories                                 │
│       │                                                         │
│       ▼                                                         │
│  [Match encontrado?]                                            │
│       │                                                         │
│       ├── SIM ──► Aplicar correcao conhecida (0 tokens extra)  │
│       └── NAO ──► Prosseguir normalmente                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# SPRINTS DE IMPLEMENTACAO

## Sprint 1: Modulo Core da KB
**Prioridade**: ALTA
**Dependencias**: Nenhuma

### Tarefas

#### 1.1 Criar lib/kb.sh
**Arquivo**: `lib/kb.sh`
**Acao**: CRIAR

```bash
# Funcoes a implementar:
kb_init()                      # Inicializa estrutura da KB
kb_catalog_resolution()        # Cataloga erro resolvido
kb_format_lesson()             # Formata no padrao estruturado
_kb_update_index()             # Atualiza indice JSON
_kb_on_resolution_complete()   # Hook chamado por skill_complete
_kb_on_failure()               # Hook chamado por skill_fail
```

**Criterio de Aceite**:
- [ ] Arquivo criado com todas as funcoes
- [ ] Funcao `kb_init()` cria estrutura em `.aidev/memory/kb/`
- [ ] Funcao `kb_catalog_resolution()` gera arquivo .md estruturado
- [ ] Indice JSON atualizado automaticamente

#### 1.2 Criar estrutura de diretorios
**Acao**: Garantir existencia de `.aidev/memory/kb/`

**Criterio de Aceite**:
- [ ] Diretorio existe
- [ ] Arquivo `index.json` inicializado

#### 1.3 Testes unitarios
**Arquivo**: `tests/unit/test-kb.sh`
**Acao**: CRIAR

```bash
# Testes a implementar:
test_kb_init()
test_kb_catalog_resolution()
test_kb_format_lesson()
test_kb_update_index()
```

**Criterio de Aceite**:
- [ ] Todos os testes passando
- [ ] Cobertura das funcoes principais

---

## Sprint 2: Hooks Automaticos
**Prioridade**: ALTA
**Dependencias**: Sprint 1

### Tarefas

#### 2.1 Modificar lib/orchestration.sh - source kb.sh
**Arquivo**: `lib/orchestration.sh`
**Linha**: Apos linha 11 (apos source lib/metrics.sh)
**Acao**: MODIFICAR

```bash
# Adicionar:
if [ -f "lib/kb.sh" ]; then
    source lib/kb.sh
fi
```

**Criterio de Aceite**:
- [ ] kb.sh carregado quando disponivel
- [ ] Nao quebra se kb.sh nao existir

#### 2.2 Modificar skill_complete() com hook KB
**Arquivo**: `lib/orchestration.sh`
**Funcao**: `skill_complete()` (linhas 160-183)
**Acao**: MODIFICAR

```bash
# Adicionar antes de print_success:
if [[ "$skill_name" == "systematic-debugging" ]] ||
   [[ "$skill_name" == "learned-lesson" ]]; then
    if command -v _kb_on_resolution_complete >/dev/null 2>&1; then
        _kb_on_resolution_complete "$skill_name"
    fi
fi
```

**Criterio de Aceite**:
- [ ] Hook chamado quando systematic-debugging completa
- [ ] Hook chamado quando learned-lesson completa
- [ ] Nao quebra se hook nao existir

#### 2.3 Modificar skill_fail() com registro
**Arquivo**: `lib/orchestration.sh`
**Funcao**: `skill_fail()` (linhas 187-212)
**Acao**: MODIFICAR

```bash
# Adicionar antes de print_error:
if command -v _kb_on_failure >/dev/null 2>&1; then
    _kb_on_failure "$skill_name" "$reason"
fi
```

**Criterio de Aceite**:
- [ ] Falhas registradas em log para correlacao
- [ ] Nao quebra se hook nao existir

#### 2.4 Testes de integracao
**Arquivo**: `tests/integration/test-kb-hooks.sh`
**Acao**: CRIAR

```bash
# Testes:
test_skill_complete_triggers_kb_hook()
test_skill_fail_logs_for_correlation()
test_hooks_graceful_without_kb()
```

**Criterio de Aceite**:
- [ ] Fluxo completo testado
- [ ] Hook dispara corretamente

---

## Sprint 3: Sistema de Busca
**Prioridade**: MEDIA
**Dependencias**: Sprint 1

### Tarefas

#### 3.1 Implementar kb_search()
**Arquivo**: `lib/kb.sh`
**Acao**: ADICIONAR

```bash
kb_search()                    # Busca semantica unificada
_kb_search_local()             # Busca em arquivos locais
```

**Criterio de Aceite**:
- [ ] Busca por termo em titulo, exception, tags
- [ ] Retorna top N resultados
- [ ] Formato estruturado de retorno

#### 3.2 Implementar kb_consult_before_coding()
**Arquivo**: `lib/kb.sh`
**Acao**: ADICIONAR

```bash
kb_consult_before_coding()     # Consulta obrigatoria pre-planejamento
```

**Criterio de Aceite**:
- [ ] Busca local funcional
- [ ] Retorna licoes relevantes
- [ ] Mensagem clara se nada encontrado

#### 3.3 Adicionar comando CLI
**Arquivo**: `bin/aidev`
**Acao**: MODIFICAR comando `lessons`

```bash
# Extender:
aidev lessons --kb-search "termo"    # Busca na KB
aidev lessons --kb-list              # Lista licoes da KB
```

**Criterio de Aceite**:
- [ ] Comandos funcionais
- [ ] Saida formatada

---

## Sprint 4: Pre-Planning Protocol
**Prioridade**: ALTA
**Dependencias**: Sprint 3

### Tarefas

#### 4.1 Criar agente knowledge-manager.md
**Arquivo**: `.aidev/agents/knowledge-manager.md`
**Acao**: CRIAR

**Conteudo**:
- Role: Gerencia KB do projeto
- Triggers: Apos skill_complete de debugging
- Responsabilidades: Catalogacao, estruturacao, indexacao, consulta
- Protocol: Fluxo de catalogacao e consulta

**Criterio de Aceite**:
- [ ] Agente documentado completamente
- [ ] Protocolo de handoff definido

#### 4.2 Modificar orchestrator.md
**Arquivo**: `.aidev/agents/orchestrator.md`
**Acao**: MODIFICAR

**Adicionar secao**:
```markdown
## Pre-Planning Protocol (OBRIGATORIO)

ANTES de iniciar qualquer skill de planejamento ou codificacao:

1. Consulta KB: kb_consult_before_coding("$task")
2. Se licao encontrada: aplicar correcao conhecida
3. Se nao encontrada: prosseguir normalmente
```

**Criterio de Aceite**:
- [ ] Protocolo documentado
- [ ] Instrucoes claras para LLM

#### 4.3 Testes end-to-end
**Arquivo**: `tests/e2e/test-kb-flow.sh`
**Acao**: CRIAR

```bash
# Testes:
test_full_flow_error_to_lesson()
test_consult_before_new_task()
test_reuse_existing_lesson()
```

**Criterio de Aceite**:
- [ ] Fluxo completo testado
- [ ] Economia de tokens verificavel

---

## Sprint 5: Integracao MCP
**Prioridade**: MEDIA
**Dependencias**: Sprint 1, Sprint 3

### Tarefas

#### 5.1 Implementar kb_sync_to_basic_memory()
**Arquivo**: `lib/kb.sh`
**Acao**: ADICIONAR

```bash
kb_sync_to_basic_memory()      # Sincroniza com Basic Memory MCP
```

**Criterio de Aceite**:
- [ ] Gera instrucao MCP correta
- [ ] Funciona em background (nao bloqueia)

#### 5.2 Implementar kb_sync_to_serena()
**Arquivo**: `lib/kb.sh`
**Acao**: ADICIONAR

```bash
kb_sync_to_serena()            # Sincroniza com Serena memories
```

**Criterio de Aceite**:
- [ ] Gera instrucao MCP correta
- [ ] Funciona em background

#### 5.3 Estender kb_consult_before_coding() para MCPs
**Arquivo**: `lib/kb.sh`
**Acao**: MODIFICAR

```bash
# Adicionar busca em:
# - Basic Memory (se BASIC_MEMORY_ENABLED=true)
# - Serena memories (se disponivel)
```

**Criterio de Aceite**:
- [ ] Busca multi-backend
- [ ] Fallback gracioso se MCP indisponivel

---

## Sprint 6: Rebuild Cache e Documentacao
**Prioridade**: BAIXA
**Dependencias**: Sprints 1-5

### Tarefas

#### 6.1 Atualizar activation cache
**Acao**: Garantir que kb.sh seja incluido no cache

```bash
aidev cache --build
```

**Criterio de Aceite**:
- [ ] Cache inclui novo agente knowledge-manager
- [ ] Cache atualizado com nova estrutura

#### 6.2 Documentar no README
**Arquivo**: `README.md`
**Acao**: ADICIONAR secao sobre KB

**Criterio de Aceite**:
- [ ] Documentacao clara
- [ ] Exemplos de uso

#### 6.3 Criar memoria Serena
**Acao**: Escrever memoria sobre o sistema

```bash
mcp__serena__write_memory memory_file_name="kb_system" content="..."
```

**Criterio de Aceite**:
- [ ] Memoria criada
- [ ] Acessivel para futuras sessoes

---

# RESUMO DE ARQUIVOS

| Sprint | Arquivo | Acao |
|--------|---------|------|
| 1 | `lib/kb.sh` | CRIAR |
| 1 | `tests/unit/test-kb.sh` | CRIAR |
| 2 | `lib/orchestration.sh` | MODIFICAR |
| 2 | `tests/integration/test-kb-hooks.sh` | CRIAR |
| 3 | `lib/kb.sh` | ADICIONAR funcoes |
| 3 | `bin/aidev` | MODIFICAR |
| 4 | `.aidev/agents/knowledge-manager.md` | CRIAR |
| 4 | `.aidev/agents/orchestrator.md` | MODIFICAR |
| 4 | `tests/e2e/test-kb-flow.sh` | CRIAR |
| 5 | `lib/kb.sh` | ADICIONAR funcoes MCP |
| 6 | `README.md` | MODIFICAR |

---

# FUNCOES EXISTENTES A REUTILIZAR

| Funcao | Arquivo | Proposito |
|--------|---------|-----------|
| `memory_save()` | lib/memory.sh:140 | Salvar licoes localmente |
| `memory_search()` | lib/memory.sh:50 | Buscar em memorias |
| `state_read_section()` | lib/state.sh:80 | Extrair contexto de erro |
| `detect_stack()` | lib/core.sh:200 | Identificar stack do projeto |
| `ensure_dir()` | lib/core.sh | Criar diretorios |
| `print_success/error/info` | lib/core.sh | Output formatado |

---

# FORMATO DE LICAO ESTRUTURADA

```markdown
---
id: KB-2026-02-04-001
type: learned-lesson
exception: "TypeError: Cannot read property 'map' of undefined"
symptoms:
  - "Console error on page load"
  - "Component fails to render"
root_cause: "API returns null instead of empty array"
tags: [react, null-safety, api-contract]
resolved_at: 2026-02-04T14:30:00Z
skill_context: systematic-debugging
---

# Licao: Null Safety em Respostas de API

**Data**: 2026-02-04
**Stack**: react
**Contexto**: systematic-debugging

## Sintomas
- Console error on page load
- Component fails to render

## Causa Raiz
API returns null instead of empty array when no data exists.

## Correcao
```diff
- const items = data.map(...)
+ const items = (data || []).map(...)
```

## Prevencao
- [ ] Adicionar validacao para este caso
- [ ] Criar teste de regressao
```

---

# VERIFICACAO FINAL

### Comandos de Teste
```bash
# Verificar estrutura
ls -la .aidev/memory/kb/

# Verificar indice
cat .aidev/memory/kb/index.json

# Testar busca
aidev lessons --kb-search "null pointer"

# Verificar cache
aidev cache --show | grep knowledge-manager

# Rodar testes
./tests/run-tests.sh --filter kb
```

### Resultado Esperado
1. Catalogacao automatica apos systematic-debugging
2. Consulta obrigatoria antes de codificar
3. Sincronizacao com MCPs
4. Zero tokens extras para erros recorrentes
