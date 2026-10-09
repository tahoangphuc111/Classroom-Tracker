import SwiftUI
import WidgetKit

// MARK: - Chunky Ember Theme
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

    public static var skyGradient: LinearGradient {
        LinearGradient(colors: [skyTop, skyBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    public static var emberGradient: LinearGradient {
        LinearGradient(colors: [emberTop, emberBottom], startPoint: .top, endPoint: .bottom)
    }
}

public enum EmberEmotion: String, CaseIterable, Sendable {
    case normal
    case stressed
    case sleeping
    case celebrating
}

// MARK: - Flame Shapes
public struct StandardEmberFlameOuter: Shape {
    let isUrgent: Bool
    let isSleeping: Bool

    public init(isUrgent: Bool = false, isSleeping: Bool = false) {
        self.isUrgent = isUrgent
        self.isSleeping = isSleeping
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.50

        path.move(to: CGPoint(x: cx, y: h * 0.91))

        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.70),
            control1: CGPoint(x: w * 0.64, y: h * 0.91),
            control2: CGPoint(x: w * 0.78, y: h * 0.82)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.45),
            control1: CGPoint(x: w * 0.78, y: h * 0.58),
            control2: CGPoint(x: w * 0.85, y: h * 0.51)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.67, y: h * 0.36),
            control1: CGPoint(x: w * 0.82, y: h * 0.39),
            control2: CGPoint(x: w * 0.71, y: h * 0.38)
        )

        let apexY = isUrgent ? h * 0.05 : (isSleeping ? h * 0.10 : h * 0.08)
        let apexX = isSleeping ? w * 0.63 : w * 0.61
        path.addCurve(
            to: CGPoint(x: apexX, y: apexY),
            control1: CGPoint(x: w * 0.61, y: h * 0.24),
            control2: CGPoint(x: w * 0.65, y: h * 0.16)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.37, y: h * 0.25),
            control1: CGPoint(x: w * 0.53, y: apexY),
            control2: CGPoint(x: w * 0.42, y: h * 0.17)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.16, y: h * 0.40),
            control1: CGPoint(x: w * 0.29, y: h * 0.29),
            control2: CGPoint(x: w * 0.16, y: h * 0.33)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.70),
            control1: CGPoint(x: w * 0.16, y: h * 0.52),
            control2: CGPoint(x: w * 0.19, y: h * 0.62)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: h * 0.91),
            control1: CGPoint(x: w * 0.22, y: h * 0.82),
            control2: CGPoint(x: w * 0.36, y: h * 0.91)
        )

        path.closeSubpath()
        return path
    }
}

// Backward compatibility alias
public typealias Concept1FlameOuter = StandardEmberFlameOuter

public struct StandardEmberFlameInner: Shape {
    let isSleeping: Bool

    public init(isSleeping: Bool = false) {
        self.isSleeping = isSleeping
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.50

        path.move(to: CGPoint(x: cx, y: h * 0.86))

        path.addCurve(
            to: CGPoint(x: w * 0.73, y: h * 0.67),
            control1: CGPoint(x: w * 0.62, y: h * 0.86),
            control2: CGPoint(x: w * 0.73, y: h * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.47),
            control1: CGPoint(x: w * 0.73, y: h * 0.58),
            control2: CGPoint(x: w * 0.78, y: h * 0.52)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.63, y: h * 0.39),
            control1: CGPoint(x: w * 0.76, y: h * 0.41),
            control2: CGPoint(x: w * 0.67, y: h * 0.40)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.18),
            control1: CGPoint(x: w * 0.58, y: h * 0.28),
            control2: CGPoint(x: w * 0.61, y: h * 0.22)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.40, y: h * 0.31),
            control1: CGPoint(x: w * 0.52, y: h * 0.18),
            control2: CGPoint(x: w * 0.44, y: h * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.23, y: h * 0.44),
            control1: CGPoint(x: w * 0.33, y: h * 0.35),
            control2: CGPoint(x: w * 0.23, y: h * 0.38)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.27, y: h * 0.67),
            control1: CGPoint(x: w * 0.23, y: h * 0.54),
            control2: CGPoint(x: w * 0.25, y: h * 0.61)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: h * 0.86),
            control1: CGPoint(x: w * 0.27, y: h * 0.78),
            control2: CGPoint(x: w * 0.38, y: h * 0.86)
        )
        path.closeSubpath()
        return path
    }
}

public struct StandardEmberFlameCore: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.50

        path.move(to: CGPoint(x: cx + w * 0.02, y: h * 0.34))
        path.addCurve(
            to: CGPoint(x: w * 0.66, y: h * 0.62),
            control1: CGPoint(x: w * 0.64, y: h * 0.42),
            control2: CGPoint(x: w * 0.68, y: h * 0.54)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: h * 0.78),
            control1: CGPoint(x: w * 0.64, y: h * 0.74),
            control2: CGPoint(x: cx + w * 0.10, y: h * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.34, y: h * 0.62),
            control1: CGPoint(x: cx - w * 0.10, y: h * 0.78),
            control2: CGPoint(x: w * 0.36, y: h * 0.74)
        )
        path.addCurve(
            to: CGPoint(x: cx + w * 0.02, y: h * 0.34),
            control1: CGPoint(x: w * 0.32, y: h * 0.54),
            control2: CGPoint(x: w * 0.38, y: h * 0.42)
        )
        path.closeSubpath()
        return path
    }
}

public typealias Concept1FlameInner = StandardEmberFlameInner
public typealias HarmoniousFlameCore = StandardEmberFlameInner
public typealias Concept1FlameCore = StandardEmberFlameInner

// MARK: - Specular Highlights
public struct TightMainCrestGlossPath: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.58, y: h * 0.11))
        path.addCurve(
            to: CGPoint(x: w * 0.39, y: h * 0.25),
            control1: CGPoint(x: w * 0.52, y: h * 0.11),
            control2: CGPoint(x: w * 0.43, y: h * 0.18)
        )
        return path
    }
}

public struct TightLeftTongueGlossPath: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.33, y: h * 0.30))
        path.addCurve(
            to: CGPoint(x: w * 0.185, y: h * 0.41),
            control1: CGPoint(x: w * 0.26, y: h * 0.32),
            control2: CGPoint(x: w * 0.185, y: h * 0.35)
        )
        return path
    }
}

public struct TightLeftCheekGlossPath: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.185, y: h * 0.48))
        path.addCurve(
            to: CGPoint(x: w * 0.24, y: h * 0.72),
            control1: CGPoint(x: w * 0.185, y: h * 0.56),
            control2: CGPoint(x: w * 0.21, y: h * 0.65)
        )
        return path
    }
}

public struct TightRightTipGlossPath: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.60, y: h * 0.10))
        path.addCurve(
            to: CGPoint(x: w * 0.63, y: h * 0.22),
            control1: CGPoint(x: w * 0.62, y: h * 0.14),
            control2: CGPoint(x: w * 0.63, y: h * 0.18)
        )
        return path
    }
}

public struct TightRightTongueGlossPath: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.70, y: h * 0.38))
        path.addCurve(
            to: CGPoint(x: w * 0.82, y: h * 0.46),
            control1: CGPoint(x: w * 0.75, y: h * 0.40),
            control2: CGPoint(x: w * 0.80, y: h * 0.43)
        )
        return path
    }
}

public struct EmberSpecularHighlightPath: Shape {
    let isSleeping: Bool

    public init(isSleeping: Bool = false) {
        self.isSleeping = isSleeping
    }

    public func path(in rect: CGRect) -> Path {
        TightMainCrestGlossPath().path(in: rect)
    }
}

public typealias StandardEmberSpecularPath = EmberSpecularHighlightPath

// MARK: - Celebrating Mouth Shapes
public struct CelebratingMouthCavityShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.12), control: CGPoint(x: w * 0.5, y: -h * 0.02))
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w, y: h * 0.56),
            control2: CGPoint(x: w * 0.82, y: h)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.12),
            control1: CGPoint(x: w * 0.18, y: h),
            control2: CGPoint(x: 0, y: h * 0.56)
        )
        path.closeSubpath()
        return path
    }
}

public struct CelebratingTongueShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.04, y: h * 1.15))
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.32),
            control1: CGPoint(x: w * 0.08, y: h * 0.42),
            control2: CGPoint(x: w * 0.32, y: h * 0.28)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.96, y: h * 1.15),
            control1: CGPoint(x: w * 0.68, y: h * 0.28),
            control2: CGPoint(x: w * 0.92, y: h * 0.42)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Character View
public struct ChunkyEmberCharacterView: View {
    let emotion: EmberEmotion
    var size: CGFloat = 76

    private let inkColor = Color(red: 0.12, green: 0.08, blue: 0.06)

    public init(emotion: EmberEmotion, size: CGFloat = 76) {
        self.emotion = emotion
        self.size = size
    }

    public var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.08, green: 0.20, blue: 0.35).opacity(0.24), Color.clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: size * 0.37
                    )
                )
                .frame(width: size * 0.74, height: size * 0.14)
                .offset(y: size * 0.45)

            flameOuterBody
                .frame(width: size, height: size)

            flameInnerBody
                .frame(width: size, height: size)

            flameCoreHeart
                .frame(width: size, height: size)

            flameRimHighlights
                .frame(width: size, height: size)

            blushCheeks
                .frame(width: size, height: size)

            facialFeatures
                .frame(width: size, height: size)

            stateAccessories
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .drawingGroup()
    }

    private var flameOuterBody: some View {
        StandardEmberFlameOuter(isUrgent: emotion == .stressed, isSleeping: emotion == .sleeping)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 1.00, green: 0.48, blue: 0.22), location: 0.0),
                        .init(color: Color(red: 0.98, green: 0.32, blue: 0.14), location: 0.52),
                        .init(color: Color(red: 0.85, green: 0.18, blue: 0.08), location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color(red: 0.86, green: 0.20, blue: 0.10).opacity(0.28), radius: 5, x: 0, y: 2.5)
    }

    private var flameInnerBody: some View {
        StandardEmberFlameInner(isSleeping: emotion == .sleeping)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 1.00, green: 0.95, blue: 0.65).opacity(0.96), location: 0.0),
                        .init(color: Color(red: 1.00, green: 0.76, blue: 0.25).opacity(0.85), location: 0.50),
                        .init(color: Color(red: 0.98, green: 0.44, blue: 0.14).opacity(0.25), location: 1.0)
                    ],
                    startPoint: UnitPoint(x: 0.50, y: 0.18),
                    endPoint: UnitPoint(x: 0.50, y: 0.86)
                )
            )
    }

    private var flameCoreHeart: some View {
        StandardEmberFlameCore()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.95), location: 0.0),
                        .init(color: Color(red: 1.00, green: 0.96, blue: 0.70).opacity(0.80), location: 0.50),
                        .init(color: Color(red: 1.00, green: 0.82, blue: 0.35).opacity(0.0), location: 1.0)
                    ],
                    startPoint: UnitPoint(x: 0.50, y: 0.34),
                    endPoint: UnitPoint(x: 0.50, y: 0.78)
                )
            )
    }

    private var flameRimHighlights: some View {
        ZStack {
            TightMainCrestGlossPath()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),
                            .init(color: Color.white.opacity(0.90), location: 0.25),
                            .init(color: Color.white.opacity(0.95), location: 0.65),
                            .init(color: Color.white.opacity(0.0), location: 1.0)
                        ],
                        startPoint: UnitPoint(x: 0.58, y: 0.11),
                        endPoint: UnitPoint(x: 0.39, y: 0.25)
                    ),
                    style: StrokeStyle(lineWidth: max(2.0, size * 0.024), lineCap: .round)
                )

            TightLeftTongueGlossPath()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),
                            .init(color: Color.white.opacity(0.85), location: 0.35),
                            .init(color: Color.white.opacity(0.95), location: 0.70),
                            .init(color: Color.white.opacity(0.0), location: 1.0)
                        ],
                        startPoint: UnitPoint(x: 0.33, y: 0.30),
                        endPoint: UnitPoint(x: 0.185, y: 0.41)
                    ),
                    style: StrokeStyle(lineWidth: max(2.0, size * 0.023), lineCap: .round)
                )

            TightLeftCheekGlossPath()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),
                            .init(color: Color.white.opacity(0.85), location: 0.35),
                            .init(color: Color.white.opacity(0.65), location: 0.75),
                            .init(color: Color.white.opacity(0.0), location: 1.0)
                        ],
                        startPoint: UnitPoint(x: 0.185, y: 0.48),
                        endPoint: UnitPoint(x: 0.24, y: 0.72)
                    ),
                    style: StrokeStyle(lineWidth: max(2.2, size * 0.025), lineCap: .round)
                )

            TightRightTipGlossPath()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),
                            .init(color: Color.white.opacity(0.65), location: 0.40),
                            .init(color: Color.white.opacity(0.0), location: 1.0)
                        ],
                        startPoint: UnitPoint(x: 0.60, y: 0.10),
                        endPoint: UnitPoint(x: 0.63, y: 0.22)
                    ),
                    style: StrokeStyle(lineWidth: max(1.6, size * 0.016), lineCap: .round)
                )

            TightRightTongueGlossPath()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),
                            .init(color: Color.white.opacity(0.60), location: 0.40),
                            .init(color: Color.white.opacity(0.0), location: 1.0)
                        ],
                        startPoint: UnitPoint(x: 0.70, y: 0.38),
                        endPoint: UnitPoint(x: 0.82, y: 0.46)
                    ),
                    style: StrokeStyle(lineWidth: max(1.6, size * 0.016), lineCap: .round)
                )
        }
    }

    private var blushCheeks: some View {
        HStack(spacing: size * 0.36) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.00, green: 0.30, blue: 0.50).opacity(0.55), Color.clear],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 0.07
                    )
                )
                .frame(width: size * 0.14, height: size * 0.14)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.00, green: 0.30, blue: 0.50).opacity(0.55), Color.clear],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 0.07
                    )
                )
                .frame(width: size * 0.14, height: size * 0.14)
        }
        .offset(x: size * 0.01, y: size * 0.105)
    }

    @ViewBuilder
    private var facialFeatures: some View {
        switch emotion {
        case .normal:
            VStack(spacing: size * 0.035) {
                HStack(spacing: size * 0.16) {
                    eyeView
                    eyeView
                }

                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(to: CGPoint(x: size * 0.10, y: 0), control: CGPoint(x: size * 0.05, y: size * 0.048))
                }
                .stroke(inkColor, style: StrokeStyle(lineWidth: max(2.0, size * 0.020), lineCap: .round))
                .frame(width: size * 0.10, height: size * 0.048)
            }
            .offset(x: size * 0.01, y: size * 0.05)

        case .stressed:
            VStack(spacing: size * 0.03) {
                HStack(spacing: size * 0.16) {
                    eyeView
                    eyeView
                }

                Path { p in
                    p.move(to: CGPoint(x: 0, y: size * 0.015))
                    p.addCurve(
                        to: CGPoint(x: size * 0.09, y: size * 0.015),
                        control1: CGPoint(x: size * 0.03, y: -size * 0.015),
                        control2: CGPoint(x: size * 0.06, y: size * 0.035)
                    )
                }
                .stroke(inkColor, style: StrokeStyle(lineWidth: max(1.8, size * 0.018), lineCap: .round))
                .frame(width: size * 0.09, height: size * 0.035)
            }
            .offset(x: size * 0.01, y: size * 0.05)

        case .sleeping:
            VStack(spacing: size * 0.04) {
                HStack(spacing: size * 0.16) {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: size * 0.02))
                        p.addQuadCurve(to: CGPoint(x: size * 0.095, y: size * 0.02), control: CGPoint(x: size * 0.047, y: 0))
                    }
                    .stroke(inkColor, style: StrokeStyle(lineWidth: max(2.0, size * 0.022), lineCap: .round))
                    .frame(width: size * 0.095, height: size * 0.02)

                    Path { p in
                        p.move(to: CGPoint(x: 0, y: size * 0.02))
                        p.addQuadCurve(to: CGPoint(x: size * 0.095, y: size * 0.02), control: CGPoint(x: size * 0.047, y: 0))
                    }
                    .stroke(inkColor, style: StrokeStyle(lineWidth: max(2.0, size * 0.022), lineCap: .round))
                    .frame(width: size * 0.095, height: size * 0.02)
                }

                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(to: CGPoint(x: size * 0.07, y: 0), control: CGPoint(x: size * 0.035, y: size * 0.03))
                }
                .stroke(inkColor, style: StrokeStyle(lineWidth: max(1.8, size * 0.018), lineCap: .round))
                .frame(width: size * 0.07, height: size * 0.03)
            }
            .offset(x: size * 0.01, y: size * 0.05)

        case .celebrating:
            let mouthW = size * 0.13
            let mouthH = size * 0.072
            VStack(spacing: size * 0.035) {
                HStack(spacing: size * 0.16) {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: size * 0.025))
                        p.addQuadCurve(to: CGPoint(x: size * 0.095, y: size * 0.025), control: CGPoint(x: size * 0.047, y: 0))
                    }
                    .stroke(inkColor, style: StrokeStyle(lineWidth: max(2.2, size * 0.024), lineCap: .round))
                    .frame(width: size * 0.095, height: size * 0.025)

                    Path { p in
                        p.move(to: CGPoint(x: 0, y: size * 0.025))
                        p.addQuadCurve(to: CGPoint(x: size * 0.095, y: size * 0.025), control: CGPoint(x: size * 0.047, y: 0))
                    }
                    .stroke(inkColor, style: StrokeStyle(lineWidth: max(2.2, size * 0.024), lineCap: .round))
                    .frame(width: size * 0.095, height: size * 0.025)
                }

                ZStack {
                    CelebratingMouthCavityShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.24, green: 0.08, blue: 0.13), Color(red: 0.10, green: 0.04, blue: 0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    CelebratingTongueShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.50, blue: 0.64),
                                    Color(red: 1.00, green: 0.32, blue: 0.49),
                                    Color(red: 0.90, green: 0.16, blue: 0.34)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Path { p in
                        p.move(to: CGPoint(x: mouthW * 0.5, y: mouthH * 0.38))
                        p.addLine(to: CGPoint(x: mouthW * 0.5, y: mouthH * 0.68))
                    }
                    .stroke(Color(red: 0.79, green: 0.13, blue: 0.29).opacity(0.85), lineWidth: max(0.8, size * 0.009))

                    Ellipse()
                        .fill(Color.white.opacity(0.42))
                        .frame(width: mouthW * 0.36, height: mouthH * 0.22)
                        .offset(y: -mouthH * 0.06)
                }
                .clipShape(CelebratingMouthCavityShape())
                .overlay(
                    CelebratingMouthCavityShape()
                        .stroke(inkColor, style: StrokeStyle(lineWidth: max(1.8, size * 0.018), lineCap: .round, lineJoin: .round))
                )
                .frame(width: mouthW, height: mouthH)
            }
            .offset(x: size * 0.01, y: size * 0.05)
        }
    }

    private var eyeView: some View {
        ZStack {
            Capsule()
                .fill(inkColor)
                .frame(width: size * 0.10, height: size * 0.155)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.040, height: size * 0.040)
                .offset(x: -size * 0.019, y: -size * 0.036)
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: size * 0.022, height: size * 0.022)
                .offset(x: size * 0.019, y: size * 0.032)
        }
    }

    @ViewBuilder
    private var stateAccessories: some View {
        if emotion == .stressed {
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.88, blue: 1.0), Color(red: 0.10, green: 0.65, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.075, height: size * 0.12)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.95), lineWidth: 0.7)
                    )

                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: size * 0.022, height: size * 0.022)
                    .offset(x: -size * 0.015, y: -size * 0.03)
            }
            .rotationEffect(.degrees(18))
            .offset(x: size * 0.28, y: -size * 0.08)
        } else if emotion == .sleeping {
            VStack(alignment: .trailing, spacing: 2) {
                Text("Z")
                    .font(.system(size: size * 0.12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("z")
                    .font(.system(size: size * 0.08, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
            .offset(x: size * 0.26, y: -size * 0.24)
        } else if emotion == .celebrating {
            ZStack {
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.15, weight: .bold))
                    .foregroundStyle(Color(red: 1.00, green: 0.88, blue: 0.35))
                    .offset(x: -size * 0.32, y: -size * 0.22)
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundStyle(Color(red: 1.00, green: 0.88, blue: 0.35))
                    .offset(x: size * 0.32, y: -size * 0.26)
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.11, weight: .bold))
                    .foregroundStyle(Color(red: 1.00, green: 0.88, blue: 0.35))
                    .offset(x: size * 0.34, y: size * 0.08)
            }
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Medium Widget View
public struct MediumWidgetView: View {
    let courseworkList: [Coursework]
    let isLoggedIn: Bool

    public init(courseworkList: [Coursework], isLoggedIn: Bool = true) {
        self.courseworkList = courseworkList
        self.isLoggedIn = isLoggedIn
    }

    private var sectionHeaderTitle: String {
        let pending = courseworkList.filter { !$0.isCompleted }
        let hasToday = pending.contains(where: \.isDueToday)
        let hasTomorrow = pending.contains(where: \.isDueTomorrow)

        if hasToday && hasTomorrow {
            return "HÔM NAY & MAI"
        } else if hasToday {
            return "HÔM NAY"
        } else if hasTomorrow {
            return "NGÀY MAI"
        } else if !pending.isEmpty {
            return "SẮP TỚI"
        } else if courseworkList.contains(where: \.isDueToday) {
            return "HÔM NAY"
        } else {
            return "NGÀY MAI"
        }
    }

    private var activeItems: [Coursework] {
        courseworkList.filter { !$0.isCompleted }
    }

    private var displayItems: [Coursework] {
        if activeItems.isEmpty {
            return courseworkList
        }
        let completed = courseworkList.filter(\.isCompleted)
        return activeItems + completed
    }

    private var characterEmotion: EmberEmotion {
        if activeItems.isEmpty {
            return courseworkList.contains(where: \.isCompleted) ? .celebrating : .sleeping
        } else if activeItems.count >= 4 {
            return .stressed
        } else {
            return .normal
        }
    }

    private var moodBadgeText: String {
        if activeItems.isEmpty {
            return courseworkList.isEmpty ? "Thảnh thơi" : "Hoàn thành"
        } else if activeItems.count >= 4 {
            return "Tập trung"
        } else {
            return "Sẵn sàng"
        }
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            ChunkyTheme.skyGradient
                .ignoresSafeArea()

            backgroundClouds

            if !isLoggedIn {
                loggedOutMediumView
            } else {
                HStack(spacing: 10) {
                    VStack(spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(activeItems.count)")
                                .font(WidgetFontSystem.counter(size: 32))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black.opacity(0.20), radius: 0, x: 0, y: 1.5)

                            if activeItems.isEmpty && !courseworkList.isEmpty {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(ChunkyTheme.butterYellow)
                            } else {
                                Text(sectionHeaderTitle)
                                    .font(WidgetFontSystem.sectionHeader(size: 9))
                                    .tracking(0.0)
                                    .foregroundStyle(ChunkyTheme.butterYellow)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 0)

                        ChunkyEmberCharacterView(emotion: characterEmotion, size: 76)
                            .padding(.bottom, 6)
                    }
                    .frame(width: 98)
                    .frame(maxHeight: .infinity)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(ChunkyTheme.sheetBg)
                            .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 6, x: 0, y: 2.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .center, spacing: 6) {
                                Text(sectionHeaderTitle)
                                    .font(WidgetFontSystem.sectionHeader(size: 10))
                                    .tracking(0.0)
                                    .foregroundStyle(ChunkyTheme.textMuted)

                                Spacer(minLength: 4)

                                if activeItems.count > 3 {
                                    Text("+\(activeItems.count - 3)")
                                        .font(WidgetFontSystem.statusTag(size: 8.5))
                                        .foregroundStyle(ChunkyTheme.urgentAccent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(ChunkyTheme.urgentAccent.opacity(0.12))
                                        .clipShape(Capsule())
                                } else if !activeItems.isEmpty {
                                    Text("\(activeItems.count)")
                                        .font(WidgetFontSystem.sectionHeader(size: 9))
                                        .foregroundStyle(ChunkyTheme.textMuted)
                                } else if !courseworkList.isEmpty {
                                    Image(systemName: "checkmark")
                                        .font(WidgetFontSystem.sectionHeader(size: 9))
                                        .foregroundStyle(Color.green)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 11)
                            .padding(.bottom, 4)

                            Rectangle()
                                .fill(ChunkyTheme.editorialHairline)
                                .frame(height: 0.8)
                                .padding(.horizontal, 10)

                            if displayItems.isEmpty {
                                emptyStateView
                                    .padding(.horizontal, 11)
                                    .frame(maxHeight: .infinity, alignment: .center)
                            } else {
                                pureTaskListRows
                                    .padding(.horizontal, 10)
                                    .padding(.top, 2)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 8)
                    .padding(.trailing, 8)
                }
            }
        }
        .unredacted()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loggedOutMediumView: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                ChunkyEmberCharacterView(emotion: .normal, size: 68)

                Text("Báo bài")
                    .font(WidgetFontSystem.sectionHeader(size: 10))
                    .foregroundStyle(ChunkyTheme.butterYellow)
            }
            .frame(width: 90)

            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ChunkyTheme.sheetBg)
                    .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 6, x: 0, y: 2.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                    )

                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(ChunkyTheme.pillBlue)

                    Text("Chưa đăng nhập")
                        .font(WidgetFontSystem.courseTitle(size: 13))
                        .foregroundStyle(ChunkyTheme.textPrimary)

                    Text("Chạm để đăng nhập Google Classroom")
                        .font(WidgetFontSystem.meta(size: 10))
                        .foregroundStyle(ChunkyTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
            }
            .frame(maxHeight: .infinity)
            .padding(.vertical, 10)
            .padding(.trailing, 12)
        }
    }

    private var backgroundClouds: some View {
        Canvas { context, size in
            let cloud1 = CGRect(x: size.width - 85, y: 6, width: 68, height: 18)
            context.fill(Path(roundedRect: cloud1, cornerRadius: 9), with: .color(Color.white.opacity(0.16)))

            let cloud2 = CGRect(x: 10, y: 8, width: 44, height: 14)
            context.fill(Path(roundedRect: cloud2, cornerRadius: 7), with: .color(Color.white.opacity(0.12)))
        }
        .allowsHitTesting(false)
    }

    private var emptyStateView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ChunkyTheme.butterYellow.opacity(0.35))
                    .frame(width: 38, height: 38)

                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.10))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sectionHeaderTitle == "HÔM NAY" ? "Hôm nay rảnh rồi!" : (sectionHeaderTitle == "SẮP TỚI" ? "Tạm thời rảnh rồi!" : "Ngày mai rảnh rồi!"))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(ChunkyTheme.textPrimary)

                Text("Tất cả môn học đã hoàn thành.\nNghỉ ngơi và thư giãn nhé.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundStyle(ChunkyTheme.textMuted)
            }
        }
    }

    @ViewBuilder
    private var pureTaskListRows: some View {
        let itemsToShow = Array(displayItems.prefix(3))
        let rowHeight: CGFloat = displayItems.count <= 2 ? 40 : 34

        VStack(spacing: 0) {
            ForEach(Array(itemsToShow.enumerated()), id: \.element.id) { index, item in
                Link(destination: item.destinationURL) {
                    VStack(spacing: 0) {
                        HStack(alignment: .center, spacing: 9) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(SubjectArtHelper.themeColor(for: item.courseName, title: item.title))
                                    .frame(width: 24, height: 24)

                                Image(systemName: SubjectArtHelper.icon(for: item.courseName, title: item.title))
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }

                            VStack(alignment: .leading, spacing: 1.5) {
                                let mainHeadline = item.title.isEmpty ? item.courseName : item.title
                                let subHeadline = item.title.isEmpty ? (item.description?.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? "") : item.courseName

                                Text(mainHeadline)
                                    .font(WidgetFontSystem.courseTitle(size: displayItems.count <= 2 ? 12.5 : 11.5))
                                    .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)

                                if !subHeadline.isEmpty {
                                    Text(subHeadline)
                                        .font(WidgetFontSystem.meta(size: displayItems.count <= 2 ? 9.8 : 8.8))
                                        .foregroundStyle(ChunkyTheme.textMuted)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.82)
                                }
                            }

                            Spacer(minLength: 4)

                            if item.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.green)
                            } else {
                                Text(item.timeOnlyString)
                                    .font(WidgetFontSystem.statusTag(size: 8.5))
                                    .foregroundStyle(item.isUrgent ? ChunkyTheme.urgentAccent : ChunkyTheme.textMuted)
                                    .padding(.horizontal, 5.5)
                                    .padding(.vertical, 2)
                                    .background(item.isUrgent ? ChunkyTheme.urgentAccent.opacity(0.12) : Color.black.opacity(0.04))
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(minHeight: rowHeight)

                        if index < itemsToShow.count - 1 {
                            Rectangle()
                                .fill(ChunkyTheme.editorialHairline)
                                .frame(height: 0.8)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func editorialSubjectBadge(name: String) -> some View {
        let code = SubjectArtHelper.badgeCode(for: name)
        let color = SubjectArtHelper.themeColor(for: name)

        Text(code)
            .font(.system(size: 8.5, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 4.5)
            .padding(.vertical, 1.8)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
    }
}

#Preview("Bốn bài mẫu (Light Mode)") {
    MediumWidgetView(courseworkList: RisoMockData.fourTasks)
        .frame(width: 364, height: 170)
}

#Preview("Một bài Hero") {
    MediumWidgetView(courseworkList: [RisoMockData.physicsTask])
        .frame(width: 364, height: 170)
}

#Preview("Hai bài") {
    MediumWidgetView(courseworkList: [RisoMockData.historyTask, RisoMockData.physicsTask])
        .frame(width: 364, height: 170)
}

#Preview("Empty State (Rảnh rồi)") {
    MediumWidgetView(courseworkList: [])
        .frame(width: 364, height: 170)
}
