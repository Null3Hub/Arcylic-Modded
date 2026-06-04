--[[
    Acrylic UI Library
    Services Module - Centralized service management

    @author Acrylic Team
    @version 2.0.0
    @license MIT
]]

local function safeGet(name: string): any?
    local sources = {}

    if type(_G) == "table" then
        local getgenv = rawget(_G, "getgenv")
        if type(getgenv) == "function" then
            local ok, env = pcall(getgenv)
            if ok and type(env) == "table" then
                table.insert(sources, env)
            end
        end
    end

    local ok, env = pcall(function()
        if type(getfenv) == "function" then
            return getfenv()
        end
        return nil
    end)
    if ok and type(env) == "table" then
        table.insert(sources, env)
    end

    table.insert(sources, _G)

    for _, source in ipairs(sources) do
        if type(source) == "table" then
            local value = rawget(source, name)
            if value ~= nil then
                return value
            end
        end
    end

    return nil
end

local cloneref = safeGet("cloneref")
if type(cloneref) ~= "function" then
    cloneref = function(s)
        return s
    end
end

-- Executor GUI protection fallback order: protect_gui or protectgui or syn.protect_gui.
local ProtectGui = safeGet("protect_gui") or safeGet("protectgui")
local synEnv = safeGet("syn")
if type(ProtectGui) ~= "function" and type(synEnv) == "table" then
    ProtectGui = synEnv.protect_gui
end
if type(ProtectGui) ~= "function" then
    ProtectGui = function(s)
        return s
    end
end

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
