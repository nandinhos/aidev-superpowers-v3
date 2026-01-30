# 🎨 Guia de Customização

Este guia explica como customizar o AI Dev Superpowers para seu projeto.

## 📁 Estrutura Customizável

```
.aidev/
├── agents/     # Seus agentes customizados
├── skills/     # Suas skills customizadas
├── rules/      # Suas regras customizadas
└── state/      # Estado persistente
```

## 🤖 Customizando Agentes

### Via CLI

```bash
# Cria template de agente
aidev add-agent meu-agente
```

### Manualmente

Crie um arquivo em `.aidev/agents/meu-agente.md`:

```markdown
# Meu Agente

## Role
[Descreva o papel deste agente]

## Responsibilities
- Responsabilidade 1
- Responsabilidade 2

## Guidelines
- Guideline 1
- Guideline 2

## Tools
- Ferramenta 1
- Ferramenta 2
```

### Exemplo: Agente de Documentação

```markdown
# Documentation Agent

## Role
Especialista em documentação técnica e comentários de código.

## Responsibilities
- Manter README atualizado
- Documentar APIs
- Criar guias de contribuição
- Revisar comentários de código

## Guidelines
- Use linguagem clara e objetiva
- Inclua exemplos de código
- Mantenha atualizados com o código

## When to Invoke
- Após implementar nova feature
- Após mudanças de API
- Antes de releases
```

## 📚 Customizando Skills

### Via CLI

```bash
# Cria template de skill
aidev add-skill minha-skill
```

### Estrutura de uma Skill

```
.aidev/skills/minha-skill/
├── SKILL.md       # Definição principal
├── examples/      # Exemplos de uso (opcional)
└── scripts/       # Scripts auxiliares (opcional)
```

### Formato do SKILL.md

```markdown
---
name: minha-skill
description: Descrição breve da skill
triggers:
  - "palavra-chave1"
  - "palavra-chave2"
globs:
  - "**/*.md"
---

# Nome da Skill

## When to Use
[Quando usar esta skill]

## Purpose
[Objetivo da skill]

## Process
1. Passo 1
2. Passo 2
3. Passo 3

## Key Principles
- Princípio 1
- Princípio 2

## Examples
[Exemplos de uso]
```

### Exemplo: Skill de Code Review

```markdown
---
name: code-review
description: Processo estruturado de revisão de código
triggers:
  - "review"
  - "revisar"
  - "PR"
globs:
  - "**/*.{js,ts,py,php}"
---

# Code Review Skill

## When to Use
- Antes de merge de PRs
- Ao revisar código de terceiros
- Para auto-revisão

## Process
1. **Leia o contexto**: Entenda o propósito da mudança
2. **Verifique testes**: Existem? Cobrem casos importantes?
3. **Revise lógica**: A implementação está correta?
4. **Verifique padrões**: Segue os padrões do projeto?
5. **Segurança**: Há vulnerabilidades?
6. **Performance**: Há problemas de performance?

## Checklist
- [ ] Testes existem e passam
- [ ] Código segue padrões
- [ ] Sem vulnerabilidades óbvias
- [ ] Sem problemas de performance
- [ ] Documentação atualizada

## Feedback Format
Use formato construtivo:
- ✅ Bom: "Considere usar X para Y"
- ❌ Ruim: "Isso está errado"
```

## 📏 Customizando Rules

### Via CLI

```bash
# Cria template de regra
aidev add-rule minha-regra
```

### Manualmente

Crie em `.aidev/rules/minha-regra.md`:

```markdown
# Minha Regra

## Conventions
[Convenções a seguir]

## Patterns
[Padrões recomendados]

## Anti-Patterns
[O que evitar]

## Examples
[Exemplos de código]
```

### Exemplo: Regras de API

```markdown
# API Design Rules

## Conventions
- Use REST semântico
- Versione APIs: `/api/v1/`
- Use plural para recursos: `/users`
- Use HTTP status codes corretos

## Patterns
### Endpoints
```
GET    /api/v1/users          # Lista
GET    /api/v1/users/:id      # Detalhes
POST   /api/v1/users          # Criar
PUT    /api/v1/users/:id      # Atualizar
DELETE /api/v1/users/:id      # Remover
```

### Response Format
```json
{
  "data": {},
  "meta": {},
  "errors": []
}
```

## Anti-Patterns
- ❌ Verbos em URLs: `/getUser`, `/createUser`
- ❌ Singular para coleções: `/user`
- ❌ Retornar 200 para erros
- ❌ Dados sensíveis em URL

## Examples
```php
// ✅ Correto
Route::get('/api/v1/users', [UserController::class, 'index']);

// ❌ Errado
Route::get('/api/v1/getUsers', [UserController::class, 'getUsers']);
```
```

## ⚙️ Arquivo .aidev.yaml

Configure comportamentos globais:

```yaml
# Modo de operação
mode: full              # full, minimal, custom

# Idioma
language: pt-br         # pt-br, en

# Debug
debug: false

# Plataforma
platform:
  name: auto            # auto, claude-code, gemini

# Skills ativas (para mode: custom)
skills:
  enabled:
    - brainstorming
    - tdd
  disabled:
    - writing-plans

# Agentes ativos (para mode: custom)
agents:
  enabled:
    - orchestrator
    - backend
    - frontend
  disabled:
    - devops

# Comportamentos
behaviors:
  tdd: mandatory        # mandatory, recommended, optional
  tests_before_code: true
  documentation: required

# Stacks adicionais
stacks:
  custom-stack:
    test_command: "npm test"
    lint_command: "npm run lint"
```

## 🔄 Sincronizando Customizações

### Entre Projetos

```bash
# Exportar customizações
cp -r .aidev/agents/* /path/to/shared/agents/
cp -r .aidev/skills/* /path/to/shared/skills/

# Importar em outro projeto
cp -r /path/to/shared/agents/* .aidev/agents/
```

### Via Git

Inclua `.aidev/` no controle de versão:

```gitignore
# .gitignore
.aidev/state/     # Ignora estado local
!.aidev/agents/   # Mantém agentes
!.aidev/skills/   # Mantém skills
!.aidev/rules/    # Mantém rules
```

## 💡 Dicas

1. **Comece simples**: Use os defaults antes de customizar
2. **Documente**: Explique o propósito de cada customização
3. **Teste**: Valide que suas customizações funcionam
4. **Compartilhe**: Contribua customizações úteis ao projeto

---

Veja também:
- [Criando Skills](CRIANDO-SKILLS.md)
- [Criando Agentes](CRIANDO-AGENTES.md)
