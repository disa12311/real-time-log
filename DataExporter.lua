-- DataExporter.lua - Handles data export functionality

local DataExporter = {}

local HttpService = game:GetService("HttpService")

function DataExporter.export(data)
    local success, result = pcall(function()
        -- Create export data structure
        local exportData = {
            timestamp = os.date("%Y-%m-%d %H:%M:%S"),
            sessionInfo = {
                placeName = game.Name,
                placeId = game.PlaceId,
                gameId = game.GameId
            },
            metrics = {}
        }
        
        -- Process each metric
        for key, values in pairs(data) do
            if #values > 0 then
                local stats = DataExporter.calculateStats(values)
                exportData.metrics[key] = {
                    data = values,
                    statistics = stats
                }
            end
        end
        
        -- Convert to JSON
        local jsonData = HttpService:JSONEncode(exportData)
        
        -- Output to console
        print("=== Real-Time Log Export ===")
        print("Timestamp:", exportData.timestamp)
        print("Place:", exportData.sessionInfo.placeName)
        print("")
        
        -- Print statistics
        print("Performance Statistics:")
        for metric, data in pairs(exportData.metrics) do
            print(string.format("\n%s:", metric:upper()))
            print(string.format("  Average: %.2f", data.statistics.average))
            print(string.format("  Min: %.2f", data.statistics.min))
            print(string.format("  Max: %.2f", data.statistics.max))
            print(string.format("  Std Dev: %.2f", data.statistics.stdDev))
        end
        
        print("\n=== Raw JSON Data ===")
        print(jsonData)
        print("======================")
        
        return true
    end)
    
    return success
end

function DataExporter.calculateStats(values)
    if #values == 0 then
        return {
            average = 0,
            min = 0,
            max = 0,
            stdDev = 0
        }
    end
    
    -- Calculate average
    local sum = 0
    for _, value in ipairs(values) do
        sum = sum + value
    end
    local average = sum / #values
    
    -- Find min and max
    local min = values[1]
    local max = values[1]
    for _, value in ipairs(values) do
        if value < min then min = value end
        if value > max then max = value end
    end
    
    -- Calculate standard deviation
    local sumSquaredDiff = 0
    for _, value in ipairs(values) do
        sumSquaredDiff = sumSquaredDiff + (value - average)^2
    end
    local stdDev = math.sqrt(sumSquaredDiff / #values)
    
    return {
        average = average,
        min = min,
        max = max,
        stdDev = stdDev
    }
end

return DataExporter