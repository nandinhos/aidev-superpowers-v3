# Backlog - Gap no Fluxo de Lições Aprendidas

## Visão Geral

O sistema de triggers para captura automática de lições aprendidas possui arquivo YAML de configuração (`.aidev/triggers/lesson-capture.yaml`) com regras bem definidas, mas não existe camada de integração que conecte a detecção de keywords à ativação efetiva do skill `learned-lesson`. O resultado é que lições são salvas manualmente em locais incorretos, sem passar pelo workflow padronizado.

**Origem**: No projeto DAS, o bug Livewire+Alpine morph foi resolvido e documentado, mas o skill `learned-lesson` nunca foi acionado automaticamente apesar de keywords como "corrigimos", "resolvido" e "bug fix" estarem presentes na conversa. A lição foi salva diretamente em `.aidev/memory/kb/` sem validação de checkpoints.

---

## Tarefas Prioritárias

### 1. [HIGH] Documentar o Incidente (Timeline)

**Descrição**: Registrar com precisão o que aconteceu para servir de caso de teste

**Detalhes técnicos**:
- **Problema encontrado**: Elementos com `x-data` dentro de `@foreach` do Livewire não atualizavam após re-render
- **Solução aplicada**: `wire:key` com hash MD5 dos dados (`wire:key="row-{{ $item['id'] }}-{{ md5(json_encode($item)) }}"`)
- **Commit**: `56bfea9` — fix(ui): corrige conflito entre Alpine transitions e Livewire
- **Lição documentada em**: `.aidev/memory/kb/2026-02-22-livewire-alpine-morph-conflict.md`
- **Skill `learned-lesson` acionado?**: Não
- **Estado observado do orquestrador**: `active_skill: "Nenhuma"` durante toda a sessão
- **Keywords presentes na conversa**: "resolvido", "bug fix", "corrigimos" — todas listadas no trigger YAML

**Arquivos de referência**:
- `.aidev/triggers/lesson-capture.yaml` (trigger existente)
- `.aidev/memory/kb/2026-02-22-livewire-alpine-morph-conflict.md` (lição salva manualmente)

---

### 2. [HIGH] Analisar Gap: Trigger YAML → Skill Activation

**Descrição**: Identificar e documentar a lacuna entre a configuração declarativa e a execução

**Detalhes técnicos**:
- O trigger `debug-success-keywords` (ID no YAML) está configurado com:
  - `type: user_intent`
  - `keywords`: "corrigimos", "funciona agora", "resolvido", "bug fix", "aprendi", "lição", etc.
  - `action: activate_learned_lesson_skill`
  - `confidence_threshold: 0.8`
- **Gap identificado**: Não existe runtime/engine que:
  1. Leia o arquivo YAML de triggers
  2. Monitore mensagens do usuário em busca de keywords
  3. Calcule confidence score
  4. Dispare a action correspondente
  5. Ative o skill `learned-lesson` com contexto da conversa
- O YAML é puramente declarativo — nenhum componente do orquestrador o consome

**Arquivos esperados**:
- `.aidev/docs/trigger-gap-analysis.md` (análise detalhada)

---

### 3. [HIGH] Implementar Engine de Triggers

**Descrição**: Criar camada de integração que processe triggers YAML e ative skills

**Detalhes técnicos**:
- Parser de YAML para carregar triggers na inicialização da sessão
- Event listener que monitora:
  - Mensagens do usuário (`user_intent` triggers)
  - Outputs de ferramentas/comandos (`error_pattern` triggers)
  - Estado do workflow (`workflow_state` triggers)
  - Resultados de testes (`test_state` triggers)
- Matching engine:
  - Para `user_intent`: tokenizar mensagem, match contra keywords, calcular confidence
  - Para `error_pattern`: regex match contra output
  - Respeitar `cooldown` entre ativações do mesmo trigger
  - Respeitar `confidence_threshold`
- Dispatcher:
  - `suggest_learned_lesson` → perguntar ao usuário se deseja documentar
  - `activate_learned_lesson_skill` → ativar skill diretamente (quando confidence > threshold)
- Logging de cada trigger avaliado (match ou não) para debugging

**Arquivos esperados**:
- `.aidev/engine/trigger-processor.md` (spec da engine)
- `.aidev/skills/trigger-engine.md` (skill de inicialização)

---

### 4. [HIGH] Implementar Hook de Validação Pós-Lesson

**Descrição**: Garantir que lições salvas passem por validação de checkpoints

**Detalhes técnicos**:
- Após o skill `learned-lesson` gerar o artefato, validar:
  - Arquivo salvo no diretório correto (`.aidev/memory/kb/`)
  - Formato do nome: `YYYY-MM-DD-{slug}.md`
  - Seções obrigatórias presentes: Contexto, Problema, Causa Raiz, Solução, Prevenção
  - Tags preenchidas
  - Referência a commit (se aplicável)
- Se validação falhar, reportar campos faltantes e solicitar correção
- Registrar em Basic Memory: `lesson_validated: true/false`

**Arquivos esperados**:
- `.aidev/skills/lesson-validator.md`

---

### 5. [MEDIUM] Implementar State Machine de Tracking

**Descrição**: Rastrear estado do fluxo de lições para diagnosticar falhas futuras

**Detalhes técnicos**:
- Estados:
  - `idle` → nenhum trigger ativo
  - `keyword_detected` → keyword encontrada, avaliando confidence
  - `skill_suggested` → sugestão apresentada ao usuário
  - `skill_activated` → skill `learned-lesson` em execução
  - `lesson_drafted` → artefato gerado, aguardando validação
  - `lesson_validated` → validação passou
  - `lesson_saved` → artefato persistido com sucesso
- Transições logadas com timestamp
- Estado consultável pelo usuário: "qual o status do fluxo de lições?"
- Persistir estado atual em memória da sessão

**Arquivos esperados**:
- `.aidev/engine/lesson-state-machine.md` (spec)

---

### 6. [LOW] Criar Testes de Integração do Fluxo

**Descrição**: Cenários de teste para validar o fluxo completo

**Detalhes técnicos**:
- Cenário 1: Usuário diz "resolvido" → trigger detecta → skill ativado → lição validada
- Cenário 2: Erro SQL detectado → trigger sugere → usuário aceita → lição salva
- Cenário 3: Keyword detectada mas confidence < threshold → nenhuma ação
- Cenário 4: Cooldown ativo → trigger ignorado
- Cenário 5: Lição salva sem seções obrigatórias → validação falha → correção solicitada

**Arquivos esperados**:
- `.aidev/tests/trigger-integration-scenarios.md`

---

## Dependências

- Parser YAML (para ler triggers)
- Sistema de skills do orquestrador (para ativar `learned-lesson`)
- Basic Memory MCP (para persistir estados e validações)

---

## Critérios de Aceitação

1. ✅ Keywords presentes na conversa ativam o trigger correspondente
2. ✅ Skill `learned-lesson` é acionado automaticamente quando confidence > threshold
3. ✅ Cooldown entre triggers é respeitado
4. ✅ Lições salvas passam por validação de checkpoints (seções, formato, tags)
5. ✅ State machine rastreia todo o fluxo e é consultável
6. ✅ Cenário do projeto DAS (Livewire+Alpine morph) seria capturado automaticamente com a nova implementação

---

## Observações

- **Incidente de referência**: Projeto DAS, 2026-02-22, bug Livewire+Alpine morph
- **Trigger YAML existente**: `.aidev/triggers/lesson-capture.yaml` — bem estruturado, com 4 triggers configurados (error_pattern, user_intent, workflow_state, test_state)
- **Problema não é de configuração**: O YAML está correto e completo. O gap é puramente de implementação — não existe runtime que consuma a configuração
- **Impacto**: Sem a engine, todo o sistema de triggers é dead code declarativo

---

## Referências

- Trigger YAML: `.aidev/triggers/lesson-capture.yaml`
- Lição manual do incidente: `.aidev/memory/kb/2026-02-22-livewire-alpine-morph-conflict.md`
- Commit da correção: `56bfea9` — fix(ui): corrige conflito entre Alpine transitions e Livewire
- Skill `learned-lesson`: `.aidev/skills/learned-lesson.md`
