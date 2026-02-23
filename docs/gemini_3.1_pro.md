# Análise Multidisciplinar de Backlog: IA Agents Roundtable

**Data:** 22/02/2026 (Simulada baseada no timestamp do sistema)
**Participantes:** Orquestrador (Moderador), Architect, Backend, Frontend, QA, DevOps, Security Guardian
**Documentos Analisados:**
1. `rules-engine-standardization.md`
2. `learned-lesson-trigger-gap.md`
3. `mcp-standardized-activation.md` (Placeholder deduzido pelo título)

---

## 🎙️ Abertura (Orquestrador)
**Orquestrador:** Bem-vindos. Temos 3 novas features no backlog que tratam, em última instância, de um problema estrutural no nosso framework: temos configurações declarativas excelentes (taxonomia de regras, YAML de triggers, lista de MCPs desejáveis) mas que não estão sendo acopladas dinamicamente na ativação da LLM no runtime. O objetivo desta mesa é chegarmos a um veredito arquitetural sobre como implementar de forma unificada e segura essas inovações.

---

## 📐 Ponto 1: Rules Engine (Carregamento e Validação de Regras)

**Architect:** A intenção é excelente. A taxonomia de precedência Global > Stack > Projeto faz todo sentido sistêmico. Porém, o verdadeiro desafio da injeção de regras é o limite da janela de contexto. Não podemos concatenar cegamente 80 páginas de Markdown em toda interação. Sugiro que o carregador de regras (`rules-loader`) crie um "Context Payload" otimizado, injetando regras baseado na `active_skill` atual e limitando a escopos restritos.

**Backend:** Total acordo com o Architect. Na implementação da engine BASH (`lib/rules-loader.sh`), precisaremos de um parser para fundir essas 3 camadas. Além disso, as verificações "Pós-Ação" devem ser incorporadas usando hooks naturais. Por exemplo: a regra de "commits em português" rodar via hook limpo, antes mesmo de onerar tokens da LLM para validar.

**Frontend:** Cuidado redobrado na camada de stack! A reincidência de criação da pasta `standards/` no projeto DAS porque a LLM "esquecia" de ler `.aidev/rules/livewire.md` é sintomática. O Frontend precisa da injeção explícita de regras. Devemos ter prevenção anti-duplicação verificando ativamente criações de subpastas como `standards` no momento que ocorrem.

**QA:** Concordo. Como cada validação tem status (pass/warning/error), precisamos de mocks e testes unitários precisos em `tests/unit/test-rules-loader.sh` para atestar a precedência de sobrescrita.

**Veredito sobre Rules Engine:** 
Implementar arquitetura de hooks acionada pelo orchestrator. A engine consolidará as regras por precedência local/global, e as injetará no ciclo através de mecanismos de "System Instruction" compactos ou no momento inicial da ativação, utilizando referências URI para evitar inchaço de contexto e gastando budget de forma consciente.

---

## ⚡ Ponto 2: Gap nos Triggers de Lições Aprendidas

**DevOps / Core:** O arquivo `.aidev/triggers/lesson-capture.yaml` contém triggers de "user_intent" (como *resolvido*, *bug fix*) definidos gramaticalmente perfeitos, mas não há um daemon que dispare isso no pipeline atual do bash de forma transparente.

**Architect:** Capturar output interativo em background é extremamente complexo em Bash (e consome I/O desnecessário). Defendo uma arquitetura desacoplada: acoplar o `trigger-processor` ao fechamento de tarefa ou ao checkpoint. Quando `sprint.sh` executa `update-task completed`, uma mini análise do log do contexto (`context-log.json`) procura os regexes das keywords antes de renderizar o novo plano, lançando a recomendação ao usuário.

**Backend:** É a via mais sólida. Mapearemos em memória uma "State Machine" de ativação (`keyword_detected` -> `skill_suggested`). O hook de validação formal (se a lição tem a Causa Raiz, Solução, etc) fica confinado e embutido no escopo de fim de skill `.aidev/skills/learned-lesson.md`.

**Veredito sobre Triggers:**
Rejeita-se a complexidade de listeners assíncronos (daemons). O `trigger-processor.sh` será uma subrotina consultada nos milestones estruturais (fim de tarefa, chamadas pre-commit ou em handoffs inter-llm) para verificar as heurísticas de expressões regulares do YAML, disparando a oferta do assistente para o registro documental no `/kb/`.

---

## 🔌 Ponto 3: Padronização de Ativação MCP (mcp-standardized-activation)

**Orquestrador:** Com o documento lido, percebemos que a "Padronização de Ativação MCP" vai muito além de health-checks. Precisamos de automação de Onboarding capaz de criar o `.mcp.json` mapeando dependências com base na "Taxonomia de MCPs": os **Universais** (como Context7, Serena, Basic Memory) contra os **Condicionais** (como Laravel Boost), que só serão ativados via Detector de Stack. 

**Architect:** Exato! A configuração crua (hardcoded) do Docker Sail não escala. O Gerador de `.mcp.json` deve atuar resolvendo contextualmente chaves vitais de ambiente (UID, GID e nome dinâmico de container). O `stack-detector` que já havíamos proposto se acopla maravilhosamente a isso: detectou `composer.json` e `artisan` -> adiciona Laravel Boost na subrotina de geração.

**DevOps:** E emenda na validação! Se o `laravel-boost` via Sail tenta ser invocado sem o docker estar UP, o Orquestrador deve injetar status "unavailable" ou propor ação corretiva. O MCP Health-Check vira o coração da robustez das nossas sessões para IAs no projeto.

**Security Guardian:** Acrescento apenas que o `project-onboarding-mcp.md` deve obrigar o uso de variáveis restritas para chaves (ex: repassadas de dot-envs) para garantir que `.mcp.json` gerado se mantenha seguro para versionamento (caso acidentalmente não esteja ignorado num diretório temporário).

**Veredito sobre MCP Activation:**
Criaremos um fluxo em três etapas no Onboarding do Projeto: 
1) **Detector de Stack** identifica as necessidades; 
2) **Gerador/Registry de MCP** constrói ou faz merge inteligente do `.mcp.json` (resolvendo container IDs e paths); 
3) **Validador de Conectividade (Health-Check)** garante que a sessão nasce com todos os poderes declarados rodando perfeitamente.

---

## 🏁 Veredito Final de Implementação Arquitetural (Roadmap Direcional)

Como **Orquestrador**, sintetizando o debate acima, os epicos no backlog serão tratados desta forma para futuras Sprints de Evolução:

1. **Sprint Core (Início):** Motor de Eventos & State Machine (`trigger-processor.sh`). Resolve o aprendizado perdido das lições, adicionando suporte de interceptação aos ganchos de script existentes `sprint.sh` e CLI principal.
2. **Sprint de Integridade (Passo 2):** Engine de Regras BASH (`rules-loader.sh`). O pipeline irá reaproveitar o arcabouço criado nos ganchos estruturais da Sprint 1 para fazer cumprir Taxonomia, anti-duplicação de arquivos (ex: no "standards/") e linting interativo.
3. **Sprint de Externalização (Passo 3):** Standardização MCP, transformando os recursos externos em agentes conectáveis resilientes que sofrem Degradação Simples ao se comportarem mal, e não pânico de kernel no Orquestramento BASH.

Com isso, alinhamos a flexibilidade dos LLMs super-capacitados à rigidez procedimental vital para projetos corporativos mantendo **YAGNI** a frente.
