# Feature - Avaliação e Evolução das Skills Atuais

> Status: **CONCLUÍDO** | Finalizado: 2026-02-26

## Visão Geral

Avaliar se as skills atuais são meros arquivos de referência (.md) ou ferramentas acionáveis. O objetivo é entender o real poder das skills e evoluí-las para que sejam ferramentas efetivas do "canivete suíço" do desenvolvedor.

**Origem**: Observação do usuário em 2026-02-25. Skills são arquivos .md mas deveriam ser tools acionáveis.

---

## Análise do Status Atual

### O que são as skills hoje

Analisando `.aidev/skills/*/SKILL.md`:

| Skill | Tipo Atual | Steps | checkpoint s | Ação Real |
|-------|-----------|-------|--------------|-----------|
| `brainstorming` | .md referência | ? | ? | LLM lê o arquivo |
| `test-driven-development` | .md referência | 3 | 3 | LLM lê o arquivo |
| `systematic-debugging` | .md referência | 4 | 4 | LLM lê o arquivo |
| `learned-lesson` | .md referência | 4 | 4 | LLM lê o arquivo |
| `writing-plans` | .md referência | ? | ? | LLM lê o arquivo |
| `code-review` | .md referência | ? | ? | LLM lê o arquivo |
| `release-management` | .md referência | ? | ? | LLM lê o arquivo |
| `meta-planning` | .md referência | ? | ? | LLM lê o arquivo |

**Problema identificado**: Skills são documentos que a LLM lê, não ferramentas que executam ações.

---

## Problema Atual

1. **Skills são passivas**: LLM lê o .md, mas skill não "faz" nada
2. **Sem execução automática**: Não há CLI commands que acionem a skill
3. **Dependência da LLM**: Tudo depende de a LLM seguir o que está no .md
4. **Checkpoints manuais**: Checkpoints existem no papel mas não são automatizados
5. **Sem tracking**: Sistema não rastreia em qual step a skill está

---

## O que Precisamos

### Skills como Ferramentas Acionáveis

```
Skill Passiva (atual):    Usuário → LLM → Lê .md → Segue manual
Skill Ativa (objetivo):   Usuário → CLI → Skill executa → Retorna resultado
```

### Capabilities Esperadas

| Capability | Descrição | Exemplo |
|------------|-----------|---------|
| `skill start <name>` | Iniciar skill com tracking | `skill start tdd` |
| `skill step <n>` | Avançar para step N | `skill step 2` |
| `skill complete` | Finalizar skill | `skill complete` |
| `skill status` | Ver estado atual | `skill status` |
| `skill validate` | Validar checkpoint | `skill validate` |
| `skill fail <reason>` | Marcar falha | `skill fail "erro"` |

---

## Tarefas Prioritárias

### 1. [HIGH] Mapeamento de Skills Existentes

**Descrição**: Documentar o estado atual de cada skill

**Detalhes técnicos**:
- Listar todas as skills em `.aidev/skills/`
- Para cada: steps, checkpoints, triggers, artifacts
- Identificar gaps (quais não têm esses dados)
- Classificar: completa / incompleta /Missing

**Arquivo esperado**:
- `.aidev/docs/skills-inventory.md`

**Critério de sucesso**: Visão completa do que existe

---

### 2. [HIGH] Transformar Skills em Ferramentas CLI

**Descrição**: Criar interface CLI para skills

**Detalhes técnicos**:
- Novo subcomando: `aidev skill <action> [params]`
- Ações:
  - `aidev skill list` - listar skills
  - `aidev skill start <name>` - iniciar skill
  - `aidev skill step <n>` - avançar step
  - `aidev skill complete` - finalizar
  - `aidev skill status` - ver estado
- Salvar estado em `.aidev/state/skills.json`
- Atualizar unified.json com skill ativa

**Arquivos esperados**:
- `bin/aidev` (skill subcommand)
- `.aidev/lib/skill-runner.sh`

**Critério de sucesso**: Skills executáveis via CLI

---

### 3. [MEDIUM] Adicionar Checkpoints Automáticos

**Descrição**: Validar progresso em cada checkpoint

**Detalhes técnicos**:
- Ao executar `skill step N`:
  - Validar pré-requisitos do step
  - Se não satisfeito, bloquear avanço
  - Registrar checkpoint em skills.json
- Checklist de validação por skill:
  - TDD: teste existe? compila?
  - Debugging: bug reproduzido?
  - Code Review: implementation complete?

**Critério de sucesso**: Skill só avança se condições atendidas

---

### 4. [MEDIUM] Handoff Automático entre Skills

**Descrição**: Quando uma skill termina, ativar próxima

**Detalhes técnicos**:
- Em skill metadata, definir `next_skill`
- Ao completar:
  - Mostrar "Próxima skill sugerida: X"
  - Oferecer: `skill start X`
- Chain: brainstorming → writing-plans → TDD → code-review

**Critério de sucesso**: Fluxo contínuo entre skills

---

### 5. [LOW] Dashboard de Skills

**Descrição**: Visão de skills por projeto

**Detalhes técnicos**:
- `aidev skills --dashboard`
- Mostrar:
  - Skills disponíveis
  - Skill ativa atual
  - Histórico de execuções
  - Success rate
  - Duração média

**Critério de sucesso**: Visibilidade do uso de skills

---

## Evolução Proposta

### Fase 1: Mapeamento
- Inventário completo das skills
- Identificar gaps

### Fase 2: CLI Interface
- `aidev skill` commands
- Tracking de estado

### Fase 3: Automação
- Checkpoints automáticos
- Handoff entre skills

### Fase 4: Intelligence
- Sugestão de skill baseada em intent
- Auto-chain de skills

---

## Dependências

- `.aidev/skills/*/SKILL.md`
- `bin/aidev`
- `.aidev/state/skills.json`
- `.aidev/lib/workflow-sync.sh`

---

## Critérios de Aceitação

1. ✅ Inventário completo de skills existente
2. ✅ Skills executáveis via CLI (`aidev skill start <name>`)
3. ✅ Checkpoints validados automaticamente
4. ✅ Handoff entre skills funciona
5. ✅ Dashboard disponível
6. ✅ Skills evoluem de "documentos" para "ferramentas"

---

## Observações

- **Canivete suíço**: Cada skill = ferramenta específica
- **Acionável**: Não depende de a LLM "lembrar" do .md
- **Rastreável**: Sistema sabe exatamente onde você está
- **Evolutivo**: Com hooks, skills ficam mais inteligentes

---

## Referências

- Skills atuais: `.aidev/skills/*/SKILL.md`
- Exemplo de metadata: learned-lesson/SKILL.md (lines 1-25)
- Feature lifecycle: como referência de implementação
