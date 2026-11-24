local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))

local Creator = require("../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local Element = {
	UICorner = 6,
	UIPadding = 8,
}

local CreateLabel = require("../components/ui/Label").New

function Element:New(Config)
	local function NormalizeKeyCode(value)
		if typeof(value) == "EnumItem" then
			return value.Name
		elseif type(value) == "string" then
			if value == "MouseLeft" or value == "MouseLeftButton" then
				return "MouseButton1"
			elseif value == "MouseRight" or value == "MouseRightButton" then
				return "MouseButton2"
			end
			return value
		else
			return "F"
		end
	end

	local initialValue = NormalizeKeyCode(Config.Value)
	local function IsSupportedKey(value)
		return Enum.KeyCode[value] ~= nil or value == "MouseButton1" or value == "MouseButton2"
	end
	if not IsSupportedKey(initialValue) then
		warn("ForktUI Keybind: unsupported initial key '" .. tostring(initialValue) .. "'; using F")
		initialValue = "F"
	end

	local Keybind = {
		__type = "Keybind",
		Title = Config.Title or "Keybind",
		Desc = Config.Desc or nil,
		Locked = Config.Locked or false,
		LockedTitle = Config.LockedTitle,
		Value = initialValue,
		Callback = Config.Callback or function() end,
		CanChange = Config.CanChange ~= false,
		Blacklist = type(Config.Blacklist) == "table" and Config.Blacklist or {},
		Picking = false,
		UIElements = {},
	}

	local FilteredBlacklist = {}
	local BlacklistedMouse = {}

	for _, Item in next, Keybind.Blacklist do
		local normalized = NormalizeKeyCode(Item)
		local keyCode = Enum.KeyCode[normalized]
		if keyCode then
			table.insert(FilteredBlacklist, keyCode)
		elseif normalized == "MouseButton1" or normalized == "MouseLeft" or normalized == "MouseLeftButton" then
			table.insert(BlacklistedMouse, "MouseButton1")
		elseif normalized == "MouseButton2" or normalized == "MouseRight" or normalized == "MouseRightButton" then
			table.insert(BlacklistedMouse, "MouseButton2")
		else
			warn("ForktUI Keybind: ignored invalid blacklist entry '" .. tostring(Item) .. "'")
		end
	end
	table.insert(FilteredBlacklist, Enum.KeyCode.Escape)


	local CanCallback = true

	Keybind.KeybindFrame = require("../components/window/Element")({
		Title = Keybind.Title,
		Desc = Keybind.Desc,
		Parent = Config.Parent,
		TextOffset = 85,
		Hover = Keybind.CanChange,
		Tab = Config.Tab,
		Index = Config.Index,
		Window = Config.Window,
		ElementTable = Keybind,
		ParentConfig = Config,
		Tags = Config.Tags,
	})

	Keybind.UIElements.Keybind = CreateLabel(
		Keybind.Value,
		nil,
		Keybind.KeybindFrame.UIElements.Main,
		nil,
		Config.Window.NewElements and 12 or 10
	)

	Keybind.UIElements.Keybind.Size =
		UDim2.new(0, 12 + 12 + Keybind.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X, 0, 42)
	Keybind.UIElements.Keybind.AnchorPoint = Vector2.new(1, 0.5)
	Keybind.UIElements.Keybind.Position = UDim2.new(1, 0, 0.5, 0)
	Keybind.UIElements.Keybind.Interactable = false

	New("UIScale", {
		Parent = Keybind.UIElements.Keybind,
		Scale = 0.85,
	})

	Creator.AddSignal(
		Keybind.UIElements.Keybind.Frame.Frame.TextLabel:GetPropertyChangedSignal("TextBounds"),
		function()
			Keybind.UIElements.Keybind.Size =
				UDim2.new(0, 12 + 12 + Keybind.UIElements.Keybind.Frame.Frame.TextLabel.TextBounds.X, 0, 42)
		end
	)

	function Keybind:Lock()
		Keybind.Locked = true
		CanCallback = false
		return Keybind.KeybindFrame:Lock(Keybind.LockedTitle)
	end
	function Keybind:Unlock()
		Keybind.Locked = false
		CanCallback = true
		return Keybind.KeybindFrame:Unlock()
	end

	function Keybind:Set(v)
		local normalizedValue = NormalizeKeyCode(v)
		if not IsSupportedKey(normalizedValue) then
			warn("ForktUI Keybind: unsupported key '" .. tostring(normalizedValue) .. "'")
			return false
		end
		Keybind.Value = normalizedValue
		Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = normalizedValue
		return true
	end

	if Keybind.Locked then
		Keybind:Lock()
	end

	local EndedEvent

	Creator.AddSignal(Keybind.KeybindFrame.UIElements.Main.MouseButton1Click, function()
		if CanCallback then
			if Keybind.CanChange then
				Keybind.Picking = true
				Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = "..."

				--task.wait(0.2)

				local Event
				Event = UserInputService.InputBegan:Connect(function(Input)
					local Key

					if Input.UserInputType == Enum.UserInputType.Keyboard then
						if Input.KeyCode == Enum.KeyCode.Escape then
							Keybind.Picking = false
							Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = Keybind.Value
							Event:Disconnect()
							if EndedEvent then
								EndedEvent:Disconnect()
								EndedEvent = nil
							end
							return
						elseif table.find(FilteredBlacklist, Input.KeyCode) then
							return
						else
							Key = Input.KeyCode.Name
						end
					elseif Input.UserInputType == Enum.UserInputType.MouseButton1
						and not table.find(BlacklistedMouse, "MouseButton1") then
						Key = "MouseButton1"
					elseif Input.UserInputType == Enum.UserInputType.MouseButton2
						and not table.find(BlacklistedMouse, "MouseButton2") then
						Key = "MouseButton2"
					end

					if EndedEvent then
						EndedEvent:Disconnect()
					end

					EndedEvent = UserInputService.InputEnded:Connect(function(Input)
						if
							Key
							and (
								Input.KeyCode.Name == Key
								or Key == "MouseButton1" and Input.UserInputType == Enum.UserInputType.MouseButton1
								or Key == "MouseButton2" and Input.UserInputType == Enum.UserInputType.MouseButton2
							)
						then
							Keybind.Picking = false

							Keybind.UIElements.Keybind.Frame.Frame.TextLabel.Text = Key
							Keybind.Value = Key

							Event:Disconnect()
							EndedEvent:Disconnect()
						end
					end)
				end)
			end
		end
	end)

	Creator.AddSignal(UserInputService.InputBegan, function(input, gpe)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if not CanCallback then
			return
		end
		if Keybind.Picking then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode.Name == Keybind.Value then
				Creator.SafeCallback(Keybind.Callback, input.KeyCode.Name)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and Keybind.Value == "MouseButton1" then
			Creator.SafeCallback(Keybind.Callback, "MouseButton1")
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and Keybind.Value == "MouseButton2" then
			Creator.SafeCallback(Keybind.Callback, "MouseButton2")
		end
	end)

	return Keybind.__type, Keybind
end

return Element
