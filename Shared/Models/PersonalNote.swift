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
        VietnameseSearchScorer.calculateScore(
            tokens: tokens,
            rawNormalizedQuery: rawNormalizedQuery,
            normTitle: normalizedTitle,
            normCourse: normalizedCourseName,
            normContentOrDesc: normalizedContent,
            checklistTitles: checklist.map(\.title)
        )
    }
}
