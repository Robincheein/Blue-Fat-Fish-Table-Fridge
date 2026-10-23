# 鲸娘 · 桌面宠物（初版 + 屏幕边界）

DSH 像素看板娘「鲸娘」的 Windows 桌宠。22 套动画、267 帧，素材来自 DSH 内置素材。

## 启动

双击 `launch.vbs`。

## 互动

| 操作 | 反应 |
| --- | --- |
| 点她左边 / 右边 | 扭头躲开（poke-left / poke-right） |
| 1.6 秒内连点 3 下 | 怕痒（tickle） |
| 双击 | 冒爱心（smile-hearts） |
| 按住拖动 | 拎起来（drag），松手放下 |
| 右键 | 摸摸头 / 开心一下 / 睡一会儿 / 叫醒她 / 回到右下角 / 退出 |
| 3 分钟没动 | 打瞌睡（sleeping），鼠标碰一下会醒 |
| 拖到屏幕边缘 | 被工作区四边挡住，不会跑丢 |

## 版本

这个目录是 git 仓库，保留了两次提交：

- `v1-original`：当前工作区 —— 初版 + 屏幕边界
- `experiments`：Claude / Codex 换形象、爱心、程序动画、闭眼帧的实验版本

切换：

```bash
git checkout experiments -- .   # 看实验版
git checkout v1-original -- .   # 回到初版
```

## 文件

- `pet.ps1` — 宠物本体（PowerShell + WPF，透明置顶窗口）
- `launch.vbs` — 无窗口启动器
- `assets/` — 鲸娘 267 帧 PNG + `timings.json`
- `pet-state.json` — 自动记住位置（运行时生成）
