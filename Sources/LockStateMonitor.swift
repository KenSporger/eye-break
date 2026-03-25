import Foundation
import AppKit
import Quartz

@MainActor
final class LockStateMonitor {
    // Published via callback to keep wiring simple (AppKit main thread).
    var onLockStateChanged: ((Bool) -> Void)?

    private var subscribers: [UUID: (Bool) -> Void] = [:]

    private var observer: NSObjectProtocol?
    private var lockObserver: DistributedLockObserver?

    private(set) var isLocked: Bool = false {
        didSet {
            guard oldValue != isLocked else { return }
            onLockStateChanged?(isLocked)
            for (_, handler) in subscribers {
                handler(isLocked)
            }
        }
    }

    init() {
        isLocked = Self.currentScreenIsLocked()
        startNotifications()
    }

    private func startNotifications() {
        let center = DistributedNotificationCenter.default()

        let lockObs = DistributedLockObserver(
            onLocked: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    self.isLocked = true
                }
            },
            onUnlocked: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    self.isLocked = false
                }
            }
        )
        self.lockObserver = lockObs

        center.addObserver(
            lockObs,
            selector: #selector(DistributedLockObserver.handleLocked(_:)),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        center.addObserver(
            lockObs,
            selector: #selector(DistributedLockObserver.handleUnlocked(_:)),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }

    private func setLocked(_ locked: Bool) {
        isLocked = locked
    }

    @discardableResult
    func subscribe(_ handler: @escaping (Bool) -> Void) -> UUID {
        let id = UUID()
        subscribers[id] = handler
        handler(isLocked)
        return id
    }

    func unsubscribe(_ id: UUID) {
        subscribers.removeValue(forKey: id)
    }

    private final class DistributedLockObserver: NSObject {
        let onLocked: () -> Void
        let onUnlocked: () -> Void

        init(onLocked: @escaping () -> Void, onUnlocked: @escaping () -> Void) {
            self.onLocked = onLocked
            self.onUnlocked = onUnlocked
        }

        @objc func handleLocked(_ notification: Notification) {
            onLocked()
        }

        @objc func handleUnlocked(_ notification: Notification) {
            onUnlocked()
        }
    }

    static func currentScreenIsLocked() -> Bool {
        guard let sessionDict = CGSessionCopyCurrentDictionary() as? [String: Any] else {
            return false
        }
        let lockedValue = sessionDict["CGSSessionScreenIsLocked"] as? Int ?? 0
        // Note: Some frameworks expose these as CFBoolean/NSNumber; handle both.
        let onConsoleBool = sessionDict["kCGSSessionOnConsoleKey"] as? Bool
        let onConsoleInt = sessionDict["kCGSSessionOnConsoleKey"] as? Int
        let onConsole = onConsoleBool ?? ((onConsoleInt ?? 1) == 1)
        // If session is not on console, treat as locked/suspended.
        return lockedValue == 1 || onConsole == false
    }
}

