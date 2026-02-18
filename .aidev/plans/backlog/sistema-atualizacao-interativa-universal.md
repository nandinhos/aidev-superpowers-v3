# Sistema de Atualização Interativa Universal

> **Status:** Em Implementação  
> **Prioridade:** Alta  
> **Criado:** 2026-02-18

## Contexto

 Atualmente, ao executar qualquer comando `aidev`, o sistema verifica atualizações em background e exibe um alerta não-interativo quando há nova versão disponível. O objetivo é transformar isso em um sistema interativo que:

1. Verifica versão em qualquer comando
2. Pergunta ao usuário se deseja atualizar
3. Executa atualização em duas frentes:
   - Instalação global (`~/.aidev-superpowers/`)
   - Projeto atual (`.aidev/` com preservação de customizações)

---

## Entendimento do Sistema Atual

### Componentes

| Componente | Local | Como Atualiza |
|------------|-------|---------------|
| Instalação Global | `~/.aidev-superpowers/` | `aidev self-upgrade` (copia do source local) |
| Projeto Atual | `./.aidev/` | `lib/upgrade.sh` com checksums e MANIFEST.json |
| Verificação Atual | Hook linhas 70-73 `bin/aidev` | `version_check_alert` em background (não interativo) |

### Políticas do MANIFEST.json

| Categoria | Padrão | Arquivos |
|-----------|--------|----------|
| core | `never_modify_in_project` | bin, lib, templates, VERSION |
| template | `overwrite_unless_customized` | agents, skills, rules |
| state | `never_overwrite` | state/* |
| user | `never_touch` | plans/**, memory/** |

---

## Arquitetura Proposta

### 1. Nova Função: `version_check_prompt()`

**Arquivo:** `lib/version-check.sh`

```bash
version_check_prompt() {
    # Obtém versões local e remota
    # Se desatualizado:
    #   - Exibe info de versão
    #   - Pergunta: "Nova versão X.Y.Z disponível. Atualizar agora? [y/N]"
    #   - Se SIM:
    #       1. Executa self-upgrade (atualiza instalação global)
    #       2. Executa upgrade do projeto atual (sem sobrescrever customizações)
    #   - Se NÃO: mostra mensagem informativa
}
```

### 2. Modificar Hook Global

**Arquivo:** `bin/aidev` (linhas 70-73)

| Antes | Depois |
|-------|--------|
| `(version_check_alert > /dev/tty 2>/dev/null &)` | `version_check_prompt` |

- **Remover `&`** → executa síncrono (aguarda resposta)
- **Substituir função** → de alerta para prompt interativo

### 3. Nova Função: `upgrade_project_if_needed()`

**Arquivo:** `lib/upgrade.sh`

```bash
upgrade_project_if_needed() {
    # Detecta se há atualização de templates/rules disponível
    # Usa upgrade_dry_run() para listar mudanças
    # Executa rsync com --checksum para atualizar:
    #   - .aidev/triggers/*.yaml
    #   - .aidev/AI_INSTRUCTIONS.md
    #   - .aidev/QUICKSTART.md
    # PRESERVA (não sobrescreve):
    #   - Agents customizados
    #   - Skills customizadas
    #   - Rules customizadas
}
```

---

## Fluxo de Execução

```
usuário executa qualquer comando aidev
           │
           ▼
version_check_prompt() [SÍNCRONO]
           │
           ├── Verifica versão local vs GitHub
           │
           ├── Se atualizado:
           │      └── Silencioso (nada faz)
           │
           └── Se desatualizado:
                  │
                  ▼
           ┌─────────────────────────────────────┐
           │  ⚠️  Nova versão disponível!       │
           │                                     │
           │     Versão local:  4.4.2            │
           │     Versão remote: 4.5.0            │
           │                                     │
           │  Deseja atualizar agora? [y/N]      │
           └─────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          │                       │
          ▼                       ▼
        [y/N]                   [n/N]
          │                       │
          ▼                       ▼
   ┌──────────────┐      ┌─────────────────┐
   │ self-upgrade │      │  Exibe info de  │
   │  (global)    │      │  como atualizar │
   └──────────────┘      │  manualmente    │
          │              └─────────────────┘
          ▼
   ┌──────────────────────────────────┐
   │ upgrade_project_if_needed()       │
   │ (projeto atual - preserva custom)│
   └──────────────────────────────────┘
          │
          ▼
      Sucesso!
```

---

## Detalhamento Técnico

### Modificações em `lib/version-check.sh`

| Linha | Mudança |
|-------|---------|
| ~165 | Adicionar `version_check_prompt()` |

### Modificações em `bin/aidev`

| Linha | Mudança |
|-------|---------|
| 71-72 | Substituir `version_check_alert` por `version_check_prompt` (remover `&`) |

### Novo arquivo/função em `lib/upgrade.sh`

| Função | Descrição |
|--------|-----------|
| `upgrade_project_if_needed()` | Atualiza projeto sem sobrescrever customizações |

---

## Considerações Importantes

1. **Self-upgrade** já existe e funciona - precisa apenas ser chamado interativamente
2. **Upgrade de projeto** precisa ser implementado para atualizar templates sem perder customizações
3. **Ordem**: sempre global primeiro (self-upgrade), depois projeto
4. **Falhas**: se self-upgrade falhar, não tentar upgrade de projeto
5. **Mensagens claras**: explicar o que será atualizado em cada frente

---

## Critérios de Aceitação

- [ ] Verificação ocorre em qualquer comando aidev (síncrono)
- [ ] Usuário é perguntado se deseja atualizar
- [ ] Instalação global atualizada via self-upgrade
- [ ] Projeto atual atualizado sem sobrescrever customizações
- [ ] Mensagens claras explicam o que será feito
- [ ] Falhas são tratadas adequadamente
- [ ] Timeout de rede não bloqueia comandos

---

## Tarefas

- [ ] Criar função `version_check_prompt()` em `lib/version-check.sh`
- [ ] Modificar hook global em `bin/aidev` (linhas 70-73)
- [ ] Implementar `upgrade_project_if_needed()` em `lib/upgrade.sh`
- [ ] Testar fluxo completo de atualização
- [ ] Adicionar testes unitários
- [ ] Atualizar documentação

---

*Criado: 2026-02-18*
*Última atualização: 2026-02-18*
