--[[
     Version: 2.0.0
     License: MIT


    @module AcrylicUI
    @author AcrylicUI Team
    @version 2.0.0

    @example
    local AcrylicUI = require(path.to.AcrylicUI)

    local window = AcrylicUI.CreateWindow({
        Title = "My Hub",
        ToggleKey = Enum.KeyCode.RightControl
    })

    local section = window:CreateSection("Combat")
    local tab = section:CreateTab("Aimbot", "rbxassetid://10723407389")

    tab:CreateToggle({
        Name = "Enable Aimbot",
        Default = false,
        Callback = function(enabled)
            print("Aimbot:", enabled)
        end
    })
]]

local AcrylicUI = {}
AcrylicUI.__index = AcrylicUI

-- Version info
AcrylicUI.Version = "2.0.0"
AcrylicUI.Author = "Arcylic-Modded"

-- Core modules
local Window = require(script.Core.Window)

-- Constants (exposed for customization)
AcrylicUI.Colors = require(script.Constants.Colors)
AcrylicUI.Sizes = require(script.Constants.Sizes)
AcrylicUI.Fonts = require(script.Constants.Fonts)
AcrylicUI.Animation = require(script.Constants.Animation)
AcrylicUI.Defaults = require(script.Constants.Defaults)
AcrylicUI.Icons = require(script.Constants.Icons)
AcrylicUI.Layers = require(script.Constants.Layers)

-- Utilities (exposed for advanced usage)
AcrylicUI.Utils = {
    Create = require(script.Utils.Create),
    Tween = require(script.Utils.Tween),
    Draggable = require(script.Utils.Draggable),
    Device = require(script.Utils.Device),
}

--[[
    Creates a new window

    @param config WindowConfig - Configuration options
    @return Window - The created window instance

    @example
    local window = AcrylicUI.CreateWindow({
        Title = "My Hub",
        Size = { Width = 700, Height = 450 },
        ToggleKey = Enum.KeyCode.RightControl
    })
]]
function AcrylicUI.CreateWindow(config: Window.WindowConfig)
    return Window.new(config)
end

function AcrylicUI.new(title: string?, configFolder: string?)
    return Window.new({
        Title = title,
        ConfigFolder = configFolder,
    })
end

--[[
    Applies a partial theme override to all UI components.

    @param overrides table - Color overrides
    @example
    AcrylicUI:SetTheme({ Accent = Color3.fromRGB(0, 170, 255) })
]]
function AcrylicUI.SetTheme(overrides: { [string]: any })
    AcrylicUI.Colors:SetTheme(overrides)
end

--[[
    Restores all theme colors to the factory defaults.
]]
function AcrylicUI.ResetTheme()
    AcrylicUI.Colors:ResetTheme()
end

--[[
    Returns a standalone snapshot of the current theme.

    @return table - Current color values
]]
function AcrylicUI.GetTheme(): { [string]: any }
    return AcrylicUI.Colors:Snapshot()
end

--[[
    Gets library information

    @return table - Library info
]]
function AcrylicUI.GetInfo()
    return {
        Version = AcrylicUI.Version,
        Author = AcrylicUI.Author,
        Components = {
            "Window",
            "Section",
            "Tab",
            "Button",
            "Toggle",
            "Slider",
            "Dropdown",
            "Keybind",
            "ColorPicker",
            "TextBox",
            "Paragraph",
            "Notification",
        },
    }
end

return AcrylicUI
