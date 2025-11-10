# PowerBI Connector Development Helper
# Main entry point for local development tasks

param(
    [Parameter(Position=0)]
    [ValidateSet("build", "validate", "quality", "test", "clean", "help")]
    [string]$Action = "help",
    
    [string]$Version = "dev",
    [switch]$Clean = $false,
    [switch]$Detailed = $false,
    [switch]$ShowSuggestions = $false
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "🚀 PowerBI Connector Development Helper" -ForegroundColor Magenta
Write-Host "Project: $(Split-Path $ProjectRoot -Leaf)" -ForegroundColor Cyan
Write-Host ""

function Show-Help {
    Write-Host "Available Actions:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  build       Build the connector MEZ package" -ForegroundColor Green
    Write-Host "  validate    Validate PowerQuery code syntax and structure" -ForegroundColor Green
    Write-Host "  quality     Run code quality and best practices check" -ForegroundColor Green
    Write-Host "  test        Run all validation and quality checks" -ForegroundColor Green
    Write-Host "  clean       Clean build outputs" -ForegroundColor Green
    Write-Host "  help        Show this help message" -ForegroundColor Green
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Version <version>     Set version for build (default: dev)" -ForegroundColor Cyan
    Write-Host "  -Clean                 Clean intermediate files" -ForegroundColor Cyan
    Write-Host "  -Detailed              Show detailed analysis" -ForegroundColor Cyan
    Write-Host "  -ShowSuggestions       Show improvement suggestions" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\dev-helper.ps1 build -Version 1.0.0" -ForegroundColor White
    Write-Host "  .\dev-helper.ps1 validate -Detailed" -ForegroundColor White
    Write-Host "  .\dev-helper.ps1 quality -ShowSuggestions" -ForegroundColor White
    Write-Host "  .\dev-helper.ps1 test" -ForegroundColor White
}

function Invoke-ConnectorBuild {
    Write-Host "🏗️ Building connector..." -ForegroundColor Green
    $buildScript = Join-Path $ScriptDir "Build-Connector.ps1"
    & $buildScript -Version $Version -Clean:$Clean
}

function Invoke-ConnectorValidation {
    Write-Host "🔍 Validating connector..." -ForegroundColor Green
    $validateScript = Join-Path $ScriptDir "Validate-Connector.ps1"
    & $validateScript -Detailed:$Detailed
}

function Invoke-CodeQualityCheck {
    Write-Host "� Running code quality check..." -ForegroundColor Green
    $qualityScript = Join-Path $ScriptDir "Code-Quality-Check.ps1"
    & $qualityScript -ShowSuggestions:$ShowSuggestions
}

function Invoke-TestSuite {
    Write-Host "🧪 Running full test suite..." -ForegroundColor Green
    Write-Host ""
    
    $allPassed = $true
    
    # Run validation
    try {
        Invoke-ConnectorValidation
        Write-Host "✅ Validation passed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Validation failed" -ForegroundColor Red
        $allPassed = $false
    }
    
    Write-Host ""
    
    # Run code quality check
    try {
        Invoke-CodeQualityCheck
        Write-Host "✅ Code quality check passed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Code quality check failed" -ForegroundColor Red
        $allPassed = $false
    }
    
    Write-Host ""
    Write-Host "📊 Test Suite Summary:" -ForegroundColor Yellow
    if ($allPassed) {
        Write-Host "🎉 All tests passed! Connector is ready for build." -ForegroundColor Green
    } else {
        Write-Host "⚠️ Some tests failed. Review issues before building." -ForegroundColor Red
    }
    
    return $allPassed
}

function Invoke-Clean {
    Write-Host "🧹 Cleaning build outputs..." -ForegroundColor Green
    
    $buildDir = Join-Path $ProjectRoot "build-output"
    if (Test-Path $buildDir) {
        Remove-Item $buildDir -Recurse -Force
        Write-Host "✅ Removed build-output directory" -ForegroundColor Green
    }
    
    # Clean any temporary files
    Get-ChildItem $ProjectRoot -Filter "*.tmp" -Recurse | Remove-Item -Force
    Get-ChildItem $ProjectRoot -Filter "*.log" -Recurse | Remove-Item -Force
    
    Write-Host "✅ Cleanup completed" -ForegroundColor Green
}

try {
    # Change to project root
    Set-Location $ProjectRoot
    
    switch ($Action) {
        "build" {
            Invoke-ConnectorBuild
        }
        "validate" {
            Invoke-ConnectorValidation
        }
        "quality" {
            Invoke-CodeQualityCheck
        }
        "test" {
            $passed = Invoke-TestSuite
            if (-not $passed) {
                exit 1
            }
        }
        "clean" {
            Invoke-Clean
        }
        "help" {
            Show-Help
        }
        default {
            Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
            Show-Help
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "✅ Action '$Action' completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ Action '$Action' failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}