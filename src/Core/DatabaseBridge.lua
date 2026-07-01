-- Database Bridge
-- Creates a bridge between the database namespace and PvPTooltip namespace

local addonName, ns = ...

-- Store the namespace reference globally so other modules can access it
_G["PvPTooltipNamespace"] = ns

-- Initialize empty tables for database content
ns.realmSlugs = ns.realmSlugs or {}
ns.regionIDs = ns.regionIDs or {}

-- Character data is populated by the per-region data add-ons (PvPTooltip_DataEU /
-- PvPTooltip_DataUS), which write directly to the PvPTooltip global (a separate
-- add-on cannot reach this private `ns`). Seed the table so lookups are safe even
-- when no region add-on is loaded (e.g. KR/TW/CN).
PvPTooltip = PvPTooltip or {}
PvPTooltip.pvpCharacters = PvPTooltip.pvpCharacters or {}