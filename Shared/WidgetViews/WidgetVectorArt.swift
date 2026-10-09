import SwiftUI

public struct AbstractWaveDecorView: View {
    let tintColor: Color
    let isDark: Bool

    public init(tintColor: Color = Color(red: 0.12, green: 0.54, blue: 1.0), isDark: Bool = false) {
        self.tintColor = tintColor
        self.isDark = isDark
    }

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let glowRect1 = CGRect(x: w * 0.1, y: h * 0.05, width: w * 0.85, height: h * 0.85)
            context.fill(
                Circle().path(in: glowRect1),
                with: .radialGradient(
                    Gradient(colors: [tintColor.opacity(0.35), tintColor.opacity(0.0)]),
                    center: CGPoint(x: w * 0.6, y: h * 0.45),
                    startRadius: 2,
                    endRadius: w * 0.48
                )
            )

            let glowRect2 = CGRect(x: -w * 0.1, y: h * 0.35, width: w * 0.7, height: h * 0.7)
            context.fill(
                Circle().path(in: glowRect2),
                with: .radialGradient(
                    Gradient(colors: [tintColor.opacity(0.20), tintColor.opacity(0.0)]),
                    center: CGPoint(x: w * 0.25, y: h * 0.7),
                    startRadius: 1,
                    endRadius: w * 0.35
                )
            )

            var backWave = Path()
            backWave.move(to: CGPoint(x: -w * 0.1, y: h * 0.82))
            backWave.addCurve(
                to: CGPoint(x: w * 0.48, y: h * 0.45),
                control1: CGPoint(x: w * 0.12, y: h * 0.95),
                control2: CGPoint(x: w * 0.30, y: h * 0.52)
            )
            backWave.addCurve(
                to: CGPoint(x: w * 1.1, y: h * 0.62),
                control1: CGPoint(x: w * 0.65, y: h * 0.38),
                control2: CGPoint(x: w * 0.88, y: h * 0.72)
            )
            backWave.addLine(to: CGPoint(x: w * 1.1, y: h * 1.1))
            backWave.addLine(to: CGPoint(x: -w * 0.1, y: h * 1.1))
            backWave.closeSubpath()

            context.fill(
                backWave,
                with: .linearGradient(
                    Gradient(colors: [tintColor.opacity(0.30), tintColor.opacity(0.08)]),
                    startPoint: CGPoint(x: 0, y: h * 0.3),
                    endPoint: CGPoint(x: w, y: h)
                )
            )

            var midWave = Path()
            midWave.move(to: CGPoint(x: -w * 0.1, y: h * 0.60))
            midWave.addCurve(
                to: CGPoint(x: w * 0.55, y: h * 0.30),
                control1: CGPoint(x: w * 0.15, y: h * 0.78),
                control2: CGPoint(x: w * 0.35, y: h * 0.38)
            )
            midWave.addCurve(
                to: CGPoint(x: w * 1.12, y: h * 0.48),
                control1: CGPoint(x: w * 0.75, y: h * 0.22),
                control2: CGPoint(x: w * 0.95, y: h * 0.55)
            )
            midWave.addLine(to: CGPoint(x: w * 1.12, y: h * 1.1))
            midWave.addLine(to: CGPoint(x: -w * 0.1, y: h * 1.1))
            midWave.closeSubpath()

            context.fill(
                midWave,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.35), tintColor.opacity(0.35), tintColor.opacity(0.12)]),
                    startPoint: CGPoint(x: w * 0.1, y: h * 0.2),
                    endPoint: CGPoint(x: w * 0.9, y: h)
                )
            )

            var midEdge = Path()
            midEdge.move(to: CGPoint(x: -w * 0.1, y: h * 0.60))
            midEdge.addCurve(
                to: CGPoint(x: w * 0.55, y: h * 0.30),
                control1: CGPoint(x: w * 0.15, y: h * 0.78),
                control2: CGPoint(x: w * 0.35, y: h * 0.38)
            )
            midEdge.addCurve(
                to: CGPoint(x: w * 1.12, y: h * 0.48),
                control1: CGPoint(x: w * 0.75, y: h * 0.22),
                control2: CGPoint(x: w * 0.95, y: h * 0.55)
            )
            context.stroke(
                midEdge,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.75), tintColor.opacity(0.8), Color.white.opacity(0.2)]),
                    startPoint: CGPoint(x: 0, y: h * 0.3),
                    endPoint: CGPoint(x: w, y: h * 0.5)
                ),
                lineWidth: 1.8
            )

            var frontWave = Path()
            frontWave.move(to: CGPoint(x: -w * 0.05, y: h * 0.74))
            frontWave.addCurve(
                to: CGPoint(x: w * 0.62, y: h * 0.52),
                control1: CGPoint(x: w * 0.20, y: h * 0.50),
                control2: CGPoint(x: w * 0.42, y: h * 0.82)
            )
            frontWave.addCurve(
                to: CGPoint(x: w * 1.15, y: h * 0.25),
                control1: CGPoint(x: w * 0.82, y: h * 0.25),
                control2: CGPoint(x: w * 0.98, y: h * 0.18)
            )
            frontWave.addLine(to: CGPoint(x: w * 1.15, y: h * 1.1))
            frontWave.addLine(to: CGPoint(x: -w * 0.05, y: h * 1.1))
            frontWave.closeSubpath()

            context.fill(
                frontWave,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.25), tintColor.opacity(0.25), Color.clear]),
                    startPoint: CGPoint(x: w * 0.3, y: h * 0.3),
                    endPoint: CGPoint(x: w, y: h)
                )
            )

            var lightBeam = Path()
            lightBeam.move(to: CGPoint(x: w * 0.08, y: h * 0.28))
            lightBeam.addCurve(
                to: CGPoint(x: w * 0.92, y: h * 0.18),
                control1: CGPoint(x: w * 0.35, y: h * 0.05),
                control2: CGPoint(x: w * 0.65, y: h * 0.42)
            )
            context.stroke(
                lightBeam,
                with: .linearGradient(
                    Gradient(colors: [tintColor.opacity(0.0), tintColor.opacity(0.65), Color.white.opacity(0.85), Color.clear]),
                    startPoint: CGPoint(x: w * 0.1, y: h * 0.2),
                    endPoint: CGPoint(x: w * 0.9, y: h * 0.2)
                ),
                lineWidth: 1.4
            )

            drawSparkle(in: context, center: CGPoint(x: w * 0.78, y: h * 0.16), radius: 7.5, color: Color.white.opacity(0.95))
            drawSparkle(in: context, center: CGPoint(x: w * 0.24, y: h * 0.26), radius: 5.5, color: tintColor.opacity(0.90))
            drawSparkle(in: context, center: CGPoint(x: w * 0.88, y: h * 0.65), radius: 5.0, color: Color.white.opacity(0.85))
            drawSparkle(in: context, center: CGPoint(x: w * 0.42, y: h * 0.14), radius: 4.0, color: Color.white.opacity(0.80))
            drawSparkle(in: context, center: CGPoint(x: w * 0.14, y: h * 0.52), radius: 3.5, color: tintColor.opacity(0.75))
            drawSparkle(in: context, center: CGPoint(x: w * 0.66, y: h * 0.38), radius: 3.0, color: Color.white.opacity(0.70))

            let particles = [
                CGPoint(x: w * 0.32, y: h * 0.18),
                CGPoint(x: w * 0.50, y: h * 0.22),
                CGPoint(x: w * 0.82, y: h * 0.32),
                CGPoint(x: w * 0.90, y: h * 0.12),
                CGPoint(x: w * 0.18, y: h * 0.68),
                CGPoint(x: w * 0.70, y: h * 0.78)
            ]
            for pt in particles {
                context.fill(Circle().path(in: CGRect(x: pt.x - 2, y: pt.y - 2, width: 4, height: 4)), with: .color(Color.white.opacity(0.75)))
            }
        }
    }
}

public struct AbstractOrbitalDecorView: View {
    let tintColor: Color
    let isDark: Bool

    public init(tintColor: Color = Color(red: 1.0, green: 0.46, blue: 0.12), isDark: Bool = false) {
        self.tintColor = tintColor
        self.isDark = isDark
    }

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w * 0.52
            let cy = h * 0.48

            context.fill(
                Circle().path(in: CGRect(x: w * 0.05, y: h * 0.05, width: w * 0.9, height: h * 0.9)),
                with: .radialGradient(
                    Gradient(colors: [tintColor.opacity(0.35), tintColor.opacity(0.0)]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 2,
                    endRadius: w * 0.48
                )
            )

            let outerRect = CGRect(x: cx - w * 0.44, y: cy - h * 0.40, width: w * 0.88, height: h * 0.80)
            var outerOrbit = Path()
            outerOrbit.addEllipse(in: outerRect)
            context.stroke(
                outerOrbit,
                with: .color(tintColor.opacity(0.28)),
                style: StrokeStyle(lineWidth: 1.2, dash: [4, 5])
            )

            let midRect = CGRect(x: cx - w * 0.32, y: cy - h * 0.30, width: w * 0.64, height: h * 0.60)
            var midOrbit = Path()
            midOrbit.addEllipse(in: midRect)
            context.stroke(
                midOrbit,
                with: .linearGradient(
                    Gradient(colors: [tintColor, tintColor.opacity(0.3), Color.white.opacity(0.8), tintColor.opacity(0.5)]),
                    startPoint: CGPoint(x: midRect.minX, y: midRect.minY),
                    endPoint: CGPoint(x: midRect.maxX, y: midRect.maxY)
                ),
                lineWidth: 1.8
            )

            let innerRect = CGRect(x: cx - w * 0.20, y: cy - h * 0.18, width: w * 0.40, height: h * 0.36)
            var innerOrbit = Path()
            innerOrbit.addEllipse(in: innerRect)
            context.stroke(
                innerOrbit,
                with: .color(Color.white.opacity(0.40)),
                style: StrokeStyle(lineWidth: 1.0, dash: [2, 3])
            )

            let orbRadius: CGFloat = min(w, h) * 0.17
            let orbRect = CGRect(x: cx - orbRadius, y: cy - orbRadius, width: orbRadius * 2, height: orbRadius * 2)
            context.fill(
                Circle().path(in: orbRect),
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.95), tintColor, tintColor.opacity(0.35)]),
                    center: CGPoint(x: cx - orbRadius * 0.35, y: cy - orbRadius * 0.35),
                    startRadius: 1,
                    endRadius: orbRadius
                )
            )
            context.stroke(Circle().path(in: orbRect), with: .color(Color.white.opacity(0.5)), lineWidth: 1.2)

            let satellites: [(CGPoint, CGFloat, Color)] = [
                (CGPoint(x: cx + w * 0.32, y: cy - h * 0.10), 4.5, Color.white),
                (CGPoint(x: cx - w * 0.28, y: cy + h * 0.22), 3.8, tintColor),
                (CGPoint(x: cx + w * 0.18, y: cy + h * 0.30), 3.0, Color.white),
                (CGPoint(x: cx - w * 0.18, y: cy - h * 0.28), 2.5, tintColor)
            ]
            for (pt, r, color) in satellites {
                context.fill(
                    Circle().path(in: CGRect(x: pt.x - r * 1.8, y: pt.y - r * 1.8, width: r * 3.6, height: r * 3.6)),
                    with: .color(color.opacity(0.3))
                )
                context.fill(
                    Circle().path(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                    with: .color(color)
                )
            }

            drawSparkle(in: context, center: CGPoint(x: cx + w * 0.28, y: cy - h * 0.32), radius: 6.5, color: Color.white.opacity(0.95))
            drawSparkle(in: context, center: CGPoint(x: cx - w * 0.35, y: cy - h * 0.16), radius: 5.0, color: Color.white.opacity(0.80))
            drawSparkle(in: context, center: CGPoint(x: cx + w * 0.38, y: cy + h * 0.26), radius: 4.0, color: tintColor.opacity(0.85))
            drawSparkle(in: context, center: CGPoint(x: cx - w * 0.12, y: cy + h * 0.38), radius: 3.5, color: Color.white.opacity(0.75))
        }
    }
}

public struct AbstractLuminousOrbsView: View {
    let tintColor: Color
    let isDark: Bool

    public init(tintColor: Color = Color(red: 0.10, green: 0.76, blue: 0.46), isDark: Bool = false) {
        self.tintColor = tintColor
        self.isDark = isDark
    }

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            context.fill(
                Circle().path(in: CGRect(x: w * 0.08, y: h * 0.08, width: w * 0.84, height: h * 0.84)),
                with: .radialGradient(
                    Gradient(colors: [tintColor.opacity(0.38), tintColor.opacity(0.0)]),
                    center: CGPoint(x: w * 0.55, y: h * 0.48),
                    startRadius: 2,
                    endRadius: w * 0.48
                )
            )

            let orb1Radius: CGFloat = min(w, h) * 0.27
            let orb1Center = CGPoint(x: w * 0.58, y: h * 0.46)
            let orb1Rect = CGRect(x: orb1Center.x - orb1Radius, y: orb1Center.y - orb1Radius, width: orb1Radius * 2, height: orb1Radius * 2)

            context.fill(
                Circle().path(in: orb1Rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.55),
                        tintColor.opacity(0.65),
                        tintColor.opacity(0.18)
                    ]),
                    center: CGPoint(x: orb1Center.x - orb1Radius * 0.35, y: orb1Center.y - orb1Radius * 0.35),
                    startRadius: 2,
                    endRadius: orb1Radius
                )
            )
            context.stroke(Circle().path(in: orb1Rect), with: .color(Color.white.opacity(0.40)), lineWidth: 1.5)

            let orb2Radius: CGFloat = min(w, h) * 0.18
            let orb2Center = CGPoint(x: w * 0.30, y: h * 0.64)
            let orb2Rect = CGRect(x: orb2Center.x - orb2Radius, y: orb2Center.y - orb2Radius, width: orb2Radius * 2, height: orb2Radius * 2)

            context.fill(
                Circle().path(in: orb2Rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.65),
                        tintColor.opacity(0.50),
                        Color.clear
                    ]),
                    center: CGPoint(x: orb2Center.x - orb2Radius * 0.3, y: orb2Center.y - orb2Radius * 0.3),
                    startRadius: 1,
                    endRadius: orb2Radius
                )
            )
            context.stroke(Circle().path(in: orb2Rect), with: .color(Color.white.opacity(0.35)), lineWidth: 1.2)

            let orb3Radius: CGFloat = min(w, h) * 0.12
            let orb3Center = CGPoint(x: w * 0.78, y: h * 0.30)
            let orb3Rect = CGRect(x: orb3Center.x - orb3Radius, y: orb3Center.y - orb3Radius, width: orb3Radius * 2, height: orb3Radius * 2)

            context.fill(
                Circle().path(in: orb3Rect),
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.8), tintColor.opacity(0.4), Color.clear]),
                    center: CGPoint(x: orb3Center.x - orb3Radius * 0.3, y: orb3Center.y - orb3Radius * 0.3),
                    startRadius: 1,
                    endRadius: orb3Radius
                )
            )
            context.stroke(Circle().path(in: orb3Rect), with: .color(Color.white.opacity(0.30)), lineWidth: 1.0)

            var arc1 = Path()
            arc1.addArc(
                center: CGPoint(x: w * 0.48, y: h * 0.52),
                radius: w * 0.36,
                startAngle: .degrees(-65),
                endAngle: .degrees(40),
                clockwise: false
            )
            context.stroke(
                arc1,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.6), Color.white.opacity(0.0)]),
                    startPoint: CGPoint(x: w * 0.3, y: h * 0.2),
                    endPoint: CGPoint(x: w * 0.9, y: h * 0.7)
                ),
                lineWidth: 1.6
            )

            drawSparkle(in: context, center: CGPoint(x: w * 0.84, y: h * 0.22), radius: 6.5, color: Color.white.opacity(0.95))
            drawSparkle(in: context, center: CGPoint(x: w * 0.16, y: h * 0.36), radius: 5.0, color: Color.white.opacity(0.85))
            drawSparkle(in: context, center: CGPoint(x: w * 0.48, y: h * 0.16), radius: 4.0, color: tintColor.opacity(0.80))
            drawSparkle(in: context, center: CGPoint(x: w * 0.72, y: h * 0.68), radius: 3.5, color: Color.white.opacity(0.75))

            let bokehs = [
                CGPoint(x: w * 0.24, y: h * 0.20),
                CGPoint(x: w * 0.88, y: h * 0.48),
                CGPoint(x: w * 0.40, y: h * 0.80)
            ]
            for pt in bokehs {
                context.fill(Circle().path(in: CGRect(x: pt.x - 2.5, y: pt.y - 2.5, width: 5, height: 5)), with: .color(Color.white.opacity(0.70)))
            }
        }
    }
}

public struct AbstractGeometricPlatesView: View {
    let tintColor: Color
    let isDark: Bool

    public init(tintColor: Color = Color(red: 0.60, green: 0.38, blue: 0.98), isDark: Bool = false) {
        self.tintColor = tintColor
        self.isDark = isDark
    }

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            context.fill(
                Circle().path(in: CGRect(x: w * 0.08, y: h * 0.08, width: w * 0.84, height: h * 0.84)),
                with: .radialGradient(
                    Gradient(colors: [tintColor.opacity(0.35), tintColor.opacity(0.0)]),
                    center: CGPoint(x: w * 0.52, y: h * 0.5),
                    startRadius: 2,
                    endRadius: w * 0.48
                )
            )

            let pillW = w * 0.58
            let pillH = h * 0.28
            let pillRect = CGRect(x: w * 0.22, y: h * 0.20, width: pillW, height: pillH)

            var angledContext = context
            angledContext.translateBy(x: pillRect.midX, y: pillRect.midY)
            angledContext.rotate(by: .degrees(-14))
            angledContext.translateBy(x: -pillRect.midX, y: -pillRect.midY)

            let pillPath = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: pillRect)
            angledContext.fill(
                pillPath,
                with: .linearGradient(
                    Gradient(colors: [tintColor.opacity(0.38), tintColor.opacity(0.10)]),
                    startPoint: CGPoint(x: pillRect.minX, y: pillRect.minY),
                    endPoint: CGPoint(x: pillRect.maxX, y: pillRect.maxY)
                )
            )
            angledContext.stroke(pillPath, with: .color(Color.white.opacity(0.35)), lineWidth: 1.2)

            let plate2W = w * 0.50
            let plate2H = h * 0.34
            let plate2Rect = CGRect(x: w * 0.35, y: h * 0.40, width: plate2W, height: plate2H)

            var plate2Context = context
            plate2Context.translateBy(x: plate2Rect.midX, y: plate2Rect.midY)
            plate2Context.rotate(by: .degrees(12))
            plate2Context.translateBy(x: -plate2Rect.midX, y: -plate2Rect.midY)

            let plate2Path = RoundedRectangle(cornerRadius: 10, style: .continuous).path(in: plate2Rect)
            plate2Context.fill(
                plate2Path,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.35), tintColor.opacity(0.55), tintColor.opacity(0.18)]),
                    startPoint: CGPoint(x: plate2Rect.minX, y: plate2Rect.minY),
                    endPoint: CGPoint(x: plate2Rect.maxX, y: plate2Rect.maxY)
                )
            )
            plate2Context.stroke(plate2Path, with: .color(Color.white.opacity(0.50)), lineWidth: 1.4)

            let miniRect = CGRect(x: w * 0.16, y: h * 0.48, width: w * 0.28, height: h * 0.22)
            var miniContext = context
            miniContext.translateBy(x: miniRect.midX, y: miniRect.midY)
            miniContext.rotate(by: .degrees(-6))
            miniContext.translateBy(x: -miniRect.midX, y: -miniRect.midY)

            let miniPath = RoundedRectangle(cornerRadius: 8, style: .continuous).path(in: miniRect)
            miniContext.fill(
                miniPath,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.50), tintColor.opacity(0.35)]),
                    startPoint: CGPoint(x: miniRect.minX, y: miniRect.minY),
                    endPoint: CGPoint(x: miniRect.maxX, y: miniRect.maxY)
                )
            )
            miniContext.stroke(miniPath, with: .color(Color.white.opacity(0.40)), lineWidth: 1.0)

            drawSparkle(in: context, center: CGPoint(x: w * 0.82, y: h * 0.18), radius: 7.0, color: Color.white.opacity(0.95))
            drawSparkle(in: context, center: CGPoint(x: w * 0.14, y: h * 0.28), radius: 5.0, color: Color.white.opacity(0.85))
            drawSparkle(in: context, center: CGPoint(x: w * 0.72, y: h * 0.74), radius: 4.5, color: tintColor.opacity(0.90))
            drawSparkle(in: context, center: CGPoint(x: w * 0.48, y: h * 0.12), radius: 3.5, color: Color.white.opacity(0.75))

            let dots = [
                CGPoint(x: w * 0.20, y: h * 0.22),
                CGPoint(x: w * 0.88, y: h * 0.68),
                CGPoint(x: w * 0.32, y: h * 0.82)
            ]
            for pt in dots {
                context.fill(Circle().path(in: CGRect(x: pt.x - 2, y: pt.y - 2, width: 4, height: 4)), with: .color(Color.white.opacity(0.75)))
            }
        }
    }
}

private func drawSparkle(in context: GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
    var path = Path()
    let inner = radius * 0.22
    path.move(to: CGPoint(x: center.x, y: center.y - radius))
    path.addQuadCurve(to: CGPoint(x: center.x + radius, y: center.y), control: CGPoint(x: center.x + inner, y: center.y - inner))
    path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + radius), control: CGPoint(x: center.x + inner, y: center.y + inner))
    path.addQuadCurve(to: CGPoint(x: center.x - radius, y: center.y), control: CGPoint(x: center.x - inner, y: center.y + inner))
    path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius), control: CGPoint(x: center.x - inner, y: center.y - inner))
    path.closeSubpath()
    context.fill(path, with: .color(color))
}

public struct RealSubjectArtScene: View {
    let courseName: String
    let tintColor: Color?
    let isDark: Bool

    public init(courseName: String, tintColor: Color? = nil, isDark: Bool = false) {
        self.courseName = courseName
        self.tintColor = tintColor
        self.isDark = isDark
    }

    private var resolvedColor: Color {
        tintColor ?? SubjectArtHelper.themeColor(for: courseName)
    }

    public var body: some View {
        let hash = abs(courseName.hashValue) % 4
        Group {
            switch hash {
            case 0:
                AbstractWaveDecorView(tintColor: resolvedColor, isDark: isDark)
            case 1:
                AbstractOrbitalDecorView(tintColor: resolvedColor, isDark: isDark)
            case 2:
                AbstractLuminousOrbsView(tintColor: resolvedColor, isDark: isDark)
            default:
                AbstractGeometricPlatesView(tintColor: resolvedColor, isDark: isDark)
            }
        }
    }
}

public typealias LaptopCodeVectorArtView = AbstractWaveDecorView
public typealias MathGeometryVectorArtView = AbstractOrbitalDecorView
public typealias ScienceFlaskVectorArtView = AbstractLuminousOrbsView
public typealias NotebookVectorArtView = AbstractGeometricPlatesView

public struct DuolingoFontHelper {
    public static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let fontName: String = switch weight {
        case .heavy, .black: "SVN-GilroyHeavy"
        case .bold: "SVN-GilroyBold"
        case .semibold: "SVN-GilroySemiBold"
        case .medium: "SVN-GilroyMedium"
        default: "SVN-Gilroy"
        }

        #if canImport(AppKit)
        if NSFont(name: fontName, size: size) != nil {
            return .custom(fontName, size: size)
        }
        #elseif canImport(UIKit)
        if UIFont(name: fontName, size: size) != nil {
            return .custom(fontName, size: size)
        }
        #endif

        return Font.system(size: size, weight: weight, design: .rounded)
    }

    public static func numeric(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: size, weight: weight, design: .rounded)
    }

    public static func body(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        let fontName: String = switch weight {
        case .heavy, .black: "SVN-GilroyHeavy"
        case .bold: "SVN-GilroyBold"
        case .semibold: "SVN-GilroySemiBold"
        default: "SVN-GilroyMedium"
        }

        #if canImport(AppKit)
        if NSFont(name: fontName, size: size) != nil {
            return .custom(fontName, size: size)
        }
        #elseif canImport(UIKit)
        if UIFont(name: fontName, size: size) != nil {
            return .custom(fontName, size: size)
        }
        #endif

        return Font.system(size: size, weight: weight, design: .default)
    }

    public static func rounded(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        display(size: size, weight: weight)
    }
}

public struct DuolingoFlameArtView: View {
    @State private var isBreathing: Bool = false

    public init() {}

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w * 0.50

            let shadowRect = CGRect(x: w * 0.22, y: h * 0.84, width: w * 0.56, height: h * 0.12)
            context.fill(
                Ellipse().path(in: shadowRect),
                with: .color(Color.black.opacity(0.18))
            )

            var outer = Path()
            outer.move(to: CGPoint(x: cx, y: h * 0.88))

            outer.addCurve(
                to: CGPoint(x: w * 0.72, y: h * 0.68),
                control1: CGPoint(x: w * 0.62, y: h * 0.88),
                control2: CGPoint(x: w * 0.72, y: h * 0.80)
            )
            outer.addCurve(
                to: CGPoint(x: w * 0.79, y: h * 0.44),
                control1: CGPoint(x: w * 0.72, y: h * 0.58),
                control2: CGPoint(x: w * 0.80, y: h * 0.50)
            )
            outer.addCurve(
                to: CGPoint(x: w * 0.65, y: h * 0.36),
                control1: CGPoint(x: w * 0.76, y: h * 0.38),
                control2: CGPoint(x: w * 0.69, y: h * 0.38)
            )
            outer.addCurve(
                to: CGPoint(x: w * 0.60, y: h * 0.08),
                control1: CGPoint(x: w * 0.59, y: h * 0.24),
                control2: CGPoint(x: w * 0.63, y: h * 0.16)
            )
            outer.addCurve(
                to: CGPoint(x: w * 0.38, y: h * 0.26),
                control1: CGPoint(x: w * 0.54, y: h * 0.08),
                control2: CGPoint(x: w * 0.42, y: h * 0.18)
            )
            outer.addCurve(
                to: CGPoint(x: w * 0.20, y: h * 0.42),
                control1: CGPoint(x: w * 0.32, y: h * 0.30),
                control2: CGPoint(x: w * 0.20, y: h * 0.34)
            )
            outer.addCurve(
                to: CGPoint(x: w * 0.28, y: h * 0.68),
                control1: CGPoint(x: w * 0.20, y: h * 0.52),
                control2: CGPoint(x: w * 0.24, y: h * 0.62)
            )
            outer.addCurve(
                to: CGPoint(x: cx, y: h * 0.88),
                control1: CGPoint(x: w * 0.30, y: h * 0.80),
                control2: CGPoint(x: w * 0.40, y: h * 0.88)
            )
            outer.closeSubpath()

            context.fill(
                outer,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.22, green: 0.95, blue: 0.95),
                        Color(red: 0.05, green: 0.65, blue: 0.95),
                        Color(red: 0.08, green: 0.35, blue: 0.88)
                    ]),
                    startPoint: CGPoint(x: cx, y: h * 0.08),
                    endPoint: CGPoint(x: cx, y: h * 0.88)
                )
            )

            var mid = Path()
            mid.move(to: CGPoint(x: cx, y: h * 0.84))

            mid.addCurve(
                to: CGPoint(x: w * 0.66, y: h * 0.66),
                control1: CGPoint(x: w * 0.58, y: h * 0.84),
                control2: CGPoint(x: w * 0.66, y: h * 0.76)
            )
            mid.addCurve(
                to: CGPoint(x: w * 0.71, y: h * 0.46),
                control1: CGPoint(x: w * 0.66, y: h * 0.56),
                control2: CGPoint(x: w * 0.72, y: h * 0.50)
            )
            mid.addCurve(
                to: CGPoint(x: w * 0.60, y: h * 0.40),
                control1: CGPoint(x: w * 0.69, y: h * 0.42),
                control2: CGPoint(x: w * 0.63, y: h * 0.42)
            )
            mid.addCurve(
                to: CGPoint(x: w * 0.56, y: h * 0.18),
                control1: CGPoint(x: w * 0.56, y: h * 0.30),
                control2: CGPoint(x: w * 0.58, y: h * 0.24)
            )
            mid.addCurve(
                to: CGPoint(x: w * 0.42, y: h * 0.32),
                control1: CGPoint(x: w * 0.52, y: h * 0.18),
                control2: CGPoint(x: w * 0.45, y: h * 0.26)
            )
            mid.addCurve(
                to: CGPoint(x: w * 0.29, y: h * 0.46),
                control1: CGPoint(x: w * 0.37, y: h * 0.36),
                control2: CGPoint(x: w * 0.29, y: h * 0.40)
            )
            mid.addCurve(
                to: CGPoint(x: w * 0.34, y: h * 0.66),
                control1: CGPoint(x: w * 0.29, y: h * 0.54),
                control2: CGPoint(x: w * 0.32, y: h * 0.62)
            )
            mid.addCurve(
                to: CGPoint(x: cx, y: h * 0.84),
                control1: CGPoint(x: w * 0.36, y: h * 0.76),
                control2: CGPoint(x: w * 0.42, y: h * 0.84)
            )
            mid.closeSubpath()

            context.fill(
                mid,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white,
                        Color(red: 0.45, green: 0.95, blue: 0.98)
                    ]),
                    startPoint: CGPoint(x: cx, y: h * 0.18),
                    endPoint: CGPoint(x: cx, y: h * 0.84)
                )
            )

            var core = Path()
            let coreTop = h * 0.32
            core.move(to: CGPoint(x: cx + w * 0.04, y: coreTop))

            core.addCurve(
                to: CGPoint(x: w * 0.58, y: h * 0.64),
                control1: CGPoint(x: w * 0.58, y: h * 0.42),
                control2: CGPoint(x: w * 0.60, y: h * 0.56)
            )
            core.addCurve(
                to: CGPoint(x: cx, y: h * 0.78),
                control1: CGPoint(x: w * 0.56, y: h * 0.74),
                control2: CGPoint(x: cx + w * 0.08, y: h * 0.78)
            )
            core.addCurve(
                to: CGPoint(x: w * 0.42, y: h * 0.64),
                control1: CGPoint(x: cx - w * 0.08, y: h * 0.78),
                control2: CGPoint(x: w * 0.44, y: h * 0.74)
            )
            core.addCurve(
                to: CGPoint(x: cx + w * 0.04, y: coreTop),
                control1: CGPoint(x: w * 0.40, y: h * 0.56),
                control2: CGPoint(x: w * 0.44, y: h * 0.40)
            )
            core.closeSubpath()

            context.fill(
                core,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.98),
                        Color(red: 0.88, green: 0.98, blue: 1.0)
                    ]),
                    startPoint: CGPoint(x: cx, y: coreTop),
                    endPoint: CGPoint(x: cx, y: h * 0.78)
                )
            )

            var mainRimGloss = Path()
            mainRimGloss.move(to: CGPoint(x: w * 0.55, y: h * 0.11))
            mainRimGloss.addCurve(
                to: CGPoint(x: w * 0.38, y: h * 0.27),
                control1: CGPoint(x: w * 0.50, y: h * 0.11),
                control2: CGPoint(x: w * 0.42, y: h * 0.19)
            )
            mainRimGloss.addCurve(
                to: CGPoint(x: w * 0.23, y: h * 0.41),
                control1: CGPoint(x: w * 0.33, y: h * 0.31),
                control2: CGPoint(x: w * 0.23, y: h * 0.35)
            )
            context.stroke(
                mainRimGloss,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.92),
                        Color.white.opacity(0.85),
                        Color.white.opacity(0.20)
                    ]),
                    startPoint: CGPoint(x: w * 0.55, y: h * 0.11),
                    endPoint: CGPoint(x: w * 0.23, y: h * 0.41)
                ),
                style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
            )

            var leftLickGloss = Path()
            leftLickGloss.move(to: CGPoint(x: w * 0.23, y: h * 0.46))
            leftLickGloss.addCurve(
                to: CGPoint(x: w * 0.27, y: h * 0.64),
                control1: CGPoint(x: w * 0.22, y: h * 0.53),
                control2: CGPoint(x: w * 0.24, y: h * 0.59)
            )
            context.stroke(
                leftLickGloss,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.75),
                        Color.white.opacity(0.15)
                    ]),
                    startPoint: CGPoint(x: w * 0.23, y: h * 0.46),
                    endPoint: CGPoint(x: w * 0.27, y: h * 0.64)
                ),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
            )

            var rightTipGloss = Path()
            rightTipGloss.move(to: CGPoint(x: w * 0.59, y: h * 0.10))
            rightTipGloss.addCurve(
                to: CGPoint(x: w * 0.60, y: h * 0.22),
                control1: CGPoint(x: w * 0.61, y: h * 0.15),
                control2: CGPoint(x: w * 0.61, y: h * 0.18)
            )
            context.stroke(
                rightTipGloss,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.65),
                        Color.white.opacity(0.10)
                    ]),
                    startPoint: CGPoint(x: w * 0.59, y: h * 0.10),
                    endPoint: CGPoint(x: w * 0.60, y: h * 0.22)
                ),
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
            )

            let sparks: [(CGPoint, CGFloat)] = [
                (CGPoint(x: w * 0.78, y: h * 0.22), 2.8),
                (CGPoint(x: w * 0.24, y: h * 0.28), 2.2),
                (CGPoint(x: w * 0.67, y: h * 0.06), 2.0),
                (CGPoint(x: w * 0.76, y: h * 0.13), 1.5)
            ]
            for (pt, r) in sparks {
                context.fill(
                    Circle().path(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)),
                    with: .color(Color(red: 0.50, green: 0.95, blue: 1.0))
                )
            }
        }
        .offset(y: isBreathing ? -1.5 : 1.5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

public typealias DuolingoMascotView = DuolingoFlameArtView


