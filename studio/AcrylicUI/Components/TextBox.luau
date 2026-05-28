local Create = require(script.Parent.Parent.Utils.Create)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Colors = require(script.Parent.Parent.Constants.Colors)
local Sizes = require(script.Parent.Parent.Constants.Sizes)
local Fonts = require(script.Parent.Parent.Constants.Fonts)

local TextBox = {}
TextBox.__index = TextBox

export type TextBoxConfig = {
	Name: string?,
	Default: string?,
	Placeholder: string?,
	ClearOnFocus: boolean?,
	NumbersOnly: boolean?,
	Flag: string?,
	Callback: ((text: string, enterPressed: boolean) -> ())?,
}

function TextBox.new(parent: Instance, config: TextBoxConfig?, window)
	local self = setmetatable({}, TextBox)
	config = config or {}

	local name = config.Name or "TextBox"
	local placeholder = config.Placeholder or "Enter text..."

	local description = Create.GetDescription(config)
	local hasDescription = description ~= nil
	local height = hasDescription and 50 or Sizes.Button.Height

	self._callback = config.Callback or function() end
	self._text = tostring(config.Default or "")
	self._connections = {}
	self._window = window
	self._flag = config.Flag
	self._numbersOnly = config.NumbersOnly or false

	self._frame = Create.Instance("Frame", {
		Name = "TextBox_" .. name,
		BackgroundColor3 = Colors.Secondary,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height),
		Parent = parent,
	})

	Create.Corner(self._frame, Sizes.Corner.Medium)
	Create.Stroke(self._frame)

	self._label = Create.Instance("TextLabel", {
		Name = "Name",
		FontFace = Fonts.Regular,
		TextColor3 = Colors.Text,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = hasDescription and UDim2.new(0, 10, 0, 7) or UDim2.new(0, 10, 0.5, -10),
		TextSize = Fonts.Size.Normal,
		Size = UDim2.new(1, -190, 0, 20),
		Parent = self._frame,
	})

	Create.Description(self._frame, description, UDim2.new(0, 10, 0, 27), UDim2.new(1, -190, 0, 14))

	self._icon = Create.Instance("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Image = "rbxassetid://93828793199781",
		ImageColor3 = Colors.TextDark,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -165, 0.5, 0),
		Size = UDim2.new(0, 18, 0, 18),
		Parent = self._frame,
	})

	self._container = Create.Instance("Frame", {
		Name = "TextBoxContainer",
		BackgroundColor3 = Colors.Secondary,
		BackgroundTransparency = 0.04,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(0, Sizes.TextBox.InputWidth, 0, 26),
		Parent = self._frame,
	})

	Create.Corner(self._container, Sizes.Corner.Medium)
	self._stroke = Create.Stroke(self._container)

	self._input = Create.Instance("TextBox", {
		Name = "Input",
		FontFace = Fonts.Regular,
		TextColor3 = Colors.Text,
		PlaceholderText = placeholder,
		PlaceholderColor3 = Colors.TextDark,
		Text = self._text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		TextSize = Fonts.Size.Small,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		ClearTextOnFocus = config.ClearOnFocus or false,
		Parent = self._container,
	})

	table.insert(
		self._connections,
		self._input.Focused:Connect(function()
			Tween.Create(self._container, { BackgroundTransparency = 0 }, "Fast")
			Tween.Create(self._stroke, { Color = Colors.Accent }, "Fast")
			Tween.Create(self._icon, { ImageColor3 = Colors.Text }, "Fast")
		end)
	)

	table.insert(
		self._connections,
		self._input.FocusLost:Connect(function(enterPressed)
			Tween.Create(self._container, { BackgroundTransparency = 0.04 }, "Fast")
			Tween.Create(self._stroke, { Color = Colors.Border }, "Fast")
			Tween.Create(self._icon, { ImageColor3 = Colors.TextDark }, "Fast")

			if self._numbersOnly then
				local numberValue = tonumber(self._input.Text)
				if numberValue then
					self._text = tostring(numberValue)
				end
				self._input.Text = self._text
			else
				self._text = self._input.Text
			end

			self._callback(self._text, enterPressed)
		end)
	)

	if self._numbersOnly then
		table.insert(
			self._connections,
			self._input:GetPropertyChangedSignal("Text"):Connect(function()
				local filtered = self._input.Text:gsub("[^%d%.%-]", "")
				if self._input.Text ~= filtered then
					self._input.Text = filtered
				end
			end)
		)
	end

	if self._flag and self._window and self._window.RegisterConfigElement then
		self._window:RegisterConfigElement(self._flag, "TextBox", function()
			return self._text
		end, function(value)
			self:SetText(value)
		end)
	end

	return self
end

function TextBox:SetText(text: any)
	self._text = tostring(text or "")
	self._input.Text = self._text
end

function TextBox:GetText(): string
	return self._text
end

function TextBox:SetPlaceholder(placeholder: string)
	self._input.PlaceholderText = placeholder
end

function TextBox:Focus()
	self._input:CaptureFocus()
end

function TextBox:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	if self._flag and self._window and self._window.UnregisterConfigElement then
		self._window:UnregisterConfigElement(self._flag)
	end

	self._frame:Destroy()
end

return TextBox
