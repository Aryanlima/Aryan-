# Entorno y toolchain Luau (sin Roblox Studio)

Roblox Studio no corre en este Linux, asi que el proyecto tiene un toolchain local para escribir,
formatear, analizar y **probar** codigo Luau sin Studio. Este documento dice que hay instalado, que no
se pudo instalar (y que host habria que permitir), como se usa y que limites tiene.

Estado verificado el 2026-10-20 en la sesion de nube (Linux x86_64, 4 hilos, cargo 1.97, cmake 3.28).

## 1. Que quedo instalado

Los binarios viven en `ROBLOX/.toolchain/bin/` (ignorado por git; ver `CLAUDE.md`). Los scripts de
`tools/` lo anaden al `PATH` solos (`tools/env.sh`).

| Herramienta | Version | Para que | Como se obtuvo |
|---|---|---|---|
| `lune` | 0.11.0 (Luau 0.740) | Ejecutar Luau y los tests | `cargo install lune --locked` (crates.io) |
| `stylua` | 2.6.0 | Formateador | `cargo install stylua --locked --features luau` |
| `selene` | 0.31.0 | Linter | `cargo install selene --locked` |
| `rojo` | 7.7.1 | Proyectos Rojo (`rojo build`, `rojo serve`) | `cargo install rojo --locked` |
| `luau-analyze` (+ `luau`, `luau-compile`) | Luau del 2026-10-10 (`8387cfb461b3`) | Comprobador de tipos Luau, REPL y compilador | Compilado desde fuente (ver 2) |
| `luau-lsp` | ver estado en 1.1 | Analizador con tipos de Roblox / servidor LSP | Compilado desde fuente (ver 2) |
| `globalTypes.d.luau` | del repo luau-lsp (2026-10-10) | Definiciones de tipos de la API de Roblox | Sale del codigo fuente de luau-lsp |

Smoke tests ejecutados (todos OK): `lune --version`, `stylua --version`, `selene --version`,
`rojo --version`; un script Luau con tipos ejecutado con `lune run`; `rojo build` de un proyecto minimo
a `.rbxlx`; `luau-analyze` sobre todo `tools/` (0 errores); y los 65 tests propios (`tools/test.sh`).

### 1.1 Estado de `luau-lsp`

ESTADO_LSP

### 1.2 Reproducir la instalacion

```bash
tools/setup.sh                 # instala lo que falte (idempotente); --check solo verifica
tools/setup.sh --skip-lsp      # omite luau-lsp (la compilacion mas lenta, ~10-15 min)
tools/setup.sh --only lune,stylua
JOBS=2 tools/setup.sh          # hilos de compilacion (por defecto nproc, maximo 4)
```

Requisitos del sistema: `cargo`, `cmake`, `curl`, `python3` y `clang++` o `g++` (`ninja` es opcional).
El primer `setup.sh` completo tarda unos 20-30 min (lune ~10 min, Luau ~3 min, luau-lsp ~10 min). Las
versiones estan fijadas al principio de `tools/setup.sh`.

Hosts de red que usa `setup.sh` (todos permitidos por la politica actual):
`index.crates.io`, `static.crates.io`, `proxy.golang.org`.

## 2. Como se consiguio cada binario (y por que no se bajaron binarios precompilados)

- **crates.io**: `lune`, `stylua`, `selene`, `rojo` se compilan con `cargo install --locked`. El indice
  (`index.crates.io`) y las descargas (`static.crates.io`) funcionan; la API `crates.io/api/...` da 403 (no se necesita).
- **Luau (`luau-analyze`)**: no hay binarios en PyPI/npm/crates que lo empaqueten (ver 3). El codigo fuente
  si es alcanzable: el **proxy de modulos de Go** (`proxy.golang.org`) es un espejo de repos de GitHub y sirve
  el zip de `github.com/luau-lang/luau` sin pasar por `github.com`
  (`https://proxy.golang.org/github.com/luau-lang/luau/@v/v0.0.0-20261010001518-8387cfb461b3.zip`).
  Se compila con cmake (`Luau.Analyze.CLI`). Es el mismo codigo que el repo oficial, pero **no se verifico su
  firma/commit** contra GitHub (el proxy de Go no sirve el checksum desde aqui: `sum.golang.org` no se uso).
- **luau-lsp**: igual, `github.com/JohnnyMorganz/luau-lsp` desde el proxy de Go. El zip no incluye submodulos,
  asi que se le copia el codigo de Luau en `./luau`. Se compila con `clang++` porque GCC 13 falla con `-Werror`
  por un falso positivo en `CallHierarchy.cpp`. Ese mismo repo trae `scripts/globalTypes.d.luau` (866 KB con
  la API de Roblox), que es lo que luau-lsp necesita para entender `game`, `Instance`, `Players`, etc.

## 3. Lo que NO se pudo (y que habria que permitir)

| Intento | Resultado | Que haria falta |
|---|---|---|
| Binarios precompilados de GitHub Releases (`github.com/.../releases`, `api.github.com`) | **403** del proxy de red | Permitir `github.com` y `api.github.com` (y `objects.githubusercontent.com`) si se quieren binarios en vez de compilar. No es imprescindible: se compila desde fuente. |
| `selene generate-roblox-std` (genera `roblox.yml` con la API completa para `std = "roblox"`) | Falla con `invalid peer certificate: UnknownIssuer`. El host `raw.githubusercontent.com` **si esta permitido** (curl responde 200 y baja el API-Dump de 7,5 MB), pero el cliente HTTP de selene (ureq con certificados raiz incluidos) **no usa** `SSL_CERT_FILE`/el CA del proxy y selene no tiene opcion para un archivo local. No se esquivo (no se desactivo TLS ni se usaron tuneles). | En una maquina sin interceptacion TLS: `selene generate-roblox-std` y cambiar `std = "roblox"` en `selene.toml`. Aqui se usa `roblox_lite.yml` (globales de Roblox como `any`). |
| npm `luau-lsp@1.0.0` | Es un lanzador de 3 KB que **descarga el binario desde GitHub** en tiempo de ejecucion (403). No sirve. | `github.com`. |
| npm `@roblox-tooling/pendant`, `lualock` | Envoltorios que tambien descargan binarios de GitHub. | `github.com`. |
| PyPI `luau-lsp` | 404 (no existe). | - |
| crates.io `luau-analyze` 0.0.1 | Marcador sin contenido util; no se uso. | - |
| `create.roblox.com`, `devforum.roblox.com` (documentacion oficial) | 403 (politica de la sesion, ver `CLAUDE.md`). | Permitirlos o verificar a mano desde un equipo con acceso. |

Alternativa de comprobacion de tipos ya encontrada por otro ayudante: `@luau-rs/luau` (npm, Luau compilado a
WebAssembly con modulo `analysis`) + `ROBLOX/scripts/typecheck.mjs`. Complementa a `luau-lsp`; las definiciones
`globalTypes.d.luau` que instala `setup.sh` (en `ROBLOX/.toolchain/share/`) sirven tambien para ese script.

## 4. Como correr lint, formato y tests

Todo desde la raiz del repo; los scripts excluyen `research/`, `.git/`, `node_modules/`, `venv/`, `.toolchain/`
y los archivos de definiciones `*.d.luau`.

```bash
tools/test.sh                       # todos los *.spec.luau (un proceso lune por archivo)
tools/test.sh tools/examples        # solo una carpeta o archivo
tools/test.sh -t "idempotente"      # solo tests cuyo nombre completo contiene el texto
tools/test.sh -v                    # salida completa tambien de los que pasan

tools/lint.sh                       # selene + stylua --check + tipos (luau-lsp o luau-analyze)
tools/lint.sh tools/testkit         # solo una ruta
tools/lint.sh --no-types            # sin comprobacion de tipos
tools/format.sh                     # reformatea con StyLua (stylua.toml: tabs, 120 columnas)
tools/format.sh --check             # solo comprueba
```

Codigos de salida: `0` todo bien, `1` hay fallos, `2` falta una herramienta o no hay specs.

Configuracion en la raiz: `.luaurc` (alias `@testkit`, alias `@lune` hacia los tipos locales de Lune; modo
`nonstrict` por defecto, los archivos nuevos de juego deben llevar `--!strict`), `selene.toml`,
`roblox_lite.yml`, `stylua.toml`, `.styluaignore`.

### Escribir un test

Un test es un archivo `nombre.spec.luau` junto al codigo. No hay que llamar a nada al final: el runner se
ejecuta solo al terminar el script y sale con codigo 1 si algo falla.

```luau
--!nonstrict
local testkit = require("@testkit")
local Mocks = require("@testkit/mocks")
local MiModulo = require("./MiModulo")

local describe, it, expect, beforeEach = testkit.describe, testkit.it, testkit.expect, testkit.beforeEach

describe("MiModulo", function()
	local env
	beforeEach(function()
		env = Mocks.new() -- entorno fresco: clock, Players, DataStoreService, MarketplaceService, RunService...
	end)

	it("guarda datos", function()
		local store = env.DataStoreService:GetDataStore("PlayerData")
		store:SetAsync("k", { coins = 1 })
		expect(store:GetAsync("k")).toEqual({ coins = 1 })
	end)
end)
```

API del runner (`tools/testkit/`):

- Estructura: `describe`, `it` / `test`, `describe.skip`, `it.skip`, `describe.only`, `it.only`,
  `beforeAll`, `afterAll`, `beforeEach`, `afterEach`. Los tests pueden ceder (`task.wait` real) con timeout de 5 s.
- `expect(x)`: `toBe`, `toEqual` (profundo, con comodines `expect.any("number")` y `expect.anything()`),
  `toBeNil`, `toBeTruthy`, `toBeFalsy`, `toBeGreaterThan(OrEqual)`, `toBeLessThan(OrEqual)`, `toBeCloseTo`,
  `toBeType`, `toContain`, `toHaveLength`, `toMatch` (patron de Luau), `toHaveProperty`, `toThrow(texto|predicado)`,
  `toHaveBeenCalled`, `toHaveBeenCalledTimes`, `toHaveBeenCalledWith`. Negacion con `.never`
  (`expect(x).never.toBe(y)`; `not` es palabra reservada en Luau). Se admite `expect(x).toBe(y)` y `expect(x):toBe(y)`.
- Espias: `testkit.fn(impl?)` -> `.callCount`, `.calls`, `.results`, `:mockReturn(...)`, `:reset()`.
- Runner aislado (para tests del propio testkit): `testkit.createRunner()`.
- Filtro por nombre: `TESTKIT_FILTER=texto` (lo que usa `tools/test.sh -t`).

### Mocks de servicios de Roblox (`tools/testkit/mocks/`)

Se crean con `Mocks.new(opciones)` y se **inyectan** en la logica bajo prueba (recomendado:
`Modulo.new({ dataStoreService = env.DataStoreService, players = env.Players, enum = env.Enum })`). Para codigo
que usa los globales de Roblox directamente: `env:installGlobals()` expone `Enum` y `game` (y `task` con
`installGlobals(true)`); `env.restoreGlobals()` los quita. `game:GetService(nombre)` devuelve los mocks.

| Mock | Que ofrece |
|---|---|
| `Clock` (`env.clock`, `env.task`) | Reloj simulado: `clock.task.wait/spawn/defer/delay/cancel`, `clock:advance(s)`, `clock:flush()`, `clock:runAll()`, `clock:now()`, `clock.time()/tick()/osTime()`. `task.wait` dentro de un hilo gestionado cede; en el cuerpo del test **hace avanzar el reloj**. Los errores de hilos se acumulan en `clock.errors` (`clock:assertNoErrors()`). |
| `Signal` | `Connect`, `Once`, `Wait`, `Fire`, `Disconnect`; cada handler corre en su propio hilo; los errores quedan en `signal.errors`. |
| `Players` | `PlayerAdded`, `PlayerRemoving`, `AddPlayer(userId, name, props)`, `RemovePlayer`, `GetPlayers`, `GetPlayerByUserId`, `GetPlayerFromName`; `Player` con `Kick` (guarda `kicked`), atributos e hijos. |
| `RunService` | `Heartbeat`, `Stepped`, `PreSimulation`, `PostSimulation`, `RenderStepped`, `PreRender`, `Step(dt)`, `RunFor(s, dt)`, `IsServer/IsClient/IsStudio/IsRunning`. |
| `DataStoreService` | `GetDataStore`, `GetAsync`, `SetAsync`, `UpdateAsync` (devolver `nil` cancela; ceder dentro del callback es un error), `IncrementAsync`, `RemoveAsync`, `DataStoreKeyInfo`. Copias profundas, validacion de valores (NaN, funciones, arrays con huecos, 4 MiB, claves de 50 caracteres). **Fallos:** `SetOutage`, `FailNext(n, {op,key,store,message})`, `SetFailureRate(p, semilla)`, `SetLatency`, gancho `onRequest` (simular otro servidor escribiendo en medio), presupuestos por minuto opcionales (`enforceBudgets`, 60 + 40 por jugador; `UpdateAsync` gasta lectura y escritura) y cooldown de escritura opcional. **Inspeccion:** `store:_peek/_seed/_keys`, `service.log`, `GetRequestCount`. |
| `MarketplaceService` | `ProcessReceipt` y `BindReceiptHandler`; el test hace de Roblox: `SimulatePurchase`, `SimulateRedelivery(purchaseId)`, `RetryPending(userId?)`, `GetReceiptStatus`, `GetDeliveryAttempts`; si el callback lanza error o devuelve `NotProcessedYet` el recibo queda pendiente. `UserOwnsGamePassAsync` con `GrantGamePass/RevokeGamePass`, `PromptGamePassPurchase`, `PromptProductPurchase` (con `autoApprove`), eventos `Prompt*Finished`, `GetProductInfo` (con `RegisterProduct`) y `FailNext` para fallos web. |
| `Enum` | Solo `ProductPurchaseDecision`, `InfoType`, `CurrencyType`, `MembershipType`, `ReceiptType`, `ReceiptDecision`; se anaden mas con `Mocks.Enum.define(nombre, {Item = valor})`. |

Ejemplo completo y probado: `tools/examples/ReceiptHandler.luau` + `ReceiptHandler.spec.luau`
(ProcessReceipt idempotente por `PurchaseId` con `UpdateAsync`: reentrega del mismo recibo, caida y
recuperacion del DataStore, jugador ausente, producto desconocido, error en el callback y carrera con otro
servidor; 9 tests).

## 5. Limitaciones

- **No hay Roblox Studio ni motor de Roblox.** Solo se puede probar logica pura (calculos, maquinas de estado,
  economia, reintentos, idempotencia). No hay fisicas, `Instance`/DataModel, replicacion cliente-servidor,
  `RemoteEvent`s, GUI, animaciones ni `Humanoid`. Nada de lo que pase aqui garantiza que funcione en Studio:
  el codigo de este repo **no esta probado en Roblox** salvo que se indique lo contrario.
- **No se puede publicar a Roblox desde aqui.** No hay Studio, `create.roblox.com` esta bloqueado y no hay
  credenciales; `rojo build` solo genera `.rbxl/.rbxlx` locales. Subir/publicar requiere Studio o Open Cloud
  desde un equipo con acceso (no probado).
- **Los mocks son un modelo, no el comportamiento real.** Los limites y presupuestos de DataStore salen de
  `roblox-dev/references/datastore-persistence.md` `[TERCERO]` (no se pudo contrastar con la documentacion
  oficial); los textos y codigos de error (`101`, `102`, `104`, `105`, `301`, `502`) son aproximaciones
  `[NO VERIFICADO]`; el valor de retorno de `UpdateAsync` al cancelar (`nil`), el cooldown de escritura de 6 s y
  la forma exacta de `BindReceiptHandler`/`Enum.ReceiptDecision` tambien lo son. No se simulan la cola real de
  peticiones (aqui un presupuesto agotado falla al instante con `301`), `OrderedDataStore`, `ListKeysAsync` ni
  `MemoryStoreService`. `Players:AddPlayer` crea un stub, no una instancia real.
- **Lune no es Roblox.** En Lune 0.11 `task` no es global (se importa con `require("@lune/task")`; los mocks
  traen su propio `task`), no existen `game`, `Enum`, `Random` ni `warn` globales, y `require` funciona por
  rutas de cadena (`require("./Modulo")`, alias `@testkit`) en vez de `require(script.Parent.Modulo)`. Dentro de
  un `init.luau`, los hijos se piden con `@self/hijo` (un `./` apunta a la carpeta padre).
  Para codigo con `require(script.Parent.X)` usa inyeccion de dependencias o un adaptador fino.
- **Tipos**: sin `luau-lsp`, `luau-analyze` no conoce los tipos de Roblox (`game`, `Instance`, `warn`...), por eso
  `lint.sh` solo lo aplica a `tools/` (Luau puro). El linter `selene` usa `roblox_lite.yml`: reconoce los globales
  de Roblox pero no valida los argumentos de sus API.
- Los tests corren en procesos separados y secuenciales; `lune` es rapido (los 65 tests tardan < 1 s), pero un
  `task.wait` real dentro de un test consume tiempo real: usa `env.clock` en su lugar.
- `lune setup` genera los tipos de `@lune/*` en `~/.lune/.typedefs/0.11.0/` (por equipo, no en el repo); el alias `lune`
  de `.luaurc` apunta ahi. `tools/setup.sh` lo regenera.
- Si se mueve `tools/` dentro de `ROBLOX/` (lo que pide `CLAUDE.md` para "todo lo de Roblox"), hay que ajustar el alias
  `testkit` de `.luaurc` y la ruta `tools/` de `lint.sh` (filtro de luau-analyze); `tools/env.sh` calcula todo
  de forma relativa y no necesita cambios.
