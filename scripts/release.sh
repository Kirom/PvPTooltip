#!/bin/bash

# Release helper script for PvP Profile
# This script helps create version tags and trigger GitHub Actions releases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 PvP Profile Release Helper${NC}"
echo "======================================="

# Function to validate version format
validate_version() {
    if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}❌ Invalid version format. Use semantic versioning (e.g., 1.0.1)${NC}"
        exit 1
    fi
}

# Function to convert interface number to version string
# e.g., 110200 -> 11.2.0, 50500 -> 5.5.0
convert_interface_to_version() {
    local interface_num=$1
    if [[ ${#interface_num} -eq 6 ]]; then
        # Modern format: 110200 -> 11.2.0
        # First two digits, then next two digits as a number, then last two digits as a number
        local major="${interface_num:0:2}"
        local minor="${interface_num:2:2}"
        local patch="${interface_num:4:2}"
        # Remove leading zeros
        minor=$((10#$minor))
        patch=$((10#$patch))
        echo "${major}.${minor}.${patch}"
    elif [[ ${#interface_num} -eq 5 ]]; then
        # Classic format: 50500 -> 5.5.0
        # First digit, then next two digits as a number, then last two digits as a number
        local major="${interface_num:0:1}"
        local minor="${interface_num:1:2}"
        local patch="${interface_num:3:2}"
        # Remove leading zeros
        minor=$((10#$minor))
        patch=$((10#$patch))
        echo "${major}.${minor}.${patch}"
    else
        echo "unknown"
    fi
}

# Function to extract interface version from TOC file
extract_interface_version() {
    local toc_file=$1
    if [ -f "$toc_file" ]; then
        local interface_line=$(grep "^## Interface:" "$toc_file" | head -1)
        if [[ $interface_line =~ Interface:[[:space:]]*([0-9]+) ]]; then
            echo "${BASH_REMATCH[1]}"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# Function to update interface versions in README.md
update_interface_versions_in_readme() {
    local retail_version=$1
    local classic_version=$2
    local readme_file="README.md"
    
    if [ ! -f "$readme_file" ]; then
        echo -e "${RED}❌ README.md not found!${NC}"
        return 1
    fi

    # Update the interface version badge using awk for better reliability
    local new_badge="[![Interface Version](https://img.shields.io/badge/Game%20Version-${retail_version}%20|%20${classic_version}-brightgreen)](https://github.com/Kirom/PvP-Profile)"
    
    # Use awk to replace the line containing "Interface Version"
    awk -v new_badge="$new_badge" '
        /\[!\[Interface Version\]/ {
            print new_badge
            next
        }
        { print }
    ' "$readme_file" > "${readme_file}.tmp" && mv "${readme_file}.tmp" "$readme_file"
    
    echo -e "${GREEN}✅ Updated interface versions in README.md: ${retail_version} | ${classic_version}${NC}"
}

# Check interface versions
echo -e "${BLUE}🔍 Checking interface versions...${NC}"

# Extract interface versions from TOC files
RETAIL_INTERFACE=$(extract_interface_version "PvPProfile.toc")
CLASSIC_INTERFACE=$(extract_interface_version "PvPProfile_Classic.toc")

if [ -z "$RETAIL_INTERFACE" ]; then
    echo -e "${RED}❌ Could not extract interface version from PvPProfile.toc${NC}"
    exit 1
fi

if [ -z "$CLASSIC_INTERFACE" ]; then
    echo -e "${RED}❌ Could not extract interface version from PvPProfile_Classic.toc${NC}"
    exit 1
fi

# Convert to version strings
RETAIL_VERSION=$(convert_interface_to_version "$RETAIL_INTERFACE")
CLASSIC_VERSION=$(convert_interface_to_version "$CLASSIC_INTERFACE")

echo -e "${BLUE}📋 Current interface versions:${NC}"
echo -e "   Retail: ${GREEN}$RETAIL_VERSION${NC} (Interface: $RETAIL_INTERFACE)"
echo -e "   Classic: ${GREEN}$CLASSIC_VERSION${NC} (Interface: $CLASSIC_INTERFACE)"

# Check current versions in README.md
if [ -f "README.md" ]; then
    # Extract current versions using a more robust approach
    CURRENT_README_LINE=$(grep "Game%20Version-" README.md | head -1)
    if [[ $CURRENT_README_LINE =~ Game%20Version-([0-9]+\.[0-9]+\.[0-9]+)%20\|%20([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        CURRENT_RETAIL_VERSION="${BASH_REMATCH[1]}"
        CURRENT_CLASSIC_VERSION="${BASH_REMATCH[2]}"
        
        echo -e "${BLUE}📋 README.md interface versions:${NC}"
        echo -e "   Retail: ${GREEN}$CURRENT_RETAIL_VERSION${NC}"
        echo -e "   Classic: ${GREEN}$CURRENT_CLASSIC_VERSION${NC}"
        
        # Check if versions need updating
        if [ "$RETAIL_VERSION" != "$CURRENT_RETAIL_VERSION" ] || [ "$CLASSIC_VERSION" != "$CURRENT_CLASSIC_VERSION" ]; then
            echo -e "${YELLOW}⚠️  Interface versions have changed!${NC}"
            echo -e "   Retail: $CURRENT_RETAIL_VERSION → $RETAIL_VERSION"
            echo -e "   Classic: $CURRENT_CLASSIC_VERSION → $CLASSIC_VERSION"
            
            # Update README.md
            update_interface_versions_in_readme "$RETAIL_VERSION" "$CLASSIC_VERSION"
            
            # Show changes
            echo -e "${BLUE}📋 Interface version changes:${NC}"
            git diff README.md || true
        else
            echo -e "${GREEN}✅ Interface versions are up to date${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not parse current interface versions from README.md${NC}"
        echo -e "${BLUE}📝 Updating README.md with current interface versions...${NC}"
        update_interface_versions_in_readme "$RETAIL_VERSION" "$CLASSIC_VERSION"
    fi
else
    echo -e "${RED}❌ README.md not found!${NC}"
    exit 1
fi

# Get current version from package.json
if [ -f "package.json" ]; then
    CURRENT_VERSION=$(grep '"version":' package.json | cut -d'"' -f4)
    echo -e "${BLUE}📋 Current version from package.json: ${GREEN}$CURRENT_VERSION${NC}"
else
    echo -e "${RED}❌ package.json not found!${NC}"
    exit 1
fi

# Check if we have uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes. Please commit them first.${NC}"
    git status --porcelain
    exit 1
fi

# Check if we're on the main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo -e "${YELLOW}⚠️  You're on branch '$CURRENT_BRANCH'. Consider switching to main/master for releases.${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get new version
if [ -z "$1" ]; then
    echo -e "${BLUE}🔢 Enter new version (current: $CURRENT_VERSION):${NC}"
    read -r NEW_VERSION
else
    NEW_VERSION=$1
fi

# Validate version format
validate_version "$NEW_VERSION"

# Check if tag already exists
if git tag -l "v$NEW_VERSION" | grep -q "v$NEW_VERSION"; then
    echo -e "${RED}❌ Tag v$NEW_VERSION already exists!${NC}"
    exit 1
fi

echo -e "${BLUE}📝 Updating version from $CURRENT_VERSION to $NEW_VERSION...${NC}"

# Update package.json only
sed -i "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" package.json

# Show changes
echo -e "${BLUE}📋 Changes made:${NC}"
git diff package.json
if git diff README.md > /dev/null 2>&1; then
    echo -e "${BLUE}📋 Interface version changes:${NC}"
    git diff README.md
fi

# Confirm changes
echo -e "\n${YELLOW}🤔 Do you want to commit these changes and create release v$NEW_VERSION?${NC}"
read -p "Continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🔙 Reverting changes...${NC}"
    git checkout -- package.json
    if [ -f "README.md.backup" ]; then
        mv README.md.backup README.md
    fi
    echo -e "${BLUE}✅ Changes reverted. Release cancelled.${NC}"
    exit 1
fi

# Commit version bump and interface updates
echo -e "${BLUE}💾 Committing version bump and interface updates...${NC}"
git add package.json
if git diff --cached README.md > /dev/null 2>&1; then
    git add README.md
fi
git commit -m "Bump version to $NEW_VERSION and update interface versions to $RETAIL_VERSION/$CLASSIC_VERSION"

# Create and push tag
echo -e "${BLUE}🏷️  Creating tag v$NEW_VERSION...${NC}"
git tag "v$NEW_VERSION" -m "Release version $NEW_VERSION (Interface: $RETAIL_VERSION/$CLASSIC_VERSION)"

echo -e "${BLUE}⬆️  Pushing to origin...${NC}"
git push origin "$CURRENT_BRANCH"
git push origin "v$NEW_VERSION"

echo -e "${GREEN}✅ Release v$NEW_VERSION created successfully!${NC}"
echo "======================================="
echo -e "${BLUE}🔗 GitHub Actions will now:${NC}"
echo "   • Create GitHub release"
echo "   • Upload addon package"
echo "   • Publish to CurseForge (if configured)"
echo "   • Publish to Wago (if configured)"
echo "   • Generate WowUp metadata"
echo ""
echo -e "${BLUE}🌐 Monitor progress at:${NC}"
echo "   https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
echo ""
echo -e "${GREEN}🎉 Release process initiated!${NC}"

# Clean up backup file
if [ -f "README.md.backup" ]; then
    rm README.md.backup
fi

# Optional: Open GitHub Actions in browser (uncomment if desired)
# if command -v xdg-open > /dev/null; then
#     xdg-open "https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
# elif command -v open > /dev/null; then
#     open "https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
# fi 