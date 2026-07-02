import AppKit

enum MainWindowMaximizeGeometry {
    static func maximizedFrame(screenFrame: NSRect, visibleFrame: NSRect, dockAutoHidden: Bool) -> NSRect {
        guard dockAutoHidden else { return visibleFrame }
        let menuBarInset = max(0, screenFrame.maxY - visibleFrame.maxY)
        return NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: screenFrame.width,
            height: screenFrame.height - menuBarInset
        )
    }

    static func isMaximized(windowFrame: NSRect, maximizedFrame: NSRect, tolerance: CGFloat = 1) -> Bool {
        abs(windowFrame.minX - maximizedFrame.minX) < tolerance
            && abs(windowFrame.minY - maximizedFrame.minY) < tolerance
            && abs(windowFrame.width - maximizedFrame.width) < tolerance
            && abs(windowFrame.height - maximizedFrame.height) < tolerance
    }

    static func clamped(_ frame: NSRect, within visibleFrame: NSRect) -> NSRect {
        var result = frame
        result.size.width = min(result.width, visibleFrame.width)
        result.size.height = min(result.height, visibleFrame.height)
        result.origin.x = min(max(result.minX, visibleFrame.minX), visibleFrame.maxX - result.width)
        result.origin.y = min(max(result.minY, visibleFrame.minY), visibleFrame.maxY - result.height)
        return result
    }
}

@MainActor
final class MainWindowMaximizer {
    static let shared = MainWindowMaximizer()

    private weak var maximizedWindow: NSWindow?
    private var restoreFrame: NSRect?

    private init() {}

    func toggleMaximize(_ window: NSWindow) {
        guard maximizedWindow !== window else {
            restore(window)
            return
        }
        maximize(window)
    }

    func reassertMaximizedFrame() {
        guard let window = maximizedWindow,
              !window.styleMask.contains(.fullScreen),
              window.screen != nil,
              let frame = maximizedFrame(for: window),
              !MainWindowMaximizeGeometry.isMaximized(windowFrame: window.frame, maximizedFrame: frame)
        else { return }
        window.setFrame(frame, display: true)
    }

    func handleUserResize() {
        guard let window = maximizedWindow else { return }
        if let frame = maximizedFrame(for: window),
           MainWindowMaximizeGeometry.isMaximized(windowFrame: window.frame, maximizedFrame: frame)
        {
            return
        }
        maximizedWindow = nil
        restoreFrame = nil
    }

    private func maximize(_ window: NSWindow) {
        guard let frame = maximizedFrame(for: window) else { return }
        restoreFrame = window.frame
        maximizedWindow = window
        window.setFrame(frame, display: true)
    }

    private func restore(_ window: NSWindow) {
        maximizedWindow = nil
        guard let frame = restoreFrame else { return }
        restoreFrame = nil
        window.setFrame(clampedRestoreFrame(frame, for: window), display: true)
    }

    private func maximizedFrame(for window: NSWindow) -> NSRect? {
        guard let screen = window.screen ?? NSScreen.main else { return nil }
        return MainWindowMaximizeGeometry.maximizedFrame(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            dockAutoHidden: Self.isDockAutoHidden()
        )
    }

    private func clampedRestoreFrame(_ frame: NSRect, for window: NSWindow) -> NSRect {
        guard let screen = window.screen ?? NSScreen.main else { return frame }
        return MainWindowMaximizeGeometry.clamped(frame, within: screen.visibleFrame)
    }

    private static func isDockAutoHidden() -> Bool {
        UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
    }
}
