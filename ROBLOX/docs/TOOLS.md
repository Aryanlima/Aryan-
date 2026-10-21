# Herramientas (PC de Aryan, Windows 11) — estado al 2026-10-21

Instalación y detalles: `entorno-y-toolchain.md` y `estado-pc.md`.

| Herramienta | Versión | Estado |
|---|---|---|
| Claude Code | 2.1.304 | Funciona |
| OpenAI Codex CLI | 0.163.0 (`npm i -g @openai/codex`, paquete oficial) | Funciona con la cuenta de ChatGPT de Aryan. En `~/.codex/config.toml`: carpeta de confianza y `[windows] sandbox = "unelevated"` (sin esto rechaza todo comando con "blocked by policy"). Git: `safe.directory` del repo y de los worktrees de Codex |
| Roblox Studio | instalado en Program Files | Funciona; playtest por MCP verificado |
| MCP de Studio (`Roblox_Studio`) | integrado en Studio | Conectado (`claude mcp list`) |
| Rojo / Rokit | 7.7.1 / 1.2.0 | Funciona (`rojo build` verificado) |
| StyLua / Selene / luau-lsp / Lune | 2.6.0 / 0.32.0 / 1.70.1 / 0.11.0 | Funcionan (`lint.sh`, `test.sh`) |
| Git / Node / npm / Python | 2.54 / 24.21 / 11.19 / 3.14 | Funcionan |
| Ropilot (app de escritorio + plugin) | app en `%APPDATA%opilot` | Registrado en Claude (`claude mcp add ropilot`, usa `ropilot-infra-helper.exe mcp --ropilot-external-mcp`) y ya lo estaba en Codex. Conectado en `claude mcp list`. Es de terceros: su plugin ejecuta código recibido de ropilot.ai; pide cuenta/créditos. El paquete npm `ropilot` está abandonado: no usarlo |
| GitHub CLI `gh` | — | No instalado (no hace falta: push por git) |

## Skills
- Claude (`~/.claude/skills`):
  - 23 técnicas de Roblox de EL4CTEO/roblox-skills (MIT).
  - 19 de diseño y negocio de AshExplained/roblox-skills (MIT).
  - `roblox-dev` (del repo), `roblox-game-orchestrator` y `token-efficient-development` (propias).
  - De diseño e investigación: find-skills, hallmark, humanizer, ui-ux-pro-max, last30days, diagram-design.
- Codex (`~/.agents/skills`): las 23 técnicas y `roblox-dev`.

## Colaboración Claude + Codex
`tools/codex-task.sh` (worktree y `codex exec`) y `docs/ai-tasks/`. Ver `docs/ai-tasks/README.md`.
