# Feature: Monitor de Janela de Contexto

> **Status:** Concluido
> **Prioridade:** Média
> **Criado:** 2026-02-20

## Problema

O LLM não tem acesso direto ao contador de tokens da própria janela de contexto.
Atualmente não existe nenhum mecanismo no aidev para alertar sobre uso da janela,
forçando o usuário a perceber manualmente quando está próximo do limite (97%+).

## Objetivo

Adicionar indicador heurístico no dashboard de ativação e em `aidev status` que
sinalize quando é hora de criar checkpoint e abrir nova sessão.

## Implementação Sugerida

### Heurística baseada em turnos e artefatos da sessão

No `activation_snapshot.json` já temos dados suficientes:
- Número de commits discutidos na sessão
- Quantidade de arquivos no context-log
- Timestamp de início vs agora

### Indicador no dashboard de ativação (`activation-snapshot.sh`)

```bash
# Calcular "pressao de contexto" pela quantidade de itens no context-log
context_pressure=$(jq '.context_log | length' .aidev/state/context-log.json 2>/dev/null || echo 0)

if [ "$context_pressure" -gt 20 ]; then
    echo "⚠️  CONTEXTO: Sessão longa detectada ($context_pressure eventos) — considere novo checkpoint"
fi
```

### Aviso no `aidev status`

Mostrar no painel:
```
▸ Janela de Contexto
  Eventos nesta sessão: 23
  ⚠️  Recomendado: criar checkpoint e abrir nova conversa
```

### Comando explícito: `aidev checkpoint`

Atalho que:
1. Atualiza `.aidev/state/checkpoint.md` com estado atual
2. Roda `workflow-sync.sh sync true`
3. Exibe mensagem: "Checkpoint criado. Abra nova janela e diga 'modo agente' para continuar."

## Arquivos a Modificar

| Arquivo | Mudança |
|---------|---------|
| `lib/activation-snapshot.sh` | Adicionar campo `context_pressure` no JSON |
| `.aidev/lib/activation-snapshot.sh` | Idem (cópia deployada) |
| `bin/aidev` `cmd_status()` | Exibir indicador de pressão de contexto |
| `bin/aidev` `cmd_checkpoint()` | Novo comando atalho |

## Critérios de Aceite

- [ ] Dashboard de ativação exibe aviso quando sessão longa detectada
- [ ] `aidev status` mostra indicador de pressão de contexto
- [ ] `aidev checkpoint` cria checkpoint + sync em um comando
- [ ] Heurística configurável (threshold padrão: 20 eventos)
