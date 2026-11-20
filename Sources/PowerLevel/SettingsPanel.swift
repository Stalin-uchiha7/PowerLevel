import AppKit
import ServiceManagement
import SwiftUI

/// A small dark utility window that closes on Escape. Used by Settings and About.
final class PanelWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) { close() }

    @MainActor static func make(title: String, content: some View) -> PanelWindow {
        let host = NSHostingView(rootView: content)
        let w = PanelWindow(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                            styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        w.title = title
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.isMovableByWindowBackground = true
        w.isReleasedWhenClosed = false
        w.appearance = NSAppearance(named: .darkAqua)
        w.backgroundColor = NSColor(Scouter.background)
        w.contentView = host
        w.setContentSize(host.fittingSize)
        w.center()
        return w
    }

    @MainActor func present() {
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }
}

enum SettingsPanel {
    @MainActor private static var window: PanelWindow?

    @MainActor static func show(monitor: SystemMonitor) {
        let w = window ?? PanelWindow.make(title: "Power Level Settings", content: SettingsView(monitor: monitor))
        window = w
        w.present()
    }
}

struct SettingsView: View {
    @ObservedObject var monitor: SystemMonitor
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SCOUTER // SETTINGS")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Scouter.dim)

            row("Refresh every") {
                ScouterSegmented(selection: $monitor.refreshInterval,
                                 options: [("1 s", 1.0), ("2 s", 2.0), ("5 s", 5.0)])
                    .frame(width: 150)
            }
            row("Enemies shown") {
                ScouterSegmented(selection: $monitor.enemyCount,
                                 options: [("3", 3), ("6", 6), ("10", 10)])
                    .frame(width: 150)
            }
            row("Power level in the menu bar") {
                Toggle("Power level in the menu bar", isOn: $monitor.showNumber)
                    .toggleStyle(ScouterToggleStyle())
            }
            row("Say \u{201C}It's over 9000!\u{201D} out loud") {
                Toggle("Shout at 9000", isOn: $monitor.shoutEnabled)
                    .toggleStyle(ScouterToggleStyle())
            }
            row("Start at login") {
                Toggle("Start at login", isOn: Binding(get: { launchAtLogin }, set: { setLaunchAtLogin($0) }))
                    .toggleStyle(ScouterToggleStyle())
            }
            if let loginError {
                Text(loginError).font(.caption).foregroundStyle(.orange)
            }

            Divider().overlay(Scouter.green.opacity(0.3))
            HStack {
                Text(AboutPanel.version)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Scouter.dim)
                Spacer()
                Button("About") { AboutPanel.show() }
                    .buttonStyle(ScouterButtonStyle())
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 30)
        .padding(.bottom, 18)
        .frame(width: 380)
        .background(Scouter.background)
        .foregroundStyle(Scouter.green)
    }

    private func row(_ label: String, @ViewBuilder _ control: () -> some View) -> some View {
        HStack {
            Text(label).font(.system(size: 12, design: .monospaced))
            Spacer()
            control()
        }
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Couldn't change the login item: \(error.localizedDescription)"
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
