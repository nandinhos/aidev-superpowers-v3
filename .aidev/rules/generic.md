# Generic Stack Rules

## Core Principles
These rules apply to ALL projects regardless of stack.

## 1. TDD is Mandatory
- **RED**: Write failing test first
- **GREEN**: Minimal code to pass
- **REFACTOR**: Improve without breaking

## 2. YAGNI (You Aren't Gonna Need It)
- Don't add functionality until needed
- Avoid premature optimization  
- Build only what's requested

## 3. DRY (Don't Repeat Yourself)
- Each piece of knowledge has single source
- Extract when repeated 3+ times
- But don't over-abstract early

## 4. Clean Code
- Meaningful names
- Small functions (≤20 lines)
- Single responsibility
- Clear separation of concerns

## 5. Error Handling
- Fail fast
- Clear error messages
- Proper exception types
- Log appropriately

## 6. Version Control
- Atomic commits
- Descriptive messages
- Branch per feature
- Review before merge

## Commit Message Format (Padrão de Governança)
Todo commit deve seguir o padrão:
```
Sprint X (Fase Y): Descrição curta em português

- Detalhe 1 (opcional)
- Detalhe 2 (opcional)
```

### Regras de Ouro
1. **Sem emojis**: Não use emojis no título (subject) do commit.
2. **Fase e Sprint**: Identifique sempre a Fase e o Sprint atual.
3. **Idioma**: Sempre em Português Brasil.
4. **Sem Co-autoria**: Não insira "Co-authored-by" nos commits.
5. **Contexto**: A descrição deve ser curta e direta no título, detalhes no corpo.

### Fases Atuais
- **Fase 1**: Desenvolvimento Core Initial (Sprints 0-11)
- **Fase 2**: Recuperação e Hardening de Ambiente (Sprints 1-5)
- **Fase 3**: Evolução do Orquestrador e Multicliente (Atual)
- Group by feature, not type
- Clear naming conventions
- Consistent structure
- Separate config from code

## Documentation
- README for every project
- Inline comments for "why"
- API documentation
- Architecture decisions


## Project: aidev-superpowers-v3-1