```text
Claude Code: termina Fish & Fortune para un lanzamiento privado de prueba y prepara una revisión de lanzamiento. Trabaja dentro de ROBLOX/ y según CLAUDE.md y las tareas numeradas existentes. No cambies arquitectura ni publiques la experiencia sin autorización explícita de Aryan. Primero inspecciona el estado real del repo, ramas, tareas, IDs y código; no des por hecho que el resumen sigue al día. No inventes IDs, cifras, APIs ni resultados de pruebas.

## Prioridades
1. **Bloqueos de lanzamiento:** identifica qué significa “publicar para amigos” en la configuración actual y verifica acceso, propiedad y estado de la experiencia. Comprueba el flujo de guardado con una experiencia de prueba separada; nunca conectes Studio a datos de producción. Prueba salir/volver, errores de DataStore, reintentos, límites, migración y recuperación sin duplicar moneda ni progreso.
2. **Bucle principal:** completa una captura de principio a fin y verifica éxito, fallo, cancelación, venta, bestiario, peso/registro, etiqueta de nuevo y estado tras reconectar. Comprueba que cada zona se desbloquee y funcione como se describe.
3. **Dispositivos y accesibilidad:** revisa móvil táctil, mando y distintas relaciones de pantalla con simuladores de Studio; prueba entrada, minijuego, menús, safe areas, texto y navegación. Registra lo que requiera dispositivo real, sin fingir que se probó.
4. **Producto y mundo:** completa la playa de Golden Coast o deja claro qué falta y si bloquea la prueba; verifica colisiones, rutas, puntos de pesca, orientación y rendimiento. Añade el tour de recompensas al entrar solo si existe una necesidad clara y puede hacerse sin tapar el juego ni retrasar el bucle de pesca. Mejora onboarding para explicar lanzar, minijuego, vender y progresar.
5. **Interfaz y arte:** revisa legibilidad, jerarquía y solapamientos en HUD, placas de evento, chat, botones y paneles a resoluciones pequeñas. Mantén estilo coherente y evita tapar la zona de juego. Confirma que los botones indiquen estado, tengan feedback y funcionen con teclado, táctil y mando.
6. **Audio:** escucha en Studio cada sonido del bucle y verifica volumen, repetición, mezcla, permisos y que haya controles de volumen/sonido si corresponde. “Registrado” no equivale a probado.
7. **Equilibrio y retención:** mide con sesiones reproducibles cuánto tarda el jugador en completar acciones y progresar; revisa tasas de captura, venta, capacidad, precios y progresión con datos reales del código y pruebas. No ajustes por intuición ni inventes objetivos. Revisa recompensas diarias, racha, códigos y temporada para que sean comprensibles, persistentes, no explotables y no creen presión engañosa. Instrumenta únicamente eventos útiles y minimizados; documenta qué métricas faltan antes de afirmar retención.
8. **Monetización honesta:** audita pases/productos e IDs existentes. No actives IDs no verificados ni vendas ventajas de suerte, resultados aleatorios pagados o moneda que permita comprarlos. Las compras deben explicar contenido y precio sin urgencia falsa; verifica propiedad de pases y un único `ProcessReceipt` idempotente para productos, con pruebas de recibos repetidos, fallidos y reintentos. Si aparece cualquier azar directa o indirectamente pagado, detén esa oferta y revisa odds, elegibilidad y `PolicyService` antes de continuar.
9. **Seguridad:** audita remotos y prompts: autoridad del servidor, validación de argumentos/instancias/estado, límites de frecuencia y protección contra duplicar capturas, ventas, códigos, recompensas y recibos. Revisa guardado concurrente y datos inválidos. Marca `REVIEW(money)` en cambios de economía/datos según CLAUDE.md.
10. **Preparación de publicación:** verifica descripción, icono, miniaturas EN/ES, clasificación y cuestionario de madurez, permisos, privacidad y configuración de monetización. Comprueba que experiencia y anuncios representen el juego real; no gastes Robux ni envíes/publicas nada. El formulario W-9 es asunto de Aryan y sus obligaciones fiscales: no recopiles SSN, documentos ni credenciales en el repo/chat; indica que lo gestione en el canal oficial adecuado.

## Crítica de la captura
Se entiende de inmediato que es un juego de pesca: colores vivos, lago atractivo, personaje, muelle y controles principales visibles; los iconos tienen personalidad y el estilo cálido de madera ayuda a distinguir paneles. Pero la vista está muy cargada: el chat ocupa y tapa parte de la escena, el pez gigante y la boya compiten con el punto de pesca, y los elementos laterales y botones derechos amontonan información. El texto “PRESS CAST…” y los botones inferiores llaman la atención, aunque varios rótulos pequeños y fondos brillantes pueden perder legibilidad. Revisa la captura en móvil: conserva espacio visual central, reduce solapamientos y comprueba contraste y tamaño de texto; no rediseñes por gusto si las pruebas no muestran un problema.

## Datos/decisiones imprescindibles de Aryan
Pídele en un solo mensaje solo lo que falte tras inspeccionar repo y Creator Hub:
- Confirmación de cuál experiencia/universo y cuenta o grupo son los propietarios; nunca pedir contraseña, cookie, clave API ni datos fiscales.
- Decisión explícita sobre audiencia/privacidad del lanzamiento de prueba y autorización final para publicar; hasta entonces deja lista la revisión sin publicar.
- IDs y estado real de pases/productos que Aryan quiera ofrecer, junto con sus precios/contenidos aprobados; si no existen, dejar monetización desactivada.
- Dispositivo real disponible para una prueba manual y quién puede probar con Aryan, si los simuladores no bastan.
No bloquees tareas independientes esperando respuesta; documenta dependencias.

## Criterios de terminado
- Cada punto anterior queda “hecho”, “bloqueado” o “no aplica”, con evidencia concreta y responsable; no declares completado lo que no se ejecutó.
- Ciclo de pesca completo probado en Studio; persistencia real comprobada en universo de prueba separado; errores/reintentos y duplicados tratados.
- Revisión de controles y disposición visual en simuladores de móvil y mando, con limitaciones reales explícitas.
- Revisión de seguridad, monetización, clasificación y contenido documentada; sin IDs inventados, compras no verificadas ni secretos.
- Ejecuta, desde Git Bash y si el entorno lo permite: `bash ROBLOX/tools/test.sh`, `bash ROBLOX/tools/lint.sh` y `bash ROBLOX/tools/format.sh --check`. Informa salida real y omite cualquier afirmación de éxito si no se ejecutó.
- Entrega a Claude una lista breve de cambios/archivos, pruebas y resultados, bloqueos, riesgos y decisiones pendientes de Aryan. No publiques.

## Roblox: políticas y riesgos que verificar
Consulta documentación oficial vigente antes de decisiones de cumplimiento. Roblox exige transparencia en monetización y puede restringir azar pagado por usuario/región; la política cubre también moneda comprada con Robux y modificadores de probabilidad. No monetices suerte ni azar pagado sin revisión explícita de elegibilidad, divulgación y alternativas aplicables. No uses temporizadores, descuentos o escasez engañosos. Para DataStores, usa una experiencia separada de pruebas: habilitar acceso de Studio en una experiencia real puede tocar los mismos datos que clientes en vivo. Revisa cuestionario de madurez, elegibilidad de publicación, normas de comunidad, anuncios y permisos antes de lanzar. Fuentes oficiales para comprobar al momento de actuar:
- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/production/monetization
- https://create.roblox.com/docs/cloud-services/data-stores
- https://create.roblox.com/docs/studio/testing-modes
- https://create.roblox.com/docs/production/promotion/ads-manager

## División del trabajo con coste bajo
- **Claude:** dueño del plan y del resultado; inspecciona repo y CLAUDE.md, ordena bloqueos, integra cambios acotados, mantiene una sola rama autorizada y prepara revisión humana.
- **Codex:** solo tareas concretas de revisión/fix dentro de `ROBLOX/docs/ai-tasks/NNN-*.md`; entrega evidencia y diff para revisión de Claude. No cambies archivos fuera del alcance.
- **Ayudantes baratos:** asigna como máximo una tarea independiente de lectura (p. ej., inventario de riesgos o checklist visual); pedir hallazgos con rutas y evidencia, sin editar ni repetir contexto. No delegues pruebas duplicadas.
- Agrupa inspección de archivos y usa primero pruebas dirigidas a archivos tocados; ejecuta los tres comandos requeridos al cierre si es posible. No añadas tests nuevos salvo que la tarea lo pida. No publiques, compres anuncios ni hagas cambios irreversibles.
```