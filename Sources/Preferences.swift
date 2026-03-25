import Foundation
import ServiceManagement
import Combine

@MainActor
final class Preferences: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { save() }
    }
    @Published var workMinutes: Int {
        didSet { save() }
    }
    @Published var repeatIntervalBaseMinutes: Int {
        didSet { save() }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            save()
            setLaunchAtLogin(launchAtLogin)
        }
    }

    @Published var lastLaunchAtLoginError: String?

    private let launchManager = LaunchAtLoginManager()

    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults

        let enabled = userDefaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        let minutes = userDefaults.object(forKey: Keys.workMinutes) as? Int ?? 30
        let repeatBase = userDefaults.object(forKey: Keys.repeatIntervalBaseMinutes) as? Int ?? 5
        let launchAtLogin = userDefaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false

        self.isEnabled = enabled
        self.workMinutes = max(1, minutes)
        self.repeatIntervalBaseMinutes = max(1, repeatBase)
        if #available(macOS 13.0, *) {
            self.launchAtLogin = launchManager.isEnabled()
        } else {
            self.launchAtLogin = launchAtLogin
        }

        // Apply initial state (best-effort; may fail without app bundle).
        if self.launchAtLogin {
            setLaunchAtLogin(true)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.lastLaunchAtLoginError = nil
            do {
                try await launchManager.setEnabled(enabled)
            } catch {
                self.lastLaunchAtLoginError = error.localizedDescription
            }
        }
    }

    private func save() {
        defaults.set(isEnabled, forKey: Keys.isEnabled)
        defaults.set(workMinutes, forKey: Keys.workMinutes)
        defaults.set(repeatIntervalBaseMinutes, forKey: Keys.repeatIntervalBaseMinutes)
        defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
    }

    private enum Keys {
        static let isEnabled = "eyeBreak.isEnabled"
        static let workMinutes = "eyeBreak.workMinutes"
        static let repeatIntervalBaseMinutes = "eyeBreak.repeatIntervalBaseMinutes"
        static let launchAtLogin = "eyeBreak.launchAtLogin"
    }
}

