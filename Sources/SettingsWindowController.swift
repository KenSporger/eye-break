import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let preferences: Preferences
    private let lockMonitor: LockStateMonitor

    private var window: NSWindow?

    init(preferences: Preferences, lockMonitor: LockStateMonitor) {
        self.preferences = preferences
        self.lockMonitor = lockMonitor
    }

    func show() {
        if window == nil {
            createWindow()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createWindow() {
        let rect = NSRect(x: 0, y: 0, width: 420, height: 300)
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "EyeBreak 设置"

        let hosting = NSHostingController(
            rootView: SettingsView(
                preferences: preferences,
                lockMonitor: lockMonitor
            )
        )
        window.contentView = hosting.view
        hosting.view.frame = rect

        self.window = window
    }
}

