import SwiftUI

// MARK: - 1. Math
public struct MathSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.95, green: 0.60, blue: 0.10)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Drafting triangle paper cutout
            var triangle = Path()
            triangle.move(to: CGPoint(x: w * 0.14, y: h * 0.86))
            triangle.addLine(to: CGPoint(x: w * 0.86, y: h * 0.86))
            triangle.addLine(to: CGPoint(x: w * 0.14, y: h * 0.22))
            triangle.closeSubpath()
            context.fill(triangle, with: .color(tintColor.opacity(0.20)))
            context.stroke(triangle, with: .color(Color.white.opacity(0.70)), lineWidth: 1.4)

            // Inner cutout of triangle
            var innerTriangle = Path()
            innerTriangle.move(to: CGPoint(x: w * 0.25, y: h * 0.77))
            innerTriangle.addLine(to: CGPoint(x: w * 0.64, y: h * 0.77))
            innerTriangle.addLine(to: CGPoint(x: w * 0.25, y: h * 0.44))
            innerTriangle.closeSubpath()
            context.fill(innerTriangle, with: .color(Color.white.opacity(0.55)))

            // Sine wave curve
            var sineWave = Path()
            sineWave.move(to: CGPoint(x: w * 0.08, y: h * 0.55))
            sineWave.addCurve(
                to: CGPoint(x: w * 0.50, y: h * 0.35),
                control1: CGPoint(x: w * 0.22, y: h * 0.18),
                control2: CGPoint(x: w * 0.36, y: h * 0.25)
            )
            sineWave.addCurve(
                to: CGPoint(x: w * 0.92, y: h * 0.38),
                control1: CGPoint(x: w * 0.64, y: h * 0.45),
                control2: CGPoint(x: w * 0.78, y: h * 0.62)
            )
            context.stroke(sineWave, with: .color(tintColor), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

            // Compass arc
            var arc = Path()
            arc.addArc(center: CGPoint(x: w * 0.72, y: h * 0.68), radius: w * 0.16, startAngle: .degrees(-60), endAngle: .degrees(40), clockwise: false)
            context.stroke(arc, with: .color(Color.white.opacity(0.85)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [3, 2]))
        }
    }
}

// MARK: - 2. Physics
public struct PhysicsSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.45, green: 0.38, blue: 0.88)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Wave front arcs
            var wave1 = Path()
            wave1.addArc(center: CGPoint(x: w * 0.10, y: h * 0.90), radius: w * 0.32, startAngle: .degrees(-70), endAngle: .degrees(0), clockwise: false)
            context.stroke(wave1, with: .color(tintColor.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

            var wave2 = Path()
            wave2.addArc(center: CGPoint(x: w * 0.10, y: h * 0.90), radius: w * 0.50, startAngle: .degrees(-70), endAngle: .degrees(0), clockwise: false)
            context.stroke(wave2, with: .color(tintColor.opacity(0.25)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

            // Orbit 1: Tilted Ellipse (-35 deg)
            let cx = w * 0.52
            let cy = h * 0.48
            let orbitRect = CGRect(x: -w * 0.35, y: -h * 0.16, width: w * 0.70, height: h * 0.32)

            var orbitContext1 = context
            orbitContext1.translateBy(x: cx, y: cy)
            orbitContext1.rotate(by: .degrees(-35))
            let orbitPath1 = Ellipse().path(in: orbitRect)
            orbitContext1.stroke(orbitPath1, with: .color(Color.white.opacity(0.85)), lineWidth: 1.8)

            // Electron on Orbit 1
            let e1 = Circle().path(in: CGRect(x: w * 0.35 - 3.5, y: -3.5, width: 7, height: 7))
            orbitContext1.fill(e1, with: .color(tintColor))
            orbitContext1.stroke(e1, with: .color(Color.white), lineWidth: 1.2)

            // Orbit 2: Tilted Ellipse (+35 deg)
            var orbitContext2 = context
            orbitContext2.translateBy(x: cx, y: cy)
            orbitContext2.rotate(by: .degrees(35))
            let orbitPath2 = Ellipse().path(in: orbitRect)
            orbitContext2.stroke(orbitPath2, with: .color(Color.white.opacity(0.85)), lineWidth: 1.8)

            // Electron on Orbit 2
            let e2 = Circle().path(in: CGRect(x: -w * 0.35 - 3.5, y: -3.5, width: 7, height: 7))
            orbitContext2.fill(e2, with: .color(tintColor))
            orbitContext2.stroke(e2, with: .color(Color.white), lineWidth: 1.2)

            // Nucleus in Center
            let nucleusRect = CGRect(x: cx - w * 0.09, y: cy - w * 0.09, width: w * 0.18, height: w * 0.18)
            context.fill(Circle().path(in: nucleusRect), with: .color(tintColor))
            context.stroke(Circle().path(in: nucleusRect), with: .color(Color.white.opacity(0.90)), lineWidth: 1.6)

            // Nucleus highlight crescent
            var highlight = Path()
            highlight.addArc(center: CGPoint(x: cx - 1, y: cy - 1), radius: w * 0.06, startAngle: .degrees(-120), endAngle: .degrees(-30), clockwise: false)
            context.stroke(highlight, with: .color(Color.white.opacity(0.90)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
    }
}

// MARK: - 3. Chemistry
public struct ChemistrySubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.86, green: 0.28, blue: 0.68)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Hexagonal Benzene Ring in upper right
            let hx = w * 0.78
            let hy = h * 0.32
            let hr: CGFloat = w * 0.14
            var hex = Path()
            for i in 0..<6 {
                let angle = CGFloat(i) * CGFloat.pi / 3.0
                let pt = CGPoint(x: hx + hr * cos(angle), y: hy + hr * sin(angle))
                if i == 0 { hex.move(to: pt) } else { hex.addLine(to: pt) }
            }
            hex.closeSubpath()
            context.stroke(hex, with: .color(Color.white.opacity(0.70)), lineWidth: 1.4)
            context.stroke(Circle().path(in: CGRect(x: hx - hr * 0.55, y: hy - hr * 0.55, width: hr * 1.1, height: hr * 1.1)), with: .color(Color.white.opacity(0.50)), lineWidth: 1.0)

            // Conical Flask Silhouette
            var flask = Path()
            flask.move(to: CGPoint(x: w * 0.40, y: h * 0.20))
            flask.addLine(to: CGPoint(x: w * 0.60, y: h * 0.20))
            flask.addLine(to: CGPoint(x: w * 0.56, y: h * 0.42))
            flask.addLine(to: CGPoint(x: w * 0.76, y: h * 0.82))
            flask.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.86), control: CGPoint(x: w * 0.76, y: h * 0.86))
            flask.addLine(to: CGPoint(x: w * 0.28, y: h * 0.86))
            flask.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.82), control: CGPoint(x: w * 0.24, y: h * 0.86))
            flask.addLine(to: CGPoint(x: w * 0.44, y: h * 0.42))
            flask.closeSubpath()

            context.fill(flask, with: .color(Color.white.opacity(0.35)))
            context.stroke(flask, with: .color(Color.white.opacity(0.85)), lineWidth: 1.6)

            // Flask Liquid
            var liquid = Path()
            liquid.move(to: CGPoint(x: w * 0.35, y: h * 0.62))
            liquid.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.62), control: CGPoint(x: w * 0.50, y: h * 0.65))
            liquid.addLine(to: CGPoint(x: w * 0.73, y: h * 0.82))
            liquid.addLine(to: CGPoint(x: w * 0.27, y: h * 0.82))
            liquid.closeSubpath()
            context.fill(liquid, with: .color(tintColor.opacity(0.45)))

            // Rising bubbles
            let b1 = Circle().path(in: CGRect(x: w * 0.48 - 4, y: h * 0.54 - 4, width: 8, height: 8))
            let b2 = Circle().path(in: CGRect(x: w * 0.53 - 3, y: h * 0.44 - 3, width: 6, height: 6))
            let b3 = Circle().path(in: CGRect(x: w * 0.47 - 2.5, y: h * 0.32 - 2.5, width: 5, height: 5))
            context.fill(b1, with: .color(Color.white.opacity(0.80)))
            context.fill(b2, with: .color(Color.white.opacity(0.70)))
            context.fill(b3, with: .color(Color.white.opacity(0.60)))
        }
    }
}

// MARK: - 4. Biology
public struct BiologySubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.20, green: 0.72, blue: 0.40)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // DNA Helix Strand on left side
            var strandA = Path()
            strandA.move(to: CGPoint(x: w * 0.14, y: h * 0.18))
            strandA.addCurve(to: CGPoint(x: w * 0.26, y: h * 0.52), control1: CGPoint(x: w * 0.28, y: h * 0.30), control2: CGPoint(x: w * 0.12, y: h * 0.40))
            strandA.addCurve(to: CGPoint(x: w * 0.16, y: h * 0.86), control1: CGPoint(x: w * 0.36, y: h * 0.64), control2: CGPoint(x: w * 0.12, y: h * 0.74))
            context.stroke(strandA, with: .color(tintColor.opacity(0.60)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

            var strandB = Path()
            strandB.move(to: CGPoint(x: w * 0.26, y: h * 0.18))
            strandB.addCurve(to: CGPoint(x: w * 0.14, y: h * 0.52), control1: CGPoint(x: w * 0.12, y: h * 0.30), control2: CGPoint(x: w * 0.28, y: h * 0.40))
            strandB.addCurve(to: CGPoint(x: w * 0.24, y: h * 0.86), control1: CGPoint(x: w * 0.12, y: h * 0.64), control2: CGPoint(x: w * 0.36, y: h * 0.74))
            context.stroke(strandB, with: .color(Color.white.opacity(0.70)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

            // DNA rungs
            let rungs: [(CGFloat, CGFloat)] = [(0.26, 0.30), (0.42, 0.42), (0.60, 0.62), (0.76, 0.74)]
            for (y1, y2) in rungs {
                var rung = Path()
                rung.move(to: CGPoint(x: w * 0.16, y: h * y1))
                rung.addLine(to: CGPoint(x: w * 0.24, y: h * y2))
                context.stroke(rung, with: .color(Color.white.opacity(0.65)), lineWidth: 1.2)
            }

            // Botanical Leaf Silhouette
            var leaf = Path()
            leaf.move(to: CGPoint(x: w * 0.42, y: h * 0.84))
            leaf.addCurve(
                to: CGPoint(x: w * 0.86, y: h * 0.22),
                control1: CGPoint(x: w * 0.42, y: h * 0.48),
                control2: CGPoint(x: w * 0.62, y: h * 0.24)
            )
            leaf.addCurve(
                to: CGPoint(x: w * 0.42, y: h * 0.84),
                control1: CGPoint(x: w * 0.90, y: h * 0.56),
                control2: CGPoint(x: w * 0.66, y: h * 0.84)
            )
            leaf.closeSubpath()

            context.fill(leaf, with: .color(tintColor.opacity(0.35)))
            context.stroke(leaf, with: .color(Color.white.opacity(0.85)), lineWidth: 1.5)

            // Leaf Central Vein
            var vein = Path()
            vein.move(to: CGPoint(x: w * 0.42, y: h * 0.84))
            vein.addCurve(to: CGPoint(x: w * 0.86, y: h * 0.22), control1: CGPoint(x: w * 0.56, y: h * 0.62), control2: CGPoint(x: w * 0.72, y: h * 0.40))
            context.stroke(vein, with: .color(Color.white.opacity(0.80)), lineWidth: 1.4)

            // Side Veins
            let sideVeins: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (0.50, 0.72, 0.60, 0.66),
                (0.60, 0.58, 0.72, 0.52),
                (0.70, 0.44, 0.80, 0.38)
            ]
            for (x1, y1, x2, y2) in sideVeins {
                var sv = Path()
                sv.move(to: CGPoint(x: w * x1, y: h * y1))
                sv.addLine(to: CGPoint(x: w * x2, y: h * y2))
                context.stroke(sv, with: .color(Color.white.opacity(0.60)), lineWidth: 1.0)
            }
        }
    }
}

// MARK: - 5. History Or Geography
public struct HistoryOrGeographySubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.85, green: 0.52, blue: 0.16)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Globe Meridian Rings in Background
            let gRect = CGRect(x: w * 0.46, y: h * 0.15, width: w * 0.48, height: w * 0.48)
            context.stroke(Circle().path(in: gRect), with: .color(tintColor.opacity(0.25)), lineWidth: 1.2)
            context.stroke(Ellipse().path(in: CGRect(x: w * 0.58, y: h * 0.15, width: w * 0.24, height: w * 0.48)), with: .color(tintColor.opacity(0.25)), lineWidth: 1.2)

            // Classical Temple
            // 1. Triangular Pediment
            var pediment = Path()
            pediment.move(to: CGPoint(x: w * 0.16, y: h * 0.42))
            pediment.addLine(to: CGPoint(x: w * 0.50, y: h * 0.24))
            pediment.addLine(to: CGPoint(x: w * 0.84, y: h * 0.42))
            pediment.closeSubpath()
            context.fill(pediment, with: .color(tintColor.opacity(0.35)))
            context.stroke(pediment, with: .color(Color.white.opacity(0.85)), lineWidth: 1.4)

            // 2. Architrave Bar
            let arch = RoundedRectangle(cornerRadius: 2).path(in: CGRect(x: w * 0.14, y: h * 0.42, width: w * 0.72, height: h * 0.05))
            context.fill(arch, with: .color(Color.white.opacity(0.40)))
            context.stroke(arch, with: .color(Color.white.opacity(0.85)), lineWidth: 1.0)

            // 3. 4 Columns
            let colX: [CGFloat] = [0.22, 0.40, 0.60, 0.78]
            for cx in colX {
                let col = RoundedRectangle(cornerRadius: 1.5).path(in: CGRect(x: w * cx - 3, y: h * 0.48, width: 6, height: h * 0.28))
                context.fill(col, with: .color(tintColor.opacity(0.40)))
                context.stroke(col, with: .color(Color.white.opacity(0.85)), lineWidth: 1.0)
            }

            // 4. Base Plinth Steps
            let base1 = RoundedRectangle(cornerRadius: 2).path(in: CGRect(x: w * 0.14, y: h * 0.76, width: w * 0.72, height: h * 0.05))
            let base2 = RoundedRectangle(cornerRadius: 2).path(in: CGRect(x: w * 0.10, y: h * 0.81, width: w * 0.80, height: h * 0.05))
            context.fill(base1, with: .color(Color.white.opacity(0.35)))
            context.stroke(base1, with: .color(Color.white.opacity(0.70)), lineWidth: 1.0)
            context.fill(base2, with: .color(tintColor.opacity(0.30)))
            context.stroke(base2, with: .color(Color.white.opacity(0.70)), lineWidth: 1.0)

            // Compass needle in corner
            var needle = Path()
            needle.move(to: CGPoint(x: w * 0.85, y: h * 0.18))
            needle.addLine(to: CGPoint(x: w * 0.89, y: h * 0.25))
            needle.addLine(to: CGPoint(x: w * 0.85, y: h * 0.32))
            needle.addLine(to: CGPoint(x: w * 0.81, y: h * 0.25))
            needle.closeSubpath()
            context.fill(needle, with: .color(Color.white.opacity(0.70)))
        }
    }
}

// MARK: - 6. Literature
public struct LiteratureSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.92, green: 0.38, blue: 0.22)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Open Book
            // Left Page
            var leftPage = Path()
            leftPage.move(to: CGPoint(x: w * 0.50, y: h * 0.78))
            leftPage.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.68), control: CGPoint(x: w * 0.32, y: h * 0.80))
            leftPage.addLine(to: CGPoint(x: w * 0.18, y: h * 0.38))
            leftPage.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.46), control: CGPoint(x: w * 0.34, y: h * 0.46))
            leftPage.closeSubpath()
            context.fill(leftPage, with: .color(Color.white.opacity(0.55)))
            context.stroke(leftPage, with: .color(Color.white.opacity(0.85)), lineWidth: 1.4)

            // Right Page
            var rightPage = Path()
            rightPage.move(to: CGPoint(x: w * 0.50, y: h * 0.78))
            rightPage.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.68), control: CGPoint(x: w * 0.68, y: h * 0.80))
            rightPage.addLine(to: CGPoint(x: w * 0.82, y: h * 0.38))
            rightPage.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.46), control: CGPoint(x: w * 0.66, y: h * 0.46))
            rightPage.closeSubpath()
            context.fill(rightPage, with: .color(tintColor.opacity(0.25)))
            context.stroke(rightPage, with: .color(Color.white.opacity(0.85)), lineWidth: 1.4)

            // Book Spine
            var spine = Path()
            spine.move(to: CGPoint(x: w * 0.50, y: h * 0.46))
            spine.addLine(to: CGPoint(x: w * 0.50, y: h * 0.80))
            context.stroke(spine, with: .color(tintColor.opacity(0.80)), lineWidth: 1.8)

            // Text lines on left page
            let leftLines: [CGFloat] = [0.44, 0.50, 0.56, 0.62]
            for ly in leftLines {
                var line = Path()
                line.move(to: CGPoint(x: w * 0.22, y: h * ly))
                line.addLine(to: CGPoint(x: w * 0.44, y: h * (ly + 0.04)))
                context.stroke(line, with: .color(tintColor.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }

            // Fountain Pen Nib (top right pointing down)
            var nib = Path()
            nib.move(to: CGPoint(x: w * 0.68, y: h * 0.16))
            nib.addLine(to: CGPoint(x: w * 0.80, y: h * 0.22))
            nib.addLine(to: CGPoint(x: w * 0.74, y: h * 0.38))
            nib.addLine(to: CGPoint(x: w * 0.68, y: h * 0.46))
            nib.addLine(to: CGPoint(x: w * 0.62, y: h * 0.38))
            nib.closeSubpath()
            context.fill(nib, with: .color(tintColor.opacity(0.50)))
            context.stroke(nib, with: .color(Color.white.opacity(0.90)), lineWidth: 1.3)

            // Nib slit line
            var slit = Path()
            slit.move(to: CGPoint(x: w * 0.68, y: h * 0.46))
            slit.addLine(to: CGPoint(x: w * 0.68, y: h * 0.28))
            context.stroke(slit, with: .color(Color.white.opacity(0.90)), lineWidth: 1.0)
        }
    }
}

// MARK: - 7. English
public struct EnglishSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.15, green: 0.58, blue: 0.92)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Global longitude meridian arcs in background
            var meridian = Path()
            meridian.addArc(center: CGPoint(x: w * 0.82, y: h * 0.35), radius: w * 0.25, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            context.stroke(meridian, with: .color(tintColor.opacity(0.20)), lineWidth: 1.4)

            // Secondary Speech Bubble
            let b2 = RoundedRectangle(cornerRadius: 10, style: .continuous).path(in: CGRect(x: w * 0.42, y: h * 0.45, width: w * 0.46, height: h * 0.36))
            context.fill(b2, with: .color(tintColor.opacity(0.25)))
            context.stroke(b2, with: .color(Color.white.opacity(0.70)), lineWidth: 1.2)

            // Primary Speech Bubble (Front)
            var bubble = Path()
            let bRect = CGRect(x: w * 0.12, y: h * 0.20, width: w * 0.60, height: h * 0.48)
            bubble.addPath(RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: bRect))
            // Pointer tail
            bubble.move(to: CGPoint(x: w * 0.22, y: h * 0.68))
            bubble.addLine(to: CGPoint(x: w * 0.16, y: h * 0.82))
            bubble.addLine(to: CGPoint(x: w * 0.32, y: h * 0.68))
            bubble.closeSubpath()

            context.fill(bubble, with: .color(Color.white.opacity(0.55)))
            context.stroke(bubble, with: .color(Color.white.opacity(0.90)), lineWidth: 1.5)

            // Bold Letter 'A' inside Primary Bubble
            var letterA = Path()
            letterA.move(to: CGPoint(x: w * 0.34, y: h * 0.56))
            letterA.addLine(to: CGPoint(x: w * 0.42, y: h * 0.30))
            letterA.addLine(to: CGPoint(x: w * 0.50, y: h * 0.56))
            context.stroke(letterA, with: .color(tintColor), style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))

            // Crossbar of 'A'
            var crossbar = Path()
            crossbar.move(to: CGPoint(x: w * 0.37, y: h * 0.47))
            crossbar.addLine(to: CGPoint(x: w * 0.47, y: h * 0.47))
            context.stroke(crossbar, with: .color(tintColor), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
    }
}

// MARK: - 8. Civics Or Philosophy
public struct CivicsOrPhilosophySubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.88, green: 0.28, blue: 0.32)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Heraldic Shield Silhouette
            var shield = Path()
            shield.move(to: CGPoint(x: w * 0.24, y: h * 0.18))
            shield.addLine(to: CGPoint(x: w * 0.76, y: h * 0.18))
            shield.addLine(to: CGPoint(x: w * 0.76, y: h * 0.52))
            shield.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.86), control: CGPoint(x: w * 0.74, y: h * 0.74))
            shield.addQuadCurve(to: CGPoint(x: w * 0.24, y: h * 0.52), control: CGPoint(x: w * 0.26, y: h * 0.74))
            shield.closeSubpath()

            context.fill(shield, with: .color(tintColor.opacity(0.20)))
            context.stroke(shield, with: .color(Color.white.opacity(0.85)), lineWidth: 1.5)

            // Right half of shield filled with lighter tint
            var shieldRight = Path()
            shieldRight.move(to: CGPoint(x: w * 0.50, y: h * 0.18))
            shieldRight.addLine(to: CGPoint(x: w * 0.76, y: h * 0.18))
            shieldRight.addLine(to: CGPoint(x: w * 0.76, y: h * 0.52))
            shieldRight.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.86), control: CGPoint(x: w * 0.74, y: h * 0.74))
            shieldRight.closeSubpath()
            context.fill(shieldRight, with: .color(Color.white.opacity(0.25)))

            // Central Vertical Pillar of Scale
            var pillar = Path()
            pillar.move(to: CGPoint(x: w * 0.50, y: h * 0.26))
            pillar.addLine(to: CGPoint(x: w * 0.50, y: h * 0.72))
            context.stroke(pillar, with: .color(Color.white.opacity(0.90)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

            // Horizontal Scale Beam
            var beam = Path()
            beam.move(to: CGPoint(x: w * 0.32, y: h * 0.38))
            beam.addLine(to: CGPoint(x: w * 0.68, y: h * 0.38))
            context.stroke(beam, with: .color(Color.white.opacity(0.90)), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

            // Left Scale Pan & Strings
            var leftPan = Path()
            leftPan.move(to: CGPoint(x: w * 0.32, y: h * 0.38))
            leftPan.addLine(to: CGPoint(x: w * 0.26, y: h * 0.54))
            leftPan.addQuadCurve(to: CGPoint(x: w * 0.38, y: h * 0.54), control: CGPoint(x: w * 0.32, y: h * 0.60))
            leftPan.addLine(to: CGPoint(x: w * 0.32, y: h * 0.38))
            context.fill(leftPan, with: .color(tintColor.opacity(0.40)))
            context.stroke(leftPan, with: .color(Color.white.opacity(0.85)), lineWidth: 1.2)

            // Right Scale Pan & Strings
            var rightPan = Path()
            rightPan.move(to: CGPoint(x: w * 0.68, y: h * 0.38))
            rightPan.addLine(to: CGPoint(x: w * 0.62, y: h * 0.54))
            rightPan.addQuadCurve(to: CGPoint(x: w * 0.74, y: h * 0.54), control: CGPoint(x: w * 0.68, y: h * 0.60))
            rightPan.addLine(to: CGPoint(x: w * 0.68, y: h * 0.38))
            context.fill(rightPan, with: .color(tintColor.opacity(0.40)))
            context.stroke(rightPan, with: .color(Color.white.opacity(0.85)), lineWidth: 1.2)
        }
    }
}

// MARK: - 9. Economics
public struct EconomicsSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.90, green: 0.65, blue: 0.12)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Coin token in top left
            let coinRect = CGRect(x: w * 0.16, y: h * 0.22, width: w * 0.22, height: w * 0.22)
            context.fill(Circle().path(in: coinRect), with: .color(Color.white.opacity(0.45)))
            context.stroke(Circle().path(in: coinRect), with: .color(tintColor), lineWidth: 1.5)
            context.stroke(Circle().path(in: coinRect.insetBy(dx: 3, dy: 3)), with: .color(Color.white.opacity(0.70)), lineWidth: 1.0)

            // Bar 1
            let bar1 = RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: w * 0.22, y: h * 0.68, width: w * 0.12, height: h * 0.18))
            // Bar 2
            let bar2 = RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: w * 0.40, y: h * 0.54, width: w * 0.12, height: h * 0.32))
            // Bar 3
            let bar3 = RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: w * 0.58, y: h * 0.42, width: w * 0.12, height: h * 0.44))
            // Bar 4
            let bar4 = RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: w * 0.76, y: h * 0.28, width: w * 0.12, height: h * 0.58))

            context.fill(bar1, with: .color(tintColor.opacity(0.25)))
            context.stroke(bar1, with: .color(Color.white.opacity(0.60)), lineWidth: 1.0)
            context.fill(bar2, with: .color(tintColor.opacity(0.35)))
            context.stroke(bar2, with: .color(Color.white.opacity(0.60)), lineWidth: 1.0)
            context.fill(bar3, with: .color(tintColor.opacity(0.45)))
            context.stroke(bar3, with: .color(Color.white.opacity(0.60)), lineWidth: 1.0)
            context.fill(bar4, with: .color(tintColor.opacity(0.55)))
            context.stroke(bar4, with: .color(Color.white.opacity(0.70)), lineWidth: 1.0)

            // Ascending Trend Line with Arrow
            var trend = Path()
            trend.move(to: CGPoint(x: w * 0.18, y: h * 0.74))
            trend.addLine(to: CGPoint(x: w * 0.46, y: h * 0.52))
            trend.addLine(to: CGPoint(x: w * 0.64, y: h * 0.44))
            trend.addLine(to: CGPoint(x: w * 0.86, y: h * 0.20))
            context.stroke(trend, with: .color(Color.white.opacity(0.95)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            // Arrow Head
            var arrow = Path()
            arrow.move(to: CGPoint(x: w * 0.74, y: h * 0.20))
            arrow.addLine(to: CGPoint(x: w * 0.86, y: h * 0.20))
            arrow.addLine(to: CGPoint(x: w * 0.86, y: h * 0.32))
            context.stroke(arrow, with: .color(Color.white.opacity(0.95)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - 10. Art And Design
public struct ArtAndDesignSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.90, green: 0.25, blue: 0.55)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Kidney-shaped Artist Palette
            var palette = Path()
            palette.move(to: CGPoint(x: w * 0.22, y: h * 0.42))
            palette.addCurve(to: CGPoint(x: w * 0.65, y: h * 0.18), control1: CGPoint(x: w * 0.26, y: h * 0.18), control2: CGPoint(x: w * 0.50, y: h * 0.14))
            palette.addCurve(to: CGPoint(x: w * 0.86, y: h * 0.60), control1: CGPoint(x: w * 0.82, y: h * 0.24), control2: CGPoint(x: w * 0.92, y: h * 0.44))
            palette.addCurve(to: CGPoint(x: w * 0.62, y: h * 0.84), control1: CGPoint(x: w * 0.82, y: h * 0.76), control2: CGPoint(x: w * 0.74, y: h * 0.86))
            palette.addCurve(to: CGPoint(x: w * 0.38, y: h * 0.70), control1: CGPoint(x: w * 0.52, y: h * 0.82), control2: CGPoint(x: w * 0.46, y: h * 0.72))
            palette.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.42), control1: CGPoint(x: w * 0.26, y: h * 0.68), control2: CGPoint(x: w * 0.16, y: h * 0.56))
            palette.closeSubpath()

            context.fill(palette, with: .color(Color.white.opacity(0.50)))
            context.stroke(palette, with: .color(Color.white.opacity(0.85)), lineWidth: 1.5)

            // Thumb hole cutout
            let thumb = Ellipse().path(in: CGRect(x: w * 0.70 - 6, y: h * 0.64 - 8, width: 12, height: 16))
            context.fill(thumb, with: .color(tintColor.opacity(0.20)))
            context.stroke(thumb, with: .color(Color.white.opacity(0.80)), lineWidth: 1.2)

            // Pigment wells
            let pigments: [(CGFloat, CGFloat, Color)] = [
                (0.38, 0.28, Color(red: 0.95, green: 0.60, blue: 0.10)), // Yellow
                (0.54, 0.24, Color(red: 0.15, green: 0.58, blue: 0.92)), // Blue
                (0.70, 0.35, Color(red: 0.88, green: 0.28, blue: 0.32)), // Red
                (0.80, 0.48, Color(red: 0.20, green: 0.72, blue: 0.40))  // Green
            ]
            for (px, py, col) in pigments {
                let dot = Circle().path(in: CGRect(x: w * px - 4, y: h * py - 4, width: 8, height: 8))
                context.fill(dot, with: .color(col.opacity(0.80)))
                context.stroke(dot, with: .color(Color.white.opacity(0.70)), lineWidth: 0.8)
            }

            // Paintbrush cutting diagonally
            var brush = Path()
            brush.move(to: CGPoint(x: w * 0.18, y: h * 0.88))
            brush.addLine(to: CGPoint(x: w * 0.48, y: h * 0.48))
            context.stroke(brush, with: .color(tintColor.opacity(0.85)), style: StrokeStyle(lineWidth: 3.0, lineCap: .round))

            // Bristle tip
            var tip = Path()
            tip.move(to: CGPoint(x: w * 0.48, y: h * 0.48))
            tip.addLine(to: CGPoint(x: w * 0.54, y: h * 0.40))
            context.stroke(tip, with: .color(Color.white.opacity(0.90)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
    }
}

// MARK: - 11. Computer Science
public struct ComputerScienceSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.08, green: 0.68, blue: 0.54)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Laptop Display Outer
            let dispRect = CGRect(x: w * 0.20, y: h * 0.20, width: w * 0.60, height: h * 0.44)
            let disp = RoundedRectangle(cornerRadius: 6, style: .continuous).path(in: dispRect)
            context.fill(disp, with: .color(Color.white.opacity(0.55)))
            context.stroke(disp, with: .color(Color.white.opacity(0.85)), lineWidth: 1.4)

            // Inner Display Screen
            let scrRect = CGRect(x: w * 0.24, y: h * 0.24, width: w * 0.52, height: h * 0.36)
            let scr = RoundedRectangle(cornerRadius: 4, style: .continuous).path(in: scrRect)
            context.fill(scr, with: .color(tintColor.opacity(0.35)))

            // Code Brackets inside screen: < / >
            // Left Bracket: <
            var leftB = Path()
            leftB.move(to: CGPoint(x: w * 0.39, y: h * 0.35))
            leftB.addLine(to: CGPoint(x: w * 0.33, y: h * 0.42))
            leftB.addLine(to: CGPoint(x: w * 0.39, y: h * 0.49))
            context.stroke(leftB, with: .color(Color.white), style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))

            // Slash: /
            var slash = Path()
            slash.move(to: CGPoint(x: w * 0.47, y: h * 0.49))
            slash.addLine(to: CGPoint(x: w * 0.53, y: h * 0.35))
            context.stroke(slash, with: .color(Color.white), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

            // Right Bracket: >
            var rightB = Path()
            rightB.move(to: CGPoint(x: w * 0.61, y: h * 0.35))
            rightB.addLine(to: CGPoint(x: w * 0.67, y: h * 0.42))
            rightB.addLine(to: CGPoint(x: w * 0.61, y: h * 0.49))
            context.stroke(rightB, with: .color(Color.white), style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))

            // Laptop Base Plinth
            var base = Path()
            base.move(to: CGPoint(x: w * 0.12, y: h * 0.66))
            base.addLine(to: CGPoint(x: w * 0.88, y: h * 0.66))
            base.addLine(to: CGPoint(x: w * 0.82, y: h * 0.74))
            base.addLine(to: CGPoint(x: w * 0.18, y: h * 0.74))
            base.closeSubpath()
            context.fill(base, with: .color(tintColor.opacity(0.40)))
            context.stroke(base, with: .color(Color.white.opacity(0.80)), lineWidth: 1.2)

            // Trackpad
            let pad = RoundedRectangle(cornerRadius: 2).path(in: CGRect(x: w * 0.42, y: h * 0.67, width: w * 0.16, height: h * 0.05))
            context.fill(pad, with: .color(Color.white.opacity(0.60)))
        }
    }
}

// MARK: - 12. Networking
public struct NetworkingSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.55, green: 0.40, blue: 0.92)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            let hub = CGPoint(x: w * 0.50, y: h * 0.50)
            let sat1 = CGPoint(x: w * 0.22, y: h * 0.28)
            let sat2 = CGPoint(x: w * 0.78, y: h * 0.28)
            let sat3 = CGPoint(x: w * 0.22, y: h * 0.74)
            let sat4 = CGPoint(x: w * 0.78, y: h * 0.74)
            let satellites = [sat1, sat2, sat3, sat4]

            // Network Links
            for sat in satellites {
                var link = Path()
                link.move(to: hub)
                link.addLine(to: sat)
                context.stroke(link, with: .color(Color.white.opacity(0.70)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
            }

            // Secondary Ring Link
            var ring = Path()
            ring.move(to: sat1)
            ring.addLine(to: sat2)
            ring.addLine(to: sat4)
            ring.addLine(to: sat3)
            ring.closeSubpath()
            context.stroke(ring, with: .color(tintColor.opacity(0.30)), lineWidth: 1.0)

            // Satellites
            for sat in satellites {
                let sRect = CGRect(x: sat.x - 6, y: sat.y - 6, width: 12, height: 12)
                context.fill(Circle().path(in: sRect), with: .color(Color.white.opacity(0.75)))
                context.stroke(Circle().path(in: sRect), with: .color(tintColor), lineWidth: 1.4)
            }

            // Central Hub
            let hubRect = CGRect(x: hub.x - 11, y: hub.y - 11, width: 22, height: 22)
            context.fill(Circle().path(in: hubRect), with: .color(tintColor))
            context.stroke(Circle().path(in: hubRect), with: .color(Color.white.opacity(0.95)), lineWidth: 1.8)

            // Hub core dot
            context.fill(Circle().path(in: CGRect(x: hub.x - 4, y: hub.y - 4, width: 8, height: 8)), with: .color(Color.white))
        }
    }
}

// MARK: - 13. General Assignment
public struct GeneralAssignmentSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.48, green: 0.42, blue: 0.84)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Clipboard Backing
            let board = RoundedRectangle(cornerRadius: 8, style: .continuous).path(in: CGRect(x: w * 0.22, y: h * 0.16, width: w * 0.56, height: h * 0.72))
            context.fill(board, with: .color(tintColor.opacity(0.30)))
            context.stroke(board, with: .color(Color.white.opacity(0.80)), lineWidth: 1.4)

            // Paper Sheet on Clipboard
            let sheet = RoundedRectangle(cornerRadius: 5, style: .continuous).path(in: CGRect(x: w * 0.26, y: h * 0.22, width: w * 0.48, height: h * 0.62))
            context.fill(sheet, with: .color(Color.white.opacity(0.60)))
            context.stroke(sheet, with: .color(Color.white.opacity(0.85)), lineWidth: 1.0)

            // Top Metal Clip
            let clip = RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: w * 0.38, y: h * 0.12, width: w * 0.24, height: h * 0.08))
            context.fill(clip, with: .color(Color.white.opacity(0.85)))
            context.stroke(clip, with: .color(tintColor), lineWidth: 1.2)

            // Checklist Items
            let items: [(CGFloat, Bool)] = [(0.34, true), (0.48, true), (0.62, false)]
            for (iy, checked) in items {
                // Checkbox
                let cb = RoundedRectangle(cornerRadius: 2).path(in: CGRect(x: w * 0.32, y: h * iy, width: 9, height: 9))
                context.stroke(cb, with: .color(tintColor), lineWidth: 1.2)
                if checked {
                    context.fill(cb, with: .color(tintColor.opacity(0.80)))
                    var check = Path()
                    check.move(to: CGPoint(x: w * 0.32 + 2, y: h * iy + 4.5))
                    check.addLine(to: CGPoint(x: w * 0.32 + 4, y: h * iy + 7))
                    check.addLine(to: CGPoint(x: w * 0.32 + 7.5, y: h * iy + 2))
                    context.stroke(check, with: .color(Color.white), lineWidth: 1.2)
                }
                // Text Bar
                let line = RoundedRectangle(cornerRadius: 1.5).path(in: CGRect(x: w * 0.46, y: h * iy + 2.5, width: w * 0.22, height: 4))
                context.fill(line, with: .color(Color.white.opacity(0.80)))
            }
        }
    }
}

// MARK: - 14. Other
public struct OtherSubjectVectorArt: View {
    public let tintColor: Color
    public init(tintColor: Color = Color(red: 0.40, green: 0.52, blue: 0.64)) {
        self.tintColor = tintColor
    }
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            let bg = RoundedRectangle(cornerRadius: 12, style: .continuous).path(in: CGRect(x: 0, y: 0, width: w, height: h))
            context.fill(bg, with: .color(tintColor.opacity(0.12)))

            // Bottom Book
            let b1 = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: w * 0.18, y: h * 0.62, width: w * 0.64, height: h * 0.18))
            context.fill(b1, with: .color(tintColor.opacity(0.35)))
            context.stroke(b1, with: .color(Color.white.opacity(0.80)), lineWidth: 1.2)

            // Top Book (Angled)
            var b2Context = context
            b2Context.translateBy(x: w * 0.50, y: h * 0.46)
            b2Context.rotate(by: .degrees(-6))
            let b2Rect = CGRect(x: -w * 0.28, y: -h * 0.09, width: w * 0.56, height: h * 0.18)
            let b2 = RoundedRectangle(cornerRadius: 4).path(in: b2Rect)
            b2Context.fill(b2, with: .color(Color.white.opacity(0.55)))
            b2Context.stroke(b2, with: .color(Color.white.opacity(0.90)), lineWidth: 1.2)

            // Ribbon bookmark
            var ribbon = Path()
            ribbon.move(to: CGPoint(x: w * 0.64, y: h * 0.50))
            ribbon.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.76), control: CGPoint(x: w * 0.70, y: h * 0.62))
            ribbon.addLine(to: CGPoint(x: w * 0.76, y: h * 0.74))
            context.stroke(ribbon, with: .color(tintColor), lineWidth: 2.2)

            // Pencil Silhouette
            var pencil = Path()
            pencil.move(to: CGPoint(x: w * 0.16, y: h * 0.32))
            pencil.addLine(to: CGPoint(x: w * 0.52, y: h * 0.32))
            context.stroke(pencil, with: .color(Color.white.opacity(0.90)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        }
    }
}

// MARK: - RealSubjectArtScene Dispatcher
public struct RealSubjectArtScene: View {
    public let courseName: String
    public let category: SubjectCategory?
    public let tintColor: Color?
    public let isDark: Bool

    public init(courseName: String, tintColor: Color? = nil, isDark: Bool = false) {
        self.courseName = courseName
        self.category = nil
        self.tintColor = tintColor
        self.isDark = isDark
    }

    public init(category: SubjectCategory, tintColor: Color? = nil, isDark: Bool = false) {
        self.courseName = ""
        self.category = category
        self.tintColor = tintColor
        self.isDark = isDark
    }

    private var resolvedCategory: SubjectCategory {
        category ?? SubjectArtHelper.category(for: courseName)
    }

    private var resolvedColor: Color {
        tintColor ?? SubjectArtHelper.themeColor(for: resolvedCategory)
    }

    public var body: some View {
        Group {
            switch resolvedCategory {
            case .computerScience:
                ComputerScienceSubjectVectorArt(tintColor: resolvedColor)
            case .math:
                MathSubjectVectorArt(tintColor: resolvedColor)
            case .english:
                EnglishSubjectVectorArt(tintColor: resolvedColor)
            case .literature:
                LiteratureSubjectVectorArt(tintColor: resolvedColor)
            case .physics:
                PhysicsSubjectVectorArt(tintColor: resolvedColor)
            case .chemistry:
                ChemistrySubjectVectorArt(tintColor: resolvedColor)
            case .biology:
                BiologySubjectVectorArt(tintColor: resolvedColor)
            case .history:
                HistoryOrGeographySubjectVectorArt(tintColor: resolvedColor)
            case .defenseEducation:
                CivicsOrPhilosophySubjectVectorArt(tintColor: resolvedColor)
            case .localEducation:
                HistoryOrGeographySubjectVectorArt(tintColor: resolvedColor)
            case .experientialActivities:
                GeneralAssignmentSubjectVectorArt(tintColor: resolvedColor)
            case .other:
                OtherSubjectVectorArt(tintColor: resolvedColor)
            }
        }
    }
}

// Compatibility typealiases
public typealias HistorySubjectVectorArt = HistoryOrGeographySubjectVectorArt
public typealias DefenseEducationSubjectVectorArt = CivicsOrPhilosophySubjectVectorArt
public typealias LocalEducationSubjectVectorArt = HistoryOrGeographySubjectVectorArt
public typealias ExperientialActivitiesSubjectVectorArt = GeneralAssignmentSubjectVectorArt
public typealias LaptopCodeVectorArtView = ComputerScienceSubjectVectorArt
public typealias MathGeometryVectorArtView = MathSubjectVectorArt
public typealias ScienceFlaskVectorArtView = ChemistrySubjectVectorArt
public typealias NotebookVectorArtView = OtherSubjectVectorArt
public typealias AbstractWaveDecorView = ComputerScienceSubjectVectorArt
public typealias AbstractOrbitalDecorView = MathSubjectVectorArt
public typealias AbstractLuminousOrbsView = ChemistrySubjectVectorArt
public typealias AbstractGeometricPlatesView = OtherSubjectVectorArt
