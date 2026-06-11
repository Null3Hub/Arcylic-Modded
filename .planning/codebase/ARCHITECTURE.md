<!-- refreshed: 2026-06-11 -->
# Architecture

**Analysis Date:** 2026-06-11

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                    AcrylicUI Public API                      │
│  src/init.luau — CreateWindow / new / SetTheme / AddIcons   │
├─────────────────────────────────────────────────────────────┤
│                         Core Layer                           │
│  Window.luau         AcrylicBlur.luau    Notification.luau   │
│  BaseComponent.luau (lifecycle base)                         │
├─────────────────────────────────────────────────────────────┤
│                     Components Layer                         │
│  Section  Tab  ContentSection  Button  Toggle  Slider        │
│  Dropdown  Keybind  ColorPicker  TextBox  Paragraph          │
├─────────────────────────────────────────────────────────────┤
│                      Utils Layer                             │
│  Create  Tween  Draggable  Device  Services                  │
│  IconResolver  ConfigEncryption  RandomString                │
├─────────────────────────────────────────────────────────────┤
│                    Constants Layer                           │
│  Colors  Sizes  Fonts  Animation  Defaults  Icons  Layers   │
├─────────────────────────────────────────────────────────────┤
│                  Roblox Runtime                              │
│  ScreenGui → Container Frame → Sidebar + Content + Popups    │
│  Lighting (blur) / Camera (mesh tracking) / UserInput        │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| AcrylicUI (module) | Public facade — exposes `CreateWindow`, `new`, `SetTheme`, `ResetTheme`, `GetTheme`, `AddIcons`, `SetIconsType`, `GetInfo` | `src/init.luau` |
| Window | Central GUI container — ScreenGui lifecycle, dragging, resizing, minimize, keybinds, config system (save/load/delete/autosave/autoload), section/tab registry | `src/Core/Window.luau` |
| BaseComponent | Shared lifecycle — frame creation, connection tracking (`Connect`, `DisconnectAll`, `Destroy`), blocker overlay, config registration | `src/Core/BaseComponent.luau` |
| AcrylicBlur | Frosted glass effect — DepthOfFieldEffect + BlurEffect + camera-tracked Part mesh, handles camera swaps | `src/Core/AcrylicBlur.luau` |
| Notification | Toast notification system — container per ScreenGui, slide-in/out animations, auto-dismiss timer | `src/Core/Notification.luau` |
| Section | Sidebar section — collapsible header with tab list | `src/Components/Section.luau` |
| Tab | Sidebar tab button + content panel — delegates component creation methods | `src/Components/Tab.luau` |
| ContentSection | In-tab section grouping — header + separator + element container, includes `CreateConfigSection` | `src/Components/ContentSection.luau` |
| Button | Clickable button — hover/press animations, icon, callback | `src/Components/Button.luau` |
| Toggle | Toggle switch — animated circle, enabled/disabled states | `src/Components/Toggle.luau` |
| Slider | Numeric slider — drag input, fill bar, min/max/increment | `src/Components/Slider.luau` |
| Dropdown | Option selector — single/multi-select, search, popup positioning | `src/Components/Dropdown.luau` |
| Keybind | Keyboard binding — listening mode, key registration on Window | `src/Components/Keybind.luau` |
| ColorPicker | Color selector — preset palette popup, preview swatch | `src/Components/ColorPicker.luau` |
| TextBox | Text input — focus effects, numbers-only filter | `src/Components/TextBox.luau` |
| Paragraph | Static text display — title + wrapped content | `src/Components/Paragraph.luau` |
| Create | Instance factory — `Instance.new` wrapper with stealth naming, UI helpers (`Corner`, `Stroke`, `Padding`, `ListLayout`, `HoverEffect`, `ApplyIcon`, `Blockable`) | `src/Utils/Create.luau` |
| Tween | Animation wrapper — TweenService with per-instance caching and named presets | `src/Utils/Tween.luau` |
| Draggable | Drag handler — mouse + touch support, returns disconnect handle | `src/Utils/Draggable.luau` |
| Device | Platform detection — `IsMobile`, `IsTablet`, `IsDesktop`, `IsConsole`, viewport size | `src/Utils/Device.luau` |
| Services | Roblox service cache — `cloneref` + `ProtectGui` fallback chain | `src/Utils/Services.luau` |
| IconResolver | Icon resolution — asset IDs, pack paths (`pack/name`), remote pack loading via `loadstring`, spritesheet support | `src/Utils/IconResolver.luau` |
| ConfigEncryption | Config obfuscation — byte-shift + marker encoding (not cryptographic) | `src/Utils/ConfigEncryption.luau` |
| RandomString | Anti-detection names — control characters (bytes 1–7) | `src/Utils/RandomString.luau` |
| Colors | Theme system — `SetTheme` / `ResetTheme` / `Snapshot`, deep-merge of overrides | `src/Constants/Colors.luau` |
| Sizes | All pixel dimensions — Window, Toggle, Slider, Dropdown, etc. | `src/Constants/Sizes.luau` |
| Fonts | Typography — GothamSSm families, size presets | `src/Constants/Fonts.luau` |
| Animation | Tween presets — duration names, easing defaults | `src/Constants/Animation.luau` |
| Defaults | Fallback values — all component config defaults | `src/Constants/Defaults.luau` |
| Icons | Asset IDs — window controls, component icons, notification icons | `src/Constants/Icons.luau` |
| Layers | ZIndex constants — Window, Dropdown, Blocker, ColorPicker | `src/Constants/Layers.luau` |

## Pattern Overview

**Overall:** Modular OOP with shared base class + public facade

**Key Characteristics:**
- **Facade pattern** — `src/init.luau` exposes a flat public API; internals are not exported
- **Base class inheritance** — All components extend `BaseComponent` via metatables (`setmetatable(X, { __index = BaseComponent })`)
- **Configuration-driven** — Every component accepts a config table; missing fields fall back to `src/Constants/Defaults.luau`
- **Stealth naming** — All created instances get random control-character names (`RandomString.new()`) or `_A{seed}_{counter}` via `Create` to avoid executor detection
- **Executor compatibility** — `safeGet` pattern probes `getgenv() → getfenv() → _G` for executor-specific APIs (`writefile`, `readfile`, `cloneref`, `protect_gui`, `HttpGet`)
- **Shared ScreenGui** — Multiple windows share one ScreenGui (reference-counted) unless given a custom `Parent`
- **Popup layering** — Dropdown popups and ColorPicker palettes render into a dedicated `PopupLayer` frame at ZIndex 900+ to escape `ClipsDescendants`

## Layers

**Public API (Facade):**
- Purpose: Single entry point for consumer code
- Location: `src/init.luau`
- Contains: `AcrylicUI` table with `CreateWindow`, `new`, `SetTheme`, `ResetTheme`, `GetTheme`, `AddIcons`, `SetIconsType`, `GetInfo`, plus re-exported `Colors`, `Sizes`, `Fonts`, `Animation`, `Defaults`, `Icons`, `Layers`, `Utils`
- Depends on: `Window`, `IconResolver`, all Constants
- Used by: Consumer scripts (executor loadstring, Studio demo)

**Core:**
- Purpose: Window lifecycle, blur effects, notifications, component base class
- Location: `src/Core/`
- Contains: `Window.luau` (1492 lines), `BaseComponent.luau` (126 lines), `AcrylicBlur.luau` (307 lines), `Notification.luau` (236 lines)
- Depends on: Utils, Constants
- Used by: Components, init.luau

**Components:**
- Purpose: Individual UI controls (buttons, toggles, sliders, etc.)
- Location: `src/Components/`
- Contains: 11 component files
- Depends on: Core/BaseComponent, Utils/Create, Utils/Tween, Constants
- Used by: Tab, ContentSection, Window

**Utils:**
- Purpose: Shared infrastructure — instance creation, animation, input, services, encryption
- Location: `src/Utils/`
- Contains: 8 utility modules
- Depends on: Constants, Roblox services
- Used by: Core, Components

**Constants:**
- Purpose: All configurable values — colors, sizes, fonts, defaults, icons, layers
- Location: `src/Constants/`
- Contains: 7 constant modules
- Depends on: Nothing (leaf layer)
- Used by: Everything

## Data Flow

### Primary Request Path

1. Consumer calls `AcrylicUI.CreateWindow(config)` (`src/init.luau:72`)
2. `Window.new(config)` creates a ScreenGui + Container Frame (`src/Core/Window.luau:239`)
3. Consumer calls `window:CreateSection(name)` → `Section.new(window, name)` (`src/Core/Window.luau:989`)
4. Consumer calls `section:CreateTab(name, icon)` → `Tab.new(window, section, name, icon)` (`src/Components/Tab.luau:36`)
5. Consumer calls `tab:Toggle(config)` → `Toggle.new(content, config, window)` (`src/Components/Toggle.luau:46`)
6. Toggle registers config element via `Create.Configurable` → `window:RegisterConfigElement` (`src/Utils/Create.luau:256`, `src/Core/Window.luau:1040`)

### Config Save/Load Flow

1. `window:SaveConfig(name)` (`src/Core/Window.luau:1074`)
2. Iterates `_configElements`, calls `getValue()` for each flag
3. Serializes `Color3` → `{_type, R, G, B}` and `EnumItem` → `{_type, EnumType, Name}` (`src/Core/Window.luau:143-184`)
4. JSON-encodes via `HttpService:JSONEncode`
5. Obfuscates via `ConfigEncryption.Encrypt` (byte-shift + marker) (`src/Utils/ConfigEncryption.luau:56`)
6. Writes to `AcrylicConfigs/{folder}/{name}.json` via executor `writefile`
7. Load reverses: `readfile` → detect encryption → `Decrypt` → `JSONDecode` → `DeserializeValue` → `setValue` per flag

### Icon Resolution Flow

1. `Create.ApplyIcon(imageLabel, icon, fallbackIcon)` (`src/Utils/Create.luau:369`)
2. `IconResolver.Resolve(icon)` (`src/Utils/IconResolver.luau:373`)
3. If asset ID string/number → normalize to `rbxassetid://` prefix
4. If `pack/name` or `pack:name` → check custom packs, then cache, then fetch remote via `loadstring`
5. Returns `IconDescriptor` with `Image`, `ImageRectOffset`, `ImageRectSize`, optional `Parts` for layered icons

**State Management:**
- Window maintains `_sections`, `_keybinds`, `_configElements`, `_currentTab`, `_currentConfig`
- Components hold local state (`_enabled`, `_value`, `_selected`, `_color`, etc.)
- Theme is global via the `Colors` module table — `SetTheme` mutates it in-place
- Config persistence relies on executor filesystem APIs (`writefile`/`readfile`); gracefully degrades with notifications when unavailable

## Key Abstractions

**BaseComponent:**
- Purpose: Provides shared lifecycle for all UI components
- Examples: `Button.luau`, `Toggle.luau`, `Slider.luau`, `Dropdown.luau`, `Keybind.luau`, `ColorPicker.luau`, `TextBox.luau`, `Paragraph.luau`, `Section.luau`, `Tab.luau`, `ContentSection.luau`
- Pattern: OOP via metatables — each component calls `BaseComponent.new(self, config)` then stores result as `self`

**Create (Instance Factory):**
- Purpose: Centralized `Instance.new` wrapper with naming policy and UI helpers
- Examples: Used by every module that creates Roblox instances
- Pattern: Static utility table — all functions are pure helpers, no state

**Configurable (Config Registration):**
- Purpose: Bridges component state to Window's config system
- Examples: `Create.Configurable(self, flag, typeName, getter, setter)` in every component
- Pattern: Registers getter/setter pair on Window for save/load round-trip

**Blockable (Block Overlay):**
- Purpose: Adds `Block(text)`, `Unblock()`, `IsBlocked()` to any component
- Examples: `Create.Blockable(self, frame)` in `BaseComponent.new` when `config.Blockable == true`
- Pattern: Mutates target object by attaching methods + overlay UI elements

## Entry Points

**AcrylicUI (Library Entry):**
- Location: `src/init.luau`
- Triggers: `require(path.to.AcrylicUI)` in consumer scripts
- Responsibilities: Exposes public API, delegates to Window, manages theme and icon packs

**Window.new (Window Creation):**
- Location: `src/Core/Window.luau:239`
- Triggers: `AcrylicUI.CreateWindow(config)` or `AcrylicUI.new(title, configFolder)`
- Responsibilities: Creates ScreenGui, Container, TopBar, Sidebar, Content area, Blur, Notification container

**ContentSection.CreateConfigSection (Config UI):**
- Location: `src/Components/ContentSection.luau:150`
- Triggers: `tab:CreateConfigSection()` or `contentSection:CreateConfigSection()`
- Responsibilities: Creates TextBox + Dropdown + Buttons + Toggles for config management

**Studio Demo (Studio Entry):**
- Location: `studio/AcrylicStudioDemo.client.luau`
- Triggers: Rojo sync with `studio.project.json`
- Responsibilities: Creates full demo window in Roblox Studio

**Smoke Test (Test Entry):**
- Location: `tests/smoke.client.luau`
- Triggers: Rojo sync with `test.project.json`
- Responsibilities: Asserts module requires and API surface

## Architectural Constraints

- **Single-threaded Roblox Luau** — No coroutine-based concurrency; all animation is via `TweenService` + `RenderStepped`
- **Global mutable state** — `Colors` module table is mutated in-place by `SetTheme`; all consumers share the same color references
- **Shared ScreenGui** — `Window._sharedScreenGui` is a class-level singleton with reference counting; destroyed when last window using it calls `Destroy()`
- **Executor dependency** — File I/O (`writefile`/`readfile`), GUI protection (`protect_gui`/`cloneref`), and HTTP (`HttpGet`/`request`) are optional executor APIs; gracefully degrade via `pcall` + `safeGet`
- **No circular imports** — Module dependency is strictly unidirectional: Constants → Utils → Core → Components → init.luau

## Anti-Patterns

### safeGet Environment Probing

**What happens:** Multiple modules (`Window.luau`, `Services.luau`, `IconResolver.luau`) independently probe `getgenv() → getfenv() → _G` to find executor APIs.
**Why it's wrong:** Code duplication across 3+ files; each module reimplements the same fallback chain with slightly different logic.
**Do this instead:** Centralize environment probing in `Services.luau` (which already does this for `cloneref`/`ProtectGui`) and export resolved functions. Other modules should import from `Services`.

### Inline Default Fallbacks

**What happens:** Components use patterns like `config.Name or Defaults.Name or "Fallback"` with 2–3 levels of fallback.
**Why it's wrong:** Makes it hard to know which default actually applies; the triple-fallback pattern is repeated in every component.
**Do this instead:** Create a `Resolve(config, key, defaultKey)` helper that reads `config[key] → ComponentDefaults[key] → fallback` in one call.

### Block Method Monkey-Patching

**What happens:** Components override `self.Block` with a wrapper that calls `close()` or resets state before delegating to `baseBlock` (e.g., `Dropdown.luau:246`, `Keybind.luau:147`, `ColorPicker.luau:251`, `TextBox.luau:161`).
**Why it's wrong:** Relies on capturing `baseBlock` before the override; fragile if initialization order changes.
**Do this instead:** Add an optional `onBlock` callback parameter to `BaseComponent.new` or `Create.Blockable` that components provide during construction.

## Error Handling

**Strategy:** Fail silently with `pcall` wrappers + `warn()` for non-critical operations; show user-facing errors via `Notification`.

**Patterns:**
- `pcall` around executor API calls (`writefile`, `readfile`, `getgenv`, `cloneref`) — never crash on missing executor features
- `pcall` around `AcrylicBlur.new` — gracefully disable blur if blocked by executor (`src/Core/Window.luau:426`)
- `warn("[AcrylicUI] ...")` for failed icon pack loads, config operations, and pending config application errors
- Notification-based user feedback for config save/load success/failure (`src/Core/Window.luau:1074-1235`)

## Cross-Cutting Concerns

**Logging:** `warn()` with `[AcrylicUI]` prefix for non-critical errors. No structured logging framework.

**Validation:** Config names are sanitized via `SanitizeConfigName` (strip whitespace, replace illegal chars, collapse `..`). No schema validation on component config tables.

**Authentication:** None. This is a client-side UI library. Executor environment detection (`safeGet`) serves as platform adaptation, not security.

**Theming:** Global mutable `Colors` table. `SetTheme` deep-merges overrides. `ResetTheme` restores from frozen `_defaults` snapshot captured at load time (`src/Constants/Colors.luau:68`).

**Anti-Detection:** `RandomString.new()` generates names from control characters (bytes 1–7). `Create` applies stealth naming to all instances. `src.lua.txt` is a generated bundle for executor `loadstring` delivery.

---

*Architecture analysis: 2026-06-11*
