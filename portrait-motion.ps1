# Procedural movement fallback; preserves original character artwork.
# Dedicated frame art can replace it later without changing action dispatch.
function Get-PortraitMotion {
    param([string]$Key, [double]$ElapsedMs)
    $t = [math]::Max(0, $ElapsedMs) / 1000
    $x = 0; $y = 0
    switch -Regex ($Key) {
        '^(typing|typing-homework|building|conducting)$' { $y = -[math]::Abs([math]::Sin($t * 4)) * 1; break }
        '^(poke-left)$' { $x = 3 * [math]::Exp(-$t * 2); break }
        '^(poke-right)$' { $x = -3 * [math]::Exp(-$t * 2); break }
        '^(tickle|error)$' { $x = 2 * [math]::Sin($t * 18); break }
        '^(happy|smile-hearts|thumbs-up|notification)$' { $y = -3 * [math]::Abs([math]::Sin($t * 5)); break }
        '^(sleeping|doze|eyes-close|eyes-closed)$' { $y = 0.5 + 0.5 * [math]::Sin($t * 0.9); break }
        '^(waking|wakeup)$' { $y = -2 * [math]::Abs([math]::Sin($t * 4)) * [math]::Exp(-$t); break }
        '^(drag|carrying)$' { $x = 1 * [math]::Sin($t * 6); $y = -1; break }
        '^(swim|idle-look|idle-spout|music)$' { $x = 1 * [math]::Sin($t * 2); $y = -1 * [math]::Abs([math]::Sin($t * 2)); break }
        default { $y = -1 * (0.5 + 0.5 * [math]::Sin($t * 1.5)) }
    }
    return @{ X = [int][math]::Round($x); Y = [int][math]::Round($y) }
}