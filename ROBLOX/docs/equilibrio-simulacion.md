# Equilibrio de Fish & Fortune: simulacion de 60 min

> TODO ESTO ES SIMULADO, NO MEDIDO con jugadores reales. Salen de `ROBLOX/tools/sim-economy.luau`, que usa los
> modulos reales (Balance, FishingRules, GameLogic, Economy, Odds). Media de 20 semillas, sesion de 60 min.
> Ejecutar: `bash -c 'source ROBLOX/tools/env.sh; cd "$ROOT"; lune run tools/sim-economy'`

## Supuestos
- Casual: un intento cada 8 s, 25 % perfecto / 35 % bueno / 40 % fallo; vende cuando el inventario se llena.
- Activo: un intento cada 1,35 s, 60 % perfecto / 25 % bueno / 15 % fallo.
- Idle: pase de Auto-Pesca, intervalo de la cana (10 s a 6 s), sin bonus de calidad.
- Politica voraz: reclama bestiario, compra cana / zona (respeta `requiresDiscoveries`) y espacio con perlas en cuanto alcanza; viaja a la mejor zona.
- Sin Robux, sin boosts, sin temporada, sin diario. Minijuego simplificado: solo calidad por probabilidad, sin tiempos.

## Resultados (minutos hasta comprar)
| Perfil | Cana junco | Fibra | Carbono | Dorada | Zona rio | Zona costa |
|---|---|---|---|---|---|---|
| Casual | 1,4 | 7,3 | 17,9 | 32,9 | 11,0 | 23,6 |
| Activo | 0,2 | 0,9 | 2,2 | 4,0 | 1,3 | 2,8 |
| Idle | 1,2 | 5,4 | 12,4 | 21,8 | 8,2 | 15,9 |

| Perfil | Monedas/hora | Especies (de 25) | % Legendaria+Mitica | Inventario lleno (veces) | Mayor hueco sin comprar (min) | Espacios |
|---|---|---|---|---|---|---|
| Casual | 1,42 M | 19,9 | 1,5 % | 10 | 15,4 | 40 |
| Activo | 18,3 M | 20,6 | 1,7 % | 49 | 9,2 | 57 |
| Idle | 3,09 M | 20,5 | 1,4 % | 18 | 11,6 | 48 |

## 5 hallazgos
1. **Demasiado rapido.** Un casual compra TODO (cana dorada, 80.000) en 33 min y un activo en 4 min. La promesa de varias horas de progreso no se cumple.
2. **Punto muerto de monedas.** Tras comprar todo, las monedas no sirven para nada: el casual gana 1,4 M/h y lo mas caro cuesta 80 k; el activo gana 18 M/h (230 veces el precio maximo). Faltan sumideros.
3. **Salto de valor en la costa.** Un comun del lago vale 8-18, uno de la costa 250-350 (unas 20 veces). Al entrar a una zona el ingreso se dispara y el siguiente precio queda ridiculo. El rio (x4-5) esta mejor.
4. **Activo contra casual: 13 veces.** Con 1,35 s contra 8 s y 60 % de perfectos, el activo gana 18 M/h contra 1,4 M/h. El idle (3,1 M/h) gana el doble que el casual manual sin hacer nada: el pase de Auto-Pesca parece obligatorio.
5. **Huecos y coleccion.** Con 20 casillas el inventario se llena 49 veces en una hora al jugar activo (interrupcion constante hasta que las perlas del bestiario dan espacio). Y solo se llega a ~20 de 25 especies: las miticas (peso 1 contra ~1000 del total) casi no salen en 60 min, asi que `disc_25` y los premios por zona completa quedan para mucho despues, justo cuando ya no hay nada que comprar.

## Cambios sugeridos (sin tocar Balance.luau todavia)
Objetivo (a validar): casual con todo comprado hacia 2-3 h, activo hacia 45-60 min.
- Precios de cana: fibra 1500 a 6000, carbono 12000 a 90000, dorada 80000 a 800000 (reed se queda en 120: el primer minuto esta bien).
- Zonas: rio 1500 a 8000, costa 15000 a 150000.
- Valores de la costa: comunes 250/350 a 120/170 y subir los raros (tuna 4000 a 5000) para suavizar el salto.
- `requiresDiscoveries` de la dorada: 14 a 18 (ya se alcanza con ~20 especies; fuerza a explorar el rio).
- Sumideros nuevos: cosmeticos de cana / skins de monedas (200 k - 5 M) y un prestigio, para que 18 M/h tengan destino.
- Para que el activo no se dispare: perfectLuck 1 a 0,7 o bajar `castCooldownSeconds` solo en la UI, y subir `baseSlots` 20 a 30 (menos interrupciones) compensando con `slotsPerPack` 10 a 8.
- Mitica: subir su peso de 1 a 2 en las tres zonas (o dar +1 luck por zona completada) para que la coleccion completa sea alcanzable en horas.

Despues de cambiar: repetir la simulacion y, sobre todo, medir con jugadores reales (tiempo hasta primera cana, ingresos/h, abandono en el primer hueco largo).

## Aplicado el 22-oct (simulado, no medido)
Precios: fibra 6.000, carbono 90.000, dorada 800.000 (requiere 18 especies); rio 8.000, costa 150.000. Repetida la simulacion (20 semillas, 60 min):
casual: carbono ~38 min (12 de 20 semillas), dorada ~55 min (2 de 20); activo: todo comprado hacia los 16 min; idle: carbono ~32 min.
**Sigue abierto:** el activo gana ~35 veces mas que el casual (16 M/h contra 0,46 M/h) y se queda sin que comprar a los ~16 min: faltan sumideros (cosmeticos, prestigio) y limitar la ventaja del activo. No se tocaron los valores de la costa ni `baseSlots`.
