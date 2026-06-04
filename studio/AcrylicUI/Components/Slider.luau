--[[
    AcrylicUI - Slider Component

    A draggable slider for numeric value selection.
]]

local Services = require(script.Parent.Parent.Utils.Services)

local Create = require(script.Parent.Parent.Utils.Create)
local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)

local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = BaseComponent })
local SliderDefaults = Defaults.Slider
local ComponentDefaults = Defaults.Components or {}
local SliderComponentDefaults = ComponentDefaults.Slider or {}

export type SliderConfig = {
    Name: string?,
    Description: string?,
    Desc: string?,
    Min: number?,
    Max: number?,
    Default: number?,
    Increment: number?,
    Flag: string?,
    Callback: ((value: number) -> ())?,
}

export type SliderObject = {
    SetValue: (self: SliderObject, value: number) -> (),
    GetValue: (self: SliderObject) -> number,
    SetMin: (self: SliderObject, min: number) -> (),
    SetMax: (self: SliderObject, max: number) -> (),
    Block: (self: SliderObject, text: string?) -> (),
    Unblock: (self: SliderObject) -> (),
    IsBlocked: (self: SliderObject) -> boolean,
    Destroy: (self: SliderObject) -> (),
}

local function isFiniteNumber(value: any): boolean
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function resolveNumber(value: any, fallback: number): number
    if isFiniteNumber(value) then
        return value
    end

    return fallback
end

local function resolveRange(minValue: any, maxValue: any): (number, number)
    local min = resolveNumber(minValue, SliderDefaults.Min)
    local max = resolveNumber(maxValue, SliderDefaults.Max)

    if max < min then
        min, max = max, min
    end

    return min, max
end

local function resolveIncrement(increment: any): number
    local resolved = resolveNumber(increment, SliderDefaults.Increment)
    if resolved <= 0 then
        return SliderDefaults.Increment
    end

    return resolved
end

local function normalizeValue(
    value: any,
    fallback: number,
    min: number,
    max: number,
    increment: number
): number
    local resolved = resolveNumber(value, fallback)
    local snapped = math.floor(resolved / increment + 0.5) * increment

    return math.clamp(snapped, min, max)
end

--[[
    Creates a new slider component

    @param parent Instance - Parent container
    @param config SliderConfig - Slider configuration
    @return SliderObject - Slider control object
]]
function Slider.new(parent: Instance, config: SliderConfig, window): SliderObject
    config = config or {}

    local name = config.Name or SliderComponentDefaults.Name or "Slider"
    local min, max = resolveRange(config.Min, config.Max)
    local increment = resolveIncrement(config.Increment)
    local value = normalizeValue(config.Default, SliderDefaults.Value, min, max, increment)
    local description = Create.GetDescription(config)
    local hasDescription = description ~= nil
    local height = hasDescription and (Sizes.Slider.HeightWithDescription or 56)
        or Sizes.Slider.Height

    local self = BaseComponent.new(Slider, {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height),
        Blockable = true,
        Flag = config.Flag,
        Window = window,
    })

    self._min = min
    self._max = max
    self._increment = increment
    self._value = value
    self._callback = config.Callback or function() end
    self._dragging = false

    -- Label
    Create.ComponentLabel(
        self._frame,
        name,
        hasDescription,
        Sizes.Slider.DescriptionRightPadding or 80
    )

    -- Description
    Create.Description(
        self._frame,
        description,
        UDim2.new(0, Sizes.Component.LabelLeft or 10, 0, Sizes.Slider.DescriptionTop or 22),
        UDim2.new(
            1,
            -(Sizes.Slider.DescriptionRightPadding or 80),
            0,
            Sizes.Component.DescriptionHeight or 14
        )
    )

    -- Value display
    self._valueLabel = Create.Instance("TextLabel", {
        Name = "Value",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = tostring(self._value),
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Position = UDim2.new(
            1,
            -(Sizes.Slider.ValueRightOffset or 60),
            0,
            hasDescription and (Sizes.Slider.HeaderTopWithDescription or 4)
                or (Sizes.Slider.HeaderTop or 5)
        ),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(0, Sizes.Slider.ValueWidth or 50, 0, Sizes.Component.LabelHeight or 20),
        Parent = self._frame,
    })

    -- Track background
    self._track = Create.Instance("Frame", {
        Name = "Track",
        BackgroundColor3 = Colors.Background,
        Position = UDim2.new(
            0,
            Sizes.Slider.TrackHorizontalPadding or 10,
            0,
            hasDescription and (Sizes.Slider.TrackTopWithDescription or 39)
                or (Sizes.Slider.TrackTop or 29)
        ),
        BorderSizePixel = 0,
        Size = UDim2.new(
            1,
            -((Sizes.Slider.TrackHorizontalPadding or 10) * 2),
            0,
            Sizes.Slider.TrackHeight
        ),
        Parent = self._frame,
    })

    Create.Corner(self._track, Sizes.Corner.Full)

    -- Fill bar
    local range = math.max(self._max - self._min, 1)
    local initialFill = (self._value - self._min) / range
    self._fill = Create.Instance("Frame", {
        Name = "Fill",
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(initialFill, 0, 1, 0),
        Parent = self._track,
    })

    Create.Corner(self._fill, Sizes.Corner.Full)

    -- Input handling
    self:Connect(self._track.InputBegan, function(input)
        if self._blocked then
            return
        end

        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            self._dragging = true
            self:_UpdateFromInput(input)
        end
    end)

    self:Connect(self._track.InputEnded, function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            self._dragging = false
        end
    end)

    self:Connect(Services.UserInputService.InputChanged, function(input)
        if
            self._dragging
            and not self._blocked
            and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            )
        then
            self:_UpdateFromInput(input)
        end
    end)

    local baseBlock = self.Block
    self.Block = function(component, text: string?)
        component._dragging = false
        baseBlock(component, text)
    end

    Create.Configurable(self, self._flag, "Slider", function()
        return self._value
    end, function(configValue)
        if type(configValue) == "number" then
            self:SetValue(configValue)
        end
    end)

    return self
end

function Slider:_UpdateFromInput(input: InputObject)
    local pos = input.Position
    local trackPos = self._track.AbsolutePosition
    local trackSize = self._track.AbsoluteSize

    local relativeX = math.clamp((pos.X - trackPos.X) / trackSize.X, 0, 1)
    local rawValue = self._min + (self._max - self._min) * relativeX

    -- Apply increment
    self._value = normalizeValue(rawValue, self._value, self._min, self._max, self._increment)

    self:_UpdateVisual()
    self._callback(self._value)
end

function Slider:_UpdateVisual()
    local range = math.max(self._max - self._min, 1)
    local fillRatio = math.clamp((self._value - self._min) / range, 0, 1)
    Tween.Create(self._fill, { Size = UDim2.new(fillRatio, 0, 1, 0) }, "Instant")
    self._valueLabel.Text = tostring(self._value)
end

function Slider:SetValue(value: number)
    self._value = normalizeValue(value, self._value, self._min, self._max, self._increment)
    self:_UpdateVisual()
    self._callback(self._value)
end

function Slider:GetValue(): number
    return self._value
end

function Slider:SetMin(min: number)
    self._min = resolveNumber(min, self._min)
    if self._max < self._min then
        self._max = self._min
    end
    self._value = normalizeValue(self._value, self._value, self._min, self._max, self._increment)
    self:_UpdateVisual()
end

function Slider:SetMax(max: number)
    self._max = resolveNumber(max, self._max)
    if self._max < self._min then
        self._min = self._max
    end
    self._value = normalizeValue(self._value, self._value, self._min, self._max, self._increment)
    self:_UpdateVisual()
end

return Slider
