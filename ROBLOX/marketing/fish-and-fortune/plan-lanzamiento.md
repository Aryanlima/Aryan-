# Fish & Fortune — Plan de lanzamiento y crecimiento a 30 días

Fecha: 2026-10-20. Idioma: español. Autor: sesión de marketing (Claude). Ventana del plan: **D-14 (mar 17-nov-2026) a D+15 (mié 16-dic-2026)**, con **L = D0 = martes 1-dic-2026 (provisional, la fija el plan de 90 días)**.

Etiquetas: **[OFICIAL]** leído directamente en `Roblox/creator-docs` (espejo de la doc oficial) el 2026-10-20; **[OFICIAL‡]** solo vi un extracto del buscador; **[TERCERO]**; **[NO VERIFICADO]**; **[IDEA PROPIA]** = diseño/heurística mía; **[AJUSTAR A LO REAL]** = depende del juego construido (a esta fecha `ROBLOX/games/fish-and-fortune` no existía).

Documentos hermanos: `pagina-del-juego.md` (título, textos, ícono/miniaturas), `guiones-videos.md` (30 guiones V01–V30), `prompts-ia.md` (brand kit y prompts), `plantillas-colaboracion.md` (creadores), `specs-video/` (6 specs y 6 MP4 ya renderizados). Contexto: `research/07` (puertas G0–G5), `ROBLOX/docs/plan-90-dias.md`, `research/03` (cumplimiento).

---

## 0. Resumen ejecutivo

1. **Estrategia en una frase:** no comprar crecimiento antes de saber si el juego retiene. Primero se prueba con una **muestra pequeña de pago** (G1), se **mide** y solo entonces se escala con creadores y contenido [coherente con `07` §3.5 y §6.3].
2. **Motor de contenido:** el momento "X pescó un MÍTICO" (banner global) es el único gancho propio y clipable del juego [`07` concepto 1]. Los 30 guiones giran en torno a él, a la progresión por zonas y al bestiario.
3. **Tres fases:** **Pre-lanzamiento** (D-14 a D-1: cuentas, teasers, G0, assets moderados), **Lanzamiento suave** (D0 a D+6: publicar, 1 campaña de Sponsored Ads de prueba, G1), **Escalado condicional** (D+7 a D+15: solo si pasa G1/G2 → creadores, evento 1, códigos).
4. **Dinero:** prueba de anuncios de **8.000 Robux** repartidos en 4 días (≈ 30 créditos; ver §6 para la conversión en USD y los 3 escenarios). No se repone por ánimo: solo tras un arreglo concreto.
5. **Decisión de escalar** (G3): ingreso a 7 días por visitante nuevo (neto del 30 % de Roblox) **≥ coste por play**. Hasta entonces, los anuncios sirven para comprar muestra y señales, no para ganar dinero [`07` §3.5].
6. **Cumplimiento** primero: sin "Robux gratis", sin urgencia falsa, sin presionar a menores a comprar, odds reales, divulgación de IA y de colaboraciones, nada de música con derechos (§1).
7. **Tiempo de Aryan:** el plan de 90 días le asigna 4–8 h/semana **en total** (S3 5 h, S4 8 h, S5 6 h, S6 5 h). Este plan de marketing suma ≈ 6–8 h/semana en modo completo y ≈ 3–4 h/semana en modo mínimo: **hay que recortar al modo mínimo o ampliar horas** (§5 y §11). Mínimo viable: 9 clips + Discord + 1 test de anuncios + 3 creadores.
8. **Qué NO puede hacer Claude desde la nube:** grabar el gameplay, publicar en TikTok/YouTube/Discord, enviar mensajes a creadores, pagar anuncios, generar con las cuentas de IA de Aryan. Todo eso está marcado como **[ARYAN]**.

---

## 1. Reglas de cumplimiento que gobiernan todo el plan

| Regla | Qué significa en la práctica | Etiqueta / fuente |
|---|---|---|
| Anuncios: nada de "Robux gratis", sin bots ni engagement falso, sin servicios de publicidad de terceros dentro del juego | Ningún contenido ni código promete Robux; no comprar vistas/seguidores | [OFICIAL] `comply-with-advertising-standards.md` vía `03` §2.5 |
| Publicidad fuera de Roblox (TikTok, YouTube, creadores de pago) | Declarar claramente que es publicidad; no copiar avisos oficiales de Roblox | [OFICIAL] `advertise-on-roblox.md` vía `05` §7.1 |
| Metadatos y miniaturas fieles al juego; nada que insinúe recompensa económica; título/imágenes únicos | Miniaturas con capturas reales; sin monedas/dinero/"gana" | [OFICIAL] `discovery.md` |
| Tienda: descuentos reales, sin falsa escasez, temporizadores exactos que no se reinician, lenguaje neutro para menores | Códigos y eventos solo con fecha de fin real; CTA "Juega gratis" (es cierto) y "compras opcionales" | [OFICIAL] `monetization/index.md` vía `03` §2.3 |
| Objetos aleatorios de pago: probabilidades numéricas reales visibles | En v1 **no hay** venta de suerte ni cajas con Robux (D9). Si el bestiario muestra probabilidades, que salgan de la tabla `Odds` | [OFICIAL] `paid-random-items.md`; decisión D9 |
| Redes sociales: solo en la página de detalles del juego (hasta 3, 16+ verificado); no escribir la URL ni el invite dentro del juego | Ningún cartel/UI del juego con "discord.gg/…" | [OFICIAL] `social-media-links.md` |
| Música/IP: derechos legales sobre todo audio; el contenido alterado con IA puede denunciarse | Música propia sintética del pipeline, Creator Store o licencia comprobada; revisar cada imagen/vídeo de IA | [OFICIAL] `audio/assets.md`, `ip-guidelines.md` |
| Contenido de IA en redes | Etiquetar "Escena creada con IA · no es gameplay" + usar el interruptor de la plataforma (TikTok: contenido realista; YouTube: contenido sintético/alterado realista) | [TERCERO] guías de 2026; **verificar en las páginas oficiales** |
| Menores | Público objetivo 13+ (D11). Sin presión de compra a menores; sin cuentas Kids como objetivo; Discord solo 13+ (edad mínima de Discord [NO VERIFICADO]) | [OFICIAL] `kids-and-select.md` + decisión D11 |
| Incentivos por interacción (seguir, "like", dar reseña, unirse al grupo) | **No** dar recompensas por seguir/votar/unirse mientras no se verifique la política vigente | [NO VERIFICADO] (`07` §3.6 ya lo marca) |
| Transparencia del autor | En contenido en primera persona: "Soy el creador del juego" | [IDEA PROPIA] |

---

## 2. Objetivos y métricas (conectadas con las puertas G0–G5)

### 2.1 Qué se mide y de dónde sale

| Métrica | Fuente | Frecuencia | Nota |
|---|---|---|---|
| **Plays, Impressions, Clicks, Spent, CPP, Playtime, Earnings** por campaña y por creatividad | Ads Manager [OFICIAL] | Diario (impresiones/clics en tiempo real; plays y earnings con hasta 48 h de retraso y hasta 30 días de atribución) | Mirar la vista **New Users**: "All Users" puede parecer bajo en retención/plays/ingresos [OFICIAL `ads-manager.md`] |
| **D1, D7, D30**, sesión media, embudo FTUE, compras | Creator Analytics (retención, embudos, monetización) [OFICIAL] | Diario | D7 y D30 aparecen vacíos hasta que pasen 7/30 días [OFICIAL `06` §7.2 vía plan 90] |
| **Fuente de la primera sesión** (anuncio / TikTok / YouTube / Discord / creador X) | **Launch data** + evento personalizado `first_join` con la fuente (ver §6.5) | Diario | Roblox lo ofrece como seguimiento opcional; puede no coincidir exactamente con las plays del anuncio [OFICIAL `ads-manager.md`]. **[ARYAN/juego]** debe implementar el evento |
| Canjes de códigos | Evento `code_redeemed` por código | Diario | §7 |
| Vistas, retención 3 s/15 s, compartidos, comentarios, clics al perfil | Analytics de TikTok/YouTube/IG | 2 veces/semana | Referencias absolutas de "buena retención" [NO VERIFICADO]: usar **medianas propias** (ver §2.3) |
| Miembros y mensajes del Discord/grupo | Discord/Roblox | Semanal | |

### 2.2 Umbrales por puerta (idénticos a `07` §6.3 y plan 90; yo solo añado qué marketing hace en cada una)

| Puerta | Cuándo (L = 1-dic) | Muestra mínima | Umbral | Si pasa / si no pasa (marketing) |
|---|---|---|---|---|
| **G0 Playtest** | S4, 23–29 nov (D-8 a D-2) | 5–10 personas | ≥ 85 % llega a la primera recompensa en ≤ 60 s = invertir; 70–85 % = iterar; < 70 % = matar/rehacer | **Pasa:** se confirma L y se anuncia la fecha. **No pasa:** se pospone L; se mantienen los teasers sin fecha; no se gasta en anuncios |
| **G1 Anuncios** | D+1 a D+4 (2–5 dic); lectura D+5/D+6 | 500–1.000 plays | D1 ≥ 15 % = invertir; 8–15 % = iterar; D1 < 8 % **y** sesión < 4 min tras 1 arreglo de 48 h = matar | **Invertir:** abrir oleada 1 de creadores + seguir contenido. **Iterar:** arreglar FTUE y repetir 1 vez con otra creatividad. **Matar:** parar gasto y creadores; el contenido orgánico baja a 1–2/semana |
| **G2 Retención** | D+7 a D+10 (8–11 dic) | 1.000–2.000 visitas | D7 ≥ 3 % **y** ≥ 1 % de visitantes compran = invertir; D7 1,5–3 % = iterar; D7 < 1,5 % = matar | **Invertir:** oleada 2 de creadores + evento 1 + código de evento. **Iterar:** v1.1 y repetir G1 |
| **G3 Económica** | D+10 a D+14 (11–15 dic) | Cohorte de G1/G2 | Ingreso bruto a 7 días por visitante **≥ CPP** = escalar anuncios; entre CPP/2 y CPP = iterar; **< CPP/2** = matar el gasto | **Escalar:** segunda campaña (§6.6). **Iterar:** solo precios/oferta inicial |
| **G4 Orgánico** | D+14 a D+28 (fuera de este plan salvo el arranque) | CCU diario | Orgánico ≥ 30 % y CCU pico ≥ 500 = Tier A | Se mide desde D+15 |

Notas honestas heredadas de `07`: los umbrales de CCU son heurísticas mías; la mediana de GameAnalytics (D1 10,3 %, D7 1,6 %, D30 0,5 %) viene de juegos con ≥ 1 M MAU, así que **un MVP medio estará por debajo** [TERCERO]; con 500 visitas D1 = 10 % tiene un margen de ±2,6 puntos (±1,9 con 1.000) [IDEA PROPIA, binomial]. **Si no se llega a la muestra, se prolonga la prueba; no se decide.**

### 2.3 Métricas de marketing (no son puertas, sirven para decidir qué contenido repetir) [IDEA PROPIA]

- **Mediana propia:** tras 6 vídeos, calcular la mediana de vistas por plataforma. **Repetir un formato** si 2 vídeos del formato superan 2× la mediana. **Dejar un formato** tras 3 publicaciones seguidas por debajo de 0,5× la mediana.
- **Del vídeo al juego:** vistas → clics al perfil/enlace → `first_join` por fuente. El número que importa es **primeras sesiones por 1.000 vistas** (por plataforma). Sin referencia externa fiable: se calibra con las primeras 3 semanas.
- **Comunidad:** miembros nuevos del Discord/grupo por semana; % que escribe al menos un mensaje (referencia propia).
- **Creadores:** por creador, vistas del vídeo, canjes de su código, `first_join` con su fuente, D1 de esos jugadores vs. media.

---

## 3. Canales y roles

| Canal | Para qué | Cadencia en el plan | Contenido | Esfuerzo [ARYAN] |
|---|---|---|---|---|
| **TikTok** | Picos rápidos y clips de momentos (el mítico, progresión, reto) | 3–5/semana (más en D0–D+6) | Los 30 guiones; vertical 9:16 | Publicar y responder comentarios (30 min/día) |
| **YouTube Shorts** | Descubrimiento sostenido; los vídeos viven más tiempo | Mismos vídeos que TikTok, subidos el mismo día | Igual; título SEO ("Fish & Fortune Roblox: …") y descripción con enlaces | Subir + metadatos (10 min/vídeo) |
| **Instagram Reels** | Opcional (mismo archivo) | Solo si queda tiempo (D+7 en adelante) | Igual | Opcional |
| **Discord** | Comunidad, feedback, anuncios de eventos/códigos | Anuncio por cada evento/código; encuesta semanal | Canales: #bienvenida, #novedades, #sugerencias, #bugs, #capturas, #creadores | Moderación diaria (15 min); reglas claras y 13+ |
| **Grupo de Roblox** | Punto de unión oficial, enlace en la página del juego | Mensaje en el muro ligado a cada novedad | Enlace desde "social links" (16+ verificado) | 5 min/novedad. Crear un grupo puede costar Robux [NO VERIFICADO: comprobar en Roblox] |
| **Creadores pequeños** | Alcance con confianza ajena; momentos clipables | Ola 1 (D+4, condicional a G1), ola 2 (D+8 a D+14, condicional a G2) | Acceso + código propio + VIP; sin pagos fijos al inicio [`07` §3.6] | Enviar mensajes y seguir (ver `plantillas-colaboracion.md`) |
| **Página del juego** | Conversión (icono → visita) | Ícono, 5 miniaturas, 1 vídeo de gameplay real | `pagina-del-juego.md` | Subir todo ≥ 3 días antes de L |

Enlaces con fuente: en TikTok la bio con enlace puede requerir cuenta de empresa o un mínimo de seguidores [NO VERIFICADO]; poner el enlace a la **página del juego** (con `launchData` por fuente, §6.5: **[VERIFICAR a mano]** que el enlace con launchData funciona y qué parámetros acepta).

---

## 4. Fases

### Fase 1 — Pre-lanzamiento (D-14 a D-1: 17-nov a 30-nov)
Objetivos: cuentas y comunidad mínima; 8–10 teasers publicados; G0 aprobado; íconos, miniaturas y vídeo de gameplay **moderados** antes de L; campaña de anuncios enviada a moderación; 3–5 creadores conocidos con acceso anticipado opcional.
Reglas: **no anunciar fecha** hasta que pase G0 (D-2) y el juego esté aprobado; sin "cuenta atrás" antes de eso.
Entregables: cuentas (TikTok, YouTube, Discord, grupo Roblox, Instagram opcional), perfil con descripción corta (`pagina-del-juego.md` §2.1), 5 clips reales grabados, 3 íconos y 5 miniaturas, 6 renders del pipeline (ya hechos).

### Fase 2 — Lanzamiento suave (D0 a D+6: 1-dic a 7-dic)
Objetivos: publicar en producción, ver que no hay errores graves, pasar G1 con un test de pago pequeño y mucho contenido orgánico "honesto".
Qué es "suave": no se anuncia a lo grande, no se lanzan creadores todavía (salvo los conocidos), parche rápido en 48 h si falla algo. El **código de lanzamiento** se publica en D0.
Salida: lectura de G1 (D+5/D+6) y decisión.

### Fase 3 — Escalado condicional (D+7 a D+15: 8-dic a 16-dic)
Solo si G1 ≥ "iterar" y no hay errores críticos.
- **Oleada 1 de creadores** (D+4, ya con datos parciales de G1): 10 invitaciones.
- **G2** (8–11 dic) → **oleada 2** (20 invitaciones) y **Evento 1** (15 dic, v1.2) solo si G2 pasa.
- **G3** (11–15 dic): decide la 2.ª campaña de anuncios.
- **Feedback sistemático** (§9) y recopilación de datos reales para V29/V30.

---

## 5. Calendario día por día

Leyenda: **[ARYAN]** = tiene que hacerlo él; **[CLAUDE]** = lo hace/prepara esta sesión (documentos, specs, renders, informes); **V##** = guion de `guiones-videos.md`. Hitos de desarrollo copiados de `ROBLOX/docs/plan-90-dias.md`.

| Día | Fecha | Fase | Desarrollo / puertas | Contenido (publicación) | Comunidad, anuncios, creadores, otras tareas |
|---|---|---|---|---|---|
| D-14 | mar 17-nov | Pre | S3: MVP completo (H3) | **V01** teaser IA (B) | [ARYAN] crear cuentas TikTok/YouTube (y Discord, grupo Roblox); bio con descripción corta; foto de perfil con la mascota/logo (`prompts-ia.md`) |
| D-13 | mié 18 | Pre | | — | [ARYAN] montar Discord (canales y reglas 13+, moderación); [CLAUDE] textos de bienvenida y reglas |
| D-12 | jue 19 | Pre | | **V05** presentación de Fortu (B) | [ARYAN] generar mascota y clip IA; activar etiqueta de IA al subir |
| D-11 | vie 20 | Pre | | **V03** gancho de marca (C, `ff-01`) | [ARYAN] publicar el MP4 ya renderizado |
| D-10 | sáb 21 | Pre | | — | [ARYAN] grabar clips reales (V02, V08, V12, V10) con 2 cuentas de prueba |
| D-9 | dom 22 | Pre | Fin S3 | **V09** leyenda del lago (B) | [ARYAN] subir a Creator Hub los íconos A/B/C y 5 miniaturas (moderación hasta 48 h) |
| D-8 | lun 23 | Pre | S4: arranca **G0** | **V02** "X pescó un MÍTICO" (A) | [ARYAN] cuestionario de madurez; decidir tarifa/Plus (D10); invitar a 5–10 personas a G0 |
| D-7 | mar 24 | Pre | G0 en curso | **V12** bestiario (A) | [CLAUDE] lista de 30 creadores a partir de lo que dé Aryan (tracker en `plantillas-colaboracion.md`); [ARYAN] responder 3–5 contactos conocidos |
| D-6 | mié 25 | Pre | G0: resultados | — (día de playtest) | [ARYAN] medir embudo FTUE (≥ 85 % a la primera recompensa en ≤ 60 s) |
| D-5 | jue 26 | Pre | Arreglos | **V10** progresión (A) | [ARYAN] decidir L definitivo; [CLAUDE] kit de anuncios |
| D-4 | vie 27 | Pre | | **V13** loop relajante (B) | [ARYAN] enlazar redes en la página del juego (social links, 16+) |
| D-3 | sáb 28 | Pre | Publicar en producción (aprobación) | — | [ARYAN] subir vídeo de gameplay real (≤ 3/mes); crear **campaña de anuncios** y enviarla a moderación (assets hasta 48 h) |
| D-2 | dom 29 | Pre | Fin S4: **G0 decidido** | **V07** escalera de rareza (C, `ff-02`) | Si G0 pasa: **anunciar fecha**. [ARYAN] probar el código `LANZAMIENTO` en el universo de pruebas |
| D-1 | lun 30 | Pre | Aprobación del juego | **V17** amanecer de lanzamiento (B), solo con fecha firme | [ARYAN] revisar campaña aprobada; programar inicio D+1 00:00; mensaje en Discord y grupo |
| **D0 = L** | **mar 1-dic** | Lanzamiento suave | **v1.0 en producción** | **V22** código (C, `ff-05`) + **V08** POV mítico (A) | [ARYAN] publicar; verificar compras y datos; activar código `LANZAMIENTO`; vigilar errores y reportes (panel de Seguridad) |
| D+1 | mié 2 | Suave | **G1 día 1** | **V04** primera caña (A) | Ads ON (objetivo Plays, New Players); [CLAUDE] informe diario (CPP, plays, D0) |
| D+2 | jue 3 | Suave | G1 día 2 | **V06** probé el pez más raro (A) | [CLAUDE] informe; regla de parada diaria (§6.4) |
| D+3 | vie 4 | Suave | G1 día 3 | **V18** pesco con amigos (A) | Parche de 48 h si hace falta (1 arreglo permitido en G1) |
| D+4 | sáb 5 | Suave | G1 día 4 (fin ads) | **V11** zonas (C, `ff-03`) | **Oleada 1 de creadores** (10 invitaciones, condicional: sin errores críticos y D1 parcial ≥ 8 %) |
| D+5 | dom 6 | Suave | **G1: lectura D1** | **V14** comparativa de cañas (A) | [CLAUDE] informe G1 con muestra y IC; decisión provisional |
| D+6 | lun 7 | Suave | G1 cerrado | **V16** reto día 1 (A) | **Decisión G1:** invertir / iterar / matar (§2.2). S6 empieza |
| D+7 | mar 8 | Escalado | **G2 abre** (8–11) | **V29** resumen semana 1 (C, solo con datos reales) | v1.1 (arreglos con datos); si G1 = iterar: segunda creatividad |
| D+8 | mié 9 | Esc. | G2 | **V15** tutorial express (C, `ff-06`) | Encuesta semanal en Discord (§9) |
| D+9 | jue 10 | Esc. | G2 | **V23** reacción de un amigo (A) | **Oleada 2 de creadores** (20, solo si D1 ≥ 8 % y sin críticos) |
| D+10 | vie 11 | Esc. | **G2 decidido**; **G3 abre** | **V20** tutorial real (A) | [CLAUDE] cohorte G1/G2: D7, compradores; ingreso 7 d vs CPP |
| D+11 | sáb 12 | Esc. | G3 | **V21** teaser evento invierno (B, solo si el evento es real) | Preparar evento 1 en Creator Hub (Experience Event con hasta 5 miniaturas) |
| D+12 | dom 13 | Esc. | G3 | **V24** reto día 7 (A) | Informe semanal 2 |
| D+13 | lun 14 | Esc. | G3 | **V26** encuesta de criatura (C) | Anunciar evento 1 en Discord y grupo (≥ 24 h antes) |
| D+14 | mar 15 | Esc. | **G3 decidido**; **v1.2 Evento 1** (solo si G2 pasa) | **V19** anuncio de evento (C, `ff-04`) | Código `LANZAMIENTO` **caduca hoy 23:59 UTC**; código del evento activo; decidir 2.ª campaña de anuncios |
| D+15 | mié 16 | Esc. | | **V27** evento en vivo (A) | [CLAUDE] informe de 30 días parcial; calendario de los siguientes 30 (reserva: V25, V28, V30) |

**Si no se llega a todo (mínimo viable, 9 clips):** publicar solo V01 (D-14), V03 (D-11), V02 (D-8), V22 y V08 (D0), V06 (D+2), V14 (D+5), V15 (D+8) y V19 (D+14), y omitir los demás; **no** omitir G0, el estado de la página, los anuncios de prueba ni el informe diario de G1.

**Reservas:** V25 (comparativa de zonas), V28 (hito de comunidad, solo si es real), V30 (balance honesto D+30). Se usan si hay hueco o si un formato funciona mucho.

---

## 6. Plan de prueba de Sponsored Ads

### 6.1 Cómo funciona Ads Manager [OFICIAL, `ads-manager.md`, leído 2026-10-20]
- Requisitos: 13+ y correo verificado; pago con **tarjeta solo 18+**; **conversión Robux → créditos irreversible**; primer pago con tarjeta: 5 USD al enviar la campaña (se aplica a la primera factura) y retención temporal de 1 USD.
- Presupuesto **diario o total (lifetime)**; **solo pujas automáticas** (no hay puja manual, ni CPC/CPP que fijar); se fija fecha, hora y duración; nombre, presupuesto, calendario y creatividades se pueden editar tras publicar; **objetivo, audiencia y método de pago no se pueden cambiar**.
- Objetivos: **Plays** (jugadores con más probabilidad de iniciar sesión; recomendado para pruebas amplias), Earnings (limitado), Engagement (jugadores muy activos; mayor coste por play; esperar 3–5 días).
- Audiencias: All, **New Players** (nunca han jugado o > 180 días), Recent (≥ 10.000 jugadores recientes), Lapsed (≥ 20.000). Segmentación avanzada opcional: ubicación, edad, género, género de juego, dispositivo.
- Creatividades: hasta **10 miniaturas 16:9 por campaña, repartidas por igual**; función "AI generate" crea 3 variantes desde texto; no hay reglas de texto propias publicadas (la miniatura es el anuncio).
- Moderación: campaña hasta 24 h; assets nuevos hasta 48 h.
- Métricas: Spent, Impressions, Clicks, Plays, **CPP (gasto/plays)**, Playtime, Earnings; ROAS solo en campañas Earnings; **no hay métrica de retención** en Ads Manager. Vistas: All, New, Recent, Resurrected. Plays y earnings pueden incluir eventos hasta 30 días tras el anuncio; datos con hasta 48 h de retraso.
- **Seguimiento por launch data:** opcional, para identificar uniones por anuncio; probar la URL antes de lanzar; puede no coincidir exactamente con las plays del tile patrocinado.
- Fraude: se analiza a los 14 días del fin; reembolsos a los 16 días.
- **No indica** presupuesto mínimo, tasa Robux→crédito, ni límites de caracteres de título: **[VERIFICAR en el panel]** antes de pagar. Un resumen de `research/07` cita **1 crédito = 263 Robux** [OFICIAL‡] y 263 ≈ 1/0,0038 (tarifa estándar de DevEx), lo que sugiere que **1 crédito vale 1 USD de gasto** [IDEA PROPIA, NO VERIFICADO].

### 6.2 Presupuesto en Robux y USD (cuatro "lentes")

Convenciones: créditos = Robux ÷ 263 [OFICIAL‡]; USD nominal = Robux × 0,01 (convención del plan 90); USD "de cobro" = Robux × 0,0038 (lo que Roblox paga por Robux ganado, DevEx estándar [OFICIAL]). El coste real depende de cómo consigas los Robux (comprarlos con tarjeta cuesta más que su valor de cobro) y de cuánto cuesta un crédito con tarjeta: **[VERIFICAR en Ads Manager]**.

| Escenario | Robux totales | Por día (4 días) | Créditos | USD nominal | USD "de cobro" | Plays esperables a CPP 4 / 8 / 12 R$ [TERCERO, 4–12 R$ por visita (DevForum vía RoWatcher)] |
|---|---:|---:|---:|---:|---:|---|
| **Mínimo** (plan 90, nivel 1 bajo) | 5.000 | 1.250 | 19,0 | 50 | 19 | 1.250 / 625 / 417 |
| **Recomendado (G1)** | **8.000** | **2.000** | **30,4** | **80** | **30** | **2.000 / 1.000 / 667** |
| **Máximo** (plan 90, nivel 1 alto) | 10.000 | 2.500 | 38,0 | 100 | 38 | 2.500 / 1.250 / 833 |

Contraste con otra fuente: un vendedor de promoción da **0,45 USD por play** [NO VERIFICADO, `07` §3.5, BLOXG]: a 0,01 USD/Robux serían **45 R$ por play** (4–10 veces más que el DevForum). Por eso el primer día es una **prueba de coste** (§6.4): si el CPP real se parece al del vendedor, 8.000 Robux solo darían ~180 plays y **no alcanzan** para G1.

**Recomendación [IDEA PROPIA]:** 8.000 Robux. Se compra de una vez (la conversión es irreversible), pero la campaña se limita con presupuesto **diario de 2.000** y 4 días. Los créditos no gastados se **devuelven** al terminar o cancelar [OFICIAL `ads-manager.md`].

### 6.3 Diseño de la campaña G1 [IDEA PROPIA, coherente con el plan 90 §6]

| Parámetro | Valor | Razón |
|---|---|---|
| Objetivo | **Plays** | Es el recomendado para pruebas amplias; Earnings está "limitado" y Engagement cuesta más |
| Audiencia | **New Players** | Mide adquisición real, sin canibalizar jugadores que ya conocen el juego; las audiencias Recent/Lapsed no alcanzan el mínimo (10.000 / 20.000) |
| Segmentación | Edad **13+** (si el selector lo permite); ubicación: dejar abierta en G1 (y mirar el desglose por país en Analytics); dispositivo: todos | El producto está pensado para 13+ (D11); cerrar países sube el CPP y reduce la muestra |
| Presupuesto | **2.000 Robux/día × 4 días (D+1 a D+4)** | 8.000 totales; ver §6.2 |
| Creatividades | **3** miniaturas 16:9 con el mismo título: **A** = hero Mítico (Idea 1), **B** = mascota Fortu (Idea 5), **C** = Idea 3 (bestiario) o Idea 4 (amigos) la que tenga capturas reales | Se reparten por igual; compara de forma limpia qué imagen convierte |
| Título/ícono | El del juego | No se cambian durante la prueba (mezclaría cohortes) |
| Lanzamiento | Aprobación de campaña **D-1**; inicio **D+1 00:00** | La campaña tarda hasta 24 h y los assets hasta 48 h en moderarse; subir assets en D-3 |
| Launch data | Etiqueta por campaña, p. ej. `ads_g1` (y variante si la herramienta la admite) | §6.5 |

### 6.4 Reglas de parada y de decisión durante G1

- **Prueba de coste (día D+1):** al final del día 1, calcular el CPP del día. Si **plays < 80** con 2.000 R$ gastados (CPP > 25 R$), **pausar**: o la miniatura no convierte o el coste real es mayor que el rango del DevForum. Acción: revisar la miniatura/título una vez (editable) y repetir 1 día; si sigue > 25 R$, bajar el objetivo de muestra y compensar con creadores (G1 tardará más y será menos fiable) [IDEA PROPIA].
- **Sin cambios a mitad:** no se tocan objetivo ni audiencia (están fijos tras publicar); solo se retira una miniatura si es claramente peor (< 0,5× de plays por impresión de las otras tras ≥ 1.000 impresiones por variante).
- **Parada de calidad:** si el juego tiene un error grave (compras/datos), **pausar los anuncios el mismo día** y no reponer el gasto hasta arreglarlo.
- **Tope duro:** el gasto total de G1 no supera los créditos comprados (8.000 R$ ≈ 30,4 créditos). No se repone "por ánimo": solo tras un arreglo concreto (plan 90).
- **Muestra:** lograr ≥ 500 plays (idealmente 1.000). Si al acabar los 4 días hay < 500, **se prolonga** hasta llegar (los créditos sobrantes se pueden reutilizar en una nueva campaña) en vez de decidir con muestra pobre.

### 6.5 Cómo medir: CPP frente a ingreso a 7 días

**Definiciones**
- **CPP** (coste por play) = gasto ÷ plays [OFICIAL, definición de Ads Manager]. Es el "CPV" del plan 90; uso CPP para no mezclar con "visitas" de Analytics.
- **Cohorte de anuncios** = jugadores cuya primera sesión llegó por la campaña (por launch data / `first_join` o, si falla, por la vista **New Users** de la campaña).
- **Ingreso bruto 7 d por play** = Robux gastados por la cohorte en sus primeros 7 días ÷ plays de la cohorte.
- **Ingreso neto 7 d por play** = bruto × 0,70 (Roblox se queda el 30 % de las ventas del juego [OFICIAL `02` §2.1]).
- **Ratio de puerta G3** = ingreso bruto 7 d por play ÷ CPP (como está definido en `07` §6.3 y plan 90). **Comprobación estricta que añado:** ratio neto = ingreso neto ÷ CPP.

**Reglas de lectura**
| Ratio bruto (G3) | Ratio neto | Decisión |
|---|---|---|
| ≥ 1,0 | ≥ 1,0 | **Escalar** (2.ª campaña, §6.6) |
| ≥ 1,0 | 0,7–1,0 | **Iterar**: oferta inicial y precios; no escalar todavía |
| 0,5–1,0 | < 0,7 | **Iterar**: solo con un cambio concreto |
| < 0,5 | cualquiera | **Matar el gasto** de anuncios de este juego (el contenido orgánico sigue) |

**Ejemplo ilustrativo (cifras inventadas para mostrar el cálculo, NO son datos):** gasto 8.000 R$, plays 1.000 → CPP 8,0 R$. La cohorte gasta 2.400 R$ brutos en 7 días → 2,4 R$ por play bruto → ratio bruto 0,30 (< 0,5 → matar); neto = 1,68 → 0,21. Para que el juego se pague solo a ese CPP, el ingreso bruto por play debería ser ≥ 8 R$: con un 2 % de jugadores que pagan, eso exige un ARPPU de 8 ÷ 0,02 = 400 R$ por pagador en 7 días (571 R$ en términos netos). La tabla de `07` §3.5 da 500 R$ para CPP 7 y 2 % con cuota del 70 %. **Conclusión de `07`:** con conversiones y ARPPU típicos, los anuncios **compran muestra y señales, no ganan dinero** al principio.

**Cómo se cruza la información [ARYAN/juego]**
1. Implementar en el juego: al primer ingreso guardar en el perfil `acquisition = {src, firstJoin}` desde `Player:GetJoinData()` (launch data) y disparar un evento personalizado `first_join` con `src`; marcar cada compra con `src` [IDEA PROPIA; los eventos personalizados y los embudos existen en Analytics, `05` §7.3]. Pedir esto al agente del juego **antes** de L.
2. Probar la URL con launch data antes de lanzar (recomendación oficial).
3. Hoja de cálculo diaria (copiar a Sheets/Excel):

| Fecha | Variante | Gasto R$ | Impresiones | Clics | Plays | CPP | CTR (clics/impr.) | Plays/impr. | D1 cohorte | Sesión media | Compradores | Ingreso bruto 7 d | Neto 7 d | Ratio bruto/neto |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

4. Calendario de lectura: **D+5/D+6** → D1 y sesión (G1); **D+9 a D+11** → D7 de las cohortes de 2–4 dic (G2); **D+10 a D+14** → ingreso a 7 días (G3). D7 de la cohorte del 5 dic no estará hasta el 12 dic.

### 6.6 Si G3 dice "escalar" (D+14)
Segunda campaña con el **mismo diseño**, presupuesto ≤ 2× el de G1 (≈ 16.000 R$) repartido en 7 días, usando solo la mejor creatividad y **reevaluando cada 3 días**; sigue la regla "ingreso 7 d por visitante > CPP" antes de cualquier aumento. Las campañas que empiecen desde el **1-ene-2027** pagan además una cuota por visitas calificadas según el país [OFICIAL `03` §2.5]: recalcular el CPP efectivo en esa fecha.

---

## 7. Plan de códigos de canje

**Objetivo:** reactivar y medir fuentes (cada código es un canal), no regalar moneda. Un código = boost pequeño o cosmético, validado en el servidor, con caducidad y límite por cuenta [`07` §3.6].

### 7.1 Reglas de diseño
1. **Validación en servidor** (nunca en el cliente); tabla de códigos en config (ConfigService) con `id`, `reward`, `startsAt`, `endsAt`, `perAccountLimit`, `source`.
2. **Un canje por cuenta y código**; registro (`code_redeemed`) con `src`; protección contra spam de intentos (rate limit).
3. **Recompensa**: boost de tiempo limitado (p. ej. 15–30 min de bonificación) o cosmético; **nada de moneda masiva ni Robux**. El texto nunca promete Robux.
4. **Fechas reales de fin**, visibles en el juego en UTC y en la hora local; no se reinician ni se reabren con otro nombre.
5. **No condicionar a seguir/dar "like"/unirse al grupo** hasta verificar la política vigente de incentivos [NO VERIFICADO].
6. **Si la recompensa es aleatoria y se gana jugando sin pagar** no entra en "objetos aleatorios de pago", pero que no pueda comprarse con moneda comprada con Robux [OFICIAL `paid-random-items.md`, exención].
7. **No poner la URL/Discord en el juego**; el código se difunde en redes, no en la UI del juego.

### 7.2 Calendario de códigos (30 días)

| Código | Cuándo | Caduca | Recompensa (propuesta; [AJUSTAR A LO REAL]) | Fuente / medición | Contenido asociado |
|---|---|---|---|---|---|
| `LANZAMIENTO` | D0 (1-dic) | **15-dic 23:59 UTC** (D+14) | Boost de lanzamiento corto (p. ej. cebo/2× dinero 15–30 min) | `code_redeemed:LANZAMIENTO`; todos los canales | **V22** (render listo) |
| `CREADOR-<NOMBRE>` | Con cada creador (D+4 en adelante) | 14 días desde su vídeo | Cosmético pequeño o boost; el creador no cobra por canje | Canjes + `first_join` por creador | Vídeo del creador |
| `EVENTO-<NOMBRE>` | Con cada evento (D+14 = evento 1) | Fin real del evento | Cosmético/boost del evento | Reactivación de dormidos | V19/V27 |
| `HITO-<N>` | Solo cuando se cumpla un hito **real** (p. ej. N criaturas pescadas por la comunidad) | 7 días | Boost para todos | Comunidad | V28 (si hay hito) |
| `OPINA` (código de encuesta) | Solo con una encuesta real (§9) | 7 días | Cosmético pequeño, **independiente de lo que responda** | Participación en la encuesta | Post en Discord |

**Métricas:** canjes/día por código, % de canjeadores con D1 vs. no canjeadores, % de canjes en las primeras 24 h tras la publicación, tasa de intentos inválidos (abuso), proporción de canjes por cuentas nuevas (< 1 día) sospechosas.

**Pasos [ARYAN] / juego:** el sistema de códigos debe existir y estar probado en el universo de pruebas **antes** de publicar V22; la sesión del juego (otro agente) implementa el módulo; marketing solo difunde códigos que existan.

---

## 8. Plan de eventos semanales

Base: eventos de **7 a 30 días**, máximo 10 publicados o próximos [OFICIAL‡ `07` §4.2]; Roblox permite usar **hasta 5 miniaturas** por evento [OFICIAL `discovery.md`]. Cadencia del plan de 90 días: v1.1 parche (8–11 dic), **v1.2 Evento 1 (15 dic, solo si G2 pasa)**, evento festivo (22–24 dic) [`plan-90-dias.md` §5].

### 8.1 Qué se propone en estas 3 semanas [IDEA PROPIA; requiere que el juego lo soporte → coordinar con el agente del juego]

| Semana | Fechas | Evento | Mecánica (config) | Marketing asociado | Condición |
|---|---|---|---|---|---|
| **S1** | 1–6 dic | **Sin evento** (estabilidad del lanzamiento); solo el código `LANZAMIENTO` | — | Lanzamiento, G1 | — |
| **S2** | 7–13 dic | **"Criatura de la semana"** (mini-evento recurrente): una criatura destacada con **probabilidad real mostrada** y el mismo horario cada lunes 00:00 UTC (predecible, sin urgencia falsa) | Entrada de config con criatura + multiplicador; probabilidad visible en el bestiario | V24 (reto), V26 (encuesta); post en Discord los domingos con la criatura de la semana siguiente | Si el juego lo soporta; si no, se pasa a S3 |
| **S3** | 14–20 dic | **Evento 1 (7 días): 15–22 dic** "Marea Brillante" (nombre de ejemplo): criaturas exclusivas jugando, entradas de bestiario nuevas, código de evento; pase de temporada 1 opcional [plan v1.2] | Evento por config + **Experience Event** de Roblox con hasta 5 miniaturas | V21 (teaser), V19 (anuncio), V27 (en vivo) | **Solo si G2 pasa** |
| S4 (fuera de ventana) | 21–27 dic | Evento festivo de invierno (hasta 30 días) [plan v1.3] | | V21 | G2/G3 |

### 8.2 Calendario de comunicación por evento (plantilla)
- **T-72 h:** teaser (IA o render) con **fechas reales**; creación del Experience Event en Roblox (miniaturas ES/EN).
- **T-24 h:** anuncio en Discord/grupo; recordatorio en TikTok/Shorts.
- **Día 1:** vídeo de gameplay del evento (A) + render de anuncio (C).
- **Mitad del evento:** clip de un momento real (p. ej. criatura del evento pescada).
- **Último día:** recordatorio con fecha/hora exactas (real; no "últimas horas" si hay margen).
- **T+24 h:** post-mortem con datos reales (cuántos jugaron, criaturas del evento pescadas; cifras pequeñas incluidas).

### 8.3 Cumplimiento de eventos
Precios/ofertas: **no** usar "oferta limitada" ni temporizadores que se reinicien; descuentos reales; lenguaje neutro ("Ver artículo", "Abrir tienda") en cualquier tienda de evento [OFICIAL `03` §2.3]. Cualquier objeto aleatorio comprado con Robux queda fuera de v1 (D9).

---

## 9. Plan para pedir feedback a jugadores

**Principios:** pedir poco, cerrar el ciclo ("hicimos caso a…"), no incentivar votos positivos ni reseñas, no recoger datos personales de menores, respetar la edad mínima de las plataformas (Discord y TikTok 13+ [NO VERIFICADO]).

| Capa | Cómo | Cuándo | Qué se pregunta | Quién |
|---|---|---|---|---|
| **1. Datos de comportamiento** | Embudos y eventos de Analytics (abandono en el tutorial, tiempo a la primera mejora, uso del bestiario) | Siempre | Qué hace el jugador, no lo que dice | [CLAUDE] lee los informes |
| **2. Micro-encuesta en el juego** | 1 pregunta con 3–4 opciones al final de la 1.ª sesión larga (≥ 8 min o 2.º día): "¿Qué fue lo más divertido? / ¿Qué te frenó?" Sin texto libre (evita moderación/filtrado) | D+1 en adelante | Opciones cerradas; la 2.ª pregunta es opcional con texto filtrado (`TextService`) solo si se añade | Juego (otro agente) |
| **3. Discord #sugerencias y #bugs** | Plantilla fijada: "¿Qué pasó? ¿En qué zona? ¿Qué esperabas?" | Siempre | Bugs y sugerencias; etiquetas de estado (visto / planeado / hecho) | [ARYAN] modera |
| **4. Encuesta semanal (formulario)** | 5 preguntas en un formulario (sin recoger nombre de usuario ni correo de menores); enlace en Discord y en TikTok | D+8, D+13 | Plantilla abajo | [ARYAN] publica; [CLAUDE] resume |
| **5. Entrevistas** | 5 conversaciones de 15 min con jugadores **adultos** o con permiso expreso de un tutor | D+6 a D+14 | "¿Qué hiciste en tu primera sesión? ¿Qué no entendiste? ¿Qué te haría volver mañana?" | [ARYAN] |
| **6. Votaciones públicas de criaturas** | Encuesta en TikTok (V26) y Discord | D+13 | "¿Qué criatura quieres en el próximo evento?" (ideas reales posibles) | Mixto |

### 9.1 Plantilla de encuesta (ES / EN)
1. ¿Cuánto tiempo llevas jugando? (< 1 día / 2–7 días / > 1 semana) · *How long have you played?*
2. ¿Qué es lo que más te gusta de Fish & Fortune? (pescar / coleccionar el bestiario / jugar con amigos / los avisos de Míticos / otra cosa) · *What do you like most?*
3. ¿Qué te frenó o te aburrió? (opciones + "otra cosa") · *What held you back or bored you?*
4. ¿Qué tan decepcionado estarías si no pudieras volver a jugar? (muy / algo / nada) [pregunta tipo "Sean Ellis", conocimiento general [NO VERIFICADO] como referencia]
5. ¿Qué te gustaría ver en la próxima actualización? (opciones + texto opcional) · *What would you like to see next?*

**Cierre del ciclo:** cada domingo, post "Esto hicimos con vuestro feedback" (3 cosas máximo) en Discord y Shorts. **Sin recompensas por responder** salvo un cosmético pequeño y **no condicionado** a la respuesta (código `OPINA`, §7).

### 9.2 Reglas de comunidad (Discord y grupo)
- Edad mínima 13+; sin mensajes directos del equipo a menores; moderación activa; reglas visibles: sin compartir datos personales, sin intercambio de Robux/cuentas, sin enlaces de apuestas [OFICIAL `03` §2.2, §2.6].
- Reportar a Roblox cualquier contenido preocupante; mantener copia de moderación.

---

## 10. Informe semanal (formato que preparará Claude) y riesgos

**Informe diario D+1 a D+6 (G1):** gasto, impresiones, plays, CPP por variante, D0/D1 parciales, sesión media, compradores, errores del juego, decisión del día.
**Informe semanal:** 1) ¿pasamos la puerta? (tabla de §2.2 con números y muestra), 2) vídeos con mejor y peor resultado, 3) canjes por código, 4) feedback agrupado en 3 temas, 5) 3 acciones de la semana siguiente.

| Riesgo | Señal | Respuesta |
|---|---|---|
| El juego no pasa G0 | < 85 % llegan a la primera recompensa ≤ 60 s | Se pospone L; solo teasers sin fecha |
| Cuenta o juego moderado por IP/IA | Aviso de moderación | Retirar el asset; guardar prompts y fuentes; no repetir |
| CPP real muy alto | > 25 R$ el día 1 | §6.4: pausar y revisar la miniatura |
| Contenido de IA mal etiquetado | Aviso de TikTok/YouTube | Etiquetar siempre; revisar guías oficiales |
| Spam o abuso en Discord/códigos | Picos de canjes sospechosos | Rate limit, caducidad corta, moderación |
| Cambios de política (Términos 1-nov-2026, anuncios) | Anuncios del DevForum | Leer los Términos nuevos antes de L; revisión mensual |
| Falta de tiempo de Aryan | > 8 h/semana | Plan mínimo viable (§0, punto 7, y §5) |

---

## 11. Qué necesita Aryan (cuentas, claves, capturas, tiempo)

**Cuentas / accesos [ARYAN]**
- [ ] Roblox: cuenta con 2FA, verificación de edad y correo; Creator Hub; Ads Manager (13+, tarjeta solo 18+; créditos = Robux, irreversible).
- [ ] TikTok, YouTube, Instagram (opcional), Discord (servidor 13+), grupo de Roblox.
- [ ] Una herramienta de **imagen** (Ideogram/gpt-image-2/Midjourney) y una de **vídeo de IA** (Veo/Kling/Runway; **Sora ya no está disponible** [TERCERO]).
- [ ] CapCut o DaVinci Resolve; OBS (o grabación de pantalla móvil).
- [ ] (Opcional) ElevenLabs Starter u otra voz con licencia comercial.

**Claves/API:** ninguna es necesaria para el marketing; el renderizador de vídeo funciona sin claves (ya se renderizaron 6 vídeos).

**Capturas/grabaciones de gameplay [a grabar por Aryan o por la sesión de su PC]:** al menos 5 clips verticales: banner de Mítico (V02/V08), primeros 3 minutos (V04/V10), bestiario (V12), lanzamiento de caña (V20), 2 jugadores en el mismo lago (V18). En **servidor privado/entorno de pruebas**, sin nombres ajenos.

**Peticiones al agente del juego (antes de L) [coordinar]:** 1) evento `first_join` con la fuente (launch data); 2) sistema de códigos validado en servidor con caducidad; 3) banner global de Mítico con texto estable; 4) bestiario con probabilidades visibles desde la tabla `Odds`; 5) botón "Códigos" visible; 6) eventos por config con fechas reales.

**Tiempo estimado de Aryan (solo marketing, por semana) [IDEA PROPIA]:** modo completo ≈ 6–8 h (pre-lanzamiento y lanzamiento), 5–6 h (escalado); modo mínimo ≈ 3–4 h/semana (9 clips, Discord, 1 test de anuncios, 3 creadores). Compárese con las horas totales del plan 90 (S3 5 h, S4 8 h, S5 6 h, S6 5 h, S7 4 h): hay que elegir el modo mínimo salvo que se amplíen.

---

## 12. Dudas abiertas y verificaciones manuales

1. Precio de un crédito en USD, mínimos de campaña y límites de texto en Ads Manager → **[VERIFICAR en el panel]**.
2. Disponibilidad y sintaxis del enlace con launch data (`?launchData=` o equivalente) y cómo se lee con `Player:GetJoinData()` → **[VERIFICAR en el Creator Hub / docs]**.
3. Política vigente de incentivos por "seguir/votar/unirse" (grupos, "like") → **[NO VERIFICADO]**.
4. Condiciones exactas de TikTok y YouTube para contenido de IA y música → **[NO VERIFICADO]**; guías de terceros de 2026 coinciden en: etiquetar contenido realista de IA y usar el interruptor de la plataforma.
5. Si la tarifa de 1.000 Robux o Plus/Premium (D10) afecta al alcance en el lanzamiento (Kids/Select) → plan 90.
6. Contenido de los Términos de Uso de Roblox del 1-nov-2026 → leer antes de L.
7. Disponibilidad real del nombre "Fish & Fortune" → **[VERIFICAR a mano en Roblox]** (ver `pagina-del-juego.md` §1).
8. Costo de crear un grupo de Roblox → **[NO VERIFICADO]**.
