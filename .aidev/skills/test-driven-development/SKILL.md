---
name: test-driven-development
description: Ciclo RED-GREEN-REFACTOR obrigatorio para todo codigo de producao
triggers:
  - "implementar"
  - "codigo"
  - "desenvolver"
  - "tdd"
  - "feature"
globs:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "tests/**"
steps: 3
checkpoints:
  - red_phase_complete
  - green_phase_complete
  - refactor_phase_complete
requires_validation: true
---

# Test-Driven Development Skill

## Metadata
- **Total de Steps**: 3 (RED, GREEN, REFACTOR)
- **Ciclo**: Repetir para cada unidade de funcionalidade
- **Prerequisito**: Plano de implementacao aprovado

## Principio Fundamental

> **NUNCA** escreva codigo de producao sem um teste que falhe primeiro.
> Codigo sem teste = Divida Tecnica = BLOQUEADO

---

## Safe-Guard: Protecao de Dados

> [!CRITICAL]
> **SEGURANCA EM PRIMEIRO LUGAR**

### Validacoes Obrigatorias Antes de Qualquer Operacao
```bash
# Antes de modificar arquivos
validation_check "safe_path" "$filepath"

# Antes de deletar codigo
validation_check "file_exists" "$filepath"

# Antes de commit
validation_check "tests_pass"
```

### Regras de Seguranca
1. **Snapshots**: Execute `aidev snapshot` antes de mudancas estruturais
2. **Double-Check**: Antes de deletar, listar exatamente o que sera removido
3. **Isolamento**: NUNCA execute `rm -rf` em paths genericos
4. **Confirmacao**: Se houver risco de perda de dados, PARE e peca confirmacao

---

## Step 1: RED Phase
**Checkpoint**: `red_phase_complete`

### Objetivo
Escrever um teste que FALHE pelo motivo correto.

### Acoes
1. Identificar a menor unidade de funcionalidade a implementar
2. Escrever o teste ANTES do codigo
3. Executar o teste - DEVE FALHAR
4. Verificar que falha pelo motivo esperado (nao por erro de sintaxe)

### Template de Teste
```javascript
describe('[Feature/Component]', () => {
  it('should [comportamento esperado] when [condicao]', () => {
    // Arrange - preparar dados
    const input = ...;

    // Act - executar acao
    const result = funcaoATestar(input);

    // Assert - verificar resultado
    expect(result).toBe(expected);
  });
});
```

### Criterios de Validacao
- [ ] Teste escrito ANTES do codigo de producao
- [ ] Teste executado e FALHOU
- [ ] Mensagem de erro indica que funcionalidade nao existe (nao erro de sintaxe)
- [ ] Teste e minimo - testa UMA coisa

### Comando de Verificacao
```bash
# Executar teste e verificar que falha
npm test -- --testNamePattern="[nome do teste]"
# ou
pytest -k "[nome do teste]"
# ou
php artisan test --filter="[nome do teste]"
```

### Confianca
- Se teste passa antes de escrever codigo: `confidence: 0.1` (algo errado)
- Se teste falha pelo motivo certo: `confidence: 0.9` (prosseguir)

---

## Step 2: GREEN Phase
**Checkpoint**: `green_phase_complete`

### Objetivo
Escrever o MINIMO codigo necessario para o teste passar.

### Acoes
1. Implementar APENAS o necessario para o teste passar
2. Nao adicionar features extras
3. Nao otimizar prematuramente
4. Executar o teste - DEVE PASSAR

### Principios
- **YAGNI**: You Aren't Gonna Need It
- **Minimal**: Menos codigo possivel
- **Focused**: Apenas o que o teste exige

### Criterios de Validacao
- [ ] Codigo implementado e MINIMO
- [ ] Nenhuma funcionalidade extra adicionada
- [ ] Teste agora PASSA
- [ ] Nenhum teste existente quebrou

### Comando de Verificacao
```bash
# Executar teste especifico
npm test -- --testNamePattern="[nome do teste]"

# Executar suite completa para verificar regressoes
npm test
```

### Confianca
- Se teste passa e nenhuma regressao: `confidence: 0.95`
- Se outros testes quebraram: `confidence: 0.2` (investigar)

---

## Step 3: REFACTOR Phase
**Checkpoint**: `refactor_phase_complete`

### Objetivo
Melhorar a qualidade do codigo SEM mudar comportamento.

### Pre-Condicoes
```bash
# Antes de refatorar, criar checkpoint
validation_check "tests_pass"
# Se mudanca grande:
aidev snapshot
```

### Acoes
1. Identificar oportunidades de melhoria:
   - Nomes mais claros
   - Extracao de funcoes
   - Remocao de duplicacao (se >= 3 ocorrencias)
   - Simplificacao de logica
2. Fazer UMA melhoria por vez
3. Executar testes apos CADA mudanca
4. Se teste falhar, reverter imediatamente

### Criterios de Validacao
- [ ] Todos os testes continuam passando
- [ ] Codigo mais legivel/manutenivel
- [ ] Nenhum comportamento alterado
- [ ] Commit atomico com mensagem descritiva

### Comando de Verificacao
```bash
# Apos cada refatoracao
npm test

# Verificar que nada quebrou
git diff --stat
```

---

## Anti-Patterns a Evitar

### 1. Test After Implementation
```
ERRADO: Escrever codigo -> Escrever teste
CERTO:  Escrever teste -> Escrever codigo
```

### 2. Testing Implementation Details
```
ERRADO: expect(spy.toHaveBeenCalledWith(...))
CERTO:  expect(result).toBe(expected)
```

### 3. Testes Que Sempre Passam
```
ERRADO: Sem assertions, catch-all de excecoes
CERTO:  Assertions especificas que podem falhar
```

### 4. Flaky Tests
```
ERRADO: Dependem de timing, estado externo
CERTO:  Isolados, deterministicos
```

### 5. Testing the Framework
```
ERRADO: Testar que React renderiza
CERTO:  Testar SUA logica de componente
```

---

## Estrutura de Teste por Stack

### JavaScript/TypeScript (Jest/Vitest)
```javascript
describe('Feature', () => {
  beforeEach(() => { /* setup */ });
  afterEach(() => { /* cleanup */ });

  it('should do X when Y', () => {
    // Arrange -> Act -> Assert
  });
});
```

### PHP (PHPUnit/Pest)
```php
test('feature does X when Y', function () {
    // Arrange
    $input = ...;

    // Act
    $result = $this->feature->execute($input);

    // Assert
    expect($result)->toBe($expected);
});
```

### Python (pytest)
```python
def test_feature_does_x_when_y():
    # Arrange
    input_data = ...

    # Act
    result = feature(input_data)

    # Assert
    assert result == expected
```

---

## Metas de Cobertura

| Tipo | Meta | Foco |
|------|------|------|
| Unit Tests | 80%+ | Funcoes individuais |
| Integration | Paths criticos | Interacao entre modulos |
| E2E | Happy paths + erros | Fluxos completos do usuario |

---

## Transicoes

### Ciclo Completo
```
RED -> GREEN -> REFACTOR -> [proxima feature] -> RED -> ...
```

### Ao Completar Feature
1. Todos os testes passando
2. Cobertura adequada
3. Codigo refatorado
4. Commit atomico

### Handoff
```bash
skill_complete "test-driven-development"
agent_handoff "backend" "qa" "Revisar implementacao" "src/feature.ts"
```

---

## Exemplo de Uso com Orquestrador

```bash
# Para cada unidade de funcionalidade:

skill_init "test-driven-development"
skill_set_steps "test-driven-development" 3

# RED
skill_advance "test-driven-development" "RED: Escrever teste que falha"
# ... escrever teste, verificar que falha ...
validation_log "test_fails" "tests/feature.test.ts" "passed"
skill_validate_checkpoint "test-driven-development"

# GREEN
skill_advance "test-driven-development" "GREEN: Implementar minimo"
# ... implementar codigo minimo ...
validation_check "tests_pass"
skill_validate_checkpoint "test-driven-development"

# REFACTOR
skill_advance "test-driven-development" "REFACTOR: Melhorar qualidade"
# ... refatorar mantendo testes verdes ...
validation_check "tests_pass"
skill_validate_checkpoint "test-driven-development"

skill_complete "test-driven-development"
```

---

## Ferramentas por Stack

| Stack | Test Runner | Coverage | Mocking |
|-------|-------------|----------|---------|
| JavaScript | Jest, Vitest | c8, istanbul | jest.mock |
| TypeScript | Jest, Vitest | c8 | ts-jest |
| PHP | PHPUnit, Pest | xdebug | Mockery |
| Python | pytest | coverage.py | pytest-mock |
| Go | testing | go test -cover | testify |
| Laravel | Pest, PHPUnit | xdebug | Mockery |
| React | RTL, Vitest | c8 | MSW |