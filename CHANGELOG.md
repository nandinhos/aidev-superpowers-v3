# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere au [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [4.5.6] - 2026-02-20

### Adicionado: Feature Lifecycle Automation

- **`aidev plan "titulo"`**: Cria item de backlog com template padronizado (título, status, prioridade, data, campos estruturados).
- **`aidev start <id>`**: Move feature de `features/` → `current/`, valida unicidade, atualiza `current/README.md` com tabela de sprints, gera checkpoint automático.
- **`aidev done <sprint-id>`**: Marca sprint como concluída na tabela do `current/README.md`, detecta quando todas as sprints estão concluídas e sugere `aidev complete`. Gera checkpoint automático.
- **`aidev complete <id>`**: Finaliza feature: move `current/` → `history/YYYY-MM/`, reseta `current/README.md`, atualiza `features/README.md` e `backlog/README.md`, reconstrói `ROADMAP.md` como índice.
- **`lib/feature-lifecycle-cli.sh`**: Novo módulo core com `flc_plan_create`, `flc_feature_start`, `flc_sprint_done`, `flc_feature_complete`, `_flc_roadmap_rebuild`.
- **ROADMAP como índice**: `_flc_roadmap_rebuild` reconstrói ROADMAP com ≤ 60 linhas (era 248). Conteúdo detalhado fica em `history/`.
- **`cmd_start` substituído**: Guia de ativação removido (coberto por `aidev agent`); `start` agora inicia execução de features.
- **Automação completa**: A cada transição, `git add` + exibição de diff para revisão antes do commit.
- **34 novos testes unitários** (test-lifecycle-plan.sh, test-lifecycle-start.sh, test-lifecycle-done.sh, test-lifecycle-complete.sh, test-lifecycle-roadmap.sh).

## [4.5.5] - 2026-02-20

### Adicionado: Basic Memory Graceful Integration

- **`mcp-detect.sh`** (Sprint 1): Detecção unificada multi-runtime (Claude Code, Antigravity, Gemini, OpenCode) com cache via `_AIDEV_BM_DETECTED`. Suporta variáveis de ambiente como layer de override.
- **`basic-memory-guard.sh`** (Sprint 2): Wrappers seguros `bm_write_note`, `bm_search`, `bm_build_context` com fallback local em `.aidev/memory/kb/`. Todos os wrappers são no-fail.
- **`ckpt_sync_to_basic_memory`** (Sprint 3): Sincronização graceful de checkpoints para Basic Memory. Fallback local em `.aidev/memory/kb/checkpoints/`. Integrado ao `ckpt_create`.
- **Context Compressor + BM** (Sprint 4): `context-compressor.sh` enriquecido com `_ctx_fetch_cross_session_memory`. Seção "Memoria Cross-Session" aparece quando BM disponível.
- **Dashboard + Diagnóstico** (Sprint 5): `cmd_status` exibe seção "Integracoes MCP" com status do Basic Memory. `cmd_doctor` diagnostica e sugere instalação. `QUICKSTART.md` atualizado com seção de Basic Memory (opcional, recomendado).
- **`install_aidev_lib`** (Pre-Sprint 0): Nova função distribui `.aidev/lib/*.sh` em `aidev init`, `upgrade` e `self-upgrade`, resolvendo gap de distribuição.
- **54 novos testes unitários** cobrindo todos os sprints (test-mcp-detect.sh, test-basic-memory-guard.sh, test-checkpoint-sync.sh, test-context-compressor-bm.sh, test-status-doctor-bm.sh).

## [4.5.4] - 2026-02-20

### 🐛 Correções de Bugs (Instalador e VPS)
- **Auto-Update Corrigido**: Resolvido bug onde o alerta de nova versão tentava chamar o subcomando local `cmd_self_upgrade` antes das funções do core estarem completamente carregadas em memória. O prompt de checagem foi isolado com segurança dentro do loop `main()`.
- **Instalação Global (Same File CP)**: Corrigido o erro que paralisava o `aidev init` na fase de root (`cp: são o mesmo arquivo`) quando a instalação ocorria diretamente dentro do diretório cache/global (`~/.aidev-core`).
- **Graceful Triggers Fallback**: A engine de Triggers em Python agora detecta e ignora silenciosamente projetos onde a dependência `PyYAML` não está instalada no host, em vez de lançar falsos positivos de `YAML Inválido` no log de terminal.

## [4.5.3] - 2026-02-20
### 🔧 Correções e Melhorias Essenciais (Activations)
- **Fonte Singular de Verdade (AIDEV_ROOT Bug)**: Resolvido o problema de resolução do `AIDEV_ROOT` nos modulos `activation-snapshot.sh`, `workflow-sync.sh` e `workflow-commit.sh` com enforcement unificado a partir da pasta isolada de scripts, eliminando a criação espúria de diretórios `state/` falsos na raiz dos projetos.
- **Validação Anti-Duplicidade**: `workflow-sync.sh validate` agora realiza o check forçado reportando e bloqueando conformidade caso existam pastas de estados na raiz real do projeto.
- **Padronização de System Prompts**: Desacoplamento do `AI_INSTRUCTIONS.md`, focando-o agora para atuar apenas como Interceptor/Roteador de Agentes de IDE, direcionando as configurações core 100% para o `QUICKSTART.md`.
- **Systematic Fallback**: Adoção no `QUICKSTART.md` de uma diretiva crítica que orienta LLMs ativados independentemente a procurarem ou gerarem ativamente sua matriz `.aidev/.cache/activation_context.md`.

## [4.5.1] - 2026-02-18
## [4.4.0] - 2026-02-16

### Guardrails de Execucao LLM (Sprint 3)
- **LLM Guard** (`lib/llm-guard.sh`): motor de validacao pre-execucao
  - `validate_scope`: bloqueia escrita em arquivos core/state via MANIFEST
  - `enforce_limits`: le MAX_FILES e MAX_LINES de `rules/llm-limits.md`
  - `pre_check`: gate unificado (scope + limits) integrado ao sprint-guard
  - `audit`: log de auditoria em `.aidev/state/audit.log`
  - `log_decision`: registra decisoes no confidence_log via state.sh
- **Template** `rules/llm-limits.md`: MAX_FILES_PER_CYCLE=10, MAX_LINES_PER_FILE=200
- Instalacao automatica no `init` e `upgrade`

### Cobertura de Testes e Bugfixes (Sprint 4)
- **Fix**: removida funcao `cmd_feature` duplicada em `bin/aidev`
- **Fix**: `cmd_upgrade` agora reinstala rules e llm-limits
- **Testes unitarios**: test-version-check.sh (10), test-release.sh (11)
- **Testes integracao**: test-upgrade.sh (5), test-self-upgrade.sh (9)
- Total: 35 novos testes

### Sistema de Migracao Incremental (Sprint 5)
- **Migration engine** (`lib/migration.sh`): 5 funcoes publicas
  - `migration_stamp`: cria/atualiza MANIFEST.local.json por projeto
  - `migration_get_project_version`: le versao do projeto
  - `migration_needed`: detecta necessidade de migracao
  - `migration_list_steps`: lista scripts entre versoes
  - `migration_execute`: executa migracoes incrementais
- **MANIFEST.local.json**: rastreia versao por projeto (nao versionado)
- Pipeline de migracao integrado ao `cmd_upgrade`
- Diretorio `migrations/` para scripts de migracao futuros

## [4.3.0] - 2026-02-13

### 🗂️ Reorganização da Estrutura de Planejamento
- **Nova estrutura em `.aidev/plans/`**:
  - 📋 `backlog/` - Ideias futuras não priorizadas
  - 🚀 `features/` - Planejados com sprint definida
  - 🏃 `current/` - Em execução AGORA
  - ✅ `history/` - Concluídos organizados por data (YYYY-MM)
  - 📚 `archive/` - Documentação e templates
- **6 READMEs navegáveis** criados para facilitar acesso
- **Fluxo de trabalho definido**: ideia → planejamento → execução → conclusão
- **Movimentação de arquivos**:
  - Sprint 5 concluída → `history/2026-02/`
  - MCP Universal → `backlog/` (ideia futura)
  - Sprint Protocol → `archive/templates/` (documentação)
  - Smart Upgrade permanece em `features/` (planejada)

### 🐛 Correções
- **Fix no path do `feature-lifecycle`**: usa `$PWD` ao invés de `BASH_SOURCE`
- **Criação automática de `.aidev/lib/`**: no `create_base_structure()` durante init

## [4.2.0] - 2026-02-13

### 🚀 Features (Feature Lifecycle Automation)
- **Gerenciamento de Ciclo de Vida de Features** (`lib/feature-lifecycle.sh`):
  - Comandos CLI: `aidev feature [list|complete|status|show]`
  - Automação de arquivamento em `.aidev/plans/history/YYYY-MM/`
  - Atualização automática de `ROADMAP.md`
  - Registro em `context-log.json` para rastreabilidade
  - Checklist de conclusão padronizado
- **Integração com Skills**:
  - Atualização da skill `test-driven-development` com seção "Ao Completar Feature"
  - Documentação do orquestrador com novos comandos
- **Documentação Completa**:
  - Guia completo em `.aidev/docs/feature-lifecycle.md`

### 🔧 Melhorias (Sincronização)
- Adicionado `lib/feature-lifecycle.sh` à lista de arquivos críticos (`AIDEV_SYNC_FILES`)

### 🛡️ Sprint 6.1: Smart Upgrade Merge (Proteção de Customizações)
- **Proteção de arquivos customizados** durante `aidev upgrade`:
  - Removido `AIDEV_FORCE=true` que forçava sobrescrita
  - Backup automático antes do upgrade
  - Mensagem informativa sobre arquivos preservados
  - Flag `--force` para sobrescrever quando necessário

### 🔍 Sprint 6.2: Advanced Error Recovery
- **Sistema de recuperação automática de erros** (`lib/error-recovery.sh`):
  - KB integrado com 20+ padrões de erro comuns
  - Funções: `analyze`, `suggest`, `auto-recovery`, `stats`
  - Integração com `error_handler` existente
  - Comando CLI: `aidev error-recovery [analyze|stats|clear|test]`
  - Sugestões contextualizadas com scoring de confiança
  - Recovery automático para erros conhecidos
  - Log de erros em `.aidev/state/error-log.json`

### 🔄 Version Check System
- **Verificação automática de versão** (`lib/version-check.sh`):
  - Compara versão local vs GitHub
  - Alerta na inicialização se desatualizado
  - Comando: `aidev version [check|info]`
  - Comparação semântica de versões (X.Y.Z)

## [4.1.0] - 2026-02-13

## [4.0.1] - 2026-02-12

### ✨ Melhorias (Antigravity UX)
- **Workflows Avançados**: Implementação de 12 novos workflows Slash Commands para o Antigravity.
- **Interatividade**: Adição de placeholders para parâmetros dinâmicos em comandos como `log`, `handoff`, `lessons` e `feature`.
- **Categorização**: Organização dos workflows em Visibilidade, Continuidade, Conhecimento e Gestão de Sprint.

### 🛠️ Correções (Roadmap Dashboard)
- **Deteção de Sprint**: Correção no `grep` do comando `roadmap status` para reconhecer sprints marcadas como "(EM PROGRESSO)", garantindo o cálculo correto da barra de progresso.
- **Extração de Nomes**: Melhoria na extração de nomes de funcionalidades em arquivos Markdown, priorizando o título `# Feature:` ou o primeiro H1.

## [4.0.0] - 2026-02-12

### 🚀 Features (Sprint 5: Orquestração por Estado Ubíquo)
- **Protocolo Universal de Handoff**:
  - Checkpoints enriquecidos com `cognitive_context` (chain_of_thought, mental_model, hypotheses).
  - Comando CLI `aidev handoff` para transição entre LLMs.
- **Handoff Agnóstico de Tooling**:
  - Geração automática de artefatos Markdown para ambientes sem MCP.
  - Comando CLI `aidev fallback` para gestão de artefatos de recuperação.
- **Sync de Roadmap em Tempo Real**:
  - Módulo `lib/context-git.sh` para registro de micro-logs de ações.
  - Integração com `sprint.sh` e `unified.json`.
  - Comando CLI `aidev log` para visualização da timeline de ações.
- **Autonomia de Alinhamento de Sprint**:
  - Módulo `lib/sprint-guard.sh` com scoring semântico de alinhamento.
  - Alertas automáticos no Orchestrator para evitar desvios do Roadmap.
  - Comando CLI `aidev guard` para auditoria de alinhamento.

### 🧪 Métricas
- **133 novos testes** garantindo a robustez das funcionalidades da Sprint 5.
- **Cobertura total** de todos os novos módulos (`context-git`, `sprint-guard`, `fallback-generator`).

## [3.10.2] - 2026-02-12

### ✨ Estilização (Cache UX)
- **Cores nas Etiquetas**: Adicionado destaque em amarelo para as etiquetas (chaves) no comando `aidev cache --show`, melhorando o contraste e a escaneabilidade.

## [3.10.1] - 2026-02-12

### ✨ Melhorias (Elegant Cache View)
- **Visualização de Cache Elegante**: Substituição do dump de JSON bruto por uma representação estruturada e legível no comando `aidev cache --show`.
- **UI Consistency**: Integração com os ornaments padrão (`print_header`, `print_section`).
- **Resumo de Conteúdo**: Exibição detalhada de agentes (com roles), skills e regras ativas.

### 🐛 Correções
- **Cache Generator**: Correção de bug de escape de aspas em descrições de agentes que causava JSON inválido.
- **Global Sync**: Atualização da instalação global para refletir as melhorias de visualização.

## [3.10.0] - 2026-02-12

### 🚀 Features (Sprint 3: Context Monitor & Auto-Checkpoint)
- **Context Monitor** (`lib/context-monitor.sh`): Monitoramento completo de janela de contexto para sessões LLM
  - Estimativa inteligente de tokens (heurística: 4 caracteres/token)
  - Triggers automáticos: 70% warning, 85% auto-checkpoint, 95% force-save
  - Funções: `ctx_estimate_tokens`, `ctx_get_usage_percent`, `ctx_should_checkpoint`, `ctx_get_remaining_capacity`
  - **60 testes unitários** cobrindo todas as funções
  
- **Checkpoint Manager** (`lib/checkpoint-manager.sh`): Gestão completa de checkpoints com persistência
  - Criação, listagem e restauração de checkpoints
  - Formato JSON estruturado com snapshots de estado
  - Funções: `ckpt_create`, `ckpt_list`, `ckpt_get_latest`, `ckpt_generate_restore_prompt`
  - **18 testes unitários** validando todas as operações
  
- **Comando `aidev restore`**: Interface completa para restauração de contexto
  - Subcomandos: `--list`, `--latest`, `<checkpoint-id>`
  - Geração de prompts de continuidade para LLM
  - **17 testes de integração** cobrindo todos os cenários
  
- **Basic Memory Integration**: Integração profunda com MCP Basic Memory
  - Schema mapping: conversão automática checkpoint → nota Markdown
  - Sync automático configurável via `CKPT_SYNC_BASIC_MEMORY`
  - Busca semântica de checkpoints históricos
  - Funções auxiliares: `ckpt_to_basic_memory_note`, `ckpt_config_sync`, `ckpt_sync_all`, `ckpt_search_basic_memory`
  - **24 testes** validando integração completa
  - **Economia de 60%+** de tokens na inicialização do agente

### 📊 Impacto da Sprint 3
- **119 testes** criados e passando (60 + 18 + 17 + 24)
- Persistência ilimitada de contexto entre sessões LLM
- Zero perda de contexto ao trocar de máquina ou projeto
- Cross-project learning via Basic Memory

### 📚 Documentação
- Plano de investigação completo: `.aidev/docs/basic-memory-investigation-plan.md`
- Protocolo de inicialização: `.aidev/docs/agent-initialization-protocol.md`
- Documentação inline em todos os módulos

## [3.9.0] - 2026-02-11

### 🚀 Features
- **Sprint Manager Integration**: Sistema de Sprint Manager agora integrado na inicialização do agente
  - Dashboard visual com status, progresso e próxima ação
  - Sincronização automática de `sprint_context` em `unified.json`
  - Contexto inteligente da sprint incluído no prompt do LLM
  - Métricas de sessão (checkpoints, tokens usados)
  - 51 testes automatizados (27 unitários + 24 integração)
  - Framework de testes reutilizável em `tests/helpers/test-framework.sh`

### 🐛 Correções
- **lib/core.sh**: Corrige erro de variável readonly `AIDEV_VERSION` ao carregar módulo múltiplas vezes
- **state.sh**: Adiciona `state_sync_legacy_session()` para manter compatibilidade com `session.json`

### 📚 Documentação
- Documentação inline completa no módulo `sprint-manager.sh`
- Testes documentados com casos de uso claros

## [3.8.4] - 2026-02-11

### 🐛 Correções
- **release.sh**: Corrige bug de inserção exponencial no CHANGELOG — `sed` agora usa `0,/pattern/` para inserir header apenas na primeira ocorrência
- **release.sh**: Define variável `current_date` que estava ausente
- **self-upgrade**: Inclui sincronização de arquivos raiz (`VERSION`, `CHANGELOG.md`, `README.md`, `install.sh`) no `cmd_self_upgrade`

### 🧹 Manutenção
- **CHANGELOG.md**: Limpeza de ~200 linhas fantasma acumuladas pelo bug do release

## [3.8.3] - 2026-02-11

### 🚀 Features (Sprint 1: Validation System Foundation)
- **Sistema de Validação Automática**: Implementação completa do sistema de validação com 7 validadores:
  - Validação de caminhos e diretórios
  - Validação de mensagens de commit (padrões convencionais)
  - Validação de emojis e prefixos
  - Validação de idiomas (pt-BR/en)
  - Validação de padrões de projeto
  - Validação TDD (testes em vermelho/verde)
  - Validação de Co-Authored-By
- **Motor de Retry e Fallback**: Sistema inteligente de retry com exponential backoff e fallback graceful
- **Context Passport**: Schema JSON padronizado para passagem de contexto entre agentes
- **59 testes automatizados** cobrindo todo o sistema de validação

### 🚀 Features (Sprint 2: Knowledge Management)
- **Auto-Catalogação de Erros**: Detecção e catalogação automática de erros com análise de padrões
- **Knowledge Base Search**: Motor de busca com relevance scoring para lições aprendidas
- **Sistema de Backlog**: Gestão de erros e tarefas pendentes com priorização
- **Integration Pipeline**: Validações integradas ao fluxo de desenvolvimento
- **Sprint Manager**: Correções no sistema de detecção automática de tasks
- **101 testes automatizados** (42 novos da Sprint 2)

### 📚 Documentação
- Documentação completa das Sprints 1 e 2
- Guias de uso do sistema de validação
- Documentação da Knowledge Base e workflows

## [3.8.2] - 2026-02-06
### 🚀 Features (Release Automation)
- **Single Source of Truth (SSOT)**: Versão centralizada no arquivo `VERSION`, eliminando redundâncias.
- **Auto-Release**: Comando `release` agora automatiza atualizações no `CHANGELOG.md`, `README.md` e testes unitários.
- **Dynamic Core**: O sistema agora carrega sua versão dinamicamente mantendo a performance com cache.

## [3.8.1] - 2026-02-06
### 🚀 Features (Sprint 4: Dashboards & System Management)
- **Dashboard de Roadmap**: Novo comando `aidev roadmap status` exibe visualmente o progresso da sprint atual.
- **Advanced Context Snapshotter**: `aidev snapshot` gera um resumo técnico portátil para migração de contexto entre IAs.
- **System Management**: Novo subcomando `aidev system` para gerenciar a instalação global.
    - `aidev system status`: Estado da instalação e backups.
    - `aidev system deploy`: Sincroniza o desenvolvimento com o global com backup automático.
    - `aidev system link`: Modo de desenvolvimento via links simbólicos.
    - `aidev system rollback`: Reversão de segurança do último deploy.

### 🐛 Fixes (Correções)
- **Cores ANSI**: Correção definitiva da exibição de cores no terminal através do uso de strings ANSI-C (`$'\e'`).
- **Sincronização Global**: Garantia de que a instalação em `~/.aidev-superpowers/` reflete exatamente a versão estável do repositório.

## [3.8.0] - 2026-02-06
### 🚀 Features (Portabilidade Multi-Ambiente)
- **Smart Path Resolution**: Nova função `resolve_path` no Core para expansão dinâmica de `$HOME` e `~` em tempo de execução.
- **Configurações Portáteis**: Templates de `memory-sync.json` agora utilizam literais de variáveis de ambiente, permitindo sincronia entre diferentes máquinas (`nandodev` vs `gacpac`) sem conflitos de Git.
- **Normalização Automática de Projeto**: O sistema agora prefere caminhos relativos (`.`) para o diretório do projeto nas configurações MCP, evitando quebras ao trocar de pasta ou máquina.
- **Auto-Cura de Caminhos**: Comando `aidev doctor --fix` agora detecta caminhos absolutos de usuário e os converte automaticamente para variáveis portáteis.

### ⚡ Melhorias
- **Upgrade Sincronizado**: O comando `aidev upgrade` agora reconfigura automaticamente o motor MCP para garantir que as melhorias de portabilidade sejam aplicadas a projetos existentes.
- **Robustez no Core**: Limpeza e otimização do módulo `lib/core.sh`.

### 🐛 Fixes (Correções)
- **Subcomandos `add-*`**: Correção de bug crítico no dispatcher do `bin/aidev` que impedia a captura correta do nome da skill/agente/rule e ignorava o parâmetro `--install-in`.
- **Testes Unitários**: Atualização da suite de testes do Core para validar a nova lógica de resolução de caminhos.
- **Uninstall Safety**: Melhoria nas validações de segurança do desinstalador.

## [3.7.0] - 2026-02-06
### Adicionado
- **Metodologia Roadmap & Sprints**: Integração formal do modelo SGAITI para planejamento de longo prazo.
- **Comandos `aidev roadmap` e `aidev feature`**: Gestão completa do ciclo de vida de funcionalidades e sprints.
- **State Manager Agent**: Novo agente focado em sincronia de contexto, fotografias de estado (snapshots) e cache inteligente.
- **Regra de Ouro (Orchestrator)**: Priorização na leitura do Roadmap e Features ativas para continuidade absoluta entre sessões.
- **Templates de Planejamento**: `ROADMAP.md.tmpl` e `FEATURE.md.tmpl` para padronização de projetos.

## [3.6.2] - 2026-02-05

### Adicionado
- **Automação de Triggers**: Motor proativo para detecção de contextos de aprendizado.
- **Módulo `lib/triggers.sh`**: Suporte a gatilhos via YAML com detecção de erros e intenções.
- **Comando `aidev triggers`**: Gestão completa de gatilhos (status, list, test).
- **Detecção de Erros Críticos**: Gancho automático no `error_handler` do CLI para sugerir lições da KB.
- **Análise de Intenção**: Detecção de palavras-chave de sucesso para ativação automática de skills.

### Segurança
- **Persistência Segura**: Estado de triggers e cooldowns gerenciado em `.aidev/state/triggers.json`.
- **Parsing Seguro**: Utilização de Python para processamento de YAML complexo de gatilhos.

## [3.6.1] - 2026-02-05

### 🚀 Features (Novidades)
- **Memory Sync Cross-Project**: Abstração da sincronização de memória e base de conhecimento (KB) entre projetos.
- **Lessons Indexer**: Novos subcomandos `aidev lessons index` e `search` otimizados via `.index.json`.
- **Trigger System**: Sistema de triggers YAML para detecção proativa de oportunidades de aprendizado (ex: `lesson-capture.yaml`).

### ⚡ Melhorias
- **Documentação Técnica**: Adicionado guia detalhado do comportamento do instalador (`docs/INSTALLER_BEHAVIOR.md`).

### 🐛 Fixes (Correções)
- **Release Module**: Correção crítica no script de release que causava falha prematura em incrementos de contadores bash.

## [3.6.0] - 2026-02-05

### 🚀 Features (Novidades)
- **Sentinela de Conhecimento**: Orquestrador agora sugere registro de lições proativamente após bugs ou tarefas complexas.
- **Padrões de Sucesso**: Expansão do sistema `learned-lesson` para capturar padrões de excelência e decisões arquiteturais (não apenas bugs).
- **Busca Unificada de Lições**: Novo módulo `lib/lessons.sh` integra busca local (`.aidev/memory/kb/`) com busca global (`basic-memory` MCP).
- **CLI Lessons Refatorado**: `aidev lessons` com suporte a `--sync`, `--search` e `--read`.
- **Knowledge Ingestion**: Sincronização automática de regras genéricas e padrões técnicos para o KB.

### ⚡ Melhorias
- Orquestrador Brain: Integração profunda com `lessons_search` para injeção de contexto inteligente.

## [3.5.0] - 2026-02-05

### 🚀 Features (Novidades)
- **MCP Manager**: Gerenciamento completo de servidores MCP (Model Context Protocol).
    - `aidev mcp add <nome> --command <cmd> --args <args>`: Adiciona servidor.
    - `aidev mcp list`: Lista servidores configurados.
    - `aidev mcp remove <nome>`: Remove servidor.
- **Runtime Detection**: Identificação inteligente do ambiente de execução (Terminal CLI vs VS Code/Cursor Integrado vs Antigravity).
    - Exibição no comando `status` (`Runtime: antigravity`).
- **Slash Commands**: Suporte nativo a comandos de chat (`/aidev`) no Antigravity via workflows.
- **Guia Técnico dos Agentes**: Documentação completa detalhando o funcionamento, ciclo de vida e dinâmicas (Greenfield/Brownfield/Legado) de cada agente.
- **Status em Tempo Real**: `aidev status` agora exibe o Intent e Skill ativos diretamente do cérebro do sistema (`unified.json`).

### 🐛 Fixes (Correções)
- **Self-Upgrade**: Correção crítica que impedia atualização quando executada da raiz do repositório (`fix source detection`).

## [3.3.2] - 2026-02-03

### 🐛 Fixes (Correções)
- **State Manager (Hardening)**:
    - Correção de colisão de IDs de checkpoins (`cp-TIMESTAMP-RANDOM`).
    - Correção na lógica de rollback para garantir integridade do JSON restaurado.

### 🛡️ Security (Segurança)
- **Orchestrator**: Substituição de `eval` inseguro por `bash -c` no wrapper de execução `try_with_recovery`.

### 🚀 Features (Novidades)
- **Smart Context Avançado**:
    - Detecção de versão exata do framework (Laravel 11, Next.js 14, Django, etc).
    - Detecção de Dívida Técnica (contagem de TODOs/FIXMEs e existência de testes).

## [3.3.1] - 2026-02-03

### 🚀 Novidades
- **Release Manager**: Agente e Skill para automação de releases.
- **CLI Command**: Novo comando `aidev release` para gerenciar ciclo de vida de versões.

## [3.3.0] - 2026-02-03

### 🚀 Novidades
- **Unified Knowledge Base (KB)**: Nova arquitetura de memória em `.aidev/memory/kb/`.
- **Lessons Command**: Comando `aidev lessons` para listar, buscar e ler lições aprendidas de forma interativa.
- **Smart Snapshot V2**: `aidev snapshot` agora inclui o estado técnico unificado (`unified.json`) com limite de 5 rollbacks para trocas de LLM sem perda de contexto.
- **Internationalization (i18n)**: Suporte completo a Inglês (en) e Português (pt-BR).
- **Config Command**: `aidev config language <lang>` para troca dinâmica de idioma.
- **Localized Templates**: Agentes e Regras organizados em `templates/{en,pt}`.

### ⚡ Melhorias
- **Orchestrator Context**: Otimização na injeção de lições para economizar tokens.
- **Auto-Load Environment**: `bin/aidev` carrega automaticamente `.env` para persistência de config.
- **Robustez CLI**: Melhoria na contagem de arquivos e tratamento de erros de shell no modo `set -e`.

## [3.2.0] - 2026-02-03

### 🚀 Novidades
- **Comandos Intuitivos**: Novos subcomandos que configuram automaticamente o fluxo do Agente:
    - `aidev new-feature "descrição"`: Inicia Brainstorming → TDD.
    - `aidev fix-bug "descrição"`: Inicia Systematic Debugging (Reproduce → Isolate → Fix).
    - `aidev refactor "escopo"`: Inicia fluxo de refatoração segura.
- **Smart Suggest (`aidev suggest`)**: Analisa o estado do projeto (Greenfield/Brownfield, testes, git) e sugere proativamente o próximo comando ideal.
- **Prompt Dinâmico**: O comando `aidev agent` agora gera prompts ainda mais específicos baseados no intent detectado pelos comandos acima.

### ⚡ Melhorias
- Correção no comando `status` para evitar crash quando o estado da sessão está parcial.
- Melhoria na detecção de projetos Brownfield sem testes na skill `suggest`.


## [3.1.0] - 2026-02-02

### 🚀 Novidades
- **Smart Context (Contexto Inteligente)**: CLI `aidev init` agora detecta maturidade do projeto (Greenfield/Brownfield) e adapta o workflow.
- **Knowledge Base Engine**: Sistema de lições aprendidas (`learned-lesson`) compartilhado entre agentes.
- **Auto-Cura Proativa**: Skill `systematic-debugging` orquestrada para detectar, corrigir e validar bugs automaticamente.
- **Telemetria Avançada**: Novo comando `aidev metrics` para visualizar performance, custos e uso de skills.
- **Context Snapshotter**: Comando `aidev snapshot` para portabilidade de contexto entre sessões/LLMs.
- **One-Liner Installer**: Script de instalação unificado `install.sh`.

### ⚡ Melhorias
- Correção de injeção de templates no Orchestrator (Antigravity).
- Suporte a hooks de auto-fix no `setup_secrets` (modo não-interativo).
- Documentação `README.md` atualizada com stacks suportadas e novos comandos.

### 🧪 Validação
- Stress Test "The Legacy Calculator" executado com sucesso (Orquestração + Falha Planejada + Correção Automática).
- Todos os testes de integração e unitários passando.


## [3.0.0] - 2026-01-29

### ✨ Adicionado
- **CLI unificado** `aidev` com comandos: init, upgrade, status, doctor, add-*
- **Sistema modular** com loader de módulos e dependências
- **Parser YAML** em Bash puro para configurações
- **Config merger** com hierarquia: CLI > projeto > defaults
- **8 agentes especializados**: orchestrator, architect, backend, frontend, qa, devops, legacy-analyzer, security-guardian
- **4 skills guiadas**: brainstorming, writing-plans, test-driven-development, systematic-debugging
- **Templates de rules** para Laravel, Node/Express, Python e genérico
- **Integração MCP** com context7 e serena
- **Auto-detecção** de stack (Laravel, Express, Python) e plataforma
- **Modo dry-run** para simular instalação
- **122 testes** (79 unitários, 26 integração, 17 E2E)

### 🔄 Mudanças
- Arquitetura completamente reescrita para modularidade
- Templates com suporte a variáveis `{{VAR}}` e condicionais `{{#if}}`
- Configuração via `.aidev.yaml` ao invés de variáveis de ambiente

### 📁 Estrutura
```
aidev-superpowers-v3/
├── bin/aidev           # CLI principal
├── lib/                # Módulos (core, cli, detection, templates, mcp, yaml-parser, config-merger)
├── config/             # Configurações default
├── templates/          # Templates de agentes, skills, rules, mcp
├── tests/              # Unitários, integração, E2E
└── docs/               # Documentação
```

### 🔧 Dependências
- Bash 4.0+
- npx (para context7)
- uvx (para serena)

---

## Sprints de Desenvolvimento

| Sprint | Descrição | Commits |
|--------|-----------|---------|
| 0 | Preparação e arquitetura | 83aba8a |
| 1 | Core module | 8d4a881 |
| 2 | Templates system | b2fb191 |
| 3 | CLI aidev | be7254c |
| 4 | Config system | ac6acd2 |
| 5 | MCP integration | f2950b7 |
| 6 | Test suite | 335c493 |
| 7 | Documentation | (atual) |

---

## Comparação com v2

| Feature | v2 | v3 |
|---------|----|----|
| CLI | Shell scripts separados | `aidev` unificado |
| Configuração | Variáveis de ambiente | `.aidev.yaml` |
| Modularidade | Monolítico | Modular com loader |
| Testes | Manuais | 122 testes automatizados |
| Detecção | Básica | Auto-detecção de stack/plataforma |
| Templates | Fixos | Variáveis e condicionais |
| MCP | Manual | Automático |

---

## Próximos Passos

- [ ] Sprint 8: Release e instalador global
- [ ] Suporte a mais stacks (Go, Rust, Java)
- [ ] Interface web para configuração
- [ ] Integração com mais plataformas AI
