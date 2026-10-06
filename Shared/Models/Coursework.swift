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
    }

    public var isCompleted: Bool {
        status == .turnedIn || status == .returned || isDueToday || isPast
    }

    public var isUrgent: Bool {
        guard let dueDate else { return false }
        let interval = dueDate.timeIntervalSince(Date())
        return interval > 0 && interval <= (12 * 3600) && !isCompleted
    }

    public var isOverdue: Bool {
        guard let dueDate else { return false }
        return dueDate < Date() && !isCompleted
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

    public var timeOnlyString: String {
        guard let dueDate else { return "--:--" }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dueDate)
        let minute = calendar.component(.minute, from: dueDate)
        if (hour == 23 && minute >= 55) || (hour == 0 && minute == 0) {
            return "Cuối ngày"
        }
        return ClassroomDateFormatters.timeOnly.string(from: dueDate)
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

        if isOverdue {
            if isDueToday {
                return isEndOfDay ? "Quá hạn" : "Trễ \(time)"
            }
            return "Quá hạn"
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
        let now = Date()
        let interval = dueDate.timeIntervalSince(now)

        if interval < 0 {
            let absSecs = abs(interval)
            if absSecs < 3600 {
                let mins = max(1, Int(absSecs / 60))
                return "Quá hạn \(mins) phút"
            } else if absSecs < 86400 {
                let hours = Int(absSecs / 3600)
                return "Quá hạn \(hours) giờ"
            } else {
                let absDays = max(1, Int(absSecs / 86400))
                return absDays == 1 ? "Quá hạn 1 ngày" : "Quá hạn \(absDays) ngày"
            }
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
        }
        if isOverdue {
            return .red
        } else if isDueToday {
            return .orange
        } else if isDueTomorrow {
            return .blue
        } else {
            return .secondary
        }
    }

    public var formattedFullDueDate: String {
        guard let dueDate else { return "Không có hạn nộp" }
        return ClassroomDateFormatters.fullDueDate.string(from: dueDate).capitalized
    }

    public var statusTitle: String {
        switch status {
        case .pending: return "Chưa nộp"
        case .late: return "Nộp trễ"
        case .turnedIn: return "Đã nộp"
        case .returned: return "Đã chấm điểm"
        }
    }
}

private enum ClassroomDateFormatters {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
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
