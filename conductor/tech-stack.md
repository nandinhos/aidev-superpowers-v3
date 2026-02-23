# Tech Stack - AI Dev Superpowers V3

## Linguagens Core
- **Bash/Shell:** Linguagem principal para o orquestrador, instaladores e scripts de automação.

## Arquitetura e Frameworks
- **Arquitetura de Agentes:** Baseada em arquivos Markdown de configuração de agentes e skills.
- **Gerenciamento de Contexto:** Uso de JSON para snapshots de ativação e compressão de contexto.

## Dependências de Sistema
- **Git:** Controle de versão e base para o workflow de commits.
- **Docker:** Utilizado para integração com MCPs baseados em containers (ex: Laravel Boost).
- **Node.js (npx):** Execução de servidores MCP e ferramentas auxiliares.
- **Python (pipx/uvx):** Execução de MCPs como `basic-memory` e `serena`.
- **jq:** Processamento de dados JSON via CLI.

## Infraestrutura de IA
- **Model Context Protocol (MCP):** Protocolo padrão para conexão com ferramentas externas.
- **Basic Memory:** Persistência de conhecimento entre sessões.
