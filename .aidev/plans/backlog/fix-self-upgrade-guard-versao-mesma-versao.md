# Fix: self-upgrade com segunda camada de verificação quando versões são iguais

**Status:** Ideia
**Prioridade:** Média
**Criado:** 2026-02-20

---

## Problema

`aidev self-upgrade` tem uma guarda de versão que bloqueia o sync quando `source_version == current_version`:

```bash
if [ "$current_version" = "$source_version" ] && [ "$AIDEV_FORCE" != true ]; then
    print_success "Ja esta na versao mais recente ($current_version)"
    exit 0
fi
```

Isso causa falsos negativos: quando há ajustes cirúrgicos no código (novos módulos,
correções de bugs, refinamentos) que **não justificam bump de versão**, o `self-upgrade`
simplesmente ignora as diferenças reais entre `lib/` local e `~/.aidev-superpowers/lib/`.

**Caso concreto:** `feature-lifecycle-cli.sh` foi adicionado ao projeto em `4.5.6`
mas nunca chegou à instalação global `4.5.6` porque a guarda bloqueou o sync.
Workaround necessário: `aidev self-upgrade --force`.

## Objetivo

Quando as versões forem iguais, realizar uma **segunda camada de verificação** que
compara o conteúdo real dos arquivos entre source e global, e sincroniza apenas
os arquivos que divergem — sem exigir bump de versão nem `--force`.

## Comportamento Desejado

```
$ aidev self-upgrade

Versao atual: 4.5.6
Versao no source: 4.5.6

✓ Mesma versão — verificando integridade dos arquivos...

  lib/feature-lifecycle-cli.sh → ausente na instalação global
  lib/checkpoint-manager.sh    → modificado (checksum diverge)

2 arquivo(s) desatualizados. Sincronizando...
✓ Sincronização concluída.
```

## Solução Proposta

Em `cmd_self_upgrade()`, substituir o `exit 0` prematuro por uma verificação de diff:

```bash
if [ "$current_version" = "$source_version" ] && [ "$AIDEV_FORCE" != true ]; then
    # Segunda camada: verifica diff real de arquivos
    local diff_count
    diff_count=$(diff -rq "$source_dir/lib/" "$global_install/lib/" 2>/dev/null | wc -l)

    if [ "$diff_count" -eq 0 ]; then
        print_success "Ja esta na versao mais recente e sincronizado ($current_version)"
        exit 0
    fi

    print_info "Mesma versao ($current_version) mas $diff_count diferenca(s) encontrada(s)"
    print_info "Sincronizando arquivos divergentes..."
    # continua fluxo normal de sync
fi
```

### Escopo da verificação

- `lib/` — módulos shell (principal foco)
- `bin/aidev` — o CLI principal
- `templates/` — opcional, mais pesado

## Critérios de Aceite

- [ ] Mesmas versões + arquivos iguais → exit sem sync (comportamento atual mantido)
- [ ] Mesmas versões + arquivos divergentes → sync executado sem precisar de `--force`
- [ ] Output informa o usuário sobre arquivos divergentes encontrados
- [ ] `--force` continua funcionando para forçar sync completo independente de diff
- [ ] Testes unitários em `tests/unit/test-self-upgrade.sh` cobrem os novos cenários

## Dependências

- `bin/aidev` — função `cmd_self_upgrade()` (linha ~3263)
- `diff` disponível no sistema (padrão em qualquer unix)

## Estimativa

~1 sprint de ~30min (fix cirúrgico + testes)
