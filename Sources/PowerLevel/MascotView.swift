import SwiftUI
import AppKit

/// Original 8-bit mascot, drawn in code from `PixelSprite`: a spiky-haired fighter whose pose, face,
/// hair and aura follow the form. It is a static drawing, so it only redraws when the form changes.
struct MascotView: View {
    let form: PowerForm

    private static let palette: [Character: Color] = [
        "k": Color(red: 0.23, green: 0.23, blue: 0.33),
        "K": Color(red: 0.36, green: 0.36, blue: 0.50),
        "s": Color(red: 0.95, green: 0.76, blue: 0.49),
        "S": Color(red: 1.00, green: 0.87, blue: 0.66),
        "d": Color(red: 0.78, green: 0.53, blue: 0.26),
        "g": Color(red: 0.94, green: 0.48, blue: 0.09),
        "F": Color(red: 1.00, green: 0.65, blue: 0.32),
        "j": Color(red: 0.14, green: 0.14, blue: 0.22),
        "G": Color(red: 0.69, green: 0.31, blue: 0.04),
        "e": Color(red: 0.08, green: 0.08, blue: 0.11),
        "w": .white,
        "o": Color(red: 0.29, green: 0.29, blue: 0.36),
        "O": Color(red: 0.15, green: 0.15, blue: 0.20),
        "p": Color(red: 0.95, green: 0.93, blue: 0.88),
        "m": Color(red: 0.54, green: 0.17, blue: 0.17),
    ]
    /// Cells drawn in the form colour, with a white or black wash on top (positive lightens, negative darkens).
    private static let accentWash: [Character: Double] = ["b": 0, "A": 0, "B": -0.3, "h": -0.18, "H": 0.25, "L": 0.65]

    var body: some View {
        let rows = PixelSprite.frames[form.rawValue].map { Array($0) }
        let accent = form.color
        return Canvas { ctx, size in
            guard let width = rows.first?.count, width > 0 else { return }
            // Whole half-points per pixel keep the edges crisp on Retina.
            let fit = min(size.width / Double(width), size.height / Double(rows.count))
            let px = max((fit * 2).rounded(.down) / 2, 0.5)
            let ox = ((size.width - px * Double(width)) / 2).rounded()
            let oy = ((size.height - px * Double(rows.count)) / 2).rounded()
            for (y, row) in rows.enumerated() {
                for (x, cell) in row.enumerated() where cell != "." {
                    let rect = Path(CGRect(x: ox + Double(x) * px, y: oy + Double(y) * px, width: px, height: px))
                    if let wash = Self.accentWash[cell] {
                        ctx.fill(rect, with: .color(accent))
                        if wash != 0 { ctx.fill(rect, with: .color((wash > 0 ? Color.white : .black).opacity(abs(wash)))) }
                    } else if cell == "a" {
                        ctx.fill(rect, with: .color(accent.opacity(0.45)))
                    } else if let color = Self.palette[cell] {
                        ctx.fill(rect, with: .color(color))
                    }
                }
            }
        }
        .accessibilityLabel("Mascot, \(form.title)")
    }
}

/// `--mascot-snapshot DIR` renders the mascot in every form (plus the popover) to PNGs and quits. For visual checks.
@MainActor
enum MascotSnapshot {
    static func write(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for form in PowerForm.allCases {
            save(MascotView(form: form).frame(width: 160, height: 208).background(Scouter.background),
                 to: dir.appendingPathComponent("form-\(form.rawValue).png"))
        }
        let lineup = HStack(alignment: .top, spacing: 10) {
            ForEach(PowerForm.allCases, id: \.rawValue) { form in
                VStack(spacing: 4) {
                    MascotView(form: form).frame(width: 80, height: 104)
                    Text(form.title).foregroundStyle(form.color)
                    Text(form == .ultraInstinct ? "9,001+" : "\(form.floor.formatted())+").foregroundStyle(Scouter.dim)
                }
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .frame(width: 96)
            }
        }
        .padding(14)
        .background(Scouter.background)
        save(lineup, to: dir.appendingPathComponent("forms.png"))
        save(ScouterView(monitor: SystemMonitor()), to: dir.appendingPathComponent("popover.png"))
        save(AboutView(), to: dir.appendingPathComponent("about.png"))
        save(SettingsView(monitor: SystemMonitor()), to: dir.appendingPathComponent("settings.png"))
    }

    private static func save(_ view: some View, to url: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }
}
