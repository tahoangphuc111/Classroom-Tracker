import Foundation

public struct Course: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let section: String?
    public let descriptionHeading: String?
    public let room: String?
    public let alternateLink: String?
    public var isSelectedForWidget: Bool

    public init(
        id: String,
        name: String,
        section: String? = nil,
        descriptionHeading: String? = nil,
        room: String? = nil,
        alternateLink: String? = nil,
        isSelectedForWidget: Bool = true
    ) {
        self.id = id
        self.name = name
        self.section = section
        self.descriptionHeading = descriptionHeading
        self.room = room
        self.alternateLink = alternateLink
        self.isSelectedForWidget = isSelectedForWidget
    }
}
