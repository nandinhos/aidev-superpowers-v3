# Plano: Otimizar Ativacao do Modo Agente + Regras de Commit

**Status**: IMPLEMENTADO
**Data**: 2026-02-02

## Problema

1. **Ativacao lenta**: 20+ leituras de arquivos para ativar o modo agente
2. **Commits sem padrao**: Falta regra explicita para portugues, sem emojis, sem co-autoria

## Solucao Implementada

### Parte 1: QUICKSTART.md - Arquivo Consolidado

Criado arquivo unico que contem TUDO necessario para ativar o modo agente.

**Reducao**: 20+ arquivos -> 1-2 arquivos

### Parte 2: Regras de Commit em Portugues

Atualizado `templates/rules/generic.md.tmpl` com regras explicitas.

---

## Arquivos Modificados

| Arquivo | Acao |
|---------|------|
| `templates/rules/generic.md.tmpl` | EDITADO - regras de commit em portugues |
| `templates/platform/QUICKSTART.md.tmpl` | CRIADO - arquivo consolidado |
| `templates/platform/CLAUDE.md.tmpl` | EDITADO - simplificado |
| `bin/aidev` | EDITADO - geracao do QUICKSTART.md |

---

## Verificacao

- [x] Regras de commit em portugues no generic.md.tmpl
- [x] QUICKSTART.md.tmpl criado com conteudo consolidado
- [x] CLAUDE.md.tmpl simplificado
- [x] bin/aidev atualizado para gerar QUICKSTART.md
