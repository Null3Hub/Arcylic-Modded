local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
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

local Tab = {}
Tab.__index = Tab
local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}
local ConfigUIDefaults = ComponentDefaults.ConfigUI or {}
local ComponentIcons = Icons.Components or {}

function Tab.new(window, section, name: string, icon: string?)
    local self = setmetatable({}, Tab)
    self._window = window
    self._section = section
    self._name = name
    self._elements = {}
    self._connections = {}

    -- Button in sidebar
    self._button = Create.Instance("Frame", {
        Name = name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, Sizes.Tab.Width, 0, Sizes.Tab.Height),
        Parent = section._tabsContainer,
    })

    Create.Corner(self._button, Sizes.Corner.Medium)
    self._stroke = Create.Stroke(self._button, Colors.Border, 1)

    self._icon = Create.Instance("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = icon or ComponentIcons.Tab or "rbxassetid://112235310154264",
        ImageColor3 = Colors.TextDark,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, Sizes.Tab.IconLeft or 11, 0.5, 0),
        Size = UDim2.new(0, Sizes.Tab.IconSize or 15, 0, Sizes.Tab.IconSize or 15),
        Parent = self._button,
    })

    self._text = Create.Instance("TextLabel", {
        Name = "TabText",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, Sizes.Tab.TextLeft or 33, 0, 0),
        Size = UDim2.new(1, -(Sizes.Tab.TextRightPadding or 42), 1, 0),
        TextSize = Fonts.Size.Small,
        Parent = self._button,
    })

    Create.Instance(
        "UIPadding",
        { PaddingRight = UDim.new(0, Sizes.Tab.TextPaddingRight or 9), Parent = self._text }
    )

    local click = Create.Instance("TextButton", {
        Name = "Click",
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._button,
    })

    -- Content frame
    self._content = Create.Instance("Frame", {
        Name = name .. "_Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = window:GetContentContainer(),
    })

    Create.ListLayout(self._content, Sizes.Tab.ContentPadding or 8)

    table.insert(
        self._connections,
        click.MouseButton1Click:Connect(function()
            window:SelectTab(self)
        end)
    )

    table.insert(
        self._connections,
        click.MouseEnter:Connect(function()
            if window._currentTab ~= self then
                Tween.Create(
                    self._button,
                    { BackgroundTransparency = CommonDefaults.HoverFaintTransparency or 0.7 },
                    "Fast"
                )
            end
        end)
    )

    table.insert(
        self._connections,
        click.MouseLeave:Connect(function()
            if window._currentTab ~= self then
                Tween.Create(
                    self._button,
                    { BackgroundTransparency = CommonDefaults.Transparent or 1 },
                    "Fast"
                )
            end
        end)
    )

    if not window._currentTab then
        window:SelectTab(self)
    end

    return self
end

function Tab:_AddElement(element)
    table.insert(self._elements, element)
    return element
end

function Tab:Select()
    self._content.Visible = true
    Tween.Create(
        self._button,
        { BackgroundTransparency = CommonDefaults.SurfaceTransparency or 0.4 },
        "Fast"
    )
    Tween.Create(self._text, { TextColor3 = Colors.Text }, "Fast")
    Tween.Create(self._icon, { ImageColor3 = Colors.Text }, "Fast")
    self._stroke.Transparency = 0
end

function Tab:Deselect()
    self._content.Visible = false
    Tween.Create(self._button, { BackgroundTransparency = CommonDefaults.Transparent or 1 }, "Fast")
    Tween.Create(self._text, { TextColor3 = Colors.TextDark }, "Fast")
    Tween.Create(self._icon, { ImageColor3 = Colors.TextDark }, "Fast")
    self._stroke.Transparency = 1
end

-- Content helpers
function Tab:CreateSection(config)
    local ContentSection = require(script.Parent.ContentSection)
    return self:_AddElement(ContentSection.new(self, config))
end

function Tab:Paragraph(config)
    local Paragraph = require(script.Parent.Paragraph)
    return self:_AddElement(Paragraph.new(self._content, config))
end

function Tab:Button(config)
    return self:_AddElement(Button.new(self._content, config, self._window))
end

function Tab:Toggle(config)
    return self:_AddElement(Toggle.new(self._content, config, self._window))
end

function Tab:Slider(config)
    return self:_AddElement(Slider.new(self._content, config, self._window))
end

function Tab:Dropdown(config)
    return self:_AddElement(Dropdown.new(self._content, config, self._window))
end

function Tab:Keybind(config)
    local Keybind = require(script.Parent.Keybind)
    return self:_AddElement(Keybind.new(self._content, config, self._window))
end

function Tab:ColorPicker(config)
    local ColorPicker = require(script.Parent.ColorPicker)
    return self:_AddElement(ColorPicker.new(self._content, config, self._window))
end

function Tab:TextBox(config)
    return self:_AddElement(TextBox.new(self._content, config, self._window))
end

function Tab:CreateConfigSection()
    local section = self:CreateSection(ConfigUIDefaults.SectionTitle or "Configuration")
    return section:CreateConfigSection()
end

function Tab:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

    for _, element in ipairs(self._elements) do
        if element.Destroy then
            element:Destroy()
        end
    end
    table.clear(self._elements)

    if self._content then
        self._content:Destroy()
    end

    if self._button then
        self._button:Destroy()
    end
end

return Tab
