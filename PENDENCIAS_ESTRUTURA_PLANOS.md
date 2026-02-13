# Relatório de Pendências - Estrutura de Planos

> Levantamento do que ficou fora do escopo de templates/init
> Data: 2026-02-13

---

## 🔍 ANÁLISE

### 1. O QUE EXISTE NO PROJETO (estrutura final organizada)
```
.aidev/plans/
├── README.md                          ✓ Índice mestre
├── ROADMAP.md                         ✓ Documento mestre
├── backlog/
│   ├── README.md                     ✓ Índice do backlog
│   └── mcp-universal-install.md      ✓ Conteúdo
├── features/
│   ├── README.md                     ✓ Índice de features
│   └── smart-upgrade-merge.md        ✓ Conteúdo
├── current/
│   └── README.md                     ✓ Índice de execução
├── history/
│   ├── README.md                     ✓ Índice de histórico
│   ├── 2026-02/                      ✓ Arquivos concluídos
│   └── v3-legacy/                    ✓ Arquivos legados
└── archive/
    ├── README.md                     ✓ Índice de documentação
    └── templates/
        └── sprint-execution-protocol.md  ✓ Documentação
```

### 2. O QUE É INSTALADO PELO INIT (bin/aidev - install_plans())
```bash
install_plans() {
    local path="$1"
    local plans_dir="$path/.aidev/plans"
    
    ensure_dir "$plans_dir"
    ensure_dir "$plans_dir/features"
    ensure_dir "$plans_dir/history"

    local roadmap_template="$AIDEV_ROOT_DIR/templates/plans/ROADMAP.md.tmpl"
    if [ -f "$roadmap_template" ]; then
        process_template "$roadmap_template" "$plans_dir/ROADMAP.md"
        print_debug "Instalado ROADMAP.md inicial"
    fi
}
```

**Resultado do init atual:**
```
.aidev/plans/
├── ROADMAP.md          ← Criado do template
├── features/           ← Diretório vazio criado
└── history/            ← Diretório vazio criado
```

### 3. O QUE ESTÁ FALTANDO (gap identificado)

#### ❌ Estrutura de pastas não criada:
- [ ] `backlog/` - Não criado
- [ ] `current/` - Não criado
- [ ] `archive/` - Não criado
- [ ] `archive/templates/` - Não criado

#### ❌ Arquivos README não instalados:
- [ ] `plans/README.md` - Índice mestre de navegação
- [ ] `plans/backlog/README.md` - Documentação do backlog
- [ ] `plans/features/README.md` - Documentação de features
- [ ] `plans/current/README.md` - Documentação de execução
- [ ] `plans/history/README.md` - Documentação de histórico
- [ ] `plans/archive/README.md` - Documentação de arquivos

#### ❌ Templates não existem:
- [ ] `templates/plans/README.md.tmpl` - Template do índice mestre
- [ ] `templates/plans/backlog/README.md.tmpl` - Template do backlog
- [ ] `templates/plans/features/README.md.tmpl` - Template de features
- [ ] `templates/plans/current/README.md.tmpl` - Template de execução
- [ ] `templates/plans/history/README.md.tmpl` - Template de histórico
- [ ] `templates/plans/archive/README.md.tmpl` - Template de archive

---

## 🎯 SOLUÇÃO PROPOSTA

### Opção 1: Criar Templates (Recomendada)

Criar estrutura completa em `templates/plans/`:

```
templates/plans/
├── README.md.tmpl
├── backlog/
│   └── README.md.tmpl
├── features/
│   └── README.md.tmpl
├── current/
│   └── README.md.tmpl
├── history/
│   └── README.md.tmpl
└── archive/
    └── README.md.tmpl
```

E atualizar `install_plans()` para processar todos os templates.

**Vantagens:**
- Permite variáveis/template processing
- Consistente com resto do sistema
- Fácil manutenção

**Desvantagens:**
- Mais arquivos para gerenciar
- Precisa criar templates

---

### Opção 2: Copiar Arquivos Estáticos (Mais simples)

Copiar os READMEs de `.aidev/plans/` para `templates/plans/` e usar `cp` ao invés de `process_template`.

**Vantagens:**
- Mais simples de implementar
- Menos processamento

**Desvantagens:**
- Sem variáveis dinâmicas
- Menos flexível

---

### Opção 3: Criar Pós-Init (Quick fix)

Adicionar comando `aidev init-plans` ou similar que cria a estrutura completa após o init.

**Vantagens:**
- Não mexe no init existente
- Pode ser rodado em projetos legados

**Desvantagens:**
- Passo extra necessário
- Não é automático

---

## 🔧 IMPLEMENTAÇÃO RECOMENDADA

### Passo 1: Criar templates
Copiar os READMEs existentes de `.aidev/plans/` para `templates/plans/` com extensão `.tmpl`

### Passo 2: Atualizar install_plans()
Modificar a função para:
1. Criar TODAS as pastas (backlog, features, current, history, archive)
2. Processar TODOS os templates README
3. Manter comportamento existente

### Passo 3: Testar
Rodar `aidev init` em projeto limpo e verificar estrutura completa.

---

## ⚠️ IMPACTO

### Em novos projetos:
Atualmente ao rodar `aidev init`, a estrutura de planos vem **incompleta**:
- ❌ Sem READMEs navegáveis
- ❌ Sem backlog/
- ❌ Sem current/
- ❌ Sem archive/

### Em upgrades:
Projetos existentes ao rodar `aidev upgrade` **não recebem** a nova estrutura.

### Workaround manual:
Usuários precisam criar manualmente ou copiar do repositório.

---

## 📝 RESUMO EXECUTIVO

**Status:** ❌ **PENDENTE**

A reorganização da estrutura de planos foi feita no repositório `.aidev/plans/`, mas **não foi incluída nos templates** que são instalados durante `init` e `upgrade`.

**O que precisa ser feito:**
1. Criar 6 templates README em `templates/plans/`
2. Atualizar `install_plans()` no `bin/aidev`
3. Testar em projeto limpo
4. Commit e sincronizar global

**Tempo estimado:** 20-30 minutos

**Prioridade:** 🔴 Alta (afeta todos os novos projetos)

---

*Relatório gerado em 2026-02-13*
