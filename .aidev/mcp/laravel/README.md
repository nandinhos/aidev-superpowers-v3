# MCP Laravel Docker - Documentação

Sistema de configuração automática do MCP Laravel Boost para containers Docker.

## Visão Geral

Este sistema resolve o problema de configuração manual do caminho do container no MCP Laravel Boost. Ele detecta automaticamente containers Laravel, valida sua saúde, instala o Laravel Boost quando necessário e configura o MCP dinamicamente.

## Arquitetura

```
Docker Events → Discovery → Health Check → Install Boost → Config MCP → Hot Reload
     ↓              ↓            ↓              ↓              ↓            ↓
  Container    Detecta      Valida      Instala se      Gera JSON    Aplica sem
  Start        Laravel      Prontidão   necessário      Config       restart IDE
```

## Instalação

### Requisitos

- Docker instalado e rodando
- jq (`apt-get install jq` ou `brew install jq`)
- Bash 4.0+

### Setup

```bash
# Clone ou copie o projeto
git clone <repo>
cd aidev-superpowers-v3-1

# Verificar instalação
./aidev-mcp-laravel doctor
```

## Uso

### Comandos Principais

#### 1. Detectar Containers

```bash
./aidev-mcp-laravel detect
```

Detecta automaticamente todos containers Laravel rodando no Docker.

**Saída:**
```
✓  Encontrados 2 container(s) Laravel:
  my-app-php | PHP 8.2 | Laravel 10.x | running
  api-service | PHP 8.3 | Laravel 11.x | running
```

#### 2. Configurar MCP

**Modo Interativo (recomendado para primeiro uso):**
```bash
./aidev-mcp-laravel setup
```

**Configurar todos containers automaticamente:**
```bash
./aidev-mcp-laravel setup --auto
```

**Configurar container específico:**
```bash
./aidev-mcp-laravel setup my-app-php
```

#### 3. Monitorar Containers

**Iniciar monitoramento automático:**
```bash
./aidev-mcp-laravel watch start
```

Quando um novo container Laravel iniciar, o sistema configurará automaticamente o MCP.

**Ver logs do monitoramento:**
```bash
./aidev-mcp-laravel watch logs
```

**Parar monitoramento:**
```bash
./aidev-mcp-laravel watch stop
```

#### 4. Ver Status

```bash
./aidev-mcp-laravel status
```

Mostra:
- Status do Events Watcher
- Containers detectados
- Projetos registrados
- Configurações MCP

#### 5. Gerenciar Configurações

```bash
# Ver configs
./aidev-mcp-laravel config view

# Aplicar hot-reload
./aidev-mcp-laravel config reload

# Validar configs
./aidev-mcp-laravel config validate

# Backup
./aidev-mcp-laravel config backup
```

#### 6. Diagnóstico

```bash
./aidev-mcp-laravel doctor
```

Verifica:
- Docker disponível
- jq instalado
- Scripts presentes
- Diretórios de estado

## Estrutura de Arquivos

```
.aidev/mcp/laravel/
├── bin/
│   └── aidev-mcp-laravel          # CLI principal
├── lib/
│   ├── docker-discovery.sh        # Detecção de containers
│   ├── laravel-health-check.sh    # Validação de saúde
│   ├── mcp-config-generator.sh    # Geração de config
│   ├── docker-events.sh           # Monitor de eventos
│   ├── trigger-orchestrator.sh    # Orquestração
│   ├── mcp-hot-reload.sh          # Hot-reload MCP
│   ├── laravel-boost-installer.sh # Instalação Boost
│   ├── boost-verification.sh      # Verificação Boost
│   ├── multi-project-manager.sh   # Gerenciamento multi-projeto
│   └── artisan-detector.sh        # Detecção de artisan path e comando Boost
├── config/                        # Configurações geradas
├── state/                         # Estado persistente
│   ├── projects.json             # Registro de projetos
│   └── *.log                     # Logs
└── backups/                       # Backups de config
```

## Configuração do Docker Compose

Para melhor detecção automática, adicione labels ao seu `docker-compose.yml`:

```yaml
services:
  app:
    image: php:8.2-fpm
    container_name: my-laravel-app
    labels:
      - "aidev.laravel.enabled=true"
      - "aidev.laravel.project=my-project"
      - "aidev.laravel.php-version=8.2"
    volumes:
      - ./:/var/www/html
```

## Como Funciona

### Fluxo Automático

1. **Container Inicia**: Docker gera evento `container start`
2. **Detecção**: `docker-events.sh` captura evento e filtra containers Laravel
3. **Debounce**: Evita processamento duplicado (10s)
4. **Orquestração**: `trigger-orchestrator.sh` gerencia o fluxo
5. **Health Check**: Valida se Laravel está pronto (vendors, artisan, DB)
6. **Instalação**: Se Laravel Boost não estiver instalado, instala automaticamente
7. **Detecção**: Detecta caminho do artisan e comando Boost disponível
8. **Configuração**: Gera configuração MCP dinâmica com comando correto
9. **Hot-Reload**: Aplica configuração ao IDE (pode requerer restart dependendo do IDE)

### Estados do Orquestrador

```
IDLE → DETECTED → HEALTH_CHECKING → CONFIGURING → ACTIVE
                           ↓
                        FAILED (retry 5x)
```

## Troubleshooting

### Container não detectado

```bash
# Verificar se container está rodando
docker ps

# Verificar se é reconhecido como Laravel
./aidev-mcp-laravel detect --verbose

# Adicionar label manualmente
docker run -l aidev.laravel.enabled=true ...
```

### Health check falha

```bash
# Verificar logs detalhados
./aidev-mcp-laravel/lib/laravel-health-check.sh check <container> --verbose

# Verificar se vendor existe
docker exec <container> ls -la vendor/

# Verificar se artisan funciona
docker exec <container> php artisan --version
```

### Laravel Boost não instala

```bash
# Verificar versão do Laravel
docker exec <container> php artisan --version

# Tentar instalação manual
./aidev-mcp-laravel/lib/laravel-boost-installer.sh install <container> --verbose
```

### Configuração não aplica

```bash
# Verificar config gerada
./aidev-mcp-laravel/lib/mcp-config-generator.sh show <container>

# Validar JSON
./aidev-mcp-laravel/lib/mcp-config-generator.sh validate <file>

# Detectar cliente MCP
./aidev-mcp-laravel/lib/mcp-hot-reload.sh detect
```

### WSL2 específico

No WSL2, pode haver delays na detecção. Aumente o timeout:

```bash
# No arquivo .env ou export
export MCP_TIMEOUT=300
```

## Scripts Individuais

Todos scripts em `lib/` podem ser usados independentemente:

```bash
# Detecção
./lib/docker-discovery.sh discover
./lib/docker-discovery.sh list
./lib/docker-discovery.sh get <container>

# Health Check
./lib/laravel-health-check.sh check <container>
./lib/laravel-health-check.sh wait <container>

# Config
./lib/mcp-config-generator.sh generate <container>
./lib/mcp-config-generator.sh save <container>
./lib/mcp-config-generator.sh merge

# Events
./lib/docker-events.sh start
./lib/docker-events.sh stop
./lib/docker-events.sh logs

# Orquestração
./lib/trigger-orchestrator.sh trigger <container>
./lib/trigger-orchestrator.sh list

# Boost
./lib/laravel-boost-installer.sh install <container>
./lib/laravel-boost-installer.sh status <container>

# Artisan Detector
./lib/artisan-detector.sh detect <container>
./lib/artisan-detector.sh command <container>

# Multi-projeto
./lib/multi-project-manager.sh list
./lib/multi-project-manager.sh sync
./lib/multi-project-manager.sh combine
./lib/multi-project-manager.sh import
```

## Integração com IDEs

### Claude Desktop

Configuração é salva automaticamente em:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

Após configuração, reinicie Claude Desktop ou pressione Cmd/Ctrl+R.

### Cursor

Configuração em:
- `~/.cursor/mcp.json`

Reinicie Cursor após configuração.

### VSCode

Configuração em:
- `~/.vscode/mcp.json`

Recarregue a janela: Cmd/Ctrl+Shift+P → "Reload Window"

## Variáveis de Ambiente

```bash
# Timeout para health check (segundos)
export MCP_HEALTH_TIMEOUT=120

# Diretório de configuração MCP
export MCP_CONFIG_DIR="~/.config/mcp"

# Modo debug (mais verbose)
export MCP_DEBUG=1
```

## Roadmap

- [x] Detecção automática de containers
- [x] Health check completo
- [x] Instalação automática Laravel Boost
- [x] Multi-projeto suporte
- [x] CLI unificada
- [ ] Suporte Kubernetes
- [ ] Web UI para gerenciamento
- [ ] Integração CI/CD

## Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## Licença

MIT

---

**AI Dev Superpowers** - Configuração dinâmica de MCP Laravel para Docker
