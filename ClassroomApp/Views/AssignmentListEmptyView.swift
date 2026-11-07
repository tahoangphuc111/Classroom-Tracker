import SwiftUI

struct GuideStepRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color(red: 0.10, green: 0.45, blue: 0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.platformTextPrimary)
        }
    }
}

struct AssignmentListEmptyView: View {
    let filter: ContentView.AppFilterCategory
    let isSearching: Bool
    let searchText: String
    let onClearSearch: () -> Void
    var onSwitchToUpcoming: (() -> Void)? = nil

    @State private var hasAppeared: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if !isSearching && (filter == .tomorrow || filter == .todayAndTomorrow) {
                #if os(macOS)
                let emptyImg = NSImage(named: "EmptyAllCaughtUp")
                #else
                let emptyImg = UIImage(named: "EmptyAllCaughtUp")
                #endif
                if emptyImg != nil {
                    Image("EmptyAllCaughtUp")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.bottom, 2)
                } else {
                    FloatingEmberView(emotion: .sleeping, size: 76)
                        .padding(.bottom, 2)
                }
            } else if !isSearching && filter == .past {
                FloatingEmberView(emotion: .celebrating, size: 76)
                    .padding(.bottom, 2)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [emptyTint.opacity(0.18), emptyTint.opacity(0.0)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 54
                            )
                        )
                        .frame(width: 92, height: 92)

                    if #available(macOS 14.0, iOS 17.0, *) {
                        Image(systemName: emptyIcon)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(emptyTint)
                            .symbolEffect(.bounce, value: hasAppeared)
                    } else {
                        Image(systemName: emptyIcon)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(emptyTint)
                    }
                }
            }

            VStack(spacing: 6) {
                Text(emptyTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.platformTextPrimary)

                Text(emptySubtitle)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.platformTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .lineSpacing(3.5)
            }

            if isSearching {
                Button("Xóa tìm kiếm") {
                    onClearSearch()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.blue)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(Color.blue.opacity(0.10))
                )
                .overlay(
                    Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1)
                )
                .padding(.top, 4)
            } else if (filter == .tomorrow || filter == .todayAndTomorrow), let onSwitchToUpcoming {
                Button {
                    onSwitchToUpcoming()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "tray")
                            .font(.system(size: 12))
                        Text("Xem tất cả bài tập sắp tới")
                            .font(.system(size: 13.5, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.blue)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(Color.blue.opacity(0.10))
                )
                .overlay(
                    Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1)
                )
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .scaleEffect(hasAppeared ? 1.0 : 0.94)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                hasAppeared = true
            }
        }
    }

    private var emptyIcon: String {
        if isSearching { return "magnifyingglass" }
        switch filter {
        case .tomorrow: return "calendar.badge.checkmark"
        case .todayAndTomorrow: return "sun.max"
        case .allUpcoming: return "tray"
        case .past: return "checkmark.seal.fill"
        case .completed: return "doc.text.magnifyingglass"
        case .notes: return "square.and.pencil"
        case .widgetPreview: return "macwindow"
        }
    }

    private var emptyTint: Color {
        if isSearching { return .blue }
        switch filter {
        case .tomorrow: return Color(red: 0.15, green: 0.65, blue: 0.45)
        case .todayAndTomorrow: return .orange
        case .allUpcoming: return .blue
        case .past: return .green
        case .completed: return .secondary
        case .notes: return .orange
        case .widgetPreview: return .purple
        }
    }

    private var emptyTitle: String {
        if isSearching { return "Không tìm thấy bài tập nào" }
        switch filter {
        case .tomorrow: return "Ngày mai không có bài tập"
        case .todayAndTomorrow: return "Không có bài tập hôm nay & mai"
        case .allUpcoming: return "Không có bài tập sắp tới"
        case .past: return "Không có bài tập quá hạn"
        case .completed: return "Chưa có bài tập hoàn thành"
        case .notes: return "Chưa có ghi chú nào"
        case .widgetPreview: return "Xem trước Widget"
        }
    }

    private var emptySubtitle: String {
        if isSearching {
            return "Không có bài tập nào khớp với từ khóa \"\(searchText)\"."
        }
        switch filter {
        case .tomorrow:
            return "Tất cả bài tập ngày mai đã hoàn thành hoặc chưa có bài mới."
        case .todayAndTomorrow:
            return "Tất cả bài tập cần nộp hôm nay và ngày mai đều đã hoàn thành."
        case .allUpcoming:
            return "Hiện không có bài tập nào trong danh sách theo dõi."
        case .past:
            return "Không có bài tập nào bị quá hạn."
        case .completed:
            return "Các bài tập bạn đã nộp hoặc đánh dấu hoàn thành sẽ xuất hiện tại đây."
        case .notes:
            return "Các ghi chú cá nhân của bạn sẽ hiển thị tại đây."
        case .widgetPreview:
            return "Kéo thả widget ra màn hình chính để theo dõi nhanh bài tập."
        }
    }
}
