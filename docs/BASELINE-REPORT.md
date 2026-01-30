# Relatório de Baseline - AI Dev Superpowers V3

> Gerado em: 2026-01-29
> Versão Fonte: 4.1.1

## Contagem de Linhas

| Arquivo | Linhas |
|---------|--------|
| aidev-installer.sh | 1844 |
| aidev-templates.sh | 1539 |
| antigravity-bootstrap.sh | 2736 |
| **Total** | **6119** |

---

## Mapeamento de Funções

### aidev-installer.sh (25 funções)

| Função | Linha | Destino Proposto |
|--------|-------|------------------|
| `print_header()` | 56 | lib/core.sh |
| `print_step()` | 63 | lib/core.sh |
| `print_success()` | 67 | lib/core.sh |
| `print_info()` | 71 | lib/core.sh |
| `print_warning()` | 75 | lib/core.sh |
| `print_error()` | 79 | lib/core.sh |
| `print_summary()` | 83 | lib/core.sh |
| `show_help()` | 100 | lib/cli.sh |
| `ensure_dir()` | 220 | lib/file-ops.sh |
| `write_file()` | 232 | lib/file-ops.sh |
| `detect_stack()` | 255 | lib/detection.sh |
| `detect_platform()` | 308 | lib/detection.sh |
| `parse_args()` | 347 | lib/cli.sh |
| `validate_args()` | 408 | lib/cli.sh |
| `create_base_structure()` | 447 | lib/commands/init.sh |
| `create_skills_core()` | 490 | lib/commands/init.sh |
| `create_agents()` | 698 | lib/commands/init.sh |
| `create_skills()` | 735 | lib/commands/init.sh |
| `create_global_rules()` | 790 | lib/commands/init.sh |
| `create_rules()` | 1204 | lib/commands/init.sh |
| `create_readme()` | 1291 | lib/commands/init.sh |
| `create_config_files()` | 1488 | lib/commands/init.sh |
| `create_state_templates()` | 1519 | lib/commands/init.sh |
| `create_workflows()` | 1550 | lib/commands/init.sh |
| `main()` | 1803 | bin/aidev |

---

### aidev-templates.sh (18 funções)

| Função | Linha | Destino Proposto |
|--------|-------|------------------|
| `create_agent_orchestrator()` | 14 | templates/agents/orchestrator.md.tmpl |
| `create_agent_architect()` | 62 | templates/agents/architect.md.tmpl |
| `create_agent_backend()` | 106 | templates/agents/backend.md.tmpl |
| `create_agent_frontend()` | 158 | templates/agents/frontend.md.tmpl |
| `create_agent_qa()` | 206 | templates/agents/qa.md.tmpl |
| `create_agent_devops()` | 251 | templates/agents/devops.md.tmpl |
| `create_agent_legacy_analyzer()` | 301 | templates/agents/legacy-analyzer.md.tmpl |
| `create_agent_security_guardian()` | 353 | templates/agents/security-guardian.md.tmpl |
| `create_skill_brainstorming()` | 413 | templates/skills/brainstorming.md.tmpl |
| `create_skill_writing_plans()` | 501 | templates/skills/writing-plans.md.tmpl |
| `create_skill_test_driven_development()` | 601 | templates/skills/tdd.md.tmpl |
| `create_skill_systematic_debugging()` | 729 | templates/skills/debugging.md.tmpl |
| `create_skill_code_analyzer()` | 900 | templates/skills/code-analyzer.md.tmpl |
| `create_skill_task_planner()` | 989 | templates/skills/task-planner.md.tmpl |
| `create_startup_protocol()` | 1081 | templates/config/startup-protocol.md.tmpl |
| `create_platform_config()` | 1301 | templates/config/platform-config.json.tmpl |
| `create_session_state_template()` | 1413 | templates/state/session-state.md.tmpl |
| `create_lessons_index_template()` | 1460 | templates/state/lessons-index.md.tmpl |

---

### antigravity-bootstrap.sh (63 funções)

| Função | Linha | Destino Proposto |
|--------|-------|------------------|
| `print_*()` | 71-98 | lib/core.sh (merge) |
| `show_help()` | 113 | lib/cli.sh (merge) |
| `parse_args()` | 173 | lib/cli.sh (merge) |
| `detect_stack()` | 256 | lib/detection.sh (merge) |
| `detect_project_context()` | 313 | lib/detection.sh |
| `detect_existing_modules()` | 350 | lib/detection.sh |
| `should_write_file()` | 398 | lib/file-ops.sh |
| `write_file()` | 413 | lib/file-ops.sh (merge) |
| `create_dir()` | 431 | lib/file-ops.sh |
| `create_directories()` | 450 | lib/commands/init.sh |
| `extract_prd_info()` | 497 | lib/commands/init.sh |
| `create_context_md_*()` | 507-825 | templates/config/context.md.tmpl |
| `create_agents_md()` | 826 | templates/config/agents.md.tmpl |
| `create_source_index()` | 885 | lib/commands/init.sh |
| `create_agent_*()` | 966-1234 | templates/agents/*.tmpl (merge) |
| `create_rule_*()` | 1235-1552 | templates/rules/*.tmpl |
| `create_workflow_*()` | 1553-1824 | templates/workflows/*.tmpl |
| `create_skill_*()` | 1825-2005 | templates/skills/*.tmpl |
| `create_session_state()` | 2006 | templates/state/session-state.md.tmpl |
| `create_antigravity_readme()` | 2047 | templates/config/readme.md.tmpl |
| `create_project_docs()` | 2099 | lib/commands/init.sh |
| `setup_mcp_engine()` | 2161 | lib/mcp.sh |
| `create_mcp_config()` | 2240 | templates/mcp/mcp-config.json.tmpl |
| `setup_claude_hooks()` | 2317 | lib/mcp.sh |
| `handle_*_mode()` | 2460-2632 | lib/commands/init.sh |
| `print_summary()` | 2633 | lib/core.sh |
| `main()` | 2688 | bin/aidev |

---

## Observações

1. **Duplicação significativa** entre os 3 scripts nas funções de output e detecção
2. **Templates inline** em heredocs devem ser extraídos para arquivos `.tmpl`
3. **MCP integration** concentrada em `antigravity-bootstrap.sh` (linhas 2161-2380)
