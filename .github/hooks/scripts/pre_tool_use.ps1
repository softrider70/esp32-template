$rawInput = [Console]::In.ReadToEnd()

if ([string]::IsNullOrWhiteSpace($rawInput)) {
    Write-Output "{}"
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json -AsHashtable
}
catch {
    Write-Output "{}"
    exit 0
}

$toolName = [string]$payload.tool_name

$allowedPatterns = @(
    '^read$',
    '^search$',
    '^todo$',
    '^agent$',
    '^read_file$',
    '^list_dir$',
    '^file_search$',
    '^grep_search$',
    '^semantic_search$',
    '^manage_todo_list$',
    '^runSubagent$',
    '^search_subagent$',
    '^memory$'
)

function Test-ToolMatch {
    param(
        [string]$Name,
        [string[]]$Patterns
    )

    foreach ($pattern in $Patterns) {
        if ($Name -match $pattern) {
            return $true
        }
    }

    return $false
}

if (Test-ToolMatch -Name $toolName -Patterns $allowedPatterns) {
    $response = @{
        hookSpecificOutput = @{
            hookEventName = 'PreToolUse'
            permissionDecision = 'allow'
            permissionDecisionReason = 'Read-only or coordination tool.'
        }
    }

    $response | ConvertTo-Json -Depth 5 -Compress
    exit 0
}

$reason = 'This workspace uses a minimal-tool default. Switch to a specialist agent or confirm why the stronger tool is necessary.'
$systemMessage = "Tool '$toolName' is outside the lean default set. Prefer Lean Workspace for read-only work, Edit Specialist for file changes, and Terminal Specialist for shell or git tasks."

$response = @{
    systemMessage = $systemMessage
    hookSpecificOutput = @{
        hookEventName = 'PreToolUse'
        permissionDecision = 'ask'
        permissionDecisionReason = $reason
    }
}

$response | ConvertTo-Json -Depth 5 -Compress
exit 0
