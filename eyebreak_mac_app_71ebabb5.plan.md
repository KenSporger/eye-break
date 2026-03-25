---
name: EyeBreak Mac App
overview: 实现一个 macOS 原生休息软件：根据“屏幕是否锁屏”累计工作时长，到达用户设定时弹出全屏休息提醒，并在菜单栏显示工作百分比；支持重复提醒与锁屏清零，提供设置 UI、Dock/状态栏入口，并支持开机自启动。
todos:
  - id: scaffold-xcode
    content: 新建 macOS SwiftUI App（Xcode 工程骨架、App 图标与 Assets.xcassets）。
    status: completed
  - id: lock-monitor
    content: 实现 `LockStateMonitor`：注册分布式通知并在启动时探测初始锁屏状态。
    status: completed
  - id: work-timer
    content: 实现 `WorkSessionManager`：基于锁屏状态与“提醒显示期”控制每秒累积、清零、百分比封顶。
    status: completed
  - id: reminder-scheduler
    content: 实现 `ReminderScheduler`：到达 100% 立即弹窗；关闭后按 5/10/20/40/80 分钟调度重复提醒（尾部 80 分钟循环）。
    status: completed
  - id: reminder-window
    content: 实现 `ReminderWindowController`：全屏/置顶提醒窗口与按钮回调；进入锁屏时关闭。
    status: completed
  - id: statusbar
    content: 实现 `StatusBarController`：`NSStatusItem` 实时显示进度百分比，并提供打开设置等入口。
    status: completed
  - id: settings-ui
    content: 实现 `SettingsView`：工作时长、启用开关、下一次提醒展示、开机自启动开关（`SMAppService`）。
    status: completed
  - id: wiring
    content: 把各控制器在 `EyeBreakApp.swift` 中串联（订阅进度、锁屏状态、提醒回调）。
    status: completed
  - id: manual-tests
    content: 完成手工验证与调参（计时精度、提醒窗口行为、锁屏清零、状态栏刷新频率）。
    status: completed
isProject: false
---

## 目标

做一个 macOS 桌面应用（Swift + SwiftUI/AppKit）：

- 自动按“锁屏状态”累计工作时间；进入锁屏则清零并停止计时。
- 工作时间达到设定上限（如 30 分钟）后显示全屏休息提醒；提醒期间暂停累计。
- 提醒关闭后继续累计，并按间隔（5/10/20/40/80 分钟）重复提醒；进入锁屏时停止并清零。
- 顶部状态栏显示百分比进度（100 表示已达到上限，显示上限可封顶为 100）。
- 提供设置 UI（工作时长、启用、开机自启动等）与应用图标/快捷入口。

## 关键技术点

1. 锁屏/解锁检测

- 用 `NSDistributedNotificationCenter` 监听：`com.apple.screenIsLocked` / `com.apple.screenIsUnlocked`。
- 同时在启动时用 `CGSessionCopyCurrentDictionary()` 检查初始是否已锁屏，避免漏掉首个状态。

1. 工作计时

- 使用 `DispatchSourceTimer` 或 `Timer` 每秒 tick。
- 条件：只有在“未锁屏”且“当前不在提醒弹窗显示期间”时，累积工作时长。
- 显示百分比：`min(elapsed/target, 1.0) * 100`。

1. 全屏提醒

- 自定义 `NSWindow`/`NSPanel` 作为覆盖层：设置 `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`，并 `orderFrontRegardless()`。
- 提醒窗口提供按钮："继续工作"/"关闭提醒"。

1. 重复提醒调度

- 当到达 `100%`：立刻弹出提醒一次。
- 关闭后进入“等待下次提醒”状态，按照数组 `[5,10,20,40,80]` 分钟依次触发（下一次提醒时间 = 关闭时间 + 对应间隔）。
- 当数组最后一个也触发后：默认继续使用最后间隔（80 分钟）循环，直到进入锁屏。
- 若进入锁屏：关闭/隐藏提醒窗口、重置计时与调度状态。

1. 状态栏进度

- 用 `NSStatusItem`：通过 `setTitle("XX%")` 实时更新。
- 定时从 `WorkSessionManager` 推送当前进度。

1. 开机自启动

- macOS 13+：用 `ServiceManagement.SMAppService.mainApp.register()` / `unregister()`。
- 在 UI 中提供开关，并展示注册状态。

## 工程结构（拟定）

- `EyeBreakApp.swift`：App 入口，创建全局控制器（状态栏、锁屏监听、计时、设置窗口）。
- `WorkSessionManager.swift`：核心计时与进度计算。
- `LockStateMonitor.swift`：锁屏/解锁通知监听 + 启动时初始状态探测。
- `StatusBarController.swift`：菜单栏进度显示与快速入口。
- `ReminderWindowController.swift`：全屏提醒窗口展示/关闭。
- `ReminderScheduler.swift`：重复提醒间隔调度逻辑。
- `SettingsView.swift` + `SettingsWindowController.swift`：设置 UI（工作时长、启用、开机自启动等）。
- `Preferences.swift`：UserDefaults 读写（工作时长、启用、是否开机自启动）。
- 资源：`Assets.xcassets`（应用图标、状态栏模板图标）。

## 数据流（Mermaid）

```mermaid
flowchart TD
User[用户] -->|设置工作时长/启用| Settings[SettingsView]
Settings --> Preferences[UserDefaults]

subgraph Runtime[运行时控制]
LockMonitor[LockStateMonitor] -->|锁屏/解锁| WorkManager[WorkSessionManager]
WorkManager -->|进度(秒/百分比)| StatusBar[StatusBarController]
WorkManager -->|到达目标| ReminderScheduler[ReminderScheduler]
ReminderScheduler -->|触发提醒| ReminderUI[ReminderWindowController]
ReminderUI -->|点击继续/关闭| ReminderScheduler
end

WorkManager -->|进入锁屏| Reset[重置计时并停止提醒]
```



## 计划实施步骤

1. 创建 Xcode macOS App 项目（SwiftUI 模板为主），加入必要 capability（如需要）与 `Assets.xcassets` 图标。
2. 实现 `LockStateMonitor`：

- 订阅 `NSDistributedNotificationCenter` 的锁屏/解锁通知。
- 启动时读取 `CGSessionCopyCurrentDictionary()` 初始锁屏状态。

1. 实现 `WorkSessionManager`：

- 读入工作时长（分钟 -> 秒）。
- 在未锁屏且不处于提醒窗口显示时，每秒累积；进入锁屏时清零。
- 对外输出当前百分比（封顶 100）。

1. 实现 `ReminderScheduler`：

- 到达目标时立刻 show 提醒，并暂停计时。
- 关闭后根据 `[5,10,20,40,80]` 依次安排下一次提醒；数组尾部默认循环 80 分钟。

1. 实现 `ReminderWindowController`：

- 用 `NSWindow/NSPanel` 覆盖全屏辅助层，提供按钮回调给 scheduler。

1. 实现 `StatusBarController`：

- 创建 `NSStatusItem`，定时/订阅进度更新 `setTitle("XX%")`。
- 可在状态栏提供菜单项（打开设置/暂停）。

1. 实现 `SettingsView`：

- 输入工作时长（如默认 30 分钟）。
- 启用开关。
- 开机自启动开关（调用 `SMAppService`）。

1. 补齐资源与入口：

- 设置 Dock 图标（默认使用 App icon）。
- 状态栏图标模板化。

1. 手工验证清单：

- 启动后解锁状态能开始计时。
- 计到 30 分钟（或设定值）弹出全屏提醒。
- 提醒期间暂停累计；关闭后出现下一次提醒，并按间隔节奏。
- 进入锁屏时立即停止并清零，解锁后从 0 重新开始。
- 状态栏百分比正确变化并在达到目标后保持 100。
- 开机自启动开关生效（通过系统登录项管理确认）。

