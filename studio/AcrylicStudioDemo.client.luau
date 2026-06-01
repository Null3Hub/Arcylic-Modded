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

local interactionSection = controlsTab:CreateSection({
    Title = "Interaction",
    Description = "Primary demo controls grouped inside a content section.",
})

local featureEnabled = false
interactionSection:Toggle({
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

interactionSection:Slider({
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

interactionSection:Dropdown({
    Name = "Search Views",
    Options = { "Pixel Grid", "Layout Grids", "Rulers", "Slices", "Comments", "Outlines" },
    Default = { "Layout Grids", "Slices" },
    MultiSelect = true,
    Search = {
        Enabled = true,
        Placeholder = "Search Views...",
    },
    Flag = "StudioSearchViews",
    Callback = function(selected)
        print("AcrylicUI Studio views:", selected)
    end,
})

interactionSection:TextBox({
    Name = "Label",
    Default = "Studio",
    Placeholder = "Type a label...",
    Flag = "StudioLabel",
    Callback = function(text, enterPressed)
        print("AcrylicUI Studio label:", text, enterPressed)
    end,
})

interactionSection:Button({
    Name = "Show State",
    Callback = function()
        window:Notify({
            Title = "Current State",
            Description = featureEnabled and "Feature is enabled" or "Feature is disabled",
            Duration = 3,
        })
    end,
})

interactionSection:Keybind({
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

local visualSection = visualTab:CreateSection({
    Title = "Visual",
    Description = "Preview colors and resize behavior.",
})

visualSection:ColorPicker({
    Name = "Preview Color",
    Default = Color3.fromRGB(115, 170, 255),
    Flag = "StudioPreviewColor",
    Callback = function(color)
        print("AcrylicUI Studio color:", color)
    end,
})

visualSection:Paragraph({
    Title = "Resize Test",
    Content = "Drag the bottom-right handle to test resize. This Studio project is intentionally served from the mirrored studio/AcrylicUI tree.",
})

local notesSection = infoTab:CreateSection({
    Title = "Notes",
    Description = "Studio-specific testing details.",
})

notesSection:Paragraph({
    Title = "Source Mirror",
    Content = "Edit src/, then run scripts/sync-studio-source.ps1 to update studio/AcrylicUI before testing with Rojo.",
})

notesSection:Paragraph({
    Title = "Config System",
    Content = "Flags register normally, but SaveConfig and LoadConfig require executor file APIs and are not expected to save files in normal Studio.",
})
