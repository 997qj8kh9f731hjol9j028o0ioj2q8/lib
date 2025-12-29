local Library = {
	directory = {
		["main_folder"] = "drawing",
		["fonts"] = "drawing/fonts/",
		["assets"] = "drawing/assets/",
	},
}

local fonts = {}; do
	function Register_Font(Name, Weight, Style, Asset)
		if not isfile(Library.directory["fonts"] .. Asset.Id) then
			writefile(Library.directory["fonts"] .. Asset.Id, Asset.Font)
		end

		if isfile(Library.directory["fonts"] .. Name .. ".font") then
			delfile(Library.directory["fonts"] .. Name .. ".font")
		end

		local Data = {
			name = Name,
			faces = {
				{
					name = "Regular",
					weight = Weight,
					style = Style,
					assetId = getcustomasset(Library.directory["fonts"] .. Asset.Id),
				},
			},
		}

		writefile(Library.directory["fonts"] .. Name .. ".font", game:GetService("HttpService"):JSONEncode(Data))

		return getcustomasset(Library.directory["fonts"] .. Name .. ".font");
	end

	local ProggyTiny = Register_Font("ProggyTiny", 200, "Normal", {
		Id = "ProggyTiny.ttf",
		Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/tahoma_bold.ttf"),
	})

	local ProggyClean = Register_Font("ProggyClean", 200, "normal", {
		Id = "ProggyClean.ttf",
		Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf")
	})

	local Tahoma = Register_Font("ProggyClean", 200, "normal", {
		Id = "Tahoma.ttf",
		Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf")
	})

	font = {
		["TahomaBold"] = Font.new(ProggyTiny, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		["ProggyClean"] = Font.new(ProggyClean, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		["Tahoma"] = Font.new(Tahoma, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	}
end




local DrawingLib = {}
local RunService = game:GetService("RunService")

-- Create container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DrawingLibContainer"
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 2147483647
ScreenGui.ResetOnSpawn = false

ScreenGui.Parent = game:GetService("CoreGui")

local ObjectCounter = 0

-- Base Drawing Object
local function CreateDrawingObject(objectType)
	ObjectCounter = ObjectCounter + 1

	local obj = {
		_type = objectType,
		_id = ObjectCounter,
		_instance = nil,
		Visible = false,
		Color = Color3.new(1, 1, 1),
		Transparency = 1,
		Remove = function(self)
			if self._instance then
				self._instance:Destroy()
				self._instance = nil
			end
		end,
		Destroy = function(self)
			self:Remove()
		end
	}

	return obj
end

-- Line Object
function DrawingLib.Line()
	local line = CreateDrawingObject("Line")

	line.Thickness = 1
	line.From = Vector2.new(0, 0)
	line.To = Vector2.new(0, 0)

	local frame = Instance.new("Frame")
	frame.Name = "Line_" .. line._id
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Parent = ScreenGui
	line._instance = frame

	local function Update()
		if not line._instance then return end

		frame.Visible = line.Visible
		frame.BackgroundColor3 = line.Color
		frame.BackgroundTransparency = 1 - line.Transparency

		local from = line.From
		local to = line.To
		local distance = (to - from).Magnitude
		local angle = math.atan2(to.Y - from.Y, to.X - from.X)

		frame.Size = UDim2.new(0, distance, 0, line.Thickness)
		frame.Position = UDim2.new(0, (from.X + to.X) / 2, 0, (from.Y + to.Y) / 2)
		frame.Rotation = math.deg(angle)
	end

	-- Auto-update on property changes
	local mt = setmetatable({}, {
		__index = line,
		__newindex = function(t, k, v)
			if v ~= nil or k == "Visible" then
				line[k] = v
				Update()
			end
		end
	})

	return mt
end

-- Square/Rectangle Object
function DrawingLib.Square()
	local square = CreateDrawingObject("Square")

	square.Thickness = 1
	square.Filled = false
	square.Size = Vector2.new(100, 100)
	square.Position = Vector2.new(0, 0)
	square.ZIndex = 1

	local frame = Instance.new("Frame")
	frame.Name = "Square_" .. square._id
	frame.Parent = ScreenGui
	frame.BorderSizePixel = 0
	frame.ZIndex = square.ZIndex
	square._instance = frame

	local outline = Instance.new("UIStroke")
	outline.Parent = frame
	outline.LineJoinMode = Enum.LineJoinMode.Miter

	local function Update()
		if not square._instance then return end

		frame.Visible = square.Visible
		frame.Size = UDim2.new(0, square.Size.X, 0, square.Size.Y)
		frame.Position = UDim2.new(0, square.Position.X, 0, square.Position.Y)

		if square.Filled then
			frame.BackgroundColor3 = square.Color
			frame.BackgroundTransparency = 1 - square.Transparency
			outline.Enabled = false
		else
			frame.BackgroundTransparency = 1
			outline.Enabled = true
			outline.Color = square.Color
			outline.Transparency = 1 - square.Transparency
			outline.Thickness = square.Thickness
		end
	end

	local mt = setmetatable({}, {
		__index = square,
		__newindex = function(t, k, v)
			if v ~= nil or k == "Visible" then
				square[k] = v
				Update()
			end
		end
	})

	return mt
end

-- Circle Object
function DrawingLib.Circle()
	local circle = CreateDrawingObject("Circle")

	circle.Thickness = 1
	circle.NumSides = 64
	circle.Radius = 50
	circle.Filled = false
	circle.Position = Vector2.new(0, 0)

	local frame = Instance.new("Frame")
	frame.Name = "Circle_" .. circle._id
	frame.Parent = ScreenGui
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	circle._instance = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local outline = Instance.new("UIStroke")
	outline.Parent = frame
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local function Update()
		if not circle._instance then return end

		frame.Visible = circle.Visible
		local diameter = circle.Radius * 2
		frame.Size = UDim2.new(0, diameter, 0, diameter)
		frame.Position = UDim2.new(0, circle.Position.X, 0, circle.Position.Y)

		if circle.Filled then
			frame.BackgroundColor3 = circle.Color
			frame.BackgroundTransparency = 1 - circle.Transparency
			outline.Enabled = false
		else
			frame.BackgroundTransparency = 1
			outline.Enabled = true
			outline.Color = circle.Color
			outline.Transparency = 1 - circle.Transparency
			outline.Thickness = circle.Thickness
		end
	end

	local mt = setmetatable({}, {
		__index = circle,
		__newindex = function(t, k, v)
			if v ~= nil or k == "Visible" then
				circle[k] = v
				Update()
			end
		end
	})

	return mt
end

-- Text Object
function DrawingLib.Text()
	local text = CreateDrawingObject("Text")

	text.Text = ""
	text.Size = 12
	text.Center = false
	text.Outline = false
	text.OutlineColor = Color3.new(0, 0, 0)
	text.Position = Vector2.new(0, 0)
	text.FontFace = Library.font

	local label = Instance.new("TextLabel")
	label.Name = "Text_" .. text._id
	label.BackgroundTransparency = 1
	label.Parent = ScreenGui
	label.RichText = false
	label.TextScaled = false
	label.TextStrokeTransparency = 0
	label.AutomaticSize = Enum.AutomaticSize.XY
	text._instance = label

	local stroke = Instance.new("UIStroke")
	stroke.Parent = label
	stroke.Thickness = 1
	stroke.Enabled = false

	local function Update()
		if not text._instance then return end

		label.Visible = text.Visible
		label.Text = text.Text
		label.TextSize = text.Size
		label.TextColor3 = text.Color
		label.TextTransparency = 1 - text.Transparency
		label.FontFace = text.FontFace or font.ProggyClean

		if text.Center then
			label.Position = UDim2.new(0, text.Position.X, 0, text.Position.Y)
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextYAlignment = Enum.TextYAlignment.Center
		else
			label.Position = UDim2.new(0, text.Position.X, 0, text.Position.Y)
			label.AnchorPoint = Vector2.new(0, 0)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Top
		end

		if text.Outline then
			stroke.Enabled = true
			stroke.Color = text.OutlineColor
		else
			stroke.Enabled = false
		end
	end

	local mt = setmetatable({}, {
		__index = text,
		__newindex = function(t, k, v)
			if v ~= nil or k == "Visible" or k == "Text" then
				text[k] = v
				Update()
			end
		end
	})

	return mt
end

-- Triangle Object
function DrawingLib.Triangle()
	local triangle = CreateDrawingObject("Triangle")

	triangle.Thickness = 1
	triangle.Filled = true
	triangle.PointA = Vector2.new(0, 0)
	triangle.PointB = Vector2.new(50, 100)
	triangle.PointC = Vector2.new(100, 0)

	local frame = Instance.new("Frame")
	frame.Name = "Triangle_" .. triangle._id
	frame.BackgroundTransparency = 1
	frame.Parent = ScreenGui
	triangle._instance = frame

	-- Create 3 lines for triangle outline or filled version
	local lines = {}
	for i = 1, 3 do
		local line = Instance.new("Frame")
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Parent = frame
		table.insert(lines, line)
	end

	local function Update()
		if not triangle._instance then return end

		frame.Visible = triangle.Visible

		local pointA = triangle.PointA
		local pointB = triangle.PointB
		local pointC = triangle.PointC

		-- Calculate bounding box
		local minX = math.min(pointA.X, pointB.X, pointC.X)
		local maxX = math.max(pointA.X, pointB.X, pointC.X)
		local minY = math.min(pointA.Y, pointB.Y, pointC.Y)
		local maxY = math.max(pointA.Y, pointB.Y, pointC.Y)

		frame.Position = UDim2.new(0, minX, 0, minY)
		frame.Size = UDim2.new(0, maxX - minX, 0, maxY - minY)

		-- Draw triangle edges
		local edges = {
			{pointA, pointB},
			{pointB, pointC},
			{pointC, pointA}
		}

		for i, edge in ipairs(edges) do
			local from = edge[1] - Vector2.new(minX, minY)
			local to = edge[2] - Vector2.new(minX, minY)
			local distance = (to - from).Magnitude
			local angle = math.atan2(to.Y - from.Y, to.X - from.X)

			lines[i].Visible = triangle.Visible
			lines[i].BackgroundColor3 = triangle.Color
			lines[i].BackgroundTransparency = 1 - triangle.Transparency
			lines[i].Size = UDim2.new(0, distance, 0, triangle.Thickness)
			lines[i].Position = UDim2.new(0, (from.X + to.X) / 2, 0, (from.Y + to.Y) / 2)
			lines[i].Rotation = math.deg(angle)
		end
	end

	local mt = setmetatable({}, {
		__index = triangle,
		__newindex = function(t, k, v)
			if v ~= nil or k == "Visible" then
				triangle[k] = v
				Update()
			end
		end
	})

	return mt
end

-- Quad Object (4-sided polygon)
function DrawingLib.Quad()
	local quad = CreateDrawingObject("Quad")

	quad.Thickness = 1
	quad.Filled = false
	quad.PointA = Vector2.new(0, 0)
	quad.PointB = Vector2.new(100, 0)
	quad.PointC = Vector2.new(100, 100)
	quad.PointD = Vector2.new(0, 100)

	local frame = Instance.new("Frame")
	frame.Name = "Quad_" .. quad._id
	frame.BackgroundTransparency = 1
	frame.Parent = ScreenGui
	quad._instance = frame

	-- Create 4 lines for quad outline
	local lines = {}
	for i = 1, 4 do
		local line = Instance.new("Frame")
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Parent = frame
		table.insert(lines, line)
	end

	local function Update()
		if not quad._instance then return end

		frame.Visible = quad.Visible

		local points = {quad.PointA, quad.PointB, quad.PointC, quad.PointD}

		local minX = math.min(points[1].X, points[2].X, points[3].X, points[4].X)
		local maxX = math.max(points[1].X, points[2].X, points[3].X, points[4].X)
		local minY = math.min(points[1].Y, points[2].Y, points[3].Y, points[4].Y)
		local maxY = math.max(points[1].Y, points[2].Y, points[3].Y, points[4].Y)

		frame.Position = UDim2.new(0, minX, 0, minY)
		frame.Size = UDim2.new(0, maxX - minX, 0, maxY - minY)

		local edges = {
			{points[1], points[2]},
			{points[2], points[3]},
			{points[3], points[4]},
			{points[4], points[1]}
		}

		for i, edge in ipairs(edges) do
			local from = edge[1] - Vector2.new(minX, minY)
			local to = edge[2] - Vector2.new(minX, minY)
			local distance = (to - from).Magnitude
			local angle = math.atan2(to.Y - from.Y, to.X - from.X)

			lines[i].Visible = quad.Visible
			lines[i].BackgroundColor3 = quad.Color
			lines[i].BackgroundTransparency = 1 - quad.Transparency
			lines[i].Size = UDim2.new(0, distance, 0, quad.Thickness)
			lines[i].Position = UDim2.new(0, (from.X + to.X) / 2, 0, (from.Y + to.Y) / 2)
			lines[i].Rotation = math.deg(angle)
		end
	end

	local mt = setmetatable({}, {
		__index = quad,
		__newindex = function(t, k, v)
			if v ~= nil or k == "Visible" then
				quad[k] = v
				Update()
			end
		end
	})

	return mt
end

function DrawingLib.Image()
	local image = CreateDrawingObject("Image")

	image.Data = ""
	image.Size = Vector2.new(100, 100)
	image.Position = Vector2.new(0, 0)
	image.Rounding = 0

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Image_" .. image._id
	imageLabel.BackgroundTransparency = 1
	imageLabel.Parent = ScreenGui
	image._instance = imageLabel

	local corner = Instance.new("UICorner")
	corner.Parent = imageLabel

	local function Update()
		if not image._instance then return end

		imageLabel.Visible = image.Visible
		imageLabel.Size = UDim2.new(0, image.Size.X, 0, image.Size.Y)
		imageLabel.Position = UDim2.new(0, image.Position.X, 0, image.Position.Y)
		imageLabel.Image = image.Data
		imageLabel.ImageColor3 = image.Color
		imageLabel.ImageTransparency = 1 - image.Transparency
		corner.CornerRadius = UDim.new(0, image.Rounding)
	end

	local mt = setmetatable({}, {
		__index = image,
		__newindex = function(t, k, v)
			if v ~= nil or k == "Visible" then
				image[k] = v
				Update()
			end
		end
	})

	return mt
end

local Drawing = {}
Drawing.Fonts = {
	UI = 0,
	System = 1,
	Plex = 2,
	Monospace = 3
}

function Drawing.new(objectType)
	if objectType == "Line" then
		return DrawingLib.Line()
	elseif objectType == "Square" then
		return DrawingLib.Square()
	elseif objectType == "Circle" then
		return DrawingLib.Circle()
	elseif objectType == "Text" then
		return DrawingLib.Text()
	elseif objectType == "Triangle" then
		return DrawingLib.Triangle()
	elseif objectType == "Quad" then
		return DrawingLib.Quad()
	elseif objectType == "Image" then
		return DrawingLib.Image()
	else
		error("Invalid Drawing object type: " .. tostring(objectType))
	end
end

--  function
function Drawing.Clear()
	ScreenGui:ClearAllChildren()
end

return Drawing
