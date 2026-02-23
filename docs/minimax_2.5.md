# Mesa de Debates - Veredito sobre Backlog

**Data:** 2026-02-23  
**Orquestrador:** AI Dev Superpowers  
**Participantes:** Architect, DevOps, Code-Reviewer

---

## Resumo Executivo

| Ideia | Viabilidade | Complexidade | Recomendação |
|-------|-------------|--------------|---------------|
| 1. Learned Lesson Trigger Gap | Alta (70% existe) | 3/5 | Postergável |
| 2. MCP Standardized Activation | Alta (70% existe) | 3/5 | **IMPLEMENTAR** |
| 3. Rules Engine Standardization | Alta | 4/5 | Postergável |

---

## Análise por Ideia

### 1. Gap no Fluxo de Lições Aprendidas

**Arquivo:** `.aidev/plans/backlog/learned-lesson-trigger-gap.md`

**Análise do Architect:**
- **Viabilidade:** VIÁVEL com ressalvas (orquestrador é documentação, não engine)
- **Dependências:** 70% existem (YAML + Skill + State)
- **Complexidade:** 3/5
- **Timing:** POSTERIORMENTE
- **Conflitos:** 2 MEDIUM, 3 LOW (mitigáveis)

**Veredito:** ❌ **ADIAR**

**Justificativa:**
1. O workflow atual funciona (acionamento manual)
2. O orquestrador é um documento markdown, não um engine executável
3. A solução proposta assume arquitetura de runtime que não existe
4. Workarounds imediatos: CLI helper `aidev lesson` ou integração no systematic-debugging

---

### 2. Padronização de Ativação de MCPs

**Arquivo:** `.aidev/plans/backlog/mcp-standardized-activation.md`

**Análise do DevOps:**
- **Viabilidade:** ALTA (base 70% pronta)
- **Dependências:** ~70% reutilizáveis
  - `mcp-detect.sh` ✅
  - `mcp-config-generator.sh` ✅
  - `docker-discovery.sh` ✅
- **Complexidade:** 3/5
- **Timing:** **IMPLEMENTAR AGORA**

**Veredito:** ✅ **IMPLEMENTAR**

**Justificativa:**
1. Alto ROI - automatiza processo manual repetitivo
2. Sem bloqueantes - todas dependências já existem
3. Risco baixo - funcionalidade incremental
4. Scripts já comprovados no projeto DAS

---

### 3. Rules Engine: Carregamento, Injeção e Validação de Regras

**Arquivo:** `.aidev/plans/backlog/rules-engine-standardization.md`

**Análise do Code-Reviewer:**
- **Viabilidade:** ALTA
- **Dependências:** 60% (CLAUDE.md existe, regras existem, detector de stack NÃO existe)
- **Complexidade:** 4/5
- **Timing:** POSTERIORMENTE (após MCP backlog)
- **Conflitos:** 2 ALTOS (livewire.md não existe, runtime inexistente)

**Veredito:** ❌ **ADIAR**

**Justificativa:**
1. Depende de detector de stack (backlog MCP)
2. Depende de trigger engine (backlog learned-lesson)
3. `livewire.md` não existe - pré-requisito faltante
4. CLAUDE.md já mitiga parcialmente o problema para Claude Code
5. ROI menor comparado ao backlog MCP

---

## Convergências Identificadas

Todas as 3 ideias compartilham **mesma causa raiz**: configuração declarativa existe, mas nenhum runtime a consome.

| Backlog | Dependência Compartilhada |
|---------|---------------------------|
| MCP Activation | Detector de stack |
| Rules Engine | Detector de stack |
| Learned Lesson | Trigger engine |

---

## Plano de Execução Recomendado

### Fase 1: Implementar MCP Standardized Activation

**Prioridade:** ALTA  
**Complexidade:** 3/5  
**Sprints estimados:** 1-2

Tarefas:
1. [HIGH] Classificação de MCPs → `.aidev/config/mcp-registry.yaml`
2. [HIGH] Detector de stack → `.aidev/skills/stack-detector.md`
3. [HIGH] Gerador `.mcp.json` → templates + scripts
4. [MEDIUM] Validação de conectividade
5. [LOW] Workflow de onboarding

**Arquivos a criar:**
- `.aidev/config/mcp-registry.yaml`
- `.aidev/skills/stack-detector.md`
- `.aidev/templates/mcp-json-base.json`
- `.aidev/templates/mcp-json-laravel.json`

---

### Fase 2: Rules Engine (após Fase 1)

**Pré-requisitos:**
- Detector de stack implementado (reutilizar da Fase 1)
- `livewire.md` criado em `.aidev/rules/`

---

### Fase 3: Learned Lesson Trigger (opcional)

**Pré-requisitos:**
- Trigger engine definida
- Arquitetura de runtime do orquestrador evoluída

**Alternativa imediata:** CLI helper `aidev lesson`

---

## Decisão Final

| Ação | Destino |
|------|---------|
| MCP Standardized Activation | → `features/` para planejamento |
| Rules Engine | Manter no backlog |
| Learned Lesson Trigger | Manter no backlog |

---

## Próximos Passos Imediatos

1. Executar `aidev start mcp-standardized-activation` para promover ideia para feature
2. Criar `.aidev/rules/livewire.md` como preparação para Fase 2
3. Documentar decisão em checkpoint

---

*Veredito emitido pelo Orquestrador em 2026-02-23*
