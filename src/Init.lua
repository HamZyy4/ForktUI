local ForktUI = {
	Window = nil,
	Theme = nil,
	Creator = require("./modules/Creator"),
	LocalizationModule = require("./modules/Localization"),
	NotificationModule = require("./components/Notification"),
	Themes = nil,
	Transparent = false,

	TransparencyValue = 0.15,

	UIScale = 1,

	ConfigManager = nil,
	Version = "0.0.0",

	Services = require("./utils/services/Init"),

	OnThemeChangeFunction = nil,

	cloneref = nil,
	UIScaleObj = nil,

	CreateWindow = nil,

	CurrentInput = nil,
}

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

ForktUI.cloneref = cloneref

local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

function ForktUI.GenerateGUID()
	return HttpService:GenerateGUID(false)
end

local CurInput = ForktUI.GenerateGUID()

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	--[[if GameProcessed then
		return
	end]]

	task.defer(function()
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			if ForktUI.CurrentInput and ForktUI.CurrentInput ~= CurInput then
				return
			end

			ForktUI.CurrentInput = CurInput
			--print(CurInput)
			--ForktUI.InputStartedOnUI = false
		end
	end)
end)
UserInputService.InputEnded:Connect(function(Input, GameProcessed)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		if ForktUI.CurrentInput and ForktUI.CurrentInput ~= CurInput then
			return
		end

		ForktUI.CurrentInput = nil
	end
end)

local LocalPlayer = Players.LocalPlayer or nil

local Package = HttpService:JSONDecode(require("../build/package"))
if Package then
	ForktUI.Version = Package.version
end

local KeySystem = require("./components/KeySystem")

local Creator = ForktUI.Creator

local New = Creator.New

--local Tween = Creator.Tween
--local ServicesModule = ForktUI.Services

local Acrylic = require("./utils/Acrylic/Init")

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local GUIParent = gethui and gethui() or (CoreGui or LocalPlayer:WaitForChild("PlayerGui"))

local UIScaleObj = New("UIScale", {
	Scale = ForktUI.UIScale,
})

ForktUI.UIScaleObj = UIScaleObj

ForktUI.ScreenGui = New("ScreenGui", {
	Name = "ForktUI",
	Parent = GUIParent,
	IgnoreGuiInset = true,
	ScreenInsets = "None",
	DisplayOrder = -99999,
}, {

	New("Folder", {
		Name = "Window",
	}),
	-- New("Folder", {
	--     Name = "Notifications"
	-- }),
	-- New("Folder", {
	--     Name = "Dropdowns"
	-- }),
	New("Folder", {
		Name = "KeySystem",
	}),
	New("Folder", {
		Name = "Popups",
	}),
	New("Folder", {
		Name = "ToolTips",
	}),
})

ForktUI.NotificationGui = New("ScreenGui", {
	Name = "ForktUI/Notifications",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
ForktUI.DropdownGui = New("ScreenGui", {
	Name = "ForktUI/Dropdowns",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
ForktUI.TooltipGui = New("ScreenGui", {
	Name = "ForktUI/Tooltips",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
ProtectGui(ForktUI.ScreenGui)
ProtectGui(ForktUI.NotificationGui)
ProtectGui(ForktUI.DropdownGui)
ProtectGui(ForktUI.TooltipGui)

Creator.Init(ForktUI)

function ForktUI:SetParent(parent)
	if ForktUI.ScreenGui then
		ForktUI.ScreenGui.Parent = parent
	end
	if ForktUI.NotificationGui then
		ForktUI.NotificationGui.Parent = parent
	end
	if ForktUI.DropdownGui then
		ForktUI.DropdownGui.Parent = parent
	end
	if ForktUI.TooltipGui then
		ForktUI.TooltipGui.Parent = parent
	end
end
ForktUI.TransparencyValue = math.clamp(ForktUI.TransparencyValue, 0, 1)

local Holder = ForktUI.NotificationModule.Init(ForktUI.NotificationGui)

function ForktUI:Notify(Config)
	Config.Holder = Holder.Frame
	Config.Window = ForktUI.Window
	--Config.ForktUI = ForktUI
	return ForktUI.NotificationModule.New(Config)
end

function ForktUI:SetNotificationLower(Val)
	Holder.SetLower(Val)
end

function ForktUI:SetFont(FontId)
	Creator.UpdateFont(FontId)
end

function ForktUI:OnThemeChange(func)
	ForktUI.OnThemeChangeFunction = func
end

function ForktUI:AddTheme(LTheme)
	ForktUI.Themes[LTheme.Name] = LTheme
	return LTheme
end

function ForktUI:SetTheme(Value)
	if ForktUI.Themes[Value] then
		ForktUI.Theme = ForktUI.Themes[Value]
		Creator.SetTheme(ForktUI.Themes[Value])

		if ForktUI.OnThemeChangeFunction then
			ForktUI.OnThemeChangeFunction(Value)
		end

		return ForktUI.Themes[Value]
	end
	return nil
end

function ForktUI:GetThemes()
	return ForktUI.Themes
end
function ForktUI:GetCurrentTheme()
	local theme = self.Theme or ForktUI.Theme
	return theme and theme.Name or nil
end
function ForktUI:GetTransparency()
	return ForktUI.Transparent or false
end
function ForktUI:GetWindowSize()
	local window = self and self.Window or ForktUI.Window
	local main = window and window.UIElements and window.UIElements.Main
	return main and main.Size or nil
end
function ForktUI:Localization(LocalizationConfig)
	return ForktUI.LocalizationModule:New(LocalizationConfig, Creator)
end

function ForktUI:SetLanguage(Value)
	if Creator.Localization then
		return Creator.SetLanguage(Value)
	end
	return false
end

function ForktUI:ToggleAcrylic(Value)
	if ForktUI.Window and ForktUI.Window.AcrylicPaint and ForktUI.Window.AcrylicPaint.Model then
		ForktUI.Window.Acrylic = Value
		ForktUI.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
		if Value then
			Acrylic.Enable()
		else
			Acrylic.Disable()
		end
	end
end

function ForktUI:Gradient(stops, props)
	if type(stops) ~= "table" then
		error("Gradient: stops must be a table", 2)
	end

	local byPosition = {}
	for rawPosition, stop in pairs(stops) do
		local percent = tonumber(rawPosition)
		if percent and type(stop) == "table" then
			local color = stop.Color
			if type(color) == "string" then
				local hex = color:gsub("^#", "")
				if #hex == 6 and hex:match("^%x+$") then
					color = Color3.fromHex(hex)
				end
			end

			if typeof(color) == "Color3" then
				local position = math.clamp(percent / 100, 0, 1)
				local transparency = tonumber(stop.Transparency) or 0
				byPosition[position] = {
					Color = color,
					Transparency = math.clamp(transparency, 0, 1),
				}
			end
		end
	end

	local stopsList = {}
	for position, stop in pairs(byPosition) do
		table.insert(stopsList, {
			Position = position,
			Color = stop.Color,
			Transparency = stop.Transparency,
		})
	end
	table.sort(stopsList, function(a, b)
		return a.Position < b.Position
	end)

	if #stopsList == 0 then
		error("Gradient: at least one valid Color3 stop is required", 2)
	end

	local first = stopsList[1]
	local last = stopsList[#stopsList]
	if #stopsList == 1 then
		stopsList = {
			{ Position = 0, Color = first.Color, Transparency = first.Transparency },
			{ Position = 1, Color = first.Color, Transparency = first.Transparency },
		}
	else
		if first.Position > 0 then
			table.insert(stopsList, 1, {
				Position = 0,
				Color = first.Color,
				Transparency = first.Transparency,
			})
		end
		if last.Position < 1 then
			table.insert(stopsList, {
				Position = 1,
				Color = last.Color,
				Transparency = last.Transparency,
			})
		end
	end

	local colorSequence = {}
	local transparencySequence = {}
	for _, stop in ipairs(stopsList) do
		table.insert(colorSequence, ColorSequenceKeypoint.new(stop.Position, stop.Color))
		table.insert(transparencySequence, NumberSequenceKeypoint.new(stop.Position, stop.Transparency))
	end

	local gradientData = {
		Color = ColorSequence.new(colorSequence),
		Transparency = NumberSequence.new(transparencySequence),
	}

	if type(props) == "table" then
		for key, value in pairs(props) do
			gradientData[key] = value
		end
	end

	return gradientData
end

function ForktUI:Popup(PopupConfig)
	if type(PopupConfig) ~= "table" then
		error("Popup: configuration must be a table", 2)
	end

	PopupConfig.ForktUI = self or ForktUI
	return require("./components/popup/Init").new(PopupConfig, ForktUI.ScreenGui.Popups)
end

ForktUI.Themes = require("./themes/Init")(ForktUI, Creator)

Creator.Themes = ForktUI.Themes

ForktUI:SetTheme("Dark")
ForktUI:SetLanguage(Creator.Language)

function ForktUI:CreateWindow(Config)
	if type(Config) ~= "table" then
		error("CreateWindow: Config must be a table", 2)
	end

	if ForktUI.Window then
		warn("ForktUI: only one window can be created per library instance")
		return nil
	end

	local CreateWindow = require("./components/window/Init")

	local function ensureFolder(path)
		if type(path) ~= "string" or path == "" or type(isfolder) ~= "function" or type(makefolder) ~= "function" then
			return
		end

		local ok, exists = pcall(isfolder, path)
		if ok and not exists then
			pcall(makefolder, path)
		end
	end

	if not RunService:IsStudio() and type(writefile) == "function" then
		ensureFolder("ForktUI")
		ensureFolder(Config.Folder or Config.Title)
		if Config.KeySystem then
			ensureFolder(Config.Folder or "Temp")
		end
	end

	Config.ForktUI = ForktUI
	Config.Window = ForktUI.Window
	Config.Parent = ForktUI.ScreenGui.Window

	if Config.KeySystem ~= nil and type(Config.KeySystem) ~= "table" then
		error("CreateWindow: KeySystem must be a table", 2)
	end
	if type(Config.KeySystem) == "table" then
		if Config.KeySystem.API ~= nil and type(Config.KeySystem.API) ~= "table" then
			error("CreateWindow: KeySystem.API must be a table", 2)
		end
		if Config.KeySystem.KeyValidator ~= nil and type(Config.KeySystem.KeyValidator) ~= "function" then
			error("CreateWindow: KeySystem.KeyValidator must be a function", 2)
		end
		if Config.KeySystem.Key ~= nil and type(Config.KeySystem.Key) ~= "string" and type(Config.KeySystem.Key) ~= "table" then
			error("CreateWindow: KeySystem.Key must be a string or an array of strings", 2)
		end
		if Config.KeySystem.SaveKey ~= nil and type(Config.KeySystem.SaveKey) ~= "boolean" then
			error("CreateWindow: KeySystem.SaveKey must be a boolean", 2)
		end
	end

	local CanLoadWindow = true
	local KeySystemCancelled = false

	local Theme = ForktUI.Themes[Config.Theme or "Dark"] or ForktUI.Themes.Dark
	if not Theme then
		error("CreateWindow: no valid theme is available", 2)
	end
	if Config.Theme and not ForktUI.Themes[Config.Theme] then
		warn("ForktUI: unknown theme '" .. tostring(Config.Theme) .. "'; falling back to Dark")
	end

	Creator.SetTheme(Theme)

	local Filename = Players.LocalPlayer and Players.LocalPlayer.UserId or "local-user"
	if type(gethwid) == "function" then
		local hwidOk, hwidValue = pcall(gethwid)
		if hwidOk and hwidValue ~= nil then Filename = hwidValue end
	end
	Filename = tostring(Filename):gsub("[^%w_%-]", "_")

	if Config.KeySystem then
		CanLoadWindow = false

		local function loadKeysystem()
			KeySystem.new(Config, Filename, function(accepted)
				CanLoadWindow = accepted == true
				KeySystemCancelled = accepted ~= true
			end)
		end

		local keyPath = tostring(Config.Folder or "Temp") .. "/" .. tostring(Filename) .. ".key"
		local savedKey = nil
		if type(isfile) == "function" and type(readfile) == "function" then
			local fileCheckOk, fileExists = pcall(isfile, keyPath)
			if fileCheckOk and fileExists then
				local readOk, fileContents = pcall(readfile, keyPath)
				if readOk and type(fileContents) == "string" then savedKey = fileContents end
			end
		end
		local hasSavedKey = savedKey ~= nil

		if Config.KeySystem.KeyValidator then
			if Config.KeySystem.SaveKey and hasSavedKey then
				local validationSuccess, isValid = pcall(Config.KeySystem.KeyValidator, savedKey)
				if not validationSuccess then
					warn("ForktUI: saved key validator failed:", isValid)
					isValid = false
				end

				if isValid == true then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		elseif type(Config.KeySystem.API) ~= "table" or #Config.KeySystem.API == 0 then
			if Config.KeySystem.SaveKey and hasSavedKey then
				local isKey = false
				if type(Config.KeySystem.Key) == "table" then
					for _, candidate in pairs(Config.KeySystem.Key) do
						if tostring(candidate) == tostring(savedKey) then isKey = true; break end
					end
				else
					isKey = Config.KeySystem.Key ~= nil and tostring(Config.KeySystem.Key) == tostring(savedKey)
				end

				if isKey then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		else
			if hasSavedKey then
				local isSuccess = false

				for _, i in ipairs(type(Config.KeySystem.API) == "table" and Config.KeySystem.API or {}) do
					if type(i) == "table" and type(i.Type) == "string" then
						local serviceData = ForktUI.Services[i.Type]
						if serviceData and type(serviceData.New) == "function" then
							local args = {}
							local serviceArgs = type(serviceData.Args) == "table" and serviceData.Args or {}
							for _, argName in ipairs(serviceArgs) do
								table.insert(args, i[argName])
							end
							local serviceOk, service = pcall(function() return serviceData.New(table.unpack(args)) end)
							if serviceOk and type(service) == "table" and type(service.Verify) == "function" then
								local verifyOk, success = pcall(service.Verify, savedKey)
								if verifyOk and success then isSuccess = true; break end
							end
						end
					end
				end

				CanLoadWindow = isSuccess
				if not isSuccess then
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		end

		repeat
			task.wait()
		until CanLoadWindow or KeySystemCancelled
		if KeySystemCancelled then
			return nil
		end
	end

	local Window = CreateWindow(Config)

	ForktUI.Transparent = Config.Transparent
	ForktUI.Window = Window

	if Config.Acrylic then
		Acrylic.init()
	end

	-- function Window:ToggleTransparency(Value)
	--     ForktUI.Transparent = Value
	--     ForktUI.Window.Transparent = Value

	--     Window.UIElements.Main.Background.BackgroundTransparency = Value and ForktUI.TransparencyValue or 0
	--     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and ForktUI.TransparencyValue or 0
	--     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
	--         NumberSequenceKeypoint.new(0, 1),
	--         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
	--     }
	-- end

	return Window
end

return ForktUI
