import AppKit

enum MainWindowMaximizeGeometry {
    static func maximizedFrame(screenFrame: NSRect, visibleFrame: NSRect) -> NSRect {
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
}

@MainActor
final class MainWindowMaximizer {
    static let shared = MainWindowMaximizer()

    private weak var maximizedWindow: NSWindow?
    private var restoreFrame: NSRect?
    private var screenParametersObserver: NSObjectProtocol?
    private var liveResizeObserver: NSObjectProtocol?

    private init() {}

    func toggleMaximize(_ window: NSWindow) {
        guard maximizedWindow !== window else {
            restore(window)
            return
        }
        maximize(window)
    }

    private func maximize(_ window: NSWindow) {
        guard let frame = maximizedFrame(for: window) else { return }
        restoreFrame = window.frame
        maximizedWindow = window
        startObserving(window)
        window.setFrame(frame, display: true)
    }

    private func restore(_ window: NSWindow) {
        stopObserving()
        maximizedWindow = nil
        guard let frame = restoreFrame else { return }
        restoreFrame = nil
        window.setFrame(frame, display: true)
    }

    private func maximizedFrame(for window: NSWindow) -> NSRect? {
        guard let screen = window.screen ?? NSScreen.main else { return nil }
        return MainWindowMaximizeGeometry.maximizedFrame(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame
        )
    }

    private func startObserving(_ window: NSWindow) {
        stopObserving()
        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.reassertMaximizedFrame()
                }
            }
        }
        liveResizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didEndLiveResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.releaseIfUserResized()
            }
        }
    }

    private func stopObserving() {
        if let screenParametersObserver {
            NotificationCenter.default.removeObserver(screenParametersObserver)
            self.screenParametersObserver = nil
        }
        if let liveResizeObserver {
            NotificationCenter.default.removeObserver(liveResizeObserver)
            self.liveResizeObserver = nil
        }
    }

    private func reassertMaximizedFrame() {
        guard let window = maximizedWindow, let frame = maximizedFrame(for: window) else { return }
        guard !MainWindowMaximizeGeometry.isMaximized(windowFrame: window.frame, maximizedFrame: frame) else { return }
        window.setFrame(frame, display: true)
    }

    private func releaseIfUserResized() {
        guard let window = maximizedWindow, let frame = maximizedFrame(for: window) else { return }
        guard !MainWindowMaximizeGeometry.isMaximized(windowFrame: window.frame, maximizedFrame: frame) else { return }
        stopObserving()
        maximizedWindow = nil
        restoreFrame = nil
    }
}
