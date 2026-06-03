--[[
    AcrylicUI - Instance Creation Utilities

    Helper functions for creating and configuring UI instances.
]]

local Constants = {
    Colors = require(script.Parent.Parent.Constants.Colors),
    Sizes = require(script.Parent.Parent.Constants.Sizes),
    Fonts = require(script.Parent.Parent.Constants.Fonts),
    Defaults = require(script.Parent.Parent.Constants.Defaults),
    Layers = require(script.Parent.Parent.Constants.Layers),
}

local IconResolver = require(script.Parent.IconResolver)

local Create = {}

local INTERNAL_PROPERTIES = {
    Parent = true,
    Name = true,
    PreserveName = true,
    RandomizeName = true,
}

local stealthNameCounter = 0
local stealthNameSeed = math.floor((os.clock() * 1000000) % 1000000000)

local function nextStealthName(): string
    stealthNameCounter += 1
    return "_A" .. tostring(stealthNameSeed) .. "_" .. tostring(stealthNameCounter)
end

local function applyNamePolicy(instance: Instance, className: string, properties: { [string]: any })
    if properties.PreserveName == true and properties.Name ~= nil then
        instance.Name = tostring(properties.Name)
        return
    end

    if properties.RandomizeName == true or className == "ScreenGui" then
        instance.Name = nextStealthName()
    end
end

--[[
    Creates a new instance with properties

    @param className string - The class name of the instance
    @param properties table - Properties to apply
    @return Instance - The created instance

    @example
    local frame = Create.Instance("Frame", {
        Name = "Container",
        BackgroundColor3 = Colors.Background,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = screenGui
    })
]]
function Create.Instance(className: string, properties: { [string]: any }): Instance
    local instance = Instance.new(className)

    for property, value in pairs(properties) do
        if not INTERNAL_PROPERTIES[property] then
            instance[property] = value
        end
    end

    applyNamePolicy(instance, className, properties)

    -- Set parent last to avoid unnecessary property updates
    if properties.Parent then
        instance.Parent = properties.Parent
    end

    return instance
end

--[[
    Creates a UICorner with specified radius

    @param parent Instance - Parent to attach corner to
    @param radius number? - Corner radius in pixels (default: 5)
    @return UICorner
]]
function Create.Corner(parent: Instance, radius: number?): UICorner
    return Create.Instance("UICorner", {
        CornerRadius = UDim.new(0, radius or Constants.Sizes.Corner.Medium),
        Parent = parent,
    }) :: UICorner
end

--[[
    Creates a UIStroke border

    @param parent Instance - Parent to attach stroke to
    @param color Color3? - Stroke color (default: Border color)
    @param transparency number? - Stroke transparency (default: 0)
    @param thickness number? - Stroke thickness (default: 1)
    @return UIStroke
]]
function Create.Stroke(
    parent: Instance,
    color: Color3?,
    transparency: number?,
    thickness: number?
): UIStroke
    return Create.Instance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or Constants.Colors.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        Parent = parent,
    }) :: UIStroke
end

--[[
    Creates a UIPadding

    @param parent Instance - Parent to attach padding to
    @param top number? - Top padding
    @param bottom number? - Bottom padding
    @param left number? - Left padding
    @param right number? - Right padding
    @return UIPadding
]]
function Create.Padding(
    parent: Instance,
    top: number?,
    bottom: number?,
    left: number?,
    right: number?
): UIPadding
    return Create.Instance("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent,
    }) :: UIPadding
end

--[[
    Creates a UIListLayout

    @param parent Instance - Parent to attach layout to
    @param padding number? - Padding between elements
    @param sortOrder Enum.SortOrder? - Sort order
    @param direction Enum.FillDirection? - Fill direction
    @return UIListLayout
]]
function Create.ListLayout(
    parent: Instance,
    padding: number?,
    sortOrder: Enum.SortOrder?,
    direction: Enum.FillDirection?
): UIListLayout
    return Create.Instance("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        FillDirection = direction or Enum.FillDirection.Vertical,
        Parent = parent,
    }) :: UIListLayout
end

--[[
    Creates a UIGridLayout

    @param parent Instance - Parent to attach layout to
    @param cellSize UDim2 - Size of each cell
    @param cellPadding UDim2? - Padding between cells
    @return UIGridLayout
]]
function Create.GridLayout(parent: Instance, cellSize: UDim2, cellPadding: UDim2?): UIGridLayout
    return Create.Instance("UIGridLayout", {
        CellSize = cellSize,
        CellPadding = cellPadding or UDim2.new(0, 5, 0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    }) :: UIGridLayout
end

function Create.GetDescription(config: { [string]: any }?): string?
    if not config then
        return nil
    end

    local description = config.Description or config.Desc
    if description == nil or description == "" then
        return nil
    end

    return tostring(description)
end

--[[
    Applies an icon string to an ImageLabel.

    Accepts:
        "rbxassetid://..."  -> direct asset
        "pack/name"         -> resolved via IconResolver
        nil / "" / unknown  -> hides the label (or applies fallbackIcon)
]]
function Create.ApplyIcon(imageLabel, icon, fallbackIcon)
    if imageLabel == nil then
        return false
    end

    if icon == nil or icon == "" then
        if fallbackIcon and fallbackIcon ~= "" then
            imageLabel.Image = fallbackIcon
            imageLabel.ImageRectOffset = Vector2.zero
            imageLabel.ImageRectSize = Vector2.zero
            imageLabel.Visible = true
            return true
        end
        imageLabel.Visible = false
        return false
    end

    if IconResolver.IsAsset(icon) then
        imageLabel.Image = icon
        imageLabel.ImageRectOffset = Vector2.zero
        imageLabel.ImageRectSize = Vector2.zero
        imageLabel.Visible = true
        return true
    end

    local resolved = IconResolver.Resolve(icon)
    if resolved and resolved.Image then
        imageLabel.Image = resolved.Image
        imageLabel.ImageRectOffset = resolved.ImageRectOffset or Vector2.zero
        imageLabel.ImageRectSize = resolved.ImageRectSize or Vector2.zero
        imageLabel.Visible = true
        return true
    end

    if fallbackIcon and fallbackIcon ~= "" then
        imageLabel.Image = fallbackIcon
        imageLabel.ImageRectOffset = Vector2.zero
        imageLabel.ImageRectSize = Vector2.zero
        imageLabel.Visible = true
        return true
    end

    imageLabel.Visible = false
    return false
end

function Create.Description(
    parent: Instance,
    text: string?,
    position: UDim2,
    size: UDim2
): TextLabel?
    if not text then
        return nil
    end

    return Create.Instance("TextLabel", {
        Name = "Description",
        FontFace = Constants.Fonts.Light,
        TextColor3 = Constants.Colors.TextDark,
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        TextSize = Constants.Fonts.Size.Tiny,
        Position = position,
        Size = size,
        Parent = parent,
    }) :: TextLabel
end

function Create.Blockable(target: any, frame: Instance)
    target._blocked = false
    local messages = Constants.Defaults.Messages or {}
    local commonDefaults = Constants.Defaults.Components and Constants.Defaults.Components.Common
        or {}
    local blockerLayers = Constants.Layers.Blocker or {}

    target._blocker = Create.Instance("TextButton", {
        Name = "Blocker",
        Text = commonDefaults.EmptyText or "",
        AutoButtonColor = false,
        Active = true,
        BackgroundColor3 = Constants.Colors.Background,
        BackgroundTransparency = commonDefaults.BlockerTransparency or 0.22,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = blockerLayers.Overlay or 1000,
        Parent = frame,
    }) :: TextButton

    Create.Corner(target._blocker, Constants.Sizes.Corner.Medium)

    target._blockerLabel = Create.Instance("TextLabel", {
        Name = "BlockerLabel",
        FontFace = Constants.Fonts.Regular,
        TextColor3 = Constants.Colors.Text,
        Text = messages.Blocked or "Blocked",
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        TextSize = Constants.Fonts.Size.Small,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        ZIndex = blockerLayers.Label or 1001,
        Parent = target._blocker,
    }) :: TextLabel

    function target:Block(text: string?)
        local blockText = if text == nil or tostring(text) == ""
            then (messages.Blocked or "Blocked")
            else tostring(text)
        self._blocked = true
        self._blockerLabel.Text = blockText
        self._blocker.Visible = true
    end

    function target:Unblock()
        self._blocked = false
        self._blocker.Visible = false
    end

    function target:IsBlocked(): boolean
        return self._blocked == true
    end
end

return Create
