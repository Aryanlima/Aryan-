# Plan de 90 días

Para: Aryan. Hoy es martes 2026-10-20 (día 0). El día 90 es el lunes 2027-01-18. Este plan convierte el [informe maestro](informe-maestro.md) en un calendario de semanas, con qué hace Claude y qué debe hacer Aryan a mano.

## 0. Cómo leer este plan

| Convención | Significado |
|---|---|
| **Claude** | Tarea que Claude puede hacer o automatizar (código, pruebas, textos, guiones, hojas de métricas). |
| **Aryan** | Tarea que solo tú puedes hacer: identidad, impuestos, pagos, aceptar términos, crear claves, jugar en un móvil real, publicar. |
| **Ambos** | Claude prepara, Aryan revisa y ejecuta. |
| [OFICIAL] / [TERCERO] / [NO VERIFICADO] / [IDEA PROPIA] | Misma leyenda que el informe maestro. |

Tres avisos sobre los números de este plan:

1. **Las puertas G0 a G5 son heurísticas** [IDEA PROPIA] del informe 07 ([07 §6.3][r07]). Se apoyan en la retención de juegos grandes de GameAnalytics (supervivientes, no juegos nuevos) y en un informe sin datos públicos de "tasa de éxito". Son barandillas, no leyes. Se calibran con tus datos tras 5 a 8 juegos; en 90 días tendremos 1 o 2, así que casi todo será juicio.
2. Las horas de Aryan por semana son una estimación [IDEA PROPIA] para ~5 h/semana de media (≈60 h en 90 días). Si respondes la pregunta 9 de [preguntas-para-aryan.md](preguntas-para-aryan.md) con otra cifra, el calendario se estira o se comprime.
3. Fechas con "provisional" dependen de tus respuestas (país, Plus, presupuesto, ordenador).

---

## 1. Calendario resumen

Semanas de lunes a domingo. La semana 0 dura hasta el domingo 1-nov. L = día de lanzamiento de Fish & Fortune, **provisional: martes 1-dic-2026**.

| Semana | Fechas | Objetivo | Claude | Aryan | Salida o puerta | Horas Aryan |
|---|---|---|---|---|---|:-:|
| **S0** | 20 oct a 1 nov | Papeles, cuentas, claves, Studio | Guías paso a paso, hoja de datos para el W-8BEN, lista de permisos mínimos de claves, lectura de políticas | **W-8BEN antes del miércoles 28-oct**, cuenta, verificación, Plus, Creator Hub, claves, instalar Studio | Papeles hechos; Studio conectado | 5 a 6 |
| S1 | 2 a 8 nov | Núcleo técnico + primera prueba en Studio | Verificar y completar el núcleo (datos, compras, política, remotos, analítica, config) con tests | Abrir el juego en Studio y jugarlo; copiar errores | **H1**: el juego abre y se juega en Studio | 3 |
| S2 | 9 a 15 nov | Fish & Fortune jugable | Bucle de pesca, tienda, UI móvil, zonas | Jugar 30 min por sesión; decir qué aburre | **H2**: MVP jugable | 4 |
| S3 | 16 a 22 nov | MVP completo, eventos, analítica | Eventos por config, códigos, embudo de analítica, tabla de odds (sin azar de pago) | Probar en móvil real; grabar clips | **H3**: MVP completo | 5 |
| S4 | 23 a 29 nov | **G0** + preparar lanzamiento | Arreglos, textos de tienda, guiones, kit de marketing, borrador del cuestionario de madurez | 5 a 10 personas juegan; cuestionario; iconos; pases y productos; decidir tarifa/Plus | **G0**; checklist de lanzamiento | 8 |
| S5 | 30 nov a 6 dic | **Lanzamiento suave + G1** | Parche rápido, informe diario de analítica, clips | Publicar en producción (aprobación), comprar anuncios de prueba, publicar clips | **G1** (días L+1 a L+4) | 6 |
| S6 | 7 a 13 dic | **G2** (D7) + 1.a actualización | Actualización v1.1 con datos, informe | Revisar, publicar, outreach a creadores | **G2** | 5 |
| S7 | 14 a 20 dic | **G3** económica + decidir 2.º juego | Cálculo ingreso vs coste, evento 1 | Decidir según G2/G3; clips | **G3**; decisión sobre Rumble Rotation | 4 |
| S8 | 21 a 27 dic | Evento festivo | Actualización de invierno, calendario de eventos | Publicar; clips; vigilar | Evento festivo publicado | 5 |
| S9 | 28 dic a 3 ene | **G4** (tráfico orgánico) | Informe, parches | Revisar; clips | **G4** | 4 |
| S10 | 4 a 10 ene | Inicio **G5**; 2.º juego en construcción | Prototipo del 2.º juego (si procede) | Probar; revisar Términos y políticas nuevas | G5 en curso | 4 |
| S11 | 11 a 17 ene | G0 del 2.º juego; informe de 90 días | Informe de 90 días, propuesta de los siguientes 90 | Playtest del 2.º juego | Informe listo | 4 |
| S12 | 18 a 24 ene | **Día 90: decisión** | Escenarios, presupuesto | Decidir: continuar, pausar o cambiar el peso de juegos y ropa | Decisión | 3 |

Carril rápido [IDEA PROPIA]: si tienes más de 15 h/semana y el juego pasa H1 en la semana 1, L puede adelantarse a la semana 4 (23 a 29 nov). No lo adelantes por ansiedad: lo que decide es pasar G0.

---

## 2. Semana 0 (urgente): papeles, cuentas y claves

Orden de prioridad. Lo que va primero tiene fecha límite.

| # | Tarea | Quién | Cuándo | Cómo y por qué | Fuente |
|---|---|---|---|---|---|
| 1 | Responder las 4 preguntas urgentes (país, edad, persona o empresa, cuenta existente) | Aryan | Hoy | Sin esto no se sabe qué formulario fiscal ni si DevEx existe en tu país | [preguntas-para-aryan.md](preguntas-para-aryan.md) |
| 2 | Cuenta de Roblox en orden: correo verificado, contraseña única, **2FA activado** | Aryan | Hoy | 2FA es requisito para publicar a todas las edades y protege la cuenta única de la que cuelga todo | [OFICIAL] [03 §3.3][r03] |
| 3 | **Verificación de edad o identidad** (estimación facial si eres menor de 18; documento de identidad si tienes 18+) | Aryan | Hoy o mañana | Necesaria para publicar a todas las edades, para añadir enlaces sociales (16+) y desbloquea más cuota de assets. Hazlo solo dentro de Roblox, nunca enviando tu documento a terceros | [OFICIAL] [03 §3.3, §5.1][r03] |
| 4 | **Formulario fiscal: W-8BEN (persona) o W-8BEN-E (empresa)** en Creator Hub > Finances > Taxes | Aryan | **Antes del miércoles 28-oct** (límite oficial: sábado 31-oct) | Si falta información, desde el 1-nov puede aplicarse una retención de respaldo de **24 % sobre todo el pago**. Con información válida, la retención va de 0 a 30 % solo sobre la parte de fuente de EE. UU. (según país y convenio). Para reducirla, el formulario debe estar completo, incluir un número de identificación fiscal (NIF/TIN) y tu país de ciudadanía debe coincidir con tu país de residencia permanente. Se presenta solo por Creator Hub, nunca por correo | [OFICIAL] [03 §5.4][r03] |
| 4b | Preparar los datos del W-8BEN: nombre legal, país, dirección, NIF/TIN, país del convenio | Claude prepara la lista, Aryan rellena | Hoy | Claude no puede firmar ni presentar por ti. La tasa que te toca depende de tu país: pregúntala a un contador local | [OFICIAL] [03 §5.4][r03] |
| 5 | Comprobar que **DevEx existe en tu país** y qué método de cobro tienes (PayPal, banco, otro) | Aryan | Esta semana | Roblox dice "más de cien países" pero la lista no se pudo leer. Mira el Help Center de DevEx y la cobertura de Tipalti | [NO VERIFICADO] [03 §5.3][r03] |
| 6 | Que el **nombre legal coincida** en Roblox, portal DevEx y cuenta bancaria | Aryan | Esta semana | Si no coincide, el pago puede fallar | [OFICIAL] [03 §10][r03] |
| 7 | **Plus o Premium**: decidir si activar Plus (4,99 USD/mes) | Aryan | Esta semana | Mantenerlo 2 meses seguidos exime de la tarifa de 1.000 Robux por juego. Si lo activas el 22-oct, los 2 meses se cumplen hacia el 22-dic. Comprueba en Creator Hub si está disponible en tu país. Plus o Premium también es obligatorio para publicar y mantener ropa y accesorios de avatar a la venta ([08 §2.2][r08]), así que sirve para las dos líneas | [OFICIAL] la regla [03 §3.3][r03]; precio [OFICIAL] vía resumen [02 §2.3][r02] |
| 8 | **Creator Hub y grupo**: entrar en create.roblox.com; decidir si publicas como persona o con un grupo | Aryan | Esta semana | Regla simple: persona si trabajas solo; grupo si habrá socios. Los requisitos de publicación se aplican a través del dueño del grupo. Cómo cobra un grupo por DevEx no está cubierto por los informes: comprobarlo antes de crear uno | [OFICIAL] [03 §3.3][r03]; cobro de grupo [NO VERIFICADO] |
| 9 | **Universo de pruebas**: crear una experiencia **privada** de staging para Fish & Fortune (desde Studio: Publish to Roblox) | Aryan | Cuando Studio esté listo | Todas las pruebas de compras y datos van aquí, nunca en producción. Esto exige haber instalado Studio (tarea 10) | [OFICIAL] la separación de entornos [06 §4.3][r06] |
| 10 | **Instalar Studio** (Windows o Mac), activar el servidor MCP integrado y conectar Claude Code | Aryan activa; Claude configura | Esta semana | Studio > Assistant > "..." > Manage MCP Servers > Enable Studio as MCP server > Quick connect > Claude Code. Concede solo herramientas de lectura al principio y deja `execute_luau`, `multi_edit`, `insert_asset`, `generate_*` y `start_stop_play` con aprobación manual | [OFICIAL] [04 §11][r04] |
| 11 | **Claves de Open Cloud con alcance mínimo** (ver 2.1) | Aryan crea; Claude usa | Después de la tarea 9 | "Equivalente a una contraseña": una clave por juego, restringida a esa experiencia, solo los permisos que hagan falta, nunca en el chat ni en el repositorio. Se caducan tras 60 días sin uso: poner un recordatorio al día 50 | [OFICIAL] [06 §4.3][r06] |
| 12 | Leer los **Términos de Uso nuevos** (en vigor el 1-nov) y apuntar qué cambia | Aryan | Antes del 1-nov | No se pudo leer qué cambia; puede afectar a cuentas, IA o pagos | [NO VERIFICADO] [03 §9][r03] |
| 13 | **Verificación de 15 minutos en Creator Hub** de lo que los informes dejaron dudoso | Aryan | Esta semana | (a) umbral de evaluación Kids/Select: 250 o 500 jugadas; (b) condiciones de reembolso de la tarifa de 1.000 Robux; (c) detalle R15 de la tarifa 18+; (d) lista de países de DevEx; (e) si Plus hace falta para actualizar; (f) si vas a probar ropa: suelo de precio por categoría, si el reparto progresivo vale para ropa 2D, precio de Plus o Premium en tu país y si el ID verificado está disponible a tu edad ([08 §7][r08]) | [NO VERIFICADO] [03 §3.3, §9][r03], [02 §8][r02], [08 §7][r08] |
| 14 | Anotar el **tope de pérdida** (dinero y horas) que aceptas | Aryan | Esta semana | Es la barandilla de todo el plan | [IDEA PROPIA] |
| 15 | **Jueves 29-oct: resultados T3 de Roblox**; leer qué dicen de bookings y de monetización | Claude resume, Aryan lee | 29-oct | Confirma o no la guía de -14 a -18 % | [TERCERO] [01 §2][r01] |

### 2.1 Permisos mínimos de las claves de Open Cloud

| Para qué | Permiso | Cuándo | Estado |
|---|---|---|---|
| Publicar versiones del lugar (staging primero) | `universe-places` con Write, limitado a **un solo universo** | Desde S1 | [OFICIAL] [04 §6.4][r04] |
| Leer analítica de todo el portafolio | `universe.analytics:read` | Desde S5 | [OFICIAL] [06 §7.2][r06] |
| Crear o actualizar pases y productos desde script | `game-pass:write`, `developer-product:write` (ambas API en **beta**) | Opcional; la primera vez, a mano en Creator Hub | [OFICIAL] [06 §4.4][r06] |
| Configs (eventos sin republicar) y experimentos | `universe:read` y `universe:write` | Cuando haya eventos | [OFICIAL] [06 §6.3][r06] |
| Tests de motor en CI (Luau Execution) | No pedir todavía: límites y nombre del permiso sin verificar | Más adelante | [NO VERIFICADO] [06 §4.3][r06] |

Prueba de que todo está bien al final de la semana 0: (1) W-8BEN presentado, (2) cuenta con 2FA y verificación, (3) Studio abierto con el MCP conectado, (4) un universo de pruebas privado creado, (5) tope de pérdida escrito.

---

## 3. Construcción: núcleo (S1 a S3) y primer juego (S2 a S5)

El kit compartido y el juego los están escribiendo agentes en paralelo (ver el estado real en [00-LEEME.md](../00-LEEME.md)). Lo que este plan añade es **validación humana en Studio**, porque nada del código se ha probado todavía dentro de Roblox.

| Hito | Cuándo | Criterio de "hecho" | Quién |
|---|---|---|---|
| **H1** | Fin de S1 | El proyecto se sincroniza con Studio (Rojo o Script Sync), el juego arranca en Play Solo sin errores en la consola y se puede pescar una vez | Claude entrega; **Aryan prueba** |
| **H2** | Fin de S2 | Bucle completo: lanzar, minijuego de ~3 s, captura, vender o guardar, mejorar caña, zona nueva. 3 zonas y 25 criaturas | Claude; Aryan juega |
| **H3** | Fin de S3 | Tienda con pase de auto-pesca, 2x dinero, pack de inicio, slots, cosméticos, VIP; eventos por config; códigos; analítica con embudo; funciona en móvil real | Claude; **Aryan en móvil** |
| **H4** | Fin de S4 | Pasa G0. Compras probadas en el universo de pruebas con `ProcessReceipt` (sin cobros dobles ni pérdidas) | Ambos |

Reglas técnicas ya decididas (detalle en [informe maestro §5](informe-maestro.md)): Luau `--!strict`, archivos más Git, un único `ProcessReceipt` idempotente, ProfileStore para datos, revisión humana de todo lo de dinero. Cómo se simulan compras dentro de Studio está sin verificar [06 §9][r06]: la prueba real de compras se hace en el universo de pruebas.

### 3.1 Qué se vende en la v1 de Fish & Fortune

Los precios son hipótesis para probar, no datos de mercado [IDEA PROPIA] ([02 §7][r02], [07 §8][r07]).

| Producto | Tipo | Precio inicial (Robux) | Notas |
|---|---|---:|---|
| Pack de inicio (una vez) | Pase | 99 | Se ofrece tras la primera mejora, nunca antes de dar valor |
| 2x dinero | Pase | 249 | |
| Auto-pesca | Pase | 299 | El pase "universal" |
| Slots de inventario | Producto | 99 a 199 | |
| Cañas cosméticas | Producto | 199 a 799 | Sin ventaja de poder |
| VIP mensual | Suscripción en Robux | 199 a 499 | 70 % desde el primer mes |
| Pase de temporada | Pase | 399 | Desde el evento 1 |
| "Suerte" (boost de probabilidad) | **No en v1** | n/a | Cuenta como objeto aleatorio de pago: exige odds numéricas dinámicas, `PolicyService` y alternativa por país. Se añade en la v1.5 si G2 pasa y el cumplimiento está probado con el Player Emulator |

Reglas de tienda [OFICIAL] ([03 §2.3][r03]): descuentos reales, sin falsa escasez, temporizadores exactos que no se reinician, lenguaje neutro, primera compra después de un momento de necesidad. Los A/B de precios con `Experiments` solo dan resultados con volumen (por debajo de ~1.000 DAU puede no haber significancia): con poca audiencia se prueba por cohortes y no se cambian precios cada semana [OFICIAL] [06 §7.3][r06], [02 §7][r02].

---

## 4. Puertas G0 a G5 (heurísticas)

Fechas con L = 1-dic (provisional). "Matar" significa: dejar de invertir tiempo y dinero (sin anuncios, sin actualizaciones) y dejar el juego publicado a menos que dé problemas de política. No se borra.

| Puerta | Cuándo | Muestra mínima | Métrica | **Matar** | Iterar | **Invertir** |
|---|---|---|---|---|---|---|
| **G0** Playtest | S4, antes de publicar | 5 a 10 personas | Embudo FTUE: llegar a la primera recompensa en 60 s | Menos de 70 % | 70 a 85 % | Más de 85 % |
| **G1** Anuncios | L+1 a L+4 (2 a 5 dic) | 500 a 1.000 visitas | D1, sesión media, de icono a visita | D1 < 8 % **y** sesión < 4 min tras 1 arreglo de 48 h | D1 8 a 15 % | D1 ≥ 15 % |
| **G2** Retención | L+7 a L+10 (8 a 11 dic) | 1.000 a 2.000 visitas | D7; compradores | D7 < 1,5 % | D7 1,5 a 3 % | D7 ≥ 3 % **y** ≥ 1 % de visitantes compran |
| **G3** Económica | L+10 a L+14 (11 a 15 dic) | Cohorte de G1 y G2 | Ingreso bruto a 7 días por visitante vs coste por visita | Ingreso < mitad del coste | Entre la mitad y el coste | Ingreso ≥ coste: se puede escalar anuncios |
| **G4** Orgánico | L+14 a L+28 (15 a 29 dic) | CCU diario | % de visitas orgánicas; CCU pico | Orgánico < 20 % y D7 < 2 % | 20 a 30 % | Orgánico ≥ 30 % y CCU pico ≥ 500: pasa a Tier A |
| **G5** Sostenibilidad | L+28 a L+60 (29 dic a 30 ene) | Retención D8 a D28 | Días de juego por usuario; ARPDAU | CCU cae > 50 % sin actualizaciones y sin compradores | Estable | Tendencia creciente tras eventos |

Fuente: [07 §6.3][r07]. Cómo leerlas:

- **Referencias de partida** [TERCERO]: GameAnalytics 2026 da D1 mediana 10,3 %, D7 1,6 %, D30 0,5 %, con p75 a p90 de D1 en 12,9 a 15,9 % ([07 §7][r07]). Son juegos con más de 1 millón de usuarios mensuales: un MVP medio estará por debajo. Por eso "matar si D1 < 8 %" es más permisivo que la mediana.
- **No uses** las cifras de blogs que dan D1 de 20 a 35 % o D7 ≥ 20 % como "bueno": usan otras definiciones [NO VERIFICADO] ([07 §7][r07]).
- **Muestra**: con 500 visitas, D1 = 10 % tiene un margen de ±2,6 puntos; con 1.000, ±1,9; D7 al 3 % necesita ~2.000 visitas para ±0,8 [IDEA PROPIA, aritmética binomial] ([07 §6.2][r07]). Si no se llega a la muestra, **se prolonga la prueba, no se decide**.
- Los gráficos D7 y D30 de Creator Analytics aparecen vacíos hasta que pasan 7 o 30 días [OFICIAL] ([06 §7.2][r06]).
- Los umbrales de CCU (100, 500, 2.000) son heurísticas nuestras ([07 §6.3][r07]).
- G0 puede reemplazarse por NPC de prueba si Roblox los ofrece; se anunciaron en RDC 2026 pero no hay detalles verificados [TERCERO] ([07 §2][r07]).

### 4.1 Niveles de inversión

| Nivel | Cadencia | Qué entra |
|---|---|---|
| **Tier A** (máx. 3) | Actualización semanal | Juegos que pasaron G4 |
| **Tier B** | Un evento mensual automatizado | Juegos estables con ingresos pequeños |
| **Tier C** | Sin actualizaciones ni anuncios | Juegos "matados" |

Reinversión: reservar el 70 % de los ingresos de un juego ganador para actualizaciones y anuncios; no escalar anuncios hasta que el ingreso a 7 días por visitante supere el coste por visita ([07 §6.2][r07], [IDEA PROPIA]).

---

## 5. Cadencia de actualizaciones de Fish & Fortune

Todo [IDEA PROPIA] apoyado en lo que hacen los juegos que duran ([01 §6][r01], [07 §4.2][r07]). **Solo se mantiene la cadencia semanal si el juego pasa G2**; si no, no se gasta tiempo en actualizar.

| Fecha | Versión | Contenido | Condición |
|---|---|---|---|
| Mar 1-dic (L) | v1.0 | 3 zonas, 25 criaturas, tienda básica, códigos de lanzamiento | Pasa G0 |
| 8 a 11 dic | v1.1 | Arreglos con datos reales (balance, embudo), ajuste del pack de inicio | Sin condición (parche) |
| 15 dic | v1.2 | **Evento 1** (7 a 14 días) con criaturas exclusivas y pase de temporada 1 | Pasa G2 |
| 22 a 24 dic | v1.3 | **Evento festivo** de invierno (hasta 30 días), cañas cosméticas | Pasa G2 |
| 29 dic | v1.4 | Evento de año nuevo, ranking semanal | Pasa G3 |
| 5 ene | v1.5 | Zona 4 y, si el cumplimiento está probado, **"Suerte" con odds numéricas** | Pasa G3 |
| 12 a 19 ene | v1.6 | Evento 3; revisión de precios por cohortes | Pasa G4 |

Reglas de publicación [OFICIAL] ([06 §6.3][r06]): se despliega antes y se activa con un flag de Configs; publicar una versión no expulsa a los jugadores (los servidores viejos siguen vivos); si cambia el formato de datos hay que reiniciar servidores; los eventos duran 7 a 30 días y puede haber hasta 10 publicados o próximos [OFICIAL‡] ([07 §4.2][r07]). Estacionalidad: se espera más tráfico en vacaciones de verano del hemisferio norte y diciembre-enero, pero es [NO VERIFICADO] ([02 §5.5][r02]); el cuarto trimestre de 2025 fue el récord de pagos a creadores [TERCERO] ([02 §4.2][r02]). Mídelo con tus datos.

### 5.1 Línea secundaria opcional: ropa y accesorios de avatar

El informe 08 recomienda **juegos como motor y ropa como línea secundaria** ([08 §6][r08]). Esta línea es opcional y **no se abre sin tu respuesta a la pregunta 11**. Los umbrales son heurísticas [IDEA PROPIA] del propio informe.

| Cuándo | Qué | Coste aproximado | Condición |
|---|---|---|---|
| S0 (15 min) | Verificación en Creator Hub (ver tarea 13) | 0 | Siempre |
| S10 en adelante | **Tienda de avatar dentro de Fish & Fortune**: 5 a 10 ítems propios exclusivos de tu juego (por Place ID) y menú de inspección activo para ganar 40 % por ítems de otros | Subida 80 R$ + anticipo según tipo por ítem | G4 pasado: ≥ 100 a 200 jugadores diarios |
| Desde S6 | **Piloto en el Marketplace: 5 ítems 3D en capas** con una sola base validada | ≈ 3.400 R$ (680 R$ por ítem) | Respondes "ropa" o "las dos"; Plus activo; ID verificado; horas disponibles |
| S10 a S12 | Medir a 30 días: unidades por ítem, aprobación, suelo real, ingresos vs gasto | 0 | Mínimo 20 ítems publicados para aplicar los criterios de matar o duplicar ([informe maestro §9.4](informe-maestro.md)) |

No se hace en estos 90 días: ropa clásica 2D como negocio, Limiteds pagados ni accesorios con máscara emisiva ([08 §6.1][r08]). Los pasos de producción con IA están **pendientes de 09**.

---

## 6. Presupuesto de anuncios de prueba

Los anuncios sirven para **comprar una muestra y medir**, no para ganar dinero (cuentas en [informe maestro §2.4](informe-maestro.md)). El coste de una visita (4 a 12 Robux) es [TERCERO] y el real se sabrá solo con una campaña pequeña ([07 §3.5][r07]).

| Nivel | Gasto | Qué compra | Cuándo |
|---|---|---|---|
| **0** (sin dinero) | 0 | Solo orgánico y creadores: G1 y G2 tardarán más y serán menos fiables | Si el presupuesto es 0 (pregunta 6) |
| **1** (mínimo útil) | 5.000 a 10.000 Robux (≈ 50 a 100 USD nominales) | ≈ 420 a 2.500 visitas: alcanza para G1 | Semana 5 |
| **2** (con repetición) | Hasta ≈ 300 USD en total en los 90 días | G1 + repetición tras un arreglo + G1 del 2.º juego | Semanas 5, 7 y 11 |

El 0,01 USD por Robux es la cifra nominal con la que Roblox calcula su "26,6 %" ([02 §2.1][r02]); lo que de verdad cuesta depende de cómo consigas los Robux. Un crédito de anuncios equivale a 263 Robux [OFICIAL] vía resumen ([07 §3.5][r07]).

**Cómo funciona Ads Manager** [OFICIAL] ([05 §7.2][r05]):

| Dato | Valor |
|---|---|
| Requisitos | 13+ y correo verificado; pago con tarjeta solo para 18+; convertir Robux en créditos es **irreversible**; cobro inicial de 5 USD en el primer pago con tarjeta |
| Compra mínima | 1 crédito. El mínimo por campaña es contradictorio (10 créditos en 2023, ~35 USD en un blog, ninguno en la doc actual): [NO VERIFICADO], verlo en el panel |
| Moderación | Campaña hasta 24 h; assets hasta 48 h. Preparar iconos y miniaturas **3 días antes** |
| Creativos | Hasta 10 miniaturas 16:9 por campaña |
| Tipos de objetivo | Plays, Earnings, Engagement; audiencias todos, nuevos, recientes (10.000+) e inactivos (20.000+) |
| Efecto en el ranking | Los anuncios no penalizan ni bajan el juego en "Recomendado para ti" [OFICIAL] ([03 §6][r03]) |

**Diseño de la prueba G1** [IDEA PROPIA]:

1. 3 variantes de icono (un solo sujeto, alto contraste, fiel al juego) y título corto con el género y el gancho.
2. 3 a 4 días seguidos; presupuesto repartido a partes iguales entre variantes.
3. Medir: de icono a visita, D1, sesión media, % que hace una primera compra.
4. Regla de parada: si el juego cae en "matar" de G1, se corta el gasto. **No se repone por ánimo**: solo se repite tras arreglar algo concreto.
5. Se escala solo cuando el ingreso a 7 días por visitante supere el coste por visita (G3).

---

## 7. Marketing con IA

### 7.1 Reglas que condicionan todo

| Regla | Etiqueta | Fuente |
|---|---|---|
| Los vídeos de la **página del juego** deben mostrar **juego real**: sin voz en off, sin música con letra, sin anuncios, sin mecánicas que el juego no tenga. Cuota gratuita de 3 subidas al mes | [OFICIAL] | [05 §2][r05] |
| La promoción **fuera de Roblox** (TikTok, YouTube, creadores de pago) cae bajo la política de publicidad independiente: declarar claramente que es publicidad, no copiar avisos oficiales de Roblox, no prometer "Robux gratis" | [OFICIAL] | [05 §7.1][r05], [03 §2.5][r03] |
| Redes sociales (hasta 3 enlaces) **solo en la página de detalles**, no dentro del juego; añadirlas exige 16+ verificado. No se puede escribir la URL ni el invite de Discord dentro del juego | [OFICIAL] | [03 §2.6][r03] |
| Las herramientas de vídeo de IA (Runway, Veo, Kling) sirven para anuncios fuera de la página del juego, no para ella | [TERCERO] | [05 §7.1][r05] |
| CapCut gratis cubre solo cuentas personales de redes; Pro quita esa restricción | [TERCERO] | [05 §7.1][r05] |
| Reglas de TikTok y YouTube sobre contenido de IA y música: no investigadas | [NO VERIFICADO] | [05 §7.1][r05] |

### 7.2 Qué hace Claude y qué haces tú

| Pieza | Claude | Aryan |
|---|---|---|
| Guiones, ganchos, textos en pantalla, descripciones, hashtags | Los escribe y varía | Aprueba |
| Calendario de publicaciones y seguimiento | Lo mantiene | Lo cumple |
| Renderizado de clips con subtítulos y escenas | Con el pipeline de vídeo del repositorio (en construcción, ver [00-LEEME.md](../00-LEEME.md)) | Revisa |
| **Grabación del gameplay real** | No puede (requiere el juego abierto en tu equipo) | **La graba** (OBS u otra herramienta) |
| Iconos y miniaturas con IA de imagen | Prepara prompts y especificaciones (512x512, círculo, 16:9) | Genera con tus cuentas de IA y sube a Creator Hub |
| Publicar en TikTok, YouTube Shorts, Discord | Redacta y programa la tanda | **Publica** desde tus cuentas |
| Outreach a creadores | Redacta mensajes y lista candidatos | **Envía** desde tus cuentas y acuerda condiciones |

### 7.3 Guiones: 6 plantillas (≤ 30 s)

Todas [IDEA PROPIA]. El gancho va en los primeros 2 segundos. Siempre gameplay real. Se prueban con 3 a 5 variantes de gancho.

| # | Formato | Gancho (0 a 2 s) | Cuerpo | Cierre |
|---|---|---|---|---|
| 1 | **Momento mítico** | "Mira lo que acabo de pescar" con el banner global visible | Reacción y el aviso al servidor | "Busca Fish & Fortune en Roblox" |
| 2 | **Progresión en 60 s** | "Del lago al volcán en 1 minuto" | Aceleración de la primera zona a la siguiente | Pregunta a los comentarios |
| 3 | **Bestiario** | "La criatura más rara del juego" | Muestra la criatura y su rareza **real** | "¿Cuál te falta?" |
| 4 | **Reto** | "Intento completar el bestiario sin gastar Robux" | Serie por episodios | "Parte 2" |
| 5 | **Co-juego** | "Pesco con mis amigos y pasa esto" | Momento cooperativo | Invitación a jugar con alguien |
| 6 | **Código** | "Código de lanzamiento" (solo cuando el sistema de códigos esté validado) | Qué da y cuándo caduca | Recordatorio de caducidad real |

### 7.4 Calendario de publicaciones

Cadencia propuesta: **3 a 5 clips por semana** por juego en TikTok y YouTube Shorts (y Reels si quieres). Si tus horas no alcanzan, baja a 3; el contenido es consecuencia del juego, no al revés.

| Semana | Qué se publica | Objetivo |
|---|---|---|
| S3 (16 a 22 nov) | Crear cuentas; 2 a 3 teasers del bucle; perfil con enlace a la página del juego cuando exista | Primera audiencia |
| S4 (23 a 29 nov) | 3 clips de "progresión"; lista de creadores | Preparar el lanzamiento |
| S5 (30 nov a 6 dic) | 5 clips: lanzamiento, mítico, código | Empujar G1 |
| S6 (7 a 13 dic) | 4 clips con datos reales del bestiario; primeros mensajes a creadores | G2 |
| S7 (14 a 20 dic) | 4 clips del evento 1 | Reactivar |
| S8 (21 a 27 dic) | 4 a 5 clips del evento festivo | Pico estacional |
| S9 a S12 | 3 clips por semana, repitiendo lo que funcionó | Orgánico |

### 7.5 Colaboraciones con creadores

Los creadores de contenido están detrás de casi todos los hits recientes ([01 §6][r01]); la cifra de "35 a 45 % de sesiones nuevas" es [NO VERIFICADO] ([07 §3.6][r07]).

1. **Lista** de 30 creadores pequeños de Roblox (micro-creadores) en el idioma de tu mercado. Claude la prepara a partir de lo que tú le des; no se verifican audiencias desde aquí.
2. **Oferta inicial** [IDEA PROPIA]: acceso anticipado, código exclusivo, servidor VIP y que sus momentos salgan en el banner del juego. **Sin pagos fijos** al principio ([07 §3.6][r07]).
3. **Mecánicas "clipables"**: banner global de mítico, drops raros, anuncios de servidor.
4. **Códigos**: validados en servidor, con caducidad y límite de canjes, que dan boosts y no moneda masiva. El sistema oficial de afiliados no se investigó; usamos códigos propios [IDEA PROPIA] ([05 §7.2][r05]).
5. **Medición**: canjes por código y eventos personalizados de analítica.
6. **Cumplimiento**: el contenido pagado o con incentivo debe declararse como publicidad; no prometer "Robux gratis" ([05 §7.1][r05]).

---

## 8. KPIs a vigilar

Se miden en Creator Analytics (gratis) y se consolidan con la API de consulta de analítica (permiso `universe.analytics:read`), que permite un panel único del portafolio con un script ([06 §7.2][r06], [05 §7.3][r05]) [OFICIAL]. Claude genera un informe semanal; tú lo lees el domingo.

| KPI | Dónde | Referencia o umbral | Acción |
|---|---|---|---|
| Visitas por fuente (orgánico, anuncios, creadores) | Analytics | G4: orgánico ≥ 30 % | Si es bajo, más clips y creadores |
| **D1, D7, D30** | Analytics (`ForwardD1Retention`, etc.) | G1 a G2 arriba [IDEA PROPIA]; mediana GameAnalytics 10,3 / 1,6 / 0,5 % [TERCERO] | Arreglar el tutorial y el bucle antes de gastar más |
| Sesión media | Analytics | G1: matar si < 4 min; mediana 2026 de ~9,8 min o ~7,3 min según el resumen [TERCERO], contradictorias | Alargar el bucle de 5 a 10 min |
| Embudo FTUE (llega a la primera recompensa en ≤ 60 s) | Eventos propios | G0: ≥ 85 % | Quitar menús y pasos |
| Conversión a pagador (`PayingUsersCVR`) | Analytics | 1 a 3 % típico en blogs [TERCERO débil]; G2: ≥ 1 % compra | Ajustar la oferta de inicio y su momento |
| ARPPU, ARPDAU, **RPV** (Robux por visita) | Analytics | 0,5 RPV es una referencia comunitaria [TERCERO débil] | Comparar con el coste por visita |
| Ingreso a 7 días por visitante vs coste por visita | Hoja propia | G3: ≥ coste = escalar | Si no, no se escalan anuncios |
| CCU pico y valle, jugadores a la vez | Analytics | G4: pico ≥ 500 | Tier A |
| Robux ganados acumulados | Creator Hub | Mínimo para cobrar: **30.000 R$ (≈ 114 USD)** [OFICIAL] | Estimar fecha del primer cobro |
| Errores de servidor (datos, recibos pendientes) | Consola y alertas | Cualquier recibo duplicado o pendiente reiterado es prioridad uno. Las alertas exigen ≥ 100 DAU y llegan solo por webhook [OFICIAL] ([06 §7.2][r06]) | Parche inmediato |
| Rendimiento móvil (fotogramas, memoria) | Analytics de rendimiento | Probar en móvil gama baja | Optimizar |
| Reportes y moderación | Panel Safety | Cualquier pico | Revisar el contenido |
| Piloto de ropa (si se hace) | Transacciones de Creator Hub | Ventas medianas por ítem < 3 al mes y retorno < 1,0x en el 60 % de ítems = matar ([08 §6.3][r08]) [IDEA PROPIA] | Parar el piloto |
| Mercado | Trackers (Rolimon's, RoMonitor) y resultados de Roblox | Vigilar si aparece un formato nuevo con ≥ 100.000 CCU en < 2 semanas | Decidir si hay ventana de "seguidor rápido" (4 a 6 semanas) ([07 §5.3][r07]) |

---

## 9. Reparto resumido: Claude y Aryan

| Área | Claude (automatizable) | Aryan (a mano) |
|---|---|---|
| Papeles | Hoja de datos, guía, recordatorios | **W-8BEN, identidad, impuestos, aceptar términos, método de cobro** |
| Cuentas y claves | Define permisos mínimos y los usa | **Crea cuentas y claves**, las guarda como secretos |
| Código | Escribe, prueba (Lune), pasa linters, documenta | **Prueba en Studio y en móvil real**; revisa todo lo de dinero |
| Publicación | Compila y prepara la versión | **Aprueba y publica a producción**; cuestionario de madurez fiel; crear universo |
| Datos y mercado | Informe semanal, resumen de políticas | Leer, decidir y matar |
| Marketing | Guiones, calendario, renders, mensajes | **Grabar, publicar, enviar** |
| Ropa (opcional) | Scripts de Blender, plantillas de textura, descripciones y metadatos, hoja de precio contra el suelo, lista de comprobación de IP | **Subir los ítems (Save to Roblox o web), pagar subida y anticipo, revisar a ojo el ajuste en varios cuerpos** |
| Dinero | Cálculos de equilibrio y presupuesto | **Pagar anuncios, Plus y tarifas** |

---

## 10. Escenarios al día 90

| Escenario | Señal | Qué hacemos |
|---|---|---|
| **A. Ningún juego pasa G2** | D7 < 1,5 % o sin compradores | Parar gasto; revisar qué falló (¿FTUE?, ¿bucle?, ¿tráfico?); decidir entre 2.º concepto (Rumble Rotation) o pivotar el bucle. La ropa solo como línea secundaria: el informe 08 la desaconseja como motor ([08 §6.1][r08]) |
| **B. Un juego pasa G2 y G3** | Retención y gasto sostenidos | Tier A, actualización semanal, reinvertir el 70 % de ingresos, empezar el 2.º juego |
| **C. Pico viral** | CCU crece rápido | **Cobrar mientras sube**: la caída típica es del 90 al 99 %. No contratar ni gastar contra ingresos futuros. Eventos y códigos ya preparados. Primer cobro: 30.000 R$ + papeles al día |
| **D. Problema de cuenta o moderación** | Aviso de Roblox, juego retirado | Apelar por el cauce oficial, sin cuentas alternas ni spam; restaurar desde copias `.rbxl`; revisar cuestionario e IP |

### Decisión de día 90 (lunes 18-ene-2027)

Con el informe de la semana 11, decidir una de tres: **continuar** (cartera pequeña con puertas), **pausar** (mantener Tier C y revisar en 90 días) o **cambiar el peso de las líneas** (más ropa o avatar solo si los datos del piloto y tu respuesta 11 lo justifican; el criterio es el de [informe maestro §9.4](informe-maestro.md)). Decidir con el tope de pérdida y las horas reales, no con la ilusión.

---

## 11. Lo que verificaremos durante el plan

| Duda | Dónde se resuelve | Quién | Cuándo |
|---|---|---|---|
| Países de DevEx y método de cobro | Help Center y Tipalti | Aryan | S0 |
| Términos de Uso del 1-nov | Help Center y DevForum | Aryan | Antes del 1-nov |
| Si "Premium" sigue a la venta y si Plus es necesario para actualizar | Creator Hub | Aryan | S0 |
| Umbral y condiciones de reembolso de la tarifa | Creator Hub, panel Audience Reach | Aryan | S4 |
| Detalle R15 para la tarifa 18+ | Documentación de Roblox | Claude, Aryan confirma | S3 |
| Coste real por visita en Ads Manager | Una campaña pequeña | Aryan | S5 |
| Compras en Studio y suscripciones en pruebas | Universo de pruebas | Aryan y Claude | S2 a S4 |
| Texto exacto de las señales del algoritmo | Documentación y DevForum | Aryan | S4 |
| Resultados T3 de Roblox | 29-oct | Claude resume | S0 |
| Reglas de TikTok y YouTube sobre contenido de IA | Sus políticas | Aryan | S3 |

[r01]: ../research/01-mejores-juegos.md
[r02]: ../research/02-monetizacion-y-economia.md
[r03]: ../research/03-politicas-y-cumplimiento.md
[r04]: ../research/04-ia-studio-mcp-skills.md
[r05]: ../research/05-ia-assets-y-marketing.md
[r06]: ../research/06-stack-tecnico.md
[r07]: ../research/07-diseno-crecimiento-y-conceptos.md
[r08]: ../research/08-ropa-vs-juegos.md
