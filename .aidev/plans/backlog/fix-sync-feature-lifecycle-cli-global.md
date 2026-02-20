# Fix: Sincronizar feature-lifecycle-cli.sh para instalação global

**Status:** Ideia
**Prioridade:** Alta
**Criado:** 2026-02-20

---

## Problema

`feature-lifecycle-cli.sh` existe em `lib/` do projeto mas **não está presente em
`~/.aidev-superpowers/lib/`** (instalação global usada pelo CLI `aidev`).

Como resultado, os comandos `aidev start`, `aidev done` e `aidev complete` falham com:

```
✗ Modulo feature-lifecycle-cli nao encontrado
```

Isso torna impossível executar o fluxo de lifecycle via CLI sem sincronização manual.

## Causa Raiz

O módulo foi desenvolvido e existe no repositório do projeto, mas o `aidev upgrade`
(que sincroniza `lib/` local → `~/.aidev-superpowers/lib/`) não foi executado após
a implementação da feature `feature-lifecycle-automation`.

## Objetivo

Garantir que `aidev start`, `aidev done` e `aidev complete` funcionem corretamente
a partir do CLI global instalado em `~/.aidev-superpowers/`.

## Solução Proposta

1. Executar `aidev upgrade` para sincronizar `lib/feature-lifecycle-cli.sh` para
   `~/.aidev-superpowers/lib/`
2. Verificar se há outros módulos de `lib/` local que também não foram sincronizados
3. Validar todos os comandos de lifecycle após sincronização:
   ```bash
   aidev start <feature-id>
   aidev done <sprint-id>
   aidev complete <feature-id>
   ```

## Critérios de Aceite

- [ ] `aidev start <id>` executa sem erro "Modulo feature-lifecycle-cli nao encontrado"
- [ ] `aidev done <sprint>` executa corretamente
- [ ] `aidev complete <id>` executa corretamente
- [ ] `~/.aidev-superpowers/lib/feature-lifecycle-cli.sh` existe e está atualizado
- [ ] Nenhum outro módulo de `lib/` local está faltando na instalação global

## Dependências

- `aidev upgrade` funcional
- `lib/feature-lifecycle-cli.sh` (já existe no projeto)

## Estimativa

~15min — verificação + upgrade + validação
