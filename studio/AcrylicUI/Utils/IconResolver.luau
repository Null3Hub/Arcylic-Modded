--[[
    AcrylicUI - Icon Resolver

    Resolves icon strings into Image descriptors.

    Supported formats:
        "rbxassetid://12345"      -> pass-through asset
        "solar/home-bold"         -> fetches from a pack URL on first use
        nil / "" / unknown        -> Resolve returns nil

    Pack resolution is wrapped in pcall and only triggered when the
    input is a "pack/name" string whose pack is listed in PackURLs.
    In Studio or any environment without HttpGet/loadstring, the
    resolver returns nil and the caller is expected to fall back.
]]

local IconResolver = {}

IconResolver.PackURLs = {
    solar = "https://raw.githubusercontent.com/StyearX/Icons/main/solar/dist/Icons.lua",
    lucide = "https://raw.githubusercontent.com/StyearX/Icons/main/lucide/dist/Icons.lua",
    gravity = "https://raw.githubusercontent.com/StyearX/Icons/main/gravity/dist/Icons.lua",
}

local _cache = {}
local _warned = {}

local ASSET_PREFIX = "rbxassetid://"

function IconResolver.IsAsset(icon)
    if icon == nil or type(icon) ~= "string" then
        return false
    end
    return string.sub(icon, 1, 12) == ASSET_PREFIX
end

function IconResolver.ParsePackPath(icon)
    if icon == nil or type(icon) ~= "string" then
        return nil
    end
    if IconResolver.IsAsset(icon) then
        return nil
    end
    local slash = string.find(icon, "/", 1, true)
    if not slash then
        return nil
    end
    local pack = string.sub(icon, 1, slash - 1)
    local name = string.sub(icon, slash + 1)
    if pack == "" or name == "" then
        return nil
    end
    return pack, name
end

local function _loadPack(pack)
    local url = IconResolver.PackURLs[pack]
    if not url then
        return nil
    end
    local ok, body = pcall(function()
        return game:GetService("HttpService"):HttpGet(url, true)
    end)
    if not ok or type(body) ~= "string" then
        if not _warned[pack] then
            _warned[pack] = true
            warn(string.format("[AcrylicUI] Failed to fetch icon pack '%s'", pack))
        end
        return nil
    end
    local chunk, loadErr = loadstring(body)
    if type(chunk) ~= "function" then
        if not _warned[pack] then
            _warned[pack] = true
            warn(
                string.format(
                    "[AcrylicUI] Failed to load icon pack '%s': %s",
                    pack,
                    tostring(loadErr)
                )
            )
        end
        return nil
    end
    local dataOk, data = pcall(chunk)
    if not dataOk or type(data) ~= "table" then
        if not _warned[pack] then
            _warned[pack] = true
            warn(string.format("[AcrylicUI] Icon pack '%s' did not return a table", pack))
        end
        return nil
    end
    return data
end

local function _lookup(packData, name)
    if type(packData) ~= "table" then
        return nil
    end
    local direct = packData[name]
    if direct ~= nil then
        return direct
    end
    local sprites = packData.Spritesheets
    if type(sprites) == "table" then
        local entry = sprites[name]
        if entry ~= nil then
            return entry
        end
    end
    return nil
end

function IconResolver.Resolve(icon)
    if icon == nil or type(icon) ~= "string" then
        return nil
    end
    if IconResolver.IsAsset(icon) then
        return { Image = icon }
    end
    local pack, name = IconResolver.ParsePackPath(icon)
    if not pack then
        return nil
    end
    if not IconResolver.PackURLs[pack] then
        return nil
    end
    if _cache[pack] == false then
        return nil
    end
    local packData = _cache[pack]
    if packData == nil then
        packData = _loadPack(pack)
        if packData == nil then
            _cache[pack] = false
            return nil
        end
        _cache[pack] = packData
    end
    local entry = _lookup(packData, name)
    if entry == nil then
        return nil
    end
    if type(entry) == "string" then
        return { Image = entry }
    end
    if type(entry) == "table" and entry.Image ~= nil then
        return entry
    end
    return nil
end

return IconResolver
