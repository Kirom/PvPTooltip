# You are the senior WoW addon developer. Create World Of Warcraft (11.2.0) addon.

## Addon description

Addon is called PvPTooltip. It should display related PvP information about all players. Players data is located in ./src/db in files `./src/db/db_pvp_eu_characters.lua` (for EU region) and `./src/db/db_pvp_us_characters.lua` (for US region). Realms and regions mappings are stored in `./src/db/db_realms.lua` and `./src/db/db_regions.lua` 

- Addon should load all entries from DB (.lua files) to display tooltips for players
- Addon should display tooltip when hovering any character in world / party / raid/ LFG leader (when player seek for group) / LFG appliers (when player is a leader)
- Follow clean architecture and clean code principles
- Source code should be in ./src directory

## Tooltip display:

PvP Tooltip info: (red colored title of section)

- Current Rating (color: #FFD035)
    - 2v2 (color: white)                           {currentRating}
    - 3v3 (color: white)                           {currentRating}
    - shuffle (color: white)                       {currentRating}
    - RBG (color: white)                           {currentRating}
    - Blitz (color: white)                         {currentRating}

- Character Experience (color: #FFD035)
    - 2v2 (color: white)                           {personalBest}
    - 3v3 (color: white)                           {personalBest}
    - shuffle (color: white)                       {personalBest}
    - RBG (color: white)                           {personalBest}
    - Blitz (color: white)                         {personalBest}

- Current Season (games played and winrate, color: #FFD035)
    - 2v2 (color: white)                           {playedTotal} ({winRate}% won)
    - 3v3 (color: white)                           {playedTotal} ({winRate}% won)
    - shuffle (color: white)                       {playedTotal} ({winRate}% won)
    - RBG (color: white)                           {playedTotal} ({winRate}% won)
    - Blitz (color: white)                         {playedTotal} ({winRate}% won)

### ratings should be colored like that: 
- 0-1799 rating: white
- 1800-2099: #2EAD65  
- 2100-2399: #046DCC
- 2400+: #A140E9

### {playedTotal} color:  #FFD035

### {winRate} color

- <= 50: #FF4500
- > 50: #57C94F

## Other tasks:

- Create best README.md as for PvP WoW addon so users can easily understand how to use it and other usefull things. Mention that addon should be updated every day so users get fresh data.
- Create best DESCRIPTION.md that I will use as main page for Addon description in the platforms like Curseforge and Wago.
- Create blank CHANGELOG.md that will contain changelog of the latest version. It should be updated automatically in github actions (via .github/workflows/release.yml) on new version release. Action should take latest version's changelog from ReleaseNotes dir and replace CHANGELOG.md content with it.
- Update github action that will publish new versions to the distribution platforms with current addon (.github/workflows/release.yml)
- Ensure that all databases (./src/db/db_pvp_eu_characters.lua, ./src/db/db_pvp_us_characters.lua, ./src/db/db_realms.lua, ./src/db/db_regions.lua) are loaded into addon and used properly.

After everything is done, ensure everything is working as expected and all requirements are met.