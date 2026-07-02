import AppKit
import Testing

@testable import Muxy

@Suite("MainWindowMaximizeGeometry")
struct MainWindowMaximizeGeometryTests {
    @Test("reclaims a bottom Dock while preserving the menu bar")
    func reclaimsBottomDock() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = NSRect(x: 0, y: 70, width: 1920, height: 1080 - 24 - 70)

        let frame = MainWindowMaximizeGeometry.maximizedFrame(screenFrame: screen, visibleFrame: visible)

        #expect(frame.minX == 0)
        #expect(frame.minY == 0)
        #expect(frame.width == 1920)
        #expect(frame.height == 1056)
    }

    @Test("keeps full height below the menu bar when no Dock is inset")
    func menuBarOnly() {
        let screen = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = NSRect(x: 0, y: 0, width: 1440, height: 876)

        let frame = MainWindowMaximizeGeometry.maximizedFrame(screenFrame: screen, visibleFrame: visible)

        #expect(frame.width == 1440)
        #expect(frame.height == 876)
    }

    @Test("reclaims a side Dock by spanning the full width")
    func reclaimsSideDock() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = NSRect(x: 80, y: 0, width: 1840, height: 1056)

        let frame = MainWindowMaximizeGeometry.maximizedFrame(screenFrame: screen, visibleFrame: visible)

        #expect(frame.minX == 0)
        #expect(frame.width == 1920)
        #expect(frame.height == 1056)
    }

    @Test("preserves the origin of a secondary display")
    func secondaryDisplayOrigin() {
        let screen = NSRect(x: 1920, y: 0, width: 1920, height: 1080)
        let visible = NSRect(x: 1920, y: 70, width: 1920, height: 986)

        let frame = MainWindowMaximizeGeometry.maximizedFrame(screenFrame: screen, visibleFrame: visible)

        #expect(frame.minX == 1920)
        #expect(frame.minY == 0)
        #expect(frame.width == 1920)
        #expect(frame.height == 1056)
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
}
