# GDD — Fish & Fortune (v1)

Detalle técnico en `games/fish-and-fortune/README.md`. Mercado en `research/10-ranking-real-y-cartera.md`.

## 1. Concepto
Pesca idle y de colección para jugar con amigos: lanzar, recoger con un minijuego de timing, vender y comprar mejores cañas. Las zonas nuevas desbloquean peces nuevos para completar el bestiario. Público: 9 a 16 años, sobre todo en móvil. Referencias del género: Fish It! y Fisch, con ~135 mil jugadores a la vez entre los dos (21-oct-2026).

## 2. Bucle y progresión
Lanzar → minijuego de 4,2 s → captura (la zona verde da calidad y suerte, no decide si pescas) → vender → caña o zona nueva → bestiario y temporada. Primeros 60 s: lanzar y vender una vez (verificado en Studio el 21-oct). Rarezas garantizadas en los 3 primeros lanzamientos.

## 3. Economía y monetización (honesta)
- Ahora: 5 pases (Auto-pesca 299, x2 monedas 249, Temporada 399, Inicial 99, VIP 199) y 6 productos (packs de monedas y perlas, espacio, boost de 15 min). Suerte de pago APAGADA en la v1.
- **Lo que falta frente al top** (hallado el 21-oct en las tiendas reales): los líderes venden **cosméticos** y **comodidad**:
  - Fish It!: VIP 445 con caña dorada y halo; packs de skins de caña a 399; bote a 225-999; "Sell Anywhere" a 315.
  - Fisch: emotes a 99; pack de 10 bobbers a 99.
  - Keyboard Escape: estelas y auras de 1.479 a 1.999.
- Propuesta v1.1: skins de caña (399), bobbers (99), estela o aura (799-1.499), "vender desde cualquier lado" (299) y un VIP con caña dorada y halo visible para los demás. Nada de esto da ventaja injusta.

## 4. Identidad visual (dirección de arte)
Patrón de los íconos top (21-oct, 12 juegos revisados):
- Un avatar de Roblox con **cara exagerada** (esfuerzo o sorpresa) y un **objeto héroe gigante**: el pez enorme, el huevo, el dado.
- Colores **saturados**, contorno grueso, cielo cian o fondo morado y naranja.
- **Números grandes** en el ícono ("+1", "+7M", "1 in 9,342,584").
- Versión de temporada (Halloween) en la fecha.

Para Fish & Fortune:
- **Paleta:** agua turquesa #2EC4F1, madera cálida #C98A4B, oro #FFC83D, acento coral #FF5A5F y UI azul noche #1E2A44 con texto blanco.
- **Ícono:** el avatar sujeta la caña tensa con un pez dorado gigante saltando del agua, con texto "x2" o "LEGENDARY" en dorado.
- **Mundo:** muelle de madera, lago con orilla de arena, carteles por zona, partículas de salpicadura y brillo dorado en las capturas raras.

## 5. Mapa
Zonas: Calm Lake (inicio, muelle y tienda de cañas) → Crystal River (cristales y cuevas) → Golden Coast (playa y barco). El recorrido es lineal, con un portal o cartel por zona y un punto de venta en cada una.

## 6. Pendiente de UI (playtest-1)
Banner de evento ilegible, el chat tapa el HUD de monedas y el aviso tapa el título del panel.

## 7. Criterios de aceptación de la v1
Sin errores en consola; los primeros 60 s funcionan en móvil y PC; las compras se prueban en la experiencia privada sin gastar; los datos guardan y cargan en la experiencia publicada; las probabilidades están visibles.
