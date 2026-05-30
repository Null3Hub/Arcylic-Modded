local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AcrylicUI = require(ReplicatedStorage:WaitForChild("AcrylicUI"))

assert(AcrylicUI.Defaults.Window.Title == "AcrylicUI", "Defaults should expose window title")
assert(AcrylicUI.Defaults.Config.Root == "AcrylicConfigs", "Defaults should expose config root")
assert(
    AcrylicUI.Icons.Window.Close == "rbxassetid://119943770201674",
    "Icons should expose window close asset"
)
assert(AcrylicUI.Layers.Blocker.Overlay == 1000, "Layers should expose blocker overlay ZIndex")
assert(
    AcrylicUI.Sizes.WindowChrome.HeaderHeight == 45,
    "Sizes should expose window chrome geometry"
)

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

local lowClampedSlider = tab:CreateSlider({
    Name = "Low Clamp Slider",
    Min = 10,
    Max = 20,
    Default = 5,
})
assert(lowClampedSlider:GetValue() == 10, "slider default below min should clamp to min")

local highClampedSlider = tab:CreateSlider({
    Name = "High Clamp Slider",
    Min = 10,
    Max = 20,
    Default = 25,
})
assert(highClampedSlider:GetValue() == 20, "slider default above max should clamp to max")

local reversedRangeSlider = tab:CreateSlider({
    Name = "Reversed Range Slider",
    Min = 100,
    Max = 0,
    Default = 75,
})
assert(reversedRangeSlider:GetValue() == 75, "slider should normalize reversed min/max")

local invalidIncrementSlider = tab:CreateSlider({
    Name = "Invalid Increment Slider",
    Min = 0,
    Max = 10,
    Default = 4.2,
    Increment = 0,
})
assert(invalidIncrementSlider:GetValue() == 4, "invalid increment should fall back to 1")
invalidIncrementSlider:SetValue(8.6)
assert(invalidIncrementSlider:GetValue() == 9, "SetValue should snap using sanitized increment")

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
