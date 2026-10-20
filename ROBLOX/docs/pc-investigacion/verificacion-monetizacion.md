# Verificación de monetización (fuentes oficiales)

Leído el 2026-10-20 desde la PC. Etiquetas: **[OFICIAL]** = página de Roblox (create.roblox.com, Help Center o DevForum de anuncios); **[TERCERO]** = otra web; **[NO VERIFICADO]** = no se pudo confirmar.
Las páginas de create.roblox.com se leyeron en su versión `.md` (por ejemplo `.../MarketplaceService.md`). Todas tienen `last_updated` 2026-10-19.

## 1. ProcessReceipt frente a BindReceiptHandler (CRÍTICO)

**Respuesta corta:** sí existe una API nueva, `MarketplaceService:BindReceiptHandler`. **`ProcessReceipt` NO está deprecado**: no tiene etiqueta ni mensaje de deprecación. La doc llama a ProcessReceipt "legacy" y a la nueva "newer alternative", pero ninguna página dice que haya que migrar. La guía de developer products sigue enseñando solo ProcessReceipt. **[OFICIAL]**
- URL: https://create.roblox.com/docs/reference/engine/classes/MarketplaceService
- URL: https://create.roblox.com/docs/production/monetization/developer-products

**Firmas exactas [OFICIAL]:**
```
MarketplaceService:BindReceiptHandler(transactionType: ReceiptType, handler: Function, filter: Array?): RBXScriptConnection
MarketplaceService.ProcessReceipt(receiptInfo: Dictionary): ProductPurchaseDecision
```
- BindReceiptHandler: `Security: None · Thread Safety: Unsafe · Capabilities: Monetization`, sin etiqueta "Yields".
- `transactionType`: `Enum.ReceiptType.DeveloperProduct`, `RobuxTransferSender` o `RobuxTransferReceiver`.
- `filter`: lista opcional de IDs de producto. Cita: "Not supported for `RobuxTransferSender` or `RobuxTransferReceiver` receipt types."
- Devuelve una `RBXScriptConnection`; si la desconectas, el handler deja de estar registrado.
- **El handler debe devolver `Enum.ReceiptDecision`** (es otro enum, no `ProductPurchaseDecision`):
  - `Processed` (1): "The receipt is marked as complete and will not be delivered again."
  - `NotProcessedYet` (0): "keeps the receipt unresolved so it will be redelivered" (en esta sesión o al volver a entrar).
  - Fuente: https://create.roblox.com/docs/reference/engine/enums/ReceiptDecision
- ProcessReceipt sigue devolviendo `Enum.ProductPurchaseDecision.PurchaseGranted` o `NotProcessedYet`.

**Prioridad y errores [OFICIAL]:**
- Cita: "A bound handler takes precedence; if no bound handler matches a developer product receipt, it falls through to `ProcessReceipt`."
- Un handler con filtro gana al handler sin filtro (catch-all) para los productos de su lista.
- Lanza un error si ya hay un handler para el mismo tipo y producto, o si ya hay un catch-all para ese tipo.
- Consecuencia: **un catch-all de DeveloperProduct se queda con TODOS los recibos** y ProcessReceipt deja de recibirlos. Se pueden mezclar, pero hay que hacerlo con cuidado.
- Campos del recibo: `PurchaseId`, `PlayerId`, `PlaceIdWherePurchased`, `ReceiptType`, `ProductId`, `CurrencyType` y `CurrencySpent`. `TransferRequestId` solo viene en recibos de transferencias de Robux.
- Las transferencias de Robux (`PromptRobuxTransferAsync`) **solo** se procesan con BindReceiptHandler, no con ProcessReceipt.

**Uso mínimo (resumen del ejemplo oficial) [OFICIAL]:**
```lua
MarketplaceService:BindReceiptHandler(Enum.ReceiptType.DeveloperProduct, function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ReceiptDecision.NotProcessedYet end
	-- conceder de forma idempotente con UpdateAsync, usando receiptInfo.PurchaseId como clave
	return Enum.ReceiptDecision.Processed -- solo si quedó guardado
end, { COINS_PRODUCT_ID }) -- quita la lista para registrar un catch-all
```

**Datos de ProcessReceipt que conviene conocer [OFICIAL]:**
- Cita: "You should only set the `ProcessReceipt` callback one time in a single server-side Script."
- Cita: "If you don't implement a `ProcessReceipt` callback, your receipts will be auto-acknowledged." Es decir, si no defines el callback, la compra se da por confirmada sin entregar nada.
- No reintenta por tiempo: solo vuelve a llamarse en una nueva compra o cuando el jugador vuelve a entrar.
- Un mismo recibo **puede ejecutarse en dos servidores a la vez**. Por eso la idempotencia por `PurchaseId` es obligatoria.

**Comparación con el repo:**
- `tools/examples/ReceiptHandler.luau` usa `ProcessReceipt` con `PurchaseGranted`/`NotProcessedYet`, idempotencia por PurchaseId y NotProcessedYet si el jugador no está. **Es correcto y sigue vigente.** No hace falta migrar.
- Si algún día se pasa a BindReceiptHandler, hay que **cambiar el enum de retorno** a `Enum.ReceiptDecision.Processed`/`NotProcessedYet`. Si se deja `ProductPurchaseDecision`, el handler devuelve un tipo incorrecto.
- **Contradicción menor:** research/02 (línea ~123) marca el uso de ProcessReceipt como [NO VERIFICADO]. Ahora está **[OFICIAL]**.
- Aviso: el ejemplo oficial de BindReceiptHandler suma las monedas **dentro** de la función de transformación de `UpdateAsync`. Esa función puede ejecutarse varias veces, así que no hay que copiar ese detalle. El enfoque del repo (cambiar los datos que se guardan) es más seguro.

## 2. Paid Random Items (loot boxes)

Fuente principal: https://create.roblox.com/docs/production/monetization/paid-random-items **[OFICIAL]**
- Incluye compras **indirectas**: gemas o tickets comprados con Robux y luego gastados en el azar. Cita: "Paying Robux to buy gems or spin tickets that are spent at a prize wheel."
- Hay que mostrar todos los resultados con su probabilidad numérica **antes** de comprar. Cita: "must indicate all possible outcomes and the actual numerical odds".
- Las probabilidades van en %. Cita: "must sum to exactly 100%". Se permite redondear si se añade un aviso.
- Si no caben, se usa un pop-up con botón "Info" o "Details". Cita: "a standalone symbol like the (i) icon without a descriptive word is **not** sufficient".
- Los objetos de suerte (pociones, cañas, pity) deben explicar su efecto en números y actualizar las probabilidades mostradas mientras estén activos.
- Las recompensas aleatorias que no se pagan con Robux ni con moneda comprada con Robux no necesitan mostrar probabilidades.
- **PolicyService [OFICIAL]** (`GetPolicyInfoForPlayerAsync`, https://create.roblox.com/docs/reference/engine/classes/PolicyService):
  - Si `ArePaidRandomItemsRestricted` es true, el jugador "can **not** interact with paid random item generators".
  - En ese caso hay que aplicar una de 6 salidas: camino gratis, orden fijo divulgado, venta directa a precio de valor esperado, ocultar el objeto, bloquear la compra con un mensaje o sacar al jugador de la zona.
  - `IsPaidItemTradingAllowed` (true = puede intercambiar) es una comprobación aparte, solo para el intercambio de objetos.
- **Regiones:** la doc oficial **no nombra países**. El anuncio del DevForum "Clarifying Requirements for Paid Random Items" (26-may-2026, sección Announcements) cita "Australia, Belgium, Netherlands, United Kingdom, and Brazil" como mercados regulados, y dice que la lista la fija Roblox y puede cambiar.
  - URL: https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622
  - **[OFICIAL-DevForum]**, aunque el autor (`dinobotsnarl824`) no aparece marcado como staff en lo que se leyó.
  - Regla práctica: no programar por país; usar siempre el flag de PolicyService.
- Del mismo anuncio: "There cannot be an outcome where the user simply loses their payment", y el castigo puede ser "game will be removed and your account will be suspended".
- **Comparación con el repo:** research/03 §2.1 coincide. El repo marcaba la lista de países como [TERCERO]; en realidad sale de un anuncio del DevForum y no de la doc.

## 3. Tarifa DevEx y requisitos

- **No hay tarifas por país [OFICIAL].** Hay una tarifa estándar, una tarifa antigua y una tarifa "designada" (18+ EE. UU.). Fuente: https://create.roblox.com/docs/production/monetization/developer-exchange
  - Cita: "The standard exchange rate for the DevEx program is `0.0038` per 1 Earned Robux, which comes out to $114 USD for 30,000 Earned Robux."
  - `0.0054` solo para ciertas compras de jugadores de EE. UU. de 18+ con edad verificada, en juegos elegibles.
  - `0.0035` para Robux ganados antes del 5-sep-2025 a las 10:00 PT. Ese saldo antiguo **se cobra primero**.
  - El pago se hace en dólares. Los Términos dicen "exchange your Earned Robux for U.S. dollars".
- **Requisitos [OFICIAL]:**
  - Tener 13 años o más.
  - Tener 30.000 Earned Robux.
  - Tener un email verificado.
  - Tener una cuenta en el portal DevEx.
  - Tener en archivo el formulario W-9 (EE. UU.) o W-8 (resto).
  - Cumplir los Términos de Uso y los Community Standards.
  - Solo se puede cobrar una vez al mes.
  - La cuenta caduca si no se usa durante 2,5 años.
  - No se piden Premium ni ID en la lista oficial. Sí se piden documentos fiscales (ver §4).
- **Países:** los Términos de DevEx (Help Center, actualizado el 2026-10-07; leído por la API pública de Zendesk porque la web da 403) dicen:
  - Cita: "We are not able to remit payments to certain countries, entities, or individuals because of legal or other considerations".
  - Cita: pagan en "over one hundred different countries".
  - La lista enlaza a la cobertura de **Tipalti** (help.tipalti.com, que da 403).
  - URL: https://en.help.roblox.com/hc/en-us/articles/115005718246-Developer-Exchange-Terms-of-Use **[OFICIAL]**
  - **Qué países quedan fuera: [NO VERIFICADO]**. Lo más probable es que sean los países con sanciones de EE. UU., pero no está confirmado. Hay que mirarlo en el portal de Tipalti.
- **Comparación con el repo:** research/02 §2.2 y research/03 §5 coinciden (0,0038, 0,0054, 0,0035, 13+, 30.000, W-9/W-8). No hay contradicciones.

## 4. Cambio fiscal del 1-nov-2026

Fuente: https://create.roblox.com/docs/production/monetization/tax-information **[OFICIAL]** (last_updated 2026-10-19)
- **Fecha confirmada.** Cita: "Beginning **November 1, 2026**, DevEx payments will be classified as royalties".
- Fechas oficiales:
  - 15-jul: se abre la página Taxes.
  - **15-oct**: fecha "Recommended deadline to request a DevEx payout before the Terms of Use update" (ya pasó).
  - **31-oct**: último día. Lo que hayas enviado ese día o antes fija la retención de los primeros pagos.
- **Qué debe hacer un creador no estadounidense antes del 31-oct-2026:**
  1. Entrar en Creator Hub > **Finances > Taxes** y revisar el estado. Tiene que quedar en "Validated".
  2. Enviar los datos para generar el **W-8BEN** (persona) o el **W-8BEN-E** (empresa). Se firma electrónicamente.
  3. Preparar estos datos:
     - nombre legal;
     - país de ciudadanía;
     - dirección permanente;
     - fecha de nacimiento;
     - NIF/TIN de EE. UU. **y/o** del propio país.
  4. Para pedir la tasa reducida de un tratado fiscal, el W-8 debe estar completo y llevar un TIN. Además, el país de ciudadanía debe coincidir con el país de la dirección permanente.
  5. Mantener los datos de pago al día en Tipalti. No hace falta crear una cuenta nueva.
- **Retención [OFICIAL]:**
  - Sin datos válidos: cita "**24% U.S. backup withholding** may apply to your full payout".
  - Con datos válidos: "0% to 30%" solo sobre la parte de ventas a jugadores de EE. UU., según el país y el tratado.
- Importa la fecha en que se **paga**, no la de la solicitud. Cita: "apply based on the payout date, not the submission date".
- Formularios de fin de año: el 1042-S para no estadounidenses, que se descarga en Creator Hub.
- Roblox no da asesoría fiscal. Para tu caso concreto, consulta a un contador.
- **Comparación con el repo:** research/03 §1 y §5.4 coinciden. Dos correcciones:
  - Lo de "depende de la fecha de pago" estaba como [TERCERO] (Panstag/StarBox). Ahora es **[OFICIAL]**.
  - research/02 línea ~99 marca el cambio del 1-nov como "[NO VERIFICADO], una sola fuente". Ahora está **[OFICIAL]** y ya no se limita a un W-9 inválido: afecta a todos los creadores.
