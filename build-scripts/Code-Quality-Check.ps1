# PowerBI Connector Code Quality Checker
# Scans PowerQuery code for potential issues and coding best practices

param(
    [string]$FilePath = "BlackbaudJobConnector.pq",
    [switch]$ShowSuggestions = $false,
    [string]$OutputReport = ""
)

Write-Host "� Code Quality Check for PowerBI Connector: $FilePath" -ForegroundColor Green

if (-not (Test-Path $FilePath)) {
    Write-Host "❌ File not found: $FilePath" -ForegroundColor Red
    exit 1
}

$content = Get-Content $FilePath -Raw
$lines = $content -split "`n"
$codeIssues = @()
$bestPracticeFindings = @()

# Code quality patterns to check
$qualityPatterns = @(
    @{
        Name = "Potential Hardcoded Credential"
        Pattern = '(?i)password\s*=\s*"[^"]*"'
        Severity = "Warning"
        Description = "Potential hardcoded password detected"
        Suggestion = "Use credential store or OAuth instead of hardcoded passwords"
    },
    @{
        Name = "Potential Hardcoded API Key"
        Pattern = '(?i)(api_?key|apikey)\s*=\s*"[a-zA-Z0-9]{20,}"'
        Severity = "Warning"
        Description = "Potential hardcoded API key detected"
        Suggestion = "Store API keys in PowerBI credential store or use OAuth"
    },
    @{
        Name = "Client Secret Pattern"
        Pattern = '(?i)(secret|client_secret)\s*=\s*"[^"]*"'
        Severity = "Info"
        Description = "Client secret pattern detected (may be validation code)"
        Suggestion = "Verify this is validation code, not a hardcoded secret"
    },
    @{
        Name = "Hardcoded Token Pattern"
        Pattern = '(?i)(access_?token|bearer_?token)\s*=\s*"[^"]*"'
        Severity = "Warning"
        Description = "Potential hardcoded access token detected"
        Suggestion = "Tokens should be obtained dynamically through OAuth"
    },
    @{
        Name = "SQL Injection Risk"
        Pattern = '(?i)sql.*"\s*&.*&\s*"'
        Severity = "Warning"
        Description = "Potential SQL injection vulnerability"
        Suggestion = "Use parameterized queries instead of string concatenation"
    },
    @{
        Name = "URL with Credentials"
        Pattern = 'https?://[^:]+:[^@]+@[^/"]+'
        Severity = "Warning"
        Description = "URL with embedded credentials detected"
        Suggestion = "Remove credentials from URLs and use proper authentication"
    },
    @{
        Name = "Insecure HTTP"
        Pattern = 'http://(?!localhost|127\.0\.0\.1)'
        Severity = "Info"
        Description = "Insecure HTTP connection detected"
        Suggestion = "Use HTTPS for all external connections"
    },
    @{
        Name = "Debug Code"
        Pattern = '(?i)(debug|trace|console\.log)'
        Severity = "Info"
        Description = "Debugging code detected"
        Suggestion = "Remove debugging code before production deployment"
    }
)

Write-Host "🔍 Scanning for code quality issues..." -ForegroundColor Yellow

# Scan each pattern
foreach ($pattern in $qualityPatterns) {
    $regexMatches = [regex]::Matches($content, $pattern.Pattern)
    
    foreach ($match in $regexMatches) {
        # Find line number
        $position = $match.Index
        $lineNumber = ($content.Substring(0, $position) -split "`n").Count
        
        $finding = @{
            Type = $pattern.Name
            Severity = $pattern.Severity
            LineNumber = $lineNumber
            Match = $match.Value
            Description = $pattern.Description
            Suggestion = $pattern.Suggestion
            Context = $lines[$lineNumber - 1].Trim()
        }
        
        if ($pattern.Severity -eq "Warning") {
            $codeIssues += $finding
        } else {
            $bestPracticeFindings += $finding
        }
    }
}

# Additional context-specific checks
Write-Host "🔍 Performing PowerBI-specific code quality checks..." -ForegroundColor Yellow

# Check OAuth implementation patterns
if ($content -match "(?i)client_secret") {
    $bestPracticeFindings += @{
        Type = "OAuth Implementation"
        Severity = "Info"
        LineNumber = 0
        Match = "client_secret usage detected"
        Description = "Client secret pattern found (likely validation code)"
        Suggestion = "PowerBI connectors should use PKCE flow without client secrets"
        Context = "OAuth Configuration"
    }
}

# Check for proper certificate validation
if ($content -notmatch "(?i)certificate|ssl|tls") {
    $bestPracticeFindings += @{
        Type = "Certificate Validation"
        Severity = "Info"
        LineNumber = 0
        Match = "No explicit certificate handling"
        Description = "No explicit certificate validation detected"
        Suggestion = "Consider explicit SSL/TLS certificate validation for enhanced security"
        Context = "HTTPS Configuration"
    }
}

# Check for rate limiting
if ($content -notmatch "(?i)(rate.?limit|throttle|delay|wait)") {
    $bestPracticeFindings += @{
        Type = "Rate Limiting"
        Severity = "Info"
        LineNumber = 0
        Match = "No rate limiting detected"
        Description = "No rate limiting mechanism detected"
        Suggestion = "Implement rate limiting to prevent API abuse"
        Context = "API Usage"
    }
}

# Check for input validation
if ($content -notmatch "(?i)(validate|sanitize|clean)") {
    $bestPracticeFindings += @{
        Type = "Input Validation"
        Severity = "Info"
        LineNumber = 0
        Match = "Limited input validation"
        Description = "Limited input validation detected"
        Suggestion = "Implement comprehensive input validation for all user inputs"
        Context = "Data Processing"
    }
}

# Generate report
Write-Host ""
Write-Host "📊 Code Quality Results:" -ForegroundColor Yellow

$warningCount = ($codeIssues | Where-Object { $_.Severity -eq "Warning" }).Count
$infoCount = ($bestPracticeFindings | Where-Object { $_.Severity -eq "Info" }).Count

Write-Host "⚠️  Code Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "ℹ️  Best Practice Notes: $infoCount" -ForegroundColor Cyan

if ($codeIssues.Count -eq 0 -and $bestPracticeFindings.Count -eq 0) {
    Write-Host ""
    Write-Host "✅ No code quality issues found!" -ForegroundColor Green
    Write-Host "🎉 Code follows best practices" -ForegroundColor Green
} else {
    if ($codeIssues.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  Code Quality Warnings:" -ForegroundColor Yellow
        
        foreach ($issue in $codeIssues) {
            Write-Host ""
            Write-Host "[Warning] $($issue.Type)" -ForegroundColor Yellow
            Write-Host "   Line $($issue.LineNumber): $($issue.Description)" -ForegroundColor White
            Write-Host "   Pattern: $($issue.Match)" -ForegroundColor Gray
            Write-Host "   Context: $($issue.Context)" -ForegroundColor Gray
            
            if ($ShowSuggestions) {
                Write-Host "   💡 Suggestion: $($issue.Suggestion)" -ForegroundColor Cyan
            }
        }
    }
    
    if ($bestPracticeFindings.Count -gt 0 -and $ShowSuggestions) {
        Write-Host ""
        Write-Host "💡 Best Practice Recommendations:" -ForegroundColor Cyan
        
        foreach ($finding in $bestPracticeFindings) {
            Write-Host ""
            Write-Host "[Info] $($finding.Type)" -ForegroundColor Cyan
            Write-Host "   $($finding.Description)" -ForegroundColor White
            Write-Host "   💡 $($finding.Suggestion)" -ForegroundColor Cyan
        }
    }
}

# Code quality best practices summary
if ($ShowSuggestions) {
    Write-Host ""
    Write-Host "� PowerBI Connector Best Practices:" -ForegroundColor Magenta
    Write-Host "   • Use OAuth 2.0 with PKCE for authentication" -ForegroundColor White
    Write-Host "   • Store credentials in PowerBI's credential store" -ForegroundColor White
    Write-Host "   • Always use HTTPS for external communications" -ForegroundColor White
    Write-Host "   • Implement proper error handling without exposing sensitive data" -ForegroundColor White
    Write-Host "   • Validate all user inputs and API responses" -ForegroundColor White
    Write-Host "   • Use Function.InvokeAfter for async operations" -ForegroundColor White
    Write-Host "   • Implement rate limiting for API calls" -ForegroundColor White
    Write-Host "   • Remove debugging code before production" -ForegroundColor White
}

# Generate report file if requested
if ($OutputReport) {
    $report = @{
        ScanDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        FilePath = $FilePath
        Summary = @{
            Warnings = $warningCount
            BestPracticeNotes = $infoCount
        }
        CodeIssues = $codeIssues
        BestPracticeFindings = $bestPracticeFindings
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File $OutputReport -Encoding utf8
    Write-Host ""
    Write-Host "📄 Code quality report saved to: $OutputReport" -ForegroundColor Green
}

# Exit codes
if ($warningCount -gt 0) {
    Write-Host ""
    Write-Host "⚠️ Code quality warnings found - review recommended" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host ""
    Write-Host "� Code quality check completed successfully!" -ForegroundColor Green
    exit 0
}