# PowerBI Connector Resources

This directory contains resources used for building the PowerBI connector MEZ package.

## Icons

Multiple icon sizes are provided for different UI contexts in PowerBI:

- `icon16.png` - 16x16 pixels - Used in small UI elements
- `icon20.png` - 20x20 pixels - Standard icon size (default)
- `icon24.png` - 24x24 pixels - Used in medium UI elements  
- `icon32.png` - 32x32 pixels - Used in larger UI elements
- `icon.png` - Default icon (copy of icon20.png)

All icons use Blackbaud's brand color (#0078D4) with a clean geometric design that represents data connectivity.

## Icon Design

The icons feature a simple, scalable design:
- **Outer border**: Blackbaud blue (#0078D4)
- **Inner border**: White background for contrast
- **Center**: Blackbaud blue square representing data/connectivity

This design works well at all sizes and maintains brand consistency.

## Customization

To use custom icons:

1. Replace the PNG files in this directory with your own designs
2. Maintain the same file names and sizes
3. Use PNG format with transparency support
4. Ensure icons are square and properly sized
5. Test at different zoom levels in PowerBI

## Build Integration

The build scripts automatically:
- Copy icons from this directory to the MEZ package
- Reference them in the metadata.json
- Include proper MIME types in [Content_Types].xml

The icons are embedded in the final MEZ package and distributed with the connector.