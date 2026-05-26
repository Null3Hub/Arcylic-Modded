--[[
    AcrylicUI - Acrylic Blur Effect

    Creates a frosted glass blur effect behind UI elements.
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Create = require(script.Parent.Parent.Utils.Create)

local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur

local nextBlurId = 0

--[[
    Creates a new acrylic blur effect

    @param targetFrame GuiObject - The frame to apply blur behind
    @return AcrylicBlur - Blur instance
]]
function AcrylicBlur.new(targetFrame: GuiObject)
    local self = setmetatable({}, AcrylicBlur)
    nextBlurId += 1

    self._target = targetFrame
    self._id = nextBlurId
    self._folderName = "AcrylicBlur_" .. tostring(self._id)
    self._dofName = "AcrylicBlurDepthOfField_" .. tostring(self._id)
    self._blurName = "AcrylicBlurEffect_" .. tostring(self._id)
    self._folder = nil
    self._root = nil
    self._frame = nil
    self._blur = nil
    self._dof = nil
    self._enabled = true
    self._connections = {}

    self:_Initialize()

    return self
end

function AcrylicBlur:_CreateEffects()
    -- Depth of field for blur effect
    self._dof = Create.Instance("DepthOfFieldEffect", {
        Name = self._dofName,
        FarIntensity = 0,
        FocusDistance = 0.01,
        InFocusRadius = 0.01,
        NearIntensity = 1,
        Parent = Lighting,
    })

    -- Additional blur
    self._blur = Create.Instance("BlurEffect", {
        Name = self._blurName,
        Size = 6,
        Enabled = true,
        Parent = Lighting,
    })
end

function AcrylicBlur:_CreateMesh()
    self._folder = Create.Instance("Folder", {
        Name = self._folderName,
        Parent = workspace.CurrentCamera,
    })

    self._root = Create.Instance("Part", {
        Name = "Root",
        Color = Color3.new(0, 0, 0),
        Material = Enum.Material.Glass,
        Size = Vector3.new(1, 1, 0),
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        Locked = true,
        CastShadow = false,
        Transparency = 0.9,
        Parent = self._folder,
    })

    Create.Instance("SpecialMesh", {
        MeshType = Enum.MeshType.Brick,
        Parent = self._root,
    })
end

function AcrylicBlur:_CreateTrackingFrame()
    self._frame = Create.Instance("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = self._target,
    })
end

function AcrylicBlur:_StartRendering()
    local distance = 0.0005
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function ViewportToWorld(location: Vector2, dist: number): Vector3
        local ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return ray.Origin + ray.Direction * dist
    end

    local function GetOffset(): number
        local viewY = workspace.CurrentCamera.ViewportSize.Y
        return (viewY / 2560) * 24 + 4
    end

    local function UpdatePositions(size: Vector2, position: Vector2)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function Update()
        if not self._root or not self._enabled then
            return
        end

        local tl = ViewportToWorld(positions.top_left, distance)
        local tr = ViewportToWorld(positions.top_right, distance)
        local br = ViewportToWorld(positions.bottom_right, distance)

        local width = (tr - tl).Magnitude
        local height = (tr - br).Magnitude

        self._root.CFrame = CFrame.fromMatrix(
            (tl + br) / 2,
            workspace.CurrentCamera.CFrame.XVector,
            workspace.CurrentCamera.CFrame.YVector,
            workspace.CurrentCamera.CFrame.ZVector
        )
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function OnChange()
        local offset = GetOffset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)
        UpdatePositions(size, position)
        task.spawn(Update)
    end

    -- Connect to camera changes
    table.insert(
        self._connections,
        workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(Update)
    )
    table.insert(
        self._connections,
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(Update)
    )
    table.insert(
        self._connections,
        workspace.CurrentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(Update)
    )

    -- Connect to frame changes
    table.insert(
        self._connections,
        self._frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(OnChange)
    )
    table.insert(
        self._connections,
        self._frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(OnChange)
    )

    -- Render step update
    table.insert(self._connections, RunService.RenderStepped:Connect(Update))

    -- Initial update
    task.spawn(OnChange)
end

function AcrylicBlur:_Initialize()
    self:_CreateEffects()
    self:_CreateMesh()
    self:_CreateTrackingFrame()
    self:_StartRendering()
end

function AcrylicBlur:SetEnabled(enabled: boolean)
    self._enabled = enabled

    if self._root then
        self._root.Transparency = enabled and 0.9 or 1
    end

    if self._dof then
        self._dof.Enabled = enabled
    end

    if self._blur then
        self._blur.Enabled = enabled
    end
end

--[[
    Destroys the blur effect and cleans up resources
]]
function AcrylicBlur:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end

    if self._folder then
        self._folder:Destroy()
    end

    if self._frame then
        self._frame:Destroy()
    end

    if self._dof then
        self._dof:Destroy()
    end

    if self._blur then
        self._blur:Destroy()
    end
end

return AcrylicBlur
