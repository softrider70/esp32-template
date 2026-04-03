#!/usr/bin/env powershell
# /add-webui - Generate Web UI Framework for ESP32 Project

param(
    [string]$ProjectPath = $PWD,
    [switch]$WithWebSocket = $true,
    [switch]$WithAuthentication = $false
)

$ErrorActionPreference = "Stop"

function Test-ProjectValid {
    if (-not (Test-Path "$ProjectPath/CMakeLists.txt")) {
        throw "Not a valid ESP32 project (missing CMakeLists.txt)"
    }
}

function Create-WebUIStructure {
    Write-Host "Creating WebUI directory structure..." -ForegroundColor Cyan
    
    $dirs = @(
        "webui",
        "webui/html",
        "webui/js",
        "webui/css",
        "webui/server"
    )
    
    foreach ($dir in $dirs) {
        New-Item -Path "$ProjectPath/$dir" -ItemType Directory -Force | Out-Null
        Write-Host "  ✓ Created $dir/" -ForegroundColor Green
    }
}

function Create-HTMLFiles {
    Write-Host "Creating HTML templates..." -ForegroundColor Cyan
    
    $index = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ESP32 Dashboard</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>ESP32 Device Control</h1>
            <button id="themeToggle" class="theme-toggle">🌙</button>
        </header>
        
        <main>
            <section id="status" class="card">
                <h2>System Status</h2>
                <div id="statusContent" class="status-grid">
                    <div class="stat">
                        <label>Memory:</label>
                        <span id="memory">--</span>
                    </div>
                    <div class="stat">
                        <label>Uptime:</label>
                        <span id="uptime">--</span>
                    </div>
                    <div class="stat">
                        <label>WiFi:</label>
                        <span id="wifi" class="status-ok">Connected</span>
                    </div>
                </div>
            </section>
            
            <section id="controls" class="card">
                <h2>Device Controls</h2>
                <div class="control-group">
                    <button id="restartBtn" class="btn btn-warning">Restart Device</button>
                    <button id="resetBtn" class="btn btn-danger">Factory Reset</button>
                </div>
            </section>
            
            <section id="settings" class="card">
                <h2>Settings</h2>
                <form id="settingsForm">
                    <div class="form-group">
                        <label for="deviceName">Device Name:</label>
                        <input type="text" id="deviceName" required>
                    </div>
                    <div class="form-group">
                        <label for="updateInterval">Update Interval (s):</label>
                        <input type="number" id="updateInterval" min="1" max="60" value="5">
                    </div>
                    <button type="submit" class="btn btn-primary">Save Settings</button>
                </form>
            </section>
        </main>
    </div>
    
    <script src="js/api.js"></script>
    <script src="js/ws.js"></script>
    <script src="js/app.js"></script>
</body>
</html>
"@
    Set-Content "$ProjectPath/webui/html/index.html" $index -Encoding ASCII
    Write-Host "  ✓ Created webui/html/index.html" -ForegroundColor Green
}

function Create-CSSFiles {
    Write-Host "Creating CSS stylesheets..." -ForegroundColor Cyan
    
    $style = @"
:root {
    --primary: #007bff;
    --secondary: #6c757d;
    --success: #28a745;
    --warning: #ffc107;
    --danger: #dc3545;
    --bg-light: #f8f9fa;
    --bg-dark: #1a1a1a;
    --text-light: #333;
    --text-dark: #eee;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: var(--bg-light);
    color: var(--text-light);
    transition: background 0.3s, color 0.3s;
}

body.dark-mode {
    background: var(--bg-dark);
    color: var(--text-dark);
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
    padding: 20px;
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

body.dark-mode header {
    background: #2a2a2a;
}

.card {
    background: white;
    border-radius: 8px;
    padding: 20px;
    margin-bottom: 20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    transition: transform 0.2s;
}

body.dark-mode .card {
    background: #2a2a2a;
}

.card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

.card h2 {
    margin-bottom: 15px;
    color: var(--primary);
}

.btn {
    padding: 10px 20px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1rem;
    transition: background 0.3s;
}

.btn-primary {
    background: var(--primary);
    color: white;
}

.btn-warning {
    background: var(--warning);
    color: black;
}

.btn-danger {
    background: var(--danger);
    color: white;
}

.btn:hover {
    opacity: 0.9;
}

.status-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 15px;
}

.stat {
    display: flex;
    flex-direction: column;
}

.stat label {
    font-weight: bold;
    margin-bottom: 5px;
    font-size: 0.9rem;
}

.form-group {
    margin-bottom: 15px;
}

.form-group label {
    display: block;
    margin-bottom: 5px;
    font-weight: 500;
}

.form-group input {
    width: 100%;
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 1rem;
}

body.dark-mode .form-group input {
    background: #333;
    color: #eee;
    border-color: #555;
}

.status-ok {
    color: var(--success);
    font-weight: bold;
}

.status-error {
    color: var(--danger);
    font-weight: bold;
}

@media (max-width: 768px) {
    .container {
        padding: 10px;
    }
    
    header {
        flex-direction: column;
        gap: 10px;
    }
    
    .status-grid {
        grid-template-columns: 1fr;
    }
}
"@
    Set-Content "$ProjectPath/webui/css/style.css" $style -Encoding ASCII
    Write-Host "  ✓ Created webui/css/style.css" -ForegroundColor Green
}

function Create-JSFiles {
    Write-Host "Creating JavaScript files..." -ForegroundColor Cyan
    
    $api = @"
// REST API Client
class API {
    constructor(baseUrl = '/api') {
        this.baseUrl = baseUrl;
    }
    
    async get(endpoint) {
        const response = await fetch(`\${this.baseUrl}\${endpoint}`);
        if (!response.ok) throw new Error(`HTTP \${response.status}`);
        return response.json();
    }
    
    async post(endpoint, data) {
        const response = await fetch(`\${this.baseUrl}\${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        if (!response.ok) throw new Error(`HTTP \${response.status}`);
        return response.json();
    }
    
    async getStatus() {
        return this.get('/status');
    }
    
    async saveSettings(settings) {
        return this.post('/config', settings);
    }
    
    async restart() {
        return this.post('/restart', {});
    }
}

const api = new API();
"@
    Set-Content "$ProjectPath/webui/js/api.js" $api -Encoding ASCII
    Write-Host "  ✓ Created webui/js/api.js" -ForegroundColor Green
    
    $app = @"
// Main Application
let updateInterval = 5000;

async function updateStatus() {
    try {
        const status = await api.getStatus();
        document.getElementById('memory').textContent = status.memory;
        document.getElementById('uptime').textContent = status.uptime;
        document.getElementById('wifi').textContent = status.wifi ? 'Connected' : 'Disconnected';
    } catch (e) {
        console.error('Failed to update status:', e);
    }
}

function setupEventListeners() {
    document.getElementById('restartBtn')?.addEventListener('click', async () => {
        if (confirm('Restart device?')) {
            await api.restart();
            setTimeout(() => location.reload(), 2000);
        }
    });
    
    document.getElementById('settingsForm')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const settings = {
            name: document.getElementById('deviceName').value,
            updateInterval: document.getElementById('updateInterval').value
        };
        
        await api.saveSettings(settings);
        alert('Settings saved!');
    });
    
    document.getElementById('themeToggle')?.addEventListener('click', () => {
        document.body.classList.toggle('dark-mode');
        localStorage.setItem('theme', document.body.classList.contains('dark-mode') ? 'dark' : 'light');
    });
}

function loadSavedTheme() {
    if (localStorage.getItem('theme') === 'dark') {
        document.body.classList.add('dark-mode');
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadSavedTheme();
    setupEventListeners();
    updateStatus();
    setInterval(updateStatus, updateInterval);
});
"@
    Set-Content "$ProjectPath/webui/js/app.js" $app -Encoding ASCII
    Write-Host "  ✓ Created webui/js/app.js" -ForegroundColor Green
}

function Create-ServerComponent {
    Write-Host "Creating HTTP server component..." -ForegroundColor Cyan
    
    $server = @"
#include "esp_http_server.h"
#include "esp_spiffs.h"

static httpd_handle_t server = NULL;

static esp_err_t api_status_handler(httpd_req_t *req) {
    const char *response = @"
{
    \"memory\": \"48/204KB\",
    \"uptime\": \"2h 45m\",
    \"wifi\": true
}
"@;
    
    httpd_resp_set_type(req, "application/json");
    httpd_resp_send(req, response, HTTPD_RESP_USE_STRLEN);
    return ESP_OK;
}

static httpd_uri_t api_status_uri = {
    .uri = "/api/status",
    .method = HTTP_GET,
    .handler = api_status_handler,
};

void webui_init(void) {
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.max_uri_handlers = 8;
    
    if (httpd_start(&server, &config) == ESP_OK) {
        httpd_register_uri_handler(server, &api_status_uri);
        ESP_LOGI(TAG, "WebUI Server started on port %d", config.server_port);
    }
}
"@
    Set-Content "$ProjectPath/webui/server/webui_server.c" $server -Encoding ASCII
    Write-Host "  ✓ Created webui/server/webui_server.c" -ForegroundColor Green
}

# Main Execution
try {
    Write-Host ""
    Write-Host "Adding WebUI Framework to $ProjectPath" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-ProjectValid
    Create-WebUIStructure
    Create-HTMLFiles
    Create-CSSFiles
    Create-JSFiles
    Create-ServerComponent
    
    Write-Host ""
    Write-Host "SUCCESS: WebUI Framework added!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Add webui/server/webui_server.c to CMakeLists.txt" -ForegroundColor Yellow
    Write-Host "  2. Include webui/server/webui_server.h in src/main.c" -ForegroundColor Yellow
    Write-Host "  3. Call webui_init() in app_main()" -ForegroundColor Yellow
    Write-Host "  4. Access WebUI at http://esp32.local" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
