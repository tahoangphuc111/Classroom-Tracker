import Foundation

public struct PersonalNote: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var courseworkId: String?
    public var courseId: String?
    public var courseName: String?
    public var title: String
    public var content: String
    public var dueDate: Date?
    public var isCompleted: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public var searchIndex: String

    private enum CodingKeys: String, CodingKey {
        case id, courseworkId, courseId, courseName, title, content, dueDate, isCompleted, createdAt, updatedAt
    }

    public init(
        id: String = UUID().uuidString,
        courseworkId: String? = nil,
        courseId: String? = nil,
        courseName: String? = nil,
        title: String,
        content: String = "",
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
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.searchIndex = "\(title) \(content) \(courseName ?? "")".normalizedForVietnameseSearch()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.courseworkId = try container.decodeIfPresent(String.self, forKey: .courseworkId)
        self.courseId = try container.decodeIfPresent(String.self, forKey: .courseId)
        self.courseName = try container.decodeIfPresent(String.self, forKey: .courseName)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
        self.searchIndex = "\(title) \(content) \(courseName ?? "")".normalizedForVietnameseSearch()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(courseworkId, forKey: .courseworkId)
        try container.encodeIfPresent(courseId, forKey: .courseId)
        try container.encodeIfPresent(courseName, forKey: .courseName)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    public var isDueTomorrow: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }

    public var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
}
