# QUICKSTART - AI Dev Superpowers

> Arquivo consolidado para ativacao rapida do modo agente.
> Leia APENAS este arquivo ao receber "modo agente", "aidev" ou "superpowers".

---

## Principios Inegociaveis

| Principio | Descricao |
|-----------|-----------|
| **TDD** | RED -> GREEN -> REFACTOR (sempre) |
| **YAGNI** | So implemente o que foi pedido |
| **DRY** | Extraia quando repetir 3+ vezes |

---

## Classificacao de Intent

| Palavra-chave | Skill | Agente Principal |
|---------------|-------|------------------|
| "nova feature", "criar", "adicionar" | brainstorming -> writing-plans -> tdd | architect -> backend/frontend |
| "bug", "erro", "nao funciona" | systematic-debugging | backend/frontend -> qa |
| "refatorar", "melhorar", "limpar" | writing-plans -> tdd | architect -> backend/frontend |
| "revisar", "review", "PR" | code-review | code-reviewer |
| "teste", "testar", "coverage" | test-driven-development | qa |
| "seguranca", "vulnerabilidade" | - | security-guardian |
| "deploy", "pipeline", "CI/CD" | - | devops |
| "legado", "entender codigo antigo" | - | legacy-analyzer |

---

## Skills Disponiveis

| Skill | Triggers | Quando Usar |
|-------|----------|-------------|
| brainstorming | "ideia", "brainstorm", "explorar" | Nova feature ou projeto |
| writing-plans | "planejar", "plano", "roadmap" | Criar plano de implementacao |
| test-driven-development | "implementar", "codar", "TDD" | Escrever codigo |
| code-review | "revisar", "review", "PR" | Avaliar qualidade |
| systematic-debugging | "debug", "bug", "erro" | Investigar problemas |
| learned-lesson | "aprendizado", "retrospectiva" | Documentar licoes |

---

## Regras de Commit

```
tipo(escopo): descricao em portugues

- Detalhe opcional
```

**OBRIGATORIO**: Portugues, sem emojis, sem Co-Authored-By

Tipos: `feat` | `fix` | `refactor` | `test` | `docs` | `chore`

---

## Checklist de Inicio de Sessao

1. [ ] Identifiquei o intent do usuario
2. [ ] Selecionei skill apropriada
3. [ ] Deleguei para agente especializado
4. [ ] TDD: teste ANTES do codigo

---

## Estado Persistente

- `.aidev/state/session.json` - Estado da sessao
- `.aidev/state/lessons/` - Licoes aprendidas
- `.aidev/memory/kb/` - Base de conhecimento

---

## Agentes

| Agente | Papel |
|--------|-------|
| orchestrator | Coordena tudo |
| architect | Design e planejamento |
| backend | Server-side (TDD) |
| frontend | Client-side (TDD) |
| code-reviewer | Qualidade e padroes |
| qa | Testes e validacao |
| security-guardian | Seguranca OWASP |
| devops | Deploy e infra |
| legacy-analyzer | Codigo legado |

---

**Confirmacao**: "Modo Agente ativado. Pronto para orquestrar."