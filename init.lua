-- Real-Time Log Plugin - Main File (init.lua)
-- Version: 1.0.0
-- This is the main entry point for the plugin

local RunService = game:GetService("RunService")

-- Module paths
local modules = script.Parent
local UI = require(modules.UI)
local PerformanceMonitor = require(modules.PerformanceMonitor)
local GraphRenderer = require(modules.GraphRenderer)
local DataExporter = require(modules.DataExporter)

-- Create toolbar button
local toolbar = plugin:CreateToolbar("Real-Time Log")
local pluginButton = toolbar:CreateButton(
    "Toggle Real-Time Log",
    "Open/Close Real-Time Log window",
    "rbxassetid://4458901886"
)

-- Create main widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Float,
    false,
    false,
    800,
    600,
    400,
    300
)

local mainWidget = plugin:CreateDockWidgetPluginGui("RealTimeLog", widgetInfo)
mainWidget.Title = "Real-Time Log"

-- Initialize UI
local uiComponents = UI.create(mainWidget)
local performanceMonitor = PerformanceMonitor.new()
local graphRenderer = GraphRenderer.new(uiComponents.graphFrames)

-- Update loop connection
local updateConnection

-- Check if game is running
local function isGameRunning()
    return RunService:IsRunning() and not RunService:IsStudio()
end

-- Status indicator update
local function updateStatus()
    if isGameRunning() then
        uiComponents.statusLabel.Text = "● Running"
        uiComponents.statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        uiComponents.statusLabel.Text = "● Stopped"
        uiComponents.statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- Main update function
local function update()
    updateStatus()
    
    if not isGameRunning() then
        -- Show waiting message when game is not running
        for key, label in pairs(uiComponents.valueLabels) do
            label.Text = "Waiting..."
        end
        return
    end
    
    -- Get performance data
    local data = performanceMonitor:collect()
    
    -- Update value labels
    uiComponents.valueLabels.fps.Text = string.format("%d FPS", data.fps)
    uiComponents.valueLabels.memory.Text = string.format("%.1f MB", data.memory)
    uiComponents.valueLabels.cpu.Text = string.format("%.1f%%", data.cpu)
    uiComponents.valueLabels.render.Text = string.format("%.2f ms", data.render)
    uiComponents.valueLabels.physics.Text = string.format("%.2f ms", data.physics)
    uiComponents.valueLabels.heartbeat.Text = string.format("%.2f ms", data.heartbeat)
    uiComponents.valueLabels.networkReceive.Text = string.format("%.1f KB/s", data.networkReceive)
    uiComponents.valueLabels.networkSend.Text = string.format("%.1f KB/s", data.networkSend)
    
    -- Render graphs
    graphRenderer:renderAll(performanceMonitor:getData())
end

-- Button handlers
uiComponents.clearButton.MouseButton1Click:Connect(function()
    performanceMonitor:clear()
    graphRenderer:clear()
end)

uiComponents.exportButton.MouseButton1Click:Connect(function()
    local success = DataExporter.export(performanceMonitor:getData())
    
    -- Show notification
    local notification = Instance.new("TextLabel")
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 0.5, -25)
    notification.Text = success and "Data exported to output!" or "Export failed!"
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.BackgroundColor3 = success and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    notification.Font = Enum.Font.SourceSans
    notification.TextScaled = true
    notification.BorderSizePixel = 0
    notification.Parent = mainWidget
    
    task.wait(2)
    notification:Destroy()
end)

-- Toggle widget visibility
pluginButton.Click:Connect(function()
    mainWidget.Enabled = not mainWidget.Enabled
    if mainWidget.Enabled then
        updateConnection = RunService.Heartbeat:Connect(update)
    else
        if updateConnection then
            updateConnection:Disconnect()
        end
    end
end)

-- Clean up on plugin unload
plugin.Unloading:Connect(function()
    if updateConnection then
        updateConnection:Disconnect()
    end
end)