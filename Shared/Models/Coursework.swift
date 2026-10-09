import Foundation
import SwiftUI

public enum SubmissionStatus: String, Codable, Sendable {
    case pending
    case turnedIn
    case returned
    case late
}

public struct Coursework: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let courseId: String
    public let courseName: String
    public let title: String
    public let description: String?
    public let alternateLink: String?
    public let dueDate: Date?
    public var status: SubmissionStatus
    public let maxPoints: Double?

    public let searchIndex: String
    public let timeOnlyString: String
    public let formattedFullDueDate: String

    private enum CodingKeys: String, CodingKey {
        case id, courseId, courseName, title, description, alternateLink, dueDate, status, maxPoints
    }

    public init(
        id: String,
        courseId: String,
        courseName: String,
        title: String,
        description: String? = nil,
        alternateLink: String? = nil,
        dueDate: Date? = nil,
        status: SubmissionStatus = .pending,
        maxPoints: Double? = nil
    ) {
        self.id = id
        self.courseId = courseId
        self.courseName = courseName
        self.title = title
        self.description = description
        self.alternateLink = alternateLink
        self.dueDate = dueDate
        self.status = status
        self.maxPoints = maxPoints

        self.searchIndex = Self.buildSearchIndex(title: title, courseName: courseName, description: description)
        self.timeOnlyString = Self.buildTimeOnlyString(from: dueDate)
        self.formattedFullDueDate = Self.buildFormattedFullDueDate(from: dueDate)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let courseId = try container.decode(String.self, forKey: .courseId)
        let courseName = try container.decode(String.self, forKey: .courseName)
        let title = try container.decode(String.self, forKey: .title)
        let description = try container.decodeIfPresent(String.self, forKey: .description)
        let alternateLink = try container.decodeIfPresent(String.self, forKey: .alternateLink)
        let dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        let status = try container.decode(SubmissionStatus.self, forKey: .status)
        let maxPoints = try container.decodeIfPresent(Double.self, forKey: .maxPoints)

        self.id = id
        self.courseId = courseId
        self.courseName = courseName
        self.title = title
        self.description = description
        self.alternateLink = alternateLink
        self.dueDate = dueDate
        self.status = status
        self.maxPoints = maxPoints

        self.searchIndex = Self.buildSearchIndex(title: title, courseName: courseName, description: description)
        self.timeOnlyString = Self.buildTimeOnlyString(from: dueDate)
        self.formattedFullDueDate = Self.buildFormattedFullDueDate(from: dueDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(courseId, forKey: .courseId)
        try container.encode(courseName, forKey: .courseName)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(alternateLink, forKey: .alternateLink)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(maxPoints, forKey: .maxPoints)
    }

    /// Triết lý ứng dụng: Cứ hết hạn thì tính là đã hoàn thành.
    /// Mọi bài tập có hạn nộp trong quá khứ (dueDate < now) đều được tính là đã hoàn thành.
    public var isCompleted: Bool {
        if status == .turnedIn || status == .returned {
            return true
        }
        if let dueDate, dueDate < Date() {
            return true
        }
        return false
    }

    public var destinationURL: URL {
        if let link = alternateLink, let url = URL(string: link) {
            return url
        }
        return URL(string: "https://classroom.google.com") ?? URL(fileURLWithPath: "/")
    }

    public var isUrgent: Bool {
        guard let dueDate else { return false }
        let interval = dueDate.timeIntervalSince(Date())
        return interval > 0 && interval <= (12 * 3600) && !isCompleted
    }

    public var isOverdue: Bool {
        // Triết lý: Cứ hết hạn thì tính là đã hoàn thành => Không còn bài tập quá hạn
        false
    }

    public var isPast: Bool {
        guard let dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }

    public var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    public var isDueTomorrow: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }

    public var isDueLater: Bool {
        guard let dueDate else { return false }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday) else { return false }
        return dueDate >= dayAfterTomorrow
    }

    public var hasNoDueDate: Bool {
        dueDate == nil
    }

    public var isDueTodayOrTomorrow: Bool {
        isDueToday || isDueTomorrow
    }

    public var isUpcomingTodayOrTomorrow: Bool {
        isDueTodayOrTomorrow && !isCompleted
    }


    public var friendlyDueString: String {
        guard let dueDate else { return "Không có hạn" }
        let time = timeOnlyString
        let isEndOfDay = (time == "Cuối ngày")

        if isOverdue {
            if isDueToday {
                return isEndOfDay ? "Quá hạn (hôm nay)" : "Quá hạn (\(time))"
            } else {
                let dayStr = ClassroomDateFormatters.shortDate.string(from: dueDate)
                return "Quá hạn (\(dayStr))"
            }
        } else if isDueToday {
            return isEndOfDay ? "Hết hôm nay" : "Hôm nay, \(time)"
        } else if isDueTomorrow {
            return isEndOfDay ? "Hết ngày mai" : "Ngày mai, \(time)"
        } else if isPast {
            let dayStr = ClassroomDateFormatters.shortDate.string(from: dueDate)
            return "Đã qua (\(dayStr))"
        } else {
            let dayStr = ClassroomDateFormatters.dayAndDate.string(from: dueDate)
            return isEndOfDay ? "\(dayStr) (hết ngày)" : "\(dayStr), \(time)"
        }
    }

    public var compactDueString: String {
        guard let dueDate else { return "Không hạn" }
        let time = timeOnlyString
        let isEndOfDay = (time == "Cuối ngày")

        if isCompleted {
            return "Đã xong"
        } else if isDueToday {
            return isEndOfDay ? "Hết hôm nay" : time
        } else if isDueTomorrow {
            return isEndOfDay ? "Hết ngày mai" : "Mai \(time)"
        } else if isPast {
            return "Đã qua"
        } else {
            let dayStr = ClassroomDateFormatters.shortDate.string(from: dueDate)
            return isEndOfDay ? dayStr : "\(dayStr) \(time)"
        }
    }

    public var dayAndTimeString: String {
        friendlyDueString
    }

    public var countdownBadgeString: String {
        guard let dueDate else { return "Không có hạn" }
        if isCompleted {
            return "Đã hoàn thành"
        }
        let now = Date()
        let interval = dueDate.timeIntervalSince(now)

        if interval < 0 {
            return "Đã hoàn thành"
        } else if interval < 3600 {
            let mins = max(1, Int(interval / 60))
            return "Còn \(mins) phút"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            let mins = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            if mins > 0 {
                return "Còn \(hours)g \(mins)p"
            }
            return "Còn \(hours) giờ"
        } else if isDueToday || isDueTomorrow {
            return friendlyDueString
        } else {
            return dayAndTimeString
        }
    }

    public var relativeDueString: String {
        dayAndTimeString
    }

    public var urgencyColor: Color {
        if isCompleted {
            return .green
        } else if isDueToday {
            return .orange
        } else if isDueTomorrow {
            return .blue
        } else {
            return .secondary
        }
    }

    public var statusTitle: String {
        switch status {
        case .turnedIn: return "Đã nộp"
        case .returned: return "Đã chấm điểm"
        case .late: return "Đã hoàn thành"
        case .pending: return isCompleted ? "Đã hoàn thành" : "Chưa nộp"
        }
    }

    private static func buildSearchIndex(title: String, courseName: String, description: String?) -> String {
        let combined = "\(title) \(courseName) \(description ?? "")"
        return combined.normalizedForVietnameseSearch()
    }

    private static func buildTimeOnlyString(from dueDate: Date?) -> String {
        guard let dueDate else { return "--:--" }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dueDate)
        let minute = calendar.component(.minute, from: dueDate)
        if hour == 23 && minute >= 55 {
            return "Cuối ngày"
        }
        return ClassroomDateFormatters.timeOnly.string(from: dueDate)
    }

    private static func buildFormattedFullDueDate(from dueDate: Date?) -> String {
        guard let dueDate else { return "Không có hạn nộp" }
        return ClassroomDateFormatters.fullDueDate.string(from: dueDate).capitalized
    }
}

private let vietnameseSearchLocale = Locale(identifier: "vi_VN")

public extension String {
    func normalizedForVietnameseSearch() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "d")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: vietnameseSearchLocale)
            .lowercased()
    }
}

private enum ClassroomDateFormatters {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "d/M"
        return formatter
    }()

    static let dayAndDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "E, d/M"
        return formatter
    }()

    static let fullDueDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, 'ngày' d 'tháng' M, yyyy 'lúc' HH:mm"
        return formatter
    }()
}
