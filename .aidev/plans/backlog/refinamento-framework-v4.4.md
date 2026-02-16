# Plano de Refinamento: aidev-superpowers-v3-1

## Contexto

O framework aidev-superpowers evoluiu organicamente ao longo de 6+ sprints, acumulando gaps críticos identificados pelo Claude Code Insights (159 msgs, 30 sessões) e pela análise arquitetural profunda do codebase. Os problemas principais são:

1. **Upgrades arriscados** - backup parcial (só agents/skills), sem checksum, sem dry-run, `self-upgrade` usa `rsync --delete` sem backup
2. **Sem classificação formal de arquivos** - proteção é comportamental (`should_write_file` verifica existência), não declarativa
3. **Sem controle de execução LLM** - regras existem em markdown mas não há enforcement programático
4. **Gaps de teste** - upgrade, self-upgrade, patch, release, version-check sem cobertura
5. **Bugs silenciosos** - `cmd_feature` definido 2x em `bin/aidev`, upgrade não reinstala rules

---

## Arquitetura Atual (Real, não idealizada)

### Fluxo de Execução
```
bin/aidev (3845 linhas, monolítico)
  → lib/loader.sh (carrega módulos com deps)
    → lib/core.sh (VERSION como SSOT, cores, helpers)
    → lib/file-ops.sh (should_write_file - gate de proteção)
    → lib/templates.sh (process_template com {{VAR}})
    → lib/state.sh (unified.json - estado master)
    → lib/cache.sh (activation_cache.json + hash SHA256)
    → lib/sprint-manager.sh (sprint-status.json)
    → lib/checkpoint-manager.sh (snapshots em sprints/checkpoints/)
    → lib/version-check.sh (compara VERSION local vs GitHub)
    → +25 outros módulos
```

### Ciclo de Vida
```
install.sh (git clone) → aidev init (scaffold .aidev/) → aidev upgrade (atualiza templates)
                                                        → aidev self-upgrade (rsync global CLI)
                                                        → aidev release (bump versão)
```

### Classificação Implícita de Arquivos (sem manifesto)
- **Core CLI**: bin/aidev, lib/*.sh, templates/ — gerenciado por self-upgrade
- **Template-generated**: .aidev/agents/*.md, skills/, rules/ — protegido por should_write_file
- **Runtime/state**: .aidev/state/, .cache/ — gitignored
- **Usuário**: .aidev/plans/, memory/kb/ — nunca tocado

---

## Sprint 1: Sistema de Manifesto + Fundação

**Objetivo**: Classificação declarativa de arquivos com políticas por categoria.

### Arquivos a criar

| Arquivo | Descrição | ~Linhas |
|---------|-----------|---------|
| `MANIFEST.json` | Manifesto global com categorias e políticas | ~80 |
| `lib/manifest.sh` | Módulo para consultar manifesto | ~120 |
| `tests/unit/test-manifest.sh` | Testes unitários | ~60 |

### `MANIFEST.json` - Estrutura
```json
{
  "manifest_version": "1.0.0",
  "aidev_version": "4.3.0",
  "categories": {
    "core": { "policy": "never_modify_in_project" },
    "template": { "policy": "overwrite_unless_customized" },
    "config": { "policy": "merge_on_upgrade" },
    "state": { "policy": "never_overwrite" },
    "generated": { "policy": "regenerate_on_demand" },
    "user": { "policy": "never_touch" }
  },
  "files": {
    "bin/aidev": "core",
    "lib/*.sh": "core",
    "templates/**/*.tmpl": "core",
    ".aidev/agents/*.md": "template",
    ".aidev/skills/*/SKILL.md": "template",
    ".aidev/rules/*.md": "template",
    ".aidev/state/*": "state",
    ".aidev/.cache/*": "generated",
    ".aidev/plans/**": "user",
    ".aidev/memory/kb/*.md": "user"
  }
}
```

### `lib/manifest.sh` - Funções
- `manifest_load()` — lê MANIFEST.json via jq
- `manifest_get_policy(filepath)` — retorna política por glob matching
- `manifest_is_protected(filepath)` — true se core/state/user
- `manifest_validate()` — valida estrutura JSON

### Arquivos a modificar
- `lib/loader.sh` — adicionar `manifest` ao mapa de dependências
- `bin/aidev` — carregar manifesto em `cmd_upgrade()` e `cmd_init()`

### Critérios de aceite
- [ ] `manifest_get_policy ".aidev/agents/orchestrator.md"` retorna `overwrite_unless_customized`
- [ ] `manifest_get_policy ".aidev/state/unified.json"` retorna `never_overwrite`
- [ ] `manifest_is_protected "bin/aidev"` retorna 0 (true)
- [ ] `manifest_validate` detecta JSON malformado
- [ ] Suite existente continua passando

### Risco
- Glob matching em bash: usar `[[ $path == $pattern ]]` com extglob

---

## Sprint 2: Segurança de Upgrade (Checksum + Dry-Run + Backup Expandido)

**Objetivo**: Tornar `cmd_upgrade` e `cmd_self_upgrade` seguros com comparação de checksum, preview dry-run e backup completo.

### Arquivos a criar

| Arquivo | Descrição | ~Linhas |
|---------|-----------|---------|
| `lib/upgrade.sh` | Motor de upgrade seguro | ~200 |
| `tests/unit/test-upgrade.sh` | Testes unitários | ~80 |

### `lib/upgrade.sh` - Funções
- `upgrade_compute_checksum(filepath)` — SHA256 (reusar padrão de `lib/cache.sh`)
- `upgrade_compare_with_template(project_file, template_output)` — retorna `identical|modified|missing`
- `upgrade_backup_full(install_path)` — backup de agents/, skills/, rules/, mcp/ (não só agents+skills como atual)
- `upgrade_dry_run(install_path)` — lista mudanças sem aplicar
- `upgrade_should_overwrite(filepath)` — decisão usando manifesto + checksum + force flag:
  ```
  se policy == never_overwrite → skip
  se arquivo não existe → write
  se AIDEV_FORCE → write (com backup)
  se checksum(arquivo) == checksum(template processado) → skip (já atualizado)
  se customizado pelo usuário → skip + warn
  ```
- `upgrade_record_checksums(install_path)` — salva checksums em `.aidev/state/checksums.json`

### Arquivos a modificar

| Arquivo | Mudança |
|---------|---------|
| `lib/file-ops.sh` | Aprimorar `should_write_file()` (linha ~149) com fallback para `upgrade_should_overwrite()` quando manifesto disponível |
| `bin/aidev` `cmd_upgrade()` (linha 244) | Expandir backup para todos os dirs; adicionar check de dry-run; chamar `upgrade_record_checksums` ao final |
| `bin/aidev` `cmd_self_upgrade()` (linha 3091) | Criar backup antes do rsync; adicionar rollback em caso de falha |
| `lib/loader.sh` | Adicionar `upgrade` ao mapa de dependências |

### Critérios de aceite
- [ ] `aidev upgrade --dry-run` mostra mudanças sem modificar nada
- [ ] Backup agora inclui rules/ e mcp/ além de agents/ e skills/
- [ ] Arquivos não modificados pelo usuário são atualizados silenciosamente
- [ ] Arquivos customizados são preservados com aviso
- [ ] `checksums.json` é gerado após cada upgrade
- [ ] `self-upgrade` cria backup antes do rsync
- [ ] Testes passam

### Risco
- Checksums devem ser computados no output processado do template (após substituição de `{{VAR}}`), não no `.tmpl` raw

---

## Sprint 3: Guardrails de Execução LLM

**Objetivo**: Enforcement programático de regras para controlar escopo, limites e auditoria das ações das LLMs.

### Arquivos a criar

| Arquivo | Descrição | ~Linhas |
|---------|-----------|---------|
| `lib/llm-guard.sh` | Motor de validação pré-execução | ~180 |
| `templates/rules/llm-limits.md.tmpl` | Template de limites imutáveis | ~40 |
| `tests/unit/test-llm-guard.sh` | Testes unitários | ~70 |

### `lib/llm-guard.sh` - Funções
- `llm_guard_validate_scope(proposed_files_json)` — rejeita modificações em arquivos `core` ou `state` via manifesto
- `llm_guard_enforce_limits()` — lê limites de `.aidev/rules/llm-limits.md`:
  - `MAX_FILES_PER_CYCLE=10`
  - `MAX_LINES_PER_FILE=200`
  - `PROTECTED_PATHS=("bin/aidev", "lib/*.sh")`
- `llm_guard_log_decision(decision, reasoning, confidence)` — reusar `state_log_confidence()` existente em `lib/state.sh`
- `llm_guard_pre_check(action, target_files)` — gate unificado: escopo + sprint_guard + limites
- `llm_guard_audit(session_id, action, result)` — append em `.aidev/state/audit.log`

### Arquivos a modificar

| Arquivo | Mudança |
|---------|---------|
| `lib/loader.sh` | Adicionar `llm-guard` com deps: core, file-ops, manifest, state |
| `lib/sprint-guard.sh` | Hook no final de `guard_check()` para chamar `llm_guard_pre_check` se disponível |
| `bin/aidev` `cmd_init()` | Instalar `llm-limits.md` a partir do template |

### Critérios de aceite
- [ ] `llm_guard_validate_scope '["bin/aidev"]'` retorna erro
- [ ] `llm_guard_validate_scope '[".aidev/plans/feature.md"]'` retorna sucesso
- [ ] Entradas de auditoria são escritas em `.aidev/state/audit.log`
- [ ] `llm-limits.md` é instalado no `aidev init`
- [ ] Integração com sprint-guard funciona quando módulo carregado
- [ ] Testes passam

### Risco
- Performance: guards só executam quando explicitamente acionados, não em toda operação de arquivo

---

## Sprint 4: Cobertura de Testes + Bugfixes Críticos

**Objetivo**: Cobrir comandos críticos sem teste e corrigir bugs silenciosos.

### Arquivos a criar

| Arquivo | Descrição | ~Linhas |
|---------|-----------|---------|
| `tests/integration/test-upgrade.sh` | Teste integrado de upgrade | ~100 |
| `tests/integration/test-self-upgrade.sh` | Teste integrado de self-upgrade | ~80 |
| `tests/unit/test-version-check.sh` | Teste de comparação semver | ~40 |
| `tests/unit/test-release.sh` | Teste de bump de versão | ~40 |

### Bugs a corrigir em `bin/aidev`

| Bug | Local | Fix |
|-----|-------|-----|
| `cmd_feature` definido 2x | Linhas ~2243 e ~3705 | Remover segunda definição (linha 3705), manter a que usa `lib/plans.sh` |
| `cmd_upgrade` não reinstala rules | Linha ~283 | Adicionar chamada a `install_rules "$install_path"` após install_skills |

### Critérios de aceite
- [ ] `cmd_feature` tem apenas uma definição
- [ ] `aidev upgrade` reinstala rules a partir dos templates
- [ ] Teste de upgrade: backup criado, arquivo customizado preservado, dry-run funciona
- [ ] Teste de self-upgrade: backup criado antes do rsync
- [ ] `version_check_compare "4.1.0" "4.3.0"` retorna `-1`
- [ ] `release_calc_next_version "4.3.0" "patch"` retorna `4.3.1`
- [ ] Total de testes sobe de ~22 para ~35+

### Risco
- Testes de integração precisam de isolamento: usar `mktemp -d` com cleanup via trap

---

## Sprint 5: Versionamento de Templates + Sistema de Migração

**Objetivo**: Rastrear qual versão do template gerou cada arquivo, possibilitando migrações incrementais futuras.

### Arquivos a criar

| Arquivo | Descrição | ~Linhas |
|---------|-----------|---------|
| `lib/migration.sh` | Motor de migração incremental | ~150 |
| `migrations/` (diretório) | Scripts de migração por versão | ~30 cada |
| `tests/unit/test-migration.sh` | Testes unitários | ~50 |

### `lib/migration.sh` - Funções
- `migration_get_project_version(install_path)` — lê versão do projeto de `unified.json`
- `migration_needed(install_path)` — compara versão do projeto vs CLI
- `migration_list_steps(from, to)` — lista scripts em `migrations/` aplicáveis
- `migration_execute(install_path, from, to)` — executa migrações com checkpoint entre cada
- `migration_stamp(install_path)` — grava versão atual no estado do projeto

### `.aidev/MANIFEST.local.json` — Manifesto local do projeto
```json
{
  "project_version": "4.3.0",
  "cli_version_at_init": "4.3.0",
  "last_upgrade": "2026-02-16T...",
  "files": {
    ".aidev/agents/orchestrator.md": {
      "template_version": "4.3.0",
      "checksum": "sha256:...",
      "customized": false
    }
  }
}
```

### Arquivos a modificar

| Arquivo | Mudança |
|---------|---------|
| `bin/aidev` `cmd_init()` | Chamar `migration_stamp` e gerar `MANIFEST.local.json` |
| `bin/aidev` `cmd_upgrade()` | Executar `migration_execute` se `migration_needed`, depois `migration_stamp` |
| `lib/loader.sh` | Adicionar `migration` ao mapa de dependências |

### Critérios de aceite
- [ ] `aidev init` cria `MANIFEST.local.json` com versão atual
- [ ] `aidev upgrade` detecta mismatch e executa migrações
- [ ] Migrações rodam em ordem lexicográfica
- [ ] Rollback funciona se migração falhar (reusar checkpoint existente)
- [ ] Testes passam

---

## Grafo de Dependências

```
Sprint 1 (Manifesto) ────┬──→ Sprint 2 (Upgrade Safety) ──→ Sprint 4 (Testes + Bugfixes)
                         ├──→ Sprint 3 (LLM Guardrails)
                         └──→ Sprint 5 (Migração)
```

Sprint 1 é pré-requisito de todos. Sprints 2 e 3 podem rodar em paralelo. Sprint 4 depende do 2. Sprint 5 depende do 1.

---

## Resumo de Entregáveis

| Sprint | Novos Arquivos | Arquivos Modificados | Novos Testes | ~Linhas |
|--------|---------------|---------------------|-------------|---------|
| 1 | `lib/manifest.sh`, `MANIFEST.json` | `lib/loader.sh`, `bin/aidev` | `test-manifest.sh` | ~260 |
| 2 | `lib/upgrade.sh` | `lib/file-ops.sh`, `bin/aidev` (upgrade+self-upgrade), `lib/loader.sh` | `test-upgrade.sh` | ~280 |
| 3 | `lib/llm-guard.sh`, `templates/rules/llm-limits.md.tmpl` | `lib/loader.sh`, `lib/sprint-guard.sh`, `bin/aidev` | `test-llm-guard.sh` | ~290 |
| 4 | — | `bin/aidev` (fix cmd_feature, add install_rules) | 4 novos arquivos de teste | ~260 |
| 5 | `lib/migration.sh`, `migrations/` | `bin/aidev` (init+upgrade), `lib/loader.sh` | `test-migration.sh` | ~230 |
| **Total** | **5 novos módulos lib** | **~10 arquivos** | **~8 novos arquivos de teste (~115 assertions)** | **~1320** |

---

## Verificação End-to-End

Após todos os sprints:
```bash
# 1. Rodar suite completa
./tests/test-runner.sh

# 2. Testar init em projeto limpo
cd /tmp && mkdir test-project && cd test-project
aidev init --stack generic --language pt

# 3. Verificar manifesto
jq . MANIFEST.json
cat .aidev/MANIFEST.local.json

# 4. Customizar um agent e testar upgrade
echo "# Custom" >> .aidev/agents/orchestrator.md
aidev upgrade --dry-run  # deve mostrar que orchestrator.md está customizado
aidev upgrade             # deve preservar orchestrator.md customizado

# 5. Verificar checksums
cat .aidev/state/checksums.json | jq .

# 6. Verificar llm-guard
cat .aidev/rules/llm-limits.md

# 7. Testar self-upgrade com backup
aidev self-upgrade --dry-run
```

---

## Arquivos Críticos de Referência

| Arquivo | Por quê |
|---------|---------|
| `bin/aidev` (linhas 244, 3091, 2243, 3705) | cmd_upgrade, cmd_self_upgrade, cmd_feature duplicado |
| `lib/file-ops.sh` (linha ~149) | `should_write_file()` — gate de proteção a aprimorar |
| `lib/state.sh` | Padrão a seguir para módulos JSON (jq atômico) |
| `lib/cache.sh` (linha ~24) | `get_aidev_hash()` — padrão de SHA256 a reusar |
| `lib/loader.sh` (linha ~76) | Mapa de dependências de módulos |
| `lib/sprint-guard.sh` | Hook de integração para llm-guard |
| `tests/test-runner.sh` | Framework de testes — todos novos testes seguem este padrão |
