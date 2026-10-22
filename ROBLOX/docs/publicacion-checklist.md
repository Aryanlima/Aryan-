# Fish & Fortune: checklist de publicacion (2026-10-22)

Solo documentacion. Nada subido, Studio no tocado.
Etiquetas: [OFICIAL] doc de Roblox; [TERCERO] terceros o prensa; [NO VERIFICADO] suposicion o dato del repo sin probar.

## 1. Textos de la ficha (pegar tal cual)

**Titulo (EN y ES):** Fish & Fortune

**Descripcion EN:**
```
Cast your line, time the reel, and sell your catch for coins. Use the coins to buy better rods, unlock Crystal River and Golden Coast, and fill your bestiary one fish at a time.
Every zone has an Odds panel. Open it to see the chance of each fish before you fish there. The timing game affects the quality of your catch, but it does not decide whether you catch a fish.
Shop items show exactly what they do. Season passes give fixed rewards. Cosmetic items only change how your gear looks, and other players can see them. In this version, no shop item is a random item bought with real money.
Seasonal events are listed in the update log.
```

**Descripcion ES:**
```
Lanza tu linea, controla el tiron y vende tu pesca por monedas. Con las monedas compra mejores canas, desbloquea el Rio Cristal y la Costa Dorada, y completa el bestiario pez a pez.
Cada zona tiene un panel de Probabilidades. Abrelo para ver la posibilidad de cada pez antes de pescar alli. El minijuego de tiempo afecta la calidad de la captura, pero no decide si pescas el pez.
Los objetos de la tienda muestran exactamente lo que hacen. Los pases de temporada dan premios fijos. Los objetos de estetica solo cambian como se ve tu equipo, y los demas jugadores pueden verlos. En esta version, ningun objeto de la tienda es un objeto aleatorio comprado con dinero real.
Los eventos de temporada aparecen en el registro de novedades.
```
Ambas estan por debajo de 1000 caracteres. [VERIFICAR con contador al pegar.]

**Generos y palabras clave (Creator Hub):** [NO VERIFICADO] nombres exactos del desplegable.
1. Simulation (genero sugerido)  2. Adventure  3. Fishing  4. Collecting  5. Idle
Sin palabras repetidas ni palabras clave sin relacion [TERCERO, research/03].

**Registro de novedades Halloween (3 lineas):**
- EN: `Halloween Harvest is live until [FECHA FIN]. Dates and rewards are in the Events panel.`
- ES: `El evento Cosecha de Halloween esta activo hasta [FECHA FIN]. Fechas y premios en el panel de Eventos.`
- EN/ES: `[Cambio real]. Odds and prices unchanged.` / `[Cambio real]. Probabilidades y precios sin cambios.`
Placeholders: escribir solo cambios reales. Nombre del evento: `src/server/LiveOpsDefaults.luau` (id `halloween_harvest`).

## 2. Cuestionario de madurez (propuesta)

[OFICIAL] Se responde con el contenido mas maduro posible; si algo cambia, se reenvia. Lo contesta Aryan. **Todo: verificar en el cuestionario real.**

| Tema | Respuesta propuesta |
|---|---|
| Violencia, sangre, lenguaje fuerte, romance, alcohol | Ninguna |
| Miedo | Leve (Halloween amable), si el evento lo incluye |
| Chat | Si: chat de Roblox por defecto, filtrado |
| Creacion libre, espacios sociales | No |
| Apuestas (incluso simuladas) | No |
| Objetos aleatorios de pago | No (v1: `paidLuckEnabled=false`) |
| IA generativa en vivo | No |
| Compras | Si: pases y productos, sin azar |

Publico: [OFICIAL] juego nuevo sin tarifa solo llega a 16+ verificados; con 1.000 Robux reembolsables o Plus/Premium 2 meses, a todas las edades [TERCERO, research/03]. Decision de Aryan.

## 3. Ajustes de la experiencia

**A. PRUEBA privada (Etapa 1, Universe 10772154962)**
- [ ] Privacidad: Private. Comprobar que no sale "Public".
- [ ] Max players: pocos (p. ej. 4). [NO VERIFICADO] valor elegido por ti.
- [ ] Studio Access to API Services: OFF en la experiencia publicada. Motivo: `pickDataStore` (GameService.luau:110-127) puede escribir en el DataStore real.
- [ ] DataStore de prueba en un universo aparte; nunca probar contra el de produccion.
- [ ] StreamingEnabled: [NO VERIFICADO] no hay valor en el repo. Dejar el de Studio y anotarlo; `Main.client.luau:121` marca el streaming como no probado.

**B. PUBLICA (solo tras la seccion 4)**
- [ ] Privacidad: Public, con cuestionario enviado.
- [ ] Publico (16+ o tarifa): decision de Aryan.
- [ ] Studio Access to API Services: sigue OFF. Max players y StreamingEnabled: los mismos que en la prueba.
- [ ] Chat: TextChatService y textos filtrados con `TextService.FilterStringAsync` [OFICIAL, safety.md].

## 4. Checklist previa a publicar

**Ficha e imagenes**
- [ ] Icono 512x512, sin texto: `marketing/fish-and-fortune/assets/icon/icon-ropilot.png` (tambien `icon-ropilot-halloween.png`). El README de assets no los lista: [VERIFICAR] que son los finales.
- [ ] Miniaturas 1920x1080, menos de 3 MB, texto por encima del 85 % de altura: `thumbnails/thumb-ropilot-{en,es}.png` y `thumb-ropilot-halloween-{en,es}.png`.
- [ ] No usar `thumb-3-amigos` hasta confirmar co-juego. Cambiar criaturas de `thumb-2-bestiario` por capturas reales.
- [ ] Iconos de interfaz: IDs en `games/fish-and-fortune/src/shared/UiIcons.luau`. [VERIFICAR] que cargan en Studio y no estan moderados.
- [ ] Pases y productos: IDs distintos de 0 en `src/server/ProductIds.luau`, con nombre y precio de `store-items.json`.
- [ ] Descripciones de `store-items.json` revisadas en EN y ES.
- [ ] Probabilidades visibles en el panel Odds.

**Legal, datos y dinero**
- [ ] Cuestionario de madurez enviado (seccion 2).
- [ ] W-9 antes del 31-oct-2026 [OFICIAL + TERCERO; CLAUDE.md]. Lo hace Aryan.
- [ ] `REVIEW(money)`: DATA-01 (bloqueo 600 s), MINI-01 (ventana 2,85 s), CONFIG-01. Decision de Aryan en cada una.
- [ ] Compra real de un pase de prueba: `TargetId` frente a `assetId` sin probar (`ProductIds.luau:19, 43`). Lo hace Aryan.
- [ ] `bash ROBLOX/tools/test.sh` en verde, lint y formato limpios; `FF_RELEASE_CHECK=1` ejecutada.

**Juego**
- [ ] Primeros 60 s probados en movil y PC, sin errores en consola.
- [ ] Avisos de playtest 1 resueltos: banner ilegible, chat tapa monedas, toast tapa titulo.
- [ ] Datos guardan y cargan al salir y volver a entrar (prueba privada).
- [ ] Acceso al universo (teletransporte desde otros lugares): revisar en Creator Dashboard [NO VERIFICADO].

## 5. Anuncios y miniaturas (plan)

**Tres variantes A/B (ficha y anuncio, ES y EN):**
- **A:** `thumb-1-mitico` ("¿UN MITICO?"). Pregunta, no promesa: un Mitico sale cerca de 0,04 % por lanzada [NO VERIFICADO, repo].
- **B:** `thumb-2-bestiario` ("COMPLETA EL BESTIARIO"). Solo con capturas reales.
- **C:** `thumb-4-zonas` ("EXPLORA 3 ZONAS"). Dato real: 3 zonas en `Balance.luau`.
- Extra: `thumb-ropilot-halloween-{en,es}.png` mientras dure el evento.

**Presupuesto (sugerencia, no garantia):**
- [TERCERO] Empezar pequeno: tope diario fijo por variante, 3 a 5 dias, y leer resultados antes de subir.
- Propuesta: 10 a 20 USD por variante en total. [NO VERIFICADO] precios reales en Ads Manager.
- Medir retencion a 28 dias y gasto recurrente, no solo clics [TERCERO, research/03].
- [OFICIAL] Anuncios con recompensa solo para 13+; etiqueta "Ad" visible.

**Reglas de gasto:**
- [ ] Nunca gasto automatico: sin scripts, sin APIs de anuncios, sin recargas. Aryan crea y pausa cada campana a mano.
- [ ] Cada variante muestra el juego real.
- [ ] Pausar si la retencion D1 queda por debajo de la mediana de referencia de 10,3 % [TERCERO, GameAnalytics 2026].
