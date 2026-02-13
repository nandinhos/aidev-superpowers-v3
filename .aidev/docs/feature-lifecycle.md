# Sistema de Lifecycle de Features

> Documentação do sistema de automação de conclusão de features  
> Criado: 2026-02-13  
> Versão: 1.0

---

## Visão Geral

O Sistema de Lifecycle de Features resolve o problema de **automação da transição** quando uma feature é concluída. Anteriormente, o processo era manual e sujeito a esquecimentos, causando inconsistências entre sessões de diferentes LLMs.

### Problema Anterior

❌ Ao terminar uma feature:
- Status não era atualizado automaticamente
- Arquivos permaneciam em `.aidev/plans/features/`
- ROADMAP.md não refletia a conclusão
- Outras LLMs não tinham visibilidade do estado atual

### Solução Implementada

✅ Automação completa:
- Marca item como concluído automaticamente
- Move para `.aidev/plans/history/YYYY-MM/` organizado por data
- Atualiza ROADMAP.md
- Registra em context-log.json para rastreabilidade

---

## Arquitetura

### Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                   Feature Lifecycle System                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐      ┌─────────────────────────────┐  │
│  │  CLI Interface   │      │      Core Functions         │  │
│  │  aidev feature   │─────▶│  • feature_complete()       │  │
│  │  [list|complete| │      │  • feature_list_active()    │  │
│  │   status|show]   │      │  • feature_get_metadata()   │  │
│  └──────────────────┘      └─────────────────────────────┘  │
│                                       │                      │
│                                       ▼                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                  Ações Automáticas                     │ │
│  ├────────────────────────────────────────────────────────┤ │
│  │ 1. Atualizar Status    │ feature.md → "Concluído"      │ │
│  │ 2. Mover Arquivo       │ features/ → history/YYYY-MM/  │ │
│  │ 3. Atualizar ROADMAP   │ Marcar checkbox/checklist    │ │
│  │ 4. Registrar Log       │ context-log.json             │ │
│  │ 5. Adicionar Seção     │ Checklist de conclusão       │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Arquivos

| Arquivo | Propósito |
|---------|-----------|
| `.aidev/lib/feature-lifecycle.sh` | Módulo core com todas as funções |
| `.aidev/plans/features/*.md` | Features ativas (planejadas/em progresso) |
| `.aidev/plans/history/YYYY-MM/*.md` | Features concluídas (organizadas por mês) |
| `.aidev/plans/ROADMAP.md` | Roadmap mestre atualizado automaticamente |
| `.aidev/state/context-log.json` | Log de transições para rastreabilidade |

---

## Uso

### Comandos Disponíveis

```bash
# Listar features ativas
aidev feature list
aidev feature ls

# Concluir uma feature
aidev feature complete <feature-id> [notas]
aidev feature done <feature-id> [notas]
aidev feature finish <feature-id> [notas]

# Ver status de features
aidev feature status              # Status geral
aidev feature status <id>         # Status específico

# Ver conteúdo de uma feature
aidev feature show <id>
aidev feature view <id>

# Ajuda
aidev feature help
```

### Exemplo de Uso

```bash
# 1. Ver features ativas
$ aidev feature list
📋 Features Ativas em .aidev/plans/features:

  📄 "Smart Upgrade: Merge Inteligente"
     ID: smart-upgrade-merge
     Status: Planejado

  📄 "Protocolo de Execução de Sprints"
     ID: sprint-execution-protocol
     Status: Em Progresso

Total: 2 feature(s) ativa(s)

# 2. Concluir uma feature
$ aidev feature complete smart-upgrade-merge \
    "Implementação concluída com sucesso. Todos os testes passando."

🚀 Concluindo feature: smart-upgrade-merge

✅ Feature concluída com sucesso!

📄 Título: Smart Upgrade: Merge Inteligente
📁 Arquivado em: .aidev/plans/history/2026-02/smart-upgrade-merge-13.md

Próximos passos:
  1. Verifique o ROADMAP.md atualizado
  2. Crie um release note se necessário
  3. Prossiga com a próxima feature
```

---

## Automação em Skills

### Integração com Skills

Quando uma skill é concluída com sucesso, o sistema oferece automaticamente arquivar a feature:

```bash
# No final de uma skill (ex: test-driven-development)
skill_complete "test-driven-development"

# Sistema verifica features ativas
📋 Features ativas detectadas:
  - "Smart Upgrade: Merge Inteligente" (smart-upgrade-merge) [Em Progresso]

💡 Use 'aidev feature complete <id>' para marcar como concluída
```

### Recomendação para Implementadores de Skills

Adicione no final da skill (seção "Ao Completar"):

```markdown
### Ao Completar

1. Todos os testes passando
2. **VERIFICAR**: Existe feature ativa para arquivar?

Se sim, execute:
```bash
aidev feature complete <feature-id> "Implementacao concluida"
```
```

---

## Formato do Arquivo Concluído

Quando uma feature é concluída, o arquivo ganha uma seção de conclusão:

```markdown
---

## ✅ Conclusão

**Status:** Concluído  
**Data Conclusão:** 2026-02-13  
**Timestamp:** 2026-02-13T13:00:53Z

**Notas:**
Teste de automação do lifecycle de features

### Checklist de Conclusão

- [x] Implementação completa
- [x] Testes passando
- [x] Documentação atualizada
- [x] Revisão de código realizada
- [x] Merge para branch principal
- [x] Feature arquivada em `.aidev/plans/history/`

---

*Arquivo movido automaticamente para histórico em: 2026-02-13T13:00:53Z*
```

---

## API Interna

### Funções Exportadas

```bash
# Concluir uma feature
feature_complete <feature_id> [completion_notes]
# Retorna: JSON com success, title, history_file, completed_at

# Listar features ativas
feature_list_active
# Retorna: JSON array com id, title, status, file

# Obter arquivo de uma feature
feature_get_file <feature_id>
# Retorna: path do arquivo ou vazio

# Extrair metadata
feature_get_metadata <feature_file>
# Retorna: JSON com id, title, status, priority, sprint, etc

# Hook para skills
feature_on_skill_complete <skill_name> <task_id> <result>
# Mostra features ativas quando skill é concluída

# CLI handler
feature_cli <subcommand> [args...]
# Delega para comandos específicos
```

### Uso Programático

```bash
# Carregar módulo
source .aidev/lib/feature-lifecycle.sh

# Concluir programaticamente
result=$(feature_complete "minha-feature" "Notas de conclusão")

# Verificar sucesso
if [ $? -eq 0 ]; then
    title=$(echo "$result" | jq -r '.title')
    echo "Feature concluída: $title"
fi
```

---

## Configuração

### Variáveis de Ambiente

```bash
# Diretórios customizados (opcional)
export FEATURES_DIR=".aidev/plans/features"
export HISTORY_DIR=".aidev/plans/history"
export ROADMAP_FILE=".aidev/plans/ROADMAP.md"
```

### Convenções de Nomenclatura

- **Features ativas**: `.aidev/plans/features/{nome-da-feature}.md`
- **Histórico**: `.aidev/plans/history/{YYYY-MM}/{nome-da-feature}-{DD}.md`
- **Organização**: Arquivos no histórico são organizados por mês/ano

---

## Checklist de Validação

Para garantir que o sistema está funcionando:

```bash
# 1. Verificar se módulo existe
[ -f .aidev/lib/feature-lifecycle.sh ] && echo "✅ Módulo existe"

# 2. Testar listagem
source .aidev/lib/feature-lifecycle.sh
feature_list_active | jq '. | length'

# 3. Testar conclusão (com feature de teste)
feature_complete "test-feature" "Teste"

# 4. Verificar context-log
grep "feature_complete" .aidev/state/context-log.json

# 5. Verificar arquivo no histórico
ls .aidev/plans/history/$(date +%Y-%m)/*-$(date +%d).md
```

---

## Troubleshooting

### Problema: Feature não encontrada

```bash
# Verificar ID correto
aidev feature list

# Usar parte do nome
aidev feature complete "smart"  # Encontra "smart-upgrade-merge"
```

### Problema: jq não instalado

O sistema depende de `jq` para manipulação JSON. Instale:

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Verificar instalação
jq --version
```

### Problema: Permissões

```bash
# Verificar permissões de escrita
ls -la .aidev/plans/features/
ls -la .aidev/plans/history/

# Corrigir se necessário
chmod 755 .aidev/plans/features/
chmod 755 .aidev/plans/history/
```

---

## Próximos Passos

### Melhorias Futuras

1. **Integração com Git**: Criar tag/release automaticamente ao concluir feature
2. **Notificações**: Alertar outros agentes sobre conclusão
3. **Estatísticas**: Métricas de tempo de desenvolvimento por feature
4. **Integração com Issues**: Sincronizar com sistema de issues (GitHub, Jira)
5. **Dependências**: Detectar e sugerir próximas features baseadas em dependências

---

## Resumo

✅ **Implementado**:
- Módulo `lib/feature-lifecycle.sh` com funções core
- Comando CLI `aidev feature [list|complete|status|show]`
- Automação de arquivamento em `history/YYYY-MM/`
- Atualização automática de ROADMAP.md
- Registro em context-log.json
- Integração com skills (documentação atualizada)

🎯 **Benefícios**:
- Padronização do processo de conclusão
- Continuidade entre sessões de diferentes LLMs
- Rastreabilidade completa
- Redução de erros manuais
- Histórico organizado e acessível

---

*Documentação gerada automaticamente pelo sistema de lifecycle de features v1.0*
