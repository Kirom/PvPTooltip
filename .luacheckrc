-- luacheck config for a WoW addon.
-- CI uses luacheck to catch real Lua syntax errors, not style nits, so the
-- WoW runtime globals and cosmetic warnings are silenced here.

std = "lua51"
max_line_length = false
self = false

-- Ignore warning classes that are noise for an addon: non-standard / undefined
-- globals (the WoW API and our own namespace) and pure cosmetic whitespace.
ignore = {
    "111", -- setting non-standard global (PvPTooltip, SlashCmdList, ...)
    "112", -- mutating non-standard global
    "113", -- accessing undefined global (WoW API: CreateFrame, C_Timer, ...)
    "121", -- setting read-only global
    "142", -- setting undefined field of global
    "143", -- accessing undefined field of global
    "211", -- unused local variable (db files: local a = ...)
    "212", -- unused argument (self, callback args)
    "213", -- unused loop variable
    "231", -- variable set but never accessed
    "311", -- value assigned but never accessed
    "411", -- redefining local
    "421", -- shadowing local
    "431", -- shadowing upvalue
    "542", -- empty if branch
    "611", -- line contains only whitespace
    "612", -- trailing whitespace
    "613", -- trailing whitespace in string
    "614", -- trailing whitespace in comment
    "631", -- line too long
}
