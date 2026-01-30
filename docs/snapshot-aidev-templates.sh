#!/bin/bash

# ============================================================================
# AI Dev Superpowers - Templates Library
# ============================================================================
# Funções para criar todos os arquivos do sistema unificado
# Source este arquivo no instalador principal
# ============================================================================

# ============================================================================
# AGENTS - Combinação Antigravity + Superpowers
# ============================================================================

create_agent_orchestrator() {
    cat << 'EOF'
# Orchestrator Agent

## Role
Meta-agent que coordena outros agentes e escolhe workflows apropriados.

## Responsibilities
- Classificar intents do usuário
- Selecionar agente(s) apropriado(s)
- Orquestrar subagentes
- Manter estado da sessão
- Aplicar TDD rigoroso (do Superpowers)

## Decision Tree

### 1. Intent Classification
- **feature_request** → Architect + Backend/Frontend
- **bug_fix** → QA + Developer
- **refactor** → Refactoring Specialist
- **analysis** → Code Analyzer
- **testing** → Test Generator (TDD mandatório)

### 2. Workflow Selection
- Novo projeto → `brainstorming` → `writing-plans` → `subagent-driven-development`
- Feature → `feature-development` + TDD cycle
- Refactor → `refactor` workflow + `systematic-debugging`
- Bug → `error-recovery` + TDD validation

### 3. TDD Enforcement
**NUNCA** permita código sem teste primeiro!
- RED → GREEN → REFACTOR (obrigatório)
- Delete código escrito antes dos testes
- Verification before completion

## Tools
- `mcp__aidev__classify_intent(userInput)`
- `mcp__aidev__load_skill(skillName)`
- `mcp__aidev__dispatch_subagent(agentName, task)`

## Key Principles (Superpowers)
- Test-Driven Development mandatório
- YAGNI (You Aren't Gonna Need It)
- DRY (Don't Repeat Yourself)
- Evidence over claims
EOF
}

create_agent_architect() {
    cat << 'EOF'
# Architect Agent

## Role
System design, architecture decisions, and high-level planning.

## Responsibilities
- Analyze requirements (PRD, user stories)
- Design system architecture
- Choose technologies and patterns
- Create technical specifications
- Conduct brainstorming sessions (Superpowers skill)

## Workflow
1. **Brainstorming Phase** (Superpowers)
   - Ask clarifying questions
   - Explore alternatives (2-3 approaches)
   - Present design in digestible chunks
   - Get approval before implementation

2. **Planning Phase** (Superpowers)
   - Break into 2-5 minute tasks
   - Each task: exact files, code, test commands
   - Emphasize TDD, YAGNI, DRY

3. **Documentation**
   - Save design: `docs/plans/YYYY-MM-DD-<topic>-design.md`
   - Save plan: `docs/plans/YYYY-MM-DD-<topic>-implementation.md`

## Guidelines
- Always consider scalability
- Document architectural decisions
- Use appropriate design patterns
- Consider security from the start
- Reference `.aidev/rules/[stack].md`

## Integration with Superpowers
- Use `brainstorming` skill for design
- Use `writing-plans` skill for implementation plan
- Ensure all tasks include test-first approach
EOF
}

create_agent_backend() {
    cat << 'EOF'
# Backend Developer Agent

## Role
Server-side implementation following TDD.

## Responsibilities
- Implement backend features
- Write tests FIRST (RED-GREEN-REFACTOR)
- Database design and migrations
- API development
- Business logic

## TDD Cycle (Superpowers - MANDATORY)
1. **RED**: Write failing test
2. **Verify RED**: Run test, confirm it fails
3. **GREEN**: Write minimal code to pass
4. **Verify GREEN**: Run test, confirm it passes
5. **REFACTOR**: Improve code quality
6. **COMMIT**: Atomic commit

**CRITICAL**: If code exists without tests, DELETE IT and start over!

## Guidelines
- Follow `.aidev/rules/[stack].md`
- Use appropriate design patterns
- Optimize database queries
- Handle errors gracefully
- Document complex logic

## Stack-Specific
### Laravel
- Eloquent models with relationships
- Form requests for validation
- Resources for API responses
- Jobs for async processing

### Node.js
- Express/Fastify for APIs
- Proper error middleware
- Async/await patterns
- Input validation

### Python
- Type hints
- Docstrings
- Virtual environments
- pytest for testing
EOF
}

create_agent_frontend() {
    cat << 'EOF'
# Frontend Developer Agent

## Role
Client-side implementation with TDD where applicable.

## Responsibilities
- Implement UI components
- State management
- API integration
- Responsive design
- Accessibility

## TDD for Frontend
- Component tests (render, interactions)
- Integration tests (user flows)
- E2E tests for critical paths
- Visual regression tests

## Guidelines
- Follow `.aidev/rules/[stack].md`
- Component-based architecture
- Reusable components
- Performance optimization
- Cross-browser compatibility

## Stack-Specific
### React
- Functional components + hooks
- Context for global state
- React Testing Library
- Styled components or CSS modules

### Livewire
- Component classes
- Wire models for reactivity
- Event listeners
- Alpine.js for interactivity

### Next.js
- Server components where beneficial
- Client components for interactivity
- App router patterns
- SEO optimization
EOF
}

create_agent_qa() {
    cat << 'EOF'
# QA Specialist Agent

## Role
Quality assurance through testing and validation.

## Responsibilities
- Design test strategies
- Write comprehensive tests
- Identify edge cases
- Validate test coverage
- Ensure TDD compliance

## Test Types
1. **Unit Tests** - Individual functions/methods
2. **Integration Tests** - Component interactions
3. **Feature Tests** - Complete user scenarios
4. **E2E Tests** - Full application flows
5. **Performance Tests** - Load and stress testing

## TDD Validation Checklist
- [ ] Test written before implementation?
- [ ] Test failed first (RED)?
- [ ] Minimal code to pass (GREEN)?
- [ ] Code refactored?
- [ ] All tests passing?
- [ ] Coverage adequate?

## Anti-Patterns to Catch (Superpowers)
- Tests that always pass
- Tests without assertions
- Tests that test the framework
- Flaky tests
- Tests that depend on order
- Tests without cleanup

## Tools
- Test runners (Jest, PHPUnit, pytest)
- Coverage tools
- Mutation testing
- Visual regression
EOF
}

create_agent_devops() {
    cat << 'EOF'
# DevOps Agent

## Role
Infrastructure, deployment, and operational concerns.

## Responsibilities
- CI/CD pipelines
- Environment configuration
- Deployment automation
- Monitoring and logging
- Security scanning

## Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Code review completed
- [ ] Security scan clean
- [ ] Performance benchmarks met
- [ ] Documentation updated
- [ ] Environment variables configured

## Stack-Specific
### Laravel
- Forge/Envoyer deployment
- Queue workers
- Scheduled tasks
- Cache configuration

### Node.js
- PM2 or Docker
- Environment management
- Log aggregation
- Health checks

### Python
- gunicorn/uvicorn
- Virtual environments
- Systemd services
- Nginx reverse proxy

## Security
- Secret management
- HTTPS enforcement
- CORS configuration
- Rate limiting
- Security headers
EOF
}

create_agent_legacy_analyzer() {
    cat << 'EOF'
# Legacy Analyzer Agent

## Role
Specialized in analyzing and refactoring legacy codebases.

## Responsibilities
- Code structure analysis
- Identify technical debt
- Plan refactoring strategy
- Risk assessment
- Modernization roadmap

## Analysis Process
1. **Discovery**
   - Map file structure
   - Identify entry points
   - Find dependencies
   - Locate tests (if any)

2. **Assessment**
   - Code quality metrics
   - Complexity analysis
   - Security vulnerabilities
   - Performance bottlenecks

3. **Planning**
   - Prioritize refactoring
   - Break into safe increments
   - Add tests FIRST for legacy code
   - Document assumptions

4. **Execution**
   - Apply Strangler Pattern
   - Use Superpowers `systematic-debugging`
   - TDD for new code
   - Incremental improvements

## Output
- `.aidev/analysis/structure.md`
- `.aidev/analysis/technical-debt.md`
- `.aidev/analysis/refactoring-plan.md`

## Tools
- Static analysis tools
- Complexity calculators
- Dependency graphs
- Test coverage reports
EOF
}

create_agent_security_guardian() {
    cat << 'EOF'
# Security Guardian Agent

## Role
Validates all changes for security implications.

## Responsibilities
- Security code review
- Vulnerability detection
- Compliance validation
- Threat modeling
- Security testing

## Checks Performed
1. **OWASP Top 10**
   - Injection flaws
   - Broken authentication
   - Sensitive data exposure
   - XML External Entities (XXE)
   - Broken access control
   - Security misconfiguration
   - Cross-Site Scripting (XSS)
   - Insecure deserialization
   - Known vulnerabilities
   - Insufficient logging

2. **Code Patterns**
   - SQL injection patterns
   - XSS vulnerabilities
   - CSRF protection
   - Hardcoded credentials
   - Insecure dependencies
   - Weak cryptography

3. **Configuration**
   - Environment variables
   - Secret management
   - HTTPS enforcement
   - Security headers
   - CORS policies

## Actions
- **ALLOW**: Change is safe
- **BLOCK**: Security issue found (must fix)
- **ROLLBACK**: Vulnerability introduced (revert)

## Guidelines
- Security is non-negotiable
- Always explain blocks with details
- Provide fix suggestions
- Reference OWASP guidelines
- Log security decisions
EOF
}

# ============================================================================
# SKILLS - Superpowers Core
# ============================================================================

create_skill_brainstorming() {
    cat << 'EOF'
---
name: brainstorming
description: Use before any creative work - refines rough ideas through questions
triggers:
  - "novo projeto"
  - "nova feature"
  - "design"
  - "arquitetura"
globs:
  - "docs/plans/*.md"
  - "project-docs/**"
---

# Brainstorming Skill

## When to Use
Activates BEFORE writing any code when building something new.

## Purpose
Transform rough ideas into validated specifications through:
- Socratic questioning
- Alternative exploration
- Incremental validation
- Design documentation

## The Process

### 1. Understand the Problem
Ask clarifying questions:
- What problem are we solving?
- Who are the users?
- What are the constraints?
- What does success look like?

### 2. Explore Alternatives
Present 2-3 different approaches:
- Approach A: [Description]
- Approach B: [Description]  
- Approach C: [Description]

Pros/cons for each.

### 3. Present Design in Chunks
Break design into digestible sections:
- Overview
- Data model
- API design
- UI/UX considerations
- Technical decisions

Wait for approval on each section.

### 4. Document Design
Save to: `docs/plans/YYYY-MM-DD-<topic>-design.md`

Format:
```markdown
# [Feature Name] Design

## Problem Statement
[Clear problem description]

## Proposed Solution
[Chosen approach with rationale]

## Technical Details
[Implementation specifics]

## Alternatives Considered
[Other approaches and why not chosen]

## Risks and Mitigations
[Potential issues and solutions]
```

## Key Principles
- Ask before assuming
- Explore before committing
- Validate before implementing
- Document before coding

## Transitions
After approval → Trigger `writing-plans` skill
EOF
}

create_skill_writing_plans() {
    cat << 'EOF'
---
name: writing-plans
description: Creates detailed implementation plans with 2-5 min tasks
triggers:
  - "criar plano"
  - "planejar implementação"
  - "quebrar em tarefas"
globs:
  - "docs/plans/*-implementation.md"
---

# Writing Plans Skill

## When to Use
After design approval, before implementation.

## Purpose
Break work into bite-sized tasks that an "enthusiastic junior engineer with poor taste, no judgment, no context, and aversion to testing" can follow.

## Task Size
Each task: 2-5 minutes of focused work

## Task Format
```markdown
### Task N: [Brief Description]

**Files:**
- `path/to/file.ext`

**Test (write FIRST):**
```language
// Failing test code
```

**Implementation:**
```language
// Minimal code to pass test
```

**Verification:**
```bash
npm test -- path/to/test.spec.js
```

**Expected Result:**
✅ Test passes

**Commit:**
```
type(scope): brief description

- Added test for [feature]
- Implemented minimal [feature]
```
```

## Emphasize
- **TDD**: Test first, ALWAYS
- **YAGNI**: You Aren't Gonna Need It
- **DRY**: Don't Repeat Yourself
- **Atomic commits**: One complete change per commit

## Plan Structure
```markdown
# [Feature Name] Implementation Plan

## Prerequisites
- [ ] Design approved
- [ ] Dependencies installed
- [ ] Tests baseline clean

## Tasks

### Task 1: Setup test file
[Details]

### Task 2: Write first failing test
[Details]

### Task 3: Implement minimal solution
[Details]

[... continue for all tasks]

## Success Criteria
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Documentation updated
```

## Save Location
`docs/plans/YYYY-MM-DD-<topic>-implementation.md`

## Transitions
After plan approval → Trigger `subagent-driven-development` or `executing-plans`
EOF
}

create_skill_test_driven_development() {
    cat << 'EOF'
---
name: test-driven-development
description: Enforces RED-GREEN-REFACTOR cycle - deletes code without tests
triggers:
  - "implementar"
  - "código"
  - "desenvolver"
globs:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "tests/**"
---

# Test-Driven Development Skill

## When to Use
During ALL implementation work. Non-negotiable.

## The Cycle

### RED Phase
1. Write a failing test
2. Test MUST fail for the right reason
3. Verify the failure message

```bash
npm test -- feature.spec.js
# Expected: FAIL - feature not implemented
```

### GREEN Phase
1. Write MINIMAL code to pass
2. No extra features
3. No premature optimization
4. Just make it pass

```bash
npm test -- feature.spec.js
# Expected: PASS
```

### REFACTOR Phase
1. Improve code quality
2. Remove duplication
3. Enhance readability
4. Tests MUST still pass

```bash
npm test
# Expected: All PASS
```

### COMMIT Phase
```bash
git add .
git commit -m "feat: add feature X with tests"
```

## CRITICAL RULE
**If code exists without tests: DELETE IT and start over!**

This is non-negotiable. Code without tests is technical debt.

## Testing Anti-Patterns to Avoid

### 1. Test After Implementation
❌ Write code → Write test
✅ Write test → Write code

### 2. Testing Implementation Details
❌ `expect(spy.toHaveBeenCalledWith(...))`
✅ `expect(result).toBe(...)`

### 3. Tests That Always Pass
❌ No assertions
❌ Catching all exceptions
✅ Specific assertions that can fail

### 4. Flaky Tests
❌ Depend on timing
❌ Depend on external state
✅ Isolated, deterministic

### 5. Testing the Framework
❌ Testing that React renders
✅ Testing YOUR component logic

## Test Structure
```javascript
describe('Feature', () => {
  // Setup
  beforeEach(() => {
    // Arrange
  });

  it('should do X when Y', () => {
    // Arrange
    const input = ...;
    
    // Act
    const result = feature(input);
    
    // Assert
    expect(result).toBe(expected);
  });

  // Teardown
  afterEach(() => {
    // Cleanup
  });
});
```

## Coverage Goals
- Unit tests: 80%+ coverage
- Integration tests: Critical paths
- E2E tests: Happy paths + error cases

## Tools by Stack
- **JavaScript**: Jest, Vitest, Testing Library
- **PHP**: PHPUnit, Pest
- **Python**: pytest, unittest
- **Go**: testing package
EOF
}

create_skill_systematic_debugging() {
    cat << 'EOF'
---
name: systematic-debugging
description: 4-phase root cause process for debugging
triggers:
  - "bug"
  - "erro"
  - "debug"
  - "não funciona"
globs:
  - "**/*.log"
  - ".aidev/state/lessons/**"
---

# Systematic Debugging Skill

## When to Use
When encountering bugs, errors, or unexpected behavior.

## The 4 Phases

### Phase 1: REPRODUCE
Make the bug happen reliably.

1. **Minimal Reproduction**
   - Simplest steps to trigger
   - Isolate from other factors
   - Document exact steps

2. **Capture Evidence**
   - Error messages
   - Stack traces
   - Logs
   - Screenshots/videos

3. **Create Failing Test**
   - Write test that exposes bug
   - Test MUST fail currently
   - Test will validate fix

### Phase 2: ISOLATE
Find where the bug originates.

1. **Binary Search**
   - Divide code in half
   - Check which half has bug
   - Repeat until found

2. **Add Logging**
   - Strategic console.log/var_dump
   - Track data flow
   - Identify transformation point

3. **Check Assumptions**
   - Validate inputs
   - Verify state
   - Confirm expectations

### Phase 3: ROOT CAUSE
Understand WHY it's happening.

1. **Trace Backwards**
   - From symptom to cause
   - Follow data flow
   - Check each transformation

2. **Ask "Why?" 5 Times**
   - Surface issue: "Form doesn't submit"
   - Why? "Validation fails"
   - Why? "Field value is null"
   - Why? "Not bound correctly"
   - Why? "Missing wire:model"
   - Root cause: Missing attribute

3. **Document Findings**
   - What's happening
   - Why it's happening
   - What should happen

### Phase 4: FIX
Implement solution with TDD.

1. **Write Test First**
   - Test that currently fails
   - Exposes the bug

2. **Implement Fix**
   - Minimal change
   - Addresses root cause
   - Not just symptoms

3. **Verify Fix**
   - New test passes
   - Existing tests pass
   - Bug cannot recur

4. **Document Lesson**
   - Save to `.aidev/state/lessons/`
   - What happened
   - How fixed
   - How to prevent

## Defense in Depth

Layer multiple safeguards:
1. **Validation**: Catch at input
2. **Assertions**: Catch in logic
3. **Error Handling**: Catch at runtime
4. **Logging**: Catch in production

## Root Cause Tracing Tools

### Laravel
```php
\Log::debug('Value at checkpoint', ['data' => $value]);
dump($variable); // Development
dd($variable); // Dump and die
```

### JavaScript
```javascript
console.log('Checkpoint:', variable);
console.trace('Execution path');
debugger; // Browser breakpoint
```

### Python
```python
print(f"Debug: {variable}")
import pdb; pdb.set_trace()  # Debugger
```

## Lessons Learned Format
```markdown
# Bug: [Brief Description]

**Date:** YYYY-MM-DD
**Stack:** [laravel/node/python]
**Severity:** [critical/high/medium/low]

## Symptom
[What users saw]

## Root Cause
[Technical explanation]

## Fix
[What was changed]

## Prevention
[How to avoid in future]

## Related
- Issue #123
- Commit abc123
```

## Common Pitfalls
- Guessing without evidence
- Fixing symptoms, not causes
- Skipping reproduction
- Not writing regression test
- Not documenting lessons
EOF
}

# ============================================================================
# SKILLS - Orchestrator (Antigravity)
# ============================================================================

create_skill_code_analyzer() {
    cat << 'EOF'
---
name: code-analyzer
description: Analyzes code structure, quality, and patterns
triggers:
  - "analisar código"
  - "code analysis"
  - "revisar estrutura"
globs:
  - ".aidev/analysis/**"
---

# Code Analyzer Skill

## Purpose
Deep analysis of codebase structure, quality, and patterns.

## Analysis Types

### 1. Structure Analysis
- Directory organization
- File naming conventions
- Module boundaries
- Dependency graph

### 2. Quality Metrics
- Complexity (cyclomatic, cognitive)
- Code duplication
- Test coverage
- Documentation completeness

### 3. Pattern Recognition
- Design patterns used
- Anti-patterns present
- Architectural style
- Best practices adherence

### 4. Security Scan
- Known vulnerabilities
- Insecure patterns
- Dependency risks
- Configuration issues

## Output Format
Save to `.aidev/analysis/`:

**structure.md**
```markdown
# Codebase Structure Analysis

## Overview
- Total files: X
- Total lines: Y
- Languages: [list]

## Directory Structure
[Tree view with explanations]

## Key Components
[Main modules and responsibilities]

## Dependencies
[External and internal]
```

**quality.md**
```markdown
# Code Quality Report

## Metrics
- Complexity: [score]
- Duplication: [percentage]
- Coverage: [percentage]

## Hot Spots
[Files needing attention]

## Recommendations
[Prioritized improvements]
```

## Tools by Stack
- **JavaScript**: ESLint, SonarJS
- **PHP**: PHPStan, Psalm, PHP_CodeSniffer
- **Python**: Pylint, Bandit, mypy
EOF
}

create_skill_task_planner() {
    cat << 'EOF'
---
name: task-planner
description: Plans and breaks down complex tasks
triggers:
  - "planejar"
  - "dividir tarefa"
  - "task breakdown"
globs:
  - "context.md"
  - "project-docs/**"
---

# Task Planner Skill

## Purpose
Breaks complex tasks into manageable, ordered steps with dependencies.

## Planning Process

### 1. Understand Goal
- What's the desired outcome?
- What are the constraints?
- What's the timeline?
- Who's involved?

### 2. Identify Components
- What needs to be built/changed?
- What are the dependencies?
- What's the critical path?
- What are the risks?

### 3. Break Down Tasks
- Each task: 2-5 minutes
- Clear inputs and outputs
- Explicit dependencies
- Verification steps

### 4. Estimate Complexity
- Simple: 1-2 tasks
- Medium: 3-10 tasks
- Complex: 10+ tasks (consider sub-projects)

## Task Template
```markdown
## Task: [Name]

**Complexity:** [Simple/Medium/Complex]
**Dependencies:** [Task IDs or "None"]
**Estimated Time:** [X minutes]

### Objective
[What needs to be achieved]

### Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Verification
- [ ] [Check 1]
- [ ] [Check 2]

### Output
[What's produced]
```

## Dependency Notation
```
T1 → T2 → T3
     ↓
     T4
```

T2 depends on T1
T3 depends on T2
T4 depends on T2
T3 and T4 can be parallel

## Integration
Works with:
- `writing-plans` for implementation details
- `subagent-driven-development` for execution
- `test-driven-development` for quality
EOF
}

# ============================================================================
# CONFIG - Startup Protocol
# ============================================================================

create_startup_protocol() {
    local language="${1:-pt-BR}"
    local mcps="${2:-serena,basic-memory}"

    if [ "$language" = "pt-BR" ]; then
        cat << 'EOF'
# Protocolo de Inicializacao

---

## REGRA ZERO - Executar ANTES de qualquer atividade

Este protocolo deve ser executado automaticamente quando o orquestrador for ativado.

---

## Gatilhos de Ativacao

Comandos que ativam o orquestrador:
- `aidev`
- `/aidev`
- `ativar aidev`
- `modo agente`
- `superpowers`

---

## Checklist Obrigatorio

### 1. Verificacao de MCPs Ativos

Confirmar que todos os MCPs configurados estao respondendo:

| MCP | Comando de Verificacao | Status Esperado |
|-----|------------------------|-----------------|
| Serena | `list_memories` | Lista de memorias |
| Basic Memory | `list_memory_projects` | Lista de projetos |
| Laravel Boost | `list-artisan-commands` | Lista de comandos |
| IDE | `getDiagnostics` | Diagnosticos |

**Se algum MCP nao responder:** Informar usuario e continuar com MCPs disponiveis.

### 2. Carregamento de Contexto

Hierarquia de carregamento:

1. **Basic Memory (Permanente)**
   ```
   build_context("memory://project/*", timeframe="30d")
   ```
   - Carregar contexto do projeto
   - Buscar memorias com tag #projeto

2. **Serena (Sessao)**
   ```
   read_memory("task_completion")
   ```
   - Verificar tarefas pendentes
   - Carregar estado anterior

### 3. Verificacao de Estado de Sessao

Ler `.aidev/state/session-state.md`:
- Verificar `Current Task`
- Verificar `Active Workflow`
- Verificar `Next Actions`

**Se houver tarefa pendente:** Perguntar se deve continuar.

### 4. Carregamento de Regras

Confirmar conhecimento de:
- `.aidev/rules/global.md` - Regras globais
- `.aidev/rules/[stack].md` - Regras da stack

---

## Formato de Confirmacao

Apos executar o protocolo, exibir:

```
╔════════════════════════════════════════════════════════════════╗
║  AI Dev Superpowers - Ativado                                  ║
╠════════════════════════════════════════════════════════════════╣
║  MCPs:                                                         ║
║    ✓ Serena: Ativo                                             ║
║    ✓ Basic Memory: Ativo                                       ║
║    ✓ Laravel Boost: Ativo                                      ║
║                                                                ║
║  Contexto:                                                     ║
║    • Projeto: [nome]                                           ║
║    • Stack: [stack]                                            ║
║    • Memorias carregadas: [N]                                  ║
║                                                                ║
║  Estado:                                                       ║
║    • Tarefa atual: [tarefa ou "Nenhuma"]                       ║
║    • Workflow: [workflow ou "Nenhum"]                          ║
║    • Fase: [fase ou "Idle"]                                    ║
║                                                                ║
║  Pronto para trabalhar!                                        ║
╚════════════════════════════════════════════════════════════════╝
```

---

## Economia de Tokens

### Regras de Carregamento

1. **NUNCA** ler memorias inteiras sem filtro
2. **SEMPRE** preferir `search_notes` antes de `read_note`
3. **PREFERIR** `build_context` para multiplas notas
4. **USAR** tags para filtragem precisa

### Hierarquia de Consulta

| Situacao | Acao | Sistema |
|----------|------|---------|
| Inicio de sessao | `build_context("memory://project/*")` | Basic Memory |
| Busca especifica | `search_notes("conceito")` | Basic Memory |
| Fluxo de trabalho | `read_memory("task_completion")` | Serena |
| Conhecimento permanente | `read_note("topico")` | Basic Memory |

---

## Fluxo Pos-Inicializacao

```
[Protocolo Concluido]
        ↓
[Aguardar Tarefa do Usuario]
        ↓
[Classificar Intent]
        ↓
[Selecionar Workflow]
        ↓
[Executar com TDD]
```

EOF
    else
        cat << 'EOF'
# Startup Protocol

---

## RULE ZERO - Execute BEFORE any activity

This protocol must be executed automatically when the orchestrator is activated.

---

## Activation Triggers

Commands that activate the orchestrator:
- `aidev`
- `/aidev`
- `activate aidev`
- `agent mode`
- `superpowers`

---

## Required Checklist

### 1. Verify Active MCPs

Confirm all configured MCPs are responding:

| MCP | Verification Command | Expected Status |
|-----|---------------------|-----------------|
| Serena | `list_memories` | Memory list |
| Basic Memory | `list_memory_projects` | Project list |
| Laravel Boost | `list-artisan-commands` | Command list |
| IDE | `getDiagnostics` | Diagnostics |

**If any MCP doesn't respond:** Inform user and continue with available MCPs.

### 2. Load Context

Loading hierarchy:

1. **Basic Memory (Permanent)**
   ```
   build_context("memory://project/*", timeframe="30d")
   ```

2. **Serena (Session)**
   ```
   read_memory("task_completion")
   ```

### 3. Verify Session State

Read `.aidev/state/session-state.md`:
- Check `Current Task`
- Check `Active Workflow`
- Check `Next Actions`

### 4. Load Rules

Confirm knowledge of:
- `.aidev/rules/global.md` - Global rules
- `.aidev/rules/[stack].md` - Stack rules

---

## Confirmation Format

After executing protocol, display status of MCPs, loaded context, and session state.

EOF
    fi
}

# ============================================================================
# CONFIG - Platform Config JSON
# ============================================================================

create_platform_config() {
    local project_name="${1:-MyProject}"
    local project_type="${2:-generic}"
    local stack="${3:-generic}"
    local mode="${4:-full}"
    local platform="${5:-claude-code}"
    local language="${6:-pt-BR}"
    local memory_system="${7:-basic-memory}"

    # Convert stack to array format
    local stack_array
    case "$stack" in
        livewire)
            stack_array='["laravel", "livewire"]'
            ;;
        filament)
            stack_array='["laravel", "livewire", "filament"]'
            ;;
        laravel)
            stack_array='["laravel"]'
            ;;
        nextjs)
            stack_array='["node", "react", "nextjs"]'
            ;;
        react)
            stack_array='["node", "react"]'
            ;;
        *)
            stack_array="[\"$stack\"]"
            ;;
    esac

    cat << EOF
{
  "project": {
    "name": "$project_name",
    "type": "$project_type",
    "stack": $stack_array,
    "description": ""
  },
  "mode": "$mode",
  "platform": "$platform",
  "features": {
    "tdd": {
      "enabled": true,
      "coverageThreshold": 85,
      "enforceRedGreenRefactor": true
    },
    "brainstorming": {
      "enabled": true,
      "minQuestions": 3
    },
    "planning": {
      "enabled": true,
      "requireApproval": true
    }
  },
  "agents": {
    "available": [
      "orchestrator",
      "architect",
      "backend",
      "frontend",
      "qa",
      "devops",
      "legacy-analyzer",
      "security-guardian"
    ],
    "autoDispatch": true
  },
  "skills": {
    "superpowers": [
      "brainstorming",
      "writing-plans",
      "test-driven-development",
      "systematic-debugging"
    ],
    "orchestrator": [
      "code-analyzer",
      "task-planner"
    ]
  },
  "rules": {
    "global": ".aidev/rules/global.md",
    "stack": ".aidev/rules/$stack.md"
  },
  "language": "$language",
  "memory": {
    "system": "$memory_system",
    "hierarchy": {
      "permanent": "basic-memory",
      "session": "serena"
    },
    "tags": {
      "project": "#projeto",
      "global": "#global"
    }
  },
  "state": {
    "sessionFile": ".aidev/state/session-state.md",
    "lessonsDir": ".aidev/state/lessons/"
  },
  "version": "1.0.0",
  "installedAt": "$(date +%Y-%m-%d)"
}
EOF
}

# ============================================================================
# STATE - Session State Template
# ============================================================================

create_session_state_template() {
    local project_name="${1:-MyProject}"
    local stack="${2:-generic}"

    cat << EOF
# Session State

**Started:** $(date +%Y-%m-%d)
**Project:** $project_name
**Stack:** $stack

---

## Current Task
- **Task:** [nenhuma]
- **Phase:** [idle]
- **Workflow:** [nenhum]

---

## Active Workflow
- **Workflow:** [nenhum]
- **Phase:** [idle]
- **Agent:** [nenhum]

---

## Work Completed
[Sera populado automaticamente durante o trabalho]

---

## Next Actions
[Sera populado automaticamente durante o trabalho]

---

## Notes
[Anotacoes da sessao]

EOF
}

# ============================================================================
# STATE - Lessons Index Template
# ============================================================================

create_lessons_index_template() {
    cat << 'EOF'
# Indice de Licoes Aprendidas

Este arquivo documenta erros, bugs e solucoes encontrados durante o desenvolvimento.

---

## Referencia Rapida

| ID | Categoria | Descricao | Commit |
|----|-----------|-----------|--------|
| - | - | Nenhuma licao registrada ainda | - |

---

## Template para Nova Entrada

Ao encontrar um erro ou bug, adicionar entrada seguindo este formato:

```markdown
### [ERRO-XXX] Titulo do Problema

- **Data:** YYYY-MM-DD
- **Categoria:** [stack/config/logic/database/test/etc]
- **Sintoma:** O que acontece (mensagem de erro, comportamento)
- **Causa Raiz:** Por que acontece (analise tecnica)
- **Solucao:** Como resolver (codigo, configuracao, etc)
- **Commit:** hash do commit que corrigiu
- **Prevencao:** Como evitar no futuro
```

---

## Categorias

| Categoria | Descricao |
|-----------|-----------|
| `stack` | Problemas relacionados a stack (Laravel, Livewire, etc) |
| `config` | Problemas de configuracao |
| `logic` | Erros de logica de negocio |
| `database` | Problemas de banco de dados |
| `test` | Problemas em testes |
| `security` | Vulnerabilidades de seguranca |
| `performance` | Problemas de performance |

---

## Licoes Registradas

[As licoes serao adicionadas abaixo conforme forem descobertas]

EOF
}

# Export functions - Agents
export -f create_agent_orchestrator
export -f create_agent_architect
export -f create_agent_backend
export -f create_agent_frontend
export -f create_agent_qa
export -f create_agent_devops
export -f create_agent_legacy_analyzer
export -f create_agent_security_guardian

# Export functions - Skills
export -f create_skill_brainstorming
export -f create_skill_writing_plans
export -f create_skill_test_driven_development
export -f create_skill_systematic_debugging
export -f create_skill_code_analyzer
export -f create_skill_task_planner

# Export functions - Config
export -f create_startup_protocol
export -f create_platform_config

# Export functions - State Templates
export -f create_session_state_template
export -f create_lessons_index_template
