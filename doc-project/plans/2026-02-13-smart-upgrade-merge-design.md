# Smart Upgrade Merge - Design Document

**Data**: 2026-02-13
**Autor**: AI Dev Superpowers v4.1.1
**Status**: Aprovado
**Feature**: 6.1 - Smart Upgrade Merge
**Sprint**: Sprint 6: Auto-Cura & Smart Upgrade

---

## Declaração do Problema

O comando `aidev upgrade` atualmente usa `AIDEV_FORCE=true` internamente, forçando a **sobrescrita total** de todos os arquivos de governança do projeto. Isso inclui:

- **Agentes** (`.aidev/agents/*.md`) - customizações de comportamento
- **Skills** (`.aidev/skills/*/SKILL.md`) - workflows personalizados  
- **Platform Instructions** (`CLAUDE.md`, `.cursorrules`, etc.) - instruções específicas
- **Triggers** (`.aidev/triggers/*.yaml`) - automações
- **MCP Config** (`.mcp.json`, `.aidev/mcp/`) - servidores configurados
- **Regras** (`.aidev/rules/*.md`) - convenções da stack

### Consequência
O usuário que personalizou agentes, adicionou instruções ao CLAUDE.md, ajustou regras, ou configurou MCP servers customizados **perde tudo** ao rodar `aidev upgrade`. O backup parcial (apenas agents e skills) existe mas não é restaurado automaticamente e não cobre todos os arquivos.

### Gatilho
Incidente real: durante testes de comandos, a pasta global `~/.aidev-superpowers/` foi apagada. O sistema deploy-sync foi criado para prevenir isso, mas o `upgrade` continua destrutivo.

---

## Solução Proposta

### Estratégia: Merge Inteligente 3-Way + Diff Interativo

**Modo padrão (sem flags):** Merge inteligente - só atualiza o que realmente mudou no template, preservando customizações do usuário.

**Modo `--force`:** Diff + confirmação - mostra as diferenças antes de sobrescrever e pede confirmação por arquivo.

### Conceito Central: Template Fingerprinting

Cada arquivo instalado pelo aidev terá um "fingerprint" armazenado em `.aidev/state/template-hashes.json`:

```json
{
  "version": "4.1.1",
  "files": {
    ".aidev/agents/orchestrator.md": {
      "template_hash": "abc123...",
      "installed_hash": "abc123...",
      "installed_at": "2026-02-13T10:00:00Z"
    }
  }
}
```

- `template_hash`: Hash do template processado no momento da instalação
- `installed_hash`: Hash do arquivo no momento que foi escrito no disco

---

## Detalhes Técnicos

### Arquitetura de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                    cmd_upgrade()                                │
│                      (bin/aidev)                                │
└────────────────────┬────────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌───────────────┐      ┌──────────────────┐
│ upgrade_smart │      │ upgrade_force_   │
│   (padrão)    │      │   interactive    │
│               │      │   (--force)      │
└───────┬───────┘      └────────┬─────────┘
        │                       │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  lib/upgrade-merge.sh │
        │                       │
        │  • Fingerprinting     │
        │  • Classificação      │
        │  • Backup completo    │
        │  • Diff interativo    │
        └───────────────────────┘
```

### Modelo de Dados

#### 1. Template Hashes (`template-hashes.json`)

```json
{
  "version": "4.1.1",
  "generated_at": "2026-02-13T10:00:00Z",
  "files": {
    ".aidev/agents/orchestrator.md": {
      "template_hash": "d41d8cd98f00b204e9800998ecf8427e",
      "installed_hash": "d41d8cd98f00b204e9800998ecf8427e",
      "installed_at": "2026-02-13T10:00:00Z",
      "size": 12345
    },
    ".aidev/agents/architect.md": {
      "template_hash": "aabbcc...",
      "installed_hash": "aabbcc...",
      "installed_at": "2026-02-13T10:00:00Z",
      "size": 6789
    }
  }
}
```

#### 2. Backup Manifest (`MANIFEST.json`)

```json
{
  "backup_id": "20250213103045",
  "created_at": "2026-02-13T10:30:45Z",
  "version": "4.1.1",
  "files": [
    {
      "path": ".aidev/agents/orchestrator.md",
      "hash": "abc123...",
      "size": 12345
    },
    {
      "path": "CLAUDE.md",
      "hash": "def456...",
      "size": 6789
    }
  ]
}
```

### Lógica de Decisão (4 Cenários)

Para cada arquivo durante o upgrade:

```
┌──────────────────────────────────────────────────────────────┐
│                    Fluxo de Decisão                          │
└────────────────────┬─────────────────────────────────────────┘
                     │
    ┌────────────────┴────────────────┐
    │  Arquivo existe no disco?       │
    └────────┬──────────────┬─────────┘
             │              │
          NÃO│              │SIM
             │              │
             ▼              ▼
    ┌─────────────────┐  ┌─────────────────────────────┐
    │ Cenário D       │  │ Template mudou?             │
    │ NOVO            │  └───────────┬─────────────────┘
    │ Instalar normal │              │
    └─────────────────┘      NÃO│    │SIM
                                │    │
                                ▼    ▼
                       ┌────────────┴────────────┐
                       │ Arquivo foi customizado?│
                       └──────────┬──────────────┘
                                  │
                   NÃO│           │           │SIM
                      │           │           │
                      ▼           │           ▼
             ┌────────────────┐   │   ┌────────────────┐
             │ Cenário B      │   │   │ Cenário C      │
             │ UPDATE         │   │   │ CONFLITO       │
             │ Atualiza       │   │   │ Prompt usuário │
             │ silenciosamente│   │   │ (keep/update/  │
             └────────────────┘   │   │ backup/skip)   │
                                  │   └────────────────┘
                                  │
                         ┌────────▼────────┐
                         │ Cenário A       │
                         │ SKIP            │
                         │ Nada a fazer    │
                         └─────────────────┘
```

**Detecção de customização:**
- `installed_hash == hash_atual_disco` → Arquivo NÃO foi customizado
- `installed_hash != hash_atual_disco` → Arquivo FOI customizado pelo usuário

### API/Interface

#### Funções Públicas (`lib/upgrade-merge.sh`)

```bash
# Inicialização
upgrade_merge_init(install_path) -> void
  # Carrega ou cria template-hashes.json

# Operações de Hash
upgrade_merge_compute_hash(file) -> hash:string
upgrade_merge_save_hash(file, template_hash, installed_hash) -> void
upgrade_merge_load_hash(file) -> json_object
upgrade_merge_register_all(install_path) -> void

# Detecção e Classificação
upgrade_merge_is_customized(file) -> boolean
upgrade_merge_classify(file, new_content) -> string
  # Retorna: "skip" | "update" | "conflict" | "new"

# Ações de Upgrade
upgrade_smart(install_path) -> results:array
upgrade_force_interactive(install_path) -> results:array

# Interatividade
upgrade_merge_show_diff(file, old_content, new_content) -> void
upgrade_merge_prompt_action(file) -> action:string
  # Retorna: "keep" | "update" | "backup" | "skip"
upgrade_merge_show_summary(results) -> void

# Backup
upgrade_backup_full(install_path) -> backup_dir:string
upgrade_backup_create_manifest(backup_dir) -> void
```

#### Fluxo de Upgrade Refatorado (`cmd_upgrade`)

```bash
cmd_upgrade() {
    local install_path="$1"
    local force_flag="${2:-false}"
    
    # 1. Carrega estado de hashes
    upgrade_merge_init "$install_path"
    
    # 2. Backup COMPLETO
    local backup_dir=$(upgrade_backup_full "$install_path")
    
    # 3. Executa upgrade inteligente
    if [ "$force_flag" != "true" ]; then
        # Modo inteligente (padrão)
        upgrade_smart "$install_path"
    else
        # Modo --force: diff + confirmação
        upgrade_force_interactive "$install_path"
    fi
    
    # 4. Atualiza hashes após upgrade
    upgrade_merge_save_state "$install_path"
    
    # 5. Resumo final
    print_success "Upgrade concluído!"
    print_info "Backup salvo em: $backup_dir"
}
```

### Stack e Bibliotecas

| Componente | Tecnologia | Justificativa |
|------------|------------|---------------|
| Hashing | `md5sum` / `md5` | Disponível em todos Unix, rápido |
| JSON | `jq` (fallback: bash puro) | Parsing JSON confiável |
| Diff | `diff` / `git diff` | Padrão Unix, colorido |
| Backup | `cp -r` / `tar` | Simples, confiável |

---

## Backup Completo

### Estrutura do Backup

```
.aidev/backups/20250213103045/
├── agents/                     # Comportamento do orquestrador
│   ├── orchestrator.md
│   ├── architect.md
│   └── ...
├── skills/                     # Workflows customizados
│   └── brainstorming/
│       └── SKILL.md
├── rules/                      # Regras da stack (NOVO)
│   └── generic.md
├── triggers/                   # Automações YAML (NOVO)
│   └── on-start.yaml
├── mcp/                        # Configurações MCP (NOVO)
│   └── memory-sync.json
├── platform-instructions/      # Instruções de LLM (NOVO)
│   ├── CLAUDE.md
│   ├── .cursorrules
│   └── cline.md
├── mcp-config/                 # Configuração MCP servers (NOVO)
│   └── .mcp.json
└── MANIFEST.json               # Índice do backup (NOVO)
```

### Escopo do Backup vs Backup Atual

| Categoria | Backup Atual | Backup Completo | Status |
|-----------|--------------|-----------------|--------|
| `agents/` | ✅ | ✅ | Mantido |
| `skills/` | ✅ | ✅ | Mantido |
| `rules/` | ❌ | ✅ | **NOVO** |
| `triggers/` | ❌ | ✅ | **NOVO** |
| `mcp/` | ❌ | ✅ | **NOVO** |
| `CLAUDE.md` | ❌ | ✅ | **NOVO** |
| `.cursorrules` | ❌ | ✅ | **NOVO** |
| `.mcp.json` | ❌ | ✅ | **NOVO** |
| `state/` | ❌ | ❌ | Excluído (reconstruível) |

---

## Alternativas Consideradas

### Alternativa 1: Git-based Merge
**Descrição:** Usar git para rastrear mudanças e fazer merge automático.

**Pros:**
- Merge 3-way nativo
- Histórico completo
- Familiar para devs

**Contras:**
- Adiciona dependência do git
- Complexidade desnecessária
- Overkill para arquivos de template

**Decisão:** ❌ Rejeitada - muito complexa para o problema.

### Alternativa 2: Não Fazer Nada (Status Quo)
**Descrição:** Manter comportamento atual de sobrescrita total.

**Pros:**
- Zero esforço de implementação
- Zero código adicional

**Contras:**
- Usuários perdem customizações
- Experiência ruim
- Risco de dados

**Decisão:** ❌ Rejeitada - inaceitável perder dados do usuário.

### Alternativa 3: Merge Inteligente com Fingerprinting (Escolhida)
**Descrição:** Sistema de hashes para detectar customizações e merge seletivo.

**Pros:**
- Simples e eficaz
- Sem dependências extras
- Retrocompatível
- Dá controle ao usuário

**Contras:**
- Requer manutenção do JSON de hashes
- Não detecta mudanças fora do aidev

**Decisão:** ✅ **Aprovada** - melhor custo/benefício.

---

## Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Corrupção do `template-hashes.json` | Baixa | Alto | Backup automático do arquivo JSON antes de modificar |
| Projetos legados sem hashes | Alta | Médio | Comportamento graceful - assume tudo customizado |
| Performance em projetos grandes | Baixa | Médio | Hashing é O(n) e rápido; cache de hashes |
| Usuário confundido com prompts | Média | Baixo | Documentação clara; modo `--force` opcional |
| Falso positivo de customização | Média | Baixo | Diff sempre mostrado no modo `--force` |
| Falha de I/O durante backup | Baixa | Alto | Verificação de espaço em disco antes de copiar |

---

## Próximos Passos

1. [x] **Brainstorming** - Completado (Step 1-4 aprovados)
2. [ ] **Criar Plano de Implementação** - Skill: `writing-plans`
   - Task 1: Módulo `lib/upgrade-merge.sh` base
   - Task 2: Função `should_write_file_smart()`
   - Task 3: Diff + Confirmação interativa
   - Task 4: Refatorar `cmd_upgrade`
   - Task 5: Backup completo expandido
   - Task 6: Registrar hashes no `cmd_init`
   - Task 7: Testes unitários (14+)
3. [ ] **Implementação com TDD** - Skill: `test-driven-development`
4. [ ] **Revisão de Segurança** - Agent: `security-guardian`
5. [ ] **Code Review** - Agent: `code-reviewer`

---

## Referências

- **Especificação Original:** `.aidev/plans/features/smart-upgrade-merge.md`
- **Arquivos Afetados:**
  - `lib/upgrade-merge.sh` (NOVO)
  - `lib/file-ops.sh` (EDITAR)
  - `bin/aidev` (EDITAR - `cmd_upgrade`, `cmd_init`)
  - `lib/deploy-sync.sh` (EDITAR)
  - `tests/unit/test-upgrade-merge.sh` (NOVO)
- **Funções Reutilizáveis:**
  - `should_write_file()` - `lib/file-ops.sh:149`
  - `process_template()` - `lib/templates.sh:19`
  - `ensure_dir()` - `lib/file-ops.sh`
  - `print_step/success/warning/error()` - `lib/core.sh`

---

*Documento criado seguindo AI Dev Superpowers v4.1.1 - Brainstorming Skill*
