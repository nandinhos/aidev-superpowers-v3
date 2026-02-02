# Plano: Comando de Ativacao Multiplataforma

**Status**: PLANEJADO
**Data**: 2026-02-02

## Objetivo

Criar comando `aidev agent` que gere prompt de ativacao otimizado para cada plataforma:
- Claude Code
- Antigravity
- Gemini CLI

## Problema Atual

O comando `aidev agent` gera um prompt generico que:
1. Nao aproveita recursos especificos de cada plataforma
2. Instrui a ler 20+ arquivos (lento)
3. Nao tem opcao de copiar automaticamente
4. Nao tem opcao de enviar direto para a CLI

---

## Solucao Proposta

### Arquitetura

```
aidev agent [--platform <plataforma>] [--copy] [--quick]

Flags:
  --platform, -p   Plataforma alvo (claude-code|antigravity|gemini|auto)
  --copy, -c       Copia para clipboard automaticamente
  --quick, -q      Prompt minimo (so QUICKSTART.md)
  --raw            Saida sem decoracao (para piping)
```

### Fluxo

```
aidev agent
    |
    v
detect_platform() --> claude-code | antigravity | gemini | generic
    |
    v
generate_<platform>_prompt()
    |
    v
[--copy] --> xclip/pbcopy
    |
    v
output
```

---

## Prompts por Plataforma

### Claude Code

**Caracteristicas**:
- Tem MCP servers integrados (serena, basic-memory, context7)
- Le arquivos rapidamente
- Suporta slash commands

**Prompt Otimizado**:
```
ATIVAR MODO AGENTE - AI Dev Superpowers

Leia APENAS: .aidev/QUICKSTART.md

Apos ler, confirme: "Modo Agente ativado. Pronto para orquestrar."
```

### Antigravity

**Caracteristicas**:
- Usa MCPs via configuracao JSON
- Interface via terminal
- Pode ter latencia na leitura de arquivos

**Prompt Otimizado**:
```
ATIVAR MODO AGENTE - AI Dev Superpowers

Projeto: {{PROJECT_NAME}}
Stack: {{STACK}}

INSTRUCAO UNICA: Leia .aidev/QUICKSTART.md

Este arquivo contem TUDO que voce precisa:
- Principios (TDD, YAGNI, DRY)
- Tabela de classificacao de intent
- Skills e agentes disponiveis
- Regras de commit

Confirme: "Modo Agente ativado. Pronto para orquestrar."
```

### Gemini CLI

**Caracteristicas**:
- Pode nao ter acesso a arquivos locais
- Melhor receber o conteudo inline

**Prompt Otimizado**:
```
ATIVAR MODO AGENTE - AI Dev Superpowers

Projeto: {{PROJECT_NAME}}
Stack: {{STACK}}

[CONTEUDO DO QUICKSTART.md INLINE]

Confirme: "Modo Agente ativado. Pronto para orquestrar."
```

---

## Implementacao

### Etapa 1: Refatorar cmd_agent (bin/aidev)

Modificar funcao `cmd_agent()` para:
1. Aceitar flags `--platform`, `--copy`, `--quick`, `--raw`
2. Detectar plataforma automaticamente se nao especificada
3. Chamar gerador especifico por plataforma

### Etapa 2: Criar geradores de prompt (lib/agent-prompts.sh)

Novo modulo com funcoes:
- `generate_claude_prompt()`
- `generate_antigravity_prompt()`
- `generate_gemini_prompt()`
- `generate_generic_prompt()`

### Etapa 3: Funcao de clipboard (lib/core.sh)

Adicionar funcao `copy_to_clipboard()`:
```bash
copy_to_clipboard() {
    local text="$1"
    if command -v pbcopy >/dev/null 2>&1; then
        echo "$text" | pbcopy
    elif command -v xclip >/dev/null 2>&1; then
        echo "$text" | xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        echo "$text" | xsel --clipboard
    else
        return 1
    fi
}
```

### Etapa 4: Atualizar templates de plataforma

Simplificar todos os templates para apontar para QUICKSTART.md:
- `CLAUDE.md.tmpl` - ja feito
- `ANTIGRAVITY.md.tmpl` - simplificar
- `GEMINI.md.tmpl` - simplificar

---

## Arquivos a Modificar/Criar

| Arquivo | Acao |
|---------|------|
| `bin/aidev` | EDITAR - refatorar cmd_agent() |
| `lib/agent-prompts.sh` | CRIAR - geradores de prompt |
| `lib/core.sh` | EDITAR - adicionar copy_to_clipboard() |
| `templates/platform/ANTIGRAVITY.md.tmpl` | EDITAR - simplificar |
| `templates/platform/GEMINI.md.tmpl` | EDITAR - simplificar |

---

## Exemplos de Uso

```bash
# Detecta plataforma automaticamente
aidev agent

# Especifica plataforma
aidev agent --platform claude-code
aidev agent -p antigravity
aidev agent -p gemini

# Copia para clipboard
aidev agent --copy
aidev agent -c

# Prompt minimo (so QUICKSTART)
aidev agent --quick
aidev agent -q

# Combinacoes
aidev agent -p antigravity -c -q

# Saida limpa para piping
aidev agent --raw | xclip -selection clipboard
```

---

## Verificacao

1. [ ] `aidev agent` detecta plataforma corretamente
2. [ ] `aidev agent -p claude-code` gera prompt otimizado
3. [ ] `aidev agent -p antigravity` gera prompt otimizado
4. [ ] `aidev agent -p gemini` inclui QUICKSTART inline
5. [ ] `aidev agent -c` copia para clipboard
6. [ ] `aidev agent -q` gera prompt minimo
7. [ ] `aidev agent --raw` saida sem decoracao

---

## Ordem de Execucao

1. **lib/core.sh** - copy_to_clipboard() (baixo risco)
2. **lib/agent-prompts.sh** - novo modulo
3. **bin/aidev** - refatorar cmd_agent()
4. **templates ANTIGRAVITY e GEMINI** - simplificar
5. **Testes** - verificar em cada plataforma

---

## Estimativa de Complexidade

| Componente | Complexidade |
|------------|--------------|
| copy_to_clipboard() | Baixa |
| agent-prompts.sh | Media |
| Refatorar cmd_agent() | Media |
| Templates | Baixa |

**Total**: Media complexidade, ~4 arquivos modificados/criados
