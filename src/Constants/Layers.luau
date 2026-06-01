--[[
    AcrylicUI - ZIndex Layer Constants

    Named ZIndex defaults for overlays and popup controls.
]]

local Layers = {
    Window = {
        TopBarDragArea = 5,
        TopBarControls = 6,
        PopupLayer = 900,
        ResizeHandle = 1000,
        BottomDragArea = 1000,
        BottomDragBar = 1001,
    },

    Dropdown = {
        Base = 1,
        Label = 1,
        Display = 2,
        ToggleButton = 3,
        Open = 10,
        Options = 100,
    },

    Blocker = {
        Overlay = 1000,
        Label = 1001,
    },

    ColorPicker = {
        Palette = 2000,
    },
}

return Layers
