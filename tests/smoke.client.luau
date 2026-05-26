local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AcrylicUI = require(ReplicatedStorage:WaitForChild("AcrylicUI"))

local window = AcrylicUI.new("Smoke Test", "SmokeTestConfigs")
window:SetToggleKey(Enum.KeyCode.RightControl)

local section = window:CreateSection("Smoke")
local tab = section:CreateTab("Main", "rbxassetid://10734898355")

local toggle = tab:CreateToggle({
    Name = "Smoke Toggle",
    Default = false,
    Flag = "SmokeToggle",
})

local textBox = tab:CreateTextBox({
    Name = "Smoke Text",
    Default = "ok",
    Flag = "SmokeText",
})

toggle:SetValue(true)
textBox:SetText("ready")

window:Toggle()
window:Toggle()
window:Destroy()

print("AcrylicUI smoke test passed")
