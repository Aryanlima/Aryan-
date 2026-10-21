## Brief de dirección de arte — Fish & Fortune

### 1. Los 5 defectos visuales más graves

1. **La escena carece de un punto focal claro.** El avatar queda tapado por el minijuego; la gran masa oscura del muelle roba atención y el agua ocupa casi todo el centro sin contar una historia.
2. **El muelle parece una plataforma improvisada.** El bloque negro, ancho y plano contrasta con las tablillas pequeñas y desordenadas de la orilla. No se entiende dónde empieza la zona de pesca ni por dónde caminar.
3. **Agua y cielo tienen colores demasiado planos y saturados.** El cian uniforme parece una superficie emisiva; el cielo pálido y la iluminación frontal aplanan el relieve de la isla.
4. **La interfaz compite consigo misma.** Hay HUD a izquierda, menú a derecha, evento arriba, aviso al centro y dos botones enormes abajo. El texto de chat invade además la esquina superior izquierda.
5. **Falta acabado visual y feedback.** El mundo tiene pocos detalles que indiquen actividad, escala o recompensa; los botones y la pesca carecen de respuesta animada y los paneles no comparten un sistema visual consistente.

### 2. Cambios priorizados, concretos y medibles

1. **Definir paleta y materiales.** Base: azul noche `#20334F`, agua `#19A9D6`, espuma `#8CEBFF`, madera `#80502F`, arena `#D8C58A`, vegetación `#628A48`, acento de recompensa `#FFD04A`. Usar agua y materiales con variación; reservar el dorado para eventos y acciones importantes.
2. **Rehacer el muelle con piezas procedurales.** Sustituir el bloque negro por tablones de madera de `1.5 × 0.35 × 7` studs, con huecos de `0.08` studs y variación leve de tono. Ancho caminable: **8 studs**; longitud visible: **18–24 studs**. Añadir dos postes y un borde bajo cada lado. Mantener colisión sencilla y pocas piezas.
3. **Dar forma al borde de la laguna.** Con Terrain, crear una transición de playa de **6–10 studs** y una caída gradual hacia el agua; eliminar la orilla circular uniforme. Añadir rocas procedurales agrupadas, sin bloquear la ruta al muelle.
4. **Recuperar profundidad del agua.** Agua en `#19A9D6`; bandas o piezas semitransparentes en `#35C8E8` cerca de la orilla, con transparencia `0.35–0.5`. Añadir ondas pequeñas en grupos limitados, no una cuadrícula visible; evitar superficies cian emisivas.
5. **Ajustar cielo e iluminación.** `Lighting.Technology = Future`, `ClockTime = 16.3`, `Brightness = 2`, `ExposureCompensation = 0.1`, `Ambient = #7B91A6`, `OutdoorAmbient = #A9C4D3`. Atmosphere: `Density = 0.25`, `Offset = 0.1`, `Color = #C5E8F3`, `Decay = #F2C995`, `Glare = 0.15`, `Haze = 1.2`. Bloom: `Intensity = 0.18`, `Size = 24`, `Threshold = 1.4`.
6. **Reencuadrar cámara y avatar.** Mantener el personaje y la punta de la caña visibles durante la pesca. Sugerencia: cámara tercera persona a unos **10–12 studs**, `FieldOfView = 70`; limitar zoom máximo a **14** en la zona de pesca si el sistema actual lo permite. Evitar que el avatar quede bajo el panel central.
7. **Reordenar la jerarquía del HUD.** Consolidar monedas, perlas, bolsa y zona en una sola tarjeta de hasta **250 × 128 px**. Mantener el menú derecho en una columna de **150–170 px** de ancho y reducir el banner de evento a **540 × 44 px**. Aplicar márgenes seguros y `UIScale`/constraints para móvil.
8. **Simplificar la interfaz de pesca.** Mostrar un único panel centrado de hasta **520 × 96 px** con instrucción breve y barra de precisión; mantener el botón de acción claramente separado. Ocultar o atenuar botones de venta/acción que no correspondan al estado actual, sin cambiar la lógica de juego.
9. **Unificar tipografía y contraste.** Usar `GothamBold` para títulos y botones, `GothamMedium` para texto secundario. Títulos **24–28 px**, botones **18–22 px**, secundarios **14–16 px**. Texto blanco `#F7F9FC`; añadir `UIStroke` exterior de 1–2 px en títulos sobre fondos variables. No usar contorno y sombra gruesos a la vez.
10. **Crear componentes visuales consistentes.** Paneles azul noche con transparencia `0.08`, esquinas de **12 px**, borde `UIStroke` de **2 px** en `#55CBEA`; acento dorado `#FFD04A` solo para el CTA primario/evento. `UIGradient` sutil, fuera de `TextButton`, en fondos o marcos. Botones con alto mínimo de **52 px** y estados normal, hover/seleccionado y pulsado.
11. **Añadir “juice” con moderación.** TweenService: botón primario escala **1 → 1.04 → 1** en `0.16 s`; al acertar, flash verde de **0.12 s** y sacudida horizontal de máximo **4 px**. Al capturar, emitir **8–12** partículas de burbuja/estrella por **0.35 s**, con tamaño de **0.15–0.35 studs** y velocidad baja. Límite: **20 partículas activas** por jugador.
12. **Asegurar rendimiento móvil.** Priorizar piezas ancladas, materiales simples y agrupación visual; evitar luces dinámicas por adorno y emisores permanentes. Limitar la decoración de alta densidad a la zona cercana, con partículas breves y conteos acotados. Hacer los cambios en scripts de presentación/cliente; **no tocar la lógica de servidor**.

### 3. Qué hacen los juegos top que aquí falta

- **Un foco legible en miniatura:** personaje, mascota, objeto o acción grande, con silueta clara y contraste inmediato.
- **Color con intención:** paletas saturadas por zonas y acentos que señalan la recompensa, en vez de varios elementos compitiendo con el mismo brillo.
- **Escala y acción exageradas:** peces, criaturas o botín reconocibles; poses y efectos que comunican qué se gana incluso en una imagen pequeña.
- **Composición ordenada:** fondo que contextualiza, sujeto principal separado y texto mínimo. La captura actual muestra mundo, chat y varios paneles con el mismo peso.
- **Feedback frecuente y limpio:** animación y partículas acompañan la acción principal; la captura de pesca debería destacar el pez, la mordida y el acierto sin tapar al jugador.