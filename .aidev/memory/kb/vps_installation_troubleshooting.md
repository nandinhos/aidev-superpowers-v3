---
title: Instalação e Bugs em VPS (v4.5.4)
description: Soluções encontradas para falhas durante instalação global ou self-upgrade em ambientes sem TTY ou secos (como VPS).
author: Antigravity Orchestrator
tags: [install, upgrade, vps, python, pyyaml, shell]
created_at: 2026-02-20
---

# Licao Aprendida: Resolução de Bugs de Instalação em Ambientes Enxutos (VPS)

## Contexto
Durante testes numa VPS contendo uma aplicação, identificamos três erros distintos com os scripts de instalação e boot do AI Dev (`aidev` cli) que impediam a inicialização correta de novos projetos instalados a partir da versão global recém-baixada.

## Desafios

### 1. "Comando self-upgrade não disponível"
**Problema:** Ao ser detectada a versão desatualizada logo no início do boot, o script entrava numa rotina para perguntar ao usuário se ele gostaria de rodar `cmd_self_upgrade`. Porém, esse bloco rodava globalmente (síncrono) logo após o carregamento do `version-check.sh`, de forma que quando ativava a prompt, as declarações da árvore principal (dentro do `main()`) e outras funções importantes da própria CLI ainda nem existiam.
**Solução:** O `version_check_prompt` foi removido do nível root do arquivo da CLI e injetado firmemente dentro do top-level do método `main()` do `bin/aidev`, protegendo sua execução para acontecer puramente em **runtime** e contendo uma cláusula para suprimir essa checagem caso o comando invocado da vez já fosse relacionado ao update (`self-upgrade`, `upgrade`, `system`, etc).

### 2. Paralisia "cp: são o mesmo arquivo"
**Problema:** Quando a instalação/boot acontecia dentro de caminhos onde `install_path` resultava no mesmo caminho do `AIDEV_ROOT` (por exemplo instalando direto via curl pra global `~/.aidev-core`), a função `create_base_structure` entrava num loop acidental tentando copiar arquivos de governança para si mesmos, falhando prematuramente a geração das pastas do sistema.
**Solução:** Envolvemos o check de cópia numa verificação de negação que pula a cópia caso o path de destino seja idêntico ao root instanciado `[ "$AIDEV_ROOT_DIR" != "$path" ]`.

### 3. Falso-Positivo "YAML Inválido" (PyYAML)
**Problema:** Em servidores minimalistas sem ambiente de desenvolvimento Python formatado (VPS crua), a biblioteca do sistema nativo `python3-yaml` ou `PyYAML` geralmente não está instalada. Assim, o `lib/triggers.sh`, que usa a conversão inline de python3, entrava em colapso avisando falsamente para o usuário que seu arquivo de regras YAML estava inválido ou corrompido, confundindo o log do Doctor.
**Solução:** Criada uma Graceful Degradation (Degradação Graciosa). Foi encapsulado um pre-check condicional `python3 -c "import yaml"` que sai do módulo silenciosamente sem erros ("Processamento abortado"), mantendo os triggers inativos mas sem gerar pânico explícito no output visual ou crash da aplicação.

## Padrões Adotados (Takeaways)
- Ao programar callbacks assíncronos de subcomandos em Bash que envolvam prompts (Y/n), ative-os apenas dentro das engrenagens da sua `main()` evitando eval root-loop.
- Evitemos o uso de dependências pesadas obrigatórias caso o projeto requeira portabilidade Shell para VPS; em todo ecossistema acoplado, verifique os binários antes com gracefully failing via `>=/dev/null`.
- Caminhos root são idênticos ao output destino durante auto-clones no contexto Bash; proteja `cp` operations e evite side-effects com chrooting.
