import AppKit
import Testing

@testable import Muxy

@Suite("MainWindowMaximizeGeometry")
struct MainWindowMaximizeGeometryTests {
    @Test("ignores an auto-hidden bottom Dock while preserving the menu bar")
    func autoHiddenBottomDock() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = NSRect(x: 0, y: 70, width: 1920, height: 1080 - 24 - 70)

        let frame = MainWindowMaximizeGeometry.maximizedFrame(
            screenFrame: screen,
            visibleFrame: visible,
            dockAutoHidden: true
        )

        #expect(frame == NSRect(x: 0, y: 0, width: 1920, height: 1056))
    }

    @Test("ignores an auto-hidden side Dock by spanning the full width")
    func autoHiddenSideDock() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = NSRect(x: 80, y: 0, width: 1840, height: 1056)

        let frame = MainWindowMaximizeGeometry.maximizedFrame(
            screenFrame: screen,
            visibleFrame: visible,
            dockAutoHidden: true
        )

        #expect(frame == NSRect(x: 0, y: 0, width: 1920, height: 1056))
    }

    @Test("respects a pinned Dock by using the visible frame")
    func pinnedDockUsesVisibleFrame() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = NSRect(x: 0, y: 70, width: 1920, height: 986)

        let frame = MainWindowMaximizeGeometry.maximizedFrame(
            screenFrame: screen,
            visibleFrame: visible,
            dockAutoHidden: false
        )

        #expect(frame == visible)
    }

    @Test("preserves the origin of a secondary display")
    func secondaryDisplayOrigin() {
        let screen = NSRect(x: 1920, y: 0, width: 1920, height: 1080)
        let visible = NSRect(x: 1920, y: 70, width: 1920, height: 986)

        let frame = MainWindowMaximizeGeometry.maximizedFrame(
            screenFrame: screen,
            visibleFrame: visible,
            dockAutoHidden: true
        )

        #expect(frame == NSRect(x: 1920, y: 0, width: 1920, height: 1056))
    }

    @Test("treats a frame within tolerance as maximized")
    func detectsMaximizedWithinTolerance() {
        let target = NSRect(x: 0, y: 0, width: 1920, height: 1056)

        #expect(MainWindowMaximizeGeometry.isMaximized(windowFrame: target, maximizedFrame: target))
        #expect(MainWindowMaximizeGeometry.isMaximized(
            windowFrame: NSRect(x: 0.4, y: -0.3, width: 1920.2, height: 1055.8),
            maximizedFrame: target
        ))
    }

    @Test("treats a Dock-shrunk frame as not maximized")
    func detectsDockShrink() {
        let target = NSRect(x: 0, y: 0, width: 1920, height: 1056)
        let shrunk = NSRect(x: 0, y: 70, width: 1920, height: 986)

        #expect(!MainWindowMaximizeGeometry.isMaximized(windowFrame: shrunk, maximizedFrame: target))
    }

    @Test("clamps an off-screen restore frame back onto the current screen")
    func clampsOffScreenRestoreFrame() {
        let visible = NSRect(x: 0, y: 0, width: 1440, height: 876)
        let external = NSRect(x: 1920, y: 100, width: 1000, height: 700)

        let clamped = MainWindowMaximizeGeometry.clamped(external, within: visible)

        #expect(clamped == NSRect(x: 440, y: 100, width: 1000, height: 700))
    }

    @Test("shrinks a restore frame larger than the current screen")
    func clampsOversizedRestoreFrame() {
        let visible = NSRect(x: 0, y: 0, width: 1440, height: 876)
        let oversized = NSRect(x: 0, y: 0, width: 2000, height: 1200)

        let clamped = MainWindowMaximizeGeometry.clamped(oversized, within: visible)

        #expect(clamped == visible)
    }

    @Test("leaves an already-contained restore frame unchanged")
    func clampKeepsContainedFrame() {
        let visible = NSRect(x: 0, y: 0, width: 1440, height: 876)
        let inside = NSRect(x: 100, y: 100, width: 800, height: 500)

        #expect(MainWindowMaximizeGeometry.clamped(inside, within: visible) == inside)
    }
}

@Suite("MainWindowMaximizer")
@MainActor
struct MainWindowMaximizerStateTests {
    @Test("driving the state entry points on a screenless window does not crash")
    func toggleWithoutScreenIsSafe() {
        let window = NSWindow()

        MainWindowMaximizer.shared.toggleMaximize(window)
        MainWindowMaximizer.shared.reassertMaximizedFrame()
        MainWindowMaximizer.shared.handleUserResize()
    }
}
