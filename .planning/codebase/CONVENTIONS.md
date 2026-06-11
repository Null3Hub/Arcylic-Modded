# Coding Conventions

**Analysis Date:** 2026-06-11

## Language & Runtime

**Primary Language:** Luau (Roblox Lua variant) with `.luau` file extension
**Type System:** Luau type annotations (`export type`, optional types `Type?`, union types `string | number`)
**Runtime:** Roblox engine (Roblox API, Roblox Services)

## Formatting

**Tool:** StyLua v0.20.0
**Configuration:** `.stylua.toml`
```toml
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 4
quote_style = "AutoPreferDouble"
```

**Key Rules:**
- 4-space indentation (no tabs)
- Unix line endings (`\n`)
- Double quotes preferred for strings
- Max line width: 100 characters

**Run Format:**
```bash
stylua src/ studio/
```

## Linting

**Tool:** Selene v0.31.0
**Configuration:** `selene.toml`
```toml
std = "roblox"
exclude = ["src.lua.txt"]

[config]
unused_variable = { ignore_pattern = "^_" }

[lints]
roblox_manual_fromscale_or_fromoffset = "allow"
global_usage = "allow"
```

**Key Rules:**
- Unused variables prefixed with `_` are ignored
- Global usage is allowed (executor environment)
- Roblox API usage is linted

**Run Lint:**
```bash
selene src/ studio/
```

## Naming Patterns

**Files:**
- PascalCase: `BaseComponent.luau`, `IconResolver.luau`, `ConfigEncryption.luau`
- Components: `Button.luau`, `Toggle.luau`, `Slider.luau`
- Constants: `Colors.luau`, `Sizes.luau`, `Animation.luau`
- Utilities: `Create.luau`, `Tween.luau`, `Draggable.luau`

**Directories:**
- PascalCase: `Components/`, `Constants/`, `Core/`, `Utils/`
- Special: `src/` (root source), `tests/` (test files)

**Modules/Tables:**
- PascalCase: `local Window = {}`, `local Create = {}`, `local Colors = {}`
- Constants modules: `local Animation = {}`, `local Fonts = {}`

**Functions/Methods:**
- Public methods: PascalCase: `Window.new()`, `Button:SetText()`, `Tween.Create()`
- Private methods: PascalCase with `_` prefix: `self:_CreateGui()`, `self:_UpdateVisual()`
- Private local functions: camelCase: `local function safeGet()`, `local function resolveNumber()`

**Variables:**
- Local variables: camelCase: `local name = config.Name`, `local self = {}`
- Instance properties: camelCase: `self._frame`, `self._callback`, `self._connections`
- Constants: PascalCase: `local ASSET_PREFIX = "rbxassetid://"`, `local CONFIG_DEFAULT_NAME = "default"`

**Types:**
- PascalCase: `export type WindowConfig = {}`, `export type ToggleConfig = {}`
- Type fields: PascalCase: `Name: string?`, `Callback: (() -> ())?`

**Private Fields Convention:**
- Underscore prefix: `self._frame`, `self._connections`, `self._blocked`
- Module-level private: `local _cache: { [string]: any } = {}`
- Weak references: `setmetatable({}, { __mode = "k" })`

## Import Organization

**Order:**
1. Roblox services (via Services module)
2. Utility modules (Create, Tween, Draggable, Device)
3. Core modules (BaseComponent)
4. Constants modules (Colors, Sizes, Fonts, Defaults, Icons, Layers)
5. Component modules (Button, Toggle, etc.)

**Pattern:**
```lua
local Services = require(script.Parent.Parent.Utils.Services)
local Create = require(script.Parent.Parent.Utils.Create)
local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
```

**Path Aliases:** None — relative `require()` paths only
- `script.Parent.Parent.Utils.Services` (two levels up to src/, then down)
- `script.Parent.Parent.Constants.Colors`

## Module Pattern

**Standard Module:**
```lua
local ModuleName = {}
ModuleName.__index = ModuleName

-- Export type definitions
export type ModuleConfig = {
    Name: string?,
    Callback: (() -> ())?,
}

-- Local defaults
local ModuleDefaults = Defaults.Components.ModuleName or {}

-- Constructor
function ModuleName.new(config: ModuleConfig)
    config = config or {}
    local self = setmetatable({}, ModuleName)
    -- Initialize
    return self
end

-- Public methods
function ModuleName:MethodName()
    -- Implementation
end

return ModuleName
```

## Component Pattern

**Base Component Inheritance:**
```lua
local MyComponent = {}
MyComponent.__index = MyComponent
setmetatable(MyComponent, { __index = BaseComponent })

function MyComponent.new(parent: Instance, config: MyConfig, window)
    config = config or {}
    local self = BaseComponent.new(MyComponent, {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height),
        Blockable = true,
        Flag = config.Flag,
        Window = window,
    })
    -- Initialize component
    return self
end
```

**Key Characteristics:**
- All components inherit from `BaseComponent` via `setmetatable`
- `BaseComponent.new()` handles frame creation, connection tracking, and cleanup
- Components store references in `self._connections` for automatic cleanup
- Blockable components implement `Block()`, `Unblock()`, `IsBlocked()`
- Configurable components use `Create.Configurable()` for config save/load

## Error Handling

**Primary Pattern:** `pcall()` wrapping for executor-dependent APIs
```lua
local ok, result = pcall(function()
    return gethui()
end)
if ok and result then
    return result
end
```

**Error Display:**
```lua
if not success then
    warn("[AcrylicUI] Failed to apply config: " .. tostring(err))
end
```

**Graceful Degradation:**
```lua
local blurOk, blur = pcall(AcrylicBlur.new, self._container)
if blurOk then
    self._acrylicBlur = blur
else
    self._acrylicBlur = nil
    warn("[AcrylicUI] Acrylic blur disabled: " .. tostring(blur))
end
```

**Config Operations:**
- All file I/O wrapped in `pcall()`
- User-facing errors shown via `self:Notify()`
- Errors logged with `warn("[AcrylicUI] ...")` prefix

## Comment Style

**Module Header:**
```lua
--[[
    AcrylicUI - Module Name

    Description of the module.
]]
```

**Function Documentation:**
```lua
--[[
    Creates a new window

    @param config WindowConfig - Window configuration
    @return Window - Window instance

    @example
    local window = Window.new({
        Title = "My Hub",
    })
]]
```

**Inline Comments:**
- Use `--` for single-line comments
- Use `--[[ ]]` for block comments
- No JSDoc/TSDoc (Luau uses `@param`, `@return`, `@example`)

## Constants Pattern

**Centralized in `src/Constants/`:**
- `Colors.luau` — Theme colors with runtime `SetTheme()`/`ResetTheme()` support
- `Sizes.luau` — All pixel dimensions organized by component
- `Fonts.luau` — Font families and text sizes
- `Animation.luau` — Duration presets and easing defaults
- `Defaults.luau` — Runtime fallback values for all components
- `Icons.luau` — Named asset IDs for UI elements
- `Layers.luau` — ZIndex layer assignments

**Access Pattern:**
```lua
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)

-- Use constants directly
local height = Sizes.Button.Height
local color = Colors.Background
```

**Fallback Pattern:**
```lua
local name = config.Name or ButtonDefaults.Name or "Button"
```

## Stealth/Anti-Detection Pattern

**RandomString Utility:**
```lua
-- Generates control-character names (char codes 1-7)
-- Used for ScreenGui and Instance naming to avoid detection
function RandomString.new(length: number?): string
    length = length or 30
    local chars = {}
    for i = 1, length do
        chars[i] = string.char(math.random(1, 7))
    end
    return table.concat(chars)
end
```

**Usage:**
- ScreenGui names: `Name = RandomString.new()`
- Instance naming: `applyNamePolicy()` with `PreserveName` or `RandomizeName`

## Executor Environment Access

**Pattern:** Safe environment probing with fallbacks
```lua
local function safeGet(name: string): any?
    -- 1. Try getgenv() (executor global env)
    -- 2. Try getfenv() (Lua environment)
    -- 3. Try _G (global table)
    -- Return first matching function
end
```

**Used for:**
- File I/O: `writefile`, `readfile`, `isfile`, `makefolder`
- GUI protection: `protect_gui`, `protectgui`, `syn.protect_gui`
- HTTP requests: `request`, `http_request`, `syn.request`
- Service cloning: `cloneref`

## Validation Patterns

**Input Validation:**
```lua
if type(iconType) ~= "string" or iconType == "" then
    error("SetIconsType: iconType must be a non-empty string", 2)
end
```

**Number Validation:**
```lua
local function isFiniteNumber(value: any): boolean
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end
```

**Config Sanitization:**
```lua
local function SanitizeConfigName(configName: string?): string
    local sanitized = tostring(configName or CONFIG_DEFAULT_NAME)
    sanitized = sanitized:gsub("^%s+", ""):gsub("%s+$", "")
    sanitized = sanitized:gsub("%.%.", "_")
    sanitized = sanitized:gsub('[%/%\\%*%?"<>|:]', "_")
    sanitized = sanitized:gsub("^%.+", ""):gsub("%.+$", "")
    return sanitized
end
```

## Resource Cleanup

**Connection Tracking:**
```lua
self._connections = {}

function BaseComponent:Connect(signal: RBXScriptSignal, callback: (...any) -> ())
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function BaseComponent:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    if self._frame then
        self._frame:Destroy()
    end
end
```

**Destroy Guard:**
```lua
function Window:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    -- Cleanup
end
```

---

*Convention analysis: 2026-06-11*
