# Informe de arte generado con IA (Fish & Fortune)

Lo rellena la sesión del PC (runbook: [`arte-con-ia-en-studio.md`](arte-con-ia-en-studio.md); mensaje: [`prompt-pc-arte-ia.md`](prompt-pc-arte-ia.md)). Estado al crear el archivo (2026-10-20): **nada generado todavía**. La sesión de la nube no tiene acceso a generate_mesh; el juego usa el arte procedural hasta que haya plantillas válidas en `ServerStorage/Art`.

Estados: `pendiente` · `aceptado` · `rechazado` (tras 3 intentos o por criterio duro) · `bloqueado` (falta algo, ver notas).

## 1. Datos de la sesión
| Campo | Valor |
|---|---|
| Fecha y hora de la versión guardada del lugar (antes de empezar) | |
| Lugar de pruebas (nombre, sin IDs sensibles) | |
| Parámetros reales de `generate_mesh` | |
| Parámetros reales de `generate_material` | |
| Dónde inserta el resultado `generate_mesh` | |
| ¿El `MeshId` generado es `rbxassetid://...`? | |
| ¿Avisos de cobro o de límite? (si hubo cobro: parar) | |
| Menú exacto de Studio para guardar `.rbxm` | |

## 2. Cupo usado por día
| Día | Fecha | Llamadas de malla (máx. 12) | Llamadas de material (máx. 8) | Incidencias |
|---|---|---:|---:|---|
| 1 | | 0 | 0 | |
| 2 | | 0 | 0 | |
| 3 | | 0 | 0 | |
| 4 | | 0 | 0 | |

## 3. Piezas
Columnas: pieza (`categoría/id`) · lote · prompt final (si es el del manifiesto, escribir `manifiesto`; si fue un reintento, `reintento 1/2` o el texto exacto si se cambió) · estado · intentos · `MeshId`(s) · triángulos medidos / presupuesto · notas (motivo del rechazo, rotación o `offset` sugeridos, parecidos de IP, desfase de la cubierta del muelle…).

| Pieza | Lote | Prompt final | Estado | Intentos | MeshId(s) | Triángulos / máx. | Notas |
|---|---|---|---|---:|---|---|---|
| `creatures/lake_spirit` | lote-1 | manifiesto: `prompt` | pendiente | 0 | - | - / 8000 | |
| `creatures/river_queen` | lote-1 | manifiesto: `prompt` | pendiente | 0 | - | - / 8000 | |
| `creatures/tide_leviathan` | lote-1 | manifiesto: `prompt` | pendiente | 0 | - | - / 8000 | |
| `props/pier` | lote-1 | manifiesto: `prompt` | pendiente | 0 | - | - / 8000 | |
| `props/lantern` | lote-1 | manifiesto: `prompt` | pendiente | 0 | - | - / 1500 | |
| `props/rowboat` | lote-1 | manifiesto: `prompt` | pendiente | 0 | - | - / 3000 | |
| `creatures/moon_koi` | lote-2 | manifiesto: `prompt` | pendiente | 0 | - | - / 4000 | |
| `creatures/ancient_carp` | lote-2 | manifiesto: `prompt` | pendiente | 0 | - | - / 6000 | |
| `creatures/crystal_pike` | lote-2 | manifiesto: `prompt` | pendiente | 0 | - | - / 4000 | |
| `creatures/manta` | lote-2 | manifiesto: `prompt` | pendiente | 0 | - | - / 4000 | |
| `creatures/golden_trout` | lote-2 | manifiesto: `prompt` | pendiente | 0 | - | - / 3000 | |
| `creatures/bluegill` | lote-2 | manifiesto: `prompt` | pendiente | 0 | - | - / 2000 | |
| `creatures/minnow` | lote-3 | manifiesto: `prompt` | pendiente | 0 | - | - / 1500 | |
| `rods/driftwood` | lote-3 | manifiesto: `prompt` | pendiente | 0 | - | - / 1500 | |
| `rods/reed` | lote-3 | manifiesto: `prompt` | pendiente | 0 | - | - / 1500 | |
| `rods/fiberglass` | lote-3 | manifiesto: `prompt` | pendiente | 0 | - | - / 2000 | |
| `rods/carbon` | lote-3 | manifiesto: `prompt` | pendiente | 0 | - | - / 2500 | |
| `rods/golden` | lote-3 | manifiesto: `prompt` | pendiente | 0 | - | - / 3500 | |
| `props/pine_tree` | lote-4 | manifiesto: `prompt` | pendiente | 0 | - | - / 1500 | |
| `props/palm_tree` | lote-4 | manifiesto: `prompt` | pendiente | 0 | - | - / 2000 | |
| `materials/ground_lake` | lote-4 | manifiesto: `prompt` | pendiente | 0 | - | - / - | |
| `materials/ground_river` | lote-4 | manifiesto: `prompt` | pendiente | 0 | - | - / - | |
| `materials/ground_coast` | lote-4 | manifiesto: `prompt` | pendiente | 0 | - | - / - | |
| `materials/pier_wood` | lote-4 | manifiesto: `prompt` | pendiente | 0 | - | - / - | |

## 4. Ajustes que debe aplicar la nube
| Pieza | Ajuste (`rotation` en grados, `offset` en studs, tamaño…) | Motivo |
|---|---|---|
| | | |

## 5. Clases rechazadas por la lista blanca que parecen legítimas
| Pieza | Clase | Por qué parece legítima |
|---|---|---|
| | | |

## 6. Estado de la persistencia
| Pieza aceptada | `.rbxm` guardado en `art/models/...` | Lugar guardado desde Studio |
|---|---|---|
| | | |
