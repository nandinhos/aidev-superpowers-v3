---
name: rules-doc-sync
description: Valida regras de stack contra documentação oficial via Context7 MCP
version: 1.0.0
triggers:
  - "sincronizar regras"
  - "validar regras com docs"
  - "atualizar regras"
  - "regras desatualizadas"
  - "rules doc sync"
globs:
  - ".aidev/rules/**"
  - ".aidev/config/rules-taxonomy.yaml"
  - ".aidev/engine/rules-doc-sync.sh"
steps: 4
checkpoints:
  - stack_identified
  - rules_extracted
  - docs_consulted
  - report_written
requires:
  - context7_mcp
---

# Skill: Rules Doc Sync

## Propósito

Verificar periodicamente se as regras de codificação em `.aidev/rules/` ainda
estão alinhadas com a documentação oficial do framework/stack detectado.
Previne que regras se tornem obsoletas após atualizações de versão.

## Quando Ativar

- Antes de iniciar uma feature nova em um projeto que não usamos há algum tempo
- Quando suspeitar que um padrão documentado pode estar desatualizado
- Após atualizar versão major de um framework
- Periodicamente (recomendado: a cada sprint ou release)

## Pré-requisito

Context7 MCP deve estar ativo na sessão. Verificar:
```
Ferramentas disponíveis: resolve-library-id, get-library-docs
```

---

## Protocolo de 4 Fases

### Fase 1 — Identificar Stack e Extrair Regras [checkpoint: stack_identified]

```bash
source .aidev/engine/rules-doc-sync.sh
rules_doc_sync_prepare   # auto-detecta stack e extrai regras
```

**Verificar**:
- [ ] Stack identificada corretamente?
- [ ] Arquivo de regras existe e tem conteúdo?
- [ ] Seções de regras extraídas com sucesso?

Se a stack for `generic` e não houver regras específicas de framework, encerre aqui — não há o que sincronizar com Context7.

---

### Fase 2 — Consultar Documentação Oficial [checkpoint: docs_consulted]

Para cada regra de stack extraída, use Context7:

```
1. Resolver ID da biblioteca:
   resolve-library-id query="<nome da stack>"
   Ex: resolve-library-id query="livewire laravel"

2. Buscar documentação relevante:
   get-library-docs libraryId="<id-resolvido>" topic="<tema-da-regra>"
   Ex: get-library-docs libraryId="/livewire/livewire" topic="wire:key loops"
```

**Para cada regra, anotar**:
- Versão da documentação consultada
- O que a documentação diz sobre o padrão
- Status: `ATUAL` | `DESATUALIZADA` | `SEM_DOCUMENTACAO`
- Se `DESATUALIZADA`: o que mudou e como atualizar

**Exemplos de consultas por stack**:

| Stack | Tópicos a verificar |
|-------|---------------------|
| Livewire | wire:key em loops, $wire vs $this, Livewire 3 lifecycle |
| Next.js | App Router vs Pages Router, Server Components, fetch caching |
| Django | Class-based vs function-based views, ORM patterns, migrations |

---

### Fase 3 — Compilar Resultado

Montar tabela de resultado no formato:

```markdown
| Regra | Status | Versão Docs | Observação |
|-------|--------|-------------|-----------|
| wire:key em loops | ATUAL | Livewire 3.x | Confirmado na docs oficial |
| $this vs $wire | DESATUALIZADA | Livewire 3.x | $wire é recomendado no L3 |
| ... | ... | ... | ... |
```

---

### Fase 4 — Persistir Relatório [checkpoint: report_written]

```bash
rules_doc_sync_write_report "<stack>" "<tabela-de-resultado>"
```

**Verificar**:
- [ ] Relatório salvo em `.aidev/state/doc-sync-report.md`?
- [ ] Log atualizado em `.aidev/state/doc-sync.log`?

**Se houver regras desatualizadas**:
1. Apresentar ao usuário: "Encontrei X regra(s) potencialmente desatualizada(s)"
2. Para cada uma, mostrar: regra atual vs. o que a documentação diz
3. Propor atualização do arquivo `.aidev/rules/<stack>.md`
4. Aguardar aprovação antes de editar

---

## Resultado Esperado

```
=== Rules Doc Sync — Resultado ===

Regras verificadas: N
  ✓ Atuais:           X
  ✗ Desatualizadas:   Y
  ? Sem documentação: Z

[Se Y > 0]
Regras que precisam de atualização:
  - <regra>: <o-que-mudou>
  ...

Relatório completo: .aidev/state/doc-sync-report.md
```

---

## Notas

- Se Context7 não retornar resultado para uma regra, classifique como `SEM_DOCUMENTACAO` e não modifique a regra
- Não edite `.aidev/rules/` sem aprovação explícita do usuário
- Após atualizar uma regra, execute `rules_inject_claude_md` para re-injetar no CLAUDE.md
- Lições validadas podem ser promovidas a regras via skill `learned-lesson`
