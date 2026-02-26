# Trigger Engine — Especificação Técnica

> Versão: 2.0.0 | Status: Consolidado em `lib/triggers.sh`

## Visão Geral

Engine unificada que processa triggers YAML, rastreia estado do fluxo de lições
aprendidas e valida lições capturadas. Tudo consolidado em um único módulo global.

## Arquivo Principal

| Arquivo | Descrição |
|---------|-----------|
| `lib/triggers.sh` | Módulo consolidado (parser, matching, state machine, validador) |
| `.aidev/triggers/lesson-capture.yaml` | Configuração de triggers (4 triggers) |
| `.aidev/state/triggers.json` | Estado de cooldowns |
| `.aidev/state/lesson-state.json` | Estado atual da state machine |
| `.aidev/state/lesson-history.json` | Histórico de transições |

## Componentes

### 1. Parser e Carregamento
```bash
triggers__load   # Carrega YAML e converte para JSON em memória
```

### 2. Monitoramento
```bash
triggers__detect_intent "mensagem"   # Detecta keywords do usuário
triggers__watch_errors "output"      # Detecta padrões de erro
```

### 3. State Machine de Lições
```bash
triggers__lesson_transition "keyword_detected" "contexto"
triggers__lesson_state          # Ver estado atual
triggers__lesson_history        # Ver histórico
triggers__lesson_reset          # Resetar para idle
```

**Estados:** idle → keyword_detected → skill_suggested → skill_activated → lesson_drafted → lesson_validated → lesson_saved

### 4. Validador de Lições
```bash
triggers__validate_lesson "/path/to/lesson.md"   # Valida uma lição
triggers__validate_all_lessons                     # Valida todo o KB
```

**Verificações:** diretório correto, formato do nome (YYYY-MM-DD-slug.md), seções obrigatórias (Contexto, Problema, Solução, Prevenção), tags.

## Integração

Carregado automaticamente pelo `bin/aidev` via `load_module "triggers"` (linha 64).

## Arquivos Removidos (v2.0)

- `.aidev/lib/trigger-processor.sh` — duplicava funcionalidade do módulo global
- `.aidev/lib/lesson-state-machine.sh` — incorporado ao módulo global

## Análise do Gap

Documentação completa em `.aidev/docs/trigger-gap-analysis.md`.
