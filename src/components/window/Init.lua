-- /* src/components/Window/Init.lua */

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))

local CurrentCamera = workspace.CurrentCamera

local Acrylic = require("../../utils/Acrylic/Init")

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

--local UIComponents = require("../Components/UI.lua")
local CreateLabel = require("../ui/Label").New
local CreateButton = require("../ui/Button").New
local CreateScrollSlider = require("../ui/ScrollSlider").New
local Tag = require("../ui/Tag")

local ConfigManager = require("../../config/Init")

local Notified = false

return function(Config)
	local Window = {
		Title = Config.Title or "ForktUI",
		Author = Config.Author or "sukitovone",
		Icon = Config.Icon,
		IconSize = Config.IconSize or 22,
		IconThemed = Config.IconThemed,
		IconRadius = Config.IconRadius or 0,
		Folder = Config.Folder,
		Resizable = Config.Resizable ~= false,
		Background = Config.Background,
		BackgroundImageTransparency = Config.BackgroundImageTransparency or 0,
		ShadowTransparency = Config.ShadowTransparency or 0.6,
		User = Config.User or {},
		Footer = Config.Footer or {},
		Topbar = type(Config.Topbar) == "table" and {
			Height = tonumber(Config.Topbar.Height) or 60,
			ButtonsType = Config.Topbar.ButtonsType == "Mac" and "Mac" or "Default",
		} or { Height = 60, ButtonsType = "Default" }, -- Default or Mac

		Size = Config.Size,

		MinSize = Config.MinSize or Vector2.new(540, 360),
		MaxSize = Config.MaxSize or Vector2.new(960, 680),

		TopBarButtonIconSize = Config.TopBarButtonIconSize,

		ToggleKey = Config.ToggleKey,
		ElementsRadius = Config.ElementsRadius,
		Radius = Config.Radius or 14,
		Transparent = Config.Transparent or false,
		HideSearchBar = Config.HideSearchBar ~= false,
		ScrollBarEnabled = Config.ScrollBarEnabled or false,
		SideBarWidth = Config.SideBarWidth or 184,
		Acrylic = Config.Acrylic or false,
		NewElements = Config.NewElements ~= false,
		IgnoreAlerts = Config.IgnoreAlerts or false,
		HidePanelBackground = Config.HidePanelBackground or false,
		AutoScale = Config.AutoScale ~= false,
		OpenButton = Config.OpenButton,
		DragFrameSize = 160,

		Position = UDim2.new(0.5, 0, 0.5, 0),
		UICorner = 14, -- ForktUI flat-panel radius
		UIPadding = 16,
		UIElements = {},
		CanDropdown = true,
		Closed = false,
		Parent = Config.Parent,
		Destroyed = false,
		IsFullscreen = false,
		CanResize = Config.Resizable ~= false,
		IsOpenButtonEnabled = true,

		CurrentConfig = nil,
		ConfigManager = nil,
		AcrylicPaint = nil,
		CurrentTab = nil,
		TabModule = nil,

		OnOpenCallback = nil,
		OnCloseCallback = nil,
		OnDestroyCallback = nil,

		IsPC = false,

		Gap = 7,

		TopBarButtons = {},
		AllElements = {},

		ElementConfig = {},

		PendingFlags = {},

		IsToggleDragging = false,
	}

	Window.UICorner = Window.Radius

	Window.TopBarButtonIconSize = Window.TopBarButtonIconSize or (Window.Topbar.ButtonsType == "Mac" and 11 or 16)

	Window.ElementConfig = {
		UIPadding = (Window.NewElements and 10 or 13),
		UICorner = Window.ElementsRadius or (Window.NewElements and 12 or 14),
	}

	local WindowSize = Window.Size or UDim2.new(0, 720, 0, 520)
	Window.Size = UDim2.new(
		WindowSize.X.Scale,
		math.clamp(WindowSize.X.Offset, Window.MinSize.X, Window.MaxSize.X),
		WindowSize.Y.Scale,
		math.clamp(WindowSize.Y.Offset, Window.MinSize.Y, Window.MaxSize.Y)
	)

	local function ensureFolder(path)
		if
			type(path) ~= "string"
			or path == ""
			or type(isfolder) ~= "function"
			or type(makefolder) ~= "function"
		then
			return
		end

		local ok, exists = pcall(isfolder, path)
		if ok and not exists then
			pcall(makefolder, path)
		end
	end

	if not RunService:IsStudio() and Window.Folder and type(writefile) == "function" then
		local folder = tostring(Window.Folder)
		ensureFolder("ForktUI")
		ensureFolder("ForktUI/" .. folder)
		ensureFolder("ForktUI/" .. folder .. "/assets")
		ensureFolder(folder)
		ensureFolder(folder .. "/assets")
	end

	local UICorner = New("UICorner", {
		CornerRadius = UDim.new(0, Window.UICorner),
	})

	if Window.Folder then
		Window.ConfigManager = ConfigManager:Init(Window)
	end

	if Window.Acrylic then
		local AcrylicPaint, BlurModule = Acrylic.AcrylicPaint({ UseAcrylic = Window.Acrylic })

		Window.AcrylicPaint = AcrylicPaint
	end

	local ResizeHandle = New("Frame", {
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 99,
		Active = true,
	}, {
		New("ImageLabel", {
			Size = UDim2.new(0, 48 * 2, 0, 48 * 2),
			BackgroundTransparency = 1,
			Image = "rbxassetid://120997033468887",
			Position = UDim2.new(0.5, -16, 0.5, -16),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 1, -- .8; .35
		}),
	})
	local FullScreenIconData = Creator.Icon("expand")
	local FullScreenIcon = Creator.NewRoundFrame(Window.UICorner, "Squircle", {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = 1, -- .65
		ImageColor3 = Color3.new(0, 0, 0),
		ZIndex = 98,
		Active = false, -- true
	}, {
		New("ImageLabel", {
			Size = UDim2.new(0, 70, 0, 70),
			Image = FullScreenIconData and FullScreenIconData[1],
			ImageRectOffset = FullScreenIconData and FullScreenIconData[2] and FullScreenIconData[2].ImageRectPosition,
			ImageRectSize = FullScreenIconData and FullScreenIconData[2] and FullScreenIconData[2].ImageRectSize,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 1,
		}),
	})

	local FullScreenBlur = Creator.NewRoundFrame(Window.UICorner, "Squircle", {
		Size = UDim2.new(1, 0, 1, 0),
		ImageTransparency = 1, -- .65
		ImageColor3 = Color3.new(0, 0, 0),
		ZIndex = 999,
		Active = false, -- true
	})

	-- local TabHighlight = Creator.NewRoundFrame(Window.UICorner-(Window.UIPadding/2), "Squircle", {
	--     Size = UDim2.new(1,0,0,0),
	--     ImageTransparency = .95,
	--     ThemeTag = {
	--         ImageColor3 = "Text",
	--     }
	-- })

	Window.UIElements.SideBar = New("ScrollingFrame", {
		Size = UDim2.new(
			1,
			Window.ScrollBarEnabled and -3 - (Window.UIPadding / 2) or 0,
			1,
			not Window.HideSearchBar and -39 - 6 or 0
		),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ElasticBehavior = "Never",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = "Y",
		ScrollingDirection = "Y",
		ClipsDescendants = true,
		VerticalScrollBarPosition = "Left",
	}, {
		New("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = "Y",
			Size = UDim2.new(1, 0, 0, 0),
			Name = "Frame",
		}, {
			New("UIPadding", {
				--PaddingTop = UDim.new(0,Window.UIPadding/2),
				--PaddingLeft = UDim.new(0,4+(Window.UIPadding/2)),
				--PaddingRight = UDim.new(0,4+(Window.UIPadding/2)),
				PaddingBottom = UDim.new(0, Window.UIPadding / 2),
			}),
			New("UIListLayout", {
				SortOrder = "LayoutOrder",
				Padding = UDim.new(0, Window.Gap),
			}),
		}),
		New("UIPadding", {
			--PaddingTop = UDim.new(0,4),
			PaddingLeft = UDim.new(0, Window.UIPadding / 2),
			PaddingRight = UDim.new(0, Window.UIPadding / 2),
			PaddingBottom = UDim.new(0, Window.UIPadding / 2),
		}),
		--TabHighlight
	})

	Window.UIElements.SideBarContainer = New("Frame", {
		Size = UDim2.new(
			0,
			Window.SideBarWidth,
			1,
			Window.User.Enabled and -Window.Topbar.Height - 42 - (Window.UIPadding * 2) or -Window.Topbar.Height
		),
		Position = UDim2.new(0, 0, 0, Window.Topbar.Height),
		BackgroundTransparency = 1,
		Visible = true,
	}, {
		New("Frame", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, not Window.HideSearchBar and -39 - 6 - Window.UIPadding or -Window.UIPadding / 2),
			Position = UDim2.new(0, 0, 1, -Window.UIPadding / 2),
			AnchorPoint = Vector2.new(0, 1),
		}),
		Window.UIElements.SideBar,
	})

	if Window.ScrollBarEnabled then
		CreateScrollSlider(
			Window.UIElements.SideBar,
			Window.UIElements.SideBarContainer.Content,
			Window,
			3,
			Config.ForktUI
		)
	end

	Window.UIElements.MainBar = New("Frame", {
		Size = UDim2.new(1, -Window.UIElements.SideBarContainer.AbsoluteSize.X, 1, -Window.Topbar.Height),
		Position = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
	}, {
		Creator.NewRoundFrame(Window.UICorner - (Window.UIPadding / 2), "Squircle", {
			Size = UDim2.new(1, 0, 1, 0),
			ThemeTag = {
				ImageColor3 = "PanelBackground",
				ImageTransparency = "PanelBackgroundTransparency",
			},
			-- ImageColor3 = Color3.new(1,1,1),
			-- ImageTransparency = .95,
			ZIndex = 3,
			Name = "Background",
			Visible = not Window.HidePanelBackground,
		}),
		New("UIPadding", {
			--PaddingTop = UDim.new(0,Window.UIPadding/2),
			PaddingLeft = UDim.new(0, Window.UIPadding / 2),
			PaddingRight = UDim.new(0, Window.UIPadding / 2),
			PaddingBottom = UDim.new(0, Window.UIPadding / 2),
		}),
	})

	local Blur = New("ImageLabel", { -- Shadow
		Image = "rbxassetid://8992230677",
		ThemeTag = {
			ImageColor3 = "WindowShadow",
			--ImageTransparency = "WindowShadowTransparency",
		},
		ImageTransparency = 1, -- .7
		Size = UDim2.new(1, 100, 1, 100),
		Position = UDim2.new(0, -100 / 2, 0, -100 / 2),
		ScaleType = "Slice",
		SliceCenter = Rect.new(99, 99, 99, 99),
		BackgroundTransparency = 1,
		ZIndex = -999999999999999,
		Name = "Blur",
	})

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		Window.IsPC = false
	elseif UserInputService.KeyboardEnabled then
		Window.IsPC = true
	else
		Window.IsPC = nil
	end

	--Window.IsPC = true

	-- local OpenButtonContainer = nil
	-- local OpenButton = nil
	-- local OpenButtonIcon = nil

	local UserIcon
	if Window.User then
		local cachedUserThumbnail = "rbxasset://textures/ui/GuiImagePlaceholder.png"

		local function GetUserThumb(userId)
			local targetId = tonumber(userId) or (Players.LocalPlayer and Players.LocalPlayer.UserId) or 1
			local ok, imageId = pcall(function()
				local thumbnail, _isReady = Players:GetUserThumbnailAsync(
					targetId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size420x420
				)
				return thumbnail
			end)
			return ok and imageId or "rbxasset://textures/ui/GuiImagePlaceholder.png"
		end

		local function RefreshUserThumbnail()
			if not UserIcon then
				return
			end
			local player = Players.LocalPlayer
			local userId = player and player.UserId
			if Window.User.Anonymous or not userId then
				cachedUserThumbnail = "rbxasset://textures/ui/GuiImagePlaceholder.png"
				local avatarFrame = UserIcon:FindFirstChild("UserIcon")
				local avatar = avatarFrame and avatarFrame:FindFirstChild("ImageLabel")
				if avatar then
					avatar.Image = cachedUserThumbnail
				end
				return
			end
			task.spawn(function()
				local imageId = GetUserThumb(userId)
				cachedUserThumbnail = imageId
				if UserIcon and UserIcon.Parent then
					local avatarFrame = UserIcon:FindFirstChild("UserIcon")
					local avatar = avatarFrame and avatarFrame:FindFirstChild("ImageLabel")
					if avatar then
						avatar.Image = imageId
					end
				end
			end)
		end

		UserIcon = New("TextButton", {
			Size = UDim2.new(
				0,
				math.max(Window.SideBarWidth - Window.UIPadding, 0),
				0,
				42 + Window.UIPadding
			),
			Position = UDim2.new(0, Window.UIPadding / 2, 1, -(Window.UIPadding / 2)),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Selectable = true,
			Text = "",
			Name = "UserProfileButton",
			Visible = Window.User.Enabled or false,
		}, {
			Creator.NewRoundFrame(Window.UICorner - (Window.UIPadding / 2), "SquircleOutline", {
				Size = UDim2.new(1, 0, 1, 0),
				ThemeTag = {
					ImageColor3 = "Text",
				},
				ImageTransparency = 1, -- .85
				Name = "Outline",
			}, {
				New("UIGradient", {
					Rotation = 78,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
					}),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0.0, 0.1),
						NumberSequenceKeypoint.new(0.5, 1),
						NumberSequenceKeypoint.new(1.0, 0.1),
					}),
				}),
			}),
			Creator.NewRoundFrame(Window.UICorner - (Window.UIPadding / 2), "Squircle", {
				Size = UDim2.new(1, 0, 1, 0),
				ThemeTag = {
					ImageColor3 = "Text",
				},
				ImageTransparency = 1, -- .95
				Name = "UserIcon",
			}, {
				New("ImageLabel", {
					Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 42, 0, 42),
					ThemeTag = {
						BackgroundColor3 = "Text",
					},
					BackgroundTransparency = 0.93,
				}, {
					New("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
				}),
				New("Frame", {
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, -58, 0, 0),
					BackgroundTransparency = 1,
				}, {
					New("TextLabel", {
						Text = Window.User.Anonymous and "Anonymous" or Players.LocalPlayer.DisplayName,
						TextSize = 17,
						ThemeTag = {
							TextColor3 = "Text",
						},
						FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
						AutomaticSize = "Y",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 0),
						TextTruncate = "AtEnd",
						TextXAlignment = "Left",
						Name = "DisplayName",
					}),
					New("TextLabel", {
						Text = Window.User.Anonymous and "anonymous" or Players.LocalPlayer.Name,
						TextSize = 15,
						TextTransparency = 0.6,
						ThemeTag = {
							TextColor3 = "Text",
						},
						FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
						AutomaticSize = "Y",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 0),
						TextTruncate = "AtEnd",
						TextXAlignment = "Left",
						Name = "UserName",
					}),
					New("UIListLayout", {
						Padding = UDim.new(0, 4),
						HorizontalAlignment = "Left",
					}),
				}),
				New("UIListLayout", {
					Padding = UDim.new(0, Window.UIPadding),
					FillDirection = "Horizontal",
					VerticalAlignment = "Center",
				}),
				New("UIPadding", {
					PaddingLeft = UDim.new(0, Window.UIPadding / 2),
					PaddingRight = UDim.new(0, Window.UIPadding / 2),
				}),
			}),
		})

		function Window.User:Enable()
			Window.User.Enabled = true
			Tween(
				Window.UIElements.SideBarContainer,
				0.25,
				{ Size = UDim2.new(0, Window.SideBarWidth, 1, -Window.Topbar.Height - 42 - (Window.UIPadding * 2)) },
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			):Play()
			UserIcon.Visible = true
		end
		function Window.User:Disable()
			Window.User.Enabled = false
			Tween(
				Window.UIElements.SideBarContainer,
				0.25,
				{ Size = UDim2.new(0, Window.SideBarWidth, 1, -Window.Topbar.Height) },
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			):Play()
			UserIcon.Visible = false
		end
		function Window.User:SetAnonymous(v)
			if type(v) ~= "boolean" then
				return false, "SetAnonymous expects a boolean"
			end
			Window.User.Anonymous = v
			local player = Players.LocalPlayer
			if UserIcon and UserIcon.Parent then
				local frame = UserIcon.UserIcon.Frame
				frame.DisplayName.Text = v and "Anonymous" or (player and player.DisplayName or "Player")
				frame.UserName.Text = v and "anonymous" or (player and player.Name or "player")
				RefreshUserThumbnail()
			end
			return Window.User
		end

		if Window.User.Enabled then
			Window.User:Enable()
		else
			Window.User:Disable()
		end

		local function escapeRichText(value)
			return tostring(value or "")
				:gsub("&", "&amp;")
				:gsub("<", "&lt;")
				:gsub(">", "&gt;")
		end

		local function ShowUserProfile()
			local player = Players.LocalPlayer
			if not player then
				return
			end

			if Window.User.Anonymous then
				Config.ForktUI:Popup({
					Title = "Anonymous profile",
					Content = "Anonymous mode is enabled. Turn it off in Window.User:SetAnonymous(false) to display the local Roblox account profile.",
					Icon = "user-round",
					Buttons = {
						{ Title = "Close", Variant = "Tertiary" },
					},
				})
				return
			end

			local profileUrl = "https://www.roblox.com/users/" .. tostring(player.UserId) .. "/profile"
			local memberType = "Standard"
			pcall(function()
				memberType = player.MembershipType.Name
			end)

			local profileDetails = table.concat({
				"@" .. escapeRichText(player.Name),
				"User ID: " .. tostring(player.UserId),
				"Account age: " .. tostring(player.AccountAge) .. " days",
				"Membership: " .. escapeRichText(memberType),
				"Profile: " .. escapeRichText(profileUrl),
			}, "\n")

			Config.ForktUI:Popup({
				Title = escapeRichText(player.DisplayName),
				Content = profileDetails,
				Icon = "user-round",
				Thumbnail = {
					Image = cachedUserThumbnail,
				},
				Buttons = {
					{
						Title = "Copy profile link",
						Icon = "copy",
						Callback = function()
							local clipboard = setclipboard or toclipboard
						if type(clipboard) == "function" then
							local copied = pcall(clipboard, profileUrl)
							if copied then
								Config.ForktUI:Notify({ Title = "Profile link copied", Content = "Roblox profile URL copied to clipboard." })
								return
							end
						end
						Config.ForktUI:Notify({ Title = "Roblox profile URL", Content = profileUrl, Duration = 7 })
						end,
					},
					{ Title = "Close", Variant = "Tertiary" },
				},
			})
		end

		-- Defer the thumbnail update until the button has been parented into the window tree.
		task.defer(RefreshUserThumbnail)
		Creator.AddSignal(UserIcon.Activated, function()
			ShowUserProfile()
			if type(Window.User.Callback) == "function" then
				local selectedPlayer = Players.LocalPlayer
				if Window.User.Anonymous then
					selectedPlayer = nil
				end
				Creator.SafeCallback(Window.User.Callback, selectedPlayer)
			end
		end)
		Creator.AddSignal(UserIcon.MouseEnter, function()
			Tween(UserIcon.UserIcon, 0.08, { ImageTransparency = 0.94 }):Play()
			Tween(UserIcon.Outline, 0.08, { ImageTransparency = 0.82 }):Play()
		end)
		Creator.AddSignal(UserIcon.MouseLeave, function()
			Tween(UserIcon.UserIcon, 0.08, { ImageTransparency = 1 }):Play()
			Tween(UserIcon.Outline, 0.08, { ImageTransparency = 1 }):Play()
		end)
		Creator.AddSignal(UserIcon.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				Tween(UserIcon.UserIcon, 0.08, { ImageTransparency = 1 }):Play()
				Tween(UserIcon.Outline, 0.08, { ImageTransparency = 1 }):Play()
			end
		end)
	end

	local Outline1
	local Outline2

	local IsVideoBG = false
	local BGImage = nil

	local BGVideo = typeof(Window.Background) == "string" and string.match(Window.Background, "^video:(.+)") or nil

	local BGHttpImage = typeof(Window.Background) == "string"
			and not BGVideo
			and string.match(Window.Background, "^https?://.+")
		or nil

	local BGRobloxImage = typeof(Window.Background) == "string"
			and not BGVideo
			and string.match(Window.Background, "^rbxassetid://%d+")
		or nil

	local function GetImageExtension(url)
		if not url or typeof(url) ~= "string" then
			return ".png"
		end
		local cleanUrl = url:match("^([^?#]+)") or url
		local ext = cleanUrl:match("%.(%w+)$")
		if ext then
			ext = ext:lower()
			if ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp" then
				return "." .. ext
			end
		end
		return ".png"
	end

	--print(GetImageExtension(BGImageUrl))

	if typeof(Window.Background) == "string" and BGVideo then
		IsVideoBG = true

		if string.find(BGVideo, "http") then
			local videoPath = (Window.Folder or "Temp") .. "/assets/." .. Creator.SanitizeFilename(BGVideo) .. ".webm"
			if not isfile(videoPath) then
				local success, result = pcall(function()
					-- local response = Creator.Request({
					-- 	Url = BGVideo,
					-- 	Method = "GET",
					-- 	Headers = { ["User-Agent"] = "Roblox/Exploit" },
					-- })
					local response = game.HttpGet and game:HttpGet(BGVideo)
						or Creator.Request({
							Url = BGVideo,
							Method = "GET",
							Headers = { ["User-Agent"] = "Roblox/Exploit" },
						}).Body
					--print(response)
					writefile(videoPath, response)
				end)
				if not success then
					warn("[ ForktUI.Window.Background ] Failed to download video: " .. tostring(result))
				end
			end

			local success, customAsset = pcall(function()
				return getcustomasset(videoPath)
			end)
			if not success then
				warn("[ ForktUI.Window.Background ] Failed to load custom asset: " .. tostring(customAsset))
			end
			warn("[ ForktUI.Window.Background ] VideoFrame may not work with custom video")
			BGVideo = customAsset
		end

		BGImage = New("VideoFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Video = BGVideo,
			Looped = true,
			Volume = 0,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
		BGImage:Play()
	elseif BGHttpImage then
		local imagePath = (Window.Folder or "Temp")
			.. "/assets/."
			.. Creator.SanitizeFilename(BGHttpImage)
			.. GetImageExtension(BGHttpImage)

		if isfile and not isfile(imagePath) then
			local success, result = pcall(function()
				local response = game.HttpGet and game:HttpGet(BGHttpImage)
					or Creator.Request({
						Url = BGHttpImage,
						Method = "GET",
						Headers = { ["User-Agent"] = "Roblox/Exploit" },
					}).Body

				writefile(imagePath, response)
			end)

			if not success then
				warn("[ Window.Background ] Failed to download image: " .. tostring(result))
			end
		end

		local success, customAsset = pcall(function()
			return getcustomasset(imagePath)
		end)

		if not success then
			warn("[ Window.Background ] Failed to load custom asset: " .. tostring(customAsset))
		end

		BGImage = New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = customAsset,
			ImageTransparency = 0,
			ScaleType = "Crop",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
	elseif BGRobloxImage then
		BGImage = New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = BGRobloxImage,
			ImageTransparency = 0,
			ScaleType = "Crop",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
	elseif Window.Background then
		BGImage = New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = typeof(Window.Background) == "string" and Window.Background or "",
			ImageTransparency = 1,
			ScaleType = "Crop",
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})
	end

	local BottomDragFrame = Creator.NewRoundFrame(99, "Squircle", {
		ImageTransparency = 0.8,
		ImageColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 0, 0, 4), -- 200
		Position = UDim2.new(0.5, 0, 1, 4),
		AnchorPoint = Vector2.new(0.5, 0),
	}, {
		New("TextButton", {
			Size = UDim2.new(1, 12, 1, 12),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Active = true,
			ZIndex = 99,
			Name = "Frame",
		}),
	})

	function createAuthor(text)
		return New("TextLabel", {
			Text = text,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			BackgroundTransparency = 1,
			TextTransparency = 0.35,
			AutomaticSize = "XY",
			Parent = Window.UIElements.Main and Window.UIElements.Main.Main.Topbar.Left.Title,
			TextXAlignment = "Left",
			TextSize = 13,
			LayoutOrder = 2,
			ThemeTag = {
				TextColor3 = "WindowTopbarAuthor",
			},
			Name = "Author",
		})
	end

	local WindowAuthor
	local WindowIcon

	if Window.Author then
		WindowAuthor = createAuthor(Window.Author)
	end

	local WindowTitle = New("TextLabel", {
		Text = Window.Title,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
		BackgroundTransparency = 1,
		AutomaticSize = "XY",
		Name = "Title",
		TextXAlignment = "Left",
		TextSize = 16,
		ThemeTag = {
			TextColor3 = "WindowTopbarTitle",
		},
	})

	Window.UIElements.Main = New("Frame", {
		Size = UDim2.new(Window.Size.X.Scale, Window.Size.X.Offset, 0, 0),
		Position = Window.Position,
		BackgroundTransparency = 1,
		Parent = Config.Parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Active = true,
		--GroupTransparency = 1,
	}, {
		Config.ForktUI.UIScaleObj,
		Window.AcrylicPaint and Window.AcrylicPaint.Frame or nil,
		Blur,
		Creator.NewRoundFrame(Window.UICorner, "Squircle", {
			ImageTransparency = 1, --  Window.Transparent and Config.ForktUI.TransparencyValue or 0,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Name = "Background",
			ThemeTag = {
				ImageColor3 = "WindowBackground",
			},
			--ZIndex = -9999,
		}, {
			BGImage,
			BottomDragFrame,
			ResizeHandle,
		}),
		--[[New("UIScale", {
			Scale = 0.89,
		}),]]
		--UIStroke,
		UICorner,
		FullScreenIcon,
		FullScreenBlur,
		New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Name = "Main",
			--GroupTransparency = 1,
			Visible = false,
			ZIndex = 97,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
			Window.UIElements.SideBarContainer,
			Window.UIElements.MainBar,

			UserIcon,

			Outline2,
			New("Frame", { -- Topbar
				Size = UDim2.new(1, 0, 0, Window.Topbar.Height),
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				Name = "Topbar",
			}, {
				Outline1,
				--[[New("Frame", { -- Outline
                    Size = UDim2.new(1,Window.UIPadding*2, 0, 1),
                    Position = UDim2.new(0,-Window.UIPadding, 1,Window.UIPadding-2),
                    BackgroundTransparency = 0.9,
                    BackgroundColor3 = Color3.fromHex(Config.Theme.Outline),
                }),]]
				New("Frame", { -- Topbar Left Side
					AutomaticSize = "X",
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 1,
					Name = "Left",
				}, {
					New("UIListLayout", {
						Padding = UDim.new(0, Window.UIPadding + 4),
						SortOrder = "LayoutOrder",
						FillDirection = "Horizontal",
						VerticalAlignment = "Center",
					}),
					New("Frame", {
						AutomaticSize = "XY",
						BackgroundTransparency = 1,
						Name = "Title",
						Size = UDim2.new(0, 0, 1, 0),
						LayoutOrder = 2,
					}, {
						New("UIListLayout", {
							Padding = UDim.new(0, 0),
							SortOrder = "LayoutOrder",
							FillDirection = "Vertical",
							VerticalAlignment = "Center",
						}),
						WindowTitle,
						WindowAuthor,
					}),
					New("UIPadding", {
						PaddingLeft = UDim.new(0, 4),
					}),
				}),
				New("CanvasGroup", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 1,
					Name = "Center",
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					AutomaticSize = "Y",
					Visible = false,
				}, {
					--[[New("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),]]
					New("ScrollingFrame", { -- Topbar Center Size
						Name = "Holder",
						BackgroundTransparency = 1,
						AutomaticSize = "Y",
						ScrollBarThickness = 0,
						ScrollingDirection = "X",
						AutomaticCanvasSize = "X",
						CanvasSize = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(1, 0, 1, 0),
						--AnchorPoint = Vector2.new(0, 0.5),
						--Position = UDim2.new(0, 0, 0.5, 0),
					}, {

						New("UIListLayout", {
							FillDirection = "Horizontal",
							VerticalAlignment = "Center",
							HorizontalAlignment = "Left",
							Padding = UDim.new(0, Window.UIPadding / 2),
						}),
					}),
				}),
				New("Frame", { -- Topbar Right Side -- Window.UIElements.Main.Main.Topbar.Right
					AutomaticSize = "XY",
					BackgroundTransparency = 1,
					Position = UDim2.new(Window.Topbar.ButtonsType == "Default" and 1 or 0, 0, 0.5, 0),
					AnchorPoint = Vector2.new(Window.Topbar.ButtonsType == "Default" and 1 or 0, 0.5),
					Name = "Right",
				}, {
					New("UIListLayout", {
						Padding = UDim.new(0, Window.Topbar.ButtonsType == "Default" and 9 or 0),
						FillDirection = "Horizontal",
						SortOrder = "LayoutOrder",
					}),
				}),
				New("UIPadding", {
					PaddingTop = UDim.new(0, Window.UIPadding),
					PaddingLeft = UDim.new(
						0,
						Window.Topbar.ButtonsType == "Default" and Window.UIPadding or Window.UIPadding - 2
					),
					PaddingRight = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, Window.UIPadding),
				}),
			}),
		}),
	})

	Creator.AddSignal(Window.UIElements.Main.Main.Topbar.Left:GetPropertyChangedSignal("AbsoluteSize"), function()
		local LeftWidth = 0
		local RightWidth = Window.UIElements.Main.Main.Topbar.Right.UIListLayout.AbsoluteContentSize.X
			/ Config.ForktUI.UIScale

		LeftWidth = Window.UIElements.Main.Main.Topbar.Left.AbsoluteSize.X / Config.ForktUI.UIScale
		if Window.Topbar.ButtonsType ~= "Default" then
			LeftWidth = LeftWidth + RightWidth + Window.UIPadding - 4
		end

		Window.UIElements.Main.Main.Topbar.Center.Position =
			UDim2.new(0, LeftWidth + (Window.UIPadding / Config.ForktUI.UIScale), 0.5, 0)
		Window.UIElements.Main.Main.Topbar.Center.Size = UDim2.new(
			1,
			-LeftWidth
				- (Window.UIPadding / Config.ForktUI.UIScale)
				- (Window.Topbar.ButtonsType == "Default" and RightWidth + Window.UIPadding or 0),
			1,
			0
		)
	end)

	if Window.Topbar.ButtonsType ~= "Default" then
		Creator.AddSignal(Window.UIElements.Main.Main.Topbar.Right:GetPropertyChangedSignal("AbsoluteSize"), function()
			Window.UIElements.Main.Main.Topbar.Left.Position = UDim2.new(
				0,
				(Window.UIElements.Main.Main.Topbar.Right.AbsoluteSize.X / Config.ForktUI.UIScale) + Window.UIPadding - 4,
				0,
				0
			)
		end)
	end

	function Window:CreateTopbarButton(Name, Icon, Callback, LayoutOrder, IconThemed, Color, IconSize)
		local IconFrame = Creator.Image(
			Icon,
			Icon,
			0,
			Window.Folder,
			"WindowTopbarIcon",
			Window.Topbar.ButtonsType == "Default" and true or false,
			IconThemed,
			"WindowTopbarButtonIcon"
		)
		IconFrame.Size = Window.Topbar.ButtonsType == "Default"
				and UDim2.new(0, IconSize or Window.TopBarButtonIconSize, 0, IconSize or Window.TopBarButtonIconSize)
			or UDim2.new(0, 0, 0, 0)
		IconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		IconFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		IconFrame.ImageLabel.ImageTransparency = Window.Topbar.ButtonsType == "Default" and 0 or 1

		if Window.Topbar.ButtonsType ~= "Default" then
			IconFrame.ImageLabel.ImageColor3 = Creator.GetTextColorForHSB(Color)
		end

		local Button = Creator.NewRoundFrame(
			Window.Topbar.ButtonsType == "Default" and Window.UICorner - (Window.UIPadding / 2) or 999,
			"Squircle",
			{
				Size = Window.Topbar.ButtonsType == "Default"
						and UDim2.new(0, Window.Topbar.Height - 16, 0, Window.Topbar.Height - 16)
					or UDim2.new(0, 14, 0, 14),
				LayoutOrder = LayoutOrder or 999,
				--Parent = Window.Topbar.ButtonsType == "Default" and Window.UIElements.Main.Main.Topbar.Right or nil,
				--Active = true,
				ZIndex = 9999,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				ImageColor3 = Window.Topbar.ButtonsType ~= "Default" and (Color or Color3.fromHex("#ff3030")) or nil,
				ThemeTag = Window.Topbar.ButtonsType == "Default" and {
					ImageColor3 = "Text",
				} or nil,
				ImageTransparency = Window.Topbar.ButtonsType == "Default" and 1 or 0, -- .93
			},
			{
				--[[Creator.NewRoundFrame(
					Window.Topbar.ButtonsType == "Default" and Window.UICorner - (Window.UIPadding / 2) or 999,
					"Glass-1",
					{
						Size = UDim2.new(1, 0, 1, 0),
						ThemeTag = {
							ImageColor3 = "Outline",
						},
						ImageTransparency = Window.Topbar.ButtonsType == "Default" and 1 or 0.5, -- .75
						Name = "Outline",
					}
				),]]
				IconFrame,
				New("UIScale", {
					Scale = 1,
				}),
			},
			true
		)

		local ButtonContainer = New("Frame", {
			Size = Window.Topbar.ButtonsType ~= "Default" and UDim2.new(0, 24, 0, 24)
				or UDim2.new(0, Window.Topbar.Height - 16, 0, Window.Topbar.Height - 16),
			BackgroundTransparency = 1,
			Parent = Window.UIElements.Main.Main.Topbar.Right,
			LayoutOrder = LayoutOrder or 999,
		}, {
			Button,
		})

		-- shhh

		Window.TopBarButtons[100 - LayoutOrder] = {
			Name = Name,
			Object = ButtonContainer,
		}

		Creator.AddSignal(Button.MouseButton1Click, function()
			if Callback then
				Callback()
			end
		end)
		Creator.AddSignal(Button.MouseEnter, function()
			if Window.Topbar.ButtonsType == "Default" then
				Tween(Button, 0.15, { ImageTransparency = 0.93 }):Play()
				--Tween(Button.Outline, 0.15, { ImageTransparency = 0.75 }):Play()
				--Tween(IconFrame.ImageLabel, .15, {ImageTransparency = 0}):Play()
			else
				--Tween(Button, .1, {Size = UDim2.new(0,14+8,0,14+8)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				Tween(
					IconFrame.ImageLabel,
					0.1,
					{ ImageTransparency = 0 },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				):Play()
				Tween(IconFrame, 0.1, {
					Size = UDim2.new(
						0,
						IconSize or Window.TopBarButtonIconSize,
						0,
						IconSize or Window.TopBarButtonIconSize
					),
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end
		end)

		Creator.AddSignal(Button.MouseButton1Down, function()
			Tween(Button.UIScale, 0.2, { Scale = 0.9 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end)

		Creator.AddSignal(Button.MouseLeave, function()
			if Window.Topbar.ButtonsType == "Default" then
				Tween(Button, 0.1, { ImageTransparency = 1 }):Play()
				--Tween(Button.Outline, 0.1, { ImageTransparency = 1 }):Play()
				--Tween(IconFrame.ImageLabel, .1, {ImageTransparency = .2}):Play()
			else
				--Tween(Button, .1, {Size = UDim2.new(0,14,0,14)}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
				Tween(
					IconFrame.ImageLabel,
					0.1,
					{ ImageTransparency = 1 },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				):Play()
				Tween(
					IconFrame,
					0.1,
					{ Size = UDim2.new(0, 0, 0, 0) },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				):Play()
			end
		end)

		Creator.AddSignal(Button.InputEnded, function()
			Tween(Button.UIScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
		end)

		return Button
	end

	function Window.Topbar:Button(ButtonConfig: {
		Name: string,
		Icon: string,
		Callback: any,
		LayoutOrder: number,
		IconThemed: boolean,
		Color: Color3,
		IconSize: number,
	})
		return Window:CreateTopbarButton(
			ButtonConfig.Name,
			ButtonConfig.Icon,
			ButtonConfig.Callback,
			ButtonConfig.LayoutOrder or 0,
			ButtonConfig.IconThemed,
			ButtonConfig.Color,
			ButtonConfig.IconSize
		)
	end

	-- local Dragged = false

	local WindowDragModule = Creator.Drag(
		Window.UIElements.Main,
		{ Window.UIElements.Main.Main.Topbar, BottomDragFrame.Frame },
		function(dragging, frame) -- On drag
			if not Window.Closed then
				if dragging and frame == BottomDragFrame.Frame then
					Tween(BottomDragFrame, 0.1, { ImageTransparency = 0.35 }):Play()
				else
					Tween(BottomDragFrame, 0.2, { ImageTransparency = 0.8 }):Play()
				end
				Window.Position = Window.UIElements.Main.Position
				Window.Dragging = dragging
			end
		end
	)

	if not IsVideoBG and Window.Background and typeof(Window.Background) == "table" then
		local BackgroundGradient = New("UIGradient")
		for key, value in next, Window.Background do
			BackgroundGradient[key] = value
		end

		Window.UIElements.BackgroundGradient = Creator.NewRoundFrame(Window.UICorner, "Squircle", {
			Size = UDim2.new(1, 0, 1, 0),
			Parent = Window.UIElements.Main.Background,
			ImageTransparency = Window.Transparent and Config.ForktUI.TransparencyValue or 0,
		}, {
			BackgroundGradient,
		})
	end

	-- local blur = require("../Blur")

	-- blur.new(Window.UIElements.Main.Background, {
	--     Corner = Window.UICorner
	-- })

	--Creator.Blur(Window.UIElements.Main.Background)
	-- local OpenButtonDragModule

	-- if not Window.IsPC then
	--     OpenButtonDragModule = Creator.Drag(OpenButtonContainer)
	-- end

	Window.OpenButtonMain = require("./Openbutton").New(Window)

	task.spawn(function()
		if Window.Icon then
			local WindowIconContainer = New("Frame", {
				Size = UDim2.new(0, 22, 0, 22),
				BackgroundTransparency = 1,
				Parent = Window.UIElements.Main.Main.Topbar.Left,
			})

			WindowIcon = Creator.Image(
				Window.Icon,
				Window.Title,
				Window.IconRadius,
				Window.Folder,
				"Window",
				true,
				Window.IconThemed,
				"WindowTopbarIcon"
			)
			WindowIcon.Parent = WindowIconContainer
			WindowIcon.Size = UDim2.new(0, Window.IconSize, 0, Window.IconSize)
			WindowIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			WindowIcon.AnchorPoint = Vector2.new(0.5, 0.5)

			Window.OpenButtonMain:SetIcon(Window.Icon)

			-- if Creator.Icon(tostring(Window.Icon)) and Creator.Icon(tostring(Window.Icon))[1] then
			--     -- ImageLabel.Image = Creator.Icon(Window.Icon)[1]
			--     -- ImageLabel.ImageRectOffset = Creator.Icon(Window.Icon)[2].ImageRectPosition
			--     -- ImageLabel.ImageRectSize = Creator.Icon(Window.Icon)[2].ImageRectSize
			--     -- OpenButtonIcon.Image = Creator.Icon(Window.Icon)[1]
			--     -- OpenButtonIcon.ImageRectOffset = Creator.Icon(Window.Icon)[2].ImageRectPosition
			--     -- OpenButtonIcon.ImageRectSize = Creator.Icon(Window.Icon)[2].ImageRectSize

			-- end
			-- end
		else
			Window.OpenButtonMain:SetIcon(Window.Icon)
			--OpenButtonIcon.Visible = false
		end
	end)

	function Window:SetToggleKey(keycode)
		Window.ToggleKey = keycode
	end

	function Window:SetTitle(text)
		Window.Title = text
		WindowTitle.Text = text
	end

	function Window:SetAuthor(text)
		Window.Author = text
		if not WindowAuthor then
			WindowAuthor = createAuthor(Window.Author)
		end

		WindowAuthor.Text = text
	end

	function Window:SetSize(size)
		if typeof(size) == "UDim2" then
			Window.Size = size

			Tween(Window.UIElements.Main, 0.08, { Size = size }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end
	end

	function Window:SetBackgroundImage(id)
		Window.UIElements.Main.Background.ImageLabel.Image = id
	end
	function Window:SetBackgroundImageTransparency(v)
		if BGImage and BGImage:IsA("ImageLabel") then
			BGImage.ImageTransparency = math.floor(v * 10 + 0.5) / 10
		end
		Window.BackgroundImageTransparency = math.floor(v * 10 + 0.5) / 10
	end

	function Window:SetBackgroundTransparency(v)
		local rounded = math.floor(tonumber(v) * 10 + 0.5) / 10
		Config.ForktUI.TransparencyValue = rounded
		Window:ToggleTransparency(rounded > 0)
	end

	local CurrentPos
	local CurrentSize
	local iconCopy = Creator.Icon("minimize")
	local iconSquare = Creator.Icon("maximize")

	local FullscreenButton = Window:CreateTopbarButton(
		"Fullscreen",
		Window.Topbar.ButtonsType == "Mac" and "rbxassetid://127426072704909" or "maximize",
		function()
			Window:ToggleFullscreen()
		end,
		(Window.Topbar.ButtonsType == "Default" and 998 or 999),
		true,
		Color3.fromHex("#60C762"),
		Window.Topbar.ButtonsType == "Mac" and 9 or nil
	)

	local function SetSize(isAnimation)
		Tween(Window.UIElements.Main, 0.45, {
			Size = not Window.IsFullscreen and CurrentSize or UDim2.new(
				0,
				(Config.ForktUI.ScreenGui.AbsoluteSize.X - 20) / Config.ForktUI.UIScale,
				0,
				(Config.ForktUI.ScreenGui.AbsoluteSize.Y - 20 - 52) / Config.ForktUI.UIScale
			),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

		Tween(
			Window.UIElements.Main,
			0.45,
			{ Position = not Window.IsFullscreen and CurrentPos or UDim2.new(0.5, 0, 0.5, 52 / 2) },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		):Play()
	end

	function Window:ToggleFullscreen()
		local isFullscreen = Window.IsFullscreen
		-- Creator.SetDraggable(isFullscreen)
		WindowDragModule:Set(isFullscreen)

		if not isFullscreen then
			CurrentPos = Window.UIElements.Main.Position
			CurrentSize = Window.UIElements.Main.Size

			Window.CanResize = false
		else
			if Window.Resizable then
				Window.CanResize = true
			end
		end

		Window.IsFullscreen = not isFullscreen

		SetSize(true)
	end

	Creator.AddSignal(Config.ForktUI.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), function()
		if Window.IsFullscreen then
			SetSize()
		end
	end)

	Window:CreateTopbarButton("Minimize", "minus", function()
		if Window.Close then
			Window:Close()
		end
		-- task.spawn(function()
		--     task.wait(.3)
		--     if not Window.IsPC and Window.IsOpenButtonEnabled then
		--         -- OpenButtonContainer.Visible = true
		--         --Window.OpenButtonMain:Visible(true)
		--     end
		-- end)

		-- local NotifiedText = Window.IsPC and "Press " .. Window.ToggleKey.Name .. " to open the Window" or "Click the Button to open the Window"

		-- if not Window.IsOpenButtonEnabled then
		--     Notified = true
		-- end
		-- if not Notified then
		--     Notified = not Notified
		--     Config.ForktUI:Notify({
		--         Title = "Minimize",
		--         Content = "You've closed the Window. " .. NotifiedText,
		--         Icon = "eye-off",
		--         Duration = 5,
		--     })
		-- end
	end, (Window.Topbar.ButtonsType == "Default" and 997 or 998), nil, Color3.fromHex("#F4C948"))

	function Window:OnOpen(func)
		Window.OnOpenCallback = func
	end
	function Window:OnClose(func)
		Window.OnCloseCallback = func
	end
	function Window:OnDestroy(func)
		Window.OnDestroyCallback = func
	end

	if Config.ForktUI.UseAcrylic then
		Window.AcrylicPaint.AddParent(Window.UIElements.Main)
	end

	function Window:SetIconSize(Size)
		local NewSize
		if typeof(Size) == "number" then
			NewSize = UDim2.new(0, Size, 0, Size)
			Window.IconSize = Size
		elseif typeof(Size) == "UDim2" then
			NewSize = Size
			Window.IconSize = Size.X.Offset
		end

		if WindowIcon then
			WindowIcon.Size = NewSize
		end
	end

	function Window:Open()
		if Window.Destroyed then
			return
		end
		task.spawn(function()
			if Window.OnOpenCallback then
				task.spawn(function()
					Creator.SafeCallback(Window.OnOpenCallback)
				end)
			end

			task.wait(0.06)
			Window.Closed = false

			Window.UIElements.Main.Size = UDim2.new(Window.Size.X.Scale, Window.Size.X.Offset, 0, 100)

			Tween(Window.UIElements.Main, 0.8, {
				--GroupTransparency = 0,
				Size = Window.Size,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

			if Window.UIElements.BackgroundGradient then
				Tween(Window.UIElements.BackgroundGradient, 0.2, {
					ImageTransparency = 0,
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end

			Window.UIElements.Main.Background.ImageTransparency = 1
			Tween(Window.UIElements.Main.Background, 0.4, {
				--Size = UDim2.new(1, 0, 1, 0),
				ImageTransparency = Window.Transparent and Config.ForktUI.TransparencyValue or 0,
			}, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out):Play()

			if BGImage then
				if BGImage:IsA("VideoFrame") then
					BGImage.Visible = true
				else
					Tween(BGImage, 0.2, {
						ImageTransparency = Window.BackgroundImageTransparency,
					}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
				end
			end

			if Window.OpenButtonMain and Window.IsOpenButtonEnabled then
				Window.OpenButtonMain:Visible(false)
			end

			--[[Config.ForktUI.UIScaleObj.Scale -= 1 - 0.85
			Tween(
				Config.ForktUI.UIScaleObj,
				0.33,
				{ Scale = Config.ForktUI.UIScale },
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			):Play()]]
			Tween(
				Blur,
				0.25,
				{ ImageTransparency = Window.ShadowTransparency },
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			):Play()
			--[[if UIStroke then
				Tween(UIStroke, 0.25, { Transparency = 0.8 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end]]

			Tween(
				BottomDragFrame,
				0.45,
				{ Size = UDim2.new(0, Window.DragFrameSize, 0, 4), ImageTransparency = 0.8 },
				Enum.EasingStyle.Exponential,
				Enum.EasingDirection.Out
			):Play()
			WindowDragModule:Set(true)

			if Window.Resizable then
				Tween(
					ResizeHandle.ImageLabel,
					0.45,
					{ ImageTransparency = 0.8 },
					Enum.EasingStyle.Exponential,
					Enum.EasingDirection.Out
				):Play()
				Window.CanResize = true
			end

			Window.CanDropdown = true
			Window.UIElements.Main.Visible = true
			--task.spawn(function()
			--task.wait(0.05)

			Window.UIElements.Main:WaitForChild("Main").Visible = true

			Config.ForktUI:ToggleAcrylic(true)
			--end)
		end)
	end
	function Window:Close()
		if Window.Destroyed then
			return
		end

		local Close = {}

		if Window.OnCloseCallback then
			task.spawn(function()
				Creator.SafeCallback(Window.OnCloseCallback)
			end)
		end

		Config.ForktUI:ToggleAcrylic(false)

		if Window.UIElements.Main and Window.UIElements.Main:WaitForChild("Main") then
			Window.UIElements.Main.Main.Visible = false
		end

		Window.CanDropdown = false
		Window.Closed = true

		Tween(Window.UIElements.Main, 0.9, {
			--GroupTransparency = 1,
			Size = UDim2.new(Window.Size.X.Scale, Window.Size.X.Offset, 0, 0),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		if Window.UIElements.BackgroundGradient then
			Tween(Window.UIElements.BackgroundGradient, 0.2, {
				ImageTransparency = 1,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut):Play()
		end

		Tween(Window.UIElements.Main.Background, 0.3, {
			--Size = UDim2.new(1, 0, 1, -240),
			ImageTransparency = 1,
		}, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut):Play()

		--[[Tween(
			Config.ForktUI.UIScaleObj,
			0.28,
			{ Scale = Config.ForktUI.UIScale - (1 - 0.85) },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		):Play()]]
		if BGImage then
			if BGImage:IsA("VideoFrame") then
				BGImage.Visible = false
			else
				Tween(BGImage, 0.3, {
					ImageTransparency = 1,
				}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
			end
		end
		Tween(Blur, 0.25, { ImageTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		--[[if UIStroke then
			Tween(UIStroke, 0.25, { Transparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end]]

		Tween(
			BottomDragFrame,
			0.3,
			{ Size = UDim2.new(0, 0, 0, 4), ImageTransparency = 1 },
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.InOut
		):Play()
		Tween(
			ResizeHandle.ImageLabel,
			0.3,
			{ ImageTransparency = 1 },
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
		):Play()
		WindowDragModule:Set(false)
		Window.CanResize = false

		task.spawn(function()
			task.wait(0.4)

			if not Window.Closed then
				return
			end

			Window.UIElements.Main.Visible = false

			if Window.OpenButtonMain and not Window.Destroyed and not Window.IsPC and Window.IsOpenButtonEnabled then
				Window.OpenButtonMain:Visible(true)
			end
		end)

		function Close:Destroy()
			task.spawn(function()
				if Window.OnDestroyCallback then
					task.spawn(function()
						Creator.SafeCallback(Window.OnDestroyCallback)
					end)
				end

				if Window.AcrylicPaint and Window.AcrylicPaint.Model then
					Window.AcrylicPaint.Model:Destroy()
				end

				Window.Destroyed = true

				task.wait(0.4)

				Config.ForktUI.ScreenGui:Destroy()
				Config.ForktUI.NotificationGui:Destroy()
				Config.ForktUI.DropdownGui:Destroy()
				Config.ForktUI.TooltipGui:Destroy()

				Creator.DisconnectAll()

				return
			end)
		end

		return Close
	end
	function Window:Destroy()
		return Window:Close():Destroy()
	end
	function Window:Toggle()
		if Window.Closed then
			Window:Open()
		else
			Window:Close()
		end
	end

	function Window:ToggleTransparency(Value)
		-- Config.Transparent = Value
		Window.Transparent = Value
		Config.ForktUI.Transparent = Value

		Window.UIElements.Main.Background.ImageTransparency = Value and Config.ForktUI.TransparencyValue or 0
		-- Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and Config.ForktUI.TransparencyValue or 0
		--Window.UIElements.MainBar.Background.ImageTransparency = Value and 0.97 or 0.95
	end

	function Window:LockAll()
		for _, element in next, Window.AllElements do
			if element.Lock then
				element:Lock()
			end
		end
	end
	function Window:UnlockAll()
		for _, element in next, Window.AllElements do
			if element.Unlock then
				element:Unlock()
			end
		end
	end
	function Window:GetLocked()
		local LockedElements = {}

		for _, element in next, Window.AllElements do
			if element.Locked then
				table.insert(LockedElements, element)
			end
		end

		return LockedElements
	end
	function Window:GetUnlocked()
		local UnlockedElements = {}

		for _, element in next, Window.AllElements do
			if element.Locked == false then
				table.insert(UnlockedElements, element)
			end
		end

		return UnlockedElements
	end

	function Window:GetUIScale(v)
		return Config.ForktUI.UIScale
	end

	function Window:SetUIScale(v)
		Config.ForktUI.UIScale = v
		Tween(Config.ForktUI.UIScaleObj, 0.2, { Scale = v }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		return Window
	end

	function Window:SetToTheCenter()
		Tween(
			Window.UIElements.Main,
			0.45,
			{ Position = UDim2.new(0.5, 0, 0.5, 0) },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		):Play()
		return Window
	end

	function Window:SetCurrentConfig(ConfigModule)
		Window.CurrentConfig = ConfigModule
	end

	local function ApplyAutoScale()
		if not Window.AutoScale then
			return
		end

		local camera = workspace.CurrentCamera or CurrentCamera
		if not camera then
			return
		end
		CurrentCamera = camera

		local viewport = camera.ViewportSize
		if viewport.X <= 0 or viewport.Y <= 0 then
			return
		end

		local margin = math.clamp(math.min(viewport.X, viewport.Y) * 0.035, 12, 32)
		local baseWidth = math.max(Window.Size.X.Offset, 1)
		local baseHeight = math.max(Window.Size.Y.Offset, 1)
		local availableWidth = math.max(viewport.X - margin * 2, 1)
		local availableHeight = math.max(viewport.Y - margin * 2, 1)
		local requiredScale = math.min(availableWidth / baseWidth, availableHeight / baseHeight)
		local finalScale = math.clamp(requiredScale, 0.3, 1)
		local currentScale = Window:GetUIScale() or 1

		if math.abs(finalScale - currentScale) > 0.025 then
			Window:SetUIScale(finalScale)
		end
	end

	local cameraViewportConnection
	local function BindCamera(camera)
		if cameraViewportConnection then
			cameraViewportConnection:Disconnect()
			cameraViewportConnection = nil
		end
		CurrentCamera = camera
		if camera then
			cameraViewportConnection = Creator.AddSignal(camera:GetPropertyChangedSignal("ViewportSize"), ApplyAutoScale)
		end
		ApplyAutoScale()
	end

	Creator.AddSignal(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		BindCamera(workspace.CurrentCamera)
	end)
	BindCamera(workspace.CurrentCamera or CurrentCamera)

	if Window.OpenButtonMain and Window.OpenButtonMain.Button then
		Creator.AddSignal(Window.OpenButtonMain.Button.TextButton.MouseButton1Click, function()
			-- OpenButtonContainer.Visible = false
			--Window.OpenButtonMain:Visible(false)
			Window:Open()
		end)
	end

	Creator.AddSignal(UserInputService.InputBegan, function(input, isProcessed)
		if isProcessed then
			return
		end

		if Window.ToggleKey then
			if input.KeyCode == Window.ToggleKey then
				Window:Toggle()
			end
		end
	end)

	task.spawn(function()
		--task.wait(1.38583)
		Window:Open()
	end)

	function Window:EditOpenButton(OpenButtonConfig)
		return Window.OpenButtonMain:Edit(OpenButtonConfig)
	end

	if Window.OpenButton and typeof(Window.OpenButton) == "table" then
		Window:EditOpenButton(Window.OpenButton)
	end

	local TabModuleMain = require("./Tab")
	local SectionModule = require("./Section")
	local TabModule = TabModuleMain.Init(Window, Config.ForktUI, Config.ForktUI.TooltipGui)
	TabModule:OnChange(function(t)
		Window.CurrentTab = t
	end)

	Window.TabModule = TabModule

	function Window:Tab(TabConfig)
		TabConfig.Parent = Window.UIElements.SideBar.Frame
		return TabModule.New(TabConfig, Config.ForktUI.UIScale)
	end

	function Window:SelectTab(Tab)
		TabModule:SelectTab(Tab)
	end

	function Window:Section(SectionConfig)
		return SectionModule.New(
			SectionConfig,
			Window.UIElements.SideBar.Frame,
			Window.Folder,
			Config.ForktUI.UIScale,
			Window
		)
	end

	function Window:IsResizable(v)
		Window.Resizable = v
		Window.CanResize = v
	end

	function Window:SetPanelBackground(v)
		if typeof(v) == "boolean" then
			Window.HidePanelBackground = v

			Window.UIElements.MainBar.Background.Visible = v

			if TabModule then
				for _, Container in next, TabModule.Containers do
					Container.ScrollingFrame.UIPadding.PaddingTop = UDim.new(0, Window.HidePanelBackground and 20 or 10)
					Container.ScrollingFrame.UIPadding.PaddingLeft =
						UDim.new(0, Window.HidePanelBackground and 20 or 10)
					Container.ScrollingFrame.UIPadding.PaddingRight =
						UDim.new(0, Window.HidePanelBackground and 20 or 10)
					Container.ScrollingFrame.UIPadding.PaddingBottom =
						UDim.new(0, Window.HidePanelBackground and 20 or 10)
				end
			end
		end
	end

	function Window:Divider()
		local Divider = New("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 0.9,
			ThemeTag = {
				BackgroundColor3 = "Text",
			},
		})
		local MainDivider = New("Frame", {
			Parent = Window.UIElements.SideBar.Frame,
			--AutomaticSize = "Y",
			Size = UDim2.new(1, -7, 0, 5),
			BackgroundTransparency = 1,
		}, {
			Divider,
		})

		return MainDivider
	end

	local DialogModule = require("./Dialog")
	function Window:Dialog(DialogConfig)
		local DialogTable = {
			Title = DialogConfig.Title or "Dialog",
			Width = DialogConfig.Width or 320,
			Content = DialogConfig.Content,
			Buttons = DialogConfig.Buttons or {},

			TextPadding = 14,
		}
		local Dialog = DialogModule.Create(false, "Dialog", Window, Config.ForktUI, Window.UIElements.Main.Main)

		Dialog.UIElements.Main.Size = UDim2.new(0, DialogTable.Width, 0, 0)

		local DialogTopColFrame = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = "Y",
			BackgroundTransparency = 1,
			Parent = Dialog.UIElements.Main,
		}, {
			New("UIListLayout", {
				FillDirection = "Vertical",
				--HorizontalAlignment = "Center",
				Padding = UDim.new(0, Dialog.UIPadding),
			}),
		})

		local DialogTopRowFrame = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = "Y",
			BackgroundTransparency = 1,
			Parent = DialogTopColFrame,
		}, {
			New("UIListLayout", {
				FillDirection = "Horizontal",
				Padding = UDim.new(0, Dialog.UIPadding),
				VerticalAlignment = "Center",
			}),
			New("UIPadding", {
				PaddingTop = UDim.new(0, DialogTable.TextPadding / 2),
				PaddingLeft = UDim.new(0, DialogTable.TextPadding / 2),
				PaddingRight = UDim.new(0, DialogTable.TextPadding / 2),
			}),
		})

		local Icon
		if DialogConfig.Icon then
			Icon = Creator.Image(
				DialogConfig.Icon,
				DialogTable.Title .. ":" .. DialogConfig.Icon,
				0,
				Window,
				"Dialog",
				true,
				DialogConfig.IconThemed
			)
			Icon.Size = UDim2.new(0, 22, 0, 22)
			Icon.Parent = DialogTopRowFrame
		end

		Dialog.UIElements.UIListLayout = New("UIListLayout", {
			Padding = UDim.new(0, 12),
			FillDirection = "Vertical",
			HorizontalAlignment = "Left",
			VerticalFlex = "SpaceBetween",
			Parent = Dialog.UIElements.Main,
		})

		New("UISizeConstraint", {
			MinSize = Vector2.new(180, 20),
			MaxSize = Vector2.new(400, math.huge),
			Parent = Dialog.UIElements.Main,
		})

		Dialog.UIElements.Title = New("TextLabel", {
			Text = DialogTable.Title,
			TextSize = 20,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
			TextXAlignment = "Left",
			TextWrapped = true,
			RichText = true,
			Size = UDim2.new(1, Icon and -26 - Dialog.UIPadding or 0, 0, 0),
			AutomaticSize = "Y",
			ThemeTag = {
				TextColor3 = "Text",
			},
			BackgroundTransparency = 1,
			Parent = DialogTopRowFrame,
		})
		if DialogTable.Content then
			local Content = New("TextLabel", {
				Text = DialogTable.Content,
				TextSize = 18,
				TextTransparency = 0.4,
				TextWrapped = true,
				RichText = true,
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				TextXAlignment = "Left",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = "Y",
				LayoutOrder = 2,
				ThemeTag = {
					TextColor3 = "Text",
				},
				BackgroundTransparency = 1,
				Parent = DialogTopColFrame,
			}, {
				New("UIPadding", {
					PaddingLeft = UDim.new(0, DialogTable.TextPadding / 2),
					PaddingRight = UDim.new(0, DialogTable.TextPadding / 2),
					PaddingBottom = UDim.new(0, DialogTable.TextPadding / 2),
				}),
			})
		end

		local ButtonsLayout = New("UIListLayout", {
			Padding = UDim.new(0, 6),
			FillDirection = "Horizontal",
			HorizontalAlignment = "Center",
			HorizontalFlex = "Fill",
		})

		local ButtonsContent = New("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			AutomaticSize = "None",
			BackgroundTransparency = 1,
			Parent = Dialog.UIElements.Main,
			LayoutOrder = 4,
		}, {
			ButtonsLayout,
			-- New("UIPadding", {
			--     PaddingTop = UDim.new(0, DialogTable.TextPadding/2),
			--     PaddingLeft = UDim.new(0, DialogTable.TextPadding/2),
			--     PaddingRight = UDim.new(0, DialogTable.TextPadding/2),
			--     PaddingBottom = UDim.new(0, DialogTable.TextPadding/2),
			-- })
		})

		local Buttons = {}

		for _, Button in next, DialogTable.Buttons do
			local ButtonFrame =
				CreateButton(Button.Title, Button.Icon, Button.Callback, Button.Variant, ButtonsContent, Dialog, true)
			table.insert(Buttons, ButtonFrame)
			ButtonFrame.Size = UDim2.new(1, 0, 1, 0)
		end

		local function CheckButtonsOverflow()
			ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
			ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			ButtonsContent.AutomaticSize = Enum.AutomaticSize.None

			for _, button in ipairs(Buttons) do
				button.Size = UDim2.new(0, 0, 1, 0)
				button.AutomaticSize = Enum.AutomaticSize.X
			end

			wait()

			local totalWidth = ButtonsLayout.AbsoluteContentSize.X / Config.ForktUI.UIScale
			local parentWidth = ButtonsContent.AbsoluteSize.X / Config.ForktUI.UIScale

			if totalWidth > parentWidth then
				ButtonsLayout.FillDirection = Enum.FillDirection.Vertical
				ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
				ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
				ButtonsContent.AutomaticSize = Enum.AutomaticSize.Y

				for _, button in ipairs(Buttons) do
					button.Size = UDim2.new(1, 0, 0, 36)
					button.AutomaticSize = Enum.AutomaticSize.None
				end
			else
				local availableSpace = parentWidth - totalWidth
				if availableSpace > 0 then
					local smallestButton = nil
					local smallestWidth = math.huge

					for _, button in ipairs(Buttons) do
						local buttonWidth = button.AbsoluteSize.X / Config.ForktUI.UIScale
						if buttonWidth < smallestWidth then
							smallestWidth = buttonWidth
							smallestButton = button
						end
					end

					if smallestButton then
						smallestButton.Size = UDim2.new(0, smallestWidth + availableSpace, 1, 0)
						smallestButton.AutomaticSize = Enum.AutomaticSize.None
					end
				end
			end
		end

		-- Creator.AddSignal(Dialog.UIElements.Main:GetPropertyChangedSignal("AbsoluteSize"), CheckButtonsOverflow)
		-- CheckButtonsOverflow()

		-- wait()
		Dialog:Open()

		return Dialog
	end

	local ClickedClose = false

	Window:CreateTopbarButton("Close", "x", function()
		if not ClickedClose then
			if not Window.IgnoreAlerts then
				ClickedClose = true
				--Window:SetToTheCenter()
				Window:Dialog({
					--Icon = "trash-2",
					Title = "Close Window",
					Content = "Do you want to close this window? You will not be able to open it again.",
					Buttons = {
						{
							Title = "Cancel",
							--Icon = "chevron-left",
							Callback = function()
								ClickedClose = false
							end,
							Variant = "Secondary",
						},
						{
							Title = "Close Window",
							--Icon = "chevron-down",
							Callback = function()
								ClickedClose = false
								Window:Destroy()
							end,
							Variant = "Primary",
						},
					},
				})
			else
				Window:Destroy()
			end
		end
	end, (Window.Topbar.ButtonsType == "Default" and 999 or 997), nil, Color3.fromHex("#F4695F"))

	function Window:Tag(TagConfig)
		if Window.UIElements.Main.Main.Topbar.Center.Visible == false then
			Window.UIElements.Main.Main.Topbar.Center.Visible = true
		end
		TagConfig.Window = Window
		return Tag:New(TagConfig, Window.UIElements.Main.Main.Topbar.Center.Holder)
	end

	local CurResizeInput = Config.ForktUI.GenerateGUID()

	local function startResizing(input)
		if Window.CanResize then
			isResizing = true
			FullScreenIcon.Active = true
			initialSize = Window.UIElements.Main.Size
			initialInputPosition = input.Position
			--Tween(FullScreenIcon, 0.12, {ImageTransparency = .65}):Play()
			--Tween(FullScreenIcon.ImageLabel, 0.12, {ImageTransparency = 0}):Play()
			Tween(ResizeHandle.ImageLabel, 0.1, { ImageTransparency = 0.35 }):Play()

			Creator.AddSignal(input.Changed, function()
				if input.UserInputState == Enum.UserInputState.End then
					if Config.ForktUI.CurrentInput and Config.ForktUI.CurrentInput ~= CurResizeInput then
						return
					end

					Config.ForktUI.CurrentInput = nil

					isResizing = false
					FullScreenIcon.Active = false
					--Tween(FullScreenIcon, 0.2, {ImageTransparency = 1}):Play()
					--Tween(FullScreenIcon.ImageLabel, 0.17, {ImageTransparency = 1}):Play()
					Tween(ResizeHandle.ImageLabel, 0.17, { ImageTransparency = 0.8 }):Play()
				end
			end)
		end
	end

	Creator.AddSignal(ResizeHandle.InputBegan, function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if Config.ForktUI.CurrentInput and Config.ForktUI.CurrentInput ~= CurResizeInput then
				return
			end
			Config.ForktUI.CurrentInput = CurResizeInput

			if Window.CanResize then
				startResizing(input)
			end
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if isResizing and Window.CanResize then
				local delta = input.Position - initialInputPosition
				local newSize = UDim2.new(0, initialSize.X.Offset + delta.X * 2, 0, initialSize.Y.Offset + delta.Y * 2)

				newSize = UDim2.new(
					newSize.X.Scale,
					math.clamp(newSize.X.Offset, Window.MinSize.X, Window.MaxSize.X),
					newSize.Y.Scale,
					math.clamp(newSize.Y.Offset, Window.MinSize.Y, Window.MaxSize.Y)
				)

				Tween(Window.UIElements.Main, 0.08, {
					Size = newSize,
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()

				Window.Size = newSize
			end
		end
	end)

	Creator.AddSignal(ResizeHandle.MouseEnter, function()
		if Config.ForktUI.CurrentInput and Config.ForktUI.CurrentInput ~= CurResizeInput then
			return
		end
		if not isResizing then
			Tween(ResizeHandle.ImageLabel, 0.1, { ImageTransparency = 0.35 }):Play()
		end
	end)
	Creator.AddSignal(ResizeHandle.MouseLeave, function()
		if Config.ForktUI.CurrentInput and Config.ForktUI.CurrentInput ~= CurResizeInput then
			return
		end
		if not isResizing then
			Tween(ResizeHandle.ImageLabel, 0.17, { ImageTransparency = 0.8 }):Play()
		end
	end)

	-- / Double click /

	local LastUpTime = 0
	local DoubleClickWindow = 0.4
	local InitialPosition = nil
	local ClickCount = 0

	function onDoubleClick()
		Window:SetToTheCenter()
	end

	Creator.AddSignal(BottomDragFrame.Frame.MouseButton1Up, function()
		local currentTime = tick()
		local currentPosition = Window.Position

		ClickCount = ClickCount + 1

		if ClickCount == 1 then
			LastUpTime = currentTime
			InitialPosition = currentPosition

			task.spawn(function()
				task.wait(DoubleClickWindow)
				if ClickCount == 1 then
					ClickCount = 0
					InitialPosition = nil
				end
			end)
		elseif ClickCount == 2 then
			if currentTime - LastUpTime <= DoubleClickWindow and currentPosition == InitialPosition then
				onDoubleClick()
			end

			ClickCount = 0
			InitialPosition = nil
			LastUpTime = 0
		else
			ClickCount = 1
			LastUpTime = currentTime
			InitialPosition = currentPosition
		end
	end)

	-- / Search Bar /

	if not Window.HideSearchBar then
		local SearchBar = require("../search/Init")
		local IsOpen = false
		local CurrentSearchBar

		-- local SearchButton
		-- SearchButton = Window:CreateTopbarButton("search", function()
		--     if IsOpen then return end

		--     SearchBar.new(Window.TabModule, Window.UIElements.Main, function()
		--         -- OnClose
		--         IsOpen = false
		--         Window.CanResize = true

		--         Tween(FullScreenBlur, 0.1, {ImageTransparency = 1}):Play()
		--         FullScreenBlur.Active = false
		--     end)
		--     Tween(FullScreenBlur, 0.1, {ImageTransparency = .65}):Play()
		--     FullScreenBlur.Active = true

		--     IsOpen = true
		--     Window.CanResize = false
		-- end, 996)

		local SearchLabel = CreateLabel("Search", "search", Window.UIElements.SideBarContainer, true)
		SearchLabel.Size = UDim2.new(1, -Window.UIPadding / 2, 0, 39)
		SearchLabel.Position = UDim2.new(0, Window.UIPadding / 2, 0,--[[Window.UIPadding/2]] 0)

		Creator.AddSignal(SearchLabel.MouseButton1Click, function()
			if IsOpen then
				return
			end

			SearchBar.new(Window.TabModule, Window.UIElements.Main, function()
				-- OnClose
				IsOpen = false
				if Window.Resizable then
					Window.CanResize = true
				end

				Tween(FullScreenBlur, 0.1, { ImageTransparency = 1 }):Play()
				FullScreenBlur.Active = false
			end)
			Tween(FullScreenBlur, 0.1, { ImageTransparency = 0.65 }):Play()
			FullScreenBlur.Active = true

			IsOpen = true
			Window.CanResize = false
		end)
	end

	-- / TopBar Edit /

	function Window:DisableTopbarButtons(btns)
		for _, b in next, btns do
			for _, i in next, Window.TopBarButtons do
				if i.Name == b then
					i.Object.Visible = false
				end
			end
		end
	end

	-- local Bindings = {
	--     Title = function(v)
	--         Window:SetTitle(v)
	--     end,
	--     Author = function(v)
	--         Window:SetAuthor(v)
	--     end,
	--     Size = function(v)
	--         Window:SetSize(v)
	--     end,
	--     HidePanelBackground  = function(v)
	--         Window:SetPanelBackground(v)
	--     end
	-- }

	-- setmetatable(Window, {
	--     __newindex = function(t, key, value)
	--         rawset(t, key, value)

	--         local bind = bindings[key]
	--         if bind then
	--             bind(value)
	--         end
	--     end
	-- })

	return Window
end
