--[[
    AcrylicUI - Font Constants

    Typography settings for consistent text rendering.
]]

local Fonts = {
    -- Font families
    Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),

    Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),

    Light = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),

    Medium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),

    -- Text sizes
    Size = {
        Title = 14,
        Normal = 14,
        Small = 13,
        Section = 15,
        Tiny = 11,
    },
}

return Fonts
