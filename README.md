# 🚀 AI Dev Superpowers V3

> Transforme qualquer IA de código em um desenvolvedor sênior com práticas TDD e padrões profissionais.

[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)]()
[![Tests](https://img.shields.io/badge/tests-122%20passing-green.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

## 📋 O que é?

AI Dev Superpowers é um framework que configura **agentes especializados**, **skills** e **regras** para guiar IAs de código (Claude Code, Gemini, Cursor, etc.) a trabalharem com:

- ✅ **TDD Mandatório** - RED → GREEN → REFACTOR
- ✅ **YAGNI** - Só implemente o necessário
- ✅ **DRY** - Não repita código
- ✅ **Evidências** - Prove que funciona, não apenas afirme

## 🎯 Instalação

### Método 1: One-Liner (Recomendado) ⚡
Ideal para quem busca rapidez e configuração automática de PATH.
```bash
curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash
```

### Método 2: Manual (Expert) 🛠️
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

## ⚡ Novidades da V3.1
Esta versão introduz a **Fase 4: Automação e Inteligência**, focada em proatividade e economia de tokens.

### 🧠 Knowledge Base Engine (Lições Aprendidas)
O framework agora possui uma **Memória Semântica**. Erros corrigidos uma vez são memorizados local e globalmente via MCP, evitando que a IA repita os mesmos erros e economizando milhares de tokens.

### 🏥 Auto-Cura Proativa (Self-Healing)
O comando `aidev doctor --fix` agora detecta falhas de ambiente, permissões ou infraestrutura e sugere reparos automáticos. O CLI intercepta erros comuns e te orienta proativamente.

### 🛰️ Context Snapshotter
Use `aidev snapshot` ao final de uma sessão para gerar um "Passaporte de Contexto". Cole esse snapshot em qualquer novo chat de IA (Claude, Gemini, Antigravity) para continuidade instantânea sem perda de foco.

## 📁 O que é instalado?

```
seu-projeto/
├── .aidev/
│   ├── agents/           # 8 agentes especializados
│   │   ├── orchestrator.md
│   │   ├── architect.md
│   │   ├── backend.md
│   │   ├── frontend.md
│   │   ├── qa.md
│   │   ├── devops.md
│   │   ├── legacy-analyzer.md
│   │   └── security-guardian.md
│   │
│   ├── skills/           # 4 skills guiadas
│   │   ├── brainstorming/
│   │   ├── writing-plans/
│   │   ├── test-driven-development/
│   │   └── systematic-debugging/
│   │
│   ├── rules/            # Regras da stack
│   │   ├── generic.md
│   │   └── [sua-stack].md
│   │
│   └── state/            # Estado persistente (sessão)
│
├── .gitignore            # Configurado para ignorar estado local
└── .mcp.json             # Configuração MCP global (se aplicável)
```

## 🛠️ Comandos CLI

| Comando | Descrição |
|---------|-----------|
| `aidev init` | Inicializa AI Dev no projeto |
| `aidev upgrade` | Atualiza para versão mais recente |
| `aidev status` | Dashboard de progresso e contexto Git |
| `aidev doctor` | Diagnóstico de saúde do ambiente |
| `aidev doctor --fix` | **Auto-Cura**: Tenta reparar problemas detectados |
| `aidev snapshot` | Gera um resumo de contexto para migração de IA |
| `aidev add-skill <nome>` | Adiciona skill customizada |
| `aidev add-agent <nome>` | Adiciona agente customizado |

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

## 🤖 Agentes

### Orchestrator (Coordenador)
Coordena o trabalho entre agentes, distribui tarefas e consolida resultados.

### Architect (Arquiteto)
Decisões de design, estrutura de código e padrões arquiteturais.

### Backend
Implementação server-side com TDD obrigatório.

### Frontend
Componentes UI, estado e integração com APIs.

### QA
Qualidade, testes abrangentes e validação de edge cases.

### DevOps
CI/CD, infraestrutura e automação de deploy.

### Legacy Analyzer
Análise de código legado, refactoring e modernização.

### Security Guardian
Revisão de segurança, vulnerabilidades e compliance.

## 📚 Skills

### Brainstorming
Refinamento de ideias através de perguntas antes de implementar.

### Writing Plans
Criação de planos detalhados com tarefas de 2-5 minutos.

### Test-Driven Development
Ciclo RED-GREEN-REFACTOR com validação obrigatória.

### Systematic Debugging
Processo de 4 fases para encontrar a causa raiz de bugs.

## ⚙️ Configuração

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

## 🔐 Gestão de Segredos

O AI Dev utiliza um arquivo `.env` para gerenciar chaves de API e tokens sensíveis de forma segura:

1.  O arquivo `.env` é automaticamente ignorado pelo Git.
2.  Tokens são injetados dinamicamente nas configurações de MCP.
3.  Para o **Context7**, obtenha sua chave em [context7.com/dashboard](https://context7.com/dashboard).

## 🔌 MCP (Model Context Protocol)

O AI Dev configura automaticamente servidores MCP:

- **context7**: Documentação técnica atualizada
- **serena**: Navegação e análise de símbolos de código
- **basic-memory**: Memória de longo prazo para projetos

O arquivo de configuração MCP é gerado dinamicamente para cada plataforma (ex: `.aidev/mcp/antigravity-config.json`).

## 📖 Documentação Completa

- [Guia de Customização](docs/CUSTOMIZACAO.md)
- [Criando Skills](docs/CRIANDO-SKILLS.md)
- [Criando Agentes](docs/CRIANDO-AGENTES.md)
- [Changelog](CHANGELOG.md)

## 🧪 Testes

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

**Status atual:** 122/122 testes passando ✅

## 📦 Stacks Suportadas

| Stack | Auto-detectado | Regras |
|-------|----------------|--------|
| Laravel | ✅ `composer.json` | ✅ |
| Express | ✅ `package.json` | ✅ |
| Python | ✅ `requirements.txt` | ✅ |
| Genérico | - | ✅ |

## 🤝 Contribuindo

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/minha-feature`
3. Commit suas mudanças: `git commit -m 'feat: minha feature'`
4. Push: `git push origin feature/minha-feature`
5. Abra um Pull Request

## 📜 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

---

Feito com ❤️ para a comunidade de desenvolvedores.
