import AppKit
import SwiftUI

/// "About Power Level": a small native window with the mascot, version, what the app is and link buttons.
enum AboutPanel {
    static let repo = URL(string: "https://github.com/Stalin-uchiha7/PowerLevel")!
    static let links: [(String, URL)] = [
        ("GitHub", repo),
        ("Releases", URL(string: "https://github.com/Stalin-uchiha7/PowerLevel/releases")!),
        ("Report an Issue", URL(string: "https://github.com/Stalin-uchiha7/PowerLevel/issues/new")!),
        ("License", URL(string: "https://github.com/Stalin-uchiha7/PowerLevel/blob/main/LICENSE")!),
    ]
    static let tagline = "Your Mac's CPU load as a scouter power level."
    static let privacy = "No network access, no telemetry, no root."
    static let disclaimer = "Unofficial fan project. Not affiliated with or endorsed by the owners of Dragon Ball."

    static var version: String {
        let info = Bundle.main.infoDictionary
        guard let short = info?["CFBundleShortVersionString"] as? String else { return "Development build" }
        let build = info?["CFBundleVersion"] as? String
        return build.map { "Version \(short) (\($0))" } ?? "Version \(short)"
    }

    @MainActor private static var window: NSWindow?

    @MainActor static func show() {
        let w = window ?? makeWindow()
        if window == nil { w.center() }
        window = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    @MainActor private static func makeWindow() -> NSWindow {
        let host = NSHostingView(rootView: AboutView())
        let w = AboutWindow(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                            styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        w.title = "About Power Level"
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.isMovableByWindowBackground = true
        w.isReleasedWhenClosed = false
        w.backgroundColor = NSColor(Scouter.background)
        w.contentView = host
        w.setContentSize(host.fittingSize)
        return w
    }
}

/// Closes on Escape, like the standard About panel.
private final class AboutWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) { close() }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 10) {
            MascotView(form: .superSaiyan)
                .frame(width: 100, height: 130)
            Text("Power Level")
                .font(.system(size: 24, weight: .heavy, design: .monospaced))
            Text(AboutPanel.version)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Scouter.dim)
                .textSelection(.enabled)
            Text(AboutPanel.tagline)
                .font(.callout)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                ForEach(AboutPanel.links, id: \.0) { link in
                    Button(link.0) { NSWorkspace.shared.open(link.1) }
                        .controlSize(.small)
                }
            }
            .padding(.top, 4)
            Divider().overlay(Scouter.green.opacity(0.3))
            VStack(spacing: 3) {
                Text(AboutPanel.privacy)
                Text("MIT License · Inspired by MacLens")
                Text(AboutPanel.disclaimer)
            }
            .font(.caption2)
            .foregroundStyle(Scouter.dim)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 18)
        .frame(width: 380)
        .background(Scouter.background)
        .foregroundStyle(Scouter.green)
    }
}
