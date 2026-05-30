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

local Window = {}
Window.__index = Window

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
    Size: { Width: number, Height: number }?,
    ToggleKey: Enum.KeyCode?,
    ConfigFolder: string?,
    ClampToViewport: boolean?,
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
    self._size = resolvedSize
    self._minSize = minSize
    self._maxSize = maxSize
    self._toggleKey = config.ToggleKey or WindowDefaults.ToggleKey or Enum.KeyCode.RightControl
    self._configFolder = SanitizeConfigName(config.ConfigFolder or self._title)
    self._visible = true
    self._minimized = false
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

    if Device.IsMobile() then
        self:_SetupMobileToggle()
    end

    if self._autoLoad then
        self:ApplyAutoLoad()
    end

    return self
end

function Window:_CreateGui()
    local player = Services.Players.LocalPlayer
    local coreGuiAvailable, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)

    -- Screen GUI
    self._screenGui = Create.Instance("ScreenGui", {
        Name = WindowDefaults.ScreenGuiName or "AcrylicUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })

    local parentedToCoreGui = false
    if coreGuiAvailable and coreGui then
        parentedToCoreGui = pcall(function()
            self._screenGui.Parent = coreGui
        end)
    end

    if not parentedToCoreGui then
        self._screenGui.Parent = player:WaitForChild("PlayerGui")
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

    Create.Corner(self._container, Sizes.Corner.Medium)
    Create.Stroke(self._container)

    -- Title
    self._titleLabel = Create.Instance("TextLabel", {
        Name = "Title",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = self._title,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, WindowChromeSizes.TitleX or 10, 0, WindowChromeSizes.TitleY or 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = Fonts.Size.Title,
        Size = UDim2.new(
            0,
            WindowChromeSizes.TitleWidth or 150,
            0,
            WindowChromeSizes.TitleHeight or 25
        ),
        Parent = self._container,
    })

    self:_CreateContentArea()
    -- Controls are created after content so resize stays above scroll layers.
    self:_CreateWindowControls()

    -- Make draggable
    self._dragConnection = Draggable.Enable(self._container, self._titleLabel)
    self._bottomDragConnection = Draggable.Enable(self._container, self._bottomDragArea)

    -- Acrylic blur effect
    self._acrylicBlur = AcrylicBlur.new(self._container)

    -- Notification container
    Notification.CreateContainer(self._screenGui)
end

function Window:_CreateWindowControls()
    -- Minimize button
    local minimizeBtn = Create.Instance("ImageLabel", {
        Name = "Minimize",
        ImageColor3 = Colors.TextDark,
        Image = WindowIcons.Minimize or "rbxassetid://82603981310445",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(
            1,
            -(WindowChromeSizes.MinimizeRightOffset or 35),
            0,
            WindowChromeSizes.ControlTop or 15
        ),
        Size = UDim2.new(
            0,
            WindowChromeSizes.ControlSize or 15,
            0,
            WindowChromeSizes.ControlSize or 15
        ),
        Parent = self._container,
    })

    local minimizeClick = Create.Instance("TextButton", {
        Name = "ClickArea",
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(
            0,
            WindowChromeSizes.MinimizeClickWidth or 21,
            0,
            WindowChromeSizes.ControlSize or 15
        ),
        Parent = minimizeBtn,
    })

    minimizeClick.MouseButton1Click:Connect(function()
        self:_ToggleMinimize()
    end)

    minimizeBtn.MouseEnter:Connect(function()
        Tween.Create(minimizeBtn, { ImageColor3 = Colors.Text }, "Fast")
    end)

    minimizeBtn.MouseLeave:Connect(function()
        Tween.Create(minimizeBtn, { ImageColor3 = Colors.TextDark }, "Fast")
    end)

    -- Close button
    local closeBtn = Create.Instance("ImageButton", {
        Name = "Close",
        ImageColor3 = Colors.TextDark,
        Image = WindowIcons.Close or "rbxassetid://119943770201674",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(
            1,
            -(WindowChromeSizes.CloseRightOffset or 10),
            0,
            WindowChromeSizes.ControlTop or 15
        ),
        Size = UDim2.new(
            0,
            WindowChromeSizes.ControlSize or 15,
            0,
            WindowChromeSizes.ControlSize or 15
        ),
        Parent = self._container,
    })

    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    closeBtn.MouseEnter:Connect(function()
        Tween.Create(closeBtn, { ImageColor3 = Colors.CloseHover }, "Fast")
    end)

    closeBtn.MouseLeave:Connect(function()
        Tween.Create(closeBtn, { ImageColor3 = Colors.TextDark }, "Fast")
    end)

    -- Resize handle
    self._resizeBtn = Create.Instance("ImageButton", {
        Name = "Resize",
        Active = true,
        ImageColor3 = Colors.ResizeHandle,
        Image = WindowIcons.Resize or "rbxassetid://120997033468887",
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
    Create.Instance("Frame", {
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
        self._resizeBtn.Visible = false
        self._bottomDragArea.Visible = false
    else
        Tween.Create(self._container, {
            Size = UDim2.new(0, self._container.AbsoluteSize.X, 0, self._originalHeight),
        }, "Slow")
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
        Image = WindowIcons.MobileToggle or "rbxassetid://112235310154264",
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
    Shows a notification

    @param config NotificationConfig - Notification configuration
]]
function Window:Notify(config)
    return Notification.Show(config, self._screenGui)
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
        pcall(function()
            setValue(DeserializeValue(self._pendingConfigData[sanitizedFlag]))
        end)
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
        writeFile(
            GetConfigPath(self._configFolder, sanitizedName),
            Services.HttpService:JSONEncode(configData)
        )
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

    local success, data = pcall(function()
        return Services.HttpService:JSONDecode(readFile(path))
    end)

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
            pcall(function()
                element.setValue(DeserializeValue(value))
            end)
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
function Window:SetAutoLoad(enabled: boolean)
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
            return
        end

        self._autoLoadConfigName = sanitizedName
    end

    self._autoLoad = enabled
    self:_SaveAutoLoadState()
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

    if self._screenGui then
        Notification.DestroyContainer(self._screenGui)
    end

    if self._screenGui then
        self._screenGui:Destroy()
    end

    table.clear(self._keybinds)
    table.clear(self._configElements)
end

return Window
