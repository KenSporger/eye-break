import AppKit
import Combine

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()

    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    func setIcon(_ image: NSImage) {
        guard let button = statusItem?.button else { return }

        // Menu bar icons must be small; scale down to avoid overflow.
        let targetSide = max(14, min(18, NSStatusBar.system.thickness - 4))
        let targetSize = NSSize(width: targetSide, height: targetSide)

        let img = image.copy() as? NSImage ?? image
        img.size = targetSize
        img.isTemplate = image.isTemplate

        button.image = img
        button.imagePosition = .imageLeft
        button.imageScaling = .scaleProportionallyDown
    }

    func start() {
        if statusItem != nil { return }

        let statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)

        statusItem?.button?.title = "0%"

        let settingsItem = NSMenuItem(
            title: "设置",
            action: #selector(handleOpenSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem?.menu = menu

        // Use a small timer to keep title responsive even if publishes coalesce.
        updateProgress(0)
    }

    func updateProgress(_ progress: Double) {
        let percent = Int((max(0, min(progress, 1)) * 100).rounded(.toNearestOrAwayFromZero))
        statusItem?.button?.title = "\(percent)%"
    }

    func setEnabled(_ enabled: Bool) {
        statusItem?.button?.isEnabled = enabled
    }

    @objc private func handleOpenSettings() {
        onOpenSettings?()
    }

    @objc private func handleQuit() {
        onQuit?()
    }
}

