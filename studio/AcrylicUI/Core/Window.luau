--[[
    AcrylicUI - Window Component

    The main window container with dragging, resizing, and minimize support.
]]

local Services = require(script.Parent.Parent.Utils.Services)
local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Draggable = require(script.Parent.Parent.Utils.Draggable)
local Device = require(script.Parent.Parent.Utils.Device)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Icons = require(script.Parent.Parent.Constants.Icons)
local Layers = require(script.Parent.Parent.Constants.Layers)

local AcrylicBlur = require(script.Parent.AcrylicBlur)
local Notification = require(script.Parent.Notification)
local ConfigEncryption = require(script.Parent.Parent.Utils.ConfigEncryption)
local RandomString = require(script.Parent.Parent.Utils.RandomString)

local Window = {}
Window.__index = Window

Window._sharedScreenGui = nil
Window._sharedScreenGuiCount = 0
Window._sharedScreenGuiParent = nil

local function safeGet(name: string): (...any) -> ...any?
    local sources = {}

    local ok, env = pcall(function()
        local genv = rawget(_G, "getgenv")
        if type(genv) == "function" then
            return genv()
        end
        return nil
    end)
    if ok and type(env) == "table" then
        table.insert(sources, env)
    end

    ok, env = pcall(function()
        if type(getfenv) == "function" then
            return getfenv()
        end
        return nil
    end)
    if ok and type(env) == "table" then
        table.insert(sources, env)
    end

    table.insert(sources, _G)

    for _, src in ipairs(sources) do
        local fn = src[name]
        if type(fn) == "function" then
            return fn
        end
    end

    return nil
end

local writeFile = safeGet("writefile")
local readFile = safeGet("readfile")
local isFile = safeGet("isfile")
local makeFolder = safeGet("makefolder")
local isFolder = safeGet("isfolder")
local listFiles = safeGet("listfiles")
local deleteFile = safeGet("delfile")

export type WindowConfig = {
    Title: string?,
    Logo: string?,
    Size: { Width: number, Height: number }?,
    ToggleKey: Enum.KeyCode?,
    ConfigFolder: string?,
    ClampToViewport: boolean?,
    Parent: Instance?,
}

local WindowDefaults = Defaults.Window or {}
local ConfigDefaults = Defaults.Config or {}
local NotificationDefaults = Defaults.Notification or {}
local MessageDefaults = Defaults.Messages or {}
local CommonDefaults = Defaults.Components and Defaults.Components.Common or {}
local WindowIcons = Icons.Window or {}
local NotificationIcons = Icons.Notification or {}
local WindowLayers = Layers.Window or {}
local WindowChromeSizes = Sizes.WindowChrome or {}
local CONFIG_ROOT = ConfigDefaults.Root or "AcrylicConfigs"
local AUTOLOAD_CONFIG_NAME = ConfigDefaults.AutoLoadName or "_autoload"
local CONFIG_DEFAULT_NAME = ConfigDefaults.DefaultName or "default"
local CONFIG_EXTENSION = ConfigDefaults.Extension or ".json"
local CONFIG_EXTENSION_PATTERN = CONFIG_EXTENSION:gsub("(%W)", "%%%1")

local function SanitizeConfigName(configName: string?): string
    local sanitized = tostring(configName or CONFIG_DEFAULT_NAME)
    sanitized = sanitized:gsub("^%s+", ""):gsub("%s+$", "")
    sanitized = sanitized:gsub("%.%.", "_")
    sanitized = sanitized:gsub('[%/%\\%*%?"<>|:]', "_")
    sanitized = sanitized:gsub("^%.+", ""):gsub("%.+$", "")

    if sanitized == "" then
        sanitized = CONFIG_DEFAULT_NAME
    end

    return sanitized
end

local function GetConfigFolder(configFolder: string): string
    return CONFIG_ROOT .. "/" .. SanitizeConfigName(configFolder)
end

local function GetConfigPath(configFolder: string, configName: string): string
    return GetConfigFolder(configFolder)
        .. "/"
        .. SanitizeConfigName(configName)
        .. CONFIG_EXTENSION
end

local function GetAutoLoadPath(configFolder: string): string
    return GetConfigFolder(configFolder) .. "/" .. AUTOLOAD_CONFIG_NAME .. CONFIG_EXTENSION
end

local function EnsureConfigFolder(configFolder: string)
    if not makeFolder then
        return
    end

    if not isFolder or not isFolder(CONFIG_ROOT) then
        pcall(makeFolder, CONFIG_ROOT)
    end

    local folder = GetConfigFolder(configFolder)
    if not isFolder or not isFolder(folder) then
        pcall(makeFolder, folder)
    end
end

local function SerializeValue(value: any): any
    local valueType = typeof(value)

    if valueType == "Color3" then
        return {
            _type = "Color3",
            R = value.R,
            G = value.G,
            B = value.B,
        }
    end

    if valueType == "EnumItem" then
        return {
            _type = "EnumItem",
            EnumType = tostring(value.EnumType),
            Name = value.Name,
        }
    end

    return value
end

local function DeserializeValue(value: any): any
    if type(value) ~= "table" then
        return value
    end

    if value._type == "Color3" then
        return Color3.new(value.R, value.G, value.B)
    end

    if value._type == "EnumItem" then
        local enumName = tostring(value.EnumType):gsub("^Enum%.", "")
        local enumType = Enum[enumName]
        if enumType and enumType[value.Name] then
            return enumType[value.Name]
        end
    end

    return value
end

local function ResolveWindowSizes(requestedSize, clampToViewport)
    local maxWidth = Sizes.MaxWindow.Width
    local maxHeight = Sizes.MaxWindow.Height

    if clampToViewport then
        local viewport = Device.GetViewportSize()
        local margin = Device.IsMobile() and (WindowChromeSizes.MobileViewportMargin or 24)
            or (WindowChromeSizes.DesktopViewportMargin or 40)
        maxWidth = math.max(WindowChromeSizes.MinMobileWidth or 320, viewport.X - margin)
        maxHeight = math.max(WindowChromeSizes.MinMobileHeight or 240, viewport.Y - margin)
    end

    local defaultWidth = requestedSize and requestedSize.Width or Sizes.Window.Width
    local defaultHeight = requestedSize and requestedSize.Height or Sizes.Window.Height

    if Device.IsMobile() then
        defaultWidth = math.min(defaultWidth, maxWidth)
        defaultHeight = math.min(defaultHeight, maxHeight)
    end

    local minWidth = math.min(Sizes.MinWindow.Width, maxWidth)
    local minHeight = math.min(Sizes.MinWindow.Height, maxHeight)
    local resolvedMaxWidth = math.min(Sizes.MaxWindow.Width, maxWidth)
    local resolvedMaxHeight = math.min(Sizes.MaxWindow.Height, maxHeight)

    minWidth = math.min(minWidth, resolvedMaxWidth)
    minHeight = math.min(minHeight, resolvedMaxHeight)

    return {
        Width = math.clamp(defaultWidth, minWidth, resolvedMaxWidth),
        Height = math.clamp(defaultHeight, minHeight, resolvedMaxHeight),
    }, {
        Width = minWidth,
        Height = minHeight,
    }, {
        Width = resolvedMaxWidth,
        Height = resolvedMaxHeight,
    }
end

--[[
    Creates a new window

    @param config WindowConfig - Window configuration
    @return Window - Window instance

    @example
    local window = Window.new({
        Title = "My Hub",
        Size = { Width = 700, Height = 450 },
        ToggleKey = Enum.KeyCode.RightControl
    })
]]
function Window.new(config: WindowConfig?)
    config = config or {}
    local self = setmetatable({}, Window)

    -- Apply theme overrides before building UI
    if config.Theme then
        Colors:SetTheme(config.Theme)
    end

    local clampToViewport = if config.ClampToViewport == nil
        then (WindowDefaults.ClampToViewport ~= false)
        else config.ClampToViewport
    local resolvedSize, minSize, maxSize = ResolveWindowSizes(config.Size, clampToViewport)

    self._title = config.Title or WindowDefaults.Title or "AcrylicUI"
    self._logo = config.Logo or "rbxassetid://94586681223401"
    self._size = resolvedSize
    self._minSize = minSize
    self._maxSize = maxSize
    self._toggleKey = config.ToggleKey or WindowDefaults.ToggleKey or Enum.KeyCode.RightControl
    self._parent = config.Parent
    self._configFolder = SanitizeConfigName(config.ConfigFolder or self._title)
    self._visible = true
    self._minimized = false
    self._minimizedChangedEvent = Instance.new("BindableEvent")
    self._sections = {}
    self._keybinds = {}
    self._configElements = {}
    self._connections = {}
    self._currentTab = nil
    self._originalHeight = self._size.Height
    self._autoSave = false
    self._autoSaveThreadRunning = false
    self._currentConfig = CONFIG_DEFAULT_NAME
    self._destroyed = false
    self._autoLoad = false
    self._autoLoadConfigName = CONFIG_DEFAULT_NAME
    self._pendingConfigData = nil
    self:_LoadAutoLoadState()

    self:_CreateGui()
    self:_SetupKeybinds()
    self:_CreateSabotageTab()

    if Device.IsMobile() then
        self:_SetupMobileToggle()
    end

    if self._autoLoad then
        self:ApplyAutoLoad()
    end

    return self
end

function Window:_FindGuiParent(): Instance
    if self._parent then
        return self._parent
    end

    local getHui = safeGet("gethui")
    local ok, result = pcall(function()
        if getHui then
            return getHui()
        end
        return nil
    end)
    if ok and result then
        return result
    end

    local getHiddenGui = safeGet("get_hidden_gui")
    ok, result = pcall(function()
        if getHiddenGui then
            return getHiddenGui()
        end
        return nil
    end)
    if ok and result then
        return result
    end

    ok, result = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and result then
        return result
    end

    return Services.Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Window:_CreateGui()
    local guiParent = self:_FindGuiParent()
    local Protection = Services.Protection or {}

    if not self._parent then
        -- Use shared ScreenGui
        if not Window._sharedScreenGui or Window._sharedScreenGuiParent ~= guiParent then
            Window._sharedScreenGui = Create.Instance("ScreenGui", {
                Name = RandomString.new(),
                IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Global,
                ResetOnSpawn = false,
            })
            if Protection.ProtectGui then
                Protection.ProtectGui(Window._sharedScreenGui)
            end
            Window._sharedScreenGui.Parent = guiParent
            Window._sharedScreenGuiCount = 0
            Window._sharedScreenGuiParent = guiParent
        end
        Window._sharedScreenGuiCount += 1
        self._screenGui = Window._sharedScreenGui
        self._usesSharedScreenGui = true
    else
        -- Create dedicated ScreenGui for this parent
        self._screenGui = Create.Instance("ScreenGui", {
            Name = RandomString.new(),
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            ResetOnSpawn = false,
        })
        if Protection.ProtectGui then
            Protection.ProtectGui(self._screenGui)
        end
        self._screenGui.Parent = guiParent
        self._usesSharedScreenGui = false
    end

    -- Main container
    self._container = Create.Instance("Frame", {
        Name = "Container",
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.05,
        Position = UDim2.new(0.5, -self._size.Width / 2, 0.5, -self._size.Height / 2),
        BorderSizePixel = 0,
        Size = UDim2.new(0, self._size.Width, 0, self._size.Height),
        ClipsDescendants = false,
        Parent = self._screenGui,
    })

    Create.Corner(self._container, Sizes.Corner.Window)
    Create.Stroke(self._container)

    -- Title
    self._titleLabel = Create.Instance("TextLabel", {
        Name = "StudioTopbarTitle",
        FontFace = Fonts.Bold,
        TextColor3 = Colors.Text,
        Text = self._title,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = 14,
        Size = UDim2.new(1, -160, 0, WindowChromeSizes.TitleHeight or 25),
        Visible = true,
        ZIndex = (WindowLayers.TopBarControls or 6) + 1,
        Parent = self._container,
    })
    self._titleLabel.Name = "StudioTopbarTitle"
    self._titleLabel.Visible = true
    self._titleLabel.TextSize = 14
    self._titleLabel.Position = UDim2.new(0, 40, 0, 10)
    self._titleLabel.Size = UDim2.new(1, -160, 0, WindowChromeSizes.TitleHeight or 25)

    -- Topbar drag area (covers full topbar minus the controls frame).
    self._topBarDragArea = Create.Instance("Frame", {
        Name = "TopBarDragArea",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(
            1,
            -(WindowChromeSizes.TopBarControlsWidth or 80),
            0,
            WindowChromeSizes.HeaderHeight or 45
        ),
        ZIndex = WindowLayers.TopBarDragArea or 5,
        Parent = self._container,
    })

    self:_CreateContentArea()
    -- Controls are created after content so resize stays above scroll layers.
    self:_CreateWindowControls()

    -- Make draggable
    self._dragConnection = Draggable.Enable(self._container, self._topBarDragArea)
    self._bottomDragConnection = Draggable.Enable(self._container, self._bottomDragArea)

    -- Acrylic blur effect. Some executors block 3D/effect properties; keep UI alive without blur.
    local blurOk, blur = pcall(AcrylicBlur.new, self._container)
    if blurOk then
        self._acrylicBlur = blur
    else
        self._acrylicBlur = nil
        warn("[AcrylicUI] Acrylic blur disabled: " .. tostring(blur))
    end

    -- Notification container
    Notification.CreateContainer(self._screenGui)
end

function Window:_ApplyTopbarIconHover(icon: ImageLabel, hoverColor: Color3?, trigger: GuiObject?)
    local normalColor = icon.ImageColor3
    local normalSize = icon.Size
    local hoverTrigger = trigger or icon
    local hoverSize = UDim2.new(
        normalSize.X.Scale,
        normalSize.X.Offset + 2,
        normalSize.Y.Scale,
        normalSize.Y.Offset + 2
    )

    table.insert(
        self._connections,
        hoverTrigger.MouseEnter:Connect(function()
            Tween.Create(
                icon,
                { ImageColor3 = hoverColor or Colors.Text, Size = hoverSize },
                "Fast"
            )
        end)
    )
    table.insert(
        self._connections,
        hoverTrigger.MouseLeave:Connect(function()
            Tween.Create(icon, { ImageColor3 = normalColor, Size = normalSize }, "Fast")
        end)
    )
end

function Window:_CreateWindowControls()
    -- Topbar controls frame (excluded from the topbar drag area).
    self._topBarControls = Create.Instance("Frame", {
        Name = "TopBarControls",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(
            0,
            WindowChromeSizes.TopBarControlsWidth or 80,
            0,
            WindowChromeSizes.HeaderHeight or 45
        ),
        ZIndex = WindowLayers.TopBarControls or 6,
        Parent = self._container,
    })

    self._logoIcon = Create.Instance("ImageLabel", {
        Name = "StudioTopbarLogo",
        BackgroundTransparency = 1,
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0, 23),
        Size = UDim2.new(0, 26, 0, 26),
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = (WindowLayers.TopBarControls or 6) + 1,
        Parent = self._container,
    })
    Create.ApplyIcon(self._logoIcon, self._logo)
    self:_ApplyTopbarIconHover(self._logoIcon, Colors.Text)

    local function createActionIcon(name: string, iconAsset, rightOffset: number): ImageLabel
        local frame = Create.Instance("Frame", {
            Name = name .. "Frame",
            BackgroundColor3 = Colors.Background,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -rightOffset, 0, 23),
            Size = UDim2.new(0, 26, 0, 26),
            ZIndex = (WindowLayers.TopBarControls or 6) + 1,
            Parent = self._container,
        })
        Create.Corner(frame, 8)
        Create.Stroke(frame, Colors.Border, 0.4, 1)

        local icon = Create.Instance("ImageLabel", {
            Name = name,
            BackgroundTransparency = 1,
            ImageColor3 = Colors.TextDark,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 15, 0, 15),
            ZIndex = (WindowLayers.TopBarControls or 6) + 2,
            Parent = frame,
        })
        Create.ApplyIcon(icon, iconAsset)

        local click = Create.Instance("TextButton", {
            Name = name .. "Click",
            Text = CommonDefaults.EmptyText or "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = (WindowLayers.TopBarControls or 6) + 3,
            Parent = frame,
        })

        self:_ApplyTopbarIconHover(icon, Colors.Text, click)

        return icon
    end

    createActionIcon("StudioTopbarConfig", "rbxassetid://11293977610", 72)
    createActionIcon("StudioTopbarBell", "rbxassetid://11295275950", 40)

    local topbarAvatar = Create.Instance("ImageLabel", {
        Name = "StudioTopbarAvatar",
        BackgroundTransparency = 1,
        Image = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0, 22),
        Size = UDim2.new(0, 26, 0, 26),
        ZIndex = (WindowLayers.TopBarControls or 6) + 1,
        Parent = self._container,
    })
    Create.Instance("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = topbarAvatar,
    })

    local localPlayer = Services.Players.LocalPlayer
    if localPlayer then
        task.spawn(function()
            local ok, thumbnail = pcall(function()
                return Services.Players:GetUserThumbnailAsync(
                    localPlayer.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size48x48
                )
            end)
            if ok and topbarAvatar.Parent then
                topbarAvatar.Image = thumbnail
            end
        end)
    end

    local controlButtonWidth = WindowChromeSizes.ControlFrameButtonWidth or 31
    local controlFrameGap = WindowChromeSizes.ControlFrameGap or 1
    local controlFrameRightInset = WindowChromeSizes.ControlFrameRightInset or 5
    local controlFrameHeight = WindowChromeSizes.ControlFrameHeight or 31
    local controlFrameTop = WindowChromeSizes.ControlFrameTop or 7

    local function createControlFrame(name: string, rightOffset: number): Frame
        local controlFrame = Create.Instance("Frame", {
            Name = name,
            BackgroundColor3 = Color3.fromRGB(163, 162, 165),
            BackgroundTransparency = 1,
            BorderColor3 = Color3.fromRGB(27, 42, 53),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -rightOffset, 0, controlFrameTop),
            Size = UDim2.new(0, controlButtonWidth, 0, controlFrameHeight),
            ZIndex = WindowLayers.TopBarControls or 6,
            Parent = self._topBarControls,
        })
        Create.Instance("UICorner", {
            CornerRadius = UDim.new(0, 5),
            Parent = controlFrame,
        })
        Create.Instance("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            BorderStrokePosition = Enum.BorderStrokePosition.Inner,
            Color = Colors.Border,
            LineJoinMode = Enum.LineJoinMode.Round,
            StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
            Thickness = 1,
            Transparency = 0,
            Parent = controlFrame,
        })

        return controlFrame
    end

    local closeControlFrame = createControlFrame("CloseControlFrame", controlFrameRightInset)
    local minimizeControlFrame = createControlFrame(
        "MinimizeControlFrame",
        controlFrameRightInset + controlButtonWidth + controlFrameGap
    )
    minimizeControlFrame.Visible = false
    closeControlFrame.Visible = false

    -- Minimize button
    local minimizeBtn = Create.Instance("ImageLabel", {
        Name = "Minimize",
        ImageColor3 = Colors.TextDark,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(
            0,
            WindowChromeSizes.ControlSize or 15,
            0,
            WindowChromeSizes.ControlSize or 15
        ),
        ZIndex = (WindowLayers.TopBarControls or 6) + 1,
        Parent = minimizeControlFrame,
    })
    Create.ApplyIcon(minimizeBtn, nil, WindowIcons.Minimize)

    local minimizeClick = Create.Instance("TextButton", {
        Name = "ClickArea",
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = (WindowLayers.TopBarControls or 6) + 2,
        Parent = minimizeControlFrame,
    })

    minimizeClick.MouseButton1Click:Connect(function()
        self:_ToggleMinimize()
    end)

    minimizeClick.MouseEnter:Connect(function()
        Tween.Create(minimizeBtn, { ImageColor3 = Colors.Text }, "Fast")
    end)

    minimizeClick.MouseLeave:Connect(function()
        Tween.Create(minimizeBtn, { ImageColor3 = Colors.TextDark }, "Fast")
    end)

    -- Close button
    local closeBtn = Create.Instance("ImageLabel", {
        Name = "Close",
        ImageColor3 = Colors.TextDark,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(
            0,
            WindowChromeSizes.ControlSize or 15,
            0,
            WindowChromeSizes.ControlSize or 15
        ),
        ZIndex = (WindowLayers.TopBarControls or 6) + 1,
        Parent = closeControlFrame,
    })
    Create.ApplyIcon(closeBtn, nil, WindowIcons.Close)

    local closeClick = Create.Instance("TextButton", {
        Name = "ClickArea",
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = (WindowLayers.TopBarControls or 6) + 2,
        Parent = closeControlFrame,
    })

    closeClick.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    closeClick.MouseEnter:Connect(function()
        Tween.Create(closeBtn, { ImageColor3 = Colors.CloseHover }, "Fast")
    end)

    closeClick.MouseLeave:Connect(function()
        Tween.Create(closeBtn, { ImageColor3 = Colors.TextDark }, "Fast")
    end)

    -- Resize handle
    self._resizeBtn = Create.Instance("ImageButton", {
        Name = "Resize",
        Active = true,
        ImageColor3 = Colors.ResizeHandle,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(
            1,
            -(WindowChromeSizes.ResizeOffset or 5),
            1,
            -(WindowChromeSizes.ResizeOffset or 5)
        ),
        Size = UDim2.new(
            0,
            WindowChromeSizes.ResizeWidth or 62,
            0,
            WindowChromeSizes.ResizeHeight or 60
        ),
        BorderSizePixel = 0,
        ZIndex = WindowLayers.ResizeHandle or 1000,
        Parent = self._container,
    })
    Create.ApplyIcon(self._resizeBtn, nil, WindowIcons.Resize)

    -- Bottom drag handle
    self._bottomDragArea = Create.Instance("TextButton", {
        Name = "BottomDragArea",
        Active = true,
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(
            0,
            WindowChromeSizes.BottomDragWidth or 140,
            0,
            WindowChromeSizes.BottomDragHeight or 18
        ),
        BorderSizePixel = 0,
        ZIndex = WindowLayers.BottomDragArea or 1000,
        Parent = self._container,
    })

    self._bottomDragBar = Create.Instance("Frame", {
        Name = "BottomDragBar",
        BackgroundColor3 = Colors.ResizeHandle,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, WindowChromeSizes.BottomDragBarTop or 4.5),
        Size = UDim2.new(
            0,
            WindowChromeSizes.BottomDragBarWidth or 90,
            0,
            WindowChromeSizes.BottomDragBarHeight or 4
        ),
        BorderSizePixel = 0,
        ZIndex = WindowLayers.BottomDragBar or 1001,
        Parent = self._bottomDragArea,
    })

    Create.Corner(self._bottomDragBar, Sizes.Corner.Full)

    self:_SetupResize()
    self:_SetupBottomDragHandle()
end

function Window:_CreateContentArea()
    -- Header separator
    self._headerSeparator = Create.Instance("Frame", {
        Name = "HeaderSeparator",
        BackgroundColor3 = Colors.Border,
        Position = UDim2.new(0, 0, 0, WindowChromeSizes.HeaderHeight or 45),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self._container,
    })

    -- Main content area
    self._mainContent = Create.Instance("Frame", {
        Name = "MainContent",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, WindowChromeSizes.ContentTop or 46),
        Size = UDim2.new(1, 0, 1, -(WindowChromeSizes.ContentTop or 46)),
        ClipsDescendants = true,
        Parent = self._container,
    })

    -- Sections sidebar
    self._sectionsContainer = Create.Instance("ScrollingFrame", {
        Name = "Sections",
        ScrollBarThickness = 0,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, WindowChromeSizes.SidebarWidth or 165, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self._mainContent,
    })

    Create.ListLayout(self._sectionsContainer, 0)
    Create.Padding(self._sectionsContainer, 5, 5, 5, 5)

    -- Separator
    Create.Instance("Frame", {
        Name = "Separator",
        BackgroundColor3 = Colors.Border,
        Position = UDim2.new(0, WindowChromeSizes.SidebarWidth or 165, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, 0),
        Parent = self._mainContent,
    })

    -- Content area
    self._contentContainer = Create.Instance("ScrollingFrame", {
        Name = "Content",
        ScrollBarThickness = WindowChromeSizes.ContentScrollbarThickness or 3,
        ScrollBarImageColor3 = Colors.Scrollbar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, WindowChromeSizes.ContentLeft or 166, 0, 0),
        Size = UDim2.new(1, -(WindowChromeSizes.ContentLeft or 166), 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self._mainContent,
    })

    Create.ListLayout(self._contentContainer, 8)
    Create.Padding(self._contentContainer, 10, 10, 15, 15)

    self._popupLayer = Create.Instance("Frame", {
        Name = "PopupLayer",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = WindowLayers.PopupLayer or 900,
        Parent = self._mainContent,
    })
end

function Window:_SetupResize()
    local resizing = false
    local startSize, startInput, lastPos

    table.insert(
        self._connections,
        self._resizeBtn.MouseEnter:Connect(function()
            Tween.Create(self._resizeBtn, { ImageColor3 = Colors.Text }, "Fast")
        end)
    )

    table.insert(
        self._connections,
        self._resizeBtn.MouseLeave:Connect(function()
            if not resizing then
                Tween.Create(self._resizeBtn, { ImageColor3 = Colors.ResizeHandle }, "Fast")
            end
        end)
    )

    table.insert(
        self._connections,
        self._resizeBtn.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                resizing = true
                startSize = self._container.AbsoluteSize
                startInput = Services.UserInputService:GetMouseLocation()
                lastPos = startInput
                self._originalHeight = startSize.Y

                local renderConn
                renderConn = Services.RunService.RenderStepped:Connect(function()
                    if not resizing then
                        return
                    end
                    local currentPos = Services.UserInputService:GetMouseLocation()
                    if currentPos == lastPos then
                        return
                    end
                    lastPos = currentPos

                    local delta = currentPos - startInput
                    local newWidth =
                        math.clamp(startSize.X + delta.X, self._minSize.Width, self._maxSize.Width)
                    local newHeight = math.clamp(
                        startSize.Y + delta.Y,
                        self._minSize.Height,
                        self._maxSize.Height
                    )

                    self._container.Size = UDim2.new(0, newWidth, 0, newHeight)
                    self._originalHeight = newHeight
                end)
                table.insert(self._connections, renderConn)

                local resizeInput = input
                local endConn
                endConn = Services.UserInputService.InputEnded:Connect(function(endInput)
                    if endInput == resizeInput then
                        resizing = false
                        renderConn:Disconnect()
                        Tween.Create(self._resizeBtn, { ImageColor3 = Colors.ResizeHandle }, "Fast")
                        endConn:Disconnect()
                    end
                end)
                table.insert(self._connections, endConn)
            end
        end)
    )
end

function Window:_SetupBottomDragHandle()
    local hovering = false
    local holding = false

    local function update()
        local color = (hovering or holding) and Colors.Text or Colors.ResizeHandle
        local height = holding and (WindowChromeSizes.BottomDragBarHoldingHeight or 5.5)
            or (WindowChromeSizes.BottomDragBarHeight or 4)

        Tween.Create(self._bottomDragBar, {
            BackgroundColor3 = color,
            Size = UDim2.new(0, WindowChromeSizes.BottomDragBarWidth or 90, 0, height),
        }, "Fast")
    end

    table.insert(
        self._connections,
        self._bottomDragArea.MouseEnter:Connect(function()
            hovering = true
            update()
        end)
    )

    table.insert(
        self._connections,
        self._bottomDragArea.MouseLeave:Connect(function()
            hovering = false
            update()
        end)
    )

    table.insert(
        self._connections,
        self._bottomDragArea.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                holding = true
                update()

                local holdInput = input
                local connection
                connection = Services.UserInputService.InputEnded:Connect(function(endInput)
                    if endInput == holdInput then
                        holding = false
                        update()
                        connection:Disconnect()
                    end
                end)

                table.insert(self._connections, connection)
            end
        end)
    )
end

function Window:_ToggleMinimize()
    self._minimized = not self._minimized
    self._minimizedChangedEvent:Fire(self._minimized)

    if self._minimized then
        Tween.Create(self._mainContent, { Size = UDim2.new(1, 0, 0, 0) }, "Slow")
        Tween.Create(self._container, {
            Size = UDim2.new(
                0,
                self._container.AbsoluteSize.X,
                0,
                WindowChromeSizes.HeaderHeight or 45
            ),
        }, "Slow")
        self._headerSeparator.Visible = false
        self._resizeBtn.Visible = false
        self._bottomDragArea.Visible = false
    else
        Tween.Create(self._container, {
            Size = UDim2.new(0, self._container.AbsoluteSize.X, 0, self._originalHeight),
        }, "Slow")
        self._headerSeparator.Visible = true
        task.delay(WindowDefaults.MinimizeRestoreDelay or 0.1, function()
            Tween.Create(
                self._mainContent,
                { Size = UDim2.new(1, 0, 1, -(WindowChromeSizes.ContentTop or 46)) },
                "Normal"
            )
        end)
        self._resizeBtn.Visible = true
        self._bottomDragArea.Visible = true
    end
end

function Window:_SetupKeybinds()
    table.insert(
        self._connections,
        Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then
                return
            end

            if input.KeyCode == self._toggleKey then
                self:Toggle()
            end

            for _, keybindData in pairs(self._keybinds) do
                if input.KeyCode == keybindData.key then
                    keybindData.callback()
                end
            end
        end)
    )
end

function Window:_SetupMobileToggle()
    self._mobileToggle = Create.Instance("ImageButton", {
        Name = "MobileToggle",
        ImageColor3 = Colors.Text,
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.1,
        Position = UDim2.new(
            0,
            WindowChromeSizes.MobileToggleX or 15,
            0.5,
            WindowChromeSizes.MobileToggleYOffset or -25
        ),
        Size = UDim2.new(
            0,
            WindowChromeSizes.MobileToggleSize or 50,
            0,
            WindowChromeSizes.MobileToggleSize or 50
        ),
        AnchorPoint = Vector2.new(0, 0.5),
        Visible = false,
        Parent = self._screenGui,
    })
    Create.ApplyIcon(self._mobileToggle, nil, WindowIcons.MobileToggle)

    Create.Corner(self._mobileToggle, WindowChromeSizes.MobileToggleCorner or 25)
    Create.Stroke(self._mobileToggle)

    local dragging = false
    local dragStart: Vector3?
    local startPos: UDim2?

    table.insert(
        self._connections,
        self._mobileToggle.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1
            then
                dragging = true
                dragStart = input.Position
                startPos = self._mobileToggle.Position
            end
        end)
    )

    table.insert(
        self._connections,
        self._mobileToggle.InputEnded:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1
            then
                if dragging and dragStart then
                    local delta = input.Position - dragStart
                    if delta.Magnitude < (WindowChromeSizes.MobileTapThreshold or 10) then
                        self:Toggle()
                    end
                end
                dragging = false
            end
        end)
    )

    table.insert(
        self._connections,
        Services.UserInputService.InputChanged:Connect(function(input)
            if
                dragging
                and dragStart
                and startPos
                and (
                    input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseMovement
                )
            then
                local delta = input.Position - dragStart
                self._mobileToggle.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    )
end

--[[
    Toggles window visibility
]]
function Window:Toggle()
    self._visible = not self._visible
    self._container.Visible = self._visible

    if self._acrylicBlur then
        self._acrylicBlur:SetEnabled(self._visible)
    end

    if self._mobileToggle then
        self._mobileToggle.Visible = not self._visible
    end
end

--[[
    Sets the toggle key for showing/hiding the window

    @param keyCode Enum.KeyCode - The key to use
]]
function Window:SetToggleKey(keyCode: Enum.KeyCode)
    self._toggleKey = keyCode
end

--[[
    Sets the topbar logo image.

    @param assetId string? - Roblox asset ID. Defaults to the built-in logo.
]]
function Window:Logo(assetId: string?)
    if self._logoIcon then
        self._logo = assetId or "rbxassetid://94586681223401"
        Create.ApplyIcon(self._logoIcon, self._logo)
    end
end

--[[
    Shows a notification

    @param config NotificationConfig - Notification configuration
]]
function Window:Notify(config)
    return Notification.Show(config, self._screenGui, self._title)
end

--[[
    Creates a new section in the sidebar

    @param name string - Section name
    @return Section - Section instance
]]
function Window:CreateSection(name: string)
    local Section = require(script.Parent.Parent.Components.Section)
    local section = Section.new(self, name)
    table.insert(self._sections, section)
    return section
end

function Window:_CreateSabotageTab()
    local sabotageSection = self:CreateSection("Sabotage")
    local sabotageTab = sabotageSection:CreateTab("Sabotage", nil)
    sabotageTab:CreateSabotageSection()
    self._sabotageTab = sabotageTab
    return sabotageTab
end

--[[
    Selects a tab

    @param tab Tab - The tab to select
]]
function Window:SelectTab(tab)
    if self._currentTab then
        self._currentTab:Deselect()
    end

    self._currentTab = tab
    tab:Select()
end

--[[
    Registers a keybind

    @param id string - Unique identifier
    @param key Enum.KeyCode - The key
    @param callback function - Callback function
]]
function Window:RegisterKeybind(id: string, key: Enum.KeyCode, callback: () -> ())
    self._keybinds[id] = {
        key = key,
        callback = callback,
    }
end

function Window:UnregisterKeybind(id: string)
    self._keybinds[id] = nil
end

--[[
    Updates a registered keybind

    @param id string - Keybind identifier
    @param key Enum.KeyCode - New key
]]
function Window:UpdateKeybind(id: string, key: Enum.KeyCode)
    if self._keybinds[id] then
        self._keybinds[id].key = key
    end
end

function Window:RegisterConfigElement(
    flag: string,
    elementType: string,
    getValue: () -> any,
    setValue: (any) -> ()
)
    local sanitizedFlag = SanitizeConfigName(flag)
    self._configElements[sanitizedFlag] = {
        type = elementType,
        getValue = getValue,
        setValue = setValue,
    }

    if self._pendingConfigData and self._pendingConfigData[sanitizedFlag] ~= nil then
        local success, err = pcall(function()
            setValue(DeserializeValue(self._pendingConfigData[sanitizedFlag]))
        end)
        if not success then
            warn(
                string.format(
                    "[AcrylicUI] Failed to apply pending config '%s': %s",
                    sanitizedFlag,
                    tostring(err)
                )
            )
        end
        self._pendingConfigData[sanitizedFlag] = nil
    end
end

function Window:UnregisterConfigElement(flag: string)
    self._configElements[SanitizeConfigName(flag)] = nil
end

function Window:SaveConfig(configName: string?): boolean
    if not writeFile then
        self:Notify({
            Title = MessageDefaults.ErrorTitle or "Error",
            Description = MessageDefaults.ConfigSystemUnsupported or "Config system not supported",
            Duration = NotificationDefaults.Duration or 3,
        })
        return false
    end

    local sanitizedName = SanitizeConfigName(configName or self._currentConfig)

    if sanitizedName == AUTOLOAD_CONFIG_NAME then
        self:Notify({
            Title = MessageDefaults.ErrorTitle or "Error",
            Description = MessageDefaults.ConfigReservedName or "Name reserved for internal use",
            Duration = NotificationDefaults.Duration or 3,
        })
        return false
    end

    EnsureConfigFolder(self._configFolder)

    local configData = {}
    for flag, element in pairs(self._configElements) do
        configData[flag] = SerializeValue(element.getValue())
    end

    local success = pcall(function()
        local jsonData = Services.HttpService:JSONEncode(configData)
        local encryptedData = ConfigEncryption.Encrypt(jsonData)
        writeFile(GetConfigPath(self._configFolder, sanitizedName), encryptedData)
    end)

    if success then
        self._currentConfig = sanitizedName
        if self._autoLoad then
            self._autoLoadConfigName = sanitizedName
            self:_SaveAutoLoadState()
        end
        self:Notify({
            Title = MessageDefaults.ConfigSavedTitle or "Config Saved",
            Description = (MessageDefaults.ConfigSavedDescriptionPrefix or "Saved as: ")
                .. sanitizedName,
            Duration = NotificationDefaults.SuccessDuration or 2,
            Icon = NotificationIcons.Config or "rbxassetid://10723356507",
        })
        return true
    end

    self:Notify({
        Title = MessageDefaults.ErrorTitle or "Error",
        Description = MessageDefaults.ConfigSaveFailed or "Failed to save config",
        Duration = NotificationDefaults.Duration or 3,
    })
    return false
end

function Window:LoadConfig(configName: string?): boolean
    if not readFile or not isFile then
        self:Notify({
            Title = MessageDefaults.ErrorTitle or "Error",
            Description = MessageDefaults.ConfigSystemUnsupported or "Config system not supported",
            Duration = NotificationDefaults.Duration or 3,
        })
        return false
    end

    local sanitizedName = SanitizeConfigName(configName or self._currentConfig)

    if sanitizedName == AUTOLOAD_CONFIG_NAME then
        self:Notify({
            Title = MessageDefaults.ErrorTitle or "Error",
            Description = MessageDefaults.ConfigReservedName or "Name reserved for internal use",
            Duration = NotificationDefaults.Duration or 3,
        })
        return false
    end

    local path = GetConfigPath(self._configFolder, sanitizedName)

    if not isFile(path) then
        self:Notify({
            Title = MessageDefaults.ErrorTitle or "Error",
            Description = (MessageDefaults.ConfigNotFoundPrefix or "Config not found: ")
                .. sanitizedName,
            Duration = NotificationDefaults.Duration or 3,
        })
        return false
    end

    local rawData = readFile(path)
    local isEncrypted = ConfigEncryption.IsEncrypted(rawData)
    local success, data

    if isEncrypted then
        success, data = pcall(function()
            local decrypted = ConfigEncryption.Decrypt(rawData)
            return Services.HttpService:JSONDecode(decrypted)
        end)
    else
        -- Plain JSON (legacy) - re-save as encrypted after a successful decode.
        success, data = pcall(function()
            return Services.HttpService:JSONDecode(rawData)
        end)
        if success and data then
            pcall(function()
                writeFile(
                    GetConfigPath(self._configFolder, sanitizedName),
                    ConfigEncryption.Encrypt(rawData)
                )
            end)
        end
    end

    if not success or type(data) ~= "table" then
        self:Notify({
            Title = MessageDefaults.ErrorTitle or "Error",
            Description = MessageDefaults.ConfigLoadFailed or "Failed to load config",
            Duration = NotificationDefaults.Duration or 3,
        })
        return false
    end

    for flag, value in pairs(data) do
        local element = self._configElements[flag]
        if element then
            local ok, err = pcall(function()
                element.setValue(DeserializeValue(value))
            end)
            if not ok then
                warn(
                    string.format(
                        "[AcrylicUI] Failed to apply config '%s' for element '%s': %s",
                        flag,
                        tostring(element.type or "?"),
                        tostring(err)
                    )
                )
            end
        else
            if not self._pendingConfigData then
                self._pendingConfigData = {}
            end
            self._pendingConfigData[flag] = value
        end
    end

    self._currentConfig = sanitizedName
    if self._autoLoad then
        self._autoLoadConfigName = sanitizedName
        self:_SaveAutoLoadState()
    end
    self:Notify({
        Title = MessageDefaults.ConfigLoadedTitle or "Config Loaded",
        Description = (MessageDefaults.ConfigLoadedDescriptionPrefix or "Loaded: ")
            .. sanitizedName,
        Duration = NotificationDefaults.SuccessDuration or 2,
        Icon = NotificationIcons.Config or "rbxassetid://10723356507",
    })
    return true
end

function Window:DeleteConfig(configName: string?): boolean
    if not deleteFile or not isFile then
        return false
    end

    local sanitizedName = SanitizeConfigName(configName or self._currentConfig)

    if sanitizedName == AUTOLOAD_CONFIG_NAME then
        return false
    end

    local path = GetConfigPath(self._configFolder, sanitizedName)

    if not isFile(path) then
        return false
    end

    deleteFile(path)
    self:Notify({
        Title = MessageDefaults.ConfigDeletedTitle or "Config Deleted",
        Description = (MessageDefaults.ConfigDeletedDescriptionPrefix or "Deleted: ")
            .. sanitizedName,
        Duration = NotificationDefaults.SuccessDuration or 2,
    })
    return true
end

function Window:GetConfigs(): { string }
    local configs = {}
    if not listFiles or not isFolder then
        return configs
    end

    EnsureConfigFolder(self._configFolder)

    local folder = GetConfigFolder(self._configFolder)
    if not isFolder(folder) then
        return configs
    end

    for _, file in ipairs(listFiles(folder)) do
        local fileName = file:match("[^/\\]+$") or file
        local configName = fileName:match("(.+)" .. CONFIG_EXTENSION_PATTERN .. "$")
        if configName and configName ~= AUTOLOAD_CONFIG_NAME then
            table.insert(configs, configName)
        end
    end

    table.sort(configs)
    return configs
end

function Window:SetAutoSave(enabled: boolean)
    self._autoSave = enabled

    if not enabled or self._autoSaveThreadRunning then
        return
    end

    self._autoSaveThreadRunning = true
    task.spawn(function()
        while
            self._autoSave
            and not self._destroyed
            and self._screenGui
            and self._screenGui.Parent
        do
            task.wait(WindowDefaults.AutoSaveInterval or 30)
            if self._autoSave and not self._destroyed then
                self:SaveConfig(self._currentConfig)
            end
        end
        self._autoSaveThreadRunning = false
    end)
end

--[[
    Enables or disables auto-load (persists config across sessions)

    @param enabled boolean - Whether to auto-load on startup
]]
function Window:SetAutoLoad(enabled: boolean): boolean
    if enabled then
        local sanitizedName = SanitizeConfigName(self._currentConfig)
        if sanitizedName == AUTOLOAD_CONFIG_NAME then
            sanitizedName = CONFIG_DEFAULT_NAME
        end

        local path = GetConfigPath(self._configFolder, sanitizedName)
        if readFile and isFile and not isFile(path) then
            self:Notify({
                Title = MessageDefaults.ErrorTitle or "Error",
                Description = MessageDefaults.ConfigAutoLoadNeedsConfig
                    or "Save or load a config before enabling Auto Load",
                Duration = NotificationDefaults.Duration or 3,
            })
            return false
        end

        self._autoLoadConfigName = sanitizedName
    end

    self._autoLoad = enabled
    self:_SaveAutoLoadState()
    return true
end

--[[
    Returns whether auto-load is enabled

    @return boolean - Current auto-load state
]]
function Window:GetAutoLoad(): boolean
    return self._autoLoad
end

--[[
    Applies auto-load: loads the last saved config if auto-load is enabled
]]
function Window:ApplyAutoLoad()
    if not self._autoLoad or not readFile or not isFile then
        return
    end

    local path = GetConfigPath(self._configFolder, self._autoLoadConfigName)
    if isFile(path) then
        self:LoadConfig(self._autoLoadConfigName)
    end
end

--[[
    Saves the current auto-load state to a file
]]
function Window:_SaveAutoLoadState()
    if not writeFile then
        return
    end

    EnsureConfigFolder(self._configFolder)
    local path = GetAutoLoadPath(self._configFolder)

    local data = {
        enabled = self._autoLoad,
        lastConfig = self._autoLoadConfigName,
    }

    pcall(function()
        writeFile(path, Services.HttpService:JSONEncode(data))
    end)
end

--[[
    Loads the auto-load state from file
]]
function Window:_LoadAutoLoadState()
    if not readFile or not isFile then
        return
    end

    local path = GetAutoLoadPath(self._configFolder)
    if not isFile(path) then
        return
    end

    local success, data = pcall(function()
        return Services.HttpService:JSONDecode(readFile(path))
    end)

    if success and type(data) == "table" then
        self._autoLoad = if data.enabled == true then true else false
        self._autoLoadConfigName = tostring(data.lastConfig or CONFIG_DEFAULT_NAME)
    end
end

--[[
    Gets the content container for tabs

    @return ScrollingFrame
]]
function Window:GetContentContainer(): ScrollingFrame
    return self._contentContainer
end

--[[
    Gets the sections container

    @return ScrollingFrame
]]
function Window:GetSectionsContainer(): ScrollingFrame
    return self._sectionsContainer
end

function Window:GetPopupLayer(): Frame
    return self._popupLayer
end

function Window:GetMinimizedSignal(): RBXScriptSignal
    return self._minimizedChangedEvent.Event
end

--[[
    Destroys the window and cleans up resources
]]
function Window:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self._autoSave = false

    for _, section in ipairs(self._sections) do
        if section.Destroy then
            pcall(function()
                section:Destroy()
            end)
        end
    end
    table.clear(self._sections)

    for _, connection in ipairs(self._connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    table.clear(self._connections)

    if self._dragConnection then
        self._dragConnection.Disconnect()
    end

    if self._bottomDragConnection then
        self._bottomDragConnection.Disconnect()
    end

    if self._acrylicBlur then
        self._acrylicBlur:Destroy()
    end

    if self._minimizedChangedEvent then
        self._minimizedChangedEvent:Destroy()
        self._minimizedChangedEvent = nil
    end

    if self._screenGui then
        Notification.DestroyContainer(self._screenGui)
    end

    if self._usesSharedScreenGui then
        Window._sharedScreenGuiCount = math.max(0, Window._sharedScreenGuiCount - 1)
        if Window._sharedScreenGuiCount == 0 then
            if Window._sharedScreenGui then
                Window._sharedScreenGui:Destroy()
            end
            Window._sharedScreenGui = nil
            Window._sharedScreenGuiParent = nil
        end
    else
        if self._screenGui then
            self._screenGui:Destroy()
        end
    end

    table.clear(self._keybinds)
    table.clear(self._configElements)
end

return Window
