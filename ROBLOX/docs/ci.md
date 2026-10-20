# Comprobación automática en GitHub (CI)

Fecha: 2026-10-20. Para alguien que no programa. Idioma: español.

**Qué es, en una frase:** cada vez que subes cambios al repositorio, GitHub abre una máquina Linux **limpia** (sin nada instalado
de antes), instala las mismas herramientas que usamos nosotros, y corre las pruebas, el linter, el formato y la construcción del
juego. Si todo sale verde, el proyecto funciona también fuera de nuestros ordenadores; si algo sale rojo, te avisa.

**Por qué sirve:** hasta ahora el proyecto solo se probaba en la nube de Claude y en tu PC. Una máquina limpia detecta lo que
"solo funcionaba en mi equipo" (una herramienta que faltaba, una versión distinta, un archivo que no se subió).

El archivo que lo define es `.github/workflows/ci.yml` (en la raíz del repositorio, porque GitHub solo lo lee de ahí).

## Qué comprueba

Hay dos trabajos independientes (se ven como dos filas en GitHub):

**1. "Luau (pruebas, lint, formato, build)"** (para Fish & Fortune y los paquetes compartidos)

| Paso | Qué hace | Comando equivalente en local |
|---|---|---|
| Instalar Rokit | Baja Rokit 1.2.0 (el gestor de herramientas) y comprueba su huella SHA-256 | (ver `docs/setup-en-tu-pc.md`) |
| Instalar herramientas | `rokit install` lee `ROBLOX/rokit.toml` e instala rojo 7.7.1, stylua 2.6.0, selene 0.31.0, lune 0.11.0 y luau-lsp 1.70.1 | `bash ROBLOX/tools/setup.sh` |
| Preparar tipos para luau-lsp | `lune setup` (tipos de Lune) y baja `globalTypes.d.luau` (tipos de Roblox) comprobando su huella | lo hace `setup.sh` |
| Pruebas (Lune) | Corre todas las `*.spec.luau` (al 2026-10-20: 481 pruebas OK en la validación local; el total crece cuando se añaden pruebas) y 2 omitidas a propósito. Las pruebas de estructura (`ProjectStructure.spec.luau`, si existen) construyen el lugar con rojo y en CI exigen que rojo esté disponible (`ARYAN_REQUIRE_ROJO=1`) en vez de omitirse | `bash ROBLOX/tools/test.sh` |
| Lint | selene (reglas de calidad), stylua (formato) y luau-lsp (tipos). Falla si la comprobación de tipos no llega a ejecutarse | `bash ROBLOX/tools/lint.sh` |
| Formato | `stylua --check`: ningún archivo sin formatear | `bash ROBLOX/tools/format.sh --check` |
| Construir Fish and Fortune | `rojo build` genera el `.rbxl` | `ROBLOX/.toolchain/bin/rojo build ROBLOX/games/fish-and-fortune/default.project.json -o fish-and-fortune.rbxl` |
| Guardar el .rbxl | Lo deja descargable 7 días (sirve para abrirlo en Studio sin montar Rojo) | — |

**2. "clothing-gen (pruebas de Python)"** (generador de ropa): crea un entorno virtual, instala Pillow y NumPy, corre
`verify_layout.py` (coordenadas contra las plantillas oficiales) y las pruebas de `unittest`.

**Qué NO corre a propósito:** el renderizador de vídeo (`ROBLOX/marketing/pipeline`: necesita Chromium y ffmpeg), y la "puerta previa
a publicar" (`ReleaseGate.spec.luau`, que solo se activa con `FF_RELEASE_CHECK=1` y fallaría mientras los IDs valgan 0; por eso
salen "2 omitidas").

## Cuándo se ejecuta

- En cada **push** a cualquier rama y en cada **pull request**.
- A mano: pestaña Actions > "CI" > botón **Run workflow**.
- **No** se ejecuta si el cambio toca solo `ROBLOX/research/`, `ROBLOX/marketing/`, `ROBLOX/docs/` o archivos `.md` (las pruebas no
  leen esas carpetas). Si algún día activas "protección de rama" con comprobaciones obligatorias, quita esas exclusiones de
  `ci.yml` (`paths-ignore`), o los cambios de solo documentos se quedarían esperando para siempre.
- Si subes cambios nuevos a la misma rama mientras corre una comprobación, la anterior se **cancela** (ya está obsoleta). Verás
  "Cancelled" en gris: es normal.
- Si hay un pull request abierto, cada push provoca dos ejecuciones (una por el push y otra por el PR). Es normal y barato.

## Cómo ver el resultado

1. Entra en `https://github.com/Aryanlima/Aryan-` y abre la pestaña **Actions**. (La primera vez GitHub puede pedirte que
   habilites Actions para el repositorio: es un botón verde.)
2. A la izquierda, "CI". La lista muestra cada ejecución con su mensaje de commit.
   - **Check verde** = todo bien. **X roja** = algo falló. **Círculo amarillo** = en curso. **Gris** = cancelada u omitida.
3. Haz clic en una ejecución. Verás los dos trabajos. Haz clic en uno para ver sus pasos; el que falló sale en rojo y se
   despliega con el texto del error.
4. En la página de la ejecución, la sección **Summary** muestra el resultado de las pruebas (por ejemplo
   `Tests: 481 passed, 0 failed, 2 skipped`) y abajo, en **Artifacts**, el archivo `fish-and-fortune-rbxl` (un `.zip` con el
   `.rbxl` dentro; caduca a los 7 días).
5. GitHub también suele enviarte un correo cuando una ejecución de tu rama falla.
6. Para repetir una ejecución sin cambiar nada (por ejemplo, si falló por un corte de internet): botón **Re-run jobs**.

## Si falla: pistas por paso

| Paso en rojo | Qué suele significar | Qué hacer |
|---|---|---|
| Instalar Rokit | No pudo bajar Rokit o la huella no coincide (`FAILED` en `sha256sum`) | Prueba **Re-run jobs**. Si la huella falla siempre, alguien cambió `ROKIT_VERSION` sin cambiar `ROKIT_ZIP_SHA256` en `ci.yml` (o el archivo de esa versión cambió: no debería pasar; investígalo antes de seguir) |
| Instalar herramientas | `rokit install` falló: corte de GitHub, límite de peticiones, o una versión de `ROBLOX/rokit.toml` que no existe | Lee el mensaje de `ERROR`. Si es de red o de límite, **Re-run jobs**. Si dice que no encuentra una versión, corrige `rokit.toml` |
| Preparar tipos para luau-lsp | Falló `lune setup` o la descarga de `globalTypes.d.luau`, o su huella no coincide | Re-run. Si la huella falla: se cambió `GLOBAL_TYPES_REF` sin cambiar `GLOBAL_TYPES_SHA256` |
| Pruebas (Lune) | Alguna prueba falla. Busca las líneas `FAIL` y debajo el detalle con `✗` | En local: `bash ROBLOX/tools/test.sh -v` o filtra con `-t "nombre"`. Si pasa en local y falla en GitHub, mira diferencias de versión de Lune |
| Lint | Hay tres secciones en el log: `selene`, `stylua --check` y `luau-lsp analyze`. Mira cuál muestra errores | selene: regla de calidad (el log dice archivo y línea). stylua: `bash ROBLOX/tools/format.sh` lo arregla solo. luau-lsp: error de tipos, a corregir en el código |
| Lint, mensaje "no ejecutó la comprobación de tipos" | `lint.sh` no encontró luau-lsp o los tipos de Roblox y se saltó los tipos en silencio | Mira los pasos anteriores (Instalar herramientas, Preparar tipos) |
| Formato | Hay archivos sin formatear | `bash ROBLOX/tools/format.sh`, y sube los cambios |
| Construir Fish and Fortune | `rojo build` falló (suele ser una ruta de `default.project.json` que no existe) | Mira el mensaje de rojo; en local: el comando de la tabla de arriba |
| clothing-gen > Crear entorno virtual | `pip` no pudo instalar Pillow/NumPy | Re-run. Si persiste, mira si salió una versión nueva incompatible (los requisitos solo piden "mínimo": `pillow>=10.1`, `numpy>=1.26`) |
| clothing-gen > verify_layout / unittest | Cambió el layout o un patrón dejó de ser periódico | En local: `cd ROBLOX/tools/clothing-gen && venv/bin/python verify_layout.py` y `venv/bin/python -m unittest discover -s tests -v` |

## Cómo ejecutar lo mismo en local

Desde la raíz del repositorio (necesitas el toolchain: `bash ROBLOX/tools/setup.sh` en Linux/nube, o `rokit install` dentro de
`ROBLOX/`; en el PC ver `docs/setup-en-tu-pc.md`):

```bash
bash ROBLOX/tools/test.sh
bash ROBLOX/tools/lint.sh
bash ROBLOX/tools/format.sh --check
(cd ROBLOX && rojo build games/fish-and-fortune/default.project.json -o fish-and-fortune.rbxl)   # rojo en el PATH (Rokit)
(cd ROBLOX/tools/clothing-gen && python3 -m venv venv && venv/bin/pip install -r requirements.txt \
  && venv/bin/python verify_layout.py && venv/bin/python -m unittest discover -s tests -v)
```

Los scripts `test.sh`, `lint.sh` y `format.sh` buscan los programas primero en `ROBLOX/.toolchain/bin` y después en el `PATH`; por
eso en GitHub (donde Rokit deja las herramientas en `~/.rokit/bin`, ya en el `PATH`) funcionan sin cambiar nada.

## Limitaciones (para no fiarse de más)

- **Todavía no se ha visto correr en GitHub.** Se validó con `actionlint` y reproduciendo los pasos en una máquina de la nube con
  los mismos binarios oficiales, pero la primera ejecución real puede pedir algún ajuste (sobre todo en "Instalar Rokit" e
  "Instalar herramientas", que dependen de la red de GitHub). Ver "Cómo se validó" abajo.
- **No sustituye a Roblox Studio.** Las pruebas usan simulaciones (mocks); el CI no abre Studio, no usa DataStore real ni
  confirma que el juego se vea o se juegue bien. `rojo build` solo demuestra que el proyecto se puede ensamblar.
- **Solo Linux** (Ubuntu 24.04). No detecta problemas propios de Windows (por ejemplo saltos de línea; para eso existe
  `.gitattributes`).
- **Las versiones de las herramientas están fijadas** (`rokit.toml`), así que no cambian solas. Los requisitos de Python solo piden
  versión mínima, así que una versión nueva de Pillow o NumPy podría romper el trabajo de clothing-gen un día.
- **Tipos de Roblox:** en GitHub se usa el `globalTypes.d.luau` de luau-lsp 1.70.1; el que compila `setup.sh` en la nube sale de un
  commit del 2026-10-10 (algo posterior). Si algún día el lint pasa en un sitio y falla en el otro, empieza por ahí.
- **Binarios:** `setup.sh` compila las herramientas con `cargo`; GitHub baja los binarios oficiales de cada versión. En la prueba
  local dieron el mismo resultado (481 pruebas, lint y formato OK), pero son compilaciones distintas.
- **Costo:** debería durar pocos minutos por ejecución (estimación; aún no medido en GitHub). Los repositorios públicos no gastan
  cuota; en los privados cuenta contra los minutos gratuitos del plan (consulta tu plan en GitHub).
- Es solo comprobación: **no publica nada, no despliega y no usa secretos** (solo el token automático de GitHub, de solo lectura).

## Mantenimiento

- **Subir una versión de una herramienta:** cambiar `ROBLOX/rokit.toml`, y mantener sincronizadas las constantes de
  `ROBLOX/tools/setup.sh`. Si es luau-lsp, cambiar también `GLOBAL_TYPES_REF` y `GLOBAL_TYPES_SHA256` en `ci.yml` (commit del tag
  y `sha256sum` de `scripts/globalTypes.d.luau` en ese commit).
- **Subir Rokit:** cambiar `ROKIT_VERSION` y `ROKIT_ZIP_SHA256` en `ci.yml` (huella de `rokit-X.Y.Z-linux-x86_64.zip` de la página
  de releases de `rojo-rbx/rokit`).
- **Acciones de GitHub:** están fijadas por commit completo (con la versión en un comentario), no por etiqueta, porque una
  etiqueta puede moverse. Para actualizar, busca el commit de la etiqueta nueva (`git ls-remote --tags https://github.com/actions/checkout`)
  y cambia el hash. Solo se usan acciones oficiales de GitHub (`actions/checkout`, `cache`, `setup-python`, `upload-artifact`);
  no se usa ninguna acción de terceros.
- **Por qué `ubuntu-24.04` y no `ubuntu-latest`:** `latest` cambia de versión de Ubuntu sin avisar y puede romper el CI un día
  cualquiera. Para usar `latest`, cambia `runs-on` en los dos trabajos.
- **Caché:** se guardan los binarios que baja Rokit (`~/.rokit/tool-storage`), con clave según `rokit.toml`; GitHub borra las
  cachés sin uso tras 7 días. Si sospechas de una caché mala: pestaña Actions > Caches > borrar.

## Cómo se validó (2026-10-20, sesión de nube) y qué falta

Comprobado de verdad:

- `actionlint` 1.7.12 (con `shellcheck` 0.11.0 activo para los bloques `run:`): sin avisos. También se comprobó que detecta errores
  sembrados a propósito (etiqueta de runner inválida, comillas rotas).
- Los binarios **oficiales** de los 5 programas (descargados de las páginas de releases de cada versión fijada) en un directorio
  limpio y con un `HOME` vacío: 481 pruebas OK, `lint: OK` (con los tipos de luau-lsp 1.70.1), formato OK y `rojo build` OK.
- Rokit 1.2.0 real (su huella SHA-256 coincide con la de `ci.yml`): `self-install`, el flag `--no-trust-check`, lectura de
  `rokit.toml`, creación de los accesos directos (shims) en `~/.rokit/bin` y que cada herramienta use la versión de `rokit.toml`
  desde la carpeta `ROBLOX/`. Esto se hizo con las herramientas ya colocadas en el almacén de Rokit (equivale a "caché
  restaurada"), porque la API de GitHub está bloqueada en la nube.
- Los pasos `run:` de ambos trabajos, ejecutados tal cual desde el YAML en una carpeta limpia; los fallos provocados a propósito
  (una prueba que falla; faltan los tipos de Roblox) hacen fallar el paso, como se espera.

**No se pudo comprobar hasta la primera ejecución real:** la descarga de las herramientas por `rokit install` desde la API de
GitHub (con y sin token), el guardado/restauración de la caché, el comportamiento de las acciones `checkout`, `cache`,
`setup-python` y `upload-artifact`, los tiempos reales, y Python 3.13 instalado por `setup-python` (aquí se probó con el Python 3.13
del sistema).
