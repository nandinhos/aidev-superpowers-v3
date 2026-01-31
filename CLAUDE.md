# aidev-superpowers-v3-1 - Instruções Claude Code

## AI Dev Superpowers

Este projeto usa **AI Dev Superpowers** para governança de desenvolvimento com IA.

### Ativação do Modo Agente

Para ativar o orquestrador com todos os padrões e agentes especializados, diga:

```
"modo agente" | "aidev" | "superpowers"
```

### O que acontece ao ativar

1. **Orquestrador** coordena 8 agentes especializados
2. **TDD obrigatório** - RED → GREEN → REFACTOR
3. **Skills** automatizam workflows (brainstorming, planning, debugging)
4. **Regras da stack** generic são aplicadas

### Estrutura

```
.aidev/
├── agents/      # 8 agentes especializados
├── skills/      # Workflows automatizados
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
*Gerado por AI Dev Superpowers v3*