--[[
    AcrylicUI - Draggable Utility

    Makes UI elements draggable with mouse and touch support.
]]

local Services = require(script.Parent.Services)

local Draggable = {}

export type DraggableConnection = {
    Disconnect: () -> (),
}

--[[
    Makes a frame draggable

    @param frame GuiObject - The frame to make draggable
    @param handle GuiObject? - Optional handle element (defaults to frame)
    @return DraggableConnection - Connection object to disconnect

    @example
    local connection = Draggable.Enable(window, titleBar)
    -- Later: connection.Disconnect()
]]
function Draggable.Enable(frame: GuiObject, handle: GuiObject?): DraggableConnection
    handle = handle or frame

    local dragging = false
    local dragInput: InputObject?
    local dragStart: Vector3
    local startPos: UDim2

    local connections: { RBXScriptConnection } = {}

    local function onInputBegan(input: InputObject)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local dragInputRef = input
            local inputConnection
            inputConnection = Services.UserInputService.InputEnded:Connect(function(endInput)
                if endInput == dragInputRef then
                    dragging = false
                    inputConnection:Disconnect()
                end
            end)

            table.insert(connections, inputConnection)
        end
    end

    local function onInputChanged(input: InputObject)
        if
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragInput = input
        end
    end

    table.insert(connections, handle.InputBegan:Connect(onInputBegan))
    table.insert(connections, handle.InputChanged:Connect(onInputChanged))

    table.insert(
        connections,
        Services.UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    )

    return {
        Disconnect = function()
            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
            table.clear(connections)
        end,
    }
end

return Draggable
