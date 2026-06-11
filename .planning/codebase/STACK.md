# Technology Stack

**Analysis Date:** 2026-06-11

## Languages

**Primary:**
- Luau (Roblox Lua variant) - All library source code (`src/`, `studio/`), component implementations, constants, utilities

**Secondary:**
- JavaScript (Node.js) - Static contract tests (`tests/static-contracts.test.js`, `tests/icon_resolver_test.js`)
- Python - IconResolver TDD test harness (`tests/icon_resolver_test.py`)
- PowerShell - Build scripts, source parity checks (`build/source-parity-check.ps1`)
- Lua (legacy) - Bundled executor example (`Exemple.lua`), generated bundle (`src.lua.txt`)

## Runtime

**Environment:**
- Roblox Engine - Client-side execution (LocalScript context)
- Executor environments - Secondary target via `loadstring` and `game:HttpGet` (Synapse X, Script-Ware, Fluxus, etc.)
- Node.js - For CI test runner (static contract tests)

**Package Manager:**
- Wally (Roblox package manager) - `wally.toml` declares the package as `null3hub/arcylic-modded` v2.0.0
  - Registry: `https://github.com/UpliftGames/wally-index`
  - Realm: `shared`
  - Dependencies section is empty (zero external Wally dependencies)

## Frameworks

**Core:**
- Custom UI framework (no third-party UI library) - Built on Roblox Instance API (Frames, TextLabels, ImageLabels, TextButtons, etc.)
- Rojo 7.4.4 - Filesystem-to-Roblox sync and build tool (`aftman.toml`, `*.project.json`)

**Testing:**
- Node.js `node:assert` - Static contract tests (`tests/static-contracts.test.js`)
- Custom JS TDD harness - IconResolver contract tests (`tests/icon_resolver_test.py`)
- In-engine smoke test - `tests/smoke.client.luau` (runs inside Roblox via test.project.json)

**Build/Dev:**
- Aftman - Roblox toolchain manager (`aftman.toml`) managing Rojo, StyLua, Selene
- StyLua 0.20.0 - Luau formatter (`.stylua.toml`)
- Selene 0.31.0 - Luau linter (`selene.toml`, `std = "roblox"`)
- build-bundle.js (referenced in `src.lua.txt` header) - Generates single-file bundle from `src/`

## Key Dependencies

**Critical:**
- None (zero external runtime dependencies) - The library is entirely self-contained with no Wally dependencies

**Roblox Services Used (via `src/Utils/Services.luau`):**
- `TweenService` - Animations and transitions
- `UserInputService` - Input handling (keyboard, mouse, touch, gamepad)
- `Players` - LocalPlayer access for GUI parenting
- `Lighting` - BlurEffect and DepthOfFieldEffect for acrylic glass
- `RunService` - RenderStepped for resize tracking and blur updates
- `GuiService` - Safe area insets for mobile notch handling
- `HttpService` - JSON encode/decode for config serialization
- `TextService` - Text measurement (used indirectly)

**Executor-Specific APIs (detected at runtime via `src/Utils/Services.luau`, `src/Core/Window.luau`):**
- `getgenv()` - Global environment access (executor)
- `cloneref()` - Instance reference cloning (anti-detection)
- `protect_gui()` / `protectgui()` / `syn.protect_gui` - GUI protection (anti-detection)
- `gethui()` / `get_hidden_gui` - Hidden GUI container (anti-detection)
- `writefile`, `readfile`, `isfile`, `makefolder`, `isfolder`, `listfiles`, `delfile` - File I/O for config persistence (executor only)
- `loadstring()` / `load()` - Dynamic code loading (executor)
- `game:HttpGet` / `request` / `http_request` / `syn.request` / `http.request` - HTTP fetching (executor)

## Configuration

**Environment:**
- No `.env` files required
- No environment variables needed at runtime
- Config is driven entirely by Lua tables passed to `AcrylicUI.CreateWindow()`

**Build:**
- `wally.toml` - Wally package manifest (package name, version, registry, realm)
- `aftman.toml` - Toolchain versions (Rojo 7.4.4, StyLua 0.20.0, Selene 0.31.0)
- `.stylua.toml` - Formatter settings: 100 column width, Unix line endings, 4-space indent, auto-prefer double quotes
- `selene.toml` - Linter config: `std = "roblox"`, excludes `src.lua.txt`, allows `global_usage`, allows `roblox_manual_fromscale_or_fromoffset`
- `default.project.json` - Rojo project: maps `src/` to `ReplicatedStorage.AcrylicUI`
- `studio.project.json` - Rojo project: maps `studio/AcrylicUI/` to `ReplicatedStorage.AcrylicUI` with demo client script
- `test.project.json` - Rojo project: maps `src/` to `ReplicatedStorage.AcrylicUI` with smoke test client script
- `build.rbxl` - Pre-built Roblox place file

**Runtime Config (user-facing):**
- `WindowConfig` table passed to `AcrylicUI.CreateWindow()` or `AcrylicUI.new()`
- Config persistence uses executor file APIs (`writefile`/`readfile`) under `AcrylicConfigs/<folder>/` path
- Config data serialized as JSON, encrypted via byte-shift + Base64 (`src/Utils/ConfigEncryption.luau`)

## Platform Requirements

**Development:**
- Windows (primary) - `.bat` launcher, PowerShell scripts
- macOS/Linux - Aftman, Rojo, StyLua, Selene are cross-platform
- Node.js - Required for CI contract tests
- Roblox Studio - For visual testing via `studio.project.json`
- Roblox Executor - For runtime testing via `Exemple.lua` or `src.lua.txt`

**Production:**
- Roblox Client - Any executor environment supporting `loadstring` and `game:HttpGet`
- Roblox Studio - Published experiences using ModuleScript `require(...)` pattern
- No server-side component (client-only library)

## Distribution Methods

1. **ModuleScript** - Place `src/` as `ReplicatedStorage.AcrylicUI`, require from LocalScript
2. **Bundle** - `src.lua.txt` (7,400 lines) - Single-file generated bundle for executor `loadstring`
3. **Built Place** - `build/` directory contains `.rbxl` and `.rbxm` files for Rojo builds

---

*Stack analysis: 2026-06-11*
