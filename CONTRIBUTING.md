# Contributing to Blackbaud Job Connector

Thank you for your interest in contributing to the Blackbaud Job Connector for Power BI! This guide will help you get started with development and contributions.

## Development Environment Setup

### Prerequisites

1. **PowerShell**: Version 5.1+ (Windows) or PowerShell Core 7+ (Cross-platform)
2. **Power BI Desktop**: Latest version for testing
3. **Git**: For version control
4. **Code Editor**: VS Code with PowerQuery extension recommended

### Getting Started

1. **Fork the Repository**
   ```bash
   # Fork the repo on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/powerbi-query-connector.git
   cd powerbi-query-connector
   ```

2. **Set Up Development Environment**
   ```powershell
   # Verify PowerShell is available
   pwsh --version
   
   # Test the development tools
   .\build-scripts\dev-helper.ps1 help
   ```

3. **Create a Development Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### 1. Code Development

The main connector code is in `BlackbaudJobConnector.pq`. This file contains:
- OAuth 2.0 + PKCE authentication implementation
- Async job processing logic
- Data transformation functions
- Navigation table generation
- Error handling

### 2. Validation and Testing

Use the development helper script for all validation:

```powershell
# Validate PowerQuery syntax
.\build-scripts\dev-helper.ps1 validate

# Check code quality and best practices
.\build-scripts\dev-helper.ps1 quality

# Build MEZ package for testing
.\build-scripts\dev-helper.ps1 build

# Run all checks together
.\build-scripts\dev-helper.ps1 all
```

### 3. Testing in Power BI

1. Build the MEZ package: `.\build-scripts\dev-helper.ps1 build`
2. Copy `BlackbaudJobConnector.mez` to your Custom Connectors folder
3. Restart Power BI Desktop
4. Test the connector functionality

## Code Standards

### PowerQuery M Language

- **Syntax**: Use proper M language syntax and conventions
- **Formatting**: Consistent indentation and spacing
- **Comments**: Document complex logic and business rules
- **Error Handling**: Include comprehensive error handling with user-friendly messages
- **Performance**: Consider memory usage and execution time for large datasets

### Example Code Style

```powerquery
// Good: Clear function with error handling
ProcessJobResult = (jobId as text) as table =>
    let
        // Poll for job completion with exponential backoff
        pollResult = Function.InvokeAfter(
            () => GetJobStatus(jobId),
            #duration(0, 0, 0, 5)  // 5 second delay
        ),
        
        // Handle different job statuses
        result = if pollResult[Status] = "Completed" then
            GetJobData(jobId)
        else if pollResult[Status] = "Failed" then
            error Error.Record(
                "JobFailed", 
                "The background job failed to complete",
                [JobId = jobId, Details = pollResult[Error]]
            )
        else
            @ProcessJobResult(jobId)  // Continue polling
    in
        result;
```

### Security Guidelines

- **No Hardcoded Secrets**: Never include API keys, passwords, or tokens in source code
- **Input Validation**: Validate all user inputs and API responses
- **Error Messages**: Don't expose sensitive information in error messages
- **OAuth Flow**: Follow OAuth 2.0 + PKCE best practices
- **Token Handling**: Securely handle and store authentication tokens

## Quality Checks

The project includes automated quality checks:

### Code Quality Patterns

The quality checker looks for:
- ✅ **Good Practices**: Proper error handling, input validation, documentation
- ⚠️ **Warnings**: Missing error handling, TODO comments, potential issues
- ❌ **Issues**: Hardcoded secrets, security risks, syntax problems

### Build Validation

The build process validates:
- PowerQuery syntax correctness
- MEZ package structure
- Required files and metadata
- Icon file formats and sizes

## Pull Request Process

### Before Submitting

1. **Run Full Validation**
   ```powershell
   .\build-scripts\dev-helper.ps1 all
   ```

2. **Test Thoroughly**
   - Test in Power BI Desktop
   - Verify OAuth flow works
   - Test with real API data
   - Check error handling

3. **Update Documentation**
   - Update README.md if adding features
   - Add entries to CHANGELOG.md
   - Include code comments

### Pull Request Guidelines

1. **Title**: Clear, descriptive title summarizing the change
2. **Description**: Detailed description of what changed and why
3. **Testing**: Describe how you tested the changes
4. **Breaking Changes**: Clearly mark any breaking changes
5. **Issues**: Reference any related GitHub issues

### Example Pull Request Description

```markdown
## Summary
Add support for custom query parameters in job submission

## Changes
- Extended `SubmitJob` function to accept optional parameters
- Added validation for parameter values
- Updated error handling for invalid parameters
- Added unit tests for new functionality

## Testing
- Tested with various parameter combinations
- Verified backward compatibility with existing queries
- Tested error scenarios and edge cases

## Breaking Changes
None - this is a backward-compatible addition

## Related Issues
Fixes #123
```

## CI/CD Pipeline

The project uses GitHub Actions for automated testing and releases:

### Validation Workflow
- Runs on every push and pull request
- Validates PowerQuery syntax
- Runs code quality checks
- Builds MEZ package
- Must pass for pull requests to be merged

### Release Workflow
- Triggers on version tags (e.g., `v1.0.0`)
- Runs full validation suite
- Builds release MEZ package
- Creates GitHub release with assets
- Updates release notes

## Release Process

### For Maintainers

1. **Update Version Information**
   - Update version in connector metadata
   - Update CHANGELOG.md with new version details
   - Commit changes

2. **Create Release Tag**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **Automated Release**
   - GitHub Actions will build the release
   - MEZ package will be attached to the GitHub release
   - Release notes will be generated

## Getting Help

### Resources
- **PowerQuery M Documentation**: [Microsoft Docs](https://docs.microsoft.com/en-us/powerquery-m/)
- **Power BI Custom Connectors**: [Microsoft Learn](https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-connector-extensibility)
- **Blackbaud SKY API**: [Developer Portal](https://developer.blackbaud.com/skyapi/)

### Support Channels
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and community support
- **Code Review**: Pull request reviews for code feedback

### Common Issues

**Build Failures**
- Check PowerShell execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Verify PowerQuery syntax in your editor
- Run individual validation steps to isolate issues

**Testing Problems**
- Ensure Power BI Desktop is completely closed before copying new MEZ files
- Check Custom Connectors folder permissions
- Verify custom connector security settings in Power BI

**OAuth Issues**
- Check Blackbaud application configuration
- Verify redirect URI settings
- Test authentication flow manually

## Code of Conduct

### Our Standards

- **Be Respectful**: Treat all contributors with respect and courtesy
- **Be Collaborative**: Work together constructively on improvements
- **Be Professional**: Maintain professional communication in all interactions
- **Be Inclusive**: Welcome contributions from developers of all backgrounds and experience levels

### Reporting Issues

If you encounter unacceptable behavior, please report it by opening a GitHub issue or contacting the maintainers directly.

---

Thank you for contributing to the Blackbaud Job Connector! Your contributions help make this tool better for the entire community.