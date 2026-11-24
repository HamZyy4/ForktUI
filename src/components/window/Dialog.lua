local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

-- local Window
-- local ForktUI

local DialogModule = {
	Holder = nil,
	--Window = nil,
	Parent = nil,
}

function DialogModule.Create(Key, Type, Window, ForktUI, Parent)
	local Dialog = {
		UICorner = 28,
		UIPadding = 12,

		Window = Window,
		ForktUI = ForktUI,

		UIElements = {},
		Closed = false,
	}

	if Key then
		Dialog.UIPadding = 0
	end -- 16
	if Key then
		Dialog.UICorner = 26
	end

	Type = Type or "Dialog"

	local viewportWidth = 390
	pcall(function()
		local camera = workspace.CurrentCamera
		if camera then
			viewportWidth = camera.ViewportSize.X
		end
	end)
	local dialogWidth = math.clamp(viewportWidth - 24, 240, 460)

	if not Key then
		Dialog.UIElements.FullScreen = New("Frame", {
			Name = "DialogBackdrop",
			ZIndex = 999,
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromHex("#000000"),
			Size = UDim2.new(1, 0, 1, 0),
			Active = true,
			Visible = false,
			Parent = DialogModule.Parent
				or (Window and Window.UIElements and Window.UIElements.Main and Window.UIElements.Main.Main),
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})

		Dialog.UIElements.BackdropButton = New("TextButton", {
			Name = "BackdropButton",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 999,
			Parent = Dialog.UIElements.FullScreen,
		})
	end

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

	Dialog.UIElements.Main = New("Frame", {
		Size = UDim2.new(0, dialogWidth, 0, 0),
		ThemeTag = {
			BackgroundColor3 = Type .. "Background",
		},
		AutomaticSize = "Y",
		BackgroundTransparency = 1, -- .7
		Visible = false,
		ZIndex = 99999,
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, Dialog.UIPadding),
			PaddingLeft = UDim.new(0, Dialog.UIPadding),
			PaddingRight = UDim.new(0, Dialog.UIPadding),
			PaddingBottom = UDim.new(0, Dialog.UIPadding),
		}),
	})

	Dialog.UIElements.MainContainer = Creator.NewRoundFrame(Dialog.UICorner, "Squircle", {
		Visible = false, -- true
		--GroupTransparency = 1, -- 0
		ImageTransparency = Key and 0.15 or 0,
		Parent = Parent or Dialog.UIElements.FullScreen,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = "XY",
		ThemeTag = {
			ImageColor3 = Type .. "Background",
			ImageTransparency = Type .. "BackgroundTransparency",
		},
		ZIndex = 9999,
	}, {
		--[[Creator.NewRoundFrame(Dialog.UICorner, "SquircleGlass", {
			ImageTransparency = 0.92,
			Size = UDim2.new(1, 2, 1, 2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		}),]]
		Dialog.UIElements.Main,

		-- New("UIScale", {
		--     Scale = .9
		-- }),
		-- Creator.NewRoundFrame(Dialog.UICorner, "SquircleOutline2", {
		--     Size = UDim2.new(1,0,1,0),
		--     ImageTransparency = 1,
		--     ThemeTag = {
		--         ImageColor3 = "Outline",
		--     },
		-- }, {
		--     New("UIGradient", {
		--         Rotation = 45,
		--         Transparency = NumberSequence.new({
		--             NumberSequenceKeypoint.new(0, 0.55),
		--             NumberSequenceKeypoint.new(0.5, 0.8),
		--             NumberSequenceKeypoint.new(1, 0.6)
		--         })
		--     })
		-- })
	})

	function Dialog:Open()
		if Dialog.Closed then
			return false
		end

		if not Key and Dialog.UIElements.FullScreen then
			Dialog.UIElements.FullScreen.Visible = true
			Dialog.UIElements.FullScreen.Active = true
		end

		Dialog.UIElements.MainContainer.Visible = true
		if not Key and Dialog.UIElements.FullScreen then
			Tween(Dialog.UIElements.FullScreen, 0.16, { BackgroundTransparency = 0.58 }):Play()
		end
		Tween(Dialog.UIElements.MainContainer, 0.16, { ImageTransparency = 0 }):Play()
		task.delay(0.04, function()
			if not Dialog.Closed and Dialog.UIElements.Main and Dialog.UIElements.Main.Parent then
				Dialog.UIElements.Main.Visible = true
			end
		end)
		return true
	end

	function Dialog:Close()
		if Dialog.Closed then
			return function() end
		end
		Dialog.Closed = true

		if Dialog.UIElements.Main then
			Dialog.UIElements.Main.Visible = false
		end
		if Dialog.UIElements.FullScreen and Dialog.UIElements.FullScreen.Parent then
			Tween(Dialog.UIElements.FullScreen, 0.12, { BackgroundTransparency = 1 }):Play()
			Dialog.UIElements.FullScreen.Active = false
		end
		if Dialog.UIElements.MainContainer and Dialog.UIElements.MainContainer.Parent then
			Tween(Dialog.UIElements.MainContainer, 0.12, { ImageTransparency = 1 }):Play()
		end

		task.delay(0.14, function()
			if Dialog.UIElements.MainContainer and Dialog.UIElements.MainContainer.Parent then
				Dialog.UIElements.MainContainer:Destroy()
			end
			if Dialog.UIElements.FullScreen and Dialog.UIElements.FullScreen.Parent then
				Dialog.UIElements.FullScreen:Destroy()
			end
		end)

		return function() end
	end

	if Dialog.UIElements.BackdropButton then
		Creator.AddSignal(Dialog.UIElements.BackdropButton.Activated, function()
			Dialog:Close()
		end)
	end

	--Dialog:Open()
	return Dialog
end

return DialogModule
