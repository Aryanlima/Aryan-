# Economía de creadores de Roblox y mecánicas de monetización (informe a 2026-10-20)

Área: economía y monetización. Contexto: crear muchos juegos de Roblox con microtransacciones. Idioma: español.

---

## 0. Cómo leer este informe (leyenda y límites del método)

**Etiquetas de fiabilidad**

| Etiqueta | Significado |
|---|---|
| **[OFICIAL]** | Dato atribuido a una fuente de Roblox (create.roblox.com, devforum, help center, newsroom) o a la SEC (8-K, 10-Q, 10-K). Ver limitación de abajo. |
| **[TERCERO]** | Prensa, blogs, calculadoras, analistas. Si es prensa seria que retransmite un dato de Roblox, se indica. |
| **[DERIVADO]** | Cálculo propio a partir de datos citados. No es una cifra publicada por nadie. |
| **[NO VERIFICADO]** | Fuente única, contradictoria, sin fuente primaria, o conocimiento general del analista que no pude comprobar en esta sesión. |

**Limitaciones importantes (honestidad metodológica)**

1. **No pude abrir ninguna página primaria.** `WebFetch` devolvió `ENOTFOUND` para sec.gov, roblox.com (create, devforum, help, about), q4cdn, investing.com, stocktitan, marketscreener y gloom.sh. No eludí el proxy. Todo lo marcado **[OFICIAL]** proviene de **resúmenes del buscador que citan esas páginas** (la URL oficial aparece en los resultados, pero yo no leí la página completa). Por eso, cuando una cifra es crítica, indico "verificar en la página".
2. **Se agotó el presupuesto de búsquedas del turno** (límite compartido de 200) justo antes de cerrar tres temas: (a) Sponsored Ads / Immersive Ads con cifras, (b) beneficios y pagos de Roblox Plus, (c) psicología de precios con datos duros. Esas secciones se apoyan en las fuentes ya recogidas y en criterio general del analista, y están marcadas como tal. No se inventó ninguna cifra.
3. Los resúmenes del buscador a veces mezclan fechas o cifras (ya detecté varios casos, ver sección 2.3). Donde hay conflicto lo indico en vez de elegir en silencio.

---

## 1. Resumen ejecutivo

1. **Tarifa de cobro real:** Roblox se queda con el 30% de las ventas dentro de la experiencia (el creador recibe 70% en "Robux ganados"). Esos Robux se cobran por DevEx a **US$0,0038 por Robux ganado** (desde 5-sep-2025; antes US$0,0035). Resultado: por cada 100 R$ que gasta un jugador, el creador cobra **≈ US$0,266** (tarifa estándar). Roblox lo expresa como "26,6% de ganancia efectiva" [OFICIAL] (coincide con 70% × 0,0038 / 0,01; ver 2.1).
2. **La cifra de US$0,0054 existe, pero NO es la tarifa general.** Aplica solo al gasto cualificado de jugadores de EE. UU. de 18+ con edad verificada, en juegos elegibles (marco de avatar R15 / humanoide), desde el 8-jun-2026 (+42% sobre ese gasto). No cubre ítems de avatar [OFICIAL].
3. **El mercado es extremadamente concentrado.** En los 12 meses hasta 30-jun-2026: ~US$1,7 mil millones pagados por DevEx, +42.000 creadores en DevEx, **mediana ≈ US$1.500 por participante al año**, top 1.000 con ~US$1,3–1,4 M de media y top 10 con US$65,7 M de media [TERCERO-prensa que retransmite datos de Roblox]. Para un portafolio de juegos pequeños, **la mediana es la expectativa realista, no el top**.
4. **Viento en contra a corto plazo:** en el Q2 2026 los *bookings* subieron solo 8% y Roblox guió el Q3 2026 a **−14% / −18% interanual**, atribuyéndolo a menor monetización por hora (sobre todo menores de 13 en EE. UU./Canadá) y a un algoritmo de descubrimiento que prioriza retención sobre monetización [OFICIAL vía resúmenes del 8-K y de la llamada]. Implicación: diseñar para **retención primero, monetización después**.
5. **Nuevas barreras para publicar a escala (2026):** Roblox Plus (US$4,99/mes, lanzado 30-abr-2026) o una **tarifa única de 1.000 R$ por juego (reembolsable a los 3 meses)** para publicar a todas las edades tras una evaluación de calidad/engagement. Esto encarece el modelo "cientos de juegos" y favorece el modelo "pocos juegos con tracción" (sección 5).
6. **Ya no existen los "Premium Payouts"**: fueron reemplazados por **Creator Rewards** el 24-jul-2025. Muchos blogs de 2026 siguen describiendo el sistema antiguo.

---

## 2. Cuánto cobra realmente el creador

### 2.1 Cascada de dinero (de lo que paga el jugador a lo que cobra el creador)

Fórmula base (ventas de pases, productos, suscripciones y servidores privados dentro de tu experiencia):

```
USD cobrados = R$ gastados por el jugador × 0,70 × tarifa DevEx
  tarifa estándar        = 0,0038 USD / R$ ganado
  tarifa 18+ EE. UU.     = 0,0054 USD / R$ ganado (solo gasto cualificado)
```

- 70% = parte del creador en ventas propias de pases [OFICIAL: [Create docs, "Monetize your games"](https://create.roblox.com/docs/monetize-experiences)]. Roblox retiene el 30% restante.
- Roblox declara "ganancia efectiva" de 26,6% (estándar) y 37,8% (18+ EE. UU.) [OFICIAL: [DevForum 18+](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091)]. **[DERIVADO]:** 0,70 × 0,0038 / 0,01 = 26,6% y 0,70 × 0,0054 / 0,01 = 37,8%, es decir, Roblox calcula contra un Robux nominal de US$0,01. Sobre el dinero real que paga el jugador (que depende del canal de compra y su comisión) el porcentaje efectivo puede ser menor [NO VERIFICADO].
- Solo cuentan para DevEx los **Robux ganados** (no los comprados) [OFICIAL: [Create docs, Monetize](https://create.roblox.com/docs/monetize-experiences)].

**Tabla de pricing escalonado: lo que cobra el creador por venta [DERIVADO]**

| Precio al jugador (R$) | R$ ganados (70%) | USD a 0,0038 (estándar) | USD a 0,0054 (18+ EE. UU. cualificado) |
|---:|---:|---:|---:|
| 49 | 34,3 | 0,13 | 0,19 |
| 99 | 69,3 | 0,26 | 0,37 |
| 199 | 139,3 | 0,53 | 0,75 |
| 499 | 349,3 | 1,33 | 1,89 |
| 999 | 699,3 | 2,66 | 3,78 |
| 1.999 | 1.399,3 | 5,32 | 7,56 |

Ejemplo de objetivo: cobrar US$100/mes netos exige ≈ 37.600 R$ brutos gastados al mes en tu juego (100 / 0,00266) **[DERIVADO]**, antes de impuestos locales.

### 2.2 Tarifa DevEx: qué es oficial y qué no

| Tema | Estado | Detalle y fuente |
|---|---|---|
| Tarifa estándar actual: **US$0,0038 / R$ ganado** | **[OFICIAL]** | Desde el 5-sep-2025 (10:00 PT). 30.000 R$ = US$114. [DevForum: "Increasing DevEx"](https://devforum.roblox.com/t/increasing-devex-%E2%80%94-creators-will-now-earn-85-more/3920159), [Help Center DevEx](https://en.help.roblox.com/hc/en-us/articles/13061189551124-Developer-Exchange-Help-and-Information-Page). Un tercero con fecha 15-oct-2026 la sigue citando como vigente ([BloxToolbox](https://bloxtoolbox.com/pages/tools/devex-cashout-calculator.html), **[TERCERO]**). |
| Tarifa anterior: US$0,0035 | **[OFICIAL]** | Vigente hasta el 5-sep-2025. Los Robux ganados antes de esa fecha se cobran a la tarifa antigua (Roblox: "Robux earned from 10 AM PT on Sept 5, 2025 onward cash out at $0.0038"). Muchos blogs y calculadoras siguen usándola por inercia. |
| Tarifa especial: US$0,0054 | **[OFICIAL] pero condicional** | Ver 2.3. |
| Cuota de Roblox ~30% | **[OFICIAL]** | Creador recibe 70% en ventas propias. |

### 2.3 Resolución de las contradicciones encontradas en blogs

| Afirmación en blogs | Veredicto | Evidencia |
|---|---|---|
| "La tarifa DevEx es US$0,0035 / US$0,0038 / US$0,0054" (tres cifras distintas) | **Las tres son reales pero de épocas/ámbitos distintos.** 0,0035 = antigua. 0,0038 = estándar vigente. 0,0054 = solo gasto cualificado 18+ EE. UU. | Documentos citados arriba. Lo falso es presentar 0,0054 como la tarifa general. |
| "Subida del 8,5% el 5-sep-2025" | **CONFIRMADO [OFICIAL]** | 0,0038 / 0,0035 = +8,57%. Roblox: "all creators earn about 8.5% more" ([DevForum](https://devforum.roblox.com/t/increasing-devex-%E2%80%94-creators-will-now-earn-85-more/3920159)). El 8-K del Q2 2026 atribuye el aumento de las "DevEx fees" a esa subida ([SEC 8-K Q2 2026, ex. 99.1](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm)). Un resumen secundario lo describe como "para creadores 18+": **parece un error**; el anuncio dice que es para todos. |
| "+42% para gasto de usuarios 18+ verificados en EE. UU. desde el 8-jun-2026" | **CONFIRMADO [OFICIAL], con condiciones** | Ganancia efectiva de 26,6% a 37,8% = +42% (US$0,38 a US$0,54 por 100 R$ ganados). Solo para gasto de jugadores **con edad verificada ≥18 y ubicación económica en EE. UU.**, en **juegos elegibles** que usen el marco de avatar **R15** (humanoide estándar/avanzado, o personajes humanoides personalizados; los juegos sin avatar o con avatar personalizado tienen reglas adicionales por publicar). Cubre pases, suscripciones en Robux, productos de desarrollador y servidores privados; **no** ítems de avatar. Elegibilidad automática, sin aplicar y sin restricción de país del creador. Fuentes: [DevForum](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091), [Create docs 18+](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate), [Newsroom Roblox](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42); prensa: [Tubefilter](https://www.tubefilter.com/2026/05/01/roblox-hikes-developer-earnings-by-42-but-only-if-they-make-games-aimed-at-adults/), [Net Influencer](https://www.netinfluencer.com/roblox-to-raise-developer-exchange-rate-for-games-aimed-at-18-plus-players-as-adult-cohort-surges/). **No es +42% sobre tus ingresos totales**, solo sobre esa fracción. Las fuentes discrepan sobre el detalle exacto del requisito R15 (hay un tercero más laxo, [devex.gg](https://devex.gg/18-plus-devex-rate), **[NO VERIFICADO]**) y Tubefilter lo enmarca como "juegos novedosos" (**[NO VERIFICADO]**). El hilo del DevForum tiene actualizaciones hasta el 12-oct-2026: revisar la versión actual. |
| "Recorte del reparto de ítems 2D de 70% a 30%" | **CONFIRMADO en lo esencial [OFICIAL + prensa]; matices sin resolver** | Cambio efectivo ~14-jul-2026 al "unificar la publicación de ítems 2D y 3D" ([DevForum](https://devforum.roblox.com/t/building-stronger-protections-and-a-more-consistent-marketplace-unifying-2d-and-3d-avatar-item-publishing/4722717)). Según [Blox News](https://bloxnetwork.org/news/article/roblox-unifies-2d-and-3d-clothing-rules-in-major-marketplace-overhaul) y [Tech Insider](https://tech-insider.org/roblox-2d-creator-revenue-share-cut-2026/) (**[TERCERO]**): el creador del ítem pasa de 70% a 30%, un 40% va al dueño de la experiencia donde se vende (o a "descubrimiento", según críticos) y quien vende su propia ropa en su propia experiencia conserva 70% total. Hubo petición ([Change.org](https://www.change.org/p/protect-roblox-clothing-creators-revenue-share)) y hilos de reversión ([DevForum](https://devforum.roblox.com/t/revert-changes-to-the-2d-clothing-update/4732289)). Un único artículo ([FFBooyah, 15-jul-2026](https://ffbooyah.com/2026/07/15/the-roblox-2d-clothing-update-what-actually-happened-and-why-it-matters/)) afirma un modelo progresivo posterior: **[NO VERIFICADO]**. **No afecta a pases/productos/suscripciones**, solo a ítems de avatar 2D. |
| "Desde el 30-abr-2026 hace falta suscripción Plus para publicar experiencias" | **PARCIALMENTE VERDADERO; simplificación engañosa** | Roblox Plus (US$4,99/mes) se lanzó el 30-abr-2026 ([Help Center Plus](https://en.help.roblox.com/hc/en-us/articles/47967913158164-Roblox-Plus), [DevForum](https://devforum.roblox.com/t/introducing-roblox-plus/4567894)). La regla de publicación ([DevForum](https://devforum.roblox.com/t/new-publishing-requirements-evaluation-process-for-games/4573166), [AMA](https://devforum.roblox.com/t/ama-publishing-requirements-roblox-kids-select/4580953)) exige suscripción (Plus **o Premium**, cualquier nivel) para publicar a **todas las edades**, y solo **después de pasar la evaluación** para Roblox Select/Kids. Después, en mayo-2026, Roblox añadió una alternativa: **tarifa única de 1.000 R$ por juego**, reembolsada a los 3 meses si el juego sigue activo y sin acciones de moderación; no se paga si llevas 2 meses seguidos con Plus/Premium (efectivo "desde junio") ([DevForum: alternativas](https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944), [Help Center publicar](https://en.help.roblox.com/hc/en-us/articles/203313890-How-to-Publish-Games-on-Roblox)). Juegos ya publicados no se ven afectados. Detalles todavía en disputa: umbral de engagement (Help Center: ~250 jugadores únicos muy comprometidos, con edad verificada y 16+, en 60 días; [BloxBot](https://bloxbot.ai/guide/roblox-new-publishing-requirements-2026) dice 500), si hay que resuscribirse para *actualizar* ([hilo de queja](https://devforum.roblox.com/t/requiring-roblox-plus-to-update-not-publish-games-that-would-otherwise-meet-the-active-requirements-is-needlessly-burdensome-to-developers/4581903)), y la afirmación de que "Premium deja de venderse" (**[NO VERIFICADO]**). |

### 2.4 Elegibilidad, tiempos, impuestos

| Aspecto | Dato | Fiabilidad y fuente |
|---|---|---|
| Edad mínima | 13+ | **[OFICIAL vía resumen]** [Create docs DevEx](https://create.roblox.com/docs/production/monetization/developer-exchange) |
| Mínimo para cobrar | **30.000 R$ ganados** (≈ US$114 a 0,0038) | **[OFICIAL]** |
| Otros requisitos listados | Email verificado, cuenta en el portal DevEx, formulario fiscal **W-9 (EE. UU.) o W-8 (resto)** en archivo | **[OFICIAL vía resumen]** |
| Premium/Plus para DevEx | La página oficial **no** lo lista; guías de terceros se contradicen | **[NO VERIFICADO]**, ver [rolearn.dev](https://rolearn.dev/guidance/roblox-devex-requirements-2026/) (ejemplo de conflicto) |
| ID gubernamental | Terceros lo exigen; la lista oficial resumida no lo menciona. Sí se exige ID verificada para Audience Expansion Rewards y para el pago de acceso pagado en dinero real | **[NO VERIFICADO]** para DevEx general; **[OFICIAL]** para Rewards/paid access |
| Mínimo "100.000 R$" (algún blog) | Contradice el oficial de 30.000 | Descartado |
| Países soportados | **No encontré lista**; el acceso a la lista oficial está bloqueado | **[NO VERIFICADO]** (comprobar en el portal DevEx y en los [Términos DevEx](https://en.help.roblox.com/hc/en-us/articles/115005718246-Developer-Exchange-Terms-of-Use)). Roblox decide la elegibilidad al pedir el cobro (a su discreción, según los Términos). |
| Pasarela | Tipalti (transferencia bancaria/ACH, PayPal, wire) | **[TERCERO]** (varias guías) |
| Plazos | Revisión de Roblox ≈10 días hábiles el primer cobro y ≈5 los siguientes, más tiempo bancario (total 1–4 semanas según guías) | **[TERCERO]** |
| Retención/impuestos para no estadounidenses | Con W-8BEN, retención de hasta 30% salvo convenio fiscal; depende del país de residencia | **[TERCERO]/[NO VERIFICADO]**, consultar a un asesor fiscal de tu país |
| Posible cambio 1-nov-2026 (W-9 inválido → retención de respaldo 24% en EE. UU.) | Una sola fuente ([Panstag](https://www.panstag.com/2026/10/roblox-devex-tax-change.html)) | **[NO VERIFICADO]**, comprobar en Creator Hub, sección Taxes |
| Umbral del 1099 | Un blog dice US$600; otra fuente indica US$2.000 para años posteriores a 2025 | **[NO VERIFICADO]**; solo relevante si eres contribuyente de EE. UU. |

---

## 3. Formas de monetizar (qué es, comisión, cuándo usarla, precios típicos)

> Comisión base: Roblox retiene **30%** en ventas dentro de la experiencia, salvo donde se indica. Rangos de precios = **orientación de terceros/criterio del analista, no datos oficiales** salvo que se marque.

| # | Mecanismo | Qué es | Comisión / reparto | Cuándo usarlo | Precios típicos (R$) |
|---|---|---|---|---|---|
| 1 | **Game pass** | Compra única y permanente (multiplicadores, auto-collect, VIP, armas, zonas). | Creador 70% en pases propios **[OFICIAL]** ([docs](https://create.roblox.com/docs/monetize-experiences)). | Ventajas permanentes. Es la base de simuladores, tycoons y obbies. | Pase principal 99–199; impulso <50; ancla 500–1.000 **[TERCERO]** ([rolearn](https://rolearn.dev/guidance/roblox-gamepass-pricing-strategy-guide/), [ugccraft](https://ugccraft.com/blog/roblox-game-passes-pricing-guide/), [generalistprogrammer](https://generalistprogrammer.com/tutorials/roblox-game-monetization-complete-revenue-strategy-guide)). |
| 2 | **Developer product** | Compra repetible y consumible (moneda, revivir, boosts temporales, cajas, packs). | 70% (misma lógica) **[OFICIAL por docs generales; cifra exacta vía resumen]**. | Todo lo que se pueda comprar muchas veces. Es el motor del ARPPU de los pagadores frecuentes. | 25–999+; ladder típico 49/99/199/499/999/1.999 **[NO VERIFICADO: práctica de la industria]**. |
| 3 | **Suscripción dentro de la experiencia** | Beneficios recurrentes mensuales. Desde 2026 se puede pagar en **Robux** y fijar precio en Robux o moneda local. | Creador 70% el primer mes y en todas las renovaciones. Subidas de precio con aviso de 30 días; bajadas al siguiente ciclo **[OFICIAL]** ([DevForum](https://devforum.roblox.com/t/let-your-players-pay-for-subscriptions-within-experiences-in-robux/4552995)). Elegibles todos los creadores. | VIP mensual, pase de temporada/battle pass, estipendio diario de moneda. Ingreso recurrente predecible. | No se confirmó un mínimo ni los niveles; no hay rangos fiables **[NO VERIFICADO]**. |
| 4 | **Servidores privados** | Alquiler mensual de un servidor propio. | Suscripción mensual en Robux; el precio determina lo que ganas; solo se puede cambiar el precio cada 60 días y al hacerlo se cancelan las suscripciones activas **[OFICIAL]** ([docs](https://create.roblox.com/docs/production/monetization/private-servers)). Los suscriptores de Roblox Plus quedan limitados a un servidor privado gratuito por juego (algunos creaban miles, lo que perjudicaba a los creadores que cobran por ellos) **[TERCERO]** ([PCGamesN](https://www.pcgamesn.com/roblox/plus-private-server-limit)); redacción ambigua, **[NO VERIFICADO]** el alcance exacto. | Juegos sociales/roleplay y con eventos de grupos. Casi irrelevante en simuladores. | Fijado por el creador; el rango "5–100" proviene de sitios de baja calidad, **no usar**. |
| 5 | **Creator Rewards** (sustituye a los Premium Payouts / Engagement-Based Payouts desde 24-jul-2025) | **Recompensa diaria:** 5 R$ cuando un "Active Spender" (gastó ≥US$9,99 en 60 días) pasa ≥10 min en tu juego (si es de los 3 primeros que abre ese día). **Audience Expansion:** 35% de reparto sobre los primeros US$100 en Robux comprados por usuarios nuevos o reactivados (inactivos ≥60 días), con retención de 60 días. | Sin tope, cobro tras 60 días de retención. Audience Expansion exige cuenta con ID verificada, cuenta DevEx válida y **100 DAU de media** en el periodo de retención **[OFICIAL]** ([DevForum](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628), [docs](https://create.roblox.com/docs/creator-rewards), [Tubefilter](https://www.tubefilter.com/2025/06/24/roblox-creator-rewards-program-robux-for-engagement-retention/)). | Automático para todos los juegos. Premia tiempo de juego y captación; no depende de que el jugador compre. Los juegos pequeños (<100 DAU) quedan fuera de la parte de captación. | Los importes "5–15 R$" por usuario/día de algunos blogs son **[NO VERIFICADO]**. |
| 6 | **Anuncios: Rewarded Video** | Anuncio de vídeo opcional a cambio de una recompensa en el juego (continuar, 2x, ítem). | Rev share Roblox–creador para *todas* las integraciones publicitarias **previsto para enero-2027** (detalles aún por cerrar) **[OFICIAL vía resumen]** ([DevForum políticas](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365)). En ago-2025 Roblox estimó que supondría "hasta el 3% de los ingresos del creador" al inicio y un objetivo de largo plazo de +5–10% ([DevForum](https://devforum.roblox.com/t/more-creators-can-now-use-rewarded-video-ads/3838678)). En mayo-2026, >1.200 juegos lo usaban ([DevForum](https://devforum.roblox.com/t/boost-your-game-earnings-with-rewarded-video-enhancements/4645335)). | Complemento para los jugadores que no pagan (la gran mayoría). Mejor en juegos de alto volumen y baja conversión. | No aplica precio; **cifras de 5–15% o 8–15% de terceros contradicen la oficial de ~3%: [NO VERIFICADO]**. |
| 7 | **Immersive Ads** (vallas, portales, opt-in video) | Anuncios nativos de marcas vendidos vía Ads Manager. | Los creadores ganan una parte; el modelo definitivo se fija con el rev share de 2027 **[TERCERO]** ([Endsights](https://endsights.com/roblox-immersive-ads)). Desde el 4-may-2026 las integraciones publicitarias independientes deben registrarse en Ads Manager y etiquetarse en Studio, migrando a formatos nativos **[OFICIAL vía resumen]**. | Solo con audiencias grandes. | Sin datos fiables. |
| 8 | **Sponsored Ads** (pagar para promocionar tu juego) | Es un **gasto**, no un ingreso: subastas en Ads Manager para ganar tráfico. | No pude buscar costes por clic/CPM actualizados (presupuesto de búsquedas agotado). | Útil cuando el LTV por jugador > coste de adquisición. Hay que medir ROAS por juego. | **[NO VERIFICADO]**: no usar cifras hasta consultarlo en Ads Manager. |
| 9 | **Acceso de pago (pay-to-play)** | Cobrar por entrar al juego. En Robux: pago único de **25 a 1.000 R$**; fondos en escrow hasta 7 días; sin servidores privados ni descarga de lugar. Requiere cuenta de ≥30 días y email verificado **[OFICIAL]** ([docs](https://create.roblox.com/docs/production/monetization/paid-access-robux)). Existe una variante en **dinero real** (2024) con reparto escalonado 50/60/70% según el precio (US$9,99/29,99/49,99), foto de ID verificada y Tipalti **[TERCERO]** ([TechCrunch](https://techcrunch.com/2024/09/06/roblox-introduces-new-earning-opportunities-for-creators-teases-generative-ai-project/), [Kidscreen](https://kidscreen.com/?p=218680)); se contradicen en los importes, **[NO VERIFICADO]**. | Varía | Experiencias narrativas, de terror o premium. Mal encaje con "muchos juegos F2P". | 25–1.000 R$ **[OFICIAL]**. |
| 10 | **Ítems de avatar / UGC** | Vender ropa y accesorios en el Marketplace o dentro de tu experiencia. | Reparto estándar ~70% (3D, **[NO VERIFICADO] vigente**). Ropa 2D: ver 2.3 (30% creador, 40% experiencia vendedora según terceros). Requiere cuenta/verificaciones adicionales **[TERCERO]**. | Línea secundaria si tu juego tiene tienda de avatar. | Variable. |
| 11 | **Regalos entre jugadores** | Comprar un pase/producto para otro jugador. | No pude verificar si existe una función nativa vigente y su reparto. | — | **[NO VERIFICADO]** |
| 12 | **Roblox Plus / Premium** | Suscripción del jugador (Plus US$4,99/mes). Para el creador, el Premium se monetiza vía Creator Rewards (Active Spenders). | — | — | Beneficios exactos de Plus y pagos a creadores: **[NO VERIFICADO]** (búsqueda agotada). |

Nota técnica (práctica general, **[NO VERIFICADO]** en esta sesión): para productos de desarrollador, usar `MarketplaceService.ProcessReceipt` con idempotencia y guardado antes de conceder el ítem; las compras duplicadas o perdidas destruyen la confianza y generan reembolsos.

---

## 4. Benchmarks

### 4.1 Plataforma (cifras oficiales de Roblox)

| Métrica | Valor | Fuente / fiabilidad |
|---|---|---|
| DAU Q2 2026 | 123 M (+10% interanual) | [SEC 8-K Q2 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) **[OFICIAL vía resumen]** |
| Horas Q2 2026 | 29 mil millones (+5%) | Ídem |
| Bookings Q2 2026 | ≈ US$1.557 M (+8%), "US$1,6 mil M", extremo bajo de la guía | [Investing.com](https://www.investing.com/news/company-news/roblox-q2-2026-slides-revenue-rises-36-as-bookings-growth-stalls-93CH-4826381), [VirtWave](https://www.virtwave.com/industry-news/roblox-statistics) **[TERCERO]** del dato oficial |
| Ingresos Q2 2026 | ≈ US$1,5 mil M (+36%; diferido) | **[OFICIAL vía resumen]** |
| **DevEx fees (pagos a creadores) Q2 2026** | **US$363 M (+15% interanual)** ≈ 23% de los bookings **[DERIVADO]** | **[OFICIAL vía resumen]** (8-K) |
| DevEx fees Q1 2026 | US$423 M (+50%) | **[TERCERO]** (resumen de un 8-K que no pude abrir) |
| ABPDAU Q2 2026 (bookings por DAU, trimestral) | US$12,66 (−2% interanual) | **[TERCERO]**; hay un US$13,35 que parece ser un valor regional |
| Bookings diarios por DAU | **US$0,14** (Q2 2026); US$0,15 (Q1 2026); US$0,15 (FY2025) | **[OFICIAL vía resumen]** [10-Q Q2 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051082/rblx-20260630.htm), [10-Q Q1 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028904/rblx-20260331.htm) |
| Bookings diarios por **usuario pagador único diario** | **US$10,42** (Q2 2026); US$10,17 (Q1 2026); US$10,36 (FY2025) | **[OFICIAL vía resumen]** (mismos 10-Q y [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)) |
| Pagadores únicos mensuales (MUP) Q2 2026 | ≈ 27 M (+15%) | **[TERCERO]** ([SQ Magazine](https://sqmagazine.co.uk/roblox-statistics/)) |
| Guía Q3 2026 | Bookings **−14% a −18%** interanual; ingresos +4–10%; se retira la guía anual | **[OFICIAL vía resumen]**; causas: menor monetización por hora (menores, EE. UU./Canadá), mezcla de 2025 virales a juegos con menor monetización/hora, cambio de algoritmo hacia retención; fricción de verificación de edad = headwind "low single digit" en bookings; 57% de DAU con edad verificada ([Aardvark Labs](https://research.aardvarklabs.co/research/rblx/earnings/2026-q2/rblx-2026-q2-recap), [Yahoo Finance](https://finance.yahoo.com/markets/stocks/articles/roblox-corp-rblx-q2-2026-050249366.html)) |
| 18+ | Cohorte 18+ ≈ 1/3 de DAU con edad verificada; 18–34 en EE. UU. crece ~40–50% interanual y monetiza >50% más que menores de 18 | **[OFICIAL vía resumen]** (llamada Q2, DevForum) |

**[DERIVADO]** Pagadores diarios ≈ 0,14 / 10,42 ≈ **1,3–1,5% de los DAU** (rango por el redondeo de los dos datos). Es plataforma entera, bookings brutos (antes de la parte de Roblox) y arrastrado por los "ballenas": la media es muy superior a la mediana por juego.

### 4.2 Ingresos de creadores 2025–2026

| Dato | Valor | Fuente / fiabilidad |
|---|---|---|
| DevEx pagado en 2025 | **US$1.503 M** (+63% vs US$922,8 M en 2024) | **[OFICIAL vía resumen del 10-K]** ([10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)); concuerda con [Statista](https://statista.com/statistics/1376672/roblox-developer-payout) **[TERCERO]** |
| Creadores registrados en DevEx a 31-dic-2025 | >35.500 (>10.500 nuevos en 2025); >23.500 recibieron pagos en 2025 | **[OFICIAL vía resumen del 10-K]** |
| Q4 2025 | Récord US$477 M (+70%) | **[TERCERO]** (retransmite comunicado de Roblox: [Threads](https://www.threads.com/@lindseygamble_/post/DUf3DVrkwJ5/in-creators-have-earned-over-billion-through-robloxs-developer-exchange-dev-ex)) |
| Top 1.000 creadores 2025 | ≈ US$1,3 M de media (+50%) | **[TERCERO-prensa]** ([Sherwood News](https://sherwood.news/business/the-top-1-000-roblox-creators-earned-an-average-of-usd1-3-million-last-year/)) |
| **12 meses hasta 30-jun-2026** | ≈ **US$1,7 mil M** vía DevEx (+~50%); >42.000 creadores en DevEx; **mediana ≈ US$1.500** (año anterior: US$1.440 con >29.000 participantes); top 10 = US$65,7 M de media (antes US$33,9 M); top 100 = US$10,8 M; top 1.000 ≈ US$1,3–1,4 M (las fuentes difieren) | **[TERCERO-prensa seria]** que retransmite la divulgación de Roblox: [TechSpot](https://www.techspot.com/news/113855-roblox-top-creators-making-65-million-year-while.html), [TweakTown](https://www.tweaktown.com/news/113585/robloxs-top-10-creators-averaged-dollars65-7-million-each-while-the-median-made-dollars1500-and-roblox-everywhere-is-the-fix/index.html), [Dexerto](https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/), [IBTimes](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403) |

**[DERIVADO]** Con esos datos: top 10 = US$657 M ≈ **39%** del total de DevEx del periodo; top 1.000 ≈ US$1,3–1,4 mil M ≈ **76–82%** (siempre que los promedios y el total estén en la misma base). El resto (~41.000 creadores) se reparte ≈ 18–24% y la mediana cae a US$1.500/año. Importante: **la mediana es solo de quienes ya pasaron el umbral de DevEx (30.000 R$)**; la gran mayoría de los creadores de Roblox ni siquiera llega a cobrar.

**Estacionalidad en datos oficiales:** DevEx Q4 2025 US$477 M, Q1 2026 US$423 M, Q2 2026 US$363 M: caída secuencial (Q4 > Q1 > Q2) **[DERIVADO]** de cifras oficiales/prensa. Ver 5.5.

### 4.3 Benchmarks por juego (conversión, ARPPU, ARPDAU)

Roblox define en su analítica: **conversion rate** = % de DAU que son pagadores; **ARPPU** = ingreso medio por pagador; **ARPDAU** = ingreso medio por DAU = conversión × ARPPU **[OFICIAL]** ([Create docs, Monetization analytics](https://create.roblox.com/docs/production/analytics/monetization)). Roblox no publica benchmarks por género.

| Métrica | Valor | Fuente y fiabilidad |
|---|---|---|
| Informe GameAnalytics 2026 (500+ juegos con ≥1 M MAU, ago-2025 a jul-2026) | D1 mediana **10,3%**; D7 **1,6%**; D30 **0,5%**; sesión mediana **9,8 min** (P75 12 min, P90 14,7 min); top 1%: D1 22,2%, D7 9,1%, D30 4,7% | [GameAnalytics 2026](https://www.gameanalytics.com/reports/2026-roblox-report) (**[TERCERO]**, fuente primaria de datos de industria, extractos vía resumen). Es una muestra de juegos **grandes**; para un juego nuevo es una vara alta. |
| Idem, monetización | **3,80%** de jugadores gastó algo en el año; pagador mediano gastó US$0,81 en el año; ARPPU mediano US$0,70, top 10% US$2,33, top 5% US$4,80, top 1% US$55,31 | [Mellow / GameDevReports](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox), [RRQ World](https://blog.rrqworld.com/roblox-game-retention/) **[TERCERO de un TERCERO]**; las cifras de ARPPU y "gasto anual" parecen usar definiciones distintas: **[NO VERIFICADO]** como pareja |
| GameAnalytics 2025 | Gasto concentrado: el pagador mediano gasta <US$1 (por día activo) y el top 5% supera US$20; la brecha subió de 20x a más de 30x. Juegos con sesiones de 0–6 min son frágiles (D1 <10%, ARPPU casi nulo); 19+ min son los "hits" | [GameAnalytics 2025](https://www.gameanalytics.com/reports/2025-roblox-report) **[TERCERO]** |
| Conversión de pagadores (blogs) | 1–3% media y >5% excelente; otra guía 3–5% media; tycoons ~3%, obbies ~0,8%; un post del DevForum considera 0,66% con ~31 R$ por pagador como bajo | **[TERCERO débil]**: [rolearn](https://rolearn.dev/guidance/monetization-fundamentals/), [ugccraft](https://ugccraft.com/blog/roblox-game-passes-pricing-guide/), [calculatorsuniverse](https://calculatorsuniverse.com/blog/roblox-game-revenue-genre-conversion-explained), [DevForum](https://devforum.roblox.com/t/best-way-to-increase-arppu-in-my-game-with-a-066-conversion-rate/2875348). Coherentes con el ~1,3–1,5% de plataforma (4.1), pero **sin base de datos verificable**. |
| ARPDAU | "US$0,05–0,15 por DAU" (glosario de terceros) | **[TERCERO débil]**. El oficial de plataforma, US$0,14 bruto/día, cae dentro de ese rango |
| Robux por visita (RPV) | Obbies/sociales 0,1–0,4; mid-core 0,6–1,2; simuladores/gacha agresivos 2–6; "sano" ~0,8; referencia comunitaria ~0,5 | **[TERCERO débil]** ([Huntlox](https://www.huntlox.com/blog/how-much-do-roblox-games-make), [calculatorsuniverse](https://calculatorsuniverse.com/blog/roblox-game-revenue-genre-conversion-explained)): calculadoras, no datos de Roblox |

### 4.4 Ingresos por 1.000 visitas y por 1.000 DAU **[DERIVADO]**

USD cobrados = visitas × RPV × 0,70 × 0,0038 (0,00266 USD por R$ bruto). No incluye impuestos locales ni el 18+ EE. UU.

| RPV (R$ brutos por visita) | Perfil típico (terceros) | USD por 1.000 visitas | USD por 1 M de visitas |
|---:|---|---:|---:|
| 0,1 | obby/social flojo | 0,27 | 266 |
| 0,4 | obby/social bueno | 1,06 | 1.064 |
| 0,5 | referencia comunitaria | 1,33 | 1.330 |
| 0,8 | juego sano general | 2,13 | 2.128 |
| 1,2 | mid-core bueno | 3,19 | 3.192 |
| 2,0 | simulador agresivo | 5,32 | 5.320 |
| 6,0 | techo de gacha/simulador | 15,96 | 15.960 |

**Visitas necesarias al mes para cobrar un objetivo neto [DERIVADO]:**

| Objetivo neto/mes | R$ brutos necesarios | Visitas/mes con RPV 0,5 | Visitas/mes con RPV 2,0 |
|---:|---:|---:|---:|
| US$100 | ≈ 37.600 | ≈ 75.200 | ≈ 18.800 |
| US$500 | ≈ 188.000 | ≈ 376.000 | ≈ 94.000 |
| US$2.000 | ≈ 752.000 | ≈ 1,5 M | ≈ 376.000 |
| US$10.000 | ≈ 3,76 M | ≈ 7,5 M | ≈ 1,9 M |

**Promedio de plataforma por DAU [DERIVADO]:** US$363 M / (123 M DAU × 91 días) ≈ **US$0,032 por DAU-día**, es decir ≈ **US$32 por 1.000 DAU al día** o ≈ US$970 al mes para un juego de 1.000 DAU con la monetización *media* de la plataforma. Cuidado: la media está arrastrada por los mayores juegos y por ítems de avatar, y los DevEx fees son lo cobrado, no lo ganado. La mediana de un juego pequeño será bastante inferior (coherente con la mediana de creador de US$1.500 al año).

### 4.5 Juego mediano vs. top

| Nivel | Qué dicen los datos | Fuente |
|---|---|---|
| Creador mediano en DevEx | ≈ US$1.500/año ≈ US$125/mes (suma de **todos** sus juegos) | **[TERCERO-prensa]** |
| Top 1.000 | ≈ US$1,3–1,4 M/año ≈ US$110–117 mil/mes de media | **[TERCERO-prensa]** |
| Top 10 | ≈ US$65,7 M/año de media (juegos virales construidos en meses; Roblox cita Grow a Garden y Steal a Brainrot como ejemplos de "éxito explosivo", con >20 M de jugadores simultáneos, pero **no revela** quiénes son los 10) | [IBTimes](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403) **[TERCERO]**. Estimaciones de ingresos por juego de [Profitable.app](https://profitable.app/roblox/developers) son **[NO VERIFICADO]**. |

---

## 5. Diseño de tienda y psicología de precios

> Fuentes: la parte de datos duros es escasa. Casi todo viene de guías de terceros y de criterio de la industria; lo marco. **Todo precio de abajo es una hipótesis para A/B test, no un dato.**

### 5.1 Lo que sí sostienen las fuentes

- **Pase principal en 99–199 R$**, uno barato (<50 R$) para el comprador impulsivo y **un pase caro ancla (500–1.000 R$)** que hace que los intermedios parezcan baratos **[TERCERO]** ([rolearn](https://rolearn.dev/guidance/roblox-gamepass-pricing-strategy-guide/), [ugccraft](https://ugccraft.com/blog/roblox-game-passes-pricing-guide/)).
- **Auto-collect y "2x" de ingresos** son los pases más vendidos en tycoons/simuladores porque el valor es inmediato y constante; en obbies convierten mejor "saltar etapa" y cosméticos **[TERCERO]**.
- **El precio óptimo se encuentra testeando**: lo que no se vende a 200 puede venderse a 75; un desarrollador reportó caída del 40% de DAU en una semana por subir agresivamente precios (anecdótico, **[NO VERIFICADO]**).
- **Retención y descubrimiento**: Roblox declaró en el Q2 2026 que su algoritmo da más impresiones a juegos con alta retención aunque moneticen menos por hora. Un diseño que cobra pronto y daña la retención se penaliza doblemente **[OFICIAL vía resumen]**.
- Los usuarios de EE. UU. de 18+ monetizan >50% más que los menores y tienen tarifa DevEx mejorada (sección 2.3): un diseño para adultos con R15 puede dar más dólares por R$ gastado.

### 5.2 Escalera de precios sugerida (hipótesis del analista [NO VERIFICADO])

| Escalón | R$ | Función psicológica | Ejemplo de producto |
|---|---:|---|---|
| Impulso | 25–49 | Primera compra sin fricción; convierte a "no pagador" en pagador (gran predictor de futuras compras) | Pack pequeño de moneda, mascota común, 1 revivir |
| Entrada | 99 | Punto de entrada "estándar" | Pase 2x moneda, pack de bienvenida |
| Valor | 199 | Mejor relación valor/precio visible | Auto-collect, pack de boosts |
| Fuerte | 499 | El ancla de gasto medio | Pase VIP, pack grande |
| Premium | 999 | Para el pagador frecuente | Paquete "todo incluido" (que no sea pay-to-win irrecuperable) |
| Ballena | 1.999+ | Ancla alta y vía para los de mayor gasto | Pack fundador, ítem exclusivo estético |

La escalera 49/99/199/499/999/1.999 que propone el usuario es razonable como punto de partida. Cobro por escalón en 2.1.

### 5.3 Mecánicas típicas y su encaje

| Mecánica | Cómo se usa | Riesgo/límite |
|---|---|---|
| **Oferta de bienvenida / starter pack** (única, a precio muy bajo en la 1.ª sesión) | Convertir al jugador temprano; mostrar al llegar a un "momento de necesidad" (primera muerte, primer cuello de botella) | Fricción en D1; no bloquear el tutorial |
| **2x / multiplicadores / auto-collect** | Pases permanentes (valor percibido constante) | Subir demasiado el ritmo de progresión sin ellos frustra y daña la retención |
| **Boosts temporales** (productos de desarrollador) | Compra repetida para pagadores frecuentes | Evitar que el pase permanente y el boost se canibalicen |
| **VIP / suscripción mensual** | Suscripción en Robux (70% desde el mes 1) con estipendio diario y cosmético exclusivo | Subidas de precio: aviso de 30 días **[OFICIAL]** |
| **Ofertas limitadas / estacionales** | Eventos (Halloween, Navidad, verano) con ítems exclusivos | Los temporizadores de presión sobre menores son un riesgo de reputación y de política; mantenerlos honestos (**[NO VERIFICADO]** como norma) |
| **Pase de temporada / battle pass** | No hay un battle pass nativo; se implementa con pase/suscripción + progreso guardado | Requiere contenido constante y buena gestión de datos |
| **Gacha / cajas aleatorias (RNG)** | Altísimo RPV en simuladores (2–6 R$/visita según terceros) | **Límites legales y de plataforma** (siguiente tabla) |

### 5.4 Gacha/RNG: límites legales y de plataforma **[NO VERIFICADO: conocimiento general, no se pudo buscar]**

- Roblox exige, según recuerdo, **divulgar las probabilidades** de los ítems aleatorios de pago y restringe/prohíbe su venta en algunas jurisdicciones (se han citado Bélgica y Países Bajos); la política vigente debe consultarse en la política de "Paid Random Items" de Roblox.
- Hay regulación creciente sobre cajas aleatorias para menores (por ejemplo, se ha mencionado Brasil, y se debate en España y la UE). Dado que los juegos de Roblox tienen audiencia mayoritariamente menor de edad, **tratar el gacha como riesgo regulatorio y reputacional**, no solo comercial.
- Recomendación: preferir ofertas deterministas (el jugador sabe qué compra) o mecánicas con **"pity"/garantía** y probabilidades visibles, y evitar el gacha en los títulos orientados a niños.
- **Prohibido por política general de Roblox:** simulaciones de casino/apuestas con dinero real o intercambio de Robux por premios externos; comprobar los Estándares de la Comunidad antes de añadir cualquier "ruleta".

### 5.5 Estacionalidad

- Datos: el récord de pagos a creadores fue el Q4 2025 (US$477 M), seguido de Q1 y Q2 2026 en descenso (4.2). El Q3 2026 se guía en caída fuerte frente a un Q3 2025 muy inflado por juegos virales **[OFICIAL/TERCERO]**.
- Hipótesis estándar **[NO VERIFICADO]**: picos en vacaciones de verano del hemisferio norte (jun–ago) y diciembre-enero (tarjetas regalo); caída en septiembre. Para público hispanohablante, el calendario escolar de Latinoamérica difiere (verano austral dic–feb); **medir con tu propia analítica**.

---

## 6. Modelo de portafolio: muchos juegos pequeños vs. pocos grandes

### 6.1 Lo que dicen los datos

| Hecho | Implicación | Fiabilidad |
|---|---|---|
| Ingresos extremadamente concentrados (top 10 ≈ 39%, top 1.000 ≈ 76–82% de DevEx; mediana US$1.500/año) | El resultado típico de un juego pequeño es ≈ 0. El portafolio funciona como "opciones": pocos aciertos pagan todo | **[DERIVADO]** sobre cifras de prensa |
| Los dos mayores éxitos recientes se construyeron "en meses" y alcanzaron >20 M de jugadores simultáneos | Los aciertos ocurren con equipo y ritmo de iteración altos, no solo por volumen | **[TERCERO]** |
| Roblox quiere dar impresiones a los juegos que retienen (Q2 2026) y guió bookings a la baja | Los clones de baja retención no recibirán tráfico; el descubrimiento premia retención | **[OFICIAL vía resumen]** |
| Publicar a todas las edades exige evaluación + (Plus **o** tarifa única de 1.000 R$ por juego, reembolsable a los 3 meses) + verificación de edad + 2FA; evaluación ≈ 250 jugadores únicos muy comprometidos en 60 días (según el Help Center) | Coste marginal de cada juego nuevo mayor que antes; el volumen "a ciegas" pierde atractivo | **[OFICIAL vía resumen]** con discrepancia de umbral |
| Creator Rewards (captación) exige ~100 DAU de media | Los juegos <100 DAU no acceden a esa fuente | **[OFICIAL vía resumen]** |
| Cobro mínimo 30.000 R$ ganados por cobro y 60 días de retención en Rewards | Retraso de caja en proyectos pequeños | **[OFICIAL vía resumen]** |
| Roblox restringe (Plus) los servidores privados y el contenido de baja calidad | Riesgo de moderación a escala; los reembolsos de la tarifa de publicación dependen de no tener acciones de moderación | **[TERCERO]** / **[OFICIAL vía resumen]** |

**[DERIVADO] Coste de la tarifa de publicación:** 1.000 R$ ≈ US$3,80 a la tarifa DevEx estándar (si se paga con Robux ganados), reembolsable. Es pequeño por juego, pero el coste real es tiempo, la ventana de 60 días y el riesgo de no pasar el umbral.

### 6.2 Comparativa

| Criterio | Muchos juegos pequeños | Pocos juegos grandes |
|---|---|---|
| Coste por intento | Bajo en código si reutilizas plantillas, pero con tarifa/verificaciones por juego | Alto, concentrado |
| Probabilidad de acierto | Mayor número de "boletos", cada uno con baja probabilidad | Menor número, mayor calidad por boleto |
| Descubrimiento | El algoritmo premia retención: los juegos flojos no escalan | Más margen para pulir retención y contenido |
| Rewards y ads | Muchos no superan 100 DAU | Sí |
| Riesgo de moderación/reputación | Alto si hay clones o spam | Menor |
| Fatiga de mantenimiento | Soporte multiplicado por N | Concentrado |
| Aprendizaje | Rápido (más experimentos de precios/género) | Más lento |

### 6.3 Recomendación para el portafolio (estrategia por etapas, hipótesis)

1. **Fase de experimentación (N pequeño):** 5–10 prototipos cortos de géneros distintos, con una **plantilla común de tienda/analítica/guardado de datos** (la parte reutilizable que sí escala).
2. **Puertas de decisión por juego (a 2–4 semanas):** retención D1 ≥ ~10%, sesión ≥ ~10 min, conversión de pagadores ≥ ~1–3%, RPV ≥ ~0,5 (referencias de la mediana de juegos grandes y de calculadoras; **son varas altas y no de Roblox**).
3. **Escalar solo los que pasan** (contenido, eventos, suscripción, localización). **Matar** el resto sin tarifa adicional.
4. **Presupuestar la tarifa de 1.000 R$** y vigilar que no haya sanciones de moderación para recuperarla.
5. **No construir sobre una sola palanca de ingreso:** pases + productos + suscripción + Rewarded Video (cuando haya rev share) + Creator Rewards.
6. **Dato propio manda:** tras los primeros 10 lanzamientos, recalcular probabilidad de éxito y RPV real; las cifras de arriba son prior débiles.

---

## 7. Menú de monetización recomendado

> Hipótesis de partida para A/B test, ordenadas por prioridad de implementación. Los precios son ladder sugerido, no datos. Todo lo comercial depende de retención: **nada de muros de pago en el tutorial**.

| Prioridad | Producto | Tipo | Precio inicial (R$) | Por qué | Cobro neto por venta (std / 18+ EE. UU.) |
|:--:|---|---|---:|---|---|
| 1 | **Pack de bienvenida** (una vez; moneda + mascota/cosmético) | Pase o producto único | 49–99 | Convierte al no pagador; precio de impulso | US$0,13–0,26 / 0,19–0,37 |
| 2 | **2x moneda / 2x XP** (permanente) | Game pass | 199 | El pase "universal" que más convierte, según terceros | US$0,53 / 0,75 |
| 3 | **Auto-collect / auto-farm** | Game pass | 99–199 | Comodidad con valor inmediato y constante | US$0,26–0,53 / 0,37–0,75 |
| 4 | **Packs de moneda** (3 escalones) | Developer products | 99 / 499 / 1.999 | Motor del ARPPU de pagadores repetidos; ladder de ancla | US$0,26 / 1,33 / 5,32 |
| 5 | **Boosts temporales** (15–60 min) | Developer products | 49–199 | Compra repetible, bajo compromiso | US$0,13–0,53 |
| 6 | **VIP mensual** (estipendio diario, cosmético, tag) | Suscripción en Robux | 199–499 al mes (**hipótesis; sin rango oficial**) | Ingreso recurrente; 70% desde el mes 1 | US$0,53–1,33 por mes |
| 7 | **Pase de temporada** (3–6 semanas) | Pase/suscripción + progreso | 499–999 | Retención + ingresos de contenido; reiniciar por temporada | US$1,33–2,66 |
| 8 | **Ancla premium / Fundador** | Game pass | 999–1.999 | Hace "baratos" a los intermedios; capta la cola alta | US$2,66–5,32 |
| 9 | **Cosméticos de avatar propios** | UGC / ítems | variable | Línea secundaria si hay tienda | **[NO VERIFICADO]** |
| 10 | **Rewarded Video** (2x temporal, revivir, "Join with Reward") | Anuncios | — | Monetiza a los no pagadores; rev share previsto en ene-2027 | Sin cifra fiable |
| 11 | **Servidores privados** (solo en juegos sociales) | Suscripción mensual | fijado por el creador | Útil en roleplay/sociales | — |
| — | **Gacha/cajas aleatorias** | — | — | **No recomendado por defecto** (riesgo legal, reputacional y de plataforma) | — |

**Reglas de diseño**

1. **Primera compra < 5 minutos de juego** en un momento de necesidad, no en pantalla de carga.
2. **Todo pagado debe dar valor visible**; evitar que la progresión gratuita sea inviable (daña D1/D7 y el descubrimiento).
3. **No cambiar precios cada semana**; testear por cohortes y con tamaño de muestra suficiente.
4. **Tienda clara y honesta** (menores como audiencia principal): sin temporizadores falsos ni confusión entre moneda y Robux.
5. **Idioma y precio locales:** localización al español; probar precios más bajos en regiones de menor poder adquisitivo (**[NO VERIFICADO]**).
6. **Instrumentación desde el día 1:** DAU, D1/D7/D30, sesión, conversión, ARPPU, RPV, embudo de tienda. Las cifras oficiales de plataforma (US$0,14 por DAU-día; ≈1,3–1,5% de pagadores diarios) sirven solo como techo de sentido común.
7. **Si el público objetivo incluye adultos de EE. UU.** (18–34, creciendo 40–50% interanual), valorar **R15/humanoide** para optar a US$0,0054 por R$ ganado en ese gasto.

---

## 8. Dudas abiertas y qué verificar a mano (cuando haya acceso a las páginas primarias)

1. **Tarifa DevEx y mínimos vigentes:** Help Center DevEx y [Create docs DevEx](https://create.roblox.com/docs/production/monetization/developer-exchange) (por si cambió algo tras el 15-oct-2026).
2. **Elegibilidad detallada de la tarifa 18+ EE. UU.:** [Create docs 18+](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate); en particular cómo se aplica a juegos sin avatar o con avatares personalizados.
3. **Orden de aplicación** si el saldo mezcla Robux de varias tarifas (0,0035, 0,0038, 0,0054): un resumen lo menciona pero no pude confirmarlo.
4. **Países soportados por DevEx, retenciones y necesidad (o no) de Premium/ID:** [Términos DevEx](https://en.help.roblox.com/hc/en-us/articles/115005718246-Developer-Exchange-Terms-of-Use) y portal DevEx. Comprobar con un asesor fiscal la retención para tu país.
5. **Publicación:** umbral exacto de evaluación (250 vs 500), si hace falta Plus para *actualizar*, y el estado de la tarifa de 1.000 R$ ([Help Center publicar](https://en.help.roblox.com/hc/en-us/articles/203313890-How-to-Publish-Games-on-Roblox)).
6. **Sponsored Ads, Immersive Ads y rev share de enero-2027:** costes por clic/CPM y porcentaje definitivo (búsquedas agotadas).
7. **Roblox Plus:** beneficios, relación con Premium (¿Premium deja de venderse?) y pagos a creadores.
8. **Política de ítems aleatorios de pago** y normativa local (España/LatAm) sobre cajas aleatorias para menores.
9. **Cifras oficiales exactas del Q2 2026** (bookings, DevEx, ABPDAU, MUP): abrir el [8-K Q2 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm), el [10-Q](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051082/rblx-20260630.htm) y la [carta a accionistas](https://s27.q4cdn.com/984876518/files/doc_financials/2026/q2/Roblox-Q2-2026-Earnings-Shareholder-Letter.pdf). Hoy dependen de resúmenes.
10. **Estado actual del reparto de ítems 2D** (¿modelo progresivo?).
11. **Fuente primaria de los 12 meses hasta 30-jun-2026** (mediana US$1.500, top 10/100/1.000): hoy solo prensa que lo retransmite.

---

## 9. Fuentes

**Roblox / SEC (URL devuelta por el buscador; contenido visto solo en extractos)**
- [DevForum: Increasing DevEx, creators earn 8.5% more](https://devforum.roblox.com/t/increasing-devex-%E2%80%94-creators-will-now-earn-85-more/3920159) (sep-2025)
- [Help Center: Developer Exchange](https://en.help.roblox.com/hc/en-us/articles/13061189551124-Developer-Exchange-Help-and-Information-Page) · [Términos DevEx](https://en.help.roblox.com/hc/en-us/articles/115005718246-Developer-Exchange-Terms-of-Use) · [Create docs DevEx](https://create.roblox.com/docs/production/monetization/developer-exchange)
- [DevForum: US 18+ DevEx Rate](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091) · [Create docs 18+](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate) · [Newsroom Roblox, abr-2026](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42)
- [Create docs: Monetize your games](https://create.roblox.com/docs/monetize-experiences) · [Analítica de monetización](https://create.roblox.com/docs/production/analytics/monetization) · [Servidores privados](https://create.roblox.com/docs/production/monetization/private-servers) · [Acceso de pago en Robux](https://create.roblox.com/docs/production/monetization/paid-access-robux)
- [DevForum: Suscripciones en Robux](https://devforum.roblox.com/t/let-your-players-pay-for-subscriptions-within-experiences-in-robux/4552995)
- [DevForum: Creator Rewards](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628) · [Create docs Creator Rewards](https://create.roblox.com/docs/creator-rewards) · [Engagement-based payouts (deprecado)](https://create.roblox.com/docs/production/monetization/engagement-based-payouts)
- Anuncios: [Nuevas políticas publicitarias](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365) · [Rewarded Video](https://devforum.roblox.com/t/more-creators-can-now-use-rewarded-video-ads/3838678) · [Mejoras Rewarded Video](https://devforum.roblox.com/t/boost-your-game-earnings-with-rewarded-video-enhancements/4645335)
- Publicación/Plus: [Help Center Roblox Plus](https://en.help.roblox.com/hc/en-us/articles/47967913158164-Roblox-Plus) · [Introducing Roblox Plus](https://devforum.roblox.com/t/introducing-roblox-plus/4567894) · [Nuevos requisitos](https://devforum.roblox.com/t/new-publishing-requirements-evaluation-process-for-games/4573166) · [AMA](https://devforum.roblox.com/t/ama-publishing-requirements-roblox-kids-select/4580953) · [Requisitos alternativos](https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944) · [Help Center: publicar](https://en.help.roblox.com/hc/en-us/articles/203313890-How-to-Publish-Games-on-Roblox)
- Ítems 2D: [DevForum: Unificación 2D/3D](https://devforum.roblox.com/t/building-stronger-protections-and-a-more-consistent-marketplace-unifying-2d-and-3d-avatar-item-publishing/4722717)
- SEC: [8-K Q2 2026 ex. 99.1](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) · [10-Q Q2 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051082/rblx-20260630.htm) · [10-Q Q1 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028904/rblx-20260331.htm) · [8-K Q1 2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028882/ex991-q12026earningsshar.htm) · [Carta Q4 2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000009/ex991-q42025shareholder.htm) · [10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm) · [Carta Q2 2026 (IR)](https://s27.q4cdn.com/984876518/files/doc_financials/2026/q2/Roblox-Q2-2026-Earnings-Shareholder-Letter.pdf)

**Prensa y análisis**
- [Tubefilter, 18+ rate (1-may-2026)](https://www.tubefilter.com/2026/05/01/roblox-hikes-developer-earnings-by-42-but-only-if-they-make-games-aimed-at-adults/) · [Net Influencer](https://www.netinfluencer.com/roblox-to-raise-developer-exchange-rate-for-games-aimed-at-18-plus-players-as-adult-cohort-surges/) · [Tubefilter, Creator Rewards (jun-2025)](https://www.tubefilter.com/2025/06/24/roblox-creator-rewards-program-robux-for-engagement-retention/)
- Q2 2026: [Investing.com slides](https://www.investing.com/news/company-news/roblox-q2-2026-slides-revenue-rises-36-as-bookings-growth-stalls-93CH-4826381) · [Investing.com transcripción](https://www.investing.com/news/transcripts/earnings-call-transcript-roblox-q2-2026-beats-eps-but-shares-sink-on-bookings-93CH-4826338) · [Yahoo Finance highlights](https://finance.yahoo.com/markets/stocks/articles/roblox-corp-rblx-q2-2026-050249366.html) · [Aardvark Labs](https://research.aardvarklabs.co/research/rblx/earnings/2026-q2/rblx-2026-q2-recap) · [VirtWave](https://www.virtwave.com/industry-news/roblox-statistics) · [SQ Magazine](https://sqmagazine.co.uk/roblox-statistics/)
- Ingresos de creadores: [TechSpot](https://www.techspot.com/news/113855-roblox-top-creators-making-65-million-year-while.html) · [TweakTown](https://www.tweaktown.com/news/113585/robloxs-top-10-creators-averaged-dollars65-7-million-each-while-the-median-made-dollars1500-and-roblox-everywhere-is-the-fix/index.html) · [Dexerto](https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/) · [IBTimes](https://www.ibtimes.co.uk/roblox-top-creators-devex-payouts-2026-1819403) · [Sherwood News](https://sherwood.news/business/the-top-1-000-roblox-creators-earned-an-average-of-usd1-3-million-last-year/) · [Statista](https://statista.com/statistics/1376672/roblox-developer-payout) · [Threads (cita de Roblox)](https://www.threads.com/@lindseygamble_/post/DUf3DVrkwJ5/in-creators-have-earned-over-billion-through-robloxs-developer-exchange-dev-ex)
- 2D: [Blox News](https://bloxnetwork.org/news/article/roblox-unifies-2d-and-3d-clothing-rules-in-major-marketplace-overhaul) · [Tech Insider](https://tech-insider.org/roblox-2d-creator-revenue-share-cut-2026/) · [FFBooyah](https://ffbooyah.com/2026/07/15/the-roblox-2d-clothing-update-what-actually-happened-and-why-it-matters/) · [Change.org](https://www.change.org/p/protect-roblox-clothing-creators-revenue-share) · [DevForum, revertir](https://devforum.roblox.com/t/revert-changes-to-the-2d-clothing-update/4732289)
- Plus/publicación: [BloxBot](https://bloxbot.ai/guide/roblox-new-publishing-requirements-2026) · [DevForum: queja sobre actualizar](https://devforum.roblox.com/t/requiring-roblox-plus-to-update-not-publish-games-that-would-otherwise-meet-the-active-requirements-is-needlessly-burdensome-to-developers/4581903) · [PCGamesN: límite de servidores privados](https://www.pcgamesn.com/roblox/plus-private-server-limit)
- Pago por acceso: [TechCrunch](https://techcrunch.com/2024/09/06/roblox-introduces-new-earning-opportunities-for-creators-teases-generative-ai-project/) · [Kidscreen](https://kidscreen.com/?p=218680)
- Benchmarks: [GameAnalytics 2026](https://www.gameanalytics.com/reports/2026-roblox-report) · [GameAnalytics 2025](https://www.gameanalytics.com/reports/2025-roblox-report) · [Mellow/GameDevReports](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox) · [RRQ World](https://blog.rrqworld.com/roblox-game-retention/)
- Guías y calculadoras (**[TERCERO débil]**): [rolearn: precios de pases](https://rolearn.dev/guidance/roblox-gamepass-pricing-strategy-guide/) · [rolearn: fundamentos](https://rolearn.dev/guidance/monetization-fundamentals/) · [rolearn: requisitos DevEx](https://rolearn.dev/guidance/roblox-devex-requirements-2026/) · [ugccraft](https://ugccraft.com/blog/roblox-game-passes-pricing-guide/) · [generalistprogrammer](https://generalistprogrammer.com/tutorials/roblox-game-monetization-complete-revenue-strategy-guide) · [calculatorsuniverse](https://calculatorsuniverse.com/blog/roblox-game-revenue-genre-conversion-explained) · [Huntlox](https://www.huntlox.com/blog/how-much-do-roblox-games-make) · [DevForum: conversión 0,66%](https://devforum.roblox.com/t/best-way-to-increase-arppu-in-my-game-with-a-066-conversion-rate/2875348) · [devex.gg 18+](https://devex.gg/18-plus-devex-rate) · [BloxToolbox](https://bloxtoolbox.com/pages/tools/devex-cashout-calculator.html) · [Panstag](https://www.panstag.com/2026/10/roblox-devex-tax-change.html) · [Endsights: Immersive Ads](https://endsights.com/roblox-immersive-ads)

*Fecha de consulta de todas las fuentes: 2026-10-20.*
