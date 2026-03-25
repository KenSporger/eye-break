import Foundation

@MainActor
final class ReminderScheduler {
    enum State {
        case idle
        case showing
        case waitingNext
    }

    private let workSession: WorkSessionManager
    private let reminderWindow: ReminderWindowController

    private var timer: DispatchSourceTimer?
    private var state: State = .idle

    // Minutes after dismiss: fixed interval based on user preference.
    // Capped to avoid unreasonably large delays.
    private let maxIntervalMinutes: Int = 12 * 60

    private let baseIntervalMinutesProvider: () -> Int

    init(
        workSession: WorkSessionManager,
        reminderWindow: ReminderWindowController,
        baseIntervalMinutesProvider: @escaping () -> Int = { 5 }
    ) {
        self.workSession = workSession
        self.reminderWindow = reminderWindow
        self.baseIntervalMinutesProvider = baseIntervalMinutesProvider
    }

    func resetForLock() {
        timer?.cancel()
        timer = nil
        state = .idle
        reminderWindow.hide()
        workSession.setPausedForReminder(false)
    }

    func handleTargetReached() {
        // If already showing or already in waiting state, ignore.
        guard state == .idle else { return }
        showReminder()
    }

    func handleDismiss() {
        guard state == .showing else { return }
        state = .waitingNext
        reminderWindow.hide()
        workSession.setPausedForReminder(false)
        scheduleNext()
    }

    private func showReminder() {
        state = .showing
        workSession.setPausedForReminder(true)
        reminderWindow.show()
    }

    private func scheduleNext() {
        timer?.cancel()
        timer = nil

        let base = max(1, baseIntervalMinutesProvider())
        let minutes = min(base, maxIntervalMinutes)

        let delaySeconds = TimeInterval(minutes * 60)
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        t.schedule(deadline: .now() + delaySeconds)
        t.setEventHandler { [weak self] in
            self?.showReminder()
        }
        timer = t
        t.resume()
    }
}

