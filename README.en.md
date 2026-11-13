# Blue Fat Fish Desktop Pet

[中文](README.md) · English

---

A Windows desktop pet for the pixel mascots bundled with DSH. Pure PowerShell + WPF (.NET Framework), no third-party dependencies, self-contained in one folder.

Three characters: **Whale Girl** (22 animations, 267 frames), **Claude Girl**, and **Codex Girl** (static portraits with a happy expression).

## Features

- Transparent, borderless, always-on-top window; no taskbar entry
- Click / multi-click / drag / right-click menu interactions
- Skin switching (Whale / Claude / Codex), remembered between launches
- Screen-edge clamping and position memory
- Live agent status: DSH sessions and Claude Code thinking / tool / done states
- Launcher: starts `dsh`, Claude Code (`claude`), or the ChatGPT desktop app based on the current skin

## Quick start

**Requirements**: Windows 10/11, Windows PowerShell 5.1 (built in), .NET Framework 4.7+ (WPF, built in).

1. Clone or download this repository
2. Double-click `launch.vbs`

The 267 sprite frames load in about a second.

## Interactions

| Action | Reaction |
| --- | --- |
| Click left / right | Whale Girl dodges (poke-left / poke-right); Claude / Codex Girl switch to the happy face |
| Triple-click within 1.6 s | Whale Girl gets ticklish |
| Double-click | Whale Girl's heart reaction |
| Drag | Picks her up; release to drop |
| Drag to a screen edge | Clamped to the work area, cannot be lost off-screen |
| Right-click | Launch / pet / cheer up / sleep / wake / change skin / reset position / quit |
| Idle for 3 minutes | Whale Girl dozes off (static skins have no sleep frames) |

## Agent status

| State | Pet |
| --- | --- |
| Thinking / waiting for first token | Whale Girl keeps her normal face and shows a pixel thought bubble |
| Tool use / coding | Whale Girl keeps her normal face and shows a pixel `</>` marker |
| Turn complete | Whale Girl switches to happy for about 3 seconds |
| Claude / Codex Girl | No pixel bubble assets, so a text bubble shows "…" or "✓ done" |
| Idle | Back to idle |

Whale Girl keeps her normal expression during thinking / tool use and only overlays a pixel bubble.

**DSH**: reads the newest `workingActivity.tracker.phase` (`thinking` / `tool` / `idle`) from
`$DSH_HOME/storages/session_projcache/sessions/*.json`. No DSH changes required.

**Claude Code**: hooks write `%LOCALAPPDATA%\dafeiyu-pet\claude-status.json` via the included
`claude-status.ps1`. Merge hooks into `%CLAUDE_CONFIG_DIR%\settings.json` (back it up first):

```json
{
  "hooks": {
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"<repo>\\claude-status.ps1\" thinking" }] }],
    "PreToolUse": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"<repo>\\claude-status.ps1\" working" }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"<repo>\\claude-status.ps1\" done" }] }],
    "SessionEnd": [{ "hooks": [{ "type": "command", "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"<repo>\\claude-status.ps1\" idle" }] }]
  }
}
```

Restart Claude Code afterwards.

## Launcher mapping

The first context-menu item follows the current skin:

| Skin | Launch | How |
| --- | --- | --- |
| Whale Girl | `dsh` | New Windows Terminal tab in `$launchDir` |
| Claude Girl | `claude` (Claude Code) | Same |
| Codex Girl | ChatGPT desktop app | `shell:AppsFolder\<AUMID>` |

Configuration at the top of `pet.ps1`:

```powershell
$launchDir = 'E:\desktop\CODE'
$chatgptAppId = 'OpenAI.Codex_2p2nqsd0c76g0!App'
```

The AUMID is machine-specific; find yours with
`Get-StartApps | Where-Object Name -like '*ChatGPT*'`.
Falls back to a PowerShell window when `wt.exe` is unavailable; failures show a message box.

## Skins

Right-click → **Change skin**. The choice is stored in `pet-state.json`.

| Skin | Notes |
| --- | --- |
| Whale Girl | Full animation set: idle, blink, poke, tickle, drag, sleep, happy |
| Claude Girl | Orange palette, normal + happy portraits |
| Codex Girl | White/lavender cat ears, normal + happy portraits |

## Layout

```
pet.ps1            # the pet (PowerShell + WPF)
launch.vbs         # windowless launcher
claude-status.ps1  # status writer used by Claude Code hooks
assets/            # 267 whale frames + Claude / Codex portraits
README.md
```

`pet-state.json` (position / skin) is generated at runtime and ignored by git.

## Tags

- `v3-status` — agent status integration (current)
- `v2-launcher` — multi-skin + launcher
- `v1-original` — original whale-only build + screen clamping
- `experiments` — hearts / procedural animation / blink-frame experiment

Restore a tag's files with `git checkout <tag> -- .`

## Credits

Character assets come from the DSH bundle (`@deepseek-harness-tui/dsh-tui/assets`); the characters and
artwork belong to their original authors. This is an unofficial fan project for personal desktop use.
