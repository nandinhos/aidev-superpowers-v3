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
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 1.2 Health Check Laravel
**Descrição:** Validar se Laravel está pronto (migrations, vendors, artisan funcional)
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 1.3 Config Generator
**Descrição:** Gerar configuração MCP Laravel Boost dinamicamente
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

---

## 🗓️ Sprint 2: Gatilhos e Lifecycle

### 2.1 Docker Events Watcher
**Descrição:** Monitorar eventos Docker para detectar quando containers iniciam
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 2.2 Trigger Orchestrator
**Descrição:** Coordenar fluxo: detecção → health check → config
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 2.3 MCP Config Hot-Reload
**Descrição:** Aplicar nova configuração MCP sem restart
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

---

## 🗓️ Sprint 3: Instalação e Bootstrap

### 3.1 Laravel Boost Auto-Installer
**Descrição:** Instalar Laravel Boost no container se necessário
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 3.2 Bootstrap Verification
**Descrição:** Validar que Laravel Boost está operacional após instalação
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 3.3 Multi-Project Support
**Descrição:** Suportar múltiplos projetos Laravel simultaneamente
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

---

## 🗓️ Sprint 4: CLI e UX

### 4.1 Command: `aidev mcp laravel detect`
**Descrição:** Comando manual para detectar e configurar
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 4.2 Command: `aidev mcp laravel status`
**Descrição:** Ver status de todos containers Laravel configurados
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 4.3 Command: `aidev mcp laravel config`
**Descrição:** Gerenciar configurações do Laravel Boost
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

**Critérios de Aceitação:**
- [x] Concluído
- [x] Concluído
- [x] Concluído

---

## 🗓️ Sprint 5: Documentação e Polish

### 5.1 Documentation
**Descrição:** Documentar uso e arquitetura
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 5.2 Edge Cases
**Descrição:** Lidar com cenários especiais
- [x] Concluído
- [x] Concluído
- [x] Concluído
- [x] Concluído

### 5.3 Tests
**Descrição:** Testes automatizados
- [x] Concluído
- [x] Concluído
- [x] Concluído

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
