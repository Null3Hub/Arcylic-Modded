local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AcrylicUI = require(ReplicatedStorage:WaitForChild("AcrylicUI"))

local window = AcrylicUI.new("Smoke Test", "SmokeTestConfigs")
window:SetToggleKey(Enum.KeyCode.RightControl)

local section = window:CreateSection("Smoke")
local tab = section:CreateTab("Main", "rbxassetid://10734898355")

local button = tab:CreateButton({
    Name = "Smoke Button",
    Callback = function() end,
})

local toggle = tab:CreateToggle({
    Name = "Smoke Toggle",
    Default = false,
    Flag = "SmokeToggle",
})

local slider = tab:CreateSlider({
    Name = "Smoke Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Flag = "SmokeSlider",
})

local dropdown = tab:CreateDropdown({
    Name = "Smoke Dropdown",
    Options = { "One", "Two" },
    Default = "One",
    Flag = "SmokeDropdown",
})

local keybind = tab:CreateKeybind({
    Name = "Smoke Keybind",
    Default = Enum.KeyCode.F,
    Flag = "SmokeKeybind",
})

local colorPicker = tab:CreateColorPicker({
    Name = "Smoke Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "SmokeColor",
})

local textBox = tab:CreateTextBox({
    Name = "Smoke Text",
    Default = "ok",
    Flag = "SmokeText",
})

local blockables = { button, toggle, slider, dropdown, keybind, colorPicker, textBox }

for _, component in ipairs(blockables) do
    assert(component:IsBlocked() == false, "component should start unblocked")
    component:Block("Smoke Blocked")
    assert(component:IsBlocked() == true, "component should be blocked")
    component:Unblock()
    assert(component:IsBlocked() == false, "component should unblock")
end

toggle:SetValue(true)
assert(toggle:GetValue() == true, "toggle should turn on before block")
toggle:Block()
assert(toggle:GetValue() == false, "blocked toggle should force off")
assert(toggle:IsBlocked() == true, "toggle should remain blocked after forcing off")
toggle:Unblock()

slider:SetValue(75)
dropdown:SetValue("Two")
keybind:SetKey(Enum.KeyCode.G)
colorPicker:SetColor(Color3.fromRGB(255, 0, 0))
textBox:SetText("ready")

window:Toggle()
window:Toggle()
window:Destroy()

print("AcrylicUI smoke test passed")
