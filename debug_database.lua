-- Debug DatabaseManager loading
print("=== DatabaseManager Debug ===")

-- Check if PvPTooltip exists
if not PvPTooltip then
    print("ERROR: PvPTooltip namespace missing")
    return
end

print("PvPTooltip namespace exists")

-- Check DatabaseManager specifically
local dm = PvPTooltip.DatabaseManager
if not dm then
    print("ERROR: DatabaseManager is nil")
    
    -- Try to manually create it to test syntax
    print("Attempting to load DatabaseManager manually...")
    
    -- This would normally be done by the file loading
    local DatabaseManager = {}
    PvPTooltip.DatabaseManager = DatabaseManager
    
    -- Add a simple test function
    function DatabaseManager:Initialize()
        print("DatabaseManager Initialize called")
        return true
    end
    
    function DatabaseManager:IsDataAvailable()
        print("DatabaseManager IsDataAvailable called")
        return false
    end
    
    print("Manual DatabaseManager created")
    
elseif type(dm) ~= "table" then
    print("ERROR: DatabaseManager is " .. type(dm) .. ", not table")
else
    print("DatabaseManager exists as table")
    
    -- Count methods
    local methodCount = 0
    for key, value in pairs(dm) do
        if type(value) == "function" then
            methodCount = methodCount + 1
        end
    end
    
    print("DatabaseManager has " .. methodCount .. " methods")
    
    -- Test Initialize
    if dm.Initialize then
        print("Initialize method exists")
        local success, result = pcall(dm.Initialize, dm)
        if success then
            print("Initialize succeeded")
        else
            print("Initialize failed: " .. tostring(result))
        end
    else
        print("Initialize method missing")
    end
    
    -- Test IsDataAvailable
    if dm.IsDataAvailable then
        print("IsDataAvailable method exists")
        local success, result = pcall(dm.IsDataAvailable, dm)
        if success then
            print("IsDataAvailable result: " .. tostring(result))
        else
            print("IsDataAvailable failed: " .. tostring(result))
        end
    else
        print("IsDataAvailable method missing")
    end
end