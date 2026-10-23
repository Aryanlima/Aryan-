# A. Informe de investigación

**Fecha de consulta: 23 oct. 2026.** “Confirmado” significa que lo respalda la fuente citada; no implica que las reglas internas, probabilidades o cifras no publicadas por el juego se hayan podido comprobar. Los detalles de Archero 2 provienen en parte de una wiki comunitaria, así que los marco como tales.

## Archero y Archero 2

- **Confirmado — fórmula general de Archero:** la ficha oficial describe partidas de acción roguelike, habilidades aleatorias durante la partida, enemigos y obstáculos, mundos distintos, reinicio al morir y equipo que mejora estadísticas. No especifica en su texto cómo dispara el personaje. [Ficha de Archero en App Store](https://apps.apple.com/us/app/archero/id1453651052?platform=ipad)
- **Confirmado — movimiento y disparo de Archero:** la mecánica popular de moverse para esquivar y disparar automáticamente al quedarse quieto se ve en material de juego y es comúnmente documentada, pero la ficha oficial consultada no la explica. **No verificado aquí con una fuente primaria textual**; usarlo como referencia de diseño, no como especificación oficial.
- **Confirmado — Archero 2 amplía la fórmula:** Habby anuncia habilidades con rarezas y más oportunidades de elección, combate más rápido, desafíos de etapas, supervivencia con cuenta atrás, batallas contra jefes, torre de pruebas, mina de oro y PvP al mejor de tres. [Ficha de Archero 2 en App Store](https://apps.apple.com/gb/app/archero-2/id6502820653)
- **No verificado de forma exhaustiva — capítulos, salas y jefes:** la ficha de Archero 2 no fija una estructura única de salas por capítulo. Guías comunitarias describen modos de salas, etapas clásicas, supervivencia cronometrada y encuentros de jefe; la estructura varía por modo y versión. No asumir un número universal de salas. [Wiki comunitaria de habilidades](https://archero-2.game-vault.net/wiki/Skills)
- **Confirmado en guía comunitaria, no por Habby — encuentros Angel/Devil:** la wiki dice que el Devil suele aparecer tras derrotar un jefe sin recibir daño, y que el Angel aparece en ciertos finales de etapa o intervalos de los modos cronometrados. Las condiciones y recompensas pueden cambiar entre versiones; no copiar sus porcentajes o valores como si fueran oficiales. [Wiki comunitaria](https://archero-2.game-vault.net/wiki/Skills)
- **No verificado como lista completa — patrones de enemigos:** las páginas oficiales consultadas no publican un catálogo de patrones. Para el prototipo, conviene diseñar patrones legibles y nuevos: persecución, carga telegrafiada, abanico de proyectiles, zona persistente, invocación y secuencia de jefe. Son propuestas originales, no una lista atribuida a Archero.
- **Confirmado — equipo y progresión:** las fichas oficiales mencionan equipo y aumento de estadísticas; Archero 2 además tiene modos y sistemas activos que la ficha enumera. **No verificado como inventario íntegro:** rarezas concretas, forja, talentos, mascotas y runas, así como la forma exacta de desbloquearlas. La tienda de aplicaciones muestra compras y cajas, pero no prueba las tasas ni toda la economía interna. [Archero](https://apps.apple.com/us/app/archero/id1453651052?platform=ipad) · [Archero 2](https://apps.apple.com/gb/app/archero-2/id6502820653)
- **No verificado — energía y cifras:** no afirmo coste de energía, regeneración, límites, premios diarios, tasas de cofres, precios ni cantidades de recursos: varían por versión/región y no están establecidos en las páginas citadas.
- **Confirmado — monetización de las fichas:** ambas fichas indican compras dentro de la app; la de Archero 2 marca cajas de recompensa y publicidad. Archero describe una suscripción con beneficios diarios en la ficha estadounidense. Es evidencia de esas ofertas listadas, no de su disponibilidad actual para cada cuenta. [Archero 2](https://apps.apple.com/gb/app/archero-2/id6502820653) · [Archero](https://apps.apple.com/us/app/archero/id1453651052?platform=ipad)
- **Inferencia de diseño — satisfacción:** la combinación de elecciones aleatorias, amenaza que obliga a moverse, mejora visible de la build y feedback rápido puede hacer cada partida legible y distinta. Daño flotante, sacudida, botín y sonido son recomendaciones de diseño; no los presento como datos medidos del juego.

## Adaptación a Roblox

- **Móvil:** joystick virtual izquierdo para moverse, autoataque al estar quieto, objetivos sugeridos por el servidor y botones grandes de habilidad/esquiva. En PC, WASD y controles equivalentes. Añadir opción de cambiar autoapuntado, vibración/sacudida y tamaño de interfaz.
- **Autoridad:** el cliente manda intención de movimiento/entrada; servidor valida estado, cadencia, alcance, objetivo y daño. El cliente puede dibujar efectos predictivos, pero no conceder impactos, recompensas ni progreso. Roblox recomienda validar cada dato entrante y limitar llamadas; su modelo de autoridad de servidor usa predicción y reconciliación, sujeto a requisitos técnicos y estado de disponibilidad. [Límite cliente-servidor](https://create.roblox.com/docs/scripting/security/client-server-boundary) · [Autoridad de servidor](https://create.roblox.com/docs/projects/server-authority)
- **Rendimiento móvil:** proyectiles visuales ligeros y agrupados, límites por sala, pooling, efectos breves, poca física, colisiones simples y pruebas en dispositivo modesto. Son decisiones recomendadas; el límite adecuado se debe medir en el juego.
- **Cooperativo:** ofrecer partidas privadas/amistosas con dificultad escalada por jugadores, patrones que no cubran toda la arena y revivir limitado o cooperativo. Mantener daño y recompensas calculados por servidor. Propuesta de diseño, no afirmación sobre Archero.
- **Política Roblox:** cofres, ruedas y azar pagado directa o indirectamente con Robux tienen que revelar resultados posibles y probabilidades numéricas; PolicyService debe aplicar restricciones por jugador/región. Para el MVP: nada de cajas pagadas ni moneda comprable que alimente azar; vender cosméticos de precio conocido es una alternativa más sencilla. [Política de objetos aleatorios pagados](https://create.roblox.com/docs/production/monetization/paid-random-items)
- **Juegos comparables en Roblox:** **QUIVER** se describe en su página oficial como juego de runs de mazmorra, solo o hasta 4, arcos/accesorios y mejoras, compatible con móvil/consola/PC; declara inspiración en Hades y Archero y estado Alpha. **Éxito no verificado:** la página abierta no ofreció métricas de visitas, jugadores concurrentes ni retención; no inferir rendimiento a partir de su descripción. [QUIVER en Roblox](https://www.roblox.com/games/140180624486189/QUIVER)

# B. Prompt único para Claude Code

```text
Actúa como diseñador y desarrollador Roblox senior para Aryan, que no programa. Crea un juego ORIGINAL de acción roguelite de arquería para Roblox, inspirado solo en mecánicas generales del género. No uses nombres, personajes, mundo, textos, diseños, modelos, iconos, audio ni código de Archero/Archero 2. No afirmes datos de referencia no verificados como hechos. Antes de diseñar sistemas, lee CLAUDE.md, AGENTS.md y la tarea autorizada existente en ROBLOX/docs/ai-tasks; respeta alcance y rama de trabajo. No toques archivos fuera de la tarea.

VISIÓN
Nombre provisional: “Brumaflecha: Asedio de los Faros”. Héroe: Nara, exploradora original que restaura faros vivos en un archipiélago cubierto de niebla. Mundo de islas-jardín y ruinas marinas, siluetas redondas y lectura clara desde arriba. Arte de juguete pintado de alta calidad: coral, turquesa, jade, amarillo cálido, violeta y azul noche; materiales mate, bordes suaves, detalles grandes y acabado de icono móvil. Nada de copiar marcas o IP de terceros.

MVP
Un capítulo con salas cortas conectadas; unos 6 enemigos normales y 2 jefes originales; unas 20 habilidades elegibles; 1 héroe; 3 armas distintas; una recompensa final y regreso al hub. Números de daño, tiempos, oleadas y límites se deciden tras prototipo y se calibran, no se inventan como cifras de referencia. No añadir progresión de héroes/equipo/forja/mascotas/runas/pase/cofres hasta que el bucle MVP sea divertido y medido.

REGLAS DE TRABAJO
1. Modo Plan primero. Antes de editar, presenta un plan y responde por defecto al menos 20 preguntas de diseño (controles, cámara, arena, autoataque, objetivos, telegráficos, colisiones, habilidades, acumulación, muerte, cooperativo, recompensas, persistencia, UI, audio, arte, límites móviles, remotos, pruebas, criterios). Explicita supuestos y riesgos; consulta a Aryan solo por decisiones bloqueantes. Claude decide/revisa; Codex recibe tareas acotadas; agentes baratos reciben subtareas independientes con archivos y resultado esperado. No delegues decisiones globales.
2. Pruebas dirigidas antes del código: escribe primero casos comprobables para daño, selección de objetivo, una habilidad y jefe. No ejecutes ni añadas pruebas no solicitadas por la autorización/repositorio. Usa Lune si la tarea autorizada lo permite. No declares pruebas pasadas sin ejecutarlas.
3. Luau --!strict; servidor autoritativo para estados, proyectiles lógicos, golpes, daño, drops y recompensas. Cliente solo manda inputs validados y presenta efectos/UI. Valida tipos, estado vivo, distancia, cadencia, valores finitos y límites; rate-limit remotos. No confiar en posiciones/objetivos/daño reportados por cliente. Mantén el único ProcessReceipt existente si hay compras; nunca crees otro.
4. Marca REVIEW(money) en todo cambio que afecte Robux, dinero, monedas o datos/progresión persistente. No secretos, IDs inventados, APIs inventadas, publicación ni gasto de Robux.
5. Controles: joystick móvil mueve; quedarse quieto habilita autoataque al objetivo válido más cercano, con indicador visual; PC teclado y gamepad funcionales. Cámara alta en tres cuartos, siempre deja héroe, amenazas y telegráficos visibles. UI con safe areas, escala adaptable y navegación táctil.
6. Sin azar pagado, moneda comprable ligada a azar, falsa urgencia, temporizadores coercitivos o ventaja pagada. Prototipo sin monetización. Si luego se propone azar pagado, bloquearlo hasta revisar política actual de Roblox y cumplimiento de PolicyService/odds; preferir compras cosméticas directas de precio transparente.
7. Enemigos telegráficos, distintos y esquivables; no spam de proyectiles. Coop solo después de validar solo, con daño/recompensas resueltos por servidor y patrones legibles para cada jugador. Optimiza para móvil: pooling, límites de entidades/efectos, poca física, colisiones sencillas y perfilado en dispositivo real.
8. Feedback: golpe con pausa visual breve, destello/material, número de daño legible, sonido original y shake moderado configurable; recompensa clara al terminar. Nunca ocultar patrones con efectos.

ARTE CON ROPILOT PARA TODO EL ARTE
Usa Ropilot para generar/revisar cada modelo, icono/imagen y recurso visual del juego; no placeholders de bloques cuadrados. Si la herramienta no está conectada, documenta el bloqueo y prepara prompts, sin sustituirlo por arte final manual. Modelos redondeados, proporciones comprobables, colores saturados, silueta reconocible a tamaño pequeño y acabado de icono. Usa solo assets autorizados/originales.
Para cada asset: prompt con vista superior/3-4, escala Roblox, pivote/origen, dimensiones, colisiones, materiales, paleta, referencias internas originales, variantes de LOD si hacen falta. Inspecciona en Studio sobre suelo y junto al héroe antes de aceptar.
Checklist anti-errores: (a) piezas asentadas sobre suelo con raycast/offset revisado; nada flotando; (b) relieve por malla/terreno continuo, nunca esferas pegadas como topografía; (c) agua con fondo visible y límite/costa legible; (d) árboles de escala medida frente a héroe y cámara; (e) encuadre de cámara probado con paredes, esquinas y jefes, nada tapa jugador/amenazas; (f) UI probada en móvil pequeño, móvil grande, escritorio y gamepad con safe areas, sin solapes ni texto cortado. Rechaza y regenera modelos que fallen.

ORDEN DE CONSTRUCCIÓN Y “TERMINADO”
Fase 0 — auditoría/plan: confirmar estructura Rojo, instrucciones, tarea autorizada, herramientas y pruebas permitidas. Terminado cuando plan, 20+ respuestas por defecto, archivos autorizados y casos dirigidos quedan escritos y Claude los revisa.
Fase 1 — prototipo de arena/cámara/movimiento: terminar cuando móvil, teclado y gamepad mueven con respuesta; cámara no se tapa y arena/costa se leen en las 3 resoluciones objetivo indicadas en plan.
Fase 2 — combate básico: terminar cuando quietud dispara, movimiento pausa disparo, objetivo válido seleccionado de forma determinista, cada impacto y cooldown se deciden en servidor y la prueba dirigida pasa.
Fase 3 — seis enemigos: asigna patrón único y telegráfico a cada uno; terminar cuando cada patrón puede esquivarse sin daño en escenario controlado y no hay entidades huérfanas tras limpiar sala.
Fase 4 — habilidades (~20): definir tabla tipada y combinaciones; terminar cuando cada opción tiene descripción, efecto real servidor, icono original, sin duplicados incompatibles y prueba de selección/acumulación.
Fase 5 — dos jefes: telegráficos, fases y ventanas de daño originales; terminar cuando cada ataque se esquiva con controles táctiles y de teclado, y el servidor resuelve vida/muerte una sola vez.
Fase 6 — sala/capítulo/recompensa: terminar cuando una partida completa funciona, termina y reinicia sin duplicar recompensa; sin softlock en muerte/reconexión.
Fase 7 — arte/UI/audio final con Ropilot: terminar solo tras checklist visual anti-errores completo y revisión de legibilidad en dispositivo móvil.
Fase 8 — perfilado y revisión: terminar cuando escenario de estrés definido en plan no presenta errores, fuga/entidades persistentes ni regresiones visibles; registrar dispositivo, carga y resultado. No prometer FPS sin medir.
Claude puede asignar una fase a Codex como tarea documentada, acotada y revisable; agentes económicos reciben únicamente inventario, revisión read-only o asset individual. Claude integra y revisa todo diff.

PLAN DE PRUEBAS PEQUEÑO Y DIRIGIDO
1) Prueba Lune de cálculo puro: daño, enfriamiento y límites de valores inválidos.
2) Prueba de combate en servidor: quieto dispara al objetivo legal; movimiento suspende; cliente no puede elegir daño/objetivo ni acelerar cadencia.
3) Prueba de habilidad: tres opciones válidas, elegir una, aplicar una vez, persistir solo lo diseñado.
4) Prueba de jefe/sala: esquiva de telegráfico, muerte/recompensa única, reinicio completo.
5) Revisión manual en Studio en móvil/táctil y escritorio; añadir gamepad si está en el alcance.
Ejecuta únicamente las verificaciones autorizadas por la tarea y las instrucciones del repo. Informa comandos exactos, resultado y pruebas omitidas.

ENTREGA A ARYAN
Explica en español sencillo qué se construyó, cómo jugarlo, qué falta y riesgos/dudas. Mantén cambios acotados y revisables; sin prometer calidad, economía o métricas no verificadas.
```

### Fuentes de Roblox consultadas

La guía oficial de autoridad de servidor detalla validación, predicción y reconciliación; las reglas de elementos aleatorios pagados exigen probabilidades y restricciones por jugador. [Server authority](https://create.roblox.com/docs/projects/server-authority) · [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)