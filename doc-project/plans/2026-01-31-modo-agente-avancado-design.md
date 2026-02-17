# Design: Modo Agente Avançado

**Data**: 2026-01-31
**Sprint**: 4 (Fase 3)
**Status**: Proposta

## 1. Visão Geral
Tornar o sistema de agentes do `aidev` mais dinâmico, permitindo configurações específicas por plataforma, skills customizáveis e persistência de contexto.

## 2. Abordagem Técnica

### 2.1 Configuração de Agentes por Plataforma
Atualmente, os agentes são copiados de `templates/agents`.
**Proposta**:
- Criar `templates/platform/[PLATFORM]/agents/` (opcional).
- O comando `aidev init` deve mesclar agentes globais com overrides da plataforma.
- Adicionar suporte a arquivos `.json` de configuração para metadados dos agentes.

### 2.2 Skills Customizáveis
**Proposta**:
- Comando `aidev add-skill <skill-name>` para baixar ou ler de diretórios de templates.
- Registro de skills em `.aidev/skills/registry.json`.

### 2.3 Contexto Persistente (Orquestrador)
**Proposta**:
- Criar `.aidev/state/session.json` com:
  - `current_fase`
  - `current_sprint`
  - `current_task`
  - `state` (active/paused/completed)
- O orquestrador deve ler este arquivo ao iniciar.

## 3. Impacto no Código
- `lib/agent-ops.sh`: Refatorar lógica de cópia de agentes.
- `lib/cli.sh`: Adicionar novos comandos e flags.
- `lib/core.sh`: Funções para ler/escrever estado JSON.

## 4. Alternativas Consideradas
- **A1**: Manter tudo em `.md` (difícil de dar parse via script).
- **A2**: Usar SQLite para estado ( overkill para o momento).
**Decisão**: Usar JSON via `jq` para simplicidade e portabilidade.
