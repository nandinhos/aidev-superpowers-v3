# Ciclo de Desenvolvimento - AI Dev Superpowers

## Visão Geral do Workflow

Este documento explica como trabalhar no desenvolvimento do próprio AI Dev Superpowers mantendo a instalação global sempre atualizada.

## Estrutura de Instalações

```
┌─────────────────────────────────────────────────────────────┐
│                    SEU PROJETO LOCAL                        │
│  ~/projects/aidev-superpowers-v3-1/                        │
│  ├── .aidev/          (seu desenvolvimento)                │
│  ├── bin/aidev        (código fonte do CLI)                │
│  ├── lib/*.sh         (módulos em desenvolvimento)         │
│  └── VERSION          (versão em desenvolvimento)          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ ./bin/aidev system link
                            │ (cria symlinks para desenvolvimento)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│               INSTALAÇÃO GLOBAL                              │
│  ~/.aidev-superpowers/                                      │
│  ├── bin/aidev        ───────► ~/projects/.../bin/aidev     │
│  ├── lib/             ───────► ~/projects/.../lib/          │
│  ├── agents/          ───────► ~/projects/.../.aidev/agents │
│  ├── skills/          ───────► ~/projects/.../.aidev/skills │
│  ├── VERSION          (arquivo físico)                     │
│  └── templates/       (copiado)                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ aidev system deploy
                            │ (copia arquivos físicos)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│               PROJETOS CLIENTES                              │
│  ~/projects/minha-app-laravel/                              │
│  └── .aidev/        (instalado via aidev init)              │
└─────────────────────────────────────────────────────────────┘
```

## Ciclo de Desenvolvimento Completo

### Fase 1: Desenvolvimento Ativo (Link Mode)

**Quando usar:** Durante o desenvolvimento de novas features

```bash
# 1. Ir para o diretório do projeto
 cd ~/projects/aidev-superpowers-v3-1

# 2. Ativar modo desenvolvimento
./bin/aidev system link

# Resultado:
# - ~/.aidev-superpowers/bin/aidev → symlink para seu código
# - ~/.aidev-superpowers/lib/ → symlink para seu código
# - ~/.aidev-superpowers/agents/ → symlink para .aidev/agents
# - ~/.aidev-superpowers/skills/ → symlink para .aidev/skills
```

**Benefícios:**
- ✅ Alterações no código fonte são imediatas
- ✅ Testa em tempo real em outros projetos
- ✅ Sem necessidade de redeploy a cada mudança

### Fase 2: Teste em Projeto Cliente

**Quando usar:** Validar as mudanças em um projeto real

```bash
# 1. Ir para um projeto Laravel (ou qualquer outro)
cd ~/projects/minha-app-laravel

# 2. Testar os comandos novos
aidev mcp laravel detect
aidev mcp laravel setup
aidev doctor

# 3. Se encontrar bugs, corrigir no código fonte
# (as alterações são imediatas graças aos symlinks)
```

### Fase 3: Consolidar (Deploy)

**Quando usar:** Quando a feature está pronta e testada

```bash
# 1. Voltar ao diretório do projeto
cd ~/projects/aidev-superpowers-v3-1

# 2. Desativar modo link (rollback)
./bin/aidev system rollback

# 3. Fazer deploy (copia física dos arquivos)
./bin/aidev system deploy

# Resultado:
# - Arquivos são copiados (não mais symlinks)
# - VERSION é atualizado
# - Backup é criado automaticamente
```

### Fase 4: Versionamento

**Quando usar:** Após deploy bem-sucedido

```bash
# 1. Verificar status
git status

# 2. Commit das alterações
git add -A
git commit -m "feat(mcp): add Laravel Docker auto-config

- Add mcp laravel command
- Auto-detect containers
- Auto-install Laravel Boost
- Multi-project support"

# 3. Opcional: bump de versão se necessário
./bin/aidev release --patch  # ou --minor, --major
```

## Comandos do Sistema

### `aidev system link`
**Propósito:** Modo desenvolvimento com symlinks

**O que faz:**
- Cria symlinks de `~/.aidev-superpowers/` → `~/projects/aidev-superpowers-v3-1/`
- Mantém VERSION e backups como arquivos físicos
- Permite desenvolvimento em tempo real

**Use quando:**
- Desenvolvendo novas features
- Corrigindo bugs
- Testando em outros projetos

### `aidev system rollback`
**Propósito:** Desfazer modo link

**O que faz:**
- Remove symlinks
- Restaura arquivos físicos do backup mais recente
- Prepara para deploy

**Use quando:**
- Antes de fazer deploy
- Quando precisa de arquivos físicos estáveis

### `aidev system deploy`
**Propósito:** Consolidar desenvolvimento

**O que faz:**
- Copia arquivos fisicamente (sem symlinks)
- Atualiza VERSION
- Cria backup automático
- Sincroniza templates

**Use quando:**
- Feature está completa
- Precisa de arquivos físicos estáveis
- Preparando para release

## Fluxo de Trabalho Recomendado

### Cenário 1: Nova Feature (ex: MCP Laravel)

```bash
# 1. Setup inicial
cd ~/projects/aidev-superpowers-v3-1
./bin/aidev system link

# 2. Desenvolvimento
# ... criar arquivos em .aidev/mcp/laravel/
# ... modificar bin/aidev
# ... testar localmente

# 3. Teste em projeto real
cd ~/projects/minha-app-laravel
aidev mcp laravel detect  # testa comando novo

# 4. Voltar e corrigir se necessário
cd ~/projects/aidev-superpowers-v3-1
# ... corrigir bugs (alterações são imediatas)

# 5. Consolidar quando pronto
./bin/aidev system rollback
./bin/aidev system deploy

# 6. Versionar
git add -A
git commit -m "feat(mcp): add Laravel Docker auto-config"
```

### Cenário 2: Correção de Bug Urgente

```bash
# 1. Identificar bug (em qualquer projeto)
cd ~/projects/qualquer-projeto
aidev status
# ... percebe que tem bug

# 2. Corrigir no código fonte
cd ~/projects/aidev-superpowers-v3-1
# (já está em modo link, então alterações são imediatas)
vim bin/aidev
# ... corrigir bug

# 3. Testar imediatamente (sem deploy!)
cd ~/projects/qualquer-projeto
aidev status  # já usa código corrigido

# 4. Se funcionar, consolidar
cd ~/projects/aidev-superpowers-v3-1
./bin/aidev system rollback
./bin/aidev system deploy

# 5. Commit
git add bin/aidev
git commit -m "fix(cli): corrige bug em status"
```

### Cenário 3: Desenvolvimento Paralelo

```bash
# Feature A em uma branch
git checkout -b feature/A
./bin/aidev system link
# ... desenvolve feature A

# Testar feature A em projeto cliente
cd ~/projects/cliente-1
aidev comando-novo-A

# Voltar para main para outra feature
cd ~/projects/aidev-superpowers-v3-1
./bin/aidev system rollback
git checkout main

# Feature B em outra branch
git checkout -b feature/B
./bin/aidev system link
# ... desenvolve feature B

# Testar feature B em outro projeto
cd ~/projects/cliente-2
aidev comando-novo-B
```

## Checklist de Desenvolvimento

### Antes de começar:
- [ ] Verificar se está na branch correta
- [ ] Executar `./bin/aidev system link` se necessário
- [ ] Verificar `aidev doctor` no projeto local

### Durante desenvolvimento:
- [ ] Testar frequentemente em projetos clientes
- [ ] Verificar se alterações são aplicadas (symlinks funcionando)
- [ ] Manter commits atômicos e descritivos

### Antes de finalizar:
- [ ] Testar em pelo menos 2 projetos diferentes
- [ ] Executar `./bin/aidev doctor` para validar
- [ ] Verificar se não quebrou funcionalidades existentes
- [ ] Executar `./bin/aidev system rollback` + `deploy`
- [ ] Commit final com mensagem descritiva

### Após deploy:
- [ ] Verificar `aidev --version` mostra versão correta
- [ ] Testar em projeto cliente (agora com arquivos físicos)
- [ ] Criar PR/MR se trabalhando em equipe

## Dicas Importantes

### 1. Sempre mantenha backup
```bash
# Backup automático é criado em cada deploy
ls ~/.aidev-superpowers/.last_deploy_backup

# Para restaurar manualmente:
./bin/aidev system rollback
```

### 2. VERSION é crítico
```bash
# O arquivo VERSION é a fonte única de verdade
cat VERSION
# v3.8.2

# Atualizar quando fizer release
./bin/aidev release --patch
```

### 3. Debug de symlinks
```bash
# Verificar se está em modo link
ls -la ~/.aidev-superpowers/bin/
# Se mostrar -> symlink, está em modo link
# Se mostrar arquivo físico, está normal

# Verificar para onde apontam
readlink ~/.aidev-superpowers/bin/aidev
```

### 4. Limpando estado
```bash
# Se algo der errado, limpe tudo
./bin/aidev system rollback
rm -rf ~/.aidev-superpowers
./bin/aidev system deploy  # Reinstala do zero
```

## Troubleshooting

### "Comando não encontrado após alteração"
```bash
# Verificar se symlink está correto
ls -la $(which aidev)

# Recriar link se necessário
./bin/aidev system rollback
./bin/aidev system link
```

### "Versão antiga sendo usada"
```bash
# Verificar cache
hash -r  # Limpa cache de comandos do shell

# Ou reiniciar terminal
exec bash
```

### "Alterações não aparecem em projeto cliente"
```bash
# 1. Verificar se está em modo link
cd ~/projects/aidev-superpowers-v3-1
./bin/aidev system status

# 2. Verificar se symlink está correto
readlink ~/.aidev-superpowers/bin/aidev

# 3. Se necessário, recriar
./bin/aidev system rollback
./bin/aidev system link
```

## Resumo do Workflow Ideal

```
┌─────────────┐
│   START     │
└──────┬──────┘
       │
       ▼
┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│  system link │────►│ Desenvolver │────►│ Testar em   │
└──────────────┘     │   código    │     │   cliente   │
                     └──────┬──────┘     └──────┬──────┘
                            │                     │
                            │◄────── loop ──────►│
                            │                     │
                            ▼                     │
                     ┌──────────────┐            │
                     │  Funciona?   │◄───────────┘
                     └──────┬───────┘
                            │
                   Não      │      Sim
                    ┌───────┴───────┐
                    │               ▼
                    │      ┌──────────────┐
                    │      │ system       │
                    │      │ rollback +   │
                    │      │ deploy       │
                    │      └──────┬───────┘
                    │             │
                    │             ▼
                    │      ┌──────────────┐
                    │      │ git commit   │
                    │      └──────┬───────┘
                    │             │
                    └─────────────┘
                                  ▼
                           ┌──────────────┐
                           │   RELEASE    │
                           │   (opcional) │
                           └──────────────┘
```

---

**Lembrete:** O modo link é seu melhor amigo durante desenvolvimento. Use-o sempre para testar em tempo real!
