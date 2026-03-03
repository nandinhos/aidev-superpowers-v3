# AI Dev Superpowers V3

> Transforme qualquer IA de código em um desenvolvedor sênior com práticas TDD e padrões profissionais.

[![Version](https://img.shields.io/badge/version-4.8.0-blue.svg)]()
[![Tests](https://img.shields.io/badge/tests-412%20passing-green.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

## O que é?

AI Dev Superpowers é um framework que configura **agentes especializados**, **skills** e **regras** para guiar IAs de código (Claude Code, Antigravity, Gemini, Cursor, etc.) a trabalharem com:

- **TDD Mandatório** — RED → GREEN → REFACTOR
- **YAGNI** — Só implemente o necessário
- **DRY** — Não repita código
- **Evidências** — Prove que funciona, não apenas afirme

---

## Instalação

### Método 1: One-Liner (Recomendado)

```bash
curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash
```

### Método 2: Manual

```bash
git clone https://github.com/nandinhos/aidev-superpowers-v3.git
export PATH="$PATH:$(pwd)/aidev-superpowers-v3/bin"
cd seu-projeto
aidev init
```

---

## 🚀 Novidades da v4.8.0 — Fluxo Fluido de Ideias

### Brainstorm integrado ao ciclo de vida

O fluxo ganhou dois novos passos para evitar features mal definidas chegando ao código:

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
- **Gate de proteção**: `aidev start` bloqueia se a feature ainda está em `brainstorm/` ou `backlog/`, orientando o próximo comando.
- **Regra de sessão**: verificar `current/` ao iniciar qualquer sessão. Se houver feature ativa, retomar antes de qualquer outra tarefa.
- **Novos triggers**: palavras `"backlog"` e `"brainstorm"` ativam o modo agente em todos os runtimes.
- **`rules/INDEX.md`**: índice leve com referência rápida às 6 regras inegociáveis.
- **`_flc_cleanup_checkpoints()`**: mantém apenas os últimos 5 checkpoints JSON automaticamente.

---

## Ciclo de Vida de Features

```
┌──────────┐    ┌────────────┐    ┌──────────┐    ┌─────────┐    ┌─────────────────┐
│ backlog/ │───▶│ brainstorm/│───▶│features/ │───▶│current/ │───▶│ history/YYYY-MM/│
│  ideia   │    │ exploração │    │ planejada│    │executando│    │   concluída     │
└──────────┘    └────────────┘    └──────────┘    └─────────┘    └─────────────────┘
```

**Regra inegociável:** nunca mova arquivos manualmente. Use sempre os comandos CLI.

---

## O que é instalado?

```
seu-projeto/
├── .aidev/
│   ├── QUICKSTART.md         # Ativação rápida do modo agente
│   │
│   ├── plans/                # Ciclo de vida de features
│   │   ├── ROADMAP.md        # Roadmap mestre (gerado automaticamente)
│   │   ├── backlog/          # Ideias brutas (aidev plan)
│   │   ├── brainstorm/       # Exploração de ideias (aidev brainstorm)
│   │   ├── features/         # Features planejadas (aidev create-feature)
│   │   ├── current/          # Feature em execução (aidev start)
│   │   └── history/          # Features concluídas (aidev complete)
│   │
│   ├── agents/               # 12 agentes especializados
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
│   ├── skills/               # 7 skills guiadas
│   │   ├── brainstorming/
│   │   ├── writing-plans/
│   │   ├── test-driven-development/
│   │   ├── code-review/
│   │   ├── systematic-debugging/
│   │   ├── learned-lesson/
│   │   └── lesson-curation/
│   │
│   ├── rules/                # Regras do framework
│   │   ├── INDEX.md          # Índice de regras (v4.8.0)
│   │   ├── generic.md        # Regras universais
│   │   └── {stack}.md        # Regras por stack
│   │
│   ├── lib/                  # Scripts de automação
│   └── state/                # Estado persistente entre sessões
│
├── CLAUDE.md                 # Instruções para Claude Code
└── .mcp.json                 # Configuração MCP
```

---

## Comandos CLI

### Ciclo de vida de features

| Comando | Descrição |
|---------|-----------|
| `aidev plan <titulo>` | Registra ideia bruta em `backlog/` |
| `aidev brainstorm <id>` | **(v4.8)** Explora ideia → `brainstorm/` |
| `aidev create-feature <id>` | **(v4.8)** Promove brainstorm → `features/` |
| `aidev refine <id>` | Refina item do backlog diretamente para `features/` |
| `aidev start <feature-id>` | Move feature para `current/` e inicia execução |
| `aidev done <sprint-id>` | Conclui sprint e atualiza `current/README.md` |
| `aidev complete <feature-id>` | Arquiva feature em `history/YYYY-MM/` |

### Modo agente e ativação

| Comando | Descrição |
|---------|-----------|
| `aidev agent` | Ativa modo agente completo |
| `aidev validate` | Valida conformidade do sistema |
| `aidev sync` | Sincroniza snapshot de ativação |
| `aidev commit "msg"` | Commit com detecção automática de tipo |
| `aidev cp "msg"` | Commit + Push |
| `aidev release patch\|minor\|major` | Automatiza ciclo de release |

### Diagnóstico e manutenção

| Comando | Descrição |
|---------|-----------|
| `aidev status` | Dashboard de progresso e contexto Git |
| `aidev doctor` | Diagnóstico de saúde do ambiente |
| `aidev doctor --fix` | Auto-cura: repara problemas detectados |
| `aidev self-upgrade` | Atualiza o CLI global |
| `aidev system status` | Verifica estado da instalação global |
| `aidev system deploy` | Atualiza sistema com auto-backup |
| `aidev system sync` | Sincroniza desenvolvimento com instalação global |
| `aidev system rollback` | Reverte para último backup estável |

### MCP e configuração

| Comando | Descrição |
|---------|-----------|
| `aidev mcp status` | Status de todos os MCPs |
| `aidev mcp generate` | Gera `.mcp.json` automaticamente |
| `aidev mcp health` | Health check completo |
| `aidev mcp doctor` | Diagnóstico + sugestões |
| `aidev config language <lang>` | Troca idioma do CLI (pt-br, en) |

### Conhecimento e aprendizado

| Comando | Descrição |
|---------|-----------|
| `aidev lessons index` | Indexa lições para busca cross-project |
| `aidev lessons search` | Busca soluções no Knowledge Base |
| `aidev snapshot` | Gera passaporte de contexto para troca de IA |

### Ativação do modo agente

```bash
# Via terminal
aidev agent | xclip    # Linux
aidev agent | pbcopy   # macOS

# Via chat com a IA
"modo agente" | "aidev" | "superpowers" | "brainstorm" | "backlog"
```

---

## Agentes

| Agente | Responsabilidade |
|--------|-----------------|
| **Orchestrator** | Coordena agentes, classifica intent, distribui tarefas |
| **Architect** | Design, estrutura de código, padrões arquiteturais |
| **Backend** | Implementação server-side com TDD obrigatório |
| **Frontend** | Componentes UI, estado, integração com APIs |
| **Code Reviewer** | Revisão de qualidade, padrões, boas práticas |
| **QA** | Testes abrangentes, validação de edge cases |
| **DevOps** | CI/CD, infraestrutura, automação de deploy |
| **Legacy Analyzer** | Análise de código legado, refactoring seguro |
| **Security Guardian** | Segurança, vulnerabilidades, OWASP |

---

## Skills

| Skill | Quando Usar |
|-------|-------------|
| **Brainstorming** | Explorar ideia antes de criar o plano formal |
| **Writing Plans** | Criar plano de implementação com sprints definidos |
| **Test-Driven Development** | Implementar código com ciclo RED→GREEN→REFACTOR |
| **Code Review** | Revisar PR ou código antes de merge |
| **Systematic Debugging** | Investigar bugs com processo de 4 fases |
| **Learned Lesson** | Documentar aprendizados e evitar recorrência |
| **Lesson Curation** | Validar lições antes de promovê-las a regras oficiais |

---

## Configuração

```yaml
# .aidev.yaml na raiz do projeto
mode: full          # full, minimal, custom
language: pt-br     # pt-br, en

platform:
  name: claude-code  # claude-code, gemini, cursor, antigravity

skills:
  - brainstorming
  - tdd
  - systematic-debugging
  - writing-plans

agents:
  - orchestrator
  - architect
  - backend
  - frontend
  - qa

rules:
  tdd: mandatory
  documentation: required

# Chaves de API: use .env na raiz (ignorado pelo git)
# CONTEXT7_API_KEY=sua_chave_aqui
```

---

## MCPs Suportados

O AI Dev configura automaticamente servidores MCP com fallback automático:

| MCP | Função | Fallback |
|-----|--------|---------|
| **context7** | Documentação técnica atualizada | `ripgrep` |
| **serena** | Navegação e análise de símbolos | `find . -name` |
| **basic-memory** | Memória de longo prazo | `.aidev/memory/kb/` |

---

## Stacks Suportadas

| Stack | Detecção automática | Regras específicas |
|-------|--------------------|--------------------|
| Laravel | `composer.json` | Sim |
| Express/Node | `package.json` | Sim |
| Python | `requirements.txt` | Sim |
| Rust | `Cargo.toml` | Sim |
| Go | `go.mod` | Sim |
| Genérico | — | Sim |

---

## Histórico de versões

| Versão | Destaque |
|--------|---------|
| **v4.8.0** | Fluxo fluido de ideias: brainstorm integrado ao lifecycle (5 passos) |
| **v4.7.1** | Retroalimentação de templates: lições viram regras automaticamente |
| **v4.7.0** | Sistema MCP padronizado com fallback automático |
| **v4.6.0** | Ativação ultra-rápida (~70% menos tokens via snapshot) |
| **v4.5.0** | Sistema de atualização interativa e self-upgrade |
| **v4.0.0** | Orquestração por estado ubíquo e handoff entre LLMs |
| **v3.8.0** | System Management: deploy, link, rollback da instalação global |
| **v3.7.0** | Metodologia Roadmap & Sprints (SGAITI) |
| **v3.6.0** | Memory Sync cross-project e automação de triggers |
| **v3.5.0** | Cache de ativação (até 96% menos tokens) |

Ver [CHANGELOG.md](CHANGELOG.md) para histórico completo.

---

## Documentação

- [Changelog completo](CHANGELOG.md)
- [Guia Técnico dos Agentes](docs/AGENTS-TECHNICAL-GUIDE.md)
- [Guia de Customização](docs/CUSTOMIZACAO.md)
- [Criando Skills](docs/CRIANDO-SKILLS.md)
- [Criando Agentes](docs/CRIANDO-AGENTES.md)

---

## Testes

```bash
./tests/test-runner.sh                          # Todos os testes
./tests/test-runner.sh tests/unit/test-*.sh    # Unitários
./tests/test-runner.sh tests/integration/      # Integração
./tests/test-runner.sh tests/e2e/              # E2E
```

---

## Contribuindo

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/minha-feature`
3. Commit seguindo o padrão: `tipo(escopo): descrição em português`
4. Push e abra um Pull Request

---

## Licença

MIT License — veja [LICENSE](LICENSE) para detalhes.

---

Feito com dedicação para a comunidade de desenvolvedores.
