import SwiftUI

struct AssignmentListEmptyView: View {
    let filter: ContentView.AppFilterCategory
    let isSearching: Bool
    let onClearSearch: () -> Void
    let onSwitchToUpcoming: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isSearching ? "magnifyingglass" : filter.icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.platformTextSecondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            if isSearching {
                Button("Xóa bộ lọc", action: onClearSearch)
                    .buttonStyle(.bordered)
            } else if filter == .tomorrow {
                Button("Xem bài tập sắp tới", action: onSwitchToUpcoming)
                    .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var title: String {
        if isSearching { return "Không tìm thấy bài tập" }
        switch filter {
        case .tomorrow: return "Ngày mai không có bài tập"
        case .allUpcoming: return "Không có bài tập sắp tới"
        case .completed: return "Chưa có bài tập hoàn thành"
        case .notes: return "Chưa có ghi chú"
        }
    }
}
