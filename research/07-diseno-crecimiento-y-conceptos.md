# 07 - Diseño de juego, descubrimiento/crecimiento y conceptos para Roblox

Fecha del informe: 2026-10-20. Idioma: español. Alcance: diseño de juego, descubrimiento, portafolio y conceptos. No cubre implementación técnica, legal ni fiscal en profundidad (otros informes).

---

## 0. Resumen ejecutivo

1. **El algoritmo de 2026 premia la retención a 28 días, el gasto recurrente y el juego con amigos, no el clic fácil.** Desde junio de 2026 "Recommended For You" mide Día 1, Días 2-7 y Días 8-28 con señales como minutos jugados, días de juego, sesiones calificadas, días de co-juego intencional, días de gasto y Robux gastados [F3][F4]. Un juego fuerte en retención Y monetización obtiene más distribución que uno fuerte en solo una [F2].
2. **El viento de cara de la plataforma es real.** DAU de 123 M en Q2-2026 frente a un pico de 151,5 M en Q3-2025, y Roblox atribuye el flojo crecimiento de bookings (+8 % en Q2) en parte al propio cambio de algoritmo y a menor monetización por hora en menores de 13 años [F10][F11][F12]. La guía de Q3 apunta a una caída de bookings del 14-18 % interanual (resumen de la transcripción, sin verificar contra la carta oficial) [F11].
3. **El dinero está muy concentrado.** Según datos presentados por Roblox en RDC 2026: ~1.700 M USD pagados a creadores en 12 meses; media del top 10 = 65,7 M USD, top 100 = 10,8 M USD, top 1.000 = 1,4 M USD; **mediana de los >42.000 creadores en DevEx ≈ 1.500 USD/año** [F24]. Mi aritmética: el top 1.000 concentra ~82 % del total. Un portafolio de "muchos juegos baratos" es comprar boletos de lotería de coste acotado; la IA abarata el boleto, no mejora la probabilidad de premio.
4. **Los juegos virales decaen brutalmente.** Grow a Garden (pico 22,3 M, ago-2025) marca ~16.000 jugadores en un tracker de octubre 2026; Steal a Brainrot (pico ~24-25 M, sep/oct-2025) ~121.000 [F32][F22]. Son instantáneas (hora del día influye), pero el orden de magnitud es 99,5-99,9 % por debajo del pico. La ventana de "fast follower" es de semanas: Steal An Egg se creó el 25-jul-2026 y fue #1 de la plataforma en septiembre [F22].
5. **Reglas que condicionan el diseño:** probabilidades publicadas para cualquier objeto aleatorio de pago [F19]; elegibilidad Kids/Select por umbral de jugadores verificados [F20]; Roblox prohíbe a cuentas Kids/Select los juegos con feed multimedia + scroll infinito/autoplay + recompensa por seguir viendo (agosto 2026) [F21].
6. **Benchmarks (GameAnalytics 2026, vía resúmenes secundarios):** mediana D1 10,3 % / D7 1,6 % / D30 0,5 % en juegos con >=1 M MAU; ojo, es una muestra de supervivientes [F13]. Cifras de blogs que dan D1 "bueno" = 20-30 % usan otras definiciones y no sirven para kill criteria sin calibrar con tus propios datos.
7. **Top 3 conceptos por riesgo/recompensa (sección 8):** (A) Fish & Fortune (pesca idle-colección), (B) Rumble Rotation (party de minijuegos con cadencia semanal), (C) Plot Defenders (tower defense co-op con unidades originales). Co-op horror y "Steal a X" quedan como apuestas de mayor varianza.
8. **Límites de esta investigación:** create.roblox.com, devforum.roblox.com, about.roblox.com, sec.gov, gameanalytics.com y otros dieron ENOTFOUND con WebFetch (probado una vez por dominio, sin insistir ni esquivar el proxy). El presupuesto compartido de WebSearch se agotó antes de poder cubrir todo (ver sección 9). Gran parte de lo "oficial" lo vi solo como extracto del buscador.

---

## 1. Metodología y leyenda de etiquetas

| Etiqueta | Significado |
|---|---|
| **[OFICIAL]** | Roblox (docs de Creator Hub, newsroom, relaciones con inversores/SEC, anuncios de DevForum de staff). **[OFICIAL‡]** = no pude abrir la página (host bloqueado); solo vi el extracto/resumen del buscador. Hay que re-verificar el texto antes de decidir algo caro. |
| **[TERCERO]** | Prensa, analítica o blogs independientes. Puede citar datos oficiales o estimar. |
| **[NO VERIFICADO]** | Una sola fuente débil, fuente comercial con interés (vendedores de promoción), cifras contradictorias o sin metodología. |
| **[IDEA PROPIA]** | Diseño, heurística, umbral o cálculo mío. No es dato de mercado. |

Cada ID [Fn] remite a la tabla de fuentes del final (con fecha cuando la conozco). Las fechas de las páginas oficiales de docs no las pude confirmar (marcadas "s/f").

---

## 2. Contexto de plataforma (octubre 2026)

| Dato | Valor | Etiqueta / Fuente |
|---|---|---|
| DAU Q2-2026 | 123 M (+10 % interanual); 132 M en Q1-2026; pico 151,5 M en Q3-2025 | [TERCERO] [F12]; origen: carta Q2-2026 [F10] |
| Causas citadas de la caída desde el pico | Verificación de edad obligatoria para chat (desde ene-2026), bloqueo en Rusia (dic-2025) | [TERCERO] [F12] |
| Bookings Q2-2026 | +8 % interanual (extremo bajo de la guía); menor monetización por hora, sobre todo menores de 13 años en EE. UU./Canadá; migración de juegos virales de alta monetización de 2025 a juegos nuevos/evergreen de menor monetización; el cambio de "Recommended For You" hacia retención "compuso" el efecto | [OFICIAL‡] [F10] (vía resumen de búsqueda) |
| Guía Q3-2026 | Bookings 1.580-1.650 M USD, -14 % a -18 % interanual; la debilidad de monetización seguiría | [NO VERIFICADO] resumen de transcripción [F11]; verificar en la carta oficial |
| Guía año completo 2026 | Bookings 7.330-7.600 M USD (+8 % a +12 %) | [OFICIAL‡] [F10] |
| Pagos a creadores | ~1.700 M USD en 12 meses hasta 30-jun-2026 (~+50 % interanual); >5.000 M USD desde 2013 | [TERCERO] [F24] (datos de Roblox en RDC) |
| Distribución | Top 10: 65,7 M USD de media; top 100: 10,8 M; top 1.000: 1,4 M; mediana >42.000 creadores DevEx: ~1.500 USD | [TERCERO] [F24] |
| Cuentas por edad | Roblox Kids (5-8) y Select (9-15); verificación de edad; etiquetas de madurez deciden quién ve el juego | [OFICIAL‡] [F20], abr-2026 |
| Wallet (pago en USD cada día hábil) | Solo creadores independientes de EE. UU. mayores de 18, "más adelante en 2026"; tarjeta en 2027 | [TERCERO] [F23][F25] (detalles como periodo de retención de hasta 30 días: [NO VERIFICADO]) |
| RDC 2026 (11-sep-2026) | Navegador sin instalación (fin de 2026), apps independientes "Roblox Everywhere" (acceso temprano pronto, amplio mediados de 2027), modo offline (mediados de 2027), NPC que prueban juegos, Scene Generator, herramientas de IA, anuncios de vídeo omitibles en pantallas de carga | [TERCERO] [F23] (nota de prensa oficial en IR sin abrir) |

**Implicación para el portafolio [IDEA PROPIA]:** hay que asumir menor ARPDAU que en 2025 (sobre todo menores de 13) y apuntar a juegos con retención larga. Diseñar para 13+ cuando el género lo permita (más gasto por usuario), cumpliendo etiquetas de madurez.

---

## 3. Cómo funciona el descubrimiento

### 3.1 El motor de recomendación (Home / "Recommended For You")

| Elemento | Qué dicen las fuentes | Etiqueta / Fuente |
|---|---|---|
| Arquitectura | Dos etapas: (1) selección de un subconjunto de juegos que cada usuario podría disfrutar según engagement, retención y monetización; (2) ranking | [OFICIAL‡] [F1][F2] |
| "Qualified play" | Filtra clics accidentales y rebotes rápidos | [OFICIAL‡] [F1] |
| Ventana temporal | Pasó de 7 a 28 días; tramos Día 1, Días 2-7, Días 8-28. Lanzamiento ~15-jun-2026 según Dubit | [OFICIAL‡] [F3][F4]; fecha [TERCERO] [F6] |
| Señales listadas en el anuncio de DevForum | Tiempo jugado, días de juego, sesiones de juego calificadas, días de co-juego intencional, días de gasto, Robux gastados (cada una en los tres tramos) | [OFICIAL‡] [F4] |
| Jerarquía de importancia | Dubit: el "play-through rate" es lo más importante; "first-play bounce" (abandono tras sesión corta) es señal negativa. Otro blog dice lo contrario sobre el qualified play-through. No pude resolver la contradicción | [TERCERO] [F6][F7] / [NO VERIFICADO] |
| Monetización vs. retención | Juegos fuertes solo en una de las dos siguen recibiendo impresiones; fuertes en ambas pueden recibir distribución más amplia | [OFICIAL‡] [F2] |
| Otros factores | Actualizaciones del juego, total de visitantes a Home y rendimiento de competidores cambian las impresiones | [OFICIAL‡] [F2] |
| Reparto por edad | El ranking recomienda juegos más cortos a menores y más profundos/recurrentes a mayores | [TERCERO] [F23] |
| Señal de "crecimiento directo" | En prueba: premiar a juegos que traen jugadores totalmente nuevos a la plataforma. Es un test, no un cambio confirmado | [TERCERO] [F23] |
| Caída de impresiones en pruebas | Un desarrollador reportó caídas del 70-80 % en pruebas de abril. Roblox no lo confirmó | [NO VERIFICADO] [F7] |

### 3.2 Charts y "Sorts"

- Existen listas no personalizadas basadas en estadísticas (Top Trending, Up-and-Coming, Top Playing Now...). El anuncio de Discover de 2024 indica que son iguales para todos [OFICIAL‡] [F31]. Un wiki de fans cuenta 29 sorts [TERCERO] [F31].
- Las fórmulas exactas de Charts no son públicas. Quien publique porcentajes de peso por factor: [NO VERIFICADO] [F31].
- Los desarrolladores se quejan de que "Up-and-Coming" incluye juegos que no son nuevos [TERCERO] [F31].

### 3.3 Qué significa para el diseño (inferencia mía a partir de las señales oficiales) [IDEA PROPIA]

| Señal oficial | Mecánica de diseño que la alimenta |
|---|---|
| Días de juego (D2-7, D8-28) | Recompensa diaria con racha, cultivos/huevos con temporizador de 4-24 h, eventos de 7-30 días |
| Sesiones calificadas | Primera recompensa antes de 60 s; objetivo claro en la primera pantalla |
| Co-juego intencional | Bonus por jugar en grupo, invitar amigos, misiones cooperativas, servidores privados baratos, "join friend" sin fricción |
| Días de gasto | Ofertas pequeñas y recurrentes (diarias/semanales), pase de temporada, suscripción, no solo un pase único caro |
| Robux gastados | Escalera de precios con sumideros de moneda y coleccionables que justifiquen gasto repetido |
| Rebote en primera sesión (negativa) | Tutorial corto, sin muros de carga, rendimiento correcto en móvil, ícono/miniatura fieles al juego (nada de clickbait) |

### 3.4 Ícono, miniatura y título

- **Evidencia sólida:** casi ninguna. No encontré guía oficial específica sobre íconos/miniaturas. Lo oficial es que el algoritmo mide el "qualified play" después del clic [F1] y, según Dubit, penaliza el rebote tras la primera sesión [F6]: una miniatura engañosa puede generar clics pero también rebote. Un blog sostiene que los íconos no afectan directamente al ranking de búsqueda, sin verificar [F35].
- **Consejos recurrentes en blogs (todos [TERCERO]/[NO VERIFICADO]):** el ícono se ve a ~110x110 px en móvil, así que un solo sujeto y alto contraste; texto solo si se lee pequeño; mostrar gameplay real mejor que arte genérico/IA; A/B test del ícono con el panel de analítica [F35][F31]. Las cifras tipo "+40 % de CTR" de páginas sin autoría: [NO VERIFICADO].
- **Medidas:** icono 512x512, miniatura 1920x1080 (16:9) según un blog: [NO VERIFICADO], confirmar en Creator Hub.
- **Práctica propia [IDEA PROPIA]:** 3 variantes de ícono por juego, rotadas durante las pruebas con anuncios; título corto con la palabra del género y el gancho ("Fish & Fortune: Atrapa el Mítico"); nada de nombres de marcas ajenas.

### 3.5 Sponsored Ads (Ads Manager): costes y ROI

| Dato | Valor | Etiqueta / Fuente |
|---|---|---|
| Financiación | Créditos de anuncio; **1 crédito = 263 Robux**; compra mínima 1 crédito; usuarios 13+ pueden convertir Robux | [OFICIAL‡] [F16] |
| Mecánica | Subasta por presupuesto diario; objetivo "Plays" tiene mayor coste por play (CPP) | [OFICIAL‡] [F16] |
| Tendencia de precio | El 8-K del Q4-2025 dice que tras el rediseño de Ads Manager el coste por play bajó >40 % frente al Q1-2025; la publicidad aún es "modesta" para Roblox | [OFICIAL‡] [F17] |
| Coste por visita | 4-12 Robux por visita (estimación de desarrolladores en DevForum vía RoWatcher); obby/tycoon en el extremo alto | [TERCERO] [F15] |
| Benchmarks comerciales | CTR medio 1,2 %, CPC 0,25 USD, coste por play 0,45 USD (BLOXG, mar-2026, 850+ juegos promocionados) | [NO VERIFICADO] (vendedor de promoción) [F14] |
| Presupuesto de prueba | 10-20 USD/día durante 3-5 días (guía) o 15-25 USD/día 2+ semanas (DevForum) | [NO VERIFICADO] [F14][F15] |
| Umbral de retención citado | Un comentarista de DevForum sugiere D7 >=20 % mínimo y >=35 % para crecer. Contradice las medianas de GameAnalytics (D7 1,6 %); definiciones distintas | [NO VERIFICADO] [F15] |
| Anuncios inmersivos/rewarded para el creador | Baja tasa de relleno y eCPM muy bajo según comunidad (~4 anuncios cada 100 visitas, ~0,05 USD por 1.000 visitas) | [NO VERIFICADO] [F18][F15] |

**Aritmética de equilibrio (mía) [IDEA PROPIA]:** para que un anuncio se pague solo, necesitas `ingreso bruto por visita x cuota del creador >= CPV`. Si la cuota del creador es ~70 % (supuesto [NO VERIFICADO]; verificar la comisión vigente) el ARPPU requerido (Robux por pagador en la ventana medida) es:

| Conversión a pagador (sobre visitas) | CPV 4 R$ | CPV 7 R$ | CPV 12 R$ |
|---|---|---|---|
| 1 % | 571 | 1.000 | 1.714 |
| 2 % | 286 | 500 | 857 |
| 4 % | 143 | 250 | 429 |

El ejemplo de RoWatcher (2 % de conversión, ARPPU 80 Robux = 1,6 Robux/visita) pierde dinero en cualquier CPV de la tabla [F15]. **Conclusión:** para un portafolio pequeño, los anuncios sirven para **comprar muestra y señales** (D1, D7, sesión), no para rentabilizar de inmediato. Solo escalar anuncios cuando el ingreso a 7 días por visitante nuevo supere el CPV.

### 3.6 Códigos de redención, grupos, redes sociales y creadores

| Palanca | Qué se sabe | Etiqueta / Fuente | Recomendación [IDEA PROPIA] |
|---|---|---|---|
| Códigos | Los vídeos de "códigos y secretos" rinden ~320K vistas de media en YouTube (informe de tendencias) | [TERCERO] [F30] | Códigos validados en servidor, con caducidad y límite de canjes, que dan boosts (no moneda masiva) y se lanzan con cada evento; sirven para reactivar jugadores latentes |
| Creadores de YouTube/TikTok | YouTube = descubrimiento sostenido; TikTok = picos rápidos y cortos. Se estima que 35-45 % de sesiones nuevas en juegos >10.000 CCU vienen de una interacción con creador (dato "interno" sin publicar) | [TERCERO] / [NO VERIFICADO] [F30] | Mecánicas "clipables" (momentos raros, anuncios globales de drops, jefe final) y kit para creadores (códigos exclusivos, servidor VIP) |
| Tratos pagados a creadores | Categoría "creciendo ~150 % interanual" según un informe | [NO VERIFICADO] [F30] | Empezar con micro-creadores y canje de código/pase, no pagos fijos |
| Casos | Steal a Brainrot ganó decenas de millones de visualizaciones en TikTok/YouTube (Wikipedia, sin atribuir a un creador concreto) | [TERCERO] [F32] | |
| Grupos y "unirse para recompensa" | Sin datos fiables en mis búsquedas | [NO VERIFICADO] | Revisar la política vigente sobre incentivos por seguir/unirse antes de usar |
| Colaboraciones | Dead Rails se analiza como mezcla de formato familiar + giro novedoso + influencers + algoritmo (marco "MAYA", Hit Makers) [F32] | [TERCERO] | Copiar la estructura "familiar con un giro", no el contenido |

---

## 4. Principios de diseño que retienen y monetizan

### 4.1 Primeros 60 segundos (FTUE)

**Base oficial [OFICIAL‡] [F27]:** FTUE = primeros minutos; medir con el embudo de jugadores y D1; tutorial corto o tooltips contextuales; no tutoriales largos; que sea visual; dar un "momento de alegría" al completar por primera vez el bucle central; seguir convenciones del género y de la UI de Roblox; no poner barreras que impidan unirse a amigos; A/B test de pasos del tutorial.

**Guion de 60 s [IDEA PROPIA]:**

| Segundo | Evento |
|---|---|
| 0-5 | Aparecer ya jugando, objetivo visible con flecha/marcador. Cero menús previos |
| 5-20 | Primera acción central (pescar, recoger, golpear) con recompensa inmediata (sonido, número, partículas) |
| 20-40 | Primera compra con moneda blanda: el jugador "siente" el poder (mejor caña/arma) |
| 40-60 | Primer "reveal" raro (huevo/captura/jefe) y siguiente objetivo visible (barra de progreso a la siguiente zona) |
| 3-10 min | Primera oferta de monetización leve (booster 15 min, 25-49 R$), nunca antes de haber dado valor |

### 4.2 Resto de principios

| Principio | Qué hacer | Evidencia |
|---|---|---|
| Bucles cortos | Ciclo de 20-60 s con recompensa; macro-ciclo de 5-10 min con mejora; meta-ciclo diario | [IDEA PROPIA] + las sesiones largas se correlacionan con retención (GA 2025: D1 de 4,3 % en juegos de 0-3 min vs 6,2 % en 4-6 min) [F13] |
| Progresión / rebirth | Cada rebirth da multiplicador permanente y desbloquea contenido, con coste creciente (Ride A Pet: rebirth exige sacrificar una mascota única, coste que sube y mejora permanente) | [TERCERO] [F32] ejemplo; diseño [IDEA PROPIA] |
| Coleccionables y RNG | Mutaciones con multiplicadores (ejemplo: Ride A Pet: Oro 10 % x2, Diamante 1 % x3, Arcoíris 0,1 % x10) | [TERCERO] [F32] |
| **Cumplimiento de odds** | Si vendes con Robux (directa o indirectamente, p. ej. comprar una semilla y plantarla) objetos aleatorios, **debes listar todos los resultados con su probabilidad numérica real**, en porcentaje, sumando 100 %; si hay muchos, tras un botón claro "Info/Detalles" (no basta un icono (i) sin etiqueta). Incluye potenciadores de suerte y sistemas de pity | [OFICIAL‡] [F19] |
| Social / trading | Intercambio de mascotas, regalos, servidores amigos; señal "co-juego intencional" en el algoritmo | [OFICIAL‡] [F4]; trading [IDEA PROPIA] |
| Eventos limitados | Los mejores eventos duran 7-30 días; máximo 10 eventos activos/próximos publicables | [OFICIAL‡] [F28] |
| Cadencia de updates | Las guías discrepan: "semanal/quincenal con drops mensuales" frente a "pequeñas cada 2-4 semanas y grandes cada 2-3 meses" (atribuida a Roblox por un blog) | [TERCERO] [F28]; no confirmado |
| Códigos | Ver 3.6 | |
| Leaderboards | Rankings por profundidad/captura/semana con reinicio semanal y premios cosméticos | [IDEA PROPIA] |
| Offline / auto-farm | Ingresos mientras no juegas (Ride A Pet: las mascotas colocadas pagan incluso offline), con tope de acumulación para que el regreso diario compense | [TERCERO] [F32]; tope [IDEA PROPIA] |
| Mascotas | Compañeros con stats y rareza; slots de mascotas como producto | [IDEA PROPIA] |
| Anti-patrón nuevo | Feed multimedia con autoplay/scroll infinito y recompensa por seguir viéndolo: vetado para cuentas Kids/Select [F21] | [TERCERO] |

### 4.3 Diseño de menú de monetización (patrón recurrente) [IDEA PROPIA]

- **Escalera de precios (R$):** 25 / 49 / 99 / 199 / 499 / 999 para productos; pases de 199-799. Son puntos de partida a testear, no datos de mercado.
- **Cinco capas:** (1) comodidad (auto-collect, 2x velocidad), (2) poder (boosts, armas), (3) coleccionismo (cajas con odds publicadas), (4) estatus (cosméticos, VIP, títulos), (5) recurrente (pase de temporada, oferta diaria, suscripción).
- **Primera compra:** pack de inicio de 99-199 R$ visible tras la primera progresión, con valor claramente > precio.
- **Ética y reputación:** evitar presión sobre menores (cuentas Kids/Select) y mecánicas casi de apuesta; revisar la política de Roblox sobre apuestas/azar [NO VERIFICADO: solo verifiqué la norma de objetos aleatorios de pago].

---

## 5. Tendencias de géneros 2026 y ciclo de vida

### 5.1 Estado por género (snapshot oct-2026)

| Género / formato | Evidencia | Estado [IDEA PROPIA] | Etiqueta / Fuente |
|---|---|---|---|
| "Steal a X" / robo y defensa de base | Steal a Brainrot (pico ~24-25 M); Steal An Egg: creado 25-jul-2026, #1 en sep-2026 (1,6-2,1 M según tracker), ~950 K el 16-oct-2026. Cifras de pico de 14 M en algunos trackers contradicen otras: no fiable | **Caliente pero hacinado**; ventana de fast follower ≈ 4-6 semanas | [TERCERO] [F22][F32]; picos [NO VERIFICADO] |
| Brainrot (tema) | Líder en CCU entre títulos rastreados (1,4 M CCU) según una fuente sin identificar | Meme envejece rápido; IP ajena es riesgo | [NO VERIFICADO] [F34] |
| Idle-grow / "cozy" (Grow a Garden) | Pico 22,3 M (ago-2025); ~16.000 en tracker de oct-2026 | **Saturado/decaído**; el formato sigue vivo en variantes (mascotas) | [TERCERO] [F32] |
| Simulador de mascotas con montura (Ride A Pet) | Top 5 en sep-2026 (~208-256 K) | **Activo** | [TERCERO] [F22] |
| Tower defense (Plants vs Brainrots) | Pico ~9 M a finales de 2025 y ha caído; creada por el estudio de Grow a Garden | Formato probado, pico de meme pasado | [TERCERO] [F32] |
| Co-op horror/supervivencia | 99 Nights in the Forest: pico 14,2 M, 26 B+ visitas, aún entre los más jugados (cifras de CCU 2026 contradictorias: 355-442 K vs 2,16 M en un tracker); Dead Rails ~33 K (ago-2026) | **Crecimiento sostenido, coste de producción alto** | [TERCERO] [F32] |
| Anime fighting / RPG | Blox Fruits ~245 K (sep-2026); Slayers 2 presente; una fuente lo llama "género de mayor crecimiento" | Evergreen con incumbentes fuertes | [TERCERO] [F22]; "mayor crecimiento" [NO VERIFICADO] [F34] |
| Deportes (anime sports) | Volleyball Legends pico 30 d ~151,5 K; Blue Lock: Rivals ~148,7 K (15-oct-2026) | Nicho en alza, producción pesada (animaciones) | [TERCERO] [F32] |
| Roleplay / social | Brookhaven RP ~330-450 K CCU y ~82,5 B visitas históricas | Incumbente casi inatacable | [TERCERO] [F22][F32] |
| Obby / escape | "Escape" 763 K CCU agrupado según una fuente; conversión menor (obby 0,8 % vs simulador 4 %, estimación de calculadora) | Barato, monetiza poco | [NO VERIFICADO] [F34][F36] |
| Simuladores y tycoons | Descritos como los más rentables de forma fiable | Evergreen | [TERCERO] [F34] |

### 5.2 Modelo de ciclo de vida de un juego viral [IDEA PROPIA con datos TERCERO]

| Fase | Duración típica | Qué ocurre | Acción |
|---|---|---|---|
| 0. Semilla | Día 0-7 | Anuncios y creadores aportan primeras 1.000-5.000 visitas | Medir D1/sesión; arreglar FTUE |
| 1. Despegue | Semanas 1-6 | Si retención+gasto pasan, el algoritmo amplifica (Home, Up-and-Coming) | Actualización semanal; códigos; evento |
| 2. Pico | Semanas 4-12 | Máximo CCU; competencia de clones | Capturar valor: ofertas, pase, colaboraciones |
| 3. Decaimiento | Meses 3-12 | Caída del 90-99 % del pico en juegos de meme | Reducir coste, pasar a mantenimiento |
| 4. Cola larga | 12+ meses | Los grandes mantienen 100 K+ (p. ej. Steal a Brainrot ~121 K), los pequeños 1-5 % de su pico [IDEA PROPIA] | Eventos estacionales, mínimo mantenimiento |

Mi aritmética sobre instantáneas: 15.972/22.346.725 = 0,07 % (Grow a Garden); 121.345/24.136.040 = 0,50 % (Steal a Brainrot) [F32]. Son fotos de un instante, no medias diarias.

### 5.3 Reglas de fast follower [IDEA PROPIA]

1. Vigilar a diario Charts (Up-and-Coming, Top Trending) y trackers (Rolimons, RoVitals, LiveCounts).
2. Si un formato nuevo cruza ~100 K CCU en menos de 2 semanas, el reloj está corriendo: lanzar MVP en <= 10-14 días.
3. Copiar la **estructura** (loop, progresión, sumideros), no el nombre, personajes ni arte (riesgo IP/moderación). Añadir un giro propio (principio MAYA [F32]).
4. Presupuesto mínimo y kill rápido: si a 72 h D1 < 8 %, parar.
5. Excluir mecánicas de feed con recompensa por ver (norma ago-2026) [F21].

---

## 6. Estrategia de portafolio

### 6.1 Núcleo reutilizable ("game kit") [IDEA PROPIA]

| Módulo | Contenido |
|---|---|
| Datos | Perfil con DataStore, sesión segura, migraciones de esquema |
| Economía | Moneda blanda/dura, multiplicadores, temporizadores, offline con tope |
| Tienda | Pases, productos de desarrollador, boosts temporales, recibo idempotente, escaleras de precio configurables |
| Colección | Huevos/cajas con tabla de odds única que genera tanto la lógica del servidor como la UI de probabilidades (cumplimiento [F19]) |
| Progresión | Rebirth, niveles, desbloqueos por zona |
| Social | Invitar amigos, bonus de grupo, trading, servidores privados |
| Live-ops | Programador de eventos (7-30 días [F28]), códigos con caducidad, mensaje de bienvenida, rotación de tienda |
| Analítica | Eventos personalizados para embudo FTUE, D1/D7, ARPDAU, conversión; panel único |
| UI | Plantilla móvil-primero, botones grandes, localización ES/EN |
| Herramientas de IA | Generación de código/escenas con Studio Assistant/MCP; el estado de estas herramientas lo vi solo en un blog [F33] ([NO VERIFICADO]). RDC 2026 anunció herramientas de IA, Scene Generator y NPC de prueba [F23] |

### 6.2 Cadencia y presupuesto [IDEA PROPIA]

| Concepto | Propuesta |
|---|---|
| Ritmo de prototipos | 2-4 MVP/mes con kit maduro (1-3 semanas cada uno si se reutiliza ~70 % del kit) |
| Juegos "vivos" simultáneos | Máximo 3 en Tier A con actualización semanal; resto en Tier B (evento mensual automatizado) o Tier C (sin actualizaciones, sin anuncios) |
| Presupuesto de prueba por juego | ~5.000-10.000 Robux en anuncios (a 4-12 R$/visita = ~420-2.500 visitas) [aritmética mía sobre [F15]]; ajustar a lo que cueste en USD (1 crédito = 263 Robux [F16]) |
| Muestra mínima para decidir | D1 con n=500 visitas: IC 95 % ≈ ±2,6 pp si D1=10 %; con n=1.000 ±1,9 pp; D7 al 3 % necesita ~2.000 visitas para ±0,8 pp [aritmética mía, binomial] |
| Reinversión | Solo en juegos que pasen G2 (tabla 6.3); reservar 70 % de ingresos del juego ganador para actualizaciones/anuncios y no escalar anuncios hasta que ingreso 7 d por visitante > CPV |

### 6.3 Puertas y kill criteria [IDEA PROPIA, ancladas en datos de GameAnalytics [F13]; sin respaldo de datos públicos de "tasa de éxito"]

| Puerta | Cuándo | Muestra | Métrica | **Matar / pivotar** | Iterar | **Invertir** |
|---|---|---|---|---|---|---|
| G0 Playtest | Antes de publicar | 5-10 personas o NPC de prueba | Embudo FTUE | <70 % llega a la primera recompensa en <=60 s | 70-85 % | >85 % |
| G1 Anuncios | Días 1-4 | >=500-1.000 visitas | D1, sesión media, ratio ícono->visita | D1 <8 % **y** sesión <4 min tras 1 arreglo de 48 h | D1 8-15 % | D1 >=15 % (percentiles 75-90 de la muestra 2026 ≈ 12,9-15,9 %) |
| G2 Retención | Días 7-10 | >=1.000-2.000 visitas | D7; compradores | D7 <1,5 % (≈ mediana 1,6 %) | 1,5-3 % | D7 >=3 % y >=1 % de visitantes con compra |
| G3 Económica | Días 10-14 | Cohorte de G1/G2 | Ingreso bruto a 7 días por visitante vs CPV | Ingreso < CPV/2 | CPV/2 a CPV | Ingreso >= CPV: escalar anuncios |
| G4 Orgánico | Días 14-28 | CCU diario | Proporción de visitas orgánicas (Home); CCU | Orgánico <20 % y D7 <2 % | 20-30 % | Orgánico >=30 % y CCU pico >=500: pasar a Tier A |
| G5 Sostenibilidad | Día 28-60 | Retención D8-28 | Días de juego por usuario; ARPDAU | CCU cae >50 % sin updates y sin compradores | Estable | Tendencia creciente tras eventos |

Los umbrales de CCU (100/500/2.000) son heurísticas mías. **Calibrar con tus datos tras los 5-8 primeros juegos.** Advertencia: la mediana de GameAnalytics es de juegos con >=1 M MAU (supervivientes), así que un MVP promedio estará por debajo; la regla "D1 <8 % = matar" es deliberadamente más permisiva que la mediana para no descartar demasiado pronto.

### 6.4 Expectativas realistas

- Mediana de DevEx ≈ 1.500 USD/año; top 1.000 ≈ 82 % del total (mi cálculo) [F24]. No hay estadísticas públicas de "probabilidad de que un juego nuevo llegue a X CCU" que haya encontrado.
- Producir "slop" con IA es barato, pero Roblox premia la retención a 28 días y penaliza el rebote [F3][F6]; el contenido masivo sin diseño tenderá a quedarse sin distribución. No pude verificar políticas de contenido no original o de spam: **revisar Community Standards antes de publicar en masa** [NO VERIFICADO].
- Roblox ha eliminado/restringido juegos de IA tipo feed (agosto 2026) [F21]: la IA para producir está permitida de forma general; la IA como contenido consumido en bucle no lo está para menores.

---

## 7. KPI y benchmarks

| KPI | Valor | Etiqueta / Fuente | Comentario |
|---|---|---|---|
| D1 / D7 / D30 mediana (>=500 juegos, >=1 M MAU, ago-2025 a jul-2026) | 10,3 % / 1,6 % / 0,5 % | [TERCERO] resúmenes de GameAnalytics 2026 [F13] | Retención clásica; muestra de supervivientes |
| D1 por percentil | Objetivo realista: mediana a p75-p90 ≈ 10,3 % a 12,9-15,9 % | [TERCERO] [F13] | |
| D30: mediana vs p99 | 0,5 % vs 4,7 % | [TERCERO] [F13] | |
| 2025 por duración de sesión (0-3 min) | D1 4,31 %, D7 0,41 %, D30 0,13 % | [TERCERO] [F13] | GameAnalytics 2025 |
| 2025 por duración de sesión (4-6 min) | D1 6,20 %, D7 0,88 %, D30 0,28 % | [TERCERO] [F13] | |
| Sesión media por usuario/día | 2025: mediana 6,62 min; p25 2,4; p75 14,5; p90 26,4; p95 37,1. 2026: mediana 7,28 min (un resumen) o 9,8 min (otro); p90 14,7 min | [TERCERO] [F13] | Las cifras 2026 se contradicen; ámbito distinto |
| ARPPU (2026) | Mediana 0,70 USD; p90 2,33 USD; p99 55,31 USD | [TERCERO] [F13] | Periodo no aclarado en el resumen |
| % pagadores | 3,8 % (un resumen de GA 2026) | [NO VERIFICADO] [F13] | |
| Conversión a pagador | Típico 1-3 %, top ~8 %; simuladores 4,0 % vs obby 0,8 % | [NO VERIFICADO] [F36] | Denominadores distintos |
| Retención por género (BLOXG): simulador 32/14/6,2 %; RPG 35/16/7,8 %; obby 18/6/1,9 % | | [NO VERIFICADO] [F14] | 5-10 veces por encima de GA; no usar para decidir |
| Dispositivos (GA 2026) | PC+móvil 44 %; solo PC 40,76 %; solo móvil 11,55 %; solo consola 0,43 % | [TERCERO] [F13] | Muestra de juegos grandes; un creador afirma que la mayoría juega en móvil [NO VERIFICADO]. Diseñar móvil-primero igualmente |

**Por qué los números no coinciden:** distinto método (retención clásica vs rodante), distinta población (todos los visitantes vs jugadores que superan sesión calificada) y distinto tipo de fuente (blogs que venden promoción). Para decisiones, usa el panel oficial de analítica de tu propio juego y compara con tu propia línea base.

---

## 8. Diez conceptos de juego [IDEA PROPIA, todos]

Convenciones: precios en Robux (R$) son punto de partida de prueba. Todo objeto aleatorio de pago llevará tabla de probabilidades visible [F19]. Personajes y nombres originales (sin IP ajena). "Núcleo" = módulos de 6.1 que reutiliza. MVP = alcance recomendado en 1-3 semanas con IA.

### Resumen comparativo

| # | Concepto | Género | MVP | Riesgo/saturación | Techo de ingresos | Potencial de reutilización del kit |
|---|---|---|---|---|---|---|
| 1 | Fish & Fortune | Pesca idle + colección | 2 sem | Medio | Alto | Muy alto |
| 2 | Rumble Rotation | Party de minijuegos | 2-3 sem (+1 minijuego/semana) | Medio | Medio | Alto |
| 3 | Plot Defenders | Tower defense co-op | 3 sem | Medio-alto | Alto | Alto |
| 4 | Night Shift Cabin | Co-op horror/supervivencia | 3 sem | Alto | Muy alto | Medio |
| 5 | Raid the Museum | "Steal a X" fast follower | 1-1,5 sem | Muy alto | Muy alto (varianza) | Alto |
| 6 | Deep Dig Co-op | Minería idle cooperativa | 2 sem | Medio-alto | Medio-alto | Muy alto |
| 7 | Rise & Escape | Escape/obby con meta-progresión | 1-1,5 sem | Medio (monetiza poco) | Bajo-medio | Medio |
| 8 | Crowned Closet | Moda social con votación | 3 sem | Medio-alto | Medio | Bajo-medio |
| 9 | Brew & Bloom | Tycoon idle de tienda | 2 sem | Medio | Medio | Muy alto |
| 10 | Power Pals | Entrenamiento + combate con mascotas | 1,5-2 sem | Alto | Medio-alto | Muy alto |

### Concepto 1: Fish & Fortune

- **Pitch:** pesca relajante en lagos compartidos donde cada lanzada puede ser una criatura rara anunciada a todo el servidor.
- **Loop central:** lanzar (hold) -> minijuego de 3 s -> captura aleatoria -> vender o guardar en el bestiario -> mejorar caña/cebo -> zona nueva.
- **Progresión:** 6 zonas (lago, río, costa, cueva, volcán, abismo); cañas por tier; rebirth "Mareas" con multiplicador permanente; bestiario con recompensas por completar; pesca automática desbloqueable.
- **Monetización:** Pase Auto-Pesca (299 R$); Pase 2x Dinero (249 R$); Pase Suerte+ permanente (399 R$, con efecto visible en la tabla de odds); boost Cebo de Suerte 15 min (29-49 R$, producto); Cañas premium cosméticas (199-799 R$); Pase de Temporada (399 R$) con pesca de evento; pack de inicio (99 R$); slots de inventario (99-199 R$); servidor privado (VIP, 199 R$).
- **Viral:** banner global "X pescó un MÍTICO" (momento clipable); bestiario compartible; códigos al llegar a hitos.
- **Riesgo/saturación:** Fisch-like existe (no verifiqué su estado actual) [NO VERIFICADO]; medio. Odds obligatorias [F19] y regular el "pity".
- **MVP:** 3 zonas, 25 criaturas, 5 cañas, venta, bestiario, 3 pases, banner global, 2 eventos, UI de odds.
- **Núcleo:** economía, colección, tienda, offline, eventos.

### Concepto 2: Rumble Rotation

- **Pitch:** 10-16 jugadores pasan por 3 minijuegos de 60-90 s por ronda; el más puntuado gana corona y cosméticos.
- **Loop central:** lobby -> minijuego A/B/C -> clasificación -> recompensa -> volver a la cola.
- **Progresión:** nivel de cuenta, coronas, ranking semanal, coleccionables cosméticos por temporada.
- **Monetización:** Pase de Temporada (399 R$) con 40 niveles; VIP (cosméticos, 2x XP, 449 R$); emotes y estelas (49-299 R$); revive/segunda oportunidad (29-49 R$ por uso, producto); paquete "Fiesta" para invitar a 3 amigos con bonus; packs de cofres cosméticos con odds publicadas (99-199 R$).
- **Viral:** juegos de grupos de amigos; los creadores juegan con la audiencia; cada semana un minijuego nuevo como "episodio".
- **Riesgo/saturación:** medio; depende de que cada minijuego sea divertido; no hay un solo "hit" que arrastre.
- **MVP:** 8 minijuegos simples, 1 mapa lobby, rotación, rankings, pase, cosméticos básicos.
- **Núcleo:** tienda, live-ops (rotación y eventos), social, analítica (comparar qué minijuego retiene).
- **Por qué encaja con 28 días:** semanas nuevas -> días de juego; co-juego intencional por diseño.

### Concepto 3: Plot Defenders

- **Pitch:** tower defense co-op de 1-4 jugadores con unidades originales (guardianes de un jardín mágico).
- **Loop central:** colocar unidades -> oleadas de 30 rondas -> jefe -> botín -> mejorar el equipo.
- **Progresión:** 4 mapas con dificultad escalada; 30 unidades; niveles de unidad; modo infinito con ranking.
- **Monetización:** Pase x2/x3 velocidad (199-399 R$); slots extra de equipo (99-199 R$ cada uno); Pase Auto-Skip (149 R$); cofres de unidades con odds (49-499 R$); unidad exclusiva por temporada (pase 399 R$); revive en jefe (49 R$).
- **Viral:** co-op, "rescate" en la última oleada, trading de unidades.
- **Riesgo/saturación:** Plants vs Brainrots tuvo un pico de ~9 M y cayó [F32]; sin meme, el género retiene mejor pero crece menos. Medio-alto.
- **MVP:** 1 mapa, 12 unidades, 20 oleadas, 1 jefe, cofre con odds, 2 pases.
- **Núcleo:** colección/odds, tienda, social, eventos.

### Concepto 4: Night Shift Cabin

- **Pitch:** 4 amigos sobreviven noches en una cabaña en un bosque con una criatura que cambia cada noche.
- **Loop central:** de día recolectar y fabricar -> de noche defender el fuego -> sobrevivir -> mejorar la cabaña.
- **Progresión:** noches desbloqueables; árbol de mejoras; clases (explorador, ingeniero, médico).
- **Monetización:** revive (49-99 R$); linternas y skins (99-499 R$); cofres de suministros con odds (49-199 R$); pase VIP (399 R$); pase de temporada con skin y criatura (399 R$); servidor privado (199 R$).
- **Viral:** el género es de YouTubers; momentos de susto clipables; co-juego (señal oficial [F4]).
- **Riesgo/saturación:** alto frente a 99 Nights in the Forest [F32]; etiqueta de madurez limita a Kids/Select [F20].
- **MVP:** 1 mapa, 1 criatura con 3 comportamientos, 5 noches, 10 objetos, ciclo día/noche, revive, 3 skins.
- **Núcleo:** economía, tienda, social; menos reutilización.

### Concepto 5: Raid the Museum (fast follower de "Steal a X")

- **Pitch:** coleccionas fósiles en tu museo; los demás intentan robarlos; defiéndelos con trampas.
- **Loop central:** excavar -> exponer -> ingresos pasivos -> robar/defender -> mejorar seguridad.
- **Progresión:** salas, vitrinas con multiplicador, rebirth "Gran Exposición".
- **Monetización:** pase 2x Ingresos (249 R$); candado de seguridad temporal (25-49 R$); trampas premium (99-299 R$); huevos de fósil con odds (49-199 R$); VIP (399 R$); pase de temporada.
- **Viral:** robos dramáticos, "me han robado el legendario", clips para TikTok.
- **Riesgo/saturación:** muy alto; la ventana de fast follower es de 4-6 semanas desde un hit [F22]. Evitar IP/nombres de Steal a Brainrot/Steal An Egg y mecánicas de feed con recompensa [F21]. Solo con presupuesto mínimo.
- **MVP:** 1 museo, 12 piezas, robo básico con puerta, 3 trampas, huevo con odds, 2 pases.
- **Núcleo:** economía, offline, colección, tienda.

### Concepto 6: Deep Dig Co-op

- **Pitch:** un pozo vertical compartido: cada jugador cava su columna y todos aportan a un "reactor" común.
- **Loop central:** cavar -> vender mineral -> mejorar pico -> bajar más -> hito cooperativo.
- **Progresión:** profundidad (leaderboard), picos, mochila, mascotas que cavan, rebirth.
- **Monetización:** auto-minado (299 R$); 2x ganancias (249 R$); mochila grande (99-299 R$); mascotas con odds (49-199 R$); picos cosméticos; boost cooperativo (49 R$).
- **Viral:** ranking de profundidad, hitos de servidor, "llegué a 1.000 m".
- **Riesgo/saturación:** minería ya vista, medio-alto; la capa cooperativa lo distingue.
- **MVP:** 1 mapa de columnas en bloques, 12 minerales, 8 picos, 6 mascotas, 2 pases.
- **Núcleo:** economía, colección, progresión.

### Concepto 7: Rise & Escape

- **Pitch:** escapar de una subida de lava/agua en niveles cortos y recuperar a amigos atrapados.
- **Loop central:** partida de 3-4 min -> monedas -> comprar equipo de escape -> mapa más difícil.
- **Progresión:** 5 biomas, equipo coleccionable (jetpack, ganchos), ranking de tiempo.
- **Monetización:** salto/revive (29-49 R$ producto); Pase VIP con estela (199 R$); trajes y estelas (49-299 R$); skip de nivel (49 R$); pase de temporada.
- **Viral:** rescate entre amigos; momentos al límite; fácil de entender en un clip.
- **Riesgo/saturación:** monetiza menos (obby ~0,8 % de conversión según estimación [F36], [NO VERIFICADO]); sesiones cortas pueden dar D7 bajo. Mitigar con meta-progresión.
- **MVP:** 3 mapas, 10 trajes, revive, ranking, 2 pases.
- **Núcleo:** tienda, eventos.

### Concepto 8: Crowned Closet

- **Pitch:** desfile de moda con temas y votación del público.
- **Loop central:** tema -> vestirte en 2 min -> pasarela -> votación -> premio.
- **Progresión:** nivel de estilista, colecciones de prendas por temporada, galería.
- **Monetización:** VIP (449 R$); packs de prendas (99-299 R$); cofres cosméticos con odds (49-199 R$); slots de outfit (99 R$); emotes y poses (49-149 R$).
- **Viral:** capturas de outfits para TikTok; temas semanales.
- **Riesgo/saturación:** incumbente (Dress to Impress; no verifiqué sus cifras) [NO VERIFICADO]; coste de assets alto; riesgo de IP/estilo de marca. Medio-alto.
- **MVP:** 150 prendas, 6 temas, pasarela, votación, VIP.
- **Núcleo:** tienda, colección, social.

### Concepto 9: Brew & Bloom

- **Pitch:** gestionas una tienda mágica de pociones: atiendes clientes, automatizas y expandes.
- **Loop central:** recoger ingredientes -> preparar -> vender -> contratar ayudantes -> ampliar.
- **Progresión:** 8 recetas, 5 zonas, rebirth "Franquicia", decoración.
- **Monetización:** auto-recolección (249 R$); 2x ganancias (249 R$); ayudantes premium (99-299 R$); decoración (49-199 R$); pase de temporada con ingredientes de evento; VIP (399 R$).
- **Viral:** visita a las tiendas de amigos; diseño compartible.
- **Riesgo/saturación:** medio; tycoon es evergreen.
- **MVP:** 1 tienda expandible, 6 recetas, 4 ayudantes, 3 pases.
- **Núcleo:** economía, offline, tienda, social.

### Concepto 10: Power Pals

- **Pitch:** entrenas con una mascota, luchas contra jefes y renaces con poder permanente (versión con IP propia del clásico "anime fighter").
- **Loop central:** entrenar -> pegar a sacos -> jefe -> botín -> eclosión -> rebirth.
- **Progresión:** mundos, rebirths, mascotas con mutaciones.
- **Monetización:** 2x/3x entrenamiento (199-399 R$); auto-entreno (299 R$); mascotas con odds (49-499 R$); slots de equipo; pase de temporada; VIP.
- **Viral:** poder visual, ranking de fuerza, trading de mascotas.
- **Riesgo/saturación:** alto (muchos clones) [F34]; evitar IP de anime ajena.
- **MVP:** 3 mundos, 9 mascotas, 5 jefes, rebirth, 3 pases.
- **Núcleo:** casi todo el kit.

### 8.1 Los 3 mejores por riesgo/recompensa y por qué

| Rango | Concepto | Razones | Qué podría salir mal |
|---|---|---|---|
| 1 | **Fish & Fortune** | Reúne las señales que el algoritmo premia: días de juego (temporizadores, eventos), días de gasto (cebos, pase), Robux gastados (cañas, suerte). Formato idle/colección es evergreen y los datos muestran que los sims de mascotas siguen en el top 5 [F22]. Reutiliza casi todo el kit; coste de arte bajo; offline y colección dan retención a D8-28. | Un incumbente de pesca con base; odds obligatorias; riesgo de "pay-to-win" percibido |
| 2 | **Rumble Rotation** | Menor coste marginal por actualización (1 minijuego/semana = el contenido de live-ops); co-juego intencional integrado [F4]; los vídeos y creadores amplifican partidas con amigos; no depende de un meme. | Techo de ingresos moderado; calidad de cada minijuego |
| 3 | **Plot Defenders** | Género con monetización probada (velocidad, slots, unidades) y mayor retención que el meme puro; co-op favorece el co-juego; el pico de Plants vs Brainrots (~9 M) muestra el techo si acierta [F32]. | Producción más cara; sin meme el crecimiento orgánico es más lento |

**Mención especial:** Night Shift Cabin tiene el techo más alto (99 Nights en 14,2 M [F32]) pero también la mayor competencia y coste; Raid the Museum es la apuesta de varianza para hacer solo si aparece una ventana de fast follower y con presupuesto casi cero.

**Aviso:** el ranking es mi juicio razonado con señales oficiales y datos de terceros débiles. No hay datos públicos de éxito por concepto.

---

## 9. Dudas abiertas y verificaciones pendientes

| Duda | Por qué importa | Cómo resolverla |
|---|---|---|
| Texto exacto del anuncio de DevForum 4684575 y la newsroom de junio de 2026 (señales y pesos) | Hay contradicción sobre "qualified play-through rate" vs "play-through + first-play bounce" [F6][F7] | Abrir create.roblox.com/docs/discovery y el hilo de DevForum desde un navegador normal |
| Carta Q2-2026 oficial: guía de Q3 (-14 % a -18 %) | Solo la tengo por resumen de transcripción [F11] | Revisar 8-K [F10] y la carta; el resultado de Q3-2026 aún no está publicado a 2026-10-20 |
| Tasa de DevEx vigente (0,0035 vs 0,0038 USD por Robux; tarifa de 0,0054 para 18+ en EE. UU.) | Afecta al cálculo de ROI de anuncios | [NO VERIFICADO] [F26]; confirmar en la página de DevEx |
| Comisión de plataforma real sobre ventas dentro de experiencias (supuse ~30 %) | Entra en la fórmula de equilibrio de anuncios | Revisar docs de monetización |
| Umbral Kids/Select: 250 vs 500 jugadas únicas verificadas en 60 días | Condiciona llegar a menores de 16 | [F20] muestra ambos valores; confirmar en el panel Audience Reach |
| Detalles de Creator Rewards (5 Robux por jugador activo/día, gasto >= 9,99 USD en 60 días, 10 min, primeros 3 juegos del día; 100 DAU durante 60 días) | Posible ingreso adicional por jugadores que gastan | [TERCERO]/[NO VERIFICADO] [F29]; confirmar en docs oficiales |
| Cifras de CCU actuales por género y el top-50 del 19-oct-2026 | No pude buscar más (límite de búsquedas) | Consultar Charts de Roblox, Rolimons, RoVitals, LiveCounts |
| Pico real de Steal An Egg (14 M vs ~2 M) | Los trackers discrepan | [NO VERIFICADO]; consultar trackers directamente |
| Políticas de apuestas/azar, contenido no original/spam y uso de IA en masa | Riesgo de moderación para publicar muchos juegos | Leer Community Standards y políticas de monetización |
| Datos duros de CPC/CPV en Ads Manager hoy | Solo hay estimaciones de terceros | Panel de Ads Manager con un presupuesto de prueba mínimo |
| Rendimiento real de Dress to Impress, Fisch, Volleyball Legends como referencia | No pude verificar su estado | Trackers |
| Genre-level D1/D7/ARPPU de GameAnalytics 2026 | Solo vi medianas globales | Descargar el informe completo (requiere acceso a gameanalytics.com) |
| Fecha de Q3-2026 de Roblox (resultados) | Podría cambiar la visión de monetización por hora | Seguir el calendario de relaciones con inversores |

**Limitaciones técnicas declaradas:** WebFetch devolvió ENOTFOUND para create.roblox.com, devforum.roblox.com, about.roblox.com, gameanalytics.com, sec.gov, wikipedia.org, massivelyop.com y studiokrew.com (una prueba por dominio; no se usó curl ni se esquivó el proxy). El presupuesto compartido de WebSearch se agotó tras 36 búsquedas ejecutadas por mí; las últimas cuatro (top-50 de hoy, tendencias de esta semana, deportes y IP "brainrot") no se ejecutaron.

---

## 10. Fuentes

| ID | Fuente | Tipo | Fecha | URL |
|---|---|---|---|---|
| F1 | Roblox Creator Hub - Discovery | OFICIAL‡ | s/f | https://create.roblox.com/docs/discovery |
| F2 | Roblox Creator Hub - Discovery FAQ | OFICIAL‡ | s/f | https://create.roblox.com/docs/discovery-faq |
| F3 | Roblox Newsroom - Optimizing Discovery | OFICIAL‡ | jun-2026 | https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox |
| F4 | DevForum - Recommended For You Algorithm Improvements That Better Value Long-Term Retention | OFICIAL‡ | 2026 (fecha exacta no confirmada) | https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575 |
| F5 | DevForum - Boost Your Discovery with the Improved Recommended For You Algorithm and Analytics for Creators (solo título) | OFICIAL‡ | 2025 (no confirmada) | https://devforum.roblox.com/t/boost-your-discovery-with-the-improved-recommended-for-you-algorithm-and-analytics-for-creators/3587441 |
| F6 | Dubit - What makes a new Roblox game take off | TERCERO | 2026 | https://dubit.io/library/what-makes-a-new-roblox-game-take-off |
| F7 | ZehnStudio26 - Recommended For You retention update | TERCERO/NO VERIFICADO | 2026 | https://zehn-studio26.com/news/recommended-for-you-retention-update/ |
| F8 | allthings.how - New Recommended For You algorithm | TERCERO | 2026 | https://allthings.how/robloxs-new-recommended-for-you-algorithm-rewards-games-that-keep-you-hooked/ |
| F9 | Endsights - Roblox rewriting its algorithm | TERCERO | 2026 | https://endsights.com/roblox-optimizing-discovery-how-great-games-reach-millions-of-players-on-roblox |
| F10 | Roblox IR - Q2 2026 results / 8-K ex99.1 | OFICIAL‡ | Q2-2026 | https://ir.roblox.com/news/news-details/2026/Roblox-Reports-Second-Quarter-2026-Financial-Results/default.aspx ; https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm |
| F11 | Yahoo Finance - transcripción Q2-2026 (resumen) | TERCERO | Q2-2026 | https://finance.yahoo.com/quote/RBLX/earnings/RBLX-Q2-2026-earnings_call-658551.html |
| F12 | SQ Magazine / Search Engine Land - estadísticas de Roblox | TERCERO | 2026 | https://sqmagazine.co.uk/roblox-statistics/ ; https://searchengineland.com/guide/roblox-users |
| F13 | GameAnalytics 2026 / 2025 Roblox Benchmark Report y resúmenes (RRQ World; gamedevreports) | TERCERO (informe primario no abierto) | 2025-2026 | https://www.gameanalytics.com/reports/2026-roblox-report ; https://www.gameanalytics.com/reports/2025-roblox-report ; https://blog.rrqworld.com/roblox-game-retention/ ; https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox |
| F14 | BLOXG - benchmarks de publicidad y retención | NO VERIFICADO (vendedor) | mar-2026 | https://bloxg.com/statistics/roblox-advertising-benchmarks ; https://bloxg.com/statistics/roblox-retention-benchmarks |
| F15 | RoWatcher - Roblox Ads in 2026 (break-even) | TERCERO | 2026 | https://rowatcher.com/news/roblox-ads-in-2026-the-break-even-math-small-devs-ignore |
| F16 | Creator Hub - Ads Manager / user advertisements | OFICIAL‡ | s/f | https://create.roblox.com/docs/production/promotion/sponsoring-experiences ; https://create.roblox.com/docs/production/promotion/user-advertisements |
| F17 | Roblox 8-K Q4-2025 shareholder letter | OFICIAL‡ | Q4-2025 | https://www.sec.gov/Archives/edgar/data/1315098/000131509826000009/ex991-q42025shareholder.htm |
| F18 | Outlook Respawn - Roblox ads face developer pushback | TERCERO | 2026 | https://respawn.outlookindia.com/gaming/gaming-news/roblox-ads-face-developer-pushback |
| F19 | Creator Hub - Paid random items | OFICIAL‡ | actualizada ago/oct-2026 según el buscador | https://create.roblox.com/docs/production/monetization/paid-random-items |
| F20 | Creator Hub - Kids and Select; Newsroom; TechCrunch | OFICIAL‡ / TERCERO | abr-2026 | https://create.roblox.com/docs/production/publishing/kids-and-select ; https://about.roblox.com/newsroom/2026/04/introducing-roblox-kids-and-select-accounts ; https://techcrunch.com/2026/04/13/roblox-introduces-kids-and-select-accounts-for-age-appropriate-access-to-games-and-chat/ ; https://create.roblox.com/docs/production/promotion/content-maturity |
| F21 | Norma anti-"doomscrolling" (TechSpot, TweakTown, MassivelyOP, Slashdot) | TERCERO | 27-29-ago-2026 | https://www.techspot.com/news/113630-roblox-cracking-down-games-reward-kids-doomscrolling.html ; https://www.tweaktown.com/news/113316/roblox-cracks-down-on-games-that-reward-players-for-doomscrolling/index.html ; https://massivelyop.com/2026/08/29/roblox-clamps-down-on-gen-ai-brainrot-scrolling-games-after-steal-an-egg-goes-viral/ ; https://games.slashdot.org/story/26/08/28/0027222/roblox-is-cracking-down-on-games-that-reward-kids-for-doomscrolling |
| F22 | Steal An Egg y rankings: Misfits (X), RoVitals, LiveCounts, StudioKrew (sep-2026), endgametools, Statroblox | TERCERO | jul-oct 2026 | https://x.com/MisfitsGG/status/2090785862632038706 ; https://rovitals.com/game/107778070777162 ; https://livecounts.nl/roblox-game-player-count/?id=107778070777162 ; https://studiokrew.com/blog/top-roblox-games-september-2026/ ; https://endgametools.com/en/roblox/news/roblox-most-popular-games ; https://statroblox.com/leaderboards/playing ; https://livecounts.nl/roblox-charts/ |
| F23 | RDC 2026: IR, Newsroom, PocketGamer.biz, PCGamesN | OFICIAL‡ / TERCERO | 11-sep-2026 | https://ir.roblox.com/news/news-details/2026/Roblox-Unveils-New-Ways-to-Play-Build-and-Grow-at-the-Roblox-Developers-Conference-RDC/default.aspx ; https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play ; https://www.pocketgamer.biz/roblox-unveils-new-play-creation-and-monetisation-tools-at-rdc-2026/ ; https://www.pcgamesn.com/roblox/rdc-2026 |
| F24 | Pagos a creadores (TweakTown, Dexerto, TechSpot, SAYS) | TERCERO | sep-2026 | https://www.tweaktown.com/news/113585/robloxs-top-10-creators-averaged-65-7-million-each-while-the-median-made-1-500-and-roblox-everywhere-is-the-fix/index.html ; https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/ ; https://www.techspot.com/news/113855-roblox-top-creators-making-65-million-year-while.html ; https://says.com/my/tech/roblox-creators-earn-1-7-billion-developer-payouts |
| F25 | Roblox Wallet (Outlook Respawn, Gamertag Mythras) | TERCERO/NO VERIFICADO | sep-2026 | https://respawn.outlookindia.com/gaming/gaming-news/roblox-is-changing-what-its-gaming-platform-can-be ; https://gamertagmythras.com/blog/roblox/roblox-rdc-2026-announcements |
| F26 | DevEx (RoWatcher; generalistprogrammer) | NO VERIFICADO | 2026 | https://rowatcher.com/news/roblox-devex-math-what-you-actually-take-home-in-2026 ; https://generalistprogrammer.com/tools/robux-to-usd/16000 |
| F27 | Creator Hub - Onboarding, Retention, Design for Roblox; creator-docs en GitHub | OFICIAL‡ | s/f | https://create.roblox.com/docs/production/game-design/onboarding ; https://create.roblox.com/docs/production/analytics/retention ; https://create.roblox.com/docs/production/game-design/design-for-roblox ; https://github.com/Roblox/creator-docs/blob/main/content/en-us/get-started/strategies.md |
| F28 | Creator Hub - Experience events; indg.vc live-ops; rolearn estacionalidad | OFICIAL‡ / TERCERO | s/f | https://create.roblox.com/docs/production/promotion/experience-events ; https://www.indg.vc/blog/how-to-build-a-roblox-live-ops-calendar-that-works ; https://rolearn.dev/insights/seasonal-trends-launch-timing/ |
| F29 | Creator Hub - Creator Rewards; rolearn monetización | OFICIAL‡ / TERCERO | s/f; programa sustituyó a Engagement-Based Payouts (24-jul-2025 según terceros) | https://create.roblox.com/docs/creator-rewards ; https://rolearn.dev/trend-reports/roblox-monetization-trends-devex-creator-rewards/ |
| F30 | rolearn - YouTube/TikTok y creadores; BLOXG growth | TERCERO/NO VERIFICADO | 2026 | https://rolearn.dev/trend-reports/roblox-youtube-tiktok-content-trends-2026/ ; https://rolearn.dev/trend-reports/roblox-content-creator-landscape-2026/ ; https://bloxg.com/statistics/roblox-growth-report |
| F31 | Charts/sorts: Fandom wiki, DevForum Enhanced Discover, rolearn | OFICIAL‡ / TERCERO | 2024-2026 | https://roblox.fandom.com/wiki/Charts ; https://devforum.roblox.com/t/testing-an-enhanced-discover-page-top-charts-and-new-sorts/2954676 ; https://rolearn.dev/insights/roblox-game-discovery-algorithm-2026/ |
| F32 | Juegos referencia: Steal a Brainrot (RTC X, PocketGamer.biz), Grow a Garden (Wikipedia), 99 Nights (games.gg), Plants vs Brainrots (games.gg), Dead Rails (GameAnalytics), Ride A Pet (allthings.how), deportes (Adellion) | TERCERO | 2025-2026 | https://x.com/Roblox_RTC/status/1966948186653863995 ; https://www.pocketgamer.biz/robloxs-steal-a-brainrot-becomes-first-game-to-surpass-25m-concurrent-players/ ; https://en.wikipedia.org/wiki/Grow_a_Garden ; https://games.gg/news/99-nights-forest-14-million-roblox/ ; https://games.gg/news/plants-vs-brainrots-roblox-viral-hit/ ; https://gameanalytics.com/blog/dead-rails-and-the-hit-makers-formula ; https://allthings.how/ride-a-pet-on-roblox-how-to-play-full-guide/ ; https://adellion.com/roblox-sports-games |
| F33 | Sorceress - herramientas de IA para Roblox Studio 2026 | NO VERIFICADO | 2026 | https://sorceress.games/blog/stack-the-best-ai-for-roblox-game-development-studio-2026 |
| F34 | Tendencias de géneros (game-ace, kitsblox, creation.dev) | TERCERO/NO VERIFICADO | 2026 | https://game-ace.com/blog/roblox-trends-in-gaming/ ; https://kitsblox.com/blog/popular-roblox-game-genres-2026 ; https://www.creation.dev/learn/best-roblox-game-ideas-2026 |
| F35 | Miniaturas/íconos (RoWatcher, rolearn) | NO VERIFICADO | 2026 | https://rowatcher.com/news/why-your-roblox-thumbnail-works-on-desktop-and-fails-on-mobile ; https://rolearn.dev/insights/roblox-game-discovery-algorithm-2026/ |
| F36 | Conversión a pagador (Calculators Universe; glosario ZehnStudio26) | NO VERIFICADO | 2026 | https://calculatorsuniverse.com/blog/roblox-game-revenue-genre-conversion-explained ; https://zehn-studio26.com/glossary/conversion-rate/ |
