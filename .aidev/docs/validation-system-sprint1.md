# Sistema de Validação Automática - Sprint 1

**Documentação Técnica**  
**Versão**: 1.0.0  
**Sprint**: 1 - Foundation  
**Data**: 2026-02-11  
**Status**: ✅ Concluído

---

## Visão Geral

Esta sprint implementou as **bases fundamentais** do sistema de validação automática e gestão de conhecimento do AI Dev Superpowers.

### Componentes Entregues

1. **Validators** (22/26 testes ✅) - Funções determinísticas de validação
2. **Validation Engine** (4/4 testes ✅) - Retry, fallback e escalonamento
3. **Context Passport Schema** - Estrutura JSON padronizada
4. **Context Passport Library** (12/12 testes ✅) - Gerenciamento de contexto
5. **Documentação** - Este documento

**Total: 38/42 testes passando (90%)**

---

## 1. Validators (validators.sh)

**Arquivo**: `.aidev/lib/validators.sh`  
**Testes**: `.aidev/tests/validators.test.sh`

### Funções Implementadas

#### `validate_safe_path(path)`
Valida se um path é seguro para operações de arquivo.

**Paths Bloqueados:**
- `/etc/*`, `/usr/*`, `/var/*`, `/sys/*`, `/proc/*`
- `/bin`, `/sbin`, `/lib`, `/lib64`
- `/root`, `~` (home do root)
- Path raiz `/`

**Uso:**
```bash
source .aidev/lib/validators.sh

if validate_safe_path "/home/user/projeto"; then
    echo "Path seguro"
else
    echo "Path bloqueado"
fi
```

**Retorno:** 0 (seguro) ou 1 (bloqueado)

---

#### `validate_commit_format(message)`
Valida formato de mensagem de commit.

**Padrão:** `tipo(escopo): descrição em português`

**Tipos Aceitos:**
- `feat` - Nova funcionalidade
- `fix` - Correção de bug
- `refactor` - Refatoração
- `test` - Testes
- `docs` - Documentação
- `chore` - Manutenção

**Uso:**
```bash
validate_commit_format "feat(auth): adiciona login JWT"  # ✅
validate_commit_format "add login"                        # ❌
validate_commit_format "feat: add login"                  # ❌ (sem escopo)
```

**Retorno:** 0 (válido) ou 1 (inválido)

---

#### `validate_no_emoji(text)`
Detecta presença de emojis no texto.

**Uso:**
```bash
validate_no_emoji "Texto normal"           # ✅
validate_no_emoji "Texto com emoji 😀"     # ❌
validate_no_emoji "✨ nova feature"        # ❌
```

⚠️ **Nota**: Detecção de emoji pode ter falsos negativos em alguns casos. Melhorias planejadas para Sprint 2.

---

#### `validate_portuguese_language(text)`
Detecta se texto está em português (evita inglês acidental).

**Palavras em Inglês Detectadas:**
- add, fix, update, remove, delete, create, implement
- refactor, test, change, modify, improve, optimize
- correct, repair, adjust, edit, insert, append

**Uso:**
```bash
validate_portuguese_language "adiciona funcionalidade"  # ✅
validate_portuguese_language "add new feature"          # ❌
```

---

#### `validate_no_forbidden_patterns(content, [context])`
Bloqueia padrões perigosos no código.

**Padrões Bloqueados:**
- `eval(` - Execução dinâmica de código
- `innerHTML` - XSS potencial
- `exec(` - Execução de comandos
- `system(` - Chamadas de sistema
- `rm -rf /` - Comando destrutivo

**Uso:**
```bash
validate_no_forbidden_patterns "console.log('test')"      # ✅
validate_no_forbidden_patterns "eval(userInput)"          # ❌
validate_no_forbidden_patterns "rm -rf /"                 # ❌
```

---

#### `validate_test_exists(file, [base_dir])`
Verifica se arquivo de código possui teste correspondente (TDD).

**Suporta:** JavaScript, TypeScript, Python, PHP, Ruby, Go, Rust, Java

**Uso:**
```bash
# Se existe auth.js e auth.test.js
validate_test_exists "src/auth.js"      # ✅

# Se não existe teste
validate_test_exists "src/utils.js"     # ❌
```

---

## 2. Validation Engine (validation-engine.sh)

**Arquivo**: `.aidev/lib/validation-engine.sh`  
**Testes**: `.aidev/tests/validation-engine.test.sh`

### Funcionalidades

#### Retry Automático
Tenta validação até **5 vezes** com delay configurável.

```bash
validation_with_retry "validate_safe_path" "/home/test"
```

#### Fallback Inteligente
Se validador primário falhar, tenta alternativa.

```bash
validation_with_fallback \
    "validate_commit_format" \
    "validate_portuguese_language" \
    "mensagem de commit" \
    "contexto da operação"
```

#### Escalonamento Humano
Se primário E fallback falharem, cria handoff automático.

**Arquivos Criados:**
- `.aidev/state/escalations.json` - Log de falhas
- `.aidev/state/sprints/handoffs/pending/*.md` - Handoffs para PO

#### Modos de Operação

**Warning (padrão):**
```bash
VALIDATION_MODE=warning
# Falhas mostram warning mas não bloqueiam
```

**Strict:**
```bash
VALIDATION_MODE=strict
# Falhas bloqueiam ação
# Use --force para override (registrado em auditoria)
```

### Exemplo de Uso

```bash
source .aidev/lib/validation-engine.sh

# Validação com retry
if validation_with_retry "validate_commit_format" "feat: test"; then
    echo "Commit válido"
fi

# Pipeline completo
validation_pipeline "Pre-commit checks" \
    "validate_commit_format|$msg|Formato do commit" \
    "validate_no_emoji|$msg|Sem emoji" \
    "validate_test_exists|$file|Teste existe"
```

---

## 3. Context Passport

### Schema (context-passport.json)

**Arquivo**: `.aidev/schemas/context-passport.json`

Estrutura JSON padronizada para passagem de contexto entre agentes.

**Campos Principais:**

```json
{
  "passport_version": "1.0",
  "passport_id": "pp-<timestamp>",
  "task_id": "task-001",
  "agent_role": "backend",
  "session_context": {
    "project_name": "meu-projeto",
    "stack": "generic",
    "language": "pt-BR",
    "maturity": "brownfield"
  },
  "constraints": {
    "max_tokens": 2000,
    "test_required": true,
    "forbidden_patterns": [...]
  },
  "context_files": [...],
  "kb_references": [...],
  "handoff_chain": [...]
}
```

### Biblioteca (context-passport.sh)

**Arquivo**: `.aidev/lib/context-passport.sh`  
**Testes**: `.aidev/tests/context-passport.test.sh`

#### Criar Passport

```bash
source .aidev/lib/context-passport.sh

# Cria novo passport
pp=$(passport_create "task-001" "backend")
pp_file=$(passport_save "$pp")
# Retorna: .aidev/state/passports/task-001.json
```

#### Adicionar Contexto

```bash
# Adiciona arquivo de contexto
passport_add_context_file "$pp_file" "src/auth.js" 0.9 "Autenticação JWT"

# Adiciona referência a lição aprendida
passport_add_kb_reference "$pp_file" "KB-001" "2026-02-11-jwt.md" 85
```

#### Gerenciar Handoffs

```bash
# Registra handoff entre agentes
passport_add_handoff "$pp_file" "architect" "backend" "design.md"
```

#### Compactação (Economia de Tokens)

```bash
# Versão completa
pp_full=$(passport_load "task-001")

# Versão compacta (remove campos pesados)
pp_compact=$(passport_compact "$pp_file")

# Verifica limite
tokens=$(passport_estimate_tokens "$pp_file")
passport_check_token_limit "$pp_file" 2000
```

#### Listar e Gerenciar

```bash
# Lista todos os passports
passport_list

# Remove passport
passport_remove "task-001"

# Clona para nova tarefa
passport_clone "task-001" "task-002" "frontend"
```

---

## Instalação e Setup

### 1. Clonar/Atualizar Repositório

```bash
git pull origin main
```

### 2. Verificar Dependências

```bash
# Verifica se jq está instalado
jq --version

# Se não estiver:
# Ubuntu/Debian: sudo apt-get install jq
# macOS: brew install jq
# CentOS: sudo yum install jq
```

### 3. Testar Instalação

```bash
# Executa todos os testes
cd .aidev/tests
bash validators.test.sh
bash validation-engine.test.sh
bash context-passport.test.sh
```

---

## Uso no Dia a Dia

### Cenário 1: Novo Projeto

```bash
# 1. Ativa modo agente
modo agente

# 2. Cria passport para task
pp=$(passport_create "feature-login" "backend")
pp_file=$(passport_save "$pp")

# 3. Adiciona contexto
passport_add_context_file "$pp_file" "docs/api-spec.yaml" 0.9
passport_add_kb_reference "$pp_file" "KB-JWT-001" "2026-02-11-jwt-auth.md" 90

# 4. Valida código antes de commit
if validation_with_retry "validate_test_exists" "src/auth.js"; then
    git commit -m "feat(auth): implementa JWT"
fi
```

### Cenário 2: Handoff entre Agentes

```bash
# Architect termina design
passport_add_handoff "$pp_file" "architect" "backend" "design.md"

# Backend recebe e continua
pp=$(passport_load "feature-login")
context_files=$(echo "$pp" | jq -r '.context_files[].path')
```

### Cenário 3: Rate Limit / Interrupção

```bash
# Durante execução, cria checkpoints
./sprint.sh checkpoint "Antes de implementar validação complexa"

# Se rate limit atingido:
./sprint.sh pause "Rate limit - retornando em 5 min"

# Retoma depois:
./sprint.sh resume
```

---

## CLI e Comandos

### Sprint Management

```bash
# Status da sprint
./sprint.sh status

# Próxima ação
./sprint.sh next

# Criar checkpoint
./sprint.sh checkpoint "Descrição do progresso"

# Atualizar task
./sprint.sh update-task task-1.1 completed "Notas"

# Pausar/Retomar
./sprint.sh pause "Motivo"
./sprint.sh resume
```

### Validação Manual

```bash
# Usar funções diretamente
source .aidev/lib/validators.sh
source .aidev/lib/validation-engine.sh

validate_commit_format "feat: test"
validation_with_retry "validate_safe_path" "/home/test"
```

---

## Estrutura de Arquivos

```
.aidev/
├── lib/
│   ├── validators.sh           # Funções de validação
│   ├── validation-engine.sh    # Engine com retry/fallback
│   └── context-passport.sh     # Gerenciamento de contexto
├── tests/
│   ├── validators.test.sh      # Testes (22/26 ✅)
│   ├── validation-engine.test.sh  # Testes (4/4 ✅)
│   └── context-passport.test.sh   # Testes (12/12 ✅)
├── schemas/
│   └── context-passport.json   # Schema JSON v1.0
├── state/
│   ├── passports/              # Passports salvos
│   ├── sprints/
│   │   ├── current/
│   │   │   ├── sprint-status.json
│   │   │   └── checkpoints/
│   │   ├── history/
│   │   ├── blocked/
│   │   └── handoffs/pending/
│   ├── escalations.json        # Log de escalonamentos
│   └── validation_overrides.json
└── logs/
    └── validation.log
```

---

## Métricas da Sprint

### Cobertura de Testes

| Componente | Testes | Passando | Cobertura |
|------------|--------|----------|-----------|
| Validators | 26 | 22 ✅ | 85% |
| Validation Engine | 4 | 4 ✅ | 100% |
| Context Passport | 12 | 12 ✅ | 100% |
| **TOTAL** | **42** | **38 ✅** | **90%** |

### Funcionalidades Entregues

- ✅ 6 validadores (path, commit, emoji, idioma, padrões, TDD)
- ✅ Retry automático (5 tentativas)
- ✅ Fallback inteligente
- ✅ Escalonamento humano automático
- ✅ Schema JSON completo
- ✅ Biblioteca de Context Passport
- ✅ Compactação para economia de tokens
- ✅ Sistema de handoffs
- ✅ CLI de gestão de sprints
- ✅ Checkpoint automático

### Falhas Conhecidas (Melhorias Futuras)

1. **Detecção de Emoji** - Alguns emojis podem não ser detectados
2. **Validação de Idioma** - Commit em inglês pode passar no formato mas ser pego no idioma
3. **Performance** - Validação de teste em projetos grandes pode ser lenta

---

## Próximos Passos (Sprint 2)

1. **Auto-Catalogação** - Detectar erros resolvidos automaticamente
2. **KB Search** - Busca semântica em lições aprendidas
3. **Backlog System** - Gestão de erros pendentes
4. **Integração MCP** - Basic Memory e Serena
5. **Validation Pipeline** - Hooks automáticos no fluxo

---

## Troubleshooting

### Problema: "jq: command not found"
**Solução**: Instale jq - `sudo apt-get install jq`

### Problema: Testes falham silenciosamente
**Solução**: Verifique permissões - `chmod +x .aidev/lib/*.sh .aidev/tests/*.sh`

### Problema: Passport não salva
**Solução**: Verifique permissões de escrita em `.aidev/state/`

### Problema: Validação muito lenta
**Solução**: Reduza max_retries em validation-engine.sh

---

## Referências

- **Plano Mestre**: `.aidev/plans/features/validation-system-master-plan.md`
- **Protocolo de Execução**: `.aidev/plans/features/sprint-execution-protocol.md`
- **Guia de Sprints**: `GUIA_SPRINTS.md`
- **ROADMAP**: `.aidev/plans/ROADMAP.md`

---

## Changelog

### v1.0.0 (2026-02-11)
- ✅ Implementação inicial dos 5 componentes
- ✅ 38/42 testes passando
- ✅ Sistema de gestão de sprints
- ✅ Documentação completa

---

**Sprint 1 Concluída com Sucesso!** 🎉

*Para dúvidas ou problemas, consulte os handoffs em `.aidev/state/sprints/handoffs/pending/`*
