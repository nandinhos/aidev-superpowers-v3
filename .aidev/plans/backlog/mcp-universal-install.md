# Plano de Investigação e Ajuste de Configurações LLM

Este plano visa corrigir o erro de conexão do Laravel Boost no Gemini CLI e documentar os locais de configuração de cada ferramenta solicitada.

## 1. Diagnóstico do Laravel Boost (Gemini CLI)

O erro `MCP error -32000: Connection closed` no Gemini CLI geralmente ocorre porque o script de ponte para o MCP não consegue estabelecer uma comunicação estável com o container Docker ou o comando termina prematuramente.

### Problemas Identificados em `scripts/boost-mcp.sh`:
1. **Nome do Container Estático**: O script usa `gacpac-ti-laravel.test-1`. Se o Docker Compose usar um prefixo diferente (baseado no nome da pasta ou projeto), o comando falha.
2. **Uso de `-i` sem `-T`**: Para servidores MCP via `docker exec`, o parâmetro `-T` (desabilitar pseudo-terminal) é essencial para evitar que caracteres de controle de terminal interfiram no protocolo JSON-RPC do MCP.
3. **Recomendação**: Utilizar `docker compose exec -T laravel.test` que é mais resiliente e segue as memórias do projeto.

## 2. Localização das Configurações

Abaixo estão os caminhos dos arquivos de configuração para cada ferramenta:

### Gemini CLI
- **Global/Projeto**: `.gemini/settings.json` (Raiz)
- **Backend Específico**: `backend/.gemini/settings.json`
- **Servidores MCP**: `.mcp.json` (Raiz e Backend - frequentemente ignorados por ferramentas de leitura se estiverem no .gitignore, mas usados internamente pelo CLI).

### Claude Code CLI
- **Local**: `.claude/settings.local.json`
- **Global (Linux)**: `~/.claude/config.json` (Geralmente armazena preferências globais).

### Antigravity
- **Principal**: `.aidev/mcp/antigravity-config.json`
- **Configurações Adicionais**: `.aidev/mcp/` (Contém outros arquivos como `gemini-config.json`).

### Opencode
- **Projeto**: `opencode.json` (Se existir na raiz, usado para identificar o ambiente).
- **Global**: `~/.opencode/config.json` (Baseado na instalação via curl e documentação do Boost).

## 3. Ações Propostas

### Passo 1: Corrigir `scripts/boost-mcp.sh`
Alterar a lógica de execução para usar `docker compose exec -T`.

```bash
# De:
docker exec -i "$CONTAINER_NAME" php artisan boost:mcp "$@"

# Para:
docker compose exec -T laravel.test php artisan boost:mcp "$@"
```

### Passo 2: Validar o Servidor MCP no Gemini
Reiniciar o Gemini CLI após a alteração para forçar o rediscovery do `laravel-boost`.

### Passo 3: Mapeamento Visual
Apresentar ao usuário a lista consolidada de arquivos para facilitar futuras edições.



# Especificação Técnica: Sistema Universal de Configuração de MCP (Laravel Boost)

Este documento descreve a arquitetura e o fluxo de implementação de um sistema automatizado para configurar o MCP `laravel-boost` em múltiplos ambientes de LLM (Gemini, Claude, Antigravity, Opencode). O objetivo é criar uma solução portável que possa ser integrada a qualquer orquestrador ou projeto Laravel.

## 1. Visão Geral
O sistema deve abstrair a complexidade da configuração do ambiente (Docker, nomes de containers, caminhos de sistema) e fornecer uma interface unificada para habilitar o MCP em diferentes ferramentas de IA.

### 1.1. Componentes Principais
1.  **Core Discovery:** Responsável por identificar o ambiente de execução (Host vs Docker) e os parâmetros dinâmicos (Container ID, Portas).
2.  **Health Check:** Valida se o MCP está respondendo corretamente antes de tentar configurar os clientes.
3.  **Adapters (Adaptadores):** Módulos específicos para cada LLM que sabem ler/escrever seus respectivos arquivos de configuração.
4.  **Unified CLI:** Interface única para o usuário (ex: `setup:mcp`).

---

## 2. Fase 1: Fundação (Core Discovery & Validation)

### 2.1. Script de Descoberta (`scripts/core/mcp-discovery.sh`)
Deve ser capaz de operar em dois modos:
*   **Modo Host:** Detecta se o Docker está rodando e qual container corresponde ao serviço `laravel.test` (ou nome configurável).
*   **Modo Container:** Detecta se já está rodando dentro do container e retorna os caminhos internos.

**Lógica de Detecção de Container:**
1.  Listar containers ativos com `docker compose ps --format json`.
2.  Filtrar pelo serviço alvo (ex: `laravel.test`).
3.  Retornar o **Nome do Container** (para uso em `docker exec`) e o **Status**.

### 2.2. Script de Health Check (`scripts/core/mcp-health.sh`)
Deve executar um "smoke test" no MCP:
1.  Executar comando MCP básico (ex: `list_tools`) via `docker exec`.
2.  Validar se a saída é um JSON válido.
3.  Verificar pré-requisitos: PHP instalado, Composer vendor presente, extensão `laravel-boost` instalada.

---

## 3. Fase 2: Estratégia por LLM (Sprints)

### 3.1. Gemini CLI
*   **Arquivo de Configuração:** `.gemini/settings.json` e `.mcp.json`.
*   **Estratégia:**
    *   Gerar `.mcp.json` dinamicamente com o caminho absoluto do script de ponte (`boost-mcp.sh`).
    *   O script de ponte deve usar o **Nome do Container** descoberto na Fase 1.

### 3.2. Claude Code CLI
*   **Arquivo de Configuração:** `~/.claude/config.json` (Global) ou `.claude/config.json` (Local).
*   **Estratégia:**
    *   Ler o JSON existente.
    *   Adicionar/Atualizar a chave `mcpServers.laravel-boost`.
    *   Garantir que o comando apontado seja executável.

### 3.3. Antigravity (AIDev)
*   **Arquivo de Configuração:** `.aidev/mcp/antigravity-config.json`.
*   **Estratégia:**
    *   Injetar configuração no array `mcpServers`.
    *   Suportar variáveis de ambiente para chaves de API se necessário.

### 3.4. Opencode
*   **Arquivo de Configuração:** `opencode.json` ou `~/.opencode/config.json`.
*   **Estratégia:**
    *   Validar schema específico do Opencode.
    *   Configurar ambiente de execução (Docker vs Local).

---

## 4. Fluxo de Execução (Pipeline)

1.  **Início:** Usuário executa `setup:mcp`.
2.  **Verificação de Ambiente:**
    *   Docker está rodando? -> Se não, tentar iniciar ou falhar.
    *   `laravel-boost` está no composer.json? -> Se não, sugerir instalação.
3.  **Descoberta:**
    *   Identificar nome do container: `my-project-laravel.test-1`.
4.  **Seleção de Alvos:**
    *   Detectar quais CLI estão instalados (Gemini, Claude, etc.).
    *   Perguntar ao usuário quais configurar.
5.  **Configuração:**
    *   Para cada alvo selecionado, chamar o **Adaptador** correspondente.
    *   O Adaptador gera/atualiza o JSON de configuração.
6.  **Validação Final:**
    *   Tentar conectar ao MCP configurado em cada ferramenta (se possível) ou exibir instruções de teste manual.

## 5. Requisitos Técnicos
- **Linguagem:** Bash (para portabilidade máxima) ou PHP (para integração nativa com Laravel/Artisan).
- **Dependências:** `jq` (para manipulação de JSON em shell scripts) ou funções PHP nativas `json_decode/encode`.

---
**Nota:** Este plano deve ser adaptado conforme as particularidades do orquestrador onde será implementado.
