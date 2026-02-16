# aidev-superpowers-v3-1 - Instruções Claude Code

## AI Dev Superpowers

Este projeto usa **AI Dev Superpowers** para governança de desenvolvimento com IA.

### Ativação do Modo Agente

Para ativar o orquestrador com todos os padrões e agentes especializados, diga:

```
"modo agente" | "aidev" | "superpowers"
```

### O que acontece ao ativar

1. **Orquestrador** coordena 12 agentes especializados
2. **TDD obrigatório** - RED → GREEN → REFACTOR
3. **Skills** automatizam workflows (brainstorming, planning, debugging)
4. **Regras da stack** generic são aplicadas

### Estrutura

```
.aidev/
├── agents/      # 12 agentes especializados
├── skills/      # 8 workflows automatizados
├── rules/       # Convenções por stack
└── state/       # Estado persistente
```

### Referência Rápida

| Comando | Descrição |
|---------|-----------|
| "modo agente" | Ativa orquestrador completo |
| "brainstorming" | Inicia sessão de ideação |
| "planejar" | Cria plano de implementação |
| "debug" | Debugging sistemático |

---

## Padrão de Commit (OBRIGATÓRIO)

**TODAS** as mensagens de commit DEVEM seguir este padrão:

```
tipo(escopo): descrição curta em português
```

### Regras Inegociáveis
- **Idioma**: PORTUGUÊS (Brasil) - obrigatório
- **Emojis**: PROIBIDOS
- **Co-autoria**: PROIBIDA (sem Co-Authored-By)
- **Formato**: Conventional Commits

### Tipos Permitidos
| Tipo | Uso |
|------|-----|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `refactor` | Mudança de código sem nova funcionalidade |
| `test` | Adição ou ajuste de testes |
| `docs` | Documentação |
| `chore` | Manutenção e tarefas auxiliares |

### Exemplos
```
feat(auth): adiciona autenticação JWT
fix(api): corrige validação de email
refactor(utils): extrai função de formatação
chore(session): salva checkpoint de continuidade
```

### PROIBIDO
```
# ERRADO - emoji
feat(auth): ✨ adiciona autenticação

# ERRADO - inglês
feat(auth): add authentication

# ERRADO - co-autoria
feat(auth): adiciona auth

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Session Management

- Ao atingir rate/context limits, IMEDIATAMENTE crie checkpoint em `.aidev/state/checkpoint.md` com: estado atual, trabalho concluído, tarefas restantes, próximo passo exato para retomar.
- Ao iniciar sessão, verifique se existe `.aidev/state/checkpoint.md` e retome sem re-explorar contexto já documentado.
- A cada milestone concluído, atualize o checkpoint.

## Debugging Rules

- Ao corrigir bug, OBRIGATORIAMENTE siga `.aidev/skills/systematic-debugging/SKILL.md` (4 fases: REPRODUCE → ISOLATE → ROOT CAUSE → FIX).
- NUNCA tente fixes especulativos. Reproduza → Isole → Identifique causa raiz → Apresente diagnóstico → Só então corrija.
- Se o mesmo fix falhar 2x, PARE e mude a abordagem completamente.
- PROIBIDO: refatorar, planejar upgrades, ou explorar código não relacionado durante debugging.

## Task Execution Rules

- NÃO pivote para planejamento, refatoração ou upgrade quando pedido para corrigir funcionalidade específica.
- Resolva o pedido exato PRIMEIRO. Sugira melhorias SEPARADAMENTE depois.
- Ao receber pedido ambíguo, pergunte antes de assumir escopo maior.

## Git Safety

- Antes de `git push`, execute: `gh auth status` e `git remote -v`.
- Se auth falhar, informe IMEDIATAMENTE ao invés de tentar push.
- Commits seguem OBRIGATORIAMENTE o padrão definido acima.

---
*Gerado por AI Dev Superpowers v3*
