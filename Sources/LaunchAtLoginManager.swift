import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager {
    static let didChangeStatusNotification = Notification.Name("eyeBreak.launchAtLogin.didChangeStatus")

    func isEnabled() -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) async throws {
        guard #available(macOS 13.0, *) else {
            throw NSError(
                domain: "eyeBreak.launchAtLogin",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "macOS 13+ required for LaunchAtLogin"]
            )
        }

        if enabled {
            try await SMAppService.mainApp.register()
        } else {
            try await SMAppService.mainApp.unregister()
        }

        NotificationCenter.default.post(
            name: Self.didChangeStatusNotification,
            object: enabled
        )
    }
}

