# Codebase Structure

**Analysis Date:** 2026-06-11

## Directory Layout

```
Arcylic/
├── src/                        # Primary library source (Luau modules)
│   ├── init.luau               # Public API facade — CreateWindow, new, SetTheme, etc.
│   ├── Types.luau              # Shared type definitions (WindowConfig, ToggleConfig, etc.)
│   ├── Core/                   # Central modules
│   │   ├── Window.luau         # GUI container, keybinds, config system (~1492 lines)
│   │   ├── BaseComponent.luau  # Shared component lifecycle (Connect, DisconnectAll, Destroy)
│   │   ├── AcrylicBlur.luau    # Frosted glass blur effect (DepthOfField + BlurEffect + mesh)
│   │   └── Notification.luau   # Toast notification system (auto-dismiss, timer bar)
│   ├── Components/             # Individual UI controls
│   │   ├── Button.luau         # Clickable button with hover/press animations
│   │   ├── Toggle.luau         # Toggle switch with animated circle
│   │   ├── Slider.luau         # Numeric slider with drag input
│   │   ├── Dropdown.luau       # Single/multi-select dropdown with search (~711 lines)
│   │   ├── Keybind.luau        # Keyboard binding selector
│   │   ├── ColorPicker.luau    # Color picker with preset palette
│   │   ├── TextBox.luau        # Text input with focus effects
│   │   ├── Paragraph.luau      # Static text display
│   │   ├── Section.luau        # Sidebar collapsible section
│   │   ├── Tab.luau            # Sidebar tab + content panel
│   │   └── ContentSection.luau # In-tab section grouping + ConfigSection builder
│   ├── Utils/                  # Shared utilities
│   │   ├── Create.luau         # Instance factory + UI helpers (~479 lines)
│   │   ├── Tween.luau          # TweenService wrapper with caching
│   │   ├── Draggable.luau      # Mouse/touch drag handler
│   │   ├── Device.luau         # Platform detection (mobile/tablet/desktop/console)
│   │   ├── Services.luau       # Roblox service cache + executor env probing
│   │   ├── IconResolver.luau   # Icon resolution (assets, packs, remote loading)
│   │   ├── ConfigEncryption.luau # Byte-shift + marker obfuscation
│   │   └── RandomString.luau   # Anti-detection name generator
│   └── Constants/              # All configurable values
│       ├── Colors.luau         # Theme colors + SetTheme/ResetTheme/Snapshot
│       ├── Sizes.luau          # Pixel dimensions for all components
│       ├── Fonts.luau          # GothamSSm font families + size presets
│       ├── Animation.luau      # Duration presets + easing defaults
│       ├── Defaults.luau       # Fallback values for all component configs
│       ├── Icons.luau          # Asset IDs for window controls + component icons
│       └── Layers.luau         # ZIndex constants for overlays
├── studio/                     # Studio testing mirror
│   ├── AcrylicUI/              # Mirror of src/ for Rojo Studio sync
│   │   ├── init.luau
│   │   ├── Types.luau
│   │   ├── Core/
│   │   ├── Components/
│   │   ├── Utils/
│   │   └── Constants/
│   ├── AcrylicUI-patches/      # Studio-specific patches
│   └── AcrylicStudioDemo.client.luau  # Studio demo script
├── tests/                      # Test files
│   ├── smoke.client.luau       # Roblox smoke test (asserts API surface)
│   ├── icon_resolver_test.js   # JavaScript icon resolver tests
│   ├── icon_resolver_test.py   # Python icon resolver tests
│   └── static-contracts.test.js # Static contract tests
├── build/                      # Rojo build outputs
│   ├── AcrylicUI.rbxm          # Library model for game insert
│   ├── AcrylicUIStudio.rbxm    # Studio model
│   ├── AcrylicUITest.rbxm      # Test model
│   ├── output.rbxl             # Built place file
│   ├── studio.rbxl             # Studio place file
│   ├── test.rbxl               # Test place file
│   └── source-parity-check.ps1 # Script to verify src/ ↔ studio/AcrylicUI parity
├── selene/                     # Selene std overrides
├── .github/                    # GitHub workflows
├── .vscode/                    # VS Code settings
├── default.project.json        # Rojo project — maps src/ → ReplicatedStorage.AcrylicUI
├── studio.project.json         # Rojo project — maps studio/AcrylicUI → ReplicatedStorage
├── test.project.json           # Rojo project — maps src/ + tests/smoke → StarterPlayerScripts
├── wally.toml                  # Wally package manifest (null3hub/arcylic-modded v2.0.0)
├── aftman.toml                 # Aftman toolchain (Rojo 7.4.4, StyLua 0.20.0, selene 0.31.0)
├── .stylua.toml                # StyLua config (4-space indent, Unix line endings)
├── selene.toml                 # Selene config (roblox std, allow global_usage)
├── src.lua.txt                 # Generated bundle for executor loadstring delivery
├── Exemple.lua                 # Executor usage example
├── build.rbxl                  # Build place
├── start-rojo.bat              # Rojo serve launcher
├── README.md                   # Documentation
├── LICENSE                     # MIT License
└── .gitignore
```

## Directory Purposes

**`src/`:**
- Purpose: Primary library source code
- Contains: All Luau modules organized into Core/, Components/, Utils/, Constants/
- Key files: `init.luau` (entry point), `Types.luau` (type definitions)

**`src/Core/`:**
- Purpose: Central infrastructure modules
- Contains: Window container, base class, blur effect, notification system
- Key files: `Window.luau` (1492 lines — largest file), `BaseComponent.luau`

**`src/Components/`:**
- Purpose: Individual UI controls
- Contains: 11 component modules, each extending BaseComponent
- Key files: `Dropdown.luau` (711 lines — most complex component), `Tab.luau`, `ContentSection.luau`

**`src/Utils/`:**
- Purpose: Shared utilities consumed by Core and Components
- Contains: Instance creation, animation, input handling, services, encryption
- Key files: `Create.luau` (479 lines — richest utility), `IconResolver.luau` (409 lines)

**`src/Constants/`:**
- Purpose: All configurable values as plain tables
- Contains: Colors, Sizes, Fonts, Animation, Defaults, Icons, Layers
- Key files: `Colors.luau` (has methods), `Defaults.luau` (most comprehensive), `Sizes.luau` (largest)

**`studio/`:**
- Purpose: Roblox Studio testing environment
- Contains: Mirror of `src/` (synced via `build/source-parity-check.ps1`), demo script
- Key files: `AcrylicStudioDemo.client.luau`, `AcrylicUI/` (mirror)

**`tests/`:**
- Purpose: Automated tests
- Contains: Roblox smoke test, JS/Python icon resolver tests
- Key files: `smoke.client.luau`, `icon_resolver_test.js`

**`build/`:**
- Purpose: Rojo build outputs and build scripts
- Contains: `.rbxm` models, `.rbxl` place files, parity check script
- Key files: `AcrylicUI.rbxm`, `source-parity-check.ps1`

**`selene/`:**
- Purpose: Selene linter standard library overrides
- Contains: Custom std definitions for Luau/Roblox

## Key File Locations

**Entry Points:**
- `src/init.luau`: Library entry — `require(AcrylicUI)` returns this module
- `studio/AcrylicStudioDemo.client.luau`: Studio demo — runs when Studio project syncs
- `tests/smoke.client.luau`: Test entry — runs when test project syncs
- `Exemple.lua`: Executor usage example — downloads `src.lua.txt` via loadstring

**Configuration:**
- `default.project.json`: Rojo project for game — maps `src/` → `ReplicatedStorage.AcrylicUI`
- `studio.project.json`: Rojo project for Studio — maps `studio/AcrylicUI` → `ReplicatedStorage`
- `test.project.json`: Rojo project for tests — maps `src/` + `tests/smoke.client.luau`
- `wally.toml`: Wally package config — `null3hub/arcylic-modded` v2.0.0
- `aftman.toml`: Toolchain — Rojo 7.4.4, StyLua 0.20.0, selene 0.31.0
- `.stylua.toml`: Formatter — 4-space indent, Unix line endings
- `selene.toml`: Linter — `roblox` std, allows `global_usage`

**Core Logic:**
- `src/Core/Window.luau`: Central module — GUI lifecycle, config system, keybinds
- `src/Core/BaseComponent.luau`: Component base class — lifecycle methods
- `src/Utils/Create.luau`: Instance factory — stealth naming, UI helpers
- `src/Utils/Services.luau`: Service cache — executor env probing
- `src/Constants/Colors.luau`: Theme system — mutable color table with methods
- `src/Constants/Defaults.luau`: All component defaults

**Testing:**
- `tests/smoke.client.luau`: Roblox smoke test
- `tests/icon_resolver_test.js`: JavaScript icon tests
- `tests/icon_resolver_test.py`: Python icon tests
- `tests/static-contracts.test.js`: Static contract tests
- `build/source-parity-check.ps1`: Source parity verification

## Naming Conventions

**Files:**
- PascalCase for all `.luau` files: `Window.luau`, `BaseComponent.luau`, `Create.luau`
- Exception: `init.luau` (Roblox convention for module entry)
- Exception: `Types.luau` (type definition file)

**Directories:**
- PascalCase for all directories: `Core/`, `Components/`, `Utils/`, `Constants/`
- Exception: `src/` (lowercase, Roblox convention)

**Modules (internal):**
- PascalCase table names: `Window`, `BaseComponent`, `Create`, `Tween`, `Colors`
- Private fields prefixed with `_`: `self._frame`, `self._connections`, `self._enabled`
- Private methods prefixed with `_`: `self:_CreateGui()`, `self:_SetupResize()`

**Constants (module-level):**
- PascalCase: `Colors.Background`, `Sizes.Window.Width`, `Fonts.Regular`
- Nested tables: `Colors.Toggle.Enabled`, `Sizes.Corner.Medium`, `Animation.Duration.Fast`
- Config keys in Defaults: PascalCase matching component config: `Defaults.Components.Toggle.Name`

**Config Properties:**
- PascalCase for all user-facing config properties: `Name`, `Description`, `Default`, `Callback`, `Flag`
- Aliases supported: `Desc` → `Description`, `Icon` → asset ID

## Where to Add New Code

**New Component:**
- Implementation: `src/Components/NewComponent.luau`
- Add `NewComponentConfig` type to `src/Types.luau`
- Add default config to `src/Constants/Defaults.luau` under `Components.NewComponent`
- Add size constants to `src/Constants/Sizes.luau` under `NewComponent`
- Wire into `Tab.luau` (add `Tab:NewComponent(config)` method)
- Wire into `ContentSection.luau` (add `ContentSection:NewComponent(config)` method)
- Expose in `AcrylicUI.GetInfo()` components list (`src/init.luau:136`)

**New Utility:**
- Implementation: `src/Utils/NewUtil.luau`
- Import in consuming modules via `require(script.Parent.Parent.Utils.NewUtil)`
- Optionally expose in `AcrylicUI.Utils` table (`src/init.luau:51`)

**New Constant:**
- Implementation: `src/Constants/NewConstant.luau`
- Export in `AcrylicUI` table (`src/init.luau`)
- Follow existing pattern: return a plain table (or table with methods like `Colors`)

**New Theme Property:**
- Add to `Colors` table in `src/Constants/Colors.luau`
- Add to `ThemeColors` type in `src/Types.luau`
- Reference in component code via `Colors.NewProperty`

**New Window Feature:**
- Add method to `src/Core/Window.luau`
- If it affects config: add to `_configElements` registration flow
- If it needs UI: add to `_CreateContentArea` or `_CreateWindowControls`

**Studio Testing:**
- Mirror changes from `src/` to `studio/AcrylicUI/` (or run `build/source-parity-check.ps1`)
- Update `studio/AcrylicStudioDemo.client.luau` if demoing new features

## Special Directories

**`studio/AcrylicUI/`:**
- Purpose: Mirror of `src/` for Roblox Studio testing
- Generated: Semi-automated — sync from `src/` via parity check script
- Committed: Yes — kept in sync for CI and Studio development

**`build/`:**
- Purpose: Rojo build outputs (`.rbxm`, `.rbxl`)
- Generated: Yes — produced by `rojo build` commands
- Committed: Yes — pre-built outputs for easy distribution

**`src.lua.txt`:**
- Purpose: Concatenated bundle for executor `loadstring` delivery
- Generated: Yes — likely via build script concatenating all `src/` modules
- Committed: Yes — serves as the downloadable artifact for executor users

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents
- Generated: Yes — produced by `/gsd-map-codebase`
- Committed: No — local planning artifacts

---

*Structure analysis: 2026-06-11*
