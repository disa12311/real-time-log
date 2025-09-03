-- AdvancedFeatures.lua - Additional features for Real-Time Log
local TweenService = game:GetService("TweenService")
local Config = require(script.Parent.Config)

local AdvancedFeatures = {}
AdvancedFeatures.__index = AdvancedFeatures

function AdvancedFeatures.new(uiManager, performanceTracker)
    local self = setmetatable({}, AdvancedFeatures)
    
    self.uiManager = uiManager
    self.performanceTracker = performanceTracker
    self.alerts = {}
    self.recording = false
    self.recordedSessions = {}
    
    return self
end

-- Performance Alerts System
function AdvancedFeatures:CreateAlertSystem(parent)
    local alertFrame = Instance.new("Frame")
    alertFrame.Name = "AlertSystem"
    alertFrame.Size = UDim2.new(1, -20, 0, 30)
    alertFrame.Position = UDim2.new(0, 10, 0, Config.HEADER_HEIGHT + 5)
    alertFrame.BackgroundColor3 = Config.COLORS.PANEL
    alertFrame.BorderSizePixel = 0
    alertFrame.Visible = false
    alertFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = alertFrame
    
    local alertIcon = Instance.new("TextLabel")
    alertIcon.Size = UDim2.new(0, 30, 1, 0)
    alertIcon.Text = "⚠️"
    alertIcon.TextScaled = true
    alertIcon.BackgroundTransparency = 1
    alertIcon.Parent = alertFrame
    
    local alertText = Instance.new("TextLabel")
    alertText.Name = "AlertText"
    alertText.Size = UDim2.new(1, -40, 1, 0)
    alertText.Position = UDim2.new(0, 35, 0, 0)
    alertText.Text = ""
    alertText.TextColor3 = Config.COLORS.TEXT
    alertText.Font = Enum.Font.Gotham
    alertText.TextScaled = true
    alertText.TextXAlignment = Enum.TextXAlignment.Left
    alertText.BackgroundTransparency = 1
    alertText.Parent = alertFrame
    
    self.alertFrame = alertFrame
    return alertFrame
end

function AdvancedFeatures:CheckPerformanceAlerts(data)
    local alerts = {}
    
    for _, metric in ipairs(Config.METRICS) do
        local threshold = Config.THRESHOLDS[metric.key]
        if threshold and data[metric.key] then
            local value = data[metric.key]
            
            if value >= threshold.critical then
                table.insert(alerts, {
                    level = "critical",
                    metric = metric.name,
                    value = value,
                    threshold = threshold.critical
                })
            elseif value >= threshold.warning then
                table.insert(alerts, {
                    level = "warning",
                    metric = metric.name,
                    value = value,
                    threshold = threshold.warning
                })
            end
        end
    end
    
    if #alerts > 0 then
        self:ShowAlert(alerts[1]) -- Show highest priority alert
    else
        self:HideAlert()
    end
    
    return alerts
end

function AdvancedFeatures:ShowAlert(alert)
    if not self.alertFrame then return end
    
    local color = alert.level == "critical" and Config.COLORS.STOPPED or Config.COLORS.WARNING
    self.alertFrame.BackgroundColor3 = color
    self.alertFrame.AlertText.Text = string.format(
        "%s: %s is %s (threshold: %s)",
        alert.level:upper(),
        alert.metric,
        tostring(alert.value),
        tostring(alert.threshold)
    )
    
    if not self.alertFrame.Visible then
        self.alertFrame.Visible = true
        self.alertFrame.Position = UDim2.new(0, 10, 0, Config.HEADER_HEIGHT - 30)
        
        local tween = TweenService:Create(self.alertFrame, 
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 10, 0, Config.HEADER_HEIGHT + 5)}
        )
        tween:Play()
    end
end

function AdvancedFeatures:HideAlert()
    if self.alertFrame and self.alertFrame.Visible then
        local tween = TweenService:Create(self.alertFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0, 10, 0, Config.HEADER_HEIGHT - 30)}
        )
        tween:Play()
        tween.Completed:Connect(function()
            self.alertFrame.Visible = false
        end)
    end
end

-- Session Recording
function AdvancedFeatures:StartRecording(sessionName)
    self.recording = true
    self.currentSession = {
        name = sessionName or os.date("Session_%Y%m%d_%H%M%S"),
        startTime = tick(),
        data = {},
        events = {}
    }
    
    return self.currentSession.name
end

function AdvancedFeatures:StopRecording()
    if not self.recording or not self.currentSession then
        return nil
    end
    
    self.recording = false
    self.currentSession.endTime = tick()
    self.currentSession.duration = self.currentSession.endTime - self.currentSession.startTime
    
    table.insert(self.recordedSessions, self.currentSession)
    
    local session = self.currentSession
    self.currentSession = nil
    
    return session
end

function AdvancedFeatures:RecordDataPoint(data)
    if not self.recording or not self.currentSession then return end
    
    table.insert(self.currentSession.data, {
        timestamp = tick() - self.currentSession.startTime,
        metrics = table.clone(data)
    })
end

function AdvancedFeatures:RecordEvent(eventType, description)
    if not self.recording or not self.currentSession then return end
    
    table.insert(self.currentSession.events, {
        timestamp = tick() - self.currentSession.startTime,
        type = eventType,
        description = description
    })
end

-- Comparison View
function AdvancedFeatures:CreateComparisonView(parent)
    local comparisonFrame = Instance.new("Frame")
    comparisonFrame.Name = "ComparisonView"
    comparisonFrame.Size = UDim2.new(1, -20, 0, 200)
    comparisonFrame.Position = UDim2.new(0, 10, 0, 10)
    comparisonFrame.BackgroundColor3 = Config.COLORS.PANEL
    comparisonFrame.BorderSizePixel = 0
    comparisonFrame.Visible = false
    comparisonFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = comparisonFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Text = "Performance Comparison"
    title.TextColor3 = Config.COLORS.TEXT
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.Parent = comparisonFrame
    
    self.comparisonFrame = comparisonFrame
    return comparisonFrame
end

function AdvancedFeatures:CompareMetrics(baseline, current)
    local comparison = {}
    
    for _, metric in ipairs(Config.METRICS) do
        local key = metric.key
        if baseline[key] and current[key] then
            local diff = current[key] - baseline[key]
            local percentChange = (diff / baseline[key]) * 100
            
            comparison[key] = {
                baseline = baseline[key],
                current = current[key],
                difference = diff,
                percentChange = percentChange,
                improved = diff < 0 -- Lower is better for most metrics
            }
            
            -- Special case for FPS - higher is better
            if key == "fps" then
                comparison[key].improved = diff > 0
            end
        end
    end
    
    return comparison
end

-- Auto-Optimization Suggestions
function AdvancedFeatures:GenerateOptimizationSuggestions(data)
    local suggestions = {}
    
    -- FPS Optimization
    if data.fps and data.fps < 30 then
        table.insert(suggestions, {
            category = "Rendering",
            priority = "High",
            suggestion = "Low FPS detected. Consider reducing part count, using LOD systems, or optimizing scripts.",
            metrics = {"fps", "render"}
        })
    end
    
    -- Memory Optimization
    if data.memory and data.memory > 1024 then
        table.insert(suggestions, {
            category = "Memory",
            priority = "High",
            suggestion = "High memory usage. Check for memory leaks, unanchored parts, or excessive asset loading.",
            metrics = {"memory"}
        })
    end
    
    -- Physics Optimization
    if data.physics and data.physics > 30 then
        table.insert(suggestions, {
            category = "Physics",
            priority = "Medium",
            suggestion = "High physics time. Reduce complex collisions, use simpler collision boxes, or decrease unanchored parts.",
            metrics = {"physics"}
        })
    end
    
    -- Network Optimization
    if data.network_out and data.network_out > 50 then
        table.insert(suggestions, {
            category = "Network",
            priority = "Medium",
            suggestion = "High network usage. Optimize RemoteEvent/RemoteFunction calls, batch updates, or reduce data size.",
            metrics = {"network_in", "network_out"}
        })
    end
    
    return suggestions
end

-- Benchmark System
function AdvancedFeatures:RunBenchmark(duration)
    duration = duration or 10 -- Default 10 seconds
    
    local benchmark = {
        startTime = tick(),
        duration = duration,
        samples = {},
        results = {}
    }
    
    -- Collect samples
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if tick() - benchmark.startTime >= duration then
            connection:Disconnect()
            self:ProcessBenchmarkResults(benchmark)
            return
        end
        
        local data = self.performanceTracker:GetCurrentValues()
        table.insert(benchmark.samples, data)
    end)
    
    return benchmark
end

function AdvancedFeatures:ProcessBenchmarkResults(benchmark)
    for _, metric in ipairs(Config.METRICS) do
        local key = metric.key
        local values = {}
        
        for _, sample in ipairs(benchmark.samples) do
            if sample[key] then
                table.insert(values, sample[key])
            end
        end
        
        if #values > 0 then
            -- Calculate statistics
            local sum = 0
            local min = math.huge
            local max = -math.huge
            
            for _, value in ipairs(values) do
                sum = sum + value
                min = math.min(min, value)
                max = math.max(max, value)
            end
            
            benchmark.results[key] = {
                average = sum / #values,
                min = min,
                max = max,
                samples = #values
            }
        end
    end
    
    return benchmark
end

-- Heatmap Generation
function AdvancedFeatures:GeneratePerformanceHeatmap(data, graphFrame)
    local heatmapFrame = Instance.new("Frame")
    heatmapFrame.Name = "Heatmap"
    heatmapFrame.Size = UDim2.new(1, 0, 0, 20)
    heatmapFrame.Position = UDim2.new(0, 0, 1, -20)
    heatmapFrame.BackgroundTransparency = 1
    heatmapFrame.Parent = graphFrame
    
    local segmentCount = math.min(#data, 100)
    local segmentWidth = 1 / segmentCount
    
    for i = 1, segmentCount do
        local value = data[math.ceil(i * #data / segmentCount)]
        local normalizedValue = math.clamp(value / 100, 0, 1) -- Normalize to 0-1
        
        local segment = Instance.new("Frame")
        segment.Size = UDim2.new(segmentWidth, 0, 1, 0)
        segment.Position = UDim2.new((i - 1) * segmentWidth, 0, 0, 0)
        segment.BorderSizePixel = 0
        
        -- Color based on performance
        local hue = (1 - normalizedValue) * 120 / 360 -- Green to red
        segment.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        
        segment.Parent = heatmapFrame
    end
    
    return heatmapFrame
end

return AdvancedFeatures
