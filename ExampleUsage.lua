-- ExampleUsage.lua - Example script showing how to use Real-Time Log API
-- Place this in ServerScriptService or as a ModuleScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for API to be available
local RealTimeLogAPI = ReplicatedStorage:WaitForChild("RealTimeLogAPI", 10)
if not RealTimeLogAPI then
    warn("Real-Time Log API not found!")
    return
end

local APIFunction = RealTimeLogAPI:WaitForChild("APIFunction")
local APIEvent = RealTimeLogAPI:WaitForChild("APIEvent")

-- Example 1: Register Custom Metrics for Game-Specific Tracking
local function setupCustomMetrics()
    -- Track player count
    local success = APIFunction:Invoke("RegisterCustomMetric", {
        key = "player_count",
        name = "Active Players",
        color = Color3.fromRGB(100, 200, 255),
        maxValue = 50,
        format = "%d players",
        unit = "players"
    })
    
    if success then
        print("Registered player_count metric")
    end
    
    -- Track NPC count
    APIFunction:Invoke("RegisterCustomMetric", {
        key = "npc_count",
        name = "Active NPCs",
        color = Color3.fromRGB(255, 200, 100),
        maxValue = 100,
        format = "%d NPCs",
        unit = "NPCs"
    })
    
    -- Track active effects
    APIFunction:Invoke("RegisterCustomMetric", {
        key = "active_effects",
        name = "VFX Count",
        color = Color3.fromRGB(255, 100, 255),
        maxValue = 200,
        format = "%d effects",
        unit = "effects"
    })
end

-- Example 2: Update Custom Metrics
local function updateGameMetrics()
    -- Update player count
    local playerCount = #Players:GetPlayers()
    APIFunction:Invoke("UpdateCustomMetric", "player_count", playerCount)
    
    -- Update NPC count (example)
    local npcFolder = workspace:FindFirstChild("NPCs")
    if npcFolder then
        local npcCount = #npcFolder:GetChildren()
        APIFunction:Invoke("UpdateCustomMetric", "npc_count", npcCount)
    end
    
    -- Update active effects (example)
    local effectsFolder = workspace:FindFirstChild("Effects")
    if effectsFolder then
        local effectCount = #effectsFolder:GetChildren()
        APIFunction:Invoke("UpdateCustomMetric", "active_effects", effectCount)
    end
end

-- Example 3: Performance Monitoring with Alerts
local function monitorPerformance()
    local metrics = APIFunction:Invoke("GetCurrentMetrics")
    
    -- Check for performance issues
    if metrics.fps < 30 then
        APIEvent:Fire("TriggerAlert", "warning", 
            string.format("Low FPS detected: %d FPS", metrics.fps))
        
        -- Log event for analysis
        APIEvent:Fire("LogPerformanceEvent", {
            type = "performance_issue",
            description = string.format("FPS dropped to %d", metrics.fps),
            data = {
                fps = metrics.fps,
                playerCount = #Players:GetPlayers()
