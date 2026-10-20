# Aryan- — juegos de Roblox con microtransacciones

Proyecto: crear muchos juegos de Roblox monetizados con microtransacciones, usando IA para acelerar.

## Cómo trabajar aquí

- **Usar siempre ayudantes (subagentes) en paralelo** para investigar o producir cosas independientes; es más rápido y eficiente. Pedido explícito del usuario. Cada ayudante debe tener un área distinta y escribir su resultado en un archivo.
- Idioma: español (el código y los identificadores en inglés).
- **Todo lo relacionado con Roblox vive en `ROBLOX/`** (investigación, juegos, herramientas, marketing, docs). Pedido explícito del usuario: era una carpeta "ROBLOX" en su Escritorio; como la sesión corre en la nube y no alcanza su Escritorio real, esa carpeta es `ROBLOX/` en este repo y el usuario la clona o descarga a su Escritorio.
- Todo lo que se instale (binarios, toolchain) va en `ROBLOX/.toolchain/` (ignorado por git); scripts y docs usan rutas relativas, nunca `/home/user/...` absolutas.
- La investigación vive en `ROBLOX/research/`. Marcar cada dato como `[OFICIAL]`, `[TERCERO]` o `[NO VERIFICADO]` con fuente y fecha; no inventar cifras ni nombres de APIs.
- Desde la red de esta sesión `create.roblox.com`, `devforum.roblox.com` y Wikipedia están bloqueados (403). No esquivar el proxy; usar `WebSearch` y verificar lo crítico en la documentación oficial desde un equipo con acceso.
- El código de Luau de este repo no se ha probado en Roblox Studio salvo que se indique lo contrario.

## Memoria del proyecto (actualizada 2026-10-20)

**Dos sesiones, un repo.** La sesión en la nube orquesta (investiga, escribe código, lanza ayudantes) y la sesión del PC de Aryan (Windows) son las "manos" (Studio, instalaciones). Comparten todo por la rama `claude/brave-meitner-esyqy8`. La sesión del PC: `git pull` al empezar, y si necesita commitear usa la rama `pc/aryan-local`. Empieza leyendo `ROBLOX/00-LEEME.md` (índice) y `ROBLOX/docs/informe-maestro.md` cuando existan.

**Dónde está cada cosa.** `research/01..09` (se moverán a `ROBLOX/research/`): 01 mejores juegos, 02 monetización, 03 políticas y cumplimiento, 04 IA/Studio/MCP/skills, 05 IA para assets y marketing, 06 stack técnico, 07 diseño/crecimiento/10 conceptos, 08 ropa vs juegos, 09 producción de ropa con IA. Además: `ROBLOX/docs/` (informe maestro, plan de 90 días, preguntas para Aryan, setup en el PC, skills instaladas, arquitectura), `ROBLOX/packages/` (núcleo Luau reutilizable) y `ROBLOX/tests/`, `ROBLOX/games/fish-and-fortune/` (primer juego), `ROBLOX/skills/roblox-dev/` (skill instalada; symlink en `.claude/skills/`), `ROBLOX/tools/clothing-gen/` (generador de ropa), `tools/` (testkit Luau con mocks y scripts de lint/tests), `marketing/pipeline/` (renderizador de videos) y `ROBLOX/marketing/fish-and-fortune/`.

**Hechos verificados en la doc oficial** (repo `Roblox/creator-docs`, leído con WebFetch en `raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/...`):
- DevEx: 0,0038 USD por Robux ganado (antes del 5-sep-2025: 0,0035); 0,0054 solo para gasto de jugadores de EE. UU. 18+ verificados en juegos elegibles (no cubre ítems de avatar); mínimo 30.000 Robux ganados; edad ≥13; email verificado; W-9/W-8 en archivo; pago en ~5-10 días hábiles.
- **Impuestos (urgente):** 31-oct-2026 es el último día bajo los Términos actuales; desde el 1-nov-2026 los pagos DevEx son regalías con retención 0-30 % sobre ventas a jugadores de EE. UU. según país/convenio, o 24 % de retención de respaldo si falta información. Se presenta en Creator Hub > Finances > Taxes (W-8BEN personas, W-8BEN-E empresas). Pendiente de Aryan; no es asesoría fiscal.
- Ropa/ítems de avatar en el Marketplace: creador 30 % base con reparto progresivo (37 % a 1,3× el precio mínimo, 50 % a 2×, 70 % desde 6×); dentro de un juego 30 % creador + 40 % dueño del juego; subida 80 R$ por envío (no reembolsable si se rechaza); anticipo reembolsable 10 R$ (ropa clásica) y 600 R$ (ropa en capas); se cobra a 0,0038.
- Red de la sesión en la nube: `create.roblox.com`, `devforum.roblox.com` y Wikipedia bloqueados; GitHub sí funciona. El presupuesto de WebSearch es compartido y limitado.

**Conclusiones de la investigación** (cifras de terceros o de prensa salvo indicación; detalle y fuentes en `research/`):
- Mercado de "ganador casi único": en 12 meses a jun-2026 los creadores cobraron ~1.700 M$ por DevEx; mediana ~1.500 $/año; top 10 ~65,7 M$ de media; top 1.000 ≈ 82 % del total. Hacer muchos juegos con IA abarata el boleto, no mejora la probabilidad.
- Los virales caen un 90-99 % desde su pico en semanas o meses; la ventana de fast follower es de 4-6 semanas. Roblox atribuye su baja de bookings a menor monetización por hora; guía T3-2026 de -14 % a -18 % (resultados el 29-oct).
- El algoritmo ("Recommended For You", desde jun-2026) mide retención a 28 días, gasto recurrente y co-juego, no el clic.
- Reglas que condicionan el diseño: odds visibles para objetos aleatorios de pago, sin resultados sin valor y con control por PolicyService; juegos nuevos llegan por defecto a 16+ verificados y para Kids/Select hay que cumplir requisitos; tope de 5 juegos nuevos por día y los casi idénticos no se priorizan; prohibido el feed con recompensa por seguir mirando; casinos y apuestas prohibidos.
- Benchmarks (GameAnalytics 2026, muestra de supervivientes): mediana D1 10,3 % / D7 1,6 % / D30 0,5 %.

**Decisiones tomadas.**
- Herramientas: Claude Code + Rojo + MCP integrado de Studio; Luau `--!strict`; ProfileStore para datos; un único `ProcessReceipt` idempotente; todo server-authoritative.
- Primer juego: Fish & Fortune (concepto 1 de `research/07`). Candidatos siguientes: Rumble Rotation y Plot Defenders.
- Juegos vs ropa (`research/08`, confianza ~65 %): juegos como motor (~75-80 % del tiempo y dinero); ítems de avatar solo como línea secundaria por etapas (tienda de ítems propios dentro de los juegos, luego piloto de 20-30 ítems 3D); evitar ropa clásica 2D en el Marketplace.
- Monetización honesta: odds visibles, sin urgencia ni descuentos falsos, sin presión de compra a menores.

**Pendiente / dudas abiertas.** Preguntas para Aryan en `ROBLOX/docs/preguntas-para-aryan.md` (país y si DevEx está disponible, edad, ID verificada, Plus/Premium, presupuesto, PC con Studio, redes). Sin verificar: tarifa DevEx por país, política de música/IA para UGC, detalles de Paid Random Items por región, Planning Mode del Assistant, `ProcessReceipt` frente a `BindReceiptHandler`. Falta crear `rokit.toml` con versiones fijas, el README de Fish & Fortune, una revisión independiente del código de compras y datos, y mover `research/`, `tools/` y `marketing/` a `ROBLOX/`.
