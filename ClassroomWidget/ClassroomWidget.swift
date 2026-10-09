import WidgetKit
import SwiftUI

struct ClassroomWidgetEntryView: View {
    var entry: ClassroomTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(courseworkList: entry.courseworkList, isLoggedIn: entry.isLoggedIn)
            case .systemMedium:
                MediumWidgetView(courseworkList: entry.courseworkList, isLoggedIn: entry.isLoggedIn)
            case .systemLarge:
                LargeWidgetView(courseworkList: entry.courseworkList, isLoggedIn: entry.isLoggedIn)
            default:
                SmallWidgetView(courseworkList: entry.courseworkList, isLoggedIn: entry.isLoggedIn)
            }
        }
        .environment(\.colorScheme, .light)
        .containerBackground(for: .widget) {
            ChunkyTheme.skyGradient
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
        .configurationDisplayName("Báo bài Ngày mai")
        .description("Theo dõi danh sách môn học và bài tập cần chuẩn bị cho ngày mai.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
