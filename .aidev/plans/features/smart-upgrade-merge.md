# Smart Upgrade: Merge Inteligente com Protecao de Customizacoes

> **Status:** Planejado
> **Prioridade:** Alta (impacta seguranca de dados do usuario)
> **Sprint:** 5 (v4.0.0)
> **Data criacao:** 2026-02-12
> **Estimativa:** 4-6 tasks

---

## Contexto e Problema

O comando `aidev upgrade` atualmente usa `AIDEV_FORCE=true` (linha 252 de `bin/aidev`), que forca a sobrescrita **total** de todos os arquivos de governanca do projeto:

- **Agentes** (`.aidev/agents/*.md`) - customizacoes de comportamento
- **Skills** (`.aidev/skills/*/SKILL.md`) - workflows personalizados
- **Platform Instructions** (`CLAUDE.md`, `.cursorrules`, etc.) - instrucoes especificas
- **Triggers** (`.aidev/triggers/*.yaml`) - automacoes
- **MCP Config** (`.mcp.json`, `.aidev/mcp/`) - servidores configurados
- **Memory Sync** (`.aidev/mcp/memory-sync.json`) - sincronizacao

### Consequencia
O usuario que personalizou agentes, adicionou instrucoes ao CLAUDE.md, ajustou regras, ou configurou MCP servers customizados **perde tudo** ao rodar `aidev upgrade`. O backup parcial (apenas agents e skills) existe mas nao e restaurado automaticamente e nao cobre todos os arquivos.

### Gatilho
Incidente real: durante testes de comandos, a pasta global `~/.aidev-superpowers/` foi apagada. O sistema deploy-sync foi criado para prevenir isso, mas o `upgrade` continua destrutivo.

---

## Solucao Proposta

### Estrategia: Merge Inteligente + Diff Interativo (com --force)

**Modo padrao (sem flags):** Merge inteligente - so atualiza o que realmente mudou no template, preservando customizacoes do usuario.

**Modo `--force`:** Diff + confirmacao - mostra as diferencas antes de sobrescrever e pede confirmacao por categoria.

---

## Arquitetura

### Novo modulo: `lib/upgrade-merge.sh`

#### Conceito: Template Fingerprint

Cada arquivo instalado pelo aidev tera um "fingerprint" armazenado em `.aidev/state/template-hashes.json`:

```json
{
  "version": "3.10.0",
  "files": {
    ".aidev/agents/orchestrator.md": {
      "template_hash": "abc123...",
      "installed_hash": "abc123...",
      "installed_at": "2026-02-12T01:00:00"
    },
    "CLAUDE.md": {
      "template_hash": "def456...",
      "installed_hash": "def456...",
      "installed_at": "2026-02-12T01:00:00"
    }
  }
}
```

- `template_hash`: Hash do template processado no momento da instalacao
- `installed_hash`: Hash do arquivo no momento que foi escrito

#### Logica de Decisao (3-way)

Para cada arquivo durante o upgrade:

```
1. Gerar novo conteudo do template (versao nova)
2. Ler hash do template antigo (template-hashes.json)
3. Ler hash do arquivo atual no disco

Cenarios:
A) Template NAO mudou → Nao faz nada (nao ha atualizacao)
B) Template mudou + Arquivo NAO foi customizado → Atualiza silenciosamente
C) Template mudou + Arquivo FOI customizado → Merge inteligente ou prompt
D) Arquivo nao existe → Instala normalmente (arquivo novo)
```

**Deteccao de customizacao:**
- `installed_hash == hash_atual_disco` → Arquivo NAO foi customizado
- `installed_hash != hash_atual_disco` → Arquivo FOI customizado pelo usuario

---

## Plano de Implementacao

### Task 1: Criar `lib/upgrade-merge.sh` (Modulo Base)

**Arquivo:** `lib/upgrade-merge.sh`

Funcoes:
- `upgrade_merge_init()` - Carrega/cria template-hashes.json
- `upgrade_merge_compute_hash(file)` - Calcula md5 de um arquivo
- `upgrade_merge_save_hash(file, template_hash, installed_hash)` - Salva no JSON
- `upgrade_merge_load_hash(file)` - Recupera hash salvo
- `upgrade_merge_is_customized(file)` - Verifica se arquivo foi customizado
- `upgrade_merge_classify(file, new_content)` - Classifica cenario (A/B/C/D)

**Dependencia:** `lib/file-ops.sh` (reutilizar `ensure_dir`, `should_write_file`)

### Task 2: Implementar `should_write_file_smart()`

**Arquivo:** `lib/file-ops.sh` (ou `lib/upgrade-merge.sh`)

Nova funcao que substitui `should_write_file` durante o upgrade:

```bash
# Retorna:
#   0 = pode escrever (nao customizado ou template novo)
#   1 = nao escrever (template nao mudou)
#   2 = conflito (ambos mudaram)
should_write_file_smart() {
    local file="$1"
    local new_content="$2"

    # Arquivo nao existe → instalar
    # Template nao mudou → pular
    # Nao customizado → atualizar
    # Customizado → conflito
}
```

### Task 3: Implementar Diff + Confirmacao Interativa (modo --force)

**Arquivo:** `lib/upgrade-merge.sh`

Funcoes:
- `upgrade_merge_show_diff(file, old_content, new_content)` - Exibe diff colorido
- `upgrade_merge_prompt_action(file)` - Pergunta ao usuario:
  - `[K]eep` - Manter versao do usuario
  - `[U]pdate` - Usar versao nova do template
  - `[B]ackup + Update` - Salva .bak e atualiza
  - `[S]kip` - Pular este arquivo
- `upgrade_merge_show_summary(results)` - Resumo final do que foi feito

**Exibicao do diff:**
```
⚠️  CONFLITO: .aidev/agents/orchestrator.md
   Customizado em: 2026-02-10
   Template atualizado: v3.10.0 → v4.0.0

   Diferencas:
   --- Sua versao
   +++ Nova versao
   @@ -15,3 +15,5 @@
   -   Regra antiga
   +   Regra nova adicionada
   +   Outra regra nova

   [K]eep yours  [U]se new  [B]ackup+Update  [S]kip ?
```

### Task 4: Refatorar `cmd_upgrade` para Usar Merge Inteligente

**Arquivo:** `bin/aidev` (funcao `cmd_upgrade`, linha 221)

Mudancas:
1. Remover `AIDEV_FORCE=true` do fluxo padrao
2. Adicionar flag `--force` que ativa o modo interativo com diff
3. Fluxo novo:

```bash
cmd_upgrade() {
    # ... (deteccao de stack/plataforma permanece igual)

    # Carrega estado de hashes
    upgrade_merge_init "$install_path"

    # Backup COMPLETO (nao so agents/skills)
    upgrade_backup_full "$install_path"

    # Modo inteligente (padrao)
    if [ "$AIDEV_FORCE" != "true" ]; then
        upgrade_smart "$install_path"
    else
        # Modo --force: diff + confirmacao
        upgrade_force_interactive "$install_path"
    fi

    # Atualiza hashes apos upgrade
    upgrade_merge_save_state "$install_path"
}
```

### Task 5: Backup Completo

**Arquivo:** `bin/aidev` ou `lib/upgrade-merge.sh`

Expandir backup para incluir:
- `.aidev/agents/` (ja faz)
- `.aidev/skills/` (ja faz)
- `.aidev/rules/` (NOVO)
- `.aidev/triggers/` (NOVO)
- `.aidev/mcp/memory-sync.json` (NOVO)
- `CLAUDE.md` / `.cursorrules` / etc (NOVO)
- `.mcp.json` (NOVO)

### Task 6: Registrar Hashes no `cmd_init`

**Arquivo:** `bin/aidev` (funcao `cmd_init`)

Ao final do `init`, registrar hashes de todos os arquivos instalados:

```bash
# Apos instalar tudo
upgrade_merge_register_all "$install_path"
```

Isso cria o baseline para futuras deteccoes de customizacao.

### Task 7: Testes Unitarios

**Arquivo:** `tests/unit/test-upgrade-merge.sh`

Testes obrigatorios:
1. `compute_hash` retorna hash consistente
2. `is_customized` retorna false para arquivo nao modificado
3. `is_customized` retorna true para arquivo modificado
4. `classify` retorna "skip" quando template nao mudou
5. `classify` retorna "update" quando so template mudou
6. `classify` retorna "conflict" quando ambos mudaram
7. `classify` retorna "new" quando arquivo nao existe
8. Backup completo inclui todos os arquivos
9. Hashes sao salvos corretamente no JSON
10. Hashes sao carregados corretamente do JSON
11. `--force` ativa modo interativo (nao sobrescreve cegamente)
12. Upgrade sem `--force` preserva customizacoes
13. Arquivo novo no template e instalado normalmente
14. Arquivo removido do template nao e deletado do projeto

---

## Arquivos Criticos

| Arquivo | Acao |
|---------|------|
| `lib/upgrade-merge.sh` | CRIAR - Modulo novo |
| `lib/file-ops.sh` | EDITAR - Adicionar `should_write_file_smart()` |
| `bin/aidev` (`cmd_upgrade`) | EDITAR - Refatorar fluxo |
| `bin/aidev` (`cmd_init`) | EDITAR - Registrar hashes apos init |
| `lib/deploy-sync.sh` | EDITAR - Adicionar `lib/upgrade-merge.sh` ao SYNC_FILES |
| `.aidev/state/template-hashes.json` | CRIAR (em runtime) |
| `tests/unit/test-upgrade-merge.sh` | CRIAR - 14+ testes |

---

## Funcoes Existentes Reutilizaveis

| Funcao | Arquivo | Uso |
|--------|---------|-----|
| `should_write_file()` | `lib/file-ops.sh:149` | Base para versao smart |
| `process_template()` | `lib/templates.sh:19` | Gerar conteudo novo do template |
| `ensure_dir()` | `lib/file-ops.sh` | Criar diretorios |
| `print_step/success/warning/error()` | `lib/core.sh` | Output formatado |
| `install_agents/skills/rules()` | `bin/aidev` | Fluxo de instalacao |

---

## Verificacao

1. `aidev init` em projeto limpo → hashes registrados
2. Modificar `.aidev/agents/orchestrator.md` manualmente
3. `aidev upgrade` → orchestrator.md preservado, outros atualizados
4. `aidev upgrade --force` → diff exibido, usuario escolhe acao
5. Rodar `tests/unit/test-upgrade-merge.sh` → 14+ testes passando
6. `aidev upgrade` em projeto sem `template-hashes.json` (legado) → comportamento gracioso (assume tudo como customizado, pede confirmacao)

---

## Notas de Design

1. **Retrocompatibilidade:** Projetos sem `template-hashes.json` devem funcionar. Nesse caso, o upgrade assume que TUDO foi customizado e no modo padrao nao sobrescreve nada (seguro). O usuario pode usar `--force` para ver diffs e decidir.

2. **Separacao clara:** O merge inteligente vive em `lib/upgrade-merge.sh`, nao polui `file-ops.sh` nem `bin/aidev` com logica complexa.

3. **`--force` nao e destrutivo:** Ao contrario do comportamento atual, `--force` passa a ser "mostre-me os diffs e deixe-me decidir", nao "sobrescreva tudo".

4. **Performance:** Hashes md5 sao rapidos. O JSON de hashes e pequeno (~2KB para 30 arquivos).

---

*Plano criado por AI Dev Superpowers v3.10.0*
