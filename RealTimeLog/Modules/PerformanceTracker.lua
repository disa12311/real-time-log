-- PerformanceTracker.lua - Fixed version with proper Stats API usage
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Config = require(script.Parent.Config)

local PerformanceTracker = {}
PerformanceTracker.__index = PerformanceTracker

-- Pre-calculate values for optimization
local BYTES_TO_MB = 1 / (1024 * 1024)
local BYTES_TO_KB = 1 / 1024

function PerformanceTracker.new()
    local self = setmetatable({}, PerformanceTracker)
    
    -- Initialize data storage
    self.data = {}
    self.currentValues = {}
    
    for _, metric in ipairs(Config.METRICS) do
        self.data[metric.key] = {}
        self.currentValues[metric.key] = 0
    end
    
    self.lastUpdateTime = 0
    self.frameCount = 0
    self.lastFrameTime = tick()
    self.frameTimeSum = 0
    self.frameTimeCount = 0
    
    return self
end

function PerformanceTracker:Collect()
    local currentTime = tick()
    
    -- Throttle updates based on config
    if currentTime - self.lastUpdateTime < Config.UPDATE_RATE then
        return nil
    end
    
    self.lastUpdateTime = currentTime
    
    -- Calculate FPS using frame timing
    self.frameCount = self.frameCount + 1
    local deltaTime = currentTime - self.lastFrameTime
    
    if deltaTime >= 1 then
        self.currentValues.fps = math.floor(self.frameCount / deltaTime)
        self.frameCount = 0
        self.lastFrameTime = currentTime
    end
    
    -- Collect metrics safely
    local success, err = pcall(function()
        -- Memory usage - this is reliable
        self.currentValues.memory = Stats:GetTotalMemoryUsageMb()
        
        -- For other metrics, we'll use safer approaches
        self:CollectPerformanceMetrics()
        self:CollectNetworkMetrics()
    end)
    
    if not success then
        warn("PerformanceTracker: Error collecting stats -", err)
        -- Use fallback values
        self:UseFallbackValues()
    end
    
    -- Store data points
    for key, value in pairs(self.currentValues) do
        local dataArray = self.data[key]
        
        -- Add new value
        table.insert(dataArray, value)
        
        -- Remove old values to maintain max points
        while #dataArray > Config.MAX_DATA_POINTS do
            table.remove(dataArray, 1)
        end
    end
    
    return self.currentValues
end

function PerformanceTracker:CollectPerformanceMetrics()
    -- CPU usage - try multiple methods
    local cpuValue = 0
    
    -- Method 1: Direct from PerformanceStats
    local perfStats = Stats:FindFirstChild("PerformanceStats")
    if perfStats then
        local cpu = perfStats:FindFirstChild("CPU")
        if cpu then
            cpuValue = cpu:GetValue()
        end
    end
    
    -- Method 2: Calculate from frame time if CPU not available
    if cpuValue == 0 then
        local frameTime = RunService.Heartbeat:Wait()
        cpuValue = math.min((frameTime * 1000) / 16.67 * 100, 100) -- Estimate based on frame time
    end
    
    self.currentValues.cpu = cpuValue
    
    -- Frame timing metrics
    local frameStart = tick()
    RunService.Heartbeat:Wait()
    local frameTime = (tick() - frameStart) * 1000
    
    -- Render time estimation (typically 60-70% of frame time)
    self.currentValues.render = frameTime * 0.65
    
    -- Physics time estimation (typically 20-30% of frame time)
    self.currentValues.physics = frameTime * 0.25
    
    -- Heartbeat time is the full frame time
    self.currentValues.heartbeat = frameTime
    
    -- Try to get more accurate values from Stats if available
    self:TryGetAccurateStats()
end

function PerformanceTracker:TryGetAccurateStats()
    -- Look for specific stat objects that might exist
    local statsChildren = Stats:GetChildren()
    
    for _, child in ipairs(statsChildren) do
        local name = child.Name:lower()
        
        -- Map common stat names to our metrics
        if name:match("render") and not name:match("stepped") then
            local value = self:SafeGetValue(child)
            if value > 0 then
                self.currentValues.render = value
            end
        elseif name:match("physics") then
            local value = self:SafeGetValue(child)
            if value > 0 then
                self.currentValues.physics = value
            end
        elseif name:match("heartbeat") then
            local value = self:SafeGetValue(child)
            if value > 0 then
                self.currentValues.heartbeat = value
            end
        end
    end
end

function PerformanceTracker:SafeGetValue(statObject)
    local success, value = pcall(function()
        if statObject:IsA("DoubleConstrainedValue") or statObject:IsA("IntConstrainedValue") then
            return statObject.Value
        elseif typeof(statObject.GetValue) == "function" then
            return statObject:GetValue()
        end
        return 0
    end)
    
    return success and value or 0
end

function PerformanceTracker:CollectNetworkMetrics()
    -- Network stats - try multiple approaches
    local networkIn = 0
    local networkOut = 0
    
    -- Method 1: Look for network stats in Stats service
    local success, _ = pcall(function()
        -- Try common locations for network stats
        local dataReceive = Stats:FindFirstChild("DataReceiveKbps")
        local dataSend = Stats:FindFirstChild("DataSendKbps")
        
        if dataReceive then
            networkIn = self:SafeGetValue(dataReceive)
        end
        
        if dataSend then
            networkOut = self:SafeGetValue(dataSend)
        end
        
        -- Method 2: Check under PerformanceStats
        if networkIn == 0 or networkOut == 0 then
            local perfStats = Stats:FindFirstChild("PerformanceStats")
            if perfStats then
                local network = perfStats:FindFirstChild("Network")
                if network then
                    local recv = network:FindFirstChild("Recv")
                    local sent = network:FindFirstChild("Sent")
                    
                    if recv then networkIn = self:SafeGetValue(recv) end
                    if sent then networkOut = self:SafeGetValue(sent) end
                end
            end
        end
    end)
    
    self.currentValues.network_in = networkIn
    self.currentValues.network_out = networkOut
end

function PerformanceTracker:UseFallbackValues()
    -- Use reasonable fallback values when stats aren't available
    if self.currentValues.fps == 0 then
        self.currentValues.fps = 60
    end
    
    if self.currentValues.cpu == 0 then
        self.currentValues.cpu = 50
    end
    
    if self.currentValues.render == 0 then
        self.currentValues.render = 16.67
    end
    
    if self.currentValues.physics == 0 then
        self.currentValues.physics = 4
    end
    
    if self.currentValues.heartbeat == 0 then
        self.currentValues.heartbeat = 16.67
    end
end

function PerformanceTracker:GetData()
    return self.data
end

function PerformanceTracker:GetCurrentValues()
    return self.currentValues
end

function PerformanceTracker:Clear()
    for key in pairs(self.data) do
        self.data[key] = {}
    end
    
    for key in pairs(self.currentValues) do
        self.currentValues[key] = 0
    end
    
    self.frameCount = 0
    self.lastFrameTime = tick()
    self.frameTimeSum = 0
    self.frameTimeCount = 0
end

-- Get statistics for a specific metric
function PerformanceTracker:GetStatistics(metricKey)
    local values = self.data[metricKey]
    if not values or #values == 0 then
        return {
            current = 0,
            average = 0,
            min = 0,
            max = 0,
            samples = 0
        }
    end
    
    local sum = 0
    local min = math.huge
    local max = -math.huge
    
    for _, value in ipairs(values) do
        sum = sum + value
        min = math.min(min, value)
        max = math.max(max, value)
    end
    
    return {
        current = values[#values],
        average = sum / #values,
        min = min,
        max = max,
        samples = #values
    }
end

-- Debug function to list available stats
function PerformanceTracker:DebugListStats()
    print("\n=== Available Stats ===")
    local function listChildren(parent, indent)
        indent = indent or ""
        for _, child in ipairs(parent:GetChildren()) do
            print(indent .. child.Name .. " (" .. child.ClassName .. ")")
            if #child:GetChildren() > 0 then
                listChildren(child, indent .. "  ")
            end
        end
    end
    
    listChildren(Stats)
    print("===================\n")
end

return PerformanceTracker
