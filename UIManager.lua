-- UIManager.lua - Optimized UI management
local TweenService = game:GetService("TweenService")
local Config = require(script.Parent.Config)

local UIManager = {}
UIManager.__index = UIManager

-- UI Element cache for performance
local elementCache = {}

-- Optimized element creation with caching
local function createElement(className, properties, parent)
    local element = elementCache[className] and elementCache[className]:Clone() or Instance.new(className)
    
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            element[prop] = value
        end
    end
    
    element.Parent = parent
    return element
end

-- Tween info for smooth animations
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function UIManager.new(widget)
    local self = setmetatable({}, UIManager)
    
    self.widget = widget
    self.graphFrames = {}
    self.valueLabels = {}
    self.notifications = {}
    
    self:CreateUI()
    
    return self
end

function UIManager:CreateUI()
    -- Main container
    self.mainFrame = createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Config.COLORS.BACKGROUND,
        BorderSizePixel = 0
    }, self.widget)
    
    -- Create header
    self:CreateHeader()
    
    -- Create content area
    self:CreateContent()
    
    -- Apply UI polish
    self:ApplyUIPolish()
end

function UIManager:CreateHeader()
    local header = createElement("Frame", {
        Size = UDim2.new(1, 0, 0, Config.HEADER_HEIGHT),
        BackgroundColor3 = Config.COLORS.HEADER,
        BorderSizePixel = 0
    }, self.mainFrame)
    
    -- Gradient overlay
    local gradient = createElement("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.8))
        },
        Rotation = 90
    }, header)
    
    -- Title
    local title = createElement("TextLabel", {
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        Text = "Real-Time Log",
        TextColor3 = Config.COLORS.TEXT,
        Font = Enum.Font.Gotham,
        TextScaled = true,
        BackgroundTransparency = 1
    }, header)
    
    -- Status indicator
    local statusFrame = createElement("Frame", {
        Size = UDim2.new(0.2, 0, 0.6, 0),
        Position = UDim2.new(0.3, 10, 0.2, 0),
        BackgroundTransparency = 1
    }, header)
    
    self.statusIndicator = createElement("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = Config.COLORS.STOPPED,
        AnchorPoint = Vector2.new(0, 0.5)
    }, statusFrame)
    
    -- Make status indicator circular
    local corner = createElement("UICorner", {
        CornerRadius = UDim.new(0.5, 0)
    }, self.statusIndicator)
    
    self.statusLabel = createElement("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        Text = "Stopped",
        TextColor3 = Config.COLORS.TEXT,
        Font = Enum.Font.Gotham,
        TextScaled = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    }, statusFrame)
    
    -- Control buttons
    local buttonContainer = createElement("Frame", {
        Size = UDim2.new(0.3, -20, 0.6, 0),
        Position = UDim2.new(0.7, 0, 0.2, 0),
        BackgroundTransparency = 1
    }, header)
    
    local buttonLayout = createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, buttonContainer)
    
    -- Clear button
    self.clearButton = self:CreateButton(buttonContainer, {
        Text = "Clear",
        BackgroundColor3 = Config.COLORS.BUTTON_CLEAR,
        LayoutOrder = 1
    })
    
    -- Export button
    self.exportButton = self:CreateButton(buttonContainer, {
        Text = "Export",
        BackgroundColor3 = Config.COLORS.BUTTON_EXPORT,
        LayoutOrder = 2
    })
end

function UIManager:CreateButton(parent, properties)
    local button = createElement("TextButton", {
        Size = UDim2.new(0, 80, 1, 0),
        Text = properties.Text,
        TextColor3 = Config.COLORS.TEXT,
        BackgroundColor3 = properties.BackgroundColor3,
        Font = Enum.Font.Gotham,
        TextScaled = true,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = properties.LayoutOrder or 0
    }, parent)
    
    local corner = createElement("UICorner", {
        CornerRadius = UDim.new(0, 6)
    }, button)
    
    local padding = createElement("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }, button)
    
    -- Hover effect
    local originalColor = properties.BackgroundColor3
    button.MouseEnter:Connect(function()
        TweenService:Create(button, tweenInfo, {
            BackgroundColor3 = originalColor:Lerp(Config.COLORS.BUTTON_HOVER, 0.2)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, tweenInfo, {
            BackgroundColor3 = originalColor
        }):Play()
    end)
    
    return button
end

function UIManager:CreateContent()
    -- Scrolling frame
    self.scrollFrame = createElement("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -Config.HEADER_HEIGHT - 10),
        Position = UDim2.new(0, 10, 0, Config.HEADER_HEIGHT + 5),
        BackgroundColor3 = Config.COLORS.PANEL,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = Config.COLORS.TEXT_DIM,
        CanvasSize = UDim2.new(0, 0, 0, #Config.METRICS * (Config.GRAPH_HEIGHT + Config.GRAPH_PADDING) + 20)
    }, self.mainFrame)
    
    local scrollCorner = createElement("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }, self.scrollFrame)
    
    -- Create metric panels
    for i, metric in ipairs(Config.METRICS) do
        self:CreateMetricPanel(metric, i)
    end
end

function UIManager:CreateMetricPanel(metric, index)
    local yPos = (index - 1) * (Config.GRAPH_HEIGHT + Config.GRAPH_PADDING) + 10
    
    -- Panel container
    local panel = createElement("Frame", {
        Size = UDim2.new(1, -20, 0, Config.GRAPH_HEIGHT),
        Position = UDim2.new(0, 10, 0, yPos),
        BackgroundColor3 = Config.COLORS.BACKGROUND,
        BorderSizePixel = 0
    }, self.scrollFrame)
    
    local panelCorner = createElement("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }, panel)
    
    -- Header section
    local headerHeight = 25
    local headerFrame = createElement("Frame", {
        Size = UDim2.new(1, 0, 0, headerHeight),
        BackgroundColor3 = Config.COLORS.HEADER,
        BorderSizePixel = 0
    }, panel)
    
    local headerCorner = createElement("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }, headerFrame)
    
    -- Bottom square corners
    local bottomFix = createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = Config.COLORS.HEADER,
        BorderSizePixel = 0
    }, headerFrame)
    
    -- Metric name
    local nameLabel = createElement("TextLabel", {
        Size = UDim2.new(0.5, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = metric.name,
        TextColor3 = metric.color,
        Font = Enum.Font.GothamBold,
        TextScaled = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    }, headerFrame)
    
    -- Value label
    local valueLabel = createElement("TextLabel", {
        Size = UDim2.new(0.5, -10, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Text = "Waiting...",
        TextColor3 = Config.COLORS.TEXT,
        Font = Enum.Font.Gotham,
        TextScaled = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right
    }, headerFrame)
    
    self.valueLabels[metric.key] = valueLabel
    
    -- Graph frame
    local graphFrame = createElement("Frame", {
        Size = UDim2.new(1, -10, 1, -headerHeight - 10),
        Position = UDim2.new(0, 5, 0, headerHeight + 5),
        BackgroundColor3 = Config.COLORS.GRAPH_BG,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, panel)
    
    local graphCorner = createElement("UICorner", {
        CornerRadius = UDim.new(0, 6)
    }, graphFrame)
    
    self.graphFrames[metric.key] = {
        frame = graphFrame,
        metric = metric
    }
end

function UIManager:ApplyUIPolish()
    -- Add padding to main frame
    local padding = createElement("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    }, self.mainFrame)
end

function UIManager:UpdateStatus(isRunning)
    local color = isRunning and Config.COLORS.RUNNING or Config.COLORS.STOPPED
    local text = isRunning and "Running" or "Stopped"
    
    TweenService:Create(self.statusIndicator, tweenInfo, {
        BackgroundColor3 = color
    }):Play()
    
    self.statusLabel.Text = text
end

function UIManager:SetWaitingState()
    for _, label in pairs(self.valueLabels) do
        label.Text = "Waiting..."
        label.TextColor3 = Config.COLORS.TEXT_DIM
    end
end

function UIManager:UpdateValues(data)
    for _, metric in ipairs(Config.METRICS) do
        local label = self.valueLabels[metric.key]
        if label and data[metric.key] then
            label.Text = string.format(metric.format, data[metric.key])
            
            -- Color coding based on thresholds
            local threshold = Config.THRESHOLDS[metric.key]
            if threshold then
                if data[metric.key] >= threshold.critical then
                    label.TextColor3 = Config.COLORS.STOPPED
                elseif data[metric.key] >= threshold.warning then
                    label.TextColor3 = Config.COLORS.WARNING
                else
                    label.TextColor3 = Config.COLORS.TEXT
                end
            else
                label.TextColor3 = Config.COLORS.TEXT
            end
        end
    end
end

function UIManager:ShowNotification(message, color)
    -- Remove old notifications
    for _, notif in pairs(self.notifications) do
        notif:Destroy()
    end
    self.notifications = {}
    
    local notification = createElement("Frame", {
        Size = UDim2.new(0, 300, 0, 50),
        Position = UDim2.new(0.5, -150, 1, 20),
        BackgroundColor3 = color or Config.COLORS.HEADER,
        BorderSizePixel = 0,
        ZIndex = 10
    }, self.mainFrame)
    
    local corner = createElement("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }, notification)
    
    local text = createElement("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = message,
        TextColor3 = Config.COLORS.TEXT,
        Font = Enum.Font.Gotham,
        TextScaled = true,
        BackgroundTransparency = 1
    }, notification)
    
    table.insert(self.notifications, notification)
    
    -- Animate in
    notification.Position = UDim2.new(0.5, -150, 1, 20)
    local tween = TweenService:Create(notification, tweenInfo, {
        Position = UDim2.new(0.5, -150, 1, -60)
    })
    tween:Play()
    
    -- Auto remove after 3 seconds
    task.wait(3)
    if notification and notification.Parent then
        local fadeOut = TweenService:Create(notification, tweenInfo, {
            Position = UDim2.new(0.5, -150, 1, 20),
            BackgroundTransparency = 1
        })
        fadeOut:Play()
        fadeOut.Completed:Wait()
        notification:Destroy()
    end
end

function UIManager:GetGraphFrames()
    return self.graphFrames
end

function UIManager:Destroy()
    if self.mainFrame then
        self.mainFrame:Destroy()
    end
end

return UIManager
