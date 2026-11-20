import SwiftUI
import AppKit

@main
struct PowerLevelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = SystemMonitor()

    var body: some Scene {
        MenuBarExtra {
            ScouterView(monitor: monitor)
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Hides the Dock icon when launched with `swift run` (the .app bundle also sets LSUIElement).
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--mascot-snapshot"), args.count > i + 1 {
            MascotSnapshot.write(to: URL(fileURLWithPath: args[i + 1]))
            exit(0)
        }
    }
}

/// What you see in the menu bar: form icon + current power level.
struct MenuBarLabel: View {
    @ObservedObject var monitor: SystemMonitor

    var body: some View {
        let form = monitor.form
        let value = form == .over9000 ? "9000+!" : monitor.powerLevel.formatted()
        HStack(spacing: 3) {
            Image(systemName: form.symbol)
            if monitor.showNumber { Text(value).monospacedDigit() }
        }
    }
}
