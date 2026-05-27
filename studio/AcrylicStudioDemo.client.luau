local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

while not workspace.CurrentCamera do
    workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
end

RunService.RenderStepped:Wait()

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local previousGui = playerGui:FindFirstChild("AcrylicUI")
if previousGui then
    previousGui:Destroy()
end

for _, child in ipairs(Lighting:GetChildren()) do
    if child.Name:match("^AcrylicBlur") then
        child:Destroy()
    end
end

local camera = workspace.CurrentCamera
if camera then
    for _, child in ipairs(camera:GetChildren()) do
        if child.Name:match("^AcrylicBlur") then
            child:Destroy()
        end
    end
end

local AcrylicUI = require(ReplicatedStorage:WaitForChild("AcrylicUI"))

AcrylicUI.SetTheme({
    Accent = Color3.fromRGB(115, 170, 255),
    Toggle = {
        Enabled = Color3.fromRGB(115, 170, 255),
    },
    Notification = {
        Timer = Color3.fromRGB(115, 170, 255),
    },
})

local window = AcrylicUI.CreateWindow({
    Title = "AcrylicUI Studio Mirror",
    Size = { Width = 500, Height = 425 },
    ClampToViewport = false,
    ConfigFolder = "StudioMirrorConfigs",
    ToggleKey = Enum.KeyCode.RightControl,
})

window:Notify({
    Title = "Studio Mirror",
    Description = "Running from studio/AcrylicUI",
    Duration = 4,
})

local mainSection = window:CreateSection("Main")
local controlsTab = mainSection:CreateTab("Controls", "rbxassetid://10734898355")
local visualTab = mainSection:CreateTab("Visual", "rbxassetid://10723407389")
local infoTab = mainSection:CreateTab("Info", "rbxassetid://10709775704")

controlsTab:CreateSection("Interaction")

local featureEnabled = false
controlsTab:CreateToggle({
    Name = "Enable Feature",
    Default = false,
    Flag = "StudioFeatureEnabled",
    Callback = function(value)
        featureEnabled = value
        window:Notify({
            Title = "Toggle",
            Description = value and "Feature enabled" or "Feature disabled",
            Duration = 2,
        })
    end,
})

controlsTab:CreateSlider({
    Name = "Intensity",
    Min = 0,
    Max = 100,
    Default = 40,
    Increment = 5,
    Flag = "StudioIntensity",
    Callback = function(value)
        print("AcrylicUI Studio intensity:", value)
    end,
})

controlsTab:CreateDropdown({
    Name = "Mode",
    Options = { "Safe", "Balanced", "Fast" },
    Default = "Balanced",
    Flag = "StudioMode",
    Callback = function(selected)
        print("AcrylicUI Studio mode:", selected)
    end,
})

controlsTab:CreateTextBox({
    Name = "Label",
    Default = "Studio",
    Placeholder = "Type a label...",
    Flag = "StudioLabel",
    Callback = function(text, enterPressed)
        print("AcrylicUI Studio label:", text, enterPressed)
    end,
})

controlsTab:CreateButton({
    Name = "Show State",
    Callback = function()
        window:Notify({
            Title = "Current State",
            Description = featureEnabled and "Feature is enabled" or "Feature is disabled",
            Duration = 3,
        })
    end,
})

controlsTab:CreateKeybind({
    Name = "Notify",
    Default = Enum.KeyCode.F,
    Flag = "StudioNotifyKey",
    Callback = function()
        window:Notify({
            Title = "Keybind",
            Description = "Pressed F",
            Duration = 2,
        })
    end,
})

visualTab:CreateSection("Visual")

visualTab:CreateColorPicker({
    Name = "Preview Color",
    Default = Color3.fromRGB(115, 170, 255),
    Flag = "StudioPreviewColor",
    Callback = function(color)
        print("AcrylicUI Studio color:", color)
    end,
})

visualTab:CreateParagraph({
    Title = "Resize Test",
    Content = "Drag the bottom-right handle to test resize. This Studio project is intentionally served from the mirrored studio/AcrylicUI tree.",
})

infoTab:CreateSection("Notes")

infoTab:CreateParagraph({
    Title = "Source Mirror",
    Content = "Edit src/, then run scripts/sync-studio-source.ps1 to update studio/AcrylicUI before testing with Rojo.",
})

infoTab:CreateParagraph({
    Title = "Config System",
    Content = "Flags register normally, but SaveConfig and LoadConfig require executor file APIs and are not expected to save files in normal Studio.",
})
