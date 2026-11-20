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
                Picker("Refresh every", selection: $monitor.refreshInterval) {
                    Text("1 s").tag(1.0)
                    Text("2 s").tag(2.0)
                    Text("5 s").tag(5.0)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 150)
            }
            row("Enemies shown") {
                Picker("Enemies shown", selection: $monitor.enemyCount) {
                    Text("3").tag(3)
                    Text("6").tag(6)
                    Text("10").tag(10)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 150)
            }
            row("Power level in the menu bar") {
                Toggle("Power level in the menu bar", isOn: $monitor.showNumber)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
            }
            row("Say \u{201C}It's over 9000!\u{201D} out loud") {
                Toggle("Shout at 9000", isOn: $monitor.shoutEnabled)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
            }
            row("Start at login") {
                Toggle("Start at login", isOn: Binding(get: { launchAtLogin }, set: { setLaunchAtLogin($0) }))
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
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
                    .controlSize(.small)
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
            Text(label).font(.callout)
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
