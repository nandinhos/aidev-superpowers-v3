# Mesa de Debates - 3 Ideias para AI Dev Superpowers

**Data**: 2026-02-23
**Modelo**: GLM-5-Free
**Participantes**: Orquestrador + 6 Agentes Especialistas
**Objetivo**: Veredito sobre implementação de 3 features do backlog

---

## Resumo das 3 Ideias

| # | Feature | Causa Raiz | Complexidade |
|---|---------|------------|--------------|
| 1 | **Learned Lesson Trigger Gap** | Triggers YAML existem mas não há engine que os consuma | ALTA |
| 2 | **MCP Standardized Activation** | Detecção de stack e ativação de MCPs é manual | MÉDIA |
| 3 | **Rules Engine Standardization** | Regras em `.aidev/rules/` não são injetadas no contexto da LLM | ALTA |

**Convergência Crítica**: As 3 features compartilham a mesma causa raiz: **configuração declarativa existe, mas não há runtime que a consuma**.

---

## Análise por Agente Especialista

### 1. Architect — Visão de Sistema

**Posicionamento**: FAVORÁVEL com ressalvas arquiteturais

**Análise**:
```
┌─────────────────────────────────────────────────────────────┐
│                    RUNTIME ENGINE (Core)                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Trigger   │  │    Stack    │  │    Rules    │        │
│  │   Engine    │  │  Detector   │  │   Loader    │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                │                │                │
│         ▼                ▼                ▼                │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              CONFIG LAYER (YAML/MD)                  │  │
│  │  triggers/*.yaml  │  rules/*.md  │  mcp-registry.yaml │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Trade-offs Identificados**:
- (+) Reutilização: Stack Detector serve Rules Loader e MCP Activation
- (+) Extensibilidade: Novos triggers/regras sem mudar código core
- (-) Complexidade inicial: 3 engines a implementar
- (-) Testabilidade: Mais pontos de falha

**Recomendação**: Implementar **Runtime Engine unificado** que consuma as 3 configurações. Prioridade: Stack Detector (compartilhado) → Rules Loader → Trigger Engine → MCP Activation.

---

### 2. Legacy Analyzer — Análise de Débito Técnico

**Posicionamento**: CRÍTICO mas NECESSÁRIO

**Análise de Gap Atual**:

| Componente | Estado | Débito |
|------------|--------|--------|
| `lesson-capture.yaml` | Existe, não consumido | DEAD CODE |
| `generic.md` (rules) | Existe, não injetado | IGNORED |
| Detecção de stack | Não existe | MISSING |
| Validação de commit | Manual | INCONSISTENTE |

**Incidente DAS (Lição não capturada)**:
- Trigger `debug-success-keywords` definido com keywords corretas
- Keywords "resolvido", "corrigimos" presentes na conversa
- **Resultado**: Nenhuma ativação → lição salva manualmente em local incorreto

**Risco de Não Implementar**:
- Continuar acumulando configuração não-funcional
- LLMs ignorando regras existentes
- Retrabalho por lições não capturadas
- Duplicação de padrões em locais não-canônicos

**Recomendação**: Priorizar **Trigger Engine** primeiro — impacto imediato no fluxo de lições aprendidas.

---

### 3. QA — Estratégia de Testes

**Posicionamento**: EXIGE TDD RIGOROSO

**Cenários de Teste Obrigatórios**:

```
Feature 1: Trigger Engine
├── test_trigger_yaml_parsing
├── test_keyword_matching_with_confidence
├── test_cooldown_between_triggers
├── test_skill_activation_flow
└── test_lesson_validation_post_save

Feature 2: Stack Detector
├── test_detect_laravel_from_composer_json
├── test_detect_nodejs_from_package_json
├── test_detect_python_from_requirements_txt
├── test_unknown_stack_returns_empty
└── test_multiple_stacks_detection

Feature 3: Rules Loader
├── test_load_generic_rules_always
├── test_load_stack_rules_conditional
├── test_precedence_project_over_stack_over_global
├── test_commit_format_validation
└── test_anti_duplication_detection
```

**Critérios de Aceitação**:
- Cobertura mínima: 80%
- Todos os edge cases cobertos
- Testes de integração entre engines
- Mock de MCPs para testes unitários

**Recomendação**: Seguir **RED → GREEN → REFACTOR** rigorosamente. Começar pelos testes de Stack Detector (menor escopo).

---

### 4. Security Guardian — Análise de Segurança

**Posicionamento**: PREOCUPAÇÃO com Runtime Interpretation

**Riscos Identificados**:

| Risco | Severidade | Mitigação |
|-------|------------|-----------|
| YAML parsing (code injection) | ALTA | Usar parser seguro, sandbox |
| Regex em triggers (ReDoS) | MÉDIA | Validar patterns, timeout |
| Execução de comandos MCP | CRÍTICA | Whitelist, validação de path |
| Exposição de regras no contexto | BAIXA | Sanitização de paths |

**Análise do MCP Activation**:
```yaml
# RISCO: Comando dinâmico
docker exec -i -u {UID}:{GID} {CONTAINER} php artisan boost:mcp

# VALIDAÇÕES NECESSÁRIAS:
# 1. Container name deve ser alfanumérico + traços
# 2. UID/GID devem ser numéricos
# 3. Comando deve estar em whitelist
```

**Recomendação**: Implementar **validação rigorosa** de inputs antes de qualquer execução. Criar whitelist de comandos MCP permitidos.

---

### 5. DevOps — Implementação e Infraestrutura

**Posicionamento**: PRAGMÁTICO

**Análise de Complexidade por Feature**:

| Feature | Estimativa | Dependências | Bloqueadores |
|---------|------------|--------------|--------------|
| Stack Detector | 2-3h | Nenhum | Nenhum |
| Rules Loader | 4-6h | Stack Detector | Nenhum |
| Trigger Engine | 6-8h | Parser YAML | Nenhum |
| MCP Activation | 3-4h | Stack Detector | Validação de segurança |
| Lesson Validator | 2-3h | Trigger Engine | Nenhum |

**Pipeline de Implementação Proposta**:
```
Sprint 1: Stack Detector (shared foundation)
    ↓
Sprint 2: Rules Loader (usa Stack Detector)
    ↓
Sprint 3: Trigger Engine (independente)
    ↓
Sprint 4: MCP Activation (usa Stack Detector)
    ↓
Sprint 5: Lesson Validator (usa Trigger Engine)
    ↓
Sprint 6: Integração + Dashboard
```

**Recomendação**: Implementar em **sprints incrementais**, começando pelo Stack Detector (shared dependency).

---

### 6. Code Reviewer — Qualidade e Manutenibilidade

**Posicionamento**: EXIGE PADRONIZAÇÃO

**Análise de Estrutura Proposta**:

```
.aidev/
├── engine/
│   ├── trigger-processor.sh      # Engine de triggers
│   ├── stack-detector.sh         # Detector de stack
│   ├── rules-loader.sh           # Loader de regras
│   └── lesson-state-machine.sh   # State machine
├── config/
│   ├── mcp-registry.yaml         # Registry de MCPs
│   └── rules-taxonomy.yaml       # Taxonomia de regras
├── skills/
│   ├── trigger-engine.md         # Skill de trigger
│   ├── rules-injection.md        # Skill de regras
│   └── lesson-validator.md       # Skill de validação
└── templates/
    ├── mcp-json-base.json        # Template base MCP
    └── mcp-json-laravel.json     # Template Laravel
```

**Problemas Identificados**:
1. **Inconsistência**: Alguns specs em `.md`, outros em `.sh`
2. **Documentação**: Skills misturam spec com workflow
3. **Validação**: Sem schema para YAML configs

**Recomendação**: Criar **schemas JSON** para validar configurações YAML. Separar specs (`engine/*.md`) de implementação (`lib/*.sh`).

---

## Mesa de Debates — Pontos de Convergência

### Debate 1: Ordem de Implementação

| Agente | Posição | Justificativa |
|--------|---------|---------------|
| Architect | Stack Detector primeiro | É dependência compartilhada |
| Legacy Analyzer | Trigger Engine primeiro | Impacto imediato em lições |
| DevOps | Stack Detector primeiro | Menor complexidade, base para outros |
| QA | Stack Detector primeiro | Menor escopo de testes |
| Security | MCP Activation por último | Precisa de validação completa |

**CONSENSO**: Implementar **Stack Detector primeiro** (base compartilhada), depois **Rules Loader** (usa Stack Detector), depois **Trigger Engine** (independente).

---

### Debate 2: Arquitetura Unificada vs Separada

| Opção | Votos | Argumentos |
|-------|-------|------------|
| **Runtime Engine Unificado** | 4/6 | Reutilização, manutenção centralizada |
| **Engines Separados** | 2/6 | Menor coupling, testes isolados |

**DECISÃO**: **Runtime Engine Unificado** com módulos independentes. Cada engine é um módulo, mas compartilha infraestrutura (config loader, logger, state).

---

### Debate 3: Prioridade de Features para Usuário

| Prioridade | Feature | Valor para Usuário |
|------------|---------|-------------------|
| 1 | Rules Loader | Regras aplicadas automaticamente |
| 2 | Trigger Engine | Lições capturadas automaticamente |
| 3 | MCP Activation | Setup mais rápido |

**CONSENSO**: Manter ordem técnica (Stack Detector → Rules → Triggers → MCP).

---

## Veredito Final

### Decisão: IMPLEMENTAR as 3 Features

**Justificativa**: As 3 features são necessárias, compartilham causa raiz, e podem ser implementadas incrementalmente com código reutilizável.

---

### Plano de Implementação

#### Fase 1: Fundação Compartilhada (Sprint 1)

**Feature**: Stack Detector

**Artefatos**:
- `.aidev/engine/stack-detector.sh`
- `.aidev/skills/stack-detector.md`
- Testes em `tests/unit/test-stack-detector.sh`

**Critérios**:
- Detecta Laravel, Node.js, Python, Go, Rust
- Retorna lista de stacks detectadas
- 100% cobertura de testes

---

#### Fase 2: Rules Engine (Sprint 2-3)

**Feature**: Rules Loader + Validator

**Artefatos**:
- `.aidev/engine/rules-loader.sh`
- `.aidev/engine/rules-validator.sh`
- `.aidev/config/rules-taxonomy.yaml`
- `.aidev/skills/rules-injection.md`

**Critérios**:
- Regras globais carregadas em toda sessão
- Regras de stack carregadas condicionalmente
- Precedência: projeto > stack > global
- Validação de formato de commit (português, sem emoji, sem co-autoria)

---

#### Fase 3: Trigger Engine (Sprint 4-5)

**Feature**: Trigger Processor + Lesson State Machine

**Artefatos**:
- `.aidev/engine/trigger-processor.sh`
- `.aidev/engine/lesson-state-machine.sh`
- `.aidev/skills/trigger-engine.md`
- `.aidev/skills/lesson-validator.md`

**Critérios**:
- Parser de `triggers/*.yaml`
- Keyword matching com confidence score
- Cooldown entre triggers respeitado
- Skill `learned-lesson` ativado automaticamente
- Validação de artefatos de lição

---

#### Fase 4: MCP Activation (Sprint 6)

**Feature**: MCP Registry + Generator + Health Check

**Artefatos**:
- `.aidev/config/mcp-registry.yaml`
- `.aidev/skills/mcp-activation.md`
- `.aidev/skills/mcp-health-check.md`
- `.aidev/templates/mcp-json-base.json`
- `.aidev/templates/mcp-json-laravel.json`

**Critérios**:
- MCPs universais configurados automaticamente
- Detecção de stack ativa MCPs condicionais
- `.mcp.json` gerado sem edição manual
- Validação de conectividade

---

#### Fase 5: Integração (Sprint 7)

**Feature**: Dashboard + Orchestration

**Artefatos**:
- Dashboard de compliance
- Integração com activation-snapshot
- Atualização do orquestrador

---

### Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Parser YAML complexo | Média | Alto | Usar biblioteca existente (yq) |
| Performance no startup | Baixa | Médio | Cache de configuração |
| Falsos positivos em triggers | Média | Médio | Confidence threshold ajustável |
| MCPs incompatíveis | Baixa | Alto | Health check obrigatório |

---

### Estimativa Total

| Fase | Tempo | Dependências |
|------|-------|--------------|
| Fase 1 (Stack Detector) | 3-4h | Nenhuma |
| Fase 2 (Rules Engine) | 8-10h | Fase 1 |
| Fase 3 (Trigger Engine) | 10-12h | Parser YAML |
| Fase 4 (MCP Activation) | 5-6h | Fase 1 |
| Fase 5 (Integração) | 4-5h | Fases 1-4 |
| **TOTAL** | **30-37h** | — |

---

### Próximos Passos

1. **Imediato**: Criar `aidev start stack-detector-engine`
2. **Após Stack Detector**: Iniciar Rules Loader
3. **Paralelo**: Documentar ADRs para decisões arquiteturais

---

## Assinaturas dos Agentes

| Agente | Posição | Aprovação |
|--------|---------|-----------|
| Orchestrator | Moderador | ✅ |
| Architect | Favorável | ✅ |
| Legacy Analyzer | Crítico/Necessário | ✅ |
| QA | Exige TDD | ✅ |
| Security Guardian | Preocupado | ✅ (com mitigações) |
| DevOps | Pragmático | ✅ |
| Code Reviewer | Exige Padronização | ✅ |

---

## Conclusão

**VEREDITO**: Implementar as 3 features em ordem de dependência técnica, começando pelo Stack Detector como fundação compartilhada. Seguir TDD rigoroso, validar segurança em cada fase, e documentar ADRs.

**Benefício Esperado**:
- Regras aplicadas automaticamente (fim de violações de commit)
- Lições capturadas automaticamente (fim de gap de conhecimento)
- MCPs configurados automaticamente (onboarding < 30s)

---

*Documento gerado pelo Orquestrador AI Dev Superpowers v4.5.6*
*Modelo: GLM-5-Free*
*Data: 2026-02-23*
