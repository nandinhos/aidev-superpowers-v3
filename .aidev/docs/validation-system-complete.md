# Sistema de Validação e Gestão de Conhecimento - Documentação Completa

**Versão**: 2.0.0  
**Sprints**: 1 (Foundation) + 2 (Knowledge Management)  
**Data**: 2026-02-11  
**Status**: ✅ Completo

---

## 📚 Sumário

1. [Visão Geral](#visão-geral)
2. [Sprint 1: Foundation](#sprint-1-foundation)
3. [Sprint 2: Knowledge Management](#sprint-2-knowledge-management)
4. [Arquitetura do Sistema](#arquitetura-do-sistema)
5. [Guia de Uso](#guia-de-uso)
6. [API de Referência](#api-de-referência)
7. [Testes](#testes)
8. [Troubleshooting](#troubleshooting)

---

## Visão Geral

Sistema completo de validação automática e gestão de conhecimento para o AI Dev Superpowers, garantindo:

- ✅ **Qualidade de Código** - Validações automáticas em cada ação
- ✅ **Rastreabilidade** - Histórico completo de decisões e erros
- ✅ **Economia de Tokens** - Reutilização de lições aprendidas
- ✅ **Continuidade** - Gestão robusta de sprints e checkpoints

### Métricas do Projeto

| Componente | Testes | Cobertura |
|------------|--------|-----------|
| Validators | 30/30 | 100% |
| Validation Engine | 4/4 | 100% |
| Context Passport | 12/12 | 100% |
| Auto-Catalog | 13/13 | 100% |
| KB Search | 12/12 | 100% |
| Backlog | 12/12 | 100% |
| Pipeline | 5/5 | 100% |
| **TOTAL** | **101/101** | **100%** |

---

## Sprint 1: Foundation

### 1. Validators (`validators.sh`)

Funções determinísticas de validação para garantir padrões de código.

#### Funções Disponíveis

```bash
validate_safe_path(path)
# Retorna: 0 (seguro) ou 1 (bloqueado)
# Bloqueia: /etc, /usr, /var, /sys, /proc, /root, ~

validate_commit_format(message)
# Valida: tipo(escopo): descrição em português
# Exemplo válido: feat(auth): adiciona login JWT
# Retorna: 0 (válido) ou 1 (inválido)
# ✅ NOVO: Bloqueia Co-Authored-By automaticamente

validate_no_emoji(text)
# Detecta: 😀 ✨ 🔥 💯 🚀 ⭐ 💡 ⚠️ ❌ ✅ 📝 🔍 🎯 💪 👍 🙏
# Retorna: 0 (sem emoji) ou 1 (emoji detectado)

validate_portuguese_language(text)
# Detecta palavras em inglês: add, fix, update, remove, create
# Retorna: 0 (português) ou 1 (inglês detectado)

validate_no_forbidden_patterns(content)
# Bloqueia: eval(, innerHTML, exec(, system(, rm -rf /
# Retorna: 0 (seguro) ou 1 (proibido detectado)

validate_test_exists(file)
# Verifica TDD: arquivo de teste correspondente existe?
# Suporta: .js, .ts, .py, .php, .java, .go, .rs
# Retorna: 0 (teste existe) ou 1 (não existe)
```

#### Uso

```bash
source .aidev/lib/validators.sh

# Validar commit
if validate_commit_format "feat(auth): adiciona login"; then
    echo "✅ Commit válido"
fi

# Validar path
validate_safe_path "/home/user/projeto" || echo "❌ Path inseguro"
```

---

### 2. Validation Engine (`validation-engine.sh`)

Engine de validação com retry e fallback.

#### Funções

```bash
validation_with_retry(validator, input, max_retries=5)
# Tenta validação até 5 vezes com delay de 1s

validation_with_fallback(primary, fallback, input, context)
# Se primário falhar, tenta alternativa
# Se ambos falharem, escala para humano

validation_enforce(validator, input, description, force=false)
# Modo warning: avisa mas não bloqueia
# Modo strict: bloqueia ação

validation_pipeline(description, validator1|input1|desc1, ...)
# Pipeline completo de múltiplas validações
```

#### Modos de Operação

```bash
# Warning (padrão)
VALIDATION_MODE=warning
# Falhas mostram ⚠️ warning mas retornam 0

# Strict
VALIDATION_MODE=strict
# Falhas retornam ❌ e bloqueiam ação
# Use --force para override (registrado em auditoria)
```

---

### 3. Context Passport (`context-passport.sh`)

Sistema de passagem de contexto entre agentes.

#### Funções

```bash
passport_create(task_id, agent_role, parent_task_id)
# Cria novo passport com ID único

passport_save(passport_content)
# Salva em .aidev/state/passports/

passport_load(task_id)
# Carrega passport pelo task_id

passport_add_context_file(file, path, relevance, summary)
# Adiciona arquivo de contexto com score de relevância

passport_add_kb_reference(file, lesson_id, lesson_file, score)
# Adiciona referência a lição aprendida

passport_add_handoff(file, from_agent, to_agent, artifact, notes)
# Registra handoff entre agentes

passport_compact(file)
# Versão econômica em tokens

passport_estimate_tokens(file)
# Estima consumo de tokens (~4 chars/token)
```

#### Schema JSON

```json
{
  "passport_version": "1.0",
  "passport_id": "pp-<timestamp>",
  "task_id": "task-001",
  "agent_role": "backend",
  "session_context": {
    "project_name": "meu-projeto",
    "stack": "generic",
    "language": "pt-BR"
  },
  "constraints": {
    "max_tokens": 2000,
    "test_required": true
  },
  "context_files": [...],
  "kb_references": [...],
  "handoff_chain": [...]
}
```

---

## Sprint 2: Knowledge Management

### 4. Auto-Catalog (`auto-catalog.sh`)

Sistema de detecção automática e catalogação de lições aprendidas.

#### Funções

```bash
error_detector_init(task_id, error_pattern, context)
# Registra erro detectado para tracking

error_detector_check_resolution(task_id, test_command)
# Verifica se erro foi resolvido:
# - Executa test_command se fornecido
# - Ou verifica mudanças no git
# Retorna: RESOLVED, LIKELY_RESOLVED, STILL_FAILING

error_detector_mark_resolved(task_id)
# Marca erro como resolvido

auto_catalog_on_skill_complete(skill_name, task_id)
# Hook: cataloga automaticamente após debugging

auto_catalog_pre_coding(task_description)
# Hook: detecta erros na descrição da task

auto_catalog_stats()
# Mostra estatísticas do sistema
```

#### Template de Lição Criada

```markdown
---
id: KB-2026-02-11-001
type: learned-lesson
category: bug
exception: "NullPointerException"
tags: [auto-generated, error-resolution]
resolved_at: 2026-02-11T10:00:00Z
---

# Lição: NullPointerException

## Contexto
...

## Sintomas
- NullPointerException

## Causa Raiz
[5 Whys]

## Solução
```

---

### 5. KB Search (`kb-search.sh`)

Motor de busca em Knowledge Base com relevance scoring.

#### Funções

```bash
kb_search(query, max_results=5, use_mcp=true)
# Busca em KB local + MCPs (se disponíveis)
# Retorna: JSON com resultados ordenados por score

kb_search_by_category(category, max_results=10)
# Busca todas as lições de uma categoria

kb_pre_coding_search(task_description, passport_file)
# Hook: consulta KB antes de codificar
# Adiciona referências ao passport automaticamente

kb_check_lessons_before_action(action, min_relevance=50)
# Verifica se há lições aplicáveis
# Retorna: 0 (encontrou) ou 1 (não encontrou)

kb_build_index()
# Constrói índice para busca otimizada

kb_stats()
# Estatísticas da KB
```

#### Exemplo de Resultado

```json
[
  {
    "id": "KB-2026-02-11-001",
    "title": "Timeout em API Externa",
    "file": "2026-02-11-timeout-api.md",
    "score": 85,
    "source": "local",
    "category": "bug"
  }
]
```

#### Integração MCP Híbrida

```bash
# Verifica se MCPs estão disponíveis
# Se sim: usa busca semântica (economiza tokens)
# Se não: usa busca local (funciona sempre)

[KB-SEARCH] MCP Basic Memory: ✓ Tokens economizados
[KB-SEARCH] ℹ️  MCPs não disponíveis. Instale para economizar tokens:
    - Basic Memory: npm install -g @anthropics/basic-memory
    - Serena: pip install serena-mcp
```

---

### 6. Backlog (`backlog.sh`)

Sistema de gestão de erros e tarefas pendentes.

#### Funções de Erros

```bash
backlog_add_error(title, description, severity, tags, files)
# severity: low, medium, high, critical
# Retorna: error_id

backlog_resolve_error(id, notes, assignee)
# Marca erro como resolvido

backlog_list_open_errors()
# Lista ordenada por severidade

backlog_get_critical()
# Apenas erros críticos abertos

backlog_get_by_tag(tag)
# Erros com tag específica
```

#### Funções de Tarefas

```bash
backlog_add_task(title, description, priority, estimated_minutes)
# priority: low, medium, high, urgent

backlog_start_task(id, assignee)
# Marca como "in_progress"

backlog_complete_task(id)
# Marca como "completed"

backlog_list_pending_tasks()
# Lista ordenada por prioridade
```

#### Dashboard

```bash
backlog_show_dashboard()
# 📊 DASHBOARD DE BACKLOG
# ════════════════════════════════════════
# 🐛 ERROS:
#   Abertos: 3
#   Críticos: 1
#   Alta prioridade: 2
# 📋 TAREFAS:
#   Pendentes: 5
#   Em progresso: 2
#
# 🚨 ERROS CRÍTICOS (1):
#   • err-xxx: Timeout em API
```

---

### 7. Validation Pipeline (`validation-pipeline.sh`)

Integração completa no fluxo de trabalho.

#### Hooks

```bash
pre_coding_hook(task_description, passport_file)
# Executado antes de iniciar codificação:
# 1. Verifica lições relevantes no KB
# 2. Busca automaticamente em KB
# 3. Alerta sobre erros críticos no backlog

post_skill_hook(skill_name, task_id, result)
# Executado após completar skill:
# - Se skill de debug: cataloga lição automaticamente
```

#### Funções de Escrita Segura

```bash
orchestrator_safe_write(file_path, content, context)
# Valida antes de escrever

orchestrator_safe_edit(file_path, old, new, context)
# Valida antes de editar

orchestrator_safe_commit(message, files)
# Valida commit antes de executar

orchestrator_execute_task(task_id, description, agent_role)
# Fluxo completo com todos os hooks
```

#### Configuração

```bash
# .aidev/config/validation.conf
VALIDATION_MODE=warning
ENFORCE_TDD=true
ENFORCE_COMMIT_PT=true
ENFORCE_COMMIT_FORMAT=true
ENFORCE_NO_EMOJI=true
ENFORCE_SAFE_PATHS=true
AUTO_BACKLOG_ERRORS=true
```

---

## Arquitetura do Sistema

### Fluxo de Dados

```
┌─────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                          │
│                      (orchestrator_execute_task)            │
└──────────────┬──────────────────────────────────────────────┘
               │
       ┌───────┴───────┬──────────────┬──────────────┐
       ▼               ▼              ▼              ▼
┌────────────┐ ┌────────────┐ ┌──────────┐ ┌────────────┐
│ pre_coding │ │   Hooks    │ │ post_    │ │  Escrita   │
│   _hook    │ │  (hooks)   │ │  _skill  │ │   Segura   │
└─────┬──────┘ └─────┬──────┘ └────┬─────┘ └─────┬──────┘
      │              │             │             │
      ▼              ▼             ▼             ▼
┌────────────┐ ┌────────────┐ ┌──────────┐ ┌────────────┐
│ KB Search  │ │ Validators │ │ Auto-    │ │ Backlog    │
│            │ │  Engine    │ │  Catalog │ │            │
└────────────┘ └────────────┘ └──────────┘ └────────────┘
```

### Estrutura de Diretórios

```
.aidev/
├── lib/
│   ├── validators.sh              # 7 validadores
│   ├── validation-engine.sh       # Retry, fallback
│   ├── context-passport.sh        # Contexto entre agentes
│   ├── auto-catalog.sh            # Catalogação automática
│   ├── kb-search.sh               # Busca em KB
│   ├── backlog.sh                 # Gestão de backlog
│   └── validation-pipeline.sh     # Integração
├── tests/
│   ├── validators.test.sh         # 30 testes
│   ├── validation-engine.test.sh  # 4 testes
│   ├── context-passport.test.sh   # 12 testes
│   ├── auto-catalog.test.sh       # 13 testes
│   ├── kb-search.test.sh          # 12 testes
│   ├── backlog.test.sh            # 12 testes
│   └── validation-pipeline.test.sh # 5 testes
├── schemas/
│   └── context-passport.json      # Schema JSON
├── state/
│   ├── sprints/
│   │   ├── current/
│   │   │   ├── sprint-status.json
│   │   │   └── checkpoints/
│   │   ├── history/
│   │   ├── blocked/
│   │   └── handoffs/pending/
│   └── backlog.json
└── docs/
    └── validation-system-complete.md  # Este documento
```

---

## Guia de Uso

### Cenário 1: Novo Projeto

```bash
# 1. Iniciar sprint
./sprint.sh start

# 2. Criar passport para task
source .aidev/lib/context-passport.sh
pp=$(passport_create "feature-login" "backend")
pp_file=$(passport_save "$pp")

# 3. Adicionar contexto
passport_add_context_file "$pp_file" "docs/api-spec.yaml" 0.9
passport_add_kb_reference "$pp_file" "KB-001" "2026-02-11-jwt.md" 90

# 4. Executar com validações
source .aidev/lib/validation-pipeline.sh
orchestrator_execute_task "feature-login" "Implementar JWT" "backend"
```

### Cenário 2: Resolver Bug

```bash
# 1. Registrar erro no backlog
source .aidev/lib/backlog.sh
error_id=$(backlog_add_error "Timeout API" "API não responde" "high")

# 2. Trabalhar na correção
# ... debugging ...

# 3. Verificar se resolveu
source .aidev/lib/auto-catalog.sh
error_detector_check_resolution "$error_id" "npm test"

# 4. Marcar como resolvido
backlog_resolve_error "$error_id" "Aumentado timeout"
```

### Cenário 3: Commit Seguro

```bash
# Validar antes de commitar
source .aidev/lib/validation-pipeline.sh

# Tenta commit (vai falhar se inválido)
orchestrator_safe_commit "feat(auth): adiciona JWT" "src/auth.js src/auth.test.js"
```

---

## API de Referência

### CLI Sprint

```bash
./sprint.sh status           # Mostra status atual
./sprint.sh next             # Mostra próxima ação
./sprint.sh checkpoint       # Cria checkpoint
./sprint.sh update-task <id> <status> [notas]
./sprint.sh pause [motivo]   # Pausa sprint
./sprint.sh resume           # Retoma sprint
```

### Variáveis de Ambiente

```bash
VALIDATION_MODE=warning|strict
AUTO_CATALOG_ENABLED=true|false
KB_DIR=.aidev/memory/kb
BACKLOG_FILE=.aidev/state/backlog.json
MCP_BASIC_MEMORY_AVAILABLE=1  # Se MCP disponível
MCP_SERENA_AVAILABLE=1        # Se MCP disponível
```

---

## Testes

### Executar Todos os Testes

```bash
cd .aidev/tests

# Sprint 1
bash validators.test.sh           # 30 testes
bash validation-engine.test.sh    # 4 testes
bash context-passport.test.sh     # 12 testes

# Sprint 2
bash auto-catalog.test.sh         # 13 testes
bash kb-search.test.sh            # 12 testes
bash backlog.test.sh              # 12 testes
bash validation-pipeline.test.sh  # 5 testes
```

### Total: 101/101 ✅ (100%)

---

## Troubleshooting

### Problema: "jq: command not found"

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# CentOS/RHEL
sudo yum install jq
```

### Problema: Testes falham silenciosamente

```bash
# Verifique permissões
chmod +x .aidev/lib/*.sh .aidev/tests/*.sh

# Verifique dependências
jq --version
```

### Problema: "Passport não salva"

```bash
# Verifique permissões de escrita
ls -ld .aidev/state/
mkdir -p .aidev/state/passports
```

### Problema: MCP não detectado

```bash
# Instale MCPs
npm install -g @anthropics/basic-memory
pip install serena-mcp

# Ou defina variáveis
export MCP_BASIC_MEMORY_AVAILABLE=1
export MCP_SERENA_AVAILABLE=1
```

---

## Changelog

### v2.0.0 (2026-02-11)
- ✅ Sprint 2: Knowledge Management completa
- ✅ 42 novos testes (total: 101)
- ✅ Auto-catalogação de lições
- ✅ Motor de busca em KB
- ✅ Sistema de backlog
- ✅ Pipeline de validação integrado

### v1.0.0 (2026-02-11)
- ✅ Sprint 1: Foundation
- ✅ 59 testes
- ✅ Validators completos
- ✅ Validation Engine
- ✅ Context Passport
- ✅ Documentação inicial

---

## Próximos Passos

### Sprint 3 (Planejada): Interface CLI
- Comando `aidev` unificado
- Subcomandos: validate, sprint, kb, backlog
- Autocompletion
- Configuração interativa

### Sprint 4 (Planejada): Documentação Interativa
- Gerador de docs automático
- Exemplos interativos
- Tutorial passo a passo

### Sprint 5 (Planejada): Multi-Agente
- Execução paralela
- Comunicação entre agentes
- Coordenação distribuída

---

**Sistema Completo e Documentado!** 🎉

Para dúvidas ou suporte, consulte:
- Este documento
- Testes em `.aidev/tests/`
- Handoffs em `.aidev/state/sprints/handoffs/pending/`
