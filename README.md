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

## 🎯 Instalação Rápida

```bash
# Clone o repositório
git clone https://github.com/nandinhos/aidev-superpowers-v3.git

# Adicione ao PATH
export PATH="$PATH:$(pwd)/aidev-superpowers-v3/bin"

# Inicialize em seu projeto
cd seu-projeto
aidev init
```

**Pronto!** Sua IA agora tem superpoderes. 🦸

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
│   └── state/            # Estado persistente
│
└── .mcp.json             # Configuração MCP
```

## 🛠️ Comandos CLI

| Comando | Descrição |
|---------|-----------|
| `aidev init` | Inicializa AI Dev no projeto |
| `aidev init --mode minimal` | Instalação mínima |
| `aidev upgrade` | Atualiza para versão mais recente |
| `aidev status` | Mostra status da instalação |
| `aidev doctor` | Diagnóstico da instalação |
| `aidev add-skill <nome>` | Adiciona skill customizada |
| `aidev add-agent <nome>` | Adiciona agente customizado |
| `aidev add-rule <nome>` | Adiciona regra customizada |

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
```

## 🔌 MCP (Model Context Protocol)

O AI Dev configura automaticamente servidores MCP:

- **context7**: Acesso a documentação atualizada
- **serena**: Navegação inteligente de código

O arquivo `.mcp.json` é gerado automaticamente no `aidev init`.

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
