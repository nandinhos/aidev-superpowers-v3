# Current - Em Execução

> Feature sendo executada agora. Máximo 1 por vez.

---

## Fluxo

```
backlog/ (ideia) → features/ (planejada) → current/ (executando) → history/YYYY-MM/ (concluída)
```

**Regras:**
- Apenas 1 feature ativa aqui por vez
- Checkpoint atualizado a cada sprint concluída
- Ao concluir: mover para `history/YYYY-MM/`, limpar esta pasta, atualizar READMEs

---

## Feature Ativa

### Basic Memory Graceful Integration

**Arquivo:** [basic-memory-graceful-integration.md](basic-memory-graceful-integration.md)
**Iniciada:** 2026-02-20
**Estimativa total:** ~305min (~5h05)

| Sprint | Objetivo | Status |
|---|---|---|
| Pré-Sprint 0 | Pipeline de distribuição — `install_aidev_lib()` | **PROXIMO** |
| Sprint 1 | `mcp-detect.sh` — detecção multi-runtime | Pendente |
| Sprint 2 | `basic-memory-guard.sh` — bash + LLM | Pendente |
| Sprint 3 | `ckpt_sync_to_basic_memory()` | Pendente |
| Sprint 4 | `context_compressor_generate()` enriquecido | Pendente |
| Sprint 5 | `cmd_status`, `cmd_doctor`, QUICKSTART | Pendente |

**Próximo passo:** Implementar Pré-Sprint 0 — adicionar `install_aidev_lib()` em `bin/aidev`

---

*Última atualização: 2026-02-20*
