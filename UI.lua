-- UI.lua - Handles all UI creation and layout

local UI = {}

-- Helper function to create UI elements
local function createElement(className, properties, parent)
    local element = Instance.new(className)
    for prop, value in pairs(properties) do
        element[prop] = value
    end
    element.Parent = parent
    return element
end

-- Metric definitions
local metrics = {
    {name = "FPS", key = "fps", color = Color3.fromRGB(100, 255, 100)},
    {name = "Memory (MB)", key = "memory", color = Color3.fromRGB(255, 255, 100)},
    {name = "CPU %", key = "cpu", color = Color3.fromRGB(255, 100, 100)},
    {name = "Render Time (ms)", key = "render", color = Color3.fromRGB(100, 200, 255)},
    {name = "Physics (ms)", key = "physics", color = Color3.fromRGB(255, 150, 100)},
    {name = "Heartbeat (ms)", key = "heartbeat", color = Color3.fromRGB(200, 100, 255)},
    {name = "Network In (KB/s)", key = "networkReceive", color = Color3.fromRGB(100, 255, 200)},
    {name = "Network Out (KB/s)", key = "networkSend", color = Color3.fromRGB(255, 100, 200)}
}

function UI.create(parent)
    local components = {
        graphFrames = {},
        valueLabels = {}
    }
    
    -- Main frame
    local mainFrame = createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0
    }, parent)
    
    -- Header
    local header = createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0
    }, mainFrame)
    
    -- Title and status
    local titleLabel = createElement("TextLabel", {
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = "Real-Time Performance Monitor",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextScaled = true,
        Font = Enum.Font.SourceSansBold,
        BackgroundTransparency = 1
    }, header)
    
    -- Status indicator
    local statusFrame = createElement("Frame", {
        Size = UDim2.new(0.2, 0, 1, 0),
        Position = UDim2.new(0.4, 0, 0, 0),
        BackgroundTransparency = 1
    }, header)
    
    components.statusLabel = createElement("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        Text = "● Stopped",
        TextColor3 = Color3.fromRGB(255, 100, 100),
        TextScaled = true,
        Font = Enum.Font.SourceSans,
        BackgroundTransparency = 1
    }, statusFrame)
    
    -- Control panel
    local controlPanel = createElement("Frame", {
        Size = UDim2.new(0.4, -10, 1, 0),
        Position = UDim2.new(0.6, 0, 0, 0),
        BackgroundTransparency = 1
    }, header)
    
    components.clearButton = createElement("TextButton", {
        Size = UDim2.new(0, 80, 0, 30),
        Position = UDim2.new(1, -170, 0.5, -15),
        Text = "Clear",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Color3.fromRGB(150, 50, 50),
        Font = Enum.Font.SourceSans,
        BorderSizePixel = 0
    }, controlPanel)
    
    components.exportButton = createElement("TextButton", {
        Size = UDim2.new(0, 80, 0, 30),
        Position = UDim2.new(1, -80, 0.5, -15),
        Text = "Export",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Color3.fromRGB(50, 50, 150),
        Font = Enum.Font.SourceSans,
        BorderSizePixel = 0
    }, controlPanel)
    
    -- Scrolling frame for graphs
    local scrollFrame = createElement("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -60),
        Position = UDim2.new(0, 10, 0, 55),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        ScrollBarThickness = 8,
        CanvasSize = UDim2.new(0, 0, 0, 1200)
    }, mainFrame)
    
    -- Create metric sections
    local GRAPH_HEIGHT = 150
    
    for i, metric in ipairs(metrics) do
        local yPos = (i - 1) * (GRAPH_HEIGHT + 30)
        
        -- Metric container
        local container = createElement("Frame", {
            Size = UDim2.new(1, -20, 0, GRAPH_HEIGHT + 25),
            Position = UDim2.new(0, 10, 0, yPos + 10),
            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            BorderSizePixel = 0
        }, scrollFrame)
        
        -- Metric label
        local label = createElement("TextLabel", {
            Size = UDim2.new(0.7, 0, 0, 20),
            Position = UDim2.new(0, 5, 0, 2),
            Text = metric.name,
            TextColor3 = metric.color,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.SourceSansBold,
            BackgroundTransparency = 1
        }, container)
        
        -- Current value label
        local valueLabel = createElement("TextLabel", {
            Size = UDim2.new(0.3, -10, 0, 20),
            Position = UDim2.new(0.7, 0, 0, 2),
            Text = "Waiting...",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Right,
            Font = Enum.Font.SourceSans,
            BackgroundTransparency = 1
        }, container)
        components.valueLabels[metric.key] = valueLabel
        
        -- Graph frame
        local graphFrame = createElement("Frame", {
            Size = UDim2.new(1, -10, 0, GRAPH_HEIGHT - 25),
            Position = UDim2.new(0, 5, 0, 25),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, container)
        components.graphFrames[metric.key] = {
            frame = graphFrame,
            color = metric.color
        }
    end
    
    return components
end

UI.metrics = metrics

return UI