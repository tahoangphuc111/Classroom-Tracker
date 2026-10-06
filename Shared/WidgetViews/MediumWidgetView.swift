import SwiftUI
import WidgetKit

// MARK: - CHUNKY EMBER THEME (Minimalist Editorial & Warm Sky)
public struct ChunkyTheme {
    // 1. Sky Background (Gentle Serene Morning Sky - Soft Harmonious Blue Gradient)
    public static let skyTop = Color(red: 0.38, green: 0.65, blue: 0.88)
    public static let skyBottom = Color(red: 0.24, green: 0.52, blue: 0.78)

    // 2. Calm Assignment Sheet (Clean warm white paper)
    public static let sheetBg = Color.white

    // 3. Ember Character (Warm vibrant coral-orange flame)
    public static let emberTop = Color(red: 1.00, green: 0.48, blue: 0.22)
    public static let emberBottom = Color(red: 0.94, green: 0.32, blue: 0.15)
    public static let emberCore = Color(red: 1.00, green: 0.86, blue: 0.38) // Inner yellow flame

    // 4. Typography
    public static let textPrimary = Color(red: 0.12, green: 0.16, blue: 0.24)
    public static let textMuted = Color(red: 0.46, green: 0.53, blue: 0.64)

    // 5. Accents
    public static let urgentAccent = Color(red: 0.94, green: 0.25, blue: 0.28) // Crimson warning
    public static let butterYellow = Color(red: 1.00, green: 0.86, blue: 0.38)
    public static let pillBlue = Color(red: 0.20, green: 0.52, blue: 0.82)

    // 6. Hard Shadows & Editorial Diffusion
    public static let hardShadow = Color(red: 0.10, green: 0.26, blue: 0.40).opacity(0.28)
    public static let characterShadow = Color(red: 0.08, green: 0.20, blue: 0.32).opacity(0.32)

    // 7. Minimalist Editorial Tokens
    public static let editorialCardBorder = Color.black.opacity(0.06)
    public static let editorialHairline = Color.primary.opacity(0.05)
    public static let editorialPillBg = Color(red: 0.94, green: 0.96, blue: 0.98)

    public static var skyGradient: LinearGradient {
        LinearGradient(colors: [skyTop, skyBottom], startPoint: .top, endPoint: .bottom)
    }

    public static var emberGradient: LinearGradient {
        LinearGradient(colors: [emberTop, emberBottom], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - EMBER EMOTIONS
public enum EmberEmotion: String, CaseIterable, Sendable {
    case normal      // 1-2 tasks: energetic, bright-eyed
    case stressed    // ≥ 3 tasks or urgent today: alert, determined
    case sleeping    // 0 tasks: peaceful shut eyes, dreaming
    case celebrating // all completed: triumphant, joyous sparkle
}

// MARK: - STANDARDIZED FLAME VECTOR SHAPES (Chubby Spiky Bé Lửa)
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

        // 1. Plump rounded bottom base
        path.move(to: CGPoint(x: cx, y: h * 0.91))

        // 2. Plump bottom right cheek
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.70),
            control1: CGPoint(x: w * 0.64, y: h * 0.91),
            control2: CGPoint(x: w * 0.78, y: h * 0.82)
        )
        // 3. Right flank up to right spiky tongue
        path.addCurve(
            to: CGPoint(x: w * 0.85, y: h * 0.45),
            control1: CGPoint(x: w * 0.78, y: h * 0.58),
            control2: CGPoint(x: w * 0.85, y: h * 0.51)
        )
        // 4. Right spiky tongue notch dipping in
        path.addCurve(
            to: CGPoint(x: w * 0.67, y: h * 0.36),
            control1: CGPoint(x: w * 0.82, y: h * 0.39),
            control2: CGPoint(x: w * 0.71, y: h * 0.38)
        )
        // 5. Sweeping up to center crest apex
        let apexY = isUrgent ? h * 0.05 : (isSleeping ? h * 0.10 : h * 0.08)
        let apexX = isSleeping ? w * 0.63 : w * 0.61
        path.addCurve(
            to: CGPoint(x: apexX, y: apexY),
            control1: CGPoint(x: w * 0.61, y: h * 0.24),
            control2: CGPoint(x: w * 0.65, y: h * 0.16)
        )
        // 6. Apex curving down to left flame notch
        path.addCurve(
            to: CGPoint(x: w * 0.37, y: h * 0.25),
            control1: CGPoint(x: w * 0.53, y: apexY),
            control2: CGPoint(x: w * 0.42, y: h * 0.17)
        )
        // 7. Left notch sweeping out to left spiky tongue
        path.addCurve(
            to: CGPoint(x: w * 0.16, y: h * 0.40),
            control1: CGPoint(x: w * 0.29, y: h * 0.29),
            control2: CGPoint(x: w * 0.16, y: h * 0.33)
        )
        // 8. Left spiky tongue down to plump left cheek
        path.addCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.70),
            control1: CGPoint(x: w * 0.16, y: h * 0.52),
            control2: CGPoint(x: w * 0.19, y: h * 0.62)
        )
        // 9. Plump left cheek curving into bottom base
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

// Inner glowing hearth core
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

// MARK: - SPECULAR HIGHLIGHT CURVES (Tight Contour Hugging with Dual Fade)

// 1. Hugs the left ridge of the main flame crest
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

// 2. Hugs the upper edge and tip of the left spiky tongue
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

// 3. Hugs the plump left cheek contour
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

// 4. Hugs the right ridge of the main crest (secondary rim)
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

// 5. Hugs the right spiky tongue contour
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

// Backward compatibility alias for single-path callers
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

// MARK: - Celebrating Mouth & Tongue Shapes (nadicode-ai-designer Redesign)
public struct CelebratingMouthCavityShape: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Top lip with gentle cheerful upward curvature
        path.move(to: CGPoint(x: 0, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.12), control: CGPoint(x: w * 0.5, y: -h * 0.02))
        // Right side down to bottom
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w, y: h * 0.56),
            control2: CGPoint(x: w * 0.82, y: h)
        )
        // Bottom back to left corner
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
        // Plump heart-arched tongue rising from bottom
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


// MARK: - 3D CUTE VECTOR EMBER MASCOT (nadicode-ai-designer High-Fidelity Character)
public struct ChunkyEmberCharacterView: View {
    let emotion: EmberEmotion
    var size: CGFloat = 76

    @State private var isBreathing: Bool = false

    private let inkColor = Color(red: 0.12, green: 0.08, blue: 0.06)

    public init(emotion: EmberEmotion, size: CGFloat = 76) {
        self.emotion = emotion
        self.size = size
    }

    public var body: some View {
        ZStack {
            // 0. Soft Ambient Ground Contact Shadow
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

            // 1. Outer 3D Flame Body (Warm Vibrant Coral-Orange Gradient)
            flameOuterBody
                .frame(width: size, height: size)

            // 2. Inner Flame Body (Spiky Amber-Gold Gradient)
            flameInnerBody
                .frame(width: size, height: size)

            // 3. Inner Radiant Hearth Glow (Luminous Center)
            flameCoreHeart
                .frame(width: size, height: size)

            // 4. Tactile 3D Vinyl Specular Highlights (Đường bóng trắng ôm sát viền lửa)
            flameRimHighlights
                .frame(width: size, height: size)

            // 5. Soft Rosy Blush Cheeks (Nằm trọn vẹn, tự nhiên trên 2 má phúng phính)
            blushCheeks
                .frame(width: size, height: size)

            // 6. Expressive Facial Features (Eyes & Mouth)
            facialFeatures
                .frame(width: size, height: size)

            // 7. Mood Accessories (Sweat drop, Sleepy Zs, Celebration Sparkles)
            stateAccessories
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .offset(y: isBreathing ? -1.5 : 1.5)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }

    // MARK: - 1. Outer Flame Body
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

    // MARK: - 2. Inner Flame Body
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

    // MARK: - 3. Inner Radiant Hearth Glow
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

    // MARK: - 4. Specular Highlights (Đường bóng trắng ôm sát viền lửa - Dual Fade)
    private var flameRimHighlights: some View {
        ZStack {
            // (a) Main Crest Left Rim
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

            // (b) Left Spiky Tongue Tip
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

            // (c) Left Cheek Rim
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

            // (d) Right Crest Rim
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

            // (e) Right Spiky Tongue Rim
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

    // MARK: - 5. Soft Blush Cheeks (Nằm chuẩn xác, đối xứng trên khuôn mặt)
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

    // MARK: - 6. Facial Features
    @ViewBuilder
    private var facialFeatures: some View {
        switch emotion {
        case .normal:
            // Alert, Intelligent, Sentient Eyes with Dual Specular Sparkles
            VStack(spacing: size * 0.035) {
                HStack(spacing: size * 0.16) {
                    eyeView
                    eyeView
                }

                // Sweet Smile
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(to: CGPoint(x: size * 0.10, y: 0), control: CGPoint(x: size * 0.05, y: size * 0.048))
                }
                .stroke(inkColor, style: StrokeStyle(lineWidth: max(2.0, size * 0.020), lineCap: .round))
                .frame(width: size * 0.10, height: size * 0.048)
            }
            .offset(x: size * 0.01, y: size * 0.05)

        case .stressed:
            // Wide alert eyes, sweat drop, nervous mouth
            VStack(spacing: size * 0.03) {
                HStack(spacing: size * 0.16) {
                    eyeView
                    eyeView
                }

                // Wavy nervous mouth
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
            // Peaceful curved closed eyelashes & sweet smile
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
            // Joyful closed crescent eyes (^ ^) and beaming open smile with plump pink tongue
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

                // Joyful Open Smile with Plump Pink Tongue
                ZStack {
                    // 1. Deep Wine Cavity Background
                    CelebratingMouthCavityShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.24, green: 0.08, blue: 0.13), Color(red: 0.10, green: 0.04, blue: 0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // 2. Plump Pink Tongue
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

                    // 3. Delicate Tongue Midline Crease
                    Path { p in
                        p.move(to: CGPoint(x: mouthW * 0.5, y: mouthH * 0.38))
                        p.addLine(to: CGPoint(x: mouthW * 0.5, y: mouthH * 0.68))
                    }
                    .stroke(Color(red: 0.79, green: 0.13, blue: 0.29).opacity(0.85), lineWidth: max(0.8, size * 0.009))

                    // 4. Specular Highlight on Tongue
                    Ellipse()
                        .fill(Color.white.opacity(0.42))
                        .frame(width: mouthW * 0.36, height: mouthH * 0.22)
                        .offset(y: -mouthH * 0.06)
                }
                .clipShape(CelebratingMouthCavityShape())
                // 5. Outer Outline Stroke with Round Cap & Join
                .overlay(
                    CelebratingMouthCavityShape()
                        .stroke(inkColor, style: StrokeStyle(lineWidth: max(1.8, size * 0.018), lineCap: .round, lineJoin: .round))
                )
                .frame(width: mouthW, height: mouthH)
            }
            .offset(x: size * 0.01, y: size * 0.05)
        }
    }

    // MARK: - Eye with Double Specular Highlights
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

    // MARK: - 7. State Accessories
    @ViewBuilder
    private var stateAccessories: some View {
        if emotion == .stressed {
            // Translucent 3D Sweat Bead
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
            // Dreamy Floating Z's
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
            // Golden Sparkle Starbursts
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

// MARK: - MEDIUM WIDGET VIEW (Minimalist Editorial - Fluid, Clean, Airy)
public struct MediumWidgetView: View {
    let courseworkList: [Coursework]

    public init(courseworkList: [Coursework]) {
        self.courseworkList = courseworkList
    }

    private var tomorrowItems: [Coursework] {
        courseworkList.filter { $0.isDueTomorrow && !$0.isCompleted }
    }

    private var activeItems: [Coursework] {
        tomorrowItems
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
            return "Thảnh thơi ✨"
        } else if activeItems.count >= 4 {
            return "Tập trung"
        } else {
            return "Sẵn sàng"
        }
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 1. Serene Morning Sky Gradient
            ChunkyTheme.skyGradient
                .ignoresSafeArea()

            // Subtle Background Cloud Silhouettes
            backgroundClouds

            // 2. Fluid Editorial Layout (Flexible HStack adapts to 325pt preview & 364pt system widget)
            HStack(spacing: 12) {
                // LEFT COLUMN: Command & Mascot Hub (Balanced: 108pt width)
                VStack(spacing: 0) {
                    // Editorial Big Counter
                    VStack(spacing: 3) {
                        Text("\(activeItems.count)")
                            .font(WidgetFontSystem.counter(size: 38))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 1.5)

                        Text("CẦN NỘP")
                            .font(WidgetFontSystem.sectionHeader(size: 8.5))
                            .tracking(1.2)
                            .foregroundStyle(ChunkyTheme.butterYellow)

                        // Mood Status Capsule
                        Text(moodBadgeText)
                            .font(WidgetFontSystem.meta(size: 8))
                            .foregroundStyle(Color.white.opacity(0.92))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.16))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 0)

                    // 3D Cute Ember Mascot (Grounded, expressive)
                    ChunkyEmberCharacterView(emotion: characterEmotion, size: 78)
                        .padding(.bottom, 6)
                }
                .frame(width: 108)
                .frame(maxHeight: .infinity)

                // RIGHT COLUMN: Shrunk & Sleek White Card
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(ChunkyTheme.sheetBg)
                        .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 6, x: 0, y: 2.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
                        )

                    // Editorial Card Content
                    VStack(alignment: .leading, spacing: 0) {
                        // Sleek Minimal Header Bar
                        HStack(alignment: .center, spacing: 6) {
                            Text("NGÀY MAI")
                                .font(WidgetFontSystem.sectionHeader(size: 9.5))
                                .tracking(1.1)
                                .foregroundStyle(ChunkyTheme.textMuted)

                            Spacer(minLength: 4)

                            if activeItems.count > 3 {
                                Text("+\(activeItems.count - 3)")
                                    .font(WidgetFontSystem.statusTag(size: 8))
                                    .foregroundStyle(ChunkyTheme.urgentAccent)
                                    .padding(.horizontal, 5.5)
                                    .padding(.vertical, 2)
                                    .background(ChunkyTheme.urgentAccent.opacity(0.12))
                                    .clipShape(Capsule())
                            } else if !activeItems.isEmpty {
                                Text("\(activeItems.count)")
                                    .font(WidgetFontSystem.sectionHeader(size: 8.5))
                                    .foregroundStyle(ChunkyTheme.textMuted)
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)

                        // Hairline Divider
                        Rectangle()
                            .fill(ChunkyTheme.editorialHairline)
                            .frame(height: 0.8)
                            .padding(.horizontal, 10)

                        // Coursework Items or Empty State
                        if activeItems.isEmpty {
                            emptyStateView
                                .padding(.horizontal, 12)
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
                .padding(.vertical, 14)
                .padding(.trailing, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.light)
    }

    // MARK: - Background Clouds Silhouettes
    private var backgroundClouds: some View {
        Canvas { context, size in
            let cloud1 = CGRect(x: size.width - 85, y: 6, width: 68, height: 18)
            context.fill(Path(roundedRect: cloud1, cornerRadius: 9), with: .color(Color.white.opacity(0.16)))

            let cloud2 = CGRect(x: 10, y: 8, width: 44, height: 14)
            context.fill(Path(roundedRect: cloud2, cornerRadius: 7), with: .color(Color.white.opacity(0.12)))
        }
        .allowsHitTesting(false)
    }

    // MARK: - Empty State View (Tranquil & Clean)
    private var emptyStateView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ChunkyTheme.butterYellow.opacity(0.35))
                    .frame(width: 36, height: 36)

                Text("✦")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.58, blue: 0.10))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Ngày mai rảnh rồi!")
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(ChunkyTheme.textPrimary)

                Text("Tất cả môn học đã hoàn thành.\nNghỉ ngơi và thư giãn nhé ✦")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundStyle(ChunkyTheme.textMuted)
            }
        }
    }

    // MARK: - Pure Task List Rows (Ghi mỗi môn học thôi, bỏ qua nội dung)
    @ViewBuilder
    private var pureTaskListRows: some View {
        let itemsToShow = Array(activeItems.prefix(3))
        let rowHeight: CGFloat = activeItems.count <= 2 ? 38 : 31

        VStack(spacing: 0) {
            ForEach(Array(itemsToShow.enumerated()), id: \.element.id) { index, item in
                Link(destination: URL(string: item.alternateLink ?? "https://classroom.google.com")!) {
                    VStack(spacing: 0) {
                        HStack(alignment: .center, spacing: 9) {
                            // Subject Icon Badge (Clean & Color Coded)
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(SubjectArtHelper.themeColor(for: item.courseName))
                                    .frame(width: 22, height: 22)

                                Image(systemName: SubjectArtHelper.icon(for: item.courseName))
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }

                            // Only Course Name (Bỏ qua nội dung)
                            Text(item.courseName)
                                .font(WidgetFontSystem.courseTitle(size: 13))
                                .foregroundStyle(item.isCompleted ? ChunkyTheme.textMuted : ChunkyTheme.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer(minLength: 4)

                            // Status / Due tag
                            if item.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.green)
                            } else {
                                Text(item.timeOnlyString)
                                    .font(WidgetFontSystem.statusTag(size: 7.5))
                                    .foregroundStyle(ChunkyTheme.textMuted)
                                    .padding(.horizontal, 5.5)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.04))
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(height: rowHeight)

                        // Subtle Hairline Divider
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

    // MARK: - Editorial Subject Badge
    @ViewBuilder
    private func editorialSubjectBadge(name: String) -> some View {
        let code = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(3)).uppercased()
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

// MARK: - PREVIEWS
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
