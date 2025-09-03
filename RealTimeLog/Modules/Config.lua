-- Config.lua - Centralized configuration
local Config = {}

-- UI Settings
Config.WINDOW_SIZE = Vector2.new(900, 650)
Config.GRAPH_HEIGHT = 120
Config.GRAPH_PADDING = 25
Config.HEADER_HEIGHT = 50
Config.ICON_ID = "rbxassetid://7733919682" -- Dashboard icon

-- Performance Settings
Config.UPDATE_RATE = 0.1 -- Data collection rate (100ms)
Config.RENDER_RATE = 0.2 -- Graph render rate (200ms)
Config.MAX_DATA_POINTS = 100

-- Colors
Config.COLORS = {
    -- UI Colors
    BACKGROUND = Color3.fromRGB(25, 25, 25),
    HEADER = Color3.fromRGB(35, 35, 35),
    PANEL = Color3.fromRGB(30, 30, 30),
    GRAPH_BG = Color3.fromRGB(20, 20, 20),
    GRID = Color3.fromRGB(45, 45, 45),
    TEXT = Color3.fromRGB(220, 220, 220),
    TEXT_DIM = Color3.fromRGB(150, 150, 150),
    
    -- Status Colors
    RUNNING = Color3.fromRGB(100, 255, 100),
    STOPPED = Color3.fromRGB(255, 100, 100),
    WARNING = Color3.fromRGB(255, 200, 100),
    
    -- Button Colors
    BUTTON_CLEAR = Color3.fromRGB(200, 60, 60),
    BUTTON_EXPORT = Color3.fromRGB(60, 120, 200),
    BUTTON_HOVER = Color3.fromRGB(255, 255, 255),
}

-- Metrics Configuration
Config.METRICS = {
    {
        key = "fps",
        name = "FPS",
        color = Color3.fromRGB(100, 255, 100),
        maxValue = 120,
        format = "%d FPS",
        unit = "fps"
    },
    {
        key = "memory",
        name = "Memory",
        color = Color3.fromRGB(255, 200, 100),
        maxValue = 2048,
        format = "%.1f MB",
        unit = "MB"
    },
    {
        key = "cpu",
        name = "CPU Usage",
        color = Color3.fromRGB(255, 100, 100),
        maxValue = 100,
        format = "%.1f%%",
        unit = "%"
    },
    {
        key = "render",
        name = "Render",
        color = Color3.fromRGB(100, 200, 255),
        maxValue = 33.33, -- 30 FPS threshold
        format = "%.2f ms",
        unit = "ms"
    },
    {
        key = "physics",
        name = "Physics",
        color = Color3.fromRGB(255, 150, 100),
        maxValue = 50,
        format = "%.2f ms",
        unit = "ms"
    },
    {
        key = "heartbeat",
        name = "Heartbeat",
        color = Color3.fromRGB(200, 100, 255),
        maxValue = 50,
        format = "%.2f ms",
        unit = "ms"
    },
    {
        key = "network_in",
        name = "Network In",
        color = Color3.fromRGB(100, 255, 200),
        maxValue = 100,
        format = "%.1f KB/s",
        unit = "KB/s"
    },
    {
        key = "network_out",
        name = "Network Out",
        color = Color3.fromRGB(255, 100, 200),
        maxValue = 100,
        format = "%.1f KB/s",
        unit = "KB/s"
    }
}

-- Performance thresholds for warnings
Config.THRESHOLDS = {
    fps = {warning = 30, critical = 20},
    memory = {warning = 1024, critical = 1536},
    cpu = {warning = 80, critical = 95},
    render = {warning = 33.33, critical = 50},
    physics = {warning = 30, critical = 40},
}

return Config
