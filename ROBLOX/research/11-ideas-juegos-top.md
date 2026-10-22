# 11 - Ideas copiables de los juegos top (22-oct-2026)

Etiquetas: [OFICIAL] = API publica de Roblox consultada desde este PC el 2026-10-22; [TERCERO] = guia o wiki de fans (puede estar desactualizada); [NO VERIFICADO] = deduccion mia o dato de una sola fuente dudosa.
No vi gameplay en video: lo de "juice" (sonido, VFX) es diseno general, no observado [NO VERIFICADO]. Solo investigacion, sin tocar codigo.

## 1. Datos duros del mercado [OFICIAL]
Fuente: `apis.roblox.com/search-api/omni-search`, `games.roblox.com/v1/games`, `game-passes/v1/universes/{id}/game-passes` (22-oct-2026).

| Juego | Jugando | Creado | Pases (R$) |
|---|---:|---|---|
| Fish It! (Fish Atelier) | 70.681 | 2024-10 | VIP 445 (resto en doc 10) |
| Fisch (Fisching) | 56.841 | 2024-03 | Enchant Anywhere 239, Double XP 239, Sell Anywhere 399, Supporter 169, Spawn Boat Anywhere 299, Appraise Anywhere 499, Appraisers Luck 299, Emote Pack 99, Bobber Pack 99, Aquarium Boat y Radio (sin precio) |
| Deep Fishing (LazyGames) | 9.707 | **2026-07-18** | Ultra Lucky 599, Double Coins 399, Super Lucky 249, Auto Sell 149, VIP 249, More Mutations 349, Fish Magnet 99, Lucky 99, Double XP 249, Extra Pet Equip |
| Go Fishing | 230 | 2024-11 | Speed Boat 399, Super Yacht 799, Military Ship 1399, x2 Cash 799, x2 Exp 599, Sell Everywhere 149, Big Backpack 299, x2 Luck 199, x2 Speed 249 |

Lectura: Deep Fishing nacio hace 3 meses y ya tiene casi 10 mil jugadores con un bucle incremental simple [OFICIAL]. Go Fishing esta casi muerto aunque vende muchos barcos: los barcos solos no retienen [NO VERIFICADO].
"Vender desde cualquier lado" existe en 3 juegos, de 149 a 399 R$. Descripciones: Fisch "400,000+ variaciones" por pez; Fish It "1,000,000+" [OFICIAL, descripcion del juego].
Fish It! (Halloween): +15 peces, Secrets nuevos, battlepass limitado y gacha, caja de skins con 5 canas animadas, jefes, invasion alien, mascota pixel [OFICIAL, descripcion 22-oct]. Go Fishing: 5 canas LIMITADAS de Navidad y codigo nuevo al llegar a 250K likes [OFICIAL, descripcion].

## 2. Tabla de ideas

Ajuste = como encaja con lo nuestro (3 zonas lago/rio/costa, 5 canas, 25 criaturas de 6 rarezas, bestiario con premios, temporada de 10 niveles, codigos, 2 eventos semanales, perlas, auto-pesca, offline).

| # | Idea | Fuente | Que hace | Por que funciona | Esf. | Ajuste con lo nuestro |
|---|---|---|---|---|---|---|
| 1 | Etiqueta de update en el nombre | Los 4 juegos: [UPD] con emoji [OFICIAL] | Prefijo con emoji y "UPD" en el titulo | Senal de "vivo" en lista y busqueda | S | Cambiar el nombre en cada evento; costo 0 |
| 2 | Revelado con "1 en N" | Iconos top con "1 in 9,342,584" (GDD sec. 4) | Banner al pescar: nombre, rareza, color, peso y probabilidad | Cada pez raro es un momento compartible | S | Ya hay panel Probabilidades; mostrar la del pez. Feedback.luau |
| 3 | Peso por pez | Fisch (kg en canas) [TERCERO] | Cada pez sale con peso aleatorio; mas peso, mas precio | Misma especie = capturas distintas; "mi mejor pez" | S | Campo `weight`; precio = base x peso; record en bestiario |
| 4 | Vender desde cualquier lado | Fisch 399, Go Fishing 149 [OFICIAL] | Pase que abre Vender lejos del puesto | Comodidad pura, sin ventaja injusta | S | Quitar la condicion de zona en SellButton; pase 249-299 |
| 5 | Auto-venta | Deep Fishing 149 [OFICIAL] | Vende solo al llenar la mochila | Completa la auto-pesca; la mochila no bloquea | S | Pase aparte de Auto-pesca (299) |
| 6 | Racha diaria | Dev anecdotico: login diario triplico D7 [TERCERO, no benchmark] | 7 dias de premios crecientes; perlas el dia 7 | Motivo para volver cada dia | S | Datos + 1 pantalla; premios en monedas, perlas, boost 15 min |
| 7 | Codigos por hito de likes | Go Fishing, codigo a 250K likes [OFICIAL] | Anunciar meta de likes y soltar codigo | Sube el % de likes sin presion | S | Ya hay codigos; solo anunciar metas |
| 8 | Cana desbloqueada por bestiario | Fisch: Trident exige bestiario completo, Destiny 70% [TERCERO] | Canas finales piden % de coleccion mas monedas | Une coleccion y progreso; meta larga | S-M | 4a y 5a cana piden X% de bestiario; sin Robux |
| 9 | Pack de bobbers / emotes 99 | Fisch Bobber Pack 99, Emote Pack 99 [OFICIAL] | Cosmetico barato y visible | Compra impulsiva baja; cero ventaja | S-M | Boya por codigo (Cosmetics.luau ya existe) |
| 10 | Skins de cana | Fish It: caja con 5 canas animadas [OFICIAL] | Skins cosmeticos en cada update | Lo que mas venden los lideres (GDD) | M | Skins a precio fijo, no caja al azar (menos riesgo de politica) |
| 11 | Mutaciones | Fisch 100+ [TERCERO nov-2025]; Fish It hasta Galaxy 6,5x [TERCERO jul-2026] | Variante aleatoria que multiplica el precio | Cada pez puede ser premio gordo | M | Campo `mutation` en Balance; listar en Probabilidades |
| 12 | Clima y hora con suerte | Fish It Stormhunter +80% luz en lluvia, Stargazer noche, Aurora [TERCERO] | Lluvia, noche y aurora cambian peces y suerte, gratis | Razon para volver a cierta hora; barato de ver | M | Sumar a Marea Dorada y Luna Mitica; cielo ya es codigo |
| 13 | Encantamientos | Fisch 21, reliquia 1/300 al pescar [TERCERO]; Fish It piedra gratis o 29 R$ [TERCERO] | Mejora aleatoria de cana, obtenible gratis | Sumidero de monedas y meta infinita | L | Perla = piedra; stats pequenos; cuidado con azar de pago |
| 14 | Cana limitada por temporada | Go Fishing 5 limitadas; Fish It battlepass limitado [OFICIAL] | Cana o skin solo en esa temporada | Urgencia honesta y razon de contenido | M | Premio final de la temporada = skin unica |
| 15 | Alcance por cana (anillos) | Deep Fishing: tirar mas lejos, peces mas hondos [TERCERO oct-2026] | La cana define a que anillo llegas | Las mejoras se sienten | M | Anillos dentro de cada zona; stats de cana en Balance |
| 16 | Minijuego tactil / asistido | Fish It "clic rapido" vs Fisch barra azul [OFICIAL] | Modo de toque simple para movil | Menos abandono en telefono | M | Minijuego de 4,2 s; anadir movimiento reducido (pendiente) |
| 17 | Tocar para acelerar la picada | Fisch "shake" [OFICIAL descripcion] | Tocar durante la espera la acorta | Quita el aburrimiento de esperar | S | Espera ya existe; tocar reduce 10-20% |
| 18 | Barcos / acuario | Fisch Aquarium y Spawn Boat; Go Fishing 399-1399 [OFICIAL] | Barco como viaje, vitrina y estatus | Social; Fisch lo vende | L | Costa Dorada tiene barco; empezar como skin o atajo |
| 19 | Mascota ayudante | Deep Fishing Extra Pet; Fish It huevo pixel [OFICIAL] | Mascota con bono pequeno | Capa extra de coleccion | L | v2; riesgo de azar de pago |
| 20 | Luck de pago | Deep Fishing 99/249/599; Go Fishing x2 Luck 199 [OFICIAL] | Sube la suerte | Vende mucho | - | NO: GDD lo apaga en v1; usar boost de monedas |

## 3. Top 8 para construir (del mas barato al mas caro)

1. **#1 Etiqueta de update** (S, 0 codigo): cada evento semanal cambia el titulo.
2. **#2 Revelado con "1 en N"** (S): banner grande en raros; es lo que se comparte.
3. **#4 Vender desde cualquier lado 299** (S) y **#5 auto-venta 149**: comodidad pura, la venden los lideres.
4. **#6 Racha diaria** (S): 7 dias, premio gordo el dia 7; se mide con el embudo ya instalado.
5. **#3 Peso por pez** (S): misma especie, valores distintos; "mi pez mas grande".
6. **#8 Cana por bestiario** (S-M): une coleccion y progreso; gratis para el jugador.
7. **#9 Bobbers 99 y #10 skins de cana 399** (S-M): propuesta v1.1 del GDD, precio fijo.
8. **#11 Mutaciones y #12 clima** (M): la capa que da razon a los eventos; mostrar en Probabilidades.

Despues: encantamientos (#13), barcos (#18), mascotas (#19).

## 4. Notas honestas
- Precios de 99 a 499 R$ en comodidad y cosmeticos son lo comun entre lideres [OFICIAL]. El azar de pago (luck) vende pero sube el riesgo de politica [NO VERIFICADO; revisar `research/03`]. Mantenerlo apagado.
- Roblox dice que su descubrimiento premia retencion, juego en grupo y gasto [OFICIAL, about.roblox.com/newsroom/2026/06]. El dato de "D7 x3" viene de un blog de un solo dev [TERCERO]: tratar como hipotesis y medir.
- Deep Fishing llega a ~10K CCU en 3 meses con tirar, vender y mejorar: la simplicidad se copia mas rapido que el sistema de Fisch [NO VERIFICADO como causa].
- Falta ver video real (sonido de picada, orden del revelado, temblor de camara). Usar `/watch` con un reel de Fisch o Fish It si se quiere.

Fuentes: apis.roblox.com y games.roblox.com (22-oct-2026); deltiasgaming.com y sportskeeda.com y destructoid.com (Fisch); bo3.gg, ofzenandcomputing.com, sportskeeda.com (Fish It, jul-2026); allthings.how (Deep Fishing, oct-2026); playnews.gg (Steal a Brainrot, jul-2026, una sola fuente); rowatcher.com y about.roblox.com/newsroom/2026/06.
