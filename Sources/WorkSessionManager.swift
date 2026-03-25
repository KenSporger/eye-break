import Foundation
import Combine

@MainActor
final class WorkSessionManager: ObservableObject {
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var progress: Double = 0 // 0...1

    var onReachedTarget: (() -> Void)?

    private var enabled: Bool = false
    private var isLocked: Bool = false
    private var isPausedForReminder: Bool = false

    private var targetSeconds: Int = 30 * 60
    private var reachedTarget: Bool = false

    private var timer: Timer?

    init() {
        startTimer()
    }

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        if !enabled {
            fullReset()
        }
    }

    func setTargetMinutes(_ minutes: Int) {
        targetSeconds = max(1, minutes) * 60
        fullReset()
    }

    func setLocked(_ locked: Bool) {
        isLocked = locked
        if locked {
            fullReset()
        }
    }

    func setPausedForReminder(_ paused: Bool) {
        isPausedForReminder = paused
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        guard enabled, !isLocked, !isPausedForReminder else { return }

        elapsedSeconds += 1

        let newProgress = min(Double(elapsedSeconds) / Double(targetSeconds), 1.0)
        progress = newProgress

        if !reachedTarget, newProgress >= 1.0 {
            reachedTarget = true
            onReachedTarget?()
        }
    }

    private func fullReset() {
        elapsedSeconds = 0
        progress = 0
        reachedTarget = false
    }
}

