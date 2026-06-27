-- Readiness Test
-- Check why the addon shows "Ready: No"

print("=== Addon Readiness Test ===")

-- Check PvPTooltip namespace
if not PvPTooltip then
    print("✗ PvPTooltip namespace missing")
    return
end

print("✓ PvPTooltip namespace exists")

-- Check IsReady function components
local addonLoaded = true -- This should be true if we're running
local playerLoggedIn = true -- This should be true if we're in game

print("Checking IsReady components:")
print("  addonLoaded: " .. tostring(addonLoaded))
print("  playerLoggedIn: " .. tostring(playerLoggedIn))

if PvPTooltipDB then
    print("  PvPTooltipDB.enabled: " .. tostring(PvPTooltipDB.enabled))
    print("  PvPTooltipDB exists: ✓")
else
    print("  PvPTooltipDB: ✗ Missing!")
end

-- Check IsReady result
if PvPTooltip.IsReady then
    local isReady = PvPTooltip:IsReady()
    print("IsReady result: " .. tostring(isReady))
else
    print("✗ IsReady function missing")
end

-- Check DatabaseManager specifically
print("\nDatabaseManager check:")
if PvPTooltip.DatabaseManager then
    print("✓ DatabaseManager exists")
    
    if PvPTooltip.DatabaseManager.Initialize then
        print("✓ DatabaseManager.Initialize exists")
        
        -- Try to initialize it
        local success, result = pcall(PvPTooltip.DatabaseManager.Initialize, PvPTooltip.DatabaseManager)
        if success then
            print("✓ DatabaseManager.Initialize succeeded")
        else
            print("✗ DatabaseManager.Initialize failed: " .. tostring(result))
        end
    else
        print("✗ DatabaseManager.Initialize missing")
    end
    
    if PvPTooltip.DatabaseManager.IsDataAvailable then
        local dataAvailable = PvPTooltip.DatabaseManager:IsDataAvailable()
        print("DatabaseManager.IsDataAvailable: " .. tostring(dataAvailable))
    else
        print("✗ DatabaseManager.IsDataAvailable missing")
    end
else
    print("✗ DatabaseManager missing")
end

-- Check if addon initialization completed
print("\nAddon initialization check:")
if PvPTooltip.Initialize then
    print("✓ PvPTooltip.Initialize exists")
else
    print("✗ PvPTooltip.Initialize missing")
end

print("=== End Readiness Test ===")