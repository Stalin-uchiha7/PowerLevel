import SwiftUI
import AppKit

/// Original mascot, drawn in code: a small scouter-wearing fighter whose pose, face, crest and aura follow the form.
/// It is a static drawing, so it only redraws when the form changes.
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

    var body: some View {
        let tier = self.tier
        let accent = form.color
        return Canvas { ctx, size in
            let s = min(size.width, size.height) / 100
            func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            func r(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect {
                CGRect(x: x * s, y: y * s, width: w * s, height: h * s)
            }
            func line(_ points: [(Double, Double)]) -> Path {
                var path = Path()
                for (i, pt) in points.enumerated() {
                    if i == 0 { path.move(to: p(pt.0, pt.1)) } else { path.addLine(to: p(pt.0, pt.1)) }
                }
                return path
            }
            func curve(_ from: (Double, Double), _ to: (Double, Double), _ control: (Double, Double)) -> Path {
                var path = Path()
                path.move(to: p(from.0, from.1))
                path.addQuadCurve(to: p(to.0, to.1), control: p(control.0, control.1))
                return path
            }
            func pen(_ width: Double) -> StrokeStyle {
                StrokeStyle(lineWidth: width * s, lineCap: .round, lineJoin: .round)
            }

            let outline = Scouter.green
            let skin = Color(red: 0.06, green: 0.22, blue: 0.13)
            let suit = Color(red: 0.10, green: 0.34, blue: 0.20)

            // Aura: grows with each form.
            if tier > 0 {
                let hw = 26.0 + 4.0 * Double(tier)
                let hh = 36.0 + 3.0 * Double(tier)
                ctx.fill(Path(ellipseIn: r(50 - hw, 52 - hh, hw * 2, hh * 2)), with: .color(accent.opacity(0.14)))
                ctx.fill(Path(ellipseIn: r(50 - hw * 0.7, 56 - hh * 0.75, hw * 1.4, hh * 1.5)),
                         with: .color(accent.opacity(0.16)))
                if tier == 4 {
                    ctx.stroke(Path(ellipseIn: r(50 - hw, 52 - hh, hw * 2, hh * 2)),
                               with: .color(accent.opacity(0.6)), style: pen(1.2))
                }
            }

            // Crest: a flame on top of the head that gets taller with each form.
            let crestH = 9.0 + 5.0 * Double(tier)
            let crestW = 6.0 + 1.5 * Double(tier)
            var crest = Path()
            crest.move(to: p(50 - crestW, 24))
            crest.addQuadCurve(to: p(52, 24 - crestH), control: p(50 - crestW, 24 - crestH * 0.6))
            crest.addQuadCurve(to: p(50 + crestW, 24), control: p(50 + crestW, 24 - crestH * 0.35))
            crest.closeSubpath()
            ctx.fill(crest, with: .color(tier == 0 ? outline.opacity(0.7) : accent))

            // Legs and arms. Arms rise as the power level does.
            ctx.stroke(line([(44, 85), (42, 96)]), with: .color(outline), style: pen(5))
            ctx.stroke(line([(56, 85), (58, 96)]), with: .color(outline), style: pen(5))
            let hands: (left: (Double, Double), right: (Double, Double))
            switch tier {
            case 0, 1: hands = ((29, 80), (71, 80))
            case 2, 3: hands = ((25, 58), (75, 58))
            default: hands = ((28, 44), (72, 44))
            }
            ctx.stroke(line([(39, 66), hands.left]), with: .color(outline), style: pen(5))
            ctx.stroke(line([(61, 66), hands.right]), with: .color(outline), style: pen(5))

            // Body with a belt in the form colour.
            let body = Path(roundedRect: r(38, 58, 24, 29), cornerRadius: 6 * s)
            ctx.fill(body, with: .color(suit))
            ctx.stroke(body, with: .color(outline), style: pen(1.5))
            ctx.stroke(line([(39, 76), (61, 76)]), with: .color(accent), style: pen(3))

            // Head.
            let head = Path(ellipseIn: r(30, 20, 40, 40))
            ctx.fill(head, with: .color(skin))
            ctx.stroke(head, with: .color(outline), style: pen(1.5))

            // Scouter: earpiece plus a tinted lens over the left eye.
            ctx.fill(Path(roundedRect: r(26, 33, 6, 13), cornerRadius: 2 * s), with: .color(outline))
            ctx.fill(Path(ellipseIn: r(37.8, 36.8, 4.4, 4.4)), with: .color(outline))
            let lens = Path(roundedRect: r(31, 32, 17, 12), cornerRadius: 3 * s)
            ctx.fill(lens, with: .color(accent.opacity(0.4)))
            ctx.stroke(lens, with: .color(accent), style: pen(1.2))

            // Right eye and brow.
            switch tier {
            case 0:
                ctx.stroke(curve((56, 39), (64, 39), (60, 43)), with: .color(outline), style: pen(1.8))
            case 4:
                ctx.stroke(Path(ellipseIn: r(55.5, 34.5, 9, 9)), with: .color(outline), style: pen(1.5))
                ctx.fill(Path(ellipseIn: r(58.5, 37.5, 3, 3)), with: .color(outline))
            default:
                ctx.fill(Path(ellipseIn: r(57.8, 36.8, 4.4, 4.4)), with: .color(outline))
            }
            if tier >= 2 && tier < 4 {
                ctx.stroke(line([(54, 34), (65, 31 - Double(tier - 2))]), with: .color(outline), style: pen(2))
            }

            // Mouth.
            switch tier {
            case 0:
                ctx.stroke(curve((45, 49), (55, 49), (50, 54)), with: .color(outline), style: pen(1.8))
            case 1:
                ctx.stroke(line([(45, 51), (55, 51)]), with: .color(outline), style: pen(1.8))
            case 4:
                let mouth = Path(ellipseIn: r(45, 46, 10, 9))
                ctx.fill(mouth, with: .color(Scouter.background))
                ctx.stroke(mouth, with: .color(outline), style: pen(1.5))
            default:
                ctx.stroke(curve((45, 52), (55, 52), (50, 48)), with: .color(outline), style: pen(2))
            }

            // Sparks at the top forms.
            if tier >= 3 {
                ctx.stroke(line([(13, 28), (19, 35), (14, 39), (20, 47)]), with: .color(accent), style: pen(1.5))
                ctx.stroke(line([(87, 22), (81, 30), (86, 34), (80, 42)]), with: .color(accent), style: pen(1.5))
            }
            if tier == 4 {
                ctx.stroke(line([(18, 70), (12, 77), (17, 80), (11, 88)]), with: .color(accent), style: pen(1.5))
                ctx.stroke(line([(83, 66), (89, 73), (84, 77), (90, 85)]), with: .color(accent), style: pen(1.5))
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
            save(MascotView(form: form).frame(width: 128, height: 128).background(Scouter.background),
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
