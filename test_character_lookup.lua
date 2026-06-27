-- Test script to verify character data retrieval
-- This script tests if characters from the database can be properly retrieved

-- Create a simple test environment
local testNamespace = {}

-- Load the database file
local function loadDatabase()
    -- Simulate the addon namespace
    local addonName, ns = "PvPTooltip", testNamespace
    
    -- Load the database file
    local chunk, err = loadfile("src/db/db_pvp_eu_characters.lua")
    if not chunk then
        print("Error loading database file: " .. tostring(err))
        return false
    end
    
    -- Execute the database file with our namespace
    local success, result = pcall(chunk, addonName, ns)
    if not success then
        print("Error executing database file: " .. tostring(result))
        return false
    end
    
    print("Database loaded successfully")
    return true
end

-- Test character lookup
local function testCharacterLookup(characterName, realmName)
    if not testNamespace.pvpCharacters then
        print("No PvP character data available")
        return false
    end
    
    local euData = testNamespace.pvpCharacters["eu"]
    if not euData then
        print("No EU data available")
        return false
    end
    
    local realmData = euData[realmName]
    if not realmData then
        print("Realm '" .. realmName .. "' not found")
        return false
    end
    
    local characterData = realmData[characterName]
    if not characterData then
        print("Character '" .. characterName .. "' not found on realm '" .. realmName .. "'")
        return false
    end
    
    print("Character found: " .. characterName .. " on " .. realmName)
    
    -- Display character data
    if characterData.brackets then
        print("PvP Data:")
        for gameMode, bracketData in pairs(characterData.brackets) do
            if bracketData.currentRating and bracketData.currentRating > 0 then
                print("  " .. gameMode .. ": " .. bracketData.currentRating .. " (PB: " .. (bracketData.personalBest or 0) .. ")")
            end
        end
    end
    
    return true
end

-- Main test function
local function runTest()
    print("=== Character Lookup Test ===")
    
    -- Load database
    if not loadDatabase() then
        print("Failed to load database")
        return
    end
    
    -- Test specific characters
    print("\nTesting character lookups:")
    
    -- Test Kiromchi-Silvermoon
    testCharacterLookup("Kiromchi", "silvermoon")
    
    -- Test Kirompriest-Silvermoon
    testCharacterLookup("Kirompriest", "silvermoon")
    
    -- Test a known working character
    testCharacterLookup("Baumling", "aegwynn")
    
    print("\n=== Test Complete ===")
end

-- Run the test
runTest()