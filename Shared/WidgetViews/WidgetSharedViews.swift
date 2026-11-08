import SwiftUI
import WidgetKit
import os

public enum SubjectCategory: Sendable {
    case computerScience
    case math
    case english
    case literature
    case physics
    case chemistry
    case biology
    case history
    case defenseEducation
    case localEducation
    case experientialActivities
    case other
}

public struct SubjectArtHelper {
    public struct VisualTheme: Sendable {
        public let category: SubjectCategory
        public let icon: String
        public let themeColor: Color
        public let bannerBackground: Color
    }

    private static let cacheLock = NSLock()
    private static var courseCategoryCache: [String: SubjectCategory] = [:]
    private static var categoryCache: [String: SubjectCategory] = [:]

    private static let standardThemes: [SubjectCategory: VisualTheme] = [
        .computerScience: VisualTheme(category: .computerScience, icon: "desktopcomputer", themeColor: Color(red: 0.08, green: 0.68, blue: 0.54), bannerBackground: Color(red: 0.06, green: 0.58, blue: 0.50)),
        .math: VisualTheme(category: .math, icon: "function", themeColor: Color(red: 0.95, green: 0.60, blue: 0.10), bannerBackground: Color(red: 0.88, green: 0.50, blue: 0.08)),
        .english: VisualTheme(category: .english, icon: "character.book.closed", themeColor: Color(red: 0.15, green: 0.58, blue: 0.92), bannerBackground: Color(red: 0.12, green: 0.48, blue: 0.88)),
        .literature: VisualTheme(category: .literature, icon: "text.book.closed", themeColor: Color(red: 0.92, green: 0.38, blue: 0.22), bannerBackground: Color(red: 0.86, green: 0.34, blue: 0.20)),
        .physics: VisualTheme(category: .physics, icon: "atom", themeColor: Color(red: 0.45, green: 0.38, blue: 0.88), bannerBackground: Color(red: 0.40, green: 0.34, blue: 0.84)),
        .chemistry: VisualTheme(category: .chemistry, icon: "flask", themeColor: Color(red: 0.86, green: 0.28, blue: 0.68), bannerBackground: Color(red: 0.80, green: 0.24, blue: 0.60)),
        .biology: VisualTheme(category: .biology, icon: "leaf", themeColor: Color(red: 0.20, green: 0.72, blue: 0.40), bannerBackground: Color(red: 0.14, green: 0.60, blue: 0.34)),
        .history: VisualTheme(category: .history, icon: "clock.arrow.circlepath", themeColor: Color(red: 0.85, green: 0.52, blue: 0.16), bannerBackground: Color(red: 0.80, green: 0.46, blue: 0.14)),
        .defenseEducation: VisualTheme(category: .defenseEducation, icon: "shield", themeColor: Color(red: 0.16, green: 0.58, blue: 0.28), bannerBackground: Color(red: 0.12, green: 0.50, blue: 0.22)),
        .localEducation: VisualTheme(category: .localEducation, icon: "map", themeColor: Color(red: 0.05, green: 0.58, blue: 0.53), bannerBackground: Color(red: 0.04, green: 0.50, blue: 0.46)),
        .experientialActivities: VisualTheme(category: .experientialActivities, icon: "sparkles", themeColor: Color(red: 0.95, green: 0.42, blue: 0.12), bannerBackground: Color(red: 0.88, green: 0.36, blue: 0.10)),
        .other: VisualTheme(category: .other, icon: "book.closed", themeColor: Color(red: 0.40, green: 0.52, blue: 0.64), bannerBackground: Color(red: 0.30, green: 0.44, blue: 0.60))
    ]

    public static func clearCaches() {
        cacheLock.lock()
        courseCategoryCache.removeAll(keepingCapacity: false)
        categoryCache.removeAll(keepingCapacity: false)
        cacheLock.unlock()
    }

    public static func category(for courseName: String, title: String? = nil) -> SubjectCategory {
        let hasTitle = !(title?.isEmpty ?? true)
        if !hasTitle {
            cacheLock.lock()
            if let cached = courseCategoryCache[courseName] {
                cacheLock.unlock()
                return cached
            }
            cacheLock.unlock()

            let computed = computeCategory(for: courseName, title: nil)
            cacheLock.lock()
            if courseCategoryCache.count >= 2048 {
                courseCategoryCache.removeAll()
            }
            courseCategoryCache[courseName] = computed
            cacheLock.unlock()
            return computed
        }

        let key = "\(courseName)|\(title ?? "")"
        cacheLock.lock()
        if let cached = categoryCache[key] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let computed = computeCategory(for: courseName, title: title)
        cacheLock.lock()
        if categoryCache.count >= 2048 {
            categoryCache.removeAll()
        }
        categoryCache[key] = computed
        cacheLock.unlock()

        return computed
    }

    public static func theme(for category: SubjectCategory) -> VisualTheme {
        standardThemes[category] ?? VisualTheme(
            category: category,
            icon: icon(for: category),
            themeColor: themeColor(for: category),
            bannerBackground: bannerBackground(for: category)
        )
    }

    public static func theme(for courseName: String, title: String? = nil) -> VisualTheme {
        let cat = category(for: courseName, title: title)
        return theme(for: cat)
    }

    public static func badgeCode(for category: SubjectCategory, courseName: String = "", title: String? = nil) -> String {
        switch category {
        case .computerScience: return "TIN"
        case .math: return "TOÁ"
        case .english: return "ANH"
        case .literature: return "VĂN"
        case .physics: return "LÝ"
        case .chemistry: return "HOÁ"
        case .biology: return "SINH"
        case .history: return "SỬ"
        case .defenseEducation: return "GDQP"
        case .localEducation: return "GDĐP"
        case .experientialActivities: return "HĐTN"
        case .other:
            let cleaned = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count >= 3 {
                return String(cleaned.prefix(3)).uppercased()
            }
            let titleCleaned = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if titleCleaned.count >= 3 {
                return String(titleCleaned.prefix(3)).uppercased()
            }
            if !cleaned.isEmpty {
                return cleaned.uppercased()
            }
            if !titleCleaned.isEmpty {
                return titleCleaned.uppercased()
            }
            return "MÔN"
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
        static let literature = TokenFlags(rawValue: 1 << 5)
        static let english = TokenFlags(rawValue: 1 << 6)
        static let cs = TokenFlags(rawValue: 1 << 7)
        static let defense = TokenFlags(rawValue: 1 << 8)
        static let local = TokenFlags(rawValue: 1 << 9)
        static let experiential = TokenFlags(rawValue: 1 << 10)

        static let ly = TokenFlags(rawValue: 1 << 11)
        static let hoa = TokenFlags(rawValue: 1 << 12)
        static let sinh = TokenFlags(rawValue: 1 << 13)
        static let su = TokenFlags(rawValue: 1 << 14)
        static let van = TokenFlags(rawValue: 1 << 15)
        static let anh = TokenFlags(rawValue: 1 << 16)
        static let tin = TokenFlags(rawValue: 1 << 17)
        static let tu = TokenFlags(rawValue: 1 << 18)
    }

    private static let tokenMap: [Substring: TokenFlags] = [
        "toan": .math, "toán": .math, "math": .math, "maths": .math, "calculus": .math, "algebra": .math,
        "geometry": .math, "trigonometry": .math, "statistics": .math, "discrete": .math,
        "physics": .physics, "mechanics": .physics, "thermodynamics": .physics, "optics": .physics,
        "ly": .ly, "lý": .ly, "lí": .ly,
        "chemistry": .chemistry, "chem": .chemistry, "biochemistry": .chemistry,
        "hoa": .hoa, "hóa": .hoa, "hoá": .hoa,
        "biology": .biology, "bio": .biology, "genetics": .biology, "ecology": .biology,
        "sinh": .sinh,
        "history": .history, "su": .su, "sử": .su,
        "literature": .literature, "writing": .literature, "essay": .literature,
        "van": .van, "văn": .van,
        "english": .english, "ielts": .english, "toeic": .english, "toefl": .english,
        "anh": .anh,
        "gdqp": .defense,
        "gddp": .local, "gdđp": .local,
        "hdtn": .experiential, "hđtn": .experiential,
        "android": .cs, "ios": .cs, "swift": .cs, "python": .cs, "java": .cs,
        "cntt": .cs, "it": .cs, "ctdl": .cs, "cpp": .cs, "kotlin": .cs,
        "javascript": .cs, "typescript": .cs, "tin": .tin, "tu": .tu, "tự": .tu
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
            if (flags.contains(.math) || text.contains("toán") ||
                text.contains("giải tích") || text.contains("giai tich") ||
                text.contains("đại số") || text.contains("dai so") ||
                text.contains("hình học") || text.contains("hinh hoc") ||
                text.contains("xác suất") || text.contains("xac suat") ||
                text.contains("lượng giác") || text.contains("luong giac") ||
                text.contains("đạo hàm") || text.contains("dao ham") ||
                text.contains("tích phân") || text.contains("tich phan") ||
                text.contains("toán cao cấp") || text.contains("toan cao cap") ||
                text.contains("toán rời rạc") || text.contains("toan roi rac") ||
                text.contains("thống kê") || text.contains("thong ke") ||
                text.contains("vi phân") || text.contains("vi phan") ||
                text.contains("ma trận") || text.contains("ma tran"))
                && !text.contains("điện toán") && !text.contains("dien toan")
                && !text.contains("an toàn") && !text.contains("an toan")
                && !text.contains("thanh toán") && !text.contains("thanh toan")
                && !text.contains("hoàn toàn") && !text.contains("hoan toan") {
                return .math
            } else if text.contains("vật lý") || text.contains("vật lí") || text.contains("vat ly") || text.contains("vat li") || flags.contains(.physics) ||
                text.contains("môn lý") || text.contains("môn lí") || text.contains("mon ly") || text.contains("mon li") ||
                text.contains("sbt lý") || text.contains("sbt lí") || text.contains("sbt ly") || text.contains("sbt li") ||
                text.contains("cơ học") || text.contains("co hoc") ||
                text.contains("nhiệt học") || text.contains("nhiet hoc") ||
                text.contains("quang học") || text.contains("quang hoc") ||
                text.contains("điện từ") || text.contains("dien tu") ||
                text.contains("vật lý đại cương") || text.contains("vật lí đại cương") || text.contains("vat ly dai cuong") || text.contains("vat li dai cuong") ||
                text.contains("dao động") || text.contains("dao dong") ||
                text.contains("sóng cơ") || text.contains("song co") ||
                (flags.contains(.ly) &&
                    !text.contains("quản lý") && !text.contains("quản lí") && !text.contains("quan ly") && !text.contains("quan li") &&
                    !text.contains("xử lý") && !text.contains("xử lí") && !text.contains("xu ly") && !text.contains("xu li") &&
                    !text.contains("tâm lý") && !text.contains("tâm lí") && !text.contains("tam ly") && !text.contains("tam li") &&
                    !text.contains("pháp lý") && !text.contains("pháp lí") && !text.contains("phap ly") && !text.contains("phap li") &&
                    !text.contains("địa lý") && !text.contains("địa lí") && !text.contains("dia ly") && !text.contains("dia li") &&
                    !text.contains("triết lý") && !text.contains("triết lí") && !text.contains("triet ly") && !text.contains("triet li") &&
                    !text.contains("lý thuyết") && !text.contains("lí thuyết") && !text.contains("ly thuyet") && !text.contains("li thuyet") &&
                    !text.contains("lý luận") && !text.contains("lí luận") && !text.contains("ly luan") && !text.contains("li luan") &&
                    !text.contains("lý do") && !text.contains("lí do") && !text.contains("ly do") && !text.contains("li do") &&
                    !text.contains("hợp lý") && !text.contains("hợp lí") && !text.contains("hop ly") && !text.contains("hop li") &&
                    !text.contains("đại lý") && !text.contains("đại lí") && !text.contains("dai ly") && !text.contains("dai li")) {
                return .physics
            } else if text.contains("hóa học") || text.contains("hoá học") || text.contains("hoa hoc") ||
                text.contains("môn hóa") || text.contains("môn hoá") || text.contains("mon hoa") ||
                text.contains("hóa hữu cơ") || text.contains("hoá hữu cơ") || text.contains("hoa huu co") ||
                text.contains("hóa vô cơ") || text.contains("hoá vô cơ") || text.contains("hoa vo co") ||
                text.contains("hóa đại cương") || text.contains("hoá đại cương") || text.contains("hoa dai cuong") ||
                text.contains("hóa phân tích") || text.contains("hoá phân tích") || text.contains("hoa phan tich") ||
                flags.contains(.chemistry) ||
                (flags.contains(.hoa) &&
                    !text.contains("tự động hóa") && !text.contains("tự động hoá") && !text.contains("tu dong hoa") &&
                    !text.contains("tiến hóa") && !text.contains("tiến hoá") && !text.contains("tien hoa") &&
                    !text.contains("tiêu hóa") && !text.contains("tiêu hoá") && !text.contains("tieu hoa") &&
                    !text.contains("hóa đơn") && !text.contains("hoá đơn") && !text.contains("hoa don") &&
                    !text.contains("văn hóa") && !text.contains("văn hoá") && !text.contains("van hoa") &&
                    !text.contains("tối ưu hóa") && !text.contains("tối ưu hoá") && !text.contains("toi uu hoa") &&
                    !text.contains("chuẩn hóa") && !text.contains("chuẩn hoá") && !text.contains("chuan hoa") &&
                    !text.contains("công nghiệp hóa") && !text.contains("công nghiệp hoá") && !text.contains("cong nghiep hoa") &&
                    !text.contains("hiện đại hóa") && !text.contains("hiện đại hoá") && !text.contains("hien dai hoa") &&
                    !text.contains("ảo hóa") && !text.contains("ảo hoá") && !text.contains("ao hoa") &&
                    !text.contains("số hóa") && !text.contains("số hoá") && !text.contains("so hoa") &&
                    !text.contains("hòa bình") && !text.contains("hoà bình") && !text.contains("hoa binh") &&
                    !text.contains("hòa hợp") && !text.contains("hoà hợp") && !text.contains("hoa hop") &&
                    !text.contains("hóa thân") && !text.contains("hoá thân") && !text.contains("hoa than")) {
                return .chemistry
            } else if text.contains("sinh học") || text.contains("sinh hoc") || text.contains("môn sinh") || text.contains("mon sinh") || flags.contains(.biology) ||
                text.contains("y học") || text.contains("y hoc") ||
                text.contains("di truyền") || text.contains("di truyen") ||
                text.contains("tế bào") || text.contains("te bao") ||
                text.contains("vi sinh") ||
                text.contains("sinh thái") || text.contains("sinh thai") ||
                text.contains("tiêu hóa") || text.contains("tiêu hoá") || text.contains("tieu hoa") ||
                (flags.contains(.sinh) &&
                    !text.contains("học sinh") && !text.contains("hoc sinh") &&
                    !text.contains("sinh viên") && !text.contains("sinh vien") &&
                    !text.contains("sinh hoạt") && !text.contains("sinh hoat")) {
                return .biology
            } else if text.contains("lịch sử") || (text.contains("lich su") && !text.contains("lịch sự") && !text.contains("lich su trong") && !text.contains("giao tiep") && !text.contains("ung xu")) || flags.contains(.history) ||
                text.contains("môn sử") || text.contains("mon su") ||
                (flags.contains(.su) &&
                    !text.contains("sử dụng") && !text.contains("su dung") &&
                    !text.contains("lịch sự") && !text.contains("lich su trong") &&
                    !text.contains("giao tiep") && !text.contains("ung xu")) {
                return .history
            } else if text.contains("ngữ văn") || text.contains("ngu van") || text.contains("tiếng việt") || text.contains("tieng viet") || flags.contains(.literature) ||
                text.contains("môn văn") || text.contains("mon van") ||
                (flags.contains(.van) &&
                    !text.contains("văn phòng") && !text.contains("van phong") &&
                    !text.contains("văn hóa") && !text.contains("văn hoá") && !text.contains("van hoa") &&
                    !text.contains("văn minh") && !text.contains("van minh") &&
                    !text.contains("văn bản") && !text.contains("van ban") &&
                    !text.contains("luận văn") && !text.contains("luan van")) {
                return .literature
            } else if text.contains("tiếng anh") || text.contains("tieng anh") || flags.contains(.english) ||
                text.contains("môn anh") || text.contains("mon anh") ||
                (flags.contains(.anh) &&
                    !text.contains("hình ảnh") && !text.contains("hinh anh") &&
                    !text.contains("âm thanh") && !text.contains("am thanh") &&
                    !text.contains("thầy") && !text.contains("thay") &&
                    !text.contains("cô") && !text.contains("co ") &&
                    !text.contains("gv")) {
                return .english
            } else if text.contains("tin học") || text.contains("tin hoc") ||
                text.contains("môn tin") || text.contains("mon tin") ||
                text.contains("lập trình") || text.contains("lap trinh") ||
                text.contains("di động") || text.contains("di dong") ||
                flags.contains(.cs) ||
                text.contains("công nghệ thông tin") || text.contains("cong nghe thong tin") ||
                text.contains("thuật toán") || text.contains("thuat toan") ||
                text.contains("cơ sở dữ liệu") || text.contains("co so du lieu") ||
                text.contains("khoa học máy tính") || text.contains("khoa hoc may tinh") ||
                text.contains("cấu trúc dữ liệu") || text.contains("cau truc du lieu") ||
                text.contains("trí tuệ nhân tạo") || text.contains("tri tue nhan tao") ||
                text.contains("machine learning") ||
                text.contains("hệ điều hành") || text.contains("he dieu hanh") ||
                text.contains("kiến trúc máy tính") || text.contains("kien truc may tinh") ||
                (flags.contains(.tin) &&
                    !text.contains("thông tin") && !text.contains("thong tin") &&
                    !text.contains("bản tin") && !text.contains("ban tin") &&
                    !text.contains("tin tức") && !text.contains("tin tuc") &&
                    !text.contains("niềm tin") && !text.contains("niem tin") &&
                    !flags.contains(.tu)) {
                return .computerScience
            } else if flags.contains(.defense) ||
                text.contains("giáo dục quốc phòng") || text.contains("giao duc quoc phong") ||
                text.contains("quốc phòng an ninh") || text.contains("quoc phong an ninh") ||
                text.contains("an ninh quốc phòng") || text.contains("an ninh quoc phong") ||
                text.contains("quân sự") || text.contains("quan su") ||
                text.contains("giáo dục qp") || text.contains("giao duc qp") {
                return .defenseEducation
            } else if flags.contains(.local) ||
                text.contains("giáo dục địa phương") || text.contains("giao duc dia phuong") ||
                text.contains("giáo dục đp") || text.contains("giao duc dp") {
                return .localEducation
            } else if flags.contains(.experiential) ||
                text.contains("hoạt động trải nghiệm") || text.contains("hoat dong trai nghiem") ||
                text.contains("hướng nghiệp") || text.contains("huong nghiep") ||
                text.contains("sinh hoạt dưới cờ") || text.contains("sinh hoat duoi co") ||
                text.contains("sinh hoạt lớp") || text.contains("sinh hoat lop") {
                return .experientialActivities
            }
            return nil
        }

        if let title, !title.isEmpty {
            let titleNormalized = title.precomposedStringWithCanonicalMapping
            let titleLower = titleNormalized.lowercased()
            let titleFlags = scanTokenFlags(in: titleLower)
            if let matched = matchCategory(text: titleLower, flags: titleFlags) {
                return matched
            }
        }

        let courseNormalized = courseName.precomposedStringWithCanonicalMapping
        let courseLower = courseNormalized.lowercased()
        let courseFlags = scanTokenFlags(in: courseLower)
        if let matched = matchCategory(text: courseLower, flags: courseFlags) {
            return matched
        }

        return .other
    }

    public static func icon(for category: SubjectCategory) -> String {
        switch category {
        case .computerScience: return "laptopcomputer"
        case .math: return "function"
        case .english: return "globe.americas"
        case .literature: return "book.pages"
        case .physics: return "atom"
        case .chemistry: return "flask"
        case .biology: return "leaf"
        case .history: return "building.columns"
        case .defenseEducation: return "shield.fill"
        case .localEducation: return "map"
        case .experientialActivities: return "sparkles"
        case .other: return "book.closed"
        }
    }

    public static func icon(for courseName: String, title: String? = nil) -> String {
        icon(for: category(for: courseName, title: title))
    }

    public static func themeColor(for category: SubjectCategory) -> Color {
        standardThemes[category]?.themeColor ?? Color(red: 0.40, green: 0.52, blue: 0.64)
    }

    public static func themeColor(for courseName: String, title: String? = nil) -> Color {
        themeColor(for: category(for: courseName, title: title))
    }

    public static func bannerBackground(for category: SubjectCategory) -> Color {
        switch category {
        case .computerScience: return Color(red: 0.06, green: 0.58, blue: 0.50)
        case .math: return Color(red: 0.88, green: 0.50, blue: 0.08)
        case .english: return Color(red: 0.12, green: 0.48, blue: 0.88)
        case .literature: return Color(red: 0.86, green: 0.34, blue: 0.20)
        case .physics: return Color(red: 0.40, green: 0.34, blue: 0.84)
        case .chemistry: return Color(red: 0.80, green: 0.24, blue: 0.60)
        case .biology: return Color(red: 0.14, green: 0.60, blue: 0.34)
        case .history: return Color(red: 0.80, green: 0.46, blue: 0.14)
        case .defenseEducation: return Color(red: 0.12, green: 0.50, blue: 0.22)
        case .localEducation: return Color(red: 0.04, green: 0.50, blue: 0.46)
        case .experientialActivities: return Color(red: 0.88, green: 0.36, blue: 0.10)
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
                        SubjectArtBadgeView(courseName: item.courseName, size: 26)
                        Text(item.courseName)
                            .font(.system(size: 16.5, weight: .bold))
                            .foregroundStyle(.white.opacity(0.95))
                    }

                    Text(item.title)
                        .font(.system(size: 21.5, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text(item.formattedFullDueDate)
                            .font(.system(size: 14.5, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
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
        #if (os(macOS) || os(iOS)) && compiler(>=6.4)
        if #available(iOS 26.0, macOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        #elseif os(macOS) || os(iOS)
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
        #else
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white)
        #endif
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
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(visualTheme.themeColor)
            Text(name)
                .font(.system(size: 12, weight: .medium))
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
                    .font(.system(size: compact ? 11.5 : 12.5, weight: .bold))
            } else if item.isOverdue || item.isPast {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: compact ? 11.5 : 12.5, weight: .semibold))
            } else {
                Image(systemName: "clock")
                    .font(.system(size: compact ? 11.5 : 12.5, weight: .semibold))
            }

            Text(badgeText)
                .font(.system(size: compact ? 13.5 : 14.5, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, compact ? 8.5 : 10.5)
        .padding(.vertical, compact ? 4 : 5)
        .appleLiquidGlassSurface(
            style: .tint(badgeColor.opacity(0.14)),
            in: RoundedRectangle(cornerRadius: 6, style: .continuous),
            isEnabled: !compact
        ) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(badgeColor.opacity(0.12))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(badgeColor.opacity(0.25), lineWidth: 1)
        )
    }
}

public struct WidgetEmptyStateView: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            ChunkyEmberCharacterView(emotion: .sleeping, size: 52)

            VStack(alignment: .leading, spacing: 2.5) {
                Text("Ngày mai không có bài!")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(ChunkyTheme.textPrimary)

                Text("Tất cả bài tập đã hoàn thành.")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .lineSpacing(2)
                    .foregroundStyle(ChunkyTheme.textMuted)
            }
        }
    }
}

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
