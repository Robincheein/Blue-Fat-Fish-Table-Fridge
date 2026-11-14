# 大肥鱼桌宠

[English](README.en.md) · 中文

---

DSH 内置像素看板娘的 Windows 桌宠。纯 PowerShell + WPF（.NET Framework）实现，零第三方依赖，单文件夹即可运行。

三位角色：**鲸娘**（22 套、267 帧逐帧动画）、**Claude 娘**、**Codex 娘**（静态立绘 + 开心表情）。

## 功能

- 透明、无边框、置顶窗口，不占任务栏
- 点击 / 连点 / 拖动 / 右键菜单互动
- 换形象：鲸娘 / Claude 娘 / Codex 娘，选择会记住
- 屏幕四边边界，位置记忆
- 状态联动：DSH 会话、Claude Code 的思考 / 工具 / 完成状态实时映射到宠物
- 启动器：按形象自动探测本机入口（DSH 的 dst / 网页 / 桌面 / CLI，Claude 的 CLI / 桌面 / 网页，Codex 的桌面 / CLI / 网页）

## 快速开始

**要求**：Windows 10 / 11，Windows PowerShell 5.1（系统自带），.NET Framework 4.7+（WPF，系统自带）。

1. 克隆或下载本仓库
2. 双击 `launch.vbs`（无控制台窗口）
3. 想让 Claude Code 也有状态联动：运行一次 `install-claude-hooks.ps1`，然后重启 Claude Code

素材共 267 帧，首次加载约 1 秒。

## 互动

| 操作 | 反应 |
| --- | --- |
| 点她左边 / 右边 | 鲸娘扭头躲（poke-left / poke-right）；Claude / Codex 娘切开心表情 |
| 1.6 秒内连点 3 下 | 鲸娘怕痒（tickle） |
| 双击 | 鲸娘冒爱心（smile-hearts） |
| 按住拖动 | 拎起来（drag），松手放下 |
| 拖到屏幕边缘 | 被工作区四边挡住，不会跑丢 |
| 右键 | 启动 / 摸摸头 / 开心一下 / 睡一会儿 / 叫醒她 / 换形象 / 回到右下角 / 退出 |
| 3 分钟没动 | 鲸娘打瞌睡（静态形象没有瞌睡动作） |

## 状态联动

| 状态 | 表现 |
| --- | --- |
| 思考 / 等首 token | 鲸娘保持平常表情，头顶浮出像素思考泡泡 |
| 写文档（.md / .txt） | 坐到键盘前「写作业」，头顶冒出像素 `Aa` |
| 读网页（web_fetch / WebFetch） | 保持平常表情，头顶浮出像素地球 |
| 写代码 / 调工具 | 坐到键盘前敲代码，头顶冒出彩色 `</>` |
| 想太久（> 45 秒） | 泡泡里换成大碗白米饭，慢慢闭眼，进入会呼吸的打瞌睡（没有 zzz） |
| 想更久（> 90 秒） | 泡泡里换成小鱼（摸鱼），继续打瞌睡 |
| 打瞌睡时 | 随机 12–28 秒后突然惊醒，回到普通思考状态，过一会儿再慢慢睡回去 |
| 等你确认 / 回答 | 头顶冒像素问号「？」 |
| 一轮完成 | 鲸娘切开心，约 3 秒后回待机 |
| Claude / Codex 娘 | 没有这些动作帧，用「…」/「✓ 完成」文字气泡表示状态 |
| 空闲 | 回到待机 |

鲸娘的「写文档 / 写代码」会切成打字动作（写文档版把 `</>` 换成 `Aa`）；
思考、网页和想太久保持平常表情，只换头顶气泡。
Claude Code 的 hooks 会把工具名和文件路径一起写进状态文件，所以 `.md` 和 `.py` 能区分开。

**DSH**：直接读 `$DSH_HOME/storages/session_projcache/sessions/*.json` 里最新的
`workingActivity.tracker.phase`（`thinking` / `tool` / `idle`），不需要改 DSH。
有活跃的 `userQuestions` 或非空 `waitingReason` 时，切成「等你确认 / 回答」状态。

**Claude Code**：运行一次 `install-claude-hooks.ps1`，它会自动备份并合并 hooks 进
`%CLAUDE_CONFIG_DIR%\settings.json`，然后重启 Claude Code 即可。
状态写在 `%LOCALAPPDATA%\dafeiyu-pet\claude-status.json`。
`Notification` 里带 permission / waiting / input 等提示时，会切成「等你确认」状态。

## 启动映射

右键菜单第一项会跟着当前形象变：

| 形象 | 启动 | 选择顺序 |
| --- | --- | --- |
| 鲸娘 | DSH | `dst` → 网页版（`dsh web`）→ 桌面版（DeepSeek Harness）→ `dsh` CLI |
| Claude 娘 | Claude Code | `claude` CLI → Claude 桌面版 → claude.ai 网页版 |
| Codex 娘 | Codex | ChatGPT 桌面版 → `codex` CLI → chatgpt.com/codex 网页版 |

每个目标都会按本机情况自动挑入口：

- DSH：优先 `dst`；没有就启动网页版（`dsh web`）；再没有就启动桌面版；最后用 `dsh` CLI
- Claude：优先 `claude` CLI；没有就找 Claude 桌面版；最后打开 claude.ai
- Codex：优先 ChatGPT 桌面版；没有就找 `codex` CLI；最后打开 chatgpt.com/codex
- CLI 会先找 PATH，再找 npm 全局目录和常见安装位置；`$launchDir` 不存在时回退到用户主目录

配置在 `pet.ps1` 顶部：

```powershell
$launchDir = 'E:\desktop\CODE'   # 不存在会自动回退
$chatgptAppId = ''               # 留空自动探测，可手动覆盖
```

没有 `wt.exe` 时回退到 PowerShell 窗口；找不到命令会弹提示框。

## 换形象

右键 → **换形象** 可以在三位之间切换，选择写入 `pet-state.json`，下次启动保持。

| 形象 | 说明 |
| --- | --- |
| 鲸娘 | 完整动画：待机、眨眼、被戳、怕痒、被拎、打瞌睡、开心 |
| Claude 娘 | 橘色系，普通 / 开心两张立绘 |
| Codex 娘 | 白紫猫耳系，普通 / 开心两张立绘 |

## 目录

```
pet.ps1            # 宠物本体（PowerShell + WPF）
launch.vbs         # 无窗口启动器
claude-status.ps1  # Claude Code hooks 的状态写入脚本
install-claude-hooks.ps1  # 一键安装 / 卸载 hooks（自动备份）
assets/            # 鲸娘 267 帧 + Claude / Codex 立绘
README.md
```

`pet-state.json`（位置 / 形象）运行时生成，已加入 `.gitignore`。

## 素材说明

角色素材来自 DSH 内置资源（`@deepseek-harness-tui/dsh-tui/assets`），角色与美术版权归原作者。
本项目是非官方粉丝作品，仅用于个人桌面装饰。
