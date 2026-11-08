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
    public let conciseDueString: String
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
        let normDesc = description?.normalizedForVietnameseSearch() ?? ""
        self.normalizedTitle = normTitle
        self.normalizedCourseName = normCourse
        self.normalizedDescription = normDesc
        self.searchIndex = Self.buildNormalizedSearchIndex(normTitle: normTitle, normCourse: normCourse, normDescription: normDesc)
        self.timeOnlyString = Self.buildTimeOnlyString(from: dueDate)
        self.formattedFullDueDate = Self.buildFormattedFullDueDate(from: dueDate)
        self.conciseDueString = Self.buildConciseDueString(from: dueDate)
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
        let normDesc = description?.normalizedForVietnameseSearch() ?? ""
        self.normalizedTitle = normTitle
        self.normalizedCourseName = normCourse
        self.normalizedDescription = normDesc
        self.searchIndex = Self.buildNormalizedSearchIndex(normTitle: normTitle, normCourse: normCourse, normDescription: normDesc)
        self.timeOnlyString = Self.buildTimeOnlyString(from: dueDate)
        self.formattedFullDueDate = Self.buildFormattedFullDueDate(from: dueDate)
        self.conciseDueString = Self.buildConciseDueString(from: dueDate)
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
        if let link = alternateLink,
           let url = URL(string: link),
           let scheme = url.scheme?.lowercased(),
           scheme == "https" || scheme == "http" {
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
        let normDesc = description?.normalizedForVietnameseSearch() ?? ""
        return buildNormalizedSearchIndex(normTitle: normTitle, normCourse: normCourse, normDescription: normDesc)
    }

    public static func buildNormalizedSearchIndex(normTitle: String, normCourse: String, normDescription: String) -> String {
        let base: String
        if !normDescription.isEmpty {
            base = "\(normTitle) \(normCourse) \(normDescription)"
        } else {
            base = "\(normTitle) \(normCourse)"
        }
        let extra = expandVietnameseAcronyms(normalizedText: base)
        if !extra.isEmpty {
            return "\(base) \(extra)"
        }
        return base
    }

    public static func buildNormalizedSearchIndex(normTitle: String, normCourse: String, description: String?) -> String {
        let normDesc = description?.normalizedForVietnameseSearch() ?? ""
        return buildNormalizedSearchIndex(normTitle: normTitle, normCourse: normCourse, normDescription: normDesc)
    }

    private static func buildTimeOnlyString(from dueDate: Date?) -> String {
        guard let dueDate else { return "--:--" }
        let hour = ClassroomDateFormatters.gregorianCalendar.component(.hour, from: dueDate)
        let minute = ClassroomDateFormatters.gregorianCalendar.component(.minute, from: dueDate)
        if hour == 23 && minute >= 55 {
            return "Cuối ngày"
        }
        let h1 = UInt8((hour / 10) + 48)
        let h2 = UInt8((hour % 10) + 48)
        let m1 = UInt8((minute / 10) + 48)
        let m2 = UInt8((minute % 10) + 48)
        return String(decoding: [h1, h2, UInt8(ascii: ":"), m1, m2], as: UTF8.self)
    }

    private static func buildFormattedFullDueDate(from dueDate: Date?) -> String {
        guard let dueDate else { return "Không có hạn nộp" }
        return ClassroomDateFormatters.fullDueDate.string(from: dueDate).capitalized
    }

    public static func buildConciseDueString(from dueDate: Date?) -> String {
        guard let dueDate else { return "Không có hạn" }
        let cal = ClassroomDateFormatters.gregorianCalendar
        let timeStr = ClassroomDateFormatters.timeOnly.string(from: dueDate)
        let dayOfWeek = cal.component(.weekday, from: dueDate)
        let dayStr: String
        switch dayOfWeek {
        case 1: dayStr = "CN"
        case 2: dayStr = "T2"
        case 3: dayStr = "T3"
        case 4: dayStr = "T4"
        case 5: dayStr = "T5"
        case 6: dayStr = "T6"
        case 7: dayStr = "T7"
        default: dayStr = ""
        }
        let day = cal.component(.day, from: dueDate)
        let month = cal.component(.month, from: dueDate)
        let year = cal.component(.year, from: dueDate)
        let currentYear = cal.component(.year, from: Date())
        if year != currentYear {
            return "\(timeStr) • \(dayStr), \(day)/\(month)/\(year)"
        }
        return "\(timeStr) • \(dayStr), \(day)/\(month)"
    }
}

// Single-pass LUT for Vietnamese Diacritics Normalization & Lowercasing
private let vietnameseLut1: [UInt8] = [
    97, 97, 97, 97, 97, 97, 0, 99, 101, 101, 101, 101, 105, 105, 105, 105, 0, 110, 111, 111, 111, 111, 111, 0, 0, 117, 117, 117, 117, 121, 0, 0, 97, 97, 97, 97, 97, 97, 0, 99, 101, 101, 101, 101, 105, 105, 105, 105, 0, 110, 111, 111, 111, 111, 111, 0, 0, 117, 117, 117, 117, 121, 0, 121, 97, 97, 97, 97, 97, 97, 99, 99, 99, 99, 99, 99, 99, 99, 100, 100, 100, 100, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 103, 103, 103, 103, 103, 103, 103, 103, 104, 104, 0, 0, 105, 105, 105, 105, 105, 105, 105, 105, 105, 0, 0, 0, 106, 106, 107, 107, 0, 108, 108, 108, 108, 108, 108, 0, 0, 0, 0, 110, 110, 110, 110, 110, 110, 0, 0, 0, 111, 111, 111, 111, 111, 111, 0, 0, 114, 114, 114, 114, 114, 114, 115, 115, 115, 115, 115, 115, 115, 115, 116, 116, 116, 116, 0, 0, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 119, 119, 121, 121, 121, 122, 122, 122, 122, 122, 122, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 111, 111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 117, 117
]

private let vietnameseLut2: [UInt8] = [
    97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 101, 105, 105, 105, 105, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 111, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 117, 121, 121, 121, 121, 121, 121, 121, 121
]

@inline(__always)
fileprivate func isSearchDelimiterByte(_ b: UInt8) -> Bool {
    return b <= 32 || b == 44 || b == 59 || b == 58 || b == 45 || b == 47 || b == 40 || b == 41 || b == 91 || b == 93 || b == 123 || b == 125 || b == 124 || b == 34 || b == 39 || b == 63 || b == 33 || b == 95
}

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
                        } else if v == 0x00A0 || v == 0x202F {
                            // Normalize non-breaking spaces to ASCII space
                            buffer[outIdx] = 32
                            outIdx += 1
                        } else if v == 0x200B || v == 0xFEFF {
                            // Drop zero-width spaces / BOM
                            continue
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

    func splitSearchTokens() -> [String] {
        guard !self.isEmpty else { return [] }

        return self.utf8.withContiguousStorageIfAvailable { buf -> [String] in
            let count = buf.count
            guard count > 0, let base = buf.baseAddress else { return [] }
            var tokens: [String] = []
            tokens.reserveCapacity(4)
            var start = -1
            for i in 0..<count {
                let b = base[i]
                if isSearchDelimiterByte(b) {
                    if start != -1 {
                        tokens.append(String(decoding: UnsafeBufferPointer(start: base + start, count: i - start), as: UTF8.self))
                        start = -1
                    }
                } else if start == -1 {
                    start = i
                }
            }
            if start != -1 {
                tokens.append(String(decoding: UnsafeBufferPointer(start: base + start, count: count - start), as: UTF8.self))
            }
            return tokens
        } ?? {
            var tokens: [String] = []
            tokens.reserveCapacity(4)
            var currentBytes: [UInt8] = []
            currentBytes.reserveCapacity(16)

            for b in self.utf8 {
                if isSearchDelimiterByte(b) {
                    if !currentBytes.isEmpty {
                        tokens.append(String(decoding: currentBytes, as: UTF8.self))
                        currentBytes.removeAll(keepingCapacity: true)
                    }
                } else {
                    currentBytes.append(b)
                }
            }
            if !currentBytes.isEmpty {
                tokens.append(String(decoding: currentBytes, as: UTF8.self))
            }
            return tokens
        }()
    }

    func searchQueryTokens() -> [String] {
        let cleanQuery = self.normalizedForVietnameseSearch()
        return cleanQuery.splitSearchTokens()
    }
}

public func cleanTelexKeystrokes(_ s: String) -> String {
    let count = s.utf8.count
    guard count >= 3 else { return s }

    return s.utf8.withContiguousStorageIfAvailable { buf -> String in
        guard let base = buf.baseAddress else { return s }
        var end = count
        let lastB = base[count - 1]
        if lastB == 115 || lastB == 102 || lastB == 114 || lastB == 120 || lastB == 106 { // 's', 'f', 'r', 'x', 'j'
            end -= 1
        }

        var hasDbl = false
        for i in 0..<end - 1 {
            let b1 = base[i]
            let b2 = base[i + 1]
            if (b1 == b2 && (b1 == 100 || b1 == 97 || b1 == 101 || b1 == 111)) || // dd, aa, ee, oo
               (b2 == 119 && (b1 == 117 || b1 == 111 || b1 == 97)) { // uw, ow, aw
                hasDbl = true
                break
            }
        }

        if !hasDbl {
            if end == count { return s }
            return String(decoding: UnsafeBufferPointer(start: base, count: end), as: UTF8.self)
        }

        return String(unsafeUninitializedCapacity: end) { outBuf in
            var outIdx = 0
            var i = 0
            while i < end {
                let b = base[i]
                if i + 1 < end {
                    let nextB = base[i + 1]
                    if (b == nextB && (b == 100 || b == 97 || b == 101 || b == 111)) ||
                       (nextB == 119 && (b == 117 || b == 111 || b == 97)) {
                        outBuf[outIdx] = b
                        outIdx += 1
                        i += 2
                        continue
                    }
                }
                outBuf[outIdx] = b
                outIdx += 1
                i += 1
            }
            return outIdx
        }
    } ?? s
}

public func expandVietnameseAcronyms(normalizedText: String) -> String {
    guard !normalizedText.isEmpty else { return "" }
    var expansions: [String] = []

    if normalizedText.contains("bai tap ve nha") { expansions.append("btvn") }
    if normalizedText.contains("kiem tra") { expansions.append("kt") }
    if normalizedText.contains("15 phut") { expansions.append("15p") }
    if normalizedText.contains("45 phut") { expansions.append("45p") }
    if normalizedText.contains("giua ki") || normalizedText.contains("giua ky") { expansions.append("gk") }
    if normalizedText.contains("cuoi ki") || normalizedText.contains("cuoi ky") { expansions.append("ck") }
    if normalizedText.contains("thuc hanh") { expansions.append("th") }
    if normalizedText.contains("chuyen de") { expansions.append("cd") }
    if normalizedText.contains("sach giao khoa") { expansions.append("sgk") }
    if normalizedText.contains("sach bai tap") { expansions.append("sbt") }

    let tokens = normalizedText.splitSearchTokens()
    for tok in tokens {
        switch tok {
        case "btvn": expansions.append("bai tap ve nha")
        case "kt": expansions.append("kiem tra")
        case "15p": expansions.append("15 phut")
        case "45p": expansions.append("45 phut")
        case "gk":
            expansions.append("giua ki")
            expansions.append("giua ky")
        case "ck":
            expansions.append("cuoi ki")
            expansions.append("cuoi ky")
        case "th": expansions.append("thuc hanh")
        case "cd": expansions.append("chuyen de")
        case "sgk": expansions.append("sach giao khoa")
        case "sbt": expansions.append("sach bai tap")
        default: break
        }
    }

    if expansions.isEmpty { return "" }
    return expansions.joined(separator: " ")
}

@inline(__always)
public func isSchoolAcronymMatch(queryOrToken: String, normTitle: String) -> Bool {
    guard !queryOrToken.isEmpty, !normTitle.isEmpty else { return false }
    switch queryOrToken {
    case "btvn": return normTitle.contains("bai tap ve nha")
    case "kt": return normTitle.contains("kiem tra")
    case "15p": return normTitle.contains("15 phut")
    case "45p": return normTitle.contains("45 phut")
    case "gk": return normTitle.contains("giua ki") || normTitle.contains("giua ky")
    case "ck": return normTitle.contains("cuoi ki") || normTitle.contains("cuoi ky")
    case "th": return normTitle.contains("thuc hanh")
    case "cd": return normTitle.contains("chuyen de")
    case "sgk": return normTitle.contains("sach giao khoa")
    case "sbt": return normTitle.contains("sach bai tap")
    case "bai tap ve nha":
        if let r = normTitle.range(of: "btvn") {
            let offset = normTitle.distance(from: normTitle.startIndex, to: r.lowerBound)
            return isWordInString(normTitle, offset: offset, len: 4)
        }
        return false
    case "kiem tra":
        if let r = normTitle.range(of: "kt") {
            let offset = normTitle.distance(from: normTitle.startIndex, to: r.lowerBound)
            return isWordInString(normTitle, offset: offset, len: 2)
        }
        return false
    case "15 phut":
        if let r = normTitle.range(of: "15p") {
            let offset = normTitle.distance(from: normTitle.startIndex, to: r.lowerBound)
            return isWordInString(normTitle, offset: offset, len: 3)
        }
        return false
    case "45 phut":
        if let r = normTitle.range(of: "45p") {
            let offset = normTitle.distance(from: normTitle.startIndex, to: r.lowerBound)
            return isWordInString(normTitle, offset: offset, len: 3)
        }
        return false
    default: return false
    }
}

@inline(__always)
fileprivate func isWordInString(_ s: String, offset: Int, len: Int) -> Bool {
    guard offset >= 0, offset + len <= s.utf8.count else { return false }
    return s.utf8.withContiguousStorageIfAvailable { buf in
        guard let base = buf.baseAddress else { return false }
        let leftOk = (offset == 0 || !((base[offset - 1] >= 97 && base[offset - 1] <= 122) || (base[offset - 1] >= 48 && base[offset - 1] <= 57)))
        let rightOk = (offset + len == buf.count || !((base[offset + len] >= 97 && base[offset + len] <= 122) || (base[offset + len] >= 48 && base[offset + len] <= 57)))
        return leftOk && rightOk
    } ?? {
        let utf8 = Array(s.utf8)
        let leftOk = (offset == 0 || !((utf8[offset - 1] >= 97 && utf8[offset - 1] <= 122) || (utf8[offset - 1] >= 48 && utf8[offset - 1] <= 57)))
        let rightOk = (offset + len == utf8.count || !((utf8[offset + len] >= 97 && utf8[offset + len] <= 122) || (utf8[offset + len] >= 48 && utf8[offset + len] <= 57)))
        return leftOk && rightOk
    }()
}

public struct FastSearchBuffer {
    let ptr: UnsafePointer<UInt8>
    let count: Int

    @inline(__always)
    func find(_ sub: FastSearchBuffer) -> Int {
        let sCount = sub.count
        guard sCount <= count, sCount > 0 else { return -1 }
        if sCount == 1 {
            if let p = memchr(ptr, Int32(sub.ptr.pointee), count) {
                return UnsafeRawPointer(p) - UnsafeRawPointer(ptr)
            }
            return -1
        }
        if let p = memmem(ptr, count, sub.ptr, sCount) {
            return UnsafeRawPointer(p) - UnsafeRawPointer(ptr)
        }
        return -1
    }

    @inline(__always)
    private static func isWordBoundaryByte(_ b: UInt8) -> Bool {
        // Alphanumeric ASCII in normalized text are 'a'...'z' (97...122) and '0'...'9' (48...57).
        // Any other character (space, tab, newline, bracket, dash, colon, punctuation, etc.) is a word boundary.
        return !((b >= 97 && b <= 122) || (b >= 48 && b <= 57))
    }

    @inline(__always)
    func isWordAt(offset: Int, len: Int) -> Bool {
        guard offset >= 0, offset + len <= count else { return false }
        let leftOk = (offset == 0 || Self.isWordBoundaryByte(ptr[offset - 1]))
        let rightOk = (offset + len == count || Self.isWordBoundaryByte(ptr[offset + len]))
        return leftOk && rightOk
    }

    @inline(__always)
    func findWordBoundary(_ sub: FastSearchBuffer, firstMatchOffset: Int) -> Bool {
        let subLen = sub.count
        if isWordAt(offset: firstMatchOffset, len: subLen) {
            return true
        }
        var nextOffset = firstMatchOffset + 1
        var remaining = count - nextOffset
        while remaining >= subLen {
            if let p = memmem(ptr + nextOffset, remaining, sub.ptr, subLen) {
                let matchOffset = UnsafeRawPointer(p) - UnsafeRawPointer(ptr)
                if isWordAt(offset: matchOffset, len: subLen) {
                    return true
                }
                nextOffset = matchOffset + 1
                remaining = count - nextOffset
            } else {
                break
            }
        }
        return false
    }

    @inline(__always)
    func equals(_ other: FastSearchBuffer) -> Bool {
        return count == other.count && (count == 0 || memcmp(ptr, other.ptr, count) == 0)
    }

    @inline(__always)
    func hasPrefix(_ other: FastSearchBuffer) -> Bool {
        return count >= other.count && (other.count == 0 || memcmp(ptr, other.ptr, other.count) == 0)
    }
}

public enum VietnameseSearchScorer {
    private static func scoreWithBuffers(
        tBuf: FastSearchBuffer,
        cBuf: FastSearchBuffer,
        dBuf: FastSearchBuffer,
        qBuf: FastSearchBuffer,
        tokens: [String],
        rawNormalizedQuery: String,
        normTitle: String,
        checklistTitles: [String]
    ) -> Int {
        var score = 0
        let rawQueryLen = qBuf.count
        var titleFirstMatchOffset = -1
        var courseMatched = false

        if rawQueryLen > 0 {
            if tBuf.equals(qBuf) {
                score += 200
                titleFirstMatchOffset = 0
            } else if tBuf.hasPrefix(qBuf) {
                score += 120
                titleFirstMatchOffset = 0
            } else if tBuf.count >= rawQueryLen {
                let idx = tBuf.find(qBuf)
                if idx >= 0 {
                    score += 80
                    titleFirstMatchOffset = idx
                }
            }

            if cBuf.equals(qBuf) {
                score += 100
                courseMatched = true
            } else if cBuf.hasPrefix(qBuf) {
                score += 60
                courseMatched = true
            } else if cBuf.count >= rawQueryLen && cBuf.find(qBuf) >= 0 {
                score += 40
                courseMatched = true
            }

            if isSchoolAcronymMatch(queryOrToken: rawNormalizedQuery, normTitle: normTitle) {
                score += 70
            }
        }

        if tokens.count == 1 && rawQueryLen > 0 && tokens[0] == rawNormalizedQuery {
            if titleFirstMatchOffset >= 0 {
                score += 30
                if tBuf.findWordBoundary(qBuf, firstMatchOffset: titleFirstMatchOffset) {
                    score += 15
                }
            }
            if courseMatched {
                score += 15
            }
            if dBuf.count >= rawQueryLen && dBuf.find(qBuf) >= 0 {
                score += 5
            }

            if titleFirstMatchOffset < 0 && !courseMatched {
                let altTok = cleanTelexKeystrokes(rawNormalizedQuery)
                if altTok != rawNormalizedQuery {
                    altTok.withCString { tokPtr in
                        let altBuf = FastSearchBuffer(ptr: UnsafeRawPointer(tokPtr).assumingMemoryBound(to: UInt8.self), count: altTok.utf8.count)
                        let altLen = altBuf.count
                        if altLen > 0 {
                            if tBuf.count >= altLen {
                                let matchIdx = tBuf.find(altBuf)
                                if matchIdx >= 0 {
                                    score += 20
                                    if tBuf.findWordBoundary(altBuf, firstMatchOffset: matchIdx) {
                                        score += 10
                                    }
                                }
                            }
                            if cBuf.count >= altLen && cBuf.find(altBuf) >= 0 {
                                score += 10
                            }
                            if dBuf.count >= altLen && dBuf.find(altBuf) >= 0 {
                                score += 4
                            }
                        }
                    }
                }
            }

            if !checklistTitles.isEmpty {
                for rawTitle in checklistTitles {
                    let normItem = rawTitle.normalizedForVietnameseSearch()
                    _ = normItem.utf8.withContiguousStorageIfAvailable { itemBuf in
                        guard let base = itemBuf.baseAddress, itemBuf.count >= rawQueryLen else { return }
                        let iBuf = FastSearchBuffer(ptr: base, count: itemBuf.count)
                        if iBuf.find(qBuf) >= 0 {
                            score += 5
                        }
                    }
                }
            }
            return score
        }

        var allMatchedTitle = true
        var allMatchedEither = true

        for token in tokens {
            var matchedTitle = false
            var matchedCourse = false

            token.withCString { tokPtr in
                let tkBuf = FastSearchBuffer(ptr: UnsafeRawPointer(tokPtr).assumingMemoryBound(to: UInt8.self), count: token.utf8.count)
                let tokenLen = tkBuf.count
                if tokenLen == 0 { return }
                if tBuf.count >= tokenLen {
                    let matchIdx = tBuf.find(tkBuf)
                    if matchIdx >= 0 {
                        score += 30
                        matchedTitle = true
                        if tBuf.findWordBoundary(tkBuf, firstMatchOffset: matchIdx) {
                            score += 15
                        }
                    }
                }
                if cBuf.count >= tokenLen && cBuf.find(tkBuf) >= 0 {
                    score += 15
                    matchedCourse = true
                }
                if dBuf.count >= tokenLen && dBuf.find(tkBuf) >= 0 {
                    score += 5
                }
            }

            if !matchedTitle && !matchedCourse {
                let altTok = cleanTelexKeystrokes(token)
                if altTok != token {
                    altTok.withCString { tokPtr in
                        let tkBuf = FastSearchBuffer(ptr: UnsafeRawPointer(tokPtr).assumingMemoryBound(to: UInt8.self), count: altTok.utf8.count)
                        let tokenLen = tkBuf.count
                        if tokenLen > 0 {
                            if tBuf.count >= tokenLen {
                                let matchIdx = tBuf.find(tkBuf)
                                if matchIdx >= 0 {
                                    score += 20
                                    matchedTitle = true
                                    if tBuf.findWordBoundary(tkBuf, firstMatchOffset: matchIdx) {
                                        score += 10
                                    }
                                }
                            }
                            if cBuf.count >= tokenLen && cBuf.find(tkBuf) >= 0 {
                                score += 10
                                matchedCourse = true
                            }
                        }
                    }
                }
            }

            if isSchoolAcronymMatch(queryOrToken: token, normTitle: normTitle) {
                score += 35
                matchedTitle = true
            }

            if !matchedTitle { allMatchedTitle = false }
            if !matchedTitle && !matchedCourse { allMatchedEither = false }
        }

        if tokens.count > 1 {
            if allMatchedTitle {
                score += 50
            } else if allMatchedEither {
                score += 25
            }
        }

        if !checklistTitles.isEmpty {
            for rawTitle in checklistTitles {
                let normItem = rawTitle.normalizedForVietnameseSearch()
                normItem.withCString { itemPtr in
                    let iBuf = FastSearchBuffer(ptr: UnsafeRawPointer(itemPtr).assumingMemoryBound(to: UInt8.self), count: normItem.utf8.count)
                    let normItemLen = iBuf.count
                    if rawQueryLen > 0 && normItemLen >= rawQueryLen {
                        if iBuf.equals(qBuf) {
                            score += 60
                        } else if iBuf.find(qBuf) >= 0 {
                            score += 30
                        }
                    }
                    for token in tokens {
                        token.withCString { tokPtr in
                            let tkBuf = FastSearchBuffer(ptr: UnsafeRawPointer(tokPtr).assumingMemoryBound(to: UInt8.self), count: token.utf8.count)
                            let tokenLen = tkBuf.count
                            if tokenLen > 0 && normItemLen >= tokenLen && iBuf.find(tkBuf) >= 0 {
                                score += 8
                            }
                        }
                    }
                }
            }
        }

        return score
    }

    public static func calculateScore(
        tokens: [String],
        rawNormalizedQuery: String,
        normTitle: String,
        normCourse: String,
        normContentOrDesc: String,
        checklistTitles: [String] = []
    ) -> Int {
        guard !tokens.isEmpty else { return 0 }

        return normTitle.withCString { tPtr in
            normCourse.withCString { cPtr in
                normContentOrDesc.withCString { dPtr in
                    rawNormalizedQuery.withCString { qPtr in
                        let tBuf = FastSearchBuffer(ptr: UnsafeRawPointer(tPtr).assumingMemoryBound(to: UInt8.self), count: normTitle.utf8.count)
                        let cBuf = FastSearchBuffer(ptr: UnsafeRawPointer(cPtr).assumingMemoryBound(to: UInt8.self), count: normCourse.utf8.count)
                        let dBuf = FastSearchBuffer(ptr: UnsafeRawPointer(dPtr).assumingMemoryBound(to: UInt8.self), count: normContentOrDesc.utf8.count)
                        let qBuf = FastSearchBuffer(ptr: UnsafeRawPointer(qPtr).assumingMemoryBound(to: UInt8.self), count: rawNormalizedQuery.utf8.count)

                        return scoreWithBuffers(
                            tBuf: tBuf,
                            cBuf: cBuf,
                            dBuf: dBuf,
                            qBuf: qBuf,
                            tokens: tokens,
                            rawNormalizedQuery: rawNormalizedQuery,
                            normTitle: normTitle,
                            checklistTitles: checklistTitles
                        )
                    }
                }
            }
        }
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
            if first.normalizedTitle != second.normalizedTitle {
                return first.normalizedTitle < second.normalizedTitle
            }
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
            if first.normalizedTitle != second.normalizedTitle {
                return first.normalizedTitle < second.normalizedTitle
            }
            let titleOrder = first.title.localizedStandardCompare(second.title)
            if titleOrder != .orderedSame {
                return titleOrder == .orderedAscending
            }
            return first.id < second.id
        }
    }

    public static func compareByDueDateAscending(_ first: Coursework, _ second: Coursework) -> Bool {
        switch (first.dueDate, second.dueDate) {
        case let (d1?, d2?):
            if d1 != d2 { return d1 < d2 }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }
        let titleOrder = first.title.localizedStandardCompare(second.title)
        if titleOrder != .orderedSame {
            return titleOrder == .orderedAscending
        }
        return first.id < second.id
    }

    public static func compareByDueDateDescending(_ first: Coursework, _ second: Coursework) -> Bool {
        switch (first.dueDate, second.dueDate) {
        case let (d1?, d2?):
            if d1 != d2 { return d1 > d2 }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }
        let titleOrder = first.title.localizedStandardCompare(second.title)
        if titleOrder != .orderedSame {
            return titleOrder == .orderedAscending
        }
        return first.id < second.id
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
        if nowTimestamp >= cachedStartOfTodayTimestamp && nowTimestamp < cacheExpirationTimestamp {
            return
        }
        boundaryLock.lock()
        defer { boundaryLock.unlock() }
        if nowTimestamp >= cachedStartOfTodayTimestamp && nowTimestamp < cacheExpirationTimestamp {
            return
        }
        let currentTzId = TimeZone.autoupdatingCurrent.identifier
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
