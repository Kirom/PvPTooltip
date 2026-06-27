-- Database Bridge
-- Creates a bridge between the database namespace and PvPTooltip namespace

local addonName, ns = ...

-- Store the namespace reference globally so other modules can access it
_G["PvPTooltipNamespace"] = ns

-- Initialize empty tables for database content
ns.realmSlugs = ns.realmSlugs or {}
ns.regionIDs = ns.regionIDs or {}
ns.pvpCharacters = ns.pvpCharacters or {}