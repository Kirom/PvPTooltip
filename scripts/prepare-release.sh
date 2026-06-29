#!/bin/bash

# Script to prepare a new release
# Usage: ./scripts/prepare-release.sh <version>

set -e

VERSION=""
ASSUME_YES=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)   ASSUME_YES=true; shift ;;
        --dry-run)  DRY_RUN=true; shift ;;
        -h|--help)
            echo "Usage: $0 <version> [-y|--yes] [--dry-run]"
            echo "Example: $0 v1.0.1"
            exit 0 ;;
        -*) echo "Error: Unknown option: $1"; exit 1 ;;
        *)
            if [ -z "$VERSION" ]; then VERSION="$1"; shift
            else echo "Error: Unexpected argument: $1"; exit 1; fi ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [-y|--yes] [--dry-run]"
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

# Fail fast if the tag already exists (locally) before mutating any files.
if git tag -l "$VERSION" | grep -q "^${VERSION}$"; then
    echo "Error: Tag $VERSION already exists!"
    exit 1
fi

confirm() {
    # confirm "message" -> returns 0 on yes
    if [ "$ASSUME_YES" = true ]; then return 0; fi
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

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

---

**Support:** [Discord](https://discord.gg/A5N6KEgbCc) · [GitHub Issues](https://github.com/PvPTooltip/PvPTooltip/issues)

Happy PvP hunting! 🗡️⚔️
EOF
    
    echo "📝 Please edit $RELEASE_NOTES_FILE with the release notes, then run this script again."
    exit 0
fi

# Validate release notes have content
if grep -q "^### Added$" "$RELEASE_NOTES_FILE" && ! grep -A1 "^### Added$" "$RELEASE_NOTES_FILE" | grep -q "^- .*[^[:space:]]"; then
    echo "⚠️  Release notes appear to be empty. Please add content to $RELEASE_NOTES_FILE"
    exit 1
fi

# TOC version is the literal @project-version@ token — the packager substitutes
# the real version from the tag at build time, so nothing to bump here.

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

# Dry run stops here — files changed, nothing committed/tagged/pushed.
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "🧪 Dry run: file changes made but nothing committed/tagged/pushed."
    echo "   Review, then re-run without --dry-run."
    exit 0
fi

echo ""
confirm "🤔 Commit, tag and push release ${VERSION}?" || {
    echo "🔙 Release cancelled. File changes left in working tree for review."
    exit 1
}

echo "💾 Committing..."
git add CHANGELOG.md "$RELEASE_NOTES_FILE"
git commit -m "Prepare release ${VERSION}"

echo "🏷️  Tagging ${VERSION}..."
git tag "$VERSION" -m "Release ${VERSION_CLEAN}"

echo "⬆️  Pushing..."
git push origin "$CURRENT_BRANCH"
git push origin "$VERSION"

echo ""
echo "✅ Release ${VERSION} pushed! GitHub Actions will build & publish (GitHub release, CurseForge, Wago, Discord)."