-- PvPTooltip Error Handler
-- Centralized error handling and graceful degradation utilities

local ErrorHandler = {}
PvPTooltip.ErrorHandler = ErrorHandler

-- Error tracking
local errorCounts = {}
local lastErrorTime = {}
local maxErrorsPerMinute = 10
local errorSuppressionTime = 60 -- seconds

-- Initialize the error handler
function ErrorHandler:Initialize()
    PvPTooltip:Debug("ErrorHandler module initialized")
end

-- Safe function call with error tracking and suppression
function ErrorHandler:SafeCall(func, context, ...)
    if not func or type(func) ~= "function" then
        self:LogError("SafeCall", "Invalid function provided", context)
        return false, "Invalid function"
    end
    
    local success, result = pcall(func, ...)
    
    if not success then
        self:LogError(context or "Unknown", result)
        return false, result
    end
    
    return true, result
end

-- Log error with rate limiting to prevent spam
function ErrorHandler:LogError(context, errorMsg, suppressLogging)
    if not context then
        context = "Unknown"
    end
    
    if not errorMsg then
        errorMsg = "Unknown error"
    end
    
    -- Initialize error tracking for this context
    if not errorCounts[context] then
        errorCounts[context] = 0
        lastErrorTime[context] = 0
    end
    
    local currentTime = GetTime()
    
    -- Reset error count if enough time has passed
    if currentTime - lastErrorTime[context] > 60 then
        errorCounts[context] = 0
    end
    
    errorCounts[context] = errorCounts[context] + 1
    lastErrorTime[context] = currentTime
    
    -- Only log if we haven't exceeded the rate limit
    if errorCounts[context] <= maxErrorsPerMinute and not suppressLogging then
        PvPTooltip:Debug(string.format("[%s] Error: %s", context, tostring(errorMsg)))
        
        -- Log to saved variables for debugging if available
        if PvPTooltipDB and PvPTooltipDB.errorLog then
            table.insert(PvPTooltipDB.errorLog, {
                context = context,
                error = tostring(errorMsg),
                time = date("%Y-%m-%d %H:%M:%S"),
                count = errorCounts[context]
            })
            
            -- Keep only last 100 errors
            if #PvPTooltipDB.errorLog > 100 then
                table.remove(PvPTooltipDB.errorLog, 1)
            end
        end
    elseif errorCounts[context] == maxErrorsPerMinute + 1 then
        PvPTooltip:Debug(string.format("[%s] Error rate limit reached, suppressing further errors", context))
    end
end

-- Validate data structure with detailed error reporting
function ErrorHandler:ValidateDataStructure(data, expectedStructure, context)
    if not data then
        self:LogError(context, "Data is nil")
        return false, "Data is nil"
    end
    
    if not expectedStructure then
        return true, "No validation structure provided"
    end
    
    local function validateRecursive(obj, structure, path)
        for key, expectedType in pairs(structure) do
            local fullPath = path and (path .. "." .. key) or key
            
            if obj[key] == nil then
                return false, "Missing required field: " .. fullPath
            end
            
            if type(expectedType) == "string" then
                -- Simple type check
                if type(obj[key]) ~= expectedType then
                    return false, string.format("Field %s expected %s, got %s", fullPath, expectedType, type(obj[key]))
                end
            elseif type(expectedType) == "table" then
                -- Nested structure check
                if type(obj[key]) ~= "table" then
                    return false, string.format("Field %s expected table, got %s", fullPath, type(obj[key]))
                end
                
                local success, error = validateRecursive(obj[key], expectedType, fullPath)
                if not success then
                    return false, error
                end
            end
        end
        
        return true, "Validation passed"
    end
    
    local success, error = validateRecursive(data, expectedStructure)
    
    if not success then
        self:LogError(context, "Data validation failed: " .. error)
    end
    
    return success, error
end

-- Safe table access with fallback values
function ErrorHandler:SafeTableAccess(table, keys, fallback)
    if not table or type(table) ~= "table" then
        return fallback
    end
    
    local current = table
    
    for _, key in ipairs(keys) do
        if type(current) ~= "table" or current[key] == nil then
            return fallback
        end
        current = current[key]
    end
    
    return current
end

-- Safe string operations
function ErrorHandler:SafeStringOp(str, operation, ...)
    if not str or type(str) ~= "string" then
        return ""
    end
    
    local success, result = pcall(string[operation], str, ...)
    
    if success then
        return result
    else
        self:LogError("SafeStringOp", "String operation failed: " .. operation)
        return str -- Return original string as fallback
    end
end

-- Safe number operations with bounds checking
function ErrorHandler:SafeNumber(value, min, max, fallback)
    if type(value) ~= "number" or value ~= value then -- NaN check
        return fallback or 0
    end
    
    if min and value < min then
        return min
    end
    
    if max and value > max then
        return max
    end
    
    return value
end

-- Check if error rate limiting is active for a context
function ErrorHandler:IsErrorSuppressed(context)
    if not errorCounts[context] then
        return false
    end
    
    return errorCounts[context] > maxErrorsPerMinute
end

-- Get error statistics for debugging
function ErrorHandler:GetErrorStats()
    local stats = {}
    
    for context, count in pairs(errorCounts) do
        stats[context] = {
            count = count,
            lastError = lastErrorTime[context],
            suppressed = count > maxErrorsPerMinute
        }
    end
    
    return stats
end

-- Reset error tracking for a specific context or all contexts
function ErrorHandler:ResetErrorTracking(context)
    if context then
        errorCounts[context] = 0
        lastErrorTime[context] = 0
    else
        errorCounts = {}
        lastErrorTime = {}
    end
    
    PvPTooltip:Debug("Error tracking reset" .. (context and (" for " .. context) or " for all contexts"))
end

-- Create a safe wrapper function for any function
function ErrorHandler:CreateSafeWrapper(func, context, fallbackReturn)
    return function(...)
        local success, result = self:SafeCall(func, context, ...)
        
        if success then
            return result
        else
            return fallbackReturn
        end
    end
end

-- Graceful degradation helper - attempts primary function, falls back to secondary
function ErrorHandler:GracefulFallback(primaryFunc, fallbackFunc, context, ...)
    local success, result = self:SafeCall(primaryFunc, context .. "_primary", ...)
    
    if success then
        return result
    end
    
    if fallbackFunc then
        local success, result = self:SafeCall(fallbackFunc, context .. "_fallback", ...)
        if success then
            return result
        end
    end
    
    return nil
end

-- Database corruption detection and recovery
function ErrorHandler:ValidateDatabaseIntegrity(data, context)
    if not data or type(data) ~= "table" then
        self:LogError(context, "Database data is not a table")
        return false
    end
    
    -- Check for basic structure
    local hasValidEntries = false
    local corruptedEntries = 0
    local totalEntries = 0
    
    for key, value in pairs(data) do
        totalEntries = totalEntries + 1
        
        if type(value) == "table" then
            hasValidEntries = true
        else
            corruptedEntries = corruptedEntries + 1
        end
    end
    
    local corruptionRate = totalEntries > 0 and (corruptedEntries / totalEntries) or 0
    
    if corruptionRate > 0.5 then
        self:LogError(context, string.format("High corruption rate detected: %.1f%% (%d/%d entries)", 
            corruptionRate * 100, corruptedEntries, totalEntries))
        return false
    end
    
    if not hasValidEntries then
        self:LogError(context, "No valid entries found in database")
        return false
    end
    
    if corruptedEntries > 0 then
        PvPTooltip:Debug(string.format("[%s] Minor corruption detected: %d corrupted entries out of %d", 
            context, corruptedEntries, totalEntries))
    end
    
    return true
end

-- Memory usage monitoring
function ErrorHandler:CheckMemoryUsage(context, threshold)
    threshold = threshold or 50 -- MB
    
    local success, memUsage = pcall(function()
        collectgarbage("collect")
        return collectgarbage("count") / 1024 -- Convert to MB
    end)
    
    if success and memUsage > threshold then
        self:LogError(context, string.format("High memory usage detected: %.1f MB", memUsage))
        return false, memUsage
    end
    
    return true, memUsage or 0
end

-- Return the module for proper loading
return ErrorHandler