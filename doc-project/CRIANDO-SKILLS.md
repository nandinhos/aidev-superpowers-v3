# 📚 Criando Skills

Este guia explica como criar suas próprias skills para o AI Dev Superpowers.

## 🤔 O que é uma Skill?

Uma skill é um **processo guiado** que a IA deve seguir em situações específicas. Diferente de agentes (que têm roles), skills são **workflows estruturados**.

## 📁 Estrutura

```
.aidev/skills/minha-skill/
├── SKILL.md           # Obrigatório: definição da skill
├── examples/          # Opcional: exemplos de uso
│   ├── exemplo1.md
│   └── exemplo2.md
├── templates/         # Opcional: templates de output
│   └── output.md.tmpl
└── scripts/           # Opcional: scripts auxiliares
    └── helper.sh
```

## 📝 Formato do SKILL.md

### Frontmatter (YAML)

```yaml
---
name: nome-da-skill
description: Descrição curta (aparece na listagem)
triggers:
  - "palavra que ativa"
  - "outra palavra"
globs:
  - "**/*.md"           # Arquivos relacionados
priority: 10            # Opcional: prioridade (maior = mais importante)
---
```

### Corpo (Markdown)

```markdown
# Nome da Skill

## When to Use
[Situações em que usar esta skill]

## Purpose
[Objetivo e benefícios]

## Prerequisites
[O que precisa estar pronto antes]

## Process
1. **Passo 1**: Descrição
2. **Passo 2**: Descrição
3. **Passo 3**: Descrição

## Key Principles
- Princípio importante 1
- Princípio importante 2

## Expected Output
[O que a skill deve produzir]

## Examples
[Exemplos práticos de uso]

## Anti-Patterns
[O que evitar ao usar esta skill]
```

## 💾 Persistência de Conhecimento (KB)

Se sua skill gera conhecimento reutilizável (lições, decisões, análises), salve-os na **Base de Conhecimento (KB)** do projeto.

- **Caminho Padrão:** `.aidev/memory/kb/`
- **Formato:** Markdown (`.md`) com metadados
- **Nome:** `YYYY-MM-DD-titulo-descritivo.md`

### Por que usar a KB?
O Orquestrador lê automaticamente esta pasta para fornecer contexto em futuras sessões, permitindo que a IA "aprenda" com o tempo.

Exemplo de artefato:
```markdown
# Decisão: Uso de Redis para Cache

**Data**: 2026-02-03
**Tags**: arquitetura, performance

## Contexto
Precisávamos reduzir a latência da API de produtos.

## Decisão
Implementamos cache layer com Redis (TTL 60min).

## Resultado
Latência caiu de 200ms para 15ms.
```

---

## 🎯 Exemplos Práticos

### Skill: API Design

```markdown
---
name: api-design
description: Processo para design de APIs RESTful
triggers:
  - "criar api"
  - "nova api"
  - "endpoint"
globs:
  - "routes/**"
  - "controllers/**"
---

# API Design Skill

## When to Use
- Criando novos endpoints
- Refatorando APIs existentes
- Documentando APIs

## Process

### 1. Defina o Recurso
- Qual entidade estamos expondo?
- Quais operações são necessárias?
- Quais relacionamentos existem?

### 2. Desenhe os Endpoints
```
GET    /api/v1/recursos          # Listar
GET    /api/v1/recursos/:id      # Obter
POST   /api/v1/recursos          # Criar
PUT    /api/v1/recursos/:id      # Atualizar
DELETE /api/v1/recursos/:id      # Remover
```

### 3. Defina Request/Response
- Quais campos no request?
- Quais campos na response?
- Quais validações?

### 4. Implemente com TDD
- Escreva testes primeiro
- Implemente o controller
- Valide responses

## Key Principles
- Use substantivos, não verbos
- Versione a API
- Use HTTP status codes corretos
- Documente com OpenAPI/Swagger

## Anti-Patterns
- ❌ `/getUser` (use GET `/users/:id`)
- ❌ `/createUser` (use POST `/users`)
- ❌ Retornar 200 para erros
```

### Skill: Database Migration

```markdown
---
name: database-migration
description: Processo seguro para migrations de banco
triggers:
  - "migration"
  - "alterar tabela"
  - "nova coluna"
globs:
  - "database/migrations/**"
---

# Database Migration Skill

## When to Use
- Adicionando novas tabelas
- Alterando estrutura existente
- Migrando dados

## Process

### 1. Análise de Impacto
- [ ] Quais tabelas afetadas?
- [ ] Há dados que serão perdidos?
- [ ] Qual o tamanho da tabela?
- [ ] Precisa de downtime?

### 2. Planeje Rollback
- [ ] Migration é reversível?
- [ ] Escreva down() antes de up()
- [ ] Teste rollback em staging

### 3. Implementação Segura
```php
// ✅ Seguro: permite NULL primeiro
$table->string('nova_coluna')->nullable();

// ❌ Perigoso: NOT NULL sem default
$table->string('nova_coluna');
```

### 4. Deploy Gradual
1. Deploy migration
2. Deploy código que usa nova coluna
3. Preencha dados faltantes
4. Torne coluna NOT NULL (se necessário)

## Key Principles
- Sempre tenha rollback
- Migrations pequenas e incrementais
- Teste em staging primeiro
- Monitore após deploy

## Anti-Patterns
- ❌ Migrations que não têm rollback
- ❌ Alterar migrations já rodadas
- ❌ DROP TABLE em produção
```

## 🔧 Usando CLI

```bash
# Criar skill básica
aidev add-skill minha-skill

# Estrutura criada:
# .aidev/skills/minha-skill/SKILL.md
```

## 💡 Dicas

### 1. Seja Específico
```markdown
# ❌ Vago
## Process
1. Faça o necessário
2. Teste

# ✅ Específico
## Process
1. Identifique os casos de teste
2. Escreva teste para caso de sucesso
3. Escreva teste para caso de erro
4. Implemente lógica mínima
```

### 2. Use Checklists
```markdown
## Checklist
- [ ] Testes escritos
- [ ] Código implementado
- [ ] Documentação atualizada
- [ ] PR criado
```

### 3. Inclua Exemplos de Código
```markdown
## Examples

### Correto
```python
def calcular_total(items):
    return sum(item.price for item in items)
```

### Evite
```python
def calc(i):  # Nome ruim, sem tipagem
    t = 0
    for x in i:
        t += x.price
    return t
```
```

### 4. Defina Triggers Claros
```yaml
triggers:
  - "criar feature"     # Específico
  - "nova funcionalidade"
  - "implementar"
# Evite triggers muito genéricos como "código" ou "fazer"
```

## 🔄 Ciclo de Vida

1. **Trigger**: IA detecta keyword no prompt
2. **Load**: Carrega SKILL.md
3. **Execute**: Segue processo passo a passo
4. **Validate**: Verifica output esperado
5. **Complete**: Marca como concluído

## 📋 Checklist de Qualidade

- [ ] Nome descritivo e único
- [ ] Description clara no frontmatter
- [ ] Triggers relevantes e específicos
- [ ] Process com passos numerados
- [ ] Key Principles definidos
- [ ] Exemplos práticos
- [ ] Anti-patterns documentados

---

Veja também:
- [Guia de Customização](CUSTOMIZACAO.md)
- [Criando Agentes](CRIANDO-AGENTES.md)
