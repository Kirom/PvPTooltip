#!/bin/bash

# Script to update CHANGELOG.md from ReleaseNotes
# Usage: ./scripts/update-changelog.sh <version>

set -e

VERSION="$1"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.0.0"
    exit 1
fi

RELEASE_NOTES_FILE="ReleaseNotes/${VERSION}.md"
CHANGELOG_FILE="CHANGELOG.md"
TEMP_FILE=$(mktemp)

echo "Updating CHANGELOG.md with release notes for ${VERSION}..."

# Check if release notes exist
if [ ! -f "${RELEASE_NOTES_FILE}" ]; then
    echo "Error: Release notes not found at ${RELEASE_NOTES_FILE}"
    exit 1
fi

# Check if CHANGELOG.md exists
if [ ! -f "${CHANGELOG_FILE}" ]; then
    echo "Error: CHANGELOG.md not found"
    exit 1
fi

# Create new changelog structure
cat > "${TEMP_FILE}" << 'EOF'
# Changelog

All notable changes to PvP Tooltip will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

EOF

# Add the new release notes (skip the first "# Changelog" line if present)
if grep -q "^# Changelog" "${RELEASE_NOTES_FILE}"; then
    tail -n +2 "${RELEASE_NOTES_FILE}" >> "${TEMP_FILE}"
else
    cat "${RELEASE_NOTES_FILE}" >> "${TEMP_FILE}"
fi

# Add any existing releases from the current changelog (skip header)
if grep -q "^## \[" "${CHANGELOG_FILE}"; then
    echo "" >> "${TEMP_FILE}"
    sed -n '/^## \[/,$p' "${CHANGELOG_FILE}" | grep -v "^## \[${VERSION#v}\]" >> "${TEMP_FILE}" || true
fi

# Replace the original changelog
mv "${TEMP_FILE}" "${CHANGELOG_FILE}"

echo "✅ CHANGELOG.md updated successfully with ${VERSION}"
echo "📝 Please review the changes before committing"