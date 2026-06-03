local Create = require(script.Parent.Parent.Utils.Create)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Icons = require(script.Parent.Parent.Constants.Icons)

local Button = require(script.Parent.Button)
local Toggle = require(script.Parent.Toggle)
local Slider = require(script.Parent.Slider)
local Dropdown = require(script.Parent.Dropdown)
local TextBox = require(script.Parent.TextBox)

local ContentSection = {}
ContentSection.__index = ContentSection

local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}
local ConfigUIDefaults = ComponentDefaults.ConfigUI or {}
local ConfigDefaults = Defaults.Config or {}
local MessageDefaults = Defaults.Messages or {}
local NotificationDefaults = Defaults.Notification or {}
local ComponentIcons = Icons.Components or {}
local NotificationIcons = Icons.Notification or {}

function ContentSection.new(tab, config)
    local self = setmetatable({}, ContentSection)
    local sectionConfig = if type(config) == "table" then config else { Title = config }
    local title = tostring(sectionConfig.Title or sectionConfig.Name or "Section")
    local description = Create.GetDescription(sectionConfig)
    local hasDescription = description ~= nil
    local headerHeight = hasDescription and 54 or 42

    self._tab = tab
    self._window = tab._window
    self._title = title
    self._elements = {}

    self._frame = Create.Instance("Frame", {
        Name = "ContentSection_" .. title,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = CommonDefaults.SurfaceTransparency or 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tab._content,
    })

    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)
    Create.ListLayout(self._frame, 0)

    self._header = Create.Instance("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, headerHeight),
        LayoutOrder = 0,
        Parent = self._frame,
    })

    self._label = Create.Instance("TextLabel", {
        Name = "Title",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Section,
        Position = UDim2.new(0, 10, 0, hasDescription and 7 or 11),
        Size = UDim2.new(1, -20, 0, Sizes.Tab.SectionHeight or 25),
        Parent = self._header,
    })

    self._description = Create.Instance("TextLabel", {
        Name = "Description",
        FontFace = Fonts.Light,
        TextColor3 = Colors.TextDark,
        Text = description or "",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Tiny,
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 0, Sizes.Component.DescriptionHeight or 14),
        Visible = hasDescription,
        Parent = self._header,
    })

    self._separator = Create.Instance("Frame", {
        Name = "Separator",
        BackgroundColor3 = Colors.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        LayoutOrder = 1,
        Parent = self._frame,
    })

    self._container = Create.Instance("Frame", {
        Name = "Elements",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Parent = self._frame,
    })

    Create.Padding(self._container, 10, 10, 10, 10)
    Create.ListLayout(self._container, Sizes.Tab.ContentPadding or 8)

    return self
end

function ContentSection:_AddElement(element)
    table.insert(self._elements, element)
    return element
end

function ContentSection:Paragraph(config)
    local Paragraph = require(script.Parent.Paragraph)
    return self:_AddElement(Paragraph.new(self._container, config))
end

function ContentSection:Button(config)
    return self:_AddElement(Button.new(self._container, config, self._window))
end

function ContentSection:Toggle(config)
    return self:_AddElement(Toggle.new(self._container, config, self._window))
end

function ContentSection:Slider(config)
    return self:_AddElement(Slider.new(self._container, config, self._window))
end

function ContentSection:Dropdown(config)
    return self:_AddElement(Dropdown.new(self._container, config, self._window))
end

function ContentSection:Keybind(config)
    local Keybind = require(script.Parent.Keybind)
    return self:_AddElement(Keybind.new(self._container, config, self._window))
end

function ContentSection:ColorPicker(config)
    local ColorPicker = require(script.Parent.ColorPicker)
    return self:_AddElement(ColorPicker.new(self._container, config, self._window))
end

function ContentSection:TextBox(config)
    return self:_AddElement(TextBox.new(self._container, config, self._window))
end

function ContentSection:CreateConfigSection()
    local function getConfigOptions()
        local configs = self._window:GetConfigs()
        if #configs == 0 then
            return { ConfigDefaults.DefaultName or "default" }
        end
        return configs
    end

    local configNameBox = self:TextBox({
        Name = ConfigUIDefaults.ConfigName or "Config Name",
        Default = self._window._currentConfig,
        Placeholder = ConfigUIDefaults.ConfigPlaceholder or "Enter config name...",
        Callback = function(text)
            self._window._currentConfig = text
        end,
    })

    local configDropdown
    configDropdown = self:Dropdown({
        Name = ConfigUIDefaults.SelectConfig or "Select Config",
        Options = getConfigOptions(),
        Default = self._window._currentConfig,
        Callback = function(selected)
            if type(selected) == "string" then
                configNameBox:SetText(selected)
                self._window._currentConfig = selected
            end
        end,
    })

    self:Button({
        Name = ConfigUIDefaults.SaveConfig or "Save Config",
        Callback = function()
            local configName = configNameBox:GetText()
            if configName ~= "" and self._window:SaveConfig(configName) then
                configDropdown:Refresh(getConfigOptions())
            end
        end,
    })

    self:Button({
        Name = ConfigUIDefaults.LoadConfig or "Load Config",
        Callback = function()
            local configName = configNameBox:GetText()
            if configName ~= "" then
                self._window:LoadConfig(configName)
            end
        end,
    })

    self:Button({
        Name = ConfigUIDefaults.DeleteConfig or "Delete Config",
        Callback = function()
            local configName = configNameBox:GetText()
            if configName ~= "" and self._window:DeleteConfig(configName) then
                configDropdown:Refresh(getConfigOptions())
            end
        end,
    })

    self:Button({
        Name = ConfigUIDefaults.RefreshConfigs or "Refresh Configs",
        Callback = function()
            configDropdown:Refresh(getConfigOptions())
            self._window:Notify({
                Title = MessageDefaults.ConfigsRefreshedTitle or "Configs Refreshed",
                Description = MessageDefaults.ConfigsRefreshedDescription or "Config list updated",
                Duration = NotificationDefaults.SuccessDuration or 2,
                Icon = NotificationIcons.Config
                    or ComponentIcons.Config
                    or "rbxassetid://10723356507",
            })
        end,
    })

    self:Toggle({
        Name = ConfigUIDefaults.AutoSave or "Auto Save",
        Default = false,
        Callback = function(enabled)
            self._window:SetAutoSave(enabled)
        end,
    })

    local autoLoadToggle = self:Toggle({
        Name = ConfigUIDefaults.AutoLoad or "Auto Load",
        Default = self._window:GetAutoLoad(),
        Callback = function(enabled)
            if not self._window:SetAutoLoad(enabled) then
                autoLoadToggle:SetValue(not enabled, true)
            end
        end,
    })

    return {
        RefreshConfigs = function()
            configDropdown:Refresh(getConfigOptions())
        end,
    }
end

function ContentSection:Destroy()
    for _, element in ipairs(self._elements) do
        if element.Destroy then
            element:Destroy()
        end
    end
    table.clear(self._elements)

    if self._frame then
        self._frame:Destroy()
    end
end

return ContentSection
