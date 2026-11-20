import SwiftUI

enum PowerScale {
    /// Power level per 1% CPU. 120 means "over 9000" kicks in at 75% total CPU.
    static let perPercent: Double = 120
    static let max: Double = 100 * perPercent   // 12,000 at 100% CPU
    static let over9000 = 9000
}

/// Transformation tiers, picked from the current power level.
enum PowerForm: Equatable {
    case base, kaioken, superSaiyan, superSaiyan2, over9000

    init(level: Int) {
        switch level {
        case ..<1000: self = .base
        case ..<3000: self = .kaioken
        case ..<6000: self = .superSaiyan
        case ...PowerScale.over9000: self = .superSaiyan2
        default: self = .over9000
        }
    }

    var title: String {
        switch self {
        case .base: "Base Form"
        case .kaioken: "Kaioken"
        case .superSaiyan: "Super Saiyan"
        case .superSaiyan2: "Super Saiyan 2"
        case .over9000: "IT'S OVER 9000!"
        }
    }

    var quote: String {
        switch self {
        case .base: "Your Mac is meditating."
        case .kaioken: "Warming up. Nothing to worry about."
        case .superSaiyan: "Something is powering up..."
        case .superSaiyan2: "Fans are getting nervous."
        case .over9000: "What?! There's no way that can be right!"
        }
    }

    var symbol: String {
        switch self {
        case .base: "circle.dotted"
        case .kaioken: "flame"
        case .superSaiyan: "bolt"
        case .superSaiyan2: "bolt.fill"
        case .over9000: "burst.fill"
        }
    }

    var color: Color {
        switch self {
        case .base: Scouter.green
        case .kaioken: .red
        case .superSaiyan: .yellow
        case .superSaiyan2: Color(red: 1.0, green: 0.85, blue: 0.2)
        case .over9000: .orange
        }
    }
}

extension ProcessInfo.ThermalState {
    var kiHeat: String {
        switch self {
        case .nominal: "Calm"
        case .fair: "Warm"
        case .serious: "Overheating!"
        case .critical: "Ki meltdown!!"
        @unknown default: "Unknown"
        }
    }

    var isHot: Bool { self == .serious || self == .critical }
}
