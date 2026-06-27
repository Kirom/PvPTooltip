#!/bin/bash

# Script to prepare a new release
# Usage: ./scripts/prepare-release.sh <version>

set -e

VERSION="$1"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.0.1"
    exit 1
fi

# Ensure version starts with 'v'
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    echo "Error: Version must be in format vX.Y.Z (e.g., v1.0.1)"
    exit 1
fi

VERSION_CLEAN="${VERSION#v}"
RELEASE_NOTES_FILE="ReleaseNotes/${VERSION}.md"
TOC_FILE="PvPTooltip.toc"

echo "🚀 Preparing release ${VERSION}..."

# Check if we're on the main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo "⚠️  Warning: You are not on the main/master branch (current: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if working directory is clean
if ! git diff-index --quiet HEAD --; then
    echo "Error: Working directory is not clean. Please commit or stash your changes."
    exit 1
fi

# Check if release notes exist
if [ ! -f "$RELEASE_NOTES_FILE" ]; then
    echo "📝 Creating release notes template at $RELEASE_NOTES_FILE"
    mkdir -p "$(dirname "$RELEASE_NOTES_FILE")"
    
    cat > "$RELEASE_NOTES_FILE" << EOF
# Changelog

## [${VERSION_CLEAN}] - $(date +%Y-%m-%d)

### Added
- 

### Changed
- 

### Deprecated
- 

### Removed
- 

### Fixed
- 

### Security
- 
EOF
    
    echo "📝 Please edit $RELEASE_NOTES_FILE with the release notes, then run this script again."
    exit 0
fi

# Validate release notes have content
if grep -q "^### Added$" "$RELEASE_NOTES_FILE" && ! grep -A1 "^### Added$" "$RELEASE_NOTES_FILE" | grep -q "^- .*[^[:space:]]"; then
    echo "⚠️  Release notes appear to be empty. Please add content to $RELEASE_NOTES_FILE"
    exit 1
fi

# Update TOC version
echo "📦 Updating TOC version to ${VERSION_CLEAN}..."
if [ -f "$TOC_FILE" ]; then
    sed -i "s/^## Version: .*/## Version: ${VERSION_CLEAN}/" "$TOC_FILE"
    echo "✅ TOC version updated"
else
    echo "Error: TOC file not found at $TOC_FILE"
    exit 1
fi

# Update CHANGELOG.md
echo "📄 Updating CHANGELOG.md..."
./scripts/update-changelog.sh "$VERSION"

# Run tests
echo "🧪 Running tests..."
if command -v luacheck &> /dev/null; then
    luacheck src/ || {
        echo "❌ Lua syntax check failed"
        exit 1
    }
    echo "✅ Lua syntax check passed"
else
    echo "⚠️  luacheck not found, skipping Lua syntax check"
fi

# Show changes
echo ""
echo "📋 Changes to be committed:"
git diff --name-only HEAD

echo ""
echo "🎯 Release ${VERSION} is ready!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit the changes: git add . && git commit -m 'Prepare release ${VERSION}'"
echo "3. Create and push the tag: git tag ${VERSION} && git push origin ${VERSION}"
echo "4. The GitHub Actions workflow will automatically create the release"
echo ""
echo "Or run: git add . && git commit -m 'Prepare release ${VERSION}' && git tag ${VERSION} && git push origin main ${VERSION}"