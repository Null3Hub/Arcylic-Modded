local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Fonts = require(script.Parent.Parent.Constants.Fonts)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Defaults = require(script.Parent.Parent.Constants.Defaults)
local Icons = require(script.Parent.Parent.Constants.Icons)

local Section = {}
Section.__index = Section
local ComponentIcons = Icons.Components or {}
local CommonDefaults = Defaults.Components and Defaults.Components.Common or {}

function Section.new(window, name: string)
    local self = setmetatable({}, Section)
    self._window = window
    self._name = name
    self._tabs = {}
    self._connections = {}

    -- Sidebar section frame
    self._frame = Create.Instance("Frame", {
        Name = "Section_" .. name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -(Sizes.Section.FrameRightPadding or 10), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = window:GetSectionsContainer(),
    })

    Create.ListLayout(self._frame, Sizes.Section.LayoutPadding or 2)

    -- Header container
    local header = Create.Instance("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, Sizes.Section.HeaderHeight or 25),
        LayoutOrder = 0,
        Parent = self._frame,
    })

    -- Click area
    local headerBtn = Create.Instance("TextButton", {
        Name = "HeaderButton",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = CommonDefaults.EmptyText or "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = header,
    })

    -- Label
    local label = Create.Instance("TextLabel", {
        Name = "Label",
        FontFace = Fonts.Regular,
        TextColor3 = Colors.TextDark,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, Sizes.Section.LabelLeft or 5, 0, 0),
        TextSize = Fonts.Size.Small,
        Size = UDim2.new(1, -(Sizes.Section.LabelRightPadding or 25), 1, 0),
        Parent = header,
    })

    -- Arrow
    local arrow = Create.Instance("ImageButton", {
        Name = "Arrow",
        Image = ComponentIcons.Arrow or "rbxassetid://105558791071013",
        ImageColor3 = Colors.TextDark,
        BackgroundTransparency = 1,
        Position = UDim2.new(
            1,
            -(Sizes.Section.ArrowRightOffset or 20),
            0.5,
            -(Sizes.Section.ArrowVerticalOffset or 7)
        ),
        Size = UDim2.new(0, Sizes.Section.ArrowSize or 15, 0, Sizes.Section.ArrowSize or 15),
        Rotation = 0,
        Parent = header,
    })

    -- Tabs container
    self._tabsContainer = Create.Instance("Frame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        LayoutOrder = 1,
        Parent = self._frame,
    })

    Create.ListLayout(self._tabsContainer, Sizes.Section.LayoutPadding or 2)
    Create.Padding(self._tabsContainer, 0, 0, Sizes.Section.TabsIndent or 15, 0)

    local expanded = true
    local function toggle()
        expanded = not expanded
        Tween.Create(arrow, { Rotation = expanded and 0 or 180 }, "Normal")
        self._tabsContainer.Visible = expanded
    end

    table.insert(self._connections, headerBtn.MouseButton1Click:Connect(toggle))
    table.insert(self._connections, arrow.MouseButton1Click:Connect(toggle))

    self._label = label
    self._arrow = arrow

    return self
end

function Section:CreateTab(name: string, icon: string?)
    local Tab = require(script.Parent.Tab)
    local tab = Tab.new(self._window, self, name, icon)
    table.insert(self._tabs, tab)
    return tab
end

function Section:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)

    for _, tab in ipairs(self._tabs) do
        if tab.Destroy then
            tab:Destroy()
        end
    end
    table.clear(self._tabs)

    if self._frame then
        self._frame:Destroy()
    end
end

return Section
