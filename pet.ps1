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

# 启动目标：按当前形象决定
#   鲸娘      -> dsh
#   Claude 娘 -> claude (Claude Code)
#   Codex 娘  -> ChatGPT 桌面版
$launchDir = 'E:\desktop\CODE'
$chatgptAppId = 'OpenAI.Codex_2p2nqsd0c76g0!App'

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
        H     = $staticH + 8
        ImgH  = $staticH
        Idle  = 'claude-girl\claude-girl.png'
        Happy = 'claude-girl\claude-girl-happy.png'
    }
    codex = @{
        Name  = 'Codex 娘'
        Kind  = 'static'
        W     = $staticH
        H     = $staticH + 8
        ImgH  = $staticH
        Idle  = 'codex-girl\codex-girl.png'
        Happy = 'codex-girl\codex-girl-happy.png'
    }
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

    $script:bob = New-Object System.Windows.Media.TranslateTransform(0, 0)
    $img.RenderTransform = $script:bob

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

    function Start-Agent {
        $script:lastInput = $script:sw.ElapsedMilliseconds

        try {
            if ($script:skin -eq 'codex') {
                Start-Process -FilePath "shell:AppsFolder\$chatgptAppId"
                return
            }

            $cmd = 'dsh'
            if ($script:skin -eq 'claude') { $cmd = 'claude' }

            $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
            if ($null -ne $wt) {
                $wtArgs = '-d "' + $launchDir + '" powershell.exe -NoExit -Command "' + $cmd + '"'
                Start-Process -FilePath $wt.Source -ArgumentList $wtArgs
            } else {
                Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit', '-Command', "Set-Location '$launchDir'; $cmd") -WorkingDirectory $launchDir
            }
        } catch {
            [System.Windows.MessageBox]::Show("启动失败：$($_.Exception.Message)", '鲸娘桌宠', 'OK', 'Warning') | Out-Null
        }
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
        $script:bob.Y = 0

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
    }

    function Update-Animation {
        $now = $script:sw.ElapsedMilliseconds

        if ($SKINS[$script:skin].Kind -eq 'static' -and -not $script:dragging) {
            $script:bob.Y = -2.4 * (0.5 + 0.5 * [math]::Sin($script:sw.Elapsed.TotalSeconds * 1.8))
        } else {
            $script:bob.Y = 0
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
    }

    function React-Click {
        param([double]$localX, [int]$clickCount)

        $now = $script:sw.ElapsedMilliseconds
        $script:lastInput = $now

        if ($SKINS[$script:skin].Kind -eq 'static') {
            Set-Animation 'happy' $false 'idle'
            return
        }

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

    $miLaunch = New-Object System.Windows.Controls.MenuItem
    $miLaunch.Header = '启动 DSH'
    $miLaunch.Add_Click({ param($s, $e) Start-Agent })
    $menu.Items.Add($miLaunch) | Out-Null

    $miPet = New-Object System.Windows.Controls.MenuItem
    $miPet.Header = '摸摸头'
    $miPet.Add_Click({
            param($s, $e)
            $script:lastInput = $script:sw.ElapsedMilliseconds
            if ($SKINS[$script:skin].Kind -eq 'static') {
                Set-Animation 'happy' $false 'idle'
            } else {
                Set-Animation 'tickle' $false 'idle'
            }
        })
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
        $miSleep.IsEnabled = ($script:skin -eq 'whale')
        $miWake.IsEnabled = ($script:skin -eq 'whale')

        switch ($script:skin) {
            'claude' { $miLaunch.Header = '启动 Claude Code' }
            'codex'  { $miLaunch.Header = '启动 ChatGPT' }
            default  { $miLaunch.Header = '启动 DSH' }
        }
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
