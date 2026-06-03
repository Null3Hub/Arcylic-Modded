--[[
    AcrylicUI - Dropdown Component

    A dropdown menu with single/multi-select support.
]]

local Create = require(script.Parent.Parent.Utils.Create)
local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Icons = require(script.Parent.Parent.Constants.Icons)
local Layers = require(script.Parent.Parent.Constants.Layers)

local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = BaseComponent })
local ComponentDefaults = Defaults.Components or {}
local CommonDefaults = ComponentDefaults.Common or {}
local DropdownDefaults = ComponentDefaults.Dropdown or {}
local ComponentIcons = Icons.Components or {}
local DropdownLayers = Layers.Dropdown or {}
local DropdownSizes = Sizes.Dropdown or {}
local SELECTED_ICON = ComponentIcons.DropdownSelected or "rbxassetid://16898669433"
local SEARCH_ICON = ComponentIcons.DropdownSearch or "rbxassetid://16898734242"

local function ResolveSearchConfig(searchConfig, name: string): (boolean, string)
    if searchConfig == true then
        return true, "Search " .. name .. "..."
    end

    if type(searchConfig) == "string" then
        return true, searchConfig
    end

    if type(searchConfig) == "table" then
        local enabled = if searchConfig.Enabled == nil then true else searchConfig.Enabled == true
        local placeholder = searchConfig.Placeholder or "Search " .. name .. "..."
        return enabled, tostring(placeholder)
    end

    return false, ""
end

export type DropdownConfig = {
    Name: string?,
    Description: string?,
    Desc: string?,
    Options: { string }?,
    Default: string | { string }?,
    MultiSelect: boolean?,
    Search: boolean | string | { Enabled: boolean?, Placeholder: string? }?,
    Flag: string?,
    Callback: ((selected: string | { string }) -> ())?,
}

export type DropdownObject = {
    SetValue: (self: DropdownObject, value: string | { string }) -> (),
    GetValue: (self: DropdownObject) -> string | { string },
    Refresh: (self: DropdownObject, options: { string }) -> (),
    Open: (self: DropdownObject) -> (),
    Close: (self: DropdownObject) -> (),
    Block: (self: DropdownObject, text: string?) -> (),
    Unblock: (self: DropdownObject) -> (),
    IsBlocked: (self: DropdownObject) -> boolean,
    Destroy: (self: DropdownObject) -> (),
}

--[[
    Creates a new dropdown component

    @param parent Instance - Parent container
    @param config DropdownConfig - Dropdown configuration
    @return DropdownObject - Dropdown control object
]]
function Dropdown.new(parent: Instance, config: DropdownConfig, window): DropdownObject
    local self
    config = config or {}

    local name = config.Name or DropdownDefaults.Name or "Dropdown"
    local options = config.Options
        or DropdownDefaults.Options
        or { "Option 1", "Option 2", "Option 3" }
    local multiSelect = if config.MultiSelect == nil
        then (DropdownDefaults.MultiSelect or false)
        else config.MultiSelect
    local callback = config.Callback or function() end
    local searchEnabled, searchPlaceholder = ResolveSearchConfig(config.Search, name)
    local description = Create.GetDescription(config)
    local hasDescription = description ~= nil
    local height = hasDescription
            and (DropdownSizes.HeightWithDescription or CommonDefaults.HeightWithDescription or 50)
        or Sizes.Dropdown.Height

    local selected = if multiSelect
        then (if type(config.Default) == "table" then config.Default else {})
        else config.Default or options[1]

    self = BaseComponent.new(Dropdown, {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, height),
        Blockable = true,
        Flag = config.Flag,
        Window = window,
    })

    self._options = options
    self._multiSelect = multiSelect
    self._callback = callback
    self._expanded = false
    self._selected = selected
    self._searchEnabled = searchEnabled
    self._searchPlaceholder = searchPlaceholder
    self._searchText = ""

    self._label = Create.ComponentLabel(
        self._frame,
        name,
        hasDescription,
        DropdownSizes.LabelRightPadding or 120
    )

    -- Description
    Create.Description(
        self._frame,
        description,
        UDim2.new(0, Sizes.Component.LabelLeft or 10, 0, Sizes.Component.SectionHeaderHeight or 25),
        UDim2.new(
            1,
            -(DropdownSizes.DescriptionRightPadding or 155),
            0,
            Sizes.Component.DescriptionHeight or 14
        )
    )

    -- Selected display
    self._display = Create.Instance("Frame", {
        Name = "Display",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = CommonDefaults.ControlTransparency or 0.04,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(1, -(DropdownSizes.DisplayRightOffset or 145), 0.5, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(
            0,
            DropdownSizes.DisplayWidth or 135,
            0,
            DropdownSizes.DisplayHeight or 26
        ),
        ZIndex = DropdownLayers.Display or 2,
        Parent = self._frame,
    })

    Create.Corner(self._display, Sizes.Corner.Medium)
    Create.Stroke(self._display)

    -- Selected label
    self._selectedLabel = Create.Instance("TextLabel", {
        Name = "SelectedLabel",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.Text,
        Text = self:_GetDisplayText(),
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Small,
        Size = UDim2.new(1, -(DropdownSizes.SelectedLabelRightPadding or 30), 1, 0),
        Position = UDim2.new(0, DropdownSizes.SelectedLabelPadding or 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = DropdownLayers.Display or 2,
        Parent = self._display,
    })

    -- Arrow indicator
    self._arrow = Create.Instance("ImageLabel", {
        Name = "Arrow",
        ImageColor3 = Colors.TextDark,
        BackgroundTransparency = 1,
        Position = UDim2.new(
            1,
            -(DropdownSizes.ArrowRightOffset or 20),
            0.5,
            -(DropdownSizes.ArrowVerticalOffset or 5)
        ),
        Size = UDim2.new(0, DropdownSizes.ArrowSize or 10, 0, DropdownSizes.ArrowSize or 10),
        Rotation = 0,
        ZIndex = DropdownLayers.Display or 2,
        Parent = self._display,
    })
    Create.ApplyIcon(self._arrow, nil, ComponentIcons.Arrow)

    -- Create options container
    self:_CreateOptionsContainer()

    -- Toggle button
    local toggleBtn = Create.Instance("TextButton", {
        Name = "ToggleButton",
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = DropdownLayers.ToggleButton or 3,
        Parent = self._display,
    })

    self:Connect(toggleBtn.MouseButton1Click, function()
        if self._blocked then
            return
        end

        if self._expanded then
            self:Close()
        else
            self:Open()
        end
    end)

    local contentContainer = self:_GetContentContainer()
    if contentContainer then
        self:Connect(contentContainer:GetPropertyChangedSignal("CanvasPosition"), function()
            if self._expanded then
                self:Close()
            end
        end)
    end

    local popupParent = self:_GetPopupParent()
    self:Connect(popupParent:GetPropertyChangedSignal("AbsoluteSize"), function()
        if self._expanded then
            self:_PositionOptionsContainer(#self:_GetFilteredOptions())
        end
    end)

    self:Connect(self._display:GetPropertyChangedSignal("AbsolutePosition"), function()
        if self._expanded then
            self:_PositionOptionsContainer(#self:_GetFilteredOptions())
        end
    end)

    self:Connect(self._display:GetPropertyChangedSignal("AbsoluteSize"), function()
        if self._expanded then
            self:_PositionOptionsContainer(#self:_GetFilteredOptions())
        end
    end)

    local baseBlock = self.Block
    self.Block = function(component, text: string?)
        component:Close()
        baseBlock(component, text)
    end

    Create.Configurable(self, self._flag, "Dropdown", function()
        return self._selected
    end, function(value)
        if self._multiSelect then
            if type(value) == "table" then
                self:SetValue(value, true)
            end
        elseif type(value) == "string" then
            self:SetValue(value, true)
        end
    end)

    return self
end

function Dropdown:_GetDisplayText(): string
    if self._multiSelect then
        if #self._selected == 0 then
            return DropdownDefaults.NoneText or "None"
        end
        return table.concat(self._selected, DropdownDefaults.Separator or ", ")
    end
    return tostring(self._selected)
end

function Dropdown:_GetSearchAreaHeight(): number
    if not self._searchEnabled then
        return 0
    end

    return (DropdownSizes.SearchHeight or 34) + (DropdownSizes.SearchSeparatorHeight or 1)
end

function Dropdown:_GetFilteredOptions(): { string }
    local searchText = string.lower(tostring(self._searchText or ""))
    if not self._searchEnabled or searchText == "" then
        return self._options
    end

    local filtered = {}
    for _, option in ipairs(self._options) do
        if string.find(string.lower(tostring(option)), searchText, 1, true) then
            table.insert(filtered, option)
        end
    end

    return filtered
end

function Dropdown:_IsSelected(option: string): boolean
    if self._multiSelect then
        return table.find(self._selected, option) ~= nil
    end

    return self._selected == option
end

function Dropdown:_GetPopupHeight(visibleCount: number): number
    local maxVisible = DropdownSizes.MaxVisibleOptions or Sizes.Dropdown.MaxVisibleOptions
    local optionHeight = DropdownSizes.OptionHeight or Sizes.Dropdown.OptionHeight
    local searchAreaHeight = self:_GetSearchAreaHeight()
    local contentHeight = if visibleCount == 0
        then (DropdownSizes.EmptyHeight or 42)
        else math.min(visibleCount, maxVisible) * optionHeight

    return searchAreaHeight + contentHeight
end

function Dropdown:_GetPopupParent(): Instance
    if self._window and self._window.GetPopupLayer then
        local ok, popupLayer = pcall(function()
            return self._window:GetPopupLayer()
        end)

        if ok and popupLayer then
            return popupLayer
        end
    end

    return self._frame
end

function Dropdown:_GetContentContainer(): ScrollingFrame?
    if self._window and self._window.GetContentContainer then
        local ok, contentContainer = pcall(function()
            return self._window:GetContentContainer()
        end)

        if ok and contentContainer then
            return contentContainer
        end
    end

    return nil
end

function Dropdown:_UpdateOptionsLayout(visibleCount: number, popupHeight: number?)
    local width = DropdownSizes.DisplayWidth or 135
    local searchAreaHeight = self:_GetSearchAreaHeight()
    local resolvedPopupHeight = popupHeight or self:_GetPopupHeight(visibleCount)
    local scrollHeight = math.max(0, resolvedPopupHeight - searchAreaHeight)
    local optionHeight = DropdownSizes.OptionHeight or Sizes.Dropdown.OptionHeight

    self._optionsContainer.Size = UDim2.new(0, width, 0, resolvedPopupHeight)
    self._optionsScroll.Position = UDim2.new(0, 0, 0, searchAreaHeight)
    self._optionsScroll.Size = UDim2.new(1, 0, 0, scrollHeight)
    self._optionsScroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * optionHeight)

    if self._emptyState then
        self._emptyState.Position = UDim2.new(0, 0, 0, searchAreaHeight)
        self._emptyState.Size = UDim2.new(1, 0, 0, scrollHeight)
    end
end

function Dropdown:_PositionOptionsContainer(visibleCount: number)
    local popupParent = self:_GetPopupParent()
    if self._optionsContainer.Parent ~= popupParent then
        self._optionsContainer.Parent = popupParent
    end

    local margin = DropdownSizes.PopupMargin or 4
    local width = DropdownSizes.DisplayWidth or self._display.AbsoluteSize.X
    local desiredHeight = self:_GetPopupHeight(visibleCount)
    local parentPosition = popupParent.AbsolutePosition
    local parentSize = popupParent.AbsoluteSize
    local displayPosition = self._display.AbsolutePosition
    local displaySize = self._display.AbsoluteSize

    local relativeX = displayPosition.X - parentPosition.X
    local belowY = displayPosition.Y
        - parentPosition.Y
        + displaySize.Y
        - (DropdownSizes.PopupOverlap or 1)
    local aboveBottomY = displayPosition.Y - parentPosition.Y + (DropdownSizes.PopupOverlap or 1)
    local availableBelow = parentSize.Y - belowY - margin
    local availableAbove = aboveBottomY - margin
    local openUp = desiredHeight > availableBelow and availableAbove > availableBelow
    local availableHeight = math.max(0, if openUp then availableAbove else availableBelow)
    local resolvedHeight = math.min(desiredHeight, availableHeight)

    if resolvedHeight <= 0 then
        resolvedHeight = math.min(desiredHeight, parentSize.Y)
    end

    local maxX = math.max(margin, parentSize.X - width - margin)
    local relativeY = if openUp then aboveBottomY - resolvedHeight else belowY
    local maxY = math.max(margin, parentSize.Y - resolvedHeight - margin)

    self._optionsContainer.Position =
        UDim2.new(0, math.clamp(relativeX, margin, maxX), 0, math.clamp(relativeY, margin, maxY))
    self:_UpdateOptionsLayout(visibleCount, resolvedHeight)
end

function Dropdown:_CreateOptionsContainer()
    local totalHeight = self:_GetPopupHeight(#self._options)

    self._optionsContainer = Create.Instance("Frame", {
        Name = "OptionsContainer",
        BackgroundColor3 = Colors.Secondary,
        BackgroundTransparency = CommonDefaults.ControlTransparency or 0.04,
        Position = UDim2.new(
            1,
            -(DropdownSizes.DisplayRightOffset or 145),
            0,
            self._frame.AbsoluteSize.Y - (DropdownSizes.PopupOverlap or 1)
        ),
        BorderSizePixel = 0,
        Size = UDim2.new(0, DropdownSizes.DisplayWidth or 135, 0, totalHeight),
        Visible = false,
        ZIndex = DropdownLayers.Options or 100,
        ClipsDescendants = true,
        Parent = self:_GetPopupParent(),
    })

    Create.Corner(self._optionsContainer, Sizes.Corner.Medium)
    Create.Stroke(self._optionsContainer)

    if self._searchEnabled then
        self._searchContainer = Create.Instance("Frame", {
            Name = "Search",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, DropdownSizes.SearchHeight or 34),
            ZIndex = (DropdownLayers.Options or 100) + 1,
            Parent = self._optionsContainer,
        })

        local searchIcon = Create.Instance("ImageLabel", {
            Name = "SearchIcon",
            ImageColor3 = Colors.TextDark,
            BackgroundTransparency = 1,
            Position = UDim2.new(
                0,
                DropdownSizes.SearchIconLeft or 10,
                0.5,
                -((DropdownSizes.SearchIconSize or 16) / 2)
            ),
            Size = UDim2.new(
                0,
                DropdownSizes.SearchIconSize or 16,
                0,
                DropdownSizes.SearchIconSize or 16
            ),
            ZIndex = (DropdownLayers.Options or 100) + 2,
            Parent = self._searchContainer,
        })
        Create.ApplyIcon(searchIcon, nil, SEARCH_ICON)

        self._searchInput = Create.Instance("TextBox", {
            Name = "SearchInput",
            FontFace = Fonts.Regular,
            TextColor3 = Colors.Text,
            PlaceholderText = self._searchPlaceholder,
            PlaceholderColor3 = Colors.TextDark,
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            TextSize = Fonts.Size.Small,
            Position = UDim2.new(0, DropdownSizes.SearchTextLeft or 34, 0, 0),
            Size = UDim2.new(1, -((DropdownSizes.SearchTextLeft or 34) + 10), 1, 0),
            ZIndex = (DropdownLayers.Options or 100) + 2,
            Parent = self._searchContainer,
        })

        self:Connect(self._searchInput:GetPropertyChangedSignal("Text"), function()
            self._searchText = self._searchInput.Text
            self:_PopulateOptions()
        end)

        Create.Instance("Frame", {
            Name = "SearchSeparator",
            BackgroundColor3 = Colors.Border,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 10, 0, DropdownSizes.SearchHeight or 34),
            Size = UDim2.new(1, -20, 0, DropdownSizes.SearchSeparatorHeight or 1),
            ZIndex = (DropdownLayers.Options or 100) + 1,
            Parent = self._optionsContainer,
        })
    end

    self._optionsScroll = Create.Instance("ScrollingFrame", {
        Name = "Scroll",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, self:_GetSearchAreaHeight()),
        Size = UDim2.new(1, 0, 1, -self:_GetSearchAreaHeight()),
        CanvasSize = UDim2.new(0, 0, 0, #self._options * (DropdownSizes.OptionHeight or 30)),
        ScrollBarThickness = DropdownSizes.ScrollbarThickness or 3,
        ScrollBarImageColor3 = Colors.Scrollbar,
        ScrollBarImageTransparency = 0.7,
        ZIndex = DropdownLayers.Options or 100,
        Parent = self._optionsContainer,
    })

    Create.ListLayout(self._optionsScroll, 0)

    self._emptyState = Create.Instance("TextLabel", {
        Name = "EmptyState",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = "Not found any",
        BackgroundTransparency = 1,
        TextSize = Fonts.Size.Small,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Position = UDim2.new(0, 0, 0, self:_GetSearchAreaHeight()),
        Size = UDim2.new(1, 0, 1, -self:_GetSearchAreaHeight()),
        Visible = false,
        ZIndex = (DropdownLayers.Options or 100) + 1,
        Parent = self._optionsContainer,
    })

    self:_PopulateOptions()
end

function Dropdown:_PopulateOptions()
    for _, child in ipairs(self._optionsScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local filteredOptions = self:_GetFilteredOptions()
    local hasOptions = #filteredOptions > 0
    if self._expanded then
        self:_PositionOptionsContainer(#filteredOptions)
    else
        self:_UpdateOptionsLayout(#filteredOptions)
    end
    self._optionsScroll.Visible = hasOptions
    if self._emptyState then
        self._emptyState.Visible = not hasOptions
    end

    for _, option in ipairs(filteredOptions) do
        local selected = self:_IsSelected(option)
        local optionBtn = Create.Instance("TextButton", {
            Name = "Option_" .. option,
            Text = CommonDefaults.EmptyText or "",
            AutoButtonColor = false,
            BackgroundColor3 = Colors.Secondary,
            BackgroundTransparency = selected and 0.9 or (CommonDefaults.Transparent or 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, DropdownSizes.OptionHeight or Sizes.Dropdown.OptionHeight),
            ZIndex = DropdownLayers.Options or 100,
            Parent = self._optionsScroll,
        })

        local selectedIcon = Create.Instance("ImageLabel", {
            Name = "SelectedIcon",
            ImageColor3 = Colors.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(
                0,
                DropdownSizes.OptionIconLeft or 12,
                0.5,
                -((DropdownSizes.OptionIconSize or 14) / 2)
            ),
            Size = UDim2.new(
                0,
                DropdownSizes.OptionIconSize or 14,
                0,
                DropdownSizes.OptionIconSize or 14
            ),
            Visible = selected,
            ZIndex = (DropdownLayers.Options or 100) + 1,
            Parent = optionBtn,
        })
        Create.ApplyIcon(selectedIcon, nil, SELECTED_ICON)

        local optionText = Create.Instance("TextLabel", {
            Name = "OptionText",
            FontFace = Fonts.Regular,
            TextColor3 = selected and Colors.Text or Colors.TextDark,
            Text = option,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BackgroundTransparency = 1,
            TextSize = Fonts.Size.Small,
            Position = UDim2.new(0, DropdownSizes.OptionTextLeft or 36, 0, 0),
            Size = UDim2.new(
                1,
                -(
                        (DropdownSizes.OptionTextLeft or 36)
                        + (DropdownSizes.OptionTextRightPadding or 10)
                    ),
                1,
                0
            ),
            ZIndex = (DropdownLayers.Options or 100) + 1,
            Parent = optionBtn,
        })

        local function setHoverVisual(hovering: boolean)
            local backgroundTransparency = if hovering
                then (if selected then 0.68 else 0.78)
                else (if selected then 0.9 else (CommonDefaults.Transparent or 1))
            local textColor = if hovering or selected then Colors.Text else Colors.TextDark

            Tween.Create(optionBtn, { BackgroundTransparency = backgroundTransparency }, "Fast")
            Tween.Create(optionText, { TextColor3 = textColor }, "Fast")
            if selectedIcon.Visible then
                Tween.Create(selectedIcon, { ImageColor3 = textColor }, "Fast")
            end
        end

        optionBtn.MouseEnter:Connect(function()
            setHoverVisual(true)
        end)

        optionBtn.MouseLeave:Connect(function()
            setHoverVisual(false)
        end)

        optionBtn.MouseButton1Click:Connect(function()
            if self._blocked then
                return
            end

            if self._multiSelect then
                local index = table.find(self._selected, option)
                if index then
                    table.remove(self._selected, index)
                else
                    table.insert(self._selected, option)
                end
                self:_UpdateDisplay()
                self:_PopulateOptions()
                self._callback(self._selected)
            else
                self._selected = option
                self:_UpdateDisplay()
                self:_PopulateOptions()
                self._callback(self._selected)
                self:Close()
            end
        end)
    end
end

function Dropdown:_UpdateDisplay()
    self._selectedLabel.Text = self:_GetDisplayText()
end

function Dropdown:Open()
    if self._blocked then
        return
    end

    self._expanded = true
    self:_PopulateOptions()
    self._optionsContainer.Visible = true
    Tween.Create(self._arrow, { Rotation = 180 }, "Normal")
    self._frame.ZIndex = DropdownLayers.Open or 10
end

function Dropdown:Close()
    self._expanded = false
    self._optionsContainer.Visible = false
    Tween.Create(self._arrow, { Rotation = 0 }, "Normal")
    self._frame.ZIndex = DropdownLayers.Base or 1
end

function Dropdown:SetValue(value: string | { string }, silent: boolean?)
    if self._multiSelect then
        if type(value) == "table" then
            self._selected = value
        end
    else
        self._selected = value
    end
    self:_UpdateDisplay()
    if self._optionsScroll then
        self:_PopulateOptions()
    end
    if not silent then
        self._callback(self._selected)
    end
end

function Dropdown:GetValue(): string | { string }
    return self._selected
end

function Dropdown:Refresh(options: { string })
    self._options = options
    self:_PopulateOptions()
end

function Dropdown:Destroy()
    if self._optionsContainer then
        self._optionsContainer:Destroy()
        self._optionsContainer = nil
    end

    BaseComponent.Destroy(self)
end

return Dropdown
