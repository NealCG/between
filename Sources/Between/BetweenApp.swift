import SwiftUI
import AppKit

@main
struct BetweenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Lives only in the menu bar. One click opens the picker.
        MenuBarExtra {
            MenuView()
        } label: {
            Image(nsImage: MenuIcon.image)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // No Dock icon, no app menu. Info.plist also sets LSUIElement for the bundled app.
        NSApp.setActivationPolicy(.accessory)
    }
}

func formatTime(_ seconds: Double) -> String {
    let s = max(0, Int(ceil(seconds)))
    return String(format: "%d:%02d", s / 60, s % 60)
}

/// Letter spacing for all text, in points.
let textTracking: CGFloat = -0.5

/// All text in the app is Helvetica Neue Regular.
func helvetica(_ size: CGFloat) -> Font {
    .custom("HelveticaNeue", size: size)
}
