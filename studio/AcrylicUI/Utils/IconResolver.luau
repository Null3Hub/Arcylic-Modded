--[[
    AcrylicUI - Icon Resolver

    Resolves icon values into normalized Image descriptors.

    Supported formats:
        "rbxassetid://12345"      -> pass-through asset
        12345 / "12345"           -> normalized to rbxassetid://12345
        "solar/home-bold"         -> pack path
        "solar:home-bold"         -> WindUI-compatible pack path
        "home"                    -> current default pack via IconsType

    Custom packs can be registered at runtime with AddIcons. Remote pack
    resolution is wrapped in pcall and only triggered for known PackURLs.
]]

local IconResolver = {}

export type IconValue = string | number
export type IconDescriptor = {
    Image: string,
    ImageRectOffset: Vector2?,
    ImageRectPosition: Vector2?,
    ImageRectSize: Vector2?,
    Parts: { any }?,
    Pack: string?,
    Name: string?,
}

IconResolver.PackURLs = {
    solar = "https://raw.githubusercontent.com/StyearX/Icons/main/solar/dist/Icons.lua",
    lucide = "https://raw.githubusercontent.com/StyearX/Icons/main/lucide/dist/Icons.lua",
    gravity = "https://raw.githubusercontent.com/StyearX/Icons/main/gravity/dist/Icons.lua",
    craft = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua",
    geist = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua",
    sfsymbols = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/sfsymbols/dist/Icons.lua",
}

IconResolver.IconsType = "lucide"
IconResolver.Icons = {}

local _cache: { [string]: any } = {}
local _warned: { [string]: boolean } = {}
local _customPacks: { [string]: any } = IconResolver.Icons

local ASSET_PREFIX = "rbxassetid://"

local function normalizeAssetId(value: any): string?
    if type(value) == "number" then
        return ASSET_PREFIX .. tostring(value)
    end

    if type(value) ~= "string" then
        return nil
    end

    if string.sub(value, 1, #ASSET_PREFIX) == ASSET_PREFIX then
        return value
    end

    if string.match(value, "^%d+$") then
        return ASSET_PREFIX .. value
    end

    return nil
end

local function getExecutorEnv(): { [string]: any }?
    local genv = if type(_G) == "table" then rawget(_G, "getgenv") else nil
    if type(genv) == "function" then
        local ok, env = pcall(genv)
        if ok and type(env) == "table" then
            return env
        end
    end

    if type(_G) == "table" then
        return _G
    end

    return nil
end

local function fetchUrl(url: string): string?
    local httpGet = game["HttpGet"]
    if type(httpGet) == "function" then
        local ok, body = pcall(httpGet, game, url, true)
        if ok and type(body) == "string" then
            return body
        end
    end

    local env = getExecutorEnv()
    if env then
        local request = env.request or env.http_request
        if type(request) ~= "function" and type(env.syn) == "table" then
            request = env.syn.request
        end
        if type(request) ~= "function" and type(env.http) == "table" then
            request = env.http.request
        end

        if type(request) == "function" then
            local ok, response = pcall(request, {
                Url = url,
                Method = "GET",
            })
            if ok then
                if type(response) == "table" and type(response.Body) == "string" then
                    return response.Body
                end
                if type(response) == "string" then
                    return response
                end
            end
        end
    end

    local httpService = game:GetService("HttpService")
    local ok, body = pcall(function()
        return httpService:GetAsync(url, true)
    end)
    if ok and type(body) == "string" then
        return body
    end

    return nil
end

local function findPathSeparator(icon: string): number?
    local slash = string.find(icon, "/", 1, true)
    local colon = string.find(icon, ":", 1, true)

    if slash and colon then
        return if slash < colon then slash else colon
    end

    return slash or colon
end

local function normalizeDescriptor(
    entry: any,
    pack: string?,
    name: string?,
    packData: any?
): IconDescriptor?
    local directAsset = normalizeAssetId(entry)
    if directAsset then
        return {
            Image = directAsset,
            ImageRectOffset = Vector2.zero,
            ImageRectPosition = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Parts = nil,
            Pack = pack,
            Name = name,
        }
    end

    if type(entry) ~= "table" then
        return nil
    end

    local image: string? = nil

    if packData and type(packData.Spritesheets) == "table" and entry.Image ~= nil then
        image = normalizeAssetId(packData.Spritesheets[tostring(entry.Image)])
    end

    if not image then
        image = normalizeAssetId(entry.Image)
    end
    if not image then
        return nil
    end

    local rectOffset = entry.ImageRectOffset or entry.ImageRectPosition or Vector2.zero
    local rectSize = entry.ImageRectSize or Vector2.zero

    return {
        Image = image,
        ImageRectOffset = rectOffset,
        ImageRectPosition = rectOffset,
        ImageRectSize = rectSize,
        Parts = entry.Parts,
        Pack = pack,
        Name = name,
    }
end

local function ensureCustomPack(packName: string): { [string]: any }
    local packData = _customPacks[packName]
    if type(packData) ~= "table" then
        packData = {
            Icons = {},
            Spritesheets = {},
        }
        _customPacks[packName] = packData
    end

    if type(packData.Icons) ~= "table" then
        packData.Icons = {}
    end
    if type(packData.Spritesheets) ~= "table" then
        packData.Spritesheets = {}
    end

    return packData
end

local function _loadPack(pack: string): any
    local url = IconResolver.PackURLs[pack]
    if not url then
        return nil
    end
    local body = fetchUrl(url)
    if type(body) ~= "string" then
        if not _warned[pack] then
            _warned[pack] = true
            warn(string.format("[AcrylicUI] Failed to fetch icon pack '%s'", pack))
        end
        return nil
    end
    local loadOk, chunk, loadErr = pcall(loadstring, body)
    if not loadOk then
        loadErr = chunk
        chunk = nil
    end
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

local function _lookup(packData: any, name: string): any
    if type(packData) ~= "table" then
        return nil
    end

    local direct = packData[name]
    if direct ~= nil then
        return direct
    end

    local icons = packData.Icons
    if type(icons) == "table" then
        local entry = icons[name]
        if entry ~= nil then
            return entry
        end
    end

    local spritesheets = packData.Spritesheets
    if type(spritesheets) == "table" then
        local entry = spritesheets[name]
        if entry ~= nil then
            return entry
        end
    end

    return nil
end

local function resolveFromPack(packData: any, pack: string, name: string): IconDescriptor?
    local entry = _lookup(packData, name)
    if entry == nil then
        return nil
    end

    return normalizeDescriptor(entry, pack, name, packData)
end

function IconResolver.NormalizeAssetId(icon: any): string?
    return normalizeAssetId(icon)
end

function IconResolver.IsAsset(icon: any): boolean
    if type(icon) ~= "string" then
        return false
    end

    return string.sub(icon, 1, #ASSET_PREFIX) == ASSET_PREFIX
end

function IconResolver.ParsePackPath(icon: any, defaultPack: string?)
    if icon == nil or IconResolver.IsAsset(icon) then
        return nil
    end
    if type(icon) ~= "string" then
        return nil
    end

    if icon == "" then
        return nil
    end

    local separator = findPathSeparator(icon)
    if not separator then
        return defaultPack or IconResolver.IconsType, icon
    end

    local pack = string.sub(icon, 1, separator - 1)
    local name = string.sub(icon, separator + 1)
    if pack == "" or name == "" then
        return nil
    end
    return pack, name
end

function IconResolver.AddIcons(packName: string, iconsData: { [string]: any })
    if type(packName) ~= "string" or packName == "" then
        error("AddIcons: packName must be a non-empty string", 2)
    end
    if type(iconsData) ~= "table" then
        error("AddIcons: iconsData must be a table", 2)
    end

    local packData = ensureCustomPack(packName)
    local spritesheets = iconsData.Spritesheets
    if type(spritesheets) == "table" then
        for spritesheetName, spritesheetAsset in pairs(spritesheets) do
            local normalizedAsset = normalizeAssetId(spritesheetAsset)
            if normalizedAsset then
                packData.Spritesheets[tostring(spritesheetName)] = normalizedAsset
            end
        end
    end

    local iconMap = if type(iconsData.Icons) == "table" then iconsData.Icons else iconsData

    for iconName, iconValue in pairs(iconMap) do
        if iconMap == iconsData and (iconName == "Icons" or iconName == "Spritesheets") then
            continue
        end

        local normalizedName = tostring(iconName)
        local descriptor = normalizeDescriptor(iconValue, packName, normalizedName, packData)
        if descriptor then
            packData.Icons[normalizedName] = descriptor
            packData.Spritesheets[tostring(descriptor.Image)] = descriptor.Image
        else
            warn("AddIcons: Unsupported icon data for '" .. normalizedName .. "'")
        end
    end
end

function IconResolver.SetIconsType(iconType: string)
    if type(iconType) ~= "string" or iconType == "" then
        error("SetIconsType: iconType must be a non-empty string", 2)
    end

    IconResolver.IconsType = iconType
end

function IconResolver.Resolve(icon: any, defaultPack: string?): IconDescriptor?
    local asset = normalizeAssetId(icon)
    if asset then
        return normalizeDescriptor(asset, nil, nil)
    end

    local pack, name = IconResolver.ParsePackPath(icon, defaultPack)
    if not pack then
        return nil
    end

    local customEntry = resolveFromPack(_customPacks[pack], pack, name)
    if customEntry then
        return customEntry
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

    return resolveFromPack(packData, pack, name)
end

return IconResolver
