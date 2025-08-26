-- PerformanceMonitor.lua - Handles performance data collection

local PerformanceMonitor = {}
PerformanceMonitor.__index = PerformanceMonitor

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local UPDATE_RATE = 0.1 -- Update every 100ms
local MAX_DATA_POINTS = 100

function PerformanceMonitor.new()
    local self = setmetatable({}, PerformanceMonitor)
    
    self.data = {
        fps = {},
        memory = {},
        cpu = {},
        render = {},
        physics = {},
        heartbeat = {},
        networkReceive = {},
        networkSend = {}
    }
    
    self.lastUpdate = 0
    
    return self
end

function PerformanceMonitor:collect()
    local currentTime = tick()
    
    -- Only update at specified rate
    if currentTime - self.lastUpdate < UPDATE_RATE then
        return self:getCurrentValues()
    end
    self.lastUpdate = currentTime
    
    -- Collect current performance metrics
    local metrics = {
        fps = math.floor(1 / RunService.Heartbeat:Wait()),
        memory = Stats:GetTotalMemoryUsageMb(),
        cpu = Stats.PerformanceStats.CPU:GetValue(),
        render = Stats.RenderStepped:GetValue() * 1000,
        physics = Stats.PhysicsStepTime:GetValue() * 1000,
        heartbeat = Stats.HeartbeatTime:GetValue() * 1000,
        networkReceive = Stats.DataReceiveKbps:GetValue(),
        networkSend = Stats.DataSendKbps:GetValue()
    }
    
    -- Store data points
    for key, value in pairs(metrics) do
        table.insert(self.data[key], value)
        if #self.data[key] > MAX_DATA_POINTS then
            table.remove(self.data[key], 1)
        end
    end
    
    return metrics
end

function PerformanceMonitor:getCurrentValues()
    -- Return the last collected values
    local current = {}
    for key, dataArray in pairs(self.data) do
        if #dataArray > 0 then
            current[key] = dataArray[#dataArray]
        else
            current[key] = 0
        end
    end
    return current
end

function PerformanceMonitor:getData()
    return self.data
end

function PerformanceMonitor:clear()
    for key, _ in pairs(self.data) do
        self.data[key] = {}
    end
end

return PerformanceMonitor