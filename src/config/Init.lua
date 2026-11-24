local cloneref = cloneref or clonereference or function(instance)
	return instance
end

local HttpService = cloneref(game:GetService("HttpService"))
local RunService = cloneref(game:GetService("RunService"))

local Window
local FileAPI = {
	writefile = writefile,
	readfile = readfile,
	isfile = isfile,
	isfolder = isfolder,
	makefolder = makefolder,
	listfiles = listfiles,
	delfile = delfile,
}

local ConfigManager = {
	Folder = nil,
	Path = nil,
	Configs = {},
	Parser = {
		Colorpicker = {
			Save = function(obj)
				return {
					__type = obj.__type,
					value = obj.Default:ToHex(),
					transparency = obj.Transparency,
				}
			end,
			Load = function(element, data)
				if element and type(element.Update) == "function" and type(data.value) == "string" then
					element:Update(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		Dropdown = {
			Save = function(obj)
				local value = obj.Value
				if type(value) == "table" then
					if type(value.Title) == "string" then
						value = value.Title
					else
						local selected = {}
						for _, item in ipairs(value) do
							if type(item) == "table" then
								local title = item.Title or item.Name
								if title ~= nil then
									table.insert(selected, tostring(title))
								end
							elseif type(item) == "string" or type(item) == "number" or type(item) == "boolean" then
								table.insert(selected, item)
							end
						end
						value = selected
					end
				end
				return { __type = obj.__type, value = value }
			end,
			Load = function(element, data)
				if element and type(element.Select) == "function" then
					element:Select(data.value)
				end
			end,
		},
		Input = {
			Save = function(obj)
				return { __type = obj.__type, value = obj.Value }
			end,
			Load = function(element, data)
				if element and type(element.Set) == "function" then
					element:Set(data.value)
				end
			end,
		},
		Keybind = {
			Save = function(obj)
				return { __type = obj.__type, value = obj.Value }
			end,
			Load = function(element, data)
				if element and type(element.Set) == "function" then
					element:Set(data.value)
				end
			end,
		},
		Slider = {
			Save = function(obj)
				local value = obj.Value
				return {
					__type = obj.__type,
					value = type(value) == "table" and value.Default or value,
				}
			end,
			Load = function(element, data)
				if element and type(element.Set) == "function" then
					element:Set(tonumber(data.value))
				end
			end,
		},
		Toggle = {
			Save = function(obj)
				return { __type = obj.__type, value = obj.Value == true }
			end,
			Load = function(element, data)
				if element and type(element.Set) == "function" then
					element:Set(data.value == true)
				end
			end,
		},
	},
}

local function hasFileFunction(name)
	return type(FileAPI[name]) == "function"
end

local function safeName(value)
	local name = tostring(value or ""):gsub("[^%w _%-]", "_"):gsub("^%s+", ""):gsub("%s+$", "")
	return name:sub(1, 48)
end

local function ensureFolder(path)
	if type(path) ~= "string" or path == "" or not hasFileFunction("isfolder") or not hasFileFunction("makefolder") then
		return false, "Folder APIs are unavailable"
	end

	local current = ""
	for segment in path:gmatch("[^/\\]+") do
		if segment == ".." or segment == "." then
			return false, "Invalid folder path"
		end
		current = current == "" and segment or (current .. "/" .. segment)
		local existsOk, exists = pcall(isfolder, current)
		if not existsOk then
			return false, tostring(exists)
		end
		if not exists then
			local createOk, createError = pcall(makefolder, current)
			if not createOk then
				return false, tostring(createError)
			end
		end
	end

	return true
end

function ConfigManager:Init(WindowTable)
	if type(WindowTable) ~= "table" or type(WindowTable.Folder) ~= "string" or WindowTable.Folder == "" then
		warn("[ ForktUI.ConfigManager ] Set a non-empty Window.Folder to enable configs.")
		return false
	end

	if RunService:IsStudio() then
		warn("[ ForktUI.ConfigManager ] Filesystem-backed configs are unavailable in Roblox Studio. The UI can still be used.")
		return false
	end

	if not (hasFileFunction("writefile") and hasFileFunction("readfile") and hasFileFunction("isfile")) then
		warn("[ ForktUI.ConfigManager ] Required filesystem functions are unavailable. Config persistence is disabled.")
		return false
	end

	local folder = safeName(WindowTable.Folder)
	if folder == "" then
		warn("[ ForktUI.ConfigManager ] Window.Folder contains no valid characters.")
		return false
	end

	local path = "ForktUI/" .. folder .. "/config"
	local ok, err = ensureFolder(path)
	if not ok then
		warn("[ ForktUI.ConfigManager ] Could not create config directory: " .. tostring(err))
		return false
	end

	Window = WindowTable
	ConfigManager.Folder = folder
	ConfigManager.Path = path .. "/"
	ConfigManager.Configs = {}

	return ConfigManager
end

function ConfigManager:SetPath(customPath)
	if type(customPath) ~= "string" or customPath == "" then
		return false, "A non-empty path is required"
	end
	if not (hasFileFunction("isfolder") and hasFileFunction("makefolder")) then
		return false, "Folder APIs are unavailable"
	end

	local path = customPath:gsub("\\", "/"):gsub("/+$", "")
	local ok, err = ensureFolder(path)
	if not ok then
		return false, err
	end

	ConfigManager.Path = path .. "/"
	return true
end

function ConfigManager:CreateConfig(configFilename, autoload)
	local filename = safeName(configFilename)
	if filename == "" then
		return false, "A valid config name is required"
	end
	if type(ConfigManager.Path) ~= "string" or ConfigManager.Path == "" then
		return false, "Config storage is not initialized"
	end

	local ConfigModule = {
		Path = ConfigManager.Path .. filename .. ".json",
		Elements = {},
		CustomData = {},
		AutoLoad = autoload == true,
		Version = 1.2,
	}

	function ConfigModule:SetAsCurrent()
		if Window and type(Window.SetCurrentConfig) == "function" then
			Window:SetCurrentConfig(ConfigModule)
		end
		return ConfigModule
	end

	function ConfigModule:Register(name, element)
		if type(name) == "string" and name ~= "" and type(element) == "table" then
			ConfigModule.Elements[name] = element
		end
		return ConfigModule
	end

	function ConfigModule:Set(key, value)
		if type(key) == "string" then
			ConfigModule.CustomData[key] = value
		end
		return ConfigModule
	end

	function ConfigModule:Get(key)
		return ConfigModule.CustomData[key]
	end

	function ConfigModule:SetAutoLoad(value)
		ConfigModule.AutoLoad = value == true
		return ConfigModule
	end

	function ConfigModule:Save()
		if not hasFileFunction("writefile") then
			return false, "writefile is unavailable"
		end

		if Window and type(Window.PendingFlags) == "table" then
			for flag, element in pairs(Window.PendingFlags) do
				ConfigModule:Register(flag, element)
			end
		end

		local saveData = {
			__version = ConfigModule.Version,
			__elements = {},
			__autoload = ConfigModule.AutoLoad,
			__custom = ConfigModule.CustomData,
		}

		for name, element in pairs(ConfigModule.Elements) do
			local parser = type(element) == "table" and ConfigManager.Parser[element.__type]
			if parser and type(parser.Save) == "function" then
				local ok, value = pcall(parser.Save, element)
				if ok then
					saveData.__elements[tostring(name)] = value
				else
					warn("[ ForktUI.ConfigManager ] Skipped element '" .. tostring(name) .. "': " .. tostring(value))
				end
			end
		end

		local encodeOk, jsonData = pcall(function()
			return HttpService:JSONEncode(saveData)
		end)
		if not encodeOk then
			return false, "Failed to encode config: " .. tostring(jsonData)
		end

		local writeOk, writeError = pcall(writefile, ConfigModule.Path, jsonData)
		if not writeOk then
			return false, "Failed to write config: " .. tostring(writeError)
		end

		ConfigManager.Configs[filename] = ConfigModule
		return true, saveData
	end

	function ConfigModule:Load()
		if not (hasFileFunction("isfile") and hasFileFunction("readfile")) then
			return false, "Filesystem read functions are unavailable"
		end

		local existsOk, exists = pcall(isfile, ConfigModule.Path)
		if not existsOk or not exists then
			return false, "Config file does not exist"
		end

		local readOk, rawData = pcall(readfile, ConfigModule.Path)
		if not readOk or type(rawData) ~= "string" then
			return false, "Failed to read config file: " .. tostring(rawData)
		end

		local decodeOk, loadData = pcall(function()
			return HttpService:JSONDecode(rawData)
		end)
		if not decodeOk or type(loadData) ~= "table" then
			return false, "Config file contains invalid JSON"
		end

		if not loadData.__version then
			loadData = {
				__version = ConfigModule.Version,
				__elements = loadData,
				__custom = {},
			}
		end

		if Window and type(Window.PendingFlags) == "table" then
			for flag, element in pairs(Window.PendingFlags) do
				ConfigModule:Register(flag, element)
			end
		end

		for name, data in pairs(loadData.__elements or {}) do
			local element = ConfigModule.Elements[name]
			local parser = type(data) == "table" and ConfigManager.Parser[data.__type]
			if element and parser and type(parser.Load) == "function" then
				local ok, err = pcall(parser.Load, element, data)
				if not ok then
					warn("[ ForktUI.ConfigManager ] Failed to restore '" .. tostring(name) .. "': " .. tostring(err))
				end
			end
		end

		ConfigModule.CustomData = type(loadData.__custom) == "table" and loadData.__custom or {}
		return true, ConfigModule.CustomData
	end

	function ConfigModule:Delete()
		if not hasFileFunction("delfile") then
			return false, "delfile is unavailable"
		end
		if not hasFileFunction("isfile") then
			return false, "isfile is unavailable"
		end

		local existsOk, exists = pcall(isfile, ConfigModule.Path)
		if not existsOk or not exists then
			return false, "Config file does not exist"
		end

		local deleteOk, deleteError = pcall(delfile, ConfigModule.Path)
		if not deleteOk then
			return false, "Failed to delete config: " .. tostring(deleteError)
		end

		ConfigManager.Configs[filename] = nil
		if Window and Window.CurrentConfig == ConfigModule then
			Window.CurrentConfig = nil
		end
		return true
	end

	function ConfigModule:GetData()
		return {
			elements = ConfigModule.Elements,
			custom = ConfigModule.CustomData,
			autoload = ConfigModule.AutoLoad,
		}
	end

	ConfigModule:SetAsCurrent()
	ConfigManager.Configs[filename] = ConfigModule

	-- Restore the persisted auto-load flag when this config is opened without an explicit override.
	if autoload == nil and hasFileFunction("isfile") and hasFileFunction("readfile") then
		local existsOk, exists = pcall(isfile, ConfigModule.Path)
		if existsOk and exists then
			local readOk, rawData = pcall(readfile, ConfigModule.Path)
			if readOk and type(rawData) == "string" then
				local decodeOk, savedData = pcall(function()
					return HttpService:JSONDecode(rawData)
				end)
				if decodeOk and type(savedData) == "table" and savedData.__autoload == true then
					ConfigModule.AutoLoad = true
				end
			end
		end
	end

	if ConfigModule.AutoLoad and hasFileFunction("isfile") and hasFileFunction("readfile") then
		local existsOk, exists = pcall(isfile, ConfigModule.Path)
		if existsOk and exists then
			task.delay(0.35, function()
				local ok, err = ConfigModule:Load()
				if not ok then
					warn("[ ForktUI.ConfigManager ] Auto-load failed for '" .. filename .. "': " .. tostring(err))
				end
			end)
		end
	end

	return ConfigModule
end

function ConfigManager:Config(configFilename, autoload)
	return ConfigManager:CreateConfig(configFilename, autoload)
end

function ConfigManager:GetAutoLoadConfigs()
	local names = {}
	for configName, configModule in pairs(ConfigManager.Configs) do
		if configModule and configModule.AutoLoad then
			table.insert(names, configName)
		end
	end
	table.sort(names)
	return names
end

function ConfigManager:DeleteConfig(configName)
	local filename = safeName(configName)
	if filename == "" then
		return false, "A valid config name is required"
	end
	if not (hasFileFunction("delfile") and hasFileFunction("isfile")) then
		return false, "File deletion functions are unavailable"
	end
	if type(ConfigManager.Path) ~= "string" then
		return false, "Config storage is not initialized"
	end

	local configPath = ConfigManager.Path .. filename .. ".json"
	local existsOk, exists = pcall(isfile, configPath)
	if not existsOk or not exists then
		return false, "Config file does not exist"
	end

	local deleteOk, deleteError = pcall(delfile, configPath)
	if not deleteOk then
		return false, "Failed to delete config: " .. tostring(deleteError)
	end

	ConfigManager.Configs[filename] = nil
	if Window and Window.CurrentConfig and Window.CurrentConfig.Path == configPath then
		Window.CurrentConfig = nil
	end
	return true
end

function ConfigManager:AllConfigs()
	local files = {}
	if type(ConfigManager.Path) ~= "string" or ConfigManager.Path == "" then
		return files
	end
	if not hasFileFunction("listfiles") then
		for name in pairs(ConfigManager.Configs) do
			table.insert(files, name)
		end
		table.sort(files)
		return files
	end

	local ok, entries = pcall(listfiles, ConfigManager.Path)
	if not ok or type(entries) ~= "table" then
		return files
	end

	for _, path in ipairs(entries) do
		if type(path) == "string" then
			local name = path:match("([^/\\]+)%.json$")
			if name then
				table.insert(files, name)
			end
		end
	end

	table.sort(files)
	return files
end

function ConfigManager:GetConfig(configName)
	return ConfigManager.Configs[safeName(configName)]
end

return ConfigManager
