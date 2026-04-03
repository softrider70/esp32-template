#!/usr/bin/env powershell
# ESP32 Project Generator - Create new project from template
# Usage: .\new-project.ps1 -ProjectName "my-app" -Board 1

param(
    [Parameter(Position = 0)]
    [string]$ProjectName,

    [Parameter(Position = 1)]
    [ValidateRange(1, 5)]
    [int]$Board,

    [string]$OutputDirectory = "",

    [switch]$SkipGit = $false,
    
    [switch]$Force = $false,
    
    [switch]$NoConfirm = $false
)

# ============================================================================
# Global Configuration
# ============================================================================

$BoardMap = @{
    1 = @{ Name = "ESP32"; ConfigName = "esp32"; Cores = 2; SRAM = "520KB"; PSRAM = "yes" }
    2 = @{ Name = "ESP32-S2"; ConfigName = "esp32s2"; Cores = 1; SRAM = "320KB"; PSRAM = "no" }
    3 = @{ Name = "ESP32-S3"; ConfigName = "esp32s3"; Cores = 2; SRAM = "512KB"; PSRAM = "yes" }
    4 = @{ Name = "ESP32-C3"; ConfigName = "esp32c3"; Cores = 1; SRAM = "400KB"; PSRAM = "no" }
    5 = @{ Name = "ESP32-C6"; ConfigName = "esp32c6"; Cores = 2; SRAM = "512KB"; PSRAM = "yes" }
}

$ErrorActionPreference = "Stop"

# ============================================================================
# Validation & Error Handling
# ============================================================================

function Test-TemplateDirectory {
    $TemplateDir = $PSScriptRoot
    if (-not (Test-Path (Join-Path $TemplateDir "CMakeLists.txt"))) {
        throw "Template directory not found at $TemplateDir (missing CMakeLists.txt)"
    }
    return $TemplateDir
}

function Test-ProjectName {
    param([string]$Name)
    
    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw "Project name cannot be empty"
    }
    
    if ($Name.Length -lt 3) {
        throw "Project name must be at least 3 characters"
    }
    
    if ($Name.Length -gt 50) {
        throw "Project name must be max 50 characters"
    }
    
    if ($Name -cnotmatch '^[a-z0-9\-]+$') {
        throw "Project name must contain only lowercase letters, numbers, and hyphens"
    }
    
    if ($Name -cmatch '^-|-$') {
        throw "Project name cannot start or end with hyphen"
    }
    
    if ($Name -cmatch '--') {
        throw "Project name cannot contain consecutive hyphens"
    }
    
    return $true
}

function Test-ProjectPath {
    param([string]$Path)
    
    if (Test-Path $Path) {
        throw "Directory already exists: $Path (use -Force to overwrite)"
    }
    
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path $parent)) {
        throw "Parent directory does not exist: $parent"
    }
    
    return $true
}

function Test-GitInstalled {
    try {
        & git --version | Out-Null
        return $true
    }
    catch {
        Write-Warning "Git not found in PATH. Git initialization will be skipped."
        return $false
    }
}

# ============================================================================
# User Input Functions
# ============================================================================

function Show-BoardMenu {
    Write-Host ""
    Write-Host "Select target board:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) ESP32          (Dual-core, 520KB SRAM, PSRAM optional)" -ForegroundColor Yellow
    Write-Host "  2) ESP32-S2       (Single-core, 320KB SRAM)" -ForegroundColor Yellow
    Write-Host "  3) ESP32-S3       (Dual-core, 512KB SRAM, PSRAM, USB)" -ForegroundColor Yellow
    Write-Host "  4) ESP32-C3       (Single-core RISC-V, 400KB SRAM)" -ForegroundColor Yellow
    Write-Host "  5) ESP32-C6       (Dual-core RISC-V, 512KB SRAM, PSRAM)" -ForegroundColor Yellow
    Write-Host ""
    
    do {
        $choice = Read-Host "Enter board number (1-5)"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le 5) {
            return [int]$choice
        }
        Write-Host "Invalid input. Enter 1-5." -ForegroundColor Red
    } while ($true)
}

function Get-ProjectName {
    Write-Host ""
    Write-Host "Enter project name (lowercase, numbers, hyphens):" -ForegroundColor Cyan
    
    do {
        $name = Read-Host "Project name"
        try {
            Test-ProjectName $name
            return $name
        }
        catch {
            Write-Host "Invalid: $_" -ForegroundColor Red
        }
    } while ($true)
}

# ============================================================================
# Project Creation
# ============================================================================

function New-ProjectDirectory {
    param(
        [string]$Path,
        [bool]$Force = $false
    )
    
    try {
        if ((Test-Path $Path) -and $Force) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop | Out-Null
        }
        
        New-Item -Path $Path -ItemType Directory -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        throw "Failed to create project directory: $_"
    }
}

function Copy-TemplateFiles {
    param(
        [string]$SourceDir,
        [string]$TargetDir
    )
    
    try {
        # List of files/directories to INCLUDE (whitelist approach - cleaner!)
        $Include = @(
            "src",
            "include",
            "CMakeLists.txt",
            "sdkconfig.defaults",
            "sdkconfig.defaults.esp32",
            "sdkconfig.defaults.esp32s2",
            "sdkconfig.defaults.esp32s3",
            "sdkconfig.defaults.esp32c3",
            "sdkconfig.defaults.esp32c6",
            "idf_component.yml.template",
            "PROJECT.md.template",
            "README.md.template",
            ".agent.md.template",
            ".vscode",
            ".github"
        )
        
        foreach ($item in $Include) {
            $sourcePath = Join-Path $SourceDir $item
            if (Test-Path $sourcePath) {
                $targetPath = Join-Path $TargetDir $item
                Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force -ErrorAction Stop
            }
        }
        
        return $true
    }
    catch {
        throw "Failed to copy template: $_"
    }
}

function Replace-ProjectVariables {
    param(
        [string]$ProjectPath,
        [string]$ProjectName
    )
    
    $files = @(
        "CMakeLists.txt",
        "src/main.c",
        "src/CMakeLists.txt",
        "include/config.h",
        "PROJECT.md.template",
        "README.md.template",
        ".agent.md.template",
        "idf_component.yml.template"
    )
    
    $replaceCount = 0
    $errorCount = 0
    
    foreach ($file in $files) {
        $filePath = Join-Path $ProjectPath $file
        if (Test-Path $filePath) {
            try {
                $content = Get-Content $filePath -Raw -ErrorAction Stop
                $newContent = $content -replace '\$\{PROJECT_NAME\}', $ProjectName
                Set-Content $filePath $newContent -NoNewline -ErrorAction Stop
                $replaceCount++
            }
            catch {
                Write-Warning "Could not update $file : $_"
                $errorCount++
            }
        }
    }
    
    Write-Host "  Replaced variables in $replaceCount files"
    if ($errorCount -gt 0) {
        Write-Warning "$errorCount file(s) could not be updated"
    }
    
    return $replaceCount -gt 0
}

function Rename-TemplateFiles {
    param(
        [string]$ProjectPath
    )
    
    try {
        $renames = @{
            "PROJECT.md.template" = "PROJECT.md"
            "README.md.template" = "README.md"
            ".agent.md.template" = ".agent.md"
            "idf_component.yml.template" = "idf_component.yml"
        }
        
        foreach ($oldName in $renames.Keys) {
            $oldPath = Join-Path $ProjectPath $oldName
            $newPath = Join-Path $ProjectPath $renames[$oldName]
            
            if (Test-Path $oldPath) {
                Rename-Item -Path $oldPath -NewName $renames[$oldName] -Force -ErrorAction Stop
            }
        }
        return $true
    }
    catch {
        Write-Warning "Template file renaming failed: $_"
        return $false
    }
}

function Set-BoardConfig {
    param(
        [string]$ProjectPath,
        [string]$BoardConfigName
    )
    
    try {
        $srcConfig = Join-Path $ProjectPath "sdkconfig.defaults.$BoardConfigName"
        $dstConfig = Join-Path $ProjectPath "sdkconfig"
        
        if (Test-Path $srcConfig) {
            Copy-Item -Path $srcConfig -Destination $dstConfig -Force -ErrorAction Stop
            return $true
        }
        else {
            Write-Warning "Board config not found: $BoardConfigName"
            return $false
        }
    }
    catch {
        throw "Failed to apply board configuration: $_"
    }
}

function Initialize-GitRepository {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [string]$BoardName
    )
    
    if (-not (Test-GitInstalled)) {
        return $false
    }
    
    try {
        Push-Location $ProjectPath -ErrorAction Stop
        
        & git init 2>&1 | Out-Null
        & git config user.email "developer@local" 2>&1 | Out-Null
        & git config user.name "ESP32 Developer" 2>&1 | Out-Null
        
        & git add . 2>&1 | Out-Null
        
        & git commit "--message" "init: Initialize ESP32 project from template" 2>&1 | Out-Null
        
        Pop-Location
        return $true
    }
    catch {
        Pop-Location
        Write-Warning "Git initialization failed: $_"
        return $false
    }
}

# ============================================================================
# Main Execution
# ============================================================================

try {
    Write-Host ""
    Write-Host "ESP32 Project Generator v1.0" -ForegroundColor Cyan
    Write-Host ""
    
    # Validate template
    $TemplateDir = Test-TemplateDirectory
    
    # Set default OutputDirectory if not provided
    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
        $OutputDirectory = $PWD
        
        # Safety check: prevent creating projects inside template directory
        if ($OutputDirectory -eq $TemplateDir) {
            throw "Cannot create project inside template directory. Run from parent directory or specify -OutputDirectory"
        }
    }
    
    # Get board if not provided
    if ($Board -eq 0) {
        $Board = Show-BoardMenu
    }
    
    # Get project name if not provided
    if (-not $ProjectName) {
        $ProjectName = Get-ProjectName
    }
    
    # Validate inputs
    Test-ProjectName $ProjectName | Out-Null
    
    $BoardInfo = $BoardMap[$Board]
    $ProjectPath = Join-Path $OutputDirectory $ProjectName
    
    # Check if project exists (unless -Force)
    if ((Test-Path $ProjectPath) -and -not $Force) {
        throw "Directory already exists: $ProjectPath (use -Force to overwrite)"
    }
    
    # Show summary
    Write-Host "Configuration:" -ForegroundColor Cyan
    Write-Host "  Project:  $ProjectName" -ForegroundColor White
    Write-Host "  Board:    $($BoardInfo.Name)" -ForegroundColor White
    Write-Host "  Location: $ProjectPath" -ForegroundColor White
    Write-Host ""
    
    if (-not $NoConfirm) {
        if (-not (Read-Host "Proceed? (y/n)" -eq "y")) {
            Write-Host "Cancelled"
            exit 0
        }
    }
    
    # Create project
    Write-Host ""
    Write-Host "Creating project..." -ForegroundColor Cyan
    
    New-ProjectDirectory -Path $ProjectPath -Force $Force | Out-Null
    Write-Host "  Project directory created"
    
    Copy-TemplateFiles -SourceDir $TemplateDir -TargetDir $ProjectPath | Out-Null
    Write-Host "  Template files copied"
    
    Replace-ProjectVariables -ProjectPath $ProjectPath -ProjectName $ProjectName | Out-Null
    
    Rename-TemplateFiles -ProjectPath $ProjectPath | Out-Null
    Write-Host "  Template files renamed"
    
    Set-BoardConfig -ProjectPath $ProjectPath -BoardConfigName $BoardInfo.ConfigName | Out-Null
    Write-Host "  Board configuration applied"
    
    if (-not $SkipGit) {
        if (Initialize-GitRepository -ProjectPath $ProjectPath -ProjectName $ProjectName -BoardName $BoardInfo.Name) {
            Write-Host "  Git repository initialized"
        }
    }
    
    # Success
    Write-Host ""
    Write-Host "SUCCESS: Project created!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. cd $ProjectName" -ForegroundColor Yellow
    Write-Host "  2. /build-project" -ForegroundColor Yellow
    Write-Host "  3. /initial-upload" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}

