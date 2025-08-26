-- GraphRenderer.lua - Handles graph rendering

local GraphRenderer = {}
GraphRenderer.__index = GraphRenderer

-- Maximum values for scaling graphs
local MAX_VALUES = {
    fps = 120,
    memory = 1000,
    cpu = 100,
    render = 50,
    physics = 50,
    heartbeat = 50,
    networkReceive = 100,
    networkSend = 100
}

function GraphRenderer.new(graphFrames)
    local self = setmetatable({}, GraphRenderer)
    self.graphFrames = graphFrames
    return self
end

-- Helper function to create UI elements
local function createElement(className, properties, parent)
    local element = Instance.new(className)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    element.Parent = parent
    return element
end

function GraphRenderer:renderGraph(key, data)
    local graphInfo = self.graphFrames[key]
    if not graphInfo then return end
    
    local graphFrame = graphInfo.frame
    local color = graphInfo.color
    local maxValue = MAX_VALUES[key] or 100
    
    -- Clear previous graph
    graphFrame:ClearAllChildren()
    
    if #data < 2 then return end
    
    local width = graphFrame.AbsoluteSize.X
    local height = graphFrame.AbsoluteSize.Y
    local pointSpacing = width / 100 -- MAX_DATA_POINTS
    
    -- Draw grid lines
    for i = 0, 4 do
        local yPos = i * height / 4
        createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, yPos),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderSizePixel = 0,
            ZIndex = 1
        }, graphFrame)
    end
    
    -- Draw vertical grid lines
    for i = 0, 10 do
        local xPos = i * width / 10
        createElement("Frame", {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(0, xPos, 0, 0),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            ZIndex = 1
        }, graphFrame)
    end
    
    -- Create line container
    local lineContainer = createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 2
    }, graphFrame)
    
    -- Draw data line
    for i = 2, #data do
        local x1 = (i - 2) * pointSpacing
        local x2 = (i - 1) * pointSpacing
        local y1 = height - (data[i-1] / maxValue) * height
        local y2 = height - (data[i] / maxValue) * height
        
        -- Clamp y values
        y1 = math.clamp(y1, 0, height)
        y2 = math.clamp(y2, 0, height)
        
        -- Create line segment
        local length = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
        local angle = math.atan2(y2 - y1, x2 - x1)
        
        createElement("Frame", {
            Size = UDim2.new(0, length, 0, 3),
            Position = UDim2.new(0, x1, 0, y1),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Rotation = math.deg(angle),
            ZIndex = 3
        }, lineContainer)
        
        -- Add data point
        if i == #data then
            createElement("Frame", {
                Size = UDim2.new(0, 6, 0, 6),
                Position = UDim2.new(0, x2 - 3, 0, y2 - 3),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                ZIndex = 4
            }, lineContainer)
        end
    end
    
    -- Add scale labels
    local scaleContainer = createElement("Frame", {
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(0, -35, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 5
    }, graphFrame)
    
    for i = 0, 4 do
        local value = maxValue * (1 - i/4)
        local yPos = i * height / 4
        
        createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 0, yPos - 10),
            Text = string.format("%.0f", value),
            TextColor3 = Color3.fromRGB(150, 150, 150),
            TextScaled = true,
            Font = Enum.Font.SourceSans,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 5
        }, scaleContainer)
    end
end

function GraphRenderer:renderAll(data)
    for key, values in pairs(data) do
        self:renderGraph(key, values)
    end
end

function GraphRenderer:clear()
    for _, graphInfo in pairs(self.graphFrames) do
        graphInfo.frame:ClearAllChildren()
    end
end

return GraphRenderer