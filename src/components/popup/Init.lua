local PopupModule = {}

local Creator = require("../../modules/Creator")
local New = Creator.New

function PopupModule.new(PopupConfig, Parent)
	if type(PopupConfig) ~= "table" then
		error("ForktUI.Popup: expected a configuration table", 2)
	end

	local fork = PopupConfig.ForktUI
	if type(fork) ~= "table" or type(fork.Window) ~= "table" then
		error("ForktUI.Popup: create a window before opening a popup", 2)
	end

	local popup = {
		Title = tostring(PopupConfig.Title or "Notice"),
		Content = PopupConfig.Content == nil and "" or tostring(PopupConfig.Content),
		Icon = PopupConfig.Icon,
		IconThemed = PopupConfig.IconThemed,
		Thumbnail = type(PopupConfig.Thumbnail) == "table" and PopupConfig.Thumbnail or nil,
		Buttons = type(PopupConfig.Buttons) == "table" and PopupConfig.Buttons or {},
	}

	local viewportWidth = 390
	pcall(function()
		local camera = workspace.CurrentCamera
		if camera then
			viewportWidth = camera.ViewportSize.X
		end
	end)

	local width = math.clamp(viewportWidth - 24, 240, 440)
	local thumbnailSize = popup.Thumbnail and popup.Thumbnail.Image and math.clamp(math.floor(width * 0.24), 64, 88) or 0
	local dialog = require("../window/Dialog").Create(true, "Popup", fork.Window, fork, Parent)
	local main = dialog.UIElements.Main
	main.Size = UDim2.new(0, width, 0, 0)
	main.AutomaticSize = Enum.AutomaticSize.Y
	main.ClipsDescendants = false

	New("UIPadding", {
		PaddingTop = UDim.new(0, 18),
		PaddingBottom = UDim.new(0, 18),
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
		Parent = main,
	})

	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 14),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Parent = main,
	})

	local iconFrame
	if popup.Icon then
		iconFrame = Creator.Image(
			popup.Icon,
			popup.Title .. ":" .. tostring(popup.Icon),
			0,
			fork.Window,
			"Popup",
			true,
			popup.IconThemed,
			"PopupIcon"
		)
		iconFrame.Size = UDim2.fromOffset(22, 22)
	end

	local title = New("TextLabel", {
		Name = "PopupTitle",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Text = popup.Title,
		ThemeTag = { TextColor3 = "PopupTitle" },
		TextSize = 18,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
		LayoutOrder = 2,
	})

	local titleContentChildren = {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	if iconFrame then
		iconFrame.LayoutOrder = 0
		table.insert(titleContentChildren, iconFrame)
	end
	table.insert(titleContentChildren, New("Frame", {
		Name = "TitleTextHolder",
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -(iconFrame and 34 or 0), 0, 0),
	}, {
		title,
	}))

	local titleContent = New("Frame", {
		Name = "PopupTitleContent",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -thumbnailSize - (thumbnailSize > 0 and 12 or 0), 0, 0),
		LayoutOrder = 1,
	}, titleContentChildren)

	local titleChildren = { titleContent }
	if thumbnailSize > 0 then
		local avatar = New("ImageLabel", {
			Name = "PopupThumbnail",
			BackgroundColor3 = Color3.fromRGB(35, 38, 44),
			BackgroundTransparency = 0,
			Image = tostring(popup.Thumbnail.Image),
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromOffset(thumbnailSize, thumbnailSize),
			ClipsDescendants = true,
			LayoutOrder = 0,
		}, {
			New("UICorner", { CornerRadius = UDim.new(0, 12) }),
		})
		table.insert(titleChildren, 1, avatar)

		if popup.Thumbnail.Title and tostring(popup.Thumbnail.Title) ~= "" then
			New("TextLabel", {
				Name = "PopupThumbnailTitle",
				BackgroundTransparency = 1,
				Text = tostring(popup.Thumbnail.Title),
				TextColor3 = Color3.fromRGB(238, 240, 244),
				TextSize = 11,
				TextWrapped = true,
				Size = UDim2.new(1, -12, 0, 30),
				Position = UDim2.new(0, 6, 1, -36),
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				Parent = avatar,
			})
		end
	end

	local titleContainer = New("Frame", {
		Name = "PopupHeader",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = main,
	}, titleChildren)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = titleContainer,
	})

	if popup.Content ~= "" then
		New("TextLabel", {
			Name = "PopupDescription",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Text = popup.Content,
			ThemeTag = { TextColor3 = "PopupContent" },
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			RichText = true,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			LayoutOrder = 2,
			Parent = main,
		})
	end

	if #popup.Buttons > 0 then
		local verticalActions = width < 360 or #popup.Buttons > 2
		local actionGap = 8
		local actionHeight = 40
		local actionsContainer = New("Frame", {
			Name = "PopupActions",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, verticalActions and (#popup.Buttons * actionHeight + (#popup.Buttons - 1) * actionGap) or actionHeight),
			LayoutOrder = 3,
			Parent = main,
		}, {
			New("UIListLayout", {
				FillDirection = verticalActions and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, actionGap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		local createButton = require("../ui/Button").New
		for index, buttonConfig in ipairs(popup.Buttons) do
			if type(buttonConfig) == "table" then
				local actionButton = createButton(
					buttonConfig.Title,
					buttonConfig.Icon,
					buttonConfig.Callback,
					buttonConfig.Variant,
					actionsContainer,
					dialog
				)
				actionButton.LayoutOrder = index
				if verticalActions then
					actionButton.AutomaticSize = Enum.AutomaticSize.None
					actionButton.Size = UDim2.new(1, 0, 0, actionHeight)
				end
			end
		end
	end

	dialog:Open()
	return popup
end

return PopupModule
