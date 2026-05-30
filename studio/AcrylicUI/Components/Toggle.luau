--[[
    AcrylicUI - Toggle Component

    A toggle switch with smooth animations.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)

local Toggle = {}
Toggle.__index = Toggle
local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}
local ToggleDefaults = ComponentDefaults.Toggle or {}

export type ToggleConfig = {
    Name: string?,
    Description: string?,
    Desc: string?,
    Default: boolean?,
    Flag: string?,
    Callback: ((enabled: boolean) -> ())?,
}

export type ToggleObject = {
    SetValue: (self: ToggleObject, value: boolean) -> (),
    GetValue: (self: ToggleObject) -> boolean,
    Block: (self: ToggleObject, text: string?) -> (),
    Unblock: (self: ToggleObject) -> (),
    IsBlocked: (self: ToggleObject) -> boolean,
    Destroy: (self: ToggleObject) -> (),
}

--[[
    Creates a new toggle component

    @param parent Instance - Parent container
    @param config ToggleConfig - Toggle configuration
    @return ToggleObject - Toggle control object
]]
function Toggle.new(parent: Instance, config: ToggleConfig, window): ToggleObject
    local self = setmetatable({}, Toggle)
    config = config or {}

    local name = config.Name or ToggleDefaults.Name or "Toggle"
    local default = if config.Default == nil
        then (ToggleDefaults.Enabled or false)
        else config.Default
    local callback = config.Callback or function() end
    local description = Create.GetDescription(config)
    local hasDescription = description ~= nil
    local height = hasDescription
            and (Sizes.Component.HeightWithDescription or CommonDefaults.HeightWithDescription or 50)
        or Sizes.Button.Height
    local knobPadding = Sizes.Toggle.Padding or 4
    local knobEnabledX = Sizes.Toggle.Width - Sizes.Toggle.Circle - knobPadding

    self._enabled = default
    self._callback = callback
    self._flag = config.Flag
    self._window = window
    self._connections = {}

    -- Main container
    self._frame = Create.Instance("Frame", {
        Name = "Toggle_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = CommonDefaults.SurfaceTransparency or 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height),
        Parent = parent,
    })

    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)

    -- Label
    self._label = Create.Instance("TextLabel", {
        Name = "Label",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = hasDescription
                and UDim2.new(0, Sizes.Component.LabelLeft or 10, 0, Sizes.Component.LabelTop or 7)
            or UDim2.new(
                0,
                Sizes.Component.LabelLeft or 10,
                0.5,
                -(Sizes.Component.LabelCenterOffset or 10)
            ),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(
            1,
            -(Sizes.Toggle.LabelRightPadding or 60),
            0,
            Sizes.Component.LabelHeight or 20
        ),
        Parent = self._frame,
    })

    -- Description
    Create.Description(
        self._frame,
        description,
        UDim2.new(0, Sizes.Component.LabelLeft or 10, 0, Sizes.Component.DescriptionTop or 27),
        UDim2.new(
            1,
            -(Sizes.Toggle.LabelRightPadding or 60),
            0,
            Sizes.Component.DescriptionHeight or 14
        )
    )

    -- Switch background
    self._switchBg = Create.Instance("Frame", {
        Name = "SwitchBackground",
        BackgroundColor3 = self._enabled and Colors.Toggle.Enabled or Colors.Toggle.Disabled,
        Position = UDim2.new(
            1,
            -(Sizes.Toggle.RightOffset or 48),
            0.5,
            -(Sizes.Toggle.VerticalOffset or 10)
        ),
        BorderSizePixel = 0,
        Size = UDim2.new(0, Sizes.Toggle.Width, 0, Sizes.Toggle.Height),
        Parent = self._frame,
    })

    Create.Corner(self._switchBg, Sizes.Corner.Full)

    -- Switch circle
    self._circle = Create.Instance("Frame", {
        Name = "Circle",
        BackgroundColor3 = Colors.Toggle.Circle,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = if self._enabled
            then UDim2.new(0, knobEnabledX, 0.5, 0)
            else UDim2.new(0, knobPadding, 0.5, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, Sizes.Toggle.Circle, 0, Sizes.Toggle.Circle),
        Parent = self._switchBg,
    })

    Create.Corner(self._circle, Sizes.Corner.Full)

    -- Click area
    local button = Create.Instance("TextButton", {
        Name = "ClickArea",
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._frame,
    })

    table.insert(
        self._connections,
        button.MouseButton1Click:Connect(function()
            if self._blocked then
                return
            end

            self:SetValue(not self._enabled)
        end)
    )

    Create.Blockable(self, self._frame)

    local baseBlock = self.Block
    self.Block = function(component, text: string?)
        if component._enabled then
            component:SetValue(false)
        end

        baseBlock(component, text)
    end

    if self._flag and self._window and self._window.RegisterConfigElement then
        self._window:RegisterConfigElement(self._flag, "Toggle", function()
            return self._enabled
        end, function(value)
            self:SetValue(value)
        end)
    end

    return self
end

function Toggle:_UpdateVisual()
    if self._enabled then
        Tween.Create(self._switchBg, { BackgroundColor3 = Colors.Toggle.Enabled }, "Normal")
        Tween.Create(self._circle, {
            Position = UDim2.new(
                0,
                Sizes.Toggle.Width - Sizes.Toggle.Circle - (Sizes.Toggle.Padding or 4),
                0.5,
                0
            ),
        }, "Normal")
    else
        Tween.Create(self._switchBg, { BackgroundColor3 = Colors.Toggle.Disabled }, "Normal")
        Tween.Create(
            self._circle,
            { Position = UDim2.new(0, Sizes.Toggle.Padding or 4, 0.5, 0) },
            "Normal"
        )
    end
end

function Toggle:SetValue(value: boolean)
    self._enabled = value
    self:_UpdateVisual()
    self._callback(self._enabled)
end

function Toggle:GetValue(): boolean
    return self._enabled
end

function Toggle:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

    if self._flag and self._window and self._window.UnregisterConfigElement then
        self._window:UnregisterConfigElement(self._flag)
    end

    self._frame:Destroy()
end

return Toggle
