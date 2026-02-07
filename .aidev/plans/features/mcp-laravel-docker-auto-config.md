# Feature: Configuração Dinâmica do MCP Laravel Boost em Docker

## 📋 Resumo
Implementar sistema de detecção automática e configuração dinâmica do MCP Laravel Boost quando containers Docker estiverem prontos, eliminando a necessidade de configuração manual do caminho do container.

## 🎯 Objetivos
1. Detectar quando container Laravel está pronto para receber configurações
2. Configurar MCP Laravel Boost dinamicamente com informações do container
3. Executar instalação/configuração apenas quando requisitos forem atendidos
4. Suportar múltiplos ambientes Docker (docker-compose, k8s, etc.)

## 🔍 Análise do Problema Atual
- Usuário precisa editar manualmente configuração do MCP
- Caminho do container varia por projeto/ambiente
- Sem gatilho automático de detecção de prontidão
- Falta de integração entre Docker lifecycle e MCP

---

## 🗓️ Sprint 1: Fundação e Detecção

### 1.1 Container Discovery Service
**Descrição:** Sistema para descobrir containers Laravel em execução
- [ ] Criar script `lib/docker-discovery.sh`
- [ ] Detectar containers com Laravel via labels/imagens
- [ ] Identificar serviços PHP-FPM/Apache/Nginx
- [ ] Mapear portas e volumes expostos

**Critérios de Aceitação:**
- [ ] Lista todos containers Laravel rodando no host
- [ ] Identifica corretamente PHP version e Laravel version
- [ ] Extrai informações de rede (IP, portas)

### 1.2 Health Check Laravel
**Descrição:** Validar se Laravel está pronto (migrations, vendors, artisan funcional)
- [ ] Criar `lib/laravel-health-check.sh`
- [ ] Verificar se vendor/ existe
- [ ] Testar `php artisan --version`
- [ ] Verificar conexão com banco (se configurado)
- [ ] Timeout e retry configuráveis

**Critérios de Aceitação:**
- [ ] Retorna HEALTHY quando Laravel está operacional
- [ ] Retorna PENDING quando ainda inicializando
- [ ] Retorna FAILED quando há erros críticos

### 1.3 Config Generator
**Descrição:** Gerar configuração MCP Laravel Boost dinamicamente
- [ ] Criar `lib/mcp-config-generator.sh`
- [ ] Template de config MCP com placeholders
- [ ] Preencher caminho do container automaticamente
- [ ] Detectar PHP executable path dentro do container
- [ ] Configurar artisan path

**Critérios de Aceitação:**
- [ ] Gera config MCP válida para container detectado
- [ ] Suporta múltiplos containers (nomes únicos)
- [ ] Valida JSON gerado antes de aplicar

---

## 🗓️ Sprint 2: Gatilhos e Lifecycle

### 2.1 Docker Events Watcher
**Descrição:** Monitorar eventos Docker para detectar quando containers iniciam
- [ ] Criar `lib/docker-events.sh`
- [ ] Usar `docker events` para capturar container start
- [ ] Filtrar eventos de containers Laravel
- [ ] Implementar debounce (evitar múltiplos triggers)

**Critérios de Aceitação:**
- [ ] Detecta start de container em < 5 segundos
- [ ] Ignora containers não-Laravel
- [ ] Não duplica eventos de mesmo container

### 2.2 Trigger Orchestrator
**Descrição:** Coordenar fluxo: detecção → health check → config
- [ ] Criar `lib/trigger-orchestrator.sh`
- [ ] Implementar state machine: IDLE → DETECTED → HEALTH_CHECKING → CONFIGURING → ACTIVE
- [ ] Aguardar health check passar antes de configurar
- [ ] Retry com exponential backoff

**Critérios de Aceitação:**
- [ ] Só configura MCP quando health check passar
- [ ] Max 5 tentativas com backoff crescente
- [ ] Timeout total de 5 minutos por container

### 2.3 MCP Config Hot-Reload
**Descrição:** Aplicar nova configuração MCP sem restart
- [ ] Criar `lib/mcp-hot-reload.sh`
- [ ] Salvar config em `.aidev/mcp/laravel-boost-dynamic.json`
- [ ] Atualizar referência no MCP server
- [ ] Notificar usuário da nova configuração

**Critérios de Aceitação:**
- [ ] Configuração aplicada sem reiniciar IDE/Editor
- [ ] Backup da config anterior mantido
- [ ] Rollback automático em caso de erro

---

## 🗓️ Sprint 3: Instalação e Bootstrap

### 3.1 Laravel Boost Auto-Installer
**Descrição:** Instalar Laravel Boost no container se necessário
- [ ] Criar `lib/laravel-boost-installer.sh`
- [ ] Verificar se Laravel Boost já está instalado
- [ ] Executar `composer require` se necessário
- [ ] Publicar configurações e assets
- [ ] Rodar migrations específicas do Boost

**Critérios de Aceitação:**
- [ ] Instalação silenciosa se já existir
- [ ] Instalação automática se não detectado
- [ ] Compatível com Laravel 10.x/11.x

### 3.2 Bootstrap Verification
**Descrição:** Validar que Laravel Boost está operacional após instalação
- [ ] Criar `lib/boost-verification.sh`
- [ ] Testar endpoints do Boost (health, artisan, etc.)
- [ ] Verificar permissões de storage/cache
- [ ] Confirmar integração com MCP server

**Critérios de Aceitação:**
- [ ] Health check do Boost retorna 200
- [ ] Comandos MCP funcionam no container
- [ ] Logs de erro visíveis para debug

### 3.3 Multi-Project Support
**Descrição:** Suportar múltiplos projetos Laravel simultaneamente
- [ ] Criar `lib/multi-project-manager.sh`
- [ ] Gerenciar configs separadas por projeto/container
- [ ] Namespacing no MCP para evitar conflitos
- [ ] Switch automático baseado em contexto

**Critérios de Aceitação:**
- [ ] 2+ containers Laravel podem rodar simultaneamente
- [ ] MCP seleciona container correto por contexto
- [ ] Labels Docker usados para identificação

---

## 🗓️ Sprint 4: CLI e UX

### 4.1 Command: `aidev mcp laravel detect`
**Descrição:** Comando manual para detectar e configurar
- [ ] Implementar comando CLI
- [ ] Opções: `--force`, `--project=<name>`, `--timeout=<sec>`
- [ ] Output formatado com status
- [ ] Integração com logs e debug

**Critérios de Aceitação:**
- [ ] Comando funciona em qualquer momento
- [ ] Mostra progresso em tempo real
- [ ] Exit code 0 em sucesso, 1 em falha

### 4.2 Command: `aidev mcp laravel status`
**Descrição:** Ver status de todos containers Laravel configurados
- [ ] Implementar comando CLI
- [ ] Mostrar: container name, status, health, config path
- [ ] Indicar qual está ativo no MCP
- [ ] Opção `--watch` para monitoramento contínuo

**Critérios de Aceitação:**
- [ ] Lista todos containers detectados
- [ ] Status em tempo real
- [ ] Cores para facilitar leitura

### 4.3 Command: `aidev mcp laravel config`
**Descrição:** Gerenciar configurações do Laravel Boost
- [ ] Implementar comando CLI
- [ ] Subcomandos: `view`, `edit`, `reset`, `backup`
- [ ] Validação de sintaxe JSON
- [ ] Preview antes de aplicar

**Critérios de Aceitação:**
- [ ] Config pode ser visualizada e editada
- [ ] Validação previne erros de sintaxe
- [ ] Backup automático antes de mudanças

---

## 🗓️ Sprint 5: Documentação e Polish

### 5.1 Documentation
**Descrição:** Documentar uso e arquitetura
- [ ] Criar `docs/mcp-laravel-docker.md`
- [ ] Exemplos de docker-compose.yml otimizado
- [ ] Troubleshooting guide
- [ ] Diagrama de arquitetura

### 5.2 Edge Cases
**Descrição:** Lidar com cenários especiais
- [ ] Container restart (reconfiguração)
- [ ] Docker Compose down/up (persistência)
- [ ] WSL2 vs Linux vs Mac comportamentos
- [ ] Network modes (bridge, host, custom)

### 5.3 Tests
**Descrição:** Testes automatizados
- [ ] Unit tests para scripts bash
- [ ] Integration tests com containers reais
- [ ] Mock Docker environment para CI

---

## 🏗️ Decisões de Design

### Arquitetura
```
Docker Events
     ↓
Container Discovery
     ↓
Health Check
     ↓
[Requisitos OK?] ──Não──→ Retry / Log
     ↓ Sim
Config Generator
     ↓
MCP Hot-Reload
     ↓
Laravel Boost Install
     ↓
Verification
     ↓
✅ Ativo
```

### Formato de Config MCP
```json
{
  "mcpServers": {
    "laravel-boost-{container_name}": {
      "command": "docker",
      "args": [
        "exec", "-i", 
        "{container_name}",
        "php", "artisan", "mcp:serve"
      ],
      "env": {
        "LARAVEL_PROJECT_PATH": "{project_path}"
      }
    }
  }
}
```

### Labels Docker (Opcional)
```yaml
labels:
  - "aidev.laravel.enabled=true"
  - "aidev.laravel.project=my-app"
  - "aidev.laravel.php-version=8.3"
```

---

## 📊 Estimativas

| Sprint | Tarefas | Complexidade | Estimativa |
|--------|---------|--------------|------------|
| 1 | 3 | Média | 3-4 dias |
| 2 | 3 | Alta | 4-5 dias |
| 3 | 3 | Média | 3-4 dias |
| 4 | 3 | Baixa | 2-3 dias |
| 5 | 3 | Baixa | 2-3 dias |

**Total Estimado:** 14-19 dias

---

## 🚀 Próximos Passos

1. **Aprovar** este plano
2. **Iniciar** Sprint 1 - Container Discovery
3. **Criar** estrutura de arquivos em `.aidev/mcp/laravel/`
4. **Definir** prioridades (quais sprints são MVP?)

---

*Criado por: AI Dev Superpowers - Meta-Planning*
*Data: 2026-02-06*
