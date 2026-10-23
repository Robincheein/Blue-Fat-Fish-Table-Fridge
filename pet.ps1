param(
    [double]$Scale = 0.75
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$root = $PSScriptRoot
$assetRoot = Join-Path $root 'assets'
$timingsPath = Join-Path $assetRoot 'timings.json'
$errorLog = Join-Path $root 'pet-error.log'
$statePath = Join-Path $root 'pet-state.json'

$staticH = [math]::Round(288 * $Scale)

$SKINS = @{
    whale = @{
        Name = '鲸娘'
        Kind = 'anim'
        W    = [math]::Round(301 * $Scale)
        H    = [math]::Round(288 * $Scale)
        ImgH = [math]::Round(288 * $Scale)
    }
    claude = @{
        Name  = 'Claude 娘'
        Kind  = 'static'
        W     = $staticH
        H     = $staticH + 24
        ImgH  = $staticH
        Idle  = 'claude-girl\claude-girl.png'
        Happy = 'claude-girl\claude-girl-happy.png'
        Blink = 'claude-girl\claude-girl-blink.png'
    }
    codex = @{
        Name  = 'Codex 娘'
        Kind  = 'static'
        W     = $staticH
        H     = $staticH + 24
        ImgH  = $staticH
        Idle  = 'codex-girl\codex-girl.png'
        Happy = 'codex-girl\codex-girl-happy.png'
        Blink = 'codex-girl\codex-girl-blink.png'
    }
}

$LINES = @{
    whale  = @('咕噜咕噜…', '今天想写点什么？', '别戳我，痒。', '好水，好水。', '我的上下文有一百万 token 喔')
    claude = @('今天想写点什么？', '让我看看这段代码…', '这个 bug 有点意思。', '要一起做点东西吗？', '别戳啦，会分心的。')
    codex  = @('这段我来试试？', '编译过了吗？', '再改一版吧。', '唔…让我想想。', '手速不错嘛。')
}

# --------------------------------------------------------------- saved state
$initialSkin = 'whale'
$saveLeft = $null
$saveTop = $null

if (Test-Path -LiteralPath $statePath) {
    try {
        $st = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -ne $st.Skin -and $SKINS.ContainsKey([string]$st.Skin)) { $initialSkin = [string]$st.Skin }
        if ($null -ne $st.Left) { $saveLeft = [double]$st.Left }
        if ($null -ne $st.Top) { $saveTop = [double]$st.Top }
    } catch { }
}

$script:skin = $initialSkin
$meta0 = $SKINS[$initialSkin]

try {
    if (-not (Test-Path -LiteralPath $timingsPath)) {
        throw "找不到素材：$timingsPath"
    }

    $timings = Get-Content -LiteralPath $timingsPath -Raw -Encoding UTF8 | ConvertFrom-Json

    # ---------------------------------------------------------------- window
    $win = New-Object System.Windows.Window
    $win.WindowStyle = [System.Windows.WindowStyle]::None
    $win.AllowsTransparency = $true
    $win.Background = [System.Windows.Media.Brushes]::Transparent
    $win.Topmost = $true
    $win.ShowInTaskbar = $false
    $win.ShowActivated = $false
    $win.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $win.Width = $meta0.W
    $win.Height = $meta0.H
    $win.WindowStartupLocation = [System.Windows.WindowStartupLocation]::Manual
    $win.UseLayoutRounding = $true

    $grid = New-Object System.Windows.Controls.Grid
    $win.Content = $grid

    $img = New-Object System.Windows.Controls.Image
    $img.Stretch = [System.Windows.Media.Stretch]::Fill
    $img.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $img.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
    [void]$grid.Children.Add($img)

    $fx = New-Object System.Windows.Controls.Canvas
    $fx.IsHitTestVisible = $false
    [void]$grid.Children.Add($fx)
    [System.Windows.Controls.Panel]::SetZIndex($img, 0)
    [System.Windows.Controls.Panel]::SetZIndex($fx, 10)

    $script:scaleT = New-Object System.Windows.Media.ScaleTransform(1, 1)
    $script:rotT = New-Object System.Windows.Media.RotateTransform(0)
    $script:bob = New-Object System.Windows.Media.TranslateTransform(0, 0)
    $script:tf = New-Object System.Windows.Media.TransformGroup
    [void]$script:tf.Children.Add($script:scaleT)
    [void]$script:tf.Children.Add($script:rotT)
    [void]$script:tf.Children.Add($script:bob)
    $img.RenderTransform = $script:tf
    $img.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 1.0)

    # ------------------------------------------------------------ speech popup
    $bubbleBorder = New-Object System.Windows.Controls.Border
    $bubbleBorder.Background = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(245, 6, 14, 30))
    $bubbleBorder.BorderBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(170, 150, 180, 255))
    $bubbleBorder.BorderThickness = New-Object System.Windows.Thickness -ArgumentList 1
    $bubbleBorder.Padding = New-Object System.Windows.Thickness -ArgumentList 9, 6, 9, 6

    $bubbleText = New-Object System.Windows.Controls.TextBlock
    $bubbleText.FontFamily = New-Object System.Windows.Media.FontFamily -ArgumentList 'Microsoft YaHei UI'
    $bubbleText.FontSize = 12
    $bubbleText.Foreground = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(232, 242, 255))
    $bubbleText.Text = ''
    $bubbleBorder.Child = $bubbleText

    $bubble = New-Object System.Windows.Controls.Primitives.Popup
    $bubble.Child = $bubbleBorder
    $bubble.PlacementTarget = $win
    $bubble.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Top
    $bubble.VerticalOffset = -10
    $bubble.HorizontalOffset = 34
    $bubble.AllowsTransparency = $true
    $bubble.StaysOpen = $true
    $bubble.IsHitTestVisible = $false
    $bubble.PopupAnimation = [System.Windows.Controls.Primitives.PopupAnimation]::None

    # ------------------------------------------------------------- heart pixels
    $HEART = @(
        '0110110',
        '2221111',
        '1111111',
        '0111110',
        '0011100',
        '0001000'
    )

    $ZZZ = @(
        '11111',
        '00010',
        '00100',
        '01000',
        '11111'
    )

    $heartBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 95, 143))
    $heartBrush.Freeze()
    $heartLight = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 179, 201))
    $heartLight.Freeze()
    $zzzBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(205, 225, 255))
    $zzzBrush.Freeze()

    function Clamp-ToScreen {
        $work = [System.Windows.SystemParameters]::WorkArea
        $maxLeft = $work.Right - $win.Width
        $maxTop = $work.Bottom - $win.Height
        if ($win.Left -lt $work.Left) { $win.Left = $work.Left }
        elseif ($win.Left -gt $maxLeft) { $win.Left = $maxLeft }
        if ($win.Top -lt $work.Top) { $win.Top = $work.Top }
        elseif ($win.Top -gt $maxTop) { $win.Top = $maxTop }
    }

    # ------------------------------------------------------------- placement
    $wa = [System.Windows.SystemParameters]::WorkArea
    $win.Left = $wa.Right - $win.Width - 70
    $win.Top = $wa.Bottom - $win.Height - 4

    if ($null -ne $saveLeft) { $win.Left = $saveLeft }
    if ($null -ne $saveTop) { $win.Top = $saveTop }
    Clamp-ToScreen

    function Save-PetState {
        try {
            $obj = [ordered]@{
                Left = [math]::Round($win.Left, 1)
                Top  = [math]::Round($win.Top, 1)
                Skin = $script:skin
            }
            $obj | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
        } catch { }
    }

    function Reset-Position {
        $work = [System.Windows.SystemParameters]::WorkArea
        $win.Left = $work.Right - $win.Width - 70
        $win.Top = $work.Bottom - $win.Height - 4
        Clamp-ToScreen
        Save-PetState
    }

    # --------------------------------------------------------------- animation
    $script:sw = [System.Diagnostics.Stopwatch]::StartNew()
    $script:animKey = ''
    $script:frames = $null
    $script:frame = 0
    $script:deadline = 0
    $script:loop = $true
    $script:after = 'idle'
    $script:lastInput = 0
    $script:nextVariation = 14000
    $script:clickTimes = @()
    $script:pressed = $false
    $script:dragging = $false
    $script:dpi = 1.0
    $script:frameCache = @{}

    $script:particles = New-Object System.Collections.ArrayList
    $script:lastFx = 0
    $script:hopY = 0.0
    $script:hopV = 0.0
    $script:shake = 0.0
    $script:sayUntil = 0
    $script:lastSay = 0
    $script:lean = 0.0
    $script:leanV = 0.0
    $script:squash = 0.0
    $script:squashV = 0.0
    $script:dragTilt = 0.0
    $script:wiggle = 0.0
    $script:dozing = $false
    $script:zzzTimer = 0.0
    $script:lastCursor = $null
    $script:nextBlinkTime = 4000
    $script:pendingHappyAt = 0

    function Load-Bitmap {
        param([string]$path)

        $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
        $bmp.BeginInit()
        $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bmp.UriSource = New-Object System.Uri($path)
        $bmp.EndInit()
        $bmp.Freeze()
        return $bmp
    }

    function Get-AnimationFrames {
        param([string]$key)

        $cacheKey = $script:skin + '/' + $key
        if ($script:frameCache.ContainsKey($cacheKey)) {
            return $script:frameCache[$cacheKey]
        }

        $list = New-Object System.Collections.ArrayList
        $meta = $SKINS[$script:skin]

        if ($meta.Kind -eq 'anim') {
            $entries = $timings.$key
            if ($null -eq $entries) { $entries = $timings.'idle' }
            foreach ($f in $entries) {
                $path = Join-Path (Join-Path $assetRoot $key) $f.file
                [void]$list.Add([pscustomobject]@{ Img = (Load-Bitmap $path); Dur = [int]$f.dur })
            }
        } else {
            if ($key -eq 'happy') {
                [void]$list.Add([pscustomobject]@{ Img = (Load-Bitmap (Join-Path $assetRoot $meta.Happy)); Dur = 1600 })
            } elseif ($key -eq 'blink') {
                [void]$list.Add([pscustomobject]@{ Img = (Load-Bitmap (Join-Path $assetRoot $meta.Blink)); Dur = 130 })
            } elseif ($key -eq 'sleep') {
                [void]$list.Add([pscustomobject]@{ Img = (Load-Bitmap (Join-Path $assetRoot $meta.Blink)); Dur = 600000 })
            } else {
                [void]$list.Add([pscustomobject]@{ Img = (Load-Bitmap (Join-Path $assetRoot $meta.Idle)); Dur = 600000 })
            }
        }

        $script:frameCache[$cacheKey] = $list
        return $list
    }

    function Set-Animation {
        param(
            [string]$key,
            [bool]$loop = $true,
            [string]$after = 'idle'
        )

        $frames = Get-AnimationFrames $key
        $script:animKey = $key
        $script:frames = $frames
        $script:frame = 0
        $script:loop = $loop
        $script:after = $after
        $img.Source = $frames[0].Img
        $script:deadline = $script:sw.ElapsedMilliseconds + $frames[0].Dur

        if ($key -eq 'idle' -and $loop -and $SKINS[$script:skin].Kind -eq 'anim') {
            $script:nextVariation = $script:sw.ElapsedMilliseconds + (Get-Random -Minimum 14000 -Maximum 34000)
        }
    }

    function Apply-Skin {
        param([string]$key, [bool]$resize = $true)

        if (-not $SKINS.ContainsKey($key)) { $key = 'whale' }
        $meta = $SKINS[$key]

        if ($resize) {
            $oldLeft = $win.Left
            $oldTop = $win.Top
            $oldW = $win.Width
            $oldH = $win.Height

            $win.Width = $meta.W
            $win.Height = $meta.H
            $win.Left = $oldLeft + ($oldW - $meta.W) / 2
            $win.Top = $oldTop + ($oldH - $meta.H)
        }

        $script:skin = $key
        $img.Width = $meta.W
        $img.Height = $meta.ImgH

        $script:hopY = 0.0
        $script:hopV = 0.0
        $script:shake = 0.0
        $script:bob.X = 0
        $script:bob.Y = 0
        $script:lean = 0.0
        $script:leanV = 0.0
        $script:squash = 0.0
        $script:squashV = 0.0
        $script:dragTilt = 0.0
        $script:wiggle = 0.0
        $script:dozing = $false
        $script:zzzTimer = 0.0
        $script:nextBlinkTime = [math]::Round(4000 + (Get-Random -Minimum 0 -Maximum 3000))
        $script:pendingHappyAt = 0
        $img.Opacity = 1.0
        $script:sayUntil = 0
        $bubble.IsOpen = $false
        [void]$fx.Children.Clear()
        $script:particles.Clear()

        if ($meta.Kind -eq 'anim') {
            [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::NearestNeighbor)
        } else {
            [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        }

        Clamp-ToScreen
        Set-Animation 'idle' $true

        if ($resize) { Save-PetState }
    }

    function Wake-Pet {
        $script:lastInput = $script:sw.ElapsedMilliseconds
        if ($script:animKey -eq 'sleeping') {
            Set-Animation 'waking' $false 'idle'
        }
        if ($script:dozing) { Wake-Dozing }
    }

    function Wake-Dozing {
        $script:dozing = $false
        $script:zzzTimer = 0.0
        $script:pendingHappyAt = 0
        $img.Opacity = 1.0
        Set-Animation 'idle' $true
        $script:lean = 0.0
        $script:leanV = 0.0
        $script:squash = 0.12
        $script:hopV = -150.0
        $script:lastInput = $script:sw.ElapsedMilliseconds
    }

    function Say-Line {
        param([string]$text, [double]$seconds = 2.6)

        $bubbleText.Text = $text
        $bubble.IsOpen = $true
        $script:sayUntil = $script:sw.ElapsedMilliseconds + [int]($seconds * 1000)
    }

    function Say-Random {
        $now = $script:sw.ElapsedMilliseconds
        if (($now - $script:lastSay) -lt 2200) { return }

        $pool = $LINES[$script:skin]
        if ($null -eq $pool) { return }

        $script:lastSay = $now
        Say-Line ([string]($pool | Get-Random))
    }

    function Spawn-PixelArt {
        param(
            [string[]]$pattern,
            $brush,
            $brush2,
            [double]$x,
            [double]$y,
            [double]$vx,
            [double]$vy,
            [double]$maxLife,
            [int]$block = 4
        )

        $parts = New-Object System.Collections.ArrayList

        for ($row = 0; $row -lt $pattern.Count; $row++) {
            $line = $pattern[$row]
            for ($col = 0; $col -lt $line.Length; $col++) {
                if ($line[$col] -eq '0') { continue }

                $px = New-Object System.Windows.Shapes.Rectangle
                $px.Width = $block
                $px.Height = $block
                if ($line[$col] -eq '2' -and $null -ne $brush2) { $px.Fill = $brush2 } else { $px.Fill = $brush }

                [void]$fx.Children.Add($px)
                [System.Windows.Controls.Canvas]::SetLeft($px, $x + $col * $block)
                [System.Windows.Controls.Canvas]::SetTop($px, $y + $row * $block)

                [void]$parts.Add([pscustomobject]@{
                    R  = $px
                    OX = $col * $block
                    OY = $row * $block
                })
            }
        }

        [void]$script:particles.Add([pscustomobject]@{
            Parts = $parts
            X     = $x
            Y     = $y
            VX    = $vx
            VY    = $vy
            Life  = 0
            Max   = $maxLife
        })
    }

    function Spawn-Heart {
        param([double]$x, [double]$y)
        Spawn-PixelArt -pattern $HEART -brush $heartBrush -brush2 $heartLight -x $x -y $y -vx (Get-Random -Minimum -14 -Maximum 15) -vy (Get-Random -Minimum -62 -Maximum -36) -maxLife (Get-Random -Minimum 1000 -Maximum 1600) -block 4
    }

    function Spawn-Zzz {
        param([double]$x, [double]$y)
        Spawn-PixelArt -pattern $ZZZ -brush $zzzBrush -brush2 $null -x $x -y $y -vx (Get-Random -Minimum -6 -Maximum 7) -vy -28 -maxLife (Get-Random -Minimum 1400 -Maximum 1900) -block 3
    }

    function Update-Particles {
        param([double]$dt)

        for ($i = $script:particles.Count - 1; $i -ge 0; $i--) {
            $p = $script:particles[$i]
            $p.Life += $dt * 1000

            if ($p.Life -ge $p.Max) {
                foreach ($part in $p.Parts) { [void]$fx.Children.Remove($part.R) }
                $script:particles.RemoveAt($i)
                continue
            }

            $p.X += $p.VX * $dt
            $p.Y += $p.VY * $dt
            $alpha = 1 - ($p.Life / $p.Max)

            foreach ($part in $p.Parts) {
                [System.Windows.Controls.Canvas]::SetLeft($part.R, $p.X + $part.OX)
                [System.Windows.Controls.Canvas]::SetTop($part.R, $p.Y + $part.OY)
                $part.R.Opacity = $alpha
            }
        }
    }

    function Invoke-StaticReaction {
        param([bool]$big = $false)

        Set-Animation 'happy' $false 'idle'

        $hop = -140.0
        $count = 3
        if ($big) { $hop = -190.0; $count = 6 }

        $script:hopV = $hop
        $script:shake = if ($big) { 1.4 } else { 1.0 }

        $slots = @(48, 92, 136)
        for ($i = 0; $i -lt $count; $i++) {
            $sx = $slots[$i % 3] + (Get-Random -Minimum -6 -Maximum 7)
            $sy = 14 + (Get-Random -Minimum 0 -Maximum 14)
            Spawn-Heart $sx $sy
        }

        Say-Random
    }

    function Update-Animation {
        $now = $script:sw.ElapsedMilliseconds

        $dt = 0.03
        if ($script:lastFx -gt 0) { $dt = [math]::Min(0.06, ($now - $script:lastFx) / 1000.0) }
        $script:lastFx = $now

        $bobY = 0
        if ($SKINS[$script:skin].Kind -eq 'static' -and -not $script:dragging) {
            $bobY = -2.4 * (0.5 + 0.5 * [math]::Sin($script:sw.Elapsed.TotalSeconds * 1.8))
        }

        if ($script:dozing) {
            $script:lean += (0.0 - $script:lean) * [math]::Min(1.0, $dt * 4.0)
            $script:leanV = 0.0
            $script:zzzTimer -= $dt
            if ($script:zzzTimer -le 0) {
                $script:zzzTimer = 1.7
                Spawn-Zzz (148 + (Get-Random -Minimum -10 -Maximum 11)) (26 + (Get-Random -Minimum 0 -Maximum 12))
            }
            $img.Opacity = 0.92
        } elseif ($script:wiggle -gt 0) {
            $script:wiggle = [math]::Max(0.0, $script:wiggle - $dt)
            $script:lean = [math]::Sin(($now / 1000.0) * 42.0) * 9.0 * ($script:wiggle / 0.9)
            $script:leanV = 0.0
        } elseif ($script:dragging) {
            $script:lean += (0.0 - $script:lean) * [math]::Min(1.0, $dt * 10.0)
            $script:leanV = 0.0
        } else {
            $script:leanV += (-150.0 * $script:lean - 11.0 * $script:leanV) * $dt
            $script:lean += $script:leanV * $dt
            if ($SKINS[$script:skin].Kind -eq 'static') { $img.Opacity = 1.0 }
        }

        $script:squashV += (-190.0 * $script:squash - 13.0 * $script:squashV) * $dt
        $script:squash += $script:squashV * $dt
        $script:scaleT.ScaleY = 1.0 + $script:squash
        $script:scaleT.ScaleX = 1.0 - $script:squash * 0.55

        if ($script:hopV -ne 0 -or $script:hopY -ne 0) {
            $script:hopY += $script:hopV * $dt
            $script:hopV += 900.0 * $dt
            if ($script:hopY -ge 0) { $script:hopY = 0.0; $script:hopV = 0.0 }
        }

        if ($script:shake -gt 0) { $script:shake = [math]::Max(0.0, $script:shake - $dt * 4.0) }
        $shakeX = [math]::Sin(($now / 1000.0) * 55.0) * 7.0 * $script:shake

        $script:bob.X = $shakeX + $script:lean
        $script:bob.Y = $bobY + $script:hopY

        Update-Particles $dt

        if ($script:sayUntil -gt 0 -and $now -gt $script:sayUntil) {
            $script:sayUntil = 0
            $bubble.IsOpen = $false
        }

        if ($script:pendingHappyAt -gt 0 -and $now -ge $script:pendingHappyAt) {
            $script:pendingHappyAt = 0
            Set-Animation 'happy' $false 'idle'
        }

        if ($SKINS[$script:skin].Kind -eq 'static' -and -not $script:dozing -and -not $script:dragging -and
            $script:animKey -eq 'idle' -and $now -ge $script:nextBlinkTime) {
            $script:nextBlinkTime = $now + (Get-Random -Minimum 4200 -Maximum 9200)
            Set-Animation 'blink' $false 'idle'
        }

        if ($null -eq $script:frames) { return }

        if ($now -ge $script:deadline) {
            $script:frame++
            if ($script:frame -ge $script:frames.Count) {
                if ($script:loop) {
                    $script:frame = 0
                } else {
                    Set-Animation $script:after $true
                    return
                }
            }
            $f = $script:frames[$script:frame]
            $img.Source = $f.Img
            $script:deadline = $now + $f.Dur
        }

        $now = $script:sw.ElapsedMilliseconds

        if ($SKINS[$script:skin].Kind -eq 'anim' -and
            $script:animKey -eq 'idle' -and $script:loop -and $now -ge $script:nextVariation) {
            $pick = @('idle-look', 'idle-spout', 'swim') | Get-Random
            Set-Animation $pick $false 'idle'
            $script:nextVariation = $now + (Get-Random -Minimum 16000 -Maximum 38000)
            return
        }

        if ($SKINS[$script:skin].Kind -eq 'anim' -and
            $script:animKey -ne 'sleeping' -and $script:animKey -ne 'waking' -and
            (($now - $script:lastInput) -gt 180000)) {
            Set-Animation 'sleeping' $true
        }

        if ($SKINS[$script:skin].Kind -eq 'static' -and -not $script:dozing -and
            (($now - $script:lastInput) -gt 180000)) {
            $script:dozing = $true
            $script:zzzTimer = 0.2
            Set-Animation 'sleep' $true
            Say-Line 'Zzz…' 3
        }
    }

    function React-Click {
        param([double]$localX, [int]$clickCount)

        $now = $script:sw.ElapsedMilliseconds
        $script:lastInput = $now

        if ($SKINS[$script:skin].Kind -eq 'static') {
            if ($script:dozing) { Wake-Dozing; return }

            $script:clickTimes = @($script:clickTimes | Where-Object { ($now - $_) -lt 1600 })
            $script:clickTimes += $now

            $dir = -1.0
            if ($localX -ge ($win.Width * 0.5)) { $dir = 1.0 }

            if ($script:clickTimes.Count -ge 3) {
                $script:clickTimes = @()
                $script:wiggle = 0.9
                $script:squash = -0.14
                $script:hopV = -130.0
                Invoke-StaticReaction $false
                return
            }

            $big = ($clickCount -ge 2)
            $amp = 7.0
            if ($big) { $amp = 11.0 }
            $script:lean = $dir * $amp
            $script:leanV = 0.0
            $script:squash = -0.12
            Invoke-StaticReaction $big
            if (-not $big) {
                Set-Animation 'blink' $true
                $script:pendingHappyAt = $now + 150
            }
            return
        }

        Say-Random

        $script:clickTimes = @($script:clickTimes | Where-Object { ($now - $_) -lt 1600 })
        $script:clickTimes += $now

        if ($script:clickTimes.Count -ge 3) {
            $script:clickTimes = @()
            Set-Animation 'tickle' $false 'idle'
            return
        }

        if ($clickCount -ge 2) {
            Set-Animation 'smile-hearts' $false 'idle'
            return
        }

        if ($localX -lt ($win.Width * 0.5)) {
            Set-Animation 'poke-left' $false 'idle'
        } else {
            Set-Animation 'poke-right' $false 'idle'
        }
    }

    # ------------------------------------------------------------------ input
    $win.Add_MouseEnter({
            param($s, $e)
            Wake-Pet
        })

    $win.Add_MouseLeftButtonDown({
            param($s, $e)
            $script:lastInput = $script:sw.ElapsedMilliseconds

            if ($script:animKey -eq 'sleeping') {
                Wake-Pet
                return
            }

            if ($script:dozing) {
                Wake-Dozing
                return
            }

            $script:pressed = $true
            $script:dragging = $false
            $script:dragTilt = 0.0
            $script:lastCursor = $null
            $script:hopY = 0.0
            $script:hopV = 0.0
            $script:shake = 0.0
            $script:startCursor = [System.Windows.Forms.Cursor]::Position
            $script:startLeft = $win.Left
            $script:startTop = $win.Top
            [void]$win.CaptureMouse()
        })

    $win.Add_MouseMove({
            param($s, $e)
            if (-not $script:pressed) { return }
            if ([System.Windows.Input.Mouse]::LeftButton -ne [System.Windows.Input.MouseButtonState]::Pressed) { return }

            $cur = [System.Windows.Forms.Cursor]::Position
            $dx = $cur.X - $script:startCursor.X
            $dy = $cur.Y - $script:startCursor.Y

            if (-not $script:dragging) {
                if (([math]::Abs($dx) + [math]::Abs($dy)) -lt 5) { return }
                $script:dragging = $true
                $script:lastCursor = $cur
                Set-Animation 'drag' $true
            }

            $mdx = 0
            if ($null -ne $script:lastCursor) { $mdx = $cur.X - $script:lastCursor.X }
            $script:lastCursor = $cur
            $script:dragTilt = [math]::Max(-13.0, [math]::Min(13.0, -$mdx * 1.1))

            $win.Left = $script:startLeft + ($dx / $script:dpi)
            $win.Top = $script:startTop + ($dy / $script:dpi)
            Clamp-ToScreen
            $script:lastInput = $script:sw.ElapsedMilliseconds
        })

    $win.Add_MouseLeftButtonUp({
            param($s, $e)
            if (-not $script:pressed) { return }

            $script:pressed = $false
            [void]$win.ReleaseMouseCapture()

            if ($script:dragging) {
                $script:dragging = $false
                $script:dragTilt = 0.0
                $script:lastCursor = $null
                Save-PetState
                Set-Animation 'idle' $true
                return
            }

            React-Click ($e.GetPosition($win).X) $e.ClickCount
        })

    # ------------------------------------------------------------ context menu
    $menu = New-Object System.Windows.Controls.ContextMenu

    $miPet = New-Object System.Windows.Controls.MenuItem
    $miPet.Header = '摸摸头'
    $miPet.Add_Click({
            param($s, $e)
            $script:lastInput = $script:sw.ElapsedMilliseconds
            if ($SKINS[$script:skin].Kind -eq 'static') {
                Invoke-StaticReaction $false
            } else {
                Set-Animation 'tickle' $false 'idle'
                Say-Random
            }
        })
    $menu.Items.Add($miPet) | Out-Null

    $miHappy = New-Object System.Windows.Controls.MenuItem
    $miHappy.Header = '开心一下'
    $miHappy.Add_Click({
            param($s, $e)
            $script:lastInput = $script:sw.ElapsedMilliseconds
            if ($SKINS[$script:skin].Kind -eq 'static') {
                Invoke-StaticReaction $true
            } else {
                Set-Animation 'happy' $false 'idle'
                Say-Random
            }
        })
    $menu.Items.Add($miHappy) | Out-Null

    $miSleep = New-Object System.Windows.Controls.MenuItem
    $miSleep.Header = '睡一会儿'
    $miSleep.Add_Click({
            param($s, $e)
            if ($SKINS[$script:skin].Kind -eq 'static') {
                $script:dozing = $true
                $script:zzzTimer = 0.2
                Set-Animation 'sleep' $true
                Say-Line 'Zzz…' 3
            } else {
                Set-Animation 'sleeping' $true
            }
        })
    $menu.Items.Add($miSleep) | Out-Null

    $miWake = New-Object System.Windows.Controls.MenuItem
    $miWake.Header = '叫醒她'
    $miWake.Add_Click({ param($s, $e) Wake-Pet })
    $menu.Items.Add($miWake) | Out-Null

    $miSkin = New-Object System.Windows.Controls.MenuItem
    $miSkin.Header = '换形象'
    foreach ($k in @('whale', 'claude', 'codex')) {
        $mi = New-Object System.Windows.Controls.MenuItem
        $mi.Header = $SKINS[$k].Name
        $mi.Tag = $k
        $mi.IsCheckable = $true
        $mi.IsChecked = ($k -eq $script:skin)
        $mi.Add_Click({
                param($s, $e)
                Apply-Skin ([string]$s.Tag) $true
                Update-SkinMenu
            })
        [void]$miSkin.Items.Add($mi)
    }
    $menu.Items.Add($miSkin) | Out-Null

    $menu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $miReset = New-Object System.Windows.Controls.MenuItem
    $miReset.Header = '回到右下角'
    $miReset.Add_Click({ param($s, $e) Reset-Position })
    $menu.Items.Add($miReset) | Out-Null

    $miQuit = New-Object System.Windows.Controls.MenuItem
    $miQuit.Header = '退出'
    $miQuit.Add_Click({ param($s, $e) Save-PetState; $win.Close() })
    $menu.Items.Add($miQuit) | Out-Null

    $win.ContextMenu = $menu

    function Update-SkinMenu {
        foreach ($item in $miSkin.Items) {
            $item.IsChecked = ([string]$item.Tag -eq $script:skin)
        }
        $miSleep.IsEnabled = $true
        $miWake.IsEnabled = $true
    }

    # ------------------------------------------------------------------- timer
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(30)
    $timer.Add_Tick({ param($s, $e) Update-Animation })

    $win.Add_Loaded({
            param($s, $e)
            try {
                $script:dpi = [double][System.Windows.Media.VisualTreeHelper]::GetDpi($win).DpiScaleX
            } catch {
                $script:dpi = 1.0
            }
            Clamp-ToScreen
            $timer.Start()
        })

    $win.Add_Closing({
            param($s, $e)
            Save-PetState
            $timer.Stop()
        })

    Apply-Skin $initialSkin $false
    Update-SkinMenu

    # --------------------------------------------------------------------- run
    $app = New-Object System.Windows.Application
    $app.ShutdownMode = [System.Windows.ShutdownMode]::OnMainWindowClose
    [void]$app.Run($win)
} catch {
    $_ | Out-String | Set-Content -LiteralPath $errorLog -Encoding UTF8
    throw
}
