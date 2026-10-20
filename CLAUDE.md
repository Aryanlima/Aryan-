# Aryan- — juegos de Roblox con microtransacciones

Proyecto: crear muchos juegos de Roblox monetizados con microtransacciones, usando IA para acelerar.

## Cómo trabajar aquí

- **Usar siempre ayudantes (subagentes) en paralelo** para investigar o producir cosas independientes; es más rápido y eficiente. Pedido explícito del usuario. Cada ayudante debe tener un área distinta y escribir su resultado en un archivo.
- Idioma: español (el código y los identificadores en inglés).
- **Todo lo relacionado con Roblox vive en `ROBLOX/`** (investigación, juegos, herramientas, marketing, docs). Pedido explícito del usuario: era una carpeta "ROBLOX" en su Escritorio; como la sesión corre en la nube y no alcanza su Escritorio real, esa carpeta es `ROBLOX/` en este repo y el usuario la clona o descarga a su Escritorio.
- Todo lo que se instale (binarios, toolchain) va en `ROBLOX/.toolchain/` (ignorado por git); scripts y docs usan rutas relativas, nunca `/home/user/...` absolutas.
- La investigación vive en `ROBLOX/research/`. Marcar cada dato como `[OFICIAL]`, `[TERCERO]` o `[NO VERIFICADO]` con fuente y fecha; no inventar cifras ni nombres de APIs.
- Desde la red de esta sesión `create.roblox.com`, `devforum.roblox.com` y Wikipedia están bloqueados (403). No esquivar el proxy; usar `WebSearch` y verificar lo crítico en la documentación oficial desde un equipo con acceso.
- El código de Luau de este repo no se ha probado en Roblox Studio salvo que se indique lo contrario.
