--[[
    Acrylic UI Library
    Theme Configuration - Color schemes and styling

    @author Acrylic Team
    @version 2.0.0
    @license MIT
]]

local Colors = require(script.Parent.Parent.Constants.Colors)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Theme = {}

--- Compatibility wrapper. Constants.Colors is the canonical theme source.
Theme.Colors = Colors

--- Font configurations
Theme.Fonts = Fonts

--- Text size presets
Theme.TextSize = Fonts.Size

--[=[
    Updates the theme colors

    @param newColors Partial<ThemeColors> -- Colors to override
]=]
function Theme:SetColors(newColors: { [string]: any })
    for key, value in pairs(newColors) do
        if type(value) == "table" then
            for subKey, subValue in pairs(value) do
                self.Colors[key][subKey] = subValue
            end
        else
            self.Colors[key] = value
        end
    end
end

--[=[
    Sets the accent color

    @param color Color3 -- The new accent color
]=]
function Theme:SetAccent(color: Color3)
    self.Colors.Accent = color
end

return Theme
