import AppKit

enum IconFactory {
    static func makeStatusBarIcon() -> NSImage {
        // Draw a small monochrome icon with a transparent background.
        // We rely on alpha only (template image) so it adapts to light/dark menu bar.
        let side: CGFloat = 18
        let size = NSSize(width: side, height: side)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.black.setFill()

        // Cup
        let cup = NSBezierPath(roundedRect: NSRect(x: 4.2, y: 5.2, width: 8.8, height: 7.8), xRadius: 2.4, yRadius: 2.4)
        cup.fill()

        // Handle (even-odd ring)
        let handle = NSBezierPath()
        handle.appendOval(in: NSRect(x: 11.5, y: 6.1, width: 5.2, height: 5.2))
        handle.appendOval(in: NSRect(x: 12.8, y: 7.4, width: 2.6, height: 2.6))
        handle.windingRule = .evenOdd
        handle.fill()

        // Saucer
        NSBezierPath(roundedRect: NSRect(x: 3.3, y: 3.1, width: 11.5, height: 2.1), xRadius: 1.0, yRadius: 1.0).fill()

        // Steam
        let steam1 = NSBezierPath()
        steam1.move(to: NSPoint(x: 6.0, y: 14.6))
        steam1.curve(to: NSPoint(x: 6.0, y: 11.2), controlPoint1: NSPoint(x: 4.7, y: 13.7), controlPoint2: NSPoint(x: 4.7, y: 12.1))
        steam1.lineWidth = 1.6
        steam1.lineCapStyle = .round
        steam1.stroke()

        let steam2 = NSBezierPath()
        steam2.move(to: NSPoint(x: 9.2, y: 14.8))
        steam2.curve(to: NSPoint(x: 9.2, y: 11.4), controlPoint1: NSPoint(x: 7.9, y: 13.9), controlPoint2: NSPoint(x: 7.9, y: 12.3))
        steam2.lineWidth = 1.6
        steam2.lineCapStyle = .round
        steam2.stroke()

        let steam3 = NSBezierPath()
        steam3.move(to: NSPoint(x: 12.4, y: 14.6))
        steam3.curve(to: NSPoint(x: 12.4, y: 11.2), controlPoint1: NSPoint(x: 11.1, y: 13.7), controlPoint2: NSPoint(x: 11.1, y: 12.1))
        steam3.lineWidth = 1.6
        steam3.lineCapStyle = .round
        steam3.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    static func makeAppIcon() -> NSImage {
        if let url = Bundle.main.url(forResource: "EyeBreak", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            image.isTemplate = false
            return image
        }

        // Fallback (should rarely happen): simple monochrome cup-like glyph.
        let size = NSSize(width: 64, height: 64)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.black.setFill()
        let cupRect = NSRect(x: 14, y: 18, width: 30, height: 28)
        NSBezierPath(roundedRect: cupRect, xRadius: 8, yRadius: 8).fill()
        let handle = NSBezierPath()
        handle.appendOval(in: NSRect(x: 38, y: 24, width: 16, height: 16))
        handle.appendOval(in: NSRect(x: 42, y: 28, width: 8, height: 8))
        handle.windingRule = .evenOdd
        handle.fill()

        let saucer = NSBezierPath(roundedRect: NSRect(x: 12, y: 10, width: 40, height: 8), xRadius: 4, yRadius: 4)
        saucer.fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

