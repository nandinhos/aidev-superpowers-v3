# Backlog - Padronização de Ativação de MCPs

## Visão Geral

Sistema de detecção automática de stack e ativação padronizada de MCP servers em projetos novos ou existentes. MCPs são opcionais — se instalados, são usados; se não instalados, há fallback que não quebra o fluxo.

**Princípio**: MCPs são enhancement, não dependência. O framework funciona sem eles.

---

## Arquitetura de Fallback

```
[Detectar Stack]
       ↓
[Verificar MCPs instalados]
       ↓
┌──────┴──────┐
│   SIM      │
│ (instalado)│   NÃO      ┌─────────────────────┐
└──────┬──────┘──────────▶│ FALLBACK ATIVO     │
       │                  │ - Grep/ripgrep      │
       ▼                  │ - Cat manual        │
[Gerar .mcp.json]         │ - Busca nativa     │
       │                  └─────────────────────┘
       ▼
[Health Check]
       ↓
┌──────┴──────┐
│   OK        │   FALHA   ┌─────────────────────┐
│ (responde)  │──────────▶│ FALLBACK ATIVO     │
└─────────────┘           └─────────────────────┘
```

**Origem**: No projeto DAS (Calculadora Simples Nacional), quatro MCPs foram configurados manualmente — Context7, Serena, Basic Memory e Laravel Boost — com sucesso, mas sem nenhum processo padronizado ou reproduzível.

---

## Tarefas Prioritárias

### 0. [CRITICAL] Sistema de Fallback + Resiliência

**Princípio**: MCPs são enhancement, não dependência.

#### Fallback (Startup)
```
SE MCP instalado E respondendo → usar MCP
SENÃO → ativar fallback (log warning, não erro)
```

#### Resiliência em Tempo de Execução

| Cenário | Comportamento |
|---------|---------------|
| **Verificação** | A cada **término de task** (hook) |
| **Detecção** | Health check no hook de sprint done |
| **Queda detectada** | Ativar fallback automaticamente (warning) |
| **Retries** | 3 tentativas antes de aceitar que MCP está down |
| **Recovery** | Re-integrar automaticamente quando MCP voltar |
| **Sincronização** | MCP e Fallback mantém mesmo estado |

**Hooks identificados**:
- `aidev done <sprint>` — verificar todos MCPs após sprint
- `ckpt_create` — verificar antes de criar checkpoint
- `aidev agent` — verificar na ativação

**Alternativas por MCP**:

| MCP | Fallback |
|-----|----------|
| Context7 | `ripgrep` ou busca manual |
| Serena | `find` + `grep` |
| Basic Memory | `.aidev/memory/kb/` em Markdown |
| Laravel Boost | `php artisan` direto |

**Critérios**:
- [x] Nenhum erro fatal se MCP não disponível
- [x] Warning claro indicando fallback ativo
- [x] Verificação a cada término de task
- [x] Recovery automático quando MCP volta
- [x] Sincronizador mantém estado alinhado

### 1. [HIGH] Implementar Classificação de MCPs

**Descrição**: Criar taxonomia de MCPs separando universais (aplicáveis a qualquer projeto) de condicionais (dependentes de stack)

**Detalhes técnicos**:
- Definir categoria `universal`: MCPs que devem estar presentes em todo projeto
  - Basic Memory (persistência cross-session)
  - Serena (navegação inteligente de código)
  - Context7 (lookup de documentação)
- Definir categoria `conditional`: MCPs ativados por detecção de stack
  - Laravel Boost → detectar `composer.json` com `laravel/framework`
  - Outros futuros: Django MCP → `requirements.txt` com Django, etc.
- Criar schema de registro em `.aidev/config/mcp-registry.yaml`

**Status**: ✅ Concluído (mcp-registry.yaml criado)
**Arquivos**:
- `.aidev/config/mcp-registry.yaml` ✅

---

### 2. [HIGH] Implementar Detector de Stack

**Descrição**: Criar lógica de detecção automática da stack do projeto para ativar MCPs condicionais

**Status**: ✅ Concluído

**Detalhes técnicos**:
- Analisar arquivos-chave no diretório raiz do projeto:
  - `composer.json` → PHP/Laravel
  - `package.json` → Node.js (verificar frameworks: Next.js, Nuxt, etc.)
  - `requirements.txt` / `pyproject.toml` → Python
  - `Cargo.toml` → Rust
  - `go.mod` → Go
- Para Laravel, verificações adicionais:
  - Presença de `artisan` na raiz
  - Container Docker rodando (caso Laravel Sail): `docker ps | grep` nome do container
  - Comando MCP específico: `php artisan boost:mcp`
- Retornar lista de MCPs condicionais a ativar

**Arquivos**:
- `lib/stack-detector.sh` ✅
- `aidev mcp stack` ✅

---

### 3. [HIGH] Criar Gerador de `.mcp.json`

**Descrição**: Gerar arquivo `.mcp.json` baseado na classificação + detecção

**Status**: ✅ Concluído

**Detalhes técnicos**:
- Template base com MCPs universais (sempre presentes)
- Merge com MCPs condicionais detectados
- Para Laravel Boost via Docker Sail, resolver dinamicamente:
  - Nome do container (`docker ps --format`)
  - UID/GID do usuário (`id -u` / `id -g`)
- Validar que o arquivo gerado é JSON válido
- Se `.mcp.json` já existir, fazer merge inteligente (não sobrescrever configs manuais)

**Arquivos**:
- `lib/mcp-json-generator.sh` ✅
- `aidev mcp generate` ✅
- `aidev mcp show` ✅

**Arquivos esperados**:
- `.aidev/templates/mcp-json-base.json`
- `.aidev/templates/mcp-json-laravel.json`

---

### 4. [MEDIUM] Implementar Validação de Conectividade

**Descrição**: Verificar que cada MCP configurado está acessível e funcional

**Detalhes técnicos**:
- Para cada MCP no `.mcp.json`:
  - Verificar que o comando/binário existe (`which npx`, `which uvx`, `which docker`)
  - Tentar inicializar e verificar resposta
  - Para Docker-based (Laravel Boost): verificar container rodando
- Retornar relatório de status:
  - `connected`: MCP respondendo
  - `unavailable`: comando não encontrado
  - `error`: falha na inicialização
- Sugerir correções para MCPs com falha

**Arquivos esperados**:
- `.aidev/skills/mcp-health-check.md`

---

### 5. [LOW] Criar Workflow de Onboarding de Projeto

**Descrição**: Integrar detecção + geração + validação em um workflow único

**Detalhes técnicos**:
- Skill ativável por comando do usuário ou automaticamente ao iniciar projeto novo
- Fluxo:
  1. Detectar stack do projeto
  2. Consultar registry de MCPs
  3. Gerar/atualizar `.mcp.json`
  4. Validar conectividade
  5. Reportar resultado ao usuário
- Registrar resultado em Basic Memory para referência futura

**Arquivos esperados**:
- `.aidev/skills/project-onboarding-mcp.md`

---

## Dependências

- Acesso ao sistema de arquivos do projeto (leitura de `composer.json`, `package.json`, etc.)
- CLI tools: `npx`, `uvx`, `docker` (conforme MCPs utilizados)
- Basic Memory MCP (para persistir resultado do onboarding)

---

## Critérios de Aceitação

1. ✅ MCPs universais são configurados automaticamente em qualquer projeto novo
2. ✅ Detecção de stack identifica corretamente Laravel, Node.js, Python (no mínimo)
3. ✅ `.mcp.json` gerado é válido e funcional sem edição manual
4. ✅ Merge com `.mcp.json` existente preserva configurações manuais
5. ✅ Validação de conectividade reporta status de cada MCP
6. ✅ Workflow completo executa em menos de 30 segundos

---

## Observações

- **Caso de uso real**: Projeto DAS (Laravel 11 + Livewire 4 + Docker Sail) teve 4 MCPs configurados manualmente com sucesso, provando a viabilidade mas expondo a falta de padronização
- **Configuração que funcionou no DAS**:
  - Context7: `npx -y @upstash/context7-mcp@latest`
  - Serena: `uvx --from git+https://github.com/oraios/serena serena start-mcp-server`
  - Basic Memory: `uvx basic-memory mcp`
  - Laravel Boost: `docker exec -i -u 1000:1000 calculadora-das php artisan boost:mcp`
- **Extensibilidade**: Registry permite adicionar novos MCPs sem alterar lógica core

---

## Referências

- Projeto DAS `.mcp.json`: configuração manual de referência
- [Context7 MCP](https://github.com/upstash/context7)
- [Serena MCP](https://github.com/oraios/serena)
- [Basic Memory MCP](https://github.com/basicmachines-co/basic-memory)
- [Laravel Boost MCP](https://github.com/laravelboost/laravel-boost)
