# Plano: Integração Graceful do Basic Memory

## Contexto

O Basic Memory MCP é uma ferramenta poderosa para persistência de conhecimento cross-session,
mas **nem todos os usuários terão o MCP instalado**. A integração atual existe parcialmente
(checkpoint-manager, kb-search, knowledge-manager), porém não há um mecanismo unificado de
**detecção graceful** que permita ao framework funcionar com a mesma maestria com ou sem ele.

### Problema Central

Quando o Basic Memory não está disponível:
- Chamadas `mcp__basic-memory__*` falham silenciosamente ou geram erros
- Não há fallback inteligente para as funcionalidades que dependem dele
- O framework desperdiça tokens tentando usar algo que não existe
- O `ckpt_sync_to_basic_memory` está como Fase 2 pendente sem detecção prévia

### Problema Adicional: Multi-Runtime

O framework é usado em múltiplos runtimes de LLM:
- **Claude Code CLI** — MCPs expostos como funções bash (`type mcp__basic-memory__write_note`)
- **Antigravity Editor (Claude)** — MCPs disponíveis via configuração `.mcp.json`
- **Antigravity Editor (Gemini)** — MCPs disponíveis mas com mecanismo diferente
- **Gemini CLI** — MCPs não expostos como funções bash
- **OpenCode** — MCPs não expostos como funções bash

A abordagem `type mcp__basic-memory__write_note &>/dev/null` **só funciona no Claude Code**.
O Sprint 1 precisa de uma estratégia de detecção multi-camada que cubra todos os runtimes.

### Impacto na Economia de Tokens

| Cenário | Sem Basic Memory | Com Basic Memory | Economia |
|---------|-----------------|------------------|----------|
| Inicialização de agente | ~1.600 tokens | ~550 tokens | 66% |
| Carga de checkpoint | ~500 tokens | ~200 tokens | 60% |
| Busca de contexto | 0 (inexistente) | ~50 tokens | Capacidade nova |
| Persistência | 1 sessão | Infinitas sessões | Continuidade total |

## Objetivo

Criar um sistema de **detecção e adaptação graceful** que:
1. Detecta automaticamente se o Basic Memory MCP está disponível (em qualquer runtime)
2. Ativa funcionalidades extras quando presente (modo "turbo")
3. Funciona perfeitamente sem ele (modo "standard")
4. Nunca gera erros ou desperdício de tokens pela ausência

## Estado Atual do Código

### O que existe e onde está

| Componente | Localização Real | Status |
|---|---|---|
| `checkpoint-manager.sh` | `lib/checkpoint-manager.sh` (raiz, 491 linhas) + `~/.aidev-superpowers/lib/` | Existe — **NÃO** em `.aidev/lib/` |
| `ckpt_to_basic_memory_note()` | `lib/checkpoint-manager.sh` linhas 254-384 | Existe (Fase 1 concluída) |
| `ckpt_sync_to_basic_memory()` | **NÃO EXISTE** | Fase 2 pendente |
| `ckpt_create()` + lógica inline BM | `lib/checkpoint-manager.sh` linhas 92-106 | Existe mas sem guard multi-runtime |
| `context_compressor_generate()` | `lib/context-compressor.sh` (raiz, 83 linhas) | Existe — modo básico funcional |
| `_kb_check_mcp_availability()` | `.aidev/lib/kb-search.sh` | Existe — padrão a reusar |
| `detect_runtime()` | `.aidev/lib/activation-snapshot.sh` | Existe — reusar no Sprint 1 |
| `cmd_status` / `cmd_doctor` | **NÃO EXISTEM** | A criar do zero no Sprint 5 |
| `mcp-detect.sh` | **NÃO EXISTE** | A criar no Sprint 1 |
| `basic-memory-guard.sh` | **NÃO EXISTE** | A criar no Sprint 2 |

### Inconsistências no Framework (a resolver junto com o Sprint 1)

1. **3 implementações divergentes de `detect_runtime()`**: `activation-snapshot.sh` (global), `activation-snapshot.sh` (projeto), e `detection.sh`. Usam variáveis diferentes (`$ANTIGRAVITY` vs `$ANTIGRAVITY_AGENT`). A canônica é a de `activation-snapshot.sh`.

2. **`mcp_bridge_check()` é um stub** em `~/.aidev-superpowers/lib/mcp-bridge.sh`: retorna 0 só para `$ANTIGRAVITY_AGENT`, 1 para todos os demais. O Sprint 1 substitui esse stub com `mcp_detect_basic_memory()`.

3. **`memory_mcp_available()` em `~/.aidev-superpowers/lib/memory.sh`**: apenas `${BASIC_MEMORY_ENABLED:-false}=true`, sem lógica de runtime.

## Arquitetura Proposta

```
┌─────────────────────────────────────────────────┐
│              aidev init / upgrade                │
│                     │                            │
│          mcp_detect_basic_memory()               │
│          (multi-camada, multi-runtime)           │
│                     │                            │
│         ┌───────────┴───────────┐                │
│         │                       │                │
│   basic-memory: ✓          basic-memory: ✗       │
│         │                       │                │
│   BASIC_MEMORY_AVAILABLE=true   BASIC_MEMORY_    │
│   Ativa sync, search,          AVAILABLE=false   │
│   cross-project learning       Usa local KB,     │
│                                 checkpoints MD   │
│         │                       │                │
│         └───────────┬───────────┘                │
│                     │                            │
│           Funciona com maestria                   │
│           em todos os runtimes                   │
└─────────────────────────────────────────────────┘
```

## Sprints

### Pré-Sprint 0: Corrigir Pipeline de Distribuição (DESBLOQUEADOR)

**Objetivo**: Garantir que qualquer arquivo novo em `.aidev/lib/` chegue automaticamente nos projetos
via self-upgrade e `aidev upgrade`. Sem isso, todos os sprints seguintes produzem código que não é
distribuído.

**Problema identificado**:

O self-upgrade (`aidev self-upgrade`) sincroniza apenas `lib/` (raiz) via `rsync`. O `.aidev/lib/`
não é incluído — e o `create_base_structure()` copia manualmente só `feature-lifecycle.sh`.
Resultado: qualquer novo `.sh` criado em `.aidev/lib/` existe só no projeto-fonte e nunca chega
no global nem nos projetos dos usuários.

Evidência: `~/.aidev-superpowers/.aidev/lib/` já está desatualizado vs `aidev-superpowers-v3-1/.aidev/lib/`:
- Ausentes no global: `activation-snapshot.sh`, `workflow-commit.sh`, `workflow-release.sh`, `workflow-sync.sh`

**Arquivos a modificar**: `bin/aidev` (projeto-fonte e global)

**Tarefas**:

1. **Criar `install_aidev_lib()`** em `bin/aidev` — análogo a `install_agents()`:

   ```bash
   install_aidev_lib() {
       local path="$1"
       local src_lib="$AIDEV_ROOT_DIR/.aidev/lib"
       local dst_lib="$path/.aidev/lib"

       ensure_dir "$dst_lib"

       for lib_file in "$src_lib"/*.sh; do
           [ -f "$lib_file" ] || continue
           cp "$lib_file" "$dst_lib/"
           chmod +x "$dst_lib/$(basename "$lib_file")"
       done
   }
   ```

2. **Adicionar chamada em `create_base_structure()`** (linha ~1591):

   ```bash
   # Substituir o if manual do feature-lifecycle.sh por:
   install_aidev_lib "$path"
   ```

3. **Adicionar chamada em `cmd_upgrade()`** (~linha 303, junto com install_agents/skills/rules):

   ```bash
   print_step "Atualizando .aidev/lib/..."
   install_aidev_lib "$install_path"
   ```

4. **Adicionar rsync do `.aidev/lib/` no self-upgrade** (após o rsync de `lib/`, ~linha 3288):

   ```bash
   print_step "Sincronizando .aidev/lib/..."
   rsync -a --delete "$source_dir/.aidev/lib/" "$global_install/.aidev/lib/" 2>/dev/null || {
       print_error "Falha ao sincronizar .aidev/lib/"
       _self_upgrade_rollback
       exit 1
   }
   ```

5. **Atualizar dry-run** para listar `.aidev/lib/*.sh` na prévia de mudanças

**Testes**:
- `test_install_aidev_lib_copies_all_sh` — todos os `.sh` de `.aidev/lib/` são copiados
- `test_upgrade_includes_aidev_lib` — `cmd_upgrade` chama `install_aidev_lib`
- `test_self_upgrade_syncs_aidev_lib` — rsync inclui `.aidev/lib/`
- `test_new_lib_file_reaches_project` — cria arquivo novo, roda upgrade, verifica que chegou

**Validação manual**:
```bash
# Após implementar:
aidev self-upgrade
ls ~/.aidev-superpowers/.aidev/lib/  # deve ter todos os arquivos do projeto-fonte
cd /outro-projeto && aidev upgrade
ls .aidev/lib/  # deve ter os mesmos arquivos
```

**Estimativa**: ~30min

**Critério de conclusão**: Todos os arquivos de `.aidev/lib/` do projeto-fonte chegam no global
após `aidev self-upgrade` e nos projetos após `aidev upgrade`. Novos arquivos dos Sprints 1-5
serão distribuídos automaticamente sem configuração adicional.

---

### Sprint 1: Detecção Unificada Multi-Runtime (`.aidev/lib/mcp-detect.sh`)

**Objetivo**: Criar módulo centralizado de detecção de MCPs com suporte a todos os runtimes.

**Contexto**: A abordagem `type mcp__basic-memory__write_note` só funciona no Claude Code.
Precisamos de detecção multi-camada.

**Tarefas**:

1. **Criar `.aidev/lib/mcp-detect.sh`** com função `mcp_detect_basic_memory()`:

   ```bash
   mcp_detect_basic_memory() {
       # Cache: evita re-detecção na mesma sessão
       [ -n "${_AIDEV_BM_DETECTED+x}" ] && return "$_AIDEV_BM_DETECTED"

       local result=1

       # Camada 1: variável explícita (setada pelo usuário ou wrapper de launch)
       if [ "${BASIC_MEMORY_ENABLED:-false}" = "true" ] || \
          [ -n "$MCP_BASIC_MEMORY_AVAILABLE" ]; then
           result=0

       # Camada 2: presença em .mcp.json (declarativa, runtime-agnóstica)
       elif [ -f ".mcp.json" ] && grep -q '"basic-memory"' ".mcp.json" 2>/dev/null; then
           local runtime
           runtime=$(detect_runtime 2>/dev/null || echo "unknown")

           case "$runtime" in
               claude_code)
                   # Claude Code: confirmar via type (funções bash injetadas pelo MCP)
                   type mcp__basic-memory__write_note &>/dev/null && result=0
                   ;;
               antigravity)
                   # Antigravity: MCPs em .mcp.json são expostos automaticamente
                   result=0
                   ;;
               gemini|opencode|*)
                   # Outros: confirmar via CLI instalado
                   command -v basic-memory &>/dev/null && result=0
                   ;;
           esac
       fi

       # Cache do resultado
       export _AIDEV_BM_DETECTED=$result
       return $result
   }
   ```

2. **Função `mcp_detect_available()`** (genérica para qualquer MCP):
   - Recebe nome do MCP como parâmetro
   - Verifica `.mcp.json` + runtime capabilities
   - Exporta `MCP_AVAILABLE_SERVERS` (lista separada por espaço)

3. **Resolver inconsistência `detect_runtime()`**:
   - Adotar a versão de `.aidev/lib/activation-snapshot.sh` como canônica
   - Unificar variável: `$ANTIGRAVITY` (já usada na versão canônica)
   - Substituir o stub `mcp_bridge_check()` em `~/.aidev-superpowers/lib/mcp-bridge.sh`

4. **Integrar na inicialização**:
   - `workflow-sync.sh`: chamar `mcp_detect_basic_memory()` ao sincronizar
   - `.aidev/lib/kb-search.sh`: substituir `_kb_check_mcp_availability()` por `mcp_detect_basic_memory()`
   - Dashboard da ativação: exibir "Basic Memory: ✓ ativo [runtime]" ou "Basic Memory: ✗ (local mode)"

**Testes** (usar `tests/helpers/test-framework.sh`):
- `test_mcp_detect_with_env_var` — `BASIC_MEMORY_ENABLED=true` retorna 0
- `test_mcp_detect_with_mcp_json` — `.mcp.json` com `basic-memory` no runtime claude_code
- `test_mcp_detect_without_bm` — sem variáveis nem config, retorna 1
- `test_mcp_detect_cache` — segunda chamada não re-detecta (verifica `_AIDEV_BM_DETECTED`)
- `test_mcp_detect_gemini_runtime` — simula `$OPENCODE=1` sem `command -v basic-memory`, retorna 1

**Estimativa**: ~60min

---

### Sprint 2: Guard Functions — Bash + LLM (Duas Camadas)

**Objetivo**: Proteger chamadas ao Basic Memory em scripts bash E atualizar instruções para o LLM.

**Tarefas**:

**Camada A — `lib/basic-memory-guard.sh`** (bash scripts, sourced por outros `.sh`):

```bash
# Wrapper seguro para write_note (bash scripts)
bm_write_note() {
    local title="$1" content="$2" directory="${3:-kb}"

    if ! mcp_detect_basic_memory; then
        # Fallback: salva localmente em .aidev/memory/kb/
        _bm_fallback_write "$title" "$content" "$directory"
        return 0
    fi
    mcp__basic-memory__write_note title="$title" content="$content" directory="$directory"
}

# Wrapper seguro para search
bm_search() {
    local query="$1" max="${2:-5}"

    if ! mcp_detect_basic_memory; then
        _bm_fallback_search "$query" "$max"
        return 0
    fi
    mcp__basic-memory__search_notes query="$query"
}

# Wrapper seguro para build_context
bm_build_context() {
    local url="$1"

    if ! mcp_detect_basic_memory; then
        _bm_fallback_context
        return 0
    fi
    mcp__basic-memory__build_context url="$url"
}

# Fallbacks locais
_bm_fallback_write() { ... salva em .aidev/memory/kb/{directory}/{title}.md ... }
_bm_fallback_search() { ... grep -rl em .aidev/memory/kb/ ... }
_bm_fallback_context() { ... cat checkpoint.md + activation_context.md ... }
```

**Nota**: `kb_search_basic_memory()` em `kb-search.sh` **permanece como placeholder** (retorna `[]`). A chamada MCP de busca é responsabilidade do LLM, não do bash script.

**Camada B — Atualizar instruções nos `.md`** (instruções para o LLM):

Os 3 arquivos com chamadas diretas `mcp__basic-memory__*`:

- `agents/knowledge-manager.md` — adicionar verificação de disponibilidade:
  ```markdown
  ## Verificação de Disponibilidade do Basic Memory

  **Antes de chamar `mcp__basic-memory__*`**, verifique no contexto:
  - Se `BASIC_MEMORY_AVAILABLE=true` → use os MCPs normalmente
  - Se não → use Write tool para salvar em `.aidev/memory/kb/[titulo].md`
  - Se não → use Read/Grep para buscar em `.aidev/memory/kb/`
  ```

- `skills/learned-lesson/SKILL.md` — adicionar fallback para Step 4
- `skills/systematic-debugging/SKILL.md` — adicionar fallback para Step 4

**Testes**:
- `test_bm_guard_write_with_bm` — `BASIC_MEMORY_ENABLED=true` chama o wrapper corretamente
- `test_bm_guard_write_fallback` — sem BM, cria arquivo local em `.aidev/memory/kb/`
- `test_bm_guard_search_fallback` — busca local por grep funciona
- `test_bm_guard_no_errors_without_bm` — zero exit codes sem Basic Memory

**Estimativa**: ~75min

---

### Sprint 3: Checkpoint Sync Graceful

**Objetivo**: Implementar `ckpt_sync_to_basic_memory` (Fase 2 pendente) com detecção graceful.

**Localização**: `lib/checkpoint-manager.sh` (raiz do projeto) — **não** em `.aidev/lib/`.

**Tarefas**:

1. **Implementar `ckpt_sync_to_basic_memory()`** em `lib/checkpoint-manager.sh`:
   - Usa `mcp_detect_basic_memory()` do Sprint 1 (source `lib/mcp-detect.sh`)
   - Se disponível → `mcp__basic-memory__write_note` com nota gerada por `ckpt_to_basic_memory_note()`
   - Se indisponível → `_ckpt_sync_local_fallback()` (salva em `.aidev/memory/kb/checkpoints/`)
   - Em caso de falha no MCP → fallback automático (erro silencioso)

2. **Refatorar `ckpt_create()`** (linhas 92-106):
   - Remover lógica inline de Basic Memory
   - Substituir pela chamada `ckpt_sync_to_basic_memory "$ckpt_file"` (com guard)

3. **Integrar no `cmd_restore`**:
   - Se Basic Memory disponível: `aidev restore --search "query"` busca via `mcp__basic-memory__search_notes`
   - Se indisponível: grep nos checkpoints locais (comportamento atual)

4. **Sync global** após testes: `aidev upgrade` para sincronizar `~/.aidev-superpowers/lib/checkpoint-manager.sh`

**Testes existentes que serão desbloqueados** (em `tests/unit/test-basic-memory-integration.sh`):
- `test_ckpt_sync_to_basic_memory_exists` — passa quando função existe
- `test_ckpt_sync_to_basic_memory_callable` — passa quando função é chamável

Novos testes:
- `test_ckpt_sync_with_bm` — com `BASIC_MEMORY_ENABLED=true`, sync funciona
- `test_ckpt_sync_without_bm` — fallback local cria arquivo correto
- `test_ckpt_create_calls_sync` — `ckpt_create()` chama `ckpt_sync_to_basic_memory`

**Estimativa**: ~50min

---

### Sprint 4: Contexto Inteligente na Ativação

**Objetivo**: Enriquecer `context_compressor_generate()` em `lib/context-compressor.sh` para usar
Basic Memory quando disponível.

**Tarefas**:

1. **Enriquecer `context_compressor_generate()`**:
   ```bash
   # Se Basic Memory disponível (mcp_detect_basic_memory):
   # - Busca últimas lessons learned relevantes ao projeto
   # - Busca checkpoints cross-session
   # - Inclui resumo compacto no activation_context.md
   #
   # Se indisponível:
   # - Usa apenas checkpoint.md local + unified.json (comportamento atual)
   ```

2. **Criar seção "Memória Cross-Session"** no `activation_context.md`:
   - Últimas 3 lições aprendidas relevantes
   - Último checkpoint de sessão anterior
   - Padrões de erro recorrentes

3. **Métricas de economia**:
   - Contar tokens do contexto gerado
   - Exibir no dashboard: "Basic Memory: ✓ ativo | ~X tokens economizados"

**Dependência**: Sprint 2 (precisa de `mcp_detect_basic_memory()`).

**Testes**:
- `test_context_with_bm` — contexto enriquecido quando BM disponível
- `test_context_without_bm` — contexto standard funciona normalmente
- `test_context_no_regression` — output sem BM idêntico ao atual

**Estimativa**: ~45min

---

### Sprint 5: Dashboard e Documentação

**Objetivo**: Tornar visível ao usuário o estado da integração e como ativar.

**Nota**: `cmd_status` e `cmd_doctor` **não existem** — precisam ser **criados**, não apenas atualizados.
`validate_conformity()` em `workflow-sync.sh` é a base mais próxima para `cmd_doctor`.

**Tarefas**:

1. **Criar `cmd_status`** (novo subcomando em `bin/aidev`):
   ```
   ▸ Integrações MCP
   ✓ Basic Memory: ativo [claude_code] (42 notas, 12 checkpoints sincronizados)
   ✗ Context7: não configurado
   ✓ Serena: ativo
   ```

2. **Criar `cmd_doctor`** (baseado em `validate_conformity()`):
   - Basic Memory configurado mas não acessível → warning com instrução de fix
   - Basic Memory não configurado → info "Recomendado para economia de tokens"
   - Runtime detectado é exibido para diagnóstico

3. **Criar guia rápido** em `.aidev/QUICKSTART.md` (seção):
   ```markdown
   ## Basic Memory (Opcional — Recomendado)
   Para persistência cross-session e economia de ~60% em tokens:
   1. pip install basic-memory (ou pipx install basic-memory)
   2. Adicione ao seu .mcp.json (ou use `aidev upgrade` para auto-configurar)
   ```

4. **Atualizar `orchestrator.md`**:
   - Mencionar que Basic Memory é opcional mas recomendado
   - Documentar os modos "standard" vs "turbo"

5. **Atualizar `knowledge-manager.md`**:
   - Documentar fallbacks (já coberto no Sprint 2 Camada B)

**Testes**:
- `test_status_shows_bm_available` — exibe quando disponível
- `test_status_shows_bm_unavailable` — exibe quando indisponível
- `test_doctor_suggests_bm` — doctor sugere instalação

**Estimativa**: ~45min

---

## Dependências (atualizado)

- **Pré-Sprint 0 é desbloqueador de tudo** — sem ele, nenhum arquivo novo em `.aidev/lib/` é distribuído
- Sprint 1 depende do Pré-Sprint 0
- Sprint 2 depende do Sprint 1
- Sprint 3 e 4 dependem do Sprint 2
- Sprint 5 pode ser feito em paralelo com Sprint 3 ou 4

```
Pré-Sprint 0 ──→ Sprint 1 ──→ Sprint 2 ──→ Sprint 3
                                    │
                                    └──→ Sprint 4
                                    │
               Sprint 5 (paralelo com 3 ou 4)
```

## Critérios de Aceite

- [ ] **[Pré-Sprint 0]** `install_aidev_lib()` existe e é chamada em `create_base_structure()` e `cmd_upgrade()`
- [ ] **[Pré-Sprint 0]** `aidev self-upgrade` sincroniza `.aidev/lib/` para o global
- [ ] **[Pré-Sprint 0]** `aidev upgrade` distribui `.aidev/lib/*.sh` para os projetos
- [ ] Framework funciona 100% sem Basic Memory instalado (zero erros)
- [ ] Framework ativa automaticamente funcionalidades extras com Basic Memory
- [ ] Nenhuma chamada direta a `mcp__basic-memory__*` em bash sem guard
- [ ] Fallbacks locais cobrem todas as operações críticas
- [ ] Dashboard mostra claramente o estado da integração e o runtime detectado
- [ ] Testes cobrem ambos os modos (com/sem Basic Memory)
- [ ] Economia de tokens é mensurável e reportada
- [ ] `ckpt_sync_to_basic_memory` implementada e testada (Fase 2 concluída)
- [ ] Detecção funciona em todos os runtimes: Claude Code, OpenCode, Gemini CLI, Antigravity (Claude e Gemini)
- [ ] `mcp_detect_basic_memory()` é a função canônica — sem duplicação com `memory_mcp_available()` e `_kb_check_mcp_availability()`
- [ ] `detect_runtime()` unificada (implementação canônica de `activation-snapshot.sh`)
- [ ] 2 testes em `tests/unit/test-basic-memory-integration.sh` passando após Sprint 3

## Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Basic Memory indisponível durante sync | Baixo | Guard functions com fallback local |
| Performance do fallback grep vs busca semântica | Médio | Cache de resultados + índice local |
| Inconsistência entre KB local e Basic Memory | Baixo | Sync unidirecional (local → BM) |
| Overhead de detecção a cada comando | Baixo | Cache de detecção por sessão (`_AIDEV_BM_DETECTED`) |
| Detecção incorreta em runtime desconhecido | Médio | Fallback conservador (assume indisponível) |
| `detect_runtime()` retorna "unknown" | Baixo | `command -v basic-memory` como última camada |

## Prioridade

**ALTA** - Impacta diretamente na economia de tokens e na experiência do usuário.
A detecção graceful é pré-requisito para qualquer expansão futura do ecossistema MCP.

## Dependências

- Sprint 1 é pré-requisito para todos os outros
- Sprint 2 é pré-requisito para Sprint 3 e 4
- Sprint 5 pode ser feito em paralelo com Sprint 3 ou 4

```
Sprint 1 ──→ Sprint 2 ──→ Sprint 3
                  │
                  └──→ Sprint 4
                  │
Sprint 5 (paralelo com 3 ou 4)
```

## Estimativa Total

| Sprint | Original | Revisado | Motivo |
|---|---|---|---|
| Pré-Sprint 0 | — | 30min | **Novo** — pipeline de distribuição (desbloqueador) |
| Sprint 1 | 45min | 60min | Multi-runtime adiciona complexidade |
| Sprint 2 | 60min | 75min | Duas camadas: bash + .md |
| Sprint 3 | 45min | 50min | Localização correta mapeada |
| Sprint 4 | 45min | 45min | Sem mudanças |
| Sprint 5 | 30min | 45min | `cmd_status`/`cmd_doctor` são criação, não atualização |
| **Total** | **225min** | **305min (~5h05)** | |

Cada sprint entrega valor independente e pode ser validado isoladamente.
