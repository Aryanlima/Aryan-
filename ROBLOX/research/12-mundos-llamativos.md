# 12 - Mundos llamativos: cómo los top de pesca/sim se ven en 3 segundos
Fecha: 2026-10-22. Solo investigación; sin cambios de código. Imágenes en `ROBLOX/research/img/12/` (icono 256 px + miniatura 384x216 de cada juego, bajadas de thumbnails.roblox.com).

## Fuentes y método
- [OFICIAL] Roblox APIs públicas (apis.roblox.com omni-search, thumbnails.roblox.com), 2026-10-22: IDs, jugadores y votos de abajo.
- [TERCERO] Destructoid / VGC / ginx.tv guías de Fisch (WebSearch, 2026-10-22): mapa de islas y NPC.
- Miniaturas: las miré con Read (color y composición son observación mía, no dato oficial). Solo se ve la miniatura/arte de marketing, NO el mundo real dentro del juego: lo de "mundo" es inferencia.
- [NO VERIFICADO] Todo valor de iluminación de otros juegos: no hay fuente; mis valores son recomendaciones a probar.
- last30days y create.roblox.com no usados (bloqueado / poco útil para arte).

| Juego | Universo | Jugadores 22-oct | Votos positivos |
|---|---|---|---|
| Fisch | 5750914919 | ~53.300 | 3,06 M |
| Fish It! | 6701277882 | ~70.900 | 1,35 M |
| Deep Fishing | 10526853622 | ~9.500 | 45 k |
| Go Fishing | 6764180126 | ~270 | 223 k |
| Grow a Garden | 7436755782 | ~15.700 | 9,44 M |
| Steal a Brainrot | 7709344486 | ~115.400 | 15,5 M |

## 1. Qué hacen los mundos top (lo que se ve en las miniaturas)
1. **Un solo objeto gigante domina el 50-60 % del cuadro.** Fisch: serpiente marina violeta neón arqueada sobre agua verde ácido; Fish It!: calabaza-monstruo con boca abierta más grande que el muelle; Deep Fishing: pulpo oscuro enorme bajo agua turquesa; Go Fishing: cabeza negra de monstruo con ojos naranjas sobre agua azul. Escala jugador:monstruo aprox. 1:10 a 1:30. [NO VERIFICADO fuera de la miniatura]
2. **Muelle de madera en una esquina, personaje pequeño en primer plano, y el agua ocupa el resto.** Es la composición de 3 de los 4 juegos de pesca (Fish It!, Deep Fishing, Go Fishing). El muelle es naranja-marrón saturado (nuestro muelle ya existe: reutilizar).
3. **Paleta de 2 colores opuestos + 1 acento:** azul/turquesa (agua) contra naranja/marrón (madera, calabaza) - Fisch: verde ácido + violeta; Fish It!: azul-índigo + naranja calabaza + rosa caramelo. Los fondos son muy saturados, sin grises.
4. **Brillo y neón como pista de rareza:** contornos y venas luminosas (violeta en Fisch, ojo amarillo en Deep Fishing). Bloom fuerte en lo raro; lo común es mate.
5. **Cielo limpio y brillante en los sims "de día" (Grow a Garden, Brainrot):** cielo azul claro, césped verde plano, objetos de color primario (naranja, amarillo). Mundo simple; el gancho es el objeto/número ($95.643.734.647, "$997.151.167/s"), no el terreno.
6. **Hub con identidad:** Fisch tiene isla de inicio central (Moosewood), reaparición ahí, islas con tema y NPC propios, volcán en Roslit Bay con senderos de bastón de caramelo, cueva de nieve con peces míticos [TERCERO, Destructoid/ginx 2026-10-22]. Los botes abren zonas tras nivel ~10.
7. **Eventos de temporada cambian todo el look** (Halloween en Fisch/Fish It!/Garden/Brainrot hoy: calabazas, velas, niebla verde). Barato y muy visible: ver mejora 8.
8. **Número/texto en la miniatura** (ganancias, "SECRET", "YOU"): señala la fantasía de progreso. Para el mundo: letreros 3D legibles con la meta de cada zona.

## 2. Biblia de arte de Fish & Fortune
Estado actual (leído de `server/WorldBuilder.luau`): una sola iluminación global (ClockTime 16.3, Brightness 2, Ambient 123,145,166), Sky + Atmosphere únicos, 3 estilos por zona (ground/water/tree color), muelle procedural, temas de río y costa, horizonte, fauna. Falta: iluminación por zona, un hero por zona, hitos grandes.

Regla de oro: cada zona = 1 color de agua + 1 color de madera/roca + 1 acento neón, y un objeto de más de 25 studs visible desde el spawn. Evitar gris; saturación HSV alta.

### Calm Lake (inicio, calma, "cielo despejado")
- Paleta: agua `#3FA9F5`, hierba `#6BCB5B`, madera `#C98A4B`, acento `#FFD84D`, cielo `#BFE6FF`.
- Hero visible desde spawn: **Faro-molino de madera de 40 studs** en un islote, con luz giratoria (SpotLight + Neon) y bandera. Alternativa: sombra gigante de pez dorado bajo el agua (Part elíptica oscura, 30 studs, Transparency 0.6) que cruza el lago cada ~60 s.
- 8 hitos (Parts): (1) faro/molino; (2) arco de entrada con letrero "Fish & Fortune"; (3) 3 boyas gigantes rojas/blancas (Ball, 6 studs); (4) cabaña del vendedor con techo de color; (5) hamaca con árbol grande; (6) bote de remos amarrado; (7) nenúfares gigantes (Cylinder plano, 8 studs, rosa); (8) roca con cartel de tablas "Pesca Aquí" + linterna.
- Luz: ClockTime 15.5; Brightness 2.4; Ambient `#8FB4D9`; OutdoorAmbient `#B5D6EE`; Atmosphere Density 0.28 Offset 0.2 Color `#C6E2FF` Decay `#FFE9B8` Haze 1.2 Glare 0.2; Bloom Intensity 0.3 Size 24 Threshold 1.0; ColorCorrection Saturation 0.15 Contrast 0.08 TintColor `#FFF6E8`.

### Crystal River (azul-turquesa, cristales)
- Paleta: agua `#27D6C8`, roca `#4F6BB8`, cristal `#B06CFF`, acento `#7DF9FF`, hierba `#4FA58A`.
- Hero: **Cristal gigante de 50 studs** (WedgePart/Parts rotadas, Neon, Transparency 0.25, PointLight cian) que sobresale de la cascada, con anillo de cristales pequeños; se ve desde el lago por una brecha en las montañas.
- 8 hitos: (1) cristal gigante; (2) cascada de 3 niveles (Parts azules con Neon suave); (3) puente de troncos arqueado; (4) racimos de cristal en orillas (6-10 por racimo); (5) arco natural de roca; (6) hongos luminosos azules (Cylinder + Ball Neon); (7) piedras de paso con runas brillantes; (8) tótem de pez de piedra con ojos Neon.
- Luz: ClockTime 17.2; Brightness 2.0; Ambient `#7A86C8`; OutdoorAmbient `#8E9BE0`; Atmosphere Density 0.35 Offset 0.1 Color `#9FB6FF` Decay `#7A4FC8` Haze 1.8 Glare 0.4; Bloom Intensity 0.6 Size 30 Threshold 0.85; ColorCorrection Saturation 0.25 Contrast 0.12 TintColor `#EAF0FF`.

### Golden Coast (oro, atardecer, tesoro)
- Paleta: arena `#F6DE9A`, agua `#1FB6D9`, oro `#FFB400`, acento coral `#FF6B4A`, palmera `#2FA05A`.
- Hero: **Estatua/arco dorado de 55 studs** (dos columnas + arco, material Metal/Neon dorado, PointLight cálida) o **barco pirata encallado de 45 studs**, silueta contra el sol bajo.
- 8 hitos: (1) arco/estatua dorada; (2) barco encallado; (3) palmeras altas (Cylinder inclinado + hojas Wedge, 20 studs); (4) cofres gigantes semienterrados (8 studs) con brillo; (5) faro rayado rojo/blanco; (6) sombrillas de playa de colores; (7) pila de monedas gigantes (Cylinder aplanado, Neon dorado); (8) antorchas/linternas en muelle que se encienden al atardecer.
- Luz: ClockTime 18.1 (sol bajo); Brightness 2.6; Ambient `#C99A74`; OutdoorAmbient `#E8B58A`; Atmosphere Density 0.3 Offset 0.25 Color `#FFD1A0` Decay `#FF7A4A` Haze 1.5 Glare 0.6; Bloom Intensity 0.7 Size 32 Threshold 0.8; ColorCorrection Saturation 0.3 Contrast 0.1 TintColor `#FFEBD6`; SunRays Intensity 0.15 Spread 0.8.

Notas: valores iniciales a afinar en Studio; transición entre zonas con TweenService (3-4 s) al cruzar el portal. Para móvil: Bloom y SunRays solo si la FPS aguanta; neón y luces puntuales limitados (máx. ~10 PointLight visibles por zona).

### Vida ambiente (barata)
Peces saltando (Part + tween parabólico + salpicadura de partículas cada 8-15 s); gaviotas (3-5 Parts con Wedge de alas, órbita lenta); luciérnagas/motas brillantes (ParticleEmitter, rate 3); mariposas en hierba; ondas en el agua alrededor del muelle; sombras de peces grandes bajo el agua; olas en costa (Part blanca que oscila); nubes lentas y cometas; NPC pescador en el muelle con cartel animado; cangrejos en arena (Golden Coast).

### Hub / portales / secretos
- Hub en Calm Lake: tienda, NPC vendedor, tablón de misiones y árbol de zonas con carteles grandes legibles a 40 studs.
- Portales: arcos de color de la zona de destino (verde-turquesa a Crystal River, dorado a Golden Coast) con partículas y bloqueo visual "Nivel X" si no se cumple.
- Secretos: botella con mensaje en cada zona; cofre bajo el muelle; pez dorado de sombra que da pista; cristal oculto detrás de la cascada. Recompensas pequeñas y siempre honestas (sin presión de pago).

## 3. Mejoras ordenadas (barato y visible primero)
| # | Mejora | Esfuerzo |
|---|---|---|
| 1 | Hero por zona visible desde spawn (faro, cristal, arco dorado) - nos da la "miniatura" | M |
| 2 | Iluminación por zona (tabla de arriba) con tween al cruzar portal | S |
| 3 | Subir saturación de agua/hierba a las paletas de arriba (cambiar colores en los 3 `ZoneStyle`) | S |
| 4 | Bloom + ColorCorrection + SunRays por zona (móvil: versión reducida) | S |
| 5 | Boyas, cofres, nenúfares y cristales sobredimensionados (props simples en Parts) | S |
| 6 | Sombra gigante de pez/monstruo bajo el agua cruzando el lago (Part + tween) | S |
| 7 | Peces saltando, gaviotas, luciérnagas, ondas (ambient life) | M |
| 8 | Skin de temporada (Halloween: calabazas y niebla verde) activable por config | M |
| 9 | Portales de zona con arco de color y letrero 3D con meta | M |
| 10 | Secretos por zona + NPC del hub con carteles animados | L |

## Pendiente de verificar en Studio
Rendimiento móvil de los efectos (FPS), look real con las paletas, y distancias de visión del hero desde el spawn. Sin Creator Store: todo con Parts/Terrain.
