--[[
    AcrylicUI - Notification System

    Toast-style notifications with auto-dismiss.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Icons = require(script.Parent.Parent.Constants.Icons)

local Notification = {}
local NotificationDefaults = Defaults.Notification or {}
local NotificationIcons = Icons.Notification or {}
local NotificationSizes = Sizes.Notification or {}

local Containers: { [ScreenGui]: Frame } = {}

export type NotificationConfig = {
    Title: string?,
    Description: string?,
    Duration: number?,
    Icon: (string | number)?,
}

--[[
    Creates the notification container

    @param screenGui ScreenGui - Parent screen gui
    @return Frame - Container frame
]]
function Notification.CreateContainer(screenGui: ScreenGui): Frame
    local existing = Containers[screenGui]
    if existing and existing.Parent == screenGui then
        return existing
    end
    Containers[screenGui] = nil

    local container = Create.Instance("Frame", {
        Name = NotificationDefaults.ContainerName or "NotificationContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(
            1,
            -(NotificationSizes.RightOffset or 240),
            0,
            NotificationSizes.TopOffset or 20
        ),
        Size = UDim2.new(
            0,
            NotificationSizes.Width or 220,
            1,
            -(NotificationSizes.VerticalPadding or 40)
        ),
        Parent = screenGui,
    })

    Create.ListLayout(container, NotificationSizes.Spacing or 10)
    Containers[screenGui] = container

    return container
end

function Notification.DestroyContainer(screenGui: ScreenGui)
    local container = Containers[screenGui]
    if container then
        if container.Parent then
            container:Destroy()
        end
        Containers[screenGui] = nil
    end
end

--[[
    Shows a notification

    @param config NotificationConfig - Notification configuration
    @return Frame - Notification frame

    @example
    Notification.Show({
        Title = "Success",
        Description = "Operation completed!",
        Duration = 3,
        Icon = "rbxassetid://10709775704"
    }, screenGui)
]]
function Notification.Show(config: NotificationConfig, screenGui: ScreenGui?): Frame?
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
    local icon = config.Icon or NotificationIcons.Default or "rbxassetid://10709775704"

    -- Notification frame
    local notification = Create.Instance("Frame", {
        Name = NotificationDefaults.InstanceName or "Notification",
        BackgroundColor3 = Colors.Notification.Background,
        Position = UDim2.new(1, NotificationSizes.SlideOffset or 20, 0, 0),
        Size = UDim2.new(1, 0, 0, NotificationSizes.Height or Sizes.Notification.Height),
        ClipsDescendants = true,
        Parent = container,
    })

    Create.Corner(notification, Sizes.Corner.Small)

    Create.Instance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Colors.Notification.Border,
        Thickness = NotificationSizes.StrokeThickness or 1.5,
        Parent = notification,
    })

    -- Title
    Create.Instance("TextLabel", {
        Name = "Title",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(
            0,
            NotificationSizes.TextLeft or 14,
            0,
            NotificationSizes.TitleTop or 16
        ),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(
            1,
            -(NotificationSizes.TextRightPadding or 60),
            0,
            NotificationSizes.TextHeight or 19
        ),
        Parent = notification,
    })

    -- Description
    Create.Instance("TextLabel", {
        Name = "Description",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = description,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position = UDim2.new(
            0,
            NotificationSizes.TextLeft or 14,
            0,
            NotificationSizes.DescriptionTop or 38
        ),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(
            1,
            -(NotificationSizes.TextRightPadding or 60),
            0,
            NotificationSizes.TextHeight or 19
        ),
        Parent = notification,
    })

    -- Icon
    local iconImage = Create.Instance("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Position = UDim2.new(
            1,
            -(NotificationSizes.IconRightOffset or 33),
            0,
            NotificationSizes.IconTop or 23
        ),
        Size = UDim2.new(0, NotificationSizes.IconSize or 19, 0, NotificationSizes.IconSize or 19),
        Parent = notification,
    })
    Create.ApplyIcon(iconImage, icon, NotificationIcons.Default)

    Create.Instance("UIAspectRatioConstraint", {
        Parent = iconImage,
    })

    -- Timer bar
    local timerBar = Create.Instance("Frame", {
        Name = "Timer",
        BackgroundColor3 = Colors.Notification.Timer,
        Position = UDim2.new(0, 0, 1, -(NotificationSizes.TimerHeight or 3)),
        Size = UDim2.new(1, 0, 0, NotificationSizes.TimerHeight or 3),
        Parent = notification,
    })

    Create.Corner(timerBar, Sizes.Corner.Full)

    -- Animate in
    Tween.Create(
        notification,
        { Position = UDim2.new(0, 0, 0, 0) },
        NotificationDefaults.AnimationDuration or 0.3,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )

    -- Timer animation
    Tween.Create(
        timerBar,
        { Size = UDim2.new(0, 0, 0, NotificationSizes.TimerHeight or 3) },
        duration,
        Enum.EasingStyle.Linear
    )

    -- Auto dismiss
    task.delay(duration, function()
        Tween.CreateWithCallback(
            notification,
            { Position = UDim2.new(1, NotificationSizes.SlideOffset or 20, 0, 0) },
            NotificationDefaults.AnimationDuration or 0.3,
            function()
                notification:Destroy()
            end
        )
    end)

    return notification
end

return Notification
