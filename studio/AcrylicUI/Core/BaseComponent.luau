--[[
    AcrylicUI - Base Component

    Shared lifecycle helpers for UI components.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Defaults = require(script.Parent.Parent.Constants.Defaults)

local BaseComponent = {}
BaseComponent.__index = BaseComponent

local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}

export type BaseConfig = {
    Parent: Instance,
    Class: string?,
    Size: UDim2?,
    BackgroundColor3: Color3?,
    BackgroundTransparency: number?,
    Properties: { [string]: any }?,
    Corner: boolean?,
    CornerRadius: number?,
    Stroke: boolean?,
    StrokeColor: Color3?,
    StrokeTransparency: number?,
    StrokeThickness: number?,
    Blockable: boolean?,
    Flag: string?,
    Window: any?,
}

local function buildFrameProperties(config: BaseConfig): { [string]: any }
    local frameProperties = {
        Name = "\0",
        PreserveName = true,
        BackgroundColor3 = config.BackgroundColor3 or Colors.Secondary,
        BackgroundTransparency = if config.BackgroundTransparency ~= nil
            then config.BackgroundTransparency
            else CommonDefaults.SurfaceTransparency or 0.4,
        BorderSizePixel = 0,
        Size = config.Size or UDim2.new(1, 0, 0, 40),
        Parent = config.Parent,
    }

    for property, value in pairs(config.Properties or {}) do
        frameProperties[property] = value
    end

    return frameProperties
end

function BaseComponent.new(classTable: any?, config: BaseConfig)
    config = config or {}

    if classTable and classTable.__index == nil then
        classTable.__index = classTable
    end

    if classTable and getmetatable(classTable) == nil then
        setmetatable(classTable, { __index = BaseComponent })
    end

    local self = setmetatable({}, classTable or BaseComponent)
    self._connections = {}
    self._blocked = false
    self._flag = config.Flag
    self._window = config.Window

    self._frame = Create.Instance(config.Class or "Frame", buildFrameProperties(config))

    if config.Corner ~= false then
        Create.Corner(self._frame, config.CornerRadius or Sizes.Corner.Medium)
    end

    if config.Stroke ~= false then
        self._stroke = Create.Stroke(
            self._frame,
            config.StrokeColor,
            config.StrokeTransparency,
            config.StrokeThickness
        )
    end

    if config.Blockable == true then
        Create.Blockable(self, self._frame)
    end

    return self
end

function BaseComponent:Connect(signal: RBXScriptSignal, callback: (...any) -> ())
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function BaseComponent:DisconnectAll()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function BaseComponent:Destroy()
    self:DisconnectAll()

    if self._id and self._window and self._window.UnregisterKeybind then
        self._window:UnregisterKeybind(self._id)
    end

    if self._flag and self._window and self._window.UnregisterConfigElement then
        self._window:UnregisterConfigElement(self._flag)
    end

    if self._frame then
        self._frame:Destroy()
        self._frame = nil
    end
end

return BaseComponent
