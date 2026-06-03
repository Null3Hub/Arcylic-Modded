--[[
    AcrylicUI - Random String Generator
    Generates random strings with control characters for anti-detection
]]

local RandomString = {}

function RandomString.new(length: number?): string
    length = length or 30
    local chars = {}
    for i = 1, length do
        chars[i] = string.char(math.random(1, 7))
    end
    return table.concat(chars)
end

return RandomString