import SwiftUI

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

public struct TightMainCrestGlossPath: Shape {
    public init() {}

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
    public init() {}

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
    public init() {}

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
    public init() {}

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
    public init() {}

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

            ZStack {
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
            }
            .drawingGroup()

            stateAccessories
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }

    private var flameOuterBody: some View {
        StandardEmberFlameOuter(isUrgent: emotion == .stressed, isSleeping: emotion == .sleeping)
            .fill(ChunkyTheme.flameOuterGradient)
            .shadow(color: Color(red: 0.86, green: 0.20, blue: 0.10).opacity(0.28), radius: 5, x: 0, y: 2.5)
    }

    private var flameInnerBody: some View {
        StandardEmberFlameInner(isSleeping: emotion == .sleeping)
            .fill(ChunkyTheme.flameInnerGradient)
    }

    private var flameCoreHeart: some View {
        StandardEmberFlameCore()
            .fill(ChunkyTheme.flameCoreGradient)
    }

    private var flameRimHighlights: some View {
        ZStack {
            TightMainCrestGlossPath()
                .stroke(ChunkyTheme.crestGlossGradient, style: StrokeStyle(lineWidth: max(2.0, size * 0.024), lineCap: .round))

            TightLeftTongueGlossPath()
                .stroke(ChunkyTheme.leftTongueGlossGradient, style: StrokeStyle(lineWidth: max(2.0, size * 0.023), lineCap: .round))

            TightLeftCheekGlossPath()
                .stroke(ChunkyTheme.leftCheekGlossGradient, style: StrokeStyle(lineWidth: max(2.2, size * 0.025), lineCap: .round))

            TightRightTipGlossPath()
                .stroke(ChunkyTheme.rightTipGlossGradient, style: StrokeStyle(lineWidth: max(1.6, size * 0.016), lineCap: .round))

            TightRightTongueGlossPath()
                .stroke(ChunkyTheme.rightTongueGlossGradient, style: StrokeStyle(lineWidth: max(1.6, size * 0.016), lineCap: .round))
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
                        .fill(ChunkyTheme.celebratingMouthGradient)

                    CelebratingTongueShape()
                        .fill(ChunkyTheme.celebratingTongueGradient)

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
                    .fill(ChunkyTheme.stressedSweatDropGradient)
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
