# Governança de Desenvolvimento - aidev-superpowers

Este documento define as regras estritas para evolução deste projeto.

## 1. Commits

Todos os commits devem seguir este padrão exato:

**Formato:** `Sprint X (Fase Y): <Descrição em Português>`

**Restrições:**
- **NUNCA** use emojis no título do commit.
- **NUNCA** use "Co-authored-by" ou atribuições de IA.
- **Sempre** em Português Brasil.
- **Sempre** inclua a Fase e o Sprint.

### Histórico de Fases
- **Fase 1**: Desenvolvimento Inicial (CLI, Templates, West-Coast Style)
- **Fase 2**: Recuperação após Data Loss & Hardening de Segurança
- **Fase 3**: Evolução Multi-Plataforma e Agentes Avançados (Atual)

## 2. Padrões de Código
- **TDD Obrigatório**: Não escreva código sem teste.
- **Segurança First**: Scripts de manutenção (como uninstall.sh) devem ter camadas de proteção dinâmicas.
- **Local First**: Priorize execução local e commit local antes de pushes.

## 3. Orquestração
- A ferramenta `aidev` deve ser o ponto central para gerenciar todos os outros projetos do ecossistema.
- O foco deve ser tornar a ferramenta confiável e robusta para recuperação de todos os outros projetos `unificados`.
