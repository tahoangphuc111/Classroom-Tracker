import Foundation
import SwiftUI

public enum SubmissionStatus: String, Codable, Sendable {
    case pending
    case turnedIn
    case returned
    case late

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased()
        switch raw {
        case "turnedin", "turned_in", "student_edited_after_turn_in":
            self = .turnedIn
        case "returned":
            self = .returned
        case "late":
            self = .late
        case "pending", "new", "created":
            self = .pending
        default:
            self = .pending
        }
    }
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
    public var isManuallyCompleted: Bool

    public let searchIndex: String
    public let timeOnlyString: String
    public let formattedFullDueDate: String
    public let normalizedTitle: String
    public let normalizedCourseName: String
    public let normalizedDescription: String

    private enum CodingKeys: String, CodingKey {
        case id, courseId, courseName, title, description, alternateLink, dueDate, status, maxPoints, isManuallyCompleted
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
        maxPoints: Double? = nil,
        isManuallyCompleted: Bool = false
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
        self.isManuallyCompleted = isManuallyCompleted

        let normTitle = title.normalizedForVietnameseSearch()
        let normCourse = courseName.normalizedForVietnameseSearch()
        let normDesc = (description?.isEmpty ?? true) ? "" : description!.normalizedForVietnameseSearch()
        self.normalizedTitle = normTitle
        self.normalizedCourseName = normCourse
        self.normalizedDescription = normDesc
        self.searchIndex = Self.buildNormalizedSearchIndex(normTitle: normTitle, normCourse: normCourse, normDescription: normDesc)
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
        let status = (try? container.decode(SubmissionStatus.self, forKey: .status)) ?? .pending
        let maxPoints = try container.decodeIfPresent(Double.self, forKey: .maxPoints)
        let isManuallyCompleted = try container.decodeIfPresent(Bool.self, forKey: .isManuallyCompleted) ?? false

        self.id = id
        self.courseId = courseId
        self.courseName = courseName
        self.title = title
        self.description = description
        self.alternateLink = alternateLink
        self.dueDate = dueDate
        self.status = status
        self.maxPoints = maxPoints
        self.isManuallyCompleted = isManuallyCompleted

        let normTitle = title.normalizedForVietnameseSearch()
        let normCourse = courseName.normalizedForVietnameseSearch()
        let normDesc = (description?.isEmpty ?? true) ? "" : description!.normalizedForVietnameseSearch()
        self.normalizedTitle = normTitle
        self.normalizedCourseName = normCourse
        self.normalizedDescription = normDesc
        self.searchIndex = Self.buildNormalizedSearchIndex(normTitle: normTitle, normCourse: normCourse, normDescription: normDesc)
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
        try container.encode(isManuallyCompleted, forKey: .isManuallyCompleted)
    }

    public var isCompleted: Bool {
        if status == .turnedIn || status == .returned || isManuallyCompleted {
            return true
        }
        if let dueDate, dueDate.timeIntervalSinceReferenceDate < Date.timeIntervalSinceReferenceDate {
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
        let interval = dueDate.timeIntervalSinceReferenceDate - Date.timeIntervalSinceReferenceDate
        return interval > 0 && interval <= (12 * 3600) && !isCompleted
    }

    public var isOverdue: Bool {
        false
    }

    public var isPast: Bool {
        guard let dueDate else { return false }
        return dueDate.timeIntervalSinceReferenceDate < ClassroomDateFormatters.startOfTodayTimestamp
    }

    public var isDueToday: Bool {
        guard let dueDate else { return false }
        let t = dueDate.timeIntervalSinceReferenceDate
        return t >= ClassroomDateFormatters.startOfTodayTimestamp && t < ClassroomDateFormatters.startOfTomorrowTimestamp
    }

    public var isDueTomorrow: Bool {
        guard let dueDate else { return false }
        let t = dueDate.timeIntervalSinceReferenceDate
        return t >= ClassroomDateFormatters.startOfTomorrowTimestamp && t < ClassroomDateFormatters.startOfDayAfterTimestamp
    }

    public var isDueLater: Bool {
        guard let dueDate else { return false }
        return dueDate.timeIntervalSinceReferenceDate >= ClassroomDateFormatters.startOfDayAfterTimestamp
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

        if isDueToday {
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
        if isCompleted {
            return "Đã xong"
        }
        let time = timeOnlyString
        let isEndOfDay = (time == "Cuối ngày")

        if isDueToday {
            return isEndOfDay ? "Cuối ngày" : time
        } else if isDueTomorrow {
            return isEndOfDay ? "Mai" : "Mai \(time)"
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

    public static func buildSearchIndex(title: String, courseName: String, description: String?) -> String {
        let normTitle = title.normalizedForVietnameseSearch()
        let normCourse = courseName.normalizedForVietnameseSearch()
        let normDesc = (description?.isEmpty ?? true) ? "" : description!.normalizedForVietnameseSearch()
        return buildNormalizedSearchIndex(normTitle: normTitle, normCourse: normCourse, normDescription: normDesc)
    }

    public static func buildNormalizedSearchIndex(normTitle: String, normCourse: String, normDescription: String) -> String {
        guard !normDescription.isEmpty else {
            return "\(normTitle) \(normCourse)"
        }
        return "\(normTitle) \(normCourse) \(normDescription)"
    }

    public static func buildNormalizedSearchIndex(normTitle: String, normCourse: String, description: String?) -> String {
        guard let description, !description.isEmpty else {
            return "\(normTitle) \(normCourse)"
        }
        return "\(normTitle) \(normCourse) \(description.normalizedForVietnameseSearch())"
    }

    private static func buildTimeOnlyString(from dueDate: Date?) -> String {
        guard let dueDate else { return "--:--" }
        let hour = ClassroomDateFormatters.gregorianCalendar.component(.hour, from: dueDate)
        let minute = ClassroomDateFormatters.gregorianCalendar.component(.minute, from: dueDate)
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

// Single-pass LUT for Vietnamese Diacritics Normalization & Lowercasing
private let vietnameseLut1: [UInt8] = [
    97, 97, 97, 97, 97, 97, 0, 99, 101, 101, 101, 101, 105, 105, 105, 105, 0, 110, 111, 111, 111, 111, 111, 0, 0, 117, 117, 117, 117, 121, 0, 0, 97, 97, 97, 97, 97, 97, 0, 99, 101, 101, 101, 101, 105, 105, 105, 105, 0, 110, 111, 111, 111, 111, 111, 0, 0, 117, 117, 117, 117, 121, 0, 121, 97, 97, 97, 97, 97, 97, 99, 99, 99, 99, 99, 99, 99, 99, 100, 100, 100, 100, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 103, 103, 103, 103, 103, 103, 103, 103, 104, 104, 0, 0, 105, 105, 105, 105, 105, 105, 105, 105, 105, 0, 0, 0, 106, 106, 107, 107, 0, 108, 108, 108, 108, 108, 108, 0, 0, 0, 0, 110, 110, 110, 110, 110, 110, 0, 0, 0, 111, 111, 111, 111, 111, 111, 0, 0, 114, 114, 114, 114, 114, 114, 115, 115, 115, 115, 115, 115, 115, 115, 116, 116, 116, 116, 0, 0, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 119, 119, 121, 121, 121, 122, 122, 122, 122, 122, 122, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 111, 111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 117, 117
]

private let vietnameseLut2: [UInt8] = [
    97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 105, 105, 105, 105, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 121, 121, 121, 121, 121, 121, 121, 121
]

public extension String {
    func normalizedForVietnameseSearch() -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        return String(unsafeUninitializedCapacity: trimmed.utf8.count) { buffer in
            var outIdx = 0
            vietnameseLut1.withUnsafeBufferPointer { lut1Ptr in
                vietnameseLut2.withUnsafeBufferPointer { lut2Ptr in
                    for scalar in trimmed.unicodeScalars {
                        let v = scalar.value
                        if v < 128 {
                            if v >= 65 && v <= 90 { // 'A'...'Z'
                                buffer[outIdx] = UInt8(v + 32)
                            } else {
                                buffer[outIdx] = UInt8(v)
                            }
                            outIdx += 1
                        } else if v >= 0x00C0 && v <= 0x01B0 {
                            let mapped = lut1Ptr[Int(v - 0x00C0)]
                            if mapped != 0 {
                                buffer[outIdx] = mapped
                                outIdx += 1
                            } else {
                                for b in scalar.utf8 {
                                    buffer[outIdx] = b
                                    outIdx += 1
                                }
                            }
                        } else if v >= 0x1EA0 && v <= 0x1EF9 {
                            let mapped = lut2Ptr[Int(v - 0x1EA0)]
                            if mapped != 0 {
                                buffer[outIdx] = mapped
                                outIdx += 1
                            } else {
                                for b in scalar.utf8 {
                                    buffer[outIdx] = b
                                    outIdx += 1
                                }
                            }
                        } else if v >= 0x0300 && v <= 0x036F {
                            // Drop combining diacritical marks
                            continue
                        } else {
                            for b in scalar.utf8 {
                                buffer[outIdx] = b
                                outIdx += 1
                            }
                        }
                    }
                }
            }
            return outIdx
        }
    }

    func searchQueryTokens() -> [String] {
        let cleanQuery = self.normalizedForVietnameseSearch()
        guard !cleanQuery.isEmpty else { return [] }

        var tokens: [String] = []
        tokens.reserveCapacity(4)
        var start: String.Index? = nil

        for i in cleanQuery.indices {
            let b = cleanQuery.utf8[i]
            if b == 32 || b == 9 || b == 10 || b == 13 {
                if let s = start {
                    tokens.append(String(cleanQuery[s..<i]))
                    start = nil
                }
            } else if start == nil {
                start = i
            }
        }
        if let s = start {
            tokens.append(String(cleanQuery[s...]))
        }
        return tokens
    }
}

public enum VietnameseSearchScorer {
    public static func calculateScore(
        tokens: [String],
        rawNormalizedQuery: String,
        normTitle: String,
        normCourse: String,
        normContentOrDesc: String,
        checklistTitles: [String] = []
    ) -> Int {
        guard !tokens.isEmpty else { return 0 }
        var score = 0
        let rawQueryLen = rawNormalizedQuery.utf8.count
        var titleMatchRange: Range<String.Index>? = nil
        var courseMatched = false
        if rawQueryLen > 0 {
            if normTitle == rawNormalizedQuery {
                score += 200
                titleMatchRange = normTitle.startIndex..<normTitle.endIndex
            } else if normTitle.hasPrefix(rawNormalizedQuery) {
                score += 120
                titleMatchRange = normTitle.startIndex..<normTitle.index(normTitle.startIndex, offsetBy: rawQueryLen)
            } else if normTitle.utf8.count >= rawQueryLen, let r = normTitle.range(of: rawNormalizedQuery, options: .literal) {
                score += 80
                titleMatchRange = r
            }

            if normCourse == rawNormalizedQuery {
                score += 100
                courseMatched = true
            } else if normCourse.hasPrefix(rawNormalizedQuery) {
                score += 60
                courseMatched = true
            } else if normCourse.utf8.count >= rawQueryLen && normCourse.range(of: rawNormalizedQuery, options: .literal) != nil {
                score += 40
                courseMatched = true
            }
        }

        if tokens.count == 1 && rawQueryLen > 0 && tokens[0] == rawNormalizedQuery {
            let token = rawNormalizedQuery
            if let matchRange = titleMatchRange {
                score += 30
                var isWordBoundary = (matchRange.lowerBound == normTitle.startIndex) ||
                    (normTitle[normTitle.index(before: matchRange.lowerBound)] == " ")
                if !isWordBoundary {
                    var searchRange = matchRange.upperBound..<normTitle.endIndex
                    while let nextRange = normTitle.range(of: token, options: .literal, range: searchRange) {
                        if normTitle[normTitle.index(before: nextRange.lowerBound)] == " " {
                            isWordBoundary = true
                            break
                        }
                        searchRange = nextRange.upperBound..<normTitle.endIndex
                    }
                }
                if isWordBoundary {
                    score += 15
                }
            }
            if courseMatched {
                score += 15
            }
            if !normContentOrDesc.isEmpty && normContentOrDesc.utf8.count >= rawQueryLen && normContentOrDesc.range(of: token, options: .literal) != nil {
                score += 5
            }
            if !checklistTitles.isEmpty {
                for rawTitle in checklistTitles {
                    let normItem = rawTitle.normalizedForVietnameseSearch()
                    if normItem.utf8.count >= rawQueryLen && normItem.range(of: token, options: .literal) != nil {
                        score += 5
                    }
                }
            }
            return score
        }

        for token in tokens {
            let tokenLen = token.utf8.count
            if tokenLen == 0 { continue }
            if normTitle.utf8.count >= tokenLen, let matchRange = normTitle.range(of: token, options: .literal) {
                score += 30
                var isWordBoundary = (matchRange.lowerBound == normTitle.startIndex) ||
                    (normTitle[normTitle.index(before: matchRange.lowerBound)] == " ")
                if !isWordBoundary {
                    var searchRange = matchRange.upperBound..<normTitle.endIndex
                    while let nextRange = normTitle.range(of: token, options: .literal, range: searchRange) {
                        if normTitle[normTitle.index(before: nextRange.lowerBound)] == " " {
                            isWordBoundary = true
                            break
                        }
                        searchRange = nextRange.upperBound..<normTitle.endIndex
                    }
                }
                if isWordBoundary {
                    score += 15
                }
            }
            if normCourse.utf8.count >= tokenLen && normCourse.range(of: token, options: .literal) != nil {
                score += 15
            }
            if !normContentOrDesc.isEmpty && normContentOrDesc.utf8.count >= tokenLen && normContentOrDesc.range(of: token, options: .literal) != nil {
                score += 5
            }
        }

        if !checklistTitles.isEmpty {
            for rawTitle in checklistTitles {
                let normItem = rawTitle.normalizedForVietnameseSearch()
                let normItemLen = normItem.utf8.count
                if rawQueryLen > 0 && normItemLen >= rawQueryLen {
                    if normItem == rawNormalizedQuery {
                        score += 60
                    } else if normItem.range(of: rawNormalizedQuery, options: .literal) != nil {
                        score += 30
                    }
                }
                for token in tokens {
                    let tokenLen = token.utf8.count
                    if tokenLen > 0 && normItemLen >= tokenLen && normItem.range(of: token, options: .literal) != nil {
                        score += 8
                    }
                }
            }
        }

        return score
    }
}

public extension Coursework {
    func searchRelevanceScore(for tokens: [String], rawNormalizedQuery: String) -> Int {
        VietnameseSearchScorer.calculateScore(
            tokens: tokens,
            rawNormalizedQuery: rawNormalizedQuery,
            normTitle: normalizedTitle,
            normCourse: normalizedCourseName,
            normContentOrDesc: normalizedDescription
        )
    }
}

extension Coursework: Comparable {
    public static func < (first: Coursework, second: Coursework) -> Bool {
        if first.isCompleted != second.isCompleted {
            return !first.isCompleted
        }
        switch (first.dueDate, second.dueDate) {
        case let (d1?, d2?):
            if d1 != d2 { return d1 < d2 }
            let titleOrder = first.title.localizedStandardCompare(second.title)
            if titleOrder != .orderedSame {
                return titleOrder == .orderedAscending
            }
            return first.id < second.id
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            let titleOrder = first.title.localizedStandardCompare(second.title)
            if titleOrder != .orderedSame {
                return titleOrder == .orderedAscending
            }
            return first.id < second.id
        }
    }
}

public enum ClassroomDateFormatters {
    public static let gregorianCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    private static var cachedStartOfToday: Date = Date.distantPast
    private static var cachedStartOfTomorrow: Date = Date.distantPast
    private static var cachedStartOfDayAfter: Date = Date.distantPast
    private static var cachedStartOfTodayTimestamp: TimeInterval = 0
    private static var cachedStartOfTomorrowTimestamp: TimeInterval = 0
    private static var cachedStartOfDayAfterTimestamp: TimeInterval = 0
    private static var cacheExpirationTimestamp: TimeInterval = 0
    private static var cachedTimeZoneId: String = ""
    private static let boundaryLock = NSLock()

    public static func ensureDayBoundaries() {
        ensureDayBoundaries(nowTimestamp: Date.timeIntervalSinceReferenceDate)
    }

    public static func ensureDayBoundaries(nowTimestamp: TimeInterval) {
        let currentTzId = TimeZone.autoupdatingCurrent.identifier
        if currentTzId == cachedTimeZoneId && nowTimestamp >= cachedStartOfTodayTimestamp && nowTimestamp < cacheExpirationTimestamp {
            return
        }
        boundaryLock.lock()
        defer { boundaryLock.unlock() }
        if currentTzId == cachedTimeZoneId && nowTimestamp >= cachedStartOfTodayTimestamp && nowTimestamp < cacheExpirationTimestamp {
            return
        }
        cachedTimeZoneId = currentTzId
        let now = Date(timeIntervalSinceReferenceDate: nowTimestamp)
        let cal = gregorianCalendar
        let startOfToday = cal.startOfDay(for: now)
        let startOfTomorrow = cal.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86400)
        let startOfDayAfter = cal.date(byAdding: .day, value: 2, to: startOfToday) ?? startOfToday.addingTimeInterval(172800)

        cachedStartOfToday = startOfToday
        cachedStartOfTomorrow = startOfTomorrow
        cachedStartOfDayAfter = startOfDayAfter
        cachedStartOfTodayTimestamp = startOfToday.timeIntervalSinceReferenceDate
        cachedStartOfTomorrowTimestamp = startOfTomorrow.timeIntervalSinceReferenceDate
        cachedStartOfDayAfterTimestamp = startOfDayAfter.timeIntervalSinceReferenceDate
        cacheExpirationTimestamp = min(cachedStartOfTomorrowTimestamp, nowTimestamp + 60.0)
    }

    public static func ensureDayBoundaries(now: Date) {
        ensureDayBoundaries(nowTimestamp: now.timeIntervalSinceReferenceDate)
    }

    public static var startOfTodayTimestamp: TimeInterval {
        ensureDayBoundaries()
        return cachedStartOfTodayTimestamp
    }

    public static var startOfTomorrowTimestamp: TimeInterval {
        ensureDayBoundaries()
        return cachedStartOfTomorrowTimestamp
    }

    public static var startOfDayAfterTimestamp: TimeInterval {
        ensureDayBoundaries()
        return cachedStartOfDayAfterTimestamp
    }

    public static var startOfToday: Date {
        ensureDayBoundaries()
        return cachedStartOfToday
    }

    public static var startOfTomorrow: Date {
        ensureDayBoundaries()
        return cachedStartOfTomorrow
    }

    public static var startOfDayAfter: Date {
        ensureDayBoundaries()
        return cachedStartOfDayAfter
    }

    public static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "d/M"
        return formatter
    }()

    public static let dayAndDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "E, d/M"
        return formatter
    }()

    public static let fullDueDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "EEEE, 'ngày' d 'tháng' M, yyyy 'lúc' HH:mm"
        return formatter
    }()
}
