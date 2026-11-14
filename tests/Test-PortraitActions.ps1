$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
$root=Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'portrait-actions.ps1')
. (Join-Path $root 'portrait-motion.ps1')
$tokens=$null; $errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'pet.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw ($errors|Out-String)}
$Scale=0.75; $staticH=184
$skinsAssignment=$ast.FindAll({param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$SKINS'},$true)[0]
Invoke-Expression $skinsAssignment.Extent.Text
foreach($name in @('Load-Bitmap','Get-AnimationFrames','Set-Animation','Update-Animation')) {
    $fn=$ast.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)[0]
    Invoke-Expression $fn.Extent.Text
}
$assetRoot=Join-Path $root 'assets'
$timings=Get-Content (Join-Path $assetRoot 'timings.json') -Raw|ConvertFrom-Json
$script:sw=[Diagnostics.Stopwatch]::StartNew()
$img=New-Object System.Windows.Controls.Image
$script:bob=New-Object System.Windows.Media.TranslateTransform
$script:agentState='working'; $script:dragging=$false
$results=@()
foreach($skin in @('kimi','minimax','claude','codex')) {
    $script:skin=$skin; $script:frameCache=@{}
    foreach($key in $timings.PSObject.Properties.Name) {
        $frames=@(Get-AnimationFrames $key)
        if(!$frames.Count){throw "Missing frames: $skin/$key"}
        foreach($f in $frames){if($f.Dur -le 0 -or !$f.Img.IsFrozen){throw "Invalid frame: $skin/$key"}}
        foreach($time in @(0,120,500,2000,5000)) {
            $m=Get-PortraitMotion $key $time
            if($m.X -isnot [int] -or $m.Y -isnot [int] -or [math]::Abs($m.X) -gt 5 -or [math]::Abs($m.Y) -gt 5){throw 'Invalid pixel motion'}
        }
    }
    foreach($pair in @(@('thinking','thinking'),@('typing','working'),@('sleeping','sleeping'),@('happy','happy'))) {
        $spec=@(Get-PortraitFrameSpec $skin $pair[0] $assetRoot)
        if([IO.Path]::GetFileName($spec[0].Path) -ne ($skin+'-girl-'+$pair[1]+'.png')){throw "Wrong state image: $skin/$($pair[0])"}
    }
    Set-Animation 'happy' $false 'idle'
    $script:deadline=0
    Update-Animation
    if($script:animKey -ne 'idle'){throw "Happy stuck: $skin"}
    Set-Animation 'waking' $false 'idle'
    $script:deadline=0; Update-Animation
    if($script:frame -ne 1){throw "Wake transition skipped: $skin"}
    $script:deadline=0; Update-Animation
    if($script:animKey -ne 'idle'){throw "Wake stuck: $skin"}
    $results+=@{skin=$skin;actions=@($timings.PSObject.Properties.Name).Count;happyReturnsIdle=$true;wakeReturnsIdle=$true}
}
$results|ConvertTo-Json|Set-Content (Join-Path $root 'docs/portrait-runtime-checks.json') -Encoding UTF8
$results|ConvertTo-Json
