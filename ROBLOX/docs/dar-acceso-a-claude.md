# Cómo darle a Claude el acceso para que lo haga todo (sin pasarle claves ni contraseñas)

Fecha: 2026-10-20. Pedido de Aryan: «busca qué se puede hacer para que tengas todos esos derechos». Esta guía junta lo que dice la documentación oficial.

**Idea central:** Claude, en la nube, hoy no puede hablar con Roblox ni con servicios de IA porque la red del entorno los bloquea y no tiene credenciales. Hay un mecanismo oficial para resolverlo sin que Claude vea nunca tu clave: los **secretos de red**. Guardas la clave una vez en el entorno; el proxy de Anthropic la añade a las peticiones que van a los sitios que tú listes, **después de salir de la sesión**. Claude ve la respuesta de la API, pero no la clave, ni en variables de entorno ni en archivos. [OFICIAL leído: [Configure cloud environments](https://code.claude.com/docs/en/cloud-environments#add-network-secrets)]

## Qué sigue siendo solo tuyo (nadie puede hacerlo por ti)

- La **verificación de identidad** de Roblox y la firma del **W-9** (formularios fiscales).
- **Pagar** la suscripción Plus o la tarifa de 1.000 Robux por juego.
- **Hacer público** el juego (con dinero real y cuestionario de madurez veraz).
- **Nunca** compartir tu contraseña ni la cookie de sesión de Roblox: automatizar con la cookie rompe las normas y arriesga la cuenta que cobra tus juegos ([09 §8](../research/09-ropa-produccion-con-ia.md)).

## Paso A: abrir la red hacia Roblox (y la IA)

1. Entra a [claude.ai/code](https://claude.ai/code), abre el menú del entorno de la sesión (barra del título) y elige **Edit**.
2. En **Network access** elige **Custom** y, en **Allowed domains**, escribe un dominio por línea. Deja marcada la casilla de gestores de paquetes.
   - `apis.roblox.com` (la API para publicar y crear pases y productos)
   - `create.roblox.com` y `devforum.roblox.com` (leer documentación oficial)
   - Más adelante, el de tu proveedor de imágenes (por ejemplo `api.openai.com`)
3. Si el cambio no se aplica de inmediato, abre una sesión nueva en ese entorno.

## Paso B: la clave de Roblox, con permisos mínimos

En [Creator Hub](https://create.roblox.com/dashboard/credentials) > **Credentials** > crea una **API key** de Open Cloud:

- **Acótala a UNA experiencia de prueba privada** (créala antes en Creator Hub; es gratis y reversible).
- Permisos, solo los necesarios: `universe-places:write` (publicar el lugar construido) [OFICIAL leído]; `game-pass:write` (crear y actualizar pases; el endpoint figura como **beta**) y `developer-product:write` (productos) [TERCERO: resumen de la referencia oficial y de herramientas de la comunidad; confirma los nombres exactos en la lista de scopes al crearla].
- No des permisos de economía general, DevEx, activos de avatar ni nada que no se use.
- Ponle **fecha de caducidad**. Las claves sin uso caducan a los 60 días [OFICIAL leído, [06 §4.3](../research/06-stack-tecnico.md)].
- Puedes revocarla cuando quieras.

## Paso C: guardarla como secreto de red (Claude no la ve)

En el mismo diálogo **Edit cloud environment**, sección **Network secrets** > **Add secret**:

| Campo | Valor |
|---|---|
| Name | `Roblox Open Cloud (prueba)` |
| Allowed websites | `apis.roblox.com` |
| Custom headers | Name: `x-api-key`, **Prefix: vacío**, Value: la clave |

Roblox pide la cabecera `x-api-key` con el valor tal cual [OFICIAL leído, [04 §6.4](../research/04-ia-studio-mcp-skills.md)]. Se guarda con el botón **Add** (no con Save changes). **No se puede ver ni editar después**: para cambiarla, bórrala y vuelve a crearla. Para comprobar que funciona, pídele a Claude que llame a la API con `curl`. [OFICIAL leído]

Para un proveedor de imágenes (OpenAI y similares) se repite el mismo paso con su host y la cabecera `Authorization` con prefijo `Bearer` (lo habitual en esas APIs; confírmalo en la documentación del proveedor).

## Qué podrá hacer Claude entonces, solo desde la nube

- Publicar el juego construido en la experiencia de **prueba privada** y actualizarlo.
- Crear los pases y productos, leer sus IDs y cablearlos en `ProductIds.luau` con la herramienta de ROBLOX/tools/wire-ids.mjs (en construcción).
- Generar imágenes con IA (íconos, miniaturas) y guardarlas en el repositorio.
- Seguir sin poder: identidad, impuestos, pagos y hacer público (ver arriba).

## Riesgos y cómo se limitan

- **Quien use el entorno puede usar la clave a través de Claude.** Por eso: permisos mínimos, una sola experiencia de prueba, caducidad y revocación inmediata. Si algún día hay duda, bórrala.
- **Texto de la web que Claude lea** podría intentar manipularlo para usar la clave: el alcance acotado es la defensa, no la confianza.
- **Gasto en IA:** usa crédito prepago y un límite mensual en la cuenta del proveedor.
- **Pases y productos con dinero real** no se activan para la venta pública sin tu confirmación.

## Alternativa o complemento: la sesión de tu PC

Tu PC ya tiene Studio con sesión iniciada y el MCP de Studio. Todo lo que no requiere la API puede hacerlo esa sesión (ver [prompt-pc-playtest-1.md](prompt-pc-playtest-1.md)). También existe el modo de «saltar permisos» de Claude Code, pero no lo recomiendo como atajo: con claves acotadas y secretos de red se logra el mismo resultado con mucho menos riesgo.
