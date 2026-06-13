--[[
    AcrylicUI - Notification System

    Toast-style notifications with auto-dismiss.
    Acrylic blur + window-matching background on each card.
    Container anchored bottom-right. Cascade-style stacking with scale + fade.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Services = require(script.Parent.Parent.Utils.Services)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Icons = require(script.Parent.Parent.Constants.Icons)
local AcrylicBlur = require(script.Parent.Parent.Core.AcrylicBlur)

local Notification = {}
local NotificationDefaults = Defaults.Notification or {}
local NotificationIcons = Icons.Notification or {}
local NotificationSizes = Sizes.Notification or {}

-- ── Constants ────────────────────────────────────────────────

local CARD_MIN_HEIGHT = 85
local CARD_PADDING_X = 16
local CARD_PADDING_Y = 16
local ICON_COLUMN_WIDTH = 32
local BELL_ICON_SIZE = 32
local SEPARATOR_WIDTH = 1
local SEPARATOR_HEIGHT = 90
local SEPARATOR_SPACING = 16
local COUNTDOWN_WIDTH = 40
local COUNTDOWN_TOP = 12
local COUNTDOWN_RIGHT = 16
local TEXT_SPACING = 4
local TEXT_COUNTDOWN_GUTTER = 48
local TITLE_HEIGHT = 20
local DESCRIPTION_MIN_HEIGHT = 16
local BELL_SWING_DURATION = 0.8
local BELL_SWING_ANGLE = 12

local FAN_MAX = 4
local FAN_SCALE_DECREMENT = 0.05
local FAN_STACK_OFFSET_Y = -12
local FAN_ENTRY_OFFSET_X = 187
local FAN_EXIT_OFFSET_X = 350
local ANIM_DURATION = 0.4

-- ── State ────────────────────────────────────────────────────

local Containers: { [ScreenGui]: Frame } = {}
local ActiveNotifications: { [Frame]: { Frame } } = {}
local NotificationData: { [Frame]: { BellIcon: ImageLabel, Scale: UIScale, CountdownLabel: TextLabel } } =
    {}
local ClosingNotifications: { [Frame]: boolean } = {}
local NotificationBlur: { [Frame]: any } = {}
local BellTweens: { [ImageLabel]: Tween } = {}
local Resizing: { [Frame]: boolean } = {}
local ContainerViewportConnections: { [Frame]: RBXScriptConnection } = {}

export type NotificationConfig = {
    Title: string?,
    Description: string?,
    Duration: number?,
}

-- ── Bell Animation ───────────────────────────────────────────

local function StartBellSwing(bellIcon: ImageLabel)
    if not bellIcon or not bellIcon.Parent then
        return
    end

    bellIcon.Rotation = 0
    local tweenInfo = TweenInfo.new(
        BELL_SWING_DURATION,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        -1,
        true
    )
    local ok, tween = pcall(function()
        return Services.TweenService:Create(bellIcon, tweenInfo, { Rotation = BELL_SWING_ANGLE })
    end)
    if not ok or not tween then
        return
    end
    tween:Play()
    BellTweens[bellIcon] = tween
end

local function StopBellSwing(bellIcon: ImageLabel)
    if not bellIcon then
        return
    end

    local tween = BellTweens[bellIcon]
    if tween then
        tween:Cancel()
        BellTweens[bellIcon] = nil
    end
    bellIcon.Rotation = 0
end

local function StartCountdown(notification: Frame, countdownLabel: TextLabel, duration: number)
    local remainingSeconds = math.ceil(duration)
    countdownLabel.Text = tostring(math.ceil(duration)) .. "s"

    task.spawn(function()
        local startedAt = os.clock()

        for remaining = remainingSeconds - 1, 1, -1 do
            local targetElapsed = duration - remaining
            if targetElapsed > 0 then
                task.wait(math.max(targetElapsed - (os.clock() - startedAt), 0))
            end

            if not notification.Parent or ClosingNotifications[notification] then
                return
            end

            countdownLabel.Text = remaining .. "s"
        end

        task.wait(math.max(duration - (os.clock() - startedAt), 0))
        if notification.Parent and not ClosingNotifications[notification] then
            countdownLabel.Text = "0s"
        end
    end)
end

-- ── Cleanup Helpers ──────────────────────────────────────────

local function DestroyBlurForNotification(notification: Frame)
    local blur = NotificationBlur[notification]
    if blur then
        blur:Destroy()
        NotificationBlur[notification] = nil
    end
end

local function RemoveFromActive(container: Frame, notification: Frame)
    local active = ActiveNotifications[container]
    if not active then
        return
    end
    for i, notif in ipairs(active) do
        if notif == notification then
            table.remove(active, i)
            break
        end
    end
end

-- ── Resize (debounced) ───────────────────────────────────────

local UpdateGrouping

local function ResizeNotification(notification: Frame, textLayout: UIListLayout)
    if Resizing[notification] then
        return
    end
    Resizing[notification] = true
    task.defer(function()
        if textLayout and textLayout.Parent then
            local contentHeight = CARD_PADDING_Y * 2 + textLayout.AbsoluteContentSize.Y
            notification.Size = UDim2.new(1, 0, 0, math.max(CARD_MIN_HEIGHT, contentHeight))

            local container = notification.Parent
            if container and container:IsA("Frame") then
                UpdateGrouping(container)
            end
        end
        Resizing[notification] = nil
    end)
end

-- ── Fan Stack (Cascade style) ──────────────────────────────

local function GetNotificationHeight(notif: Frame): number
    return notif.AbsoluteSize.Y
end

local function GetViewportWidth(): number
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize.X
    end

    return NotificationSizes.Width or 320
end

local function ResolveNotificationWidth(): number
    local maxWidth = NotificationSizes.Width or 320
    local minWidth = NotificationSizes.MinWidth or 260
    local safeMargin = NotificationSizes.SafeMargin or 16
    local availableWidth = GetViewportWidth() - safeMargin * 2

    if availableWidth <= minWidth then
        return math.max(availableWidth, 0)
    end

    return math.clamp(availableWidth, minWidth, maxWidth)
end

local function UpdateContainerLayout(container: Frame, height: number?)
    local safeMargin = NotificationSizes.SafeMargin or 16
    local bottomOffset = NotificationSizes.BottomOffset or 20
    local resolvedHeight = height or container.Size.Y.Offset

    container.AnchorPoint = Vector2.new(1, 1)
    container.Position = UDim2.new(1, -safeMargin, 1, -bottomOffset)
    container.Size = UDim2.new(0, ResolveNotificationWidth(), 0, resolvedHeight)
end

local function SetContainerHeight(container: Frame, count: number)
    local active = ActiveNotifications[container]
    if not active then
        return
    end

    local maxHeight = 0
    for _, notif in ipairs(active) do
        if notif and notif.Parent then
            maxHeight = math.max(maxHeight, GetNotificationHeight(notif))
        end
    end

    local stackHeight = maxHeight + math.abs(FAN_STACK_OFFSET_Y) * math.max(count - 1, 0)
    UpdateContainerLayout(container, stackHeight)
end

local function TweenFade(inst, props)
    if not inst or not inst.Parent then
        return
    end

    -- Bypass Tween.Create's per-instance cache so fade tweens do not cancel stack movement.
    local tweenInfo =
        TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    local ok, tween = pcall(function()
        return Services.TweenService:Create(inst, tweenInfo, props)
    end)
    if ok and tween then
        tween:Play()
    end
end

local function ApplyFade(notif: Frame, age: number, instant: boolean?)
    if not notif or not notif.Parent then
        return
    end

    local isFaded = age >= (FAN_MAX - 1)
    local targetBg = isFaded and 1 or 0.05

    local function apply(inst, props)
        if not inst or not inst.Parent then
            return
        end
        if instant then
            for k, v in pairs(props) do
                inst[k] = v
            end
        else
            TweenFade(inst, props)
        end
    end

    apply(notif, { BackgroundTransparency = targetBg })

    for _, desc in ipairs(notif:GetDescendants()) do
        if desc:IsA("TextLabel") then
            apply(desc, { TextTransparency = isFaded and 1 or 0 })
        elseif desc:IsA("ImageLabel") then
            apply(desc, { ImageTransparency = isFaded and 1 or 0 })
        elseif
            desc:IsA("Frame")
            and (desc.Name == "Separator" or desc.Name == "Timer" or desc.Name == "Fill")
        then
            apply(desc, { BackgroundTransparency = isFaded and 1 or 0 })
        end
    end

    local stroke = notif:FindFirstChildOfClass("UIStroke")
    if stroke then
        apply(stroke, { Transparency = isFaded and 1 or 0 })
    end
end

local function ApplyNotificationZIndex(notifFrame: Frame, baseZIndex: number)
    notifFrame.ZIndex = baseZIndex

    for _, descendant in ipairs(notifFrame:GetDescendants()) do
        if descendant:IsA("GuiObject") then
            descendant.ZIndex = baseZIndex + 1
        end
    end
end

function UpdateGrouping(container: Frame, instant: boolean?)
    local active = ActiveNotifications[container]
    if not active then
        return
    end

    local count = #active
    SetContainerHeight(container, count)

    for i, notifFrame in ipairs(active) do
        if not notifFrame or not notifFrame.Parent then
            continue
        end
        if ClosingNotifications[notifFrame] then
            continue
        end

        local age = count - i
        local targetY = age * FAN_STACK_OFFSET_Y
        local targetScale = 1 - (age * FAN_SCALE_DECREMENT)

        notifFrame.AnchorPoint = Vector2.new(0, 1)

        local scaleObj = notifFrame:FindFirstChildOfClass("UIScale")
        if scaleObj and scaleObj.Parent then
            if instant then
                scaleObj.Scale = targetScale
            else
                Tween.Create(
                    scaleObj,
                    { Scale = targetScale },
                    "Normal",
                    Enum.EasingStyle.Exponential,
                    Enum.EasingDirection.Out
                )
            end
        end

        if instant then
            notifFrame.Position = UDim2.new(0, 0, 1, targetY)
        else
            Tween.Create(notifFrame, {
                Position = UDim2.new(0, 0, 1, targetY),
            }, "Normal", Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
        end

        ApplyNotificationZIndex(notifFrame, 100 - age)

        ApplyFade(notifFrame, age, instant)
    end
end

-- ── Container ────────────────────────────────────────────────

function Notification.CreateContainer(screenGui: ScreenGui): Frame
    local existing = Containers[screenGui]
    if existing and existing.Parent == screenGui then
        UpdateContainerLayout(existing)
        return existing
    end
    Containers[screenGui] = nil

    local container = Create.Instance("Frame", {
        Name = NotificationDefaults.ContainerName or "NotificationContainer",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(
            1,
            -(NotificationSizes.SafeMargin or 16),
            1,
            -(NotificationSizes.BottomOffset or 20)
        ),
        Size = UDim2.new(0, ResolveNotificationWidth(), 0, 0),
        Parent = screenGui,
    })
    UpdateContainerLayout(container)

    local camera = workspace.CurrentCamera
    if camera then
        ContainerViewportConnections[container] = camera
            :GetPropertyChangedSignal("ViewportSize")
            :Connect(function()
                UpdateContainerLayout(container)
            end)
    end

    Containers[screenGui] = container
    ActiveNotifications[container] = {}

    return container
end

function Notification.DestroyContainer(screenGui: ScreenGui)
    local container = Containers[screenGui]
    if not container then
        return
    end

    local active = ActiveNotifications[container]
    if active then
        for _, notif in ipairs(active) do
            local data = NotificationData[notif]
            if data then
                StopBellSwing(data.BellIcon)
            end
            NotificationData[notif] = nil
            ClosingNotifications[notif] = nil
            DestroyBlurForNotification(notif)
        end
    end

    ActiveNotifications[container] = nil
    Containers[screenGui] = nil
    local viewportConnection = ContainerViewportConnections[container]
    if viewportConnection then
        viewportConnection:Disconnect()
        ContainerViewportConnections[container] = nil
    end

    if container.Parent then
        container:Destroy()
    end
end

-- ── Card Builders ────────────────────────────────────────────

local function BuildCard(notification: Frame): (UIStroke, UIScale)
    Create.Corner(notification, Sizes.Corner.Medium)

    local stroke = Create.Instance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Colors.Border,
        Thickness = NotificationSizes.StrokeThickness or 1,
        Parent = notification,
    })

    local scale = Create.Instance("UIScale", {
        Scale = 1,
        Parent = notification,
    })

    local blurOk, blur = pcall(AcrylicBlur.new, notification)
    if blurOk then
        NotificationBlur[notification] = blur
    else
        warn("[AcrylicUI] Notification blur disabled: " .. tostring(blur))
    end

    return stroke, scale
end

local function BuildHorizontalLayout(notification: Frame): (ImageLabel, TextLabel, UIListLayout)
    local iconColumn = Create.Instance("Frame", {
        Name = "IconColumn",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, CARD_PADDING_X, 0, 0),
        Size = UDim2.new(0, ICON_COLUMN_WIDTH, 1, 0),
        Parent = notification,
    })

    local bellIcon = Create.Instance("ImageLabel", {
        Name = "BellIcon",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, BELL_ICON_SIZE, 0, BELL_ICON_SIZE),
        Parent = iconColumn,
    })
    Create.ApplyIcon(bellIcon, NotificationIcons.Default or "rbxassetid://10709775704")
    Create.Instance("UIAspectRatioConstraint", { Parent = bellIcon })

    local separatorX = CARD_PADDING_X + ICON_COLUMN_WIDTH + SEPARATOR_SPACING
    Create.Instance("Frame", {
        Name = "VerticalSeparator",
        BackgroundColor3 = Colors.Border,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, separatorX, 0.5, 0),
        Size = UDim2.new(0, SEPARATOR_WIDTH, 0, SEPARATOR_HEIGHT),
        Parent = notification,
    })

    local textStartX = separatorX + SEPARATOR_WIDTH + SEPARATOR_SPACING
    local textColumn = Create.Instance("Frame", {
        Name = "TextColumn",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, textStartX, 0.5, 0),
        Size = UDim2.new(1, -(textStartX + CARD_PADDING_X + TEXT_COUNTDOWN_GUTTER), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = notification,
    })

    local textLayout = Create.ListLayout(textColumn, TEXT_SPACING)
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local countdownLabel = Create.Instance("TextLabel", {
        Name = "CountdownLabel",
        FontFace = Fonts.Medium,
        TextColor3 = Color3.fromRGB(153, 153, 153),
        Text = "",
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        TextSize = 12,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -COUNTDOWN_RIGHT, 0, COUNTDOWN_TOP),
        Size = UDim2.new(0, COUNTDOWN_WIDTH, 0, 16),
        Parent = notification,
    })

    return bellIcon, countdownLabel, textLayout
end

local function BuildTitle(parent: Frame, title: string)
    Create.Instance("TextLabel", {
        Name = "ContentTitle",
        FontFace = Fonts.Bold,
        TextColor3 = Colors.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Section,
        Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
        LayoutOrder = 1,
        Parent = parent,
    })
end

local function BuildDescription(parent: Frame, description: string)
    if description == "" then
        return
    end

    Create.Instance("TextLabel", {
        Name = "ContentText",
        FontFace = Fonts.Light,
        TextColor3 = Color3.fromRGB(153, 153, 153),
        Text = description,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Small,
        Size = UDim2.new(1, 0, 0, DESCRIPTION_MIN_HEIGHT),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Parent = parent,
    })
end

-- ── Dismiss ──────────────────────────────────────────────────

local function DismissNotification(
    container: Frame,
    notification: Frame,
    bellIcon: ImageLabel,
    scale: UIScale,
    animationDuration: number
)
    if not notification or not notification.Parent then
        return
    end
    if ClosingNotifications[notification] then
        return
    end
    ClosingNotifications[notification] = true

    StopBellSwing(bellIcon)

    -- Slide out to the right + scale down (Cascade style)
    local currentPos = notification.Position
    Tween.Create(notification, {
        Position = currentPos + UDim2.fromOffset(FAN_EXIT_OFFSET_X, 0),
    }, "Normal", Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

    if scale and scale.Parent then
        Tween.Create(
            scale,
            { Scale = 0.85 },
            "Normal",
            Enum.EasingStyle.Exponential,
            Enum.EasingDirection.Out
        )
    end

    -- Apply fade to this notification
    ApplyFade(notification, FAN_MAX, false)

    -- After animation, remove and reorganize
    task.delay(animationDuration, function()
        if not notification or not notification.Parent then
            NotificationData[notification] = nil
            ClosingNotifications[notification] = nil
            return
        end

        RemoveFromActive(container, notification)
        StopBellSwing(bellIcon)
        DestroyBlurForNotification(notification)
        NotificationData[notification] = nil
        ClosingNotifications[notification] = nil
        notification:Destroy()
        UpdateGrouping(container)
    end)
end

-- ── Show ─────────────────────────────────────────────────────

function Notification.Show(
    config: NotificationConfig,
    screenGui: ScreenGui?,
    _windowTitle: string?
): Frame?
    if not screenGui then
        warn(
            NotificationDefaults.WarningUninitialized
                or "AcrylicUI: Notification container not initialized"
        )
        return nil
    end

    local container = Notification.CreateContainer(screenGui)
    local title = config.Title or NotificationDefaults.Title or "Notification"
    local description = config.Description or NotificationDefaults.Description or ""
    local duration = config.Duration or NotificationDefaults.Duration or 3

    -- Enforce max notifications
    local active = ActiveNotifications[container]
    if active and #active >= FAN_MAX then
        local oldest = table.remove(active, 1)
        local oldestData = oldest and NotificationData[oldest]
        if oldest and oldestData then
            DismissNotification(
                container,
                oldest,
                oldestData.BellIcon,
                oldestData.Scale,
                ANIM_DURATION
            )
        end
    end

    -- Card
    local notification = Create.Instance("Frame", {
        Name = NotificationDefaults.InstanceName or "Notification",
        BackgroundColor3 = Colors.Background,
        BackgroundTransparency = 0.05,
        AnchorPoint = Vector2.new(0, 1),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Position = UDim2.new(1, FAN_ENTRY_OFFSET_X, 1, 0),
        Parent = container,
    })

    local _, scale = BuildCard(notification)
    local bellIcon, countdownLabel, textLayout = BuildHorizontalLayout(notification)
    local textColumn = textLayout.Parent :: Frame
    BuildTitle(textColumn, title)
    BuildDescription(textColumn, description)

    -- Resize wiring
    textLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ResizeNotification(notification, textLayout)
    end)
    ResizeNotification(notification, textLayout)

    -- Track
    if active then
        table.insert(active, notification)
    end
    NotificationData[notification] = {
        BellIcon = bellIcon,
        Scale = scale,
        CountdownLabel = countdownLabel,
    }

    -- Start at 0.85 scale, slide in to target (Cascade style)
    scale.Scale = 0.85
    task.defer(function()
        if notification.Parent then
            UpdateGrouping(container)
        end
    end)

    -- Bell swing
    task.delay(ANIM_DURATION, function()
        if notification.Parent and bellIcon and bellIcon.Parent then
            StartBellSwing(bellIcon)
        end
    end)

    StartCountdown(notification, countdownLabel, duration)

    task.delay(duration, function()
        local data = NotificationData[notification]
        if notification and notification.Parent and data then
            DismissNotification(container, notification, data.BellIcon, data.Scale, ANIM_DURATION)
        end
    end)

    return notification
end

return Notification
