import WidgetKit
import SwiftUI

struct ClassroomWidgetEntryView: View {
    var entry: ClassroomTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(courseworkList: entry.courseworkList)
            case .systemMedium:
                MediumWidgetView(courseworkList: entry.courseworkList)
            case .systemLarge:
                LargeWidgetView(courseworkList: entry.courseworkList)
            default:
                SmallWidgetView(courseworkList: entry.courseworkList)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

public struct ClassroomWidget: Widget {
    public let kind: String = "ClassroomWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClassroomTimelineProvider()) { entry in
            ClassroomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Classroom Hôm nay & Ngày mai")
        .description("Theo dõi bài tập Google Classroom đến hạn hôm nay và ngày mai.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
