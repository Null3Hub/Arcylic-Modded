const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), "utf8");
}

function assertIncludes(file, text) {
  assert.ok(read(file).includes(text), `${file} should include ${text}`);
}

function assertNotIncludes(file, text) {
  assert.ok(!read(file).includes(text), `${file} should not include ${text}`);
}

function assertOrdered(file, source, before, after) {
  const beforeIndex = source.indexOf(before);
  const afterIndex = source.indexOf(after);
  assert.ok(beforeIndex >= 0, `${file} should include ${before}`);
  assert.ok(afterIndex >= 0, `${file} should include ${after}`);
  assert.ok(beforeIndex < afterIndex, `${file} should place ${before} before ${after}`);
}

for (const windowPath of [
  "src/Core/Window.luau",
  "studio/AcrylicUI/Core/Window.luau",
]) {
  const source = read(windowPath);
  assert.ok(
    source.includes("ConfigEncryption.IsEncrypted(rawData)"),
    `${windowPath} should detect encrypted configs before JSON fallback`,
  );
  assert.ok(
    !source.includes("function Window:Unload"),
    `${windowPath} should expose Destroy as the only window cleanup method`,
  );
  assertIncludes(windowPath, '"MinimizeControlFrame"');
  assertIncludes(windowPath, '"CloseControlFrame"');
  assertIncludes(windowPath, "WindowChromeSizes.ControlFrameGap or 1");
  assertIncludes(windowPath, "WindowChromeSizes.ControlFrameRightInset or 5");
  assertIncludes(windowPath, "WindowChromeSizes.ControlFrameTop or 7");
  assertIncludes(windowPath, "WindowChromeSizes.ControlFrameButtonWidth or 31");
  assertIncludes(windowPath, "WindowChromeSizes.ControlFrameHeight or 31");
  assertIncludes(windowPath, "UDim.new(0, 5)");
  assertIncludes(windowPath, "ApplyStrokeMode = Enum.ApplyStrokeMode.Border");
  assertIncludes(windowPath, "BorderStrokePosition = Enum.BorderStrokePosition.Inner");
  assertIncludes(windowPath, "LineJoinMode = Enum.LineJoinMode.Round");
  assertIncludes(windowPath, "self._headerSeparator = Create.Instance(\"Frame\"");
  assertIncludes(windowPath, "self._headerSeparator.Visible = false");
  assertIncludes(windowPath, "self._headerSeparator.Visible = true");
  assertIncludes(windowPath, "self._minimizedChangedEvent = Instance.new(\"BindableEvent\")");
  assertIncludes(windowPath, "self._minimizedChangedEvent:Fire(self._minimized)");
  assertIncludes(windowPath, "function Window:GetMinimizedSignal(): RBXScriptSignal");
  assertIncludes(windowPath, "return self._minimizedChangedEvent.Event");
}

{
  const studioWindowPath = "studio/AcrylicUI/Core/Window.luau";
  assertIncludes(studioWindowPath, '"AvatarControlFrame"');
  assertIncludes(studioWindowPath, 'Name = "Avatar"');
  assertIncludes(studioWindowPath, 'Name = "AvatarSeparator"');
  assertIncludes(studioWindowPath, "Services.Players.LocalPlayer");
  assertIncludes(studioWindowPath, "GetUserThumbnailAsync");
  assertIncludes(studioWindowPath, "Enum.ThumbnailType.HeadShot");
  assertIncludes(studioWindowPath, "Enum.ThumbnailSize.Size48x48");
  assertIncludes(studioWindowPath, "UICorner");
  assertIncludes(studioWindowPath, "WindowChromeSizes.ControlFrameAvatarGap or 4");
  assertIncludes(studioWindowPath, "WindowChromeSizes.ControlFrameSeparatorWidth or 1");
  assertIncludes(studioWindowPath, "WindowChromeSizes.ControlFrameSeparatorHeight or 20");
  assertIncludes("studio/AcrylicUI/Constants/Sizes.luau", "ControlFrameAvatarGap = 4");
  assertIncludes("studio/AcrylicUI/Constants/Sizes.luau", "ControlFrameSeparatorWidth = 1");
  assertIncludes("studio/AcrylicUI/Constants/Sizes.luau", "ControlFrameSeparatorHeight = 20");
  assertIncludes("studio/AcrylicUI/Constants/Sizes.luau", "TopBarControlsWidth = 120");
}

{
  const srcWindowPath = "src/Core/Window.luau";
  assertIncludes(srcWindowPath, '"AvatarControlFrame"');
  assertIncludes(srcWindowPath, 'Name = "Avatar"');
  assertIncludes(srcWindowPath, 'Name = "AvatarSeparator"');
  assertIncludes(srcWindowPath, "Services.Players.LocalPlayer");
  assertIncludes(srcWindowPath, "GetUserThumbnailAsync");
  assertIncludes(srcWindowPath, "Enum.ThumbnailType.HeadShot");
  assertIncludes(srcWindowPath, "Enum.ThumbnailSize.Size48x48");
  assertIncludes(srcWindowPath, "UDim.new(0, 5)");
  assertIncludes(srcWindowPath, "Position = UDim2.new(0.5, 0, 0.5, 1)");
  assertIncludes(srcWindowPath, "WindowChromeSizes.ControlFrameAvatarGap or 4");
  assertIncludes(srcWindowPath, "WindowChromeSizes.ControlFrameSeparatorWidth or 1");
  assertIncludes(srcWindowPath, "WindowChromeSizes.ControlFrameSeparatorHeight or 20");
  assertIncludes("src/Constants/Sizes.luau", "ControlFrameAvatarGap = 4");
  assertIncludes("src/Constants/Sizes.luau", "ControlFrameSeparatorWidth = 1");
  assertIncludes("src/Constants/Sizes.luau", "ControlFrameSeparatorHeight = 20");
  assertIncludes("src/Constants/Sizes.luau", "TopBarControlsWidth = 120");
}

for (const dropdownPath of [
  "src/Components/Dropdown.luau",
  "studio/AcrylicUI/Components/Dropdown.luau",
]) {
  assertIncludes(dropdownPath, "local function IsPointInsideGui");
  assertIncludes(dropdownPath, "Services.UserInputService.InputChanged");
  assertIncludes(dropdownPath, "Enum.UserInputType.MouseWheel");
  assertIncludes(dropdownPath, "self:_ShouldCloseForScrollInput(input)");
  assertIncludes(dropdownPath, "self._window:GetMinimizedSignal()");
  assertIncludes(dropdownPath, "if minimized and self._expanded then");
}

for (const encryptionPath of [
  "src/Utils/ConfigEncryption.luau",
  "studio/AcrylicUI/Utils/ConfigEncryption.luau",
]) {
  assertIncludes(encryptionPath, "function ConfigEncryption.IsEncrypted");
}

for (const typesPath of [
  "src/Types.luau",
  "studio/AcrylicUI/Types.luau",
]) {
  assertIncludes(typesPath, "Parent: Instance?");
  assertIncludes(typesPath, "Search: boolean | string | { Enabled: boolean?, Placeholder: string? }?");
}

assertNotIncludes("README.md", "scripts/build-bundle.ps1");
assertNotIncludes("README.md", "scripts/validate-bundle.ps1");
assertIncludes("README.md", "## UI Elements");
assertIncludes("README.md", "## Exemple");
assertIncludes("README.md", "Exemple.lua");
assertNotIncludes("README.md", "window:Unload");

assertIncludes(".github/workflows/ci.yml", "node tests/static-contracts.test.js");
assertIncludes(".github/workflows/ci.yml", "rojo build default.project.json");
assertIncludes(".github/workflows/ci.yml", "rojo build studio.project.json");
assertIncludes(".github/workflows/ci.yml", "rojo build test.project.json");

assert.ok(fs.existsSync(path.join(root, "tests/smoke.client.luau")));

for (const notificationPath of [
  "src/Core/Notification.luau",
  "studio/AcrylicUI/Core/Notification.luau",
]) {
  const notificationSource = read(notificationPath);

  assertIncludes(notificationPath, 'Name = "IconColumn"');
  assertIncludes(notificationPath, 'Name = "BellIcon"');
  assertIncludes(notificationPath, 'Name = "VerticalSeparator"');
  assertIncludes(notificationPath, 'Name = "TextColumn"');
  assertIncludes(notificationPath, 'Name = "CountdownLabel"');
  assertIncludes(notificationPath, 'Name = "ContentTitle"');
  assertIncludes(notificationPath, 'Name = "ContentText"');
  assertIncludes(notificationPath, "local CARD_MIN_HEIGHT = 85");
  assertIncludes(notificationPath, "local CARD_PADDING_X = 16");
  assertIncludes(notificationPath, "local CARD_PADDING_Y = 16");
  assertIncludes(notificationPath, "local BELL_ICON_SIZE = 32");
  assertIncludes(notificationPath, "local ICON_COLUMN_WIDTH = 32");
  assertIncludes(notificationPath, "local SEPARATOR_WIDTH = 1");
  assertIncludes(notificationPath, "local SEPARATOR_HEIGHT = 90");
  assertIncludes(notificationPath, "local SEPARATOR_SPACING = 16");
  assertIncludes(notificationPath, "local COUNTDOWN_WIDTH = 40");
  assertIncludes(notificationPath, "local COUNTDOWN_TOP = 12");
  assertIncludes(notificationPath, "local COUNTDOWN_RIGHT = 16");
  assertIncludes(notificationPath, "local TEXT_SPACING = 4");
  assertIncludes(notificationPath, "local TEXT_COUNTDOWN_GUTTER = 48");
  assertIncludes(notificationPath, "local function BuildHorizontalLayout");
  assertIncludes(notificationPath, "local function ResizeNotification");
  assertIncludes(notificationPath, "math.max(CARD_MIN_HEIGHT");
  assertIncludes(notificationPath, "+ textLayout.AbsoluteContentSize.Y");
  assertIncludes(notificationPath, "AnchorPoint = Vector2.new(1, 0)");
  assertIncludes(notificationPath, "Position = UDim2.new(1, -COUNTDOWN_RIGHT, 0, COUNTDOWN_TOP)");
  assertIncludes(notificationPath, "Size = UDim2.new(0, BELL_ICON_SIZE, 0, BELL_ICON_SIZE)");
  assertIncludes(notificationPath, "Size = UDim2.new(0, SEPARATOR_WIDTH, 0, SEPARATOR_HEIGHT)");
  assertIncludes(notificationPath, "TextSize = 12");
  assertIncludes(notificationPath, "Fonts.Medium");
  assertIncludes(notificationPath, "Color3.fromRGB(153, 153, 153)");
  assertIncludes(notificationPath, "Text = tostring(math.ceil(duration)) .. \"s\"");
  assertIncludes(notificationPath, "local function StartCountdown");
  assertIncludes(notificationPath, "countdownLabel.Text = remaining .. \"s\"");
  assertIncludes(notificationPath, "countdownLabel.Text = \"0s\"");
  assertIncludes(notificationPath, "StartCountdown(notification, countdownLabel, duration)");
  assertIncludes(notificationPath, "local FAN_MAX = 4");
  assertIncludes(notificationPath, "local FAN_STACK_OFFSET_Y = -12");
  assertIncludes(notificationPath, "local FAN_SCALE_DECREMENT = 0.05");
  assertIncludes(notificationPath, "local function GetViewportWidth");
  assertIncludes(notificationPath, "local function ResolveNotificationWidth");
  assertIncludes(notificationPath, "local function UpdateContainerLayout");
  assertIncludes(notificationPath, "NotificationSizes.SafeMargin or 16");
  assertIncludes(notificationPath, "NotificationSizes.MinWidth or 260");
  assertIncludes(notificationPath, "local NotificationData");
  assertIncludes(notificationPath, "CountdownLabel: TextLabel");
  assertIncludes(notificationPath, "local ClosingNotifications");
  assertIncludes(notificationPath, "AnchorPoint = Vector2.new(0, 1)");
  assertIncludes(notificationPath, "AnchorPoint = Vector2.new(1, 1)");
  assertIncludes(notificationPath, ":GetPropertyChangedSignal(\"ViewportSize\")");
  assertIncludes(notificationPath, "UpdateContainerLayout(container)");
  assertIncludes(notificationPath, "Position = UDim2.new(1, FAN_ENTRY_OFFSET_X, 1, 0)");
  assertIncludes(notificationPath, "Position = UDim2.new(0, 0, 1, targetY)");
  assertIncludes(notificationPath, "Scale = targetScale");
  assertIncludes(notificationPath, "Position = currentPos + UDim2.fromOffset(FAN_EXIT_OFFSET_X, 0)");
  assertIncludes(notificationPath, "UpdateGrouping(container)");
  assertIncludes(notificationPath, "local function TweenFade");
  assertIncludes(notificationPath, "TweenFade(inst, props)");
  assertIncludes(notificationPath, "Services.TweenService:Create(inst, tweenInfo, props)");
  assertIncludes(notificationPath, "local function ApplyNotificationZIndex");
  assertIncludes(notificationPath, "descendant:IsA(\"GuiObject\")");
  assertIncludes(notificationPath, "descendant.ZIndex = baseZIndex + 1");
  assertIncludes(notificationPath, "if ClosingNotifications[notifFrame] then");
  assertOrdered(
    notificationPath,
    notificationSource,
    "if ClosingNotifications[notifFrame] then",
    "local age = count - i",
  );
  assertNotIncludes(notificationPath, 'Name = "WindowTitle"');
  assertNotIncludes(notificationPath, 'Name = "Header"');
  assertNotIncludes(notificationPath, 'Name = "RightSlot"');
  assertNotIncludes(notificationPath, 'Name = "TimerSlot"');
  assertNotIncludes(notificationPath, 'Name = "Timer"');
  assertNotIncludes(notificationPath, 'Name = "Fill"');
  assertNotIncludes(notificationPath, "Text = windowTitle");
  assertNotIncludes(notificationPath, "local HEADER_HEIGHT");
  assertNotIncludes(notificationPath, "local HEADER_PADDING_LEFT");
  assertNotIncludes(notificationPath, "local CONTENT_POSITION_Y");
  assertNotIncludes(notificationPath, "local TIMER_TOP_MARGIN");
  assertNotIncludes(notificationPath, "local TIMER_HEIGHT");
  assertNotIncludes(notificationPath, "BuildHeader");
  assertNotIncludes(notificationPath, "BuildTimer");
  assertNotIncludes(notificationPath, "Tween.Create(timerFill");
  assertNotIncludes(notificationPath, "TimerBar: Frame");
  assertNotIncludes(notificationPath, 'Name = "AppIcon"');
  assertNotIncludes(notificationPath, "local icon = config.Icon");
  assertNotIncludes(notificationPath, "windowTitle .. \"  ·  \" .. os.date");
  assertNotIncludes(notificationPath, "GetStackY");
  assertNotIncludes(notificationPath, "Create.ListLayout(notification, 6)");
  assertNotIncludes(notificationPath, "Create.Padding(notification, 10, 10, 10, 10)");
}

for (const fontsPath of [
  "src/Constants/Fonts.luau",
  "studio/AcrylicUI/Constants/Fonts.luau",
]) {
  assertIncludes(fontsPath, "Medium");
}

for (const sizesPath of [
  "src/Constants/Sizes.luau",
  "studio/AcrylicUI/Constants/Sizes.luau",
]) {
  assertIncludes(sizesPath, "ControlFrameRightInset = 5");
  assertIncludes(sizesPath, "ControlFrameTop = 7");
  assertIncludes(sizesPath, "ControlFrameButtonWidth = 31");
  assertIncludes(sizesPath, "ControlFrameGap = 1");
  assertIncludes(sizesPath, "ControlFrameHeight = 31");
  assertIncludes(sizesPath, "LabelCenterOffset = 10");
  assertIncludes(sizesPath, "Slider = {");
  assertIncludes(sizesPath, "LabelCenterOffset = 18");
  assertIncludes(sizesPath, "Width = 320");
  assertIncludes(sizesPath, "MinWidth = 260");
  assertIncludes(sizesPath, "Height = 85");
  assertIncludes(sizesPath, "SafeMargin = 16");
  assertIncludes(sizesPath, "RightOffset = 344");
  assertIncludes(sizesPath, "BottomOffset = 24");
}

for (const createPath of [
  "src/Utils/Create.luau",
  "studio/AcrylicUI/Utils/Create.luau",
]) {
  assertIncludes(createPath, "labelCenterOffset: number?");
  assertIncludes(createPath, "-(labelCenterOffset or Constants.Sizes.Component.LabelCenterOffset or 10)");
}

for (const sliderPath of [
  "src/Components/Slider.luau",
  "studio/AcrylicUI/Components/Slider.luau",
]) {
  assertIncludes(sliderPath, "Sizes.Slider.LabelCenterOffset or 18");
}

for (const tweenPath of [
  "src/Utils/Tween.luau",
  "studio/AcrylicUI/Utils/Tween.luau",
]) {
  assertIncludes(tweenPath, "pcall(function()");
  assertIncludes(tweenPath, "Services.TweenService:Create(instance, tweenInfo, properties)");
  assertIncludes(tweenPath, "if not tween then");
}
