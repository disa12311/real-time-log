-- PerformanceTracker.lua - Optimized performance data collection
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Config = require(script.Parent.Config)

local PerformanceTracker = {}
PerformanceTracker.__index = PerformanceTracker

-- Pre-calculate values for optimization
local NANO_TO_MS = 1e-6
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
    
    -- Cache Stats objects for performance
    self.statsCache = {
        performance = Stats.PerformanceStats,
        render = Stats.RenderStepped,
        physics = Stats.Physics,
        heartbeat = Stats.Heartbeat,
        network = Stats.Network
    }
    
    return self
end

function PerformanceTracker:Collect()
    local currentTime = tick()
    
    -- Throttle updates based on config
    if currentTime - self.lastUpdateTime < Config.UPDATE_RATE then
        return nil
    end
    
    self.lastUpdateTime = currentTime
    
    -- Calculate FPS more accurately
    self.frameCount = self.frameCount + 1
    local deltaTime = currentTime - self.lastFrameTime
    
    if deltaTime >= 1 then
        self.currentValues.fps = math.floor(self.frameCount / deltaTime)
        self.frameCount = 0
        self.lastFrameTime = currentTime
    end
    
    -- Collect other metrics with error handling
    local success, err = pcall(function()
        -- Memory usage
        self.currentValues.memory = Stats:GetTotalMemoryUsageMb()
        
        -- CPU usage (percentage)
        self.currentValues.cpu = self.statsCache.performance.CPU:GetValue()
        
        -- Render time (convert from microseconds to milliseconds)
        self.currentValues.render = self.statsCache.render:GetValue() * NANO_TO_MS
        
        -- Physics time
        local physicsStats = self.statsCache.physics
        if physicsStats then
            self.currentValues.physics = physicsStats.StepTime:GetValue() * NANO_TO_MS
        end
        
        -- Heartbeat time
        local heartbeatStats = self.statsCache.heartbeat
        if heartbeatStats then
            self.currentValues.heartbeat = heartbeatStats.Time:GetValue() * NANO_TO_MS
        end
        
        -- Network stats
        local networkStats = self.statsCache.network
        if networkStats then
            self.currentValues.network_in = networkStats.ServerStatsItem.Data.Recv:GetValue() * BYTES_TO_KB
            self.currentValues.network_out = networkStats.ServerStatsItem.Data.Sent:GetValue() * BYTES_TO_KB
        end
    end)
    
    if not success then
        warn("PerformanceTracker: Error collecting stats -", err)
        return self.currentValues
    end
    
    -- Store data points efficiently
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

return PerformanceTracker
