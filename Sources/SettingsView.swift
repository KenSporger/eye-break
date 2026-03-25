import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: Preferences
    let lockMonitor: LockStateMonitor

    @State private var isLocked: Bool = false
    @State private var lockSubId: UUID?
    @State private var lastLaunchAtLoginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(label: Text("计时设置").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(
                        "启用计时",
                        isOn: Binding(
                            get: { preferences.isEnabled },
                            set: { preferences.isEnabled = $0 }
                        )
                    )

                    Stepper(
                        value: Binding(
                            get: { preferences.workMinutes },
                            set: { preferences.workMinutes = $0 }
                        ),
                        in: 1...240,
                        step: 1
                    ) {
                        Text("工作时长：\(preferences.workMinutes) 分钟")
                    }

                    Stepper(
                        value: Binding(
                            get: { preferences.repeatIntervalBaseMinutes },
                            set: { preferences.repeatIntervalBaseMinutes = $0 }
                        ),
                        in: 1...120,
                        step: 1
                    ) {
                        Text("重复间隔：\(preferences.repeatIntervalBaseMinutes) 分钟")
                    }
                }
                .padding(8)
            }

            GroupBox(label: Text("锁屏规则").font(.headline)) {
                Text(isLocked ? "当前：锁屏中（工作计时清零）" : "当前：未锁屏（工作计时累计）")
                    .foregroundColor(isLocked ? .red : .secondary)
                    .padding(8)
            }

            GroupBox(label: Text("开机自启动").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(
                        "开机自启动",
                        isOn: Binding(
                            get: { preferences.launchAtLogin },
                            set: { preferences.launchAtLogin = $0 }
                        )
                    )

                    if let err = lastLaunchAtLoginError ?? preferences.lastLaunchAtLoginError {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
            }

            Text("通过顶部状态栏查看进度与触发提醒。")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .padding(.horizontal, 12)
        .frame(minWidth: 380, idealWidth: 420, maxWidth: 500)
        .onAppear {
            isLocked = lockMonitor.isLocked
            lockSubId = lockMonitor.subscribe { locked in
                isLocked = locked
            }
            lastLaunchAtLoginError = preferences.lastLaunchAtLoginError
        }
        .onDisappear {
            if let id = lockSubId {
                lockMonitor.unsubscribe(id)
            }
        }
    }
}

