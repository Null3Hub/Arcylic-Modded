local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Library = require(ReplicatedStorage:WaitForChild("AcrylicUI"))

assert(type(Library) == "table", "AcrylicUI should require to a table")
assert(type(Library.CreateWindow) == "function", "CreateWindow should be available")
assert(type(Library.new) == "function", "new should be available")
assert(type(Library.AddIcons) == "function", "AddIcons should be available")
assert(type(Library.SetIconsType) == "function", "SetIconsType should be available")
assert(type(Library.GetInfo) == "function", "GetInfo should be available")

local info = Library.GetInfo()
assert(type(info) == "table", "GetInfo should return a table")
assert(info.Author == "Arcylic-Modded", "Author should stay stable")
