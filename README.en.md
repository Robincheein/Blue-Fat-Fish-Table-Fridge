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
3. For Claude Code status, run `install-claude-hooks.ps1` once and restart Claude Code

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
| Thinking / waiting for first token | Normal face + pixel thought bubble |
| Writing docs (.md / .txt) | Typing/homework pose with a pixel `Aa` overhead |
| Reading web (web_fetch / WebFetch) | Normal face + pixel globe |
| Coding / tools | Typing pose with the animated color `</>` |
| Thinking too long (>45 s) | The thought bubble shows a bowl of rice |
| Even longer (>90 s) | The bubble shows a little fish (slacking off) |
| Turn complete | Happy for about 3 seconds |
| Claude / Codex Girl | Text bubble ("…" / "✓ done"); no animation frames |
| Idle | Back to idle |

Whale Girl switches to the typing pose for writing and coding (the docs variant has the `</>` replaced by `Aa`);
thinking, web and long-thinking states keep her normal face with an overlay.
Claude Code hooks include the tool name and file path in the status file, so `.md` and `.py` are distinguished.

**DSH**: reads the newest `workingActivity.tracker.phase` (`thinking` / `tool` / `idle`) from
`$DSH_HOME/storages/session_projcache/sessions/*.json`. No DSH changes required.

**Claude Code**: run `install-claude-hooks.ps1` once. It backs up and merges the hooks into
`%CLAUDE_CONFIG_DIR%\settings.json`; restart Claude Code afterwards.
The status file is `%LOCALAPPDATA%\dafeiyu-pet\claude-status.json`.

## Launcher mapping

The first context-menu item follows the current skin:

| Skin | Launch | How |
| --- | --- | --- |
| Whale Girl | `dsh` | New Windows Terminal tab in `$launchDir` |
| Claude Girl | `claude` (Claude Code) | Same |
| Codex Girl | ChatGPT desktop app | `shell:AppsFolder\<AUMID>` |

All three targets are auto-detected:

- `dsh` / `claude`: checked on PATH, then the npm global folder (`%APPDATA%\npm`) and common install paths
- ChatGPT desktop app: AUMID discovered via `Get-StartApps`
- If `$launchDir` does not exist, the user's home folder is used

Configuration at the top of `pet.ps1`:

```powershell
$launchDir = 'E:\desktop\CODE'   # falls back if missing
$chatgptAppId = ''               # empty = auto-detect, or set to override
```

Falls back to a PowerShell window when `wt.exe` is unavailable; missing commands show a message box.

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
install-claude-hooks.ps1  # one-shot installer / uninstaller for the hooks
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
