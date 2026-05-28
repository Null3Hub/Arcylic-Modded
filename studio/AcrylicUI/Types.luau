--[[
    AcrylicUI - Type Definitions
    Version: 2.0.0
    Author: AcrylicUI Team

    Type definitions for strict type checking across the library.
]]

export type Color3 = Color3
export type UDim2 = UDim2
export type Instance = Instance

export type ThemeColors = {
	Background: Color3,
	Secondary: Color3,
	Border: Color3,
	Text: Color3,
	TextDark: Color3,
	TextFade: Color3,
	Accent: Color3,
	Toggle: {
		Enabled: Color3,
		Disabled: Color3,
		Circle: Color3,
	},
	Notification: {
		Background: Color3,
		Border: Color3,
		Timer: Color3,
	},
	CloseHover: Color3,
	ResizeHandle: Color3,
	Scrollbar: Color3,
}

export type WindowConfig = {
	Title: string?,
	Size: { Width: number, Height: number }?,
	Position: UDim2?,
	Theme: ThemeColors?,
	ToggleKey: Enum.KeyCode?,
	ConfigFolder: string?,
	ClampToViewport: boolean?,
}

export type ButtonConfig = {
	Name: string?,
	Description: string?,
	Desc: string?,
	Callback: (() -> ())?,
}

export type ToggleConfig = {
	Name: string?,
	Description: string?,
	Desc: string?,
	Default: boolean?,
	Flag: string?,
	Callback: ((enabled: boolean) -> ())?,
}

export type SliderConfig = {
	Name: string?,
	Description: string?,
	Desc: string?,
	Min: number?,
	Max: number?,
	Default: number?,
	Increment: number?,
	Flag: string?,
	Callback: ((value: number) -> ())?,
}

export type DropdownConfig = {
	Name: string?,
	Description: string?,
	Desc: string?,
	Options: { string }?,
	Default: string | { string }?,
	MultiSelect: boolean?,
	Flag: string?,
	Callback: ((selected: string | { string }) -> ())?,
}

export type KeybindConfig = {
	Name: string?,
	Description: string?,
	Desc: string?,
	Default: Enum.KeyCode?,
	Flag: string?,
	Callback: (() -> ())?,
}

export type ColorPickerConfig = {
	Name: string?,
	Description: string?,
	Desc: string?,
	Default: Color3?,
	Flag: string?,
	Callback: ((color: Color3) -> ())?,
}

export type TextBoxConfig = {
	Name: string?,
	Description: string?,
	Desc: string?,
	Default: string?,
	Placeholder: string?,
	ClearOnFocus: boolean?,
	NumbersOnly: boolean?,
	Flag: string?,
	Callback: ((text: string, enterPressed: boolean) -> ())?,
}

export type ParagraphConfig = {
	Title: string?,
	Content: string?,
}

export type NotificationConfig = {
	Title: string?,
	Description: string?,
	Duration: number?,
	Icon: string?,
}

export type Connection = RBXScriptConnection

return nil
