# PvPTooltip — WoW Addon

WoW addon (Lua 5.1 / WoW API) that shows PvP ratings in player tooltips. Interface: `120007` (Midnight 12.0.7).

## Commands

```bash
# Lint (luacheck.exe bundled in repo root)
./luacheck.exe src/ --config .luacheckrc

# Or via script
./scripts/run_luacheck.sh

# Release
./scripts/prepare-release.sh v1.0.X   # bumps TOC version, creates ReleaseNotes template
git add . && git commit -m "Prepare release vX.Y.Z"
git tag vX.Y.Z && git push origin master vX.Y.Z   # triggers CI release
```

## Architecture

Load order is defined by `PvPTooltip.toc` — TOC order IS the dependency order. db files load first.

```
src/db/          ← GENERATED — do not hand-edit (see below)
src/Core/        ← Addon.lua (namespace + lifecycle), Config, ErrorHandler, DatabaseBridge, EventManager, PerformanceMonitor
src/Data/        ← DatabaseManager, RealmResolver, PlayerLookup
src/UI/          ← ColorUtils, TooltipRenderer
```

Global namespace: `PvPTooltip` (table). SavedVariables: `PvPTooltipDB`.

## Gotchas

**src/db/ files are generated externally.** The Python scripts project at `E:\Coding\PvP Tooltip scripts` scrapes Seramate API → SQLite → Lua files → pushes here. Entry: `uv run generate-profiles`. Editing db files manually is pointless — next sync overwrites them.

Db shape: `b.pvpCharacters["eu"][realm][charName].brackets[bracket]={CR,TotBest,SeasBest,TotG,WR,SSSpec}`. Brackets: `2v2`, `3v3`, `ss`, `rbg`, `btz`.

**luacheck globals**: WoW API globals (`CreateFrame`, `C_Timer`, etc.) and addon globals (`PvPTooltip`, `SlashCmdList`) are all suppressed in `.luacheckrc`. Don't add `globals = {}` entries — the ignore list handles it.

## Commits

**Never commit automatically.** Always ask the user before staging or committing anything.

Best practices:
- Run `./luacheck.exe src/ --config .luacheckrc` before committing
- Stage specific files — never `git add .` or `git add -A`
- Conventional Commits format: `type(scope): subject` (≤50 chars)
- Common types: `fix`, `feat`, `chore`, `refactor`, `docs`
- Body only when the *why* isn't obvious from the subject
- Do not skip hooks (`--no-verify`)

## CI / Release

| Workflow | Trigger |
|----------|---------|
| `test.yml` | Every push/PR — luacheck + TOC validation |
| `validate-release.yml` | PRs touching release files |
| `release.yml` | Tag `v*` push — packages + publishes to CurseForge/Wago |

Secrets needed for distribution: `CURSEFORGE_TOKEN`, `WAGO_API_TOKEN`.
