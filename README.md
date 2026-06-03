# Arcylic-Modded
A stabilized, toolchain-backed modded build of AcrylicUI for Roblox, with acrylic blur effects, smooth animations, config support, and generated loadstring output.

## Highlights
-  **Modern Design** - Acrylic blur backdrop with smooth animations
-  **Mobile Support** - Built-in draggable mobile toggle button for touch devices
-  **Drag & Resize** - Fully draggable topbar and window with smart resizing
-  **Notifications** - Beautiful notification system with icons and timers
-  **Components** - Button, Toggle, Slider, Dropdown (with search), Keybind, ColorPicker, TextBox, Paragraph
-  **Content Sections** - Grouped content areas with header, description, and separator inside tabs
-  **Icon Packs** - Drop in `solar/home-bold`, `lucide/arrow`, `gravity/...` style names; raw `rbxassetid://...` also works
-  **Customizable** - Theme colors, sizes, fonts, and animation speeds
-  **Keybind System** - Custom keybinds with listener support
-  **Sections & Tabs** - Organized layout with collapsible sections
-  **Config System** - Save, load, and manage configuration profiles with auto-save support
-  **Native Stealth** - UI instances use null names and the main ScreenGui targets CoreGui when available

## Installation

### Method 1: Executor / Loadstring

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null3Hub/Arcylic-Modded/refs/heads/main/src.lua.txt"))()
```

### Method 2: Roblox Studio / Rojo (ModuleScript)
> For Studio, Rojo sync, or published games without an executor.

**Option A:** Drop the library folder into your project as a ModuleScript (e.g. under `ReplicatedStorage`) and require it:
```lua
local Library = require(game.ReplicatedStorage:WaitForChild("AcrylicUI"))
```

**Option B:** Use Rojo with the included project files:
```bash
rojo serve default.project.json   # syncs src/ into ReplicatedStorage.AcrylicUI
```
Then require from a LocalScript:
```lua
local Library = require(game.ReplicatedStorage:WaitForChild("AcrylicUI"))
```

> **Note:** `loadstring` is only available in executor environments. In Studio or published games, always use `require`.

## Source & Build

`src/` is the source of truth. The loadstring file `src.lua.txt` is generated from the modular source and should not be edited manually.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build-bundle.ps1
powershell -ExecutionPolicy Bypass -File scripts/validate-bundle.ps1
```

Project tooling is included for Rojo, Aftman, Wally, StyLua, and Selene.

## Quick Start

### Executor / Loadstring
```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null3Hub/Arcylic-Modded/refs/heads/main/src.lua.txt"))()

local window = Library.new("My Hub", "MyHubConfigs")
window:SetToggleKey(Enum.KeyCode.RightControl)

window:Notify({
    Title = "Welcome!",
    Description = "Hub loaded successfully",
    Duration = 3,
    Icon = "rbxassetid://10709775704"
})
```

### Studio / Rojo (require)
```lua
local Library = require(game.ReplicatedStorage:WaitForChild("AcrylicUI"))

local window = Library.new("My Hub", "MyHubConfigs")
window:SetToggleKey(Enum.KeyCode.RightControl)

window:Notify({
    Title = "Welcome!",
    Description = "Hub loaded successfully",
    Duration = 3,
    Icon = "rbxassetid://10709775704"
})
```

## API Reference

### Library

#### `Library.new(title, configFolder)`
Creates a new window instance.

```lua
local window = Library.new("My Hub", "MyHubConfigs")
```

**Parameters:**
- `title` (string): The window title
- `configFolder` (string, optional): Name for config folder (defaults to title)

**Returns:** Window object

---

### Window Methods

#### `window:SetToggleKey(keyCode)`
Sets the keybind to toggle UI visibility.

```lua
window:SetToggleKey(Enum.KeyCode.RightControl)
```

**Parameters:**
- `keyCode` (KeyCode): The key to toggle the UI

---

#### `window:Toggle()`
Manually toggles the UI visibility.

```lua
window:Toggle()
```

---

#### `window:Notify(config)`
Shows a notification.

```lua
window:Notify({
    Title = "Notification Title",
    Description = "Notification description text",
    Duration = 3,
    Icon = "rbxassetid://10709775704" -- optional
})
```

**Parameters:**
- `Title` (string): Notification title
- `Description` (string): Notification description
- `Duration` (number): Duration in seconds (default: 3)
- `Icon` (string): Optional asset ID for icon

---

#### `window:CreateSection(name)`
Creates a collapsible section in the sidebar.

```lua
local section = window:CreateSection("Combat")
```

**Parameters:**
- `name` (string): Section name

**Returns:** Section object

---

#### `window:Destroy()`
Destroys the UI and cleans up all connections. Auto-saves config if auto-save is enabled.

```lua
window:Destroy()
```

---

### Config System Methods

#### `window:SaveConfig(configName)`
Saves the current settings to a config file.

```lua
window:SaveConfig("MyConfig")
```

**Parameters:**
- `configName` (string): Name of the config file

**Returns:** Boolean (success)

---

#### `window:LoadConfig(configName)`
Loads settings from a config file.

```lua
window:LoadConfig("MyConfig")
```

**Parameters:**
- `configName` (string): Name of the config to load

**Returns:** Boolean (success)

---

#### `window:DeleteConfig(configName)`
Deletes a config file.

```lua
window:DeleteConfig("MyConfig")
```

**Parameters:**
- `configName` (string): Name of the config to delete

**Returns:** Boolean (success)

---

#### `window:GetConfigs()`
Returns a list of available config names.

```lua
local configs = window:GetConfigs()
for _, name in ipairs(configs) do
    print(name)
end
```

**Returns:** Table of config names

---

#### `window:SetAutoSave(enabled)`
Enables or disables auto-save (saves every 30 seconds).

```lua
window:SetAutoSave(true)
```

**Parameters:**
- `enabled` (boolean): Enable or disable auto-save

---

### Section Methods

#### `section:CreateTab(name, icon)`
Creates a tab within the section.

```lua
local tab = section:CreateTab("Aimbot", "rbxassetid://10723407389")
```

**Parameters:**
- `name` (string): Tab name
- `icon` (string, optional): Asset ID for tab icon

**Returns:** Tab object

---

### Tab Methods

#### `tab:CreateSection(config)`
Creates a content section within the tab. Returns a ContentSection handler.

```lua
-- String shorthand
local section = tab:CreateSection("Settings")

-- Table config with description
local section = tab:CreateSection({
    Title = "Settings",
    Description = "Adjust your settings below.",
})

-- Use the handler to add elements inside the section
local toggle = section:Toggle({
    Name = "Enable",
    Default = false,
    Callback = function(enabled) end,
})
```

**Parameters:**
- `config` (string or table): Section title string, or table with `Title` and `Description`/`Desc`

**Returns:** ContentSection handler with element methods (see [ContentSection Methods](#contentsection-methods))

---

#### `tab:Toggle(config)`
Creates a toggle switch.

```lua
local toggle = tab:Toggle({
    Name = "Enable Feature",
    Default = false,
    Flag = "FeatureEnabled", -- Optional: for config saving
    Callback = function(enabled)
        print("Toggle:", enabled)
    end
})
```

**Config:**
- `Name` (string): Toggle name
- `Default` (boolean): Initial state (default: false)
- `Flag` (string, optional): Unique identifier for config system
- `Callback` (function): Function called when toggled

**Methods:**
- `toggle:SetValue(value)` - Set toggle state
- `toggle:GetValue()` - Get current state

---

#### `tab:Slider(config)`
Creates a slider.

```lua
local slider = tab:Slider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
    Flag = "SpeedValue",
    Callback = function(value)
        print("Slider value:", value)
    end
})
```

**Config:**
- `Name` (string): Slider name
- `Min` (number): Minimum value
- `Max` (number): Maximum value
- `Default` (number): Initial value
- `Flag` (string, optional): Unique identifier for config system
- `Callback` (function): Function called when value changes

**Methods:**
- `slider:SetValue(value)` - Set slider value
- `slider:GetValue()` - Get current value

---

#### `tab:Dropdown(config)`
Creates a dropdown menu with optional search.

```lua
local dropdown = tab:Dropdown({
    Name = "Select Option",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    MultiSelect = false,
    Search = true,
    Flag = "SelectedOption",
    Callback = function(selected)
        print("Selected:", selected)
    end
})
```

**Config:**
- `Name` (string): Dropdown name
- `Options` (table): Array of option strings
- `Default` (string or table): Initial selection
- `MultiSelect` (boolean, optional): Allow multiple selections (default: false)
- `Search` (boolean, string, or table, optional): Enable search filtering. `true` for default placeholder, a string for custom placeholder, or `{ Enabled = true, Placeholder = "..." }` for full control.
- `Flag` (string, optional): Unique identifier for config system
- `Callback` (function): Function called when selection changes

**Methods:**
- `dropdown:SetValue(value)` - Set selected value(s)
- `dropdown:GetValue()` - Get current selection
- `dropdown:Refresh(newOptions)` - Update dropdown options

---

#### `tab:Keybind(config)`
Creates a keybind selector.

```lua
local keybind = tab:Keybind({
    Name = "Fly Toggle",
    Default = Enum.KeyCode.F,
    Flag = "FlyKeybind",
    Callback = function()
        print("Keybind pressed!")
    end
})
```

**Config:**
- `Name` (string): Keybind name
- `Default` (KeyCode): Initial key
- `Flag` (string, optional): Unique identifier for config system
- `Callback` (function): Function called when key is pressed

**Methods:**
- `keybind:SetKey(keyCode)` - Set keybind
- `keybind:GetKey()` - Get current key

---

#### `tab:ColorPicker(config)`
Creates a color picker.

```lua
local colorPicker = tab:ColorPicker({
    Name = "Team Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "TeamColor",
    Callback = function(color)
        print("Color:", color)
    end
})
```

**Config:**
- `Name` (string): Color picker name
- `Default` (Color3): Initial color
- `Flag` (string, optional): Unique identifier for config system
- `Callback` (function): Function called when color changes

**Methods:**
- `colorPicker:SetColor(color)` - Set color
- `colorPicker:GetColor()` - Get current color

---

#### `tab:Button(config)`
Creates a button.

```lua
local button = tab:Button({
    Name = "Click Me",
    Callback = function()
        print("Button clicked!")
    end
})
```

**Config:**
- `Name` (string): Button text
- `Callback` (function): Function called when clicked

**Methods:**
- `button:SetText(text)` - Change button text

---

#### `tab:TextBox(config)`
Creates a text input box.

```lua
local textBox = tab:TextBox({
    Name = "Player Name",
    Default = "",
    Placeholder = "Enter name...",
    ClearOnFocus = false,
    NumbersOnly = false,
    Flag = "PlayerName",
    Callback = function(text, enterPressed)
        print("Text:", text, "Enter pressed:", enterPressed)
    end
})
```

**Config:**
- `Name` (string): TextBox label
- `Default` (string): Initial text value
- `Placeholder` (string): Placeholder text when empty
- `ClearOnFocus` (boolean, optional): Clear text when focused (default: false)
- `NumbersOnly` (boolean, optional): Only allow numeric input (default: false)
- `Flag` (string, optional): Unique identifier for config system
- `Callback` (function): Function called when focus is lost (receives text and enterPressed boolean)

**Methods:**
- `textBox:SetText(text)` - Set the text value
- `textBox:GetText()` - Get current text
- `textBox:SetPlaceholder(placeholder)` - Update placeholder text
- `textBox:Focus()` - Focus the text box

---

#### `tab:Paragraph(config)`
Creates an informational text block.

```lua
local paragraph = tab:Paragraph({
    Title = "Information",
    Content = "This is some informational text that explains features or provides details."
})
```

**Config:**
- `Title` (string): Paragraph title
- `Content` (string): Paragraph content text

**Methods:**
- `paragraph:SetTitle(title)` - Update title
- `paragraph:SetContent(content)` - Update content

---

### ContentSection Methods

The ContentSection handler returned by `tab:CreateSection(config)` supports the same element methods as Tab:

- `section:Paragraph(config)` - Creates a paragraph
- `section:Button(config)` - Creates a button
- `section:Toggle(config)` - Creates a toggle
- `section:Slider(config)` - Creates a slider
- `section:Dropdown(config)` - Creates a dropdown
- `section:Keybind(config)` - Creates a keybind
- `section:ColorPicker(config)` - Creates a color picker
- `section:TextBox(config)` - Creates a text box
- `section:CreateConfigSection()` - Creates a pre-built config management UI

---

### Blocking Components

Interactive components support a shared blocking API:

```lua
local farmToggle = tab:Toggle({
    Name = "Auto Farm",
    Default = true,
    Callback = function(enabled)
        print("Farm:", enabled)
    end,
})

farmToggle:Block()
farmToggle:Block("Need level 10")
farmToggle:Unblock()
print(farmToggle:IsBlocked())
```

**Methods:**
- `component:Block(text)` - Blocks user interaction and shows a centered overlay. Text is optional and defaults to `"Blocked"`.
- `component:Unblock()` - Removes the overlay and restores normal user interaction.
- `component:IsBlocked()` - Returns whether the component is currently blocked.

Blocking prevents user input only. Programmatic setters such as `SetValue`, `SetText`, `SetColor`, and `SetKey` continue to work. `Toggle:Block()` is the only method that changes component value: if the toggle is on, it turns off and calls `Callback(false)`.

---

#### `tab:CreateConfigSection()`
Creates a pre-built configuration management UI with save, load, delete, and auto-save functionality.

```lua
local configSection = tab:CreateConfigSection()
```

**Returns:** Object with `RefreshConfigs()` method

This creates:
- Config name input box
- Config selector dropdown
- Save, Load, Delete, and Refresh buttons
- Auto-save toggle

---

## Complete Executor Example

See [`Exemple.lua`](Exemple.lua) in the repository root for a complete executor/loadstring example that demonstrates the current library features, including components, descriptions, config saving, auto-save/auto-load, theme APIs, notifications, and runtime block/unblock methods.

Use `Exemple.lua` only in executor environments. Studio and published games should continue to use the `require(...)` setup shown above.

## Features

### Acrylic Blur Effect
The library automatically creates a beautiful acrylic blur effect behind the UI using depth of field and blur effects.

### Mobile Support
If touch input is detected, a draggable mobile toggle button appears automatically in the bottom-left corner. Tap to toggle, drag to reposition.

### Resizable Window
Click and drag the resize handle in the bottom-right corner to resize the window. Size is constrained between minimum and maximum values.

### Collapsible Sections
Click section headers in the sidebar to collapse/expand tabs within that section.

### Smart Color Picker
The color picker automatically positions itself to stay on screen and closes when you click elsewhere.

### Config System
The library includes a full configuration system that allows users to:
- **Save configs** - Save all flagged component values to a JSON file
- **Load configs** - Restore saved settings
- **Delete configs** - Remove unwanted configuration files
- **Auto-save** - Automatically save every 30 seconds
- **Multiple profiles** - Create and manage multiple configuration profiles

Config files are stored in `AcrylicConfigs/<configFolder>/`, where `configFolder` is the second argument passed to `Library.new(title, configFolder)`.

#### Using the Config System

**Method 1: Pre-built Config UI**
```lua
local ConfigTab = SettingsSection:CreateTab("Config", "rbxassetid://10734898355")
ConfigTab:CreateConfigSection() -- Creates full config management UI
```

**Method 2: Manual Control**
```lua
-- Make sure to add Flag to components you want to save
AimbotTab:Toggle({
    Name = "Enable Aimbot",
    Flag = "AimbotEnabled", -- This flag is used as the save key
    Callback = function(enabled) end
})

-- Save/Load manually
window:SaveConfig("MyProfile")
window:LoadConfig("MyProfile")

-- Enable auto-save
window:SetAutoSave(true)
```

## Customization

### Sizes
Window sizes and component dimensions are pre-configured for optimal appearance.

### Animations
Animation speeds are tuned for smooth, modern feel:
- Fast: 0.1s
- Normal: 0.15s
- Slow: 0.2s
- Very Slow: 0.3s

## Icons

Any `icon` argument that takes a string accepts three forms:

1. **Raw asset** - `rbxassetid://12345`. Works everywhere, including Studio.
2. **Pack name** - `solar/home-bold`, `lucide/arrow`, `gravity/...`. Resolved at runtime against a pack URL map. Falls back to the per-component default asset if the pack is unavailable.
3. **Empty / unknown** - the ImageLabel is hidden (or uses the component's fallback asset if one is configured).

```lua
local tab = section:CreateTab("Combat", "solar/crosshair-minimalistic")

tab:Button({
    Name = "Run",
    Icon = "lucide/play",  -- resolved via IconResolver; falls back to default if pack missing
    Callback = function() end,
})
```

Pack resolution uses `game:HttpGet` + `loadstring` inside `pcall`, so:
- **Executors**: pack icons render automatically.
- **Studio / published games**: HttpGet/loadstring are unavailable, the pack silently fails, and components fall back to the bundled `rbxassetid://...` defaults (or hide if no fallback).

Common asset IDs used in examples:
- `rbxassetid://10709775704` - Checkmark/Success
- `rbxassetid://10747384394` - Warning/Error
- `rbxassetid://10723407389` - Target/Aim
- `rbxassetid://10734898355` - Settings/Gear
- `rbxassetid://10734950309` - Teleport/Location
- `rbxassetid://10723356507` - Save/Config
- `rbxassetid://93828793199781` - Text/Input
- `rbxassetid://112235310154264` - Menu

## License
MIT License - Feel free to use and modify for your projects.

## Credits and Author
noowtf31-ui
v0rtexd
