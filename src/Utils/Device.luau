--[[
    AcrylicUI - Device Detection Utility

    Detects device type and capabilities.
]]

local Services = require(script.Parent.Services)
local Defaults = require(script.Parent.Parent.Constants.Defaults)

local Device = {}
local DeviceDefaults = Defaults.Device or {}
local DEFAULT_VIEWPORT = DeviceDefaults.DefaultViewport or Vector2.new(1280, 720)

--[[
    Checks if the current device is mobile (touch only)

    @return boolean - True if mobile device
]]
function Device.IsMobile(): boolean
    return Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled
end

--[[
    Checks if the current device is a tablet

    @return boolean - True if tablet device
]]
function Device.IsTablet(): boolean
    local viewport = Device.GetViewportSize()
    return Device.IsMobile()
        and math.min(viewport.X, viewport.Y) >= (DeviceDefaults.TabletMinShortSide or 600)
end

--[[
    Checks if the current device is a console

    @return boolean - True if console device
]]
function Device.IsConsole(): boolean
    return Services.UserInputService.GamepadEnabled
        and not Services.UserInputService.KeyboardEnabled
        and not Services.UserInputService.TouchEnabled
end

--[[
    Checks if the current device is desktop

    @return boolean - True if desktop device
]]
function Device.IsDesktop(): boolean
    return Services.UserInputService.KeyboardEnabled and Services.UserInputService.MouseEnabled
end

--[[
    Gets the safe area insets (for notched devices)

    @return { Top: number, Bottom: number, Left: number, Right: number }
]]
function Device.GetSafeAreaInsets(): { Top: number, Bottom: number, Left: number, Right: number }
    local insets = Services.GuiService:GetGuiInset()
    return {
        Top = insets.Y,
        Bottom = DeviceDefaults.SafeAreaBottom or 0,
        Left = DeviceDefaults.SafeAreaLeft or 0,
        Right = DeviceDefaults.SafeAreaRight or 0,
    }
end

--[[
    Gets the current viewport size

    @return Vector2 - Viewport dimensions
]]
function Device.GetViewportSize(): Vector2
    local camera = workspace.CurrentCamera
    if not camera then
        return DEFAULT_VIEWPORT
    end

    return camera.ViewportSize
end

return Device
