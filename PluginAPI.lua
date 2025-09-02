-- PluginAPI.lua - External API for other scripts to interact with Real-Time Log
local PluginAPI = {}
PluginAPI.__index = PluginAPI

-- Shared storage for cross-script communication
local SharedStorage = game:GetService("ReplicatedStorage")
local APIFolder = SharedStorage:FindFirstChild("RealTimeLogAPI")

if not APIFolder then
    APIFolder = Instance.new("Folder")
    APIFolder.Name = "RealTimeLogAPI"
    APIFolder.Parent = SharedStorage
end

function PluginAPI.new(performanceTracker, advancedFeatures)
    local self = setmetatable({}, PluginAPI)
    
    self.performanceTracker = performanceTracker
    self.advancedFeatures = advancedFeatures
    self.callbacks = {}
    self.customMetrics = {}
    
    self:InitializeAPI()
    
    return self
end

function PluginAPI:InitializeAPI()
    -- Create RemoteFunction for external scripts
    local apiRemote = APIFolder:FindFirstChild("APIRemote") or Instance.new("RemoteFunction")
    apiRemote.Name = "APIRemote"
    apiRemote.Parent = APIFolder
    
    -- Create BindableEvents for local scripts
    local apiEvent = APIFolder:FindFirstChild("APIEvent") or Instance.new("BindableEvent")
    apiEvent.Name = "APIEvent"
    apiEvent.Parent = APIFolder
    
    local apiFunction = APIFolder:FindFirstChild("APIFunction") or Instance.new("BindableFunction")
    apiFunction.Name = "APIFunction"
    apiFunction.Parent = APIFolder
    
    -- Set up API handlers
    apiFunction.OnInvoke = function(action, ...)
        return self:HandleAPICall(action, ...)
    end
    
    apiEvent.Event:Connect(function(action, ...)
        self:HandleAPIEvent(action, ...)
    end)
    
    self.apiRemote = apiRemote
    self.apiEvent = apiEvent
    self.apiFunction = apiFunction
end

function PluginAPI:HandleAPICall(action, ...)
    local args = {...}
    
    if action == "GetCurrentMetrics" then
        return self.performanceTracker:GetCurrentValues()
        
    elseif action == "GetHistoricalData" then
        local metricKey = args[1]
        local data = self.performanceTracker:GetData()
        return metricKey and data[metricKey] or data
        
    elseif action == "GetStatistics" then
        local metricKey = args[1]
        return self.performanceTracker:GetStatistics(metricKey)
        
    elseif action == "RegisterCustomMetric" then
        local metricConfig = args[1]
        return self:RegisterCustomMetric(metricConfig)
        
    elseif action == "UpdateCustomMetric" then
        local metricKey = args[1]
        local value = args[2]
        return self:UpdateCustomMetric(metricKey, value)
        
    elseif action == "StartRecording" then
        local sessionName = args[1]
        return self.advancedFeatures:StartRecording(sessionName)
        
    elseif action == "StopRecording" then
        return self.advancedFeatures:StopRecording()
        
    elseif action == "RecordEvent" then
        local eventType = args[1]
        local description = args[2]
        self.advancedFeatures:RecordEvent(eventType, description)
        return true
        
    elseif action == "GetOptimizationSuggestions" then
        local data = self.performanceTracker:GetCurrentValues()
        return self.advancedFeatures:GenerateOptimizationSuggestions(data)
        
    elseif action == "RunBenchmark" then
        local duration = args[1] or 10
        return self.advancedFeatures:RunBenchmark(duration)
        
    elseif action == "RegisterCallback" then
        local callbackType = args[1]
        local callbackId = args[2]
        return self:RegisterCallback(callbackType, callbackId)
        
    elseif action == "UnregisterCallback" then
        local callbackId = args[1]
        return self:UnregisterCallback(callbackId)
    end
    
    return nil, "Unknown action: " .. tostring(action)
end

function PluginAPI:HandleAPIEvent(action, ...)
    local args = {...}
    
    if action == "TriggerAlert" then
        local alertType = args[1]
        local message = args[2]
        self:TriggerCustomAlert(alertType, message)
        
    elseif action == "LogPerformanceEvent" then
        local eventData = args[1]
        self:LogPerformanceEvent(eventData)
    end
end

function PluginAPI:RegisterCustomMetric(config)
    if not config.key or not config.name then
        return false, "Missing required fields: key, name"
    end
    
    -- Validate config
    config.color = config.color or Color3.fromRGB(255, 255, 255)
    config.maxValue = config.maxValue or 100
    config.format = config.format or "%.2f"
    config.unit = config.unit or ""
    
    -- Add to custom metrics
    self.customMetrics[config.key] = config
    
    -- Initialize data storage
    local data = self.performanceTracker:GetData()
    if not data[config.key] then
        data[config.key] = {}
    end
    
    return true
end

function PluginAPI:UpdateCustomMetric(key, value)
    if not self.customMetrics[key] then
        return false, "Custom metric not registered: " .. key
    end
    
    -- Add to performance data
    local data = self.performanceTracker:GetData()
    table.insert(data[key], value)
    
    -- Maintain max data points
    while #data[key] > 100 do
        table.remove(data[key], 1)
    end
    
    -- Trigger callbacks
    self:TriggerCallbacks("MetricUpdate", key, value)
    
    return true
end

function PluginAPI:RegisterCallback(callbackType, callbackId)
    if not self.callbacks[callbackType] then
        self.callbacks[callbackType] = {}
    end
    
    self.callbacks[callbackType][callbackId] = true
    return true
end

function PluginAPI:UnregisterCallback(callbackId)
    for callbackType, callbacks in pairs(self.callbacks) do
        callbacks[callbackId] = nil
    end
    return true
end

function PluginAPI:TriggerCallbacks(callbackType, ...)
    local callbacks = self.callbacks[callbackType]
    if not callbacks then return end
    
    for callbackId, _ in pairs(callbacks) do
        local callbackEvent = APIFolder:FindFirstChild("Callback_" .. callbackId)
        if callbackEvent and callbackEvent:IsA("BindableEvent") then
            callbackEvent:Fire(...)
        end
    end
end

function PluginAPI:TriggerCustomAlert(alertType, message)
    -- Create custom alert data
    local alertData = {
        type = alertType,
        message = message,
        timestamp = tick()
    }
    
    -- Trigger alert callbacks
    self:TriggerCallbacks("Alert", alertData)
end

function PluginAPI:LogPerformanceEvent(eventData)
    -- Validate event data
    if not eventData.type or not eventData.description then
        return false, "Missing required fields: type, description"
    end
    
    -- Add timestamp if not provided
    eventData.timestamp = eventData.timestamp or tick()
    
    -- Record event if recording
    if self.advancedFeatures.recording then
        self.advancedFeatures:RecordEvent(eventData.type, eventData.description)
    end
    
    -- Trigger event callbacks
    self:TriggerCallbacks("PerformanceEvent", eventData)
    
    return true
end

-- Public API Documentation
function PluginAPI:GenerateDocumentation()
    return {
        Info = {
            Name = "Real-Time Log Plugin API",
            Version = "1.0.0",
            Description = "External API for interacting with Real-Time Log plugin"
        },
        
        Methods = {
            GetCurrentMetrics = {
                Description = "Get current performance metrics",
                Returns = "Table of current metric values"
            },
            
            GetHistoricalData = {
                Description = "Get historical data for metrics",
                Parameters = {"metricKey (optional)"},
                Returns = "Historical data array or all data"
            },
            
            GetStatistics = {
                Description = "Get statistics for a specific metric",
                Parameters = {"metricKey"},
                Returns = "Statistics table (min, max, average, etc.)"
            },
            
            RegisterCustomMetric = {
                Description = "Register a custom metric for tracking",
                Parameters = {
                    "config = {",
                    "  key = 'unique_key',",
                    "  name = 'Display Name',",
                    "  color = Color3,",
                    "  maxValue = number,",
                    "  format = 'format string',",
                    "  unit = 'unit string'",
                    "}"
                },
                Returns = "success, errorMessage"
            },
            
            UpdateCustomMetric = {
                Description = "Update value for a custom metric",
                Parameters = {"metricKey", "value"},
                Returns = "success, errorMessage"
            },
            
            StartRecording = {
                Description = "Start recording a performance session",
                Parameters = {"sessionName (optional)"},
                Returns = "sessionName"
            },
            
            StopRecording = {
                Description = "Stop current recording session",
                Returns = "sessionData"
            },
            
            RecordEvent = {
                Description = "Record a performance event",
                Parameters = {"eventType", "description"},
                Returns = "success"
            },
            
            GetOptimizationSuggestions = {
                Description = "Get AI-generated optimization suggestions",
                Returns = "Array of suggestions"
            },
            
            RunBenchmark = {
                Description = "Run a performance benchmark",
                Parameters = {"duration (seconds)"},
                Returns = "benchmarkResults"
            }
        },
        
        Events = {
            TriggerAlert = {
                Description = "Trigger a custom alert",
                Parameters = {"alertType", "message"}
            },
            
            LogPerformanceEvent = {
                Description = "Log a custom performance event",
                Parameters = {
                    "eventData = {",
                    "  type = 'event_type',",
                    "  description = 'description',",
                    "  timestamp = tick() (optional)",
                    "}"
                }
            }
        },
        
        Callbacks = {
            MetricUpdate = {
                Description = "Fired when a metric is updated",
                Parameters = {"metricKey", "value"}
            },
            
            Alert = {
                Description = "Fired when an alert is triggered",
                Parameters = {"alertData"}
            },
            
            PerformanceEvent = {
                Description = "Fired when a performance event is logged",
                Parameters = {"eventData"}
            }
        },
        
        Examples = {
            BasicUsage = [[
-- Get API reference
local RealTimeLogAPI = game:GetService("ReplicatedStorage"):WaitForChild("RealTimeLogAPI")
local APIFunction = RealTimeLogAPI:WaitForChild("APIFunction")

-- Get current metrics
local metrics = APIFunction:Invoke("GetCurrentMetrics")
print("Current FPS:", metrics.fps)

-- Register custom metric
APIFunction:Invoke("RegisterCustomMetric", {
    key = "player_count",
    name = "Active Players",
    color = Color3.fromRGB(100, 200, 255),
    maxValue = 50,
    format = "%d players",
    unit = "players"
})

-- Update custom metric
APIFunction:Invoke("UpdateCustomMetric", "player_count", #game.Players:GetPlayers())
]],
            
            RecordingSession = [[
-- Start recording
local sessionName = APIFunction:Invoke("StartRecording", "Boss Fight Test")

-- Record events during gameplay
APIFunction:Invoke("RecordEvent", "combat", "Boss fight started")
-- ... gameplay ...
APIFunction:Invoke("RecordEvent", "combat", "Boss defeated")

-- Stop and get session data
local sessionData = APIFunction:Invoke("StopRecording")
print("Session duration:", sessionData.duration, "seconds")
]],
            
            PerformanceMonitoring = [[
-- Set up performance monitoring
local APIEvent = RealTimeLogAPI:WaitForChild("APIEvent")

-- Monitor FPS drops
game:GetService("RunService").Heartbeat:Connect(function()
    local metrics = APIFunction:Invoke("GetCurrentMetrics")
    
    if metrics.fps < 20 then
        APIEvent:Fire("TriggerAlert", "critical", "FPS dropped below 20!")
    end
end)

-- Get optimization suggestions
local suggestions = APIFunction:Invoke("GetOptimizationSuggestions")
for _, suggestion in ipairs(suggestions) do
    print(suggestion.category, "-", suggestion.suggestion)
end
]]
        }
    }
end

return PluginAPI
