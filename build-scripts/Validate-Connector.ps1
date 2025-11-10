# PowerBI Connector Validation Script
# Validates PowerQuery code for common issues before building

param(
    [string]$FilePath = "BlackbaudJobConnector.pq",
    [switch]$Detailed = $false
)

Write-Host "🔍 Validating PowerBI Connector: $FilePath" -ForegroundColor Green

$validationErrors = @()
$validationWarnings = @()

if (-not (Test-Path $FilePath)) {
    Write-Host "❌ File not found: $FilePath" -ForegroundColor Red
    exit 1
}

$content = Get-Content $FilePath -Raw

try {
    Write-Host "📋 Running validation checks..." -ForegroundColor Yellow
    
    # 1. Basic PowerQuery syntax validation
    Write-Host "   • Checking PowerQuery syntax..." -ForegroundColor Cyan
    
    # Check balanced brackets and parentheses
    $brackets = 0
    $parentheses = 0
    $squareBrackets = 0
    $inString = $false
    $inComment = $false
    $escapeNext = $false
    
    for ($i = 0; $i -lt $content.Length; $i++) {
        $char = $content[$i]
        $nextChar = if ($i + 1 -lt $content.Length) { $content[$i + 1] } else { $null }
        
        if ($escapeNext) {
            $escapeNext = $false
            continue
        }
        
        if ($char -eq '\') {
            $escapeNext = $true
            continue
        }
        
        # Handle comments
        if (-not $inString -and $char -eq '/' -and $nextChar -eq '*') {
            $inComment = $true
            $i++ # Skip next character
            continue
        }
        if ($inComment -and $char -eq '*' -and $nextChar -eq '/') {
            $inComment = $false
            $i++ # Skip next character
            continue
        }
        if ($inComment) { continue }
        
        # Handle strings
        if ($char -eq '"') {
            $inString = -not $inString
            continue
        }
        if ($inString) { continue }
        
        # Count brackets and parentheses
        switch ($char) {
            '{' { $brackets++ }
            '}' { $brackets-- }
            '(' { $parentheses++ }
            ')' { $parentheses-- }
            '[' { $squareBrackets++ }
            ']' { $squareBrackets-- }
        }
        
        # Check for negative counts (closing before opening)
        if ($brackets -lt 0) {
            $validationErrors += "Unmatched closing brace '}' at position $i"
            $brackets = 0  # Reset to continue checking
        }
        if ($parentheses -lt 0) {
            $validationErrors += "Unmatched closing parenthesis ')' at position $i"
            $parentheses = 0
        }
        if ($squareBrackets -lt 0) {
            $validationErrors += "Unmatched closing bracket ']' at position $i"
            $squareBrackets = 0
        }
    }
    
    # Check for unclosed brackets/parentheses
    if ($brackets -gt 0) {
        $validationErrors += "Unclosed braces: $brackets brace(s) not closed"
    }
    if ($parentheses -gt 0) {
        $validationErrors += "Unclosed parentheses: $parentheses parenthesis(es) not closed"
    }
    if ($squareBrackets -gt 0) {
        $validationErrors += "Unclosed square brackets: $squareBrackets bracket(s) not closed"
    }
    
    # 2. Check for required PowerQuery connector elements
    Write-Host "   • Checking connector structure..." -ForegroundColor Cyan
    
    $requiredElements = @(
        "let",
        "shared.*\.Contents",  # Main connector function (regex pattern)
        "Navigation"
    )
    
    foreach ($element in $requiredElements) {
        if ($element -match "regex:") {
            # Handle regex patterns
            $pattern = $element -replace "regex:", ""
            if ($content -notmatch $pattern) {
                $validationWarnings += "Missing expected PowerQuery element: $element"
            }
        } elseif ($element -match "\.\*") {
            # Handle regex patterns
            if ($content -notmatch $element) {
                $validationWarnings += "Missing expected PowerQuery element pattern: $element"
            }
        } else {
            # Handle literal strings
            if ($content -notmatch [regex]::Escape($element)) {
                $validationWarnings += "Missing expected PowerQuery element: $element"
            }
        }
    }
    
    # 3. Code quality checks
    Write-Host "   • Checking code quality..." -ForegroundColor Cyan
    
    # Check for TODO/FIXME comments
    if ($content -match "(?i)(TODO|FIXME|HACK)") {
        $validationWarnings += "Code contains TODO/FIXME/HACK comments that should be addressed"
    }
    
    # Check for proper error handling
    if ($content -notmatch "try.*otherwise") {
        $validationWarnings += "Consider adding error handling with try...otherwise blocks"
    }
    
    # Check connector metadata
    if ($content -notmatch 'ConnectorVersion\s*=') {
        $validationWarnings += "ConnectorVersion not found - version management recommended"
    }
    
    # 5. OAuth validation (specific to this connector)
    Write-Host "   • Checking OAuth implementation..." -ForegroundColor Cyan
    
    # Check for OAuth 2.0 with PKCE implementation
    if ($content -match "code_verifier" -and $content -match "code_challenge") {
        # PKCE flow detected - this is good
    } elseif ($content -match "client_secret") {
        $validationWarnings += "Consider using OAuth PKCE flow instead of client secrets for better security"
    } elseif ($content -notmatch "OAuth|authentication") {
        $validationWarnings += "No authentication mechanism detected - verify connector security"
    }
    
    # 6. Performance checks
    Write-Host "   • Checking performance considerations..." -ForegroundColor Cyan
    
    # Check for potential infinite loops in polling
    if ($content -match "while" -and $content -notmatch "Function\.InvokeAfter") {
        $validationWarnings += "Consider using Function.InvokeAfter for async operations instead of while loops"
    }
    
    # Results summary
    Write-Host ""
    Write-Host "📊 Validation Results:" -ForegroundColor Yellow
    
    if ($validationErrors.Count -eq 0 -and $validationWarnings.Count -eq 0) {
        Write-Host "✅ All validation checks passed!" -ForegroundColor Green
        Write-Host "🎉 Connector appears to be ready for building" -ForegroundColor Green
    } else {
        if ($validationErrors.Count -gt 0) {
            Write-Host ""
            Write-Host "❌ Validation Errors ($($validationErrors.Count)):" -ForegroundColor Red
            foreach ($validationIssue in $validationErrors) {
                Write-Host "   • $validationIssue" -ForegroundColor Red
            }
        }
        
        if ($validationWarnings.Count -gt 0) {
            Write-Host ""
            Write-Host "⚠️  Validation Warnings ($($validationWarnings.Count)):" -ForegroundColor Yellow
            foreach ($warning in $validationWarnings) {
                Write-Host "   • $warning" -ForegroundColor Yellow
            }
        }
        
        if ($validationErrors.Count -gt 0) {
            Write-Host ""
            Write-Host "🚫 Build not recommended due to validation errors" -ForegroundColor Red
            exit 1
        } else {
            Write-Host ""
            Write-Host "✅ No critical errors found - build can proceed" -ForegroundColor Green
            Write-Host "💡 Consider addressing warnings for production use" -ForegroundColor Yellow
        }
    }
    
    # Detailed analysis if requested
    if ($Detailed) {
        Write-Host ""
        Write-Host "📈 Detailed Analysis:" -ForegroundColor Magenta
        
        $lines = $content -split "`n"
        Write-Host "   • Total lines: $($lines.Count)" -ForegroundColor Cyan
        Write-Host "   • File size: $([math]::Round((Get-Item $FilePath).Length / 1KB, 2)) KB" -ForegroundColor Cyan
        
        $functionCount = ([regex]::Matches($content, '\b\w+\s*=\s*\(')).Count
        Write-Host "   • Estimated functions: $functionCount" -ForegroundColor Cyan
        
        $commentLines = ($lines | Where-Object { $_ -match '^\s*//' }).Count
        Write-Host "   • Comment lines: $commentLines" -ForegroundColor Cyan
        
        if ($content -match 'ConnectorVersion\s*=\s*"([^"]*)"') {
            Write-Host "   • Connector version: $($Matches[1])" -ForegroundColor Cyan
        }
    }
    
} catch {
    Write-Host "❌ Validation failed with error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔍 Validation completed!" -ForegroundColor Green