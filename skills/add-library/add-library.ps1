#!/usr/bin/env powershell
# /add-library - Component Registry Integration

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$ComponentName,
    
    [string]$Version = "latest",
    [switch]$List = $false,
    [switch]$Resolve = $false
)

$ErrorActionPreference = "Stop"

function Test-ProjectValid {
    if (-not (Test-Path "idf_component.yml")) {
        throw "Not a valid ESP project (missing idf_component.yml)"
    }
}

function Show-AvailableComponents {
    Write-Host "Popular ESP-IDF Components:" -ForegroundColor Cyan
    Write-Host ""
    
    $components = @(
        @{Name="mqtt"; Desc="MQTT Client Library"; Ver="1.4.0"},
        @{Name="esp_wifi"; Desc="WiFi Management"; Ver="1.2.0"},
        @{Name="esp_http_client"; Desc="HTTP Client"; Ver="1.0.0"},
        @{Name="json"; Desc="cJSON Parser"; Ver="2.0.0"},
        @{Name="littlefs"; Desc="LittleFS FileSystem"; Ver="1.3.0"},
        @{Name="esp_ble_mesh"; Desc="BLE Mesh Stack"; Ver="1.0.0"},
        @{Name="sdmmc"; Desc="SD Card Interface"; Ver="1.0.0"},
        @{Name="lvgl"; Desc="LVGL Graphics Lib"; Ver="8.2.0"}
    )
    
    foreach ($comp in $components) {
        Write-Host "  $($comp.Name -PadRight 20) - $($comp.Desc) (v$($comp.Ver))" -ForegroundColor Green
    }
}

function Add-ComponentDependency {
    param(
        [string]$Name,
        [string]$Ver
    )
    
    Write-Host "Adding $Name (v$Ver) to idf_component.yml..." -ForegroundColor Cyan
    
    $content = Get-Content "idf_component.yml" -Raw
    
    if ($content -match "dependencies:") {
        # Dependency section exists
        $newDep = @"
  $Name`:
    version: "$Ver"
    registry: "esp-idf"
"@
        
        # Find the last dependency and add after it
        $content = $content -replace "(dependencies:.*?)(\n[a-z]|\Z)", "`$1$newDep`$2"
    } else {
        # Create dependencies section
        $newDep = @"

dependencies:
  $Name`:
    version: "$Ver"
    registry: "esp-idf"
"@
        $content += $newDep
    }
    
    Set-Content "idf_component.yml" $content -NoNewline
    Write-Host "  ✓ Added dependency for $Name" -ForegroundColor Green
}

function Resolve-Dependencies {
    Write-Host "Resolving component dependencies..." -ForegroundColor Cyan
    
    if (Test-Path ".idf_component_resolved") {
        Remove-Item ".idf_component_resolved"
    }
    
    Write-Host "  ✓ Dependencies resolved" -ForegroundColor Green
    Write-Host "  Run 'idf.py build' to download components" -ForegroundColor Yellow
}

# Main Execution
try {
    Write-Host ""
    Write-Host "ESP-IDF Component Manager" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-ProjectValid
    
    if ($List) {
        Show-AvailableComponents
        exit 0
    }
    
    if ($Resolve) {
        Resolve-Dependencies
        exit 0
    }
    
    if ([string]::IsNullOrEmpty($ComponentName)) {
        Write-Host "Usage: /add-library COMPONENT_NAME [OPTIONS]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  --version VERSION    Specify version (default: latest)" -ForegroundColor Gray
        Write-Host "  --list               Show available components" -ForegroundColor Gray
        Write-Host "  --resolve            Resolve all dependencies" -ForegroundColor Gray
        Write-Host ""
        Show-AvailableComponents
        exit 1
    }
    
    Add-ComponentDependency -Name $ComponentName -Ver $Version
    
    Write-Host ""
    Write-Host "SUCCESS: Component $ComponentName added!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. idf.py build   (to download and build)" -ForegroundColor Yellow
    Write-Host "  2. Review idf_component.yml changes" -ForegroundColor Yellow
    Write-Host "  3. Include component headers in your code" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
