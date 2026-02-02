# AI Dev Superpowers V3

> Transforme qualquer IA de codigo em um desenvolvedor senior com praticas TDD e padroes profissionais.

[![Version](https://img.shields.io/badge/version-3.1.0-blue.svg)]()
[![Tests](https://img.shields.io/badge/tests-122%20passing-green.svg)]()
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

## Novidades da V3.1

### Ativacao Rapida com QUICKSTART.md
Reducao de 20+ arquivos para 1 arquivo. Ao dizer "modo agente", a IA le apenas `.aidev/QUICKSTART.md` que contem tudo consolidado:
- Principios (TDD, YAGNI, DRY)
- Tabela de classificacao de intent
- Skills e agentes disponiveis
- Regras de commit

### Regras de Commit em Portugues
Commits agora seguem padrao obrigatorio:
- Idioma: **PORTUGUES**
- Emojis: **PROIBIDOS**
- Co-autoria: **PROIBIDA**

```
tipo(escopo): descricao em portugues
```

### Knowledge Base Engine (Licoes Aprendidas)
O framework possui **Memoria Semantica**. Erros corrigidos sao memorizados via MCP, evitando repeticao.

### Auto-Cura Proativa
O comando `aidev doctor --fix` detecta e repara problemas de ambiente automaticamente.

### Context Snapshotter
Use `aidev snapshot` para gerar um "Passaporte de Contexto" e continuar em outro chat.

## O que e instalado?

```
seu-projeto/
├── .aidev/
│   ├── QUICKSTART.md     # Arquivo consolidado para ativacao rapida
│   │
│   ├── agents/           # 9 agentes especializados
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
│   ├── rules/            # Regras da stack
│   │   ├── generic.md    # Inclui regras de commit em portugues
│   │   └── [sua-stack].md
│   │
│   └── state/            # Estado persistente (sessao)
│
├── CLAUDE.md             # Instrucoes para Claude Code
└── .mcp.json             # Configuracao MCP (se aplicavel)
```

## Comandos CLI

| Comando | Descricao |
|---------|-----------|
| `aidev init` | Inicializa AI Dev no projeto |
| `aidev agent` | Gera prompt de ativacao do modo agente |
| `aidev start` | Mostra instrucoes de ativacao |
| `aidev upgrade` | Atualiza para versao mais recente |
| `aidev status` | Dashboard de progresso e contexto Git |
| `aidev doctor` | Diagnostico de saude do ambiente |
| `aidev doctor --fix` | **Auto-Cura**: Repara problemas detectados |
| `aidev snapshot` | Gera resumo de contexto para migracao de IA |
| `aidev add-skill <nome>` | Adiciona skill customizada |
| `aidev add-agent <nome>` | Adiciona agente customizado |

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
