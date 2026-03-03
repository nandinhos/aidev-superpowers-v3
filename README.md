# AI Dev Superpowers V3

> Transforme qualquer IA de codigo em um desenvolvedor senior com praticas TDD e padroes profissionais.

[![Version](https://img.shields.io/badge/version-4.8.0-blue.svg)]()
[![Tests](https://img.shields.io/badge/tests-412%20passing-green.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

## O que e?

AI Dev Superpowers e um framework que configura **agentes especializados**, **skills** e **regras** para guiar IAs de codigo (Claude Code, Antigravity, Gemini, Cursor, etc.) a trabalharem com:

- **TDD Mandatorio** - RED -> GREEN -> REFACTOR
- **YAGNI** - So implemente o necessario
- **DRY** - Nao repita codigo
- **Evidencias** - Prove que funciona, nao apenas afirme

## Instalação

### Método 1: One-Liner (Recomendado) 
Ideal para quem busca rapidez e configuração automática de PATH.
```bash
curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash
```

### Método 2: Manual (Expert) 
Ideal para desenvolvedores que desejam manter o repositório em um local específico.
```bash
# 1. Clone o repositório
git clone https://github.com/nandinhos/aidev-superpowers-v3.git

# 2. Adicione os binários ao seu PATH (exemplo no .bashrc)
export PATH="$PATH:$(pwd)/aidev-superpowers-v3/bin"

# 3. Inicialize seu projeto
cd seu-projeto
aidev init
```

---

## 🚀 Novidades da v4.8.0 — Fluxo Fluido de Ideias

### Brainstorm integrado ao ciclo de vida

O fluxo de desenvolvimento ganhou dois novos passos para evitar features mal definidas chegando ao código:

```
backlog/ → brainstorm/ → features/ → current/ → history/
```

**Fluxo completo (5 passos):**
```bash
aidev plan <titulo>           # Registra ideia bruta em backlog/
aidev brainstorm <backlog-id> # Explora ideia → .aidev/plans/brainstorm/
aidev create-feature <id>     # Promove brainstorm → .aidev/plans/features/
aidev start <feature-id>      # Inicia execução → current/
aidev done <sprint-id>        # Conclui sprint
aidev complete <feature-id>   # Arquiva → history/YYYY-MM/
```

- **`aidev brainstorm`**: cria documento estruturado com problema, abordagens, riscos e decisão preliminar. Suporta `--auto` para template sem interação.
- **`aidev create-feature`**: converte brainstorm em plano formal com sprints e critérios de aceite.

### Gate de proteção

`aidev start` agora bloqueia se a feature ainda está em `brainstorm/` ou `backlog/`, orientando o próximo comando correto.

### Regra de sessão

Ao iniciar qualquer sessão, verificar `current/` primeiro. Se houver feature ativa, retomar antes de qualquer outra tarefa. Incorporada ao `orchestrator.md`, `CLAUDE.md`, `rules/generic.md` e `QUICKSTART.md`.

### Novos triggers de ativação

Palavras `"backlog"` e `"brainstorm"` adicionadas como triggers em todos os runtimes (claude_code, opencode, claude_desktop, gemini, antigravity). Intents `backlog_add` e `brainstorm` incluídos na classificação do orchestrator.

### Renomeação: backlog.sh → error-tracker.sh

`lib/backlog.sh` renomeado para `lib/error-tracker.sh` para refletir seu escopo real (rastreamento de erros, não gestão de backlog de ideias).

### Índice de regras

Novo arquivo `rules/INDEX.md` com referência rápida a todas as regras do sistema e resumo das 6 inegociáveis.

### Skills: paths de artefatos corrigidos

- `brainstorming/SKILL.md`: artefatos salvos em `.aidev/plans/brainstorm/` (era `docs/plans/`)
- `writing-plans/SKILL.md`: artefatos salvos em `.aidev/plans/features/` (era `docs/plans/`)

### Limpeza automática de checkpoints

Nova função `_flc_cleanup_checkpoints()` mantém apenas os últimos 5 checkpoints JSON, evitando acumulação indefinida.

---

## 🚀 Novidades da V4.7.1 (Retroalimentação de Templates & Curadoria)
 
 ### Sistema de Retroalimentação de Templates
 Agora o framework possui um **ciclo virtuoso de aprendizado**, transformando lições aprendidas em regras de stack automaticamente:
 - **Lesson Classifier**: Classifica lições em 3 níveis (Local, Global, Universal) usando análise semântica e keywords.
 - **Lesson Promoter**: Converte lições validadas em regras oficiais de desenvolvimento em `.aidev/rules/{stack}.md`.
 - **Lesson Curator**: Novo motor de curadoria (heurística + suporte a MCPs) para garantir que apenas lições de alta qualidade virem regras.
 - **Lesson Dashboard**: Visualize a saúde do seu Knowledge Base com métricas de classificação e taxas de curadoria.
 
 ### Novo Skill: `lesson-curation`
 Skill especializada para guiar IAs na validação de lições contra documentação oficial (Context7/Laravel Boost) antes da promoção.
 
 ---
 
 ## 🚀 Novidades da V4.7.0 (Sistema MCP Padronizado)

### Sistema de Fallback para MCPs
MCPs agora são **opcionais**. Se não instalados ou sem resposta, o sistema ativa fallback automaticamente sem erro:
- **Basic Memory**: Fallback para `.aidev/memory/kb/`
- **Context7**: Fallback para `ripgrep`
- **Serena**: Fallback para `find . -name`
- **Laravel Boost**: Fallback para `php artisan`

### Novos Comandos MCP
```bash
aidev mcp status      # Ver status dos MCPs
aidev mcp stack      # Detectar stack do projeto
aidev mcp keys       # Importar chaves de API
aidev mcp show       # Preview da configuração
aidev mcp generate   # Gerar .mcp.json
aidev mcp health     # Health check completo
aidev mcp doctor     # Diagnóstico + sugestões
```

### Stack Detector
Detecção automática de stack (Laravel, Node.js, Python, Rust, Go) para ativar MCPs condicionais automaticamente.

### Tratamento de Erros Melhorado
Mensagens amigáveis em vez de erros genéricos:
- `aidev start`: Verifica se feature já está em execução ou concluída
- `aidev complete`: Verifica se feature já foi concluída
- `aidev done`: Verifica se há feature em execução

### Unificação de Fluxos
- Código morto removido (~1.800 linhas)
- Fluxo único: `backlog/ → features/ → current/ → history/`

---

## 🔮 Novidades da V4.6 `(Ativação Ultra-Rápida)`

### cmd_agent_lite Otimizado
Agora o comando `aidev agent` usa `activation_snapshot.json` diretamente se fresco (< 1 hora), evitando leitura de orchestrator.md e unified.json. **Economia de ~70% em tokens e tempo de ativação**.

### context_compressor_generate
Cria automaticamente `unified.json` com template padrão quando não existe, evitando erros em instalações legadas.

---

## 🚀 Novidades da V4.5 `(Sistema de Atualização Interativa)`

 ### Atualização Interativa Universal
 Agora o sistema verifica automaticamente se há uma nova versão disponível ao executar qualquer comando. O usuário é perguntado se deseja atualizar e o sistema faz tudo automaticamente:
 ```bash
 # Ao executar qualquer comando aidev, se houver nova versão:
 # - Exibe alerta de nova versão disponível
 # - Pergunta: "Deseja atualizar agora? [y/N]"
 # - Se sim: atualiza instalação global + projeto (preservando customizações)
 ```

 ### Self-Upgrade com Preservação
 O sistema de upgrade agora preserva agentes, skills e rules customizados:
 ```bash
 aidev self-upgrade        # Atualiza instalação global
 aidev upgrade --dry-run  # Preview do que seria atualizado
 ```

### Versão Dinâmica
Correção de versões hardcoded em arquivos de estado, agora usando a variável `$AIDEV_VERSION` corretamente em todos os pontos do sistema.

 ---

 ## 🌐 Novidades da V4.0 `(Orquestração por Estado Ubíquo)`

 ### Estado Ubíquo & Handoff
 Transição sem atrito entre diferentes LLMs (Claude Code, Gemini CLI, Antigravity) através de persistência de estado agnóstica e **Contexto Cognitivo**.
 ```bash
 aidev handoff create  # Prepara o terreno para outra IA
 aidev restore --latest # Retoma o raciocínio onde parou
 ```

 ### Context Git & Real-time Sync
 Micro-logs de cada ação realizada, mantendo a sprint sincronizada independente de qual CLI está sendo usada.
 ```bash
 aidev log show        # Visualiza a timeline da sessão
 ```

 ### Sprint Guard
 Scoring semântico automático para detectar se a IA está desviando da tarefa ativa na sprint.
 ```bash
 aidev guard status    # Verifica alinhamento da sprint
 ```

 ### Antigravity UX
 12 novos workflows Slash Commands integrados para execução rápida de comandos complexos com interatividade direta no chat.

 ---

 ## 🛰️ Novidades da V3.8 `(Portabilidade & System Management)`
 
 ### System Management (Nova!)
 Gerencie seu framework como um profissional. Sincronize o código de desenvolvimento com o global ou use o modo link para desenvolvimento em tempo real.
 ```bash
 aidev system status   # Verifica o estado global
 aidev system deploy   # Atualiza o sistema com segurança (auto-backup)
 aidev system link     # Ativa o modo de desenvolvimento (live sync)
 aidev system rollback # Reverte para o último backup estável
 ```

 ### Dashboards & Snapshots
 Visualize seu progresso e migre contextos sem perda de informação.
 ```bash
 aidev roadmap status  # Dashboard visual da Sprint
 aidev snapshot        # Passaporte técnico para troca de IA
 ```

 ### ANSI Colors Fix
 Correção definitiva de cores no terminal, agora 100% suportada em ambientes com redirecionamento e pipes.
 
 ---
 
 ## 🗺️ Novidades da V3.7 `(Metodologia Roadmap & Sprints)`
 
 ### Metodologia SGAITI Integrada
 Implementação formal do modelo de Roadmaps e Sprints. Agora você pode planejar grandes funcionalidades em pequenos incrementos rastreáveis.
 
 ```bash
 aidev roadmap status  # Visualiza o progresso da sprint atual
 aidev feature add     # Inicia uma nova funcionalidade no roadmap
 ```
 
 ### State Manager Agent
 Um novo agente especializado em garantir que a troca de contexto ou de modelo de IA ocorra sem perda de informação, gerenciando "Snapshots" e sincronia de estado técnica.
 
 ---
 
 ## 🚀 Novidades da V3.6 `(Memory Sync & Automação de Triggers)`
 
 ### Memory Sync Cross-Project
 O conhecimento agora é **global**. Lições aprendidas em um projeto podem ser indexadas e consultadas em outros repositórios, criando um cérebro coletivo para o time de desenvolvimento.
 
 ```bash
 aidev lessons index   # Indexa todas as lições aprendidas
 aidev lessons search  # Busca semântica por soluções no KB
 ```
 
 ### Automação de Triggers 
 O sistema tornou-se **proativo**. Através de gatilhos configuráveis, ele monitora a sessão e age sozinho:
 - **Ganchos de Erro**: Detecta erros críticos (SQL, Exceptions) e sugere soluções da KB.
 - **Detector de Intenção**: Identifica quando um bug foi resolvido e sugere documentar a lição.
 - **Gestão de Cooldown**: Respeita seu fluxo de trabalho, evitando sugestões repetitivas.
 
 ```bash
 aidev triggers list    # Lista gatilhos ativos
 aidev triggers status  # Verifica saúde do motor de automação
 ```
 
 ---
 
 ## ⚡ Novidades da V3.5 `(Cache de Ativação & Economia de Tokens)`

### Cache de Ativação Inteligente
O sistema agora **pré-computa** todas as informações essenciais (agentes, skills, regras) em um único JSON, reduzindo o consumo de tokens na ativação em **até 96%**.

```bash
aidev cache --build   # Gera o cache
aidev cache --status  # Verifica integridade
aidev agent           # Prompt já inclui o cache automaticamente
```

**Documentação técnica**: [docs/CACHE_SYSTEM.md](docs/CACHE_SYSTEM.md)

### Continuidade de Sessão
O prompt de ativação agora injeta o **contexto da sessão anterior** (intenção ativa, skill em uso), permitindo que a IA retome trabalhos pendentes em vez de sugerir novas tarefas.

### Compatibilidade Multi-Modelo
Instruções otimizadas para diferentes comportamentos de LLMs:
- **Claude**: Ativa instantaneamente, respeita cache
- **Gemini**: Instruções assertivas com emojis (⚠️🛑) forçam economia
- **GPT-4**: Meio-termo equilibrado

### Correções de Estabilidade
- Fix: Crash quando nome do projeto não é detectado
- Fix: Listagem redundante de agentes quando cache existe

---
 
 ## ⚡ Novidades da V3.4 `(MCP Manager & Runtime Detection)`
 
 ### MCP Manager (Model Context Protocol)
 Agora você pode gerenciar seus próprios servidores MCP diretamente pelo CLI. Adicione documentação customizada ou ferramentas de análise com facilidade.
 
 ```bash
 aidev mcp list             # Lista servidores ativos
 aidev mcp add <nome>       # Registra um novo servidor
 ```
 
 ### Runtime & Slash Commands
 O sistema detecta se você está no terminal puro, VS Code ou no modo Antigravity, adaptando os lembretes. No Antigravity, use `/aidev` para workflows automáticos.
 
 ---
 
 ## 🌍 Novidades da V3.3 `(Internacionalização & Release Manager)`
 
 ### Multi-Idioma (i18n)
 Suporte nativo completo para **Português (pt-BR)** e **Inglês (en)**. Mensagens, templates de agentes e regras agora falam a sua língua.
 
 ```bash
 aidev config language en    # Muda para Inglês
 aidev config language pt-br # Volta para Português
 ```
 
 ### Automação de Releases
 Novo comando `aidev release` coordenado pelo **Release Agent**. Ele automatiza o bump de versão, atualiza changelogs e cria tags git com um único comando.
 
 ---
 
 ## 💡 Novidades da V3.2 `(Comandos de Intenção & Smart Suggest)`
 
 ### Comandos Baseados em Intenção
 O CLI agora configura automaticamente o fluxo de trabalho da IA baseado no seu objetivo:
 - `aidev new-feature`: Brainstorming -> Plano -> TDD.
 - `aidev fix-bug`: Systematic Debugging.
 - `aidev refactor`: Refatoração Segura.
 
 ### Smart Suggest
 O comando `aidev suggest` analisa o seu projeto (git status, arquivos, testes) e diz exatamente o que você deveria fazer agora.
 
 ---
 
## Novidades da V3.1 `(Greenfield & Brownfield)`

### Contexto Inteligente (Smart Context)
O `aidev init` agora detecta automaticamente o estado do projeto:
*   **Greenfield (Projetos Novos)**: Bloqueia se não houver um PRD. Força *Design-First*.
*   **Brownfield (Projetos Legados)**: Sugere diagnóstico com *Legacy Analyzer*. Foca em Refatoração.

### Telemetria e Métricas
Novo comando `aidev metrics` fornece insights sobre o uso dos agentes:
*   Tempo de execução por skill.
*   Taxa de sucesso/falha (TDD).
*   Custo e eficiência dos agentes.

### Auto-Cura Proativa (Systematic Debugging)
A nova skill `systematic-debugging` orquestrada pelo agente não apenas identifica erros, mas aplica correções, valida com testes e gera uma **Lição Aprendida** na memória para evitar recorrência.

### Knowledge Base Engine
Memória semântica compartilhada. O que o *Backend Agent* aprende sobre um bug de banco de dados, o *Architect Agent* sabe ao planejar a próxima feature.

### Context Snapshotter V2
Use `aidev snapshot` para gerar um "Passaporte de Contexto" portátil. Agora inclui o **Unified State**, permitindo que a próxima LLM saiba exatamente em qual passo de qual skill você parou.

### Knowledge Base Interativa
Novo comando `aidev lessons` permite consultar todo o conhecimento acumulado do projeto diretamente pelo terminal, com busca semântica por tags e leitura rápida.

## O que e instalado?

```
seu-projeto/
├── .aidev/
│   ├── QUICKSTART.md     # Arquivo consolidado para ativacao rapida
│   │
│   ├── plans/            # [NOVO v3.7] Roadmaps e Sprints (Metodologia SGAITI)
│   │   ├── ROADMAP.md
│   │   ├── features/
│   │   └── history/
│   │
│   ├── agents/           # 10 agentes especializados
│   │   ├── orchestrator.md
│   │   ├── architect.md
│   │   ├── backend.md
│   │   ├── frontend.md
│   │   ├── code-reviewer.md
│   │   ├── qa.md
│   │   ├── devops.md
│   │   ├── legacy-analyzer.md
│   │   └── security-guardian.md
│   │
│   ├── skills/           # 6 skills guiadas
│   │   ├── brainstorming/
│   │   ├── writing-plans/
│   │   ├── test-driven-development/
│   │   ├── code-review/
│   │   ├── systematic-debugging/
│   │   └── learned-lesson/
│   │
│   ├── rules/            # Regras da stack (generic + stack específica)
│   │
│   ├── triggers/         # Gatilhos automáticos de captura de lições (YAML)
│   │
│   └── state/            # Estado persistente (sessao e cooldowns)
│
├── CLAUDE.md             # Instrucoes para Claude Code
└── .mcp.json             # Configuracao MCP (se aplicavel)
```

## Comandos CLI

| Comando | Descricao |
|---------|-----------|
| `aidev init` | Inicializa AI Dev no projeto |
| `aidev new-feature` | **(v3.2)** Inicia fluxo de Nova Feature (Brainstorming -> TDD) |
| `aidev fix-bug` | **(v3.2)** Inicia fluxo de Correção de Bug (Systematic Debugging) |
| `aidev refactor` | **(v3.2)** Inicia fluxo de Refatoração Segura |
| `aidev suggest` | **(v3.2)** Analisa o projeto e sugere o próximo passo ideal |
| `aidev agent` | Gera prompt de ativacao do modo agente |
| `aidev cache --build` | **(v3.5)** Gera cache de ativação para economia de tokens |
| `aidev cache --status` | **(v3.5)** Verifica integridade do cache |
| `aidev cache --clear` | **(v3.5)** Remove cache (força leitura completa) |
| `aidev config language <lang>` | **(v3.3)** Troca o idioma do CLI (pt-br, en) |
| `aidev release <tipo>` | **(v3.3)** Automatiza ciclo de release (patch, minor, major) |
| `aidev mcp list/add`  | **(v3.5)** Gerencia servidores Model Context Protocol |
| `aidev lessons index` | **(v3.6)** Indexa lições para busca cross-project |
| `aidev lessons search`| **(v3.6)** Busca soluções similares no Knowledge Base |
| `aidev triggers list` | **(v3.6)** Lista gatilhos proativos ativos |
| `aidev triggers status`| **(v3.6)** Status do motor de automação |
| `aidev start` | Mostra instrucoes de ativacao |
| `aidev upgrade` | Atualiza para versao mais recente |
| `aidev roadmap` | **(v3.7)** Dashboard de progresso e gestão de Sprints |
| `aidev feature` | **(v3.7)** Gestão do ciclo de vida de funcionalidades |
| `aidev status` | Dashboard de progresso e contexto Git |
| `aidev doctor` | Diagnostico de saude do ambiente |
| `aidev doctor --fix` | **Auto-Cura**: Repara problemas detectados |
| `aidev snapshot` | Gera resumo de contexto para migracao de IA |
| `aidev add-skill` | Adiciona skill customizada |
| `aidev add-agent` | Adiciona agente customizado |
| `aidev self-upgrade` | Atualiza o CLI global (opcional `--force`) |
| `aidev system` | **(v3.8.1)** Gestão global (status, deploy, link, rollback) |

### Ativacao do Modo Agente

```bash
# Opcao 1: Gerar prompt e copiar
aidev agent | pbcopy   # macOS
aidev agent | xclip    # Linux

# Opcao 2: Dizer para a IA
"modo agente" | "aidev" | "superpowers"
```

### Opções Globais

| Opção | Descrição |
|-------|-----------|
| `--install-in <path>` | Especifica diretório de instalação |
| `--stack <nome>` | Força stack (laravel, node, python, etc.) |
| `--platform <nome>` | Força plataforma (claude-code, gemini) |
| `--force` | Sobrescreve arquivos existentes |
| `--dry-run` | Mostra o que seria feito sem executar |
| `--no-mcp` | Não configura MCP |
| `--debug` | Modo debug com mais informações |

## Agentes

| Agente | Responsabilidade |
|--------|------------------|
| **Orchestrator** | Coordena agentes, distribui tarefas, consolida resultados |
| **Architect** | Design, estrutura de codigo, padroes arquiteturais |
| **Backend** | Implementacao server-side com TDD obrigatorio |
| **Frontend** | Componentes UI, estado, integracao com APIs |
| **Code Reviewer** | Revisao de qualidade, padroes, boas praticas |
| **QA** | Testes abrangentes, validacao de edge cases |
| **DevOps** | CI/CD, infraestrutura, automacao de deploy |
| **Legacy Analyzer** | Analise de codigo legado, refactoring |
| **Security Guardian** | Seguranca, vulnerabilidades, OWASP |

## Skills

| Skill | Quando Usar |
|-------|-------------|
| **Brainstorming** | Nova feature ou projeto - refina ideias antes de implementar |
| **Writing Plans** | Criar plano de implementacao com tarefas de 2-5 minutos |
| **Test-Driven Development** | Implementar codigo com ciclo RED-GREEN-REFACTOR |
| **Code Review** | Revisar PR ou codigo antes de merge |
| **Systematic Debugging** | Investigar bugs com processo de 4 fases |
| **Learned Lesson** | Documentar aprendizados e evitar repeticao de erros |

## Configuração

### Arquivo .aidev.yaml

Crie um arquivo `.aidev.yaml` na raiz do projeto para customizações:

```yaml
# Configurações do projeto
mode: full          # full, minimal, custom
language: pt-br     # pt-br, en

# Plataforma
platform:
  name: claude-code  # claude-code, gemini, cursor
  enabled: true

# Skills ativas
skills:
  - brainstorming
  - tdd
  - systematic-debugging
  - writing-plans

# Agentes ativos
agents:
  - orchestrator
  - architect
  - backend
  - frontend
  - qa

# Regras customizadas
rules:
  tdd: mandatory
  documentation: required

# Segredos (Gerenciados via .env, não via YAML)
# Crie um arquivo .env na raiz:
# CONTEXT7_API_KEY=sua_chave_aqui
```

## Gestão de Segredos

O AI Dev utiliza um arquivo `.env` para gerenciar chaves de API e tokens sensíveis de forma segura:

1.  O arquivo `.env` é automaticamente ignorado pelo Git.
2.  Tokens são injetados dinamicamente nas configurações de MCP.
3.  Para o **Context7**, obtenha sua chave em [context7.com/dashboard](https://context7.com/dashboard).

## MCP (Model Context Protocol)

O AI Dev configura automaticamente servidores MCP:

- **context7**: Documentação técnica atualizada
- **serena**: Navegação e análise de símbolos de código
- **basic-memory**: Memória de longo prazo para projetos

O arquivo de configuração MCP é gerado dinamicamente para cada plataforma (ex: `.aidev/mcp/antigravity-config.json`).

## Documentação Completa

- [Guia Técnico dos Agentes](docs/AGENTS-TECHNICAL-GUIDE.md)
- [Guia de Customização](docs/CUSTOMIZACAO.md)
- [Criando Skills](docs/CRIANDO-SKILLS.md)
- [Criando Agentes](docs/CRIANDO-AGENTES.md)
- [Changelog](CHANGELOG.md)

## Testes

```bash
# Executar todos os testes
./tests/test-runner.sh

# Executar apenas unitários
./tests/test-runner.sh tests/unit/test-*.sh

# Executar integração
./tests/test-runner.sh tests/integration/test-*.sh

# Executar E2E
./tests/test-runner.sh tests/e2e/test-*.sh
```

**Status atual:** 122/122 testes passando Sim

## Stacks Suportadas

| Stack | Auto-detectado | Regras |
|-------|----------------|--------|
| Laravel | Sim `composer.json` | Sim |
| Express | Sim `package.json` | Sim |
| Python | Sim `requirements.txt` | Sim |
| Genérico | - | Sim |

## Contribuindo

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/minha-feature`
3. Commit suas mudanças: `git commit -m 'feat: minha feature'`
4. Push: `git push origin feature/minha-feature`
5. Abra um Pull Request

## Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

---

Feito com dedicacao para a comunidade de desenvolvedores.
