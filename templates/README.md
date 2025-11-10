# PowerBI Connector Templates

This directory contains template files used during the MEZ package build process.

## Template Files

### [Content_Types].xml
Defines MIME types for files included in the MEZ package. This is required by the Open Packaging Conventions (OPC) format that MEZ files follow.

**Supported content types:**
- `.m` files - PowerQuery M language source code
- `.json` files - Metadata and configuration
- `.png` files - Icon images
- `.xml` files - Configuration and manifest files
- `.txt` files - Documentation and license files

### metadata.json
Comprehensive metadata template for the connector including:

**Core Information:**
- Connector name, display name, and description
- Version and author information
- Category and beta status

**Capabilities:**
- OAuth2 authentication with PKCE support
- Async query execution
- Data source connectivity

**URLs:**
- Documentation and support links
- Privacy policy and license information

**Build Information:**
- Build date and tool information
- Source file references
- Requirements and dependencies

**Branding:**
- Icon file references
- Tags for discovery

## Usage in Build Process

The build scripts use these templates:

1. **[Content_Types].xml** - Copied directly to MEZ package root
2. **metadata.json** - Processed to update version, build date, and other dynamic values

## Customization

### Updating Metadata
Edit `metadata.json` to customize:
- Company and author information
- Support URLs and documentation links
- Capability declarations
- Requirements and dependencies

### Content Types
Add new content types to `[Content_Types].xml` if you include additional file types:

```xml
<Default Extension="pdf" ContentType="application/pdf"/>
<Default Extension="md" ContentType="text/markdown"/>
```

### Version Management
The build process automatically updates:
- `version` field from git tags or build parameters
- `buildDate` to current timestamp
- `buildTool` to identify build environment

## Validation

Templates are validated during build:
- JSON syntax checking for metadata.json
- XML schema validation for [Content_Types].xml
- Required field verification
- URL accessibility testing (optional)

These templates ensure your MEZ package meets PowerBI's requirements and provides proper metadata for the connector marketplace.