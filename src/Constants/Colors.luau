--[[
    AcrylicUI - Color Constants

    Default theme colors for the UI library.
    Supports dark mode with acrylic/glass aesthetics.
    Provides a runtime-applicable theme system via SetTheme/ResetTheme.
]]

local function deepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function deepMerge(base, overrides)
    local result = deepCopy(base)
    for key, value in pairs(overrides) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = deepMerge(result[key], value)
        else
            result[key] = value
        end
    end
    return result
end

local Colors = {
    -- Primary colors
    Background = Color3.fromRGB(12, 12, 12),
    Secondary = Color3.fromRGB(20, 20, 20),
    Border = Color3.fromRGB(39, 39, 39),

    -- Text colors
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(93, 93, 93),
    TextFade = Color3.fromRGB(9, 9, 9),

    -- Accent color (customizable)
    Accent = Color3.fromRGB(255, 255, 255),

    -- Toggle specific colors
    Toggle = {
        Enabled = Color3.fromRGB(255, 255, 255),
        Disabled = Color3.fromRGB(32, 32, 32),
        Circle = Color3.fromRGB(20, 20, 20),
    },

    -- Notification specific colors
    Notification = {
        Background = Color3.fromRGB(11, 11, 11),
        Border = Color3.fromRGB(26, 26, 26),
        Timer = Color3.fromRGB(255, 255, 255),
    },

    -- Window control colors
    CloseHover = Color3.fromRGB(255, 100, 100),
    ResizeHandle = Color3.fromRGB(110, 110, 110),
    Scrollbar = Color3.fromRGB(60, 60, 60),
}

-- Frozen snapshot of factory defaults for ResetTheme
Colors._defaults = deepCopy(Colors)

--[[
    Applies a partial theme override to the active Colors table.
    Nested tables (Toggle, Notification) are deep-merged.

    @param overrides table - Partial color overrides
]]
function Colors:SetTheme(overrides: { [string]: any })
    if not overrides then
        return
    end

    for key, value in pairs(overrides) do
        if key == "_defaults" then
            continue
        end
        if type(value) == "table" and type(self[key]) == "table" then
            self[key] = deepMerge(self[key], value)
        else
            self[key] = value
        end
    end
end

--[[
    Restores all colors to the factory defaults captured at load time.
]]
function Colors:ResetTheme()
    for key, value in pairs(self._defaults) do
        if key == "_defaults" then
            continue
        end
        if type(value) == "table" then
            self[key] = deepCopy(value)
        else
            self[key] = value
        end
    end
end

--[[
    Returns a standalone copy of the current theme without the methods.

    @return table - Snapshot of current color values
]]
function Colors:Snapshot(): { [string]: any }
    local snapshot = {}
    for key, value in pairs(self) do
        if key == "_defaults" or type(value) == "function" then
            continue
        end
        if type(value) == "table" then
            snapshot[key] = deepCopy(value)
        else
            snapshot[key] = value
        end
    end
    return snapshot
end

return Colors
