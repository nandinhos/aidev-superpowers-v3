Relatório Técnico: Comportamento do aidev upgrade
Este relatório detalha o impacto e o comportamento do comando aidev upgrade, analisado experimentalmente no projeto check-print.

1. Ciclo de Execução e Idempotência
Primeira Execução (Migração/Update)
Impacto: O comando identificou a necessidade de atualizar o projeto para a versão 4.5.1.
Mudanças:
Instalou 15 novos workflows em .agent/workflows/.
Atualizou a estrutura de metadados em .aidev/MANIFEST.local.json.
Sobrescreveu o arquivo .mcp.json com configurações padrão para a plataforma antigravity. Isso resultou na perda da configuração customizada do laravel-boost (que usava Docker Sail).
Execução Subsequente (Idempotente)
Impacto: Com o projeto já na versão 4.5.1, o comando agiu de forma conservadora.
Mudanças:
As configurações do .mcp.json foram preservadas. O Git não detectou alterações no arquivo após a segunda execução.
Os workflows foram "reafirmados", mas sem alterações de conteúdo se já fossem idênticos.
A versão e o timestamp de atualização foram registrados em .aidev/MANIFEST.local.json.
2. Estratégia de Backup
Antes de qualquer alteração, o aidev upgrade cria um snapshot completo do diretório .aidev/ em: .aidev/backups/[TIMESTAMP]/

Isso inclui agent definitions, skills e configurações de MCP. É a rede de segurança caso uma customização seja sobrescrita.

3. Preservação de Customizações
Agentes e Skills: O CLI reporta que arquivos customizados em .aidev/agents/ e .aidev/skills/ são preservados, a menos que o flag --force seja usado.
MCP Config: O .mcp.json parece ser re-padronizado apenas durante mudanças de versão major/minor que alteram a especificação da plataforma, ou quando o MANIFEST está desatualizado.
4. Recomendações para o Orquestrador
Para evitar redundâncias e proteger o ambiente:

Checar MANIFEST: Antes de sugerir um upgrade, verificar se a versão atual no .aidev/MANIFEST.local.json já é a desejada.
Snapshot de Configuração: Salvar temporariamente as seções críticas do .mcp.json antes de rodar o upgrade para auto-reparar eventuais sobrescritos indesejados.
Verificação de Triggers: O upgrade reinstala configurações de triggers (Memory Sync), o que é benéfico para manter a integridade operacional.