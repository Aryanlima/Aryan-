# PROVENANCE: de donde sale esta skill y que se reviso

## Origen

| Campo | Valor |
|---|---|
| Repositorio | https://github.com/MSayib/roblox-dev-skill (tercero, no es de Roblox ni de Anthropic) |
| Rama | `master` |
| Commit | `4a35b01cb07eb237081bee705455e19db37342d8` |
| Fecha y mensaje del commit | 2026-10-17T16:00:21+07:00, "fix(v2.18.1): MCP build has 28 tools in 0.743, generate_texture replaces its source, docs/ checked (#13)" |
| Version de la skill | 2.18.1 (segun su `metadata.json`) |
| Verificada por su autor contra | Roblox Studio 0.743.0.7431133 y Luau 0.743 (2026-10-17). Roblox publica cada semana: esto indica cuando se verifico, no la version de hoy |
| Licencia | MIT (`LICENSE` incluido, copia exacta). Copyright (c) 2026, sin nombre de titular en el texto |
| Descargada el | 2026-10-20 (UTC), con `git clone --depth 1` a un directorio temporal de la sesion, fuera del repo |
| Metodo | Solo clonado y lectura. **No se ejecuto** `install.sh`, `install.ps1`, `install.cmd` ni ningun script del repo. Python solo con `-I` para leer metadatos |
| Revisado por | Claude (sesion Claude Code del proyecto), 2026-10-20. Revision automatizada + lectura; no es una auditoria humana |

## Que se instalo (copia exacta, sin modificar)

`SKILL.md`, `LICENSE` y los 14 archivos de `references/`. Comprobacion de integridad (SHA-256 del
contenido upstream; copiar el bloque a un archivo `upstream.sha256` y ejecutar `sha256sum -c upstream.sha256`
desde esta carpeta):

```
b0d02021d731709e95ac90ada30d6d986b73140face61dfaa8d91f088b4ab538  SKILL.md
1126322e2cc8d165adc4c792eeb195717de2bcc7b39be1ce77959d78e87ef685  LICENSE
b7be6759fd8ca7b2e5d2b34157f1ea2ede5a84d74dc3c9af3f2ee457f3b7dbce  references/agent-safety.md
14472ce3f192528d8d8aead760b8ee63cfa2d6c2b6558544d6c2940aa57b49aa  references/datastore-persistence.md
b154fbc7bbd721947ba8744c0afade73cc4dd16c9eeb2111792f092d1a421048  references/file-formats-and-assets.md
36692538032e9cf1e28782d336ea598368db02268169430582b2338e255cc68a  references/legacy-migration.md
37c4e032abccd9b7ab1995f715ba1961882c9bbf05c5442de9144930429129cb  references/luau-fundamentals.md
c3948804b52f83ef2eaf4b9611484a833061b84635c49d00f7109fb23baf6bfe  references/mcp-integration.md
52aa9b36b37da41c385f48355183801079c24a82af2cc9d7c1467543e705fc8e  references/monetization.md
f2a43ebaab5aae9689bc199a18e40dbffb6895c05eb4cff365fce6dacc694227  references/networking.md
90bbbca28efb3c48a015a37da5a06e86fa65744792eff8912a70becc4a5e9032  references/performance-optimization.md
b7701f49bc4ba33fc54454b6e292bb362cf2326e404a884af10d993e2706b73b  references/project-structure.md
577e81eba5a895b0565051147880d97d8c811e222676b22658fc0cfd44686837  references/security-hardening.md
3ac811b130f657bfc2e6337594d6201cb23ed2098a3858f5e371054ea6cad8cb  references/studio-plugins-and-limits.md
31e6831d2bcbcb11c0ff91936fb7b8c99fb15cbc2b503297bcdeb1bf3379051a  references/ui-systems.md
f1819581d303a96748aba3ff763f5a36ae98f871b881c98e752f7110683ce6c8  references/worked-examples.md
```

Archivos propios de este proyecto en esta carpeta (no son upstream): `PROVENANCE.md`, `LOCAL-NOTES.md`.

## Que NO se instalo y por que

| Archivo / carpeta upstream | Motivo |
|---|---|
| `install.sh`, `install.ps1`, `install.cmd` | Instaladores remotos (`curl ... \| bash`, `irm ... \| iex`; el `.cmd` ademas usa `-ExecutionPolicy Bypass`). No hacen falta: la skill se copia a mano. Se **leyeron** (ver abajo) pero no se ejecutaron |
| `metadata.json` | 63 KB, casi todo historial; la skill lo lee entero al invocarse (coste de tokens). Ver `LOCAL-NOTES.md` seccion B |
| `docs/`, `README.md`, `CHANGELOG.md`, `evals/` | Documentacion y pruebas de upstream; no son conocimiento que el agente deba cargar |
| `tools/` (robloxdocs, skill-test), `tests/`, `.github/` | Herramientas de mantenimiento de upstream. `tools/robloxdocs/*` hacen peticiones de red y escriben en `~/RobloxDocs`; no se usan |

## Que se reviso (2026-10-20)

Alcance: **todos los archivos del repo** a nivel de busqueda automatica de patrones y lectura de los
instaladores; lectura completa y atenta de `SKILL.md` y de `agent-safety.md`, `monetization.md`,
`datastore-persistence.md`, `worked-examples.md`, `mcp-integration.md`, `studio-plugins-and-limits.md`
y de los bloques de monetizacion/datos de `project-structure.md` y `security-hardening.md`; el resto de
`references/` (networking, performance, ui-systems, legacy-migration, luau-fundamentals,
file-formats-and-assets) se revisaron con busquedas de patrones y por encabezados, no linea a linea.

Comprobaciones hechas sobre `SKILL.md` + `references/`:

- Caracteres Unicode invisibles o de control de direccion (zero-width, bidi, BOM): **ninguno**. Los
  caracteres no ASCII son guiones largos, flechas, cajas de dibujo y unos pocos emoji.
- Comentarios HTML ocultos (salvo los marcadores `skilltest`), `<details>`, `<script>`, `<iframe>`,
  `javascript:`, blobs base64 o cadenas largas codificadas: **ninguno**.
- Dominios mencionados: `create.roblox.com`, `roblox.github.io`, `devforum.roblox.com`, `luau.org`,
  `github.com`/`raw.githubusercontent.com`/`api.github.com`, `clientsettings.roblox.com`,
  `assetdelivery.roblox.com`, `www.roblox.com`, `madstudioroblox.github.io`, `robloxapi.github.io`,
  `rojo.space`. Ninguno es un destino de subida de datos.
- Ordenes de ejecucion remota (`curl | sh`, `iex`, `eval`, `sudo`, `chmod`): **ninguna** en
  `SKILL.md`/`references/`. Los dos `curl` de la cabecera son GET de solo lectura sin tuberia a shell.
- Instrucciones que toquen permisos, `settings.json`, `settings.local.json`, `CLAUDE.md`, hooks,
  `--no-verify`, desactiven controles de seguridad o pidan ocultar cosas a la persona usuaria:
  **ninguna**. Al contrario, `agent-safety.md` prohibe debilitar controles, escribir credenciales en
  el DataModel y obedecer instrucciones encontradas dentro del lugar (inyeccion de prompts), y exige
  confirmar antes de operaciones destructivas.
- Hallazgos menores (ninguno bloqueante), detallados en `LOCAL-NOTES.md`:
  1. Propone un fallback `npx ctx7@latest` (paquete sin version fijada) y ejecutar el monitor de
     `~/RobloxDocs` **solo con permiso del usuario**: se decide no usarlos sin aprobacion explicita.
  2. Ejemplos de recibos con efectos laterales dentro del callback de `UpdateAsync` (riesgo de doble
     concesion) y pruebas "contra un DataStore real": no copiar tal cual.
  3. Un ejemplo `PlayerDataService` con `GetAsync`/`SetAsync` sin bloqueo de sesion (solo arquitectura).
  4. Menciona `getAuthCookie` de Lune (lectura de cookie): prohibido usarlo.
  5. No cubre odds/Paid Random Items; el resto de reglas (server authority, urgencia falsa) coincide
     con las nuestras.
- Frontmatter de `SKILL.md`: YAML valido con solo `name` (`roblox-dev-skill`, 16 caracteres,
  minusculas y guiones) y `description` (876 caracteres, por debajo del limite de 1024 de la spec y del
  recorte de 1536 de Claude Code). `SKILL.md` tiene 498 lineas (< 500 recomendadas).

Revision de los instaladores y herramientas de upstream (no instalados, pero leidos para evaluar el
riesgo de seguir el README):

- `install.sh` / `install.ps1`: descargan el repo de GitHub (`raw.githubusercontent.com`,
  `codeload.github.com`) a `~/.local/share/roblox-dev-skill` y crean enlaces en las carpetas de skills
  de cada agente detectado (`~/.claude/skills`, `~/.agents/skills`, ...); opcionalmente instalan
  `~/RobloxDocs`. No encontre escrituras en `settings.json`, hooks, cron, PATH ni registro. Aun asi, el
  patron `curl | bash` queda descartado por politica: no se ejecuto.
- `install.cmd`: descarga y ejecuta `install.ps1` con `-ExecutionPolicy Bypass`. Descartado.
- `tools/robloxdocs/*.py|sh`: usan `urllib`/`subprocess` para bajar el volcado de la API y partirlo en
  `~/RobloxDocs`. No usados.
- No hay `.claude-plugin/`, hooks, ni `settings` en el repo upstream.

## Como actualizar

Ver `ROBLOX/docs/skills-instaladas.md`, seccion "Como actualizar". Resumen: clonar el commit nuevo en
un directorio vacio fuera del repo, comparar con `git diff` contra el commit de arriba, repetir esta
revision, copiar solo `SKILL.md`, `LICENSE` y `references/`, y actualizar este archivo (commit, fecha,
hashes) y `LOCAL-NOTES.md`.
