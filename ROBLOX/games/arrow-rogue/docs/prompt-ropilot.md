# Prompt para Ropilot

Eres el director técnico de arte de **Brumaflecha: Asedio de los Faros**, un roguelite original de arquería para Roblox, móvil primero y con cámara alta en tres cuartos. Crea y prepara los assets que se piden abajo, en lotes ordenados por prioridad para reducir llamadas. Usa las herramientas disponibles de Blender, Studio, texturas, VFX, rigs y capturas. **No escribas código de gameplay ni inventes APIs o IDs de assets.** No subas imágenes a Roblox: déjalas listas para revisión local.

## Biblia visual común

- **Paleta mate, saturada:** coral `#FF6F59`, turquesa `#2EC4B6`, jade `#3DA35D`, amarillo cálido `#FFC857`, violeta `#7B5EA7`, azul noche `#1B2A41`; niebla y piedra en tonos claros neutros, sin bajar el contraste de las señales de peligro.
- **Forma:** siluetas redondeadas, bordes suaves y detalles grandes; evita bloques cuadrados, ruido fino y acumulaciones de esferas pegadas. Relieve con malla o terreno continuo.
- **Acabado:** juguete pintado de alta calidad; para iconos, contorno grueso y lectura clara en tamaño pequeño.
- **Escalas del diseño:** Nara mide 5 studs; enemigos, 3–6; jefes, 14–18; árboles, como máximo unas 3 veces la altura de Nara; módulos de suelo, 8×8 studs. Conserva las dimensiones de sala indicadas más adelante.
- Mantén una silueta y codificación de color distintas para cada personaje, arma y patrón de ataque. Las zonas de peligro deben contrastar con el suelo y seguir visibles bajo efectos y niebla.
- Para cada asset especifica dimensiones en studs, orientación, pivote en la base cuando corresponda, materiales, colisión tipo Box y LOD si hace falta. En modelos, une piezas estáticas por material y usa una malla por parte móvil. Mantén cada malla por debajo del límite de triángulos de importación de Roblox; verifica el recuento real antes de entregar, sin asumir ni inventar un límite numérico.

## Lote 1 — Nara y sus animaciones

Crea a **Nara**, exploradora original, como modelo compatible con el rig R15 de Ropilot: proporciones legibles desde una cámara alta en tres cuartos, rostro y vestuario originales, arco y accesorios separados y reconocibles. Usa la paleta común con acentos coral y turquesa. Escala total: 5 studs.

Entrega el modelo y los accesorios como colección/Model de Nara en `Workspace.Extras`, con piezas móviles separadas según corresponda. Crea con `ropilot_blender_import_rig` el rig compatible y prepara las animaciones **correr, quieto, disparar, recibir golpe, morir y celebrar**. Importa las animaciones con el flujo de Ropilot para rigs R15; no inventes IDs. No publiques ni subas assets.

Comprueba en Studio que el rig importa, que las articulaciones no se deforman y que el arco no atraviesa manos o torso al disparar. Mira la silueta desde arriba y tres cuartos, junto a una referencia de 5 studs. Rechaza formas cuadradas, accesorios flotantes y pivotes fuera de la base o del centro funcional de cada pieza.

## Lote 2 — Seis enemigos y dos jefes

Crea ocho modelos originales en `Workspace.Extras`, cada uno con silueta y color propios, dimensiones en el rango de 3–6 studs para enemigos normales y 14–18 para jefes. Inspírate en estos conceptos del GDD, sin recurrir a referencias de franquicias existentes:

- **Muelle:** cangrejo-farol.
- **Embestida:** jabalí de coral.
- **Abanico:** planta espinosa fija.
- **Charca:** medusa de niebla flotante.
- **Eco:** espíritu gemelo.
- **Invocador:** monje de faro.
- **Guardián de Roca Hueca:** jefe de roca hueca.
- **Reina del Faro Apagado:** jefa faro viviente.

Prepara para cada uno las animaciones de **aviso/telegráfico, ataque y muerte**. Los avisos deben corresponder a los patrones del GDD y leerse claramente en una vista de juego alta; reserva el telegráfico dibujado en el suelo para VFX del lote 5. Mantén las partes móviles en mallas separadas, pivotes bien ubicados y colisiones Box. Para los jefes, diferencia claramente fases y ataques mediante postura, color o accesorios móviles sin tapar su señal de peligro.

Comprueba cada modelo sobre el suelo y junto a Nara para validar escala, base, pivotes y lectura de silueta. Rechaza duplicados indistinguibles, piezas que flotan y gestos de aviso que el efecto de ataque oculte.

## Lote 3 — Kit modular de arena y biomas

Crea un kit modular para tres biomas coherentes dentro de **Archipiélago de la Niebla**: costa de faros, ruinas de coral y bosque isleño brumoso. Entrega colecciones separadas por bioma en `Workspace.Extras`. Cada módulo debe indicar dimensiones y escala en studs, tener pivote centrado en la base, encajar con la cuadrícula y usar colisión Box.

Incluye **suelo, muros, pilares, puerta, obstáculos y decoración de borde**. Usa suelo modular de 8×8 studs; prepara piezas para salas de combate de 64×64, sala de jefe de 96×96 y puerta de 16 studs. No conviertas las dimensiones en bloques sin detalle: redondea bordes y añade formas grandes, legibles y modulares. Si hay agua, incluye fondo visible y una costa que se distinga del terreno transitable. Árboles a escala medida contra Nara, sin superar aproximadamente tres veces su altura.

Une geometría estática por material, limita triángulos por malla según el requisito común y separa cada parte móvil. Comprueba en Studio que los bordes encajan, el agua tiene fondo, no hay huecos ni piezas flotantes y la cámara conserva la vista de Nara y las amenazas en paredes y esquinas.

## Lote 4 — Tres armas, proyectiles y efectos de impacto

Crea como Models en `Workspace.Extras` las tres armas originales: **Arco de Faro**, **Ballesta Gemela** y **Honda de Rebote**. Añade sus proyectiles visuales: flecha, dos virotes y piedra. Mantén escalas proporcionadas a Nara y una silueta distinta por arma; prepara cada proyectil como pieza visual ligera, sin física de gameplay.

Prepara efectos visuales de impacto legibles para flecha, virote y piedra, reutilizables y en la paleta común. Une piezas estáticas por material; separa las partes móviles; pivotes en el punto de agarre o centro funcional. No añadas colisiones innecesarias a proyectiles visuales.

Comprueba equipamiento en Nara, orientación y escala, legibilidad durante movimiento y quietud, y que el impacto no cubra al objetivo ni un telegráfico cercano. No inventes IDs ni subas los assets.

## Lote 5 — VFX, texturas y flipbooks

Con `ropilot_vfx_textures` y ayudantes disponibles, crea texturas y flipbooks originales para: **impacto, daño, aura de habilidad, muerte de enemigo, recogida de botín, telegráfico en el suelo y ataques de jefe**. Entrega la colección de texturas y VFX en `Workspace.Extras`, con nombres claros por efecto y variante. Haz que los avisos en suelo sean distinguibles por forma y tono además de color; deben ajustarse a patrones circulares, lineales, abanicos, cargas y áreas de jefe.

Mantén partículas y auras contenidas, con duración y tamaño visual configurables; evita ruido, exceso de brillo y luces con sombra. El daño puede tener un destello corto, pero ninguna animación debe esconder el aviso del próximo golpe ni a Nara. Comprueba todos los efectos sobre cada bioma y junto a Nara, con cámara alta, en condiciones de niebla. Rechaza texturas borrosas, artefactos de flipbook y efectos que hagan ilegible la arena.

## Lote 6 — Iconos de habilidades, HUD y armas

Crea un icono original para cada una de las **20 habilidades del GDD** y prepara variantes visuales para las rarezas **común, rara y épica**, de modo que rareza y habilidad se distingan sin depender solo del color. No cambies nombres, efectos ni rarezas. Añade iconos para HUD y las tres armas.

Entrega una colección ordenada en `Workspace.Extras` con nombres estables basados en los IDs del GDD (`s01`–`s20`, `bow`, `twin`, `sling` y HUD). Mantén encuadre, grosor de contorno, escala visual y fondo consistentes. Usa el acabado de icono de la biblia visual y fondo transparente si el flujo lo permite. Comprueba cada imagen a tamaño pequeño y sobre fondos claros y oscuros; rechaza texto ilegible, símbolos ambiguos, recortes y variantes de rareza difíciles de diferenciar. Deja las imágenes listas para revisión local, sin subirlas.

## Lote 7 — Interfaz

Prepara componentes visuales para **marcos, botones, barras de vida, selector de tres habilidades y pantallas de victoria/derrota**. Entrégalos como colección ordenada en `Workspace.Extras`, con estados visuales claramente nombrados. Respeta la biblia visual y deja áreas de texto libres para que Claude Code conecte el contenido.

La jerarquía debe funcionar en móvil primero y respetar safe areas: vida arriba a la izquierda, nivel/XP abajo y tres tarjetas de habilidad centradas al elegir. Prepara tamaños y márgenes adaptables; contempla `UIScale`, pantallas pequeñas y gamepad. No asumas que el arte garantiza que la lógica de diseño sea responsiva.

Comprueba los componentes montados en una vista de Studio para móvil pequeño, móvil grande y PC/gamepad. Rechaza tarjetas, barras o texto cortados, solapes, botones sin estados legibles y fondos que escondan el juego durante combate.

## Lote 8 — Icono, miniaturas y tráiler de capturas

Prepara el **icono del juego** y **miniaturas en español e inglés**, con composición original y foco en Nara, su arco y un faro del archipiélago en la niebla. Usa el mismo lenguaje visual y deja el título editable o reservado si Ropilot no puede producir texto fiable. Entrega archivos nombrados por idioma y uso en `Workspace.Extras` o en la carpeta de salida de arte correspondiente; registra formato, dimensiones reales y ruta. No inventes requisitos de plataforma ni subas/publices imágenes.

Prepara un **tráiler de capturas**, no una promesa de gameplay: captura material desde Studio con `ropilot_studio_screenshot`, muestra movimiento, disparo, selección de habilidad, un telegráfico esquivable y el contraste de un jefe. Entrega la secuencia de capturas ordenada y una propuesta de montaje con orden y duración sugerida, identificando qué escenas son capturas reales y cuáles son arte estático. Comprueba que no aparezcan ventanas de herramientas, errores, cámara tapada ni efectos que oculten patrones.

## Lote 9 — Revisión visual en Studio

Monta o inspecciona los assets importados en Studio con `ropilot_studio_screenshot` y las herramientas de revisión disponibles. Captura vistas de: suelo modular, Nara junto a árboles, cámara en paredes y esquinas, escala de enemigos y jefes junto a Nara, telegráficos bajo efectos y componentes de interfaz en móvil pequeño, móvil grande y PC/gamepad.

Usa las capturas para corregir y regenerar assets que fallen. Comprueba en particular: cámara sin obstrucciones; nada flotando; pivotes en la base de cada módulo y en el centro funcional de accesorios; agua con fondo y costa legible; árboles a escala; mallas bajo el límite de importación; UI sin solapes, cortes o texto tapado; ningún efecto cubre un telegráfico. Guarda capturas y notas de aprobación o rechazo en una colección/carpeta de revisión bajo `Workspace.Extras`, con nombres que identifiquen escena y dispositivo. No marques como aprobada una vista no comprobada.

## Lista de comprobación antes de entregar

- [ ] Lotes en orden, con nombres de colecciones/Models claros dentro de `Workspace.Extras`.
- [ ] Escalas, dimensiones, orientaciones y pivotes documentados; módulos asentados sobre el suelo.
- [ ] Mallas dentro del límite real de importación; estáticos unidos por material y partes móviles separadas.
- [ ] Nara y los ocho enemigos/jefes se distinguen por silueta y funcionan con las animaciones previstas.
- [ ] Sin geometría cuadrada como acabado, relieve de esferas pegadas, agua sin fondo, árboles gigantes ni piezas flotantes.
- [ ] Cámara despejada y escala validada contra Nara en escenas de Studio.
- [ ] Iconos completos, VFX legibles y telegráficos siempre visibles.
- [ ] UI comprobada en móvil pequeño, móvil grande y PC/gamepad, sin solapes ni cortes.
- [ ] Capturas de revisión guardadas; errores anotados y assets fallidos regenerados.
- [ ] Imágenes no subidas y experiencia no publicada.