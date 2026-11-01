import SwiftUI

public struct ChunkyTheme {
    public static let skyTop = Color(red: 0.38, green: 0.78, blue: 1.00)
    public static let skyBottom = Color(red: 0.14, green: 0.62, blue: 0.98)

    public static let sheetBg = Color.white

    public static let emberTop = Color(red: 1.00, green: 0.48, blue: 0.22)
    public static let emberBottom = Color(red: 0.94, green: 0.32, blue: 0.15)
    public static let emberCore = Color(red: 1.00, green: 0.86, blue: 0.38)

    public static let textPrimary = Color(red: 0.12, green: 0.16, blue: 0.24)
    public static let textMuted = Color(red: 0.46, green: 0.53, blue: 0.64)

    public static let urgentAccent = Color(red: 0.94, green: 0.25, blue: 0.28)
    public static let butterYellow = Color(red: 1.00, green: 0.86, blue: 0.38)
    public static let pillBlue = Color(red: 0.20, green: 0.52, blue: 0.82)

    public static let hardShadow = Color(red: 0.10, green: 0.26, blue: 0.40).opacity(0.28)
    public static let characterShadow = Color(red: 0.08, green: 0.20, blue: 0.32).opacity(0.32)

    public static let editorialCardBorder = Color.black.opacity(0.06)
    public static let editorialHairline = Color.primary.opacity(0.05)
    public static let editorialPillBg = Color(red: 0.94, green: 0.96, blue: 0.98)

    public static let skyGradient = LinearGradient(colors: [skyTop, skyBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    public static let emberGradient = LinearGradient(colors: [emberTop, emberBottom], startPoint: .top, endPoint: .bottom)

    public static let flameOuterGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 1.00, green: 0.48, blue: 0.22), location: 0.0),
            .init(color: Color(red: 0.98, green: 0.32, blue: 0.14), location: 0.52),
            .init(color: Color(red: 0.85, green: 0.18, blue: 0.08), location: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let flameInnerGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 1.00, green: 0.95, blue: 0.65).opacity(0.96), location: 0.0),
            .init(color: Color(red: 1.00, green: 0.76, blue: 0.25).opacity(0.85), location: 0.50),
            .init(color: Color(red: 0.98, green: 0.44, blue: 0.14).opacity(0.25), location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.50, y: 0.18),
        endPoint: UnitPoint(x: 0.50, y: 0.86)
    )

    public static let flameCoreGradient = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.95), location: 0.0),
            .init(color: Color(red: 1.00, green: 0.96, blue: 0.70).opacity(0.80), location: 0.50),
            .init(color: Color(red: 1.00, green: 0.82, blue: 0.35).opacity(0.0), location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.50, y: 0.34),
        endPoint: UnitPoint(x: 0.50, y: 0.78)
    )

    public static let crestGlossGradient = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.0), location: 0.0),
            .init(color: Color.white.opacity(0.90), location: 0.25),
            .init(color: Color.white.opacity(0.95), location: 0.65),
            .init(color: Color.white.opacity(0.0), location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.58, y: 0.11),
        endPoint: UnitPoint(x: 0.39, y: 0.25)
    )

    public static let leftTongueGlossGradient = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.0), location: 0.0),
            .init(color: Color.white.opacity(0.85), location: 0.35),
            .init(color: Color.white.opacity(0.95), location: 0.70),
            .init(color: Color.white.opacity(0.0), location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.33, y: 0.30),
        endPoint: UnitPoint(x: 0.185, y: 0.41)
    )

    public static let leftCheekGlossGradient = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.0), location: 0.0),
            .init(color: Color.white.opacity(0.85), location: 0.35),
            .init(color: Color.white.opacity(0.65), location: 0.75),
            .init(color: Color.white.opacity(0.0), location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.185, y: 0.48),
        endPoint: UnitPoint(x: 0.24, y: 0.72)
    )

    public static let rightTipGlossGradient = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.0), location: 0.0),
            .init(color: Color.white.opacity(0.65), location: 0.40),
            .init(color: Color.white.opacity(0.0), location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.60, y: 0.10),
        endPoint: UnitPoint(x: 0.63, y: 0.22)
    )

    public static let rightTongueGlossGradient = LinearGradient(
        stops: [
            .init(color: Color.white.opacity(0.0), location: 0.0),
            .init(color: Color.white.opacity(0.60), location: 0.40),
            .init(color: Color.white.opacity(0.0), location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.70, y: 0.38),
        endPoint: UnitPoint(x: 0.82, y: 0.46)
    )

    public static let stressedSweatDropGradient = LinearGradient(
        colors: [Color(red: 0.45, green: 0.88, blue: 1.0), Color(red: 0.10, green: 0.65, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let celebratingMouthGradient = LinearGradient(
        colors: [Color(red: 0.24, green: 0.08, blue: 0.13), Color(red: 0.10, green: 0.04, blue: 0.06)],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let celebratingTongueGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.50, blue: 0.64),
            Color(red: 1.00, green: 0.32, blue: 0.49),
            Color(red: 0.90, green: 0.16, blue: 0.34)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

public enum EmberEmotion: String, CaseIterable, Sendable {
    case normal
    case stressed
    case sleeping
    case celebrating
}
