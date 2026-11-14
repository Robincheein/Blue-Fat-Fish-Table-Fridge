function Get-PortraitPoseName {
    param([string]$Key)
    switch -Regex ($Key) {
        '^(happy|smile-hearts|thumbs-up|tickle|notification)$' { return 'happy' }
        '^(thinking|compacting)$' { return 'thinking' }
        '^(typing|typing-homework|building|conducting)$' { return 'working' }
        '^(sleeping|doze|eyes-close|eyes-closed)$' { return 'sleeping' }
        '^waiting$' { return 'waiting' }
        default { return 'idle' }
    }
}

function Get-PortraitFrameSpec {
    param([string]$Skin, [string]$Key, [string]$AssetRoot)
    $pose = Get-PortraitPoseName $Key
    $base = Join-Path $AssetRoot ($Skin + '-girl')
    $idle = Join-Path $base ($Skin + '-girl.png')
    $path = if ($pose -eq 'idle') { $idle } else { Join-Path $base ($Skin + '-girl-' + $pose + '.png') }
    if (!(Test-Path -LiteralPath $path)) {
        if ($pose -eq 'waiting') { $path = Join-Path $base ($Skin + '-girl-thinking.png') }
        if (!(Test-Path -LiteralPath $path)) { $path = $idle }
    }
    if ($Key -in @('waking','wakeup')) {
        # Explicit transition out of the sleeping pose; never stay stuck asleep.
        return @(
            @{Path=(Join-Path $base ($Skin+'-girl-sleeping.png')); Dur=180},
            @{Path=$idle; Dur=500}
        )
    }
    $duration = switch ($Key) {
        'poke-left' { 650 }; 'poke-right' { 650 }; 'tickle' { 1100 }
        'eyes-close' { 250 }; default { 1600 }
    }
    return @(@{Path=$path; Dur=$duration})
}
