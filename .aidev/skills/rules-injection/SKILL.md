---
name: rules-injection
description: Carrega e injeta regras de codificação no contexto da sessão LLM
version: 1.0.0
triggers:
  - "carregar regras"
  - "regras do projeto"
  - "rules engine"
  - "injetar regras"
  - "verificar regras"
globs:
  - ".aidev/rules/**"
  - ".aidev/config/rules-taxonomy.yaml"
  - ".aidev/engine/rules-loader.sh"
steps: 3
checkpoints:
  - stack_detected
  - rules_loaded
  - injection_confirmed
---

# Skill: Rules Injection

## Propósito

Garantir que toda sessão LLM inicia com as regras de codificação corretas
carregadas e acessíveis. Previne violações por falta de contexto (incidente
de referência: projeto DAS, 2026-02-22).

## Quando Ativar

- Ao iniciar nova sessão de desenvolvimento
- Quando suspeitar que regras não estão sendo seguidas
- Antes de iniciar feature nova
- Após `aidev start <feature-id>`

## Protocolo de 3 Fases

### Fase 1 — Detectar Stack [checkpoint: stack_detected]

```bash
source .aidev/engine/rules-loader.sh
STACK=$(rules_detect_stack)
echo "Stack detectada: $STACK"
```

**Verificar**:
- [ ] Stack correta para o projeto?
- [ ] Arquivo de regras de stack existe em `.aidev/rules/$STACK.md`?

Se stack incorreta: ajuste manual em `.aidev/config/rules-taxonomy.yaml`

---

### Fase 2 — Carregar Regras [checkpoint: rules_loaded]

```bash
rules_load_all
rules_summary
```

**Verificar**:
- [ ] Camada `limits` carregada (llm-limits.md)
- [ ] Camada `global` carregada (generic.md)
- [ ] Camada `stack` carregada (se aplicável)
- [ ] Camada `project` carregada (se project.md existir)

**Regras críticas que devem estar carregadas**:
| Regra | Severidade | Scope |
|-------|-----------|-------|
| commit-format | error | commit |
| feature-lifecycle | error | file-creation |
| tdd-mandatory | warning | code-edit |
| max-files-per-cycle | error | file-creation |
| language-pt | warning | always |

---

### Fase 3 — Confirmar Injeção [checkpoint: injection_confirmed]

Para Claude Code, verifique se CLAUDE.md contém as regras:

```bash
grep -q "Regras Injetadas pelo Rules Engine" CLAUDE.md && \
  echo "✓ Regras presentes no CLAUDE.md" || \
  echo "⚠ Regras ausentes — execute: rules_inject_claude_md"
```

Se ausentes:
```bash
rules_inject_claude_md
```

---

## Regras de Prioridade Alta (sempre verificar)

### commit-format (ERRO se violado)
- Idioma: **português (Brasil)**
- Formato: `tipo(escopo): descrição`
- Emojis: **PROIBIDOS**
- Co-autoria: **PROIBIDA**

### feature-lifecycle (ERRO se violado)
- Nunca usar `cp`, `mv` para mover arquivos de plano
- Sempre usar `aidev start` → `aidev done` → `aidev complete`

### tdd-mandatory (WARNING)
- RED: escreva o teste que falha primeiro
- GREEN: mínimo código para passar
- REFACTOR: limpe sem quebrar

---

## Anti-Duplicação (prevenir incidente DAS)

Se detectar arquivo com conteúdo de regras fora de `.aidev/rules/`:
```
Padrões suspeitos: "regras", "rules", "standards", "conventions", "guidelines"
Locais não-canônicos: qualquer lugar fora de .aidev/rules/
```

**Ação**:
1. Alertar usuário: "Arquivo de regras detectado em local não-canônico"
2. Sugerir: "Mova/merge para `.aidev/rules/{nome-correto}.md`"
3. Aguardar autorização antes de qualquer merge

---

## Integração com Orquestrador

O orquestrador deve invocar esta skill automaticamente:
- Ao iniciar nova sessão (`aidev agent`)
- Após `aidev start <feature>` (nova feature, novo contexto)

Configurar em `.aidev/agents/orchestrator.md`:
```
skills_auto_load:
  - rules-injection  # carrega ao iniciar sessão
```

---

## Referências

- Taxonomia: [.aidev/config/rules-taxonomy.yaml](../../config/rules-taxonomy.yaml)
- Loader: [.aidev/engine/rules-loader.sh](../../engine/rules-loader.sh)
- Regras globais: [.aidev/rules/generic.md](../../rules/generic.md)
- Limites LLM: [.aidev/rules/llm-limits.md](../../rules/llm-limits.md)
- Incidente de referência: projeto DAS, 2026-02-22/23
