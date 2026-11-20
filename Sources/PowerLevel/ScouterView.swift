import SwiftUI
import AppKit

enum Scouter {
    static let green = Color(red: 0.25, green: 1.0, blue: 0.5)
    static let dim = green.opacity(0.55)
    static let background = Color(red: 0.02, green: 0.08, blue: 0.04)
}

/// The popover: a green scouter-style HUD.
struct ScouterView: View {
    @ObservedObject var monitor: SystemMonitor
    @State private var confirmForce: pid_t?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Sparkline(values: monitor.history,
                      capacity: SystemMonitor.historyLength,
                      maxValue: PowerScale.max,
                      threshold: Double(PowerScale.over9000))
                .frame(height: 44)
            stats
            Divider().overlay(Scouter.green.opacity(0.3))
            enemyList
            if let message = monitor.lastMessage {
                Text(message).font(.caption).foregroundStyle(.orange)
            }
            footer
        }
        .padding(14)
        .frame(width: 330)
        .background(Scouter.background)
        .foregroundStyle(Scouter.green)
        .font(.system(.body, design: .monospaced))
    }

    // MARK: Sections

    private var header: some View {
        let form = monitor.form
        return VStack(alignment: .leading, spacing: 4) {
            Text("SCOUTER // POWER LEVEL")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Scouter.dim)
            HStack(alignment: .center) {
                Text(monitor.powerLevel, format: .number)
                    .font(.system(size: 42, weight: .heavy, design: .monospaced))
                Spacer()
                MascotView(form: form)
                    .frame(width: 80, height: 104)
            }
            Text(form.title)
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(form.color)
            Text(form.quote)
                .font(.caption)
                .foregroundStyle(Scouter.dim)
        }
    }

    private var stats: some View {
        VStack(spacing: 6) {
            statRow("KI (CPU)", String(format: "%.0f%%", monitor.cpuPercent))
            statRow("STAMINA (RAM)",
                    "\(bytes(monitor.memoryUsed)) / \(bytes(monitor.memoryTotal))")
            statRow("KI HEAT", monitor.thermal.kiHeat,
                    color: monitor.thermal.isHot ? .red : Scouter.green)
        }
    }

    private var enemyList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ENEMIES DETECTED")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Scouter.dim)
            if monitor.enemies.isEmpty {
                Text("Scanning...").font(.caption)
            }
            ForEach(monitor.enemies) { enemy in
                enemyRow(enemy)
            }
        }
    }

    private func enemyRow(_ enemy: Enemy) -> some View {
        HStack(spacing: 8) {
            Group {
                if let icon = enemy.icon {
                    Image(nsImage: icon).resizable()
                } else {
                    Image(systemName: "person.fill.questionmark")
                }
            }
            .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 0) {
                Text(enemy.name).font(.caption).lineLimit(1)
                Text("PL \(enemy.powerLevel.formatted()) · \(bytes(enemy.memoryBytes))")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Scouter.dim)
            }
            Spacer()
            Button("Blast") { monitor.blast(enemy, force: false) }
                .help("Quit the process (SIGTERM)")
            Button(confirmForce == enemy.id ? "Sure?" : "Force") {
                if confirmForce == enemy.id {
                    monitor.blast(enemy, force: true)
                    confirmForce = nil
                } else {
                    confirmForce = enemy.id
                }
            }
            .help("Force kill (SIGKILL). Click twice.")
            .foregroundStyle(confirmForce == enemy.id ? .red : Scouter.green)
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
    }

    private var footer: some View {
        HStack {
            Button("Settings") { SettingsPanel.show(monitor: monitor) }
                .controlSize(.small)
            Button("About") { AboutPanel.show() }
                .controlSize(.small)
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .controlSize(.small)
        }
    }

    // MARK: Helpers

    private func statRow(_ label: String, _ value: String, color: Color = Scouter.green) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(Scouter.dim)
            Spacer()
            Text(value).font(.system(.caption, design: .monospaced)).foregroundStyle(color)
        }
    }

    private func bytes(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory)
    }
}

/// Power-level history with a dashed line at 9000.
struct Sparkline: View {
    let values: [Int]
    let capacity: Int
    let maxValue: Double
    let threshold: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let step = w / CGFloat(max(capacity - 1, 1))
            let offset = CGFloat(capacity - values.count) * step

            ZStack {
                Path { p in
                    let y = h - h * CGFloat(threshold / maxValue)
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: w, y: y))
                }
                .stroke(Color.orange.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                Path { p in
                    for (i, v) in values.enumerated() {
                        let ratio = min(Double(v), maxValue) / maxValue
                        let point = CGPoint(x: offset + CGFloat(i) * step, y: h - h * CGFloat(ratio))
                        if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
                    }
                }
                .stroke(Scouter.green, lineWidth: 1.5)
            }
        }
    }
}
