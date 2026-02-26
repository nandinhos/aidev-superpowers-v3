# Backlog - Bug: Instalador Global Não Instala no Projeto

## Visão Geral

Ao executar `curl -sSL https://raw.githubusercontent.com/nandinhos/aidev-superpowers-v3/main/install.sh | bash` e aceitar inicializar o projeto, o output mostra "0 Diretórios" e "7 Arquivos" mas nenhum arquivo é criado no diretório do projeto. Apenas após rodar `aidev init` manualmente a instalação funciona.

**Origem**: Relatório do usuário em 2026-02-25. Cenário: Instalação global via curl, resposta "y" para inicializar projeto, contadores mostram 0 diretórios/7 arquivos mas nada é criado efetivamente.

---

## Causa Raiz Identificada

1. O instalador chama `"$BIN_PATH/aidev" init --install-in "$PWD"` (install.sh:103)
2. `cmd_init` usa `$AIDEV_ROOT_DIR` (bin/aidev:54) que aponta para `~/.aidev-core/` (global)
3. Funções como `install_agents()` (bin/aidev:1898) buscam templates em `$AIDEV_ROOT_DIR/templates/`
4. Quando executado via install.sh, o PATH pode não estar configurado ainda
5. As funções falham silenciosamente - nenhuma verificação de erro após `install_aidev_lib()`, `install_agents()`, etc.
6. `should_write_file()` pode bloquear reescrita sem log adequado
7. **Resultado**: contadores ficam em 0 porque as funções retornam antes de criar algo

---

## Tarefas Prioritárias

### 1. [HIGH] Diagnosticar Falha Silenciosa

**Descrição**: Identificar exatamente onde a instalação falha

**Detalhes técnicos**:
- Adicionar logs explícitos nas funções `install_aidev_lib()`, `install_agents()`, `install_skills()`, `install_rules()`
- Verificar se `$AIDEV_ROOT_DIR` está correto quando chamado via install.sh
- Verificar se `should_write_file()` está bloqueando escritas
- Testar se os caminhos de templates estão resolving corretamente

**Critério de sucesso**: Log claro mostrando por que nada é criado

---

### 2. [HIGH] Corrigir Resolução de Caminhos

**Descrição**: Garantir que instalação use caminhos corretos independente de como foi chamada

**Detalhes técnicos**:
- Em `cmd_init`, verificar se `$CLI_INSTALL_PATH` está sendo passado corretamente
- Em `install_aidev_lib()`, adicionar log do source e destination paths
- Em `install_agents()`, `install_skills()`, `install_rules()` - mesmo tratamento

**Critério de sucesso**: Instalação via curl funciona corretamente

---

### 3. [MEDIUM] Adicionar Verificação de Resultados

**Descrição**: Garantir que instalação realmente criou algo antes de mostrar summary

**Detalhes técnicos**:
- Após cada `install_*`, verificar se arquivos/diretórios foram criados
- Se zero, logar warning ou erro

**Critério de sucesso**: Usuário recebe feedback real do resultado

---

### 4. [LOW] Teste de Integração

**Descrição**: Criar teste que simula instalação via curl

**Critério de sucesso**: Bug não regressa

---

## Critérios de Aceitação

1. ✅ Instalação via `curl | bash` com resposta "y" cria arquivos no projeto
2. ✅ Log claro se algo falhar (sem falha silenciosa)
3. ✅ Contadores refletem realidade (não mais "0 Diretórios")
4. ✅ `aidev init` continua funcionando quando executado manualmente

---

## Observações

- **Comportamento esperado**: Usuário roda curl | bash, aceita inicializar projeto, arquivos aparecem em ./aidev/
- **Comportamento atual**: Usuário vê "0 Diretórios, 7 Arquivos" mas nada é criado
- **workaround atual**: Rodar `aidev init` manualmente após a instalação

---

## Referências

- instalador: `install.sh`
- CLI principal: `bin/aidev`
- funções de instalação: `create_base_structure()`, `install_agents()`, `install_skills()`, `install_rules()`
- contadores: `lib/core.sh` (AIDEV_DIRS_CREATED, AIDEV_FILES_CREATED)
