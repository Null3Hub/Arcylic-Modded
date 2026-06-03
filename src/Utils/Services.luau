--[[
    Acrylic UI Library
    Services Module - Centralized service management

    @author Acrylic Team
    @version 2.0.0
    @license MIT
]]

local cloneref = cloneref or function(s) return s end
local ProtectGui = protect_gui or protectgui or (syn and syn.protect_gui) or function(s) return s end

local Services = {
    TweenService = cloneref(game:GetService("TweenService")),
    UserInputService = cloneref(game:GetService("UserInputService")),
    Players = cloneref(game:GetService("Players")),
    Lighting = cloneref(game:GetService("Lighting")),
    RunService = cloneref(game:GetService("RunService")),
    GuiService = cloneref(game:GetService("GuiService")),
    HttpService = cloneref(game:GetService("HttpService")),
    TextService = cloneref(game:GetService("TextService")),
}

Services.Protection = {
    cloneref = cloneref,
    ProtectGui = ProtectGui,
}

return Services
