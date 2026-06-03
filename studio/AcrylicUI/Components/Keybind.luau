local Services = require(script.Parent.Parent.Utils.Services)

local Create = require(script.Parent.Parent.Utils.Create)
local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)

local Keybind = {}
Keybind.__index = Keybind
setmetatable(Keybind, { __index = BaseComponent })
local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}
local KeybindDefaults = ComponentDefaults.Keybind or {}
local KeybindSizes = Sizes.Keybind or {}

function Keybind.new(parent: Instance, config, window)
    config = config or {}

    local name = config.Name or KeybindDefaults.Name or "Keybind"
    local default = config.Default or KeybindDefaults.Key or Enum.KeyCode.F
    local callback = config.Callback or function() end
    local description = Create.GetDescription(config)
    local hasDescription = description ~= nil
    local height = hasDescription
            and (KeybindSizes.HeightWithDescription or CommonDefaults.HeightWithDescription or 50)
        or Sizes.Button.Height

    local self = BaseComponent.new(Keybind, {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height),
        Blockable = true,
        Flag = config.Flag,
        Window = window,
    })

    Create.ComponentLabel(self._frame, name, hasDescription)

    Create.Description(
        self._frame,
        description,
        UDim2.new(0, Sizes.Component.LabelLeft or 10, 0, Sizes.Component.DescriptionTop or 27),
        UDim2.new(0, KeybindSizes.LabelWidth or 200, 0, Sizes.Component.DescriptionHeight or 14)
    )

    self._box = Create.Instance("Frame", {
        Name = "KeyBox",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = CommonDefaults.ControlTransparency or 0.04,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -(KeybindSizes.BoxRightOffset or 10), 0.5, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(
            0,
            KeybindSizes.BoxWidth or KeybindDefaults.BoxWidth or 30,
            0,
            KeybindSizes.BoxHeight or 26
        ),
        Parent = self._frame,
    })

    Create.Corner(self._box, Sizes.Corner.Small)
    Create.Stroke(self._box)

    self._label = Create.Instance("TextLabel", {
        Name = "Key",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = default.Name,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._box,
    })

    self._listenBtn = Create.Instance("TextButton", {
        Name = "Listen",
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._box,
    })

    self._currentKey = default
    self._listening = false

    self._id = name
        .. "_"
        .. tostring(math.floor(os.clock() * (KeybindDefaults.IdClockScale or 1000)))
    window:RegisterKeybind(self._id, self._currentKey, function()
        if self._blocked then
            return
        end

        callback()
    end)

    local function refresh()
        if self._listening then
            self._label.Text = KeybindDefaults.ListeningText or "..."
            self._box.Size = UDim2.new(
                0,
                KeybindSizes.ListeningWidth or KeybindDefaults.ListeningWidth or 43,
                0,
                KeybindSizes.BoxHeight or 26
            )
        else
            local keyName = self._currentKey.Name
            local w = math.max(
                #keyName * (KeybindDefaults.TextWidthScale or 9)
                    + (KeybindDefaults.TextWidthPadding or 10),
                KeybindDefaults.MinWidth or 24
            )
            self._box.Size = UDim2.new(0, w, 0, KeybindSizes.BoxHeight or 26)
            self._label.Text = keyName
        end
    end

    self:Connect(self._listenBtn.MouseButton1Click, function()
        if self._blocked then
            return
        end

        self._listening = true
        refresh()
    end)

    self:Connect(Services.UserInputService.InputBegan, function(input, _gameProcessed)
        if self._blocked then
            return
        end

        if not self._listening then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self._currentKey = input.KeyCode
            self._listening = false
            window:UpdateKeybind(self._id, self._currentKey)
            refresh()
        end
    end)

    self._refresh = refresh

    local baseBlock = self.Block
    self.Block = function(component, text: string?)
        component._listening = false
        component._refresh()
        baseBlock(component, text)
    end

    Create.Configurable(self, self._flag, "Keybind", function()
        return self._currentKey.Name
    end, function(value)
        if type(value) == "string" and Enum.KeyCode[value] then
            self:SetKey(Enum.KeyCode[value])
        elseif typeof(value) == "EnumItem" then
            self:SetKey(value)
        end
    end)

    refresh()
    return self
end

function Keybind:SetKey(key: Enum.KeyCode)
    self._currentKey = key
    self._window:UpdateKeybind(self._id, self._currentKey)
    self._refresh()
end

function Keybind:GetKey(): Enum.KeyCode
    return self._currentKey
end

return Keybind
