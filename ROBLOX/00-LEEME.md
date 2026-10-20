# ROBLOX: juegos con microtransacciones e IA (índice del proyecto)

> **Aviso (una sola vez):** esto es investigación y planificación, no asesoría legal ni fiscal. Para impuestos, contratos y responsabilidad legal consulta a un profesional de tu país.

Para: Aryan. Estado a 2026-10-20. Varios agentes siguen trabajando en paralelo: si algo de la tabla de carpetas no coincide con lo que ves, manda lo que ves (usa `ls`).

## 1. En una frase

Un experimento de 90 días para crear pocos juegos de Roblox bien hechos con ayuda de IA, empezando por **Fish & Fortune**, con puertas de parada y sin esperar milagros: la mediana de los creadores que cobran es de ~1.500 USD al año y los juegos virales caen entre 90 y 99 % ([informe maestro §2](docs/informe-maestro.md)).

**Lo único urgente:** presentar el formulario fiscal **W-8BEN antes del 31-oct-2026** (mejor antes del miércoles 28) en Creator Hub > Finances > Taxes. Detalle en [plan-90-dias.md](docs/plan-90-dias.md), semana 0.

## 2. Por dónde empezar a leer (orden recomendado)

| Paso | Qué leer | Tiempo | Para qué |
|---:|---|---|---|
| 1 | Este archivo | 5 min | Saber qué hay |
| 2 | [docs/informe-maestro.md](docs/informe-maestro.md), sección 1 (veredicto) y sección 2 (números) | 10 min | Entender qué esperar de verdad |
| 3 | [docs/preguntas-para-aryan.md](docs/preguntas-para-aryan.md) | 15 min | Responder lo que solo tú sabes (empieza por las 4 urgentes: 1, 2, 3 y 4, y la 7) |
| 4 | [docs/plan-90-dias.md](docs/plan-90-dias.md), semana 0 y calendario | 20 min | Saber qué hacer esta semana |
| 5 | [docs/informe-maestro.md](docs/informe-maestro.md) completo | 30 min | Decisiones, riesgos, hechos verificados vs dudas, juegos vs ropa |
| 6 | [docs/setup-en-tu-pc.md](docs/setup-en-tu-pc.md) | 60 a 90 min | Montar Studio y Claude Code en tu PC (lo escribió otro agente; no se probó en Windows ni macOS) |
| 7 | Informes de `research/`, en este orden: [07 diseño y conceptos](research/07-diseno-crecimiento-y-conceptos.md), [02 dinero](research/02-monetizacion-y-economia.md), [03 políticas](research/03-politicas-y-cumplimiento.md), [08 ropa vs juegos](research/08-ropa-vs-juegos.md), [01 mercado](research/01-mejores-juegos.md) | 2 a 3 h | Entender de dónde sale cada dato |
| 8 | Informes técnicos: [04 IA en Studio](research/04-ia-studio-mcp-skills.md), [05 IA para assets y marketing](research/05-ia-assets-y-marketing.md), [06 stack técnico](research/06-stack-tecnico.md) | Cuando haga falta | Detalle de herramientas y arquitectura |

Cada informe es muy largo (decenas de páginas): no hace falta leerlos enteros. Los documentos de `docs/` ya resumen y enlazan cada dato a su informe.

## 3. Qué hay en cada carpeta

Estado tomado a las ~14:40 UTC del 2026-10-20. "Se moverá" significa que otro agente está trasladando el contenido a `ROBLOX/`.

| Carpeta | Qué contiene | Estado hoy |
|---|---|---|
| `research/` | Informes 01 a 08: mejores juegos, monetización y economía, políticas, IA en Studio, IA para assets y marketing, stack técnico, diseño y conceptos, ropa vs juegos | Hechos. **El 09 (producir ropa con IA) estaba pendiente al escribir esto.** Hoy viven en `research/` en la raíz del repositorio y se moverán a `ROBLOX/research/` |
| `docs/` | Documentos de decisión: `informe-maestro.md`, `plan-90-dias.md`, `preguntas-para-aryan.md`. Además `setup-en-tu-pc.md` y `skills-instaladas.md` (otros agentes). `entorno-y-toolchain.md` está en `docs/` de la raíz del repositorio y se moverá | Los tres de decisión, hechos. Los otros, de otros agentes |
| `packages/` | Código Luau compartido ("el kit"): `Data` (datos por jugador), `Net` (remotos validados), `Economy` (monedas, boosts, offline), `Odds` (tabla de probabilidades para cumplir con objetos aleatorios de pago), y `Shop` (tienda y compras) si ya estaba al abrir | **En construcción.** Faltan, según [06 §4.2](research/06-stack-tecnico.md): `Policy`, `Analytics`, `LiveConfig`, `UIKit` |
| `games/` | Los juegos. El primero será `fish-and-fortune` | **Aún no existe en `ROBLOX/`** al escribir esto; lo construye otro agente |
| `tests/` | Pruebas del kit en Lune (`*.spec.luau`) | Hechas para los paquetes presentes |
| `tools/` | `clothing-gen/` (generador de ropa en Python con plantillas oficiales; en construcción), y, en la raíz del repositorio hasta que se muevan: `testkit/` (ejecutor de pruebas y simulaciones de servicios de Roblox), `examples/` (ejemplo de `ProcessReceipt`), `setup.sh`, `test.sh`, `lint.sh`, `format.sh` | En construcción; el `testkit` funciona |
| `scripts/` | `typecheck.mjs` (comprobación de tipos Luau sin Studio) y `roblox-lite.d.luau` (definiciones mínimas de Roblox) | Funcionan con limitaciones: ver el encabezado del script |
| `marketing/` | Generador de vídeos promocionales a partir de un archivo de datos (`pipeline/`: JSON, HTML/Canvas, Playwright y ffmpeg) y materiales de Fish & Fortune | **En construcción.** Hoy `marketing/pipeline` puede estar todavía en la raíz del repositorio |
| `skills/` | Skill `roblox-dev` (conocimiento verificado de Roblox y Luau para Claude) | Instalada y revisada: ver [docs/skills-instaladas.md](docs/skills-instaladas.md) |
| `.toolchain/` | Herramientas instaladas localmente (ignorada por git) | Se regenera con `tools/setup.sh` |

Reglas del repositorio (resumen de `CLAUDE.md`): todo lo de Roblox vive bajo `ROBLOX/`; idioma español (el código y los identificadores, en inglés); no se instalan binarios fuera de `ROBLOX/.toolchain/`; los datos de investigación llevan etiqueta [OFICIAL], [TERCERO] o [NO VERIFICADO].

## 4. Cómo correr y probar (hoy)

Estos comandos funcionan en el entorno de nube donde se construyó el proyecto (Linux). En tu PC primero hay que montar el toolchain: [docs/setup-en-tu-pc.md](docs/setup-en-tu-pc.md).

| Qué | Comando (desde la raíz del repositorio) | Qué comprueba |
|---|---|---|
| Todas las pruebas | `tools/test.sh` | Ejecuta cada `*.spec.luau` con Lune. Al escribir esto: **7 especificaciones, 169 pruebas, 0 fallos** |
| Una sola prueba | `lune run ROBLOX/tests/Odds.spec.luau` | Lo mismo para un archivo |
| Filtrar por nombre | `tools/test.sh -t "ProcessReceipt"` | Solo pruebas cuyo nombre contiene ese texto |
| Linter y formato | `tools/lint.sh` y `tools/format.sh --check` | selene, stylua y tipos. Al escribir esto: selene 0 errores y 5 avisos; stylua pedía reformatear algunos archivos (`tools/format.sh` lo arregla) |
| Tipos sin Studio | `node ROBLOX/scripts/typecheck.mjs ROBLOX/packages` | Comprobación `--!strict` de los paquetes. Al escribir esto: 4 archivos, 0 errores |
| Vídeos promocionales | `cd marketing/pipeline && npm run render` | **Aún no disponible**: faltaba el comando de render al escribir esto |
| Ejecutar los juegos | Abrir el proyecto en Roblox Studio con Rojo o Script Sync | Ver [docs/setup-en-tu-pc.md](docs/setup-en-tu-pc.md). **Nunca probado por nosotros** |

Las pruebas usan Lune y simulaciones (mocks) de los servicios de Roblox: demuestran que la lógica es correcta, no que funcione dentro de Studio.

## 5. Estado actual, honesto

### Hecho y comprobado

- 8 informes de investigación con etiquetas de fiabilidad y fuentes (01 a 08).
- 3 documentos de decisión en `docs/` ([informe maestro](docs/informe-maestro.md), [plan de 90 días](docs/plan-90-dias.md), [preguntas para Aryan](docs/preguntas-para-aryan.md)) que resumen, deciden y enlazan cada dato a su informe.
- Un toolchain local sin Studio (Lune, StyLua, selene, Rojo) y 169 pruebas en verde (al escribir esto).

### Hecho, pero SIN probar en Roblox

- Todo el código Luau (`packages/`, ejemplos, juego). Se probó con Lune y simulaciones, **no** en Studio.
- El módulo `Data` es una **implementación propia**; el propio módulo recomienda sustituirla por ProfileStore para un juego real con tráfico ([06 §2](research/06-stack-tecnico.md)).
- Todo lo que toque dinero (`Shop`, `Economy`, recibos) lleva la marca `REVIEW(money)`: necesita revisión humana y pruebas con jugadores de prueba antes de publicar.

### No se pudo verificar

- El texto real de las páginas de Creator Hub y DevForum (bloqueadas desde la nube): lo oficial se leyó en el repositorio `Roblox/creator-docs`, y lo demás son resúmenes de buscador ([informe maestro §6](docs/informe-maestro.md)).
- Si DevEx está disponible en tu país, la lista de países, y la tasa fiscal que te toca.
- Los Términos de Uso que entran el 1-nov-2026.
- Costes reales de anuncios en Ads Manager, y todas las cifras de ingresos de juegos concretos (son estimaciones de terceros).
- Si el código funciona en Studio, en móviles reales y bajo carga.

### Requiere a Aryan (nadie más puede hacerlo)

1. Responder las preguntas de [preguntas-para-aryan.md](docs/preguntas-para-aryan.md).
2. **W-8BEN antes del 31-oct**, cuenta con 2FA y verificación de edad o identidad, método de cobro, y decidir Plus o tarifa de publicación.
3. Instalar Studio (Windows o Mac), activar el MCP y crear el universo de pruebas y las claves de Open Cloud.
4. Probar en un móvil real, grabar gameplay, publicar a producción, publicar clips y pagar anuncios.
5. Fijar tu tope de pérdida (dinero y horas).

## 6. Dónde mirar si algo falla

| Problema | Dónde |
|---|---|
| Una cifra o regla parece contradictoria | [Informe maestro §6](docs/informe-maestro.md) (hechos verificados vs dudas): dice qué informe manda |
| No sé qué hacer esta semana | [Plan de 90 días](docs/plan-90-dias.md), semana 0 |
| Algo del toolchain no arranca | `docs/entorno-y-toolchain.md` y `tools/setup.sh --check` |
| Preguntas sobre ropa | [Informe maestro §9](docs/informe-maestro.md) y [08](research/08-ropa-vs-juegos.md) |
