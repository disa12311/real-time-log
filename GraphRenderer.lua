-- GraphRenderer.lua - Optimized graph rendering with object pooling
local Config = require(script.Parent.Config)

local GraphRenderer = {}
GraphRenderer.__index = GraphRenderer

-- Object pools for performance
local linePool = {}
local pointPool = {}
local POOL_SIZE = 200

function GraphRenderer.new(graphFrames)
    local self = setmetatable({}, GraphRenderer)
    
    self.graphFrames = graphFrames
    self.lineObjects = {}
    self.gridCache = {}
    
    -- Initialize object pools
    self:InitializePools()
    
    -- Pre-create grids for all graphs
    for key, graphInfo in pairs(graphFrames) do
        self:CreateGrid(graphInfo.frame, key)
    end
    
    return self
end

function GraphRenderer:InitializePools()
    -- Pre-create line objects
    for i = 1, POOL_SIZE do
        local line = Instance.new("Frame")
        line.BorderSizePixel = 0
        line.Size = UDim2.new(0, 1, 0, 2)
        line.ZIndex = 3
        linePool[i] = line
    end
    
    -- Pre-create point objects
    for i = 1, 50 do
        local point = Instance.new("Frame")
        point.BorderSizePixel = 0
        point.Size = UDim2.new(0, 4, 0, 4)
        point.ZIndex = 4
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = point
        
        pointPool[i] = point
    end
end

function GraphRenderer:GetFromPool(pool)
    for i, obj in ipairs(pool) do
        if not obj.Parent then
            return obj
        end
    end
    
    -- Create new object if pool is exhausted
    local newObj = Instance.new("Frame")
    newObj.BorderSizePixel = 0
    newObj.Size = pool[1].Size
    newObj.ZIndex = pool[1].ZIndex
    return newObj
end

function GraphRenderer:ReturnToPool(obj)
    obj.Parent = nil
end

function GraphRenderer:CreateGrid(frame, key)
    local gridContainer = Instance.new("Frame")
    gridContainer.Name = "Grid"
    gridContainer.Size = UDim2.new(1, 0, 1, 0)
    gridContainer.BackgroundTransparency = 1
    gridContainer.ZIndex = 1
    gridContainer.Parent = frame
    
    -- Create horizontal grid lines
    for i = 0, 4 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, i / 4, 0)
        line.BackgroundColor3 = Config.COLORS.GRID
        line.BorderSizePixel = 0
        line.BackgroundTransparency = 0.7
        line.Parent = gridContainer
    end
    
    -- Create vertical grid lines
    for i = 0, 10 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 1, 1, 0)
        line.Position = UDim2.new(i / 10, 0, 0, 0)
        line.BackgroundColor3 = Config.COLORS.GRID
        line.BorderSizePixel = 0
        line.BackgroundTransparency = 0.8
        line.Parent = gridContainer
    end
    
    -- Create scale labels
    self:CreateScaleLabels(frame, key)
    
    self.gridCache[key] = gridContainer
end

function GraphRenderer:CreateScaleLabels(frame, key)
    local metric = nil
    for _, m in ipairs(Config.METRICS) do
        if m.key == key then
            metric = m
            break
        end
    end
    
    if not metric then return end
    
    local labelContainer = Instance.new("Frame")
    labelContainer.Name = "Labels"
    labelContainer.Size = UDim2.new(0, 40, 1, 0)
    labelContainer.Position = UDim2.new(0, -45, 0, 0)
    labelContainer.BackgroundTransparency = 1
    labelContainer.ZIndex = 5
    labelContainer.Parent = frame
    
    for i = 0, 4 do
        local value = metric.maxValue * (1 - i / 4)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, i / 4, -10)
        label.Text = string.format("%.0f", value)
        label.TextColor3 = Config.COLORS.TEXT_DIM
        label.Font = Enum.Font.Gotham
        label.TextScaled = true
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Right
        label.Parent = labelContainer
    end
end

function GraphRenderer:RenderGraph(key, data)
    local graphInfo = self.graphFrames[key]
    if not graphInfo or not data or #data < 2 then return end
    
    local frame = graphInfo.frame
    local metric = graphInfo.metric
    
    -- Clear previous line objects (keep grid)
    if self.lineObjects[key] then
        for _, obj in ipairs(self.lineObjects[key]) do
            self:ReturnToPool(obj)
        end
    end
    self.lineObjects[key] = {}
    
    -- Get or create line container
    local lineContainer = frame:FindFirstChild("Lines") or Instance.new("Frame")
    if not lineContainer.Parent then
        lineContainer.Name = "Lines"
        lineContainer.Size = UDim2.new(1, 0, 1, 0)
        lineContainer.BackgroundTransparency = 1
        lineContainer.ZIndex = 2
        lineContainer.Parent = frame
    end
    
    local width = frame.AbsoluteSize.X
    local height = frame.AbsoluteSize.Y
    
    if width <= 0 or height <= 0 then return end
    
    local pointSpacing = width / Config.MAX_DATA_POINTS
    local maxValue = metric.maxValue
    
    -- Render with optimized line segments
    local points = {}
    for i, value in ipairs(data) do
        local x = (i - 1) * pointSpacing
        local y = height - (math.clamp(value, 0, maxValue) / maxValue) * height
        table.insert(points, {x = x, y = y})
    end
    
    -- Draw lines between points
    for i = 2, #points do
        local p1 = points[i - 1]
        local p2 = points[i]
        
        local line = self:GetFromPool(linePool)
        line.BackgroundColor3 = metric.color
        
        -- Calculate line position and rotation
        local dx = p2.x - p1.x
        local dy = p2.y - p1.y
        local length = math.sqrt(dx * dx + dy * dy)
        local angle = math.atan2(dy, dx)
        
        line.Size = UDim2.new(0, length, 0, 2)
        line.Position = UDim2.new(0, p1.x, 0, p1.y)
        line.Rotation = math.deg(angle)
        line.Parent = lineContainer
        
        table.insert(self.lineObjects[key], line)
    end
    
    -- Add current value point
    if #points > 0 then
        local lastPoint = points[#points]
        local point = self:GetFromPool(pointPool)
        point.BackgroundColor3 = metric.color
        point.Position = UDim2.new(0, lastPoint.x - 2, 0, lastPoint.y - 2)
        point.Parent = lineContainer
        table.insert(self.lineObjects[key], point)
        
        -- Add glow effect to current point
        local glow = point:FindFirstChild("Glow") or Instance.new("PointLight")
        glow.Name = "Glow"
        glow.Brightness = 2
        glow.Color = metric.color
        glow.Parent = point
    end
end

function GraphRenderer:RenderAll(allData)
    for key, data in pairs(allData) do
        self:RenderGraph(key, data)
    end
end

function GraphRenderer:Clear()
    for key, objects in pairs(self.lineObjects) do
        for _, obj in ipairs(objects) do
            self:ReturnToPool(obj)
        end
    end
    self.lineObjects = {}
    
    -- Clear line containers but keep grids
    for _, graphInfo in pairs(self.graphFrames) do
        local lineContainer = graphInfo.frame:FindFirstChild("Lines")
        if lineContainer then
            lineContainer:ClearAllChildren()
        end
    end
end

return GraphRenderer
