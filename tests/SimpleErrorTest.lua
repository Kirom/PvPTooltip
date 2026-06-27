-- Simple Error Handler Test
-- Basic test to verify ErrorHandler functionality without complex dependencies

local SimpleErrorTest = {}

function SimpleErrorTest:RunTest()
    print("=== Simple Error Handler Test ===")
    
    -- Test 1: Check if ErrorHandler exists
    if not PvPTooltip then
        print("✗ PvPTooltip namespace not available")
        return false
    end
    
    if not PvPTooltip.ErrorHandler then
        print("✗ ErrorHandler module not available")
        print("Available modules:")
        for key, value in pairs(PvPTooltip) do
            if type(value) == "table" then
                print("  - " .. key)
            end
        end
        return false
    end
    
    print("✓ ErrorHandler module available")
    
    -- Test 2: Check if SafeCall method exists
    if not PvPTooltip.ErrorHandler.SafeCall then
        print("✗ SafeCall method not available")
        print("Available ErrorHandler methods:")
        for key, value in pairs(PvPTooltip.ErrorHandler) do
            if type(value) == "function" then
                print("  - " .. key)
            end
        end
        return false
    end
    
    print("✓ SafeCall method available")
    
    -- Test 3: Test SafeCall with successful function
    local success, result = PvPTooltip.ErrorHandler:SafeCall(function() 
        return "test success" 
    end, "SimpleTest")
    
    if not success or result ~= "test success" then
        print("✗ SafeCall failed with successful function")
        return false
    end
    
    print("✓ SafeCall works with successful function")
    
    -- Test 4: Test SafeCall with error function
    success, result = PvPTooltip.ErrorHandler:SafeCall(function() 
        error("test error") 
    end, "SimpleTest")
    
    if success then
        print("✗ SafeCall should have returned false for error function")
        return false
    end
    
    print("✓ SafeCall correctly handles error function")
    
    -- Test 5: Test LogError method
    if PvPTooltip.ErrorHandler.LogError then
        PvPTooltip.ErrorHandler:LogError("SimpleTest", "Test error message", true) -- Suppress logging
        print("✓ LogError method works")
    else
        print("✗ LogError method not available")
        return false
    end
    
    print("=== Simple Error Handler Test: ALL PASSED ===")
    return true
end

-- Make it globally accessible
_G.SimpleErrorTest = SimpleErrorTest

-- Auto-run when loaded
if PvPTooltip and PvPTooltip.ErrorHandler then
    SimpleErrorTest:RunTest()
else
    print("SimpleErrorTest: Waiting for PvPTooltip to load...")
end

return SimpleErrorTest