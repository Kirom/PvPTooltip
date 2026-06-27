-- Debug script to check module loading
print("=== Module Debug ===")

if PvPTooltip then
    print("PvPTooltip namespace exists")
    
    for key, value in pairs(PvPTooltip) do
        print("PvPTooltip." .. key .. " = " .. type(value))
        
        if type(value) == "table" then
            local methodCount = 0
            for k, v in pairs(value) do
                if type(v) == "function" then
                    methodCount = methodCount + 1
                end
            end
            print("  Methods: " .. methodCount)
        end
    end
else
    print("PvPTooltip namespace does not exist")
end