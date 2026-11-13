param([string]$State = 'idle')

$dir = Join-Path $env:LOCALAPPDATA 'dafeiyu-pet'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$tool = ''
$file = ''

if ($State -eq 'working' -and [Console]::IsInputRedirected) {
    try {
        $raw = [Console]::In.ReadToEnd()
        if ($raw) {
            $payload = $raw | ConvertFrom-Json
            $tool = [string]$payload.tool_name
            if ($payload.tool_input) {
                $file = [string]$payload.tool_input.file_path
                if (-not $file) { $file = [string]$payload.tool_input.path }
                if (-not $file) { $file = [string]$payload.tool_input.notebook_path }
            }
        }
    } catch { }
}

$obj = [ordered]@{
    state = $State
    ts    = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    cwd   = (Get-Location).Path
    tool  = $tool
    file  = $file
}
$obj | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dir 'claude-status.json') -Encoding UTF8