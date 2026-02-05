---
name: Systematic Release Management
description: Workflow sistemático para versionamento, atualização de documentação e tagueamento seguro de releases.
---

# Systematic Release Management

Esta skill guia o **Release Manager** (ou o desenvolvedor) através de um processo seguro e padronizado de release.

## Fluxo de Trabalho

### Phase 1: Pre-Release Check (Segurança)
1. **Git Clean Check**: Verifique se o diretório de trabalho está limpo.
   - **IMPORTANTE**: Todo o código da versão (features/fixes) já deve estar commitado ANTES de iniciar o release.
   - *Cmd*: `git status --porcelain` (Deve estar vazio)
2. **Testes**: Executar suite de testes para garantir que nada está quebrado.
   - *Ação*: Rode os testes unitários/integração relevantes. Se falhar, ABORTE.

### Phase 2: Version Analysis (Planejamento)
1. **Identificar Versão Atual**: Leia a versão atual do `lib/core.sh` ou arquivo equivalente.
2. **Analisar Commits**: Liste os commits desde a última tag para entender o impacto.
   - *Cmd*: `git log $(git describe --tags --abbrev=0)..HEAD --oneline`
3. **Advanced Discovery**:
   - Busque por arquivos que contenham a versão atual para garantir que nada foi esquecido.
   - *Cmd*: `grep -r "vCURRENT_VERSION" . --exclude-dir={.git,node_modules,vendor}`
4. **Determinar Incremento**:
   - **MAJOR**: Quebra de compatibilidade (Breaking changes).
   - **MINOR**: Novas features compatíveis (Feat).
   - **PATCH**: Correções de bugs (Fix, Docs, Chore, Style).
4. **Definir Nova Versão**: Calcule o número exato (ex: 3.3.0 -> 3.3.1).

### Phase 3: Content Updates (Execução)
1. **Atualizar Arquivos de Versão**:
   - Substitua a string de versão em TODOS os arquivos mapeados (libs, configs, readmes).
2. **Atualizar Changelog**:
   - Crie uma nova seção no topo do `CHANGELOG.md`.
   - Data: Hoje (YYYY-MM-DD).
   - Agrupe os commits em seções: 🚀 Novidades, ⚡ Melhorias, 🐛 Correções.

### Phase 4: Finalization (Release)
1. **Verificação Visual**: Use `git diff` para rever as mudanças automáticas.
2. **Commit de Release**:
   - Mensagem Padrão: `chore(release): prepare vX.Y.Z`
3. **Version Tag**:
   - *Cmd*: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
4. **Push**:
   - *Cmd*: `git push origin main --tags` (Solicite confirmação do usuário antes deste passo).

## Dicas do Mestre
- **Nunca releia código sujo**: Se houver mudanças locais, elas podem ser acidentalmente incluídas no release. Force `git stash` ou `commit` antes.
- **Sincronia é Chave**: O número da versão deve ser idêntico em todos os lugares. Um `grep` pós-alteração ajuda a verificar.