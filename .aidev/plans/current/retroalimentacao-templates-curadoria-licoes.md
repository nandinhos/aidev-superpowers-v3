# Backlog - Sistema de Retroalimentação de Templates com Curadoria de Lições

## Visão Geral

Criar um ciclo virtuoso onde lições aprendidas durante o desenvolvimento são capturadas, classificadas, validadas por curadoria (MCPs) e promotionadas a regras/templates globais. Isso enriquece os templates dos agentes e skills com conhecimento específico do projeto e da stack, tornando-os especialistas mais robustos.

**Origem**: Observações do usuário em 2026-02-25. Templates são genéricos e não se beneficiam do conhecimento acumulado durante o desenvolvimento.

---

## Problema Atual

1. **Lições locais não alimentam templates**: Lições aprendidas ficam em `.aidev/memory/kb/` mas não melhoram os templates
2. **Sem classificação automática**: Lições não são classificadas como local vs global
3. **Sem curadoria**: Não há processo de validação para promover lição a regra
4. **Stack validation ausente**: Não há verificação contra documentação oficial (Context7, Laravel Boost)
5. **Templates estáticos**: Não evoluem com o tempo e experiência

---

## Fluxo Proposto

```
[Lição Local] → [Classificação Local/Global] → [Curadoria] → [Regra Validada] → [Template Atualizado] → [Repo Remoto]
                           ↓                                              ↓
                    .aidev/memory/kb/                            templates/
```

---

## Tarefas Prioritárias

### 1. [HIGH] Sistema de Classificação Local vs Global

**Descrição**: Classificar automaticamente lições aprendidas

**Detalhes técnicos**:
- Ao salvar lição em `.aidev/memory/kb/`, adicionar metadata de classificação:
  - `scope: local` - aplicável apenas ao projeto atual
  - `scope: global` - aplicável a qualquer projeto da mesma stack
  - `scope: universal` - aplicável a qualquer projeto
- Critérios de classificação:
  - Stack-específica? → global
  - Padrão de código? → universal
  - Configuração de projeto? → local
- Automatizar classificação via análise de conteúdo

**Arquivos esperados**:
- `.aidev/lib/lesson-classifier.sh`

**Critério de sucesso**: Toda nova lição classificada automaticamente

---

### 2. [HIGH] Pipeline de Curadoria de Lições Globais

**Descrição**: Processo de validação para promotionar lição a regra

**Detalhes técnicos**:
- **Trigger**: Lição classificada como `global` ou `universal`
- **Validação por stack**:
  - Se Laravel → validar com MCP Laravel Boost + Context7
  - Se outra stack → validar com Context7 MCP
- **Checklist de validação**:
  - Padrão ainda é recomendado?
  - Há breaking changes na versão atual?
  - Best practice atual confirma?
  - É viável implementar?
- **Resultado**: Aprovado/Rejeitado/Ajustar
- Se aprovado → promotionar a regra

**Arquivos esperados**:
- `.aidev/skills/lesson-curation/SKILL.md`
- `.aidev/lib/lesson-curation.sh`

**Critério de sucesso**: Lições globais validadas contra documentação oficial

---

### 3. [HIGH] Promoção de Lição Validada a Regra

**Descrição**: Converter lição aprovada em regra/template

**Detalhes técnicos**:
- Template de regra:
  ```markdown
  # Regra: [Nome da Regra]
  
  ## Origem
  - Lição: .aidev/memory/kb/YYYY-MM-DD-*.md
  - Validada em: [data]
  - Stack: [stack]
  
  ## Regra
  [Descrição da regra]
  
  ## Quando Aplicar
  [Casos de uso]
  
  ## Exemplo
  [Código de exemplo]
  
  ## Anti-Exemplo
  [O que evitar]
  ```
- Salvar em `.aidev/rules/{stack}.md` ou `.aidev/rules/generic.md`
- Atualizar skill relacionada com novo pattern

**Critério de sucesso**: Lição validada vira regra utilizável

---

### 4. [MEDIUM] Atualização de Templates Globais

**Descrição**: Consolidar regras em templates de agentes/skills

**Detalhes técnicos**:
- Ler regras de `.aidev/rules/*.md`
- Para cada skill/agent:
  - Identificar regras relevantes
  - Adicionar à seção "Patterns" do template
  - Gerar versão atualizada
- Commit automático com as atualizações

**Critério de sucesso**: Templates refletem últimas regras validadas

---

### 5. [MEDIUM] Sync com Repositório Remoto

**Descrição**: Atualizar repo remoto com novos templates

**Detalhes técnicos**:
- Após validação e atualização local:
  - Criar branch: `lesson-promotion/{id}`
  - Commitar mudanças
  - Criar PR automático
  - Mergear após approval
- Atualizar VERSION se necessário

**Critério de sucesso**: Novas instalações já nascem com templates enriquecidos

---

### 6. [LOW] Dashboard de Lições

**Descrição**: Visão consolidada do sistema de lições

**Detalhes técnicos**:
- Métricas:
  - Total lições locais
  - Total lições globais
  - Lições promotionadas a regras
  - Taxa de aprovação em curadoria
- Consultável: `aidev lessons --stats`

**Critério de sucesso**: Visibilidade do ciclo de retroalimentação

---

## Integração com Ideias Existentes

**Conectado com:**
- `rules-engine-standardization.md` - Regras promotionadas alimentam a engine
- `learned-lesson-trigger-gap.md` - Gatilho para capturar lições
- `onboarding-interativo-orquestrador-semantico.md` - Respostas de onboarding viram lições iniciais

---

## Dependências

- `.aidev/memory/kb/` (lições locais)
- `.aidev/rules/` (regras)
- `.aidev/skills/learned-lesson/SKILL.md`
- MCPs: Context7, Laravel Boost
- `templates/agents/`, `templates/skills/`

---

## Critérios de Aceitação

1. ✅ Lições classificadas automaticamente (local/global/universal)
2. ✅ Lições globais passam por curadoria com MCPs
3. ✅ Lição validada vira regra em `.aidev/rules/`
4. ✅ Templates de agentes/skills atualizados com novas regras
5. ✅ Repo remoto atualizado para novas instalações
6. ✅ Dashboard de métricas disponível
7. ✅ Ciclo completo: lição → classificação → curadoria → regra → template

---

## Observações

- **Ciclo virtuoso**: Cada projeto enriquece a base global
- **Stack-aware**: Validação customizada por stack
- **Qualidade**: Curadoria garante que apenas boas práticas viram regras
- **Diferencial**: Templates evoluem com uso real

---

## Referências

- Skill learned-lesson: `.aidev/skills/learned-lesson/SKILL.md`
- Rules existentes: `.aidev/rules/generic.md`, `.aidev/rules/llm-limits.md`
- MCP Context7: documentação oficial
- MCP Laravel Boost: validações Laravel

---

## Refinamento — 2026-02-26

**Status:** VALIDADA
**Sprints estimados:** 2

**Dependências:** rules-engine, learned-lesson-trigger-gap (ambos concluídos)


### Critérios de Aceitação (refinados)1. Classificação automática
2. promoção a regras
3. curadoria com MCPs

### Sprints Planejados

| Sprint | Objetivo | Status |
|--------|----------|--------|
| Sprint 1 | A definir | Pendente |
| Sprint 2 | A definir | Pendente |

