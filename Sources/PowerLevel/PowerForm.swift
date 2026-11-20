import SwiftUI

enum PowerScale {
    /// Power level per 1% CPU. 120 means "over 9000" kicks in at 75% total CPU.
    static let perPercent: Double = 120
    static let max: Double = 100 * perPercent   // 12,000 at 100% CPU
    static let over9000 = 9000
}

/// Transformation tiers, picked from the current power level. The raw value is the mascot frame index.
enum PowerForm: Int, CaseIterable {
    case base, kaioken, superSaiyan, superSaiyan2, superSaiyan3, god, blue, ultraInstinct

    /// Each form starts at this power level; the top form is anything over 9000.
    var floor: Int {
        switch self {
        case .base: 0
        case .kaioken: 1000
        case .superSaiyan: 2000
        case .superSaiyan2: 3500
        case .superSaiyan3: 5000
        case .god: 6500
        case .blue: 7800
        case .ultraInstinct: PowerScale.over9000 + 1
        }
    }

    init(level: Int) {
        self = Self.allCases.last { level >= $0.floor } ?? .base
    }

    var title: String {
        switch self {
        case .base: "Base Form"
        case .kaioken: "Kaioken"
        case .superSaiyan: "Super Saiyan"
        case .superSaiyan2: "Super Saiyan 2"
        case .superSaiyan3: "Super Saiyan 3"
        case .god: "Super Saiyan God"
        case .blue: "Super Saiyan Blue"
        case .ultraInstinct: "Ultra Instinct"
        }
    }

    var quote: String {
        switch self {
        case .base: "Your Mac is meditating."
        case .kaioken: "Warming up. Nothing to worry about."
        case .superSaiyan: "Something is powering up..."
        case .superSaiyan2: "Sparks are flying."
        case .superSaiyan3: "Fans are getting nervous."
        case .god: "This is getting serious."
        case .blue: "Right at the edge of 9000."
        case .ultraInstinct: "IT'S OVER 9000!"
        }
    }

    var symbol: String {
        switch self {
        case .base: "circle.dotted"
        case .kaioken: "flame"
        case .superSaiyan: "bolt"
        case .superSaiyan2: "bolt.fill"
        case .superSaiyan3: "bolt.circle.fill"
        case .god: "flame.fill"
        case .blue: "sparkles"
        case .ultraInstinct: "burst.fill"
        }
    }

    var color: Color {
        switch self {
        case .base: Scouter.green
        case .kaioken: .red
        case .superSaiyan: .yellow
        case .superSaiyan2: Color(red: 1.0, green: 0.85, blue: 0.2)
        case .superSaiyan3: Color(red: 1.0, green: 0.66, blue: 0.08)
        case .god: Color(red: 1.0, green: 0.22, blue: 0.44)
        case .blue: Color(red: 0.22, green: 0.72, blue: 1.0)
        case .ultraInstinct: Color(red: 0.84, green: 0.89, blue: 1.0)
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
