# Arcylic-Modded

Arcylic-Modded is a Roblox UI library based on AcrylicUI. It provides a draggable acrylic-style window, sidebar sections, tabs, interactive components, notifications, config profiles, theme helpers, and icon pack support.

## Usage

### ModuleScript

Place the library as `ReplicatedStorage.AcrylicUI` and require it from a LocalScript.

```lua
local Library = require(game.ReplicatedStorage:WaitForChild("AcrylicUI"))

local window = Library.new("My Hub", "MyHubConfigs")
window:SetToggleKey(Enum.KeyCode.RightControl)
```

### Executor

Executor environments can use the bundled `src.lua.txt` distribution when `loadstring` is available. Review or pin the source you load for your own project instead of depending blindly on a moving branch.

## Library API

### `Library.new(title, configFolder)`

Creates a window with a title and optional config folder.

```lua
local window = Library.new("My Hub", "MyHubConfigs")
```

### `Library.CreateWindow(config)`

Creates a window with table-based options.

```lua
local window = Library.CreateWindow({
    Title = "My Hub",
    ConfigFolder = "MyHubConfigs",
    Size = { Width = 560, Height = 460 },
    ToggleKey = Enum.KeyCode.RightControl,
    ClampToViewport = true,
})
```

### Theme and metadata

- `Library.SetTheme(overrides)` applies partial theme overrides.
- `Library.ResetTheme()` restores default theme colors.
- `Library.GetTheme()` returns a snapshot of the current theme.
- `Library.GetInfo()` returns version, author, and component names.
- `Library.AddIcons(packName, iconsData)` registers a local custom icon pack.
- `Library.SetIconsType(iconType)` changes the default pack used by bare icon names.

## Window

Window methods:

- `window:SetToggleKey(keyCode)` changes the key used to show or hide the UI.
- `window:Toggle()` toggles visibility.
- `window:Notify(config)` shows a notification.
- `window:CreateSection(name)` creates a sidebar section.
- `window:Destroy()` destroys the UI and disconnects resources.
- `window:SaveConfig(configName)` saves flagged component values.
- `window:LoadConfig(configName)` loads flagged component values.
- `window:DeleteConfig(configName)` deletes a config profile.
- `window:GetConfigs()` returns available config profile names.
- `window:SetAutoSave(enabled)` enables periodic saving.
- `window:SetAutoLoad(enabled)` stores whether the last config should auto-load.
- `window:GetAutoLoad()` returns the auto-load state.
- `window:ApplyAutoLoad()` loads the stored auto-load profile when available.

```lua
window:Notify({
    Title = "Loaded",
    Description = "Press RightControl to toggle the UI.",
    Duration = 3,
    Icon = "rbxassetid://10709775704",
})
```

`Destroy()` is the cleanup API. It stops auto-save, destroys sections and components, disconnects window connections, clears keybind/config registries, removes notifications, and releases the screen GUI when appropriate.

## UI Elements

### Sections and Tabs

Sections group tabs in the sidebar.

```lua
local mainSection = window:CreateSection("Main")
local combatTab = mainSection:CreateTab("Combat", "solar/crosshair-minimalistic")
```

Tabs and content sections can create the same interactive elements. Use `tab:CreateSection(config)` to group controls with an optional description.

```lua
local controls = combatTab:CreateSection({
    Title = "Controls",
    Description = "Core combat settings.",
})
```

### Button

Runs a callback when clicked. Supports text, description, icon, callback replacement, and blocking.

```lua
local button = controls:Button({
    Name = "Run Action",
    Description = "Runs the configured action.",
    Icon = "lucide:play",
    Callback = function() end,
})

button:SetText("Updated Action")
button:SetIcon("rbxassetid://10747384394")
button:SetCallback(function() end)
```

### Toggle

Stores a boolean value. Supports config flags, callbacks, programmatic value changes, and blocking.

```lua
local toggle = controls:Toggle({
    Name = "Auto Farm",
    Description = "Saved when Flag is set.",
    Default = false,
    Flag = "AutoFarm",
    Callback = function(enabled) end,
})

toggle:SetValue(true)
print(toggle:GetValue())
```

Blocking a toggle turns it off when it is currently enabled.

### Slider

Stores a numeric value with min, max, and optional increment.

```lua
local slider = controls:Slider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    Flag = "Speed",
    Callback = function(value) end,
})

slider:SetValue(75)
slider:SetMin(10)
slider:SetMax(150)
print(slider:GetValue())
```

### Dropdown

Stores a single value or multiple selected values. Search can be enabled with `true`, a placeholder string, or a table.

```lua
local dropdown = controls:Dropdown({
    Name = "Target",
    Options = { "Closest", "Lowest HP", "Highest Threat" },
    Default = "Closest",
    Search = true,
    Flag = "Target",
    Callback = function(selected) end,
})

dropdown:SetValue("Lowest HP")
dropdown:Refresh({ "Closest", "Random" })
print(dropdown:GetValue())
```

Multi-select:

```lua
local multi = controls:Dropdown({
    Name = "Weapons",
    Options = { "Sword", "Bow", "Magic" },
    Default = { "Sword" },
    MultiSelect = true,
})
```

### Keybind

Stores an `Enum.KeyCode` and runs a callback when the key is pressed.

```lua
local keybind = controls:Keybind({
    Name = "Fly",
    Default = Enum.KeyCode.F,
    Flag = "FlyKey",
    Callback = function() end,
})

keybind:SetKey(Enum.KeyCode.G)
print(keybind:GetKey())
```

### ColorPicker

Stores a `Color3` value and supports config flags.

```lua
local picker = controls:ColorPicker({
    Name = "Accent",
    Default = Color3.fromRGB(90, 170, 255),
    Flag = "AccentColor",
    Callback = function(color) end,
})

picker:SetColor(Color3.fromRGB(255, 120, 80))
print(picker:GetColor())
```

### TextBox

Stores text input. Supports placeholder text, `ClearOnFocus`, numeric-only mode, focus control, and config flags.

```lua
local box = controls:TextBox({
    Name = "Player Name",
    Default = "",
    Placeholder = "Enter name...",
    ClearOnFocus = false,
    NumbersOnly = false,
    Flag = "PlayerName",
    Callback = function(text, enterPressed) end,
})

box:SetText("ExamplePlayer")
box:SetPlaceholder("New placeholder...")
box:Focus()
print(box:GetText())
```

### Paragraph

Displays read-only text.

```lua
local paragraph = controls:Paragraph({
    Title = "Info",
    Content = "Status text.",
})

paragraph:SetTitle("Updated Info")
paragraph:SetContent("Updated content.")
```

### Config Section

Creates a built-in config manager with name input, config selector, save, load, delete, refresh, auto-save, and auto-load controls.

```lua
local settings = window:CreateSection("Settings")
local configTab = settings:CreateTab("Config", "rbxassetid://10723356507")
local configSection = configTab:CreateConfigSection()

configSection.RefreshConfigs()
```

### Blocking API

Most interactive components support:

- `component:Block(text)` blocks user input and shows an overlay.
- `component:Unblock()` restores user input.
- `component:IsBlocked()` returns the current blocked state.

Programmatic setters such as `SetValue`, `SetText`, `SetColor`, and `SetKey` continue to work while blocked.

## Config System

Add `Flag` to components that should be saved.

```lua
controls:Toggle({
    Name = "Enabled",
    Default = false,
    Flag = "Enabled",
})

window:SaveConfig("Default")
window:LoadConfig("Default")
window:SetAutoSave(true)
window:SetAutoLoad(true)
```

Config files are stored under `AcrylicConfigs/<configFolder>/` in executor environments that expose file APIs. Saved configs are obfuscated by the built-in config encryption helper. Legacy plain JSON configs are still accepted and migrated after a successful load.

## Icons

Icon arguments accept:

- `rbxassetid://12345`
- `12345` or `"12345"`
- Pack paths such as `solar/home-bold`, `lucide/play`, or `gravity/...`
- WindUI-style pack paths such as `solar:home-bold`
- Bare names resolved through the current default pack
- Custom packs registered with `Library.AddIcons(...)`

```lua
Library.SetIconsType("lucide")

local tab = mainSection:CreateTab("Combat", "solar:crosshair-minimalistic")

controls:Button({
    Name = "Run",
    Icon = "lucide:play",
    Callback = function() end,
})
```

Custom packs:

```lua
Library.AddIcons("custom", {
    shield = {
        Image = "rbxassetid://1000000000",
        ImageRectSize = Vector2.new(32, 32),
        ImageRectPosition = Vector2.new(0, 0),
        Parts = { "shield-shine" },
    },
    ["shield-shine"] = "rbxassetid://1000000001",
})

local tab = mainSection:CreateTab("Defense", "custom:shield")
```

Remote pack names are resolved through the icon resolver with HTTP and `loadstring` when the environment supports it. Use direct asset IDs or `Library.AddIcons(...)` when you need fully controlled icon data.

## Exemple

See [`Exemple.lua`](Exemple.lua) in the repository root for a complete executor example. It demonstrates window creation, sections, tabs, every UI element, descriptions, config save/load, auto-save, auto-load, theme APIs, notifications, icon packs, custom icons, and runtime block/unblock methods.

`Exemple.lua` is intended for executor environments. Studio and published Roblox experiences should use the ModuleScript `require(...)` setup.

## License

MIT License.

## Credits and Author

noowtf31-ui

v0rtexd
