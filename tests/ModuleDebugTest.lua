-- Module Debug Test
-- Debug script to understand why some modules aren't loading

print("=== Module Debug Test ===")

-- Check if PvPTooltip namespace exists
if not PvPTooltip then
    print("ERROR: PvPTooltip namespace does not exist!")
    return
end

print("PvPTooltip namespace exists")

-- Check each module individually
local modules = {
    "Config", "ErrorHandler", "DatabaseManager", "RealmResolver", 
    "PlayerLookup", "ColorUtils", "TooltipRenderer", "EventManager", 
    "PerformanceMonitor", "ErrorHandlingTests", "PerformanceTests"
}

for _, moduleName in ipairs(modules) do
    local module = PvPTooltip[moduleName]
    
    if not module then
        print(string.format("✗ %s: Module is nil", moduleName))
    elseif type(module) ~= "table" then
        print(string.format("✗ %s: Module is %s (not table)", moduleName, type(module)))
    else
        local methodCount = 0
        local hasInitialize = false
        local methods = {}
        
        for key, value in pairs(module) do
            if type(value) == "function" then
                methodCount = methodCount + 1
                table.insert(methods, key)
                if key == "Initialize" then
                    hasInitialize = true
                end
            end
        end
        
        if methodCount > 0 then
            print(string.format("✓ %s: %d methods%s", moduleName, methodCount, 
                hasInitialize and " (has Initialize)" or " (no Initialize)"))
            
            -- Show first few methods for debugging
            if #methods > 0 then
                local methodList = {}
                for i = 1, math.min(3, #methods) do
                    table.insert(methodList, methods[i])
                end
                print(string.format("    Methods: %s%s", table.concat(methodList, ", "), 
                    #methods > 3 and "..." or ""))
            end
        else
            print(string.format("⚠ %s: Table exists but no methods found", moduleName))
        end
    end
end

-- Test a specific module that should work
if PvPTooltip.Config and PvPTooltip.Config.Initialize then
    print("\nTesting Config.Initialize...")
    local success, result = pcall(PvPTooltip.Config.Initialize, PvPTooltip.Config)
    if success then
        print("✓ Config.Initialize worked")
    else
        print("✗ Config.Initialize failed: " .. tostring(result))
    end
end

-- Check if the addon is enabled
if PvPTooltipDB then
    print(string.format("\nAddon enabled: %s", tostring(PvPTooltipDB.enabled)))
else
    print("\nPvPTooltipDB not available")
end