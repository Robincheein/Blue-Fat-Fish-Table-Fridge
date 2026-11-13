# 像素桌宠 · 鲸娘 / Claude 娘 / Codex 娘

DSH 自带三位像素看板娘的 Windows 桌宠，带一个「按形象启动」的入口。

## 启动

双击 `launch.vbs`。没有控制台窗口，她会出现在桌面右下角。

## 互动

| 操作 | 反应 |
| --- | --- |
| 右键 → 启动 | 按当前形象启动（见下） |
| 点她左边 / 右边 | 鲸娘扭头躲（poke-left / poke-right）；Claude / Codex 娘切开心表情 |
| 1.6 秒内连点 3 下 | 鲸娘怕痒（tickle） |
| 双击 | 鲸娘冒爱心（smile-hearts） |
| 按住拖动 | 拎起来（drag），松手放下 |
| 拖到屏幕边缘 | 被工作区四边挡住，不会跑丢 |
| 右键 | 启动 / 摸摸头 / 开心一下 / 睡一会儿 / 叫醒她 / 换形象 / 回到右下角 / 退出 |
| 3 分钟没动 | 鲸娘打瞌睡（静态形象没有瞌睡动作） |

## 启动映射

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

没有 `wt.exe` 时会回退到 PowerShell 窗口；启动失败会弹一个提示框。

## 状态联动

宠物会跟着 agent 的状态走：

| 状态 | 表现 |
| --- | --- |
| 思考 / 等首 token | 头顶冒「…」；鲸娘播放 thinking 动画 |
| 调工具 / 写代码 | 头顶冒「…」；鲸娘播放 typing 动画 |
| 一轮完成 | 头顶冒「✓ 完成」；鲸娘切开心，约 3 秒后恢复 |
| 空闲 | 回到待机 |

鲸娘用自带的像素 `thinking` / `typing` 动画（画面里本来就带思考泡泡），不再叠加文字框；
Claude / Codex 娘没有这些动作帧，才用文字气泡。

### DSH

直接读 DSH 的会话投影（`$DSH_HOME/storages/session_projcache/sessions/*.json`）里的
`workingActivity.tracker.phase`（`thinking` / `tool` / `idle`），不需要改 DSH。

### Claude Code

用 hooks 写状态文件（已合并进 `%CLAUDE_CONFIG_DIR%\settings.json`，原文件备份为 `settings.json.bak-*`）：

- `UserPromptSubmit` → thinking
- `PreToolUse` → working
- `Stop` → done
- `SessionEnd` → idle

状态文件：`%LOCALAPPDATA%\dafeiyu-pet\claude-status.json`。
Claude Code 需要重启一次才会加载新 hooks。

## 版本（git）

- `v3-status`：当前 —— 三位形象 + 启动入口 + DSH / Claude 状态联动
- `v2-launcher`：三位形象 + 启动入口
- `v1-original`：最初的鲸娘版 + 屏幕边界
- `experiments`：带爱心、程序动画、闭眼帧的实验版

切换：

```bash
git checkout <tag> -- .
```

## 文件

- `pet.ps1` — 宠物本体（PowerShell + WPF）
- `launch.vbs` — 无窗口启动器
- `claude-status.ps1` — Claude Code hooks 调用的状态写入脚本
- `assets/` — 鲸娘 267 帧 + Claude / Codex 立绘
- `pet-state.json` — 记住位置和当前形象（运行时生成）
