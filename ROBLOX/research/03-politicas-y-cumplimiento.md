# Roblox 2026: políticas, seguridad infantil y riesgos legales para publicar muchos juegos con microtransacciones

Fecha del informe: 2026-10-20. Área: cumplimiento de plataforma (para no perder juegos ni la cuenta).

> **Aviso (una sola vez):** esto es investigación de políticas públicas, no asesoría legal ni fiscal. Para impuestos, contratos y responsabilidad legal consulta a un profesional de tu país.

---

## 0. Cómo leer este informe

**Etiquetas de confianza**

- **[OFICIAL]** = lo leí directamente en la documentación oficial de Roblox para creadores (repositorio público `Roblox/creator-docs`, rama `main`, que es el origen de create.roblox.com/docs). Leído el 2026-10-20. Ojo: el repositorio puede ir unos días por delante o por detrás de la web publicada, y mi herramienta de lectura resume el texto con un modelo pequeño, así que **verifica las cifras críticas en Creator Hub** antes de decidir con dinero.
- **[TERCERO]** = noticia, blog, foro o resumen del buscador. Incluye páginas oficiales de Roblox (Help Center, DevForum, newsroom) que **no pude abrir** (hosts bloqueados) y solo conozco por el resumen del buscador. Cada una lleva su URL.
- **[NO VERIFICADO]** = inferencia mía, dato contradictorio entre fuentes o algo que no pude confirmar.

**Limitaciones de esta investigación**

- `create.roblox.com`, `devforum.roblox.com`, `about.roblox.com`, `en.help.roblox.com`, `sec.gov`, sitios de fiscalías y Wikipedia devolvieron error de red. No esquivé el bloqueo.
- Se agotó el presupuesto de búsquedas web antes de cerrar cuatro temas: (a) qué cambia exactamente en los Términos de Uso de noviembre 2026, (b) lista de países de DevEx y su cobertura en países hispanohablantes, (c) Brasil/ECA Digital y otros países que restringen o bloquean Roblox, (d) casos de baneos automáticos por assets. Quedan como dudas abiertas (sección 9).

---

## 1. Resumen ejecutivo (lo que más importa)

1. **Fecha límite inminente (11 días): impuestos de DevEx.** [OFICIAL] Si eres creador no estadounidense debes completar el formulario W-8BEN (persona) o W-8BEN-E (empresa) en Creator Hub > Finanzas > Impuestos **antes del 31 de octubre de 2026**. Desde el **1 de noviembre de 2026** los pagos de DevEx se clasifican como regalías y puede aplicarse retención. Sin información válida puede aplicarse una retención de respaldo de hasta 24 % sobre todo el pago. Con información válida, la retención es de 0 % a 30 % solo sobre la parte de fuente estadounidense (en general, compras de jugadores de EE. UU.), según tu país y tratado. Fuente: [tax-information.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/tax-information.md).
2. **Los juegos nuevos ya no llegan a todas las edades por defecto.** [OFICIAL] Sin pagar una tarifa reembolsable (1.000 Robux por juego) o mantener Roblox Plus/Premium 2 meses consecutivos, un juego nuevo solo se lanza a usuarios de 16+ con verificación de edad (etiqueta "Content May Vary"). Para llegar a Kids (5-8) y Select (9-15) además hay una evaluación (250 jugadas únicas de usuarios con edad verificada en 60 días). Fuente: [publish-games-and-places.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md) y [kids-and-select.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/kids-and-select.md).
3. **Tope de volumen explícito: 5 juegos nuevos por día.** [OFICIAL] Y los juegos casi idénticos a otros **no se priorizan** en recomendaciones; Roblox dice que reduce la exposición de contenido de baja calidad. Publicar "muchos juegos" solo funciona si cada uno es realmente distinto.
4. **Loot boxes (Paid Random Items) permitidas, pero con reglas duras.** [OFICIAL] Probabilidades numéricas de cada resultado antes de comprar (suman 100 %), ningún resultado sin valor, y bloqueo/alternativa por usuario con `PolicyService` (`ArePaidRandomItemsRestricted`, `IsPaidItemTradingAllowed`). Regiones citadas como reguladas: Australia, Bélgica, Países Bajos, Reino Unido y Brasil [TERCERO]. Los casinos y apuestas simuladas están prohibidos.
5. **Riesgo de cuenta único (todo cuelga de una cuenta).** [OFICIAL] Información de madurez inexacta, IP infringida, fraude con Robux o abuso de programas pueden llevar a moderar el juego **y la cuenta**. Hay quejas de desarrolladores sobre terminaciones graves [TERCERO, anecdótico].
6. **Presión legal creciente sobre menores y gasto.** [TERCERO] Según un seguimiento de terceros, al menos 10 fiscalías estatales de EE. UU. han demandado a Roblox (y otras investigan); la demanda de Iowa alega diseño que incentiva el gasto impulsivo de menores de 13 años sin consentimiento parental. Esto empuja a Roblox a restringir edades, chat y gasto, y a ti a diseñar tiendas sobrias.
7. **Nuevo incentivo económico hacia público adulto.** [OFICIAL] Desde el 8-jun-2026, el gasto de jugadores **estadounidenses de 18+ verificados** se paga a 0,0054 USD/Robux frente a 0,0038 estándar (+42 %), con condiciones de avatar (R15). Tiene sentido de negocio y de cumplimiento (menos exposición a menores).

---

## 2. Reglas de monetización

### 2.1 Paid Random Items (loot boxes, huevos, ruedas, cofres)

**Qué cuenta como Paid Random Item** [OFICIAL]: cualquier resultado aleatorio obtenido con Robux, directa o indirectamente (por ejemplo, gemas o tickets comprados con Robux y luego gastados en una ruleta). Cubre cápsulas (huevos, cofres), mejoras con azar (pociones, hechizos con probabilidad de fallo), combinaciones (fusionar objetos para un mejor resultado) y modificadores de probabilidad (boosts de suerte, pity systems, rate-up). Fuente: [paid-random-items.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-random-items.md) (ver también [create.roblox.com/docs/production/monetization/paid-random-items](https://create.roblox.com/docs/production/monetization/paid-random-items)).

**Obligaciones de divulgación** [OFICIAL]:

- Mostrar **antes de la compra** cada resultado posible con su probabilidad numérica real, en porcentaje, sumando 100 %. No sirven categorías como "raro/épico" sin porcentaje [TERCERO: resumen de la comunidad].
- Si la lista no cabe, ventana emergente con botón descriptivo ("Info", "Detalles"); un icono (i) solo **no basta**.
- Si muchos objetos comparten probabilidad, se puede indicar una vez arriba.
- Si un resultado solo puede obtenerse una vez por usuario, actualizar las probabilidades restantes.
- En compras indirectas (llaves, tickets, re-rolls), las probabilidades deben mostrarse **antes de gastar** esa moneda.
- Los objetos que modifican probabilidad deben explicar su efecto numérico y actualizar las probabilidades mostradas mientras estén activos.
- Exención: recompensas aleatorias ganadas jugando, sin pago en Robux ni moneda comprada con Robux, no requieren divulgación.
- Los paquetes que incluyen un objeto aleatorio convierten **todo el paquete** en Paid Random Item [TERCERO: resumen de [Community Standards](https://about.roblox.com/community-standards)].
- Los **pases promocionados** no pueden dar Paid Random Items [OFICIAL, [passes.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/passes.md)].

**Restricción por usuario con `PolicyService`** [OFICIAL]: consulta `PolicyService:GetPolicyInfoForPlayerAsync()` para cada jugador.

- `ArePaidRandomItemsRestricted = true`: el usuario no puede interactuar con generadores aleatorios pagados (ni con Robux ni con moneda comprada con Robux). Debes ofrecer una de estas salidas: camino gratuito ganable, orden fijo no aleatorio divulgado antes de comprar, venta directa del resultado a precio basado en su valor esperado, ocultar/eliminar el objeto, bloquear la compra con mensaje, o sacar al usuario de las zonas con estos objetos.
- `IsPaidItemTradingAllowed = false`: no permitir intercambio de resultados aleatorios ni de objetos pagados. Es una comprobación **separada** de la de adquisición.
- Todos los resultados deben dar algún beneficio (no puede haber un resultado en que el jugador solo pierda lo pagado) [TERCERO: [anuncio en DevForum](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622) según resumen del buscador].

**Contexto 2026** [TERCERO]:

- El DevForum publicó una aclaración de requisitos hacia finales de mayo 2026 (un resumen de terceros indica vigencia desde el 26-may-2026; fecha exacta [NO VERIFICADO]). Menciona probar con el Player Emulator de Studio para Australia, Bélgica, Países Bajos, Reino Unido y Brasil. Fuentes: [DevForum](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622), [ZehnStudio99](https://zehn-studio26.com/news/paid-random-items-odds-disclosure/).
- Una nota de prensa vincula la revisión a la ley de juegos de Corea del Sur, aplicada a nivel mundial: [TechTimes, 2026-06-26](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm).
- Existen anuncios previos de restricciones para usuarios del Reino Unido menores de 18 y para Australia ([UK](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183), [Australia](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-australian-users/3153602)); solo vi los títulos.

**Consecuencia práctica:** si tu plan de monetización depende de loot boxes, tendrás que implementar odds visibles + `PolicyService` + alternativa para cada juego, y aun así una parte del público (menores en países regulados) no podrá comprarlas. Un modelo con compras directas de objetos concretos es más simple y de menor riesgo [NO VERIFICADO: recomendación mía].

### 2.2 Gambling (casinos, apuestas, sitios de terceros)

- **Prohibido jugar apuestas, incluso simuladas.** [OFICIAL] "experiences cannot contain playable gambling content, including simulated gambling". Se define gambling como intercambiar dinero real, Robux u objetos de valor dentro del juego por un juego de azar. Se permite **representar** gambling no jugable (un casino decorativo, gente jugando cartas). Fuente: [experience-guidelines.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/experience-guidelines.md). Esa página está ligada al sistema antiguo de "guías por edad"; el cuestionario de madurez actual es [content-maturity.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md).
- **Zona gris:** una caja de botín pagada con Robux encaja en la definición amplia de azar por valor, pero Roblox la permite bajo la política de Paid Random Items. Casinos, apuestas entre jugadores (coin flip, crash, jackpot, ruleta con objetos de valor) y cualquier "apuesta" de Robux/objetos con premio mayor **quedan del lado prohibido** [NO VERIFICADO: lectura mía de ambas políticas; evítalo].
- **Sitios de apuestas de terceros:** Roblox dice prohibir todo gambling real o simulado y actúa contra cuentas y referencias a estos sitios [TERCERO: [iGamingExpert](https://igamingexpert.com/news/games/bloxflip-return-roblox/)]. No enlaces ni promociones sitios externos de apuestas.
- Un resumen indica que un tribunal federal de EE. UU. habría considerado a Robux "cosa de valor" bajo ley de California en el caso *Colvin v. Roblox*, lo que debilita el argumento de "dinero de juguete" [NO VERIFICADO; no encontré fuente primaria]. Si es cierto, aumenta el riesgo legal de cualquier mecánica de apuesta.
- Las Community Standards, según resumen del buscador, indican que no se puede intercambiar dinero real, Robux ni objetos de valor en relación con gambling, y que el mal uso de métodos de pago o Robux puede acarrear moderación [TERCERO: [Community Standards](https://about.roblox.com/community-standards)].

### 2.3 Presentación de tienda, "pay-to-win engañoso" y menores

Reglas leídas en [monetization/index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/index.md) [OFICIAL]:

- Presentar productos de forma "transparente, honesta y fácil de usar".
- Descuentos **reales** (no permanentemente "en oferta" al mismo precio) y justos (no ofrecidos solo brevemente para presionar).
- No afirmar que algo está por agotarse o es de tiempo limitado si no lo es. Temporizadores precisos, que **no se reinicien** automáticamente para el mismo objeto.
- No engañar, confundir ni presionar a usuarios para compras no deseadas.
- Promociones aptas para todo público por defecto.
- Para menores, evitar lenguaje urgente. Alternativas recomendadas: "View Item", "See Price", "Open Shop" en lugar de "¡BUY BEFORE IT'S GONE!".
- Ser transparente con mecánicas de azar y usarlas responsablemente.
- La documentación observa que los jugadores pueden votar negativamente juegos con monetización que desaprueben (es una guía, no una regla).

**Sobre "pay-to-win":** en las páginas oficiales que leí **no hay una prohibición expresa de pay-to-win** como tal. Lo que sí está prohibido es el engaño y la presión (arriba) [OFICIAL]. Las señales de descubrimiento de Roblox valoran juego diario, tiempo de juego, retención y luego gasto [OFICIAL, [discovery.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/discovery.md)], de modo que una tienda agresiva suele penalizar la retención.

**`PolicyService` es obligatorio** [OFICIAL]: determina por usuario si puede comprar suscripciones o commerce products, ver Paid Random Items, comerciar objetos pagados y ver anuncios (`AreAdsAllowed`). La elegibilidad depende de ubicación, edad y plataforma. Un mismo juego puede necesitar tienda distinta según el jugador.

**Otras obligaciones técnicas con efecto de cumplimiento** [OFICIAL]:

- Usa `ProcessReceipt` (no `PromptProductPurchaseFinished`). Roblox revisa tu implementación de forma continua y los productos con problemas dejan de mostrarse fuera de tu juego ([developer-products.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-products.md)).
- Roblox no guarda por ti el historial de compras de pases/productos; debes guardarlo (DataStore u otro).

### 2.4 Pases, productos, suscripciones, acceso pagado, commerce, transferencias

| Producto | Reglas relevantes [OFICIAL] | Fuente |
|---|---|---|
| Pases | Compra única; los promocionados deben costar entre 50 y 800 Robux (mayor que 49 y menor que 801) y cumplir Community Standards. **Desde el 30-may-2026 se desactivó la venta entre juegos (cross-game)** de pases y productos; integrar Robux Transfers. | [passes.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/passes.md) |
| Productos de desarrollador | Precio de 1 a mil millones de Robux. Si son recompensa aleatoria, aplica la política de Paid Random Items. | [developer-products.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-products.md) |
| Suscripciones | En Robux: abiertas a todos los creadores. En moneda local: cuenta verificada por ID o teléfono, no disponible en 12 países listados (incluye China, India, Japón, Türkiye). Beneficios iguales en todas las plataformas y honrados todo el plazo. **Prohibido** dirigir a comprar en otra plataforma desde la app. Sin reembolso automático. | [subscriptions.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/subscriptions.md) |
| Acceso pagado | Correo verificado y cuenta de 30+ días. 25-1.000 Robux. Sin reembolsos para el usuario. Sin servidores privados. No disponible en Xbox. Juego roto con muchos reportes puede ser puesto en cuarentena y reembolsarse lo retenido. | [paid-access-robux.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-access-robux.md) |
| Commerce products (compras en dinero real con Shopify) | Creador de 18+, ID verificado, 2FA, titular de la tienda Shopify. Solo compradores en EE. UU. (13+; 18+ en Texas). Requiere cuestionario de madurez. | [commerce-products.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/commerce-products.md) |
| Robux Transfers | Los suscriptores de Roblox Plus pueden enviar Robux desde un juego (10 a 500 por transacción); el juego se queda con 10 %. Roblox aplica sus propias comprobaciones de seguridad; el creador no controla la ejecución. | [robux-transfers.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/robux-transfers.md) |

**Regalos y comercio** [TERCERO]: el hilo del DevForum "Update on Roblox Plus, Transfers, and Community Gifting" ([enlace](https://devforum.roblox.com/t/update-on-roblox-plus-transfers-and-community-gifting/4637912)) describe el cierre de ventas entre juegos, la nueva API de Transfers y límites parentales de transferencia previstos para otoño 2026. Los límites numéricos (500/día y 1.000/mes por defecto; más con 2FA) vienen de guías de terceros: confírmalos en el Help Center antes de depender de ellos.

### 2.5 Anuncios (política de mayo 2026)

[OFICIAL, leído en creator-docs]:

- "Ad integrations" son anuncios fuera de los productos de Roblox (promocionar marca, producto, evento o llamada a acciones fuera de la plataforma, incluso merchandising propio). Deben cumplir Community Standards y Advertising Standards y estar **aprobados antes** de mostrarse. Registro en Ads Manager con al menos 5 días de antelación; moderación típica de hasta 48 h; requiere datos de facturación. Fuente: [ad-integrations.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/ad-integrations.md).
- Etiquetado visible "Ad" estandarizado. Video con recompensa solo a usuarios de 13+.
- **No se permiten servicios de publicidad de terceros** ni código que llame a servidores de anuncios externos; no bots ni engagement falso; no prometer "Robux gratis" para atraer clics. Incumplir puede suspender el juego o la cuenta y revocar pagos de tráfico fraudulento ([comply-with-advertising-standards.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/comply-with-advertising-standards.md)).
- `AreAdsAllowed` de `PolicyService`: si es falso debes ocultar, reemplazar o bloquear el anuncio para ese usuario.
- **Reparto de ingresos:** las campañas que empiecen desde el **1-ene-2027** pagan una cuota a Roblox por visitas calificadas (tarifas por mil visitas por nivel de país: 1,50 / 0,75 / 0,20 / 0,05 USD los primeros 28 días; luego 0,10) y hay un tope de 400.000 USD por campaña en 2027. No aplica a marcas que etiquetan sus propios assets en juegos propios.
- [TERCERO] Cambios del **4-may-2026** según prensa: los formatos de recompensa quedan prohibidos para menores de 13; no se sirven anuncios de comida, cosméticos, farmacia ni servicios financieros a menores de 13; los videos con recompensa independientes deben migrar al formato nativo de Roblox. Fuentes: [DevForum](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365) (la publicación tiene notas de actualización de abril y junio de 2026, así que las condiciones finales pueden diferir), [Advertising Integrations Terms](https://en.help.roblox.com/hc/en-us/articles/47656162239124-Advertising-Integrations-Terms), [Bloomberg, 2026-03-20](https://www.bloomberg.com/news/articles/2026-03-20/roblox-overhauls-ad-policies-in-bid-to-boost-sponsorship-revenue).

### 2.6 Fraude, Robux fuera de plataforma, enlaces externos y DevEx

- **Robux ganados vs. no ganados** [OFICIAL, [developer-exchange.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md)]: no cuentan como "Earned Robux" las compras directas de Robux, subvenciones mensuales de suscripciones, reventa/intercambio de objetos, Robux recibidos por transferencias, canjes de tarjetas regalo, **pases vendidos en juegos plantilla sin visitas legítimas** y contenido moderado por infracción. Las solicitudes pueden rechazarse por estafas, robo de cuentas o cambiar Robux fuera del programa. Una aprobación pasada no garantiza la siguiente.
- **Intercambio de Robux fuera de Roblox:** puede terminar la cuenta. Hay un caso de un desarrollador que dice haber sido terminado por "comprar/vender/intercambiar Robux" sin haberlo hecho (alega que terceros compraron por sus enlaces) [TERCERO, anecdótico: [DevForum](https://devforum.roblox.com/t/account-terminated-and-group-locked-for-alleged-buying-selling-or-trading-robux/4583341)]. Nunca vendas Robux, objetos o cuentas por dinero real fuera de Roblox, y no enlaces a sitios que lo hagan.
- **Términos de Uso:** según resumen del buscador de páginas oficiales, Roblox puede revocar Robux sin reembolso ante fraude o conducta ilegal asociada a la cuenta, y puede suspender o terminar cuentas, valorando gravedad e historial, incluso de inmediato sin aviso en casos graves ([Roblox Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use)) [TERCERO]. **Hay una actualización de los Términos con vigencia del 1-nov-2026** ([aviso](https://en.help.roblox.com/hc/en-us/articles/14663412502676-Roblox-is-Updating-our-Terms-of-Use), [DevForum](https://devforum.roblox.com/t/updates-to-the-roblox-terms-of-use-november-2026/4907620)). No pude leer qué cambia; léela antes de esa fecha. Hay afirmaciones virales (prohibición de VPN, baneos por ID de hardware) sin sustento verificable: trátalas como **[NO VERIFICADO]**.
- **Enlaces externos dentro del juego** [OFICIAL, [social-media-links.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/social-media-links.md)]: las redes sociales solo pueden enlazarse en la **página de detalles** del juego, no dentro del juego. Puedes decir "enlaces en la página del juego" pero **no** escribir la URL, el código de invitación ni el correo. Para añadir hasta 3 enlaces debes tener 16+ verificado por estimación facial o ID. Plataformas permitidas: Facebook, Twitter, YouTube, Twitch, Discord, Guilded, comunidad de Roblox.
- **Creator Rewards** [OFICIAL, [creator-rewards.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/creator-rewards.md)]: prohíbe bots, extensiones o manipulaciones para inflar visitas, fomentar cuentas alternas, suplantar a Roblox; posibles sanciones: pérdida de recompensas, expulsión del programa o terminación de la cuenta. Se pueden retener recompensas a cuentas con una tasa de contracargos desproporcionada.

---

## 3. Verificación de edad, cuentas por tramos y diseño de tiendas

### 3.1 Tramos de cuenta y verificación (estado 2026)

- **Tramos** [OFICIAL, [content-maturity.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md)]:

| Etiqueta del juego | Quién puede jugar |
|---|---|
| Minimal o Mild | Roblox Kids (5-8) y Roblox Select (9-15) |
| Moderate | Roblox Select (9-15) y cuentas estándar 16+ |
| Content May Vary | Solo usuarios de 16+ con edad verificada (age-checked) |
| Restricted | Solo usuarios de 18+ con verificación de edad completa (ID) |

- **Cronología** [TERCERO]: la estimación facial de edad pasó a ser obligatoria para usar el chat desde enero 2026 ([Help Center](https://en.help.roblox.com/hc/en-us/articles/43611824582292-How-to-chat-on-Roblox)); las cuentas Kids/Select se anunciaron el 13-abr-2026 ([TechCrunch](https://techcrunch.com/2026/04/13/roblox-introduces-kids-and-select-accounts-for-age-appropriate-access-to-games-and-chat/)) y llegaron a nivel global en junio 2026 ([newsroom](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available), [Help Center](https://en.help.roblox.com/hc/en-us/articles/48163847200532-What-are-Roblox-Kids-and-Roblox-Select)). Los límites de edad pueden variar por región.
- **Chat** [OFICIAL, [kids-and-select.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/kids-and-select.md)]: en Kids está apagado por defecto y solo lo activa una cuenta parental vinculada; en Select está apagado para cuentas sin edad verificada y se amplía gradualmente después de verificar la edad.
- **Control parental de gasto** [TERCERO, [Help Center](https://en.help.roblox.com/hc/en-us/articles/30428310121620-Parental-Controls-Overview)]: los padres pueden fijar un límite mensual de gasto (no cubre canje de tarjetas regalo); no hay límite por defecto. Los límites de transferencia de Robux y la aprobación parental de "amigos de confianza" están en despliegue (otoño 2026). Los padres también pueden usar el control "Approved Experience" para permitir juegos concretos a un menor [OFICIAL, kids-and-select.md].

### 3.2 Etiquetas de madurez y cuestionario (obligatorio por juego)

[OFICIAL, content-maturity.md y [safety.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/safety.md)]:

- **Todo juego público requiere el Maturity & Compliance Questionnaire** con respuestas basadas en "el contenido más maduro o extremo que un jugador puede encontrar". Si cambias el juego y cambia alguna respuesta, **debes reenviarlo**.
- **Juego sin etiqueta = restringido para todos los jugadores.** [OFICIAL] (El plazo del 30-sep-2025 para completar el cuestionario viene de un anuncio del DevForum [TERCERO]: [enlace](https://devforum.roblox.com/t/important-updates-unrated-experiences-and-changes-to-experience-pages/3899317).)
- **Información inexacta puede llevar a moderación del juego y de la cuenta del creador.**
- Para publicar solo a 16+ en la mayoría de regiones basta la primera pregunta; para Kids/Select o contenido específico por región hay que hacer el cuestionario completo.
- **Etiqueta Restricted:** requiere cuenta verificada como 18+ y no se puede cambiar (solo sus descriptores).
- **Descriptores que suben la edad mínima** [OFICIAL]: violencia fuerte, sangre realista intensa, lenguaje fuerte, temas románticos y alcohol requieren 18+ verificado; creación libre por usuarios requiere 16+; "social hangouts" 16+ sin espacios privados y 18+ con ellos.
- **IA en el juego:** cualquier interacción que dispare una respuesta de un modelo (chat, voz, imágenes, 3D) debe declararse en el cuestionario; los chatbots de conversación continua o con memoria entre sesiones exigen la etiqueta Restricted ([generative-AI.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/generative-AI.md)).

### 3.3 Requisitos del creador para llegar a Kids y Select [OFICIAL]

Fuente: [kids-and-select.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/kids-and-select.md) y [publish-games-and-places.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md).

1. Cuenta en buen estado (y con al menos 2 días de antigüedad para 16+).
2. Verificación: estimación facial de edad (menores de 18) o documento de identidad (18+).
3. Autenticación en dos pasos (2FA) activada.
4. Cuestionario completado: Kids = Minimal/Mild; Select también admite Moderate (9+).
5. Tarifa única reembolsable por juego (1.000 Robux) **o** Roblox Plus/Premium activo 2 meses consecutivos.
6. Pasar la evaluación: fase de prueba solo para 16+ verificados, análisis de engagement real, revisión de seguridad, y umbral de **250 jugadas únicas** de usuarios con edad verificada en 60 días. Se puede seguir en el panel Audience Reach. Los juegos gratuitos pueden calificar.
7. Revisión acelerada opcional: 50.000 Robux por juego, reembolsable.
8. En juegos de grupo los requisitos se aplican a través del dueño del grupo.

**Inconsistencias a revisar en Creator Hub** [NO VERIFICADO]:

- Una página dice que la tarifa se reembolsa si el juego mantiene "25 jugadores muy comprometidos durante 60 días sin moderación"; otra dice que se reembolsa a los 90 días de ser elegible. Y el umbral de elegibilidad es 250 jugadas. "Muy comprometido" no está definido.
- **No encontré la fecha de entrada en vigor** de la regla de 16+ por defecto ni si afecta a juegos publicados antes. El texto dice que la tarifa/suscripción hace falta "solo al publicar un juego nuevo o actualizar uno para audiencias de todas las edades".
- La tarifa no se devuelve si el juego es retirado de forma permanente por infracciones graves, así que un juego moderado cuesta además 1.000 Robux.

### 3.4 Qué significa para el diseño de tiendas y monetización

- **Mecánica de edad:** diseña una tienda base (compras directas, nada aleatorio, sin lenguaje de urgencia) válida para todos, y capas condicionales (loot boxes, comercio, anuncios, suscripciones) activadas solo si `PolicyService` lo permite.
- **Público 16+ por defecto:** los juegos nuevos sin tarifa solo llegan a 16+ verificados. El público que gasta más y está en la tarifa 18+ está ahí, pero el volumen de jugadores es menor que en las tiers de menores [NO VERIFICADO: inferencia mía; faltan datos de tamaño de audiencia].
- **Reducir descriptores para ampliar alcance:** sin social hangouts, creación libre, romance, alcohol, etc., puedes quedarte en Minimal/Mild (Kids+Select). Cada descriptor reduce la audiencia.
- **Tarifa 18+ de EE. UU.** [OFICIAL, [18-plus-devex-rate.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/18-plus-devex-rate.md)]: 0,0054 USD/Robux para compras (productos, pases, suscripciones, servidores privados) de jugadores de EE. UU. de 18+ verificados, desde el 8-jun-2026; exige que el 100 % del tiempo activo los personajes sean R15 de plataforma o personalizados que cumplan requisitos (hay una contradicción interna sobre el umbral de partes/uniones; confirma con Roblox). Roblox hace comprobaciones de fondo y un problema deja el juego inelegible hasta resolverlo.
- **Seguridad infantil en el diseño** [OFICIAL, safety.md]: filtrar todo texto de usuario visible a otros con `TextService.FilterStringAsync()` (si Roblox encuentra juegos sin filtrado pueden ser retirados hasta añadirlo); evitar entornos en espacios privados (dormitorios, baños), limitar camas, restringir ambientes de adultos (discotecas, bares) a 18+; usar `Player:IsVerified()` para funciones como rangos o comercio; revisar editores de avatar/ropa.
- **Moderación en vivo:** revisa el panel de Seguridad (Creator Dashboard > Safety) por picos de reportes. Usa `Players:BanAsync()` con motivo basado en políticas.

---

## 4. Moderación de contenido y assets: qué provoca baneos o retiradas

### 4.1 Causas documentadas [OFICIAL]

- Contenido que viola Community Standards (incluido el generado con IA) [generative-AI.md]. En tu responsabilidad: todo lo que muestren herramientas de IA de terceros.
- **Cuestionario de madurez incorrecto o desactualizado** (moderación del juego y la cuenta) [content-maturity.md].
- **Falta de filtrado de texto** (retirada del juego) [safety.md].
- **Infracción de IP**: Roblox retira el contenido infractor, y las cuentas con infracciones repetidas o graves pueden ser suspendidas, terminadas o bloqueadas. Se puede infringir aunque no ganes dinero, des crédito o creas que es uso legítimo. Las copias modificadas, **incluidas las alteradas con IA**, pueden denunciarse si reproducen la expresión protegida ([ip-guidelines.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/ip-guidelines.md)). No hay un sistema de "strikes" descrito formalmente.
- **Anuncios y programas:** incumplir las normas de anuncios o abusar de Creator Rewards puede suspender el juego o la cuenta ([comply-with-advertising-standards.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/comply-with-advertising-standards.md), creator-rewards.md).
- **Restricción por país:** Roblox puede restringir juegos o contenido concretos en un país si recibe solicitudes; el juego queda oculto e inaccesible allí sin afectar a otros países ([regional-content-availability.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/regional-content-availability.md)).

### 4.2 Copyright, marcas y clones

- **Marcas y clones de juegos:** la página de IP cubre copyright y marcas registradas; no trata "fan games" ni da una lista de marcas [OFICIAL]. Un juego que copia el nombre, logo, personajes o mecánicas protegidas de otro es denunciable por copyright/marca. Además, el sistema de descubrimiento no prioriza juegos cuyos metadatos y archivos se parezcan a otros existentes [OFICIAL, [discovery.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/discovery.md)]. Seguir una tendencia es aceptable "si aporta un giro distinto".
- **Proceso de denuncia y apelación:** los titulares denuncian por correo o plataforma de IP; el usuario puede presentar contranotificación (estilo DMCA, 17 U.S.C. § 512) y Roblox suele restaurar en 14 días hábiles salvo demanda; la UE tiene un canal propio (DSA) con apelación en 6 meses ([ip-guidelines.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/ip-guidelines.md), [dsa-ip-reporting.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/dsa-ip-reporting.md)). Los titulares de derechos usan Rights Manager para solicitar retiradas (hasta 250 enlaces por solicitud) ([rights-manager.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/rights-manager.md)).
- **Vía legítima para marcas:** el programa de licencias (catálogo de "Licenses") permite solicitar licencia de franquicias para un juego propio; socios iniciales: Lionsgate y Kodansha (por ejemplo, *Blue Lock*) ([ip-licensing/index.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ip-licensing/index.md)).
- **Memes con derechos / música:** la página de IP no menciona memes ni música. No encontré en las páginas leídas una regla específica sobre música de terceros; usa solo audio propio o de la biblioteca oficial del Creator Store y conserva pruebas de licencia [NO VERIFICADO: recomendación prudente]. Los assets del Creator Store pueden tener "dependencias restringidas" que no puedes redistribuir si no las subiste tú ([creator-store.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/creator-store.md)).

### 4.3 Riesgo de usar assets gratuitos del Creator Store

[OFICIAL, creator-store.md]: los modelos gratuitos pueden contener scripts que cargan otro código en tiempo de ejecución (`require(assetId)`, `loadstring`, `LoadAsset`), código ofuscado o scripts que se ejecutan solos. Desactiva scripts de lo que no revisaste (clic derecho > Disable Scripts). Hay un relato de un desarrollador que afirma que una terminación automática de cuenta por un "meme" extendido en el toolbox/Creator Store le costó unos 3 millones de Robux bloqueados [TERCERO, anecdótico, sin confirmación de Roblox: [DevForum](https://devforum.roblox.com/t/ai-is-terminating-accounts-over-a-meme-found-everywhere-in-toolboxcreator-store-3-million-robux-lost/4836607)]. Lección práctica: no reutilices assets de origen desconocido en juegos con ingresos.

### 4.4 Assets generados por IA

- [OFICIAL, generative-AI.md] Roblox exige que todo lo que muestres, incluso si lo generó una IA, cumpla Community Standards. Con las APIs de Roblox (`GenerationService`, `TextGenerator`) entradas y salidas se moderan; con herramientas de terceros **tú respondes** de todo lo entregado y no debes saltarte los sistemas de seguridad. Hay que avisar a los usuarios de que hablan con una IA y declarar estas interacciones en el cuestionario.
- La página **no** trata copyright ni restricciones sobre assets generados con IA [OFICIAL: ausencia]. Riesgo: una imagen generada que se parezca a un personaje/marca protegidos sigue siendo denunciable (ver ip-guidelines). Revisa cada imagen generada contra marcas y personajes conocidos.

---

## 5. Requisitos de la cuenta del creador: edad, identidad, DevEx, impuestos, países

### 5.1 Edad y verificación [OFICIAL salvo indicación]

| Qué | Requisito | Fuente |
|---|---|---|
| DevEx | 13+ años, correo verificado, 30.000 Earned Robux mínimo, cuenta del portal DevEx (Tipalti), formulario W-9/W-8, nombre legal correcto | [developer-exchange.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md) |
| Vendedor en Creator Store | 18+ (o 13-17 con consentimiento parental), 2FA, país soportado, cuenta individual (no de grupo) | [creator-store.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/creator-store.md) |
| Verificación por ID | 13+, documento con foto y móvil con cámara | [account-verification.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/account-verification.md) |
| Audience Expansion Rewards | cuenta con ID verificado y en buen estado | [creator-rewards.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/creator-rewards.md) |
| Commerce products | 18+, ID, 2FA | commerce-products.md |
| Publicar para todas las edades | verificación (estimación facial o ID), 2FA, tarifa/suscripción | kids-and-select.md |
| Enlaces sociales | 16+ verificado | social-media-links.md |

Nota: la página de verificación de cuentas dice que el teléfono no se usa para verificar; la de suscripciones en moneda local sí menciona "ID o teléfono". Hay contradicciones menores entre páginas [NO VERIFICADO].

### 5.2 DevEx: condiciones y dinero [OFICIAL]

- **Mínimo 30.000 Earned Robux** (a 0,0038 USD/Robux son 114 USD). Hay cifras de terceros de 100.000 Robux y Premium obligatorio que **contradicen** a Roblox: la documentación oficial no menciona Premium ni país en los requisitos.
- **Tarifas:** estándar 0,0038 USD/Robux; 0,0054 para gasto elegible de EE. UU. 18+; 0,0035 para saldos ganados antes del 5-sep-2025 (se cobran primero).
- **Proceso:** Creator Hub > Finanzas > Cash Out. Una solicitud por mes natural. Revisión de unos 10 días hábiles la primera vez y unos 5 después. No se puede cancelar. Primer registro en el portal DevEx (Tipalti) en la semana siguiente a la invitación o se rechaza automáticamente.
- **Comisiones:** Tipalti descuenta una tarifa de transacción según método; si conviertes a moneda local, un cargo de cambio de 1,9 % a 3 % ([devex-portal.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/devex-portal.md)). Métodos nombrados: PayPal, ACH, eCheck, transferencia bancaria; el nombre de la cuenta bancaria debe coincidir con el del portal.
- **Historial de moderación:** no descalifica automáticamente; Roblox considera tipo y momento de la infracción.

### 5.3 Países de DevEx y países hispanohablantes

- Roblox dice que paga a participantes de DevEx en "más de cien países" y que no puede pagar a ciertos países, entidades o personas por razones legales; la lista está en el Help Center [TERCERO: resumen del buscador de [DevEx Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115005718246-Developer-Exchange-Terms-of-Use) y [DevEx Help](https://en.help.roblox.com/hc/en-us/articles/13061189551124-Developer-Exchange-Help-and-Information-Page)]. La página del portal DevEx no incluye lista de países y remite a la cobertura de métodos de pago de Tipalti [OFICIAL].
- **[NO VERIFICADO]**: no pude confirmar si México, Argentina, Colombia, Chile, Perú, España, etc. están en la lista ni qué método de pago local tienen. Un hilo de la comunidad dice que, si no hay moneda local disponible, el pago puede ir por PayPal ([DevForum](https://devforum.roblox.com/t/what-countries-is-devex-supported-in/3510524), solo conocido por resumen). Comprueba tu país en el Help Center y en la cobertura de Tipalti **antes** de montar el negocio en torno a DevEx.

### 5.4 Impuestos (W-8BEN y fechas) [OFICIAL, [tax-information.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/tax-information.md)]

| Fecha | Hecho |
|---|---|
| 2026-07-15 | Se abrió la página "Taxes" en Creator Hub |
| **2026-10-31** | Último día para presentar información fiscal que determine la retención de tus primeros pagos como regalías |
| 2026-11-01 | Los pagos de DevEx pasan a clasificarse como regalías y puede aplicarse retención |

- **No estadounidenses:** persona = W-8BEN; empresa (S.L., S.A. de C.V., etc.) = W-8BEN-E. Al firmarlo certificas que no eres persona de EE. UU.
- **Retención:** 0 % a 30 % sobre la parte de fuente estadounidense (en general, compras de jugadores de EE. UU.) según país y tratado. Para reducirla, el W-8 debe ser válido y completo, incluir un número de identificación fiscal (NIF/TIN, de EE. UU. o extranjero) y que tu país de ciudadanía coincida con tu país de residencia permanente.
- **Si falta información** al 31-oct: pagos desde el 1-nov pueden sufrir hasta 24 % de retención de respaldo sobre **todo** el pago.
- **Documentos año siguiente:** formulario 1042-S para no estadounidenses.
- Presenta la información solo por Creator Hub, nunca por correo.
- [TERCERO] Un análisis indica que la retención depende de la fecha en que se **procesa** el pago, no de cuando lo solicitaste ([Panstag](https://www.panstag.com/2026/10/roblox-devex-tax-change.html), [StarBox](https://www.starbox.co.uk/blog/what-the-roblox-devex-payment-changes-mean-for-content-creators)). Varias guías de terceros dicen 30 % por defecto: la fuente oficial dice 24 % de retención de respaldo.
- **[NO VERIFICADO]:** qué tipo de tratado aplica a tu país y qué tasa resulta; además deberás declarar el ingreso en tu propio país. Consulta con un contador local.

---

## 6. Volumen de juegos similares: spam, descubrimiento y penalizaciones

Todo [OFICIAL] salvo indicación:

| Tema | Qué dice | Fuente |
|---|---|---|
| Límite de lanzamiento | **Hasta 5 juegos nunca antes lanzados por día.** Revocar y volver a publicar no cuenta. | [publish-games-and-places.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md) |
| Propósito de la tarifa de 1.000 Robux | Hacer "caro y logísticamente difícil" que actores malos creen muchas cuentas | misma |
| Metadatos spam | Repetición de palabras, decoración excesiva y palabras clave irrelevantes "pueden causar la degradación" del juego | misma |
| Juegos casi idénticos | Los juegos con metadatos y archivos parecidos a otros **ya no se priorizan** en recomendaciones y pueden clasificar peor en búsqueda; se prioriza el que primero añadió metadatos/archivos únicos, no el creado primero | [discovery.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/discovery.md), [discovery-faq.md](https://github.com/Roblox/creator-docs/blob/main/content/en-us/discovery-faq.md) |
| Baja calidad | Roblox "reduce la exposición de contenido de baja calidad"; el panel de creador muestra un aviso de exposición reducida (actualizado a diario) | discovery-faq.md |
| Clickbait / sorteos | Metadatos que insinúan recompensa económica no se priorizan; miniaturas o títulos que no coinciden con el juego bajan en recomendaciones y búsqueda | discovery.md |
| Reutilizar tu propia miniatura | No debería penalizar por sí sola | discovery-faq.md |
| Anuncios | No penalizan ni bajan el juego en "Recomendado para ti" | discovery-faq.md |
| Señales de ranking | Prioridad a tasa de juego, rebote de primera sesión (negativo), días de juego y tiempo por usuario; luego gasto. Son promedios por usuario, no totales | discovery.md |

**Lectura de riesgo:** publicar muchos juegos plantilla con retoques menores choca con tres mecanismos documentados (límite diario, priorización de originales, exposición reducida por baja calidad) y con la regla de DevEx que excluye pases de juegos plantilla sin visitas legítimas. Cada juego necesita un giro real, metadatos propios y su propio cuestionario de madurez. La documentación no define umbrales ni "strikes" por volumen [NO VERIFICADO si existe penalización a nivel de cuenta].

**Varias cuentas:** la tarifa existe para dificultar la creación masiva de cuentas; Creator Rewards prohíbe incentivar cuentas alternas. No encontré en las páginas leídas la regla exacta sobre cuentas múltiples de creador, pero repartir juegos en cuentas distintas para esquivar moderación o límites es un riesgo claro de terminación [NO VERIFICADO; revisa los Términos de Uso del 1-nov-2026].

---

## 7. Demandas y presión regulatoria 2025-2026 y su impacto probable

### 7.1 Hechos reportados [TERCERO salvo indicación]

Las cifras difieren entre fuentes: verifica cada caso en la nota de la fiscalía correspondiente.

| Fecha | Qué | Fuente |
|---|---|---|
| dic-2025 | **Iowa** demanda (AG Brenna Bird). Entre las alegaciones: diseño que incentiva el gasto impulsivo en Robux y Premium de menores de 13 sin mecanismos de consentimiento parental exigidos por ley. Un juez **denegó** la moción de desestimación en mayo 2026. | [Resumen en Tech-Insider](https://tech-insider.org/roblox-lawsuit-2026/), [CourtDocket](https://courtdocket.org/roblox-lawsuit-response-ag-cases-mdl-and-settlements/) |
| 2026-03-04 | **Nebraska** demanda (AG Hilgers): alega que la publicidad y mensajes de seguridad engañaron a los padres | [Nebraska AG](https://ago.nebraska.gov/nebraska-attorney-general-hilgers-files-lawsuit-against-roblox-enabling-child-exploitation-and) |
| 2026-04-21 | **Alabama** acuerdo de 12,2 millones USD | [Tech-Insider](https://tech-insider.org/roblox-lawsuit-2026/) |
| 2026-05-14 | **Oklahoma** demanda (AG Drummond): alega cuentas "relajadas" de adultos haciéndose pasar por niños y uso de Robux como palanca para el grooming | [Oklahoma AG](https://oklahoma.gov/oag/news/newsroom/2026/may/drummond-files-lawsuit-against-roblox-for-endangering-children-and-deceiving-parents.html), [Hoodline](https://hoodline.com/2026/05/oklahoma-ag-rips-roblox-as-predator-playground-in-explosive-child-safety-suit/) |
| 2026 | **West Virginia** acuerdo de 11 millones USD con verificación de edad obligatoria, chat adulto-niño restringido y ajustes seguros por defecto para menores de 16; **Kansas** 9,8 millones; **Dakota del Sur** 15 millones; **Arkansas** demanda a Roblox y Discord; **Florida** citación judicial sobre marketing a menores y moderación de chat; **Condado de Los Ángeles** demanda | [WV AG](https://ago.wv.gov/article/west-virginia-reaches-11-million-settlement-roblox-prompts-major-child-safety-overhaul), [Tech-Insider](https://tech-insider.org/roblox-lawsuit-2026/) |
| 2026-08-25 | Un seguimiento cuenta al menos 10 estados demandantes, más de 160 familias en un MDL federal y 3 estados con acuerdos por más de 35 millones USD (otra fuente: 11 estados y 54 millones) | [CourtDocket](https://courtdocket.org/roblox-lawsuit-response-ag-cases-mdl-and-settlements/) |
| 2026-10-17 | **Arizona** (AG Mayes) pide a un tribunal obligar a Roblox a entregar datos de una investigación | [Hoodline](https://hoodline.com/2026/10/arizona-ag-kris-mayes-takes-roblox-to-court-over-child-safety-data/) |
| 2026-06-30 | El 10-Q de Roblox reconoce que varias fiscalías han presentado reclamaciones o investigan temas de protección de menores y consumo digital | [SEC 10-Q](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051082/rblx-20260630.htm) (solo vi la mención del buscador) |
| feb-2026 / mar-2026 | Se informa de amenazas de multas a Roblox en Australia (hasta 49,5 millones AUD) y de acciones contra ciberdelitos en Filipinas; la Gambling Commission del Reino Unido colabora en retirar sitios no licenciados | [Yogonet](https://www.yogonet.com/international/news/2026/03/25/118234-philippines-steps-up-cybercrime-crackdown-on-gaming-platforms-flags-roblox-risks) y resumen del buscador; cifras [NO VERIFICADO] |

Todos los casos son alegaciones, salvo los acuerdos. No encontré sentencias sobre el fondo de las reclamaciones de monetización más allá de la denegación de la moción en Iowa.

### 7.2 Impacto probable en monetización (análisis mío) [NO VERIFICADO]

1. **Más puertas de edad.** Chat con verificación, tramos Kids/Select, juegos nuevos por defecto a 16+: reducen la audiencia infantil alcanzable y su gasto. Roblox ya está moviendo el incentivo económico hacia 18+ (tarifa de 0,0054).
2. **Menos frictionless para menores.** Límites parentales de gasto y transferencia, aprobación de comercio, menos regalos.
3. **Escrutinio del diseño de gasto de menores** (alegación de Iowa): es probable que Roblox endurezca o audite urgencia artificial, loot boxes y "lenguaje de presión"; las reglas de honestidad de la tienda ya existen y se pueden hacer cumplir más estrictamente.
4. **Cambios rápidos de política:** en el último año hubo cambio de tarifas (5-sep-2025), venta entre juegos desactivada (30-may-2026), nueva tarifa 18+ (8-jun-2026), cambio fiscal (1-nov-2026), nuevos Términos (1-nov-2026) y reparto de ingresos de anuncios (1-ene-2027). Planifica con margen y no dependas de una sola mecánica.
5. **Posible riesgo reputacional/legal de mecánicas de azar** si los tribunales consideran Robux "cosa de valor" (caso Colvin, no verificado).

---

## 8. Matriz de riesgos para la estrategia "muchos juegos con microtransacciones"

| Riesgo | Gravedad | Cómo se materializa | Mitigación |
|---|---|---|---|
| Terminación de la cuenta (todos los juegos y Robux bloqueados) | Muy alta | IP/audio, cuestionario falso, fraude con Robux, abuso de programas, assets del Creator Store marcados | Assets propios o licenciados; auditar cada asset; 2FA y correo verificado; no tocar Robux fuera de plataforma; guardar copias locales de los lugares y las licencias; reponer cuestionarios al cambiar el juego |
| Juegos "similares" sin alcance | Alta | No priorizados; aviso de baja calidad | Cada juego con idea, metadatos y miniaturas propios; lanzar de forma escalonada (límite de 5 nuevos/día) |
| Alcance reducido (16+ por defecto) | Alta | Sin tarifa/suscripción y evaluación | Decidir por juego si vale 1.000 Robux (reembolsable) o Plus/Premium; medir en Audience Reach |
| Incumplir Paid Random Items | Alta | Sin odds, sin `PolicyService`, resultados sin valor | Odds visibles y dinámicas, alternativa por usuario, probar con Player Emulator |
| Diseño de gasto dirigido a menores | Alta (legal y de plataforma) | Urgencia falsa, descuentos falsos, compras impulsivas | Seguir las reglas de honestidad; lenguaje neutro; límites de frecuencia de ofertas |
| Impuestos y retención | Media-alta | Sin W-8 antes del 31-oct | Completar la página de Impuestos ya; consultar contador |
| Cobro DevEx no disponible en tu país | Por determinar | País fuera de lista / método de pago local | Verificar en Help Center y Tipalti antes de invertir |
| Cambios de política | Media | Ver sección 7.2 | Revisar anuncios del DevForum cada mes |

---

## 9. Dudas abiertas y puntos no verificados

1. Qué cambia exactamente en los **Términos de Uso del 1-nov-2026** (incluidos los términos para el EEE/Reino Unido/Suiza, probablemente aplicables a España: [enlace](https://en.help.roblox.com/hc/en-us/articles/52986395990932-Roblox-Terms-of-Use-for-the-European-Economic-Area-the-United-Kingdom-and-Switzerland)).
2. **Lista de países de DevEx** y métodos de pago en países hispanohablantes.
3. **Brasil (ECA Digital) y otros países** que restringen Paid Random Items, o que bloquean o restringen Roblox (no pude investigarlo).
4. Fecha de entrada en vigor y alcance de la regla de **16+ por defecto/tarifa de 1.000 Robux** para juegos ya publicados, y definición de "jugadores muy comprometidos".
5. **Política sobre cuentas múltiples de creador** y sanciones por volumen de juegos similares a nivel de cuenta.
6. Reglas de **música y audio de terceros** en juegos y qué ocurre con juegos que usan audio sin licencia.
7. Tratado fiscal aplicable a tu país y tasa efectiva de retención; tratamiento fiscal local de los ingresos.
8. Caso *Colvin v. Roblox* y la calificación de Robux como "cosa de valor".
9. Cifras de demandas y acuerdos (varían entre fuentes: 10 u 11 estados; 35 u otros 54 millones USD).
10. Condiciones finales de la política de anuncios de mayo 2026 (la publicación original tiene actualizaciones posteriores).

Si quieres, se puede continuar con búsquedas adicionales sobre estos puntos una vez restablecido el presupuesto de búsqueda.

---

## 10. Checklist antes de lanzar

**Cuenta y finanzas**

- [ ] Cuenta con correo verificado, 2FA activada y verificación de edad o ID completada.
- [ ] Mayor de 13 años (mínimo para DevEx); si eres menor de 18, revisa el consentimiento parental para Creator Store.
- [ ] **Antes del 31-oct-2026:** formulario W-8BEN/W-8BEN-E completado en Creator Hub > Finanzas > Impuestos.
- [ ] Nombre legal coincidente en Roblox, portal DevEx y cuenta bancaria.
- [ ] Verificado que tu país está en la lista de DevEx y qué método de pago tienes.
- [ ] Leídos los Términos de Uso que entran en vigor el 1-nov-2026.

**Publicación y madurez**

- [ ] Cuestionario de madurez completado con el contenido **más maduro** posible; se repite al añadir chat, IA, creación libre, social hangouts, etc.
- [ ] Decidido el público: solo 16+ (por defecto) o todas las edades (tarifa 1.000 Robux reembolsable o Plus/Premium 2 meses + evaluación Kids/Select).
- [ ] Menos de 5 juegos nuevos por día; cada juego con nombre, descripción y miniatura únicos, sin palabras repetidas ni palabras clave irrelevantes.
- [ ] Miniaturas y títulos que reflejan el juego real; sin lenguaje de "Robux gratis".

**Tienda y microtransacciones**

- [ ] `PolicyService` integrado: suscripciones/commerce, Paid Random Items, comercio de objetos pagados, anuncios.
- [ ] Si hay azar pagado: probabilidades numéricas por resultado (suman 100 %), visibles antes de comprar y antes de gastar la moneda indirecta; modificadores explicados y dinámicos; ningún resultado sin valor; alternativa por usuario; probado con Player Emulator (AU, BE, NL, UK, BR).
- [ ] Sin casinos, apuestas, ruletas con objetos de valor ni enlaces a sitios de apuestas.
- [ ] Descuentos reales; sin falsa escasez; temporizadores exactos que no se reinician; lenguaje neutro ("View Item", "See Price").
- [ ] `ProcessReceipt` correcto; historial de compras guardado en DataStore.
- [ ] Suscripciones: mismos beneficios en todas las plataformas, durante todo el plazo; sin redirigir a otras plataformas.
- [ ] Pases promocionados sin azar; rango de precio 50-800 Robux si se promocionan; sin dependencia de ventas entre juegos (desactivadas desde 30-may-2026).
- [ ] Si buscas la tarifa 18+ de EE. UU.: 100 % R15 y R15 Only en la configuración del proyecto.

**Seguridad y contenido**

- [ ] Todo texto de usuario filtrado con `TextService.FilterStringAsync()` y chat por `TextChatService`.
- [ ] Sin entornos de espacios privados (dormitorios, baños); ambientes de adultos limitados a 18+.
- [ ] Panel de Seguridad revisado y moderación (`BanAsync`) lista.
- [ ] Si usas IA: aviso visible de que es IA, declarada en el cuestionario, salidas acordes a la etiqueta.

**Assets e IP**

- [ ] Todos los assets, nombres, personajes, memes, música y sonidos son propios o con licencia documentada (guardar las pruebas).
- [ ] Revisados los modelos del Creator Store (sin `require(assetId)`, `loadstring`, `LoadAsset` ni código ofuscado); scripts desconocidos desactivados.
- [ ] Imágenes generadas con IA contrastadas con marcas y personajes protegidos.
- [ ] Sin clones de juegos ni de sus nombres/logos; si usas franquicias, solicitar licencia en el catálogo.

**Enlaces, anuncios y promoción**

- [ ] Redes sociales solo en la página de detalles del juego (sin URLs dentro del juego); 16+ verificado para añadirlas.
- [ ] Anuncios propios registrados en Ads Manager con 5+ días de antelación, etiquetados "Ad", sin servicios publicitarios de terceros; sin recompensas por anuncios a menores de 13.
- [ ] Ninguna venta, compra o intercambio de Robux, objetos o cuentas fuera de Roblox; sin cuentas alternas ni bots.

**Seguimiento**

- [ ] Alertas mensuales del DevForum (anuncios) y del Help Center sobre cambios de política.
- [ ] Copias de seguridad locales de cada lugar (.rbxl) y registro de licencias.

---

## 11. Fuentes

**Oficiales (leídas directamente en el repositorio `Roblox/creator-docs`, rama `main`, 2026-10-20)**

- Monetización: [index](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/index.md), [paid-random-items](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-random-items.md), [developer-exchange](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-exchange.md), [devex-portal](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/devex-portal.md), [tax-information](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/tax-information.md), [18-plus-devex-rate](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/18-plus-devex-rate.md), [passes](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/passes.md), [developer-products](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/developer-products.md), [subscriptions](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/subscriptions.md), [paid-access-robux](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/paid-access-robux.md), [commerce-products](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/commerce-products.md), [robux-transfers](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/monetization/robux-transfers.md)
- Publicación y madurez: [content-maturity](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/content-maturity.md), [experience-guidelines](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/experience-guidelines.md), [kids-and-select](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/kids-and-select.md), [publish-games-and-places](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/publish-games-and-places.md), [account-verification](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/account-verification.md), [safety](https://github.com/Roblox/creator-docs/blob/main/content/en-us/safety.md), [regional-content-availability](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/regional-content-availability.md)
- IP, assets e IA: [ip-guidelines](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/ip-guidelines.md), [dsa-ip-reporting](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/dsa-ip-reporting.md), [rights-manager](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/publishing/rights-manager.md), [creator-store](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/creator-store.md), [ip-licensing](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ip-licensing/index.md), [generative-AI](https://github.com/Roblox/creator-docs/blob/main/content/en-us/generative-AI.md)
- Descubrimiento, anuncios y programas: [discovery](https://github.com/Roblox/creator-docs/blob/main/content/en-us/discovery.md), [discovery-faq](https://github.com/Roblox/creator-docs/blob/main/content/en-us/discovery-faq.md), [recommendation](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/recommendation.md), [ad-integrations](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/ad-integrations.md), [comply-with-advertising-standards](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/comply-with-advertising-standards.md), [social-media-links](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/promotion/social-media-links.md), [creator-rewards](https://github.com/Roblox/creator-docs/blob/main/content/en-us/creator-rewards.md), [configure-games](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/configure-games.md), [bans](https://github.com/Roblox/creator-docs/blob/main/content/en-us/production/bans.md)

**Páginas oficiales de Roblox que no pude abrir (solo resumen del buscador, por tanto [TERCERO])**

- [Community Standards](https://about.roblox.com/community-standards), [Terms of Use](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use), [aviso de actualización de Términos](https://en.help.roblox.com/hc/en-us/articles/14663412502676-Roblox-is-Updating-our-Terms-of-Use), [Terms EEE/UK/Suiza](https://en.help.roblox.com/hc/en-us/articles/52986395990932-Roblox-Terms-of-Use-for-the-European-Economic-Area-the-United-Kingdom-and-Switzerland)
- [Kids y Select (newsroom, jun-2026)](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available), [Help: qué son Kids y Select](https://en.help.roblox.com/hc/en-us/articles/48163847200532-What-are-Roblox-Kids-and-Roblox-Select), [Help: cómo chatear](https://en.help.roblox.com/hc/en-us/articles/43611824582292-How-to-chat-on-Roblox), [Parental Controls](https://en.help.roblox.com/hc/en-us/articles/30428310121620-Parental-Controls-Overview)
- [DevEx Help](https://en.help.roblox.com/hc/en-us/articles/13061189551124-Developer-Exchange-Help-and-Information-Page), [DevEx Terms](https://en.help.roblox.com/hc/en-us/articles/115005718246-Developer-Exchange-Terms-of-Use), [Tax and DevEx Portal](https://en.help.roblox.com/hc/en-us/articles/27985018895124-Tax-and-DevEx-Portal-Tipalti-Information), [Advertising Integrations Terms](https://en.help.roblox.com/hc/en-us/articles/47656162239124-Advertising-Integrations-Terms)
- DevForum: [Paid Random Items](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622), [tarifa 18+](https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091), [políticas de publicidad](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365), [Plus/Transfers/Gifting](https://devforum.roblox.com/t/update-on-roblox-plus-transfers-and-community-gifting/4637912), [Términos nov-2026](https://devforum.roblox.com/t/updates-to-the-roblox-terms-of-use-november-2026/4907620), [países de DevEx](https://devforum.roblox.com/t/what-countries-is-devex-supported-in/3510524), [experiencias sin clasificar](https://devforum.roblox.com/t/important-updates-unrated-experiences-and-changes-to-experience-pages/3899317)
- Newsroom: [tarifa 18+ (abr-2026)](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42)

**Terceros (prensa, blogs, agregadores)**

- Loot boxes: [TechTimes 2026-06-26](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm), [ZehnStudio99](https://zehn-studio26.com/news/paid-random-items-odds-disclosure/)
- Kids/Select y verificación: [TechCrunch 2026-04-13](https://techcrunch.com/2026/04/13/roblox-introduces-kids-and-select-accounts-for-age-appropriate-access-to-games-and-chat/), [Bloxy News](https://www.bloxy.news/post/roblox-kids-chat-restrictions-publishing-requirements)
- Anuncios: [Bloomberg 2026-03-20](https://www.bloomberg.com/news/articles/2026-03-20/roblox-overhauls-ad-policies-in-bid-to-boost-sponsorship-revenue), [GuruFocus](https://www.gurufocus.com/news/8731450/roblox-rblx-revises-advertising-policies-for-enhanced-user-experience)
- Impuestos: [Panstag](https://www.panstag.com/2026/10/roblox-devex-tax-change.html), [StarBox](https://www.starbox.co.uk/blog/what-the-roblox-devex-payment-changes-mean-for-content-creators)
- Gambling: [iGamingExpert](https://igamingexpert.com/news/games/bloxflip-return-roblox/), [Yogonet](https://www.yogonet.com/international/news/2026/03/25/118234-philippines-steps-up-cybercrime-crackdown-on-gaming-platforms-flags-roblox-risks)
- Demandas: [Oklahoma AG](https://oklahoma.gov/oag/news/newsroom/2026/may/drummond-files-lawsuit-against-roblox-for-endangering-children-and-deceiving-parents.html), [Nebraska AG](https://ago.nebraska.gov/nebraska-attorney-general-hilgers-files-lawsuit-against-roblox-enabling-child-exploitation-and), [West Virginia AG](https://ago.wv.gov/article/west-virginia-reaches-11-million-settlement-roblox-prompts-major-child-safety-overhaul), [Hoodline (Oklahoma)](https://hoodline.com/2026/05/oklahoma-ag-rips-roblox-as-predator-playground-in-explosive-child-safety-suit/), [Hoodline (Arizona)](https://hoodline.com/2026/10/arizona-ag-kris-mayes-takes-roblox-to-court-over-child-safety-data/), [CourtDocket](https://courtdocket.org/roblox-lawsuit-response-ag-cases-mdl-and-settlements/), [Tech-Insider](https://tech-insider.org/roblox-lawsuit-2026/), [SEC 10-Q jun-2026](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051082/rblx-20260630.htm)
- Relatos de desarrolladores (anecdóticos): [terminación por meme](https://devforum.roblox.com/t/ai-is-terminating-accounts-over-a-meme-found-everywhere-in-toolboxcreator-store-3-million-robux-lost/4836607), [terminación por Robux](https://devforum.roblox.com/t/account-terminated-and-group-locked-for-alleged-buying-selling-or-trading-robux/4583341)
