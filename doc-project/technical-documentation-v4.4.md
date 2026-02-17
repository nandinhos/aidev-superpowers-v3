# AI Dev Superpowers v4.4.0 - Documentacao Tecnica Completa

> Documento tecnico de referencia com arquitetura, fluxos detalhados e diagramas.
> Gerado em: 2026-02-16

---

## Sumario

1. [Visao Geral da Arquitetura](#1-visao-geral-da-arquitetura)
2. [Mapa de Modulos (37 libs)](#2-mapa-de-modulos)
3. [Grafo de Dependencias](#3-grafo-de-dependencias)
4. [Fluxo: aidev init](#4-fluxo-aidev-init)
5. [Fluxo: aidev upgrade](#5-fluxo-aidev-upgrade)
6. [Fluxo: aidev release](#6-fluxo-aidev-release)
7. [Fluxo: aidev self-upgrade](#7-fluxo-aidev-self-upgrade)
8. [Fluxo: aidev agent (Orquestracao)](#8-fluxo-aidev-agent)
9. [Sistema de Estado (unified.json)](#9-sistema-de-estado)
10. [Sistema de Manifesto (MANIFEST.json)](#10-sistema-de-manifesto)
11. [LLM Guard (Guardrails)](#11-llm-guard)
12. [Deploy Sync (Local-Global)](#12-deploy-sync)
13. [Matriz de Protecao de Arquivos](#13-matriz-de-protecao)
14. [Analise de Gargalos e Melhorias](#14-gargalos-e-melhorias)

---

## 1. Visao Geral da Arquitetura

### Topologia do Sistema

```mermaid
graph TB
    subgraph GLOBAL["Instalacao Global (~/.aidev-superpowers/)"]
        GBIN["bin/aidev"]
        GLIB["lib/*.sh (37 modulos)"]
        GTMPL["templates/**/*.tmpl"]
        GVER["VERSION (SSOT)"]
        GMANIFEST["MANIFEST.json"]
    end

    subgraph PROJECT["Projeto do Usuario (.aidev/)"]
        PAGENTS["agents/*.md (12)"]
        PSKILLS["skills/*/SKILL.md (8)"]
        PRULES["rules/*.md (2)"]
        PSTATE["state/unified.json"]
        PMLOCAL["MANIFEST.local.json"]
        PCACHE[".cache/checksums.json"]
        PPLANS["plans/{backlog,features,current,history,archive}/"]
        PAUDIT["state/audit.log"]
    end

    subgraph SYMLINK["PATH do usuario"]
        BIN["~/.local/bin/aidev"]
    end

    BIN -->|symlink| GBIN
    GBIN -->|resolve AIDEV_ROOT_DIR| GLIB
    GLIB -->|source loader.sh| GBIN
    GTMPL -->|instala via init/upgrade| PAGENTS & PSKILLS & PRULES
    GMANIFEST -->|classifica| PAGENTS & PSTATE & PPLANS
    GVER -->|AIDEV_VERSION| GLIB
    PMLOCAL -->|rastreia versao| PSTATE
end
```

### Cadeia de Resolucao de Versao

```
~/.local/bin/aidev (symlink)
  -> ~/.aidev-superpowers/bin/aidev (real)
    -> AIDEV_ROOT_DIR = ~/.aidev-superpowers/
      -> lib/loader.sh -> lib/core.sh
        -> cat $AIDEV_ROOT_DIR/VERSION -> AIDEV_VERSION (readonly)
```

### Dispatcher Principal (bin/aidev main())

```mermaid
graph LR
    MAIN["main()"] --> INIT["init"]
    MAIN --> STATUS["status"]
    MAIN --> UPGRADE["upgrade"]
    MAIN --> AGENT["agent"]
    MAIN --> RELEASE["release"]
    MAIN --> SELFUP["self-upgrade"]
    MAIN --> DOCTOR["doctor"]
    MAIN --> SYSTEM["system"]
    MAIN --> FEATURE["feature/new-feature"]
    MAIN --> GUARD["guard"]
    MAIN --> LESSONS["lessons"]
    MAIN --> OTHER["+ 25 outros comandos"]
```

**Total: 44 subcomandos** em 3.932 linhas no bin/aidev.

---

## 2. Mapa de Modulos

| Modulo | Arquivo | Linhas | Proposito |
|--------|---------|--------|-----------|
| **core** | lib/core.sh | ~200 | Output, cores, contadores, AIDEV_VERSION |
| **loader** | lib/loader.sh | ~200 | Carga de modulos com dependencias |
| **cli** | lib/cli.sh | ~300 | Parsing de argumentos, interface CLI |
| **i18n** | lib/i18n.sh | ~150 | Internacionalizacao pt-BR/en |
| **file-ops** | lib/file-ops.sh | ~200 | Primitivas de arquivo/diretorio |
| **detection** | lib/detection.sh | ~575 | Auto-deteccao de stack, plataforma, maturidade |
| **templates** | lib/templates.sh | ~200 | Processamento de templates com substituicao |
| **state** | lib/state.sh | ~650 | Estado unificado ACID-like, checkpoints, rollback |
| **orchestration** | lib/orchestration.sh | ~728 | Maquina de estados de skills, protocolo de agentes |
| **manifest** | lib/manifest.sh | ~190 | Classificacao declarativa de arquivos (6 categorias) |
| **upgrade** | lib/upgrade.sh | ~200 | Motor de upgrade seguro com checksums |
| **migration** | lib/migration.sh | ~140 | Migracao incremental entre versoes |
| **llm-guard** | lib/llm-guard.sh | ~163 | Gate de validacao pre-execucao LLM |
| **release** | lib/release.sh | ~250 | Bump automatizado de versao |
| **deploy-sync** | lib/deploy-sync.sh | ~373 | Sincronizacao local-global |
| **sprint-guard** | lib/sprint-guard.sh | ~200 | Score de alinhamento anti-drift |
| **sprint-manager** | lib/sprint-manager.sh | ~200 | Gestao de sprints e estado |
| **mcp** | lib/mcp.sh | ~536 | Configuracao MCP para ferramentas AI |
| **mcp-bridge** | lib/mcp-bridge.sh | ~100 | Abstracao MCP multi-ecosistema |
| **memory** | lib/memory.sh | ~511 | Integracao basic-memory MCP |
| **lessons** | lib/lessons.sh | ~300 | Licoes aprendidas e KB |
| **kb** | lib/kb.sh | ~200 | Knowledge base indexacao |
| **cache** | lib/cache.sh | ~200 | Cache de ativacao do agente |
| **plans** | lib/plans.sh | ~200 | Roadmaps, sprints, features (SGAITI) |
| **metrics** | lib/metrics.sh | ~200 | Telemetria e observabilidade |
| **triggers** | lib/triggers.sh | ~200 | Engine de deteccao e triggers |
| **config-merger** | lib/config-merger.sh | ~200 | Hierarquia CLI > projeto > defaults |
| **yaml-parser** | lib/yaml-parser.sh | ~150 | Parser YAML minimal |
| **validation** | lib/validation.sh | ~200 | Validacao de pre-requisitos |
| **version-check** | lib/version-check.sh | ~200 | Comparacao de versoes e alertas |
| **error-recovery** | lib/error-recovery.sh | ~200 | Sugestoes automaticas de correcao |
| **system** | lib/system.sh | ~200 | Deploy, sync, gestao global |
| **context-monitor** | lib/context-monitor.sh | ~200 | Monitor de janela de contexto LLM |
| **context-compressor** | lib/context-compressor.sh | ~200 | Sumario ultra-comprimido de contexto |
| **context-git** | lib/context-git.sh | ~200 | Micro-logs por acao para git sync |
| **checkpoint-manager** | lib/checkpoint-manager.sh | ~200 | Checkpoints automaticos de contexto |
| **fallback-generator** | lib/fallback-generator.sh | ~200 | Artefatos fallback para LLMs sem MCP |

---

## 3. Grafo de Dependencias

```mermaid
graph TD
    CORE["core"] --> FOPS["file-ops"]
    CORE --> DET["detection"]
    CORE --> CLI["cli"]
    CORE --> I18N["i18n"]
    CORE --> MEM["memory"]
    CORE --> SPMAN["sprint-manager"]
    CORE --> REL["release"]
    CORE --> MAN["manifest"]

    FOPS --> TMPL["templates"]
    FOPS --> STATE["state"]
    FOPS --> ORCH["orchestration"]
    FOPS --> VAL["validation"]
    FOPS --> SYS["system"]
    FOPS --> MCP["mcp"]

    DET --> STATE
    DET --> ORCH
    DET --> VAL
    DET --> MCP

    CORE --> YAML["yaml-parser"]
    YAML --> CFGM["config-merger"]

    MAN --> UPG["upgrade"]
    MAN --> LLMG["llm-guard"]

    FOPS --> LLMG
    STATE --> LLMG
    STATE --> MIG["migration"]

    style CORE fill:#e1f5fe
    style STATE fill:#fff3e0
    style MAN fill:#e8f5e9
    style LLMG fill:#fce4ec
    style ORCH fill:#f3e5f5
```

### Modulos sem entry no dependency map (fallback para core apenas)

`lessons`, `kb`, `triggers`, `error-recovery`, `version-check`, `context-compressor`,
`deploy-sync`, `sprint-manager`, `cache`, `checkpoint-manager`, `context-git`,
`context-monitor`, `fallback-generator`, `metrics`, `plans`, `mcp-bridge`

---

## 4. Fluxo: aidev init

```mermaid
flowchart TD
    A([aidev init]) --> B[parse_args]
    B --> C{Interativo?}
    C -->|sim| D[Selecao de idioma]
    C -->|nao| E
    D --> E[detect_stack + detect_platform]
    E --> F[detect_maturity + detect_style]
    F --> G{greenfield sem PRD?}
    G -->|sim| H[Aviso: criar PRD.md]
    G -->|nao| I
    H --> I[create_base_structure]
    I --> J[install_agents]
    J --> K[install_skills]
    K --> L[install_rules]
    L --> M[install_llm_limits]
    M --> N{CLI_NO_MCP?}
    N -->|nao| O[setup_secrets + configure_mcp]
    N -->|sim| P
    O --> P[install_platform_instructions]
    P --> Q[install_memory_sync + install_triggers]
    Q --> R[install_plans]
    R --> S[setup_gitignore]
    S --> T[set_state_value x8]
    T --> U[migration_stamp]
    U --> V([Sucesso: print_summary])

    style A fill:#4caf50,color:#fff
    style V fill:#4caf50,color:#fff
```

### Estrutura criada pelo init

```
projeto/
├── .aidev/
│   ├── agents/           # 12 agentes .md
│   ├── skills/           # 8 skills com SKILL.md
│   │   ├── brainstorming/
│   │   ├── code-review/
│   │   ├── learned-lesson/
│   │   ├── meta-planning/
│   │   ├── release-management/
│   │   ├── systematic-debugging/
│   │   ├── test-driven-development/
│   │   └── writing-plans/
│   ├── rules/            # generic.md + llm-limits.md
│   ├── state/            # unified.json (runtime)
│   ├── plans/            # backlog/ features/ current/ history/ archive/
│   ├── memory/kb/        # Knowledge base
│   ├── mcp/              # MCP configs
│   ├── triggers/         # Triggers YAML
│   ├── backups/          # Backups de upgrade
│   ├── .cache/           # Cache de ativacao
│   ├── AI_INSTRUCTIONS.md
│   ├── QUICKSTART.md
│   └── MANIFEST.local.json  # Versao do projeto
├── CLAUDE.md             # (ou .cursorrules para Cursor)
└── .gitignore            # Atualizado com exclusoes
```

---

## 5. Fluxo: aidev upgrade

```mermaid
flowchart TD
    A([aidev upgrade]) --> B[parse_args]
    B --> C{.aidev/ existe?}
    C -->|nao| ERR([Erro: projeto nao inicializado])
    C -->|sim| D[detect_stack + detect_platform]
    D --> E[manifest_load]
    E --> F{DRY_RUN?}
    F -->|sim| DR([upgrade_dry_run: preview sem modificar])
    F -->|nao| G[upgrade_backup_full]

    G --> H["install_agents\n(com protecao de manifesto)"]
    H --> I{Para cada arquivo:}
    I --> J[upgrade_should_overwrite?]
    J --> K{Politica?}
    K -->|never_overwrite/touch/core| SKIP[Preservar arquivo]
    K -->|arquivo ausente| WRITE[Escrever arquivo]
    K -->|FORCE=true| WRITE
    K -->|overwrite_unless_customized| L{Customizado?}
    L -->|nao - identico| WRITE
    L -->|sim - modificado| SKIP

    WRITE --> M
    SKIP --> M
    M[install_skills + install_rules + install_llm_limits]
    M --> N[install_platform + memory_sync + triggers]
    N --> O[upgrade_plans_structure]
    O --> P[configure_mcp]
    P --> Q[upgrade_record_checksums]
    Q --> R{migration_needed?}
    R -->|sim| S["migration_execute\n(scripts de migrations/)"]
    S --> T[migration_stamp]
    R -->|nao| T
    T --> U([Sucesso + path do backup])

    style A fill:#ff9800,color:#fff
    style U fill:#4caf50,color:#fff
    style SKIP fill:#fff3e0
    style WRITE fill:#e8f5e9
```

### Arvore de Decisao do upgrade_should_overwrite

```mermaid
flowchart TD
    A["upgrade_should_overwrite(arquivo)"] --> B{Manifesto carregado?}
    B -->|sim| C[manifest_get_policy]
    B -->|nao| D{Arquivo existe?}
    C --> E{Politica?}
    E -->|never_overwrite| SKIP([PRESERVAR])
    E -->|never_touch| SKIP
    E -->|never_modify_in_project| SKIP
    E -->|outra| D
    D -->|nao existe| WRITE([ESCREVER])
    D -->|existe| F{FORCE=true?}
    F -->|sim| WRITE
    F -->|nao| G{overwrite_unless_customized?}
    G -->|sim| H[Comparar com template]
    H -->|identico| WRITE
    H -->|customizado| SKIP
    G -->|nao| SKIP

    style SKIP fill:#ffcdd2
    style WRITE fill:#c8e6c9
```

---

## 6. Fluxo: aidev release

```mermaid
flowchart TD
    A([aidev release tipo]) --> B{Tipo especificado?}
    B -->|sim| C["bump = major|minor|patch"]
    B -->|nao| D["bump = patch (default)"]
    C & D --> E[load release + state + orchestration]
    E --> F[release_get_current_version]
    F --> G[release_calc_next_version]
    G --> H{DRY_RUN?}
    H -->|sim| DR([Preview dos arquivos afetados])
    H -->|nao| I[release_bump_version]

    I --> J["1. VERSION (SSOT)"]
    J --> K["2. CHANGELOG.md (header)"]
    K --> L["3. README.md (badges)"]
    L --> M["4. test-core.sh (asserts)"]
    M --> N[release_discover_version_points]
    N --> O[release_rebuild_cache]

    O --> P[state: active_intent=release]
    P --> Q[state_activate_skill release-management]
    Q --> R[Instrucoes para AI]

    R --> S[deploy_sync_after_release]
    S --> T["deploy_sync_to_global\n(37 arquivos + templates/ + migrations/)"]
    T --> U([Sucesso: release + global sincronizado])

    style A fill:#9c27b0,color:#fff
    style U fill:#4caf50,color:#fff
```

### Arquivos atualizados pelo release_bump_version

| Arquivo | O que muda |
|---------|-----------|
| `VERSION` | SSOT - novo numero de versao |
| `CHANGELOG.md` | Insere header `## [X.Y.Z] - YYYY-MM-DD` |
| `README.md` | Atualiza badge `version-OLD-blue` -> `version-NEW-blue` |
| `tests/unit/test-core.sh` | Atualiza asserts de versao |

---

## 7. Fluxo: aidev self-upgrade

```mermaid
flowchart TD
    A([aidev self-upgrade]) --> B[Resolver path global via symlink]
    B --> C[Ler VERSION global atual]
    C --> D[Encontrar source_dir]
    D --> E{source encontrado?}
    E -->|nao| ERR([Erro: clone o repositorio])
    E -->|sim| F{Versoes iguais e sem FORCE?}
    F -->|sim| OK([Ja esta na versao mais recente])
    F -->|nao| G{DRY_RUN?}
    G -->|sim| DR([Preview])
    G -->|nao| H["Backup: cp -r global -> .bak.TIMESTAMP"]

    H --> I["rsync bin/"]
    I -->|falha| RB([ROLLBACK + exit 1])
    I -->|ok| J["rsync lib/"]
    J -->|falha| RB
    J -->|ok| K["rsync templates/"]
    K -->|falha| RB
    K -->|ok| L["rsync tests/ (silent)"]
    L --> M["cp VERSION CHANGELOG README MANIFEST.json install.sh"]
    M --> N["Verificar: aidev --version"]
    N --> O([Sucesso + path do backup])

    style A fill:#f44336,color:#fff
    style RB fill:#ffcdd2
    style O fill:#4caf50,color:#fff
```

### Prioridade de busca do source_dir

1. `./lib/core.sh && ./bin/aidev` (diretorio atual)
2. `$AIDEV_ROOT_DIR/lib/core.sh` (diferente do global)
3. `~/projects/aidev-superpowers-v3-1`
4. `~/projects/aidev-superpowers-v3`
5. `~/aidev-superpowers`

---

## 8. Fluxo: aidev agent

```mermaid
flowchart TD
    A([aidev agent]) --> B[parse_args]
    B --> C{--full flag?}
    C -->|nao| D["cmd_agent_lite\n(context_compressor_generate)"]
    D --> E([Output: activation_context.md])

    C -->|sim| F[deploy_sync_check_on_init]
    F --> G[sprint_sync_to_unified]
    G --> H[validate_cache_freshness]
    H --> I{Cache valido?}
    I -->|sim| J[get_cached_activation]
    I -->|nao| K[Listar agents/ e skills/]
    J & K --> L[Ler session context do unified.json]
    L --> M[Ler sprint context]
    M --> N["Output: Prompt completo de ativacao\n(TDD, workflows, agentes, skills)"]
    N --> O([Agent ativado])

    style A fill:#2196f3,color:#fff
    style E fill:#e3f2fd
    style O fill:#e3f2fd
```

### Motor de Orquestracao

```mermaid
flowchart LR
    subgraph CLASSIFY["Classificacao de Intent"]
        CI["orchestrator_classify_intent()"]
        CI --> FR["feature_request"]
        CI --> BF["bug_fix"]
        CI --> RF["refactor"]
        CI --> AN["analysis"]
        CI --> TE["testing"]
        CI --> DP["deployment"]
        CI --> SR["security_review"]
    end

    subgraph AGENTS["Selecao de Agentes"]
        FR --> A1["architect, backend,\nfrontend, code-reviewer, qa"]
        BF --> A2["qa, backend,\nsecurity-guardian"]
        RF --> A3["legacy-analyzer,\narchitect, code-reviewer, qa"]
        TE --> A4["qa, backend"]
        DP --> A5["devops,\nsecurity-guardian"]
    end

    subgraph SKILLS["Selecao de Skill"]
        FR --> S1["brainstorming"]
        BF --> S2["systematic-debugging"]
        RF --> S3["writing-plans"]
        TE --> S4["test-driven-development"]
    end
```

### Protocolo de Handoff entre Agentes

```mermaid
sequenceDiagram
    participant O as Orchestrator
    participant A as Agent A
    participant B as Agent B
    participant S as State (unified.json)

    O->>S: agent_activate(A, task)
    S-->>A: status: active
    A->>A: Executa tarefa
    A->>S: agent_handoff(A, B, next_task, artifact)
    S-->>S: A.status = completed
    S-->>S: handoff_queue += {A->B}
    S-->>S: active_agent = B
    O->>S: agent_process_handoff()
    S-->>B: activate(B, next_task)
    B->>B: Executa proxima tarefa
```

---

## 9. Sistema de Estado

### Schema do unified.json

```mermaid
erDiagram
    UNIFIED_STATE {
        string version "3.2.0"
    }
    SESSION {
        string id "uuid"
        string started_at "ISO-8601"
        string last_activity "ISO-8601"
        string project_name ""
        string stack "generic|node|python|laravel"
        string maturity "greenfield|brownfield"
    }
    CHECKPOINT {
        string id "cp-TIMESTAMP-RANDOM"
        string description ""
        string timestamp "ISO-8601"
        json state_snapshot "snapshot completo"
    }
    ARTIFACT {
        string path ""
        string type ""
        string source "skill|agent"
        string created_at ""
    }
    HANDOFF {
        string from "agent_name"
        string to "agent_name"
        string task ""
        string artifact ""
        boolean processed "false"
    }
    CONFIDENCE {
        string decision ""
        float score "0.0-1.0"
        string level "low|medium|high"
        string timestamp ""
    }

    UNIFIED_STATE ||--|| SESSION : session
    UNIFIED_STATE ||--o{ CHECKPOINT : rollback_stack
    UNIFIED_STATE ||--o{ ARTIFACT : artifacts
    UNIFIED_STATE ||--o{ HANDOFF : agent_queue
    UNIFIED_STATE ||--o{ CONFIDENCE : confidence_log
```

### Ciclo de Vida do Estado

```mermaid
stateDiagram-v2
    [*] --> Idle: state_init()
    Idle --> SkillActive: state_activate_skill()
    SkillActive --> Checkpoint: state_checkpoint()
    Checkpoint --> SkillActive: continua execucao
    SkillActive --> SkillComplete: skill_complete()
    SkillComplete --> Idle: active_skill = null
    SkillActive --> Rollback: state_rollback()
    Rollback --> Idle: restaura snapshot
    Checkpoint --> Rollback: falha detectada

    state SkillActive {
        [*] --> AgentA: agent_activate()
        AgentA --> AgentB: agent_handoff()
        AgentB --> AgentC: agent_handoff()
    }
```

---

## 10. Sistema de Manifesto

### 6 Categorias

```mermaid
pie title Distribuicao de Categorias no MANIFEST.json
    "core (never_modify)" : 6
    "template (overwrite_unless_custom)" : 8
    "config (merge_on_upgrade)" : 2
    "state (never_overwrite)" : 1
    "generated (regenerate)" : 1
    "user (never_touch)" : 4
```

| Categoria | Politica | Exemplos | Quem modifica |
|-----------|----------|----------|---------------|
| **core** | `never_modify_in_project` | bin/aidev, lib/*.sh, templates/, VERSION | Apenas self-upgrade |
| **template** | `overwrite_unless_customized` | .aidev/agents/*.md, skills/*, rules/* | Upgrade (se nao customizado) |
| **config** | `merge_on_upgrade` | CLAUDE.md, .aidev/mcp/*.json | Upgrade (merge inteligente) |
| **state** | `never_overwrite` | .aidev/state/* | Runtime (state.sh) |
| **generated** | `regenerate_on_demand` | .aidev/.cache/* | Cache rebuild |
| **user** | `never_touch` | .aidev/plans/**, memory/kb/* | Somente o usuario/LLM |

### Fluxo de Classificacao

```mermaid
flowchart TD
    A["manifest_get_policy(filepath)"] --> B{MANIFEST_LOADED?}
    B -->|nao| C["return 'unknown'"]
    B -->|sim| D["_manifest_match_category(filepath)"]
    D --> E["Para cada glob em MANIFEST.json .files:"]
    E --> F["_manifest_glob_match(filepath, glob)"]
    F -->|match| G["return categoria"]
    F -->|no match| H{Proximo glob}
    H -->|fim| I["return 'unknown'"]
    G --> J["Busca policy da categoria"]
    J --> K["return policy"]
```

---

## 11. LLM Guard

```mermaid
flowchart TD
    A["llm_guard_pre_check(action, files_json)"] --> B["PASSO 1: validate_scope"]
    B --> C["Para cada arquivo no JSON:"]
    C --> D["manifest_get_policy(arquivo)"]
    D --> E{Politica?}
    E -->|never_modify_in_project| BLOCK_SCOPE
    E -->|never_overwrite| BLOCK_SCOPE
    E -->|never_touch / outra| F[Permitido]

    BLOCK_SCOPE["Bloqueado por escopo"] --> G["audit: blocked:scope\nscore: 0.1"]
    G --> BLOCKED([return 1 BLOQUEADO])

    F --> H["PASSO 2: enforce_limits"]
    H --> I["Ler MAX_FILES de llm-limits.md"]
    I --> J{file_count > MAX_FILES?}
    J -->|sim| K["audit: blocked:limit_files\nscore: 0.2"]
    K --> BLOCKED
    J -->|nao| L["PASSO 3: Tudo OK"]
    L --> M["audit: allowed\nscore: 0.9"]
    M --> ALLOWED([return 0 PERMITIDO])

    style BLOCKED fill:#f44336,color:#fff
    style ALLOWED fill:#4caf50,color:#fff
```

### Matriz de Bloqueio

| Condicao | Resultado | Score | Exemplo |
|----------|-----------|-------|---------|
| Arquivo core (never_modify_in_project) | BLOQUEADO | 0.1 | lib/core.sh |
| Arquivo state (never_overwrite) | BLOQUEADO | 0.1 | state/unified.json |
| Arquivos > MAX_FILES (default 10) | BLOQUEADO | 0.2 | 15 arquivos de uma vez |
| Arquivo user (never_touch) | PERMITIDO | 0.9 | plans/todo.md |
| Arquivo template customizado | PERMITIDO | 0.9 | agents/orchestrator.md |
| Tudo dentro dos limites | PERMITIDO | 0.9 | 5 arquivos normais |

---

## 12. Deploy Sync

```mermaid
flowchart TD
    A["deploy_sync_to_global(local_path)"] --> B{Global existe?}
    B -->|nao| ERR([Erro: instalacao global nao encontrada])
    B -->|sim| C{Mesmo diretorio?}
    C -->|sim| OK([Nao precisa sincronizar])
    C -->|nao| D["Para cada arquivo em AIDEV_SYNC_FILES (43):"]
    D --> E{Arquivo local existe?}
    E -->|nao| SKIP[skip + skipped_count++]
    E -->|sim| F{md5sum local == global?}
    F -->|sim| SKIP
    F -->|nao| G{dry_run?}
    G -->|sim| H["[SIMULAR] arquivo"]
    G -->|nao| I["cp local -> global"]
    I --> J{Sucesso?}
    J -->|sim| K[synced_count++]
    J -->|nao| L[error_count++]

    K & L & SKIP --> M["Sync diretorios: templates/ migrations/"]
    M --> N{rsync disponivel?}
    N -->|sim| O["rsync -a local/dir/ -> global/dir/"]
    N -->|nao| P["cp -r local/dir/* -> global/dir/"]
    O & P --> Q["Salva .last_sync_timestamp"]
    Q --> R([Sucesso])

    style A fill:#ff9800,color:#fff
    style R fill:#4caf50,color:#fff
```

### Arquivos Sincronizados

- **bin/aidev** (executavel principal)
- **37 libs** (lib/*.sh)
- **VERSION, CHANGELOG.md, README.md, MANIFEST.json, install.sh**
- **templates/** (diretorio inteiro via rsync)
- **migrations/** (diretorio inteiro via rsync)

---

## 13. Matriz de Protecao de Arquivos

```mermaid
quadrantChart
    title Protecao vs Frequencia de Modificacao
    x-axis Baixa Frequencia --> Alta Frequencia
    y-axis Baixa Protecao --> Alta Protecao
    quadrant-1 Core (nunca modificar)
    quadrant-2 State (runtime)
    quadrant-3 Templates (auto-upgrade)
    quadrant-4 User (livre)
    bin/aidev: [0.1, 0.95]
    lib/*.sh: [0.15, 0.95]
    VERSION: [0.3, 0.9]
    state/unified.json: [0.95, 0.9]
    state/audit.log: [0.9, 0.85]
    agents/*.md: [0.4, 0.5]
    skills/*/SKILL.md: [0.35, 0.5]
    rules/*.md: [0.3, 0.45]
    CLAUDE.md: [0.5, 0.4]
    .cache/*: [0.8, 0.2]
    plans/**/*: [0.85, 0.15]
    memory/kb/*: [0.7, 0.1]
```

---

## 14. Gargalos e Melhorias

### Severidade CRITICAL

| # | Problema | Impacto | Solucao |
|---|----------|---------|---------|
| 1 | bin/aidev com 3.932 linhas | Impossivel testar/manter | Extrair para lib/cmd/*.sh |
| 2 | Race condition no state.sh | Corrupcao de dados | Adicionar flock |
| 3 | `local` fora de funcao no test | Comportamento indefinido | Mover para funcao helper |

### Severidade HIGH

| # | Problema | Solucao |
|---|----------|---------|
| 4 | cmd_lessons duplicado | Remover definicao morta (linha 1187) |
| 5 | process_agent_template nunca chamada | Remover dead code |
| 6 | feature-lifecycle.sh na sync list mas nao existe | Remover da lista |
| 7 | 38+ erros silenciados | Logging com fallback em vez de `\|\| true` |
| 8 | Migracao sem rollback | Checkpoint pre-script + restauracao |
| 9 | jq chamado excessivamente | Batch reads (ler 1x em variavel) |
| 10 | Loader com busca O(n) | Associative array para lookup O(1) |
| 11 | 10+ modulos sem testes | Criar testes prioritarios |
| 12 | cmd_init/cmd_upgrade duplicam logica | Extrair install_core_components() |

### Severidade MEDIUM

| # | Problema | Solucao |
|---|----------|---------|
| 13 | 12 modulos loaded eagerly | Lazy loading por comando |
| 14 | `**` glob nao funciona no manifest | Implementar fnmatch correto |
| 15 | Paths hardcoded /tmp | Usar mktemp |
| 16 | i18n incompleto | Wrapper para mensagens de erro |
| 17 | Testes sem isolamento | Rodar em subprocessos |

### Roadmap de Melhoria Sugerido

```mermaid
gantt
    title Roadmap de Melhorias v4.5+
    dateFormat YYYY-MM-DD
    section Critical
    Extrair comandos em lib/cmd/        :crit, c1, 2026-02-17, 5d
    Adicionar flock ao state.sh         :crit, c2, 2026-02-17, 1d
    Fix local fora de funcao            :crit, c3, 2026-02-17, 1d
    section High
    Batch jq reads                      :h1, after c2, 2d
    Remover dead code                   :h2, after c1, 1d
    Migration rollback                  :h3, after c2, 3d
    Testes para modulos sem cobertura   :h4, after c3, 5d
    section Medium
    Lazy loading de modulos             :m1, after h1, 2d
    Fix manifest glob **                :m2, after h2, 1d
    Isolamento de testes                :m3, after h4, 3d
```

---

## Apendice: Referencia Rapida de Paths

| Path | Descricao |
|------|-----------|
| `~/.local/bin/aidev` | Symlink para instalacao global |
| `~/.aidev-superpowers/` | Instalacao global (bin/, lib/, templates/) |
| `~/.aidev-superpowers/VERSION` | Versao global (SSOT) |
| `.aidev/` | Diretorio do projeto |
| `.aidev/state/unified.json` | Estado runtime (ACID) |
| `.aidev/state/audit.log` | Trail de auditoria LLM Guard |
| `.aidev/MANIFEST.local.json` | Versao do projeto (migration) |
| `.aidev/.cache/checksums.json` | Registry de checksums pos-upgrade |
| `.aidev/.cache/activation_cache.json` | Cache de ativacao do agente |
| `.aidev/backups/YYYYMMDDHHMMSS/` | Backups de upgrade |
| `MANIFEST.json` | Regras de classificacao (raiz do repo) |
| `VERSION` | SSOT de versao (raiz do repo) |
| `migrations/` | Scripts de migracao incremental |
