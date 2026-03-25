import AppKit
import SwiftUI

@MainActor
final class ReminderWindowController {
    private var panel: NSPanel?
    private var dismissHandler: (() -> Void)?

    func setDismissHandler(_ handler: @escaping () -> Void) {
        self.dismissHandler = handler
    }

    func show() {
        if panel == nil {
            createPanel()
        }
        guard let panel else { return }
        // Re-fit to current main screen in case of resolution/space changes.
        if let frame = NSScreen.main?.frame {
            panel.setFrame(frame, display: true)
        }

        // Ensure it shows above fullscreen apps and becomes interactive.
        panel.level = .screenSaver
        panel.hidesOnDeactivate = false
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let rect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)

        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.6)
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false

        // Keep it clickable.
        panel.ignoresMouseEvents = false
        panel.isMovable = false

        let view = ReminderContentView(dismiss: { [weak self] in
            self?.dismissHandler?()
        })
        let hosting = NSHostingView(rootView: view)
        hosting.frame = panel.contentView?.bounds ?? rect
        panel.contentView = hosting

        hosting.autoresizingMask = [.width, .height]

        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        self.panel = panel
    }
}

private struct ReminderContentView: View {
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.clear
            VStack(spacing: 18) {
                Text("休息一下")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)

                Text("达到工作时长上限。进入锁屏会自动清零。")
                    .font(.system(size: 18))
                    .foregroundColor(Color.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: dismiss) {
                    Text("继续工作")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.92))
                        .foregroundColor(.black.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
            }
        }
    }
}

