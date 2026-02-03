---
title: Estratégia de Versionamento e Release
tags: [versioning, release, automation, best-practices]
created_at: 2026-02-03
---

# Estratégia de Versionamento e Release

## Problema
Em projetos distribuídos ou monolitos modulares, a string de versão (ex: `v3.3.0`) tende a se espalhar por múltiplos arquivos (`package.json`, `README.md`, `setup.py`, scripts de deploy), gerando inconsistência e esquecimento durante o release.

## Solução
Implementamos um **Agente de Release Manager** que automatiza a identificação e atualização desses pontos.

### Princípios Chave:
1.  **Fonte Única da Verdade (SSOT)**: Defina um arquivo (ex: `lib/core.sh` ou `package.json`) como a fonte mestre. Todos os outros são derivados.
2.  **Atomicidade**: O processo de bump de versão, changelog e tag deve ocorrer em um único commit de release.
3.  **Pré-checagem Rígida**: Testes e Git limpo são pré-requisitos não negociáveis.

## Técnica de Busca Avançada (Discovery)
Para encontrar onde a versão está "escondida" no sistema, não confie apenas em caminhos hardcoded. Use busca heurística:

```bash
# Encontra arquivos que contêm o padrão de versão atual (ex: 3.3.0)
grep -r "3\.3\.0" . --exclude-dir=.git --exclude-dir=node_modules

# Encontra definições de variáveis comuns
grep -rE "(VERSION|version).*=.*[0-9]+\.[0-9]+\.[0-9]+" .
```

O Agente de Release deve ser capaz de receber novos caminhos descobertos por essa busca e adicioná-los à sua lista de atualização.
