--[[
    AcrylicUI - Acrylic Blur Effect

    Creates a frosted glass blur effect behind UI elements.
    Handles camera nil-check and reconnects on camera swap (respawn).
]]

local Services = require(script.Parent.Parent.Utils.Services)

local Create = require(script.Parent.Parent.Utils.Create)
local Defaults = require(script.Parent.Parent.Constants.Defaults)

local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur
local BlurDefaults = Defaults.AcrylicBlur or {}

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
    self._folderName = (BlurDefaults.FolderPrefix or "AcrylicBlur_") .. tostring(self._id)
    self._dofName = (BlurDefaults.DepthOfFieldPrefix or "AcrylicBlurDepthOfField_")
        .. tostring(self._id)
    self._blurName = (BlurDefaults.BlurPrefix or "AcrylicBlurEffect_") .. tostring(self._id)
    self._folder = nil
    self._root = nil
    self._frame = nil
    self._blur = nil
    self._dof = nil
    self._enabled = true
    self._connections = {}
    self._cameraConnections = {}
    self._renderUpdate = nil
    self._onChange = nil
    self._destroyed = false

    self:_Initialize()

    return self
end

function AcrylicBlur:_CreateEffects()
    self._dof = Create.Instance("DepthOfFieldEffect", {
        Name = self._dofName,
        FarIntensity = BlurDefaults.FarIntensity or 0,
        FocusDistance = BlurDefaults.FocusDistance or 0.01,
        InFocusRadius = BlurDefaults.InFocusRadius or 0.01,
        NearIntensity = BlurDefaults.NearIntensity or 1,
        Parent = Services.Lighting,
    })

    self._blur = Create.Instance("BlurEffect", {
        Name = self._blurName,
        Size = BlurDefaults.BlurSize or 6,
        Enabled = true,
        Parent = Services.Lighting,
    })
end

function AcrylicBlur:_CreateMesh()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    self._folder = Create.Instance("Folder", {
        Name = self._folderName,
        Parent = camera,
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
        Transparency = BlurDefaults.RootTransparency or 0.9,
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

function AcrylicBlur:_DisconnectCamera()
    for _, conn in ipairs(self._cameraConnections) do
        conn:Disconnect()
    end
    table.clear(self._cameraConnections)
end

function AcrylicBlur:_ConnectCamera()
    self:_DisconnectCamera()

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local distance = BlurDefaults.CameraDistance or 0.0005
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function ViewportToWorld(location: Vector2, dist: number): Vector3
        local cam = workspace.CurrentCamera
        if not cam then
            return Vector3.zero
        end
        local ray = cam:ScreenPointToRay(location.X, location.Y)
        return ray.Origin + ray.Direction * dist
    end

    local function GetOffset(): number
        local cam = workspace.CurrentCamera
        if not cam then
            return BlurDefaults.FallbackOffset or 28
        end
        local viewY = cam.ViewportSize.Y
        return (viewY / (BlurDefaults.ReferenceViewportHeight or 2560))
                * (BlurDefaults.OffsetScale or 24)
            + (BlurDefaults.OffsetBase or 4)
    end

    local function UpdatePositions(size: Vector2, position: Vector2)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function Update()
        if not self._root or not self._enabled or self._destroyed then
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then
            return
        end

        local tl = ViewportToWorld(positions.top_left, distance)
        local tr = ViewportToWorld(positions.top_right, distance)
        local br = ViewportToWorld(positions.bottom_right, distance)

        local width = (tr - tl).Magnitude
        local height = (tr - br).Magnitude

        self._root.CFrame = CFrame.fromMatrix(
            (tl + br) / 2,
            cam.CFrame.XVector,
            cam.CFrame.YVector,
            cam.CFrame.ZVector
        )
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function OnChange()
        if self._destroyed then
            return
        end
        local offset = GetOffset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)
        UpdatePositions(size, position)
        task.spawn(Update)
    end

    self._renderUpdate = Update
    self._onChange = OnChange

    table.insert(self._cameraConnections, camera:GetPropertyChangedSignal("CFrame"):Connect(Update))
    table.insert(
        self._cameraConnections,
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(Update)
    )
    table.insert(
        self._cameraConnections,
        camera:GetPropertyChangedSignal("FieldOfView"):Connect(Update)
    )

    table.insert(
        self._connections,
        self._frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(OnChange)
    )
    table.insert(
        self._connections,
        self._frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(OnChange)
    )

    table.insert(self._connections, Services.RunService.RenderStepped:Connect(Update))

    task.spawn(OnChange)
end

function AcrylicBlur:_StartRendering()
    self:_ConnectCamera()

    table.insert(
        self._connections,
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            if not self._destroyed then
                self:_ReparentToCamera()
                self:_ConnectCamera()
            end
        end)
    )
end

function AcrylicBlur:_ReparentToCamera()
    local camera = workspace.CurrentCamera
    if not camera or not self._folder then
        return
    end

    self._folder.Parent = camera
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
        self._root.Transparency = if enabled
            then (BlurDefaults.RootTransparency or 0.9)
            else (BlurDefaults.DisabledTransparency or 1)
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
    if self._destroyed then
        return
    end
    self._destroyed = true

    self:_DisconnectCamera()

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

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
