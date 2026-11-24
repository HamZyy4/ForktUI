local RunService = game:GetService("RunService")
--[[

    ForktUI showcase example
    
]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local HttpService = cloneref(game:GetService("HttpService"))

local ForktUI

do
	local ok, result = pcall(function()
		return require("./src/Init")
	end)

	if ok then
		ForktUI = result
	else
		if cloneref(game:GetService("RunService")):IsStudio() then
			ForktUI = require(cloneref(ReplicatedStorage:WaitForChild("ForktUI"):WaitForChild("Init")))
		else
			ForktUI =
				loadstring(game:HttpGet("https://raw.githubusercontent.com/HamZyy4/ForktUI/main/dist/main.lua"))()
		end
	end
end

--[[

ForktUI.Creator.AddIcons("solar", {
    ["CheckSquareBold"] = "rbxassetid://132438947521974",
    ["CursorSquareBold"] = "rbxassetid://120306472146156",
    ["FileTextBold"] = "rbxassetid://89294979831077",
    ["FolderWithFilesBold"] = "rbxassetid://74631950400584",
    ["HamburgerMenuBold"] = "rbxassetid://134384554225463",
    ["Home2Bold"] = "rbxassetid://92190299966310",
    ["InfoSquareBold"] = "rbxassetid://119096461016615",
    ["PasswordMinimalisticInputBold"] = "rbxassetid://109919668957167",
    ["SolarSquareTransferHorizontalBold"] = "rbxassetid://125444491429160",
})--]]

function createPopup()
	return ForktUI:Popup({
		Title = "Welcome to the ForktUI!",
		Icon = "bird",
		Content = "Hello!",
		Buttons = {
			{
				Title = "Hahaha",
				Icon = "bird",
				Variant = "Tertiary",
			},
			{
				Title = "Hahaha",
				Icon = "bird",
				Variant = "Tertiary",
			},
			{
				Title = "Hahaha",
				Icon = "bird",
				Variant = "Tertiary",
			},
		},
	})
end

-- */  Window  /* --
local Window = ForktUI:CreateWindow({
	Title = "ForktUI Showcase",
	Author = "sukitovone",
	Folder = "ForktUI-Showcase",
	Icon = "solar:folder-2-bold-duotone",
	--Theme = "Mellowsi",
	--IconSize = 22*2,
	NewElements = true,
	--Size = UDim2.fromOffset(700,700),

	HideSearchBar = false,

	OpenButton = {
		Title = "Open ForktUI", -- can be changed
		CornerRadius = UDim.new(1, 0), -- fully rounded
		StrokeThickness = 3, -- removing outline
		Enabled = true, -- enable or disable openbutton
		Draggable = true,
		OnlyMobile = false,
		Scale = 0.5,

		Color = ColorSequence.new( -- gradient
			Color3.fromHex("#30FF6A"),
			Color3.fromHex("#e7ff2f")
		),
	},
	Topbar = {
		Height = 44,
		ButtonsType = "Mac", -- Default or Mac
	},
})

--createPopup()

--Window:SetUIScale(.8)

-- */  Tags  /* --
do
	Window:Tag({
		Title = "v" .. ForktUI.Version,
		Icon = "github",
		Color = Color3.fromHex("#1c1c1c"),
		Border = true,
	})
end

-- */  Colors  /* --
local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Green = Color3.fromHex("#10C550")
local Grey = Color3.fromHex("#83889E")
local Blue = Color3.fromHex("#257AF7")
local Red = Color3.fromHex("#EF4F1D")

-- */ Other Functions /* --
local function parseJSON(luau_table, indent, level, visited)
	indent = indent or 2
	level = level or 0
	visited = visited or {}

	local currentIndent = string.rep(" ", level * indent)
	local nextIndent = string.rep(" ", (level + 1) * indent)

	if luau_table == nil then
		return "null"
	end

	local dataType = type(luau_table)

	if dataType == "table" then
		if visited[luau_table] then
			return '"[Circular Reference]"'
		end

		visited[luau_table] = true

		local isArray = true
		local maxIndex = 0

		for k, _ in pairs(luau_table) do
			if type(k) == "number" and k > maxIndex then
				maxIndex = k
			end
			if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
				isArray = false
				break
			end
		end

		local count = 0
		for _ in pairs(luau_table) do
			count = count + 1
		end
		if count ~= maxIndex and isArray then
			isArray = false
		end

		if count == 0 then
			return "{}"
		end

		if isArray then
			if count == 0 then
				return "[]"
			end

			local result = "[\n"

			for i = 1, maxIndex do
				result = result .. nextIndent .. parseJSON(luau_table[i], indent, level + 1, visited)
				if i < maxIndex then
					result = result .. ","
				end
				result = result .. "\n"
			end

			result = result .. currentIndent .. "]"
			return result
		else
			local result = "{\n"
			local first = true

			local keys = {}
			for k in pairs(luau_table) do
				table.insert(keys, k)
			end
			table.sort(keys, function(a, b)
				if type(a) == type(b) then
					return tostring(a) < tostring(b)
				else
					return type(a) < type(b)
				end
			end)

			for _, k in ipairs(keys) do
				local v = luau_table[k]
				if not first then
					result = result .. ",\n"
				else
					first = false
				end

				if type(k) == "string" then
					result = result .. nextIndent .. '"' .. k .. '": '
				else
					result = result .. nextIndent .. '"' .. tostring(k) .. '": '
				end

				result = result .. parseJSON(v, indent, level + 1, visited)
			end

			result = result .. "\n" .. currentIndent .. "}"
			return result
		end
	elseif dataType == "string" then
		local escaped = luau_table:gsub("\\", "\\\\")
		escaped = escaped:gsub('"', '\\"')
		escaped = escaped:gsub("\n", "\\n")
		escaped = escaped:gsub("\r", "\\r")
		escaped = escaped:gsub("\t", "\\t")

		return '"' .. escaped .. '"'
	elseif dataType == "number" then
		return tostring(luau_table)
	elseif dataType == "boolean" then
		return luau_table and "true" or "false"
	elseif dataType == "function" then
		return '"function"'
	else
		return '"' .. dataType .. '"'
	end
end

local function tableToClipboard(luau_table, indent)
	indent = indent or 4
	local jsonString = parseJSON(luau_table, indent)
	setclipboard(jsonString)
	return jsonString
end

-- */  About Tab  /* --
do
	local AboutTab = Window:Tab({
		Title = "About ForktUI",
		Desc = "Description Example",
		Icon = "solar:info-square-bold",
		IconColor = Grey,
		IconShape = "Square",
		Border = true,
	})

	local AboutSection = AboutTab:Section({
		Title = "About ForktUI",
	})

	AboutSection:Image({
		Image = "https://repository-images.githubusercontent.com/880118829/22c020eb-d1b1-4b34-ac4d-e33fd88db38d",
		AspectRatio = "16:9",
		Radius = 9,
	})

	AboutSection:Space({ Columns = 3 })

	AboutSection:Section({
		Title = "What is ForktUI?",
		TextSize = 24,
		FontWeight = Enum.FontWeight.SemiBold,
	})

	AboutSection:Space()

	AboutSection:Section({
		Title = "ForktUI is a modular interface library for Roblox experiences, maintained by sukitovone.\nIt provides a cohesive toolkit for windows, navigation, controls, notifications, dialogs, and themes.\nThe project is written in Luau, Roblox scripting language.",
		TextSize = 18,
		TextTransparency = 0.35,
		FontWeight = Enum.FontWeight.Medium,
	})

	AboutTab:Space({ Columns = 4 })

	-- Default buttons

	AboutTab:Button({
		Title = "Export ForktUI JSON (copy)",
		Color = Color3.fromHex("#a2ff30"),
		Justify = "Center",
		IconAlign = "Left",
		Icon = "", -- removing icon
		Callback = function()
			tableToClipboard(ForktUI)
			ForktUI:Notify({
				Title = "ForktUI JSON",
				Content = "Copied to Clipboard!",
			})
		end,
	})
	AboutTab:Space({ Columns = 1 })

	AboutTab:Button({
		Title = "Destroy Window",
		Color = Color3.fromHex("#ff4830"),
		Justify = "Center",
		Icon = "shredder",
		IconAlign = "Left",
		Callback = function()
			Window:Destroy()
		end,
	})
end

-- */  Elements Section  /* --
local ElementsSection = Window:Section({
	Title = "Elements",
})
local ConfigUsageSection = Window:Section({
	Title = "Config Usage",
})
local OtherSection = Window:Section({
	Title = "Other",
})

-- */  Overview Tab  /* --
do
	local OverviewTab = ElementsSection:Tab({
		Title = "Overview",
		Icon = "solar:home-2-bold",
		IconColor = Grey,
		IconShape = "Square",
		Border = true,
	})

	local OverviewSection1 = OverviewTab:Section({
		Title = "Group's Example",
	})

	local OverviewGroup1 = OverviewTab:Group({})

	OverviewGroup1:Button({
		Title = "Button 1",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 1")
		end,
	})
	OverviewGroup1:Space()
	OverviewGroup1:Button({
		Title = "Button 2",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 2")
		end,
	})

	OverviewTab:Space()

	local OverviewGroup2 = OverviewTab:Group({})

	OverviewGroup2:Button({
		Title = "Button 1",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 1")
		end,
	})
	OverviewGroup2:Space()
	OverviewGroup2:Toggle({
		Title = "Toggle 2",
		Callback = function(v)
			print("clicked toggle 2:", v)
		end,
	})
	OverviewGroup2:Space()
	OverviewGroup2:Colorpicker({
		Title = "Colorpicker 3",
		Default = Color3.fromHex("#30ff6a"),
		Callback = function(color)
			print(color)
		end,
	})

	OverviewTab:Space()

	local OverviewGroup3 = OverviewTab:Group({})

	local OverviewSection1 = OverviewGroup3:Section({
		Title = "Section 1",
		Desc = "Section exampleee",
		Box = true,
		BoxBorder = true,
		Opened = true,
	})
	OverviewSection1:Button({
		Title = "Button 1",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 1")
		end,
	})
	OverviewSection1:Space()
	OverviewSection1:Toggle({
		Title = "Toggle 2",
		Callback = function(v)
			print("clicked toggle 2:", v)
		end,
	})

	OverviewGroup3:Space()

	local OverviewSection2 = OverviewGroup3:Section({
		Title = "Section 2",
		Box = true,
		BoxBorder = true,
		Opened = true,
	})
	OverviewSection2:Button({
		Title = "Button 1",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 1")
		end,
	})
	OverviewSection2:Space()
	OverviewSection2:Button({
		Title = "Button 2",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 2")
		end,
	})

	--OverviewTab:Space()
end

-- */  Toggle Tab  /* --
do
	local ToggleTab = ElementsSection:Tab({
		Title = "Toggle",
		Icon = "solar:check-square-bold",
		IconColor = Green,
		IconShape = "Square",
		Border = true,
	})

	ToggleTab:Toggle({
		Title = "Toggle",
	})

	ToggleTab:Space()

	ToggleTab:Toggle({
		Title = "Toggle",
		Desc = "Toggle example",
	})

	ToggleTab:Space()

	local ToggleGroup1 = ToggleTab:Group()
	ToggleGroup1:Toggle({})
	ToggleGroup1:Space()
	ToggleGroup1:Toggle({})

	ToggleTab:Space()

	ToggleTab:Toggle({
		Title = "Checkbox",
		Type = "Checkbox",
	})

	ToggleTab:Space()

	ToggleTab:Toggle({
		Title = "Checkbox",
		Desc = "Checkbox example",
		Type = "Checkbox",
	})

	ToggleTab:Space()

	ToggleTab:Toggle({
		Title = "Toggle",
		Locked = true,
		LockedTitle = "This element is locked",
	})

	ToggleTab:Toggle({
		Title = "Toggle",
		Desc = "Toggle example",
		Locked = true,
		LockedTitle = "This element is locked",
	})
end

-- */  Button Tab  /* --
do
	local ButtonTab = ElementsSection:Tab({
		Title = "Button",
		Icon = "solar:cursor-square-bold",
		IconColor = Blue,
		IconShape = "Square",
		Border = true,
	})

	local HighlightButton
	HighlightButton = ButtonTab:Button({
		Title = "Highlight Button",
		Icon = "mouse",
		Callback = function()
			print("clicked highlight")
			HighlightButton:Highlight()
		end,
	})

	ButtonTab:Space()

	ButtonTab:Button({
		Title = "Blue Button",
		Color = Color3.fromHex("#305dff"),
		Icon = "",
		Callback = function() end,
	})

	ButtonTab:Space()

	ButtonTab:Button({
		Title = "Blue Button",
		Desc = "With description",
		Color = Color3.fromHex("#305dff"),
		Icon = "",
		Callback = function() end,
	})

	ButtonTab:Space()

	ButtonTab:Button({
		Title = "Notify Button",
		--Desc = "Button example",
		Callback = function()
			ForktUI:Notify({
				Title = "Hello",
				Content = "Welcome to the ForktUI Example!",
				Icon = "solar:bell-bold",
				Duration = 5,
				CanClose = false,
			})
		end,
	})

	ButtonTab:Button({
		Title = "Notify Button 2",
		--Desc = "Button example",
		Callback = function()
			ForktUI:Notify({
				Title = "Hello",
				Content = "Welcome to the ForktUI Example!",
				--Icon = "solar:bell-bold",
				Duration = 5,
				CanClose = false,
			})
		end,
	})

	ButtonTab:Space()

	ButtonTab:Button({
		Title = "Button",
		Locked = true,
		LockedTitle = "This element is locked",
	})

	ButtonTab:Button({
		Title = "Button",
		Desc = "Button example",
		Locked = true,
		LockedTitle = "This element is locked",
	})
end

-- */  Input Tab  /* --
do
	local InputTab = ElementsSection:Tab({
		Title = "Input",
		Icon = "solar:password-minimalistic-input-bold",
		IconColor = Purple,
		IconShape = "Square",
		Border = true,
	})

	InputTab:Input({
		Title = "Input",
		Icon = "mouse",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input Textarea",
		Type = "Textarea",
		Icon = "mouse",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input Textarea",
		Type = "Textarea",
		--Icon = "mouse",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input",
		Desc = "Input example",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input Textarea",
		Desc = "Input example",
		Type = "Textarea",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input",
		Locked = true,
		LockedTitle = "This element is locked",
	})

	InputTab:Input({
		Title = "Input",
		Desc = "Input example",
		Locked = true,
		LockedTitle = "This element is locked",
	})
end

-- */  Slider Tab  /* --
do
	local SliderTab = ElementsSection:Tab({
		Title = "Slider",
		Icon = "solar:square-transfer-horizontal-bold",
		IconColor = Green,
		IconShape = "Square",
		Border = true,
	})

	SliderTab:Section({
		Title = "Default Slider with Tooltip and without textbox",
		TextSize = 14,
	})

	SliderTab:Slider({
		Title = "Slider Example",
		Desc = "Hahahahaha hello",
		IsTooltip = true,
		IsTextbox = false,
		Width = 200,
		Step = 1,
		Value = {
			Min = 0,
			Max = 200,
			Default = 100,
		},
		Callback = function(value)
			print(value)
		end,
	})

	SliderTab:Space()

	SliderTab:Section({
		Title = "Slider without description",
		TextSize = 14,
	})

	SliderTab:Slider({
		Title = "Slider Example",
		Step = 1,
		Width = 200,
		Value = {
			Min = 0,
			Max = 200,
			Default = 100,
		},
		Callback = function(value)
			print(value)
		end,
	})

	SliderTab:Space()

	SliderTab:Section({
		Title = "Slider without titles",
		TextSize = 14,
	})

	SliderTab:Slider({
		IsTooltip = true,
		Step = 1,
		Value = {
			Min = 0,
			Max = 200,
			Default = 100,
		},
		Callback = function(value)
			print(value)
		end,
	})

	SliderTab:Space()

	SliderTab:Section({
		Title = "Slider with icons ('from' only)",
		TextSize = 14,
	})

	SliderTab:Slider({
		IsTooltip = true,
		Step = 1,
		Value = {
			Min = 0,
			Max = 200,
			Default = 100,
		},
		Icons = {
			From = "sfsymbols:sunMinFill",
			--To = "sfsymbols:sunMaxFill",
		},
		Callback = function(value)
			print(value)
		end,
	})

	SliderTab:Space()

	SliderTab:Section({
		Title = "Slider with icons (from & to)",
		TextSize = 14,
	})

	SliderTab:Slider({
		IsTooltip = true,
		Step = 1,
		Value = {
			Min = 0,
			Max = 100,
			Default = 50,
		},
		Icons = {
			From = "sfsymbols:sunMinFill",
			To = "sfsymbols:sunMaxFill",
		},
		Callback = function(value)
			print(value)
		end,
	})
end

-- */  Dropdown Tab  /* --
do
	local DropdownTab = ElementsSection:Tab({
		Title = "Dropdown",
		Icon = "solar:hamburger-menu-bold",
		IconColor = Yellow,
		IconShape = "Square",
		Border = true,
	})

	DropdownTab:Dropdown({
		Title = "Advanced Dropdown (example)",
		Values = {
			{
				Title = "New file",
				Desc = "Create a new file",
				Icon = "file-plus",
				Callback = function()
					print("Clicked 'New File'")
				end,
			},
			{
				Title = "Copy link",
				Desc = "Copy the file link",
				Icon = "copy",
				Callback = function()
					print("Clicked 'Copy link'")
				end,
			},
			{
				Title = "Edit file",
				Desc = "Allows you to edit the file",
				Icon = "file-pen",
				Callback = function()
					print("Clicked 'Edit file'")
				end,
			},
			{
				Type = "Divider",
			},
			{
				Title = "Delete file",
				Desc = "Permanently delete the file",
				Icon = "trash",
				Callback = function()
					print("Clicked 'Delete file'")
				end,
			},
		},
	})

	DropdownTab:Space()

	DropdownTab:Dropdown({
		Title = "Multi Dropdown",
		Values = {
			"Привет",
			"Hello",
			"Сәлем",
			"Bonjour",
		},
		Value = nil,
		AllowNone = true,
		Multi = true,
		Callback = function(selectedValue)
			print("Selected: " .. selectedValue)
		end,
	})

	DropdownTab:Space()

	DropdownTab:Dropdown({
		Title = "No Multi Dropdown (default",
		Values = {
			"Привет",
			"Hello",
			"Сәлем",
			"Bonjour",
		},
		Value = 1,
		--AllowNone = true,
		Callback = function(selectedValue)
			print("Selected: " .. selectedValue)
		end,
	})

	DropdownTab:Space()
end

-- */  Config Usage  /* --
do
	local ConfigElementsTab = ConfigUsageSection:Tab({
		Title = "Config Elements",
		Icon = "solar:file-text-bold",
		IconColor = Blue,
		IconShape = nil,
		Border = true,
	})

	-- Config flags must be unique. Controls remain visible in Studio even when
	-- the current runtime does not expose filesystem persistence functions.
	ConfigElementsTab:Colorpicker({
		Flag = "AccentColor",
		Title = "Accent color",
		Desc = "Stored as a hex color when config persistence is available.",
		Default = Color3.fromRGB(155, 163, 175),
		Transparency = 0,
		Callback = function(color)
			print("Accent color:", color)
		end,
	})

	ConfigElementsTab:Dropdown({
		Flag = "DisplayMode",
		Title = "Display mode",
		Values = { "Compact", "Comfortable", "Spacious" },
		Value = "Comfortable",
		Callback = function(value)
			print("Display mode:", value)
		end,
	})

	ConfigElementsTab:Input({
		Flag = "ProfileLabel",
		Title = "Profile label",
		Value = "Default profile",
		Placeholder = "Enter a label...",
		Callback = function(value)
			print("Profile label:", value)
		end,
	})

	ConfigElementsTab:Keybind({
		Flag = "WindowToggleKey",
		Title = "Window toggle key",
		Value = "RightShift",
		Callback = function(value)
			local keyCode = Enum.KeyCode[tostring(value)]
			if keyCode then
				Window:SetToggleKey(keyCode)
			end
		end,
	})

	ConfigElementsTab:Slider({
		Flag = "InterfaceScale",
		Title = "Interface scale",
		Step = 0.05,
		Value = { Min = 0.7, Max = 1.2, Default = 1 },
		Callback = function(value)
			Window:SetUIScale(value)
		end,
	})

	ConfigElementsTab:Toggle({
		Flag = "PanelBackgroundVisible",
		Title = "Panel background",
		Value = not Window.HidePanelBackground,
		Callback = function(enabled)
			Window:SetPanelBackground(enabled)
		end,
	})

	ConfigElementsTab:Toggle({
		Flag = "ExampleToggle",
		Title = "Example preference",
		Desc = "A second independently persisted toggle.",
		Value = false,
		Callback = function(enabled)
			print("Example preference:", enabled)
		end,
	})

	local ConfigTab = ConfigUsageSection:Tab({
		Title = "Config Manager",
		Icon = "solar:folder-with-files-bold",
		IconColor = Purple,
		Border = true,
	})

	local ConfigManager = Window.ConfigManager
	local HasConfigStorage = type(ConfigManager) == "table"
	local ConfigName = "default"
	local ConfigNameInput = ConfigTab:Input({
		Title = "Config name",
		Icon = "file-cog",
		Value = ConfigName,
		Placeholder = "Enter a config name...",
		Callback = function(value)
			local cleanName = tostring(value or ""):gsub("[^%w _%-]", ""):sub(1, 48)
			if cleanName ~= "" then
				ConfigName = cleanName
			end
		end,
	})

	if not HasConfigStorage then
		ConfigTab:Paragraph({
			Title = "Filesystem storage unavailable",
			Desc = "The config controls are displayed for reference, but this runtime does not expose the file APIs required to save or load local JSON files. Run in a compatible client environment or use a normal in-game DataStore workflow on the server.",
		})
	else
		local function getConfigs()
			local ok, configs = pcall(function()
				return ConfigManager:AllConfigs()
			end)
			return ok and type(configs) == "table" and configs or {}
		end

		local ConfigDropdown = ConfigTab:Dropdown({
			Title = "Saved configurations",
			Desc = "Select an existing local configuration.",
			Values = getConfigs(),
			AllowNone = true,
			Callback = function(value)
				if type(value) == "string" and value ~= "" then
					ConfigName = value
					ConfigNameInput:Set(value)
				end
			end,
		})

		local function refreshConfigs()
			ConfigDropdown:Refresh(getConfigs())
		end

		ConfigTab:Button({
			Title = "Save configuration",
			Icon = "save",
			Callback = function()
				local config = ConfigManager:Config(ConfigName)
				if type(config) ~= "table" then
					ForktUI:Notify({ Title = "Save failed", Content = "Could not create the selected configuration." })
					return
				end

				local saved, result = config:Save()
				ForktUI:Notify({
					Title = saved and "Configuration saved" or "Save failed",
					Content = saved and ("Saved '" .. ConfigName .. "'.") or tostring(result),
					Duration = 4,
				})
				refreshConfigs()
			end,
		})

		ConfigTab:Button({
			Title = "Load configuration",
			Icon = "folder-open",
			Variant = "Secondary",
			Callback = function()
				local config = ConfigManager:Config(ConfigName)
				if type(config) ~= "table" then
					ForktUI:Notify({ Title = "Load failed", Content = "Could not create the selected configuration." })
					return
				end

				local loaded, result = config:Load()
				ForktUI:Notify({
					Title = loaded and "Configuration loaded" or "Load failed",
					Content = loaded and ("Loaded '" .. ConfigName .. "'.") or tostring(result),
					Duration = 4,
				})
			end,
		})

		ConfigTab:Button({
			Title = "Delete configuration",
			Icon = "trash-2",
			Variant = "Tertiary",
			Callback = function()
				local deleted, result = ConfigManager:DeleteConfig(ConfigName)
				ForktUI:Notify({
					Title = deleted and "Configuration deleted" or "Delete failed",
					Content = deleted and ("Deleted '" .. ConfigName .. "'.") or tostring(result),
					Duration = 4,
				})
				refreshConfigs()
			end,
		})

		ConfigTab:Button({
			Title = "View auto-load configurations",
			Icon = "list-checks",
			Variant = "Tertiary",
			Callback = function()
				local encoded = HttpService:JSONEncode(ConfigManager:GetAutoLoadConfigs())
				ForktUI:Notify({ Title = "Auto-load configurations", Content = encoded, Duration = 6 })
			end,
		})
	end
end

-- */  Community  /* --
do
	local CommunityTab = OtherSection:Tab({
		Title = "Community",
		Icon = "users-round",
		Border = true,
	})

	CommunityTab:Paragraph({
		Title = "ForktUI resources",
		Desc = "Find the source code, implementation examples, and API documentation using the links below. A replacement community invite has not been configured in this example yet, so no legacy invite is displayed.",
	})

	local function copyOrShow(label, value)
		local clipboard = setclipboard or toclipboard
		if type(clipboard) == "function" then
			local ok = pcall(clipboard, value)
			if ok then
				ForktUI:Notify({ Title = "Copied", Content = label .. " copied to clipboard." })
				return
			end
		end
		ForktUI:Notify({ Title = label, Content = value, Duration = 7 })
	end

	CommunityTab:Button({
		Title = "Copy GitHub repository",
		Icon = "github",
		Callback = function()
			copyOrShow("Repository URL", "https://github.com/HamZyy4/ForktUI")
		end,
	})

	CommunityTab:Button({
		Title = "Copy documentation URL",
		Icon = "book-open",
		Variant = "Secondary",
		Callback = function()
			copyOrShow("Documentation URL", "https://hamzyy4.github.io/ForktUI-Docs/")
		end,
	})
end

local Tabs = {
	ExampleTab = Window:Tab({
		Title = "Example Tab",
		Icon = "bird",
	}),
}

local dropdownA

local LargeListA = {
	"All",
	"Item A2",
	"Item A3",
	"Item A4",
	"Item A5",
	"Item A6",
	"Item A7",
	"Item A8",
	"Item A9",
	"Item A10",
	"Item A11",
	"Item A12",
	"Item A13",
	"Item A14",
	"Item A15",
	"Item A16",
	"Item A17",
	"Item A18",
	"Item A19",
	"Item A20",
	"Item A21",
	"Item A22",
	"Item A23",
	"Item A24",
	"Item A25",
	"Item A26",
	"Item A27",
	"Item A28",
	"Item A29",
	"Item A30",
	"Item A31",
	"Item A32",
	"Item A33",
	"Item A34",
	"Item A35",
	"Item A36",
	"Item A37",
	"Item A38",
	"Item A39",
	"Item A40",
	"Item A41",
	"Item A42",
	"Item A43",
	"Item A44",
	"Item A45",
	"Item A46",
	"Item A47",
	"Item A48",
	"Item A49",
	"Item A50",
	"Item A51",
	"Item A52",
	"Item A53",
	"Item A54",
	"Item A55",
	"Item A56",
	"Item A57",
	"Item A58",
	"Item A59",
	"Item A60",
	"Item A61",
	"Item A62",
	"Item A63",
	"Item A64",
	"Item A65",
	"Item A66",
	"Item A67",
	"Item A68",
	"Item A69",
	"Item A70",
	"Item A71",
	"Item A72",
	"Item A73",
	"Item A74",
	"Item A75",
	"Item A76",
	"Item A77",
	"Item A78",
	"Item A79",
	"Item A80",
	"Item A81",
	"Item A82",
	"Item A83",
	"Item A84",
	"Item A85",
	"Item A86",
	"Item A87",
	"Item A88",
	"Item A89",
	"Item A90",
	"Item A91",
	"Item A92",
	"Item A93",
	"Item A94",
	"Item A95",
	"Item A96",
	"Item A97",
	"Item A98",
	"Item A99",
	"Item A100",
}

local LargeListB = {
	"Data B1",
	"Data B2",
	"Data B3",
	"Data B4",
	"Data B5",
	"Data B6",
	"Data B7",
	"Data B8",
	"Data B9",
	"Data B10",
}

Tabs.ExampleTab:Dropdown({
	Title = "Main Category",
	Values = { "All", "Other Option" },
	Value = "All",
	Callback = function(option)
		if dropdownA then
			task.spawn(function()
				if option == "All" then
					dropdownA:Refresh(LargeListA)
				else
					dropdownA:Refresh(LargeListB)
				end

				dropdownA:Select({ "All" })
			end)
		end
	end,
})

dropdownA = Tabs.ExampleTab:Dropdown({
	Title = "Target",
	Values = LargeListA,
	Multi = true,
	Value = { "All" },
	Callback = function(option) end,
})
