import SwiftUI
import WidgetKit

public enum SubjectCategory: Sendable {
    case math
    case literature
    case english
    case physics
    case chemistry
    case biology
    case historyOrGeography
    case civicsOrPhilosophy
    case economics
    case artAndDesign
    case computerScience
    case networking
    case generalAssignment
    case other
}

public struct SubjectArtHelper {
    public static func category(for courseName: String, title: String? = nil) -> SubjectCategory {
        let combined = "\(courseName) \(title ?? "")".lowercased()
        if combined.contains("toán") || combined.contains("math") || combined.contains("giải tích") || combined.contains("đại số") || combined.contains("hình học") || combined.contains("xác suất") || combined.contains("calculus") {
            return .math
        } else if combined.contains("lập trình") || combined.contains("tin học") || combined.contains("di động") || combined.contains("ios") || combined.contains("swift") || combined.contains("python") || combined.contains("java") || combined.contains("cntt") || combined.contains("công nghệ thông tin") || (combined.contains("tin") && !combined.contains("thông tin liên lạc")) {
            return .computerScience
        } else if combined.contains("mạng") || combined.contains("network") || combined.contains("an ninh mạng") || combined.contains("tcp") || combined.contains("socket") || combined.contains("cloud") {
            return .networking
        } else if combined.contains("ngữ văn") || combined.contains("tiếng việt") || combined.contains("literature") || combined.contains("writing") || combined.contains("essay") || (combined.contains("văn") && !combined.contains("văn phòng")) {
            return .literature
        } else if combined.contains("tiếng anh") || combined.contains("english") || combined.contains("ielts") || combined.contains("toeic") || (combined.contains("anh") && !combined.contains("hình ảnh") && !combined.contains("âm thanh")) {
            return .english
        } else if combined.contains("vật lý") || combined.contains("vật lí") || combined.contains("physics") || combined.contains("môn lý") || combined.contains("sbt lý") || (combined.contains("lý") && !combined.contains("quản lý") && !combined.contains("xử lý") && !combined.contains("tâm lý") && !combined.contains("pháp lý") && !combined.contains("địa lý") && !combined.contains("địa lí") && !combined.contains("triết lý")) {
            return .physics
        } else if combined.contains("hóa học") || combined.contains("môn hóa") || combined.contains("chemistry") || (combined.contains("hóa") && !combined.contains("tự động hóa") && !combined.contains("tiến hóa") && !combined.contains("hóa đơn") && !combined.contains("văn hóa")) {
            return .chemistry
        } else if combined.contains("sinh học") || combined.contains("môn sinh") || combined.contains("biology") || combined.contains("y học") || (combined.contains("sinh") && !combined.contains("học sinh") && !combined.contains("sinh viên") && !combined.contains("sinh hoạt")) {
            return .biology
        } else if combined.contains("lịch sử") || combined.contains("history") || combined.contains("địa lý") || combined.contains("địa lí") || combined.contains("geography") || (combined.contains("sử") && !combined.contains("sử dụng")) || (combined.contains("địa") && !combined.contains("địa chỉ")) {
            return .historyOrGeography
        } else if combined.contains("gdcd") || combined.contains("triết") || combined.contains("mác") || combined.contains("tư tưởng") || combined.contains("chính trị") || combined.contains("pháp luật") || combined.contains("kinh tế và pháp luật") || combined.contains("law") {
            return .civicsOrPhilosophy
        } else if combined.contains("kinh tế") || combined.contains("quản trị") || combined.contains("tài chính") || combined.contains("marketing") || combined.contains("kế toán") || combined.contains("business") {
            return .economics
        } else if combined.contains("đồ họa") || combined.contains("thiết kế") || combined.contains("mỹ thuật") || combined.contains("art") || combined.contains("design") || combined.contains("vẽ") {
            return .artAndDesign
        } else if combined.contains("nhiệm vụ") || combined.contains("lab") || combined.contains("thực hành") || combined.contains("bài tập") || combined.contains("project") || combined.contains("dự án") {
            return .generalAssignment
        } else {
            return .other
        }
    }

    public static func icon(for courseName: String, title: String? = nil) -> String {
        switch category(for: courseName, title: title) {
        case .math: return "function"
        case .literature: return "book.pages"
        case .english: return "globe.americas"
        case .physics: return "atom"
        case .chemistry: return "flask"
        case .biology: return "leaf"
        case .historyOrGeography: return "building.columns"
        case .civicsOrPhilosophy: return "shield"
        case .economics: return "chart.line.uptrend.xyaxis"
        case .artAndDesign: return "paintpalette"
        case .computerScience: return "laptopcomputer"
        case .networking: return "network"
        case .generalAssignment: return "checklist"
        case .other: return "graduationcap"
        }
    }

    public static func themeColor(for courseName: String, title: String? = nil) -> Color {
        switch category(for: courseName, title: title) {
        case .math: return Color(red: 0.95, green: 0.60, blue: 0.10)
        case .literature: return Color(red: 0.92, green: 0.38, blue: 0.22)
        case .english: return Color(red: 0.15, green: 0.58, blue: 0.92)
        case .physics: return Color(red: 0.45, green: 0.38, blue: 0.88)
        case .chemistry: return Color(red: 0.86, green: 0.28, blue: 0.68)
        case .biology: return Color(red: 0.20, green: 0.72, blue: 0.40)
        case .historyOrGeography: return Color(red: 0.85, green: 0.52, blue: 0.16)
        case .computerScience: return Color(red: 0.08, green: 0.68, blue: 0.54)
        case .networking: return Color(red: 0.55, green: 0.40, blue: 0.92)
        case .civicsOrPhilosophy: return Color(red: 0.88, green: 0.28, blue: 0.32)
        case .economics: return Color(red: 0.90, green: 0.65, blue: 0.12)
        case .artAndDesign: return Color(red: 0.90, green: 0.25, blue: 0.55)
        case .generalAssignment: return Color(red: 0.48, green: 0.42, blue: 0.84)
        case .other: return Color(red: 0.40, green: 0.52, blue: 0.64)
        }
    }

    public static func bannerBackground(for courseName: String, title: String? = nil) -> Color {
        switch category(for: courseName, title: title) {
        case .math: return Color(red: 0.52, green: 0.32, blue: 0.05)
        case .literature: return Color(red: 0.55, green: 0.22, blue: 0.08)
        case .english: return Color(red: 0.08, green: 0.32, blue: 0.60)
        case .physics: return Color(red: 0.03, green: 0.34, blue: 0.42)
        case .chemistry: return Color(red: 0.42, green: 0.12, blue: 0.38)
        case .biology: return Color(red: 0.16, green: 0.38, blue: 0.10)
        case .historyOrGeography: return Color(red: 0.46, green: 0.28, blue: 0.06)
        case .computerScience: return Color(red: 0.04, green: 0.36, blue: 0.24)
        case .networking: return Color(red: 0.26, green: 0.16, blue: 0.50)
        case .civicsOrPhilosophy: return Color(red: 0.48, green: 0.12, blue: 0.14)
        case .economics, .artAndDesign, .generalAssignment, .other:
            return Color(red: 0.10, green: 0.25, blue: 0.48)
        }
    }
}

public struct CourseColorHelper {
    public static func color(for courseName: String, title: String? = nil) -> Color {
        SubjectArtHelper.themeColor(for: courseName, title: title)
    }
}

public struct SubjectArtBadgeView: View {
    let courseName: String
    var title: String? = nil
    var size: CGFloat = 20
    @Environment(\.colorScheme) private var colorScheme

    public init(courseName: String, title: String? = nil, size: CGFloat = 20) {
        self.courseName = courseName
        self.title = title
        self.size = size
    }

    private var color: Color {
        SubjectArtHelper.themeColor(for: courseName, title: title)
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(color.opacity(colorScheme == .dark ? 0.28 : 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(color.opacity(colorScheme == .dark ? 0.55 : 0.38), lineWidth: 1)
                )
                .frame(width: size, height: size)

            Image(systemName: SubjectArtHelper.icon(for: courseName, title: title))
                .font(.system(size: size * 0.52, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

public struct SubjectVectorArtComposition: View {
    let courseName: String

    public init(courseName: String) {
        self.courseName = courseName
    }

    public var body: some View {
        HStack(spacing: 12) {
            switch SubjectArtHelper.category(for: courseName) {
            case .math:
                Image(systemName: "function")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "ruler")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .computerScience:
                Image(systemName: "iphone")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "curlybraces")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .networking:
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "server.rack")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "network")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .literature:
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "feather")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "book.pages")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .english:
                Image(systemName: "character.book.closed")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "quote.bubble")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "globe.americas")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .civicsOrPhilosophy:
                Image(systemName: "scroll")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "shield")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "building.columns")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .physics:
                Image(systemName: "gauge.with.needle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "atom")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .chemistry:
                Image(systemName: "bubbles.and.sparkles")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "flame")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "flask")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .biology:
                Image(systemName: "allergens")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "dna")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "leaf")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .economics:
                Image(systemName: "briefcase")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "chart.bar")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            case .historyOrGeography:
                Image(systemName: "map")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Image(systemName: "building.columns")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
                Image(systemName: "books.vertical")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            default:
                Image(systemName: "graduationcap")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
                Image(systemName: "books.vertical")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}

public struct ClassroomSubjectBanner: View {
    let item: Coursework
    @State private var isHovered: Bool = false

    public init(item: Coursework) {
        self.item = item
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SubjectArtHelper.bannerBackground(for: item.courseName))
                .frame(height: 105)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(isHovered ? 0.35 : 0.16), lineWidth: 1)
                )

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        SubjectArtBadgeView(courseName: item.courseName, size: 20)
                        Text(item.courseName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text(item.title)
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(item.formattedFullDueDate)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                DuolingoStudyBookArtView()
                    .frame(width: 88, height: 80)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .offset(x: isHovered ? -2 : 0, y: isHovered ? -2 : 0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isHovered)
            }
            .padding(.leading, 18)
            .padding(.trailing, 12)
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                isHovered = hovering
            }
        }
    }
}

public struct WidgetCardBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        RisoTheme.paper(for: colorScheme)
    }
}

public struct WidgetAppleGlassBackground: View {
    var cornerRadius: CGFloat = 20
    @Environment(\.colorScheme) private var colorScheme

    public init(cornerRadius: CGFloat = 20) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RisoTheme.paper(for: colorScheme)
    }
}

public struct WidgetAtmosphereBackground: View {
    public init(hasUrgentTask: Bool = false) {}

    public var body: some View {
        WidgetAppleGlassBackground()
    }
}

public struct CourseTagView: View {
    let name: String

    public init(name: String, showDot: Bool = false) {
        self.name = name
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: SubjectArtHelper.icon(for: name))
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(SubjectArtHelper.themeColor(for: name))
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

public struct DueBadgeView: View {
    let item: Coursework
    var compact: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    public init(item: Coursework, compact: Bool = false) {
        self.item = item
        self.compact = compact
    }

    private var badgeColor: Color {
        if item.isDueToday {
            return RisoTheme.accent(for: colorScheme)
        } else if item.isDueTomorrow {
            return RisoTheme.sub(for: colorScheme)
        } else {
            return RisoTheme.muted(for: colorScheme)
        }
    }

    private var badgeText: String {
        if compact {
            if item.isDueToday {
                return item.timeOnlyString == "Cuối ngày" ? "Hết hôm nay" : "Hôm nay \(item.timeOnlyString)"
            } else if item.isDueTomorrow {
                return item.timeOnlyString == "Cuối ngày" ? "Hết ngày mai" : "Mai \(item.timeOnlyString)"
            }
            return item.timeOnlyString
        } else {
            return item.friendlyDueString
        }
    }

    public var body: some View {
        Text(badgeText)
            .font(.system(size: compact ? 9.5 : 10.5, weight: .bold, design: .monospaced))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2.5 : 3.5)
            .background(badgeColor.opacity(colorScheme == .dark ? 0.22 : 0.14))
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(badgeColor, lineWidth: 1)
            )
    }
}

public struct WidgetEmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        RisoEmptyStateDeskView()
    }
}

// MARK: - RISOGRAPH POSTER & EDITORIAL PRINT SYSTEM
// Strictly Flat: No Gradients, No Soft Shadows, No Blur, No Materials.
// Depth is achieved purely through Flat Layering, Hard Offset Shadows,
// Linocut Hatching, Hand-crafted Shapes, and Misregistration.

public struct RisoTheme {
    // 5 Flat Colors (Light Mode - Risograph Studio Print on Washi Paper)
    public static let paperLight = Color(red: 0.961, green: 0.949, blue: 0.922)      // #F5F2EB Washi paper
    public static let paperCardLight = Color(red: 0.984, green: 0.976, blue: 0.957)  // #FAF9F4 Open Notebook
    public static let inkLight = Color(red: 0.102, green: 0.133, blue: 0.188)        // #1A2230 Kuroshio navy-black ink
    public static let accentLight = Color(red: 0.851, green: 0.263, blue: 0.196)     // #D94332 Risograph Scarlet Vermilion
    public static let subLight = Color(red: 0.886, green: 0.639, blue: 0.212)        // #E2A336 Warm Ochre Mustard
    public static let mutedLight = Color(red: 0.490, green: 0.475, blue: 0.435)      // #7D796F Raw Straw Gray
    public static let hardShadowLight = Color(red: 0.102, green: 0.133, blue: 0.188) // Solid flat silhouette
    public static let gridLineLight = Color(red: 0.102, green: 0.133, blue: 0.188).opacity(0.12)

    // 5 Flat Colors (Dark Mode - Midnight Desk with Warm Study Lamp)
    public static let paperDark = Color(red: 0.078, green: 0.098, blue: 0.137)       // #141923 Midnight Desk Wood
    public static let paperCardDark = Color(red: 0.102, green: 0.133, blue: 0.188)   // #1A2230 Deep Indigo Notebook
    public static let inkDark = Color(red: 0.925, green: 0.906, blue: 0.863)         // #ECE7DC Chalk Ivory Print Ink
    public static let accentDark = Color(red: 1.000, green: 0.369, blue: 0.302)      // #FF5E4D Luminous Scarlet Ink
    public static let subDark = Color(red: 0.965, green: 0.729, blue: 0.290)         // #F6BA4A Sunlit Ochre
    public static let mutedDark = Color(red: 0.525, green: 0.573, blue: 0.643)       // #8692A4 Slate Gray
    public static let hardShadowDark = Color(red: 0.035, green: 0.047, blue: 0.067)  // #090C11 Midnight Shadow
    public static let gridLineDark = Color(red: 0.925, green: 0.906, blue: 0.863).opacity(0.12)

    public static func paper(for scheme: ColorScheme) -> Color {
        scheme == .dark ? paperDark : paperLight
    }
    public static func paperCard(for scheme: ColorScheme) -> Color {
        scheme == .dark ? paperCardDark : paperCardLight
    }
    public static func ink(for scheme: ColorScheme) -> Color {
        scheme == .dark ? inkDark : inkLight
    }
    public static func accent(for scheme: ColorScheme) -> Color {
        scheme == .dark ? accentDark : accentLight
    }
    public static func sub(for scheme: ColorScheme) -> Color {
        scheme == .dark ? subDark : subLight
    }
    public static func muted(for scheme: ColorScheme) -> Color {
        scheme == .dark ? mutedDark : mutedLight
    }
    public static func hardShadow(for scheme: ColorScheme) -> Color {
        scheme == .dark ? hardShadowDark : hardShadowLight
    }
    public static func gridLine(for scheme: ColorScheme) -> Color {
        scheme == .dark ? gridLineDark : gridLineLight
    }
}

// MARK: - VECTOR ARTWORK COMPONENTS (Pure SwiftUI Shapes & Canvas)

/// Subtle vector paper grain using crisp 1pt micro-flecks (no raster noise, no blur).
public struct RisoPaperGrainView: View {
    let color: Color

    public init(color: Color) {
        self.color = color
    }

    public var body: some View {
        Canvas { context, size in
            // Deterministic pseudo-random vector flecks (fibers of washi paper)
            let step: CGFloat = 24.0
            var x: CGFloat = 8.0
            while x < size.width {
                var y: CGFloat = 8.0
                while y < size.height {
                    let hash = Int((x * 37.0 + y * 17.0).truncatingRemainder(dividingBy: 100.0))
                    if hash % 3 == 0 {
                        let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                        context.fill(Path(rect), with: .color(color))
                    } else if hash % 7 == 0 {
                        // Short 2.5pt fiber dash
                        var linePath = Path()
                        linePath.move(to: CGPoint(x: x, y: y))
                        linePath.addLine(to: CGPoint(x: x + 2.5, y: y + 0.8))
                        context.stroke(linePath, with: .color(color), lineWidth: 0.8)
                    }
                    y += step
                }
                x += step
            }
        }
        .allowsHitTesting(false)
    }
}

/// Linocut 45-degree diagonal hatching for desk texture and shadow planes.
public struct RisoWoodcutHatchingShape: Shape {
    var spacing: CGFloat = 8.0

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let total = rect.width + rect.height
        var offset: CGFloat = -rect.height
        while offset < total {
            let start = CGPoint(x: rect.minX + offset, y: rect.maxY)
            let end = CGPoint(x: rect.minX + offset + rect.height, y: rect.minY)
            path.move(to: start)
            path.addLine(to: end)
            offset += spacing
        }
        return path
    }
}

/// Official Risograph Assignment Seal Stamp (Con Dấu Báo Bài)
/// Featuring a double circular border, misregistration offset accent underlay,
/// curved arch typography, and a huge editorial serif count numeral.
public struct RisoSealStampView: View {
    let count: Int
    var size: CGFloat = 56
    @Environment(\.colorScheme) private var colorScheme

    public init(count: Int, size: CGFloat = 56) {
        self.count = count
        self.size = size
    }

    private var ink: Color { RisoTheme.ink(for: colorScheme) }
    private var accent: Color { RisoTheme.accent(for: colorScheme) }

    public var body: some View {
        ZStack {
            // Misregistration layer (Risograph print offset: shifted flat accent layer)
            Circle()
                .fill(accent.opacity(colorScheme == .dark ? 0.26 : 0.18))
                .frame(width: size, height: size)
                .offset(x: 2.0, y: 2.0)

            // Outer dashed circular ring
            Circle()
                .stroke(ink, style: StrokeStyle(lineWidth: 1.2, dash: [3.5, 2.5]))
                .frame(width: size, height: size)

            // Inner solid circular ring
            Circle()
                .stroke(ink, lineWidth: 1.2)
                .frame(width: size - 8, height: size - 8)

            // Stamp Typography Layout
            VStack(spacing: 0) {
                Text("BÁO BÀI")
                    .font(.system(size: size * 0.12, weight: .heavy, design: .serif))
                    .tracking(1.4)
                    .foregroundStyle(ink)
                    .padding(.top, 4)

                Spacer(minLength: 0)

                // Large Central Numeral
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: size * 0.44, weight: .heavy, design: .serif))
                        .foregroundStyle(accent)
                        .widgetAccentable()
                        .offset(y: -1)
                } else {
                    Text("✦")
                        .font(.system(size: size * 0.38, weight: .heavy, design: .serif))
                        .foregroundStyle(accent)
                        .widgetAccentable()
                        .offset(y: -1)
                }

                Spacer(minLength: 0)

                Text("MAI")
                    .font(.system(size: size * 0.12, weight: .heavy, design: .serif))
                    .tracking(1.4)
                    .foregroundStyle(ink)
                    .padding(.bottom, 4)
            }
            .frame(width: size - 10, height: size - 10)
        }
        .frame(width: size + 4, height: size + 4)
    }
}

/// Editorial Wooden Ruler (Thước kẻ gỗ học trò) with millimeter graduation marks and hard flat shadow.
public struct RisoWoodenRulerView: View {
    var height: CGFloat = 144
    @Environment(\.colorScheme) private var colorScheme

    public init(height: CGFloat = 144) {
        self.height = height
    }

    private var sub: Color { RisoTheme.sub(for: colorScheme) }
    private var ink: Color { RisoTheme.ink(for: colorScheme) }
    private var shadow: Color { RisoTheme.hardShadow(for: colorScheme) }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Hard offset shadow (flat solid offset, no blur)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(shadow)
                .frame(width: 22, height: height)
                .offset(x: 2.5, y: 2.5)

            // Ruler body
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(sub)
                .frame(width: 22, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(ink, lineWidth: 1.2)
                )

            // Beveled edge facet (lighter flat strip)
            Rectangle()
                .fill(sub.opacity(0.85))
                .frame(width: 7, height: height - 6)
                .padding(.leading, 1.2)
                .padding(.vertical, 3)

            // Millimeter graduation tick marks & numbers
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<9) { index in
                    HStack(spacing: 3) {
                        Rectangle()
                            .fill(ink)
                            .frame(width: (index % 2 == 0) ? 6 : 3.5, height: 1)

                        if index % 2 == 0 {
                            Text("\(index / 2)")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(ink)
                        }
                    }
                    .frame(height: (height - 24) / 8, alignment: .leading)
                }
            }
            .padding(.leading, 1.5)
            .padding(.top, 10)
        }
        .frame(width: 26, height: height + 4)
    }
}

/// Hand-sharpened 6-facet Pencil (Cây bút chì gọt thủ công) with hard flat shadow.
public struct RisoSharpenedPencilView: View {
    var length: CGFloat = 92
    @Environment(\.colorScheme) private var colorScheme

    public init(length: CGFloat = 92) {
        self.length = length
    }

    private var sub: Color { RisoTheme.sub(for: colorScheme) }
    private var ink: Color { RisoTheme.ink(for: colorScheme) }
    private var accent: Color { RisoTheme.accent(for: colorScheme) }
    private var paperCard: Color { RisoTheme.paperCard(for: colorScheme) }
    private var shadow: Color { RisoTheme.hardShadow(for: colorScheme) }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Hard offset shadow
            pencilGeometry(isShadow: true)
                .offset(x: 2.0, y: 2.0)

            // Pencil body & components
            pencilGeometry(isShadow: false)
        }
        .frame(width: 14, height: length + 4)
    }

    @ViewBuilder
    private func pencilGeometry(isShadow: Bool) -> some View {
        VStack(spacing: 0) {
            if isShadow {
                Rectangle()
                    .fill(shadow)
                    .frame(width: 10, height: length)
            } else {
                // Eraser top (flat red/scarlet)
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 10, height: 9)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(ink, lineWidth: 1))

                // Metal ferrule ring
                Rectangle()
                    .fill(ink.opacity(0.35))
                    .frame(width: 10, height: 5)
                    .overlay(Rectangle().stroke(ink, lineWidth: 1))

                // Hexagonal shaft (two facets for crisp flat depth)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(sub)
                        .frame(width: 5, height: length - 28)
                    Rectangle()
                        .fill(sub.opacity(0.80))
                        .frame(width: 5, height: length - 28)
                }
                .overlay(Rectangle().stroke(ink, lineWidth: 1))

                // Whittled wooden cone
                RisoWoodConeShape()
                    .fill(paperCard)
                    .frame(width: 10, height: 10)
                    .overlay(RisoWoodConeShape().stroke(ink, lineWidth: 1))

                // Graphite tip
                RisoGraphiteTipShape()
                    .fill(ink)
                    .frame(width: 6, height: 5)
            }
        }
    }
}

public struct RisoWoodConeShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - 2, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

public struct RisoGraphiteTipShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Punched binder holes on the notebook page with connecting stitched line.
public struct RisoBinderHolesView: View {
    var height: CGFloat = 130
    @Environment(\.colorScheme) private var colorScheme

    public init(height: CGFloat = 130) {
        self.height = height
    }

    private var paper: Color { RisoTheme.paper(for: colorScheme) }
    private var ink: Color { RisoTheme.ink(for: colorScheme) }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<4) { index in
                ZStack {
                    // Reveals the desk surface underneath
                    Circle()
                        .fill(paper)
                        .frame(width: 7, height: 7)

                    Circle()
                        .stroke(ink, lineWidth: 1)
                        .frame(width: 7, height: 7)
                }

                if index < 3 {
                    Spacer()
                }
            }
        }
        .frame(width: 9, height: height)
    }
}

/// Vintage School Notebook Label (Nhãn Vở Học Sinh)
public struct RisoVintageLabelHeader: View {
    let classTitle: String
    let dateString: String
    @Environment(\.colorScheme) private var colorScheme

    public init(classTitle: String = "11 TIN • TUẦN 5", dateString: String = "MAI") {
        self.classTitle = classTitle
        self.dateString = dateString
    }

    private var ink: Color { RisoTheme.ink(for: colorScheme) }
    private var sub: Color { RisoTheme.sub(for: colorScheme) }
    private var muted: Color { RisoTheme.muted(for: colorScheme) }

    public var body: some View {
        HStack(alignment: .center, spacing: 6) {
            // Label box with linocut double frame
            HStack(spacing: 4) {
                Rectangle()
                    .fill(sub)
                    .frame(width: 3.5, height: 11)

                Text(classTitle)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(ink)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(ink, lineWidth: 1)
            )

            Spacer(minLength: 4)

            // Date / Status Stamp
            HStack(spacing: 3) {
                Image(systemName: "calendar")
                    .font(.system(size: 8.5, weight: .bold))
                Text(dateString.uppercased())
                    .font(.system(size: 9.5, weight: .bold, design: .serif))
                    .tracking(0.4)
            }
            .foregroundStyle(muted)
        }
    }
}

/// Hand-carved linocut checkmark for completed tasks.
public struct RisoHandDrawnCheckmark: View {
    var size: CGFloat = 12
    var color: Color = Color(red: 0.851, green: 0.263, blue: 0.196)

    public init(size: CGFloat = 12, color: Color = Color(red: 0.851, green: 0.263, blue: 0.196)) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 2, y: size * 0.55))
            path.addLine(to: CGPoint(x: size * 0.42, y: size * 0.88))
            path.addLine(to: CGPoint(x: size * 0.95, y: 2))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// Hand-drawn double strike-through line for crossing out completed tasks.
public struct RisoStrikeThroughLine: View {
    var color: Color

    public init(color: Color) {
        self.color = color
    }

    public var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(color)
                .frame(height: 1.2)
            Rectangle()
                .fill(color.opacity(0.65))
                .frame(height: 0.8)
        }
    }
}

/// Linocut Subject Badge (e.g. [SỬ], [LÝ], [HÓA], [VĂN], [TOÁN])
public struct RisoSubjectTag: View {
    let name: String
    @Environment(\.colorScheme) private var colorScheme

    public init(name: String) {
        self.name = name
    }

    private var code: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 4 { return trimmed.uppercased() }
        let words = trimmed.components(separatedBy: .whitespaces)
        if words.count >= 2 {
            return words.prefix(2).map { String($0.prefix(1)).uppercased() }.joined()
        }
        return String(trimmed.prefix(3)).uppercased()
    }

    private var ink: Color { RisoTheme.ink(for: colorScheme) }
    private var sub: Color { RisoTheme.sub(for: colorScheme) }

    public var body: some View {
        Text(code)
            .font(.system(size: 10, weight: .heavy, design: .serif))
            .tracking(0.5)
            .foregroundStyle(ink)
            .padding(.horizontal, 4.5)
            .padding(.vertical, 1.5)
            .background(sub.opacity(colorScheme == .dark ? 0.30 : 0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(ink, lineWidth: 1)
            )
    }
}

/// Empty State Desk Illustration: Closed Journal, ceramic tea mug, and tranquil editorial text.
public struct RisoEmptyStateDeskView: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    private var ink: Color { RisoTheme.ink(for: colorScheme) }
    private var accent: Color { RisoTheme.accent(for: colorScheme) }
    private var sub: Color { RisoTheme.sub(for: colorScheme) }
    private var paperCard: Color { RisoTheme.paperCard(for: colorScheme) }
    private var muted: Color { RisoTheme.muted(for: colorScheme) }
    private var shadow: Color { RisoTheme.hardShadow(for: colorScheme) }

    public var body: some View {
        HStack(spacing: 16) {
            // Closed Journal & Tea Mug Illustration
            ZStack(alignment: .bottomLeading) {
                // Hard offset shadow for closed book
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(shadow)
                    .frame(width: 58, height: 76)
                    .offset(x: 2.5, y: 2.5)

                // Closed Journal cover
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(sub)
                    .frame(width: 58, height: 76)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(ink, lineWidth: 1.2)
                    )

                // Book spine band
                Rectangle()
                    .fill(ink.opacity(0.25))
                    .frame(width: 10, height: 76)
                    .overlay(Rectangle().stroke(ink, lineWidth: 1))

                // Scarlet bookmark ribbon hanging out
                Rectangle()
                    .fill(accent)
                    .frame(width: 6, height: 16)
                    .offset(x: 28, y: 8)

                // Ceramic Tea Mug
                ZStack {
                    Circle()
                        .fill(shadow)
                        .frame(width: 28, height: 28)
                        .offset(x: 1.5, y: 1.5)

                    Circle()
                        .fill(paperCard)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(ink, lineWidth: 1.2))

                    Circle()
                        .fill(accent.opacity(0.35))
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(ink, lineWidth: 0.8))

                    // Mug handle
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(ink, lineWidth: 1.2)
                        .frame(width: 6, height: 10)
                        .offset(x: 15)
                }
                .offset(x: 52, y: 12)
            }
            .frame(width: 86, height: 86)

            // Editorial Tranquil Message
            VStack(alignment: .leading, spacing: 3) {
                Text("Ngày mai rảnh rồi")
                    .font(.system(size: 15, weight: .heavy, design: .serif))
                    .foregroundStyle(ink)
                    .lineLimit(1)

                Text("Tất cả bài tập đã hoàn thành.\nHãy nghỉ ngơi và tận hưởng buổi tối ✦")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .lineSpacing(2.5)
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - COMPREHENSIVE MOCK DATA SUITE
public struct RisoMockData {
    public static var tomorrowEvening: Date {
        let calendar = Calendar.current
        var comp = calendar.dateComponents([.year, .month, .day], from: Date())
        comp.day = (comp.day ?? 0) + 1
        comp.hour = 23
        comp.minute = 59
        return calendar.date(from: comp) ?? Date()
    }

    public static var tomorrowAfternoon: Date {
        let calendar = Calendar.current
        var comp = calendar.dateComponents([.year, .month, .day], from: Date())
        comp.day = (comp.day ?? 0) + 1
        comp.hour = 17
        comp.minute = 30
        return calendar.date(from: comp) ?? Date()
    }

    public static var todayEvening: Date {
        let calendar = Calendar.current
        var comp = calendar.dateComponents([.year, .month, .day], from: Date())
        comp.hour = 23
        comp.minute = 55
        return calendar.date(from: comp) ?? Date()
    }

    public static let historyTask = Coursework(
        id: "task-su",
        courseId: "11-tin",
        courseName: "Sử",
        title: "Cách mạng tháng Tám và sự ra đời của nước VNDCCH",
        description: "Lập bảng niên biểu các mốc sự kiện chính trong tuần 5",
        dueDate: tomorrowEvening
    )

    public static let physicsTask = Coursework(
        id: "task-ly",
        courseId: "11-tin",
        courseName: "Lý",
        title: "Hiện tượng cảm ứng điện từ và định luật Faraday (Bài 1-5 SBT)",
        description: "Làm vào vở bài tập, chuẩn bị bài thí nghiệm thực hành",
        dueDate: tomorrowAfternoon
    )

    public static let chemistryTask = Coursework(
        id: "task-hoa",
        courseId: "11-tin",
        courseName: "Hóa",
        title: "Hoàn thành sơ đồ nhận biết hợp chất hữu cơ có nhóm chức",
        description: nil,
        dueDate: tomorrowEvening
    )

    public static let literatureTask = Coursework(
        id: "task-van",
        courseId: "11-tin",
        courseName: "Ngữ văn",
        title: "Viết đoạn văn 200 chữ phân tích nghệ thuật trào phúng Vũ Trọng Phụng",
        description: nil,
        dueDate: tomorrowEvening
    )

    public static let mathTask = Coursework(
        id: "task-toan",
        courseId: "11-tin",
        courseName: "Toán",
        title: "Giải tích: Đạo hàm cấp hai và khảo sát sự biến thiên của hàm số",
        dueDate: tomorrowEvening
    )

    public static let longTitleTask = Coursework(
        id: "task-long",
        courseId: "11-tin",
        courseName: "Tin học",
        title: "Lập trình thuật toán sắp xếp nhanh (QuickSort) và tìm kiếm nhị phân nâng cao trên mảng số nguyên",
        dueDate: tomorrowEvening
    )

    public static let fourTasks: [Coursework] = [
        historyTask,
        physicsTask,
        chemistryTask,
        literatureTask
    ]

    public static let manyTasks: [Coursework] = [
        physicsTask,
        historyTask,
        chemistryTask,
        literatureTask,
        mathTask
    ]

    public static let partiallyCompletedTasks: [Coursework] = [
        Coursework(
            id: "task-done-1",
            courseId: "11-tin",
            courseName: "Sử",
            title: "Cách mạng tháng Tám và sự ra đời của nước VNDCCH",
            dueDate: tomorrowEvening,
            status: .turnedIn
        ),
        Coursework(
            id: "task-done-2",
            courseId: "11-tin",
            courseName: "Hóa",
            title: "Hoàn thành sơ đồ nhận biết hợp chất hữu cơ có nhóm chức",
            dueDate: tomorrowEvening,
            status: .turnedIn
        ),
        physicsTask,
        literatureTask
    ]
}

public typealias ChunkyMockData = RisoMockData

// MARK: - Widget Typography System (Google Fonts & System Fallback)
import CoreText

public enum WidgetFontSystem {
    private static var isRegistered = false

    public static func registerCustomFonts() {
        guard !isRegistered else { return }
        isRegistered = true

        let fontFiles = [
            "BeVietnamPro-Bold.ttf",
            "BeVietnamPro-SemiBold.ttf",
            "BeVietnamPro-ExtraBold.ttf",
            "BeVietnamPro-Medium.ttf",
            "PlusJakartaSans.ttf"
        ]

        let searchDirs: [URL] = [
            Bundle.main.bundleURL,
            Bundle.main.resourceURL ?? Bundle.main.bundleURL,
            URL(fileURLWithPath: "Shared/Fonts"),
            URL(fileURLWithPath: "/Users/tahoangphuc/classroom/Shared/Fonts")
        ]

        for dir in searchDirs {
            for fileName in fontFiles {
                let fileURL = dir.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    var error: Unmanaged<CFError>?
                    CTFontManagerRegisterFontsForURL(fileURL as CFURL, .process, &error)
                }
            }
        }
    }

    public static func counter(size: CGFloat) -> Font {
        registerCustomFonts()
        #if canImport(AppKit)
        if NSFont(name: "BeVietnamPro-ExtraBold", size: size) != nil {
            return .custom("BeVietnamPro-ExtraBold", size: size)
        }
        #elseif canImport(UIKit)
        if UIFont(name: "BeVietnamPro-ExtraBold", size: size) != nil {
            return .custom("BeVietnamPro-ExtraBold", size: size)
        }
        #endif
        return .system(size: size, weight: .heavy, design: .rounded)
    }

    public static func sectionHeader(size: CGFloat) -> Font {
        registerCustomFonts()
        #if canImport(AppKit)
        if NSFont(name: "BeVietnamPro-ExtraBold", size: size) != nil {
            return .custom("BeVietnamPro-ExtraBold", size: size)
        }
        #elseif canImport(UIKit)
        if UIFont(name: "BeVietnamPro-ExtraBold", size: size) != nil {
            return .custom("BeVietnamPro-ExtraBold", size: size)
        }
        #endif
        return .system(size: size, weight: .heavy, design: .rounded)
    }

    public static func courseTitle(size: CGFloat) -> Font {
        registerCustomFonts()
        #if canImport(AppKit)
        if NSFont(name: "BeVietnamPro-Bold", size: size) != nil {
            return .custom("BeVietnamPro-Bold", size: size)
        }
        #elseif canImport(UIKit)
        if UIFont(name: "BeVietnamPro-Bold", size: size) != nil {
            return .custom("BeVietnamPro-Bold", size: size)
        }
        #endif
        return .system(size: size, weight: .bold, design: .rounded)
    }

    public static func statusTag(size: CGFloat) -> Font {
        registerCustomFonts()
        #if canImport(AppKit)
        if NSFont(name: "BeVietnamPro-Bold", size: size) != nil {
            return .custom("BeVietnamPro-Bold", size: size)
        }
        #elseif canImport(UIKit)
        if UIFont(name: "BeVietnamPro-Bold", size: size) != nil {
            return .custom("BeVietnamPro-Bold", size: size)
        }
        #endif
        return .system(size: size, weight: .bold, design: .rounded)
    }

    public static func meta(size: CGFloat) -> Font {
        registerCustomFonts()
        #if canImport(AppKit)
        if NSFont(name: "BeVietnamPro-SemiBold", size: size) != nil {
            return .custom("BeVietnamPro-SemiBold", size: size)
        }
        #elseif canImport(UIKit)
        if UIFont(name: "BeVietnamPro-SemiBold", size: size) != nil {
            return .custom("BeVietnamPro-SemiBold", size: size)
        }
        #endif
        return .system(size: size, weight: .medium, design: .rounded)
    }
}

