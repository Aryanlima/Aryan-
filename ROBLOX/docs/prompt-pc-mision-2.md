# Prompt para la sesión del PC: misión 2 (experiencia privada, pases y productos, IDs cableados)

Cuándo usarlo: después de que la sesión del PC haya hecho (o pueda hacer) el primer playtest ([prompt-pc-playtest-1.md](prompt-pc-playtest-1.md)). Esta misión encadena las **Etapas 0 a 3** de [publicar-paso-a-paso.md](publicar-paso-a-paso.md): playtest sin compras, experiencia de prueba **privada**, pases/productos **fuera de venta**, IDs cableados y comprobados **sin confirmar ninguna compra**. No hace nada público y no gasta nada.

## Antes de pegar (Aryan, 3 minutos)

1. Abre Roblox Studio con tu sesión iniciada y deja el PC desbloqueado: la sesión usará el control del escritorio **solo con tu permiso**.
2. **Rellena las dos líneas "DATOS DE ARYAN"** del bloque (si no sabes algo, déjalo en blanco; la sesión omitirá esa prueba y lo anotará como NO PROBADO).
3. *(Opcional, ahorra muchos clics; si no, se hace a mano en Creator Hub)* Crea la clave de API **tú**: Creator Hub → *API Keys* → *Create API Key*. Límites: **solo** estas APIs, **solo** la experiencia de prueba (ya existirá tras la Etapa 1; si todavía no la tienes, la sesión te avisará y se hace en ese momento), caducidad de 7 días:
   - *Game Passes*: lectura y escritura · *Developer Products*: lectura y escritura · *Place Publishing (universe-places)*: escritura · *universe* (lectura de la experiencia), si aparece.
   Guárdala en una **variable de entorno de usuario** llamada `ROBLOX_API_KEY` (Panel de control → "Editar las variables de entorno de esta cuenta" → Nueva), y **abre una terminal nueva**. **No** la pegues en el chat, ni en un archivo.
4. Pega el bloque en la sesión de Claude Code del PC, abierta en la carpeta `Aryan-`.

## El mensaje (copiar todo el bloque)

```
Hola. Soy Aryan. MISIÓN 2 de Fish & Fortune: encadenar las ETAPAS 0 a 3 de ROBLOX/docs/publicar-paso-a-paso.md (léelo entero primero, y también ROBLOX/docs/pc-investigacion/verificacion-pases-y-publicacion.md). Hazlo tú de principio a fin, sin pedirme nada salvo lo que diga "PARAR". Responde en español y simple (no soy programador).

RETOMAR: si ROBLOX/docs/mision-2-informe.md ya existe, léelo primero. NO repitas las filas OK ni crees otra experiencia (la privada ya existe: Universe ID y Place ID en el informe); empieza en la primera fila PENDIENTE o FALLA y actualiza el mismo informe. Haz `git merge origin/claude/brave-meitner-esyqy8` antes (trae el arreglo de pickDataStore con 642 pruebas, el diagnóstico de wire-ids.spec y la resolución del conflicto con tu arreglo: queda el de la nube).

DATOS DE ARYAN (rellenados antes de pegar; en blanco = no sé):
  ROBUX_EN_LA_CUENTA: ________   (si pongo 0 puedes hacer la prueba del diálogo de compra de la Etapa 3.5; si es mayor que 0 o está en blanco, OMÍTELA y anótala NO PROBADO)
  GUARDÉ_ROBLOX_API_KEY: SI / NO  (SI = ya creé la clave y la guardé en la variable de entorno ROBLOX_API_KEY)

REGLAS DURAS (si algo las rompería, PARAR y avisarme; no hay excepciones):
 1. NO hagas público nada. Nunca pulses Continue/Publish en la ventana de madurez, nunca toques "Manage Audience", "Public", "Activate", ni cambies la audiencia, la edad o las regiones. La experiencia se queda PRIVADA todo el tiempo.
 2. NO gastes Robux ni pagues tarifas (ni la de 1.000 Robux, ni Plus, ni Premium). NUNCA pulses el botón de confirmar compra de un diálogo de Roblox. En los diálogos no hagas clic: ábrelos, toma captura y ciérralos con la tecla Escape o parando el playtest.
 3. NO toques mi verificación de identidad/edad, la 2FA, el formulario fiscal (W-9) ni nada de Impuestos/Finanzas.
 4. NO guardes claves en archivos ni las escribas en el chat ni en comandos. La clave de Open Cloud solo vive en la variable de entorno ROBLOX_API_KEY (la creo yo). Para saber si existe usa SOLO: node -e "console.log(process.env.ROBLOX_API_KEY ? 'definida' : 'NO definida')". Prohibido imprimirla: nada de echo/Write-Host de la variable, ni set, ni env, ni Get-ChildItem Env:.
 5. NO marques nada como "Listed" (Monetization > Shop) y NO crees Pase Suerte+ ni Cebo de Suerte (están APAGADOS a propósito en la v1).
 6. Commits SOLO en la rama pc/aryan-local (nunca en claude/brave-meitner-esyqy8 ni en main). Push: git push -u origin pc/aryan-local.
 7. No edites el código del juego (src/, packages/) ni las pruebas. Solo estos archivos: ROBLOX/games/fish-and-fortune/ids.local.json, ROBLOX/games/fish-and-fortune/src/server/ProductIds.luau (y SOLO mediante node ROBLOX/tools/wire-ids.mjs), y ROBLOX/docs/mision-2-informe.md. Si el código falla, reporta; la nube lo arregla.
 8. execute_luau solo para consultas de SOLO LECTURA (GetProductInfoAsync, leer propiedades) y para el escuchador de la Etapa 3.5. Nada que escriba DataStores, publique o compre.
 9. Si la interfaz de Creator Hub o de Studio NO coincide con lo documentado (botones distintos, pasos que faltan, errores raros), PARA, toma una captura, anótalo como FALLA/NO PROBADO en el informe y avísame. No improvises ni insistas con clics, y menos si hay dinero de por medio.
10. Ejecuta todos los comandos node/bash desde Git Bash (el "bash" de Windows/WSL rompe los scripts).

INFORME (obligatorio): crea y mantén ROBLOX/docs/mision-2-informe.md con una tabla "paso | resultado (OK / FALLA / NO PROBADO) | evidencia (salida de consola, ruta de captura, ID) | notas". Una fila por paso numerado de abajo. Actualízala y haz commit al terminar CADA etapa (git add del informe, ids.local.json y ProductIds.luau; mensaje corto en español). Las capturas se guardan en ROBLOX/.toolchain/evidencia/ (no se versiona) y en el informe pones su nombre.

ETAPA 0 — Preparación y playtest sin compras
 0.1 git fetch origin; git checkout pc/aryan-local; git merge origin/claude/brave-meitner-esyqy8 (si hay conflictos, conserva la versión de la nube, salvo en tu estado-pc.md y en los archivos que ya existían en pc-investigacion/). Comprueba .gitattributes (LF) y node --version (>= 20). Si falta algo del toolchain: cd ROBLOX && rokit install.
 0.2 Corre bash ROBLOX/tools/test.sh, bash ROBLOX/tools/lint.sh y bash ROBLOX/tools/format.sh --check. Anota los números REALES (se esperan 642 pruebas o más, 0 fallos). Si tools/wire-ids.spec.luau falla, la salida ahora trae un bloque "[wire-ids.spec] node --test FALLO" (código de salida, so, cwd, comando, stdout y stderr de node): copia ese bloque ENTERO al informe; no lo parchees. Si falla algo que en la nube pasa, diagnostica y reporta SIN parchear el juego (otro agente de la nube puede estar editando: espera 2 minutos y repite una vez).
 0.3 Playtest sin compras: si ROBLOX/docs/playtest-1.md ya trae la "Segunda pasada" sin FALLA en arranque, tienda, datos ni tutorial, NO lo repitas (cita su resumen). Si no, repítelo según ROBLOX/docs/prompt-pc-playtest-1.md y añade una nueva sección fechada. En un lugar sin publicar debe salir el aviso "[Data] ... almacen en MEMORIA" y el servidor NO debe caerse; el aviso ContentId rbxassetid://203785492 no es del repo (anótalo, no es FALLA).
 0.4 Puerta: si el playtest más reciente tiene FALLA en arranque, tienda, datos o el tutorial de 60 s, PARAR y avisarme (la nube arregla y se repite).

ETAPA 1 — Experiencia de prueba PRIVADA
 1.1 Pide permiso del escritorio y crea la experiencia: en Studio abre un lugar nuevo (Baseplate), File > Publish, ventana "Game details": nombre "FF Pruebas (privado)", género y descripción cortos, Save. Si aparece otra ventana con Invite/Continue o preguntas del cuestionario de madurez, ciérrala sin pulsar nada (es el flujo de hacerla pública).
 1.2 Anota el Universe ID (Creator Hub > Creations > ⋯ de la miniatura > Copy Universe ID) y el Place ID (la experiencia > Places > el lugar; está en la URL .../places/{PlaceID}/configure).
 1.3 Comprueba que es PRIVADA: captura de Creator Hub (no debe aparecer como pública) y, si GUARDÉ_ROBLOX_API_KEY = SI, node ROBLOX/tools/publish-place.mjs --universe <U> --place <P> (plan) y luego con --apply (sube una versión GUARDADA; se niega solo si la experiencia no es privada).
 1.4 Carga el juego: rojo serve ROBLOX/games/fish-and-fortune/default.project.json (déjalo corriendo en segundo plano) y conecta el plugin en ese lugar. Con search_game_tree comprueba que están el mundo y los scripts.
 Puerta: es privada y tienes Universe ID y Place ID. Si Creator Hub no la muestra privada o algo no encaja: PARAR.

ETAPA 2 — Pases y productos (fuera de venta)
 2.1 La lista exacta a crear está en ROBLOX/games/fish-and-fortune/store-items.json (11 objetos: 5 pases y 6 productos; NO Suerte+ ni Cebo). Nombre en inglés, descripción en inglés, precio y el ícono de ROBLOX/marketing/fish-and-fortune/assets/.
 2.2 CAMINO A (si GUARDÉ_ROBLOX_API_KEY = SI y la variable está "definida"): node ROBLOX/tools/create-items.mjs --universe <U> (revisa el plan) y luego node ROBLOX/tools/create-items.mjs --universe <U> --apply. Crea fuera de venta, es idempotente y guarda los IDs en ids.local.json. Si da error de permisos o la API se comporta distinto: apunta el error tal cual (sin la clave) y pasa al camino B.
     CAMINO B (a mano, con el control del escritorio y mi permiso): Creator Hub > la experiencia > Monetization > Passes > Create pass (ícono, nombre, descripción, categoría, precio) y Monetization > Developer Products > Create developer product (ídem). Copia cada ID con ⋯ > Copy Asset ID. Crea ids.local.json desde ids.example.json. Una captura por cada pase/producto creado.
 2.3 Si Creator Hub no deja crear objetos en una experiencia PRIVADA: PARAR y avisarme (NO la hagas pública para poder crearlos).
 2.4 Comprueba que ningún objeto está "Listed" ni a la venta (todavía) y que nombres y precios coinciden con store-items.json.
 Puerta: 11 objetos creados e ids.local.json completo (luck_plus y lucky_bait_15 siguen en 0).

ETAPA 3 — Cablear y comprobar SIN gastar
 3.1 node ROBLOX/tools/wire-ids.mjs --dry-run  (revisa el resumen; si hay problemas, corrige ids.local.json, nunca ProductIds.luau a mano).
 3.2 node ROBLOX/tools/wire-ids.mjs  (escribe ProductIds.luau y corre la puerta FF_RELEASE_CHECK=1). Debe terminar con PUERTA OK. Si falla, restaura solo y te cuenta por qué; reporta y PARA.
 3.3 Verificación de solo lectura: node ROBLOX/tools/wire-ids.mjs --emit-verify-luau  e imprime un script; ejecútalo con la herramienta execute_luau de Studio (datamodel Edit, la experiencia de prueba abierta). Anota la salida COMPLETA: cada línea dice OK o REVISAR (nombre/precio/venta/TargetId). Si execute_luau no puede llamar a GetProductInfoAsync, pruébalo en un playtest (datamodel Server) y anótalo.
 3.4 TargetId o assetId: para cada pase compara el número de "Copy Asset ID" con el TargetId que informó 3.3. Todos iguales = Caso A, no cambias nada. Distintos = Caso B: en ids.local.json pon "vip": { "passId": <TargetId>, "assetId": <el de Copy Asset ID> } (y lo mismo para los que difieran), repite 3.1 y 3.2 y anótalo.
 3.5 Diálogo de compra SIN confirmar (SOLO si ROBUX_EN_LA_CUENTA = 0; si no, fila NO PROBADO). Para poner a la venta, solo con la experiencia privada comprobada: node ROBLOX/tools/create-items.mjs --universe <U> --apply --for-sale (comprueba por API que es PRIVATE) o el interruptor en Creator Hub. Luego: start_stop_play (Play solo). Con execute_luau en el datamodel Server: (a) conecta un escuchador: game:GetService("MarketplaceService").PromptGamePassPurchaseFinished:Connect(function(p,id,w) print("[MISION2] Finished id="..tostring(id).." comprado="..tostring(w)) end); (b) abre el diálogo de UN pase con su passId de ProductIds.luau: game:GetService("MarketplaceService"):PromptGamePassPurchase(game.Players:GetPlayers()[1], <passId>). Toma screen_capture (nombre y precio del diálogo deben ser los del pase). Cierra con user_keyboard_input Escape (NO hagas clic; si Escape no lo cierra, para el playtest con start_stop_play). Lee get_console_output: debe salir "[MISION2] Finished id=<el mismo passId> comprado=false" y NO debe salir "ID de pase DESCONOCIDO" (si no sale ninguna línea Finished al cerrar con Escape, anótalo como NO CONCLUYENTE: no es un fallo del juego). Repite con UN producto (PromptProductPurchase). Pon el id que informó el evento en el informe. Si el diálogo muestra otro objeto, un error, o el id del evento es distinto: PARAR (Caso D) y reportar; no cambies código.
 3.6 git status; git diff --stat; commit (ids.local.json, ProductIds.luau, informe) en pc/aryan-local y git push -u origin pc/aryan-local.

AL TERMINAR: dime en 6 líneas máximo qué pasó en cada etapa, qué quedó NO PROBADO y qué decisión me toca a mí (la 3b —una compra real de 49 Robux—, la Etapa 4 con amigos y la Etapa 5 pública son SOLO mías y no las hagas). Recuérdame que revoque la clave de API cuando acabemos.
```

## Qué esperar

- Tiempo: unos 30 a 60 minutos. Se interrumpe solo con "PARAR" (interfaz distinta, no se deja crear en privado, un resultado que contradice la documentación, o algo que implicaría dinero o hacer público).
- Resultado: `ROBLOX/docs/mision-2-informe.md` en la rama `pc/aryan-local` (la nube lo lee allí), con `ids.local.json` y `ProductIds.luau` con los IDs reales, y el commit hecho.
- Después, la nube revisa el informe: arregla lo que falle, resuelve el caso B/D si apareció, y tú decides si hacer la compra mínima (3b), la prueba con amigos (4) y, algún día, lo público (5).
- Cuando termine todo: **revoca la clave de API** en Creator Hub y borra la variable `ROBLOX_API_KEY`.
