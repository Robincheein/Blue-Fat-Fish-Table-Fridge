param([string]$State = 'idle')

$dir = Join-Path $env:LOCALAPPDATA 'dafeiyu-pet'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$obj = [ordered]@{
    state = $State
    ts    = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    cwd   = (Get-Location).Path
}
$obj | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dir 'claude-status.json') -Encoding UTF8
