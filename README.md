# PvP Tooltip

**Enhanced PvP Information for World of Warcraft Players**

PvP Tooltip is a lightweight, performance-optimized World of Warcraft addon that enriches player tooltips with comprehensive ranked PvP information. Get instant access to current ratings, personal bests, and season statistics for any player you encounter in the world, party, raid, or Group Finder.

## ✨ Features

### 🎯 **Comprehensive PvP Data**
- **Current Season Ratings** for all competitive brackets (2v2, 3v3, Shuffle, RBG, Blitz)
- **Personal Best Ratings** showing historical peak performance  
- **Season Statistics** including games played and win rates
- **Multi-Region Support** for both EU and US with daily-updated databases

### 🎨 **Professional Display**
- **Color-coded ratings** for instant skill assessment
- **Clean, organized layout** with clear sections
- **Intuitive color scheme** that's easy to read at a glance
- **Zero configuration** required - install and play

### 🌍 **Universal Compatibility**
- Works in **all game contexts**: world, party, raid, Group Finder
- **Cross-realm and cross-faction** player lookup
- **Compatible** with popular UI addons and frameworks
- **Minimal performance impact** with optimized data structures

## 📊 What You'll See

When hovering over any player, the addon adds a "PvP Tooltip info" section displaying:

### Current Rating
View current season ratings across all competitive brackets:
- **2v2, 3v3, Shuffle, RBG, Blitz**
- Color-coded by skill level for instant assessment

### Character Experience  
See personal best ratings to understand historical performance:
- **All-time peak ratings** for each bracket
- **Experience indicators** across different PvP formats

### Current Season Statistics
Check activity and performance for the current season:
- **Games played** and **win rates** for each bracket
- **Performance trends** and activity levels

## 🎨 Color Coding System

### Rating Colors
- **0-1799**: White (Unrated/Low)
- **1800-2099**: Green (Rival/Combatant) 
- **2100-2399**: Blue (Challenger/Elite)
- **2400+**: Purple (Gladiator)

### Statistics Colors
- **Games Played**: Gold (#FFD035)
- **Win Rate ≤50%**: Red (#FF4500) 
- **Win Rate >50%**: Green (#57C94F)

## 🚀 Installation

### Automatic Installation (Recommended)
1. **CurseForge App**: Search for "PvP Tooltip" and install
2. **Wago App**: Search for "PvP Tooltip" and install

### Manual Installation
1. Download the latest release from [GitHub Releases](https://github.com/PvPTooltip/PvPTooltip/releases)
2. Extract the `PvPTooltip` folder to your WoW AddOns directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **Mac**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or reload your UI (`/reload`)

### Verification
- Check that "PvP Tooltip" appears in your AddOns list (`/addons`)
- Hover over any player to see the enhanced tooltip

## 📈 Data Freshness

**Important**: For the most accurate and up-to-date information:

- **Update regularly** (ideally daily) to get the latest player data
- **Database refresh**: Our databases in `src/db/` are updated frequently with current ratings and statistics
- **Automatic updates**: Enable automatic addon updates in your addon manager for the best experience

The addon includes databases for:
- `db_pvp_eu_characters.lua` - EU region player data
- `db_pvp_us_characters.lua` - US region player data  
- `db_realms.lua` - Realm mappings and information
- `db_regions.lua` - Region detection and routing

## 🎮 Supported Contexts

PvP Tooltip enhances tooltips in all major game situations:

- **World Exploration**: Hovering over players in the open world
- **Group Content**: Party and raid member information
- **Group Finder**: Both when searching for groups and reviewing applicants
- **Social Features**: Guild members, friends, and other social interactions
- **PvP Environments**: Battlegrounds, arenas, and world PvP

## ⚡ Performance

- **Lightweight**: Minimal memory footprint and CPU usage
- **Optimized**: Fast lookup algorithms for instant tooltip enhancement  
- **Efficient**: Smart caching prevents repeated database queries
- **Non-intrusive**: Doesn't interfere with game performance or other addons

## 🛠️ Development

### Architecture
- **Clean Architecture**: Modular design with clear separation of concerns
- **Error Handling**: Comprehensive error handling and graceful degradation
- **Testing**: Full test suite for reliability and stability
- **Documentation**: Well-documented codebase for maintainability

### Contributing
- **Issues**: Bug reports and feature requests welcome via [GitHub Issues](https://github.com/PvPTooltip/PvPTooltip/issues)
- **Code Style**: Follow clean code principles and existing patterns
- **Testing**: Run `scripts/run_luacheck.sh` for syntax validation
- **Pull Requests**: Contributions are welcome and appreciated

### Building & Releases
```bash
# Lint code
./scripts/run_luacheck.sh

# Prepare a new release
./scripts/prepare-release.sh v1.0.1

# The release process is automated via GitHub Actions
# See RELEASE_PROCESS.md for detailed information
```

For detailed information about the release process, see [RELEASE_PROCESS.md](RELEASE_PROCESS.md).

## 📋 Requirements

- **World of Warcraft**: Retail (11.2.0+)
- **Dependencies**: None (standalone addon)
- **Memory**: ~2-5MB depending on database size
- **Performance**: Negligible impact on game performance

## 🤝 Community & Support

- **GitHub**: [PvPTooltip Repository](https://github.com/PvPTooltip/PvPTooltip)
- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Community discussions and support via GitHub Discussions

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

**Transform your PvP experience with instant access to comprehensive player information. Install PvP Tooltip today and never wonder about another player's skill level again!**
