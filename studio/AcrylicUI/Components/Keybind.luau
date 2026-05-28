local Services = require(script.Parent.Parent.Utils.Services)

local Create = require(script.Parent.Parent.Utils.Create)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local Keybind = {}
Keybind.__index = Keybind

function Keybind.new(parent: Instance, config, window)
    local self = setmetatable({}, Keybind)

    local name = (config and config.Name) or "Keybind"
    local default = (config and config.Default) or Enum.KeyCode.F
    local callback = (config and config.Callback) or function() end
    local flag = config and config.Flag
    local description = Create.GetDescription(config)
    local hasDescription = description ~= nil
    local height = hasDescription and 50 or Sizes.Button.Height

    self._frame = Create.Instance("Frame", {
        Name = "Keybind_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height),
        Parent = parent,
    })

    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)

    Create.Instance("TextLabel", {
        Name = "Name",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = hasDescription and UDim2.new(0, 10, 0, 7) or UDim2.new(0, 10, 0.5, -10),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(0, 200, 0, 20),
        Parent = self._frame,
    })

    Create.Description(self._frame, description, UDim2.new(0, 10, 0, 27), UDim2.new(0, 200, 0, 14))

    self._box = Create.Instance("Frame", {
        Name = "KeyBox",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = 0.04,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 30, 0, 26),
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
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._box,
    })

    self._currentKey = default
    self._listening = false
    self._flag = flag
    self._window = window
    self._connections = {}

    self._id = name .. "_" .. tostring(math.floor(os.clock() * 1000))
    window:RegisterKeybind(self._id, self._currentKey, function()
        if self._blocked then
            return
        end

        callback()
    end)

    local function refresh()
        if self._listening then
            self._label.Text = "..."
            self._box.Size = UDim2.new(0, 43, 0, 26)
        else
            local keyName = self._currentKey.Name
            local w = math.max(#keyName * 9 + 10, 24)
            self._box.Size = UDim2.new(0, w, 0, 26)
            self._label.Text = keyName
        end
    end

    table.insert(
        self._connections,
        self._listenBtn.MouseButton1Click:Connect(function()
            if self._blocked then
                return
            end

            self._listening = true
            refresh()
        end)
    )

    table.insert(
        self._connections,
        Services.UserInputService.InputBegan:Connect(function(input, _gameProcessed)
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
    )

    self._refresh = refresh

    Create.Blockable(self, self._frame)

    local baseBlock = self.Block
    self.Block = function(component, text: string?)
        component._listening = false
        component._refresh()
        baseBlock(component, text)
    end

    if self._flag and self._window and self._window.RegisterConfigElement then
        self._window:RegisterConfigElement(self._flag, "Keybind", function()
            return self._currentKey
        end, function(value)
            self:SetKey(value)
        end)
    end

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

function Keybind:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

    if self._window then
        self._window:UnregisterKeybind(self._id)
    end

    if self._flag and self._window and self._window.UnregisterConfigElement then
        self._window:UnregisterConfigElement(self._flag)
    end

    self._frame:Destroy()
end

return Keybind
