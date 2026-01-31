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