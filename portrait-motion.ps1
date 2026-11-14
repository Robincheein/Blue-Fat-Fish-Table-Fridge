# Procedural movement fallback; preserves original character artwork.
# Dedicated frame art can replace it later without changing action dispatch.
function Get-PortraitMotion {
    param([string]$Key, [double]$ElapsedMs)
    $t = [math]::Max(0, $ElapsedMs) / 1000
    $x = 0; $y = 0
    switch -Regex ($Key) {
        '^(typing|typing-homework|building|conducting)$' { $x = [math]::Sin($t * 12); $y = -[math]::Abs([math]::Sin($t * 9)) * 2; break }
        '^(poke-left)$' { $x = 5 * [math]::Exp(-$t * 2); break }
        '^(poke-right)$' { $x = -5 * [math]::Exp(-$t * 2); break }
        '^(tickle|error)$' { $x = 3 * [math]::Sin($t * 24); break }
        '^(happy|smile-hearts|thumbs-up|notification)$' { $y = -5 * [math]::Abs([math]::Sin($t * 5)); break }
        '^(sleeping|doze|eyes-close|eyes-closed)$' { $y = 1 + [math]::Sin($t * 0.9); break }
        '^(waking|wakeup)$' { $y = -4 * [math]::Abs([math]::Sin($t * 4)) * [math]::Exp(-$t); break }
        '^(drag|carrying)$' { $x = 2 * [math]::Sin($t * 6); $y = -2; break }
        '^(swim|idle-look|idle-spout|music)$' { $x = 2 * [math]::Sin($t * 2); $y = -2 * [math]::Abs([math]::Sin($t * 2)); break }
        default { $y = -2 * (0.5 + 0.5 * [math]::Sin($t * 1.8)) }
    }
    return @{ X = [int][math]::Round($x); Y = [int][math]::Round($y) }
}
