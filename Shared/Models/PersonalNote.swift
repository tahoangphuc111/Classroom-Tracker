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

    public var searchIndex: String {
        let checklistText = checklist.map(\.title).joined(separator: " ")
        return "\(title) \(content) \(courseName ?? "") \(checklistText)".normalizedForVietnameseSearch()
    }

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
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.courseworkId = try container.decodeIfPresent(String.self, forKey: .courseworkId)
        self.courseId = try container.decodeIfPresent(String.self, forKey: .courseId)
        self.courseName = try container.decodeIfPresent(String.self, forKey: .courseName)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.checklist = (try? container.decode([ChecklistItem].self, forKey: .checklist)) ?? []
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
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
        return Calendar.current.isDateInTomorrow(dueDate)
    }

    public var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    /// Computes search relevance score based on title, course name, and content.
    public func searchRelevanceScore(for tokens: [String], rawNormalizedQuery: String) -> Int {
        guard !tokens.isEmpty else { return 0 }
        let normTitle = title.normalizedForVietnameseSearch()
        let normCourse = (courseName?.isEmpty ?? true) ? "" : courseName!.normalizedForVietnameseSearch()
        let normContent = content.isEmpty ? "" : content.normalizedForVietnameseSearch()

        var score = 0
        if normTitle == rawNormalizedQuery {
            score += 200
        } else if normTitle.hasPrefix(rawNormalizedQuery) {
            score += 120
        } else if normTitle.contains(rawNormalizedQuery) {
            score += 80
        }

        if normCourse == rawNormalizedQuery {
            score += 100
        } else if normCourse.hasPrefix(rawNormalizedQuery) {
            score += 60
        } else if normCourse.contains(rawNormalizedQuery) {
            score += 40
        }

        for token in tokens {
            if normTitle.contains(token) {
                score += 30
                if normTitle.hasPrefix(token) || normTitle.contains(" \(token)") {
                    score += 15
                }
            }
            if normCourse.contains(token) {
                score += 15
            }
            if normContent.contains(token) {
                score += 5
            }
        }

        for item in checklist {
            let normItem = item.title.normalizedForVietnameseSearch()
            if normItem == rawNormalizedQuery {
                score += 60
            } else if normItem.contains(rawNormalizedQuery) {
                score += 30
            }
            for token in tokens {
                if normItem.contains(token) {
                    score += 8
                }
            }
        }
        return score
    }
}
