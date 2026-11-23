import SwiftUI

struct TomorrowProgressHeroCard: View {
    let totalCount: Int
    let completedCount: Int
    let hasTomorrowTasks: Bool
    let hasTodayTasks: Bool
    let shareText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text("Đã xong \(completedCount)/\(totalCount) mục")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.platformTextSecondary)
                }

                Spacer()

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .accessibilityLabel("Chia sẻ báo bài")
            }

            ProgressView(value: Double(completedCount), total: Double(max(1, totalCount)))
                .tint(.blue)
                .accessibilityLabel("Tiến độ Báo bài")
        }
        .padding(12)
        .background(Color.platformControlBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private var title: String {
        if hasTomorrowTasks { return "Báo bài ngày mai" }
        if hasTodayTasks { return "Báo bài hôm nay" }
        return "Báo bài sắp tới"
    }
}
