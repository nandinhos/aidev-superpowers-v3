# Backlog - Rules Engine: Carregamento, Injeção e Validação de Regras por LLM

## Visão Geral

As regras de codificação do orquestrador existem como arquivos Markdown em `.aidev/rules/` (generic, livewire, llm-limits), mas não há mecanismo que carregue, injete no contexto da LLM e valide o cumprimento dessas regras durante a sessão. O resultado é que LLMs ignoram regras existentes, criam padrões ad-hoc em locais não-canônicos, e retrabalho surge por violações de convenções já documentadas.

**Origem**: No projeto DAS, a LLM criou uma pasta `standards/` via Basic Memory com regras de frontend duplicadas, ignorando completamente `.aidev/rules/livewire.md` que já continha as mesmas convenções. Além disso, regras como "commits em português" e "sem Co-Authored-By" (definidas em `generic.md`) foram violadas repetidamente porque nenhum componente injeta essas regras no contexto da sessão.

**Convergência**: Este gap compartilha a mesma causa raiz do gap de lições aprendidas (`learned-lesson-trigger-gap.md`) e da ativação de MCPs (`mcp-standardized-activation.md`) — configuração declarativa existe, mas nenhum runtime a consome.

---

## Tarefas Prioritárias

### 1. [HIGH] Definir Taxonomia de Regras

**Descrição**: Classificar regras em camadas com hierarquia clara de precedência

**Detalhes técnicos**:
- **Camada global** (`.aidev/rules/generic.md`): Regras universais aplicáveis a qualquer projeto e stack
  - TDD, YAGNI, DRY, formato de commit, idioma, etc.
- **Camada de stack** (`.aidev/rules/{stack}.md`): Regras específicas da stack detectada
  - `livewire.md`, futuro `nextjs.md`, `django.md`, etc.
  - Ativação condicional baseada na detecção de stack (convergência com MCP detector)
- **Camada de projeto** (`.aidev/rules/project.md`): Overrides específicos do projeto
  - Regras que sobrescrevem ou complementam as globais/stack
- **Precedência**: projeto > stack > global (mais específico vence)
- Criar schema de metadados para cada regra: `id`, `severity` (error/warning), `scope`, `validatable`

**Arquivos esperados**:
- `.aidev/config/rules-taxonomy.yaml`

---

### 2. [HIGH] Implementar Loader de Regras por LLM

**Descrição**: Criar mecanismo que carrega regras relevantes e as injeta no contexto da LLM ativa

**Detalhes técnicos**:
- Na inicialização da sessão, o orquestrador deve:
  1. Identificar a LLM ativa (Claude, GPT, Gemini, etc.) via identificador prévio
  2. Carregar regras globais (`.aidev/rules/generic.md`)
  3. Detectar stack do projeto e carregar regras de stack (`.aidev/rules/{stack}.md`)
  4. Carregar overrides de projeto se existirem
  5. Montar payload consolidado de regras
- Formato de injeção adaptado por LLM:
  - Claude Code: via `CLAUDE.md` ou system prompt customizado
  - Cursor: via `.cursorrules`
  - Outros: via mecanismo equivalente de cada ferramenta
- O loader deve ser idempotente (múltiplas execuções = mesmo resultado)
- Regras injetadas devem incluir referência à fonte (arquivo de origem)

**Arquivos esperados**:
- `.aidev/engine/rules-loader.md` (spec)
- `.aidev/skills/rules-injection.md` (skill)

---

### 3. [HIGH] Implementar Validação de Regras Pós-Ação

**Descrição**: Verificar que ações da LLM cumprem as regras carregadas

**Detalhes técnicos**:
- Hooks de validação em pontos críticos:
  - **Pré-commit**: Verificar formato de commit (português, sem emoji, sem co-autoria)
  - **Pós-criação de arquivo**: Verificar localização canônica (não criar em `standards/`, usar `.aidev/rules/`)
  - **Pós-edição de código**: Verificar padrões de stack (wire:key com hash em loops, etc.)
- Cada regra com `validatable: true` deve ter uma função de verificação associada
- Resultado da validação:
  - `pass`: Regra cumprida
  - `warning`: Violação leve, reportar ao usuário
  - `error`: Violação crítica, bloquear ação e solicitar correção
- Integração com `llm-limits.md` existente (MAX_FILES_PER_CYCLE, caminhos protegidos)

**Arquivos esperados**:
- `.aidev/engine/rules-validator.md` (spec)

---

### 4. [MEDIUM] Criar Mecanismo Anti-Duplicação

**Descrição**: Prevenir que LLMs criem regras/padrões fora dos locais canônicos

**Detalhes técnicos**:
- Detectar criação de arquivos em diretórios não-canônicos que contenham conteúdo de regras:
  - Padrões suspeitos: "regras", "rules", "standards", "conventions", "guidelines"
  - Diretórios não-canônicos: qualquer lugar fora de `.aidev/rules/`
- Ao detectar, o orquestrador deve:
  1. Alertar o usuário sobre o local incorreto
  2. Sugerir mover/merge para `.aidev/rules/{arquivo-correto}.md`
  3. Se autorizado, executar o merge automaticamente
- Manter índice de arquivos de regras conhecidos para detecção rápida

**Arquivos esperados**:
- `.aidev/engine/rules-dedup.md` (spec)

---

### 5. [MEDIUM] Sincronizar Regras com Documentação Oficial

**Descrição**: Validar regras de stack contra documentação oficial para evitar padrões obsoletos

**Detalhes técnicos**:
- Integração com Context7 MCP para buscar documentação atualizada
- Para cada regra de stack, verificar periodicamente:
  - Padrão ainda é recomendado pela documentação oficial?
  - Houve breaking change na versão atual do framework?
  - Existe best practice nova que deveria ser incorporada?
- Gerar relatório de regras potencialmente desatualizadas
- Convergência com lições aprendidas: lições validadas podem gerar novas regras automaticamente

**Arquivos esperados**:
- `.aidev/skills/rules-doc-sync.md`

---

### 6. [LOW] Criar Dashboard de Compliance

**Descrição**: Visão consolidada de aderência às regras por sessão

**Detalhes técnicos**:
- Métricas por sessão:
  - Total de regras carregadas
  - Validações executadas (pass/warning/error)
  - Regras mais violadas
  - LLM com mais violações (comparativo cross-LLM)
- Persistir em Basic Memory para análise histórica
- Formato consultável: "qual o compliance da última sessão?"

**Arquivos esperados**:
- `.aidev/engine/rules-dashboard.md` (spec)

---

## Dependências

- Identificador de LLM prévio (já previsto no orquestrador)
- Detector de stack (convergência com `mcp-standardized-activation.md`, tarefa 2)
- Context7 MCP (para validação contra documentação oficial)
- Basic Memory MCP (para persistir métricas de compliance)
- Sistema de lições aprendidas (convergência com `learned-lesson-trigger-gap.md`)

---

## Critérios de Aceitação

1. ✅ Regras globais são injetadas automaticamente em toda sessão, independente da LLM
2. ✅ Regras de stack são carregadas condicionalmente baseado na detecção automática
3. ✅ Precedência projeto > stack > global é respeitada
4. ✅ Formato de commit é validado antes de cada commit (português, sem emoji, sem co-autoria)
5. ✅ Criação de arquivos de regras fora de `.aidev/rules/` é detectada e alertada
6. ✅ Cenário do projeto DAS (pasta `standards/` criada ad-hoc) não se repetiria com a nova implementação
7. ✅ Lições aprendidas validadas podem ser promovidas a regras automaticamente

---

## Observações

- **Incidente de referência**: Projeto DAS, 2026-02-22/23 — LLM criou `standards/Regras Frontend TALL Stack - DAS.md` via Basic Memory, duplicando conteúdo de `.aidev/rules/livewire.md`
- **Regras existentes ignoradas**: `generic.md` define "commits em português, sem co-autoria" mas a LLM violou repetidamente por não receber essas regras no contexto
- **Causa raiz compartilhada**: Mesma de lições aprendidas e MCPs — configuração declarativa sem runtime que a consuma
- **Oportunidade de convergência**: O detector de stack (tarefa 2 do backlog de MCPs) pode ser reutilizado pelo loader de regras (tarefa 2 deste backlog)
- **Loop virtuoso**: Lição aprendida → validada → promovida a regra → injetada em toda sessão → previne reincidência

---

## Referências

- Regras existentes no DAS: `.aidev/rules/generic.md`, `.aidev/rules/livewire.md`, `.aidev/rules/llm-limits.md`
- Arquivo duplicado (removido): `standards/Regras Frontend TALL Stack - DAS.md`
- Backlog relacionado: `.aidev/plans/backlog/learned-lesson-trigger-gap.md`
- Backlog relacionado: `.aidev/plans/backlog/mcp-standardized-activation.md`

---

## Refinamento — 2026-02-26

**Status:** VALIDADA
**Sprints estimados:** 3

**Dependências:** - Identificador de LLM prévio (já previsto no orquestrador)
**Observações:** Auto-aprovado: spec já detalhada com tarefas, critérios e dependências definidos

### Critérios de Aceitação (refinados)*Usar critérios originais do backlog*

### Sprints Planejados

| Sprint | Objetivo | Status |
|--------|----------|--------|
| Sprint 1 | Fundação — Taxonomia + Loader de Regras | Concluído |
| Sprint 2 | Enforcement — Validator + Anti-Duplicação + Hooks | Concluído |
| Sprint 3 | Sincronização com Docs Oficiais + Dashboard de Compliance | Em andamento |

### Sprint 3 — Detalhamento

**Objetivo**: Fechar o ciclo do Rules Engine com validação contra documentação oficial e visibilidade de compliance.

**Tarefas**:
- Task 5: `rules-doc-sync.sh` + `skills/rules-doc-sync/SKILL.md` — sincroniza regras via Context7 MCP
- Task 6: `rules-dashboard.sh` — dashboard de métricas de compliance por sessão

