if shared.Venyx then
    shared.Venyx.uninject()
end

-- init
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

-- services
local input = game:GetService("UserInputService")
local run = game:GetService("RunService")
local tween = game:GetService("TweenService")
local tweeninfo = TweenInfo.new

-- additional
local utility = {}

-- themes
local objects = {}
local themes = {
	Background = Color3.fromRGB(24, 24, 24), 
	Glow = Color3.fromRGB(0, 0, 0), 
	Accent = Color3.fromRGB(10, 10, 10), 
	LightContrast = Color3.fromRGB(20, 20, 20), 
	DarkContrast = Color3.fromRGB(14, 14, 14),  
	TextColor = Color3.fromRGB(255, 255, 255)
}

do
	if not isfolder or not makefolder then
		warn("Venyx Warning: File system functions (e.g., isfolder) not found. Saving and loading will be disabled.")
	else
		if not isfolder("Venyx") then
			makefolder("Venyx")
		end
		if not isfolder("Venyx/games") then
			makefolder("Venyx/games")
		end
		if not isfolder("Venyx/profiles") then
			makefolder("Venyx/profiles")
		end
	end
end


do
	function utility:Create(instance, properties, children)
		local object = Instance.new(instance)
		
		for i, v in pairs(properties or {}) do
			object[i] = v
			
			if typeof(v) == "Color3" then -- save for theme changer later
				local theme = utility:Find(themes, v)
				
				if theme then
					objects[theme] = objects[theme] or {}
					objects[theme][i] = objects[theme][i] or setmetatable({}, {__mode = "k"})
					
					table.insert(objects[theme][i], object)
				end
			end
		end
		
		for i, module in pairs(children or {}) do
			module.Parent = object
		end
		
		return object
	end
	
	function utility:Tween(instance, properties, duration, ...)
		tween:Create(instance, tweeninfo(duration, ...), properties):Play()
	end
	
	function utility:Wait()
		return run.RenderStepped:Wait()
	end
	
	function utility:Find(table, value) -- table.find doesn't work for dictionaries
		for i, v in pairs(table) do
			if v == value then
				return i
			end
		end
	end
	
	function utility:Sort(pattern, values)
		local new = {}
		pattern = pattern:lower()
		
		if pattern == "" then
			return values
		end
		
		for i, value in pairs(values) do
			if tostring(value):lower():find(pattern) then
				table.insert(new, value)
			end
		end
		
		return new
	end
	
	function utility:DraggingEnabled(frame, parent)	
		parent = parent or frame		
		local dragging = false
		local dragInput, mousePos, framePos
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				mousePos = input.Position
				framePos = parent.Position				
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		frame.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		input.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - mousePos
				parent.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
			end
		end)
    end

    function utility:DraggingEnded(callback)
        input.InputEnded:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch then
                callback()
            end
        end)
    end
end

local library = {}
local tab = {}
local section = {}
library.__index = library
tab.__index = tab
section.__index = section

function library.new(title)
    local self = setmetatable({
        title = title or "Venyx",
        container = nil,
        tabs = {},
        currentTab = nil,
        activePicker = nil,
        toggleConnection = nil, -- To hold the keybind connection
        profilePath = "Venyx/profiles/" .. tostring(game.PlaceId) .. ".lua",
        controls = {} -- A structured way to access controls for saving/loading
    }, library)
    
    self.container = utility:Create("ScreenGui", {
        Name = "Venyx",
        Parent = game:GetService("CoreGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false -- Prevent Roblox from destroying the GUI on respawn
    })
    
    local mainFrame = utility:Create("ImageLabel", {
        Name = "Main",
        Parent = self.container,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 511, 0, 320),
        Image = "rbxassetid://4641149554",
        ImageColor3 = themes.Background,
    }, {
        utility:Create("ImageLabel", {
            Name = "Glow",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, -15, 0, -15),
            Size = UDim2.new(1, 30, 1, 30),
            ZIndex = 0,
            Image = "rbxassetid://5028857084",
            ImageColor3 = themes.Glow,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(24, 24, 276, 276)
        }),
        utility:Create("ImageLabel", {
            Name = "tabs",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.new(0, 0, 0, 38),
            Size = UDim2.new(0, 126, 1, -38),
            ZIndex = 3,
            Image = "rbxassetid://5012534273",
            ImageColor3 = themes.DarkContrast,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(4, 4, 296, 296)
        }, {
            utility:Create("ScrollingFrame", {
                Name = "tabs_Container",
                Active = true,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 10),
                Size = UDim2.new(1, 0, 1, -20),
                CanvasSize = UDim2.new(0, 0, 0, 0), -- Will be resized
                ScrollBarThickness = 0
            }, {
                utility:Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 10)
                })
            })
        }),
        utility:Create("ImageLabel", {
            Name = "TopBar",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 0, 38),
            ZIndex = 5,
            Image = "rbxassetid://4595286933",
            ImageColor3 = themes.Accent,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(4, 4, 296, 296)
        }, {
            utility:Create("TextLabel", {
                Name = "Title",
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 19),
                Size = UDim2.new(1, -46, 0, 16),
                ZIndex = 5,
                Font = Enum.Font.GothamBold,
                Text = self.title,
                TextColor3 = themes.TextColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        })
    })

    self.mainFrame = mainFrame
    
    utility:DraggingEnabled(self.mainFrame.TopBar, self.mainFrame)
    
    self.tabsContainer = self.mainFrame.tabs.tabs_Container
    
    self.toggleConnection = input.InputBegan:Connect(function(inputObj, gameProcessedEvent)
        if gameProcessedEvent then return end
        if inputObj.KeyCode == Enum.KeyCode.RightShift then
            self:toggle()
        end
    end)
    
    shared.Venyx.instance = self
    
    self:loadGameConfigs()

    task.wait()
    self:loadProfile()
    
    return self
end

function library:uninject()
    if self.toggleConnection then
        self.toggleConnection:Disconnect()
        self.toggleConnection = nil
    end
    
    if self.container and self.container.Parent then
        self.container:Destroy()
        self.container = nil
    end

    if shared.Venyx and shared.Venyx.instance == self then
        shared.Venyx.instance = nil
    end
end

shared.Venyx = shared.Venyx or {}
shared.Venyx.uninject = function()
    if shared.Venyx.instance and typeof(shared.Venyx.instance.uninject) == "function" then
        shared.Venyx.instance:uninject()
    end
end


function library:loadGameConfigs()
    if not isfile or not loadfile then return end

    local universalConfigPath = "Venyx/games/universal.lua"
    local gameConfigPath = "Venyx/games/" .. tostring(game.PlaceId) .. ".lua"

    local function executeConfig(path)
        if isfile(path) then
            local success, configFunc = pcall(loadfile, path)
            if success and typeof(configFunc) == "function" then
                pcall(configFunc, self) 
            else
                warn("Venyx: Failed to load config from " .. path, configFunc)
            end
        end
    end
    
    executeConfig(universalConfigPath)
    executeConfig(gameConfigPath)
end


function library:saveProfile()
    if not writefile then return end

    local profileData = {}
    
    for tabName, tabData in pairs(self.controls) do
        profileData[tabName] = profileData[tabName] or {}
        for sectionName, sectionData in pairs(tabData) do
            profileData[tabName][sectionName] = profileData[tabName][sectionName] or {}
            for controlName, controlInfo in pairs(sectionData) do
                if controlInfo.getValue then
                    profileData[tabName][sectionName][controlName] = controlInfo.getValue()
                end
            end
        end
    end

    local function serialize(data, indent)
        indent = indent or ""
        local s = "{\n"
        local keys = {}
        for k in pairs(data) do table.insert(keys, k) end
        table.sort(keys)

        for _, k in ipairs(keys) do
            local v = data[k]
            s = s .. indent .. "  "
            if type(k) == "string" then
                s = s .. '["' .. tostring(k):gsub('"', '\\"'):gsub("\n", "\\n") .. '"] = '
            else
                s = s .. '[' .. tostring(k) .. '] = '
            end

            local vType = type(v)
            if v == nil then
                s = s .. "nil"
            elseif vType == "table" then
                s = s .. serialize(v, indent .. "  ")
            elseif vType == "string" then
                s = s .. '"' .. tostring(v):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
            elseif vType == "boolean" or vType == "number" then
                s = s .. tostring(v)
            elseif typeof(v) == "Color3" then
                s = s .. string.format("Color3.fromRGB(%.0f, %.0f, %.0f)", v.R * 255, v.G * 255, v.B * 255)
            else
                s = s .. '"' .. tostring(v) .. '"'
            end
            s = s .. ",\n"
        end
        return s .. indent .. "}"
    end
    
    local content = "return " .. serialize(profileData)
    writefile(self.profilePath, content)
end

function library:loadProfile()
    if not isfile or not isfile(self.profilePath) or not loadfile then
        return
    end

    local success, result = pcall(loadfile, self.profilePath)
    if not success or typeof(result) ~= "function" then
        warn("Venyx: Could not execute profile file: " .. tostring(result))
        return
    end
    
    local loadSuccess, profileData = pcall(result)
    if not loadSuccess or type(profileData) ~= "table" then
        warn("Venyx: Profile data is invalid: " .. tostring(profileData))
        return
    end

    for tabName, tabData in pairs(profileData) do
        if self.controls[tabName] then
            for sectionName, sectionData in pairs(tabData) do
                if self.controls[tabName][sectionName] then
                    for controlName, value in pairs(sectionData) do
                        local controlInfo = self.controls[tabName][sectionName][controlName]
                        if controlInfo and controlInfo.setValue and value ~= nil then
                            pcall(controlInfo.setValue, controlInfo, value)
                        end
                    end
                end
            end
        end
    end
end

function library:addTab(title, icon)
    local newTab = tab.new(self, title, icon)
    table.insert(self.tabs, newTab)
    
    local listLayout = self.tabsContainer.UIListLayout
    local numTabs = #self.tabs
    local newCanvasY = (numTabs * 26) + ((numTabs - 1) * listLayout.Padding.Offset)
    self.tabsContainer.CanvasSize = UDim2.new(0, 0, 0, newCanvasY)

    if #self.tabs == 1 then
        self:selectTab(newTab)
    end
    
    return newTab
end

function library:selectTab(targetTab)
    for _, t in pairs(self.tabs) do
        t.container.Visible = false
        t.button.Title.TextTransparency = 0.65
        t.button.Title.Font = Enum.Font.Gotham
        if t.button:FindFirstChild("Icon") then
            t.button.Icon.ImageTransparency = 0.65
        end
    end
    
    targetTab.container.Visible = true
    targetTab.button.Title.TextTransparency = 0
    targetTab.button.Title.Font = Enum.Font.GothamSemibold
    if targetTab.button:FindFirstChild("Icon") then
        targetTab.button.Icon.ImageTransparency = 0
    end
    
    self.currentTab = targetTab
    task.wait()
    targetTab:Resize()
end


function library:setTheme(theme, color3)
	themes[theme] = color3
	
	for property, theme_objects in pairs(objects[theme] or {}) do
		for i, object in pairs(theme_objects) do
			if not object.Parent or (object.Name == "Button" and object.Parent.Name == "ColorPicker") then
				theme_objects[i] = nil
			else
				object[property] = color3
			end
		end
	end
end

function library:toggle()
	if self.toggling then return end
	self.toggling = true
	
	local container = self.mainFrame
	local topbar = container:WaitForChild("TopBar")
	
	if (container == nil or topbar == nil) then return end
	
	if self.position then
        container.ClipsDescendants = false
		utility:Tween(container, {
			Size = UDim2.new(0, 511, 0, 320),
			Position = self.position
		}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(0.2)
		
		utility:Tween(topbar, {Size = UDim2.new(1, 0, 0, 38)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(0.2)
		
		self.position = nil
	else
		self.position = container.Position
		
		utility:Tween(topbar, {Size = UDim2.new(1, 0, 1, 0)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(0.2)
		
		utility:Tween(container, {
			Size = UDim2.new(0, 511, 0, 0),
			Position = self.position + UDim2.new(0, 0, 0, 160)
		}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(0.2)
        container.ClipsDescendants = true
	end
	
	self.toggling = false
end

function library:Notify(title, text, time, callback)
	if self.activeNotification then
		self.activeNotification = self.activeNotification()
	end
	
	local notification = utility:Create("ImageLabel", {
		Name = "Notification",
		Parent = self.container,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 200, 0, 60),
		Image = "rbxassetid://5028857472",
		ImageColor3 = themes.Background,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(4, 4, 296, 296),
		ZIndex = 100,
		ClipsDescendants = true
	}, {
		utility:Create("ImageLabel", {
			Name = "Flash",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://4641149554",
			ImageColor3 = themes.TextColor,
			ZIndex = 5
		}),
		utility:Create("ImageLabel", {
			Name = "Glow",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -15, 0, -15),
			Size = UDim2.new(1, 30, 1, 30),
			ZIndex = 2,
			Image = "rbxassetid://5028857084",
			ImageColor3 = themes.Glow,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(24, 24, 276, 276)
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 8),
			Size = UDim2.new(1, -40, 0, 16),
			ZIndex = 4,
			Font = Enum.Font.GothamSemibold,
			TextColor3 = themes.TextColor,
			TextSize = 14.000,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("TextLabel", {
			Name = "Text",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 1, -24),
			Size = UDim2.new(1, -40, 0, 16),
			ZIndex = 4,
			Font = Enum.Font.Gotham,
			TextColor3 = themes.TextColor,
			TextSize = 12.000,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("ImageButton", {
			Name = "Accept",
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -26, 0, 8),
			Size = UDim2.new(0, 16, 0, 16),
			Image = "rbxassetid://5012538259",
			ImageColor3 = themes.TextColor,
			ZIndex = 4
		}),
		utility:Create("ImageButton", {
			Name = "Decline",
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -26, 1, -24),
			Size = UDim2.new(0, 16, 0, 16),
			Image = "rbxassetid://5012538583",
			ImageColor3 = themes.TextColor,
			ZIndex = 4
		})
	})
	
	utility:DraggingEnabled(notification)
	
	title = title or "Notification"
	text = text or ""
	
	notification.Title.Text = title
	notification.Text.Text = text
	
	local padding = 10
	local textSize = game:GetService("TextService"):GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(math.huge, 16))
	
	notification.Position = library.lastNotification or UDim2.new(0, padding, 1, -(notification.AbsoluteSize.Y + padding))
	notification.Size = UDim2.new(0, 0, 0, 60)
	
	utility:Tween(notification, {Size = UDim2.new(0, textSize.X + 70, 0, 60)}, 0.2)
	wait(0.2)
	
	notification.ClipsDescendants = false
	utility:Tween(notification.Flash, {
		Size = UDim2.new(0, 0, 0, 60),
		Position = UDim2.new(1, 0, 0, 0)
	}, 0.2)
	
	local active = true
	local close = function()
		if not (notification and notification.Parent) then return end
		if not active then return end
		active = false
		notification.ClipsDescendants = true
		
		library.lastNotification = notification.Position
		notification.Flash.Position = UDim2.new(0, 0, 0, 0)
		utility:Tween(notification.Flash, {Size = UDim2.new(1, 0, 1, 0)}, 0.2)
		
		wait(0.2)
		utility:Tween(notification, {
			Size = UDim2.new(0, 0, 0, 60),
			Position = notification.Position + UDim2.new(0, (textSize.X + 70)/2, 0, 0)
		}, 0.2)
		
		wait(0.2)
		notification:Destroy()
	end
	
	self.activeNotification = close
	
	notification.Accept.MouseButton1Click:Connect(function()
		if not active then return end
		if callback then task.spawn(callback, true) end
		close()
	end)
	
	notification.Decline.MouseButton1Click:Connect(function()
		if not active then return end
		if callback then task.spawn(callback, false) end
		close()
	end)
	
	task.spawn(function()
		if (time and type(time) == "number") then
			task.wait(tonumber(time))
			if active then close() end
		end
	end)
end

function tab.new(library, title, icon)
    local button = utility:Create("TextButton", {
        Name = title,
        Parent = library.tabsContainer,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 26),
        ZIndex = 3,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 14
    }, {
        utility:Create("TextLabel", {
            Name = "Title",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 40, 0.5, 0),
            Size = UDim2.new(0, 76, 1, 0),
            ZIndex = 3,
            Font = Enum.Font.Gotham,
            Text = title,
            TextColor3 = themes.TextColor,
            TextSize = 12,
            TextTransparency = 0.65,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        icon and utility:Create("ImageLabel", {
            Name = "Icon", 
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16),
            ZIndex = 3,
            Image = "rbxassetid://" .. tostring(icon),
            ImageColor3 = themes.TextColor,
            ImageTransparency = 0.65,
            ScaleType = Enum.ScaleType.Fit
        }) or nil
    })
    
    local container = utility:Create("ScrollingFrame", {
        Name = title,
        Parent = library.mainFrame,
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 134, 0, 46),
        Size = UDim2.new(1, -142, 1, -56),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = themes.DarkContrast,
        Visible = false
    }, {
        utility:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })
    })
    
    local newTab = setmetatable({
        library = library,
        container = container,
        button = button,
        sections = {}
    }, tab)
    
    button.Activated:Connect(function()
        library:selectTab(newTab)
    end)
    
    return newTab
end

function tab:addSection(title)
    local newSection = section.new(self, title)
    table.insert(self.sections, newSection)
    return newSection
end

function tab:Resize()
    local padding = self.container.UIListLayout.Padding.Offset
    local size = padding 
    
    for i, section in pairs(self.sections) do
        size = size + section.container.Parent.AbsoluteSize.Y + padding
    end
    
    self.container.CanvasSize = UDim2.new(0, 0, 0, size)
end

function section.new(tab, title)
    local container = utility:Create("ImageLabel", {
        Name = title,
        Parent = tab.container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 28),
        ZIndex = 2,
        Image = "rbxassetid://5028857472",
        ImageColor3 = themes.LightContrast,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(4, 4, 296, 296),
    }, {
        utility:Create("Frame", {
            Name = "Container",
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -16, 1, -16),
        }, {
            utility:Create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 2,
                Font = Enum.Font.GothamSemibold,
                Text = title,
                TextColor3 = themes.TextColor,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTransparency = 0
            }),
            utility:Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4)
            })
        })
    })
    
    local self = setmetatable({
        tab = tab,
        container = container.Container,
        modules = {},
        colorpickers = {},
        dropdownData = setmetatable({}, {__mode = "k"})
    }, section) 

    -- Prepare the library's controls table for this new section
    local lib = self.tab.library
    local tabTitle = self.tab.button.Name
    lib.controls[tabTitle] = lib.controls[tabTitle] or {}
    lib.controls[tabTitle][title] = lib.controls[tabTitle][title] or {}

    return self
end

function section:addButton(title, callback)
	local button = utility:Create("ImageButton", {
		Name = "Button",
		Parent = self.container,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 2,
		Image = "rbxassetid://5028857472",
		ImageColor3 = themes.DarkContrast,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 298, 298)
	}, {
		utility:Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 3,
			Font = Enum.Font.Gotham,
			Text = title,
			TextColor3 = themes.TextColor,
			TextSize = 12,
			TextTransparency = 0.1
		})
	})
	
	table.insert(self.modules, button)
	self:Resize()
	
	local debounce = false
	button.MouseButton1Click:Connect(function()
		if debounce then return end
		debounce = true

		local originalSize = button.Size
		utility:Tween(button, {Size = originalSize - UDim2.fromOffset(0, 2)}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.wait(0.1)
		utility:Tween(button, {Size = originalSize}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		if callback then
			task.spawn(callback, function(...) self:updateButton(button, ...) end)
		end
		
		task.wait(0.2)
		debounce = false
	end)
	
	return button
end

function section:addToggle(title, default, callback)
	local toggle = utility:Create("ImageButton", {
		Name = "Toggle",
		Parent = self.container,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 2,
		Image = "rbxassetid://5028857472",
		ImageColor3 = themes.DarkContrast,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 298, 298)
	},{
		utility:Create("TextLabel", {
			Name = "Title",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0.5, 1),
			Size = UDim2.new(0.5, 0, 1, 0),
			ZIndex = 3,
			Font = Enum.Font.Gotham,
			Text = title,
			TextColor3 = themes.TextColor,
			TextSize = 12,
			TextTransparency = 0.1,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("ImageLabel", {
			Name = "Button",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -50, 0.5, -8),
			Size = UDim2.new(0, 40, 0, 16),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.LightContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		}, {
			utility:Create("ImageLabel", {
				Name = "Frame",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 2, 0.5, -6),
				Size = UDim2.new(1, -22, 1, -4),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.TextColor,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			})
		})
	})
	
	table.insert(self.modules, toggle)
	
	local active = default or false
    local lib = self.tab.library
    local tabTitle = self.tab.button.Name
    local sectionTitle = self.container.Title.Text

    lib.controls[tabTitle][sectionTitle][title] = {
        instance = toggle,
        getValue = function()
            return active
        end,
        setValue = function(self, newValue)
            if active ~= newValue then
                active = newValue
                self:updateToggle(toggle, nil, active)
                if callback then
                    task.spawn(callback, active, function(...) self:updateToggle(toggle, ...) end)
                end
            end
        end
    }

	self:updateToggle(toggle, nil, active)
	self:Resize()
	
	toggle.Activated:Connect(function()
		active = not active
		self:updateToggle(toggle, nil, active)
		
		if callback then
			task.spawn(callback, active, function(...) self:updateToggle(toggle, ...) end)
		end
        lib:saveProfile()
	end)
	
	return toggle
end

function section:addSlider(title, default, min, max, callback)
	local slider = utility:Create("ImageButton", {
		Name = "Slider",
		Parent = self.container,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 50),
		ZIndex = 2,
		Image = "rbxassetid://5028857472",
		ImageColor3 = themes.DarkContrast,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 298, 298)
	}, {
		utility:Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 6),
			Size = UDim2.new(0.5, 0, 0, 16),
			ZIndex = 3,
			Font = Enum.Font.Gotham,
			Text = title,
			TextColor3 = themes.TextColor,
			TextSize = 12,
			TextTransparency = 0.1,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("TextBox", {
			Name = "TextBox",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -30, 0, 6),
			Size = UDim2.new(0, 20, 0, 16),
			ZIndex = 3,
			Font = Enum.Font.GothamSemibold,
			Text = default or min,
			TextColor3 = themes.TextColor,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right
		}),
		utility:Create("TextLabel", {
			Name = "Slider",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 28),
			Size = UDim2.new(1, -20, 0, 16),
			ZIndex = 3,
			Text = "",
		}, {
			utility:Create("ImageLabel", {
				Name = "Bar",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 4),
				ZIndex = 3,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.LightContrast,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("ImageLabel", {
					Name = "Fill",
					BackgroundTransparency = 1,
					Size = UDim2.new(0.8, 0, 1, 0),
					ZIndex = 3,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.TextColor,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("ImageLabel", {
						Name = "Circle",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						ImageTransparency = 1.000,
						ImageColor3 = themes.TextColor,
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 10, 0, 10),
						ZIndex = 3,
						Image = "rbxassetid://4608020054"
					})
				})
			})
		})
	})
	
	table.insert(self.modules, slider)
	self:Resize()
	
	local allowed = { [""] = true, ["-"] = true }
	local textbox = slider.TextBox
	local circle = slider.Slider.Bar.Fill.Circle
	local value = default or min
	local dragging = false
    local lib = self.tab.library
    local tabTitle = self.tab.button.Name
    local sectionTitle = self.container.Title.Text
	
	local callbackFunc = function(val)
		if callback then
			task.spawn(callback, val, function(...) self:updateSlider(slider, ...) end)
		end
        lib:saveProfile()
	end
	
    lib.controls[tabTitle][sectionTitle][title] = {
        instance = slider,
        getValue = function()
            return tonumber(slider.TextBox.Text)
        end,
        setValue = function(self, newValue)
            value = self:updateSlider(slider, nil, newValue, min, max)
            if callback then
                task.spawn(callback, value, function(...) self:updateSlider(slider, ...) end)
            end
        end
    }

	self:updateSlider(slider, nil, value, min, max)
	
	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			utility:Tween(circle, {ImageTransparency = 0}, 0.1)
			
			while dragging do
				value = self:updateSlider(slider, nil, nil, min, max, true)
				callbackFunc(value)
				utility:Wait()
			end
            
			utility:Tween(circle, {ImageTransparency = 1}, 0.2)
		end
	end)
    
    input.InputEnded:Connect(function(endInput)
        if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
	
	textbox.FocusLost:Connect(function()
		if not tonumber(textbox.Text) then
			value = self:updateSlider(slider, nil, default or min, min, max)
			callbackFunc(value)
		end
	end)
	
	textbox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = textbox.Text
		
		if not allowed[text] and not tonumber(text) then
			textbox.Text = text:sub(1, #text - 1)
		elseif not allowed[text] then	
			value = self:updateSlider(slider, nil, tonumber(text) or value, min, max)
			callbackFunc(value)
		end
	end)
	
	return slider
end
	
function section:addDropdown(title, list, p3, p4)
    local multiChoice = (type(p3) == "boolean" and p3) or false
    local callback = (type(p3) == "function" and p3) or (type(p4) == "function" and p4)

	local dropdown = utility:Create("Frame", {
		Name = "Dropdown",
		Parent = self.container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		ClipsDescendants = true
	}, {
		utility:Create("ImageButton", {
			Name = "Search",
            Parent = dropdown,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 30),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.DarkContrast,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		}, {
			utility:Create("TextBox", {
				Name = "TextBox",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 10, 0.5, 1),
				Size = UDim2.new(1, -42, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.Gotham,
				Text = title,
				TextColor3 = themes.TextColor,
				TextSize = 12,
				TextTransparency = 0.1,
				TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false
			}),
			utility:Create("ImageLabel", {
				Name = "Button",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -28, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0, 18, 0, 18),
				ZIndex = 3,
				Image = "rbxassetid://5012539403",
				ImageColor3 = themes.TextColor,
			})
		}),
		utility:Create("ImageLabel", {
			Name = "List",
            Parent = dropdown,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 34),
			Size = UDim2.new(1, 0, 0, 0),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = themes.Background,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298),
            ClipsDescendants = true,
		}, {
			utility:Create("ScrollingFrame", {
				Name = "Frame",
				Active = true,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 4, 0, 4),
				Size = UDim2.new(1, -8, 1, -8),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ZIndex = 2,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = themes.DarkContrast
			}, {
				utility:Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4)
				})
			})
		})
	})
	
	table.insert(self.modules, dropdown)
    self.dropdownData[dropdown] = { selectedItems = {} }
	self:Resize()
	
	local search = dropdown.Search
	local textbox = search.TextBox
	local focused = false
	local isOpen = false
    local lib = self.tab.library
    local tabTitle = self.tab.button.Name
    local sectionTitle = self.container.Title.Text
	
	list = list or {}
	
    lib.controls[tabTitle][sectionTitle][title] = {
        instance = dropdown,
        getValue = function()
            if multiChoice then
                return self.dropdownData[dropdown].selectedItems
            else
                local text = dropdown.Search.TextBox.Text
                return text ~= title and text or nil
            end
        end,
        setValue = function(self, newValue)
            if multiChoice then
                if type(newValue) == "table" then
                    self.dropdownData[dropdown].selectedItems = newValue
                    local selectedText = table.concat(newValue, ", ")
                    local hasSelection = #selectedText > 0
                    dropdown.Search.TextBox.Text = hasSelection and selectedText or title
                    dropdown.Search.TextBox.TextTransparency = hasSelection and 0 or 0.1
                    if callback then task.spawn(callback, newValue) end
                end
            else
                if type(newValue) == "string" then
                    dropdown.Search.TextBox.Text = newValue
                    dropdown.Search.TextBox.TextTransparency = 0
                    if callback then task.spawn(callback, newValue) end
                end
            end
        end
    }

	search.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			self:updateDropdown(dropdown, nil, list, callback, false, multiChoice)
		else
			self:updateDropdown(dropdown, nil, nil, callback, false, multiChoice)
		end
	end)
	
	textbox.Focused:Connect(function()
		if not isOpen then
			isOpen = true
			self:updateDropdown(dropdown, nil, list, callback, false, multiChoice)
		end
		if not multiChoice or #self.dropdownData[dropdown].selectedItems == 0 then
			textbox.Text = ""
            textbox.TextTransparency = 0
		end
		focused = true
	end)
	
	textbox.FocusLost:Connect(function()
		focused = false
        task.wait(0.1) 
        if textbox:IsFocused() then return end

        if #self.dropdownData[dropdown].selectedItems == 0 and textbox.Text == "" then
            textbox.Text = title
            textbox.TextTransparency = 0.1
        end

        if isOpen then
            isOpen = false
            self:updateDropdown(dropdown, nil, nil, callback, false, multiChoice)
        end
	end)
	
	textbox:GetPropertyChangedSignal("Text"):Connect(function()
		if focused then
            textbox.TextTransparency = 0
			local sortedList = utility:Sort(textbox.Text, list)
			self:updateDropdown(dropdown, nil, sortedList, callback, true, multiChoice)
		end
	end)
	
	return dropdown
end

function section:addColorPicker(title, default, callback)
	local colorpicker = utility:Create("ImageButton", {
		Name = "ColorPicker",
		Parent = self.container,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 2,
		Image = "rbxassetid://5028857472",
		ImageColor3 = themes.DarkContrast,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 298, 298)
	},{
		utility:Create("TextLabel", {
			Name = "Title",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0.5, 1),
			Size = UDim2.new(0.5, 0, 1, 0),
			ZIndex = 3,
			Font = Enum.Font.Gotham,
			Text = title,
			TextColor3 = themes.TextColor,
			TextSize = 12,
			TextTransparency = 0.1,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("ImageButton", {
			Name = "Button",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -50, 0.5, -7),
			Size = UDim2.new(0, 40, 0, 14),
			ZIndex = 2,
			Image = "rbxassetid://5028857472",
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 298, 298)
		})
	})
	
	local tab = utility:Create("ImageLabel", {
		Name = "ColorPicker",
		Parent = self.tab.library.mainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.75, 0, 0.4, 0),
		Selectable = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 162, 0, 169),
		Image = "rbxassetid://5028857472",
		ImageColor3 = themes.Background,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 298, 298),
		Visible = false,
		ZIndex = 10
	}, {
		utility:Create("ImageLabel", {
			Name = "Glow",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -15, 0, -15),
			Size = UDim2.new(1, 30, 1, 30),
			ZIndex = -1,
			Image = "rbxassetid://5028857084",
			ImageColor3 = themes.Glow,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(22, 22, 278, 278)
		}),
		utility:Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 8),
			Size = UDim2.new(1, -40, 0, 16),
			ZIndex = 2,
			Font = Enum.Font.GothamSemibold,
			Text = title,
			TextColor3 = themes.TextColor,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		}),
		utility:Create("ImageButton", {
			Name = "Close",
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -26, 0, 8),
			Size = UDim2.new(0, 16, 0, 16),
			ZIndex = 2,
			Image = "rbxassetid://5012538583",
			ImageColor3 = themes.TextColor
		}), 
		utility:Create("Frame", {
			Name = "Container",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 32),
			Size = UDim2.new(1, -18, 1, -40)
		}, {
			utility:Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6)
			}),
			utility:Create("ImageButton", {
				Name = "Canvas",
				BackgroundTransparency = 1,
				BorderColor3 = themes.LightContrast,
				Size = UDim2.new(1, 0, 0, 60),
				AutoButtonColor = false,
				Image = "rbxassetid://5108535320",
				ImageColor3 = Color3.fromRGB(255, 0, 0),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298),
                ClipsDescendants = true
			}, {
				utility:Create("ImageLabel", {
					Name = "White_Overlay",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Image = "rbxassetid://5107152351",
                    ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}),
				utility:Create("ImageLabel", {
					Name = "Black_Overlay",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Image = "rbxassetid://5107152095",
                    ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}),
				utility:Create("ImageLabel", {
					Name = "Cursor",
					BackgroundColor3 = themes.TextColor,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1.000,
					Size = UDim2.new(0, 10, 0, 10),
					Position = UDim2.new(0, 0, 0, 0),
					Image = "rbxassetid://5100115962",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 2
				})
			}),
			utility:Create("ImageButton", {
				Name = "Color",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0, 4),
				Selectable = false,
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = 2,
				AutoButtonColor = false,
				Image = "rbxassetid://5028857472",
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298),
                ClipsDescendants = true
			}, {
				utility:Create("Frame", {
					Name = "Select",
					BackgroundColor3 = themes.TextColor,
					BorderSizePixel = 0,
					Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.new(0, 2, 1, 0),
					ZIndex = 2
				}),
				utility:Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), 
						ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)), 
						ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), 
						ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)), 
						ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)), 
						ColorSequenceKeypoint.new(0.82, Color3.fromRGB(255, 0, 255)), 
						ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
					})
				})
			}),
			utility:Create("Frame", {
				Name = "Inputs",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 158),
				Size = UDim2.new(1, 0, 0, 16)
			}, {
				utility:Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6)
				}),
				utility:Create("ImageLabel", {
					Name = "R",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.305, 0, 1, 0),
					ZIndex = 2,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.DarkContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("TextLabel", {
						Name = "Text",
						BackgroundTransparency = 1,
						Size = UDim2.new(0.4, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						Text = "R:",
						TextColor3 = themes.TextColor,
						TextSize = 10.000
					}),
					utility:Create("TextBox", {
						Name = "Textbox",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.3, 0, 0, 0),
						Size = UDim2.new(0.6, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						PlaceholderColor3 = themes.DarkContrast,
						Text = "255",
						TextColor3 = themes.TextColor,
						TextSize = 10.000
					})
				}),
				utility:Create("ImageLabel", {
					Name = "G",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.305, 0, 1, 0),
					ZIndex = 2,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.DarkContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("TextLabel", {
						Name = "Text",
						BackgroundTransparency = 1,
						ZIndex = 2,
						Size = UDim2.new(0.4, 0, 1, 0),
						Font = Enum.Font.Gotham,
						Text = "G:",
						TextColor3 = themes.TextColor,
						TextSize = 10.000
					}),
					utility:Create("TextBox", {
						Name = "Textbox",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.3, 0, 0, 0),
						Size = UDim2.new(0.6, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						Text = "255",
						TextColor3 = themes.TextColor,
						TextSize = 10.000
					})
				}),
				utility:Create("ImageLabel", {
					Name = "B",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.305, 0, 1, 0),
					ZIndex = 2,
					Image = "rbxassetid://5028857472",
					ImageColor3 = themes.DarkContrast,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 298, 298)
				}, {
					utility:Create("TextLabel", {
						Name = "Text",
						BackgroundTransparency = 1,
						Size = UDim2.new(0.4, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						Text = "B:",
						TextColor3 = themes.TextColor,
						TextSize = 10.000
					}),
					utility:Create("TextBox", {
						Name = "Textbox",
						BackgroundTransparency = 1,
						Position = UDim2.new(0.3, 0, 0, 0),
						Size = UDim2.new(0.6, 0, 1, 0),
						ZIndex = 2,
						Font = Enum.Font.Gotham,
						Text = "255",
						TextColor3 = themes.TextColor,
						TextSize = 10.000
					})
				}),
			}),
			utility:Create("ImageButton", {
				Name = "Button",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 20),
				ZIndex = 2,
				Image = "rbxassetid://5028857472",
				ImageColor3 = themes.DarkContrast,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 298, 298)
			}, {
				utility:Create("TextLabel", {
					Name = "Text",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 3,
					Font = Enum.Font.Gotham,
					Text = "Submit",
					TextColor3 = themes.TextColor,
					TextSize = 11.000
				})
			})
		})
	})
	
	utility:DraggingEnabled(tab)
	table.insert(self.modules, colorpicker)
	self:Resize()
	
	local allowed = { [""] = true }
	local canvas = tab.Container.Canvas
	local colorSlider = tab.Container.Color
	local canvasSize, canvasPosition
	local colorSize, colorPosition
	local draggingColor, draggingCanvas = false, false
	local color3 = default or Color3.fromRGB(255, 255, 255)
	local hue, sat, brightness = Color3.toHSV(color3)
	local rgb = { r = color3.R * 255, g = color3.G * 255, b = color3.B * 255 }
    local lib = self.tab.library
    local tabTitle = self.tab.button.Name
    local sectionTitle = self.container.Title.Text

	self.colorpickers[colorpicker] = {
		tab = tab,
		callback = function(prop, value)
			rgb[prop] = value
			hue, sat, brightness = Color3.toHSV(Color3.fromRGB(rgb.r, rgb.g, rgb.b))
		end
	}
	
	local callbackWrapper = function(value)
		if callback then
			task.spawn(callback, value, function(...) self:updateColorPicker(colorpicker, ...) end)
		end
        lib:saveProfile()
	end
	
    lib.controls[tabTitle][sectionTitle][title] = {
        instance = colorpicker,
        getValue = function()
            return colorpicker.Button.ImageColor3
        end,
        setValue = function(self, newValue)
            if typeof(newValue) == "Color3" then
                self:updateColorPicker(colorpicker, nil, newValue)
                if callback then
                    task.spawn(callback, newValue, function(...) self:updateColorPicker(colorpicker, ...) end)
                end
            end
        end
    }

	utility:DraggingEnded(function()
		draggingColor, draggingCanvas = false, false
	end)
	
	self:updateColorPicker(colorpicker, nil, default)
	
	for i, container in pairs(tab.Container.Inputs:GetChildren()) do
		if container:IsA("ImageLabel") then
			local textbox = container.Textbox
			local focused = false
			
			textbox.Focused:Connect(function() focused = true end)
			
			textbox.FocusLost:Connect(function()
				focused = false
				if not tonumber(textbox.Text) then
					textbox.Text = math.floor(rgb[container.Name:lower()])
				end
			end)
			
			textbox:GetPropertyChangedSignal("Text"):Connect(function()
				local text = textbox.Text
				
				if not allowed[text] and not tonumber(text) then
					textbox.Text = text:sub(1, #text - 1)
				elseif focused and not allowed[text] then
					rgb[container.Name:lower()] = math.clamp(tonumber(textbox.Text) or 0, 0, 255)
					
					local newColor3 = Color3.fromRGB(rgb.r, rgb.g, rgb.b)
					hue, sat, brightness = Color3.toHSV(newColor3)
					
					self:updateColorPicker(colorpicker, nil, newColor3)
					callbackWrapper(newColor3)
				end
			end)
		end
	end
	
	canvas.InputBegan:Connect(function(inputObj)
		if inputObj.UserInputType == Enum.UserInputType.Touch or inputObj.UserInputType == Enum.UserInputType.MouseButton1 then		    
			draggingCanvas = true			
			canvasSize, canvasPosition = canvas.AbsoluteSize, canvas.AbsolutePosition
			while draggingCanvas do
				local x, y = mouse.X, mouse.Y
				sat = math.clamp((x - canvasPosition.X) / canvasSize.X, 0, 1)
				brightness = 1 - math.clamp((y - canvasPosition.Y) / canvasSize.Y, 0, 1)
				color3 = Color3.fromHSV(hue, sat, brightness)
				for i, prop in pairs({"r", "g", "b"}) do rgb[prop] = color3[prop:upper()] * 255 end
				self:updateColorPicker(colorpicker, nil, {hue, sat, brightness})
				utility:Tween(canvas.Cursor, {Position = UDim2.new(sat, 0, 1 - brightness, 0)}, 0)
				callbackWrapper(color3)
				utility:Wait()
			end
		end
	end)

	canvas.InputEnded:Connect(function() draggingCanvas = false end)
	
	colorSlider.InputBegan:Connect(function(inputObj)
		if inputObj.UserInputType == Enum.UserInputType.Touch or inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingColor = true
			colorSize, colorPosition = colorSlider.AbsoluteSize, colorSlider.AbsolutePosition
			while draggingColor do
				hue = math.clamp((mouse.X - colorPosition.X) / colorSize.X, 0, 1)
				color3 = Color3.fromHSV(hue, sat, brightness)
				for i, prop in pairs({"r", "g", "b"}) do rgb[prop] = color3[prop:upper()] * 255 end
				self:updateColorPicker(colorpicker, nil, {hue, sat, brightness})
				utility:Tween(tab.Container.Color.Select, {Position = UDim2.new(hue, 0, 0, 0)}, 0)
				callbackWrapper(color3)
				utility:Wait()
			end
		end
	end)

	colorSlider.InputEnded:Connect(function() draggingColor = false end)
	
	local button = colorpicker.Button
	local toggle, debounce, animate, lastColor
	
	lastColor = Color3.fromHSV(hue, sat, brightness)
	animate = function(visible, overwrite)
		if overwrite then
			if not toggle then return end
			if debounce then
				while debounce do utility:Wait() end
			end
		elseif not overwrite then
			if debounce then return end
		end
		
		toggle = visible
		debounce = true
		
		if visible then
			if self.tab.library.activePicker and self.tab.library.activePicker ~= animate then
				self.tab.library.activePicker(false, true)
			end
			
			self.tab.library.activePicker = animate
			lastColor = Color3.fromHSV(hue, sat, brightness)
			
			local mainFrame = self.tab.library.mainFrame
			local buttonPos = button.AbsolutePosition
			local buttonSize = button.AbsoluteSize
			local mainPos = mainFrame.AbsolutePosition
			
			local newX = (buttonPos.X - mainPos.X) + buttonSize.X
			local newY = (buttonPos.Y - mainPos.Y)
			
			tab.ClipsDescendants = true
			tab.Visible = true
			tab.Size = UDim2.new(0, 0, 0, 0)
			tab.Position = UDim2.fromOffset(newX, newY)
			
			utility:Tween(tab, {Size = UDim2.new(0, 162, 0, 169)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			
			task.wait(0.2)
			tab.ClipsDescendants = false
			
			canvasSize, canvasPosition = canvas.AbsoluteSize, canvas.AbsolutePosition
			colorSize, colorPosition = colorSlider.AbsoluteSize, colorSlider.AbsolutePosition
		else
			tab.ClipsDescendants = true
			utility:Tween(tab, {Size = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			
			task.wait(0.2)
			tab.Visible = false
		end
		
		debounce = false
	end
	
	button.Activated:Connect(function() animate(not toggle) end)
	tab.Container.Button.Activated:Connect(function() 
        animate(false) 
        callbackWrapper(colorpicker.Button.ImageColor3) -- Save on submit
    end)
	tab.Close.Activated:Connect(function()
		self:updateColorPicker(colorpicker, nil, lastColor)
        callbackWrapper(lastColor)
		animate(false)
	end)
	
	return colorpicker
end
	
function section:Resize(smooth)
	if self.tab.library.currentTab ~= self.tab then return end
	
	local padding = self.container.UIListLayout.Padding.Offset
	local size = self.container.Title.AbsoluteSize.Y + (padding*2)
	
	for i, module in pairs(self.modules) do
		size = size + module.AbsoluteSize.Y + padding
	end
	
	if smooth then
		utility:Tween(self.container.Parent, {Size = UDim2.new(1, -10, 0, size)}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.1, function() self.tab:Resize() end)
	else
		self.container.Parent.Size = UDim2.new(1, -10, 0, size)
		self.tab:Resize()
	end
end

function section:getModule(info)
	if typeof(info) == "Instance" and table.find(self.modules, info) then
		return info
	end
	
	for i, module in pairs(self.modules) do
        local titleLabel = module:FindFirstChild("Title") or module:FindFirstChild("TextBox", true)
		if titleLabel and titleLabel.Text == info then
			return module
		end
	end
	
	error("No module found under "..tostring(info))
end

function section:updateButton(button, title)
	button = self:getModule(button)
	button.Title.Text = title
end

function section:updateToggle(toggle, title, value)
	toggle = self:getModule(toggle)
	
	local position = { In = UDim2.new(0, 2, 0.5, -6), Out = UDim2.new(0, 20, 0.5, -6) }
	local frame = toggle.Button.Frame
	local state = value and "Out" or "In"
	
	if title then toggle.Title.Text = title end
	if value ~= nil then utility:Tween(frame, {Position = position[state]}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
end

function section:updateTextbox(textbox, title, value)
	textbox = self:getModule(textbox)
	if title then textbox.Title.Text = title end
	if value then textbox.Button.Textbox.Text = value end
end

function section:updateSlider(slider, title, value, min, max, fromMouse)
	slider = self:getModule(slider)
	
	local bar = slider.Slider.Bar
	local fill = bar.Fill
	local textbox = slider.TextBox
	local range = max - min
	
	if title then slider.Title.Text = title end
	
	if fromMouse then
		local mouseX = mouse.X - bar.AbsolutePosition.X
		local percent = math.clamp(mouseX / bar.AbsoluteSize.X, 0, 1)
		value = min + (range * percent)
	else
		value = math.clamp(tonumber(value) or min, min, max)
	end
	
	local percent = (range == 0) and 1 or (value - min) / range
	
	textbox.Text = string.format("%.2f", value)
	fill.Size = UDim2.new(percent, 0, 1, 0)
	
	return value
end

function section:updateDropdown(dropdown, title, list, callback, isSearch, isMultiChoice)
	dropdown = self:getModule(dropdown)
	local data = self.dropdownData[dropdown]
	local lib = self.tab.library
	
	local search = dropdown.Search
	local listContainer = dropdown.List
	local frame = listContainer.Frame
	
	if title then search.TextBox.Text = title end
	
	if list then
		if not isSearch then utility:Tween(search.Button, {Rotation = 90}, 0.2) end
		
		for _, v in pairs(frame:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end
		
		local canvasHeight = 0
		local padding = frame.UIListLayout.Padding.Offset
		
		for i, v in pairs(list) do
			local itemButton = utility:Create("TextButton", {
				Name = tostring(v), Parent = frame, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.Gotham,
				Text = "  " .. tostring(v), TextColor3 = themes.TextColor,
				TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i
			})
			canvasHeight = canvasHeight + 20 + padding

			if isMultiChoice then
				local isSelected = table.find(data.selectedItems, v)
				itemButton.Text = (isSelected and "✔ " or "  ") .. tostring(v)

				itemButton.MouseButton1Click:Connect(function()
					local selectedIndex = table.find(data.selectedItems, v)
					if selectedIndex then
						table.remove(data.selectedItems, selectedIndex)
						itemButton.Text = "  " .. tostring(v)
					else
						table.insert(data.selectedItems, v)
						itemButton.Text = "✔ " .. tostring(v)
					end
					
					local selectedText = table.concat(data.selectedItems, ", ")
					search.TextBox.Text = #selectedText > 0 and selectedText or (dropdown.Name or "Select...")
					
					if callback then task.spawn(callback, data.selectedItems) end
                    lib:saveProfile()
				end)
			else
				itemButton.MouseEnter:Connect(function() itemButton.TextTransparency = 0.5 end)
				itemButton.MouseLeave:Connect(function() itemButton.TextTransparency = 0 end)
				itemButton.MouseButton1Click:Connect(function()
					search.TextBox.Text = tostring(v)
                    search.TextBox.TextTransparency = 0
					if callback then task.spawn(callback, v) end
					search.TextBox:ReleaseFocus()
                    lib:saveProfile()
				end)
			end
		end
		
		local listHeight = math.min(canvasHeight - padding, 120)
		frame.CanvasSize = UDim2.new(0, 0, 0, canvasHeight - padding)
		
		local finalHeight = 30 + 4 + listHeight + 8
		utility:Tween(dropdown, {Size = UDim2.new(1, 0, 0, finalHeight)}, 0.2)
		utility:Tween(listContainer, {Size = UDim2.new(1, 0, 0, listHeight + 8)}, 0.2)
		task.delay(0.2, function() self:Resize(true) end)
		
	else
		utility:Tween(search.Button, {Rotation = 0}, 0.2)
		utility:Tween(listContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
		utility:Tween(dropdown, {Size = UDim2.new(1, 0, 0, 30)}, 0.2)
		task.delay(0.2, function() self:Resize(true) end)
	end
end

function section:updateColorPicker(colorpicker, title, value)
	colorpicker = self:getModule(colorpicker)
	local data = self.colorpickers[colorpicker]
	if not data then return end
	local tab = data.tab
	
	local canvas = tab.Container.Canvas
	local colorSlider = tab.Container.Color
	local inputs = tab.Container.Inputs
	
	local hue, sat, val, color3
	
	if type(value) == "table" then
		hue, sat, val = value[1], value[2], value[3]
		color3 = Color3.fromHSV(hue, sat, val)
	elseif typeof(value) == "Color3" then
		color3 = value
		hue, sat, val = Color3.toHSV(color3)
	else
		return
	end
	
	if title then
		colorpicker.Title.Text = title
		tab.Title.Text = title
	end
	
	colorpicker.Button.ImageColor3 = color3
	canvas.ImageColor3 = Color3.fromHSV(hue, 1, 1)
	
	canvas.Cursor.Position = UDim2.new(sat, 0, 1 - val, 0)
	colorSlider.Select.Position = UDim2.new(hue, 0, 0, 0)
	
	local r, g, b = tostring(math.floor(color3.R*255)), tostring(math.floor(color3.G*255)), tostring(math.floor(color3.B*255))
	if inputs.R.Textbox.Text ~= r then inputs.R.Textbox.Text = r end
	if inputs.G.Textbox.Text ~= g then inputs.G.Textbox.Text = g end
	if inputs.B.Textbox.Text ~= b then inputs.B.Textbox.Text = b end
end

local gui = library.new("Venyx")
local externalToggleButton = utility:Create("TextButton", {
    Name = "V",
    Parent = gui.container,
    Size = UDim2.new(0, 45, 0, 45),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
    BorderColor3 = Color3.fromRGB(80, 80, 80),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.Gotham,
    Text = "V",
    TextSize = 14
}, { 
    utility:Create("UICorner", {
    	Name = "Corner",
    	CornerRadius = UDim.new(0, 36)
  })
})
utility:DraggingEnabled(externalToggleButton, externalToggleButton)
externalToggleButton.MouseButton1Click:Connect(function()
    gui:toggle()
end)


local tab1 = gui:addTab("Main", "0")
local section1 = tab1:addSection("Controls")

local button1 = section1:addButton("Test Button", function(update)
	print("Button clicked!")
	task.wait(0.5)
	update("Button was clicked!")
end)

local toggle1 = section1:addToggle("Test Toggle", false, function(state, update)
	print("Toggle:", state)
end)

local slider1 = section1:addSlider("Speed", 50, 0, 100, function(value)
    print("Slider value:", value)
end)

local dropdown1 = section1:addDropdown("Select Item", {"Apple", "Banana", "Orange", "Grape", "Mango"}, function(item)
    print("Dropdown selected:", item)
end)

local multiDropdown = section1:addDropdown("Select Fruits", {"Strawberry", "Blueberry", "Raspberry"}, true, function(items)
    print("Multi-choice selection:", table.concat(items, ", "))
end)


local tab2 = gui:addTab("Settings", "0")
local section2 = tab2:addSection("Configuration")

local colorpicker1 = section2:addColorPicker("Primary Color", Color3.fromRGB(0, 120, 255), function(color)
    print("Color picked:", color)
    gui:setTheme("Accent", color)
end)

local button2 = section2:addButton("Notify Test", function()
	gui:Notify("Test Notification", "This is a test notification!", 5, function(accepted)
		print("Notification response:", accepted)
	end)
end)

local toggle2 = section2:addToggle("Theme Toggle", false, function(state)
	if state then
		gui:setTheme("Background", Color3.fromRGB(50, 50, 50))
	else
		gui:setTheme("Background", Color3.fromRGB(24, 24, 24))
	end
end)

local tab3 = gui:addTab("About", "0")
local section3 = tab3:addSection("Information")

section3:addButton("Toggle GUI", function()
    gui:toggle()
end)

section3:addButton("Uninject GUI", function()
    print("Uninjecting GUI...")
    gui:uninject()
end)

return library
