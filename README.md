# AI Dev Superpowers V3

> 🚀 Sistema modular e reutilizável de superpoderes para desenvolvimento com IA

## Visão Geral

AI Dev Superpowers V3 é uma versão consolidada do orquestrador de desenvolvimento, separando código reutilizável de código específico de projeto.

## Estrutura

```
aidev-superpowers-v3/
├── bin/          # CLI executáveis (aidev)
├── lib/          # Módulos core (core.sh, file-ops.sh, etc.)
├── templates/    # Templates .tmpl parametrizáveis
│   ├── agents/   # Templates de agentes
│   ├── skills/   # Templates de skills
│   ├── rules/    # Templates de regras
│   ├── workflows/# Templates de workflows
│   ├── config/   # Templates de configuração
│   └── mcp/      # Templates MCP
├── engines/      # Engines de processamento
├── config/       # Configurações padrão
├── docs/         # Documentação
└── tests/        # Suite de testes
    ├── unit/
    ├── integration/
    └── e2e/
```

## Instalação

```bash
# Via curl (após release)
curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash

# Ou clone manual
git clone https://github.com/nandinhos/aidev-superpowers-v3.git
cd aidev-superpowers-v3
./install.sh
```

## Uso

```bash
# Inicializar em um projeto
aidev init --stack laravel --language pt-BR

# Verificar status
aidev status

# Diagnóstico
aidev doctor
```

## Desenvolvimento

Veja [TODO-CONSOLIDACAO-V3.md](./TODO-CONSOLIDACAO-V3.md) para o plano de desenvolvimento.

## Licença

MIT License - veja [LICENSE](./LICENSE) para detalhes.
