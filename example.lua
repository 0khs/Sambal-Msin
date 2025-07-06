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