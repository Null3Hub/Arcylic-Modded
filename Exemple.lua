--[[
    Arcylic-Modded executor example

    This file is intended for executor/loadstring usage only.
    For Roblox Studio or published games, use require(...) instead of loadstring.
]]

local LIBRARY_URL = "https://raw.githubusercontent.com/Null3Hub/Arcylic-Modded/refs/heads/main/src.lua.txt"

local Library = loadstring(game["HttpGet"](game, LIBRARY_URL))()
local Players = game:GetService("Players")

local function joinValues(values)
	if type(values) ~= "table" then
		return tostring(values)
	end

	local parts = {}
	for _, value in ipairs(values) do
		table.insert(parts, tostring(value))
	end

	return table.concat(parts, ", ")
end

local function getHumanoid()
	local player = Players.LocalPlayer
	local character = player and player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

Library.ResetTheme()
Library.SetTheme({
	Accent = Color3.fromRGB(90, 170, 255),
	Toggle = {
		Enabled = Color3.fromRGB(90, 170, 255),
	},
	Notification = {
		Timer = Color3.fromRGB(90, 170, 255),
	},
})

local libraryInfo = Library.GetInfo()
local themeSnapshot = Library.GetTheme()

local window = Library.CreateWindow({
	Title = "Arcylic Executor Example",
	ConfigFolder = "ArcylicExecutorExample",
	Size = { Width = 560, Height = 460 },
	ToggleKey = Enum.KeyCode.RightControl,
	ClampToViewport = true,
})

window:Notify({
	Title = "Arcylic Loaded",
	Description = "Press RightControl to toggle the UI.",
	Duration = 4,
	Icon = "rbxassetid://10709775704",
})

local combatSection = window:CreateSection("Combat")
local playerSection = window:CreateSection("Player")
local uiSection = window:CreateSection("UI")
local settingsSection = window:CreateSection("Settings")

local combatTab = combatSection:CreateTab("Combat", "solar/crosshair-minimalistic")
local actionsSection = combatTab:CreateSection({
	Title = "Actions",
	Description = "Core combat actions and configuration.",
})

local autoFarmEnabled = false
local autoFarmToggle = combatTab:Toggle({
	Name = "Auto Farm",
	Description = "Toggle with config saving and runtime blocking support.",
	Default = false,
	Flag = "AutoFarm",
	Callback = function(enabled)
		autoFarmEnabled = enabled
		window:Notify({
			Title = enabled and "Auto Farm Enabled" or "Auto Farm Disabled",
			Description = "Current value: " .. tostring(autoFarmEnabled),
			Duration = 2,
		})
	end,
})

local actionButton = combatTab:Button({
	Name = "Run Action",
	Desc = "Button with SetText, SetIcon, SetCallback, Block, and Unblock support.",
	Icon = "rbxassetid://10709775704",
	Callback = function()
		window:Notify({
			Title = "Action",
			Description = "Button callback fired.",
			Duration = 2,
		})
	end,
})

local damageSlider = combatTab:Slider({
	Name = "Damage Multiplier",
	Description = "Slider with min, max, increment, callbacks, and config flag.",
	Min = 1,
	Max = 10,
	Default = 3,
	Increment = 1,
	Flag = "DamageMultiplier",
	Callback = function(value)
		print("Damage multiplier:", value)
	end,
})

local targetDropdown = combatTab:Dropdown({
	Name = "Target Priority",
	Description = "Single-select dropdown with search enabled.",
	Options = { "Closest", "Lowest HP", "Highest Threat" },
	Default = "Closest",
	Search = true,
	Flag = "TargetPriority",
	Callback = function(selected)
		print("Target priority:", selected)
	end,
})

local weaponsDropdown = combatTab:Dropdown({
	Name = "Allowed Weapons",
	Desc = "Multi-select dropdown using a table value.",
	Options = { "Sword", "Bow", "Magic", "Melee" },
	Default = { "Sword", "Bow" },
	MultiSelect = true,
	Flag = "AllowedWeapons",
	Callback = function(selected)
		print("Allowed weapons:", joinValues(selected))
	end,
})

local movementTab = playerSection:CreateTab("Movement", "rbxassetid://10734898355")
local movementControls = movementTab:CreateSection({
	Title = "Movement Controls",
	Description = "Speed, flight, and teleport settings.",
})

local walkSpeedSlider = movementTab:Slider({
	Name = "Walk Speed",
	Description = "Applies to the local Humanoid when available.",
	Min = 16,
	Max = 200,
	Default = 16,
	Increment = 1,
	Flag = "WalkSpeed",
	Callback = function(value)
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end,
})

local flyKeybind = movementTab:Keybind({
	Name = "Fly Toggle",
	Description = "Keybind selector and global key callback.",
	Default = Enum.KeyCode.F,
	Flag = "FlyKeybind",
	Callback = function()
		window:Notify({
			Title = "Keybind",
			Description = "Fly keybind callback fired.",
			Duration = 2,
		})
	end,
})

local teleportBox = movementTab:TextBox({
	Name = "Teleport Target",
	Desc = "TextBox with placeholder, SetText, GetText, and Focus support.",
	Default = "",
	Placeholder = "Player name...",
	ClearOnFocus = false,
	Flag = "TeleportTarget",
	Callback = function(text, enterPressed)
		if enterPressed and text ~= "" then
			window:Notify({
				Title = "Teleport",
				Description = "Requested target: " .. text,
				Duration = 2,
			})
		end
	end,
})

local appearanceTab = uiSection:CreateTab("Appearance", "rbxassetid://10734898355")
local themeSection = appearanceTab:CreateSection({
	Title = "Theme and Text",
	Description = "Customize accent colors and display text.",
})

local accentPicker = appearanceTab:ColorPicker({
	Name = "Accent Color",
	Description = "ColorPicker plus SetTheme example.",
	Default = themeSnapshot.Accent,
	Flag = "AccentColor",
	Callback = function(color)
		Library.SetTheme({
			Accent = color,
			Toggle = {
				Enabled = color,
			},
			Notification = {
				Timer = color,
			},
		})
		print("Accent changed:", color)
	end,
})

local statusBox = appearanceTab:TextBox({
	Name = "Status Message",
	Description = "Press Enter to show the text in a notification.",
	Default = "Ready",
	Placeholder = "Type a status...",
	Flag = "StatusMessage",
	Callback = function(text, enterPressed)
		if enterPressed then
			window:Notify({
				Title = "Status",
				Description = text,
				Duration = 2,
			})
		end
	end,
})

local infoParagraph = appearanceTab:Paragraph({
	Title = "Library Info",
	Content = "Version: "
		.. tostring(libraryInfo.Version)
		.. "\nAuthor: "
		.. tostring(libraryInfo.Author)
		.. "\nComponents: "
		.. joinValues(libraryInfo.Components),
})

local runtimeTab = uiSection:CreateTab("Runtime API", "rbxassetid://10723356507")
runtimeTab:CreateSection({
	Title = "Programmatic Methods",
	Description = "Set values, block/unblock controls, and manage window state at runtime.",
})

runtimeTab:Button({
	Name = "Set Example Values",
	Description = "Programmatic setters keep working even when components are blocked.",
	Callback = function()
		autoFarmToggle:SetValue(true)
		damageSlider:SetValue(7)
		walkSpeedSlider:SetValue(32)
		targetDropdown:SetValue("Lowest HP")
		weaponsDropdown:SetValue({ "Sword", "Magic" })
		flyKeybind:SetKey(Enum.KeyCode.G)
		accentPicker:SetColor(Color3.fromRGB(255, 120, 80))
		teleportBox:SetText("ExamplePlayer")
		statusBox:SetText("Updated from code")
		actionButton:SetText("Updated Action")
		actionButton:SetIcon("rbxassetid://10747384394")
		actionButton:SetCallback(function()
			window:Notify({
				Title = "Updated Action",
				Description = "SetCallback replaced the original callback.",
				Duration = 2,
			})
		end)
		infoParagraph:SetTitle("Runtime API Updated")
		infoParagraph:SetContent("Values were updated programmatically at " .. os.date("%X"))
	end,
})

runtimeTab:Button({
	Name = "Block Showcase Controls",
	Description = "Adds the shared blocked overlay to several controls.",
	Callback = function()
		autoFarmToggle:Block("Blocked by example")
		damageSlider:Block("Blocked by example")
		targetDropdown:Block("Blocked by example")
		weaponsDropdown:Block("Blocked by example")
		flyKeybind:Block("Blocked by example")
		accentPicker:Block("Blocked by example")
		teleportBox:Block("Blocked by example")
		statusBox:Block("Blocked by example")
		actionButton:Block("Blocked by example")

		window:Notify({
			Title = "Controls Blocked",
			Description = "Slider blocked: " .. tostring(damageSlider:IsBlocked()),
			Duration = 3,
		})
	end,
})

runtimeTab:Button({
	Name = "Unblock Showcase Controls",
	Description = "Removes the shared blocked overlay.",
	Callback = function()
		autoFarmToggle:Unblock()
		damageSlider:Unblock()
		targetDropdown:Unblock()
		weaponsDropdown:Unblock()
		flyKeybind:Unblock()
		accentPicker:Unblock()
		teleportBox:Unblock()
		statusBox:Unblock()
		actionButton:Unblock()
	end,
})

runtimeTab:Button({
	Name = "Focus Status TextBox",
	Description = "TextBox:Focus() no-ops while blocked.",
	Callback = function()
		statusBox:Focus()
	end,
})

runtimeTab:Button({
	Name = "Toggle Window For One Second",
	Description = "Calls window:Toggle() directly.",
	Callback = function()
		window:Toggle()
		task.delay(1, function()
			window:Toggle()
		end)
	end,
})

runtimeTab:Button({
	Name = "Reset Theme",
	Description = "Calls Library.ResetTheme() and restores the picker color.",
	Callback = function()
		Library.ResetTheme()
		local defaultTheme = Library.GetTheme()
		accentPicker:SetColor(defaultTheme.Accent)
	end,
})

local configTab = settingsSection:CreateTab("Config", "rbxassetid://10723356507")
local configSection = configTab:CreateConfigSection()

configTab:CreateSection({
	Title = "Manual Config API",
	Description = "Direct config save/load/delete via window methods.",
})

configTab:Button({
	Name = "Save ExampleManual",
	Description = "Calls window:SaveConfig().",
	Callback = function()
		window:SaveConfig("ExampleManual")
		configSection.RefreshConfigs()
	end,
})

configTab:Button({
	Name = "Load ExampleManual",
	Description = "Calls window:LoadConfig().",
	Callback = function()
		window:LoadConfig("ExampleManual")
	end,
})

configTab:Button({
	Name = "Delete ExampleManual",
	Description = "Calls window:DeleteConfig().",
	Callback = function()
		if window:DeleteConfig("ExampleManual") then
			configSection.RefreshConfigs()
		end
	end,
})

configTab:Button({
	Name = "Print Available Configs",
	Description = "Calls window:GetConfigs().",
	Callback = function()
		local configs = window:GetConfigs()
		local message = #configs > 0 and joinValues(configs) or "No configs found"
		print("Available configs:", message)
		window:Notify({
			Title = "Configs",
			Description = message,
			Duration = 3,
		})
	end,
})

configTab:Toggle({
	Name = "Manual Auto Save",
	Description = "Calls window:SetAutoSave(). Requires executor file APIs.",
	Default = false,
	Callback = function(enabled)
		window:SetAutoSave(enabled)
	end,
})

configTab:Toggle({
	Name = "Manual Auto Load",
	Description = "Calls window:SetAutoLoad() and window:GetAutoLoad().",
	Default = window:GetAutoLoad(),
	Callback = function(enabled)
		window:SetAutoLoad(enabled)
	end,
})
