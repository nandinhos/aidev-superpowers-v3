# 📖 AI Dev - Documentação Completa do Instalador

> Versão analisada: **v3.6.0**  
> Última atualização: 2026-02-05

---

## 🎯 Resumo Executivo

O sistema **aidev** possui três comandos principais de instalação/atualização com comportamentos distintos:

| Comando | Escopo | Sobrescreve? | Cria Backup? |
|---------|--------|--------------|--------------|
| `aidev init` | Projeto local | ❌ Não (exceto `--force`) | ❌ Não |
| `aidev upgrade` | Projeto local | ✅ Sim (força automático) | ✅ Sim |
| `aidev self-upgrade` | Instalação global | ❌ Não se mesma versão | ❌ Não |
| `aidev self-upgrade --force` | Instalação global | ✅ Sim (mesmo se mesma versão) | ❌ Não |

---

## 📋 Comparação Detalhada dos Comandos

### **`aidev init` vs `aidev upgrade`**

| Aspecto | `aidev init` | `aidev upgrade` |
|---------|--------------|-----------------|
| **Propósito** | Primeira instalação no projeto | Atualizar instalação existente |
| **Pré-requisito** | Nenhum | `.aidev/` deve existir |
| **AIDEV_FORCE padrão** | `false` | `true` (forçado automaticamente) |
| **Backup automático** | ❌ Não | ✅ Sim (`.aidev/backups/YYYYMMDDHHMMSS`) |
| **Configura segredos** | ✅ Sim (interativo) | ❌ Não |
| **Configura MCP** | ✅ Sim | ❌ Não |
| **Reinstala agentes** | ✅ Sim | ✅ Sim |
| **Reinstala skills** | ✅ Sim | ✅ Sim |
| **Reinstala rules** | ✅ Sim | ❌ Não |
| **Atualiza instruções de plataforma** | ✅ Sim | ✅ Sim |

### **`aidev self-upgrade` vs `aidev self-upgrade --force`**

| Aspecto | `self-upgrade` | `self-upgrade --force` |
|---------|----------------|------------------------|
| **Propósito** | Atualizar CLI global | Forçar atualização mesmo se já atualizado |
| **Executa se mesma versão** | ❌ Não | ✅ Sim |
| **Método de sync** | `rsync -a --delete` | `rsync -a --delete` |
| **Afeta instalação global** | ✅ Sim | ✅ Sim |
| **Afeta projetos locais** | ❌ Não | ❌ Não |

---

## 🔄 Lógica de Sobrescrita de Arquivos

### **Função Central: `should_write_file()`**

```bash
# Localização: lib/file-ops.sh:149-167
should_write_file() {
    local file="$1"

    # Em modo dry-run, apenas simula
    if [ "$AIDEV_DRY_RUN" = "true" ]; then
        return 1  # Não escreve
    fi

    if [ ! -f "$file" ]; then
        return 0  # Não existe, pode escrever
    fi

    if [ "$AIDEV_FORCE" = "true" ]; then
        return 0  # Force está ativo
    fi

    return 1  # Existe e force não está ativo
}
```

### **Regras de Decisão:**

| Condição | Resultado |
|----------|-----------|
| Arquivo não existe | ✅ Escreve |
| Arquivo existe + `--force` | ✅ Sobrescreve |
| Arquivo existe + sem `--force` | ❌ Pula com warning |
| `--dry-run` ativo | ❌ Apenas simula |

---

## 📁 Arquivos Afetados por Cada Comando

### **`aidev init`** (sem `--force`)

| Diretório/Arquivo | Ação | Sobrescreve? |
|-------------------|------|--------------|
| `.aidev/` | Cria estrutura | N/A |
| `.aidev/agents/*.md` | Instala | ❌ Pula se existe |
| `.aidev/skills/*/SKILL.md` | Instala | ❌ Pula se existe |
| `.aidev/rules/*.md` | Instala | ❌ Pula se existe |
| `.aidev/state/` | Cria diretório | N/A |
| `.aidev/memory/kb/` | Cria diretório | N/A |
| `.aidev/AI_INSTRUCTIONS.md` | Instala | ❌ Pula se existe |
| `.aidev/QUICKSTART.md` | Instala | ❌ Pula se existe |
| `.mcp.json` | Configura MCP | ❌ Pula se existe |
| `.env` | Configura segredos | Adiciona keys (não sobrescreve) |
| `.gitignore` | Adiciona entradas | Append (não sobrescreve) |
| `AI_INSTRUCTIONS.md` (raiz) ou específico | Instala | ❌ Pula se existe |

### **`aidev init --force`**

Mesmo que acima, mas **TODOS os arquivos são sobrescritos**.

### **`aidev upgrade`**

| Diretório/Arquivo | Ação | Sobrescreve? |
|-------------------|------|--------------|
| `.aidev/backups/TIMESTAMP/` | Cria backup | N/A |
| `.aidev/agents/*.md` | Reinstala | ✅ **Sim** (AIDEV_FORCE=true) |
| `.aidev/skills/*/SKILL.md` | Reinstala | ✅ **Sim** |
| `.aidev/AI_INSTRUCTIONS.md` | Reinstala | ✅ **Sim** |
| `.aidev/QUICKSTART.md` | Reinstala | ✅ **Sim** |
| Arquivos específicos de plataforma | Reinstala | ✅ **Sim** |
| `.aidev/rules/*.md` | **NÃO reinstala** | ❌ Preservado |
| `.mcp.json` | **NÃO atualiza** | ❌ Preservado |
| `.env` | **NÃO atualiza** | ❌ Preservado |

> [!IMPORTANT]
> O `aidev upgrade` força `AIDEV_FORCE=true` internamente, mas **preserva rules, MCP e segredos**.

### **`aidev self-upgrade`**

| Diretório/Arquivo | Ação | Método |
|-------------------|------|--------|
| `$GLOBAL_INSTALL/bin/` | Sincroniza | `rsync -a --delete` |
| `$GLOBAL_INSTALL/lib/` | Sincroniza | `rsync -a --delete` |
| `$GLOBAL_INSTALL/templates/` | Sincroniza | `rsync -a --delete` |
| `$GLOBAL_INSTALL/tests/` | Sincroniza | `rsync -a --delete` |

> [!CAUTION]
> O `rsync --delete` **REMOVE** arquivos no destino que não existem na origem!

---

## 🔍 Detecção de Source para Self-Upgrade

O comando `self-upgrade` busca o código fonte nesta ordem:

1. `./lib/core.sh` (diretório atual)
2. `$AIDEV_ROOT_DIR/lib/core.sh` (se diferente da instalação global)
3. `$HOME/projects/aidev-superpowers-v3`
4. `$HOME/aidev-superpowers`

---

## ⚙️ Flags Globais de Controle

| Flag | Variável | Efeito |
|------|----------|--------|
| `--force` | `AIDEV_FORCE=true` | Sobrescreve arquivos existentes |
| `--dry-run` | `AIDEV_DRY_RUN=true` | Simula execução sem alterações |
| `--install-in <path>` | `CLI_INSTALL_PATH=<path>` | Define diretório alvo |

---

## 🛡️ O que é PRESERVADO em cada cenário

### **`aidev init`** (sem `--force`)
- ✅ Todos os arquivos existentes são preservados
- ✅ Customizações manuais são mantidas
- ⚠️ Novos arquivos da versão atualizada **não são instalados** se já existe versão antiga

### **`aidev upgrade`**
- ✅ `.env` (segredos)
- ✅ `.mcp.json` (configuração MCP)
- ✅ `.aidev/rules/` (regras customizadas)
- ✅ `.aidev/memory/kb/` (base de conhecimento)
- ✅ `.aidev/state/` (estado da sessão)
- ✅ `.aidev/analysis/` (análises salvas)
- ❌ Agentes e skills são sobrescritos

### **`aidev self-upgrade`**
- ✅ Projetos locais (`.aidev/` em cada projeto)
- ❌ Arquivos adicionados manualmente em `bin/`, `lib/`, `templates/` na instalação global **são removidos** pelo `rsync --delete`

---

## 📊 Fluxo de Decisão Visual

```
┌─────────────────────────────────────────────────────────┐
│                   COMANDO EXECUTADO                      │
└─────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
      ┌─────────┐    ┌──────────┐    ┌─────────────┐
      │  init   │    │ upgrade  │    │self-upgrade │
      └────┬────┘    └────┬─────┘    └──────┬──────┘
           │              │                 │
           ▼              ▼                 ▼
    ┌─────────────┐ ┌───────────┐   ┌─────────────────┐
    │ --force?    │ │FORCE=true │   │ Versão igual?   │
    └─────┬───────┘ │(automático│   └────────┬────────┘
          │         └─────┬─────┘            │
    ┌─────┴─────┐         │           ┌─────┴─────┐
    │           │         │           │           │
    ▼           ▼         ▼           ▼           ▼
  ┌───┐       ┌───┐   ┌───────┐   ┌───────┐  ┌─────────┐
  │Não│       │Sim│   │Backup │   │ Skip  │  │--force? │
  └─┬─┘       └─┬─┘   │ .aidev│   │(exit) │  └────┬────┘
    │           │     └───┬───┘   └───────┘       │
    ▼           ▼         ▼                 ┌─────┴─────┐
┌────────┐  ┌────────┐ ┌────────┐          │           │
│Pula se │  │Sobres- │ │Sobres- │          ▼           ▼
│existe  │  │creve   │ │creve   │      ┌───────┐  ┌───────┐
└────────┘  └────────┘ └────────┘      │ Skip  │  │ rsync │
                                       └───────┘  │--delete│
                                                  └───────┘
```

---

## 💡 Recomendações de Uso

| Cenário | Comando Recomendado |
|---------|---------------------|
| Primeira instalação em projeto novo | `aidev init` |
| Projeto já tem `.aidev/` e quer atualizar | `aidev upgrade` |
| Atualizar CLI global para nova versão | `aidev self-upgrade` |
| Forçar reinstalação completa | `aidev init --force` |
| Simular antes de executar | `aidev init --dry-run` |
| Debug/diagnóstico | `aidev doctor` |
| Reparar instalação corrompida | `aidev doctor --fix` |

---

## 🧪 Como Verificar a Versão

```bash
# Versão do CLI global
aidev --version

# Status da instalação no projeto atual
aidev status

# Diagnóstico completo
aidev doctor
```

---

## 📝 Notas Técnicas

1. **Templates são processados com substituição de variáveis** (`{{VAR}}`, `{{VAR:default}}`, `{{#if VAR}}...{{/if}}`)
2. **Localização**: Templates suportam `pt-BR` e `en` via estrutura de diretórios (`templates/agents/pt/` vs `templates/agents/en/`)
3. **Backup do upgrade**: Apenas agentes e skills são salvos em `.aidev/backups/TIMESTAMP/`
4. **Self-upgrade detecta source automaticamente**: Primeiro tenta diretório atual, depois paths conhecidos
