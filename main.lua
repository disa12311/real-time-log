-- Main.lua - Updated version with advanced features integration
local RunService = game:GetService("RunService")

-- Load modules
local Modules = script.Parent.Modules
local UIManager = require(Modules.UIManager)
local PerformanceTracker = require(Modules.PerformanceTracker)
local GraphRenderer = require(Modules.GraphRenderer)
local DataExporter = require(Modules.DataExporter)
local Config = require(Modules.Config)

-- Load advanced modules (if available)
local AdvancedFeatures = Modules:FindFirstChild("AdvancedFeatures")
local PluginAPI = Modules:FindFirstChild("PluginAPI")

if AdvancedFeatures then
    AdvancedFeatures = require(AdvancedFeatures)
end

if PluginAPI then
    PluginAPI = require(PluginAPI)
end

-- Create toolbar with enhanced tooltip
local toolbar = plugin:CreateToolbar("Real-Time Log")
local pluginButton = toolbar:CreateButton(
    "Real-Time Log",
    "Advanced performance monitoring tool\nClick to toggle window",
    Config.ICON_ID
)

-- Create widget with saved state
local savedEnabled = plugin:GetSetting("WidgetEnabled")
local savedPosition = plugin:GetSetting("WidgetPosition")

local widgetInfo = DockWidgetPluginGuiInfo.new(
    savedPosition or Enum.InitialDockState.Float,
    savedEnabled or false,
    false,
    Config.WINDOW_SIZE.X,
    Config.WINDOW_SIZE.Y,
    Config.WINDOW_SIZE.X * 0.5,
    Config.WINDOW_SIZE.Y * 0.5
)

local widget = plugin:CreateDockWidgetPluginGui("RealTimeLog_V2", widgetInfo)
widget.Title = "Real-Time Log"
widget.Name = "RealTimeLog"

-- Initialize systems
local ui = UIManager.new(widget)
local tracker = PerformanceTracker.new()
local renderer = GraphRenderer.new(ui:GetGraphFrames())
local exporter = DataExporter.new()

-- Initialize advanced features if available
local advanced, api

if AdvancedFeatures then
    advanced = AdvancedFeatures.new(ui, tracker)
    
    -- Create alert system
    advanced:CreateAlertSystem(ui.mainFrame)
    
    -- Add recording button to UI
    local recordButton = ui:CreateButton(ui.mainFrame:FindFirstChild("Header"):FindFirstChild("ButtonContainer"), {
        Text = "Record",
        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
        LayoutOrder = 0
    })
    
    recordButton.MouseButton1Click:Connect(function()
        if not advanced.recording then
            local sessionName = advanced:StartRecording()
            recordButton.Text = "Stop"
            recordButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            ui:ShowNotification("Recording started: " .. sessionName, Color3.fromRGB(50, 200, 50))
        else
            local session = advanced:StopRecording()
            recordButton.Text = "Record"
            recordButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            if session then
                ui:ShowNotification(
                    string.format("Recording saved: %s (%.1fs)", session.name, session.duration),
                    Color3.fromRGB(50, 150, 200)
                )
            end
        end
    end)
end

if PluginAPI and advanced then
    api = PluginAPI.new(tracker, advanced)
    
    -- Add API status indicator
    local apiStatus = Instance.new("Frame")
    apiStatus.Size = UDim2.new(0, 10, 0, 10)
    apiStatus.Position = UDim2.new(1, -20, 0, 10)
    apiStatus.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    apiStatus.BorderSizePixel = 0
    apiStatus.Parent = widget:FindFirstChild("Header") or widget
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = apiStatus
    
    -- Tooltip for API status
    local tooltip = Instance.new("TextLabel")
    tooltip.Size = UDim2.new(0, 100, 0, 20)
    tooltip.Position = UDim2.new(0, -110, 0, -5)
    tooltip.Text = "API: Active"
    tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltip.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tooltip.Font = Enum.Font.Gotham
    tooltip.TextScaled = true
    tooltip.Visible = false
    tooltip.Parent = apiStatus
    
    apiStatus.MouseEnter:Connect(function()
        tooltip.Visible = true
    end)
    
    apiStatus.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
end

-- State management
local isMonitoring = false
local updateConnection = nil
local lastAlertCheck = 0

-- Enhanced update function
local lastRenderTime = 0
local function updateMonitor()
    local now = tick()
    
    -- Update status
    local isRunning = RunService:IsRunning() and not RunService:IsStudio()
    ui:UpdateStatus(isRunning)
    
    if not isRunning then
        ui:SetWaitingState()
        return
    end
    
    -- Collect data
    local data = tracker:Collect()
    if data then
        ui:UpdateValues(data)
        
        -- Record data point if recording
        if advanced and advanced.recording then
            advanced:RecordDataPoint(data)
        end
        
        -- Check for alerts (throttled)
        if advanced and now - lastAlertCheck > 1 then
            advanced:CheckPerformanceAlerts(data)
            lastAlertCheck = now
        end
        
        -- Render graphs at lower frequency
        if now - lastRenderTime >= Config.RENDER_RATE then
            renderer:RenderAll(tracker:GetData())
            lastRenderTime = now
        end
    end
end

-- Enhanced button handlers
ui.clearButton.MouseButton1Click:Connect(function()
    tracker:Clear()
    renderer:Clear()
    ui:ShowNotification("Data cleared!", Color3.fromRGB(100, 200, 100))
end)

ui.exportButton.MouseButton1Click:Connect(function()
    local success, message = exporter:Export(tracker:GetData())
    local color = success and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 100, 100)
    ui:ShowNotification(message, color)
end)

-- Add keyboard shortcuts
local function handleInput(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.F9 then
        -- Toggle widget with F9
        widget.Enabled = not widget.Enabled
    elseif widget.Enabled and input.KeyCode == Enum.KeyCode.C and input:IsModifierKeyDown(Enum.ModifierKey.Ctrl) then
        -- Clear with Ctrl+C
        tracker:Clear()
        renderer:Clear()
        ui:ShowNotification("Data cleared!", Color3.fromRGB(100, 200, 100))
    elseif widget.Enabled and input.KeyCode == Enum.KeyCode.E and input:IsModifierKeyDown(Enum.ModifierKey.Ctrl) then
        -- Export with Ctrl+E
        local success, message = exporter:Export(tracker:GetData())
        local color = success and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 100, 100)
        ui:ShowNotification(message, color)
    end
end

game:GetService("UserInputService").InputBegan:Connect(handleInput)

-- Widget toggle with state saving
local function toggleWidget()
    widget.Enabled = not widget.Enabled
    plugin:SetSetting("WidgetEnabled", widget.Enabled)
    
    if widget.Enabled then
        if not isMonitoring then
            isMonitoring = true
            updateConnection = RunService.Heartbeat:Connect(updateMonitor)
        end
    else
        if isMonitoring and updateConnection then
            isMonitoring = false
            updateConnection:Disconnect()
            updateConnection = nil
        end
    end
end

pluginButton.Click:Connect(toggleWidget)

-- Save dock state when changed
widget:GetPropertyChangedSignal("Enabled"):Connect(function()
    plugin:SetSetting("WidgetEnabled", widget.Enabled)
end)

-- Auto-hide when game starts (optional)
RunService:GetPropertyChangedSignal("IsRunning"):Connect(function()
    if RunService:IsRunning() and plugin:GetSetting("AutoHideOnPlay") then
        widget.Enabled = false
    end
end)

-- Cleanup with proper state saving
plugin.Unloading:Connect(function()
    -- Save current state
    plugin:SetSetting("WidgetEnabled", widget.Enabled)
    
    -- Disconnect connections
    if updateConnection then
        updateConnection:Disconnect()
    end
    
    -- Clean up advanced features
    if advanced and advanced.recording then
        advanced:StopRecording()
    end
    
    -- Clean up UI
    ui:Destroy()
    
    -- Clear references
    tracker = nil
    renderer = nil
    exporter = nil
    advanced = nil
    api = nil
    ui = nil
end)

-- Auto-start if previously enabled
if widget.Enabled then
    isMonitoring = true
    updateConnection = RunService.Heartbeat:Connect(updateMonitor)
end

-- Print initialization message
print("[Real-Time Log] Plugin loaded successfully!")
if api then
    print("[Real-Time Log] API is available at game.ReplicatedStorage.RealTimeLogAPI")
end
