# aidev-superpowers-v3-1 - Instrucoes Antigravity

## AI Dev Superpowers

Este projeto usa **AI Dev Superpowers** para governanca de desenvolvimento com IA.

### Ativacao do Modo Agente

**Opcao 1 - Comando direto (recomendado):**
```bash
aidev agent | xclip -selection clipboard
```
Cole o prompt gerado aqui.

**Opcao 2 - Ativacao por trigger:**
```
"modo agente" | "aidev" | "superpowers"
```

### O que acontece ao ativar

1. **Orquestrador** coordena 9 agentes especializados
2. **TDD obrigatorio** - RED -> GREEN -> REFACTOR
3. **Skills** automatizam workflows (brainstorming, planning, code-review, debugging)
4. **Regras da stack** generic sao aplicadas

### Estrutura

```
.aidev/
├── agents/      # 9 agentes especializados
├── skills/      # 6 workflows automatizados
├── rules/       # Convencoes por stack
└── state/       # Estado persistente
```

### MCPs Disponiveis

O Antigravity tem acesso aos seguintes MCPs:
- **serena** - Analise semantica de codigo
- **basic-memory** - Memoria persistente
- **context7** - Documentacao de bibliotecas

### Agentes Disponiveis

| Agente | Responsabilidade |
|--------|------------------|
| orchestrator | Coordenacao geral |
| architect | Design e planejamento |
| backend | Implementacao server-side (TDD) |
| frontend | Implementacao client-side (TDD) |
| code-reviewer | Revisao de qualidade |
| qa | Testes e validacao |
| security-guardian | Seguranca e OWASP |
| devops | Deploy e infra |
| legacy-analyzer | Codigo legado |

### Skills Disponiveis

| Skill | Quando usar |
|-------|-------------|
| brainstorming | Nova feature ou projeto |
| writing-plans | Criar plano de implementacao |
| test-driven-development | Implementar codigo |
| code-review | Revisar PR ou codigo |
| systematic-debugging | Corrigir bugs |
| learned-lesson | Documentar aprendizados |

### Comandos CLI

| Comando | Descricao |
|---------|-----------|
| `aidev agent` | Gera prompt de ativacao |
| `aidev start` | Mostra instrucoes de ativacao |
| `aidev status` | Mostra status |
| `aidev doctor` | Diagnostico |
| `aidev snapshot` | Context passport |

---
*Gerado por AI Dev Superpowers v3*