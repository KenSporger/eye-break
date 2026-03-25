import AppKit
import Combine

@MainActor
final class EyeBreakAppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()

    private lazy var lockMonitor: LockStateMonitor = LockStateMonitor()
    private lazy var workSession: WorkSessionManager = WorkSessionManager()
    private lazy var reminderWindow: ReminderWindowController = ReminderWindowController()
    private lazy var reminderScheduler: ReminderScheduler = ReminderScheduler(
        workSession: workSession,
        reminderWindow: reminderWindow,
        baseIntervalMinutesProvider: { [weak self] in
            self?.preferences.repeatIntervalBaseMinutes ?? 5
        }
    )
    private lazy var statusBar: StatusBarController = StatusBarController()

    private lazy var settingsWindow: SettingsWindowController = SettingsWindowController(
        preferences: preferences,
        lockMonitor: lockMonitor
    )

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Provide a "shortcut" icon (Dock + status bar) without relying on Xcode asset catalogs.
        let icon = IconFactory.makeAppIcon()
        NSApp.applicationIconImage = icon
        let statusIcon = IconFactory.makeStatusBarIcon()

        statusBar.onOpenSettings = { [weak self] in
            self?.settingsWindow.show()
        }
        statusBar.onQuit = { [weak self] in
            NSApp.terminate(self)
        }

        statusBar.start()
        statusBar.setIcon(statusIcon)
        statusBar.updateProgress(0)

        // Wire status bar updates.
        workSession.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.statusBar.updateProgress(value)
            }
            .store(in: &cancellables)

        // When we hit 100% work time, trigger reminder scheduling.
        workSession.onReachedTarget = { [weak self] in
            self?.reminderScheduler.handleTargetReached()
        }

        // Lock/unlock monitoring drives work reset.
        lockMonitor.onLockStateChanged = { [weak self] isLocked in
            guard let self else { return }
            self.workSession.setLocked(isLocked)
            if isLocked {
                self.reminderScheduler.resetForLock()
            }
        }

        // Apply initial lock state (important if app starts while locked).
        workSession.setLocked(lockMonitor.isLocked)
        if lockMonitor.isLocked {
            reminderScheduler.resetForLock()
        }

        // Initial configuration
        workSession.setEnabled(preferences.isEnabled)
        workSession.setTargetMinutes(preferences.workMinutes)
        reminderWindow.setDismissHandler { [weak self] in
            self?.reminderScheduler.handleDismiss()
        }

        reminderScheduler.resetForLock() // ensures state aligns on first launch

        preferences.$isEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.workSession.setEnabled(enabled)
                if !enabled {
                    self?.reminderScheduler.resetForLock()
                }
            }
            .store(in: &cancellables)

        preferences.$workMinutes
            .dropFirst()
            .sink { [weak self] minutes in
                guard let self else { return }
                self.workSession.setTargetMinutes(minutes)
                self.reminderScheduler.resetForLock()
            }
            .store(in: &cancellables)

        // Autostart toggle is handled inside SettingsView via Preferences.
        statusBar.setEnabled(preferences.isEnabled)
    }
}

