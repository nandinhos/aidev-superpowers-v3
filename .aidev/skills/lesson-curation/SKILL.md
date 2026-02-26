---
name: lesson-curation
description: Curadoria de lições aprendidas com validação via MCPs
---

# Skill: Curadoria de Lições Aprendidas

## Propósito

Validar lições classificadas como `global` ou `universal` antes de promovê-las a regras oficiais. Usa MCPs (Context7, Laravel Boost) para confirmar que a lição reflete boas práticas atuais.

## Quando Ativar

- Após `classify_lesson` retornar scope `global` ou `universal`
- Antes de `promote_lesson_to_rule`
- Manualmente via `aidev lessons --curate`

## Fluxo

```
1. Receber lição classificada (global/universal)
2. Extrair problema + solução
3. Validar com MCP:
   - Context7: buscar documentação oficial da biblioteca
   - Laravel Boost: validar com docs do Laravel (se stack=laravel)
4. Avaliar resultado:
   - APROVADA → promote_lesson_to_rule
   - AJUSTAR → sugerir correções ao usuário
   - REJEITADA → marcar como "curadoria_rejeitada"
5. Registrar resultado em metadata da lição
```

## Checklist de Validação

- [ ] Padrão ainda é recomendado na versão atual?
- [ ] Há breaking changes que invalidam a lição?
- [ ] Best practice oficial confirma a abordagem?
- [ ] Solução é viável e reproduzível?

## Integração

- **Input**: Lição em `.aidev/memory/kb/` com scope global/universal
- **Output**: Lição marcada com `curated: true|false` + resultado
- **Dependências**: Context7 MCP, Laravel Boost MCP (opcional)

## Exemplos de Uso

```bash
# Curar uma lição específica
source .aidev/lib/lesson-curator.sh
curate_lesson ".aidev/memory/kb/2026-02-22-livewire-morph.md"

# Curar todas as lições elegíveis
curate_eligible_lessons
```

## Limitações

- A curadoria depende de MCPs ativos (verificar com `aidev doctor`)
- Context7 pode não ter documentação para todas as libs
- Resultado é recomendação, decisão final é do desenvolvedor
