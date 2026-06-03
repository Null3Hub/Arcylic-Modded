--[[
    AcrylicUI - Button Component

    A clickable button with hover effects and icon support.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Icons = require(script.Parent.Parent.Constants.Icons)

local Button = {}
Button.__index = Button
local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}
local ButtonDefaults = ComponentDefaults.Button or {}
local ComponentIcons = Icons.Components or {}

export type ButtonConfig = {
    Name: string?,
    Description: string?,
    Desc: string?,
    Icon: string?,
    Callback: (() -> ())?,
}

export type ButtonObject = {
    SetText: (self: ButtonObject, text: string) -> (),
    SetIcon: (self: ButtonObject, icon: string) -> (),
    SetCallback: (self: ButtonObject, callback: () -> ()) -> (),
    Block: (self: ButtonObject, text: string?) -> (),
    Unblock: (self: ButtonObject) -> (),
    IsBlocked: (self: ButtonObject) -> boolean,
    Destroy: (self: ButtonObject) -> (),
}

--[[
    Creates a new button component

    @param parent Instance - Parent container
    @param config ButtonConfig - Button configuration
    @return ButtonObject - Button control object

    @example
    local button = Button.new(container, {
        Name = "Execute",
        Icon = "rbxassetid://10734898355",
        Callback = function()
            print("Button clicked!")
        end
    })
]]
function Button.new(parent: Instance, config: ButtonConfig): ButtonObject
    local self = setmetatable({}, Button)
    config = config or {}

    local name = config.Name or ButtonDefaults.Name or "Button"
    local icon = config.Icon or ComponentIcons.Button or "rbxassetid://10734898355"
    local callback = config.Callback or function() end
    local description = Create.GetDescription(config)
    local hasDescription = description ~= nil
    local height = hasDescription
            and (Sizes.Component.HeightWithDescription or CommonDefaults.HeightWithDescription or 50)
        or Sizes.Button.Height

    self._connections = {}

    -- Main container
    self._frame = Create.Instance("Frame", {
        Name = "Button_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = CommonDefaults.SurfaceTransparency or 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height),
        Parent = parent,
    })

    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)

    -- Button label
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
            -(Sizes.Button.LabelRightPadding or 50),
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
            -(Sizes.Button.LabelRightPadding or 50),
            0,
            Sizes.Component.DescriptionHeight or 14
        )
    )

    -- Icon
    self._icon = Create.Instance("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        ImageColor3 = Colors.Text,
        Position = UDim2.new(
            1,
            -(Sizes.Button.IconRightOffset or 30),
            0.5,
            -((Sizes.Button.IconSize or 20) / 2)
        ),
        Size = UDim2.new(0, Sizes.Button.IconSize or 20, 0, Sizes.Button.IconSize or 20),
        Parent = self._frame,
    })
    Create.ApplyIcon(self._icon, icon, ComponentIcons.Button)

    Create.Instance("UIAspectRatioConstraint", {
        Parent = self._icon,
    })

    -- Click button
    self._button = Create.Instance("TextButton", {
        Name = "ClickArea",
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._frame,
    })

    self._callback = callback

    -- Event handlers
    table.insert(
        self._connections,
        self._button.MouseButton1Click:Connect(function()
            if self._blocked then
                return
            end

            -- Click animation
            Tween.Create(
                self._frame,
                { BackgroundTransparency = CommonDefaults.PressedTransparency or 0.2 },
                "Fast"
            )
            task.wait(CommonDefaults.ClickFlashDelay or 0.1)
            Tween.Create(
                self._frame,
                { BackgroundTransparency = CommonDefaults.SurfaceTransparency or 0.4 },
                "Fast"
            )

            self._callback()
        end)
    )

    table.insert(
        self._connections,
        self._button.MouseEnter:Connect(function()
            if self._blocked then
                return
            end

            Tween.Create(
                self._frame,
                { BackgroundTransparency = CommonDefaults.HoverTransparency or 0.3 },
                "Fast"
            )
        end)
    )

    table.insert(
        self._connections,
        self._button.MouseLeave:Connect(function()
            Tween.Create(
                self._frame,
                { BackgroundTransparency = CommonDefaults.SurfaceTransparency or 0.4 },
                "Fast"
            )
        end)
    )

    Create.Blockable(self, self._frame)

    return self
end

function Button:SetText(text: string)
    self._label.Text = text
end

function Button:SetIcon(icon: string?)
    Create.ApplyIcon(self._icon, icon, ComponentIcons.Button)
end

function Button:SetCallback(callback: () -> ())
    self._callback = callback
end

function Button:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

    self._frame:Destroy()
end

return Button
