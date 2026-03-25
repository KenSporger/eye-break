# EyeBreak

macOS 免费的菜单栏护眼/久坐提醒工具：根据「未锁屏」时间累计工作进度，到达目标后弹出全屏休息提醒；支持固定间隔重复提醒、锁屏清零、设置窗口、开机自启动。

## 功能

- **菜单栏显示进度**：顶部状态栏实时显示工作进度百分比。
- **锁屏清零**：进入锁屏即停止并清零；解锁后重新开始累计。
- **全屏休息提醒**：进度到 100% 立即弹出全屏遮罩提醒，可点击“继续工作”关闭。
- **重复提醒**：点击“继续工作”后，按用户设置的固定重复间隔再次提醒。
- **设置**：工作时长、重复间隔、启用开关、开机自启动。

## 截图 / 预览

![image-20260326003755994](./assets/image-20260326003755994.png)

## 构建与运行

本项目使用 Swift Package Manager（Swift 6）。

### 1) 构建可执行文件

```bash
swift build -c release
```

产物默认在：

- `.build/release/EyeBreak`

### 2) 运行

直接运行可执行文件：

```bash
.build/release/EyeBreak
```

或运行 app bundle（如果你本地已组装了 `.app`）：

```bash
open EyeBreak.app
```

## 项目结构

- `Sources/`：核心代码
  - `main.swift`：应用入口（菜单栏模式）
  - `EyeBreakAppDelegate.swift`：依赖装配与事件串联
  - `LockStateMonitor.swift`：锁屏/解锁检测
  - `WorkSessionManager.swift`：工作计时与进度
  - `ReminderScheduler.swift`：提醒调度（固定重复间隔）
  - `ReminderWindowController.swift`：全屏提醒面板
  - `StatusBarController.swift`：状态栏图标/菜单
  - `SettingsView.swift` / `SettingsWindowController.swift`：设置 UI
  - `Preferences.swift`：UserDefaults 持久化

## 使用说明

- **工作时长**：达到该时长后会触发全屏提醒。
- **重复间隔**：点击“继续工作”后，等待该间隔再次提醒。
- **启用计时**：关闭会停止并重置计时。
- **开机自启动**：macOS 13+ 使用 `SMAppService` 尝试注册（需要以 app bundle 形式运行时更稳定）。

