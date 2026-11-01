import SwiftUI
import WidgetKit
import os

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
    public struct VisualTheme: Sendable {
        public let category: SubjectCategory
        public let icon: String
        public let themeColor: Color
        public let bannerBackground: Color
    }

    private static var cacheLock = os_unfair_lock_s()
    private static var courseCategoryCache: [String: SubjectCategory] = [:]
    private static var categoryCache: [String: SubjectCategory] = [:]
    private static var courseBadgeCache: [String: String] = [:]

    public static func category(for courseName: String, title: String? = nil) -> SubjectCategory {
        os_unfair_lock_lock(&cacheLock)
        let courseCat: SubjectCategory
        if let cached = courseCategoryCache[courseName] {
            courseCat = cached
            os_unfair_lock_unlock(&cacheLock)
        } else {
            os_unfair_lock_unlock(&cacheLock)
            let computed = computeCategory(for: courseName, title: nil)
            os_unfair_lock_lock(&cacheLock)
            if courseCategoryCache.count >= 2048 {
                courseCategoryCache.removeAll()
            }
            courseCategoryCache[courseName] = computed
            courseCat = computed
            os_unfair_lock_unlock(&cacheLock)
        }

        if courseCat != .other || title == nil || title!.isEmpty {
            return courseCat
        }

        let key = "\(courseName)|\(title ?? "")"
        os_unfair_lock_lock(&cacheLock)
        if let cached = categoryCache[key] {
            os_unfair_lock_unlock(&cacheLock)
            return cached
        }
        os_unfair_lock_unlock(&cacheLock)

        let computed = computeCategory(for: courseName, title: title)
        os_unfair_lock_lock(&cacheLock)
        if categoryCache.count >= 2048 {
            categoryCache.removeAll()
        }
        categoryCache[key] = computed
        os_unfair_lock_unlock(&cacheLock)

        return computed
    }

    public static func theme(for courseName: String, title: String? = nil) -> VisualTheme {
        let cat = category(for: courseName, title: title)
        return VisualTheme(
            category: cat,
            icon: icon(for: cat),
            themeColor: themeColor(for: cat),
            bannerBackground: bannerBackground(for: cat)
        )
    }

    public static func badgeCode(for category: SubjectCategory, courseName: String, title: String? = nil) -> String {
        switch category {
        case .math: return "TOÁ"
        case .physics: return "LÝ"
        case .chemistry: return "HOÁ"
        case .biology: return "SINH"
        case .literature: return "VĂN"
        case .english: return "ANH"
        case .civicsOrPhilosophy: return "GDCD"
        case .economics: return "KTẾ"
        case .artAndDesign: return "TKẾ"
        case .computerScience: return "TIN"
        case .networking: return "MẠNG"
        case .generalAssignment: return "BTH"
        case .historyOrGeography:
            os_unfair_lock_lock(&cacheLock)
            if let cached = courseBadgeCache[courseName] {
                os_unfair_lock_unlock(&cacheLock)
                return cached
            }
            os_unfair_lock_unlock(&cacheLock)

            let isDia = courseName.localizedCaseInsensitiveContains("địa") || (title?.localizedCaseInsensitiveContains("địa") == true) || courseName.localizedCaseInsensitiveContains("dia") || (title?.localizedCaseInsensitiveContains("dia") == true)
            let code = isDia ? "ĐỊA" : "SỬ"

            os_unfair_lock_lock(&cacheLock)
            if courseBadgeCache.count >= 2048 {
                courseBadgeCache.removeAll()
            }
            courseBadgeCache[courseName] = code
            os_unfair_lock_unlock(&cacheLock)
            return code
        case .other:
            let cleaned = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count >= 3 {
                return String(cleaned.prefix(3)).uppercased()
            }
            if let title, !title.isEmpty {
                let titleCleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
                if titleCleaned.count >= 3 {
                    return String(titleCleaned.prefix(3)).uppercased()
                }
            }
            return cleaned.isEmpty ? "MÔN" : cleaned.uppercased()
        }
    }

    public static func badgeCode(for courseName: String, title: String? = nil) -> String {
        let cat = category(for: courseName, title: title)
        return badgeCode(for: cat, courseName: courseName, title: title)
    }

    private struct TokenFlags: OptionSet {
        let rawValue: UInt64

        static let math = TokenFlags(rawValue: 1 << 0)
        static let physics = TokenFlags(rawValue: 1 << 1)
        static let chemistry = TokenFlags(rawValue: 1 << 2)
        static let biology = TokenFlags(rawValue: 1 << 3)
        static let history = TokenFlags(rawValue: 1 << 4)
        static let geography = TokenFlags(rawValue: 1 << 5)
        static let literature = TokenFlags(rawValue: 1 << 6)
        static let english = TokenFlags(rawValue: 1 << 7)
        static let civics = TokenFlags(rawValue: 1 << 8)
        static let networking = TokenFlags(rawValue: 1 << 9)
        static let economics = TokenFlags(rawValue: 1 << 10)
        static let art = TokenFlags(rawValue: 1 << 11)
        static let cs = TokenFlags(rawValue: 1 << 12)
        static let assignment = TokenFlags(rawValue: 1 << 13)

        static let ly = TokenFlags(rawValue: 1 << 14)
        static let hoa = TokenFlags(rawValue: 1 << 15)
        static let sinh = TokenFlags(rawValue: 1 << 16)
        static let su = TokenFlags(rawValue: 1 << 17)
        static let dia = TokenFlags(rawValue: 1 << 18)
        static let van = TokenFlags(rawValue: 1 << 19)
        static let anh = TokenFlags(rawValue: 1 << 20)
        static let triet = TokenFlags(rawValue: 1 << 21)
        static let mang = TokenFlags(rawValue: 1 << 22)
        static let cloud = TokenFlags(rawValue: 1 << 23)
        static let soundcloud = TokenFlags(rawValue: 1 << 24)
        static let artOnly = TokenFlags(rawValue: 1 << 25)
        static let artExcludedWord = TokenFlags(rawValue: 1 << 26)
        static let ve = TokenFlags(rawValue: 1 << 27)
        static let tin = TokenFlags(rawValue: 1 << 28)
        static let tu = TokenFlags(rawValue: 1 << 29)
    }

    private static let tokenMap: [Substring: TokenFlags] = [
        "toan": .math, "math": .math, "maths": .math, "calculus": .math, "algebra": .math,
        "geometry": .math, "trigonometry": .math, "statistics": .math, "discrete": .math,
        "physics": .physics, "mechanics": .physics, "thermodynamics": .physics, "optics": .physics,
        "ly": .ly, "lý": .ly, "lí": .ly,
        "chemistry": .chemistry, "chem": .chemistry, "biochemistry": .chemistry,
        "hoa": .hoa, "hóa": .hoa, "hoá": .hoa,
        "biology": .biology, "bio": .biology, "genetics": .biology, "ecology": .biology,
        "sinh": .sinh,
        "history": .history, "su": .su, "sử": .su,
        "geography": .geography, "dia": .dia, "địa": .dia,
        "literature": .literature, "writing": .literature, "essay": .literature,
        "van": .van, "văn": .van,
        "english": .english, "ielts": .english, "toeic": .english, "toefl": .english,
        "anh": .anh,
        "gdcd": .civics, "law": .civics, "triet": .triet, "triết": .triet,
        "cybersecurity": .networking, "network": .networking, "networking": .networking,
        "tcp": .networking, "socket": .networking, "cloud": .cloud, "soundcloud": .soundcloud,
        "mang": .mang, "mạng": .mang,
        "business": .economics, "economics": .economics,
        "design": .art, "ui": .art, "ux": .art,
        "art": .artOnly, "part": .artExcludedWord, "smart": .artExcludedWord, "start": .artExcludedWord,
        "ve": .ve, "vẽ": .ve,
        "android": .cs, "ios": .cs, "swift": .cs, "python": .cs, "java": .cs,
        "cntt": .cs, "it": .cs, "ctdl": .cs, "cpp": .cs, "kotlin": .cs,
        "javascript": .cs, "typescript": .cs, "tin": .tin, "tu": .tu, "tự": .tu,
        "lab": .assignment, "project": .assignment
    ]

    private static func scanTokenFlags(in text: String) -> TokenFlags {
        var flags: TokenFlags = []
        var start: String.Index? = nil
        for i in text.indices {
            let ch = text[i]
            if ch.isLetter || ch.isNumber {
                if start == nil { start = i }
            } else if let s = start {
                if let flag = tokenMap[text[s..<i]] {
                    flags.insert(flag)
                }
                start = nil
            }
        }
        if let s = start {
            if let flag = tokenMap[text[s...]] {
                flags.insert(flag)
            }
        }
        return flags
    }

    private static func computeCategory(for courseName: String, title: String? = nil) -> SubjectCategory {
        func matchCategory(text: String, flags: TokenFlags) -> SubjectCategory? {
            if !text.contains("điện toán") && (text.contains("toán") || flags.contains(.math) || text.contains("giải tích") || text.contains("đại số") || text.contains("hình học") || text.contains("xác suất") || text.contains("lượng giác") || text.contains("đạo hàm") || text.contains("tích phân") || text.contains("toán cao cấp") || text.contains("toán rời rạc") || text.contains("thống kê") || text.contains("vi phân") || text.contains("ma trận")) {
                return .math
            } else if text.contains("vật lý") || text.contains("vật lí") || flags.contains(.physics) || text.contains("môn lý") || text.contains("môn lí") || text.contains("sbt lý") || text.contains("sbt lí") || text.contains("cơ học") || text.contains("nhiệt học") || text.contains("quang học") || text.contains("điện từ") || text.contains("vật lý đại cương") || text.contains("vật lí đại cương") || text.contains("dao động") || text.contains("sóng cơ") || (flags.contains(.ly) && !text.contains("quản lý") && !text.contains("quản lí") && !text.contains("xử lý") && !text.contains("xử lí") && !text.contains("tâm lý") && !text.contains("tâm lí") && !text.contains("pháp lý") && !text.contains("pháp lí") && !text.contains("địa lý") && !text.contains("địa lí") && !text.contains("triết lý") && !text.contains("triết lí") && !text.contains("lý thuyết") && !text.contains("lí thuyết") && !text.contains("lý luận") && !text.contains("lí luận") && !text.contains("lý do") && !text.contains("lí do")) {
                return .physics
            } else if text.contains("hóa học") || text.contains("hoá học") || text.contains("môn hóa") || text.contains("môn hoá") || text.contains("hóa hữu cơ") || text.contains("hoá hữu cơ") || text.contains("hóa vô cơ") || text.contains("hoá vô cơ") || text.contains("hóa đại cương") || text.contains("hoá đại cương") || text.contains("hóa phân tích") || text.contains("hoá phân tích") || flags.contains(.chemistry) || (flags.contains(.hoa) && !text.contains("tự động hóa") && !text.contains("tự động hoá") && !text.contains("tiến hóa") && !text.contains("tiến hoá") && !text.contains("tiêu hóa") && !text.contains("tiêu hoá") && !text.contains("hóa đơn") && !text.contains("hoá đơn") && !text.contains("văn hóa") && !text.contains("văn hoá") && !text.contains("tối ưu hóa") && !text.contains("tối ưu hoá") && !text.contains("chuẩn hóa") && !text.contains("chuẩn hoá") && !text.contains("công nghiệp hóa") && !text.contains("công nghiệp hoá") && !text.contains("hiện đại hóa") && !text.contains("hiện đại hoá") && !text.contains("ảo hóa") && !text.contains("ảo hoá") && !text.contains("số hóa") && !text.contains("số hoá")) {
                return .chemistry
            } else if text.contains("sinh học") || text.contains("môn sinh") || flags.contains(.biology) || text.contains("y học") || text.contains("di truyền") || text.contains("tế bào") || text.contains("vi sinh") || text.contains("sinh thái") || text.contains("tiêu hóa") || text.contains("tiêu hoá") || (flags.contains(.sinh) && !text.contains("học sinh") && !text.contains("sinh viên") && !text.contains("sinh hoạt")) {
                return .biology
            } else if text.contains("lịch sử") || flags.contains(.history) || (flags.contains(.su) && !text.contains("sử dụng") && !text.contains("lịch sự")) {
                return .historyOrGeography
            } else if text.contains("địa lý") || text.contains("địa lí") || flags.contains(.geography) || (flags.contains(.dia) && !text.contains("địa chỉ") && !text.contains("địa điểm")) {
                return .historyOrGeography
            } else if text.contains("ngữ văn") || text.contains("tiếng việt") || flags.contains(.literature) || (flags.contains(.van) && !text.contains("văn phòng") && !text.contains("văn hóa") && !text.contains("văn hoá") && !text.contains("văn minh") && !text.contains("văn bản") && !text.contains("luận văn")) {
                return .literature
            } else if text.contains("tiếng anh") || flags.contains(.english) || (flags.contains(.anh) && !text.contains("hình ảnh") && !text.contains("âm thanh") && !text.contains("thầy") && !text.contains("cô") && !text.contains("gv")) {
                return .english
            } else if flags.contains(.civics) || text.contains("triết học") || text.contains("chính trị") || text.contains("pháp luật") || text.contains("kinh tế và pháp luật") || text.contains("tư tưởng") || text.contains("mác - lênin") || text.contains("mác lênin") || text.contains("tư tưởng hồ chí minh") || text.contains("pháp luật đại cương") || (flags.contains(.triet) && !text.contains("triết lý")) {
                return .civicsOrPhilosophy
            } else if text.contains("an ninh mạng") || text.contains("mạng máy tính") || text.contains("an toàn thông tin") || text.contains("hệ thống phân tán") || text.contains("quản trị mạng") || flags.contains(.networking) || (flags.contains(.mang) && !text.contains("mạng xã hội")) || (flags.contains(.cloud) && !flags.contains(.soundcloud)) {
                return .networking
            } else if !text.contains("quản trị mạng") && (text.contains("kinh tế") || text.contains("quản trị") || text.contains("tài chính") || text.contains("marketing") || text.contains("kế toán") || flags.contains(.economics)) {
                return .economics
            } else if text.contains("đồ họa") || text.contains("thiết kế") || text.contains("mỹ thuật") || flags.contains(.art) || (flags.contains(.artOnly) && !flags.contains(.artExcludedWord)) || (flags.contains(.ve) && !text.contains("bản vẽ kỹ thuật")) {
                return .artAndDesign
            } else if text.contains("lập trình") || text.contains("tin học") || text.contains("di động") || flags.contains(.cs) || text.contains("công nghệ thông tin") || text.contains("thuật toán") || text.contains("cơ sở dữ liệu") || text.contains("khoa học máy tính") || text.contains("cấu trúc dữ liệu") || text.contains("trí tuệ nhân tạo") || text.contains("machine learning") || text.contains("hệ điều hành") || text.contains("kiến trúc máy tính") || (flags.contains(.tin) && !text.contains("thông tin") && !text.contains("bản tin") && !text.contains("tin tức") && !text.contains("niềm tin") && !flags.contains(.tu)) {
                return .computerScience
            } else if text.contains("nhiệm vụ") || flags.contains(.assignment) || text.contains("thực hành") || text.contains("bài tập") || text.contains("dự án") {
                return .generalAssignment
            }
            return nil
        }

        let courseLower = courseName.lowercased()
        let courseFlags = scanTokenFlags(in: courseLower)
        if let matched = matchCategory(text: courseLower, flags: courseFlags) {
            return matched
        }

        if let title, !title.isEmpty {
            let titleLower = title.lowercased()
            let titleFlags = scanTokenFlags(in: titleLower)
            if let matched = matchCategory(text: titleLower, flags: titleFlags) {
                return matched
            }
        }
        return .other
    }

    public static func icon(for category: SubjectCategory) -> String {
        switch category {
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
        case .other: return "book.closed"
        }
    }

    public static func icon(for courseName: String, title: String? = nil) -> String {
        icon(for: category(for: courseName, title: title))
    }

    public static func themeColor(for category: SubjectCategory) -> Color {
        switch category {
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

    public static func themeColor(for courseName: String, title: String? = nil) -> Color {
        themeColor(for: category(for: courseName, title: title))
    }

    public static func bannerBackground(for category: SubjectCategory) -> Color {
        switch category {
        case .math: return Color(red: 0.88, green: 0.50, blue: 0.08)
        case .literature: return Color(red: 0.86, green: 0.34, blue: 0.20)
        case .english: return Color(red: 0.12, green: 0.48, blue: 0.88)
        case .physics: return Color(red: 0.40, green: 0.34, blue: 0.84)
        case .chemistry: return Color(red: 0.80, green: 0.24, blue: 0.60)
        case .biology: return Color(red: 0.14, green: 0.60, blue: 0.34)
        case .historyOrGeography: return Color(red: 0.80, green: 0.46, blue: 0.14)
        case .computerScience: return Color(red: 0.06, green: 0.58, blue: 0.50)
        case .networking: return Color(red: 0.48, green: 0.32, blue: 0.84)
        case .civicsOrPhilosophy: return Color(red: 0.82, green: 0.24, blue: 0.28)
        case .economics: return Color(red: 0.84, green: 0.56, blue: 0.10)
        case .artAndDesign: return Color(red: 0.84, green: 0.22, blue: 0.52)
        case .generalAssignment: return Color(red: 0.44, green: 0.36, blue: 0.78)
        case .other: return Color(red: 0.30, green: 0.44, blue: 0.60)
        }
    }

    public static func bannerBackground(for courseName: String, title: String? = nil) -> Color {
        bannerBackground(for: category(for: courseName, title: title))
    }
}

public struct CourseColorHelper {
    public static func color(for courseName: String, title: String? = nil) -> Color {
        SubjectArtHelper.themeColor(for: courseName, title: title)
    }
}

public struct SubjectArtBadgeView: View, Equatable {
    let courseName: String
    var title: String? = nil
    var size: CGFloat = 20
    @Environment(\.colorScheme) private var colorScheme

    public init(courseName: String, title: String? = nil, size: CGFloat = 20) {
        self.courseName = courseName
        self.title = title
        self.size = size
    }

    public static func == (lhs: SubjectArtBadgeView, rhs: SubjectArtBadgeView) -> Bool {
        lhs.courseName == rhs.courseName && lhs.title == rhs.title && lhs.size == rhs.size
    }

    public var body: some View {
        let visualTheme = SubjectArtHelper.theme(for: courseName, title: title)
        let cornerRadius = size * 0.28
        let isDark = colorScheme == .dark
        let bgOpacity: Double = isDark ? 0.28 : 0.16
        let strokeOpacity: Double = isDark ? 0.55 : 0.38

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(visualTheme.themeColor.opacity(bgOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(visualTheme.themeColor.opacity(strokeOpacity), lineWidth: 1)
                )
                .frame(width: size, height: size)

            Image(systemName: visualTheme.icon)
                .font(.system(size: size * 0.52, weight: .semibold))
                .foregroundStyle(visualTheme.themeColor)
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
        let visualTheme = SubjectArtHelper.theme(for: item.courseName, title: item.title)
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            visualTheme.bannerBackground,
                            visualTheme.bannerBackground.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                #if os(iOS)
                .frame(minHeight: 88)
                #else
                .frame(minHeight: 110)
                #endif
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(isHovered ? 0.35 : 0.18), lineWidth: 1)
                )
                .shadow(color: visualTheme.bannerBackground.opacity(0.18), radius: 8, x: 0, y: 3)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        SubjectArtBadgeView(courseName: item.courseName, size: 24)
                        Text(item.courseName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white.opacity(0.95))
                    }

                    Text(item.title)
                        .font(.system(size: 19.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11.5, weight: .semibold))
                        Text(item.formattedFullDueDate)
                            .font(.system(size: 13.5, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3.5)
                    .background(Color.black.opacity(0.18))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                #if os(iOS)
                let artWidth: CGFloat = 72
                let artHeight: CGFloat = 65
                #else
                let artWidth: CGFloat = 88
                let artHeight: CGFloat = 80
                #endif

                ZStack {
                    RealSubjectArtScene(courseName: item.courseName)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .opacity(0.85)

                    ChunkyEmberCharacterView(
                        emotion: item.isCompleted ? .celebrating : (item.isUrgent ? .stressed : .normal),
                        size: artHeight * 0.88
                    )
                    .scaleEffect(isHovered ? 1.08 : 1.0)
                    .offset(x: isHovered ? -2 : 0, y: isHovered ? -2 : 0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isHovered)
                }
                .frame(width: artWidth, height: artHeight)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        #if os(macOS)
        .onHover { hovering in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                isHovered = hovering
            }
        }
        #endif
    }
}

public struct WidgetCardBackground: View {
    var cornerRadius: CGFloat = 16

    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(ChunkyTheme.sheetBg)
            .shadow(color: Color(red: 0.08, green: 0.22, blue: 0.36).opacity(0.12), radius: 6, x: 0, y: 2.5)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(ChunkyTheme.editorialCardBorder, lineWidth: 1)
            )
    }
}

public struct WidgetAppleGlassBackground: View {
    var cornerRadius: CGFloat = 20

    public init(cornerRadius: CGFloat = 20) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
    }
}

public struct WidgetAtmosphereBackground: View {
    var cornerRadius: CGFloat = 20

    public init(cornerRadius: CGFloat = 20, hasUrgentTask: Bool = false) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        WidgetAppleGlassBackground(cornerRadius: cornerRadius)
    }
}

public struct CourseTagView: View {
    let name: String

    public init(name: String, showDot: Bool = false) {
        self.name = name
    }

    public var body: some View {
        let visualTheme = SubjectArtHelper.theme(for: name)
        HStack(spacing: 4) {
            Image(systemName: visualTheme.icon)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(visualTheme.themeColor)
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

public struct DueBadgeView: View, Equatable {
    let item: Coursework
    var compact: Bool = false

    public init(item: Coursework, compact: Bool = false) {
        self.item = item
        self.compact = compact
    }

    public static func == (lhs: DueBadgeView, rhs: DueBadgeView) -> Bool {
        lhs.item.id == rhs.item.id &&
        lhs.item.status == rhs.item.status &&
        lhs.item.dueDate == rhs.item.dueDate &&
        lhs.item.isCompleted == rhs.item.isCompleted &&
        lhs.item.isOverdue == rhs.item.isOverdue &&
        lhs.compact == rhs.compact
    }

    private var badgeColor: Color {
        if item.isCompleted {
            return Color(red: 0.12, green: 0.62, blue: 0.35)
        } else if item.isOverdue || item.isPast {
            return Color(red: 0.90, green: 0.22, blue: 0.21)
        } else if item.isDueToday {
            return Color(red: 0.90, green: 0.48, blue: 0.08)
        } else if item.isDueTomorrow {
            return Color(red: 0.14, green: 0.48, blue: 0.92)
        } else {
            return Color(red: 0.45, green: 0.50, blue: 0.58)
        }
    }

    private var badgeText: String {
        if compact {
            return item.compactDueString
        } else {
            return item.friendlyDueString
        }
    }

    public var body: some View {
        HStack(spacing: 4) {
            if item.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: compact ? 10.5 : 11.5, weight: .bold))
            } else if item.isOverdue || item.isPast {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: compact ? 10.5 : 11.5, weight: .semibold))
            } else {
                Image(systemName: "clock")
                    .font(.system(size: compact ? 10.5 : 11.5, weight: .semibold))
            }

            Text(badgeText)
                .font(.system(size: compact ? 12.5 : 13.5, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(badgeColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(badgeColor.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

public struct WidgetEmptyStateView: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            ChunkyEmberCharacterView(emotion: .sleeping, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ngày mai rảnh rồi!")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(ChunkyTheme.textPrimary)

                Text("Tất cả bài tập đã hoàn thành.\nNghỉ ngơi và thư giãn nhé.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundStyle(ChunkyTheme.textMuted)
            }
        }
    }
}

// MARK: - Mock Data
public struct RisoMockData {
    public static var tomorrowEvening: Date {
        let calendar = Calendar.autoupdatingCurrent
        var comp = calendar.dateComponents([.year, .month, .day], from: Date())
        comp.day = (comp.day ?? 0) + 1
        comp.hour = 23
        comp.minute = 59
        return calendar.date(from: comp) ?? Date()
    }

    public static var tomorrowAfternoon: Date {
        let calendar = Calendar.autoupdatingCurrent
        var comp = calendar.dateComponents([.year, .month, .day], from: Date())
        comp.day = (comp.day ?? 0) + 1
        comp.hour = 17
        comp.minute = 30
        return calendar.date(from: comp) ?? Date()
    }

    public static var todayEvening: Date {
        let calendar = Calendar.autoupdatingCurrent
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

// MARK: - Typography
public enum WidgetFontSystem {
    public static func counter(size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    public static func sectionHeader(size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    public static func courseTitle(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    public static func statusTag(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    public static func meta(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

public extension Coursework {
    var badgeCode: String {
        SubjectArtHelper.badgeCode(for: courseName, title: title)
    }
    var subjectCategory: SubjectCategory {
        SubjectArtHelper.category(for: courseName, title: title)
    }
}
