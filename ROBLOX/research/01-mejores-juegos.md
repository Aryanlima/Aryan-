# 01 — Análisis de los mejores juegos de Roblox (2024 – oct. 2026)

**Fecha del informe:** 2026-10-20
**Objetivo:** entender qué juegos de Roblox han tenido más éxito, cómo ganan dinero, qué patrones comparten los virales y qué advertencias hay, para decidir cómo crear muchos juegos con microtransacciones y ayuda de IA.

---

## 0. Cómo leer este informe (metodología y límites)

**Limitaciones reales de esta investigación (importantes):**

1. Todos los hosts útiles estaban bloqueados (`WebFetch` falló con `ENOTFOUND` en livecounts.nl, studiokrew.com, bloxrant.com, sec.gov, pcgamer.com). Solo pude usar `WebSearch`, que devuelve resúmenes de páginas, no las páginas. No pude abrir ninguna fuente primaria (SEC, DevForum, create.roblox.com, Wikipedia). Los enlaces citados son los que devolvió el buscador; **los datos pueden contener errores de resumen**.
2. El presupuesto de búsquedas del turno (200, compartido entre agentes) se agotó tras unas 40 consultas. Quedaron **sin investigar** (ver sección 10): entrevistas primarias sobre cómo se hicieron virales (GamesBeat/Jandel, Andy Hall sobre Steal a Brainrot), Dead Rails, Forsaken, Dig, Blade Ball, Garden Tower Defense, Anime Vanguards/Defenders, Ink Game en detalle, y datos de retención (D1/D7) de cualquier juego.
3. **Roblox no publica ingresos por juego.** Toda cifra de ingresos por juego es una estimación modelada de terceros y las estimaciones se contradicen por 1–3 órdenes de magnitud.
4. Los contadores de jugadores simultáneos (CCU) oscilan 2–3x entre el valle y el pico del día, y cada tracker mide en momentos y con *place IDs* distintos. Un mismo juego aparece con cifras diferentes según la página.

**Leyenda de fiabilidad (se usa en todo el documento):**

| Etiqueta | Significado |
|---|---|
| **[OFICIAL]** | Lo publica Roblox, el desarrollador o un documento oficial (SEC, DevForum, docs). Si solo lo vi citado por prensa lo indico como "[OFICIAL, vía prensa]". |
| **[TERCERO]** | Tracker (Rolimons, RoWatcher, Profitable, etc.), medio de prensa, wiki de fans o análisis. Es un dato con fuente, pero no verificado por Roblox. |
| **[NO VERIFICADO]** | Un solo origen débil, fuentes contradictorias sin resolver, o conocimiento general mío que no pude confirmar en esta sesión. |
| **cálculo propio** | Operación aritmética mía sobre datos de terceros; hereda su incertidumbre. |

---

## 1. Resumen ejecutivo

1. **El mercado es de "ganador se lleva casi todo".** Según Roblox (12 meses hasta 30-jun-2026) los creadores cobraron ~**1.700 M$** por DevEx (+50 % interanual); el **top 10 promedió 65,7 M$ cada uno** (≈39 % del total), el top 100 10,8 M$, el top 1.000 1,4 M$, y el **creador mediano cobró ~1.500 $** (más de 42.000 creadores). [OFICIAL, vía prensa] ([Dexerto](https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/), [TweakTown](https://www.tweaktown.com/news/113585/robloxs-top-10-creators-averaged-dollars65-7-million-each-while-the-median-made-dollars1500-and-roblox-everywhere-is-the-fix/index.html), [TechSpot](https://www.techspot.com/news/113855-roblox-top-creators-making-65-million-year-while.html)).
2. **Los picos virales son enormes pero efímeros.** Steal a Brainrot pasó de ~25,4–25,8 M CCU (oct-2025) a ~111–129 mil (oct-2026): cerca de **-99,5 %** (cálculo propio). Los nuevos hits de 2026 tardan menos en llegar al pico (Steal An Egg: ~56 días desde el lanzamiento) y también caen más rápido.
3. **Los juegos "viejos" que siguen vigentes** (Brookhaven, Murder Mystery 2, Blox Fruits, Adopt Me, Dress to Impress, RIVALS) mantienen 100–700 mil CCU durante años gracias a eventos regulares, economías de trading/cosméticos y comunidad.
4. **Cadena de éxito 2026:** Escape Tsunami for Brainrots (dic-2025/ene-2026) → Animal Hospital (may-2026) → Grow a Garden 2 (12-jun-2026) → +1 Speed Keyboard Escape (pico 7,26 M, 18-jul-2026) → **Steal An Egg** (lanzado 25-jul-2026, pico ~14,3 M el 19-sep-2026), el hit del momento. 99 Nights in the Forest (pico 14,2 M en oct-2025) sigue siendo top-tier.
5. **Mismo patrón de diseño en casi todos:** loop de 30 segundos obvio (coleccionar/robar → ingreso pasivo → mejorar velocidad/capacidad), meme o IP reconocible en el título, eventos limitados, y trading/rareza.
6. **Estudios pequeños pueden ganar mucho:** un adolescente de 16 años creó la primera versión de Grow a Garden en "unos días"; 99 Nights la hizo un estudio de Nueva Zelanda; Dress to Impress la creó una adolescente (Gigi). Pero hay un sesgo de supervivencia gigantesco (mediana = 1.500 $/año).
7. **Riesgo de plataforma real:** Roblox bajó de 152 M DAU (T3-2025) a 123 M (T2-2026); las reservas (bookings) crecen solo 8 % y la guía de T3-2026 es **-14 % a -18 %**; la dirección atribuye esto a menor monetización por hora en usuarios jóvenes de EE. UU./Canadá y a un desplazamiento hacia juegos que monetizan menos. [OFICIAL, vía prensa]. Además, Roblox retiró Steal An Egg unas horas por su mecánica de "videos infinitos" y prohibió el diseño para menores (ago-2026).
8. **Clones saturados:** una estimación de un solo blog cuenta ~12.400 juegos "Brainrot" y ~3.300 clones "Steal a ___"; reporta que el descubrimiento de Roblox penaliza juegos muy parecidos y que los creadores de Steal a Brainrot presentaron al menos 4 demandas. [NO VERIFICADO] (un solo origen).

---

## 2. Contexto de plataforma (oct-2026)

| Dato | Valor | Etiqueta / Fuente |
|---|---|---|
| Bookings T2-2026 | ~1.600 M$, +8 % interanual (extremo bajo de la guía) | [OFICIAL, vía prensa] — [Investing.com transcripción](https://www.investing.com/news/transcripts/earnings-call-transcript-roblox-q2-2026-beats-eps-but-shares-sink-on-bookings-93CH-4826338), [Outlook](https://respawn.outlookindia.com/gaming/gaming-news/roblox-q2-2026-revenue-soars-36-to-15b-despite-bookings-miss); primaria: [SEC 8-K T2-2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) (no pude abrirla) |
| DAU | 123 M (+10 % a/a) pero **bajo desde el máximo de 152 M en T3-2025** | ídem |
| Horas jugadas | 29.000 M (+5 % a/a) vs 40.000 M en T3-2025 | ídem |
| Bookings por DAU | 12,66 $ (-2 %) | ídem |
| Pagadores únicos mensuales | 27 M (+15 %); gasto por pagador 19,25 $ | ídem |
| Guía T3-2026 | Bookings 1.580–1.650 M$ (**-14 % a -18 %**) | ídem; [TIKR](https://www.tikr.com/blog/roblox-stock-is-down-37-in-2026-heres-what-its-new-viral-hit-has-to-prove-on-october-29) |
| Causa que da la dirección | Menor monetización por hora, sobre todo en jóvenes de EE. UU./Canadá; el compromiso se desplazó a juegos que monetizan menos | [OFICIAL, vía prensa] ([Investing.com](https://www.investing.com/news/transcripts/earnings-call-transcript-roblox-q2-2026-beats-eps-but-shares-sink-on-bookings-93CH-4826338)) |
| Resultados T3-2026 | Se publican **29-oct-2026** tras el cierre (aún no disponibles hoy) | [TERCERO] [MarketBeat](https://www.marketbeat.com/earnings/reports/2026-10-29-roblox-corp-stock/) |
| Récord de CCU de la plataforma | 47,4 M (ago-2025, evento Grow a Garden vs Steal a Brainrot) | [TERCERO] [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot), [Tubefilter](https://www.tubefilter.com/2025/08/25/roblox-grow-garden-steal-brainrot-admin-war-record/amp/) |
| Pagos DevEx 12 m. a jun-2026 | ~1.700 M$ (+~50 %) | [OFICIAL, vía prensa] ([Dexerto](https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/)) |
| Concentración | Top 10: 65,7 M$ medio (antes 33,9 M$); top 100: 10,8 M$; top 1.000: 1,4 M$ (otra fuente: 1,3 M$); mediana ~1.500 $; >42.000 creadores | [OFICIAL, vía prensa] ([TechSpot](https://www.techspot.com/news/113855-roblox-top-creators-making-65-million-year-while.html), [IBTimes](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403)). Cálculo propio: top 1.000 × 1,4 M$ ≈ 1.400 M$ ≈ 82 % del total |
| Nueva tarifa DevEx "US 18+" | Desde 8-jun-2026, el gasto de jugadores de EE. UU. con edad verificada ≥18 años en juegos elegibles (R15) pasa de 26,6 % a 37,8 % (+42 %) para premiar juegos "novedosos" | [OFICIAL] ([DevForum](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091); solo vi el título y un resumen del buscador) |
| Tarifa DevEx base | Fuentes contradictorias: 0,0038 $/Robux (subida en sept-2025) vs 0,0035 $/Robux a inicios de 2026 | [TERCERO] ([TechTimes](https://www.techtimes.com/articles/326712/20260904/roblox-creator-economy-paid-444m-non-tech-communities-bookings-now-falling.htm)). Verificar en DevForum antes de proyectar |
| Política "doomscrolling" | Ago-2026: se excluyen de los catálogos *Roblox Kids* (5–8) y *Select* (9–15) los juegos con feed multimedia + autoplay/scroll infinito + recompensas por seguir mirando. Los anuncios con recompensa (rewarded video) no entran en la restricción | [TERCERO] ([TechSpot](https://www.techspot.com/news/113630-roblox-cracking-down-games-reward-kids-doomscrolling.html), [TweakTown](https://www.tweaktown.com/news/113316/roblox-cracks-down-on-games-that-reward-players-for-doomscrolling/index.html), [Kotaku](https://kotaku.com/roblox-cracks-down-on-doomscrolling-games-like-steal-an-egg-that-forces-players-to-watch-reels-while-running-on-a-treadmill-2000727952), [GamesRadar](https://www.gamesradar.com/games/simulation/roblox-takes-down-controversial-doomscrolling-game-promises-to-remove-others-that-reward-watching-a-continuous-feed-of-content-as-theyre-not-appropriate-for-younger-users/)) |
| Competencia | Google lanzó "Playground" (7-oct-2026), herramienta que convierte texto en juegos jugables | [TERCERO] ([TIKR](https://www.tikr.com/blog/roblox-stock-is-down-37-in-2026-heres-what-its-new-viral-hit-has-to-prove-on-october-29)) |

---

## 3. Qué está vigente en oct-2026 (instantáneas de CCU)

Los rankings en vivo **no coinciden** porque miden a horas distintas y con filtros distintos. Instantáneas encontradas:

| Fecha de la instantánea | Fuente | Lo que muestra |
|---|---|---|
| ~7-oct-2026 | [GGAID](https://www.ggaid.com/roblox/top-games) | Steal An Egg #1 con ~1,2 M |
| ~14-oct-2026 | [LevelUpPlay](https://levelupplay.my/charts/top-playing) | Adopt Me! #1 con ~233 mil (cifra incompatible con las demás; probable filtro/momento distinto) |
| ~18-oct-2026 | [Rokoala](https://rokoala.com/roblox-player-count/) | Steal An Egg #1 con ~925 mil; después Murder Mystery 2 y Brookhaven RP |
| oct-2026 | [BloxRant](https://bloxrant.com/roblox-top-earning-games) | Ranking de "top earning" de 7 días: Steal An Egg, Blox Fruits, RIVALS |
| oct-2026 | [RBLXSTAT](https://rblxstat.com/lists/top-rated-roblox-games) | Steal An Egg ~812 mil (filtrado por ≥85 % de votos positivos) |
| oct-2026 | [BloxGuides](https://bloxguidesgg.com/roblox-stats) | RIVALS ~315 mil; Dress to Impress ~409 mil |
| 20-ago-2026 | [StudioKrew agosto](https://studiokrew.com/blog/top-roblox-games-august-2026/) | MM2 538,7 mil; Animal Hospital 358,5 mil; +1 Speed Keyboard Escape 358,0 mil; Brookhaven 301,6 mil; Steal An Egg 281,7 mil; luego Blox Fruits y Grow a Garden 2 (otra página de StudioKrew da a MM2 192 mil: contradicción interna) |
| jul-2026 | [StudioKrew julio](https://studiokrew.com/blog/top-roblox-games-july-2026/) | MM2 545,9 mil; Brookhaven 525,9 mil; Grow a Garden 2 505,3 mil |

**Conclusión:** vigentes y fuertes en oct-2026: **Steal An Egg, Murder Mystery 2, Brookhaven RP, Blox Fruits, RIVALS, Dress to Impress, Adopt Me!, 99 Nights in the Forest, Fisch, Pet Simulator 99, Animal Hospital, +1 Speed Keyboard Escape**. En fuerte declive desde el pico: Steal a Brainrot, Grow a Garden (original y 2ª parte), Escape Tsunami for Brainrots, Plants vs Brainrots.

---

## 4. Ficha comparativa (≈20 juegos)

> Todos los picos y CCU son [TERCERO] salvo que se indique. "Pequeño/grande" es mi clasificación según lo que dicen las fuentes; ningún resultado dio plantillas exactas.

### 4.1 Identidad, fechas y cifras

| # | Juego | Género | Estudio (tamaño) | Lanzamiento | Pico CCU (fuente) | CCU reciente | Estado oct-2026 |
|---|---|---|---|---|---|---|---|
| 1 | **Steal An Egg** | Colección de mascotas + robo + "treadmill" de velocidad | Grupo "and Collect Rare Pets" (pequeño; sin equipo/entrevista localizada; una wiki de fans cita al dueño pero con baja fiabilidad) | 25-jul-2026 (Rolimons y LiveCounts; una wiki dice 20-ago: peso bajo) | 14.293.524 el 19-sep-2026 ([Rolimons](https://www.rolimons.com/game/107778070777162)); 13.790.561 el 26-sep ([LiveCounts](https://livecounts.nl/roblox-game-player-count/?id=107778070777162)); 14,2 M ([OtakuKart](https://otakukart.com/robloxs-steal-an-egg-reaches-6-billion-visits-and-14-2-million-peak-concurrent-players/)) | 0,8–1,6 M (7–18-oct) | **#1 actual**; visitas 8,8 mil M (Rolimons) vs 6 mil M (OtakuKart) |
| 2 | **99 Nights in the Forest** | Supervivencia/terror cooperativo | Grandma's Favourite Games (Nueva Zelanda; equipo pequeño liderado por Kieft; sin cifra de plantilla) | 2025 (fecha exacta no hallada) | 14.153.173 el 4-oct-2025 ([Rolimons](https://www.rolimons.com/game/79546208627805)); 14,2 M ([PC Gamer](https://www.pcgamer.com/games/survival-crafting/with-a-peak-player-count-of-14-2-million-99-nights-in-the-forest-has-an-audience-other-multiplayer-games-would-kill-for-to-find-these-behemoth-playerbases-you-need-to-be-on-a-platform-like-roblox/)) | ~187 mil de media reciente ([RoMonitor](https://romonitorstats.com/experience/79546208627805/)) | Vigente; 26 mil M de visitas (abr-2026) y adaptación cinematográfica anunciada con 20th Century Studios ([Wikipedia](https://en.wikipedia.org/wiki/List_of_Roblox_games)) |
| 3 | **Steal a Brainrot** | Robo/coleccionista de "brainrots" con ingreso pasivo | DoBig Studios y SpyderSammy / "BRAZILIAN SPYDER" (equipo pequeño + publisher; reparto no aclarado) ([Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot)) | may-2025 ([The Star](https://www.thestar.com.my/tech/tech-news/2026/03/25/robloxs-hit-game-steal-a-brainrot-battles-its-many-imitators)) | 25,4 M (7-oct-2025, [PocketGamer.biz](https://www.pocketgamer.biz/robloxs-steal-a-brainrot-becomes-first-game-to-surpass-25m-concurrent-players)); 25,2 M ([Outlook](https://respawn.outlookindia.com/gaming/gaming-news/robloxs-steal-a-brainrot-breaks-all-time-player-record)); 25.836.222 ([Rolimons](https://www.rolimons.com/game/109983668079237)) | ~111–129 mil (oct-2026) ([EndgameTools](https://endgametools.com/en/roblox/players/steal-a-brainrot)) | En declive fuerte pero aún con 100 mil+; ~74 mil M de visitas |
| 4 | **Grow a Garden (GaG)** | Granja/idle/colección | BMWLux (adolescente de 16 años, creador original) + Jandel / Splitting Point Studios; DoBig con participación minoritaria ([Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden)) | 26-mar-2025 (Wikipedia) | 16,41 M (jun-2025, [esports.gg](https://esports.gg/news/roblox/grow-a-garden-breaks-blox-fruits-record-for-most-concurrent-users-on-roblox/)); **22,3 M el 23-ago-2025** ([Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden), [GamesBeat](https://gamesbeat.com/janzen-madsen-interview/)); "casi 22 M en julio" ([Game Developer](https://www.gamedeveloper.com/business/roblox-s-grow-a-garden-had-nearly-22-million-concurrent-users-in-july)) | No hallé cifra actual del original | Sustituido en protagonismo por su secuela; en may-2026 una lista lo llamaba el mayor por CCU diaria ([StudioKrew mayo](https://studiokrew.com/blog/top-roblox-games-may-2026/)) |
| 5 | **Grow a Garden 2** | Idem (juego **separado**, no actualización) | "Strawberreh Squad" en trackers; una guía dice Jandel/Grow Games (conflicto) | 12-jun-2026 ([GosuGamers](https://www.gosugamers.net/entertainment/news/78614-grow-a-garden-2-has-launched-on-roblox-here-s-everything-new-added-in-this-sequel)) | >400 mil a los 20 min del lanzamiento; 483.561 el 13-ago-2026 ([RoVitals](https://rovitals.com/game/97598239454123)) | 2,7–4,7 mil en septiembre según trackers: **[NO VERIFICADO]**, puede ser un *place ID* distinto | Fuerte caída; dudas abiertas |
| 6 | **+1 Speed Keyboard Escape** | Obby/incremental ("+1 velocidad por paso") con estética ASMR/caramelo | SecretVerse Studio (independiente) ([Fandom](https://roblox.fandom.com/wiki/SecretVerse_Studio/%2B1_Speed_Keyboard_Escape)) | 2026 (fecha exacta no hallada; "creado a inicios de 2026") | 7.263.327 el 18-jul-2026 ([Rolimons](https://www.rolimons.com/game/95082159892680)); ~6,2 M ([Bloxline](https://www.thebloxline.com/articles/1-speed-keyboard-escape-has-become-one-of-roblox-s-biggest-games-here-s-why-it-works)); 5,62 M el 28-jun ([RblxTracker](https://x.com/RblxTracker/status/2071231292637651446)); concierto bbno$ 6.355.764 el 25-jul | ~358 mil (20-ago) | Vigente; visitas 2,5–6,5 mil M según tracker |
| 7 | **Animal Hospital** | Terror/simulación | Animal Anomaly (pequeño) | 10-may-2026 ([GosuGamers](https://www.gosugamers.net/entertainment/news/78741-animal-hospital-becomes-roblox-s-latest-horror-sensation-here-s-everything-you-need-to-know)) | 736.948 el 5-jul-2026; luego **1,2 M** tras una gran actualización ([GosuGamers](https://www.gosugamers.net/entertainment/news/78773-roblox-animal-hospital-hits-1-2-million-ccu-with-major-update-featuring-new-character-and-items)) | 358,5 mil (20-ago) | Vigente; >1,4 mil M de visitas; polémica por uso de IA (sección 7) |
| 8 | **Escape Tsunami for Brainrots** | Obby de supervivencia / escapar | Grupo "Wave of Brainrots" (pequeño) | 15-dic-2025 (otra página dice ene-2026) | ~5 M ([RoWatcher](https://rowatcher.com/games/9363735110/escape-tsunami-for-brainrots)); superó brevemente a Steal a Brainrot en ene-2026 | ~164 mil (fecha incierta) ([RoWatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)); Profitable da 342,6 mil como pico (incongruente) | Muy por debajo del pico |
| 9 | **Plants vs Brainrots** | Defensa de torres + granja con meme brainrot | No identificado en las búsquedas | 2025 | 3,2 M ([TS2](https://ts2.tech/en/robloxs-newest-phenomenon-plants-vs-brainrots-breaks-records-heres-why-everyones-obsessed/)); 8,65 M según blog promocional (**[NO VERIFICADO]**, fuente poco fiable) | n/d | Sin datos recientes fiables |
| 10 | **Blox Fruits** | RPG/PvP estilo anime, frutas con habilidades | Gamer Robot Inc (mygame43 y rip_indra; estudio pequeño/mediano de comunidad) ([Fandom](https://roblox.fandom.com/wiki/Gamer_Robot_Inc/Blox_Fruits)) | ene-2019 | 412,6 mil ([BloxSniper](https://bloxsniper.cc/games/994732206)) – 469,8 mil ([Profitable](https://profitable.app/roblox/games/blox-fruits)); Rotrends 2,8 M (probable error) | ~162–323 mil (oct-2026) | Vigente; ~64 mil M de visitas |
| 11 | **Adopt Me!** | Mascotas/rol/trading | Uplift Games (estudio grande/consolidado) | 2017 [NO VERIFICADO, conocimiento general] | 1.370.017 el 3-oct-2026 ([Rival Ducks](https://rivalducks.com/apps/radar/games/383310974-adopt-me)); Wikipedia da 1,92 M (conflicto) | 108–258 mil (sep–oct-2026) | Vigente; ~45 mil M de visitas |
| 12 | **Brookhaven RP** | Rol/vida social | Creado en solitario por Wolfpaq; **adquirido por Voldex el 4-feb-2025** ([Silicon Canals](https://siliconcanals.com/?p=59578)) | 2020 [NO VERIFICADO, conocimiento general] | 1.296.208 el 19-dic-2025 ([RoWatcher](https://rowatcher.com/games/1686885941/brookhaven-rp)) | 300–670 mil (jul–ago-2026) | Vigente; 69–86 mil M de visitas según fuente |
| 13 | **Murder Mystery 2** | Deducción social/PvP | Nikilis (estudio pequeño/mediano) | 2014 [NO VERIFICADO, conocimiento general] | **1.349.555 en ago-2026** durante el evento de verano (24-jul a 24-ago) ([StudioKrew julio/agosto](https://studiokrew.com/blog/top-roblox-games-august-2026/)); media 7 días 895 mil | 192–539 mil (ago-2026) | Vigente; récord histórico reciente |
| 14 | **Dress to Impress (DTI)** | Moda/concurso social | Gigi (adolescente creadora; creado en nov-2023) ([RoWatcher](https://rowatcher.com/news/dress-to-impress-how-a-teen-developer-s-fashion-game-hit-9-7-billion-visits)) | nov-2023 | 1,5 M ([RoWatcher](https://rowatcher.com/news/dress-to-impress-how-a-teen-developer-s-fashion-game-hit-9-7-billion-visits)); un sitio poco fiable dice 1,8 M en ago-2026 (**[NO VERIFICADO]**) | ~409 mil (oct-2026, BloxGuides) | Vigente; 9,7 mil M de visitas; 3 premios Roblox Innovation 2024 |
| 15 | **RIVALS** | Shooter 1v1 competitivo | Nosniy Games (pequeño; 19 experiencias publicadas) | 26-may-2024 (otra fuente: 28-jun-2024) | 967.342 ([RoWatcher](https://rowatcher.com/news/rivals-how-roblox-s-top-shooter-built-a-nearly-million-player-empire)); 961,6 mil ([Profitable](https://profitable.app/roblox/games/rivals)) | ~213–376 mil | Vigente; >13 mil M de visitas; 94,4 % de aprobación |
| 16 | **Fisch** | Pesca/RPG idle | Grupo "Fisching" (pequeño) | 2025 [NO VERIFICADO] | 454 mil el 3-oct-2026 (variante "SAVE NATE") ([RoWatcher](https://rowatcher.com/games/5750914919/fisch-save-nate/dying)) | ~55 mil (media 7 d: 81 mil) | Vigente; picos por actualización |
| 17 | **Sol's RNG** | RNG/incremental (rodar "auras") | Sol's Studio (pequeño) | 2024 [NO VERIFICADO] | 77,8 mil ([Profitable](https://profitable.app/roblox/games/sol-s-rng)) | ~32,5 mil (jul-2026) | Vigente pero de nicho; ~1,7–2 mil M de visitas |
| 18 | **Pet Simulator 99** | Mascotas/clicker/gacha | BIG Games (estudio grande/establecido) | 2024 [NO VERIFICADO] | n/d (no hallé pico) | ~158–190 mil (jul-2026) ([AllThingsHow](https://allthings.how/pet-simulator-99-saturday-update-schedule/)) | Vigente con actualizaciones semanales |
| 19 | **Tower Defense Simulator** | Torres de defensa cooperativo | Paradoxum Games (estudio mediano) | 2019 [NO VERIFICADO] | n/d | ~20 mil en partidas típicas; 4,8 mil M de visitas | Vigente de nicho; eventos semanales ([AllThingsHow](https://allthings.how/tower-defense-simulator-events-schedule/)) |
| 20 | **The Forge** | RPG de minería/forja | "The Forge Community" (nada más) | 10-may-2025; último update 5-sep-2026 ([Rotrends](https://www.rotrends.com/game/7671049560/The-Forge-BETA)) | n/d (no hallado) | n/d | Vigente (top trending #26 en 2025–26) |

No investigados por falta de presupuesto de búsquedas: Dead Rails, Forsaken, Dig, Blade Ball, Garden Tower Defense, Anime Vanguards/Defenders, Ink Game (solo un dato: 3,2 M$ de ingresos mensuales estimados y 1.130 M de horas en ago-2025, [Creator Exchange](https://x.com/CreatorExc/status/1952868682096574520), [TERCERO]), obbies clásicos (tipo Tower of Hell) y los juegos de marca de publishers grandes como [Gamefam](https://en.wikipedia.org/wiki/Gamefam).

### 4.2 Monetización y loop central

| Juego | Cómo monetiza (evidencia) | Loop central que retiene |
|---|---|---|
| **Steal An Egg** | Gastar Robux o ver feed para ir más rápido en la cinta ("treadmill") — mecánica retirada tras el incidente ([TechSpot](https://www.techspot.com/news/113630-roblox-cracking-down-games-reward-kids-doomscrolling.html)); mascotas con "dinero por segundo" y listas de valor ([TimeSaver](https://timesaver.gg/blog/steal-an-egg-pet-value-list)). Sin lista oficial de pases/productos hallada. | Robar huevos → llevarlos al corral → eclosionar mascotas → ingreso pasivo → mejoras (velocidad, etc.) ([Fandom](https://roblox.fandom.com/wiki/And_Collect_Rare_Pets/Steal_An_Egg)). |
| **99 Nights** | Sin cifra oficial. Monetización detallada **no hallada**; supuesto de que vende cosméticos/reanimaciones es [NO VERIFICADO]. Estimación de ingresos 4,0–6,5 M$/mes ([BloxPrices](https://www.bloxprices.com/roblox-top-earning-games/)), modelo basado en visitas. | Sobrevivir 99 noches en cooperativo, recolectar recursos, terror y progresión por sesión. |
| **Steal a Brainrot** | Pases: 2X Money 299 R$, VIP 499 R$, Admin Commands 4.999–7.999 R$ según fuente ([Tribality](https://www.tribality.com/articles/steal-a-brainrot-best-game-passes-upgrades-worth-your-robux/)) — precios cambian a menudo. Streamer KreekCraft dice haber ganado >1 M$ con el juego ([bo3.gg](https://bo3.gg/games/news/kreekcraft-says-steal-a-brainrot-has-earned-him-over-1-million)), lo que sugiere acuerdos de socios. | Comprar brainrots → generan dinero → robar los de otros/defender tu base → comprar más raros. Eventos que disparan picos (evento "Yin Yang" oct-2025). |
| **Grow a Garden** | Semillas, mejoras y animales raros comprados con Robux ([Calcalist](https://www.calcalistech.com/ctechnews/article/dj4lxef8r)). | Plantar → esperar → vender → comprar semillas más raras; eventos climáticos/mutaciones y eventos de administradores (según mi conocimiento general, [NO VERIFICADO] aquí). |
| **Grow a Garden 2** | Sin datos de monetización hallados. | Igual que el original. |
| **+1 Speed Keyboard Escape** | Anuncios de Roblox con recompensa: ventana emergente de "segunda oportunidad/revivir" dentro del juego ([documentación de Roblox sobre ad placements](https://create.roblox.com/docs/production/ad-placements/1speed), solo vi el resultado del buscador) [OFICIAL]; estelas/rebirths ([Roblox Fandom](https://roblox.fandom.com/wiki/SecretVerse_Studio/%2B1_Speed_Keyboard_Escape)). Concierto de bbno$ como evento. | Cada paso suma velocidad; recorrido enorme con estética de teclas, sonido ASMR y colores de caramelo; "número que sube" y rebirths ([Bloxline](https://www.thebloxline.com/articles/1-speed-keyboard-escape-has-become-one-of-roblox-s-biggest-games-here-s-why-it-works)). |
| **Animal Hospital** | Skins relativamente caras (inferencia de un medio, no dato). Sin cifras. | Terror y cooperación en un hospital de animales; actualizaciones con personajes/objetos. |
| **Escape Tsunami for Brainrots** | Sin datos hallados. | Correr/escapar de tsunamis con brainrots; sesiones cortas y repetibles. |
| **Plants vs Brainrots** | Sin datos fiables. | Defensa de torres + granja + coleccionables con meme. |
| **Blox Fruits** | **Gacha** de frutas desde nivel ~50 con precios crecientes ([Fandom](https://roblox.fandom.com/wiki/Gamer_Robot_Inc/Blox_Fruits)); **6 game passes y 188 dev products** ([Rotrends](https://www.rotrends.com/game/994732206/RED-EVENT-Blox-Fruits)); descrito como monetización agresiva con pases ([RoLearn](https://rolearn.dev/insights/roblox-creator-earnings-how-much-developers-make/)). | Subir de nivel, grindeo, PvP y raids; frutas aleatorias, trading. |
| **Adopt Me!** | Huevos de pago (p. ej. 350–1.450 R$ según guía; algunas precios en Bucks, conflicto), pase "Hatch Now" que ahorra tiempo por huevo; mascotas de evento limitado y retiradas que alimentan el **trading** ([Wikipedia](https://en.wikipedia.org/wiki/Adopt_Me!)). | Cuidar mascotas, completar tareas, eclosionar, tradear; eventos temporales (p. ej. Halloween con pico el 3-oct-2026). |
| **Brookhaven RP** | ~15 game passes de 70–999 R$ y >20 casas (guía de fans) ([Earnaldo](https://earnaldo.com/blog/brookhaven-rp-free-robux-guide)). Voldex compró el juego. | Rol libre sin presión; casas, vehículos, social. Actualizaciones estacionales (Olimpiadas de invierno feb-2026, Cherry Blossom mar-2026). |
| **Murder Mystery 2** | Cajas misteriosas con cuchillos/armas ("godlies", "ancient"), economía de trading, eventos de verano con pack ([AllThingsHow](https://allthings.how/murder-mystery-2-events-schedule/), [RoWatcher](https://rowatcher.com/news/what-is-murder-mystery-2-a-guide-to-roblox-s-legendary-social-deduction-game)). | Rondas cortas de 3–5 minutos (inocente/sheriff/asesino) + coleccionismo y trading. |
| **Dress to Impress** | Cosméticos, personalización de avatar y contenido por temporada (estimación de un tracker); VIP: sin datos fiables. | Rondas de moda con tema y votación social; los usuarios crean contenido (outfits). |
| **RIVALS** | Casi todo **cosmético**: skins de armas, llaves, battle pass, economía de cajas estilo CS:GO ([RoWatcher](https://rowatcher.com/news/the-10-highest-earning-roblox-games-in-2026-and-what-they-mean-for-the-platform)). | Duelos 1v1 rápidos, ranking, desbloqueo por contratos. |
| **Fisch** | Sin datos de pases; Profitable estima 37,4 M$ de ingresos totales (modelo). | Pescar, vender, mejorar caña/barco, explorar zonas. |
| **Sol's RNG** | Pases de temporada, pociones de suerte, cofres de pociones, códigos distribuidos en Discord ([Profitable](https://profitable.app/roblox/games/sol-s-rng), [games.gg](https://games.gg/news/sols-rng-roblox-codes-for-march-2026/)). | Rodar RNG para obtener auras raras; eventos y jefes (actualización de jefes 28-feb-2026). |
| **Pet Simulator 99** | Pets limitadas (Huge/Titanic), huevos especiales de evento; precios no hallados. | Romper monedas → eclosionar → mejorar mascotas; **actualización cada sábado** (Update 83: 4-jul-2026; Update 85: 18-jul-2026) ([AllThingsHow](https://allthings.how/pet-simulator-99-saturday-update-schedule/)). |
| **Tower Defense Simulator** | Sin datos de monetización hallados. | Colocar torres, ganar monedas, evolucionar torres; torre/evento nuevo cada semana o dos (Kingpin 17-jul, Enforcer ago-2026, Frost Champion 28-ago) ([AllThingsHow](https://allthings.how/tower-defense-simulator-events-schedule/)). |
| **The Forge** | Sin datos. | Minar, forjar equipo, progresión RPG. |

---

## 5. Ingresos: lo que dicen los terceros (y por qué no te puedes fiar de ninguno)

**Ningún dato de esta tabla es de Roblox ni del desarrollador.** Los modelos de Profitable.app asumen (según su propio texto): 2 % de engagement × 150 Robux de gasto por sesión × 70 % de reparto × 0,0038 $/Robux, aplicados a las visitas históricas. Eso da cifras "de por vida" gigantes que no se corresponden con la realidad de un juego en declive.

| Juego | Estimaciones encontradas (todas [TERCERO] / modelo) | Comentario |
|---|---|---|
| Grow a Garden | 12 M$ solo en mayo-2025 ([Calcalist](https://www.calcalistech.com/ctechnews/article/dj4lxef8r)); 150 M$ brutos en 3 meses según un analista de JPMorgan citado en redes (**[NO VERIFICADO]**); 287,1 M$ para el grupo propietario ([tracker citado por TechSpot/IBTimes](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403)) | Roblox no relaciona ningún juego concreto con los 657 M$ del top 10. |
| Steal a Brainrot | 64 M$ desde mayo-2025 (Romonitor vía [The Star](https://www.thestar.com.my/tech/tech-news/2026/03/25/robloxs-hit-game-steal-a-brainrot-battles-its-many-imitators)); 1,43 M$/mes ([RoWatcher](https://rowatcher.com/games/7709344486/steal-a-brainrot)); 577,5 M$ de por vida ([Profitable](https://profitable.app/roblox/games/steal-a-brainrot)); 11 M$/mes en ago-2025 ([Creator Exchange](https://x.com/CreatorExc/status/1952868682096574520)) | Rango de 2 órdenes de magnitud. |
| Steal An Egg | ~13,5 M$ por 30 días ([BloxRant](https://bloxrant.com/roblox-top-earning-games)) | Modelo propio de BloxRant. |
| 99 Nights | 4,0–6,5 M$/mes ([BloxPrices](https://www.bloxprices.com/roblox-top-earning-games/)) | La otra fuente ([StealWhatWorks](https://stealwhatworks.com/blogs/news/roblox-games-over-10k-month-now)) dice que casi seguro supera 10 mil$/mes pero no se puede precisar. |
| Blox Fruits | 6,0–9,5 M$/mes ([BloxPrices](https://www.bloxprices.com/stats/blox-fruits/)); 40–70 M$/año ([RoLearn](https://rolearn.dev/insights/roblox-creator-earnings-how-much-developers-make/)); 516,7 M$ de por vida (Profitable) | Concuerdan en el orden de las decenas de M$/año. |
| Adopt Me! | ~3,5 M$/mes (BloxRant); 357,7 M$ de por vida (Profitable) | — |
| Brookhaven RP | 2,27 M$/mes; 683,5 M$ de por vida (Profitable) | — |
| Murder Mystery 2 | ~1,06 M$/mes | — |
| RIVALS | 1,74 M$/mes ([RoWatcher](https://rowatcher.com/news/rivals-how-roblox-s-top-shooter-built-a-nearly-million-player-empire)); 4,3 M$ en 30 días (Profitable); 8–15 M$/mes (otra fuente) | Rango de ~9x. Se dice que lideró ingresos en PC y móvil en ene-2026 ([RoWatcher](https://rowatcher.com/news/the-10-highest-earning-roblox-games-in-2026-and-what-they-mean-for-the-platform)). |
| Dress to Impress | 820 mil$/mes ([RoWatcher](https://rowatcher.com/games/5203828273/dress-to-impress)); 83,3 M$ totales ([Profitable](https://profitable.app/roblox/games/dress-to-impress)) | — |
| Fisch | 37,4 M$ totales (Profitable) | — |
| Sol's RNG | 323–383 mil$/mes; 16,1 M$ totales (Profitable) | Ejemplo de juego "pequeño pero rentable por visita". |
| Plants vs Brainrots | 36,5 mil$/mes ([RoWatcher](https://rowatcher.com/games/8316902627/plants-brainrots)) vs 37,3 M$ de por vida (Profitable) | Contradicción de ~3 órdenes de magnitud. |

**Regla práctica con datos oficiales:** Roblox cita un reparto efectivo de **26,6 % del gasto del jugador** para el desarrollador (37,8 % para gasto de adultos de EE. UU. verificados) ([DevForum](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)), es decir, de cada 100 $ que gastan los jugadores, el creador cobra aproximadamente 27 $ (sin impuestos ni costes de equipo). No confundas "bookings" brutos con lo que cobra el estudio.

---

## 6. Patrones de los juegos virales (con evidencia y nivel de confianza)

| Patrón | Evidencia encontrada | Etiqueta |
|---|---|---|
| **Meme/tendencia en el título y el arte** | "Brainrot" aparece en Steal a Brainrot, Plants vs Brainrots, Escape Tsunami for Brainrots, Swing Obby for Brainrots… ([RoWatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)); "Steal a ___" genera ~3.300 clones (estimación de un blog) | [TERCERO] |
| **Mezclar mecánica conocida + meme** | Plants vs Brainrots (Plants vs Zombies + brainrots); Steal An Egg (Steal a Brainrot + mascotas); Grow a Garden (granja idle) | [TERCERO] (inferencia mía a partir de los títulos) |
| **Loop de ~30 segundos y número que sube** | +1 Speed Keyboard Escape: cada paso suma velocidad, "un número que sube y te hace más fuerte" ([Bloxline](https://www.thebloxline.com/articles/1-speed-keyboard-escape-has-become-one-of-roblox-s-biggest-games-here-s-why-it-works)); Steal An Egg: robar–eclosionar–ingreso–mejorar | [TERCERO] |
| **Eventos/estunts que disparan los picos** | Concierto bbno$ (6,36 M CCU en +1 Speed, 25-jul-2026); evento "Yin Yang" de Steal a Brainrot (pico de oct-2025); "guerra de administradores" Jandel vs Sammy que ayudó a un récord de plataforma de 47,4 M ([Tubefilter](https://www.tubefilter.com/2025/08/25/roblox-grow-garden-steal-brainrot-admin-war-record/amp/)); evento de verano de MM2 (récord 1,35 M); Halloween en Adopt Me (pico 3-oct-2026) | [TERCERO] |
| **Cadencia de actualizaciones muy alta** | Pet Simulator 99: actualización cada sábado; TDS: torre/evento nuevo cada 1–2 semanas; Steal a Brainrot "sobrevive por actualizaciones constantes" ([RoWatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)) | [TERCERO] |
| **Códigos y comunidad (Discord/redes)** | Sol's RNG reparte códigos de pociones vía Discord en cada actualización ([games.gg](https://games.gg/news/sols-rng-roblox-codes-for-march-2026/)) | [TERCERO] |
| **Economías de rareza y trading** | MM2 (cuchillos godly), Adopt Me (mascotas de evento limitadas → apreciación gradual), Steal An Egg (listas de valor por "dinero por segundo") | [TERCERO] |
| **Streamers/YouTubers y socios** | KreekCraft afirma haber ganado >1 M$ con Steal a Brainrot ([bo3.gg](https://bo3.gg/games/news/kreekcraft-says-steal-a-brainrot-has-earned-him-over-1-million)); GaG tiene co-propiedad entre creador, estudio de Jandel y DoBig ([Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden)) | [TERCERO] — sin detalle de acuerdos |
| **Colaboraciones de IP/música** | bbno$ en +1 Speed; película con 20th Century Studios para 99 Nights | [TERCERO] |
| **Anuncios con recompensa como ingreso no invasivo** | +1 Speed usa un "revive" con anuncio; Roblox lo documenta como ejemplo de *ad placement* | [OFICIAL] (solo vi el resultado) |

### Tiempo al pico y caída (cálculo propio con datos de terceros)

Un pico es un valor máximo y la cifra actual es una instantánea (puede estar en el valle diario); la caída está algo sobreestimada.

| Juego | Lanzamiento | Pico | Tiempo al pico | CCU reciente | Caída aprox. (cálculo propio) |
|---|---|---|---|---|---|
| Grow a Garden | 26-mar-2025 | 22,3 M (23-ago-2025) | ~5 meses | n/d | n/d |
| Steal a Brainrot | may-2025 | ~25,4–25,8 M (oct-2025) | ~5 meses | ~111–129 mil (13-oct-2026) | ≈ -99,5 % |
| 99 Nights | 2025 | 14,15 M (4-oct-2025) | n/d | ~187 mil (media reciente) | ≈ -98,7 % |
| Escape Tsunami | 15-dic-2025 | ~5 M (ene-2026) | semanas | ~164 mil | ≈ -97 % |
| Animal Hospital | 10-may-2026 | 1,2 M (verano-2026) | ~2–3 meses | 358,5 mil (20-ago) | ≈ -70 % |
| +1 Speed Keyboard Escape | 2026 | 7,26 M (18-jul-2026) | ≤ ~6 meses | ~358 mil (20-ago) | ≈ -95 % en ~1 mes |
| Steal An Egg | 25-jul-2026 | 14,29 M (19-sep-2026) | ~56 días | 0,8–1,2 M (7–18-oct) | ≈ -92 % a -94 % en ~4 semanas (mezclando trackers) |
| Grow a Garden 2 | 12-jun-2026 | 483,6 mil (13-ago-2026) | ~2 meses | 2,7–4,7 mil (sep, **dudoso**) | n/d |

Los "juegos longevos" (Adopt Me, Brookhaven, MM2, Blox Fruits, Dress to Impress) tienen picos de 0,4–1,35 M **y** CCU diarias de 100–700 mil durante años: la base estable es más importante que el pico.

---

## 7. Estudios pequeños con éxito rápido y poco presupuesto

| Caso | Qué se sabe | Etiqueta |
|---|---|---|
| **Grow a Garden** | La primera versión la hizo en "pocos días" un adolescente anónimo de 16 años (BMWLux). Jandel (Splitting Point Studios, con >25 juegos creados desde 2021 y "ingresos de seis cifras al mes" según Business Insider) se unió y escaló el juego; DoBig tiene participación minoritaria ([Calcalist](https://www.calcalistech.com/ctechnews/article/dj4lxef8r), [Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden), [GamesBeat](https://gamesbeat.com/janzen-madsen-interview/)). Patrón: **creador de prototipo + socio con audiencia/operaciones**. | [TERCERO] |
| **99 Nights in the Forest** | Estudio de Nueva Zelanda (~5 M de habitantes) con un equipo pequeño; 14,2 M de pico ([PC Gamer](https://www.pcgamer.com/games/survival-crafting/with-a-peak-player-count-of-14-2-million-99-nights-in-the-forest-has-an-audience-other-multiplayer-games-would-kill-for-to-find-these-behemoth-playerbases-you-need-to-be-on-a-platform-like-roblox/)). | [TERCERO] |
| **Dress to Impress** | Creado por una adolescente (Gigi) en nov-2023; 9,7 mil M de visitas ([RoWatcher](https://rowatcher.com/news/dress-to-impress-how-a-teen-developer-s-fashion-game-hit-9-7-billion-visits)). | [TERCERO] |
| **+1 Speed Keyboard Escape** | Estudio independiente (SecretVerse Studio), un género muy simple (obby incremental) en 2026 → pico de 7,26 M. | [TERCERO] |
| **Steal an Egg** | Grupo sin nombre público; lanzamiento 25-jul-2026 → ~14 M de pico en 8 semanas. | [TERCERO] |
| **Sol's RNG** | Juego "RNG" de un estudio pequeño; no llega al millón de CCU, pero genera ~0,3 M$/mes (estimación) con pocas mecánicas de monetización claras. | [TERCERO] |

**Advertencia de sesgo de supervivencia:** son los 10 casos entre decenas de miles. La mediana de DevEx es 1.500 $/año.

---

## 8. Fracasos y advertencias

1. **Caída post-viral extrema** (tabla de la sección 6): -93 % a -99,5 % desde el pico en semanas o meses. Los trackers consideran que cada pico por evento cae más rápido que el anterior ([RoWatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)).
2. **Saturación de clones:** ~12.400 juegos "Brainrot" y ~3.300 "Steal a ___" [NO VERIFICADO, un blog]. La misma fuente dice que el descubrimiento de Roblox ahora **penaliza** juegos cuyo título, miniatura y archivos de lugar se parecen mucho a otros, y que los creadores de Steal a Brainrot demandaron al menos 4 veces desde nov-2025. Dos afirmaciones importantes sin segunda fuente: verificarlas antes de basar la estrategia en ellas. Coherente con ello, Roblox premia la "novedad" en su nueva tarifa DevEx de EE. UU. 18+ [OFICIAL].
3. **Popularidad ≠ dinero:** Roblox reconoce que parte de la caída de bookings se debe a que el compromiso se desplazó a juegos que monetizan menos por hora [OFICIAL, vía prensa]. Un juego con millones de CCU de niños pequeños puede ingresar poco.
4. **Riesgo regulatorio y de contenido:** Steal An Egg fue retirado horas después de llegar al #1 por su feed de videos; Roblox prohibió el patrón en los catálogos para menores. Se puede reponer sin la mecánica ([GamesRadar](https://www.gamesradar.com/games/simulation/roblox-takes-down-controversial-doomscrolling-game-promises-to-remove-others-that-reward-watching-a-continuous-feed-of-content-as-theyre-not-appropriate-for-younger-users/), [1vX](https://1vx.gg/news/steal-an-egg-was-pulled-from-roblox-after-hitting-no-1-with-500-000-concurrent-players)).
5. **Riesgo reputacional por IA:** el desarrollador de Animal Hospital pidió disculpas por usar activos generados con IA en una actualización ([GosuGamers](https://www.gosugamers.net/entertainment/news/79296-roblox-s-animal-hospital-developer-apologises-for-using-ai-in-the-game-s-latest-update)); hay un vídeo titulado "The Downfall of One of Roblox's Biggest Horror Games" ([YouTube](https://www.youtube.com/watch?v=EXdNlG2skyM)), cuyo contenido no pude comprobar.
6. **Estancamiento de la plataforma:** DAU baja desde el máximo, bookings -14 % a -18 % en T3-2026 (guía) y acción -37 % en 2026 [TERCERO]. Puede reducir el gasto por jugador y el presupuesto de descubrimiento.
7. **Cifras que se contradicen:** muchos "top" que se citan en blogs son modelos; usar picos de 2025 para estimar ingresos de 2026 produce expectativas irreales.

---

## 9. Lecciones aplicables a nuestros juegos

> Son recomendaciones mías basadas en la evidencia anterior; cuando algo es inferencia lo digo. No hay datos propios de retención ni conversión: todo debe validarse con pruebas pequeñas.

### 9.1 Estrategia de cartera (muchos juegos)
1. **Piensa en cartera de apuestas baratas, no en un "juego grande".** La mediana de creador gana ~1.500 $/año y el top 10 gana 65,7 M$ de media: el reparto es de cola larga. Con IA se reduce el coste por prototipo, así que la ventaja posible es **más intentos por euro**, no mejor calidad por juego.
2. **Define reglas de descarte desde el día 1** (inferencia): p. ej. publicar un prototipo mínimo, medir CCU y retención de 1–7 días durante 2–4 semanas, y solo invertir más en los que superen un umbral. El mercado cambia en semanas (Steal An Egg: 56 días hasta el pico).
3. **No cuentes con un único hit viral:** los picos caen 93–99 % en semanas/meses. Si uno despega, planifica ingresos para la caída (arrancar el calendario de contenido y los eventos mientras suben los jugadores).
4. **Los juegos longevos (Brookhaven, MM2, Adopt Me, Blox Fruits, DTI)** muestran que la meta realista de un estudio pequeño es una base estable de miles de CCU con trading/cosméticos, no el millón.

### 9.2 Diseño de loop y retención
5. **Loop obvio en 30 segundos con "número que sube"** (patrón +1 Speed, Steal An Egg, GaG): robar/recoger → ingreso pasivo → mejorar. Que se entienda sin tutorial.
6. **Sesiones y rondas cortas** (MM2, RIVALS, DTI) y **reentrada fácil** (ingreso pasivo/offline).
7. **Trading y rareza controlada** (MM2, Adopt Me): crean economía social y razones para volver. Ten cuidado con la normativa de objetos aleatorios de pago (Roblox exige informar probabilidades; en algunos países hay restricciones). Esto es conocimiento general mío, **[NO VERIFICADO] en esta sesión**; consultar la política actual de Roblox.
8. **Eventos limitados + cadencia fija** (PS99 cada sábado, TDS cada 1–2 semanas, MM2 verano). Construye desde el principio un **sistema de eventos configurable por datos** (no por cada evento un desarrollo nuevo).
9. **Códigos y Discord** (Sol's RNG) como canal barato de retención.

### 9.3 Monetización
10. **Mezcla probada de microtransacciones** (por orden de evidencia): pases de multiplicador/velocidad (2X Money 299 R$), VIP 499 R$, cosméticos y skins (RIVALS), cajas/gacha con trading (MM2, Blox Fruits, Adopt Me), pociones de suerte y pases de temporada (Sol's RNG), anuncios con recompensa (+1 Speed). **No hay datos aquí de conversión ni de precios óptimos**: probar con A/B.
11. **Apunta a monetizar por hora, no solo a conseguir horas** (Roblox lo señala como causa de su caída de bookings). Los juegos cosméticos con jugadores mayores (RIVALS, DTI) son el contrapeso a los de niños pequeños; además la **tarifa DevEx US 18+ (37,8 % vs 26,6 %)** premia gasto de adultos verificados de EE. UU. [OFICIAL].
12. **Planifica con el 26,6 % (o 37,8 %) del gasto bruto** como ingreso del estudio, no con las cifras de "bookings" o de los modelos de terceros.

### 9.4 Originalidad, riesgos y uso de IA
13. **No clones literalmente.** Hay evidencia (aunque de un solo blog) de penalización de clones en el descubrimiento y de demandas; Roblox premia la novedad en la tarifa DevEx. Estrategia: **combinar una mecánica probada + un tema/meme distinto + un giro de loop** (como Steal An Egg sobre Steal a Brainrot) y diferenciarse en título, miniatura y estructura.
14. **Cuidado con mecánicas de "feed infinito"** o cualquier diseño que Roblox pueda restringir en los catálogos de menores; revisa las políticas antes de lanzar.
15. **IA:** úsala para código, prototipos, iconos/texto de tienda y balance, pero **evita arte/assets generados por IA visibles sin supervisión humana** (caso Animal Hospital) y revisa las normas de Roblox sobre contenido generado. Las herramientas de IA de Roblox y de terceros no se investigaron aquí.
16. **Búsqueda de socios con audiencia:** los casos de GaG (creador + estudio de Jandel + DoBig) y KreekCraft/Steal a Brainrot sugieren que la distribución (streamers, comunidad) es tan importante como el juego. Los detalles de los acuerdos **no los conozco**.

### 9.5 Qué haría primero (propuesta, inferencia mía)
- Armar un **"kit base" reutilizable** (tienda con pases/dev products, sistema de eventos, códigos, trading básico, economía de mascotas/ingreso pasivo, telemetría) y producir 5–10 prototipos con variaciones de tema.
- Lanzarlos con presupuesto mínimo, medir 2–4 semanas, y duplicar solo en los que muestren retención y gasto por jugador.
- Revisar las políticas de Roblox (objetos aleatorios de pago, contenido para menores, IA, clones) **antes** de monetizar.

---

## 10. Dudas abiertas y próximos pasos

1. ¿Qué pasó realmente con Grow a Garden 2? Los trackers muestran 483 mil de pico (13-ago) pero 2,7–4,7 mil en septiembre: puede ser un place ID distinto. Verificar en el chart oficial de Roblox.
2. **Cifras de Roblox T3-2026 (29-oct):** esperar el informe; indicará el efecto real de Steal An Egg en bookings.
3. **¿Existe y cómo funciona la penalización de clones?** Solo un blog lo afirma. Buscar anuncios oficiales en DevForum/blog de Roblox.
4. **Monetización detallada** (pases/dev products y precios) de Steal An Egg, 99 Nights, Animal Hospital, +1 Speed, Grow a Garden 2: no hallada.
5. **Cómo se hicieron virales realmente** (entrevistas con Jandel/GamesBeat, PC Gamer sobre 99 Nights, ensayo "The Algorithm Behind Steal a Brainrot" de Andy Hall): solo vi títulos. Leer cuando haya acceso.
6. **Datos de retención/ARPDAU** de cualquier juego: no disponibles públicamente; habrá que medirlos con prototipos propios.
7. **Políticas de Roblox** (objetos aleatorios de pago, IA generativa, contenido infantil, derechos sobre memes/IP): consultar documentación oficial cuando sea accesible (create.roblox.com y devforum estaban bloqueados).
8. **Juegos no cubiertos:** Dead Rails, Forsaken, Dig, Blade Ball, Garden Tower Defense, Anime Vanguards/Defenders, Ink Game, obbies clásicos y juegos de publishers grandes (Gamefam, Voldex).
9. **Tarifa DevEx base** (0,0035 vs 0,0038 $/Robux): confirmar en DevForum.

---

## 11. Fuentes (enlaces consultados vía buscador)

*(Solo se leyeron resúmenes de los resultados de búsqueda; ninguna página se pudo abrir con WebFetch.)*

**Roblox / plataforma / finanzas:** [SEC 8-K T2-2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) · [Investing.com transcripción T2](https://www.investing.com/news/transcripts/earnings-call-transcript-roblox-q2-2026-beats-eps-but-shares-sink-on-bookings-93CH-4826338) · [Investing.com diapositivas](https://www.investing.com/news/company-news/roblox-q2-2026-slides-bookings-growth-slows-to-8-amid-user-decline-93CH-4826401) · [Investing.com análisis bookings](https://www.investing.com/analysis/roblox-bookings-recovery-could-decide-whether-the-stock-holds-its-rebound-200689301) · [Outlook T2-2026](https://respawn.outlookindia.com/gaming/gaming-news/roblox-q2-2026-revenue-soars-36-to-15b-despite-bookings-miss) · [TIKR](https://www.tikr.com/blog/roblox-stock-is-down-37-in-2026-heres-what-its-new-viral-hit-has-to-prove-on-october-29) · [MarketBeat T3](https://www.marketbeat.com/earnings/reports/2026-10-29-roblox-corp-stock/) · [DevForum US 18+ DevEx](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091) · [Roblox chart Top Earning](https://www.roblox.com/charts/top-earning)

**Pagos a creadores:** [Dexerto](https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/) · [TweakTown](https://www.tweaktown.com/news/113585/robloxs-top-10-creators-averaged-dollars65-7-million-each-while-the-median-made-dollars1500-and-roblox-everywhere-is-the-fix/index.html) · [TechSpot](https://www.techspot.com/news/113855-roblox-top-creators-making-65-million-year-while.html) · [IBTimes](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403) · [SAYS](https://says.com/my/tech/roblox-creators-earn-1-7-billion-developer-payouts) · [TechTimes](https://www.techtimes.com/articles/326712/20260904/roblox-creator-economy-paid-444m-non-tech-communities-bookings-now-falling.htm)

**Rankings/CCU:** [LiveCounts](https://livecounts.nl/roblox-charts/) · [Rokoala](https://rokoala.com/roblox-player-count/) · [LevelUpPlay](https://levelupplay.my/charts/top-playing) · [GGAID](https://www.ggaid.com/roblox/top-games) · [BloxGuides](https://bloxguidesgg.com/roblox-stats) · [RBLXSTAT](https://rblxstat.com/lists/top-rated-roblox-games) · [BloxRant](https://bloxrant.com/roblox-top-earning-games) · [StudioKrew mayo](https://studiokrew.com/blog/top-roblox-games-may-2026/) · [StudioKrew julio](https://studiokrew.com/blog/top-roblox-games-july-2026/) · [StudioKrew agosto](https://studiokrew.com/blog/top-roblox-games-august-2026/) · [RoWatcher marzo-2026](https://rowatcher.com/news/top-10-roblox-games-by-players-march-2026-data-breakdown) · [RoWatcher mayores ingresos](https://rowatcher.com/news/the-10-highest-earning-roblox-games-in-2026-and-what-they-mean-for-the-platform) · [RoVitals récords](https://rovitals.com/records) · [Wikipedia: List of Roblox games](https://en.wikipedia.org/wiki/List_of_Roblox_games)

**Por juego:**
- Steal An Egg: [Rolimons](https://www.rolimons.com/game/107778070777162) · [LiveCounts](https://livecounts.nl/roblox-game-player-count/?id=107778070777162) · [OtakuKart](https://otakukart.com/robloxs-steal-an-egg-reaches-6-billion-visits-and-14-2-million-peak-concurrent-players/) · [Player.one](https://www.player.one/robloxs-steal-egg-beating-some-platforms-biggest-games-164086) · [EGamers](https://egamers.io/robloxs-no-1-game-steal-an-egg-was-pulled-hours-after-reaching-the-top/) · [1vX](https://1vx.gg/news/steal-an-egg-was-pulled-from-roblox-after-hitting-no-1-with-500-000-concurrent-players) · [GamesRadar](https://www.gamesradar.com/games/simulation/roblox-takes-down-controversial-doomscrolling-game-promises-to-remove-others-that-reward-watching-a-continuous-feed-of-content-as-theyre-not-appropriate-for-younger-users/) · [TechSpot](https://www.techspot.com/news/113630-roblox-cracking-down-games-reward-kids-doomscrolling.html) · [TweakTown](https://www.tweaktown.com/news/113316/roblox-cracks-down-on-games-that-reward-players-for-doomscrolling/index.html) · [Kotaku](https://kotaku.com/roblox-cracks-down-on-doomscrolling-games-like-steal-an-egg-that-forces-players-to-watch-reels-while-running-on-a-treadmill-2000727952) · [Fandom](https://roblox.fandom.com/wiki/And_Collect_Rare_Pets/Steal_An_Egg) · [TimeSaver](https://timesaver.gg/blog/steal-an-egg-pet-value-list)
- Steal a Brainrot: [Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot) · [PocketGamer.biz](https://www.pocketgamer.biz/robloxs-steal-a-brainrot-becomes-first-game-to-surpass-25m-concurrent-players) · [Outlook](https://respawn.outlookindia.com/gaming/gaming-news/robloxs-steal-a-brainrot-breaks-all-time-player-record) · [Tubefilter](https://www.tubefilter.com/2025/08/25/roblox-grow-garden-steal-brainrot-admin-war-record/amp/) · [The Star](https://www.thestar.com.my/tech/tech-news/2026/03/25/robloxs-hit-game-steal-a-brainrot-battles-its-many-imitators) · [Rolimons](https://www.rolimons.com/game/109983668079237) · [RoWatcher](https://rowatcher.com/games/7709344486/steal-a-brainrot) · [Profitable](https://profitable.app/roblox/games/steal-a-brainrot) · [EndgameTools](https://endgametools.com/en/roblox/players/steal-a-brainrot) · [RoWatcher: ¿muere el brainrot?](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals) · [Tribality](https://www.tribality.com/articles/steal-a-brainrot-best-game-passes-upgrades-worth-your-robux/) · [bo3.gg](https://bo3.gg/games/news/kreekcraft-says-steal-a-brainrot-has-earned-him-over-1-million) · [Creator Exchange (X)](https://x.com/CreatorExc/status/1952868682096574520) · [Andy Hall (solo título)](https://freesystems.substack.com/p/the-algorithm-behind-steal-a-brainrot)
- Grow a Garden / 2: [Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden) · [GamesBeat](https://gamesbeat.com/janzen-madsen-interview/) · [Game Developer](https://www.gamedeveloper.com/business/roblox-s-grow-a-garden-had-nearly-22-million-concurrent-users-in-july) · [Calcalist](https://www.calcalistech.com/ctechnews/article/dj4lxef8r) · [esports.gg](https://esports.gg/news/roblox/grow-a-garden-breaks-blox-fruits-record-for-most-concurrent-users-on-roblox/) · [Fortune](https://fortune.com/2025/07/30/roblox-video-game-grow-a-garden-viral-summer-hit/) · [GosuGamers GaG2](https://www.gosugamers.net/entertainment/news/78614-grow-a-garden-2-has-launched-on-roblox-here-s-everything-new-added-in-this-sequel) · [RoVitals](https://rovitals.com/game/97598239454123) · [BloxBunny](https://bloxbunny.com/games/10200395747/grow-a-garden-2) · [Profitable GaG2](https://profitable.app/roblox/games/grow-a-garden-2)
- 99 Nights: [PC Gamer](https://www.pcgamer.com/games/survival-crafting/with-a-peak-player-count-of-14-2-million-99-nights-in-the-forest-has-an-audience-other-multiplayer-games-would-kill-for-to-find-these-behemoth-playerbases-you-need-to-be-on-a-platform-like-roblox/) · [games.gg](https://games.gg/news/99-nights-forest-14-million-roblox/) · [Rolimons](https://www.rolimons.com/game/79546208627805) · [RoMonitor](https://romonitorstats.com/experience/79546208627805/) · [BloxPrices](https://www.bloxprices.com/roblox-top-earning-games/) · [StealWhatWorks](https://stealwhatworks.com/blogs/news/roblox-games-over-10k-month-now)
- +1 Speed Keyboard Escape: [Rolimons](https://www.rolimons.com/game/95082159892680) · [Bloxline](https://www.thebloxline.com/articles/1-speed-keyboard-escape-has-become-one-of-roblox-s-biggest-games-here-s-why-it-works) · [RblxTracker (X)](https://x.com/RblxTracker/status/2071231292637651446) · [Fandom](https://roblox.fandom.com/wiki/SecretVerse_Studio/%2B1_Speed_Keyboard_Escape) · [Docs Roblox ad placement](https://create.roblox.com/docs/production/ad-placements/1speed) · [Deathgamer](https://deathgamer.com/2026/06/02/1-speed-keyboard-escape-how-did-this-become-robloxs-8-game/) · [Earnaldo](https://earnaldo.com/blog/speed-keyboard-escape)
- Animal Hospital: [GosuGamers lanzamiento](https://www.gosugamers.net/entertainment/news/78741-animal-hospital-becomes-roblox-s-latest-horror-sensation-here-s-everything-you-need-to-know) · [GosuGamers 1,2 M](https://www.gosugamers.net/entertainment/news/78773-roblox-animal-hospital-hits-1-2-million-ccu-with-major-update-featuring-new-character-and-items) · [GosuGamers IA](https://www.gosugamers.net/entertainment/news/79296-roblox-s-animal-hospital-developer-apologises-for-using-ai-in-the-game-s-latest-update) · [Wiki](https://animalhospital.wiki/release/) · [YouTube](https://www.youtube.com/watch?v=EXdNlG2skyM)
- Escape Tsunami / Plants vs Brainrots: [RoWatcher](https://rowatcher.com/games/9363735110/escape-tsunami-for-brainrots) · [Profitable](https://profitable.app/roblox/games/escape-tsunami-for-brainrots) · [TS2](https://ts2.tech/en/robloxs-newest-phenomenon-plants-vs-brainrots-breaks-records-heres-why-everyones-obsessed/) · [Profitable PvB](https://profitable.app/roblox/games/plants-brainrots) · [RoWatcher PvB](https://rowatcher.com/games/8316902627/plants-brainrots)
- Blox Fruits: [Fandom](https://roblox.fandom.com/wiki/Gamer_Robot_Inc/Blox_Fruits) · [BloxSniper](https://bloxsniper.cc/games/994732206) · [Profitable](https://profitable.app/roblox/games/blox-fruits) · [BloxPrices](https://www.bloxprices.com/stats/blox-fruits/) · [Rotrends](https://www.rotrends.com/game/994732206/RED-EVENT-Blox-Fruits) · [RoLearn](https://rolearn.dev/insights/roblox-creator-earnings-how-much-developers-make/)
- Adopt Me: [Wikipedia](https://en.wikipedia.org/wiki/Adopt_Me!) · [Rival Ducks](https://rivalducks.com/apps/radar/games/383310974-adopt-me) · [Profitable](https://profitable.app/roblox/games/adopt-me)
- Brookhaven: [RoWatcher](https://rowatcher.com/games/1686885941/brookhaven-rp) · [Silicon Canals](https://siliconcanals.com/?p=59578) · [Profitable](https://profitable.app/roblox/games/brookhaven-rp) · [Earnaldo](https://earnaldo.com/blog/brookhaven-rp-free-robux-guide)
- Murder Mystery 2: [Rotrends](https://rotrends.com/game/66654135) · [AllThingsHow](https://allthings.how/murder-mystery-2-events-schedule/) · [RoWatcher guía](https://rowatcher.com/news/what-is-murder-mystery-2-a-guide-to-roblox-s-legendary-social-deduction-game)
- Dress to Impress: [RoWatcher](https://rowatcher.com/news/dress-to-impress-how-a-teen-developer-s-fashion-game-hit-9-7-billion-visits) · [Profitable](https://profitable.app/roblox/games/dress-to-impress)
- RIVALS: [RoWatcher](https://rowatcher.com/news/rivals-how-roblox-s-top-shooter-built-a-nearly-million-player-empire) · [Profitable](https://profitable.app/roblox/games/rivals)
- Fisch / Sol's RNG / Pet Simulator 99 / TDS / The Forge: [RoWatcher Fisch](https://rowatcher.com/games/5750914919/fisch-save-nate/dying) · [Profitable Fisch](https://profitable.app/roblox/games/fisch) · [Profitable Sol's RNG](https://profitable.app/roblox/games/sol-s-rng) · [games.gg Sol's RNG](https://games.gg/news/sols-rng-roblox-codes-for-march-2026/) · [AllThingsHow PS99](https://allthings.how/pet-simulator-99-saturday-update-schedule/) · [AllThingsHow TDS](https://allthings.how/tower-defense-simulator-events-schedule/) · [Rotrends The Forge](https://www.rotrends.com/game/7671049560/The-Forge-BETA)
- Clones y mercado: [RoWatcher: ¿cuántos juegos hay en Roblox en 2026?](https://rowatcher.com/news/how-many-games-are-on-roblox-in-2026) · [GameSpot: clon "brainrot" de Roblox en las listas de Fortnite](https://www.gamespot.com/articles/a-brainrotted-roblox-clone-is-dominating-the-fortnite-charts/1100-6534047/) (solo título; no lo leí)
