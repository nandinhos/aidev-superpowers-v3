# Smart Context & Prompt Refinement Plan

**Objetivo**: Tornar o AI Dev consciente do estágio do projeto e adaptar seu comportamento.

## 1. Mapeamento de Contexto (`lib/detection.sh`)

Implementar `detect_maturity` e `detect_style`.

### 🟢 Greenfield (Novo)
*   **Definição**: Diretório vazio/novo ou < 10 commits.
*   **Requisito Crítico**: **PRD (Product Requirements Document)** obrigatório.
*   **Fluxo de Inicialização**:
    1.  Verificar existência de `docs/PRD.md` ou solicitar conteúdo.
    2.  **Agente Especializado**: Ler PRD e sugerir skills personalizadas.
    3.  **ERD**: Verificar diagrama de banco (opcional).
*   **Prompt**: "Mode: Creator. Architecture first. Follow PRD strictly."

### 🟤 Brownfield (Legado/Em Andamento)
*   **Definição**: Base de código existente, histórico git longo.
*   **Fluxo de Inicialização**:
    1.  **Health Check**: Rodar diagnóstico (`legacy-analyzer`) para identificar pontos críticos.
    2.  **Style Extraction**: Ler linter/formatter existentes (`detect_style`).
*   **Prompt**: "Mode: Maintainer. Analyze first. Respect existing patterns."

## 2. Execução (Roadmap)

1.  [x] **Core**: Implementar detecção de maturidade e estilo.
2.  [x] **CLI**: Adaptar `aidev init` para os dois fluxos.
3.  [x] **Templates**: Inserir condicionais Handlebars (`{{#if IS_GREENFIELD}}`).
