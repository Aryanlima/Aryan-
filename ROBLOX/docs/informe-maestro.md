# Informe maestro: juegos de Roblox con microtransacciones e IA

Para: Aryan. Fecha de los datos: 2026-10-20. Base: los informes 01 a 07 de `../research/` (y 08/09 sobre ropa, ver sección 9).
Este documento resume y decide; no repite las investigaciones. Cada dato lleva su etiqueta y un enlace al informe de origen.

## 0. Cómo leer este documento

| Etiqueta | Significa |
|---|---|
| **[OFICIAL]** | Leído en la documentación oficial de Roblox (repositorio `Roblox/creator-docs`) o ya verificado ahí por el equipo. |
| **[TERCERO]** | Prensa, blogs, trackers, o un resumen de una página oficial que no se pudo abrir. Es una pista con fuente, no una verdad. |
| **[NO VERIFICADO]** | Una sola fuente débil, fuentes que se contradicen, o conocimiento general sin comprobar. No decidir dinero con esto. |
| **[IDEA PROPIA]** | Decisión, heurística o cálculo nuestro. Hereda la incertidumbre de los datos de partida. |

Glosario mínimo: **DevEx** = el programa que convierte Robux ganados en dinero real. **Robux ganados** = lo que te queda de cada venta (70 %). **CCU / DAU** = jugadores a la vez / jugadores distintos por día. **D1, D7, D28** = % de jugadores nuevos que vuelven al día 1, 7, 28. **RPV** = Robux por visita. **Odds** = probabilidades publicadas de un premio aleatorio.

Enlaces: `[02 §2.1]` significa informe 02, sección 2.1. Las definiciones están al final del archivo.

---

## 1. Veredicto honesto (lectura de 1 minuto)

1. **Esto es una lotería de boletos baratos, no un plan de ingresos.** La IA abarata el boleto (menos horas y menos dinero por juego), pero **no mejora la probabilidad de ganar**. [IDEA PROPIA] apoyada en [01 §1][r01], [02 §6][r02] y [07 §0][r07].
2. **Planifica para el caso "mediana o menos".** La mediana de los creadores que ya cobran es de unos 1.500 USD **al año**, y el 1 % de arriba se lleva casi todo (sección 2). [TERCERO]
3. **Si un juego despega, caerá.** Los virales pierden 90 a 99 % de su pico en semanas o meses (sección 2). Hay que cobrar mientras suben y no vivir de eso. [TERCERO]
4. **Comprar visitas casi seguro pierde dinero.** Cada visita comprada cuesta más (unos 4 a 12 Robux) de lo que suele dejar (0,5 a 2 Robux por visita). Los anuncios sirven para medir, no para ganar. [TERCERO] + cálculo [IDEA PROPIA], sección 2.4.
5. **Lo que sí está en nuestras manos:** retención a 28 días, gasto pequeño y recurrente, jugar con amigos, eventos con calendario fijo, marketing con clips reales y mejorar rápido con datos (sección 3). [OFICIAL/TERCERO según fila]
6. **Recomendación: seguir, pero como experimento de 90 días con puertas de parada** (matar, iterar o invertir) y con un tope de pérdida que decidas tú. Ver [plan-90-dias.md](plan-90-dias.md) y [preguntas-para-aryan.md](preguntas-para-aryan.md).
7. **Lo urgente es administrativo, no técnico:** el formulario fiscal **W-8BEN antes del 31-oct-2026** (11 días). Si no, puede aplicarse hasta 24 % de retención sobre todo el pago desde el 1-nov. [OFICIAL] ([03 §5.4][r03]).
8. **Primer juego: Fish & Fortune** (pesca idle y colección). Segundo y tercero: Rumble Rotation y Plot Defenders. No hacemos 100 juegos: Roblox lo encarece y lo castiga (sección 4).

---

## 2. Expectativas realistas (con números)

### 2.1 Quién cobra qué (12 meses hasta 30-jun-2026)

| Dato | Valor | Etiqueta | Fuente |
|---|---|---|---|
| Pagado por DevEx a creadores | ~1.700 M USD (+~50 % interanual) | [TERCERO] (prensa que retransmite datos de Roblox) | [01 §2][r01], [02 §4.2][r02] |
| Creadores en DevEx | más de 42.000 | [TERCERO] | [02 §4.2][r02] |
| **Mediana** | **~1.500 USD al año** (≈125 USD/mes, sumando todos sus juegos). Año anterior: 1.440 USD | [TERCERO] | [02 §4.2][r02] |
| Top 10 (media cada uno) | 65,7 M USD (≈39 % del total) | [TERCERO] + cálculo [IDEA PROPIA] | [01 §2][r01] |
| Top 100 (media) | 10,8 M USD | [TERCERO] | [01 §2][r01] |
| **Top 1.000 (media)** | 1,3 a 1,4 M USD: **≈ 76 a 82 % del total** (82 % con 1,4 M) | [TERCERO] + cálculo [IDEA PROPIA] | [01 §2][r01], [02 §4.2][r02] |
| Quién entra en la mediana | Solo quienes ya superan el mínimo de cobro (30.000 Robux ganados). Los que no llegan no cuentan, así que **la mediana de "alguien que empieza" es más baja** | [IDEA PROPIA] (lectura del dato) | [02 §4.2][r02] |

No existe una estadística pública de "probabilidad de que un juego nuevo llegue a X jugadores". [07 §6.4][r07]

### 2.2 Los virales caen casi siempre

| Juego | Pico | Hoy (instantánea) | Caída aprox. | Etiqueta |
|---|---|---|---|---|
| Steal a Brainrot | ~25,4 a 25,8 M CCU (oct-2025) | ~111 a 129 mil (oct-2026) | ≈ -99,5 % | [TERCERO] + cálculo propio |
| 99 Nights in the Forest | 14,15 M (oct-2025) | ~187 mil (media reciente) | ≈ -98,7 % | [TERCERO] |
| Escape Tsunami for Brainrots | ~5 M (ene-2026) | ~164 mil | ≈ -97 % | [TERCERO] |
| +1 Speed Keyboard Escape | 7,26 M (jul-2026) | ~358 mil (20-ago) | ≈ -95 % en ~1 mes | [TERCERO] |
| Steal An Egg | 14,29 M según un tracker (hay otro que dice ~2 M) | 0,8 a 1,2 M (oct) | ≈ -92 a -94 % en ~4 semanas | [NO VERIFICADO] (trackers se contradicen) |

Todo son fotos de un instante (la hora del día mueve la cifra 2 a 3 veces), así que la caída está algo exagerada, pero el orden de magnitud es real. [01 §6][r01], [07 §5.2][r07]. Los juegos longevos (Adopt Me, Brookhaven, Murder Mystery 2, Blox Fruits, Dress to Impress) mantienen 100 a 700 mil CCU durante años: **la base estable vale más que el pico**. [TERCERO] [01 §6][r01]

### 2.3 Cuánto deja cada venta y cuánto hay que vender

Fórmula: dólares cobrados = Robux que paga el jugador × 0,70 × tarifa DevEx. Tarifa estándar **0,0038 USD por Robux ganado** (antes del 5-sep-2025: 0,0035). Tarifa **0,0054 solo** para el gasto de jugadores de EE. UU. de 18+ con edad verificada, en juegos elegibles. Mínimo para cobrar: **30.000 Robux ganados (≈ 114 USD)**. [OFICIAL] ([02 §2.1-2.2][r02], [03 §5.2][r03]).

| Precio al jugador (Robux) | Cobras, tarifa estándar | Cobras, EE. UU. 18+ verificado |
|---:|---:|---:|
| 49 | 0,13 USD | 0,19 USD |
| 99 | 0,26 USD | 0,37 USD |
| 199 | 0,53 USD | 0,75 USD |
| 499 | 1,33 USD | 1,89 USD |
| 999 | 2,66 USD | 3,78 USD |
| 1.999 | 5,32 USD | 7,56 USD |

(Cálculo [IDEA PROPIA] sobre datos [OFICIAL]; antes de impuestos y de comisiones de cobro: Tipalti 1,9 a 3 % si conviertes moneda. [03 §5.2][r03])

Para **cobrar el primer pago** hacen falta ~42.900 Robux de gasto de jugadores (30.000 / 0,70). Para otros objetivos (referencias de RPV de calculadoras: [TERCERO] débil):

| Quieres cobrar al mes | Robux de gasto necesarios | Visitas/mes si RPV = 0,5 | Visitas/mes si RPV = 2,0 |
|---:|---:|---:|---:|
| 100 USD | ≈ 37.600 | ≈ 75.000 | ≈ 19.000 |
| 500 USD | ≈ 188.000 | ≈ 376.000 | ≈ 94.000 |
| 2.000 USD | ≈ 752.000 | ≈ 1,5 M | ≈ 376.000 |

([02 §4.4][r02], cálculo [IDEA PROPIA]). Orden de magnitud de plataforma: con la monetización **media** de Roblox, 1.000 jugadores diarios rendirían ≈ 970 USD/mes; un juego pequeño real rendirá menos, porque la media la tiran hacia arriba los gigantes. [02 §4.4][r02] [IDEA PROPIA]

### 2.4 Por qué los anuncios son para medir y no para ganar

| Pieza | Valor | Etiqueta |
|---|---|---|
| Coste de una visita comprada | 4 a 12 Robux (estimación de desarrolladores) | [TERCERO] ([07 §3.5][r07]) |
| Lo que deja una visita (RPV) | 0,5 (referencia comunitaria) a 2 (simulador agresivo); techo de gacha ~6 | [TERCERO] débil ([02 §4.3][r02]) |
| Lo que te queda de cada Robux gastado | 70 % | [OFICIAL] |
| Para empatar con 4 R$ por visita hace falta RPV ≈ 5,7; con 12 R$, ≈ 17 | | [IDEA PROPIA] (4 / 0,7 y 12 / 0,7) |

Conclusión: salvo que un juego tenga una monetización excepcional, **comprar tráfico pierde dinero**. El presupuesto de anuncios se usa solo para comprar una muestra y medir retención y gasto; se escala únicamente cuando el ingreso a 7 días por visitante supera el coste por visita. [07 §3.5][r07]

### 2.5 El viento en contra de la plataforma

| Dato | Valor | Etiqueta | Fuente |
|---|---|---|---|
| DAU | 123 M (T2-2026), por debajo del máximo de ~152 M (T3-2025) | [TERCERO] (vía prensa y resúmenes del 8-K) | [01 §2][r01] |
| Bookings T2-2026 | +8 %; guía T3-2026 de **-14 % a -18 %** interanual | [TERCERO] | [01 §2][r01], [02 §4.1][r02] |
| Causa que da la dirección | Menos monetización por hora (sobre todo menores de EE. UU./Canadá) y algoritmo que premia retención antes que gasto | [TERCERO] | [02 §1][r02] |
| Resultados T3-2026 | Se publican el **29-oct-2026** (dentro de 9 días): vigilar | [TERCERO] | [01 §2][r01] |
| Presión legal por menores y gasto | Al menos 10 fiscalías estatales de EE. UU. han demandado a Roblox (cifras varían: 10 u 11) | [TERCERO] | [03 §7][r03] |

Implicación: asumir **menos gasto por jugador que en 2025** y diseñar para retención larga y para jugadores de 13+ cuando el género lo permita. [07 §2][r07] [IDEA PROPIA]

---

## 3. Qué SÍ mueve la probabilidad

| Palanca | Evidencia | Cómo la usamos | Etiqueta |
|---|---|---|---|
| **Retención a 28 días** | Desde jun-2026 "Recomendado para ti" mide Día 1, Días 2-7 y Días 8-28 (minutos jugados, días de juego, sesiones calificadas, co-juego, días de gasto, Robux gastados). Rebote en la primera sesión es señal negativa | Primera recompensa antes de 60 s, tutorial corto, recompensa diaria con racha, temporizadores de 4 a 24 h, eventos de 7 a 30 días | [TERCERO] (extractos de páginas oficiales no abiertas) [07 §3.1-3.3][r07] |
| **Gasto recurrente (no una sola compra grande)** | "Días de gasto" y "Robux gastados" puntúan en los tres tramos. Los juegos fuertes en retención **y** monetización reciben más distribución | Ofertas pequeñas y recurrentes, pase de temporada, suscripción VIP, escalera de precios | [TERCERO] [07 §3.3][r07] |
| **Co-juego (jugar con amigos)** | Señal explícita en el algoritmo | Bonus por jugar en grupo, misiones cooperativas, "unirse a un amigo" sin fricción, servidor privado barato | [TERCERO] [07 §3.1][r07] |
| **Cadencia de eventos** | Pet Simulator 99 actualiza cada sábado; Tower Defense Simulator cada 1 a 2 semanas; los mejores eventos duran 7 a 30 días | Sistema de eventos **configurable por datos** (no un desarrollo nuevo por evento); `ConfigService` para activarlos sin republicar | [TERCERO] [01 §6][r01], [06 §6.3][r06] |
| **Marketing y creadores** | Streamers y YouTubers están detrás de casi todos los hits recientes. Un dato "interno" habla de 35 a 45 % de sesiones nuevas desde creadores en juegos grandes | Mecánicas "clipables" (captura rara, anuncio global), códigos, micro-creadores a cambio de código o servidor VIP, no pagos fijos | [TERCERO] / [NO VERIFICADO] la cifra [07 §3.6][r07] |
| **Socios con audiencia** | Grow a Garden: creador del prototipo + estudio con audiencia y operaciones | Valorar un socio con audiencia (pregunta 13 de [preguntas-para-aryan.md](preguntas-para-aryan.md)) | [TERCERO] [01 §7][r01] |
| **Iteración rápida con datos propios** | Mercado que cambia en semanas (Steal An Egg: 56 días hasta el pico) | Kit reutilizable (datos, compras, tienda, eventos, analítica), puertas G0 a G5, A/B con `Experiments` (útil solo con volumen: por debajo de ~1.000 DAU puede no haber significancia) | [OFICIAL] el A/B [06 §7.3][r06]; el resto [IDEA PROPIA] |
| **Monetizar por hora, no solo ganar horas** | Roblox lo señala como causa de su caída de bookings | Público 13+ y adultos de EE. UU. (18 a 34 crece ~40 a 50 % y gasta >50 % más que menores) con avatar R15 para optar a 0,0054 | [TERCERO] [02 §4.1][r02]; la tarifa [OFICIAL] |
| **Honestidad de tienda** | Roblox exige descuentos reales, temporizadores reales, lenguaje neutro. Una tienda agresiva daña retención y descubrimiento | Ver sección 4 | [OFICIAL] [03 §2.3][r03] |

**Lo que la IA sí cambia:** más prototipos por hora, texto y código más baratos, balance y análisis más rápidos. **Lo que no cambia:** que el juego sea divertido, que Roblox lo recomiende, que un creador lo quiera enseñar. [IDEA PROPIA]

---

## 4. Qué evitar

| Tema | Regla o hecho | Consecuencia | Etiqueta | Fuente |
|---|---|---|---|---|
| **Spam de clones** | Tope de **5 juegos nuevos por día**. Los juegos con título, miniatura y archivos casi idénticos a otros **no se priorizan** en recomendaciones. Metadatos repetidos o con palabras irrelevantes pueden degradar el juego | Muchos juegos plantilla = sin tráfico. No es nuestro cuello de botella (haremos ~1 juego cada 4 a 6 semanas) pero sí un límite de diseño: cada juego con idea y giro propios | [OFICIAL] | [03 §6][r03] |
| Pases en juegos plantilla | Pases vendidos en juegos plantilla sin visitas legítimas **no cuentan** como Robux ganados para DevEx | Dinero que no se puede cobrar | [OFICIAL] | [03 §2.6][r03] |
| Varias cuentas para esquivar límites | La tarifa de publicación existe para dificultar cuentas masivas; no hay regla exacta leída | Riesgo claro de terminación | [NO VERIFICADO] (la regla exacta) | [03 §6][r03] |
| **Apuestas** (casino, coin flip, ruletas con objetos de valor) | "Experiences cannot contain playable gambling content, including simulated gambling" | Retirada del juego y posible sanción a la cuenta. Evitar también "crash" y "jackpot" (lectura nuestra) | [OFICIAL] la regla; la lista [NO VERIFICADO] | [03 §2.2][r03] |
| **Odds ocultas** | Todo objeto aleatorio comprado con Robux (directa o indirectamente: gemas, boosts de suerte, pity) exige mostrar **cada resultado con su probabilidad numérica (suma 100 %) antes de comprar**, ningún resultado sin valor, y `PolicyService` para bloquear o dar alternativa por país y edad (AU, BE, NL, UK, BR citados) | Juego retirado; riesgo legal | [OFICIAL] | [03 §2.1][r03] |
| **Urgencia falsa** | Descuentos reales; no decir "se acaba" si no es cierto; temporizadores exactos que **no se reinician**; para menores, lenguaje neutro ("Ver artículo", no "¡Cómpralo antes de que se acabe!") | Moderación y reputación. Además Iowa alega diseño que incentiva el gasto impulsivo de menores | [OFICIAL] regla; [TERCERO] demanda | [03 §2.3][r03], [03 §7][r03] |
| **Feed de vídeos con recompensa** | Desde ago-2026 se excluyen de Kids/Select los juegos con feed multimedia, autoplay o scroll infinito y recompensa por seguir mirando. Steal An Egg fue retirado unas horas | No lo hacemos | [TERCERO] | [01 §8][r01], [07 §5.3][r07] |
| Robux fuera de la plataforma | Vender, comprar o intercambiar Robux, objetos o cuentas por dinero real | Terminación de cuenta | [OFICIAL] | [03 §2.6][r03] |
| "Robux gratis" y anuncios de terceros | Prohibidos en anuncios; no se permiten redes publicitarias de terceros | Suspensión del juego o la cuenta | [OFICIAL] | [03 §2.5][r03] |
| URLs o Discord escritos dentro del juego | Las redes solo van en la página del juego (y exigen 16+ verificado) | Moderación | [OFICIAL] | [03 §2.6][r03] |
| IP ajena (marcas, personajes, memes con derechos, música) | Roblox retira el contenido aunque lo haya generado una IA | Retirada y, si se repite, cuenta | [OFICIAL] | [03 §4.2][r03] |
| IA visible sin supervisión | Con herramientas de IA de terceros **tú respondes** de todo lo que ven los jugadores. El estudio de Animal Hospital pidió disculpas por arte de IA | Daño reputacional | [OFICIAL] la responsabilidad; [TERCERO] el caso | [03 §4.4][r03], [01 §8][r01] |
| Assets del Creator Store sin revisar | Pueden traer código oculto (`require(id)`, `loadstring`) | Cuenta en riesgo | [OFICIAL] | [03 §4.3][r03] |
| Música de IA (Suno/Udio) | Udio no permite descargas; Suno exige plan de pago y tiene litigios. Roblox exige derechos sobre todo audio | Eliminación del audio | [TERCERO] | [05 §0][r05] |
| Cuestionario de madurez inexacto | Información incorrecta puede llevar a moderar juego y cuenta. Hay que reenviarlo si cambia el juego | Cuenta en riesgo | [OFICIAL] | [03 §3.2][r03] |

---

## 5. Decisiones tomadas

Estado: **[IDEA PROPIA]** salvo donde se indica. Las marcadas "provisional" dependen de respuestas de Aryan.

| # | Decisión | Elegido | Descartado y por qué | Fuente |
|---|---|---|---|---|
| D1 | Modelo de portafolio | **Pocos juegos, en secuencia**: 1 juego, medir, decidir, siguiente. Máximo 3 "vivos" con actualización semanal | "Cientos de juegos": Roblox lo encarece (tarifa 1.000 Robux o Plus por juego, verificación, evaluación de ~250 jugadas) y lo castiga (casi idénticos sin prioridad) | [02 §6][r02], [03 §3.3, §6][r03], [07 §6.2][r07] |
| D2 | **Primer juego** | **Fish & Fortune** (pesca idle + colección, lagos compartidos, banner global cuando alguien pesca un mítico) | Raid the Museum ("Steal a X"): saturado y ventana de 4 a 6 semanas | [07 §8.1][r07] |
| D3 | **Segundo y tercer candidato** | **2º Rumble Rotation** (party de minijuegos, 1 minijuego nuevo por semana). **3º Plot Defenders** (tower defense co-op, unidades originales) | Night Shift Cabin (techo alto, mayor coste y competencia). Reserva barata: Deep Dig Co-op o Brew & Bloom (reutilizan casi todo el kit, pero cuidado: "casi idéntico" se castiga) | [07 §8.1][r07] |
| D4 | Código | **Luau puro `--!strict`**, archivos + Git, **Claude Code + MCP integrado de Studio + Rojo** (Script Sync como alternativa simple). Assistant de Studio solo para 3D, materiales, bocetos | roblox-ts (capa extra), Knit y TestEZ (archivados), pesde (esperar), DataStore2 | [04 §10][r04], [06 §3][r06] |
| D5 | Datos y compras | **ProfileStore**; un único `ProcessReceipt` idempotente (`PurchaseRouter`); `PolicyService` en un solo módulo; `ConfigService` para eventos; revisión humana de todo lo de dinero | Código de compras sin revisar (la IA falla aquí de forma sutil) | [04 §0][r04], [06 §1-2, §4][r06] |
| D6 | UI y analítica | React Lua para UI; Creator Analytics + `AnalyticsService` + API de consulta de analítica (panel único) | Fusion (no mezclar) | [06 §3, §7][r06] |
| D7 | Calidad automática | StyLua, Selene, luau-lsp, tests en Lune, CI en GitHub Actions + Open Cloud; universo de pruebas separado; publicar en producción solo con aprobación manual | Publicar directo desde CI | [04 §11][r04], [06 §4.3][r06] |
| D8 | Assets | Generación de Studio + Blender (mallas bajo 20.000 triángulos); audio del Creator Store; Meshy o Tripo **solo en plan de pago** y solo cuando haga falta | Hunyuan3D (prohibido en UE, Reino Unido y Corea del Sur: **depende de tu país**), Cube 3D abierto (solo investigación), Suno/Udio | [05 §0, §2, §10][r05] |
| D9 | Monetización de la v1 de F&F | Pack de inicio, 2x dinero, auto-pesca, slots, cosméticos, VIP mensual, pase de temporada. **Sin venta de "suerte" ni cajas con Robux en la v1** (provisional) | Vender suerte desde el día 1: obliga a odds dinámicas, `PolicyService` y alternativa por país; se añade en v1.1 cuando esté probado | [02 §7][r02], [03 §2.1][r03], [07 §8][r07] |
| D10 | Publicación | Activar Plus o Premium cuanto antes (la exención de la tarifa exige **2 meses seguidos**); si el 1.er lanzamiento llega antes, pagar la tarifa de 1.000 Robux (reembolsable) o lanzar solo para 16+ (provisional) | Lanzar sin decidir: por defecto un juego nuevo solo llega a 16+ verificados | [03 §3.3][r03], [02 §2.3][r02] |
| D11 | Público e idioma | Diseñar para 13+ y avatar R15 estándar (opta a 0,0054 si hay adultos de EE. UU.); sin chat libre ni "hangouts" para conservar etiqueta suave. Texto EN + ES; marketing según tus canales (provisional) | Público infantil como objetivo: es el que menos monetiza por hora y el más regulado | [03 §3.4][r03], [05 §7.3][r05], [07 §2][r07] |
| D12 | Cuenta | **Una sola cuenta o grupo** del creador, con 2FA, correo verificado y verificación de edad. Claves de Open Cloud: una por juego, permisos mínimos | Repartir juegos en varias cuentas | [03 §8][r03], [06 §4.3][r06] |
| D13 | Presupuesto | Herramientas 0 a 40 USD/mes al empezar; subir al stack de ~150 a 170 USD/mes solo si un juego pasa G2. Anuncios: tope que fijas tú (ver plan) | Stack caro desde el día 1 | [05 §10][r05] |

---

## 6. Hechos verificados vs dudas

### 6.1 Dinero y DevEx

| Hecho | Estado | Fuente |
|---|---|---|
| Tarifa estándar **0,0038 USD por Robux ganado** desde el 5-sep-2025 (antes 0,0035; lo ganado antes se cobra primero a 0,0035) | **[OFICIAL]** | [02 §2.2][r02], [03 §5.2][r03] |
| 0,0054 solo para gasto de jugadores de **EE. UU. 18+ verificados** en juegos elegibles (desde 8-jun-2026); no cubre ítems de avatar | **[OFICIAL]** | [02 §2.3][r02] |
| Detalle exacto de elegibilidad R15 para el 0,0054 (hay una contradicción interna entre páginas sobre el umbral de partes) | [NO VERIFICADO] | [03 §3.4][r03] |
| Reparto: el creador recibe 70 % de sus ventas propias; Roblox 30 % | **[OFICIAL]** | [02 §2.1][r02] |
| Mínimo **30.000 Robux ganados**; edad ≥ 13; correo verificado; formulario W-9/W-8 en archivo; solo cuentan Robux **ganados** | **[OFICIAL]** | [03 §5.2][r03] |
| Pago: revisión de ~10 días hábiles la primera vez y ~5 después (total ~5 a 10 días hábiles), más tiempo bancario (guías de terceros: 1 a 4 semanas) | [OFICIAL] la revisión; [TERCERO] el total | [02 §2.4][r02], [03 §5.2][r03] |
| Premium o Plus obligatorio para cobrar DevEx; mínimo de 100.000 Robux | **Descartado**: la documentación oficial no lo pide; son guías de terceros que contradicen a Roblox | [03 §5.2][r03] |
| ID gubernamental para DevEx general | [NO VERIFICADO] (sí se exige para Audience Expansion y acceso pagado en dinero real) | [02 §2.4][r02] |
| **Países donde está disponible DevEx** y método de cobro en países hispanohablantes | [NO VERIFICADO]. Roblox dice "más de cien países"; no se pudo abrir la lista | [03 §5.3][r03] |
| Tipalti descuenta comisión según método y 1,9 a 3 % si cambias moneda | [OFICIAL] | [03 §5.2][r03] |
| Los "Premium Payouts" ya no existen; hoy hay Creator Rewards (5 Robux por jugador activo con gasto reciente; captación exige ~100 DAU de media) | [OFICIAL] vía resumen | [02 §3][r02] |
| Anuncios con recompensa: hasta ~3 % de ingresos del creador al inicio (cifras de 5 a 15 % de terceros contradicen) | [OFICIAL] vía resumen / [NO VERIFICADO] las cifras altas | [02 §3][r02] |
| Venta de pases/productos **entre juegos** desactivada desde el 30-may-2026 | [OFICIAL] | [03 §2.4][r03] |
| Ropa 2D: el reparto para quien crea la prenda pasó de 70 % a ~30 % (jul-2026) y ~40 % al dueño de la experiencia donde se vende | [TERCERO]; matices [NO VERIFICADO] | [02 §2.3][r02] |

### 6.2 Impuestos

| Hecho | Estado | Fuente |
|---|---|---|
| **31-oct-2026** es el último día bajo los términos actuales; desde el **1-nov-2026** los pagos DevEx se clasifican como **regalías** | **[OFICIAL]** | [03 §5.4][r03] |
| No estadounidense: **W-8BEN** (persona) o **W-8BEN-E** (empresa) en Creator Hub > Finances > Taxes | **[OFICIAL]** | [03 §5.4][r03] |
| Retención de 0 a 30 % sobre la parte de fuente de EE. UU. (en general, compras de jugadores de EE. UU.) según país y convenio; con información válida y TIN | **[OFICIAL]** | [03 §5.4][r03] |
| Si falta información: **24 % de retención de respaldo** sobre todo el pago | **[OFICIAL]** | [03 §5.4][r03] |
| Guías de terceros que dicen "30 % por defecto" | Contradicen a la fuente oficial (24 %): usar 24 % | [03 §5.4][r03] |
| La retención depende de la fecha en que se **procesa** el pago, no de cuándo lo pediste | [TERCERO] | [03 §5.4][r03] |
| Qué tasa te toca según tu país, y cómo declarar el ingreso en tu país | [NO VERIFICADO]: depende de Aryan (pregunta 1) | [03 §9][r03] |
| El informe 02 marcaba el cambio del 1-nov como "no verificado" (una sola fuente) | **Resuelto por 03**: es oficial | [02 §2.4][r02] vs [03 §5.4][r03] |

### 6.3 Publicación y políticas

| Hecho | Estado | Fuente |
|---|---|---|
| Sin pagar tarifa (1.000 Robux por juego, reembolsable) ni mantener Plus o Premium **2 meses seguidos**, un juego nuevo solo llega a usuarios de **16+** con edad verificada | [OFICIAL] | [03 §3.3][r03] |
| Roblox Plus cuesta 4,99 USD/mes (lanzado el 30-abr-2026) | [OFICIAL] vía resumen | [02 §2.3][r02] |
| Para Kids (5-8) y Select (9-15): cuestionario, 2FA, verificación y **250 jugadas únicas de usuarios verificados en 60 días** (un blog dice 500) | [OFICIAL] 250 / [NO VERIFICADO] 500 | [03 §3.3][r03], [02 §2.3][r02] |
| Condiciones exactas de reembolso de la tarifa (25 jugadores muy comprometidos 60 días vs 90 días) | [NO VERIFICADO] (las páginas se contradicen) | [03 §3.3][r03] |
| Si hace falta Plus para *actualizar* (no solo publicar) juegos antiguos; si "Premium deja de venderse" | [NO VERIFICADO] | [02 §2.3][r02] |
| Máximo 5 juegos nuevos por día; casi idénticos sin prioridad | [OFICIAL] | [03 §6][r03] |
| El informe 01 daba la "penalización de clones" como dudosa (un solo blog) | **Resuelto**: la priorización de juegos únicos es oficial; las 4 demandas de Steal a Brainrot siguen [NO VERIFICADO] | [01 §8][r01] vs [03 §6][r03] |
| Cajas y azar de pago: **permitidos con reglas** (odds, `PolicyService`). El informe 02 lo daba como "no verificado" | **Resuelto por 03: [OFICIAL]** | [02 §5.4][r02] vs [03 §2.1][r03] |
| Texto exacto de los Términos de Uso del 1-nov-2026 | [NO VERIFICADO]: leer antes de esa fecha | [03 §9][r03] |
| Cuota de Roblox sobre las integraciones publicitarias en juegos (campañas desde el 1-ene-2027); no afecta a nuestras primeras semanas | [OFICIAL] (detalles aún por cerrar) | [03 §2.5][r03], [02 §3][r02] |

### 6.4 Plataforma, herramientas y benchmarks

| Hecho | Estado | Fuente |
|---|---|---|
| Benchmarks de retención de GameAnalytics 2026: D1 10,3 %, D7 1,6 %, D30 0,5 % (muestra de juegos grandes, supervivientes) | [TERCERO] | [02 §4.3][r02], [07 §7][r07] |
| Blogs que dan D1 20 a 35 % o D7 ≥ 20 % como "bueno" | [NO VERIFICADO] (definiciones distintas, vendedores de promoción); no usar para decidir | [07 §7][r07] |
| Coste por visita en anuncios (4 a 12 Robux) y mínimos de campaña (10 créditos en 2023, ~35 USD en un blog 2026, ninguno en la doc actual) | [TERCERO] / [NO VERIFICADO] el mínimo | [05 §7.2][r05], [07 §3.5][r07] |
| 1 crédito de anuncios = 263 Robux | [OFICIAL] vía resumen | [07 §3.5][r07] |
| Claves de Open Cloud: una por aplicación, permisos mínimos, se caducan tras 60 días sin uso | [OFICIAL] | [06 §4.3][r06] |
| La API de publicación no actualiza `SurfaceAppearance`, `EditableMesh`, `PartOperation`, etc. | [OFICIAL] | [04 §6.4][r04] |
| Luau Execution API (tests de motor en CI): estado y límites reales | [NO VERIFICADO] | [06 §4.3][r06] |
| Studio no corre de forma nativa en Linux (necesitas Windows o Mac) | [TERCERO] (guías Vinegar/Wine sin verificar) | [04 §11][r04] |
| Costes del Assistant de Studio y de `generate_mesh` | [NO VERIFICADO] (la doc no los publica) | [04 §12][r04] |
| **Nada del código de este repositorio se ha probado dentro de Roblox Studio** (sí con Lune y mocks) | Hecho propio | `CLAUDE.md` del repositorio |

---

## 7. Riesgos y mitigaciones

Probabilidad (P) e impacto (I): A = alta, M = media, B = baja. [IDEA PROPIA] salvo donde se cite.

| # | Riesgo | P | I | Mitigación | Quién |
|---|---|:-:|:-:|---|---|
| 1 | **Ningún juego llega a retener ni a cobrar** (el resultado "mediana o menos") | A | M | Experimento con tope de pérdida, puertas G0 a G5, kit reutilizable que ya amortiza el esfuerzo | Aryan decide el tope |
| 2 | Retención o ingresos bajan por la plataforma (bookings -14 a -18 %, más verificación de edad) | M | M | Diseño 13+, no depender de menores de 13; vigilar resultados del 29-oct | Claude vigila, Aryan lee |
| 3 | **Retención de impuestos 24 % o más** por no presentar el W-8BEN a tiempo | M | A | Presentarlo esta semana ([plan](plan-90-dias.md), semana 0) | Aryan |
| 4 | **DevEx no disponible en tu país** o método de cobro incómodo | N/D | A | Comprobarlo antes de invertir tiempo (pregunta 1) | Aryan |
| 5 | **Terminación de cuenta** (todo cuelga de una cuenta): IP, cuestionario falso, fraude de Robux, abuso de programas, assets sospechosos | B | Muy A | Assets propios o con licencia documentada, cuestionario fiel, 2FA, copias locales de cada `.rbxl`, nada de Robux fuera de Roblox | Ambos |
| 6 | Juegos "similares" sin tráfico; exposición reducida por baja calidad | A | M | Giro real por juego, metadatos y miniatura propios, lanzar espaciado | Claude |
| 7 | Alcance limitado a 16+ por no pagar tarifa/Plus | M | M | Decidir D10 antes del lanzamiento y verificar en Creator Hub | Aryan |
| 8 | Incumplir reglas de azar de pago (odds, `PolicyService`) | M | A | Sin azar pagado en v1; luego tabla de odds única que alimente lógica y UI; probar con Player Emulator (AU, BE, NL, UK, BR) | Claude |
| 9 | **Fallo en compras o datos** (cobros duplicados, ítems perdidos, datos borrados): destruye confianza y genera reembolsos | M | A | `ProcessReceipt` idempotente con tests, ProfileStore, revisión humana de cada cambio de dinero, universo de pruebas | Claude escribe, Aryan revisa/prueba |
| 10 | **Código sin probar en Studio** (solo hay pruebas con Lune y mocks) | A | M | Primer hito: abrir el juego en Studio y jugarlo (semana 1 a 2); playtest en móvil real | Aryan prueba |
| 11 | Exploits y trampas (clientes que mienten) | M | M | Servidor manda, validar todo, límites de frecuencia ([06 §5][r06]) | Claude |
| 12 | Cambios de política (Términos 1-nov-2026, anuncios 1-ene-2027, tarifas) | A | M | Revisar el DevForum una vez al mes; no depender de una sola palanca de ingreso | Ambos |
| 13 | Riesgo reputacional o legal por IA o IP (arte de IA visible, parecido con marcas, música) | M | M | Revisar cada imagen contra marcas conocidas, audio del Creator Store, no usar nombres ni memes con dueño | Ambos |
| 14 | Presión regulatoria por gasto de menores (demandas en EE. UU.) | M | M | Tienda sobria, sin urgencia falsa, límites de ofertas | Claude |
| 15 | Dependencia de herramientas (Sora cerrado, Udio sin descargas, MCP de terceros archivado) | M | B | No casar el pipeline con una sola herramienta cerrada; usar el MCP integrado | Claude |
| 16 | **Fuga de claves** (Open Cloud) o abuso del MCP de Studio (ejecuta código en tu lugar abierto) | B | A | Claves solo en variables de entorno o secretos de GitHub, una por juego y con permiso mínimo; MCP solo con clientes de confianza; guardar versión antes de cada tarea grande | Aryan crea, Claude cumple |
| 17 | Agotamiento: pocas horas semanales para tareas manuales (probar, grabar, publicar, responder) | A | M | Plan según tus horas (pregunta 9); automatizar lo demás | Aryan |
| 18 | Competencia directa: **Fisch** sigue vigente en oct-2026 ([01 §3][r01]); el informe 07 no verificó su estado | M | M | Diferenciar F&F: lagos compartidos, banner global, bestiario, giro co-op; vigilar sus datos en trackers | Claude |

---

## 8. Fechas que importan

| Fecha | Qué | Etiqueta | Fuente |
|---|---|---|---|
| **Sáb 31-oct-2026** | Último día para presentar W-8BEN con los términos actuales (hacerlo antes del miércoles 28 para tener margen) | [OFICIAL] | [03 §5.4][r03] |
| Jue 29-oct-2026 | Resultados T3-2026 de Roblox (confirma o no la guía de -14 a -18 %) | [TERCERO] | [01 §2][r01] |
| Dom 1-nov-2026 | Entran los Términos de Uso nuevos; los pagos DevEx pasan a regalías | [OFICIAL] | [03 §5.4, §2.6][r03] |
| 1-ene-2027 | Nuevo reparto/cuota en las integraciones publicitarias | [OFICIAL] | [03 §2.5][r03] |
| 18-ene-2027 | Día 90 del plan: revisión y decisión | [IDEA PROPIA] | [plan-90-dias.md](plan-90-dias.md) |

---

## 9. Juegos vs ropa

> **Pendiente de 08 y 09.** Los informes `08-ropa-vs-juegos.md` y `09-ropa-produccion-con-ia.md` no existían cuando se escribió este documento. Lo de abajo es un análisis provisional que solo usa lo que dicen 02 y 03. Se sustituirá al llegar 08/09.

| Aspecto | Juegos (lo que ya sabemos) | Ropa y avatar (solo con 02 y 03) |
|---|---|---|
| Qué se vende | Pases, productos, suscripciones dentro de tu juego | Prendas y accesorios en el Marketplace o dentro de tu experiencia |
| Reparto del creador | 70 % de las ventas propias, a 0,0038 USD por Robux (0,0054 con jugadores de EE. UU. 18+) [OFICIAL] | 3D: ~70 % pero vigente [NO VERIFICADO]. **2D: de 70 % a ~30 % para el creador de la prenda** desde jul-2026; ~40 % al dueño de la experiencia donde se vende; quien vende su propia ropa en su propio juego conserva ~70 % [TERCERO]. La tarifa 18+ **no** cubre ítems de avatar [OFICIAL] ([02 §2.3][r02]) |
| Requisitos del creador | 13+ para DevEx; W-8; cuenta en buen estado | Creator Store: 18+ (o 13 a 17 con consentimiento parental), 2FA, país soportado, cuenta individual [OFICIAL] ([03 §5.1][r03]) |
| Riesgo de IP | Alto con memes y marcas | Alto: logos y estilos de marca; las copias alteradas con IA pueden denunciarse [OFICIAL] ([03 §4.1][r03]) |
| Tiempo hasta saber si funciona | 4 a 8 semanas para pasar G2 | Pendiente de 08/09 |
| Concentración de ingresos | Extrema (top 1.000 ≈ 76 a 82 %) | Pendiente de 08/09 |
| Coste de producción con IA | Código y arte, semanas por juego | Pendiente de 08/09 |

Existe una herramienta de plantillas de ropa en `../tools/clothing-gen/` (en construcción por otro agente). Que exista no significa que la ropa sea mejor negocio: esa comparación es lo que debe resolver 08. [IDEA PROPIA]

**Regla provisional:** hasta tener 08/09 y la respuesta de Aryan (pregunta 11), el plan es **juegos primero**, porque es lo que ya está construido y medido por informes; la ropa se trata como línea secundaria.

---

## 10. Qué sigue

1. Aryan responde las preguntas urgentes de [preguntas-para-aryan.md](preguntas-para-aryan.md) (país, edad, cuenta, persona o empresa).
2. Aryan presenta el W-8BEN antes del 28-oct ([plan-90-dias.md](plan-90-dias.md), semana 0).
3. Claude y Aryan avanzan según el calendario de 12 semanas con puertas de parada.

---

## 11. Mapa de fuentes

| Tema | Informe |
|---|---|
| Mejores juegos, cifras, patrones virales y fracasos | [01 mejores juegos][r01] |
| Economía de creadores, tarifas, monetización, benchmarks | [02 monetización y economía][r02] |
| Políticas, edad, azar, impuestos, spam, demandas, checklist de lanzamiento | [03 políticas y cumplimiento][r03] |
| IA en Studio, MCP, skills, setup paso a paso | [04 IA, Studio, MCP][r04] |
| Herramientas de IA para arte, audio y marketing; stacks de coste | [05 IA para assets y marketing][r05] |
| Arquitectura técnica, compras, datos, CI, analítica | [06 stack técnico][r06] |
| Descubrimiento, diseño, portafolio, puertas, 10 conceptos | [07 diseño, crecimiento y conceptos][r07] |
| Ropa vs juegos y producción de ropa con IA | 08 y 09 (pendientes) |

[r01]: ../research/01-mejores-juegos.md
[r02]: ../research/02-monetizacion-y-economia.md
[r03]: ../research/03-politicas-y-cumplimiento.md
[r04]: ../research/04-ia-studio-mcp-skills.md
[r05]: ../research/05-ia-assets-y-marketing.md
[r06]: ../research/06-stack-tecnico.md
[r07]: ../research/07-diseno-crecimiento-y-conceptos.md
