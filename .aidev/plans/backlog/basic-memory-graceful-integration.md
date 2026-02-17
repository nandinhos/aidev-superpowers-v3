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

### Impacto na Economia de Tokens

| Cenário | Sem Basic Memory | Com Basic Memory | Economia |
|---------|-----------------|------------------|----------|
| Inicialização de agente | ~1.600 tokens | ~550 tokens | 66% |
| Carga de checkpoint | ~500 tokens | ~200 tokens | 60% |
| Busca de contexto | 0 (inexistente) | ~50 tokens | Capacidade nova |
| Persistência | 1 sessão | Infinitas sessões | Continuidade total |

## Objetivo

Criar um sistema de **detecção e adaptação graceful** que:
1. Detecta automaticamente se o Basic Memory MCP está disponível
2. Ativa funcionalidades extras quando presente (modo "turbo")
3. Funciona perfeitamente sem ele (modo "standard")
4. Nunca gera erros ou desperdício de tokens pela ausência

## Arquitetura Proposta

```
┌─────────────────────────────────────────────────┐
│              aidev init / upgrade                │
│                     │                            │
│              detect_mcp_servers()                │
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
│           em ambos os modos                      │
└─────────────────────────────────────────────────┘
```

## Sprints

### Sprint 1: Detecção Unificada de MCP (lib/mcp-detect.sh)

**Objetivo**: Criar módulo centralizado de detecção de MCPs disponíveis.

**Tarefas**:

1. **Criar `lib/mcp-detect.sh`** com função `mcp_detect_available()`
   - Verifica `.mcp.json` por servers configurados
   - Testa se o comando `basic-memory` existe (`command -v basic-memory`)
   - Testa se `uvx basic-memory` está acessível
   - Exporta variável `BASIC_MEMORY_AVAILABLE=true|false`
   - Exporta `MCP_AVAILABLE_SERVERS` (lista de MCPs detectados)

2. **Função `mcp_detect_basic_memory()`** (específica)
   - Verifica em `.mcp.json` se `basic-memory` está configurado
   - Verifica se o binário existe
   - Retorna 0 (disponível) ou 1 (indisponível)
   - Cache do resultado para evitar re-detecção na mesma sessão

3. **Integrar na inicialização** (`cmd_init`, `cmd_upgrade`, `cmd_status`)
   - Chamar `mcp_detect_available()` no início
   - Exibir no dashboard: "Basic Memory: ✓ ativo" ou "Basic Memory: ✗ (local mode)"

**Testes**:
- `test_mcp_detect_with_basic_memory` - simula .mcp.json com basic-memory
- `test_mcp_detect_without_basic_memory` - simula .mcp.json sem basic-memory
- `test_mcp_detect_cache` - verifica que não re-detecta na mesma sessão

**Estimativa**: ~45min

---

### Sprint 2: Guard Functions (Wrappers Graceful)

**Objetivo**: Criar wrappers que protegem todas as chamadas ao Basic Memory.

**Tarefas**:

1. **Criar `lib/basic-memory-guard.sh`** com wrappers:
   ```bash
   # Wrapper seguro para write_note
   bm_write_note() {
       if [ "$BASIC_MEMORY_AVAILABLE" != "true" ]; then
           # Fallback: salva localmente em .aidev/memory/kb/
           _bm_fallback_write "$@"
           return 0
       fi
       mcp__basic-memory__write_note "$@"
   }

   # Wrapper seguro para search
   bm_search() {
       if [ "$BASIC_MEMORY_AVAILABLE" != "true" ]; then
           # Fallback: grep local em .aidev/memory/kb/
           _bm_fallback_search "$@"
           return 0
       fi
       mcp__basic-memory__search_notes "$@"
   }

   # Wrapper seguro para build_context
   bm_build_context() {
       if [ "$BASIC_MEMORY_AVAILABLE" != "true" ]; then
           # Fallback: lê checkpoint.md local
           _bm_fallback_context "$@"
           return 0
       fi
       mcp__basic-memory__build_context "$@"
   }
   ```

2. **Fallbacks locais inteligentes**:
   - `_bm_fallback_write()` → salva em `.aidev/memory/kb/{title}.md`
   - `_bm_fallback_search()` → `grep -rl` em `.aidev/memory/kb/`
   - `_bm_fallback_context()` → lê `checkpoint.md` + `activation_context.md`

3. **Migrar chamadas diretas** nos agents e skills:
   - `knowledge-manager.md` → usar `bm_write_note` / `bm_search`
   - `learned-lesson/SKILL.md` → usar `bm_write_note`
   - `systematic-debugging/SKILL.md` → usar `bm_write_note`

**Testes**:
- `test_bm_guard_write_with_bm` - escreve via MCP quando disponível
- `test_bm_guard_write_fallback` - escreve localmente quando indisponível
- `test_bm_guard_search_fallback` - busca local funciona
- `test_bm_guard_no_errors_without_bm` - zero erros sem Basic Memory

**Estimativa**: ~60min

---

### Sprint 3: Checkpoint Sync Graceful

**Objetivo**: Implementar `ckpt_sync_to_basic_memory` (Fase 2 pendente) com detecção graceful.

**Tarefas**:

1. **Implementar `ckpt_sync_to_basic_memory()`** em `lib/checkpoint-manager.sh`
   - Usa `bm_write_note()` do guard (Sprint 2)
   - Se Basic Memory indisponível → fallback para `.aidev/memory/kb/checkpoints/`
   - Converte checkpoint JSON → Markdown via `ckpt_to_basic_memory_note()` (já existe)

2. **Ativar sync automático** condicional:
   ```bash
   # Em ckpt_create(), após criar o checkpoint:
   if mcp_detect_basic_memory; then
       ckpt_sync_to_basic_memory "$ckpt_file"
   fi
   # Sem Basic Memory: não faz nada extra (zero overhead)
   ```

3. **Integrar no `cmd_restore`**:
   - Se Basic Memory disponível: `aidev restore --search "query"` busca semanticamente
   - Se indisponível: busca por grep nos checkpoints locais (já funciona)

4. **Atualizar teste existente**:
   - `test_ckpt_sync_to_basic_memory_exists` → deve passar (função existe)
   - Adicionar testes de fallback

**Testes**:
- `test_ckpt_sync_with_bm` - sync funciona com Basic Memory
- `test_ckpt_sync_without_bm` - fallback local funciona
- `test_ckpt_restore_search_with_bm` - busca semântica
- `test_ckpt_restore_search_without_bm` - busca grep local

**Estimativa**: ~45min

---

### Sprint 4: Contexto Inteligente na Ativação

**Objetivo**: Na ativação do modo agente, usar Basic Memory para carregar contexto relevante
com economia máxima de tokens.

**Tarefas**:

1. **Enriquecer `context_compressor_generate()`** em `lib/context-compressor.sh`:
   ```bash
   # Se Basic Memory disponível:
   # - Busca últimas lessons learned relevantes ao projeto
   # - Busca checkpoints cross-session
   # - Inclui resumo compacto no activation_context.md
   #
   # Se indisponível:
   # - Usa apenas checkpoint.md local + unified.json (comportamento atual)
   ```

2. **Criar seção "Memória Cross-Session"** no activation_context.md:
   - Últimas 3 lições aprendidas relevantes
   - Último checkpoint de sessão anterior
   - Padrões de erro recorrentes (do error-recovery.sh)

3. **Métricas de economia**:
   - Contar tokens do contexto gerado
   - Comparar com/sem Basic Memory
   - Exibir no `aidev status`: "Economia estimada: X tokens/sessão"

**Testes**:
- `test_context_with_bm` - contexto enriquecido com Basic Memory
- `test_context_without_bm` - contexto standard funciona normalmente
- `test_context_token_count` - métricas são geradas

**Estimativa**: ~45min

---

### Sprint 5: Dashboard e Documentação

**Objetivo**: Tornar visível ao usuário o estado da integração e como ativar.

**Tarefas**:

1. **Atualizar `cmd_status`** para mostrar:
   ```
   ▸ Integrações MCP
   ✓ Basic Memory: ativo (42 notas, 12 checkpoints sincronizados)
   ✗ Context7: não configurado
   ✓ Serena: ativo
   ```

2. **Atualizar `cmd_doctor`** para validar:
   - Basic Memory configurado mas não acessível → warning com instrução de fix
   - Basic Memory não configurado → info "Recomendado para economia de tokens"

3. **Criar guia rápido** em `.aidev/QUICKSTART.md` (seção):
   ```markdown
   ## Basic Memory (Opcional - Recomendado)
   Para persistência cross-session e economia de ~60% em tokens:
   1. pip install basic-memory (ou pipx install basic-memory)
   2. aidev upgrade (auto-detecta e configura)
   ```

4. **Atualizar agents** para mencionar detecção graceful:
   - `orchestrator.md` → mencionar que Basic Memory é opcional
   - `knowledge-manager.md` → documentar fallbacks

**Testes**:
- `test_status_shows_bm_available` - exibe quando disponível
- `test_status_shows_bm_unavailable` - exibe quando indisponível
- `test_doctor_suggests_bm` - doctor sugere instalação

**Estimativa**: ~30min

---

## Critérios de Aceite

- [ ] Framework funciona 100% sem Basic Memory instalado (zero erros)
- [ ] Framework ativa automaticamente funcionalidades extras com Basic Memory
- [ ] Nenhuma chamada direta a `mcp__basic-memory__*` sem guard
- [ ] Fallbacks locais cobrem todas as operações críticas
- [ ] Dashboard mostra claramente o estado da integração
- [ ] Testes cobrem ambos os modos (com/sem Basic Memory)
- [ ] Economia de tokens é mensurável e reportada
- [ ] `ckpt_sync_to_basic_memory` implementada e testada (Fase 2 concluída)

## Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Basic Memory indisponível durante sync | Baixo | Guard functions com fallback local |
| Performance do fallback grep vs busca semântica | Médio | Cache de resultados + índice local |
| Inconsistência entre KB local e Basic Memory | Baixo | Sync unidirecional (local → BM) |
| Overhead de detecção a cada comando | Baixo | Cache de detecção por sessão |

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

~225min (~3h45) distribuídos em 5 sprints incrementais.
Cada sprint entrega valor independente e pode ser validado isoladamente.
