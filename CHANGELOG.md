# Changelog

All notable changes to the Blackbaud Job Connector for Power BI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup with comprehensive build system
- GitHub Actions CI/CD pipeline for automated validation and releases
- Local development toolchain with PowerShell build scripts
- Comprehensive project documentation

### Changed
- Migrated project to GitHub repository structure
- Enhanced code quality checking and validation processes

## [1.0.0] - TBD

### Added
- OAuth 2.0 + PKCE authentication with Blackbaud SKY API
- Asynchronous job processing with automatic polling
- CSV data parsing and transformation for Power BI tables
- Navigation table for browsing available endpoints
- Comprehensive error handling and user feedback
- Custom connector icons for Power BI Desktop integration
- MEZ package structure with proper metadata
- Cross-platform PowerShell build tools
- Automated validation and code quality checks
- GitHub Actions workflows for CI/CD
- Professional project documentation

### Security
- Implemented PKCE (Proof Key for Code Exchange) for OAuth 2.0
- No hardcoded credentials or sensitive data in source code
- Secure token handling and storage
- Input validation and sanitization for API requests

### Technical Details
- 729 lines of PowerQuery M language code
- Custom SHA256 implementation for PKCE code challenge
- Exponential backoff strategy for job polling
- Robust CSV parsing with error recovery
- MEZ package with proper OPC structure
- Cross-platform development support

---

## Version History Format

### Types of Changes
- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes

### Version Numbers
This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions
- **PATCH** version for backwards-compatible bug fixes

### Release Process
1. Update version number in connector metadata
2. Update this CHANGELOG.md with new version details
3. Create git tag with version number (e.g., `v1.0.0`)
4. Push tag to trigger automated release workflow
5. GitHub Actions will build and publish the release automatically

### Unreleased Changes
All changes since the last release are tracked in the [Unreleased] section above.
When creating a new release, these changes are moved to a new version section.