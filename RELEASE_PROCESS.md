# Release Process

This document describes the automated release process for PvPTooltip addon.

## Overview

The release process is fully automated using GitHub Actions and follows these principles:

- **Automated Distribution**: Releases are automatically published to CurseForge, Wago, and GitHub
- **Version Management**: Version numbers are automatically updated in all relevant files
- **Changelog Generation**: CHANGELOG.md is automatically updated from ReleaseNotes
- **Quality Assurance**: All releases are validated before publication

## Release Workflow

### 1. Prepare Release

Use the provided script to prepare a new release:

```bash
./scripts/prepare-release.sh v1.0.1
```

This script will:
- Create a release notes template (if it doesn't exist)
- Update the TOC version
- Update CHANGELOG.md
- Run basic validation tests
- Show you what changes will be committed

### 2. Manual Steps

1. **Edit Release Notes**: Fill in the release notes template at `ReleaseNotes/vX.Y.Z.md`
2. **Review Changes**: Check the updated files with `git diff`
3. **Commit Changes**: `git add . && git commit -m "Prepare release vX.Y.Z"`
4. **Create Tag**: `git tag vX.Y.Z`
5. **Push**: `git push origin main vX.Y.Z`

### 3. Automated Release

Once you push the tag, GitHub Actions will automatically:

1. **Validate** the release (run tests, check files)
2. **Update** CHANGELOG.md with the new release notes
3. **Package** the addon according to `.pkgmeta` configuration
4. **Publish** to CurseForge and Wago (if API keys are configured)
5. **Create** a GitHub release with release notes

## File Structure

### Release Notes

Release notes are stored in `ReleaseNotes/vX.Y.Z.md` and follow this format:

```markdown
# Changelog

## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```

### Configuration Files

- **`.pkgmeta`**: Controls how the addon is packaged for distribution
- **`PvPTooltip.toc`**: WoW addon metadata file (version is auto-updated)
- **`CHANGELOG.md`**: Auto-generated from ReleaseNotes directory

## GitHub Actions Workflows

### Release Workflow (`.github/workflows/release.yml`)

Triggered by:
- Pushing a tag matching `v*` pattern
- Manual workflow dispatch

Steps:
1. **Validate**: Run pre-release validation
2. **Update**: Update CHANGELOG.md and TOC version
3. **Package**: Use BigWigsMods/packager to create and distribute the release

### Validation Workflow (`.github/workflows/validate-release.yml`)

Triggered by:
- Pull requests affecting release files
- Manual workflow dispatch

Validates:
- Release notes exist and have content
- TOC version consistency
- CHANGELOG.md format
- Lua syntax
- Package structure

### Test Workflow (`.github/workflows/test.yml`)

Runs on every push/PR to validate:
- Lua syntax with luacheck
- File structure
- TOC file format
- Package creation

## Distribution Platforms

The release workflow supports automatic distribution to:

### CurseForge
- Requires `CURSEFORGE_TOKEN` secret
- Configured via `CF_API_KEY` environment variable

### Wago
- Requires `WAGO_API_TOKEN` secret
- Configured via `WAGO_API_TOKEN` environment variable

### GitHub Releases
- Automatic using `GITHUB_TOKEN`
- Includes release notes and packaged files

## Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions
- **PATCH** version for backwards-compatible bug fixes

Format: `vMAJOR.MINOR.PATCH` (e.g., `v1.2.3`)

## Secrets Configuration

To enable automatic distribution, configure these repository secrets:

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `CURSEFORGE_TOKEN`: Your CurseForge API token
   - `WAGO_API_TOKEN`: Your Wago API token

## Troubleshooting

### Release Failed

1. Check the GitHub Actions logs for specific error messages
2. Ensure all required files exist and are properly formatted
3. Verify that release notes exist for the version being released
4. Check that the TOC version matches the release version

### Distribution Failed

1. Verify that API tokens are correctly configured in repository secrets
2. Check that the addon project exists on the target platform
3. Ensure the packaged files meet platform requirements

### Validation Failed

1. Run `luacheck src/` locally to check for Lua syntax errors
2. Verify that all required files exist (TOC, README, CHANGELOG, etc.)
3. Check that release notes follow the expected format

## Manual Release

If you need to create a release manually:

1. Use the workflow dispatch option in GitHub Actions
2. Specify the version tag to release
3. The workflow will run the same automated process

## Best Practices

1. **Test Before Release**: Always test the addon in-game before creating a release
2. **Meaningful Release Notes**: Provide clear, detailed release notes for users
3. **Version Consistency**: Ensure version numbers are consistent across all files
4. **Regular Releases**: Release frequently with smaller changes rather than large updates
5. **Backup**: Keep backups of important releases in case rollback is needed

## Support

For issues with the release process:

1. Check GitHub Actions logs for detailed error information
2. Verify configuration files are correct
3. Ensure all prerequisites are met
4. Contact the maintainer if problems persist