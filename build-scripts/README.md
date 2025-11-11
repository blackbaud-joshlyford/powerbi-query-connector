# Build Scripts for PowerBI Connector Development

This directory contains PowerShell scripts for local development and testing of the Blackbaud PowerBI connector.

## Scripts Overview

### 🚀 dev-helper.ps1
Main entry point for all development tasks. Provides a unified interface for building, validating, and testing the connector.

```powershell
# Show help and available commands
.\dev-helper.ps1 help

# Build the connector with version 1.0.0
.\dev-helper.ps1 build -Version 1.0.0

# Validate connector code with detailed analysis
.\dev-helper.ps1 validate -Detailed

# Run code quality check with suggestions
.\dev-helper.ps1 quality -ShowSuggestions

# Run complete test suite (validation + quality check)
.\dev-helper.ps1 test

# Clean build outputs
.\dev-helper.ps1 clean
```

### 🏗️ Build-Connector.ps1
Creates a MEZ package from the PowerQuery source file. Handles:
- Version management
- MEZ package structure creation
- Content_Types.xml generation
- Metadata creation
- Icon handling
- ZIP packaging

```powershell
# Build with default version (dev)
.\Build-Connector.ps1

# Build with specific version and clean intermediate files
.\Build-Connector.ps1 -Version "1.2.0" -Clean
```

### 🔍 Validate-Connector.ps1
Validates PowerQuery code for syntax errors and best practices:
- Balanced brackets/parentheses checking
- Required PowerQuery elements verification
- Code quality assessment
- OAuth implementation validation
- Performance considerations

```powershell
# Basic validation
.\Validate-Connector.ps1

# Detailed validation with analysis
.\Validate-Connector.ps1 -Detailed
```

### � Code-Quality-Check.ps1
Analyzes code for quality issues and best practices:
- Pattern matching for potential credential exposure
- Code quality assessments
- PowerBI-specific best practice recommendations
- OAuth implementation validation
- Development workflow suggestions

```powershell
# Basic code quality check
.\Code-Quality-Check.ps1

# Code quality check with improvement suggestions
.\Code-Quality-Check.ps1 -ShowSuggestions

# Generate code quality report
.\Code-Quality-Check.ps1 -OutputReport "quality-report.json"
```

## Development Workflow

### Quick Start
```powershell
# Run the complete development workflow
.\dev-helper.ps1 test    # Validate and scan
.\dev-helper.ps1 build   # Build if tests pass
```

### Pre-commit Checks
```powershell
# Recommended checks before committing
.\dev-helper.ps1 validate -Detailed
.\dev-helper.ps1 quality -ShowSuggestions
```

### Release Preparation
```powershell
# Clean build for release
.\dev-helper.ps1 clean
.\dev-helper.ps1 test
.\dev-helper.ps1 build -Version "1.0.0" -Clean
```

## Output Locations

- **MEZ packages**: `build-output/BlackbaudJobConnector.mez`
- **Build artifacts**: `build-output/mez-contents/`
- **Security reports**: Specified output file or console

## Installation Instructions

After building a MEZ package:

1. Copy the `.mez` file to: `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\`
2. Restart PowerBI Desktop
3. Enable custom connectors in PowerBI security settings
4. The connector will appear in the "Get Data" dialog

## Requirements

- PowerShell 5.1 or later
- Write access to project directory
- For local testing: PowerBI Desktop with custom connectors enabled

## Troubleshooting

### Common Issues

**Build fails with "File not found"**
- Ensure you're running from the project root or build-scripts directory
- Verify `BlackbaudJobConnector.pq` exists

**Security scan reports false positives**
- Review the specific patterns flagged
- Use `-FixSuggestions` to see recommendations
- Consider adding exceptions for legitimate use cases

**MEZ package won't install**
- Verify the package structure with a ZIP tool
- Check PowerBI custom connector settings
- Ensure PowerBI Desktop restart after copying

### Script Debugging

Enable verbose output:
```powershell
$VerbosePreference = "Continue"
.\dev-helper.ps1 validate
```

Check for PowerShell execution policy issues:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Contributing

When adding new scripts:
1. Follow the existing PowerShell style and error handling patterns
2. Add help documentation with examples
3. Include appropriate exit codes (0 = success, 1 = warnings, 2 = errors)
4. Update this README with new functionality

## Integration with CI/CD

These scripts complement the GitHub Actions workflows:
- Local development uses these scripts
- CI/CD uses similar logic but optimized for automation
- Same validation and security patterns ensure consistency