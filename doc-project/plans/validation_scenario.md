# Plano de Validação: Fluxo de Lições Aprendidas

## Objetivo
Verificar a desconexão entre o local onde a skill `learned-lesson` salva os arquivos e o local onde o Orquestrador realiza a leitura, sem alterar o código-fonte inicialmente.

## Fase 1: Diagnóstico (Não Invasivo)
1. **Verificar Lógica do `aidev status`:**
   - Confirmar exatamente qual diretório o comando `aidev status` lê.
   - *Ação:* `grep -C 5 "lessons_dir=" bin/aidev`

2. **Verificar Lógica de Contexto do Orquestrador:**
   - Confirmar qual diretório o `lib/orchestration.sh` utiliza para injetar lições no contexto.
   - *Ação:* `grep -C 5 "lessons_dir=" lib/orchestration.sh`

3. **Verificar Instrução no Template da Skill:**
   - Confirmar a instrução fixada no template da skill.
   - *Ação:* `grep "artifact:" templates/skills/learned-lesson/SKILL.md.tmpl`

## Fase 2: Simulação (Modificação Segura de Estado)
Criaremos arquivos de lição fictícios em ambos os locais para observar o comportamento do sistema.

1. **Caso de Teste A: Comportamento Atual (Knowledge Base)**
   - Criar uma lição fictícia em `.aidev/memory/kb/teste-licao-kb.md`.
   - Executar `./bin/aidev status`.
   - *Resultado Esperado:* A lição **NÃO** deve aparecer na seção de "Histórico" ou "Lições Recentes".

2. **Caso de Teste B: Correção Proposta (State Lessons)**
   - Criar uma lição fictícia em `.aidev/state/lessons/teste-licao-state.md`.
   - Executar `./bin/aidev status`.
   - *Resultado Esperado:* A lição **DEVE** aparecer listada no status.

## Fase 3: Análise de Impacto
Com base nos resultados da simulação, confirmaremos:
- **Leitor:** O sistema (CLI e Orquestrador) busca apenas em `.aidev/state/lessons`.
- **Escritor:** O Agente (via Skill) está instruído erroneamente a escrever em `.aidev/memory/kb`.

## Fase 4: Plano de Implementação (Se Validado)
Se a hipótese for confirmada, o plano de remediação será:
1. **Atualizar Template:** Alterar o campo `artifact` em `templates/skills/learned-lesson/SKILL.md.tmpl` para apontar para `.aidev/state/lessons/`.
2. **Migração (Opcional):** Mover arquivos existentes de `kb` para `lessons` (atualmente não existem arquivos).
3. **Validação Final:** Executar a skill `learned-lesson` em um ciclo real de correção de bug.