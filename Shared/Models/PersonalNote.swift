import Foundation

public struct ChecklistItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var isCompleted: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

public struct PersonalNote: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var courseworkId: String?
    public var courseId: String?
    public var courseName: String?
    public var title: String
    public var content: String
    public var checklist: [ChecklistItem]
    public var dueDate: Date?
    public var isCompleted: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public let searchIndex: String
    public let normalizedTitle: String
    public let normalizedCourseName: String
    public let normalizedContent: String

    private enum CodingKeys: String, CodingKey {
        case id, courseworkId, courseId, courseName, title, content, checklist, dueDate, isCompleted, createdAt, updatedAt
    }

    public init(
        id: String = UUID().uuidString,
        courseworkId: String? = nil,
        courseId: String? = nil,
        courseName: String? = nil,
        title: String,
        content: String = "",
        checklist: [ChecklistItem] = [],
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.courseworkId = courseworkId
        self.courseId = courseId
        self.courseName = courseName
        self.title = title
        self.content = content
        self.checklist = checklist
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        let normTitle = title.normalizedForVietnameseSearch()
        let normCourse = (courseName?.isEmpty ?? true) ? "" : courseName!.normalizedForVietnameseSearch()
        let normContent = content.isEmpty ? "" : content.normalizedForVietnameseSearch()
        self.normalizedTitle = normTitle
        self.normalizedCourseName = normCourse
        self.normalizedContent = normContent
        self.searchIndex = Self.buildSearchIndex(normTitle: normTitle, normCourse: normCourse, normContent: normContent, checklist: checklist)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.courseworkId = try container.decodeIfPresent(String.self, forKey: .courseworkId)
        self.courseId = try container.decodeIfPresent(String.self, forKey: .courseId)
        self.courseName = try container.decodeIfPresent(String.self, forKey: .courseName)
        let title = try container.decode(String.self, forKey: .title)
        self.title = title
        let content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.content = content
        let checklist = (try? container.decode([ChecklistItem].self, forKey: .checklist)) ?? []
        self.checklist = checklist
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()

        let normTitle = title.normalizedForVietnameseSearch()
        let normCourse = (self.courseName?.isEmpty ?? true) ? "" : self.courseName!.normalizedForVietnameseSearch()
        let normContent = content.isEmpty ? "" : content.normalizedForVietnameseSearch()
        self.normalizedTitle = normTitle
        self.normalizedCourseName = normCourse
        self.normalizedContent = normContent
        self.searchIndex = Self.buildSearchIndex(normTitle: normTitle, normCourse: normCourse, normContent: normContent, checklist: checklist)
    }

    private static func buildSearchIndex(normTitle: String, normCourse: String, normContent: String, checklist: [ChecklistItem]) -> String {
        if checklist.isEmpty {
            return "\(normTitle) \(normContent) \(normCourse)"
        }
        let checklistText = checklist.map(\.title).joined(separator: " ").normalizedForVietnameseSearch()
        return "\(normTitle) \(normContent) \(normCourse) \(checklistText)"
    }

    private static func buildSearchIndex(normTitle: String, normCourse: String, content: String, checklist: [ChecklistItem]) -> String {
        let normContent = content.isEmpty ? "" : content.normalizedForVietnameseSearch()
        return buildSearchIndex(normTitle: normTitle, normCourse: normCourse, normContent: normContent, checklist: checklist)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(courseworkId, forKey: .courseworkId)
        try container.encodeIfPresent(courseId, forKey: .courseId)
        try container.encodeIfPresent(courseName, forKey: .courseName)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(checklist, forKey: .checklist)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    public var completedChecklistCount: Int {
        checklist.filter(\.isCompleted).count
    }

    public var totalChecklistCount: Int {
        checklist.count
    }

    public var hasChecklist: Bool {
        !checklist.isEmpty
    }

    public var checklistProgress: Double {
        checklist.isEmpty ? 0 : Double(completedChecklistCount) / Double(totalChecklistCount)
    }

    public var isDueTomorrow: Bool {
        guard let dueDate else { return false }
        let t = dueDate.timeIntervalSinceReferenceDate
        return t >= ClassroomDateFormatters.startOfTomorrowTimestamp && t < ClassroomDateFormatters.startOfDayAfterTimestamp
    }

    public var isDueToday: Bool {
        guard let dueDate else { return false }
        let t = dueDate.timeIntervalSinceReferenceDate
        return t >= ClassroomDateFormatters.startOfTodayTimestamp && t < ClassroomDateFormatters.startOfTomorrowTimestamp
    }

    public func searchRelevanceScore(for tokens: [String], rawNormalizedQuery: String) -> Int {
        guard !tokens.isEmpty else { return 0 }
        let normTitle = self.normalizedTitle
        let normCourse = self.normalizedCourseName
        let normContent = self.normalizedContent

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
            if !normContent.isEmpty && normContent.utf8.count >= rawQueryLen && normContent.range(of: token, options: .literal) != nil {
                score += 5
            }
            if !checklist.isEmpty {
                for item in checklist {
                    let normItem = item.title.normalizedForVietnameseSearch()
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
            if !normContent.isEmpty && normContent.utf8.count >= tokenLen && normContent.range(of: token, options: .literal) != nil {
                score += 5
            }
        }

        if !checklist.isEmpty {
            for item in checklist {
                let normItem = item.title.normalizedForVietnameseSearch()
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
