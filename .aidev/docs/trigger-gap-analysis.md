# Análise do Gap: Triggers YAML → Ativação de Skills

> Data: 2026-02-26 | Status: RESOLVIDO (consolidação v2.0)

## Problema Identificado

O sistema de triggers para captura automática de lições aprendidas possuía
configuração YAML completa (`.aidev/triggers/lesson-capture.yaml`) com 4 triggers
funcionais, mas existiam **duas implementações paralelas desconectadas**:

1. **Módulo global** (`lib/triggers.sh`) — integrado ao `bin/aidev` via `load_module`
2. **Scripts locais** (`.aidev/lib/trigger-processor.sh` e `lesson-state-machine.sh`) — nunca carregados

### Causa Raiz

Uma sessão anterior criou os scripts locais em `.aidev/lib/` sem verificar que
`lib/triggers.sh` já implementava as mesmas funcionalidades. Resultado: duplicação
de código com zero integração.

### Incidente de Referência

- **Projeto**: DAS (2026-02-22)
- **Bug**: Livewire+Alpine morph conflict
- **Commit**: `56bfea9`
- **Keywords presentes**: "resolvido", "bug fix", "corrigimos"
- **Skill ativado**: NÃO — apesar do módulo global estar carregado, faltavam
  a state machine de rastreamento e o validador pós-captura

## Resolução

### Consolidação no Módulo Global (v2.0)

Toda funcionalidade foi consolidada em `lib/triggers.sh`:

| Componente | Antes | Depois |
|------------|-------|--------|
| Parser YAML | ✅ `triggers__load()` | ✅ (mantido) |
| Detecção de keywords | ✅ `triggers__detect_intent()` | ✅ (mantido) |
| Error patterns | ✅ `triggers__watch_errors()` | ✅ (mantido) |
| Cooldown | ✅ `triggers__is_on_cooldown()` | ✅ (mantido) |
| **State Machine** | ❌ (só existia no duplicado) | ✅ `triggers__lesson_transition()` |
| **Validador** | ❌ (não existia) | ✅ `triggers__validate_lesson()` |

### Arquivos Removidos (duplicados)

- `.aidev/lib/trigger-processor.sh` (292 linhas — substituído por `lib/triggers.sh`)
- `.aidev/lib/lesson-state-machine.sh` (259 linhas — incorporado em `lib/triggers.sh`)

### Prevenção

Para evitar duplicação futura, a regra `.aidev/rules/generic.md` deve incluir:
> "Antes de criar scripts em `.aidev/lib/`, verificar se funcionalidade equivalente
> já existe em `lib/` (módulos globais carregados via `load_module`)."
