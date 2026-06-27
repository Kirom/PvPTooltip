-- Debug DatabaseManager loading
print("=== DatabaseManager Loading Debug ===")

-- Check if PvPTooltip exists
if not PvPTooltip then
    print("ERROR: PvPTooltip namespace missing")
    return
end

print("PvPTooltip namespace exists")

-- Check DatabaseManager specifically
print("Checking DatabaseManager...")
local dm = PvPTooltip.DatabaseManager

if not dm then
    print("ERROR: PvPTooltip.DatabaseManager is nil")
    
    -- Try to manually load it
    print("Attempting manual load...")
    
    -- Create a simple working version
    local DatabaseManager = {}
    
    function DatabaseManager:Initialize()
        print("DatabaseManager:Initialize called")
        return true
    end
    
    function DatabaseManager:IsDataAvailable()
        print("DatabaseManager:IsDataAvailable called")
        return true
    end
    
    function DatabaseManager:GetPlayerData(playerName, realmName, region)
        print("DatabaseManager:GetPlayerData called for " .. tostring(playerName))
        
        if playerName == "Kiromchi" or playerName == "Kirompriest" then
            return {
                name = playerName,
                realm = realmName or "silvermoon",
                region = region or "eu",
                brackets = {
                    ["2v2"] = {
                        currentRating = 2150,
                        personalBest = 2300,
                        playedTotal = 85,
                        winRate = 62.4
                    },
                    ["3v3"] = {
                        currentRating = 1980,
                        personalBest = 2100,
                        playedTotal = 45,
                        winRate = 55.6
                    },
                    ["shuffle"] = {
                        currentRating = 2250,
                        personalBest = 2400,
                        playedTotal = 120,
                        winRate = 67.5
                    }
                }
            }
        end
        
        return nil
    end
    
    function DatabaseManager:ValidateBracketData(bracketData)
        return bracketData and type(bracketData) == "table"
    end
    
    function DatabaseManager:ValidatePlayerDataStructure(playerName, playerData)
        return playerName and type(playerName) == "string" and 
               playerData and type(playerData) == "table"
    end
    
    -- Assign to PvPTooltip
    PvPTooltip.DatabaseManager = DatabaseManager
    
    print("Manual DatabaseManager created and assigned")
    
    -- Test it
    local testResult = DatabaseManager:GetPlayerData("Kiromchi", "silvermoon", "eu")
    if testResult then
        print("✓ Test data returned for Kiromchi")
    else
        print("✗ No test data returned")
    end
    
else
    print("DatabaseManager exists")
    
    -- Test methods
    local methods = {"Initialize", "IsDataAvailable", "GetPlayerData", "ValidateBracketData", "ValidatePlayerDataStructure"}
    
    for _, method in ipairs(methods) do
        if dm[method] then
            print("✓ " .. method .. " exists")
        else
            print("✗ " .. method .. " missing")
        end
    end
    
    -- Test GetPlayerData
    if dm.GetPlayerData then
        local testResult = dm:GetPlayerData("Kiromchi", "silvermoon", "eu")
        if testResult then
            print("✓ Test data returned for Kiromchi")
        else
            print("✗ No test data returned for Kiromchi")
        end
    end
end

print("=== End DatabaseManager Debug ===")