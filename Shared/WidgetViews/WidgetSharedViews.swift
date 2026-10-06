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
        } else if combined.contains("tin") || combined.contains("lập trình") || combined.contains("di động") || combined.contains("ios") || combined.contains("swift") || combined.contains("code") || combined.contains("dev") || combined.contains("web") || combined.contains("python") || combined.contains("java") || combined.contains("cntt") || combined.contains("công nghệ thông tin") {
            return .computerScience
        } else if combined.contains("mạng") || combined.contains("network") || combined.contains("security") || combined.contains("an toàn") || combined.contains("tcp") || combined.contains("socket") || combined.contains("cloud") {
            return .networking
        } else if combined.contains("văn") || combined.contains("ngữ văn") || combined.contains("tiếng việt") || combined.contains("writing") || combined.contains("literature") || combined.contains("essay") {
            return .literature
        } else if combined.contains("anh") || combined.contains("english") || combined.contains("ielts") || combined.contains("toeic") || combined.contains("ngôn ngữ") {
            return .english
        } else if combined.contains("lý") || combined.contains("vật lý") || combined.contains("physics") {
            return .physics
        } else if combined.contains("hóa") || combined.contains("chemistry") {
            return .chemistry
        } else if combined.contains("sinh") || combined.contains("biology") || combined.contains("y học") {
            return .biology
        } else if combined.contains("sử") || combined.contains("lịch sử") || combined.contains("history") || combined.contains("địa") || combined.contains("địa lý") || combined.contains("geography") {
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
        case .math: return Color(red: 1.00, green: 0.68, blue: 0.14)
        case .literature: return Color(red: 1.00, green: 0.46, blue: 0.18)
        case .english: return Color(red: 0.18, green: 0.75, blue: 1.00)
        case .physics: return Color(red: 0.02, green: 0.82, blue: 0.88)
        case .chemistry: return Color(red: 0.94, green: 0.30, blue: 0.82)
        case .biology: return Color(red: 0.38, green: 0.84, blue: 0.22)
        case .historyOrGeography: return Color(red: 0.95, green: 0.58, blue: 0.12)
        case .computerScience: return Color(red: 0.10, green: 0.82, blue: 0.52)
        case .networking: return Color(red: 0.65, green: 0.45, blue: 1.00)
        case .civicsOrPhilosophy: return Color(red: 0.95, green: 0.28, blue: 0.32)
        case .economics: return Color(red: 0.98, green: 0.72, blue: 0.12)
        case .artAndDesign: return Color(red: 0.98, green: 0.28, blue: 0.60)
        case .generalAssignment: return Color(red: 0.52, green: 0.46, blue: 1.00)
        case .other: return Color(red: 0.25, green: 0.65, blue: 1.00)
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
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(colorScheme == .dark ? 0.32 : 0.22),
                            color.opacity(colorScheme == .dark ? 0.18 : 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                        .stroke(color.opacity(colorScheme == .dark ? 0.48 : 0.32), lineWidth: 1)
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
                .fill(
                    LinearGradient(
                        colors: [
                            SubjectArtHelper.bannerBackground(for: item.courseName),
                            SubjectArtHelper.bannerBackground(for: item.courseName).opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 105)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(isHovered ? 0.24 : 0.12), lineWidth: 1)
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
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.14, blue: 0.20),
                        Color(red: 0.08, green: 0.09, blue: 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.12),
                        Color.purple.opacity(0.06),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.995, blue: 1.0),
                        Color(red: 0.95, green: 0.97, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.04),
                        Color.teal.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }
}

public struct WidgetAppleGlassBackground: View {
    var cornerRadius: CGFloat = 22

    public init(cornerRadius: CGFloat = 22) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.31, green: 0.18, blue: 0.96),
                        Color(red: 0.38, green: 0.17, blue: 0.92),
                        Color(red: 0.45, green: 0.14, blue: 0.88),
                        Color(red: 0.30, green: 0.08, blue: 0.64)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [
                        Color(red: 0.58, green: 0.77, blue: 0.99).opacity(0.12),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 5,
                    endRadius: max(w, h) * 0.7
                )

                LinearGradient(
                    stops: [
                        .init(color: Color.clear, location: 0.0),
                        .init(color: Color.clear, location: 0.70),
                        .init(color: Color.white.opacity(0.03), location: 0.88),
                        .init(color: Color.white.opacity(0.09), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.10),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1.0
                    )

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.clear, location: 0.0),
                                .init(color: Color.clear, location: 0.72),
                                .init(color: Color.white.opacity(0.08), location: 0.88),
                                .init(color: Color.white.opacity(0.24), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )

                Canvas { context, size in
                    let cr = cornerRadius
                    let strokeW: CGFloat = 1.3
                    let inset: CGFloat = 1.0

                    var bottomEdgePath = Path()
                    bottomEdgePath.move(to: CGPoint(x: inset, y: size.height - cr * 1.2))
                    bottomEdgePath.addCurve(
                        to: CGPoint(x: cr * 1.3, y: size.height - inset),
                        control1: CGPoint(x: inset, y: size.height - inset),
                        control2: CGPoint(x: cr * 0.4, y: size.height - inset)
                    )
                    bottomEdgePath.addLine(to: CGPoint(x: size.width - cr * 1.3, y: size.height - inset))
                    bottomEdgePath.addCurve(
                        to: CGPoint(x: size.width - inset, y: size.height - cr * 1.2),
                        control1: CGPoint(x: size.width - cr * 0.4, y: size.height - inset),
                        control2: CGPoint(x: size.width - inset, y: size.height - inset)
                    )

                    context.stroke(
                        bottomEdgePath,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.32),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: CGPoint(x: inset, y: size.height),
                            endPoint: CGPoint(x: size.width - inset, y: size.height)
                        ),
                        lineWidth: strokeW
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
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
            return Color(red: 1.0, green: 0.46, blue: 0.12)
        } else if item.isDueTomorrow {
            return Color(red: 0.10, green: 0.56, blue: 1.00)
        } else {
            return Color.secondary
        }
    }

    private var badgeText: String {
        if compact {
            if item.isDueToday {
                return item.timeOnlyString == "Cuối ngày" ? "Hôm nay" : "Hôm nay \(item.timeOnlyString)"
            } else if item.isDueTomorrow {
                return item.timeOnlyString == "Cuối ngày" ? "Ngày mai" : "Ngày mai \(item.timeOnlyString)"
            }
            return item.timeOnlyString
        } else {
            return item.friendlyDueString
        }
    }

    private var iconName: String {
        item.isDueToday ? "clock.fill" : "calendar"
    }

    public var body: some View {
        HStack(spacing: 3.5) {
            Image(systemName: iconName)
                .font(.system(size: compact ? 7.5 : 8.5, weight: .bold))
            Text(badgeText)
                .font(.system(size: compact ? 9.5 : 10.5, weight: .semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 2.5 : 3.5)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(badgeColor.opacity(colorScheme == .dark ? 0.22 : 0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(badgeColor.opacity(colorScheme == .dark ? 0.36 : 0.24), lineWidth: 0.8)
        )
        .foregroundStyle(badgeColor)
    }
}

public struct WidgetEmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.80, blue: 0.52).opacity(colorScheme == .dark ? 0.30 : 0.20),
                                Color(red: 0.08, green: 0.65, blue: 0.42).opacity(colorScheme == .dark ? 0.15 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color(red: 0.10, green: 0.75, blue: 0.50)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 2) {
                Text("Không có bài tập!")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Hôm nay & ngày mai đều đã xong")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
}
