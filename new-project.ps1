#!/usr/bin/env powershell
# ESP32 Project Generator - Create new project from template
# Usage: .\new-project.ps1 -ProjectName "my-app" -Board 1

param(
    [Parameter(Position = 0)]
    [string]$ProjectName,

    [Parameter(Position = 1)]
    [ValidateRange(1, 5)]
    [int]$Board,

    [string]$OutputDirectory = $PWD,

    [switch]$SkipGit = $false
)

$BoardMap = @{
    1 = @{ Name = "ESP32"; ConfigName = "esp32"; Cores = 2; SRAM = "520KB"; PSRAM = "yes" }
    2 = @{ Name = "ESP32-S2"; ConfigName = "esp32s2"; Cores = 1; SRAM = "320KB"; PSRAM = "no" }
    3 = @{ Name = "ESP32-S3"; ConfigName = "esp32s3"; Cores = 2; SRAM = "512KB"; PSRAM = "yes" }
    4 = @{ Name = "ESP32-C3"; ConfigName = "esp32c3"; Cores = 1; SRAM = "400KB"; PSRAM = "no" }
    5 = @{ Name = "ESP32-C6"; ConfigName = "esp32c6"; Cores = 2; SRAM = "512KB"; PSRAM = "yes" }
}

$TemplateDir = $PSScriptRoot
if (-not (Test-Path (Join-Path $TemplateDir "CMakeLists.txt"))) {
    Write-Host "ERROR: Could not find template directory at $TemplateDir" -ForegroundColor Red
    exit 1
}

# Show board menu if not provided
if ($Board -eq 0) {
    Write-Host ""
    Write-Host "Select target board:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) ESP32          (Dual-core, 520KB SRAM, PSRAM optional)" -ForegroundColor Yellow
    Write-Host "  2) ESP32-S2       (Single-core, 320KB SRAM)" -ForegroundColor Yellow
    Write-Host "  3) ESP32-S3       (Dual-core, 512KB SRAM, PSRAM, USB)" -ForegroundColor Yellow
    Write-Host "  4) ESP32-C3       (Single-core RISC-V, 400KB SRAM)" -ForegroundColor Yellow
    Write-Host "  5) ESP32-C6       (Dual-core RISC-V, 512KB SRAM, PSRAM)" -ForegroundColor Yellow
    Write-Host ""
    $Board = Read-Host "Enter board number (1-5)"
}

# Get project name if not provided
if (-not $ProjectName) {
    Write-Host ""
    Write-Host "Enter project name (lowercase, numbers, hyphens):" -ForegroundColor Cyan
    $ProjectName = Read-Host "Project name"
}

$BoardInfo = $BoardMap[[int]$Board]
$ProjectPath = Join-Path $OutputDirectory $ProjectName

# Validate
if (Test-Path $ProjectPath) {
    Write-Host ""
    Write-Host "ERROR: Directory already exists: $ProjectPath" -ForegroundColor Red
    exit 1
}

# Show summary
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Project:  $ProjectName" -ForegroundColor White
Write-Host "  Board:    $($BoardInfo.Name)" -ForegroundColor White
Write-Host "  Location: $ProjectPath" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Proceed? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled"
    exit 0
}

# Create project directory
Write-Host ""
Write-Host "Creating project..." -ForegroundColor Cyan
New-Item -Path $ProjectPath -ItemType Directory | Out-Null

# Copy template contents (all except new-project.ps1 and .git)
Write-Host "  Copying template..."
Get-ChildItem -Path $TemplateDir -Force | Where-Object { $_.Name -ne "new-project.ps1" -and $_.Name -ne ".git" } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $ProjectPath -Recurse -Force
}

# Replace project name in files
Write-Host "  Replacing project name..."
$files = @(
    "CMakeLists.txt",
    "src/main.c",
    "src/CMakeLists.txt",
    "include/config.h",
    "idf_component.yml",
    "PROJECT.md.template",
    ".github/copilot-instructions.md"
)

foreach ($file in $files) {
    $filePath = Join-Path $ProjectPath $file
    if (Test-Path $filePath) {
        (Get-Content $filePath) -replace '\$\{PROJECT_NAME\}', $ProjectName | Set-Content $filePath
    }
}

# Setup board config
Write-Host "  Configuring board..."
$srcConfig = Join-Path $ProjectPath "sdkconfig.defaults.$($BoardInfo.ConfigName)"
$dstConfig = Join-Path $ProjectPath "sdkconfig"

if (Test-Path $srcConfig) {
    Copy-Item -Path $srcConfig -Destination $dstConfig -Force
}

# Initialize git
if (-not $SkipGit) {
    Write-Host "  Initializing git..."
    Push-Location $ProjectPath
    
    & git init | Out-Null
    & git config user.email "developer@local" | Out-Null
    & git config user.name "ESP32 Developer" | Out-Null
    
    & git add . | Out-Null
    & git commit -m "init: Initialize ESP32 project from template" | Out-Null
    
    Pop-Location
}

# Show completion
Write-Host ""
Write-Host "SUCCESS: Project created!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. cd $ProjectName" -ForegroundColor Yellow
Write-Host "  2. /build-project" -ForegroundColor Yellow
Write-Host "  3. /initial-upload" -ForegroundColor Yellow
Write-Host ""
