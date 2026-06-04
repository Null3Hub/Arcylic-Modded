--[[
    AcrylicUI - Config Encryption
    Simple byte-shift + Base64 obfuscation (Neverlose.cc pattern)
]]

local ConfigEncryption = {}

local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function ConfigEncryption.Base64Encode(data: string): string
    return (
        (data:gsub(".", function(x)
            local r, b2 = "", x:byte()
            for i = 8, 1, -1 do
                r = r .. (b2 % 2 ^ i - b2 % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
            if #x < 6 then
                return ""
            end
            local c = 0
            for i = 1, 6 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
            end
            return b:sub(c + 1, c + 1)
        end) .. ({ "", "==", "=" })[#data % 3 + 1]
    )
end

function ConfigEncryption.Base64Decode(data: string): string
    data = string.gsub(data, "[^" .. b .. "=]", "")
    return (
        data:gsub(".", function(x)
            if x == "=" then
                return ""
            end
            local r, f = "", (b:find(x) - 1)
            for i = 6, 1, -1 do
                r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return r
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then
                return ""
            end
            local c = 0
            for i = 1, 8 do
                c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
            end
            return string.char(c)
        end)
    )
end

function ConfigEncryption.Encrypt(data: string): string
    local bytes = {}
    local encrypt_seed = ((#data + 3782) % 111) + 1

    _ = string.gsub(data, ".", function(dt)
        table.insert(bytes, tostring(dt:byte() + encrypt_seed))
    end)

    local concatbyte = table.concat(bytes, "?")
    table.clear(bytes)

    return "{" .. tostring(encrypt_seed + 72667) .. "}?" .. concatbyte
end

function ConfigEncryption.Decrypt(data: string): string
    local main_data = string.split(data, "?")
    local seed_str = main_data[1]:gsub("{", ""):gsub("}", "")
    local seed = tonumber(seed_str)

    local ks = {}
    local real_seed = seed - 72667

    for i, v in next, main_data do
        if i > 1 then
            local fake_byte = tonumber(v)
            table.insert(ks, string.char(fake_byte - real_seed))
        end
    end

    local result = table.concat(ks)
    table.clear(ks)

    return result
end

return ConfigEncryption
