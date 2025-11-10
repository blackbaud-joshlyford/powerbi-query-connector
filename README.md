# Blackbaud Job Connector for Power BI

A custom Power BI connector that provides access to Blackbaud SKY API data through asynchronous job execution. This connector implements OAuth 2.0 with PKCE for secure authentication and supports async query processing for large datasets.

## Features

- **OAuth 2.0 + PKCE Authentication**: Secure authentication flow with Blackbaud SKY API
- **Asynchronous Job Processing**: Submit queries and poll for results asynchronously
- **CSV Data Processing**: Automatic parsing of job results into Power BI tables
- **Navigation Tables**: Easy browsing of available endpoints and operations
- **Error Handling**: Comprehensive error reporting and recovery
- **Custom Icons**: Professional UI integration with Power BI Desktop

## Installation

### Download Pre-built Package

1. Go to the [Releases](../../releases) page
2. Download the latest `BlackbaudJobConnector.mez` file
3. Copy the `.mez` file to your Power BI custom connectors directory:
   - **Windows**: `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\`
   - **macOS**: `~/Documents/Power BI Desktop/Custom Connectors/`
4. Enable custom connectors in Power BI Desktop:
   - Go to **File** → **Options and settings** → **Options**
   - Navigate to **Security**
   - Under **Data Extensions**, select **(Not Recommended) Allow any extension to load without validation or warning**
5. Restart Power BI Desktop

### Build from Source

If you prefer to build the connector yourself:

```powershell
# Clone the repository
git clone https://github.com/blackbaud-joshlyford/powerbi-query-connector.git
cd powerbi-query-connector

# Build the MEZ package
.\build-scripts\dev-helper.ps1 build

# The MEZ file will be created in the project root
# Copy BlackbaudJobConnector.mez to your Custom Connectors folder
```

## Usage

1. Open Power BI Desktop
2. Click **Get Data** → **More...**
3. Search for "Blackbaud Job Connector" or find it under **Other**
4. Click **Connect**
5. Complete the OAuth authentication flow when prompted
6. Browse available endpoints and select your data

### Authentication Setup

Before using the connector, ensure you have:

1. **Blackbaud Developer Account**: Register at [Blackbaud Developer](https://developer.blackbaud.com/)
2. **Application Registration**: Create an app in the Blackbaud Developer Console
3. **API Subscriptions**: Subscribe to the necessary SKY API endpoints
4. **OAuth Configuration**: Configure redirect URIs in your application settings

The connector will guide you through the OAuth flow on first use.

## Development

### Prerequisites

- **PowerShell 5.1+** (Windows) or **PowerShell Core 7+** (Cross-platform)
- **Power BI Desktop** (for testing)
- **Git** (for version control)
- **Text Editor** (VS Code recommended)

### Project Structure

```
powerbi-query-connector/
├── BlackbaudJobConnector.pq          # Main connector source code
├── build-scripts/                    # Development and build tools
│   ├── dev-helper.ps1                # Main development interface
│   ├── Build-Connector.ps1           # MEZ package builder
│   ├── Validate-Connector.ps1        # Code validation
│   └── Code-Quality-Check.ps1        # Code quality analysis
├── resources/                        # Icons and templates
│   ├── icons/                        # Connector icons (16x16 to 32x32)
│   ├── Content_Types.xml.template    # MEZ structure template
│   └── metadata.json.template        # Connector metadata
├── specs/                            # API specifications
├── .github/workflows/                 # CI/CD automation
└── README.md                         # This file
```

### Development Workflow

The project includes a comprehensive development helper script that provides a unified interface for all development tasks:

```powershell
# Show available commands
.\build-scripts\dev-helper.ps1 help

# Validate your connector code
.\build-scripts\dev-helper.ps1 validate

# Run code quality checks
.\build-scripts\dev-helper.ps1 quality

# Build MEZ package
.\build-scripts\dev-helper.ps1 build

# Run all checks and build
.\build-scripts\dev-helper.ps1 all
```

### Making Changes

1. **Edit the Connector**: Modify `BlackbaudJobConnector.pq` with your changes
2. **Validate**: Run `.\build-scripts\dev-helper.ps1 validate` to check syntax
3. **Quality Check**: Run `.\build-scripts\dev-helper.ps1 quality` for best practices
4. **Build**: Run `.\build-scripts\dev-helper.ps1 build` to create the MEZ package
5. **Test**: Install the new MEZ file in Power BI Desktop and test

### Code Quality Standards

The project enforces several quality standards:

- **PowerQuery Syntax**: Valid M language syntax
- **Authentication Patterns**: Proper OAuth 2.0 implementation
- **Error Handling**: Comprehensive error messages and recovery
- **Code Organization**: Clean, readable, and well-documented code
- **Security Practices**: No hardcoded credentials or sensitive data

### Testing

1. **Syntax Validation**: Automated PowerQuery syntax checking
2. **Code Quality**: Pattern matching for best practices and security
3. **Build Verification**: MEZ package structure validation
4. **Manual Testing**: Test connector functionality in Power BI Desktop

## CI/CD Pipeline

The project includes automated GitHub Actions workflows:

### Validation Workflow (`.github/workflows/validation.yml`)

Triggers on every push and pull request:
- PowerQuery syntax validation
- Code quality checks
- Security scanning
- Build verification

### Release Workflow (`.github/workflows/release.yml`)

Triggers on version tags (e.g., `v1.0.0`):
- Full validation suite
- MEZ package creation
- GitHub release with downloadable artifacts
- Automatic changelog generation

### Creating a Release

```bash
# Tag a new version
git tag v1.0.0
git push origin v1.0.0

# The release workflow will automatically:
# 1. Validate the code
# 2. Build the MEZ package
# 3. Create a GitHub release
# 4. Upload the MEZ file as a downloadable asset
```

## API Reference

### Supported Endpoints

The connector provides access to Blackbaud SKY API endpoints through async job processing:

- **School Information**: School details and configurations
- **Student Data**: Student records and related information
- **Financial Data**: Tuition, fees, and payment information
- **Custom Queries**: Submit custom API queries for processing

### Authentication Flow

1. **Authorization Request**: Redirects to Blackbaud OAuth endpoint
2. **User Consent**: User authorizes application access
3. **Authorization Code**: Blackbaud returns authorization code
4. **Token Exchange**: Connector exchanges code for access token using PKCE
5. **API Access**: Authenticated requests to SKY API endpoints

### Data Processing

1. **Job Submission**: Submit query to async job endpoint
2. **Polling**: Monitor job status with exponential backoff
3. **Result Retrieval**: Download CSV results when job completes
4. **Data Transformation**: Parse CSV into Power BI table format

## Troubleshooting

### Common Issues

**"Custom data connectors aren't enabled"**
- Enable custom connectors in Power BI Desktop security settings
- Restart Power BI Desktop after enabling

**"OAuth authentication failed"**
- Verify your Blackbaud application configuration
- Check redirect URI settings
- Ensure API subscriptions are active

**"Job execution timeout"**
- Large queries may take time to process
- Check job status in Blackbaud Developer Console
- Consider breaking large queries into smaller chunks

**"MEZ file not recognized"**
- Verify the MEZ file is in the correct Custom Connectors folder
- Check file permissions
- Ensure Power BI Desktop is restarted after copying

### Debug Logs

Enable Power BI Desktop diagnostic logging for detailed troubleshooting:
1. **File** → **Options and settings** → **Options**
2. **Diagnostics** → Enable logging
3. Check logs in `%LOCALAPPDATA%\Microsoft\Power BI Desktop\Traces`

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the full validation suite (`.\build-scripts\dev-helper.ps1 all`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow PowerQuery M language best practices
- Include comprehensive error handling
- Add comments for complex logic
- Maintain backward compatibility when possible
- Update documentation for new features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Report bugs and request features via [GitHub Issues](../../issues)
- **Documentation**: Additional documentation in the [Wiki](../../wiki)
- **Blackbaud API**: Official [SKY API Documentation](https://developer.blackbaud.com/skyapi/)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

---

**Built with ❤️ for the Blackbaud community**