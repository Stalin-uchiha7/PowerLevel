import SwiftUI
import AppKit

/// Original 8-bit mascot, drawn in code from `PixelSprite`: a spiky-haired fighter with a scouter visor whose pose, face,
/// hair and aura follow the form. It is a static drawing, so it only redraws when the form changes.
struct MascotView: View {
    let form: PowerForm

    private var tier: Int {
        switch form {
        case .base: 0
        case .kaioken: 1
        case .superSaiyan: 2
        case .superSaiyan2: 3
        case .over9000: 4
        }
    }

    private static let palette: [Character: Color] = [
        "k": Color(red: 0.23, green: 0.23, blue: 0.33),
        "K": Color(red: 0.36, green: 0.36, blue: 0.50),
        "s": Color(red: 0.95, green: 0.76, blue: 0.49),
        "S": Color(red: 1.00, green: 0.87, blue: 0.66),
        "d": Color(red: 0.78, green: 0.53, blue: 0.26),
        "g": Color(red: 0.15, green: 0.69, blue: 0.57),
        "G": Color(red: 0.09, green: 0.47, blue: 0.39),
        "v": Scouter.green,
        "V": Color(red: 0.11, green: 0.60, blue: 0.31),
        "e": Color(red: 0.08, green: 0.08, blue: 0.11),
        "w": .white,
        "o": Color(red: 0.48, green: 0.48, blue: 0.61),
        "O": Color(red: 0.29, green: 0.29, blue: 0.40),
        "p": Color(red: 0.61, green: 0.42, blue: 0.88),
        "m": Color(red: 0.54, green: 0.17, blue: 0.17),
    ]
    /// Cells drawn in the form colour, with a white or black wash on top (positive lightens, negative darkens).
    private static let accentWash: [Character: Double] = ["b": 0, "A": 0, "B": -0.3, "H": 0.25, "L": 0.65]

    var body: some View {
        let rows = PixelSprite.frames[tier].map { Array($0) }
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
        let forms: [(String, PowerForm)] = [
            ("0-base", .base), ("1-kaioken", .kaioken), ("2-super", .superSaiyan),
            ("3-super2", .superSaiyan2), ("4-over9000", .over9000),
        ]
        for (name, form) in forms {
            save(MascotView(form: form).frame(width: 160, height: 208).background(Scouter.background),
                 to: dir.appendingPathComponent("\(name).png"))
        }
        save(ScouterView(monitor: SystemMonitor()), to: dir.appendingPathComponent("popover.png"))
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
