# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere au [Versionamento Semântico](https://semver.org/lang/pt-BR/).

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

## [3.8.2] - 

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

## [3.8.2] - 

## [3.7.0] - 2026-02-06
### Adicionado
- **Metodologia Roadmap & Sprints**: Integração formal do modelo SGAITI para planejamento de longo prazo.
- **Comandos `aidev roadmap` e `aidev feature`**: Gestão completa do ciclo de vida de funcionalidades e sprints.
- **State Manager Agent**: Novo agente focado em sincronia de contexto, fotografias de estado (snapshots) e cache inteligente.
- **Regra de Ouro (Orchestrator)**: Priorização na leitura do Roadmap e Features ativas para continuidade absoluta entre sessões.
- **Templates de Planejamento**: `ROADMAP.md.tmpl` e `FEATURE.md.tmpl` para padronização de projetos.

## [3.8.2] - 

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

## [3.8.2] - 

## [3.6.1] - 2026-02-05

### 🚀 Features (Novidades)
- **Memory Sync Cross-Project**: Abstração da sincronização de memória e base de conhecimento (KB) entre projetos.
- **Lessons Indexer**: Novos subcomandos `aidev lessons index` e `search` otimizados via `.index.json`.
- **Trigger System**: Sistema de triggers YAML para detecção proativa de oportunidades de aprendizado (ex: `lesson-capture.yaml`).

### ⚡ Melhorias
- **Documentação Técnica**: Adicionado guia detalhado do comportamento do instalador (`docs/INSTALLER_BEHAVIOR.md`).

### 🐛 Fixes (Correções)
- **Release Module**: Correção crítica no script de release que causava falha prematura em incrementos de contadores bash.

## [3.8.2] - 

## [3.6.0] - 2026-02-05

### 🚀 Features (Novidades)
- **Sentinela de Conhecimento**: Orquestrador agora sugere registro de lições proativamente após bugs ou tarefas complexas.
- **Padrões de Sucesso**: Expansão do sistema `learned-lesson` para capturar padrões de excelência e decisões arquiteturais (não apenas bugs).
- **Busca Unificada de Lições**: Novo módulo `lib/lessons.sh` integra busca local (`.aidev/memory/kb/`) com busca global (`basic-memory` MCP).
- **CLI Lessons Refatorado**: `aidev lessons` com suporte a `--sync`, `--search` e `--read`.
- **Knowledge Ingestion**: Sincronização automática de regras genéricas e padrões técnicos para o KB.

### ⚡ Melhorias
- Orquestrador Brain: Integração profunda com `lessons_search` para injeção de contexto inteligente.

## [3.8.2] - 

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

## [3.8.2] - 

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

## [3.8.2] - 

## [3.3.1] - 2026-02-03

### 🚀 Novidades
- **Release Manager**: Agente e Skill para automação de releases.
- **CLI Command**: Novo comando `aidev release` para gerenciar ciclo de vida de versões.

## [3.8.2] - 

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

## [3.8.2] - 

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



## [3.8.2] - 

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


## [3.8.2] - 

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
