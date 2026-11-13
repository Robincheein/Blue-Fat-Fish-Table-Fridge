param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot
$statusScript = Join-Path $repo 'claude-status.ps1'
$configDir = $env:CLAUDE_CONFIG_DIR
if (-not $configDir) { $configDir = Join-Path $env:USERPROFILE '.claude' }
$settingsPath = Join-Path $configDir 'settings.json'

if (-not (Test-Path -LiteralPath $settingsPath)) {
    Write-Host "找不到 $settingsPath —— 请先安装并运行一次 Claude Code。"
    exit 1
}

$backup = "$settingsPath.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
Copy-Item -LiteralPath $settingsPath -Destination $backup -Force

$json = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($Uninstall) {
    if ($json.PSObject.Properties.Name -contains 'hooks') {
        $json.PSObject.Properties.Remove('hooks')
    }
    Write-Host '已移除 Claude Code hooks。'
} else {
    $cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $statusScript + '" '
    $hooks = [ordered]@{
        UserPromptSubmit = @(@{ hooks = @(@{ type = 'command'; command = $cmd + 'thinking' }) })
        PreToolUse       = @(@{ matcher = '*'; hooks = @(@{ type = 'command'; command = $cmd + 'working' }) })
        Notification     = @(@{ hooks = @(@{ type = 'command'; command = $cmd + 'thinking' }) })
        Stop             = @(@{ hooks = @(@{ type = 'command'; command = $cmd + 'done' }) })
        SessionEnd       = @(@{ hooks = @(@{ type = 'command'; command = $cmd + 'idle' }) })
    }
    $json | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]$hooks) -Force
    Write-Host '已写入 Claude Code hooks。'
}

$text = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($settingsPath, $text, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("settings: " + $settingsPath)
Write-Host ("backup:   " + $backup)
Write-Host '重启 Claude Code 后生效。'
