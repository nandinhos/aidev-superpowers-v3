# Generic Stack Rules

## Core Principles
These rules apply to ALL projects regardless of stack.

- **Comunicação**: Toda a interação entre Agente e Usuário deve ser em PORTUGUÊS (Brasil).

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

## 6. Controle de Versao
- Commits atomicos
- Mensagens descritivas em PORTUGUES
- Branch por feature
- Review antes de merge

## Formato de Commit

**REGRAS OBRIGATORIAS**:
- Idioma: PORTUGUES (obrigatorio)
- Emojis: PROIBIDOS
- Co-autoria: PROIBIDA (sem Co-Authored-By)
- Utilize Conventional Commits

### Formato
```
tipo(escopo): descricao curta em portugues

- Detalhe 1 (opcional)
- Detalhe 2 (opcional)
```

### Tipos
- `feat`: Nova funcionalidade
- `fix`: Correcao de bug
- `refactor`: Mudanca de codigo (sem nova funcionalidade)
- `test`: Adicao de testes
- `docs`: Documentacao
- `chore`: Manutencao

### Exemplos Corretos
```
feat(auth): adiciona autenticacao JWT
fix(api): corrige validacao de email
refactor(utils): extrai funcao de formatacao
```

### NAO FACA
```
# ERRADO - emoji
feat(auth): :sparkles: adiciona autenticacao

# ERRADO - ingles
feat(auth): add authentication

# ERRADO - co-autoria
feat(auth): adiciona auth

Co-Authored-By: Claude <noreply@anthropic.com>
```

## File Organization
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