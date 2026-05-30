local Create = require(script.Parent.Parent.Utils.Create)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Layers = require(script.Parent.Parent.Constants.Layers)

local ColorPicker = {}
ColorPicker.__index = ColorPicker
local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}
local ColorPickerDefaults = ComponentDefaults.ColorPicker or {}
local ColorPickerLayers = Layers.ColorPicker or {}
local ColorPickerSizes = Sizes.ColorPicker or {}

-- Minimal color picker: preview + simple palette popup
local PRESETS = ColorPickerDefaults.Presets
    or {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 128, 255),
        Color3.fromRGB(255, 128, 0),
        Color3.fromRGB(255, 0, 255),
    }

function ColorPicker.new(parent: Instance, config, window)
    local self = setmetatable({}, ColorPicker)
    local name = (config and config.Name) or ColorPickerDefaults.Name or "Color Picker"
    self._callback = (config and config.Callback) or function() end
    self._color = (config and config.Default) or PRESETS[1]
    self._flag = config and config.Flag
    self._window = window
    self._connections = {}
    local description = Create.GetDescription(config)
    local hasDescription = description ~= nil
    local height = hasDescription
            and (ColorPickerSizes.HeightWithDescription or CommonDefaults.HeightWithDescription or 50)
        or Sizes.Button.Height

    self._frame = Create.Instance("Frame", {
        Name = "ColorPicker_" .. name,
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = CommonDefaults.SurfaceTransparency or 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height),
        Parent = parent,
    })

    Create.Corner(self._frame, Sizes.Corner.Medium)
    Create.Stroke(self._frame)

    Create.Instance("TextLabel", {
        Name = "Name",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = hasDescription
                and UDim2.new(0, Sizes.Component.LabelLeft or 10, 0, Sizes.Component.LabelTop or 7)
            or UDim2.new(0, Sizes.Component.LabelLeft or 10, 0, 0),
        TextSize = Fonts.Size.Normal,
        Size = UDim2.new(
            1,
            -(ColorPickerSizes.LabelRightPadding or 50),
            0,
            Sizes.Component.LabelHeight or 20
        ),
        Parent = self._frame,
    })

    Create.Description(
        self._frame,
        description,
        UDim2.new(0, Sizes.Component.LabelLeft or 10, 0, Sizes.Component.DescriptionTop or 27),
        UDim2.new(
            1,
            -(ColorPickerSizes.LabelRightPadding or 50),
            0,
            Sizes.Component.DescriptionHeight or 14
        )
    )

    self._preview = Create.Instance("Frame", {
        Name = "Preview",
        BackgroundColor3 = self._color,
        Position = UDim2.new(
            1,
            -(ColorPickerSizes.PreviewRightOffset or 45),
            0.5,
            -(ColorPickerSizes.PreviewVerticalOffset or 8)
        ),
        Size = UDim2.new(
            0,
            ColorPickerSizes.PreviewWidth or 35,
            0,
            ColorPickerSizes.PreviewHeight or 16
        ),
        Parent = self._frame,
    })
    Create.Corner(self._preview, Sizes.Corner.Small)
    Create.Stroke(self._preview)

    local previewBtn = Create.Instance("TextButton", {
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._preview,
    })

    -- Palette popup
    self._palette = Create.Instance("Frame", {
        Name = "Palette",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = CommonDefaults.ControlTransparency or 0.04,
        BorderSizePixel = 0,
        Size = UDim2.new(
            0,
            ColorPickerSizes.PaletteWidth or 160,
            0,
            ColorPickerSizes.PaletteHeight or 70
        ),
        Visible = false,
        ZIndex = ColorPickerLayers.Palette or 2000,
        Parent = parent,
    })
    Create.Corner(self._palette, Sizes.Corner.Medium)
    Create.Stroke(self._palette)
    Create.Padding(
        self._palette,
        ColorPickerSizes.PalettePadding or 8,
        ColorPickerSizes.PalettePadding or 8,
        ColorPickerSizes.PalettePadding or 8,
        ColorPickerSizes.PalettePadding or 8
    )

    Create.Instance("UIGridLayout", {
        CellPadding = UDim2.new(
            0,
            ColorPickerSizes.PaletteCellPadding or 8,
            0,
            ColorPickerSizes.PaletteCellPadding or 8
        ),
        CellSize = UDim2.new(
            0,
            ColorPickerSizes.PaletteSwatchSize or 24,
            0,
            ColorPickerSizes.PaletteSwatchSize or 24
        ),
        Parent = self._palette,
    })

    for _, col in ipairs(PRESETS) do
        local swatch = Create.Instance("TextButton", {
            BackgroundColor3 = col,
            Text = CommonDefaults.EmptyText or "",
            Size = UDim2.new(
                0,
                ColorPickerSizes.PaletteSwatchSize or 24,
                0,
                ColorPickerSizes.PaletteSwatchSize or 24
            ),
            Parent = self._palette,
        })
        Create.Corner(swatch, Sizes.Corner.Small)
        Create.Stroke(swatch)
        table.insert(
            self._connections,
            swatch.MouseButton1Click:Connect(function()
                if self._blocked then
                    return
                end

                self:SetColor(col)
                self._palette.Visible = false
            end)
        )
    end

    local function open()
        if self._blocked then
            return
        end

        local p = self._preview.AbsolutePosition
        self._palette.Position = UDim2.new(
            0,
            p.X - (ColorPickerSizes.PaletteWidth or 160) + (ColorPickerSizes.PreviewWidth or 35),
            0,
            p.Y + (ColorPickerSizes.PaletteYOffset or 22)
        )
        self._palette.Visible = true
    end

    table.insert(
        self._connections,
        previewBtn.MouseButton1Click:Connect(function()
            if self._blocked then
                return
            end

            self._palette.Visible = not self._palette.Visible
            if self._palette.Visible then
                open()
            end
        end)
    )

    Create.Blockable(self, self._frame)

    local baseBlock = self.Block
    self.Block = function(component, text: string?)
        component._palette.Visible = false
        baseBlock(component, text)
    end

    if self._flag and self._window and self._window.RegisterConfigElement then
        self._window:RegisterConfigElement(self._flag, "ColorPicker", function()
            return self._color
        end, function(value)
            self:SetColor(value)
        end)
    end

    return self
end

function ColorPicker:SetColor(color: Color3)
    self._color = color
    self._preview.BackgroundColor3 = color
    self._callback(color)
end

function ColorPicker:GetColor(): Color3
    return self._color
end

function ColorPicker:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

    if self._flag and self._window and self._window.UnregisterConfigElement then
        self._window:UnregisterConfigElement(self._flag)
    end

    if self._palette then
        self._palette:Destroy()
    end
    self._frame:Destroy()
end

return ColorPicker
