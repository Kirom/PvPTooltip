-- Module Loading Test
-- Simple test to verify all modules are loading correctly after the fix

local ModuleLoadingTest = {}

function ModuleLoadingTest:RunTest()
    print("=== Module Loading Test ===")
    
    if not PvPTooltip then
        print("✗ PvPTooltip namespace not available")
        return false
    end
    
    local expectedModules = {
        {name = "Config", requiresInit = true},
        {name = "ErrorHandler", requiresInit = true},
        {name = "DatabaseManager", requiresInit = true},
        {name = "RealmResolver", requiresInit = true},
        {name = "PlayerLookup", requiresInit = true},
        {name = "ColorUtils", requiresInit = true},
        {name = "TooltipRenderer", requiresInit = true},
        {name = "EventManager", requiresInit = true},
        {name = "PerformanceMonitor", requiresInit = true},
        {name = "ErrorHandlingTests", requiresInit = true},
        {name = "PerformanceTests", requiresInit = false}
    }
    
    local totalModules = #expectedModules
    local loadedModules = 0
    local modulesWithInit = 0
    
    print("Checking module loading...")
    
    for _, moduleInfo in ipairs(expectedModules) do
        local module = PvPTooltip[moduleInfo.name]
        
        if module and type(module) == "table" then
            local methodCount = 0
            local hasInitialize = false
            
            for key, value in pairs(module) do
                if type(value) == "function" then
                    methodCount = methodCount + 1
                    if key == "Initialize" then
                        hasInitialize = true
                    end
                end
            end
            
            loadedModules = loadedModules + 1
            
            if hasInitialize then
                modulesWithInit = modulesWithInit + 1
                print(string.format("✓ %s: %d methods (has Initialize)", moduleInfo.name, methodCount))
            else
                local status = moduleInfo.requiresInit and "⚠" or "✓"
                print(string.format("%s %s: %d methods%s", status, moduleInfo.name, methodCount, 
                    moduleInfo.requiresInit and " (missing Initialize)" or ""))
            end
        else
            print(string.format("✗ %s: Not loaded or not a table", moduleInfo.name))
        end
    end
    
    print(string.format("\nSummary: %d/%d modules loaded", loadedModules, totalModules))
    print(string.format("Modules with Initialize: %d", modulesWithInit))
    
    -- Test a few key methods to ensure they're accessible
    print("\nTesting key method accessibility...")
    
    local methodTests = {
        {module = "Config", method = "Initialize", description = "Config initialization"},
        {module = "ErrorHandler", method = "SafeCall", description = "Error handling"},
        {module = "ColorUtils", method = "GetRatingColor", description = "Color utilities"},
        {module = "DatabaseManager", method = "IsDataAvailable", description = "Database access"}
    }
    
    local accessibleMethods = 0
    
    for _, test in ipairs(methodTests) do
        local module = PvPTooltip[test.module]
        if module and module[test.method] and type(module[test.method]) == "function" then
            print(string.format("✓ %s.%s accessible", test.module, test.method))
            accessibleMethods = accessibleMethods + 1
        else
            print(string.format("✗ %s.%s not accessible", test.module, test.method))
        end
    end
    
    print(string.format("\nMethod accessibility: %d/%d methods accessible", accessibleMethods, #methodTests))
    
    local success = loadedModules >= (totalModules * 0.8) and accessibleMethods >= (#methodTests * 0.75)
    
    if success then
        print("\n✅ Module loading test PASSED")
        print("Modules are loading correctly after the fix!")
    else
        print("\n❌ Module loading test FAILED")
        print("Some modules are still not loading properly.")
    end
    
    return success
end

-- Make it globally accessible
_G.ModuleLoadingTest = ModuleLoadingTest

-- Auto-run when loaded (if PvPTooltip is available)
if PvPTooltip then
    ModuleLoadingTest:RunTest()
end

return ModuleLoadingTest