# Feature: MCP Laravel Boost Auto-Configuration

## Visão Geral
Sistema inteligente para configurar automaticamente o MCP Laravel Boost por projeto, detectando o container Docker correto e gerando a configuração no formato padrão.

## Diferença dos Outros MCPs
- **MCPs Globais** (Context7, Brave, etc.): Configurados uma vez, usados em todos projetos
- **Laravel Boost**: Específico por projeto, pois cada projeto tem seu próprio container Docker

## Padrão de Configuração

### Formato Padrão
```json
{
  "mcpServers": {
    "laravel-boost": {
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "{container_name}",
        "php",
        "{artisan_path}",
        "boost:mcp"
      ],
      "disabledTools": []
    }
  }
}
```

### Exemplos de Projetos

#### Eventos Pro
```json
"laravel-boost": {
  "command": "docker",
  "args": [
    "exec",
    "-i",
    "eventospro-laravel.test-1",
    "php",
    "/var/www/html/artisan",
    "boost:mcp"
  ]
}
```

#### Bella Beaulty
```json
"laravel-boost": {
  "command": "docker",
  "args": [
    "exec",
    "-i",
    "bellabeaulty-app",
    "php",
    "/var/www/artisan",
    "boost:mcp"
  ]
}
```

#### Cred Crud
```json
"laravel-boost": {
  "command": "docker",
  "args": [
    "exec",
    "-i",
    "cred_crud-laravel.test-1",
    "php",
    "/var/www/html/artisan",
    "mcp:start",
    "laravel-boost"
  ]
}
```

## Lógica de Funcionamento

### Fluxo Principal
```
Usuário roda: aidev mcp laravel setup

1. DETECTAR CONTAINERS
   └─→ Lista containers Docker rodando
   └─→ Filtra apenas containers Laravel (têm artisan, composer.json)

2. IDENTIFICAR PROJETO ATUAL
   └─→ Pega nome do diretório atual (ex: "spadaer")
   └─→ Busca container que contenha esse nome
   └─→ Se não encontrar, pergunta ao usuário qual usar

3. VERIFICAR CONFIGURAÇÃO EXISTENTE
   └─→ Lê ~/.config/mcp/mcp.json (ou equivalente)
   └─→ Verifica se já existe "laravel-boost" configurado
   
   SE existe AND é de outro projeto:
   ├─→ Mostra: "MCP Laravel Boost já configurado para {outro_projeto}"
   ├─→ Pergunta: "Deseja substituir para este projeto ({projeto_atual})?"
   └─→ Se sim: continua | Se não: aborta
   
   SE existe AND é do mesmo projeto:
   └─→ Mostra: "Já configurado para este projeto. Deseja recriar?"

4. DETECTAR CAMINHO DO ARTISAN
   └─→ Executa no container: find /var/www -name artisan -type f
   └─→ Ou verifica caminhos padrão: /var/www/html/artisan, /var/www/artisan
   └─→ Detecta automaticamente o caminho correto

5. DETECTAR COMANDO BOOST
   └─→ Testa: php artisan list | grep boost
   └─→ Se tiver "boost:mcp" → usa "boost:mcp"
   └─→ Se tiver "mcp:start" → usa "mcp:start laravel-boost"
   └─→ Fallback: "boost:mcp"

6. GERAR CONFIGURAÇÃO
   └─→ Cria JSON no formato padrão
   └─→ Salva em: ~/.config/mcp/mcp.json (merge com existente)
   └─→ Backup da config anterior em: ~/.config/mcp/backups/

7. VALIDAR E APLICAR
   └─→ Valida JSON gerado
   └─→ Mostra preview da configuração
   └─→ Informa que precisa reiniciar o Claude/Cursor
```

## Detecção de Container por Projeto

### Algoritmo de Matching
```bash
# 1. Pega nome do diretório atual
project_dir=$(basename "$PWD")
# Ex: "spadaer", "eventospro", "bellabeaulty"

# 2. Normaliza o nome (remove hífens, underscores, etc.)
project_normalized=$(echo "$project_dir" | tr '[:upper:]' '[:lower:]' | sed 's/[-_]//g')

# 3. Lista containers e procura match
for container in $(docker ps --format '{{.Names}}'); do
    container_normalized=$(echo "$container" | tr '[:upper:]' '[:lower:]' | sed 's/[-_.]//g')
    
    # Verifica se o nome do projeto está no nome do container
    if [[ "$container_normalized" == *"$project_normalized"* ]]; then
        echo "Match encontrado: $container"
        break
    fi
done

# 4. Se não encontrar, mostra lista para seleção
```

### Exemplos de Matching

| Diretório Projeto | Containers Detectados | Match |
|------------------|----------------------|-------|
| `~/projects/spadaer` | spadaer-laravel.test-1 | ✅ spadaer |
| `~/projects/eventospro` | eventospro-laravel.test-1 | ✅ eventospro |
| `~/projects/bellabeaulty` | bellabeaulty-app | ✅ bellabeaulty |
| `~/projects/cred_crud` | cred_crud-laravel.test-1 | ✅ credcrud (normalizado) |

## Gestão de Configurações

### Arquivo de Config MCP
```bash
# Local padrão
~/.config/mcp/mcp.json

# Ou conforme IDE
~/Library/Application Support/Claude/claude_desktop_config.json  # macOS
~/.config/Claude/claude_desktop_config.json                      # Linux
~/.cursor/mcp.json                                               # Cursor
```

### Estrutura do Arquivo
```json
{
  "mcpServers": {
    "context7": { ... },           // Global - disponível em todos projetos
    "brave-search": { ... },       // Global
    "serena": { ... },             // Global
    "laravel-boost": { ... }       // Específico do projeto atual!
  }
}
```

### Backup e Histórico
```
~/.config/mcp/
├── mcp.json                          # Config atual
├── backups/
│   ├── mcp.json.20240206.151030.bak  # Backup eventospro
│   ├── mcp.json.20240206.162145.bak  # Backup bellabeaulty
│   └── mcp.json.20240206.173022.bak  # Backup spadaer
└── projects/                         # Registro por projeto
    ├── eventospro.json
    ├── bellabeaulty.json
    └── spadaer.json
```

## Implementação

### Novo Comando: `aidev mcp laravel auto`

```bash
# Detecta e configura automaticamente para o projeto atual
aidev mcp laravel auto

# Flags
aidev mcp laravel auto --force          # Força recriação mesmo se existir
aidev mcp laravel auto --container=X    # Especifica container manualmente
aidev mcp laravel auto --dry-run        # Mostra o que seria feito
```

### Subcomandos Auxiliares

```bash
# Ver qual projeto está configurado
aidev mcp laravel current

# Listar histórico de configurações
aidev mcp laravel history

# Restaurar configuração anterior
aidev mcp laravel restore bellabeaulty

# Ver diff entre config atual e projeto atual
aidev mcp laravel diff
```

## Detecção de Artisan Path

### Algoritmo de Detecção Robusta

```bash
detect_artisan_path() {
    local container_name="$1"
    local detected_path=""
    
    log_info "Detectando caminho do artisan no container..."
    
    # Estratégia 1: Caminhos padrão conhecidos
    local common_paths=(
        "/var/www/html/artisan"      # Laravel Sail (mais comum)
        "/var/www/artisan"           # Alternativo
        "/app/artisan"               # Docker genérico
        "/srv/artisan"               # Outro padrão
        "/home/www/artisan"          # Setup custom
        "/opt/artisan"               # Instalação opt
        "/code/artisan"              # VSCode dev containers
        "/workspace/artisan"         # Gitpod/Codespaces
    )
    
    for path in "${common_paths[@]}"; do
        if docker exec "$container_name" test -f "$path" 2>/dev/null; then
            # Verifica se é realmente o artisan do Laravel
            if docker exec "$container_name" head -1 "$path" | grep -q "php"; then
                detected_path="$path"
                log_success "✓ Encontrado em caminho padrão: $path"
                break
            fi
        fi
    done
    
    # Estratégia 2: Busca recursiva se não encontrou nos padrões
    if [ -z "$detected_path" ]; then
        log_info "Buscando recursivamente em /var/www..."
        detected_path=$(docker exec "$container_name" find /var/www -name artisan -type f 2>/dev/null | head -1)
        
        if [ -n "$detected_path" ]; then
            log_success "✓ Encontrado via busca: $detected_path"
        fi
    fi
    
    # Estratégia 3: Busca em todo o sistema (mais lento, só se necessário)
    if [ -z "$detected_path" ]; then
        log_info "Buscando em todo o container..."
        detected_path=$(docker exec "$container_name" find / -name artisan -type f 2>/dev/null | grep -v "proc\|sys" | head -1)
        
        if [ -n "$detected_path" ]; then
            log_success "✓ Encontrado em: $detected_path"
        fi
    fi
    
    # Validação final
    if [ -n "$detected_path" ]; then
        # Testa se funciona
        if docker exec "$container_name" php "$detected_path" --version &>/dev/null; then
            log_success "✓ Validado: $detected_path funciona!"
            echo "$detected_path"
            return 0
        else
            log_warn "⚠ Encontrado mas não funcionou: $detected_path"
        fi
    fi
    
    # Fallback
    log_warn "⚠ Usando fallback: /var/www/html/artisan"
    echo "/var/www/html/artisan"
    return 1
}
```

### Exemplos de Caminhos Detectados

| Projeto | Container | Caminho Detectado | Método |
|---------|-----------|-------------------|--------|
| Eventos Pro | eventospro-laravel.test-1 | `/var/www/html/artisan` | Padrão #1 |
| Bella Beaulty | bellabeaulty-app | `/var/www/artisan` | Padrão #2 |
| Cred Crud | cred_crud-laravel.test-1 | `/var/www/html/artisan` | Padrão #1 |
| Spadaer | spadaer-laravel.test-1 | `/var/www/html/artisan` | Busca |
| API Custom | api-service | `/app/artisan` | Padrão #3 |

### Validação do Artisan

```bash
validate_artisan() {
    local container="$1"
    local artisan_path="$2"
    
    # Verifica se arquivo existe
    if ! docker exec "$container" test -f "$artisan_path"; then
        return 1
    fi
    
    # Verifica se é script PHP
    if ! docker exec "$container" head -1 "$artisan_path" | grep -q "<?php\|#!/usr/bin/env php"; then
        return 1
    fi
    
    # Testa execução
    if ! docker exec "$container" php "$artisan_path" --version &>/dev/null; then
        return 1
    fi
    
    return 0
}
```

## Detecção do Comando Boost

### Versões do Comando
```bash
# Verifica qual comando está disponível no artisan

# Opção 1 (mais comum)
php artisan boost:mcp

# Opção 2 (alternativa)
php artisan mcp:start laravel-boost

# Detecção
if docker exec $container php artisan list | grep -q "boost:mcp"; then
    command="boost:mcp"
elif docker exec $container php artisan list | grep -q "mcp:start"; then
    command="mcp:start laravel-boost"
else
    command="boost:mcp"  # fallback
fi
```

## Ciclo de Uso

### Cenário 1: Primeira Configuração
```bash
cd ~/projects/spadaer
aidev mcp laravel auto

# Output:
# 🔍 Detectando containers Laravel...
# ✅ Container encontrado: spadaer-laravel.test-1
# 📁 Diretório projeto: spadaer
# 🔗 Match: spadaer-laravel.test-1 contém 'spadaer'
# 
# 📝 Configuração gerada:
# {
#   "mcpServers": {
#     "laravel-boost": {
#       "command": "docker",
#       "args": ["exec", "-i", "spadaer-laravel.test-1", "php", "/var/www/html/artisan", "boost:mcp"]
#     }
#   }
# }
# 
# 💾 Salvo em: ~/.config/mcp/mcp.json
# ⚠️  Reinicie o Claude/Cursor para aplicar
```

### Cenário 2: Trocar de Projeto
```bash
cd ~/projects/eventospro
aidev mcp laravel auto

# Output:
# ⚠️  MCP Laravel Boost já configurado para outro projeto: spadaer
#    Container atual: spadaer-laravel.test-1
#    Container novo: eventospro-laravel.test-1
# 
# ❓ Deseja substituir? (s/N): s
# ✅ Configuração atualizada para eventospro
# 💾 Backup criado: ~/.config/mcp/backups/mcp.json.20240206.XXXXXX.bak
```

### Cenário 3: Detecção Automática de Artisan
```bash
cd ~/projects/bellabeaulty
aidev mcp laravel auto

# Output:
# 🔍 Detectando containers Laravel...
# ✅ Container encontrado: bellabeaulty-app
# 📁 Diretório projeto: bellabeaulty
# 🔗 Match: bellabeaulty-app contém 'bellabeaulty'
# 
# 🔍 Detectando caminho do artisan...
# ℹ️  Tentando caminhos padrão...
# ✓ Encontrado em caminho padrão: /var/www/artisan
# ✓ Validado: /var/www/artisan funciona!
# 
# 📝 Configuração gerada:
# {
#   "mcpServers": {
#     "laravel-boost": {
#       "command": "docker",
#       "args": [
#         "exec",
#         "-i",
#         "bellabeaulty-app",
#         "php",
#         "/var/www/artisan",     ← Caminho detectado automaticamente!
#         "boost:mcp"
#       ]
#     }
#   }
# }
```

### Cenário 4: Artisan em Local Não-Padrão
```bash
cd ~/projects/api-custom
cd ~/projects/spadaer
aidev mcp laravel auto

# Output:
# 🔍 Detectando containers Laravel...
# ✅ Container encontrado: api-custom
# 📁 Diretório projeto: api-custom
# 
# 🔍 Detectando caminho do artisan...
# ℹ️  Tentando caminhos padrão...
# ⚠️  Não encontrado nos caminhos padrão
# ℹ️  Buscando recursivamente em /var/www...
# ✓ Encontrado via busca: /app/artisan
# ✓ Validado: /app/artisan funciona!
# 
# 📝 Configuração gerada com caminho customizado: /app/artisan
```

### Cenário 5: Mesmo Projeto, Recriar
```bash
cd ~/projects/spadaer
aidev mcp laravel auto

# Output:
# ℹ️  MCP Laravel Boost já configurado para este projeto (spadaer)
#    Container: spadaer-laravel.test-1
#    Artisan path: /var/www/html/artisan
# 
# ❓ Deseja recriar a configuração? (s/N): s
# ✅ Configuração recriada
```

## Integração com Orquestrador

### Hook de Inicialização
```bash
# No início de cada sessão, o orquestrador pode verificar:

1. Verificar se existe .aidev/ no projeto
2. Se for Laravel, verificar se tem MCP configurado
3. Se não tiver laravel-boost no mcp.json, sugerir configurar
4. Se tiver de outro projeto, alertar sobre mismatch
```

### Mensagem do Orquestrador
```
🤖 Orquestrador AI Dev

📍 Projeto: spadaer (Laravel 12.x)
🔍 Verificando MCP Laravel Boost...

⚠️  Atenção: MCP Laravel Boost não configurado para este projeto!
   Último configurado: eventospro (em 06/02/2026 15:30)

💡 Sugestão: Execute 'aidev mcp laravel auto' para configurar automaticamente
   ou 'aidev mcp laravel setup' para modo interativo.
```

## Mapeamento de Projetos Existentes

Para importar configurações existentes e manter histórico:

```bash
# Comando para importar configs manuais existentes
aidev mcp laravel import

# Output:
# 🔍 Procurando configurações Laravel Boost existentes...
# 
# Encontradas:
# 1. eventospro-laravel.test-1 → /var/www/html/artisan
# 2. bellabeaulty-app → /var/www/artisan  
# 3. cred_crud-laravel.test-1 → /var/www/html/artisan
# 
# 💾 Registrando no histórico...
# ✅ 3 configurações importadas para ~/.aidev/mcp/laravel/projects/
```

### Estrutura de Registro
```
~/.aidev/mcp/laravel/
├── projects/                      # Registro de projetos conhecidos
│   ├── eventospro.json
│   │   {
│   │     "name": "eventospro",
│   │     "container": "eventospro-laravel.test-1",
│   │     "artisan_path": "/var/www/html/artisan",
│   │     "command": "boost:mcp",
│   │     "last_used": "2024-02-06T15:30:00",
│   │     "project_dir": "~/projects/eventospro"
│   │   }
│   ├── bellabeaulty.json
│   ├── cred_crud.json
│   └── spadaer.json
├── current.json                   # Aponta para o projeto ativo
│   {
│     "active_project": "spadaer",
│     "container": "spadaer-laravel.test-1",
│     "updated_at": "2024-02-06T16:45:00"
│   }
└── config/
    └── backups/                   # Backups das configs MCP
        ├── mcp.json.202402061530.bak  # eventospro
        ├── mcp.json.202402061545.bak  # bellabeaulty
        └── mcp.json.202402061645.bak  # spadaer
```

## Comando de Status Avançado

```bash
aidev mcp laravel status --full

# Output:
# 📊 Status do MCP Laravel Boost
# 
# 🎯 Projeto Atual: spadaer
#    Container: spadaer-laravel.test-1
#    Artisan: /var/www/html/artisan
#    Comando: boost:mcp
# 
# 📜 Histórico de Projetos:
#    1. eventospro (último uso: 6h atrás)
#    2. bellabeaulty (último uso: 2d atrás)
#    3. cred_crud (último uso: 1s atrás)
#    4. spadaer (ATIVO)
# 
# 🔄 Rápido switch:
#    aidev mcp laravel switch eventospro
#    aidev mcp laravel switch bellabeaulty
```

## Vantagens da Abordagem

1. **Zero Configuração Manual**: Detecta tudo automaticamente
2. **Seguro**: Alerta antes de sobrescrever config de outro projeto
3. **Histórico**: Mantém backups e permite restaurar
4. **Inteligente**: Usa nome do diretório para matching
5. **Flexível**: Permite override manual se necessário
6. **Padronizado**: Sempre gera config no formato correto
7. **Smart Path Detection**: Encontra artisan em qualquer local
8. **Multi-Projeto**: Gerencia configs de vários projetos Laravel

## Próximos Passos

### Sprint 1: Detecção e Geração
- [ ] Implementar detecção de container por diretório
- [ ] Implementar detecção de artisan path
- [ ] Gerar configuração no formato padrão
- [ ] Salvar no mcp.json do usuário

### Sprint 2: Gestão e Backup
- [ ] Implementar verificação de config existente
- [ ] Criar sistema de backup automático
- [ ] Implementar restore de configurações
- [ ] Criar comando `history` e `current`

### Sprint 3: Integração
- [ ] Hook no orquestrador para verificar ao iniciar
- [ ] Sugestão automática quando detectar mismatch
- [ ] Documentação e exemplos

---

**Status:** Pronto para implementação
**Prioridade:** Alta (facilita muito o workflow diário)
**Complexidade:** Média (principalmente detecção e merge de JSON)
