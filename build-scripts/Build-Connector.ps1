# PowerBI Connector Build Script
# Creates a .mez package for local development and testing

param(
    [string]$Version = "dev",
    [string]$OutputDir = "build-output",
    [switch]$Clean = $false
)

Write-Host "🏗️ Building Blackbaud PowerBI Connector" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Yellow

# Clean output directory if requested
if ($Clean -and (Test-Path $OutputDir)) {
    Write-Host "🧹 Cleaning output directory..." -ForegroundColor Yellow
    Remove-Item $OutputDir -Recurse -Force
}

# Create build directories
$mezDir = "$OutputDir/mez-contents"
$resourcesDir = "$mezDir/Resources"

Write-Host "📁 Creating build directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path $mezDir -Force | Out-Null
New-Item -ItemType Directory -Path $resourcesDir -Force | Out-Null

try {
    # Validate source file exists
    $pqFile = "BlackbaudJobConnector.pq"
    if (-not (Test-Path $pqFile)) {
        throw "PowerQuery file not found: $pqFile"
    }
    
    Write-Host "✅ Source file validated" -ForegroundColor Green
    
    # Copy .pq file as .m file
    Copy-Item $pqFile "$mezDir/BlackbaudJobConnector.m"
    Write-Host "✅ Copied connector file" -ForegroundColor Green
    
    # Create [Content_Types].xml directly (avoid square bracket filename issues)
    $contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="m" ContentType="application/x-powerquery-m"/>
    <Default Extension="json" ContentType="application/json"/>
    <Default Extension="png" ContentType="image/png"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Default Extension="txt" ContentType="text/plain"/>
</Types>
'@
    
    $contentTypesPath = Join-Path $mezDir "[Content_Types].xml"
    [System.IO.File]::WriteAllText($contentTypesPath, $contentTypes, [System.Text.Encoding]::UTF8)
    Write-Host "✅ Created Content_Types.xml" -ForegroundColor Green
    
    # Create metadata.json (use template if available, otherwise generate)
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptDir
    $metadataTemplate = Join-Path $projectRoot "templates" "metadata.json"
    
    if (Test-Path $metadataTemplate) {
        $templateContent = Get-Content $metadataTemplate -Raw | ConvertFrom-Json
        $templateContent.version = $Version
        $templateContent.build.buildDate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        $metadataJson = $templateContent | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText("$resourcesDir/metadata.json", $metadataJson, [System.Text.Encoding]::UTF8)
        Write-Host "✅ Created metadata.json from template" -ForegroundColor Green
    } else {
        # Fallback to embedded version
        $metadata = @{
            name = "BlackbaudJobConnector"
            displayName = "Blackbaud Query Connector"
            description = "PowerBI connector for Blackbaud SKY API Query service with async execution support"
            version = $Version
            author = "Blackbaud"
            category = "Online Services"
            beta = $true
            learnMoreUrl = "https://developer.blackbaud.com/skyapi/"
            supportUrl = "https://github.com/blackbaud-joshlyford/powerbi-query-connector"
            buildDate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        $metadataJson = $metadata | ConvertTo-Json -Depth 3
        [System.IO.File]::WriteAllText("$resourcesDir/metadata.json", $metadataJson, [System.Text.Encoding]::UTF8)
        Write-Host "✅ Created metadata.json (fallback)" -ForegroundColor Green
    }
    
    # Copy icons from resources directory
    $iconPath = "$resourcesDir/icon.png"
    $sourceIconPath = Join-Path $projectRoot "resources" "icon.png"
    
    if (Test-Path $sourceIconPath) {
        Copy-Item $sourceIconPath $iconPath
        Write-Host "✅ Copied icon from resources" -ForegroundColor Green
        
        # Copy all icon sizes if they exist
        $iconSizes = @("16", "20", "24", "32")
        foreach ($size in $iconSizes) {
            $sizeIconSource = Join-Path $projectRoot "resources" "icon$size.png"
            $sizeIconDest = "$resourcesDir/icon$size.png"
            if (Test-Path $sizeIconSource) {
                Copy-Item $sizeIconSource $sizeIconDest
                Write-Host "✅ Copied icon$size.png" -ForegroundColor Green
            }
        }
    } else {
        # Create a simple placeholder icon if no custom icon exists
        $iconBase64 = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAFYSURBVDiNpZM9SwNBEIafBAtbwcJCG1sLwcJCK1sLwcJaG1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sLwcJCK1sL"
        $iconBytes = [Convert]::FromBase64String($iconBase64)
        [System.IO.File]::WriteAllBytes($iconPath, $iconBytes)
        Write-Host "✅ Created placeholder icon" -ForegroundColor Green
    }
    
    # Create MEZ package
    $mezFile = "$OutputDir/BlackbaudJobConnector-$Version.mez"
    Write-Host "📦 Creating MEZ package..." -ForegroundColor Yellow
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($mezDir, $mezFile)
    
    # Verify package
    if (Test-Path $mezFile) {
        $size = (Get-Item $mezFile).Length
        Write-Host "✅ MEZ package created successfully!" -ForegroundColor Green
        Write-Host "📊 Package: $(Split-Path $mezFile -Leaf)" -ForegroundColor Cyan
        Write-Host "📊 Size: $([math]::Round($size / 1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "📁 Location: $(Resolve-Path $mezFile)" -ForegroundColor Cyan
        
        Write-Host ""
        Write-Host "🚀 Installation Instructions:" -ForegroundColor Yellow
        Write-Host "1. Copy the .mez file to: %USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\" -ForegroundColor White
        Write-Host "2. Restart PowerBI Desktop" -ForegroundColor White
        Write-Host "3. Enable custom connectors in PowerBI security settings" -ForegroundColor White
        
    } else {
        throw "MEZ package creation failed"
    }
    
} catch {
    Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Clean up intermediate files if needed
    if ($Clean -and (Test-Path "$OutputDir/mez-contents")) {
        Remove-Item "$OutputDir/mez-contents" -Recurse -Force
    }
}

Write-Host ""
Write-Host "🎉 Build completed successfully!" -ForegroundColor Green