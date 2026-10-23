<div align="center">

<img src="assets/icons/github-256.png" width="128" alt="PvP Tooltip icon">

# PvP Tooltip

**Ranked PvP ratings, personal bests and season stats — right in the player tooltip.**

</div>

<div align="center">

[![Release](https://img.shields.io/github/v/release/Kirom/PvPTooltip)](https://github.com/Kirom/PvPTooltip/releases/latest)
[![Build](https://img.shields.io/github/actions/workflow/status/Kirom/PvPTooltip/release.yml?label=Build)](https://github.com/Kirom/PvPTooltip/actions)
[![CurseForge](https://img.shields.io/badge/CurseForge-Install-orange?logo=curseforge)](https://www.curseforge.com/wow/addons/pvptooltip)
[![Wago](https://img.shields.io/badge/Wago-Install-blue)](https://addons.wago.io/addons/pvptooltip)

[![World of Warcraft](https://img.shields.io/badge/World%20of%20Warcraft-Midnight-0084ff?logo=battle.net)](https://worldofwarcraft.blizzard.com/)
[![Game Version](https://img.shields.io/badge/Game%20Version-12.1.5-brightgreen)](https://github.com/Kirom/PvPTooltip)
[![Issues](https://img.shields.io/github/issues/Kirom/PvPTooltip)](https://github.com/Kirom/PvPTooltip/issues)

[![Discord](https://img.shields.io/badge/Discord-Join%20Community-7289DA?logo=discord)](https://discord.gg/A5N6KEgbCc)

</div>

PvP Tooltip is a World of Warcraft addon that adds ranked PvP information to player tooltips. Hover over any player — in the open world, your group, or Group Finder — and instantly see their current ratings, personal bests and season stats across every competitive bracket. No clicks, no website, no setup.

## Features

- **Ratings for every bracket** — 2v2, 3v3, Solo Shuffle, Rated Battlegrounds and Blitz
- **Personal bests** — all-time peak rating per bracket
- **Season stats** — games played and win rate for the current season
- **Per-spec Shuffle/Blitz** — see each spec's rating, or just active spec
- **Color-coded ratings** — read skill level at a glance
- **Four tooltip layouts** — Panel with rating bars (default), Compact table, Sections, or Classic
- **In-game settings panel** — toggle sections, brackets and a show-on-modifier key, with a live tooltip preview
- **Multi-region** — EU and US databases, refreshed frequently
- **Cross-realm & cross-faction** lookup, everywhere a unit tooltip appears
- **Minimal footprint** — fast lookups, no measurable performance impact

## What You'll See

Hovering a player adds a PvP block to the tooltip with this data for each enabled bracket:

| Data | Shows |
|------|-------|
| **Current Rating** | Current-season rating, color-coded |
| **Character Experience** (Best) | All-time personal-best rating |
| **Games Played** | Games played this season and win rate |

Pick how it's laid out in the settings panel (`/pvpt` → **Tooltip layout**):

<table>
  <tr>
    <td align="center" valign="top" width="50%">
      <img src="assets/layouts/panel.png" width="360" alt="Panel layout"><br>
      <b>Panel</b> (default)<br>
      An aligned table with column headers and a rating bar per bracket (fill = current, tick = best)
    </td>
    <td align="center" valign="top" width="50%">
      <img src="assets/layouts/compact.png" width="360" alt="Compact layout"><br>
      <b>Compact</b><br>
      One line per bracket with aligned Current / Best / Played / Win% columns
    </td>
  </tr>
  <tr>
    <td align="center" valign="top" width="50%">
      <img src="assets/layouts/sections.png" width="360" alt="Sections layout"><br>
      <b>Sections</b><br>
      Rating, personal best and games played listed in separate sections
    </td>
    <td align="center" valign="top" width="50%">
      <img src="assets/layouts/classic.png" width="360" alt="Classic layout"><br>
      <b>Classic</b><br>
      The original three-section look
    </td>
  </tr>
</table>

For Solo Shuffle and Blitz, ratings are shown **per spec** with the spec's icon; when the hovered player's active spec is known, the other specs are dimmed.

### Color Coding

**Ratings**

| Rating | Color | Tier |
|--------|-------|------|
| 0–1799 | White | Unrated / Low |
| 1800–2099 | Green | Rival / Combatant |
| 2100–2399 | Blue | Challenger / Elite |
| 2400+ | Purple | Gladiator |

**Stats** — Games played: gold · Win rate ≤50%: red · Win rate >50%: green.

## Installation

### Addon managers (recommended)

- **CurseForge** — search **"PvP Tooltip"** and install
- **Wago** — search **"PvP Tooltip"** and install
- **WowUp** — installs directly from GitHub releases

### Manual

1. Download the latest release from [GitHub Releases](https://github.com/Kirom/PvPTooltip/releases/latest).
2. Extract the `PvPTooltip` folder into your AddOns directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **macOS**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or `/reload`.
4. Confirm **PvP Tooltip** appears in your AddOns list, then hover any player.

## Configuration

PvP Tooltip works out of the box — configuration is optional.

### Settings panel

Open it any of these ways:

- Type `/pvpt` (or `/pvptooltip`)
- `Esc → Options → AddOns → PvPTooltip`

The panel includes a **live tooltip preview** that updates as you change options:

- **Show info when** — Always, or only while holding **Shift / Ctrl / Alt** (great for keeping tooltips clean)
- **Tooltip layout** — Panel, Compact, Sections or Classic
- **Sections** — toggle Current Rating, Character Experience, Games Played (columns in Compact / Panel)
- **Brackets** — show/hide 2v2, 3v3, Solo Shuffle, RBG, Blitz individually
- **Display** — show all specs vs only the hovered spec; hide brackets with no games
- **Integrations** — show PvP info in Total RP 3 profile tooltips (only listed when TRP3 is installed)

### Slash commands

| Command | Action |
|---------|--------|
| `/pvpt` · `/pvpt config` | Open the settings panel |
| `/pvpt enable` · `/pvpt disable` | Toggle the addon |
| `/pvpt status` | Show current state |
| `/pvpt debug` | Toggle debug logging |

Unknown or missing arguments print this command list to chat.

## Supported Contexts

Tooltips are enhanced wherever a unit tooltip shows: open-world players, party and raid members, Group Finder listings and applicants, guild and friends lists, battlegrounds and arenas.

With [Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3) installed, the PvP block is appended to the bottom of TRP3's profile tooltip when it replaces the default one. Turn this off under **Integrations** in the settings panel.

## Data Freshness

Player rating data ships as separate per-region add-ons — **PvPTooltip_DataEU** and **PvPTooltip_DataUS** — so only your region's database loads. Realm and region mapping data lives in `src/db/` and loads with the main addon. All are generated externally and refreshed frequently from current ranked data. For the most accurate ratings, **keep the addon updated** (enable auto-update in your addon manager, install all bundled add-ons).

| Database | Add-on | Contents |
|----------|--------|----------|
| `db_pvp_eu_characters.lua` | PvPTooltip_DataEU | EU player ratings |
| `db_pvp_us_characters.lua` | PvPTooltip_DataUS | US player ratings |
| `db_realms.lua` | PvPTooltip | Realm mappings |
| `db_regions.lua` | PvPTooltip | Region detection |

> These files are generated externally — do not hand-edit them.

## Usage Statistics

If you use the Wago App with analytics on, PvP Tooltip reports which tooltip layout you use (and any PvP Tooltip Lua errors) through Wago Analytics, so we know which layouts are worth improving. Nothing else is added, and the add-on itself never connects to the internet. You can opt out in the Wago App settings.

## Requirements

- **World of Warcraft**: Retail — Midnight (Interface `120105`)
- **Dependencies**: none (standalone)

## Project Structure

```
PvPTooltip/
├── PvPTooltip.toc          # Metadata + load order (TOC order = dependency order)
├── Media/                  # In-game textures (addon list icon)
├── src/
│   ├── Core/               # Lifecycle, config, events, errors, performance
│   ├── Data/               # Player lookup + realm/region resolution
│   ├── UI/                 # Tooltip rendering + settings panel
│   │   └── Layouts/        # Compact / Sections / Panel tooltip layouts
│   └── db/                 # GENERATED realm/region databases
├── data/
│   ├── PvPTooltip_DataEU/  # GENERATED per-region character add-on (EU)
│   └── PvPTooltip_DataUS/  # GENERATED per-region character add-on (US)
├── scripts/                # Lint + release automation
├── ReleaseNotes/           # Per-version notes
├── CHANGELOG.md
└── LICENSE
```

## Development

```bash
# Lint
./luacheck.exe src/ --config .luacheckrc

# Prepare + ship a release (bumps notes, tags, pushes → CI publishes)
./scripts/prepare-release.sh v1.0.1
```

Releases are fully automated via GitHub Actions — tagging `v*` packages the addon and publishes to CurseForge and Wago, then announces in Discord. See [RELEASE_PROCESS.md](RELEASE_PROCESS.md) for the full flow.

## Contributing

1. Fork and create a feature branch.
2. Run `./luacheck.exe src/ --config .luacheckrc` before committing.
3. Use [Conventional Commits](https://www.conventionalcommits.org/) (`type(scope): subject`).
4. Open a Pull Request.

Bug reports and feature requests are welcome via [GitHub Issues](https://github.com/Kirom/PvPTooltip/issues) or the Discord.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

## Support & Community

- **Discord** — [join the server](https://discord.gg/A5N6KEgbCc) for help, bug reports and feature ideas
- **GitHub Issues** — [report a bug or request a feature](https://github.com/Kirom/PvPTooltip/issues)

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

**Happy PvP hunting!** 🗡️⚔️

</div>
