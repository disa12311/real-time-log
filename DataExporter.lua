-- DataExporter.lua - Optimized data export with multiple formats
local HttpService = game:GetService("HttpService")
local Config = require(script.Parent.Config)

local DataExporter = {}
DataExporter.__index = DataExporter

function DataExporter.new()
    local self = setmetatable({}, DataExporter)
    return self
end

function DataExporter:Export(data)
    local success, result = pcall(function()
        return self:GenerateExport(data)
    end)
    
    if success then
        self:OutputToConsole(result)
        return true, "Data exported successfully!"
    else
        warn("Export failed:", result)
        return false, "Export failed: " .. tostring(result)
    end
end

function DataExporter:GenerateExport(data)
    local export = {
        metadata = {
            timestamp = os.date("%Y-%m-%d %H:%M:%S"),
            version = "1.0.0",
            place = {
                name = game.Name,
                placeId = game.PlaceId,
                gameId = game.GameId
            }
        },
        summary = {},
        metrics = {},
        analysis = {}
    }
    
    -- Process each metric
    for _, metricConfig in ipairs(Config.METRICS) do
        local key = metricConfig.key
        local values = data[key]
        
        if values and #values > 0 then
            local stats = self:CalculateStatistics(values)
            
            export.metrics[key] = {
                name = metricConfig.name,
                unit = metricConfig.unit,
                samples = #values,
                data = values,
                statistics = stats
            }
            
            -- Add to summary
            export.summary[key] = {
                current = values[#values],
                average = stats.average,
                peak = stats.max
            }
            
            -- Performance analysis
            local analysis = self:AnalyzeMetric(key, stats, metricConfig)
            if analysis then
                table.insert(export.analysis, analysis)
            end
        end
    end
    
    return export
end

function DataExporter:CalculateStatistics(values)
    local sum = 0
    local min = math.huge
    local max = -math.huge
    
    -- Basic stats
    for _, value in ipairs(values) do
        sum = sum + value
        min = math.min(min, value)
        max = math.max(max, value)
    end
    
    local average = sum / #values
    
    -- Calculate standard deviation
    local variance = 0
    for _, value in ipairs(values) do
        variance = variance + (value - average) ^ 2
    end
    variance = variance / #values
    local stdDev = math.sqrt(variance)
    
    -- Calculate percentiles
    local sorted = table.clone(values)
    table.sort(sorted)
    
    local function getPercentile(p)
        local index = math.ceil(#sorted * p / 100)
        return sorted[math.min(index, #sorted)]
    end
    
    return {
        average = average,
        min = min,
        max = max,
        stdDev = stdDev,
        percentiles = {
            p50 = getPercentile(50),  -- Median
            p95 = getPercentile(95),
            p99 = getPercentile(99)
        }
    }
end

function DataExporter:AnalyzeMetric(key, stats, config)
    local threshold = Config.THRESHOLDS[key]
    if not threshold then return nil end
    
    local analysis = {
        metric = config.name,
        status = "Good"
    }
    
    -- Check against thresholds
    if stats.average >= threshold.critical then
        analysis.status = "Critical"
        analysis.message = string.format(
            "%s is critically high (avg: %s)",
            config.name,
            string.format(config.format, stats.average)
        )
    elseif stats.average >= threshold.warning then
        analysis.status = "Warning"
        analysis.message = string.format(
            "%s is above warning threshold (avg: %s)",
            config.name,
            string.format(config.format, stats.average)
        )
    elseif stats.max >= threshold.critical then
        analysis.status = "Warning"
        analysis.message = string.format(
            "%s had critical spikes (peak: %s)",
            config.name,
            string.format(config.format, stats.max)
        )
    end
    
    return analysis.status ~= "Good" and analysis or nil
end

function DataExporter:OutputToConsole(export)
    print("\n" .. string.rep("=", 60))
    print("REAL-TIME LOG PERFORMANCE REPORT")
    print(string.rep("=", 60))
    
    -- Metadata
    print("\nREPORT DETAILS:")
    print("  Generated:", export.metadata.timestamp)
    print("  Place:", export.metadata.place.name)
    print("  Place ID:", export.metadata.place.placeId)
    
    -- Summary
    print("\nPERFORMANCE SUMMARY:")
    print(string.rep("-", 60))
    
    for _, metric in ipairs(Config.METRICS) do
        local summary = export.summary[metric.key]
        if summary then
            print(string.format(
                "  %-15s Current: %-10s Avg: %-10s Peak: %s",
                metric.name .. ":",
                string.format(metric.format, summary.current),
                string.format(metric.format, summary.average),
                string.format(metric.format, summary.peak)
            ))
        end
    end
    
    -- Detailed Statistics
    print("\nDETAILED STATISTICS:")
    print(string.rep("-", 60))
    
    for key, data in pairs(export.metrics) do
        local stats = data.statistics
        print(string.format("\n%s (%s):", data.name, data.unit))
        print(string.format("  Samples: %d", data.samples))
        print(string.format("  Min/Max: %.2f / %.2f", stats.min, stats.max))
        print(string.format("  Average: %.2f (±%.2f)", stats.average, stats.stdDev))
        print(string.format("  Percentiles: P50=%.2f, P95=%.2f, P99=%.2f",
            stats.percentiles.p50,
            stats.percentiles.p95,
            stats.percentiles.p99
        ))
    end
    
    -- Performance Analysis
    if #export.analysis > 0 then
        print("\nPERFORMANCE ISSUES DETECTED:")
        print(string.rep("-", 60))
        for _, issue in ipairs(export.analysis) do
            print(string.format("  [%s] %s", issue.status, issue.message))
        end
    else
        print("\nPERFORMANCE ANALYSIS: All metrics within acceptable ranges")
    end
    
    -- JSON Export
    print("\nJSON EXPORT:")
    print(string.rep("-", 60))
    
    local jsonSuccess, jsonData = pcall(function()
        return HttpService:JSONEncode(export)
    end)
    
    if jsonSuccess then
        print(jsonData)
    else
        print("Failed to generate JSON:", jsonData)
    end
    
    print("\n" .. string.rep("=", 60))
    print("END OF REPORT")
    print(string.rep("=", 60) .. "\n")
end

return DataExporter
