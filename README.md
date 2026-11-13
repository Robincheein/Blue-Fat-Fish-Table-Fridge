# 大肥鱼桌宠 / Blue Fat Fish Desktop Pet

DSH 内置像素看板娘的 Windows 桌宠。纯 PowerShell + WPF（.NET Framework）实现，零第三方依赖，单文件夹即可运行。

三位角色：**鲸娘**（22 套、267 帧逐帧动画）、**Claude 娘**、**Codex 娘**（静态立绘 + 开心表情）。

---

## 中文

### 功能

- 透明、无边框、置顶窗口，不占任务栏
- 点击 / 连点 / 拖动 / 右键菜单互动
- 换形象：鲸娘 / Claude 娘 / Codex 娘，选择会记住
- 屏幕四边边界，位置记忆
- 状态联动：DSH 会话、Claude Code 的思考 / 工具 / 完成状态实时映射到宠物
- 启动器：按当前形象启动 `dsh` / `claude`（Claude Code）/ ChatGPT 桌面版

### 快速开始

**要求**：Windows 10 / 11，Windows PowerShell 5.1（系统自带），.NET Framework 4.7+（WPF，系统自带）。

1. 克隆或下载本仓库
2. 双击 `launch.vbs`（无控制台窗口）

素材共 267 帧，首次加载约 1 秒。

### 互动

| 操作 | 反应 |
| --- | --- |
| 点她左边 / 右边 | 鲸娘扭头躲（poke-left / poke-right）；Claude / Codex 娘切开心表情 |
| 1.6 秒内连点 3 下 | 鲸娘怕痒（tickle） |
| 双击 | 鲸娘冒爱心（smile-hearts） |
| 按住拖动 | 拎起来（drag），松手放下 |
| 拖到屏幕边缘 | 被工作区四边挡住，不会跑丢 |
| 右键 | 启动 / 摸摸头 / 开心一下 / 睡一会儿 / 叫醒她 / 换形象 / 回到右下角 / 退出 |
| 3 分钟没动 | 鲸娘打瞌睡（静态形象没有瞌睡动作） |

### 状态联动

| 状态 | 表现 |
| --- | --- |
| 思考 / 等首 token | 鲸娘播放 `thinking` 动画（画面自带像素思考泡泡） |
| 调工具 / 写代码 | 鲸娘播放 `typing` 动画 |
| 一轮完成 | 鲸娘切开心，约 3 秒后回待机 |
| Claude / Codex 娘 | 没有动作帧，用「…」/「✓ 完成」文字气泡表示状态 |
| 空闲 | 回到待机 |

**DSH**：直接读 `$DSH_HOME/storages/session_projcache/sessions/*.json` 里最新的
`workingActivity.tracker.phase`（`thinking` / `tool` / `idle`），不需要改 DSH。

**Claude Code**：用 hooks 写 `%LOCALAPPDATA%\dafeiyu-pet\claude-status.json`，仓库里的
`claude-status.ps1` 就是写入脚本。需要把 hooks 合并进 `%CLAUDE_CONFIG_DIR%\settings.json`（改前请备份）：

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

改完重启 Claude Code 生效。

### 启动映射

右键菜单第一项会跟着当前形象变：

| 形象 | 启动 | 方式 |
| --- | --- | --- |
| 鲸娘 | `dsh` | 新开 Windows Terminal 标签，工作目录 `$launchDir` |
| Claude 娘 | `claude`（Claude Code） | 同上 |
| Codex 娘 | ChatGPT 桌面版 | `shell:AppsFolder\<AUMID>` |

配置在 `pet.ps1` 顶部：

```powershell
$launchDir = 'E:\desktop\CODE'
$chatgptAppId = 'OpenAI.Codex_2p2nqsd0c76g0!App'
```

`$chatgptAppId` 因机器而异，可用 `Get-StartApps | Where-Object Name -like '*ChatGPT*'` 查。
没有 `wt.exe` 时回退到 PowerShell 窗口；启动失败会弹提示框。

### 换形象

右键 → **换形象** 可以在三位之间切换，选择写入 `pet-state.json`，下次启动保持。

| 形象 | 说明 |
| --- | --- |
| 鲸娘 | 完整动画：待机、眨眼、被戳、怕痒、被拎、打瞌睡、开心 |
| Claude 娘 | 橘色系，普通 / 开心两张立绘 |
| Codex 娘 | 白紫猫耳系，普通 / 开心两张立绘 |

### 目录

```
pet.ps1            # 宠物本体（PowerShell + WPF）
launch.vbs         # 无窗口启动器
claude-status.ps1  # Claude Code hooks 的状态写入脚本
assets/            # 鲸娘 267 帧 + Claude / Codex 立绘
README.md
```

`pet-state.json`（位置 / 形象）运行时生成，已加入 `.gitignore`。

### 版本

仓库保留了开发过程中的几个标签：

- `v3-status` —— 状态联动（当前）
- `v2-launcher` —— 多形象 + 启动入口
- `v1-original` —— 最初的鲸娘版 + 屏幕边界
- `experiments` —— 爱心 / 程序动画 / 闭眼帧的实验版

切换某个版本的文件：`git checkout <tag> -- .`

### 素材说明

角色素材来自 DSH 内置资源（`@deepseek-harness-tui/dsh-tui/assets`），角色与美术版权归原作者。
本项目是非官方粉丝作品，仅用于个人桌面装饰。

---

## English

A Windows desktop pet for the pixel mascots bundled with DSH. Pure PowerShell + WPF (.NET Framework), no third-party dependencies, self-contained in one folder.

Three characters: **Whale Girl** (22 animations, 267 frames), **Claude Girl**, and **Codex Girl** (static portraits with a happy expression).

### Features

- Transparent, borderless, always-on-top window; no taskbar entry
- Click / multi-click / drag / right-click menu interactions
- Skin switching (Whale / Claude / Codex), remembered between launches
- Screen-edge clamping and position memory
- Live agent status: DSH sessions and Claude Code thinking / tool / done states
- Launcher: starts `dsh`, Claude Code (`claude`), or the ChatGPT desktop app based on the current skin

### Quick start

**Requirements**: Windows 10/11, Windows PowerShell 5.1 (built in), .NET Framework 4.7+ (WPF, built in).

1. Clone or download this repository
2. Double-click `launch.vbs`

The 267 sprite frames load in about a second.

### Interactions

| Action | Reaction |
| --- | --- |
| Click left / right | Whale Girl dodges (poke-left / poke-right); Claude / Codex Girl switch to the happy face |
| Triple-click within 1.6 s | Whale Girl gets ticklish |
| Double-click | Whale Girl's heart reaction |
| Drag | Picks her up; release to drop |
| Drag to a screen edge | Clamped to the work area, cannot be lost off-screen |
| Right-click | Launch / pet / cheer up / sleep / wake / change skin / reset position / quit |
| Idle for 3 minutes | Whale Girl dozes off (static skins have no sleep frames) |

### Agent status

| State | Pet |
| --- | --- |
| Thinking / waiting for first token | Whale Girl plays her `thinking` animation (which already contains a pixel thought bubble) |
| Tool use / coding | Whale Girl plays her `typing` animation |
| Turn complete | Whale Girl switches to happy for about 3 seconds |
| Claude / Codex Girl | No animation frames, so a text bubble shows "…" or "✓ done" |
| Idle | Back to idle |

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

### Launcher mapping

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

### Skins

Right-click → **Change skin**. The choice is stored in `pet-state.json`.

| Skin | Notes |
| --- | --- |
| Whale Girl | Full animation set: idle, blink, poke, tickle, drag, sleep, happy |
| Claude Girl | Orange palette, normal + happy portraits |
| Codex Girl | White/lavender cat ears, normal + happy portraits |

### Layout

```
pet.ps1            # the pet (PowerShell + WPF)
launch.vbs         # windowless launcher
claude-status.ps1  # status writer used by Claude Code hooks
assets/            # 267 whale frames + Claude / Codex portraits
README.md
```

`pet-state.json` (position / skin) is generated at runtime and ignored by git.

### Tags

- `v3-status` — agent status integration (current)
- `v2-launcher` — multi-skin + launcher
- `v1-original` — original whale-only build + screen clamping
- `experiments` — hearts / procedural animation / blink-frame experiment

Restore a tag's files with `git checkout <tag> -- .`

### Credits

Character assets come from the DSH bundle (`@deepseek-harness-tui/dsh-tui/assets`); the characters and
artwork belong to their original authors. This is an unofficial fan project for personal desktop use.
