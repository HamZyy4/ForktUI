return {
	Elements = {
		Paragraph = require("./Paragraph"),
		Button = require("./Button"),
		Toggle = require("./Toggle"),
		Slider = require("./Slider"),
		ProgressBar = require("./ProgressBar"),
		Keybind = require("./Keybind"),
		Input = require("./Input"),
		Dropdown = require("./Dropdown"),
		Code = require("./Code"),
		Colorpicker = require("./Colorpicker"),
		Section = require("./Section"),
		Divider = require("./Divider"),
		Space = require("./Space"),
		Image = require("./Image"),
		Group = require("./Group"),
		HStack = require("./HStack"),
		VStack = require("./VStack"),
		Viewport = require("./Viewport"),
		--Video       = require("./Video"),
	},
	Load = function(tbl, Container, Elements, Window, ForktUI, OnElementCreateFunction, ElementsModule, UIScale, Tab)
		local function removeByIdentity(list, target)
			for index = #list, 1, -1 do
				if list[index] == target then
					table.remove(list, index)
					return index
				end
			end
			return nil
		end

		for name, module in next, Elements do
			tbl[name] = function(self, config)
				config = config or {}
				config.Tab = Tab or tbl
				config.ParentType = tbl.__type
				config.ParentTable = tbl
				config.Index = #tbl.Elements + 1
				config.GlobalIndex = #Window.AllElements + 1
				config.TabIndex = Tab and Tab ~= tbl and (#Tab.Elements + 1) or nil
				config.Parent = Container
				config.Window = Window
				config.ForktUI = ForktUI
				config.UIScale = UIScale
				config.ElementsModule = ElementsModule

				local _elementInstance, content = module:New(config)

				if config.Flag and typeof(config.Flag) == "string" then
					if Window.CurrentConfig then
						Window.CurrentConfig:Register(config.Flag, content)

						if Window.PendingConfigData and Window.PendingConfigData[config.Flag] then
							local data = Window.PendingConfigData[config.Flag]

							local ConfigManager = Window.ConfigManager
							if ConfigManager.Parser[data.__type] then
								task.defer(function()
									local success, err = pcall(function()
										ConfigManager.Parser[data.__type].Load(content, data)
									end)

									if success then
										Window.PendingConfigData[config.Flag] = nil
									else
										warn(
											"[ ForktUI ] Failed to apply pending config for '"
												.. config.Flag
												.. "': "
												.. tostring(err)
										)
									end
								end)
							end
						end
					else
						Window.PendingFlags = Window.PendingFlags or {}
						Window.PendingFlags[config.Flag] = content
					end
				end

				local frame
				for key, value in next, content do
					if typeof(value) == "table" and key ~= "ElementFrame" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if frame then
					content.ElementFrame = frame.UIElements and frame.UIElements.Main or content.ElementFrame
					function content:SetTitle(title)
						return frame.SetTitle and frame:SetTitle(title)
					end
					function content:SetDesc(desc)
						return frame.SetDesc and frame:SetDesc(desc)
					end
					function content:SetImage(image, size)
						return frame.SetImage and frame:SetImage(image, size)
					end
					function content:SetThumbnail(image, size)
						return frame.SetThumbnail and frame:SetThumbnail(image, size)
					end
					function content:Highlight()
						if frame.Highlight then
							frame:Highlight()
						end
					end
				end

				local originalDestroy = content.Destroy
				function content:Destroy()
					if self.__ForktUIDestroyed then
						return
					end
					self.__ForktUIDestroyed = true

					-- Group-like elements own child controls; clean those registries too.
					if type(self.Elements) == "table" then
						for index = #self.Elements, 1, -1 do
							local child = self.Elements[index]
							if type(child) == "table" and type(child.Destroy) == "function" then
								pcall(child.Destroy, child)
							end
						end
					end

					if type(originalDestroy) == "function" then
						local ok, err = pcall(originalDestroy, self)
						if not ok then
							warn("ForktUI: element cleanup failed:", err)
						end
					elseif frame and type(frame.Destroy) == "function" then
						pcall(frame.Destroy, frame)
					else
						local visual = self.ElementFrame
						if visual and type(visual.Destroy) == "function" then
							pcall(visual.Destroy, visual)
						end
					end

					removeByIdentity(Window.AllElements, self)
					removeByIdentity(tbl.Elements, self)
					if Tab and Tab ~= tbl then
						removeByIdentity(Tab.Elements, self)
					end
					if tbl.UpdateAllElementShapes then
						tbl:UpdateAllElementShapes(tbl)
					end
				end

				-- Parent containers create their nested controls inside module:New().
				-- Insert the parent at its original position afterwards so it does not
				-- overwrite a child or appear after its own descendants.
				table.insert(Window.AllElements, config.GlobalIndex, content)
				table.insert(tbl.Elements, config.Index, content)
				if Tab and Tab ~= tbl then
					table.insert(Tab.Elements, config.TabIndex, content)
				end

				if Window.NewElements then
					tbl:UpdateAllElementShapes(tbl)
				end

				if OnElementCreateFunction then
					OnElementCreateFunction(content, tbl.Elements)
				end
				return content
			end
		end
		function tbl:UpdateAllElementShapes(bbb)
			for i, element in next, bbb.Elements do
				local frame
				for key, value in pairs(element) do
					if typeof(value) == "table" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if not frame and element.UpdateShape then
					frame = element
				end

				if frame then
					--print("idx changed : " .. i .. " " .. (element.Title or "not found"))
					frame.Index = i
					if frame.UpdateShape then
						--print(" .changed: " .. i)
						frame.UpdateShape(bbb)
					end
				end
			end
		end
	end,
}
