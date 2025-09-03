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
            }
        })
    end
    
    -- Check memory usage
    if metrics.memory > 1500 then
        APIEvent:Fire("TriggerAlert", "critical", 
            string.format("High memory usage: %.1f MB", metrics.memory))
    end
    
    -- Check for network issues
    if metrics.network_out > 100 then
        APIEvent:Fire("LogPerformanceEvent", {
            type = "network_spike",
            description = "High network output detected",
            data = {
                network_out = metrics.network_out,
                network_in = metrics.network_in
            }
        })
    end
end

-- Example 4: Recording Game Sessions
local function startGameSession(mapName)
    local sessionName = string.format("Game_%s_%s", 
        mapName, 
        os.date("%H%M%S")
    )
    
    local session = APIFunction:Invoke("StartRecording", sessionName)
    print("Started recording session:", session)
    
    -- Record initial event
    APIFunction:Invoke("RecordEvent", "game_start", 
        string.format("Game started on map: %s", mapName))
    
    return session
end

local function endGameSession(winner)
    -- Record final event
    APIFunction:Invoke("RecordEvent", "game_end", 
        string.format("Game ended. Winner: %s", winner or "None"))
    
    -- Stop recording and get data
    local sessionData = APIFunction:Invoke("StopRecording")
    
    if sessionData then
        print("Session completed:")
        print("  Duration:", sessionData.duration, "seconds")
        print("  Events:", #sessionData.events)
        print("  Data points:", #sessionData.data)
    end
    
    return sessionData
end

-- Example 5: Benchmark System
local function runPerformanceBenchmark()
    print("Starting 10-second performance benchmark...")
    
    local benchmark = APIFunction:Invoke("RunBenchmark", 10)
    
    -- Wait for benchmark to complete
    task.wait(11)
    
    -- Get and display results
    local results = benchmark.results
    if results then
        print("\nBenchmark Results:")
        print("=================")
        
        for metric, data in pairs(results) do
            print(string.format("%s:", metric))
            print(string.format("  Average: %.2f", data.average))
            print(string.format("  Min: %.2f", data.min))
            print(string.format("  Max: %.2f", data.max))
            print(string.format("  Samples: %d", data.samples))
        end
    end
end

-- Example 6: Combat Performance Tracking
local CombatTracker = {}
CombatTracker.__index = CombatTracker

function CombatTracker.new()
    local self = setmetatable({}, CombatTracker)
    self.combatActive = false
    self.combatStartTime = 0
    self.damageEvents = 0
    return self
end

function CombatTracker:StartCombat(enemyName)
    self.combatActive = true
    self.combatStartTime = tick()
    self.damageEvents = 0
    
    APIFunction:Invoke("RecordEvent", "combat_start", 
        "Combat started with: " .. enemyName)
end

function CombatTracker:RecordDamage(damage, source)
    if not self.combatActive then return end
    
    self.damageEvents = self.damageEvents + 1
    
    -- Track damage events
    if self.damageEvents % 10 == 0 then
        local metrics = APIFunction:Invoke("GetCurrentMetrics")
        
        APIEvent:Fire("LogPerformanceEvent", {
            type = "combat_performance",
            description = "Combat performance check",
            data = {
                damageEvents = self.damageEvents,
                combatDuration = tick() - self.combatStartTime,
                fps = metrics.fps,
                physics = metrics.physics
            }
        })
    end
end

function CombatTracker:EndCombat(result)
    if not self.combatActive then return end
    
    local duration = tick() - self.combatStartTime
    
    APIFunction:Invoke("RecordEvent", "combat_end", 
        string.format("Combat ended: %s (Duration: %.1fs, Events: %d)", 
            result, duration, self.damageEvents))
    
    -- Get optimization suggestions if performance was poor
    local suggestions = APIFunction:Invoke("GetOptimizationSuggestions")
    if #suggestions > 0 then
        print("\nPerformance Suggestions:")
        for _, suggestion in ipairs(suggestions) do
            print("- " .. suggestion.suggestion)
        end
    end
    
    self.combatActive = false
end

-- Example 7: Advanced Statistics Analysis
local function analyzePerformanceTrends()
    print("\nPerformance Trend Analysis")
    print("=========================")
    
    local metricsToAnalyze = {"fps", "memory", "cpu", "physics"}
    
    for _, metricKey in ipairs(metricsToAnalyze) do
        local stats = APIFunction:Invoke("GetStatistics", metricKey)
        
        if stats and stats.samples > 0 then
            print(string.format("\n%s Analysis:", metricKey:upper()))
            print(string.format("  Current: %.2f", stats.current))
            print(string.format("  Average: %.2f", stats.average))
            print(string.format("  Min/Max: %.2f / %.2f", stats.min, stats.max))
            print(string.format("  Samples: %d", stats.samples))
            
            -- Determine trend
            local variance = stats.max - stats.min
            local trend = "Stable"
            
            if variance > stats.average * 0.5 then
                trend = "Highly Variable"
            elseif variance > stats.average * 0.2 then
                trend = "Moderately Variable"
            end
            
            print(string.format("  Trend: %s", trend))
        end
    end
end

-- Example 8: Automated Performance Report
local function generatePerformanceReport()
    local report = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        metrics = {},
        issues = {},
        recommendations = []
    }
    
    -- Collect current metrics
    local currentMetrics = APIFunction:Invoke("GetCurrentMetrics")
    
    -- Analyze each metric
    for key, value in pairs(currentMetrics) do
        local stats = APIFunction:Invoke("GetStatistics", key)
        
        report.metrics[key] = {
            current = value,
            average = stats and stats.average or value,
            status = "Normal"
        }
        
        -- Check thresholds
        if key == "fps" and value < 30 then
            report.metrics[key].status = "Poor"
            table.insert(report.issues, {
                metric = "FPS",
                severity = "High",
                description = string.format("FPS is below 30 (current: %d)", value)
            })
        elseif key == "memory" and value > 1024 then
            report.metrics[key].status = "Warning"
            table.insert(report.issues, {
                metric = "Memory",
                severity = "Medium",
                description = string.format("Memory usage is high: %.1f MB", value)
            })
        end
    end
    
    -- Get optimization suggestions
    local suggestions = APIFunction:Invoke("GetOptimizationSuggestions")
    for _, suggestion in ipairs(suggestions) do
        table.insert(report.recommendations, suggestion)
    end
    
    -- Output report
    print("\n" .. string.rep("=", 60))
    print("AUTOMATED PERFORMANCE REPORT")
    print(string.rep("=", 60))
    print("Generated:", report.timestamp)
    print("\nCurrent Performance:")
    
    for key, data in pairs(report.metrics) do
        print(string.format("  %-15s: %-10s [%s]", 
            key, 
            tostring(data.current), 
            data.status
        ))
    end
    
    if #report.issues > 0 then
        print("\nIssues Detected:")
        for _, issue in ipairs(report.issues) do
            print(string.format("  [%s] %s - %s", 
                issue.severity, 
                issue.metric, 
                issue.description
            ))
        end
    end
    
    if #report.recommendations > 0 then
        print("\nRecommendations:")
        for i, rec in ipairs(report.recommendations) do
            print(string.format("  %d. [%s] %s", 
                i, 
                rec.priority, 
                rec.suggestion
            ))
        end
    end
    
    print(string.rep("=", 60))
    
    return report
end

-- Initialize and start monitoring
local function initialize()
    print("Initializing Real-Time Log integration...")
    
    -- Set up custom metrics
    setupCustomMetrics()
    
    -- Update metrics every second
    local updateConnection = RunService.Heartbeat:Connect(function()
        updateGameMetrics()
    end)
    
    -- Monitor performance every 5 seconds
    task.spawn(function()
        while true do
            task.wait(5)
            monitorPerformance()
        end
    end)
    
    -- Analyze trends every 30 seconds
    task.spawn(function()
        while true do
            task.wait(30)
            analyzePerformanceTrends()
        end
    end)
    
    -- Generate report every 2 minutes
    task.spawn(function()
        while true do
            task.wait(120)
            generatePerformanceReport()
        end
    end)
    
    print("Real-Time Log integration initialized!")
end

-- Public API for other scripts
local ExampleUsage = {
    StartGameSession = startGameSession,
    EndGameSession = endGameSession,
    RunBenchmark = runPerformanceBenchmark,
    CombatTracker = CombatTracker,
    GenerateReport = generatePerformanceReport,
    Initialize = initialize
}

-- Auto-initialize if running as a script
if script.Parent == game.ServerScriptService then
    initialize()
end

return ExampleUsage
