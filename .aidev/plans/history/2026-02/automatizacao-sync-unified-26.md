# Backlog - Automatização do Sync de Estado Unificado

## Visão Geral

O arquivo `.aidev/state/unified.json` está desatualizado porque não há um processo de atualização automática robusto. O sync depende de execução manual (`aidev sync` ou após commits), mas muitas vezes as LLMs não o fazem. Precisamos garantir que o estado seja sempre atualizado automaticamente.

**Origem**: Observação do usuário em 2026-02-25. unified.json mostra dados antigos (versão 4.4.0 vs atual 4.7.0).

---

## Problema Atual

1. **Sync manual**: Usuário precisa executar `aidev sync` manualmente
2. **LLMs esquecem**: Não há trigger automático para atualizar estado
3. **Dados desatualizados**: unified.json pode ficar dias/_semanas desatualizado
4. **Sem responsabilidade clara**: Não há "dono" do processo de sync
5. **Penalty em rate limits**: Estado desatualizado = perda de contexto em recovery

---

## Análise Técnica

### O que precisa ser sincronizado

| Componente | Arquivo | Frequência |
|------------|---------|------------|
| Estado unificado | `.aidev/state/unified.json` | A cada milestone |
| Snapshot | `.aidev/state/activation_snapshot.json` | A cada checkpoint |
| Skills ativas | `.aidev/state/skills.json` | A cada step |
| Session | `.aidev/state/session.json` | A cada início/fim |

### Responsável atual

- `workflow-sync.sh` - script de sincronização
- Chamado manualmente: `aidev sync`
- Chamado parcialmente em: `aidev commit`, `aidev done`

---

## Tarefas Prioritárias

### 1. [HIGH] Hook Automático de Sync em Comandos CLI

**Descrição**: Garantir sync após operações críticas

**Detalhes técnicos**:
- Em `cmd_done`: chamar workflow-sync.sh automaticamente
- Em `cmd_complete`: chamar workflow-sync.sh automaticamente  
- Em `cmd_checkpoint`: chamar workflow-sync.sh automaticamente
- Opção `--no-sync` para desabilitar se necessário

**Critério de sucesso**: A cada milestone, unified.json atualizado

---

### 2. [HIGH] Sync no Início de Sessão

**Descrição**: Verificar e corrigir estado ao iniciar

**Detalhes técnicos**:
- Ao detectar que AI Dev está instalado:
  - Verificar se unified.json está desatualizado
  - Se sim, executar sync automaticamente
  - Notificar usuário: "Estado sincronizado"
- Em `cmd_status`: sempre mostrar se há sync pendente

**Critério de sucesso**: Sessão sempre começa com estado atual

---

### 3. [MEDIUM] Monitor de Desatualização

**Descrição**: Alertar quando estado está muito antigo

**Detalhes técnicos**:
- Definir threshold: ex: 7 dias = "muito antigo"
- Em qualquer comando:
  - Verificar idade do unified.json
  - Se > threshold, warnar: "Estado desatualizado, execute 'aidev sync'"
- Métrica em `aidev status`: "Última sync: X dias atrás"

**Critério de sucesso**: Usuário sempre sabe se estado está fresco

---

### 4. [LOW] Sistema de Notificações

**Descrição**: Alertas proativos sobre estado

**Detalhes técnicos**:
- Notificações em:
  - Início de sessão (se desatualizado)
  - Antes de operações importantes
  - Em rate limit warning
- Tipos: info, warning, error

**Critério de sucesso**: Sync nunca é esquecido por esquecimento

---

## Fluxo Proposto

```
[Usuário executa comando]
    ↓
[Comando executa operação]
    ↓
[Após milestone/done/complete]
    ↓
[Hook automático → workflow-sync.sh]
    ↓
[unified.json + snapshot atualizados]
    ↓
[Próxima sessão: estado fresco]
```

---

## Dependências

- `bin/aidev` (cmd_done, cmd_complete, cmd_init)
- `.aidev/lib/workflow-sync.sh`
- `.aidev/state/unified.json`

---

## Critérios de Aceitação

1. ✅ A cada `aidev done`, sync automático
2. ✅ A cada `aidev complete`, sync automático
3. ✅ Ao iniciar sessão, verificação de estado
4. ✅ Warning quando estado > 7 dias
5. ✅ unified.json nunca fica > 7 dias desatualizado

---

## Observações

- **Zero friction**: Usuário não precisa lembrar de sync
- **Proativo**: Sistema avisa antes de precisar
- **Recovery**: Estado fresco = melhor continuidade em rate limits

---

## Referências

- Workflow sync: `.aidev/lib/workflow-sync.sh`
- Comando sync: já existe `aidev sync`
- Unified json: `.aidev/state/unified.json`
