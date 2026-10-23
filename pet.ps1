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

try {
    if (-not (Test-Path -LiteralPath $timingsPath)) {
        throw "找不到素材：$timingsPath"
    }

    $timings = Get-Content -LiteralPath $timingsPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $baseW = 301
    $baseH = 288
    $winW = [math]::Round($baseW * $Scale)
    $winH = [math]::Round($baseH * $Scale)

    # ---------------------------------------------------------------- window
    $win = New-Object System.Windows.Window
    $win.WindowStyle = [System.Windows.WindowStyle]::None
    $win.AllowsTransparency = $true
    $win.Background = [System.Windows.Media.Brushes]::Transparent
    $win.Topmost = $true
    $win.ShowInTaskbar = $false
    $win.ShowActivated = $false
    $win.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $win.Width = $winW
    $win.Height = $winH
    $win.WindowStartupLocation = [System.Windows.WindowStartupLocation]::Manual
    $win.UseLayoutRounding = $true

    $img = New-Object System.Windows.Controls.Image
    $img.Stretch = [System.Windows.Media.Stretch]::Fill
    [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::NearestNeighbor)
    $win.Content = $img

    # ------------------------------------------------------------- placement
    $statePath = Join-Path $root 'pet-state.json'
    $wa = [System.Windows.SystemParameters]::WorkArea

    $win.Left = $wa.Right - $winW - 70
    $win.Top = $wa.Bottom - $winH - 4

    if (Test-Path -LiteralPath $statePath) {
        try {
            $st = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $st.Left) { $win.Left = [double]$st.Left }
            if ($null -ne $st.Top) { $win.Top = [double]$st.Top }
        } catch { }
    }

    function Clamp-ToScreen {
        $work = [System.Windows.SystemParameters]::WorkArea
        $maxLeft = $work.Right - $win.Width
        $maxTop = $work.Bottom - $win.Height
        if ($win.Left -lt $work.Left) { $win.Left = $work.Left }
        elseif ($win.Left -gt $maxLeft) { $win.Left = $maxLeft }
        if ($win.Top -lt $work.Top) { $win.Top = $work.Top }
        elseif ($win.Top -gt $maxTop) { $win.Top = $maxTop }
    }

    Clamp-ToScreen

    function Save-PetState {
        try {
            $obj = [ordered]@{
                Left = [math]::Round($win.Left, 1)
                Top  = [math]::Round($win.Top, 1)
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

    function Get-AnimationFrames {
        param([string]$key)

        if ($script:frameCache.ContainsKey($key)) {
            return $script:frameCache[$key]
        }

        $list = New-Object System.Collections.ArrayList
        $entries = $timings.$key
        if ($null -eq $entries) { throw "动画不存在：$key" }

        foreach ($f in $entries) {
            $path = Join-Path (Join-Path $assetRoot $key) $f.file
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.UriSource = New-Object System.Uri($path)
            $bmp.EndInit()
            $bmp.Freeze()
            [void]$list.Add([pscustomobject]@{ Img = $bmp; Dur = [int]$f.dur })
        }

        $script:frameCache[$key] = $list
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

        if ($key -eq 'idle' -and $loop) {
            $script:nextVariation = $script:sw.ElapsedMilliseconds + (Get-Random -Minimum 14000 -Maximum 34000)
        }
    }

    function Wake-Pet {
        $script:lastInput = $script:sw.ElapsedMilliseconds
        if ($script:animKey -eq 'sleeping') {
            Set-Animation 'waking' $false 'idle'
        }
    }

    function Update-Animation {
        $now = $script:sw.ElapsedMilliseconds
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

        if ($script:animKey -eq 'idle' -and $script:loop -and $now -ge $script:nextVariation) {
            $pick = @('idle-look', 'idle-spout', 'swim') | Get-Random
            Set-Animation $pick $false 'idle'
            $script:nextVariation = $now + (Get-Random -Minimum 16000 -Maximum 38000)
            return
        }

        if ($script:animKey -ne 'sleeping' -and $script:animKey -ne 'waking' -and
            (($now - $script:lastInput) -gt 180000)) {
            Set-Animation 'sleeping' $true
        }
    }

    function React-Click {
        param([double]$localX, [int]$clickCount)

        $now = $script:sw.ElapsedMilliseconds
        $script:lastInput = $now

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

            $script:pressed = $true
            $script:dragging = $false
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
                Set-Animation 'drag' $true
            }

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
    $miPet.Add_Click({ param($s, $e) $script:lastInput = $script:sw.ElapsedMilliseconds; Set-Animation 'tickle' $false 'idle' })
    $menu.Items.Add($miPet) | Out-Null

    $miHappy = New-Object System.Windows.Controls.MenuItem
    $miHappy.Header = '开心一下'
    $miHappy.Add_Click({ param($s, $e) $script:lastInput = $script:sw.ElapsedMilliseconds; Set-Animation 'happy' $false 'idle' })
    $menu.Items.Add($miHappy) | Out-Null

    $miSleep = New-Object System.Windows.Controls.MenuItem
    $miSleep.Header = '睡一会儿'
    $miSleep.Add_Click({ param($s, $e) Set-Animation 'sleeping' $true })
    $menu.Items.Add($miSleep) | Out-Null

    $miWake = New-Object System.Windows.Controls.MenuItem
    $miWake.Header = '叫醒她'
    $miWake.Add_Click({ param($s, $e) Wake-Pet })
    $menu.Items.Add($miWake) | Out-Null

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
            Set-Animation 'idle' $true
            $timer.Start()
        })

    $win.Add_Closing({
            param($s, $e)
            Save-PetState
            $timer.Stop()
        })

    # --------------------------------------------------------------------- run
    $app = New-Object System.Windows.Application
    $app.ShutdownMode = [System.Windows.ShutdownMode]::OnMainWindowClose
    [void]$app.Run($win)
} catch {
    $_ | Out-String | Set-Content -LiteralPath $errorLog -Encoding UTF8
    throw
}
