--[[
    AcrylicUI - Toggle Component

    A toggle switch with smooth animations.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Defaults = require(script.Parent.Parent.Constants.Defaults)

local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = BaseComponent })
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
    SetValue: (self: ToggleObject, value: boolean, silent: boolean?) -> (),
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

    local self = BaseComponent.new(Toggle, {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height),
        Blockable = true,
        Flag = config.Flag,
        Window = window,
    })

    self._enabled = default
    self._callback = callback

    -- Label
    self._label = Create.ComponentLabel(
        self._frame,
        name,
        hasDescription,
        Sizes.Toggle.LabelRightPadding or 60
    )

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

    self:Connect(button.MouseButton1Click, function()
        if self._blocked then
            return
        end

        self:SetValue(not self._enabled)
    end)

    local baseBlock = self.Block
    self.Block = function(component, text: string?)
        if component._enabled then
            component:SetValue(false)
        end

        baseBlock(component, text)
    end

    Create.Configurable(self, self._flag, "Toggle", function()
        return self._enabled
    end, function(value)
        if type(value) == "boolean" then
            self:SetValue(value, true)
        end
    end)

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

function Toggle:SetValue(value: boolean, silent: boolean?)
    self._enabled = value
    self:_UpdateVisual()
    if not silent then
        self._callback(self._enabled)
    end
end

function Toggle:GetValue(): boolean
    return self._enabled
end

return Toggle
