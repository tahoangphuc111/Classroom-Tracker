import WidgetKit
import SwiftUI

struct ClassroomWidgetEntryView: View {
    var entry: ClassroomTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    var body: some View {
        Group {
            switch entry.state {
            case .needsSync, .storageUnavailable:
                syncStatusView
            case .signedOut, .ready:
                let isLoggedIn = entry.state == .ready
                switch family {
                case .systemMedium:
                    MediumWidgetView(courseworkList: entry.courseworkList, isLoggedIn: isLoggedIn)
                case .systemLarge:
                    LargeWidgetView(courseworkList: entry.courseworkList, isLoggedIn: isLoggedIn)
                default:
                    SmallWidgetView(courseworkList: entry.courseworkList, isLoggedIn: isLoggedIn)
                }
            }
        }
        .environment(\.colorScheme, .light)
        .containerBackground(for: .widget) {
            ChunkyTheme.skyGradient
        }
    }

    private var syncStatusView: some View {
        let storageUnavailable = entry.state == .storageUnavailable
        return VStack(spacing: 6) {
            Image(systemName: storageUnavailable ? "exclamationmark.circle" : "arrow.triangle.2.circlepath")
                .font(.title2)
            Text(storageUnavailable ? "Không đọc được dữ liệu chung" : "Chạm để đồng bộ")
                .font(WidgetFontSystem.sectionHeader(size: 13))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(ChunkyTheme.textMuted)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "classroomwidget://sync"))
    }
}

public struct ClassroomWidget: Widget {
    #if os(iOS) || CLASSROOM_TESTING
    public let kind: String = ClassroomStorage.widgetKind
    #else
    public let kind: String = "ClassroomWidget"
    #endif

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
