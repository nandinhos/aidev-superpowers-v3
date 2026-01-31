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