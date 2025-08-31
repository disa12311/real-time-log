--[[
    Real-Time Log Plugin Structure:
    
    📁 RealTimeLog (Folder)
        📄 Main (Script) - This file
        📁 Modules (Folder)
            📄 UIManager (ModuleScript)
            📄 PerformanceTracker (ModuleScript)
            📄 GraphRenderer (ModuleScript)
            📄 DataExporter (ModuleScript)
            📄 Config (ModuleScript)
--]]

-- Main.lua - Optimized main entry point
local RunService = game:GetService("RunService")

-- Load modules
local Modules = script.Parent.Modules
local UIManager = require(Modules.UIManager)
local PerformanceTracker = require(Modules.PerformanceTracker)
local GraphRenderer = require(Modules.GraphRenderer)
local DataExporter = require(Modules.DataExporter)
local Config = require(Modules.Config)

-- Create toolbar
local toolbar = plugin:CreateToolbar("Real-Time Log")
local pluginButton = toolbar:CreateButton(
    "Real-Time Log",
    "Performance monitoring tool",
    Config.ICON_ID
)

-- Create widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Float,
    false, -- Disable initial state
    false, -- Don't override previous state
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

-- State management
local isMonitoring = false
local updateConnection = nil

-- Optimized update function
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
    
    -- Collect data at specified rate
    local data = tracker:Collect()
    if data then
        ui:UpdateValues(data)
        
        -- Render graphs at lower frequency for performance
        if now - lastRenderTime >= Config.RENDER_RATE then
            renderer:RenderAll(tracker:GetData())
            lastRenderTime = now
        end
    end
end

-- Button handlers
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

-- Widget toggle
local function toggleWidget()
    widget.Enabled = not widget.Enabled
    
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

-- Cleanup
plugin.Unloading:Connect(function()
    if updateConnection then
        updateConnection:Disconnect()
    end
    
    -- Clean up any remaining UI elements
    ui:Destroy()
    
    -- Clear references
    tracker = nil
    renderer = nil
    exporter = nil
    ui = nil
end)

-- Auto-start if widget was previously open
if widget.Enabled then
    isMonitoring = true
    updateConnection = RunService.Heartbeat:Connect(updateMonitor)
end
