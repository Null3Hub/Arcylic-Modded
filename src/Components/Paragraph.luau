local Create = require(script.Parent.Parent.Utils.Create)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)

local Paragraph = {}
Paragraph.__index = Paragraph
setmetatable(Paragraph, { __index = BaseComponent })
local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}
local ParagraphDefaults = ComponentDefaults.Paragraph or {}

function Paragraph.new(parent: Instance, config)
    local self = BaseComponent.new(Paragraph, {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 0),
        Blockable = false,
        Properties = {
            AutomaticSize = Enum.AutomaticSize.Y,
        },
    })
    local title = (config and config.Title) or ParagraphDefaults.Title or "Paragraph"
    local content = (config and config.Content)
        or ParagraphDefaults.Content
        or "Description text here."

    Create.Padding(self._frame, 10, 10, 10, 10)

    self._title = Create.Instance("TextLabel", {
        Name = "Title",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(1, 0, 0, Sizes.Paragraph.TitleHeight or 20),
        Parent = self._frame,
    })

    self._content = Create.Instance("TextLabel", {
        Name = "Content",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = content,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Small,
        Position = UDim2.new(0, 0, 0, Sizes.Paragraph.ContentTop or 22),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self._frame,
    })

    return self
end

function Paragraph:SetTitle(text: string)
    self._title.Text = text
end

function Paragraph:SetContent(text: string)
    self._content.Text = text
end

return Paragraph
