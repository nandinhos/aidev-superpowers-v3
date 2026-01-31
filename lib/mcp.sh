#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - MCP Module
# ============================================================================
# Model Context Protocol - Configuração de servidores MCP para AIs
# 
# Uso: source lib/mcp.sh
# Dependências: lib/core.sh, lib/file-ops.sh, lib/detection.sh
# ============================================================================

# ============================================================================
# Configuração de Servidores MCP
# ============================================================================

# Gera configuração MCP para Claude Code
# Uso: generate_mcp_config "claude-code" "/path/to/project"
generate_mcp_config() {
    local platform="$1"
    local project_path="${2:-.}"
    
    case "$platform" in
        "claude-code")
            generate_claude_mcp_config "$project_path"
            ;;
        "antigravity")
            generate_antigravity_mcp_config "$project_path"
            ;;
        "gemini"|"opencode")
            generate_generic_mcp_config "$project_path" "$platform"
            ;;
        *)
            print_debug "MCP não suportado para: $platform"
            return 0
            ;;
    esac
}

# Gera .mcp.json para Claude Code
generate_claude_mcp_config() {
    local project_path="$1"
    local mcp_file="$project_path/.mcp.json"
    
    # Detecta stack para personalização
    local stack
    stack=$(detect_stack "$project_path")
    
    local project_name
    project_name=$(detect_project_name "$project_path")
    
    if should_write_file "$mcp_file"; then
        cat > "$mcp_file" << EOF
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "description": "Context7 server for documentation lookups"
    },
    "serena": {
      "command": "uvx",
      "args": ["serena", "--project=$project_path"],
      "description": "Serena server for intelligent code navigation"
    }
  },
  "projectConfig": {
    "name": "$project_name",
    "stack": "$stack",
    "version": "1.0.0"
  }
}
EOF
        increment_files
        print_success "Configuração MCP criada: $mcp_file"
    fi
}

# Gera configuração MCP para Antigravity
generate_antigravity_mcp_config() {
    local project_path="$1"
    local config_dir="$project_path/.aidev/mcp"
    
    ensure_dir "$config_dir"
    
    local config_file="$config_dir/antigravity-config.json"
    
    local project_name
    project_name=$(detect_project_name "$project_path")
    
    local stack
    stack=$(detect_stack "$project_path")
    
    if should_write_file "$config_file"; then
        cat > "$config_file" << EOF
{
  "platform": "antigravity",
  "project": "$project_name",
  "stack": "$stack",
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/oraios/serena", "serena", "start-mcp-server"],
      "description": "Analise semantica de codigo"
    },
    "basic-memory": {
      "command": "uvx",
      "args": ["basic-memory", "mcp"],
      "description": "Memoria persistente"
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "description": "Documentacao de bibliotecas"
    }
  }
}
EOF
        increment_files
        print_success "Configuração MCP Antigravity: $config_file"
    fi
}

# Gera configuração genérica para outras plataformas
generate_generic_mcp_config() {
    local project_path="$1"
    local platform="$2"
    local config_dir="$project_path/.aidev/mcp"
    
    ensure_dir "$config_dir"
    
    local config_file="$config_dir/${platform}-config.json"
    
    if should_write_file "$config_file"; then
        cat > "$config_file" << EOF
{
  "platform": "$platform",
  "servers": {
    "context7": {
      "enabled": true,
      "command": "npx -y @upstash/context7-mcp@latest"
    },
    "serena": {
      "enabled": true,
      "command": "uvx serena --project=."
    }
  }
}
EOF
        increment_files
        print_success "Configuração MCP ($platform): $config_file"
    fi
}

# ============================================================================
# Servidores MCP Disponíveis
# ============================================================================

# Lista servidores MCP padrão
list_mcp_servers() {
    cat << 'EOF'
context7     - Documentação e exemplos de código
serena       - Navegação inteligente de código
filesystem   - Operações de sistema de arquivos
git          - Integração com Git
memory       - Memória persistente entre sessões
EOF
}

# Configura servidor MCP individual
configure_mcp_server() {
    local server_name="$1"
    local project_path="${2:-.}"
    local enabled="${3:-true}"
    
    local servers_file="$project_path/.aidev/mcp/servers.yaml"
    
    ensure_dir "$(dirname "$servers_file")"
    
    # Adiciona ou atualiza servidor
    if [ ! -f "$servers_file" ]; then
        echo "servers:" > "$servers_file"
    fi
    
    cat >> "$servers_file" << EOF
  $server_name:
    enabled: $enabled
    configured_at: $(date -Iseconds)
EOF
    
    print_info "Servidor MCP '$server_name' configurado"
}

# ============================================================================
# Validação MCP
# ============================================================================

# Verifica se MCP está configurado
has_mcp_config() {
    local project_path="${1:-.}"
    
    # Claude Code
    [ -f "$project_path/.mcp.json" ] && return 0
    
    # Gemini/outros
    [ -d "$project_path/.aidev/mcp" ] && return 0
    
    return 1
}

# Valida configuração MCP
validate_mcp_config() {
    local project_path="${1:-.}"
    local errors=0
    
    print_section "Verificando MCP"
    
    if [ -f "$project_path/.mcp.json" ]; then
        # Valida JSON
        if command -v jq &> /dev/null; then
            if jq . "$project_path/.mcp.json" > /dev/null 2>&1; then
                print_success ".mcp.json válido"
            else
                print_error ".mcp.json JSON inválido"
                ((errors++))
            fi
        else
            print_info ".mcp.json existe (jq não disponível para validação)"
        fi
    else
        print_warning ".mcp.json não encontrado"
    fi
    
    return $errors
}

# ============================================================================
# MCP Engine Setup
# ============================================================================

# Configura MCP Engine completo
setup_mcp_engine() {
    local project_path="${1:-.}"
    local platform="${2:-auto}"
    
    # Auto-detecta plataforma se necessário
    if [ "$platform" = "auto" ]; then
        platform=$(detect_platform)
    fi
    
    print_step "Configurando MCP Engine para $platform..."
    
    # Gera config principal
    generate_mcp_config "$platform" "$project_path"
    
    # Cria estrutura de diretórios MCP
    ensure_dir "$project_path/.aidev/mcp/servers"
    ensure_dir "$project_path/.aidev/mcp/memory"
    
    # Gera arquivos auxiliares
    generate_mcp_readme "$project_path"
    
    print_success "MCP Engine configurado!"
}

# Gera README explicativo para MCP
generate_mcp_readme() {
    local project_path="$1"
    local readme_file="$project_path/.aidev/mcp/README.md"
    
    if should_write_file "$readme_file"; then
        cat > "$readme_file" << 'EOF'
# MCP - Model Context Protocol

Este diretório contém a configuração do MCP para este projeto.

## Servidores Configurados

### context7
Acesso a documentação e exemplos de código atualizados.

### serena
Navegação inteligente de código com análise semântica.

## Estrutura

```
mcp/
├── servers/     # Configs de servidores individuais
├── memory/      # Memória persistente
└── README.md    # Este arquivo
```

## Uso

Os servidores MCP são carregados automaticamente pelo AI quando você inicia uma sessão.

## Configuração

Edite `.mcp.json` na raiz do projeto para customizar servidores.
EOF
        increment_files
    fi
}

# ============================================================================
# Comandos de Gerenciamento
# ============================================================================

# Status do MCP
mcp_status() {
    local project_path="${1:-.}"
    
    print_section "Status do MCP"
    
    if has_mcp_config "$project_path"; then
        print_success "MCP configurado"
        
        if [ -f "$project_path/.mcp.json" ]; then
            echo "  Plataforma: Claude Code"
            echo "  Config: .mcp.json"
            
            if command -v jq &> /dev/null; then
                local servers
                servers=$(jq -r '.mcpServers | keys[]' "$project_path/.mcp.json" 2>/dev/null | tr '\n' ', ')
                echo "  Servidores: ${servers%,}"
            fi
        fi
    else
        print_warning "MCP não configurado"
        print_info "Use 'aidev init' ou 'aidev mcp setup' para configurar"
    fi
}

# Adiciona servidor ao MCP
mcp_add_server() {
    local server_name="$1"
    local project_path="${2:-.}"
    
    if [ -z "$server_name" ]; then
        print_error "Nome do servidor é obrigatório"
        return 1
    fi
    
    if [ ! -f "$project_path/.mcp.json" ]; then
        print_error ".mcp.json não encontrado"
        return 1
    fi
    
    print_step "Adicionando servidor '$server_name'..."
    
    # TODO: Implementar adição de servidor ao JSON
    print_info "Edite .mcp.json manualmente para adicionar servidores customizados"
}

# Remove servidor do MCP
mcp_remove_server() {
    local server_name="$1"
    local project_path="${2:-.}"
    
    if [ -z "$server_name" ]; then
        print_error "Nome do servidor é obrigatório"
        return 1
    fi
    
    print_step "Removendo servidor '$server_name'..."
    
    # TODO: Implementar remoção de servidor do JSON
    print_info "Edite .mcp.json manualmente para remover servidores"
}
