#!/usr/bin/env powershell
<#
.SYNOPSIS
    Phase 3 Robustness Verification - 16-point checklist
    
.DESCRIPTION
    Tests new-project.ps1 and template robustness with:
    - Input validation (project names, board selection)
    - Error handling (existing directories, missing files)
    - Negative test cases
    - 16-point verification suite
    
.EXAMPLE
    .\test-phase3.ps1 -TestDirectory "C:\temp\test-phase3"
    
#>

param(
    [string]$TestDirectory = "C:\temp\test-phase3",
    [string]$TemplateDir = $PSScriptRoot
)

$ErrorActionPreference = "Continue"
$testResults = @()
$passCount = 0
$failCount = 0

# ============================================================================
# Helper Functions
# ============================================================================

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $result = @{
        Name = $TestName
        Passed = $Passed
        Details = $Details
        Timestamp = Get-Date
    }
    
    $global:testResults += $result
    
    if ($Passed) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $global:passCount++
    }
    else {
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        if ($Details) {
            Write-Host "         $Details" -ForegroundColor Yellow
        }
        $global:failCount++
    }
}

function Test-NegativeCase {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [bool]$ShouldFail = $true
    )
    
    try {
        & $TestScript
        
        # Check if subprocess failed (exit code was non-zero)
        if ($LASTEXITCODE -ne 0) {
            if ($ShouldFail) {
                Add-TestResult -TestName $TestName -Passed $true
            }
            else {
                Add-TestResult -TestName $TestName -Passed $false -Details "Subprocess exited with code $LASTEXITCODE"
            }
        }
        else {
            if ($ShouldFail) {
                Add-TestResult -TestName $TestName -Passed $false -Details "Expected to fail but succeeded"
            }
            else {
                Add-TestResult -TestName $TestName -Passed $true
            }
        }
    }
    catch {
        if ($ShouldFail) {
            Add-TestResult -TestName $TestName -Passed $true
        }
        else {
            Add-TestResult -TestName $TestName -Passed $false -Details $_.Exception.Message
        }
    }
}

# ============================================================================
# Setup
# ============================================================================

Write-Host ""
Write-Host "Phase 3: Robustness Verification" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $TestDirectory)) {
    New-Item -Path $TestDirectory -ItemType Directory | Out-Null
}

Write-Host "Test directory: $TestDirectory" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# Test Category 1: Input Validation
# ============================================================================

Write-Host "Test Category 1: Input Validation" -ForegroundColor Cyan
Write-Host ""

# Test 1: Valid project name (lowercase with hyphen)
Test-NegativeCase -TestName "Valid project name (my-app)" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "my-app" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
    if (-not (Test-Path "$TestDirectory\my-app")) { throw "Directory not created" }
} -ShouldFail $false

# Test 2: Invalid - empty project name
Test-NegativeCase -TestName "Reject empty project name" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
} -ShouldFail $true

# Test 3: Invalid - too short (< 3 chars)
Test-NegativeCase -TestName "Reject short name (ab)" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "ab" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
} -ShouldFail $true

# Test 4: Invalid - uppercase letters
Test-NegativeCase -TestName "Reject uppercase (MyApp)" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "MyApp" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
} -ShouldFail $true

# Test 5: Invalid - special characters
Test-NegativeCase -TestName "Reject special chars (my@app)" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "my@app" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
} -ShouldFail $true

# Test 6: Invalid - consecutive hyphens
Test-NegativeCase -TestName "Reject consecutive hyphens (my--app)" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "my--app" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
} -ShouldFail $true

# Test 7: Invalid - starts with hyphen
Test-NegativeCase -TestName "Reject leading hyphen (-myapp)" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "-myapp" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
} -ShouldFail $true

# Test 8: Invalid - board selection out of range
Test-NegativeCase -TestName "Reject invalid board (0)" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "app" -Board 0 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
} -ShouldFail $true

Write-Host ""

# ============================================================================
# Test Category 2: Directory & File Handling
# ============================================================================

Write-Host "Test Category 2: Directory & File Handling" -ForegroundColor Cyan
Write-Host ""

# Test 9: Project directory creation succeeds
Test-NegativeCase -TestName "Create project directory" -TestScript {
    $testPath = "$TestDirectory\test-proj-001"
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "test-proj-001" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
    if (-not (Test-Path $testPath)) { throw "Directory not created" }
} -ShouldFail $false

# Test 10: Reject existing directory without -Force
Test-NegativeCase -TestName "Reject existing directory" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "test-proj-001" -Board 1 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
} -ShouldFail $true

# Test 11: Allow overwrite with -Force flag
Test-NegativeCase -TestName "Allow overwrite with -Force" -TestScript {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "test-proj-001" -Board 1 -OutputDirectory $TestDirectory -Force -NoConfirm 2>&1 | Out-Null
    if (-not (Test-Path "$TestDirectory\test-proj-001")) { throw "Not created" }
} -ShouldFail $false

# Test 12: All required files copied
Test-NegativeCase -TestName "All template files copied" -TestScript {
    $projDir = "$TestDirectory\test-proj-002"
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "test-proj-002" -Board 2 -OutputDirectory $TestDirectory -NoConfirm 2>&1 | Out-Null
    
    $requiredFiles = @(
        "CMakeLists.txt",
        "src/main.c",
        "src/CMakeLists.txt",
        "include/config.h",
        "idf_component.yml",
        "sdkconfig",
        "BUILD_GUIDE.md",
        "SECURITY.md"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path "$projDir\$file")) {
            throw "Missing file: $file"
        }
    }
} -ShouldFail $false

Write-Host ""

# ============================================================================
# Test Category 3: Board-Specific Configuration
# ============================================================================

Write-Host "Test Category 3: Board-Specific Configuration" -ForegroundColor Cyan
Write-Host ""

# Test 13: Board 1 (ESP32) - Basic
Test-NegativeCase -TestName "Board 1 (ESP32)" -TestScript {
    $projDir = "$TestDirectory\test-esp32-board"
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "test-esp32-board" -Board 1 -OutputDirectory $TestDirectory -Force -NoConfirm 2>&1 | Out-Null
    
    $config = Get-Content "$projDir\sdkconfig" -Raw
    if ($config -notmatch 'CONFIG_IDF_TARGET="esp32"') {
        throw "Wrong target"
    }
} -ShouldFail $false

# Test 14: Board 2 (ESP32-S2) - Single-core
Test-NegativeCase -TestName "Board 2 (ESP32-S2) single-core config" -TestScript {
    $projDir = "$TestDirectory\test-esp32s2-board"
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
        -ProjectName "test-esp32s2-board" -Board 2 -OutputDirectory $TestDirectory -Force -NoConfirm 2>&1 | Out-Null
    
    $config = Get-Content "$projDir\sdkconfig" -Raw
    if ($config -notmatch 'CONFIG_IDF_TARGET="esp32s2"') {
        throw "Wrong target"
    }
    if ($config -notmatch 'CONFIG_FREERTOS_NO_AFFINITY=y') {
        throw "Missing single-core config"
    }
} -ShouldFail $false

# Test 15: Variable substitution for all boards
Test-NegativeCase -TestName "Variable substitution (all boards)" -TestScript {
    foreach ($board in 1..5) {
        $projName = "var-test-b$board"
        $projDir = "$TestDirectory\$projName"
        
        & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
            -ProjectName $projName -Board $board -OutputDirectory $TestDirectory -Force -NoConfirm 2>&1 | Out-Null
        
        $mainC = Get-Content "$projDir\src\main.c" -Raw
        if ($mainC -match '\$\{PROJECT_NAME\}') {
            throw "Variable not replaced in board $board"
        }
        if ($mainC -notmatch "var-test-b$board") {
            throw "Project name not found in board $board"
        }
    }
} -ShouldFail $false

# Test 16: Git initialization when available
Test-NegativeCase -TestName "Git initialization (if available)" -TestScript {
    # Check if git is available
    try {
        & git --version | Out-Null
        $hasGit = $true
    }
    catch {
        $hasGit = $false
    }
    
    if ($hasGit) {
        $projDir = "$TestDirectory\test-git-proj"
        & powershell -NoProfile -ExecutionPolicy Bypass -File "$TemplateDir\new-project.ps1" `
            -ProjectName "test-git-proj" -Board 1 -OutputDirectory $TestDirectory -Force -NoConfirm 2>&1 | Out-Null
        
        if (-not (Test-Path "$projDir\.git")) {
            throw "Git repo not created"
        }
    }
    # If git not available, test is skipped (pass)
} -ShouldFail $false

Write-Host ""

# ============================================================================
# Summary
# ============================================================================

Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests:  $($passCount + $failCount)" -ForegroundColor White
Write-Host "Passed:       $passCount" -ForegroundColor Green
Write-Host "Failed:       $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "Phase 3: PASSED - All robustness checks successful!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Phase 3: FAILED - Some tests did not pass" -ForegroundColor Red
    exit 1
}
