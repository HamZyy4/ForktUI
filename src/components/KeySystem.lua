local KeySystem = {}

local Creator = require("../modules/Creator")
local New = Creator.New
local CreateButton = require("./ui/Button").New
local CreateInput = require("./ui/Input").New

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function notify(ForktUI, title, content, icon)
	if ForktUI and type(ForktUI.Notify) == "function" then
		pcall(function()
			ForktUI:Notify({ Title = title, Content = tostring(content or ""), Icon = icon or "key-round" })
		end)
	end
end

local function copyText(value)
	local candidates = { setclipboard, toclipboard, set_clipboard }
	for _, copyFn in pairs(candidates) do
		if type(copyFn) == "function" then
			local ok, result = pcall(copyFn, tostring(value))
			if ok and result ~= false then return true end
		end
	end
	return false
end

local function ensureFolder(path)
	if type(path) ~= "string" or path == "" then return false end
	if type(makefolder) ~= "function" then return false end
	if type(isfolder) == "function" then
		local ok, exists = pcall(isfolder, path)
		if ok and exists then return true end
	end
	local ok = pcall(makefolder, path)
	if ok then return true end
	return type(isfolder) == "function" and select(2, pcall(isfolder, path)) == true
end

local function saveKey(config, filename, value)
	local keyConfig = type(config.KeySystem) == "table" and config.KeySystem or {}
	if keyConfig.SaveKey ~= true then return true end
	if type(writefile) ~= "function" then return false end

	local folder = tostring(config.Folder or "Temp")
	local path = folder .. "/" .. tostring(filename) .. ".key"
	if folder:find("/", 1, true) then
		local current = ""
		for part in folder:gmatch("[^/]+") do
			current = current == "" and part or (current .. "/" .. part)
			ensureFolder(current)
		end
	else
		ensureFolder(folder)
	end

	local ok = pcall(writefile, path, tostring(value))
	return ok
end

local function makeLabel(text, size, transparency, weight, colorTag)
	return New("TextLabel", {
		Text = text,
		TextSize = size,
		TextTransparency = transparency or 0,
		FontFace = Font.new(Creator.Font, weight or Enum.FontWeight.Regular),
		ThemeTag = { TextColor3 = colorTag or "Text" },
		BackgroundTransparency = 1,
		AutomaticSize = "Y",
		Size = UDim2.new(1, 0, 0, 0),
		TextWrapped = true,
		TextXAlignment = "Left",
	})
end

function KeySystem.new(Config, Filename, callback)
	local KeyConfig = type(Config.KeySystem) == "table" and Config.KeySystem or {}
	local ForktUI = Config.ForktUI
	local DialogModule = require("./window/Dialog")
	local Dialog = DialogModule.Create(true, "Popup", Config.Window, ForktUI, ForktUI.ScreenGui.KeySystem)
	local Main = Dialog.UIElements.Main

	Main.AutomaticSize = "Y"
	Main.Size = UDim2.new(0, 440, 0, 0)

	local finished = false
	local submitting = false
	local enteredKey = ""
	local services = {}
	local serviceLastError = nil

	local function resolve(accepted)
		if finished then return end
		finished = true
		pcall(function() Dialog:Close() end)
		if type(callback) == "function" then
			task.spawn(function()
				task.wait(0.12)
					pcall(callback, accepted == true)
			end)
		end
	end

	local Content = New("Frame", {
		Name = "ForktUIAccessPanel",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = "Y",
		BackgroundTransparency = 1,
		Parent = Main,
	}, {
		New("UIListLayout", {
			FillDirection = "Vertical",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 12),
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 22),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 22),
			PaddingRight = UDim.new(0, 22),
		}),
	})

	local thumbnail = type(KeyConfig.Thumbnail) == "table" and KeyConfig.Thumbnail or nil
	if thumbnail and thumbnail.Image then
		local image = thumbnail.Image
		if type(image) == "number" then image = "rbxassetid://" .. tostring(image) end
		local ThumbnailFrame = New("ImageLabel", {
			Name = "AccessThumbnail",
			Image = tostring(image),
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.new(1, 0, 0, 104),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			Parent = Content,
		}, {
			New("UICorner", { CornerRadius = UDim.new(0, 10) }),
		})
		if type(thumbnail.Title) == "string" and thumbnail.Title ~= "" then
			local thumbnailTitle = makeLabel(thumbnail.Title, 15, 0, Enum.FontWeight.SemiBold)
			thumbnailTitle.Size = UDim2.new(1, -24, 0, 26)
			thumbnailTitle.AutomaticSize = "None"
			thumbnailTitle.Position = UDim2.new(0, 12, 0.5, 0)
			thumbnailTitle.AnchorPoint = Vector2.new(0, 0.5)
			thumbnailTitle.TextYAlignment = Enum.TextYAlignment.Center
			thumbnailTitle.TextStrokeTransparency = 0.55
			thumbnailTitle.Parent = ThumbnailFrame
		end
	end

	local Header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, {
		New("Frame", {
			Name = "BrandMarker",
			Size = UDim2.new(0, 4, 0, 42),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ThemeTag = { BackgroundColor3 = "Primary" },
			BorderSizePixel = 0,
		}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
		New("Frame", {
			Size = UDim2.new(1, -18, 1, 0),
			Position = UDim2.new(0, 18, 0, 0),
			BackgroundTransparency = 1,
		}, {
			New("UIListLayout", {
				FillDirection = "Vertical",
				SortOrder = "LayoutOrder",
				Padding = UDim.new(0, 5),
				VerticalAlignment = "Center",
			}),
			makeLabel("FORKTUI  /  ACCESS CONTROL", 10, 0.35, Enum.FontWeight.Bold, "Primary"),
			makeLabel(KeyConfig.Title or "Verify access key", 22, 0, Enum.FontWeight.SemiBold),
		}),
	})
	Header.Parent = Content

	local Description = makeLabel(
		type(KeyConfig.Note) == "string" and KeyConfig.Note ~= "" and KeyConfig.Note
			or "Enter your access key to continue. ForktUI will check it against the configured access rule.",
		14,
		0.28,
		Enum.FontWeight.Regular
	)
	Description.LayoutOrder = 2
	Description.Parent = Content

	local InputHeading = makeLabel("ACCESS KEY", 10, 0.25, Enum.FontWeight.Bold, "Primary")
	InputHeading.LayoutOrder = 3
	InputHeading.Parent = Content

	local InputFrame = CreateInput("Paste your access key", "key-round", nil, "Input", function(value)
		enteredKey = value
	end, false, 12, false, true)
	InputFrame.Name = "AccessKeyInput"
	InputFrame.LayoutOrder = 4
	InputFrame.Parent = Content

	local providerHeader
	local ProviderList
	local function addProviderButton(title, icon, action)
		local button = CreateButton(title, icon or "external-link", action, "Secondary", ProviderList)
		button.Size = UDim2.new(1, 0, 0, 38)
		button.AutomaticSize = "None"
		button.LayoutOrder = #services
		return button
	end

	if type(KeyConfig.API) == "table" and #KeyConfig.API > 0 then
		providerHeader = makeLabel("KEY PROVIDERS", 10, 0.25, Enum.FontWeight.Bold, "Primary")
		providerHeader.LayoutOrder = 5
		providerHeader.Parent = Content

		ProviderList = New("Frame", {
			Name = "ProviderList",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = "Y",
				BackgroundTransparency = 1,
				LayoutOrder = 6,
			}, {
				New("UIListLayout", {
					FillDirection = "Vertical",
					SortOrder = "LayoutOrder",
					Padding = UDim.new(0, 6),
				}),
			})
		ProviderList.Parent = Content

		for _, item in ipairs(KeyConfig.API) do
			if type(item) == "table" and type(item.Type) == "string" then
				local serviceDef = ForktUI.Services and ForktUI.Services[item.Type]
				if serviceDef and type(serviceDef.New) == "function" then
					local args = {}
					local serviceArgs = type(serviceDef.Args) == "table" and serviceDef.Args or {}
					for _, argName in ipairs(serviceArgs) do
						table.insert(args, item[argName])
					end
					local ok, service = pcall(function()
						return serviceDef.New(table.unpack(args))
					end)
					if ok and type(service) == "table" then
						service.Type = item.Type
						table.insert(services, service)
						local providerName = item.Title or serviceDef.Name or item.Type
						addProviderButton(providerName, item.Icon or serviceDef.Icon, function()
							if type(service.Copy) ~= "function" then
								notify(ForktUI, "Provider unavailable", "This provider does not expose a copy action.", "circle-alert")
								return
							end
							local copyOk, copyResult = pcall(service.Copy)
							if copyOk then
								notify(ForktUI, "Provider ready", "The provider action was opened or copied.", "check-circle-2")
							else
								notify(ForktUI, "Provider error", copyResult, "circle-alert")
							end
						end)
					else
						serviceLastError = service
					end
				end
			end
		end
	end

	if type(KeyConfig.URL) == "string" and KeyConfig.URL ~= "" then
		local urlOrder = type(KeyConfig.API) == "table" and #KeyConfig.API > 0 and 7 or 5
		local getKeyButton = CreateButton("Copy key link", "link", function()
			if copyText(KeyConfig.URL) then
				notify(ForktUI, "Link copied", "The key link is ready to paste.", "check-circle-2")
			else
				notify(ForktUI, "Clipboard unavailable", "Copy this link manually: " .. KeyConfig.URL, "clipboard")
			end
		end, "Secondary", Content)
		getKeyButton.Size = UDim2.new(1, 0, 0, 40)
		getKeyButton.AutomaticSize = "None"
		getKeyButton.LayoutOrder = urlOrder
	end

	local Actions = New("Frame", {
		Name = "Actions",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		LayoutOrder = 8,
		Parent = Content,
	}, {
		New("UIListLayout", {
			FillDirection = "Horizontal",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 8),
		}),
	})

	local SubmitButton = CreateButton("Continue", "arrow-right", function()
		if submitting or finished then return end
		submitting = true
		local key = trim(enteredKey)
		if key == "" then
			submitting = false
			notify(ForktUI, "Key required", "Enter your key before continuing.", "circle-alert")
			return
		end

		local valid = false
		local failureMessage = "The key was not accepted. Check it and try again."

		if type(KeyConfig.KeyValidator) == "function" then
			local ok, result = pcall(KeyConfig.KeyValidator, key)
			valid = ok and result == true
			if not ok then
				failureMessage = "The key validator returned an error: " .. tostring(result)
			end
		elseif type(KeyConfig.API) ~= "table" or #KeyConfig.API == 0 then
			local keys = KeyConfig.Key
			if type(keys) == "table" then
				for _, candidate in pairs(keys) do
					if tostring(candidate) == key then valid = true; break end
				end
			else
				valid = keys ~= nil and tostring(keys) == key
			end
		else
			for _, service in ipairs(services) do
				if type(service.Verify) == "function" then
					local ok, result, message = pcall(service.Verify, key)
					if ok and result then
						valid = true
						break
					end
					if not ok then
						failureMessage = tostring(result)
					elseif message then
						failureMessage = tostring(message)
					end
				end
			end
			if #services == 0 and serviceLastError then
				failureMessage = "A configured key provider could not be initialized."
			end
		end

		if valid then
			if KeyConfig.SaveKey == true and not saveKey(Config, Filename, key) then
				notify(ForktUI, "Key accepted", "Access was granted, but this executor could not save the key.", "check-circle-2")
			end
			submitting = false
			resolve(true)
		else
			submitting = false
			notify(ForktUI, "Verification failed", failureMessage, "shield-alert")
		end
	end, "Primary", Actions)
	SubmitButton.Size = UDim2.new(0.66, -4, 0, 42)
	SubmitButton.AutomaticSize = "None"
	SubmitButton.LayoutOrder = 1

	local ExitButton = CreateButton("Exit", "x", function()
		resolve(false)
	end, "Secondary", Actions)
	ExitButton.Size = UDim2.new(0.34, -4, 0, 42)
	ExitButton.AutomaticSize = "None"
	ExitButton.LayoutOrder = 2

	local Footer = makeLabel("FORKTUI  •  ACCESS GATE", 9, 0.58, Enum.FontWeight.Medium, "Text")
	Footer.TextXAlignment = "Center"
	Footer.LayoutOrder = 9
	Footer.Parent = Content

	Dialog:Open()
	return Dialog
end

return KeySystem
