# 13 - Archero 2 / Archero: mecánicas para un juego ORIGINAL en Roblox

Fecha: 2026-10-23. Solo se copian MECÁNICAS (no protegibles); nombre, personajes, arte, sonidos y textos serán propios. No usar nombres de skills, héroes ni capítulos del juego original.

Etiquetas: [OFICIAL] = API de Roblox o docs leídas directamente. [TERCERO] = blogs/guías/reseñas (varias son páginas de fans con relleno). [NO VERIFICADO] = inferencia mía o fuentes que se contradicen.
Límites: wikis de fans y progameguides/gamezebo dieron 403; no existe lista oficial de skills de Archero 2. Los números de energía y retención vienen del Archero ORIGINAL, no del 2.

## 1. Core loop

- **Control de un dedo** [TERCERO, someselectedstories]: joystick para moverse; el héroe dispara SOLO cuando está quieto y apunta solo al enemigo más cercano (auto-aim). Crea el ritmo "parar-disparar / esquivar" y la técnica "stutter step" (mover un poco entre disparos) [TERCERO, theriagames].
- **Etapa** = sala cerrada con muros/obstáculos: matar a todos -> se abre el portal -> elegir mejora -> siguiente sala. Hay salas de ángel/demonio, ruleta de recompensa y jefe al final de bloques de etapas. En el original un capítulo tiene hasta 50 etapas [TERCERO, Udonis]; en el 2 hay objetivos tipo "pasar X niveles o sobrevivir X minutos" [TERCERO].
- **Enemigos (tipos genéricos de las guías)** [TERCERO]: embestidor (rueda/salta hacia ti), tirador de proyectil recto, lanzador en abanico de 3 proyectiles, saltador errático, arquero que apunta (se esquiva de lado), torreta fija, volador que ignora muros, invocador. Regla de diseño: cada tipo se lee en 1 segundo por forma/color y su ataque avisa antes (telegraph).
- **Jefes** [TERCERO]: proyectiles pequeños densos + bolas grandes lentas (hay que moverse para sacar los pequeños de pantalla y esquivar las grandes), embestidas, invocaciones, zonas de daño en el suelo; ciclos de 2-3 ataques.
- **Capítulos**: cada uno = tema visual + enemigos nuevos + jefes; limpiar uno desbloquea el siguiente más difícil. En el 2 además se pide pasar un piso de la Torre (5 etapas, entradas que se gastan al perder) [TERCERO].
- **Energía** [TERCERO, Udonis, original]: 20 de energía, cada intento cuesta 5 (4 intentos); +1 cada 12 min (~4 h para llenar); recarga con gemas o anuncio (+5, hasta 4/día). En el 2: anuncio da 5 energía hasta 3 veces/día [TERCERO, guía de principiantes].
- Algunos jugadores reinician la partida si la primera tirada es mala [TERCERO].

## 2. Skills y talentos (dentro de la partida)

- **Subida de nivel**: al llenar la barra de XP salen 3 opciones aleatorias, eliges 1. Hay rareza (común / rara / épica / legendaria en el 2); "cientos de skills, miles de combinaciones" según App Store [TERCERO].
- **Ángeles**: 2 opciones (bono de ataque/vida máxima O curación). **Demonio**: UNA opción poderosa que cuesta vida máxima (~20% en el original; un héroe del 2 quita la penalización) [TERCERO]. **Valquiria**: da una bendición. **Ruleta inicial** de recompensa.
- Los multiplicadores se MULTIPLICAN entre sí [TERCERO, allclash]: por eso las sinergias rompen el juego y hay que poner topes.
- **Sinergias típicas**: proyectiles extra + rebote + perforar; elementos (fuego/hielo/rayo) + efecto al morir; frente + diagonales; orbes/compañeros; vida extra + escudo. Perforar choca con proyectiles que regresan (boomerang) [TERCERO].

~25 efectos genéricos (nombres propios sugeridos entre paréntesis):
1. +1 proyectil paralelo, -velocidad de ataque (Doble Tiro) [TERCERO: x0.8 vel.].
2. Abanico frontal (Abanico).
3. Disparos diagonales (Flancos).
4. Perforar, daño decrece por golpe (Atraviesa).
5. Rebote entre enemigos (Salto).
6. Rebote en muros (Eco de Muro); solo vale con perforar/dividir.
7. Proyectil teledirigido (Ojo Fijo).
8. Daño base +30% aprox. (Fuerza Bruta) [TERCERO: ~1.3x].
9. Velocidad de ataque +x% (Ráfaga).
10. Crítico: probabilidad y daño (Punto Débil).
11. Pack: vida, ataque y velocidad x1.15 (Trío) [TERCERO].
12. Quemadura, daño por tiempo (Brasa).
13. Congelar/ralentizar (Escarcha).
14. Rayo en cadena (Chispa).
15. Orbes orbitales (Satélites).
16. Compañero volador que dispara (Dron).
17. Escudo que bloquea 1 golpe por oleada (Barrera) [TERCERO].
18. Revivir una vez (Segunda Vida) [TERCERO].
19. Curar al subir de nivel o al matar (Savia).
20. Esquive o reducción de daño (Reflejos).
21. Daño extra a jefes + cura total al empezar jefe (Cazajefes) [TERCERO].
22. Explosión al morir el enemigo (Metralla).
23. Veneno que se propaga (Plaga).
24. Invulnerabilidad breve tras golpe (Gracia).
25. Más daño con menos vida (Furia Herida).
26. Imán de XP/monedas más grande (Imán).
27. Atravesar muros (solo demonio) (Fantasma).

Talentos permanentes (meta): "cartas de talento" que se sacan con oro (cada tirada cuesta más; duplicados las suben); fuerza y vitalidad se consideran las mejores [TERCERO, pocketgamer].

## 3. Meta-progresión

- **Héroes**: uno gratis; otros por fragmentos (eventos/pase), ~3000 gemas o compra directa (~US$30 los premium) [TERCERO]. Cada héroe con pasiva única.
- **Equipo**: ranuras de arma, armadura, anillos, colgante, pulsera, mascotas (original) [TERCERO, androidauthority]. Rarezas por color (verde/azul/morado/dorado...). **Fusión**: 3 piezas iguales -> siguiente rareza; **mejora** con pergamino + oro (los pergaminos caen en campaña) [TERCERO]. Sets con bonos por piezas.
- **Mascotas**: en el 2 se obtienen al azar dentro de la partida y se mejoran fuera; en el 1 son ranuras fijas con ataque propio [TERCERO].
- **Runas**: bonos pequeños de estadística según el estilo [TERCERO].
- **Modos**: Arena semanal (Bronce/Oro/Diamante/Maestro), batalla de sellos (2 intentos/día de 2 min, jefe cambia cada 7 días, temporada 28 días), invasión de monstruos de gremio, Torre [TERCERO, substack].
- **Cofres** con llave/gemas; el cromático se prioriza, el barato no conviene [TERCERO].

## 4. Monetización y retención (y qué es seguro en Roblox)

Datos [TERCERO, Udonis, original]: retención D1 58% / D7 31% / D30 13%; ~US$2.5M/mes; pase US$4.99 (30 niveles, 13 días); paquete 1ª compra US$1.99; ads SOLO recompensados (revivir, ruleta, cofre diario, energía); pop-ups de compra nunca en pleno juego. Archero 2: pase de 28 días a US$9.99 / US$29.99, tarjeta sin anuncios, paquete nuevo por capítulo, packs de novato [TERCERO]. Reseñas critican la monetización agresiva [TERCERO].

Mapa a Roblox (según 03-politicas-y-cumplimiento.md):
| Gancho | Seguro en Roblox? |
|---|---|
| Recompensa diaria, misiones diarias/semanales, rachas | Sí. |
| Pase de batalla / temporada | Sí, pero un pase promocionado NO puede dar Paid Random Items [OFICIAL 03]. Hacerlo determinista (recompensas fijas visibles). |
| Cofres / gacha pagado con Robux | Riesgo: permitido con reglas duras (mostrar probabilidades, `PolicyService` por usuario, restringido en algunos países/edades) [OFICIAL 03, sec. 2.1]. Recomendación: NO usar azar pagado en el MVP; cofres solo con monedas del juego. |
| Energía con espera | Permitido, pero fricción alta; mejor sin energía o con llaves generosas. |
| Recarga con anuncio recompensado | NO: Roblox no permite anuncios de terceros ni código de ads externos; solo sus formatos propios y `AreAdsAllowed` [OFICIAL 03, sec. 2.5]. Sustituir por misiones. |
| Revivir con Robux (developer product) | Sí (una vez por intento, precio claro). |
| Boost de oro/XP, skins de héroe, mascotas cosméticas | Sí; los cosméticos son lo más sano. |
| Demonio "paga con vida" | Sí, es mecánica, no compra. |
Evitar presión de gasto en menores (03, sec. 1 punto 6) y pay-to-win en el PvE cooperativo.

## 5. Qué hace que se sienta bien

[TERCERO + [NO VERIFICADO] criterio general de diseño; en Archero el feel viene de claridad más que de efectos pesados]
- Auto-apuntado instantáneo, proyectil visible y rápido, hit-stop de 2-4 frames, parpadeo blanco del enemigo, knockback corto.
- Números de daño flotantes (blanco normal, amarillo crítico, grandes en jefes), agrupados para no saturar.
- Shake de pantalla solo en eventos grandes (jefe, explosión), 0.1-0.2 s, desactivable.
- Explosión de botín: monedas/XP salen en arco y se atraen al jugador al limpiar la sala (sonido "tick" con pitch ascendente).
- Sonido: disparo con variación aleatoria de pitch, "pling" al subir de nivel, graves en demonio, campanas en ángel, música distinta en jefe.
- Telegraph rojo en el suelo, barra de vida grande del jefe, 3 tarjetas con animación al subir de nivel.
- Cada skill cambia el aspecto del proyectil (más balas, fuego, hielo).

## 6. Cómo lo adaptan los juegos top de Roblox (API, 2026-10-23, [OFICIAL])

La búsqueda "archero / roguelike archer" NO muestra un clon directo exitoso; el género fuerte es dungeon / survivors. Datos de games.roblox.com (jugando ahora, visitas, favoritos, máx. jugadores por servidor, votos arriba/abajo):
| Juego | Jugando | Visitas | Favs | Máx | Votos | Notas |
|---|---|---|---|---|---|---|
| Dungeon Heroes | 682 | 288.3M | 506K | 30 | 272K/10K | creado 2025-04, act. 2026-10-16 |
| Dungeon Hunters | 409 | 233.8M | 1.83M | 20 | 502K/8.5K | creado 2025-10, ~98% aprobación |
| Zombie Rush Survival | 6.088 | 141.4M | 182K | 30 | 123K/3.2K | creado 2026-05 |
| Survive The Swarm [GUILDS] | 1.769 | 16.8M | 145K | 30 | 36K/1.2K | creado 2026-08, crecimiento rápido |
| Archer[Boss] | 396 | 4.6M | 9.9K | 10 | 9.4K/1.1K | tirador contra jefes, 2026-09 |
| Bullet Heaven (tipo Vampire Survivors) | 0 | 107K | 632 | 8 | 319/167 | beta; no despegó |
| Fallen Survival | 615 | 49.2M | 289K | 100 | 47K/8K | 2022 |
Lectura [NO VERIFICADO, mía]: (a) los exitosos son co-op de 20-30 jugadores por servidor con oleadas; (b) aprobación 93-98%; (c) el roguelike "puro" en solitario (Bullet Heaven) no retuvo; (d) gremios y botín frecuente empujan retención. Una búsqueda ordena por relevancia, no por ranking: no es lista de top oficial.
Adaptaciones habituales [NO VERIFICADO]: control móvil con thumbstick + auto-ataque (sin botón de disparo); cámara fija en ángulo alto; proyectiles simulados en servidor con cosmética en cliente; lobby + servidor reservado de 1-4 jugadores (ver roblox-teleport-matchmaking); co-op con revive mutuo.

## 7. MVP propuesto (3-4 semanas, Claude + Codex)

Alcance: 1 capítulo (10 etapas, miniboss en la 5, jefe en la 10), 6 enemigos, 2 jefes, 20 skills, 1 héroe, 3 armas, móvil primero, solo (co-op 2-4 después).
Enemigos: embestidor, tirador recto, lanzador de abanico, saltador errático, torreta fija, volador.
Armas: arco rápido (poco daño), ballesta lenta (perfora), bastón mágico (teledirigido lento).

Semana 1 - núcleo
1. Cámara fija + joystick móvil + movimiento.
2. Disparo en servidor: auto-aim al más cercano, solo estando quieto; proyectiles lógicos (raycast/Heartbeat), sin una Part replicada por bala.
3. Enemigo base con IA en servidor + vida + daño al jugador.
4. Sala: arena, puertas, portal al limpiar.
Semana 2 - contenido
5. Los 6 enemigos con telegraph; spawn por tabla de sala.
6. Subida de nivel: 3 tarjetas, aplicar modificadores (tabla de stats).
7. 20 skills data-driven (un ModuleScript).
8. Sala ángel/demonio.
Semana 3 - jefes y meta
9. Jefes 1 y 2 con 3 patrones cada uno.
10. 3 armas + héroe; guardado (ProfileStore): monedas, armas, 5 talentos.
11. Tienda de talentos con monedas del juego; misión diaria; pantalla de resultado.
Semana 4 - pulido y seguridad
12. Juice: números flotantes, hit-stop, botín, sonidos propios.
13. Prueba móvil (roblox-mobile-playtest), perfilado, tope de enemigos, tutorial de 1 minuto.
14. Revisión de seguridad/exploits + telemetría básica (D1, etapa alcanzada); publicar solo con permiso.
Orden: tareas pequeñas y verificables, una por prompt a Codex, yo reviso; no pasar a la 5 sin que la 2 funcione en celular. Pruebas pocas y dirigidas.

## 8. Riesgos

- **Autoridad del servidor**: balas, daño, drops y tarjetas ofrecidas se generan y validan en servidor. El cliente solo envía dirección de movimiento y "elegí tarjeta N". Límite de frecuencia en remotes; validar NaN/tipos.
- **Rendimiento móvil**: tope ~30 enemigos y ~100 proyectiles vivos; sin Part por bala (pool o simulación lógica + VFX en cliente); animaciones simples. Medir con MicroProfiler en teléfono real.
- **Exploits**: nada de monedas/XP calculados en cliente; revivir/compras vía ProcessReceipt; guardado con sesión bloqueada; comprobar velocidad máxima y teletransporte.
- **Balance**: los multiplicadores generan runs infinitos; topes por stat (ej. velocidad de ataque x3) y vida enemiga escalada por etapa.
- **Monetización**: sin azar pagado ni anuncios; ingreso por pase determinista, cosméticos y boosts. Riesgo de ingreso bajo, aceptable para MVP.
- **Mercado**: el survivors solitario puro fracasó en la muestra; co-op y gremios mueven números [NO VERIFICADO]. Validar con prueba abierta corta.
- **IP**: no copiar nombres de skills/héroes/jefes, sprites, sonidos ni música; arte propio (usar Ropilot para diseños, con permiso antes de subir imágenes).

Fuentes [TERCERO]: someselectedstories.substack.com (Tiny Teardown Archero 2), blog.udonis.co (Archero monetization), pocketgamer.com/archero-2/guide, progameguides/allclash/highgroundgaming (tier lists, resumidas por el buscador), theriagames.com (jefes), androidauthority (equipo). [OFICIAL] games.roblox.com y apis.roblox.com/search-api.
