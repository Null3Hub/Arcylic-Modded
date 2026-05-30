--[[
    AcrylicUI - Default Value Constants

    Runtime defaults for component configuration when callers omit values.
]]

local Defaults = {
    Window = {
        Title = "AcrylicUI",
        ToggleKey = Enum.KeyCode.RightControl,
        ClampToViewport = true,
        ScreenGuiName = "AcrylicUI",
        AutoSaveInterval = 30,
        MinimizeRestoreDelay = 0.1,
    },

    Notification = {
        Title = "Notification",
        InstanceName = "Notification",
        ContainerName = "NotificationContainer",
        Description = "",
        Duration = 3,
        SuccessDuration = 2,
        AnimationDuration = 0.3,
        WarningUninitialized = "AcrylicUI: Notification container not initialized",
    },

    Config = {
        Root = "AcrylicConfigs",
        DefaultName = "default",
        AutoLoadName = "_autoload",
        Extension = ".json",
    },

    Messages = {
        ErrorTitle = "Error",
        Blocked = "Blocked",
        ConfigSystemUnsupported = "Config system not supported",
        ConfigReservedName = "Name reserved for internal use",
        ConfigSavedTitle = "Config Saved",
        ConfigSavedDescriptionPrefix = "Saved as: ",
        ConfigSaveFailed = "Failed to save config",
        ConfigLoadedTitle = "Config Loaded",
        ConfigLoadedDescriptionPrefix = "Loaded: ",
        ConfigNotFoundPrefix = "Config not found: ",
        ConfigLoadFailed = "Failed to load config",
        ConfigDeletedTitle = "Config Deleted",
        ConfigDeletedDescriptionPrefix = "Deleted: ",
        ConfigAutoLoadNeedsConfig = "Save or load a config before enabling Auto Load",
        ConfigsRefreshedTitle = "Configs Refreshed",
        ConfigsRefreshedDescription = "Config list updated",
    },

    Device = {
        DefaultViewport = Vector2.new(1280, 720),
        TabletMinShortSide = 600,
        SafeAreaBottom = 0,
        SafeAreaLeft = 0,
        SafeAreaRight = 0,
    },

    AcrylicBlur = {
        FolderPrefix = "AcrylicBlur_",
        DepthOfFieldPrefix = "AcrylicBlurDepthOfField_",
        BlurPrefix = "AcrylicBlurEffect_",
        FarIntensity = 0,
        FocusDistance = 0.01,
        InFocusRadius = 0.01,
        NearIntensity = 1,
        BlurSize = 6,
        RootTransparency = 0.9,
        DisabledTransparency = 1,
        CameraDistance = 0.0005,
        FallbackOffset = 28,
        ReferenceViewportHeight = 2560,
        OffsetScale = 24,
        OffsetBase = 4,
    },

    Components = {
        Common = {
            EmptyText = "",
            HeightWithDescription = 50,
            SurfaceTransparency = 0.4,
            ControlTransparency = 0.04,
            HoverTransparency = 0.3,
            PressedTransparency = 0.2,
            HoverFaintTransparency = 0.7,
            OptionHoverTransparency = 0.5,
            BlockerTransparency = 0.22,
            Transparent = 1,
            ClickFlashDelay = 0.1,
        },
        Button = {
            Name = "Button",
        },
        Toggle = {
            Name = "Toggle",
            Enabled = false,
        },
        Slider = {
            Name = "Slider",
        },
        Dropdown = {
            Name = "Dropdown",
            Options = { "Option 1", "Option 2", "Option 3" },
            MultiSelect = false,
            NoneText = "None",
            Separator = ", ",
        },
        Keybind = {
            Name = "Keybind",
            Key = Enum.KeyCode.F,
            ListeningText = "...",
            IdClockScale = 1000,
            TextWidthScale = 9,
            TextWidthPadding = 10,
            MinWidth = 24,
            BoxWidth = 30,
            ListeningWidth = 43,
        },
        ColorPicker = {
            Name = "Color Picker",
            Presets = {
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 0, 0),
                Color3.fromRGB(0, 255, 0),
                Color3.fromRGB(0, 128, 255),
                Color3.fromRGB(255, 128, 0),
                Color3.fromRGB(255, 0, 255),
            },
        },
        TextBox = {
            Name = "TextBox",
            Placeholder = "Enter text...",
            DefaultText = "",
            ClearOnFocus = false,
            NumbersOnly = false,
        },
        Paragraph = {
            Title = "Paragraph",
            Content = "Description text here.",
        },
        ConfigUI = {
            SectionTitle = "Configuration",
            ConfigName = "Config Name",
            ConfigPlaceholder = "Enter config name...",
            SelectConfig = "Select Config",
            SaveConfig = "Save Config",
            LoadConfig = "Load Config",
            DeleteConfig = "Delete Config",
            RefreshConfigs = "Refresh Configs",
            AutoSave = "Auto Save",
            AutoLoad = "Auto Load",
        },
    },

    Slider = {
        Min = 0,
        Max = 100,
        Value = 50,
        Increment = 1,
    },
}

return Defaults
