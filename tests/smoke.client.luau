local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AcrylicUI = require(ReplicatedStorage:WaitForChild("AcrylicUI"))

assert(AcrylicUI.Defaults.Window.Title == "AcrylicUI", "Defaults should expose window title")
assert(AcrylicUI.Defaults.Config.Root == "AcrylicConfigs", "Defaults should expose config root")
assert(
    AcrylicUI.Icons.Window.Close == "rbxassetid://119943770201674",
    "Icons should expose window close asset"
)
assert(AcrylicUI.Layers.Blocker.Overlay == 1000, "Layers should expose blocker overlay ZIndex")
assert(AcrylicUI.Layers.Window.PopupLayer == 900, "Layers should expose window popup layer ZIndex")
assert(AcrylicUI.Layers.Window.TopBarDragArea == 5, "Layers should expose topbar drag area ZIndex")
assert(
    AcrylicUI.Icons.Components.DropdownSelected == "rbxassetid://16898669433",
    "Icons should expose dropdown selected asset"
)
assert(
    AcrylicUI.Icons.Components.DropdownSearch == "rbxassetid://16898734242",
    "Icons should expose dropdown search asset"
)
assert(
    AcrylicUI.Sizes.WindowChrome.HeaderHeight == 45,
    "Sizes should expose window chrome geometry"
)
assert(
    AcrylicUI.Sizes.WindowChrome.TopBarControlsWidth == 80,
    "Sizes should expose topbar controls width"
)
assert(AcrylicUI.Sizes.Dropdown.SearchHeight == 34, "Sizes should expose dropdown search geometry")

local window = AcrylicUI.new("Smoke Test", "SmokeTestConfigs")
window:SetToggleKey(Enum.KeyCode.RightControl)

local section = window:CreateSection("Smoke")
local tab = section:CreateTab("Main", "rbxassetid://10734898355")

-- ContentSection handler via Tab
local contentSection = tab:CreateSection({
    Title = "Smoke Section",
    Description = "Smoke section description",
})
assert(
    contentSection ~= nil and type(contentSection.Button) == "function",
    "CreateSection should return a ContentSection handler"
)
local contentButton = contentSection:Button({
    Name = "Smoke Content Button",
    Callback = function() end,
})
assert(contentButton ~= nil, "ContentSection:Button should return a component")

local button = tab:Button({
    Name = "Smoke Button",
    Callback = function() end,
})

local toggle = tab:Toggle({
    Name = "Smoke Toggle",
    Default = false,
    Flag = "SmokeToggle",
})

local slider = tab:Slider({
    Name = "Smoke Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Flag = "SmokeSlider",
})

local lowClampedSlider = tab:Slider({
    Name = "Low Clamp Slider",
    Min = 10,
    Max = 20,
    Default = 5,
})
assert(lowClampedSlider:GetValue() == 10, "slider default below min should clamp to min")

local highClampedSlider = tab:Slider({
    Name = "High Clamp Slider",
    Min = 10,
    Max = 20,
    Default = 25,
})
assert(highClampedSlider:GetValue() == 20, "slider default above max should clamp to max")

local reversedRangeSlider = tab:Slider({
    Name = "Reversed Range Slider",
    Min = 100,
    Max = 0,
    Default = 75,
})
assert(reversedRangeSlider:GetValue() == 75, "slider should normalize reversed min/max")

local invalidIncrementSlider = tab:Slider({
    Name = "Invalid Increment Slider",
    Min = 0,
    Max = 10,
    Default = 4.2,
    Increment = 0,
})
assert(invalidIncrementSlider:GetValue() == 4, "invalid increment should fall back to 1")
invalidIncrementSlider:SetValue(8.6)
assert(invalidIncrementSlider:GetValue() == 9, "SetValue should snap using sanitized increment")

local dropdown = tab:Dropdown({
    Name = "Smoke Dropdown",
    Options = { "One", "Two" },
    Default = "One",
    Search = true,
    Flag = "SmokeDropdown",
})
assert(dropdown._searchEnabled == true, "Dropdown search should be enabled when Search = true")
assert(
    type(dropdown._searchInput) == "Instance" or dropdown._searchInput == nil,
    "Dropdown search input should be initialized on open"
)

local dropdownConfigSearch = tab:Dropdown({
    Name = "Smoke Dropdown Config",
    Options = { "Alpha", "Beta" },
    Default = "Alpha",
    Search = { Placeholder = "Find option..." },
})
assert(
    dropdownConfigSearch._searchEnabled == true,
    "Dropdown search should be enabled with table config"
)
assert(
    dropdownConfigSearch._searchPlaceholder == "Find option...",
    "Dropdown search placeholder should match config"
)

local keybind = tab:Keybind({
    Name = "Smoke Keybind",
    Default = Enum.KeyCode.F,
    Flag = "SmokeKeybind",
})

local colorPicker = tab:ColorPicker({
    Name = "Smoke Color",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "SmokeColor",
})

local textBox = tab:TextBox({
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
assert(window:GetPopupLayer() ~= nil, "Window should expose popup layer")
assert(window:GetSectionsContainer() ~= nil, "Window should expose sections container")
assert(window:GetContentContainer() ~= nil, "Window should expose content container")
window:Destroy()

print("AcrylicUI smoke test passed")
