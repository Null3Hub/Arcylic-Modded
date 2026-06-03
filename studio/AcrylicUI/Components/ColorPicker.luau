local Create = require(script.Parent.Parent.Utils.Create)
local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Layers = require(script.Parent.Parent.Constants.Layers)
local Services = require(script.Parent.Parent.Utils.Services)

local ColorPicker = {}
ColorPicker.__index = ColorPicker
setmetatable(ColorPicker, { __index = BaseComponent })
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
    config = config or {}

    local name = config.Name or ColorPickerDefaults.Name or "Color Picker"
    local description = Create.GetDescription(config)
    local hasDescription = description ~= nil
    local height = hasDescription
            and (ColorPickerSizes.HeightWithDescription or CommonDefaults.HeightWithDescription or 50)
        or Sizes.Button.Height

    local self = BaseComponent.new(ColorPicker, {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height),
        Blockable = true,
        Flag = config.Flag,
        Window = window,
    })

    self._callback = config.Callback or function() end
    self._color = config.Default or PRESETS[1]

    Create.ComponentLabel(
        self._frame,
        name,
        hasDescription,
        ColorPickerSizes.LabelRightPadding or 50
    )

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

    local function close()
        if self._isOpen then
            self._isOpen = false
            self._palette.Visible = false
            if self._outsideClickConn then
                self._outsideClickConn:Disconnect()
                self._outsideClickConn = nil
            end
        end
    end

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
        self:Connect(swatch.MouseButton1Click, function()
            if self._blocked then
                return
            end

            self:SetColor(col)
            close()
        end)
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
        self._isOpen = true

        -- Connect outside-click handler
        if not self._outsideClickConn then
            self._outsideClickConn = self:Connect(
                Services.UserInputService.InputBegan,
                function(input, gameProcessed)
                    if gameProcessed then
                        return
                    end
                    if
                        input.UserInputType ~= Enum.UserInputType.MouseButton1
                        and input.UserInputType ~= Enum.UserInputType.Touch
                    then
                        return
                    end

                    if not self._isOpen then
                        return
                    end

                    local clickPos = input.Position

                    -- Click on palette → let swatch handle it
                    local palPos = self._palette.AbsolutePosition
                    local palSize = self._palette.AbsoluteSize
                    if
                        clickPos.X >= palPos.X
                        and clickPos.X <= palPos.X + palSize.X
                        and clickPos.Y >= palPos.Y
                        and clickPos.Y <= palPos.Y + palSize.Y
                    then
                        return
                    end

                    -- Click on preview → let toggle handle it
                    local prevPos = self._preview.AbsolutePosition
                    local prevSize = self._preview.AbsoluteSize
                    if
                        clickPos.X >= prevPos.X
                        and clickPos.X <= prevPos.X + prevSize.X
                        and clickPos.Y >= prevPos.Y
                        and clickPos.Y <= prevPos.Y + prevSize.Y
                    then
                        return
                    end

                    close()
                end
            )
        end
    end

    self:Connect(previewBtn.MouseButton1Click, function()
        if self._blocked then
            return
        end

        if self._isOpen then
            close()
        else
            open()
        end
    end)

    local baseBlock = self.Block
    self.Block = function(component, text: string?)
        close()
        baseBlock(component, text)
    end

    Create.Configurable(self, self._flag, "ColorPicker", function()
        return {
            R = self._color.R,
            G = self._color.G,
            B = self._color.B,
        }
    end, function(value)
        if
            type(value) == "table"
            and type(value.R) == "number"
            and type(value.G) == "number"
            and type(value.B) == "number"
        then
            self:SetColor(Color3.new(value.R, value.G, value.B))
        elseif typeof(value) == "Color3" then
            self:SetColor(value)
        end
    end)

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
    if self._palette then
        self._palette:Destroy()
        self._palette = nil
    end

    BaseComponent.Destroy(self)
end

return ColorPicker
