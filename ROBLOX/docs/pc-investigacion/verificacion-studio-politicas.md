# Verificación: Studio, políticas y Open Cloud

Leído el **2026-10-20** desde esta PC. Las páginas de create.roblox.com/docs muestran `last_updated: 2026-10-19`.
Marcas: [OFICIAL] = docs de Roblox o anuncio de DevForum escrito por "Roblox Staff" · [TERCERO] = otra fuente · [NO VERIFICADO] = no encontré cita.

## ⚠ Contradicciones con el repo

1. **Script Sync YA NO es beta.** `flujo.md` (líneas 21-22) dice "sigue en beta" y marca el lanzamiento completo como [NO VERIFICADO]; `research/04` (línea 167) lo marca [TERCERO]. Hoy es **[OFICIAL]**: anuncio de staff "[Full Release] Studio Script Sync" del 2026-06-17. Ojo: la guía `ai/coding-harness` sigue diciendo "Enable the Script Sync beta" (está desactualizada; la propia documentación de Roblox se contradice).
2. **Los requisitos de publicación se aplican también a cada actualización**, no solo a juegos nuevos. `research/03` (línea 177) no lo tenía claro. Esto afecta a publicar por Open Cloud (ver punto 4).
3. Fechas de Planning Mode (`research/04`, línea 367): anuncio **2026-04-16**; planes Markdown editables **2026-06-18**. Ya está resuelto.
4. Lo demás del repo (5 juegos al día, tarifa de 1.000 Robux, permisos de Open Cloud) **coincide**.

## 1. Planning Mode del Roblox Studio Assistant

- **Existe.** [OFICIAL] create.roblox.com/docs/en-us/assistant/guide (sección "Planning Mode"):
  > "Planning Mode lets you preview Assistant's next steps before execution."
- **Cómo se activa:** en el desplegable de Assistant elige **Plan** o escribe `/plan`. [OFICIAL] misma página.
- **Qué hace:** primero hace preguntas, luego crea un plan de tareas que puedes editar, reordenar o borrar, y después ejecuta y prueba. Esto es el ciclo "Plan, Build, and Test". Usa la generación de materiales y mallas y la inserción desde Creator Store. [OFICIAL] devforum.roblox.com/t/announcing-planning-mode-for-roblox-assistant/4580715 (staff, 2026-04-16)
- **Planes en Markdown (2026-06-18):** se guardan en la nube, ligados a tu experiencia y a tu perfil, y son privados (los colaboradores no los ven). Tienen un editor propio ("Open Plan") y un botón Save.
  > "Plans never auto-execute or time out into acceptance. The workflow only executes when you click **Build**"
  [OFICIAL] assistant/guide y devforum.roblox.com/t/4690993 (staff, 2026-06-18)
- **¿Se puede usar desde el MCP o desde Claude Code?** **No.** La lista oficial de herramientas del MCP de Studio (create.roblox.com/docs/en-us/studio/mcp) **no incluye ninguna herramienta de plan**. Lo más parecido es `subagent` (tipos `explore` y `playtest`). [OFICIAL: no aparece en la lista]
  - Planning Mode es algo de la interfaz de Assistant dentro de Studio. Desde Claude Code se usa el modo plan del propio Claude Code junto con las herramientas del MCP. [NO VERIFICADO que exista otra vía oculta]
  - Con tu propia API key (BYOK: Anthropic, OpenAI, Gemini) puedes elegir el modelo **dentro** de Assistant: "⋯ → Manage API Keys". [OFICIAL] assistant/mcp

## 2. Script Sync

- **Estado: estable (lanzamiento completo).** [OFICIAL] devforum.roblox.com/t/full-release-studio-script-sync/4688454 (staff "Roblox Staff", 2026-06-17):
  > "Following our beta, Studio Script Sync is now fully released!"
  La página oficial `scripting/sync` ya no menciona la palabra beta. Se usa así: clic derecho en una carpeta → **Sync to…**
- **Límites:** hasta 10.000 scripts por instancia raíz sincronizada y 128 instancias raíz. Solo sincroniza Script, LocalScript, ModuleScript y Folder. **No** sincroniza atributos ni tags; Roblox dice que no sincronices scripts que los tengan, porque puedes perder datos. Funciona con Team Create. [OFICIAL] create.roblox.com/docs/en-us/scripting/sync
- **¿Convive con Rojo?** Roblox los presenta como **alternativas**, no como algo para usar a la vez:
  > "If you want to check your entire project (not just code) into version control or use your file system as the source of truth ... Rojo are a better choice." [OFICIAL] scripting/sync
  > "we think Rojo is great and have no plans to replace it or make it obsolete." [OFICIAL] devforum.roblox.com/t/4065468 (staff, 2025-11-12)
  - No encontré una regla oficial sobre usar los dos **en la misma carpeta**. Lo prudente es que cada script tenga un solo escritor (Rojo **o** Script Sync). [TERCERO/NO VERIFICADO]
- **¿Se puede publicar un juego hecho con Script Sync?** Sí. Es una herramienta del editor y los scripts quedan como Script normales dentro del place. Además ya no es beta, así que no aplica ninguna restricción de "beta no publicable". [NO VERIFICADO con una cita directa; es una deducción de la doc oficial]

## 3. Música y audio con IA (juegos y UGC)

- **Regla general para subir audio** [OFICIAL] create.roblox.com/docs/en-us/audio/assets:
  > "You have the legal rights to that audio asset."
  Además: formato .mp3, .ogg, .wav o .flac; menos de **20 MB** y **7 minutos**; 48 kHz como máximo; mono o estéreo (también 3.0 o 5.1).
- **Límite de subida:** **2.000 audios cada 30 días** con ID verificado y **100 cada 30 días** sin verificar. El límite diario se reemplazó por este límite mensual. [OFICIAL] audio/assets
- **Audio Upload License Agreement** (Help Center, actualizado 2026-10-19): garantizas que tienes **todas** las licencias, incluidas las de interpretación pública, y que Roblox no paga regalías. Aceptas indemnizar a Roblox. [OFICIAL] en.help.roblox.com/hc/en-us/articles/23359485439124
- **Audio hecho con IA:** **no encontré ninguna regla oficial específica** (ni permiso ni prohibición) en audio/assets, en el acuerdo de audio, en generative-AI ni en marketplace-policy. [OFICIAL: no se menciona]
  - En la práctica, la música de IA se trata como cualquier otro audio: debes tener los derechos. Eso depende de la licencia de la herramienta de IA (por ejemplo, plan de pago con uso comercial) y debe pasar la moderación y la revisión de copyright. [NO VERIFICADO: deducción]
- **IA dentro del juego** (chatbots, voz, imágenes generadas en vivo): hay que declararla en el cuestionario de madurez y mostrar un aviso visible, por ejemplo: "This is an AI-powered conversation…". Si usas herramientas de terceros: "You are responsible for the content delivered to users, even if it is AI-generated." [OFICIAL] create.roblox.com/docs/en-us/generative-AI
- **Canciones en la página del juego** (desde 2026-07-27): requieren pasar la revisión de copyright, un título con sentido, que quien la sube tenga **ID verificado** y que haya aceptado los términos de audio. [OFICIAL] audio/assets y devforum.roblox.com/t/4760221 (staff)
- **UGC (ítems de avatar):** la regla es "you must ensure that you have the right to upload the asset". Están prohibidos los ítems demasiado parecidos a otros. **No hay una regla específica sobre IA.** [OFICIAL] create.roblox.com/docs/en-us/marketplace/marketplace-policy
  - El 2026-08-19 Roblox **retiró ítems 3D duplicados** (malla, textura o animación copiadas) y endureció los controles. [OFICIAL] devforum.roblox.com/t/4820200 (categoría Announcements)
  - Desde el 2026-07-14, subir un ítem 2D o 3D cuesta 80 Robux. [OFICIAL] devforum.roblox.com/t/4722717 (categoría Announcements)
  - Los ítems de avatar no llevan audio. [NO VERIFICADO: no encontré texto oficial que lo diga]

## 4. Límites de publicación y público menor de 16

- **Tope diario:** [OFICIAL] create.roblox.com/docs/en-us/production/publishing/publish-games-and-places
  > "You can release up to 5 games per day that have never been released before."
  Revocar el acceso público y volver a publicar **no** cuenta para el tope.
- **Juegos casi idénticos:** no están prohibidos, pero salen perjudicados en recomendaciones y búsqueda. [OFICIAL] create.roblox.com/docs/en-us/discovery
  > "Games with metadata and place files that closely resemble existing games on Roblox are no longer prioritized for recommendations and might rank lower in search results."
- **Requisitos para cualquier publicación** (también al actualizar):
  > "Release requirements apply to **all** release actions" (incluye "releasing a new version of a place") [OFICIAL] publish-games-and-places
  - **Para llegar a 16+:** cuenta en buen estado con al menos 2 días de antigüedad, control de edad (estimación facial o documento) y responder la primera pregunta del cuestionario. Si respondes "No", el juego recibe la etiqueta "Content May Vary" y **solo** lo ven usuarios de 16+ con edad comprobada.
  - **Para llegar a menores de 16 (todas las edades, Kids y Select):** todo lo anterior y además:
    1. Verificación de edad: estimación facial si eres menor de 18, o documento de identidad si tienes 18 o más.
    2. 2FA activada.
    3. Tener Roblox Plus o Premium 2 meses seguidos, **o** pagar la tarifa reembolsable de **1.000 Robux** por juego.
    4. Pasar la evaluación de Kids y Select.
    5. Completar el cuestionario entero con resultado Minimal, Mild o Moderate (9+).
    [OFICIAL] publish-games-and-places
  - **Reembolso de la tarifa:** "If your game maintains 25 highly engaged players for 60 days without moderation, you will receive a refund". [OFICIAL] misma página. Confirma una de las dos versiones que `research/03` veía en conflicto; la otra versión (90 días) no la revisé.

## 5. Open Cloud: permisos (scopes) y API keys

- **Publicar un place** (`POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions`, marcado **[BETA]** en la referencia):
  - En el panel: **Access Permissions → `universe-places`** con la operación **Write** sobre tu juego. [OFICIAL] create.roblox.com/docs/en-us/cloud/guides/usage-place-publishing
  - Nombre técnico del scope: **`universe-places:write`**. [OFICIAL] create.roblox.com/docs/en-us/reference/cloud/universes-api/v1
  - No confundir con `universe.place:write`, que sirve para **editar los datos** del place (PATCH v2), no para publicar. [OFICIAL] cloud/reference/features/places
- **Luau Execution** (todos los endpoints marcados **[STABLE]**): [OFICIAL] create.roblox.com/docs/en-us/cloud/reference/features/luau-execution
  - Crear tareas y subir entradas binarias: **`universe.place.luau-execution-session:write`**.
  - Leer tareas y logs: `universe.place.luau-execution-session:read` (o `:write`).
- **Dónde se crean las keys:** Creator Dashboard → **API Keys** (create.roblox.com/dashboard/credentials?activeTab=ApiKeysTab) → **Create API Key** → elegir la API en "Select API System". Puedes limitar las IP con CIDR y poner fecha de caducidad. [OFICIAL] create.roblox.com/docs/en-us/cloud/auth/api-keys
  > "If you or your group don't use or update an API key for 60 days, it automatically expires"
  Esto importa para el CI: una key que no se usa durante 60 días deja de funcionar.

## Fuentes (todas leídas el 2026-10-20)
- create.roblox.com/docs/en-us/: assistant/guide, assistant/mcp, studio/mcp, scripting/sync, ai/coding-harness, audio/assets, generative-AI, marketplace/marketplace-policy, production/publishing/publish-games-and-places, discovery, cloud/guides/usage-place-publishing, reference/cloud/universes-api/v1, cloud/reference/features/places, cloud/reference/features/luau-execution, cloud/auth/api-keys
- DevForum (staff o categoría Announcements): /t/4580715, /t/4690993, /t/4688454, /t/4065468, /t/4760221, /t/4820200, /t/4722717
- Help Center: Audio Upload License Agreement (/articles/23359485439124)
