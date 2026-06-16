--[[
    AcrylicUI - Size Constants

    Dimension constants for UI components.
    All values are in pixels unless otherwise specified.
]]

local Sizes = {
    -- Window dimensions
    Window = {
        Width = 690,
        Height = 446,
    },

    WindowChrome = {
        MinMobileWidth = 320,
        MinMobileHeight = 240,
        MobileViewportMargin = 24,
        DesktopViewportMargin = 40,
        HeaderHeight = 45,
        ContentTop = 46,
        SidebarWidth = 165,
        ContentLeft = 166,
        ContentScrollbarThickness = 3,
        TitleX = 10,
        TitleY = 10,
        TitleWidth = 150,
        TitleHeight = 25,
        ControlTop = 15,
        ControlSize = 15,
        ControlFrameRightInset = 5,
        ControlFrameTop = 7,
        ControlFrameButtonWidth = 31,
        ControlFrameGap = 1,
        ControlFrameHeight = 31,
        ControlFrameAvatarGap = 4,
        ControlFrameSeparatorWidth = 1,
        ControlFrameSeparatorHeight = 20,
        MinimizeRightOffset = 35,
        MinimizeClickWidth = 21,
        CloseRightOffset = 10,
        TopBarControlsWidth = 120,
        ResizeOffset = 5,
        ResizeWidth = 62,
        ResizeHeight = 60,
        BottomDragWidth = 140,
        BottomDragHeight = 18,
        BottomDragBarWidth = 90,
        BottomDragBarHeight = 4,
        BottomDragBarHoldingHeight = 5.5,
        BottomDragBarTop = 4.5,
        MobileToggleSize = 50,
        MobileToggleCorner = 25,
        MobileToggleX = 15,
        MobileToggleYOffset = -25,
        MobileTapThreshold = 10,
    },

    -- Minimum window size (for resizing)
    MinWindow = {
        Width = 500,
        Height = 300,
    },

    -- Maximum window size (for resizing)
    MaxWindow = {
        Width = 1200,
        Height = 800,
    },

    -- Toggle switch dimensions
    Toggle = {
        Width = 38,
        Height = 21,
        Circle = 13,
        Padding = 4,
        RightOffset = 48,
        VerticalOffset = 10,
        LabelRightPadding = 60,
    },

    -- Button dimensions
    Button = {
        Height = 39,
        IconSize = 20,
        IconRightOffset = 30,
        LabelRightPadding = 50,
    },

    -- Slider dimensions
    Slider = {
        Height = 46,
        HeightWithDescription = 56,
        LabelCenterOffset = 18,
        TrackHeight = 7,
        LabelWidth = 200,
        ValueWidth = 50,
        ValueRightOffset = 60,
        DescriptionRightPadding = 80,
        TrackHorizontalPadding = 10,
        TrackTop = 29,
        TrackTopWithDescription = 39,
        HeaderTop = 5,
        HeaderTopWithDescription = 4,
        DescriptionTop = 22,
    },

    -- Dropdown dimensions
    Dropdown = {
        Height = 39,
        HeightWithDescription = 50,
        OptionHeight = 30,
        MaxVisibleOptions = 5,
        DisplayWidth = 135,
        DisplayHeight = 26,
        DisplayRightOffset = 145,
        PopupOverlap = 1,
        ScrollbarThickness = 3,
        LabelWidth = 200,
        DescriptionRightPadding = 155,
        SelectedLabelRightPadding = 30,
        SelectedLabelPadding = 10,
        ArrowRightOffset = 20,
        ArrowSize = 10,
        ArrowVerticalOffset = 5,
        SearchHeight = 34,
        SearchIconSize = 16,
        SearchIconLeft = 10,
        SearchTextLeft = 34,
        SearchSeparatorHeight = 1,
        EmptyHeight = 42,
        OptionIconSize = 14,
        OptionIconLeft = 12,
        OptionTextLeft = 36,
        OptionTextRightPadding = 10,
    },

    -- Tab dimensions
    Tab = {
        Width = 135,
        Height = 35,
        IconSize = 15,
        IconLeft = 11,
        TextLeft = 33,
        TextRightPadding = 42,
        TextPaddingRight = 9,
        ContentPadding = 8,
        SectionHeight = 25,
    },

    Section = {
        FrameRightPadding = 10,
        HeaderHeight = 25,
        LayoutPadding = 2,
        LabelLeft = 5,
        LabelRightPadding = 25,
        ArrowRightOffset = 20,
        ArrowSize = 15,
        ArrowVerticalOffset = 7,
        TabsIndent = 15,
    },

    -- Color picker dimensions
    ColorPicker = {
        Width = 160,
        Height = 115,
        HeightWithDescription = 50,
        PreviewWidth = 35,
        PreviewHeight = 16,
        PreviewRightOffset = 45,
        PreviewVerticalOffset = 8,
        LabelRightPadding = 50,
        PaletteWidth = 160,
        PaletteHeight = 70,
        PalettePadding = 8,
        PaletteCellPadding = 8,
        PaletteSwatchSize = 24,
        PaletteYOffset = 22,
    },

    -- Notification dimensions
    Notification = {
        Width = 320,
        MinWidth = 260,
        Height = 85,
        SafeMargin = 16,
        RightOffset = 344,
        TopOffset = 24,
        BottomOffset = 24,
        VerticalPadding = 48,
        Spacing = 16,
        SlideOffset = 24,
        StrokeThickness = 1.5,
        TextLeft = 16,
        TextRightPadding = 64,
        TitleTop = 16,
        DescriptionTop = 48,
        TextHeight = 24,
        IconRightOffset = 40,
        IconTop = 24,
        IconSize = 24,
    },

    -- Text input dimensions
    TextBox = {
        Height = 39,
        HeightWithDescription = 50,
        InputWidth = 150,
        InputHeight = 26,
        LabelRightPadding = 190,
        IconSize = 18,
        IconRightOffset = 165,
        InputRightOffset = 10,
        InputTextPadding = 8,
        InputTextRightPadding = 16,
    },

    Keybind = {
        HeightWithDescription = 50,
        LabelWidth = 200,
        BoxWidth = 30,
        BoxHeight = 26,
        BoxRightOffset = 10,
        ListeningWidth = 43,
    },

    Paragraph = {
        TitleHeight = 20,
        ContentTop = 22,
    },

    Component = {
        HeightWithDescription = 50,
        LabelLeft = 10,
        LabelWidth = 200,
        LabelHeight = 20,
        LabelTop = 7,
        LabelCenterOffset = 10,
        DescriptionTop = 27,
        DescriptionHeight = 14,
        SectionIndent = 10,
        SectionHeaderHeight = 25,
    },

    -- Corner radius values
    Corner = {
        Small = 4,
        Medium = 5,
        Large = 6,
        Full = 100,
    },

    -- Padding values
    Padding = {
        Small = 5,
        Medium = 10,
        Large = 15,
    },
}

return Sizes
