import SwiftUI
import WidgetKit

public struct SmallWidgetView: View {
    let courseworkList: [Coursework]

    public init(courseworkList: [Coursework]) {
        self.courseworkList = courseworkList
    }

    private var todayItems: [Coursework] {
        courseworkList.filter { $0.isDueToday }
    }

    private var tomorrowItems: [Coursework] {
        courseworkList.filter { $0.isDueTomorrow }
    }

    private var primaryItem: Coursework? {
        todayItems.first ?? tomorrowItems.first
    }

    private var headerTitle: String {
        if primaryItem?.isDueToday == true {
            return "Hôm nay cần nộp"
        } else if primaryItem?.isDueTomorrow == true {
            return "Báo bài Ngày mai"
        } else {
            return "Báo bài"
        }
    }

    private var remainingCount: Int {
        max(0, courseworkList.count - 1)
    }

    public var body: some View {
        ZStack {
            WidgetAppleGlassBackground(cornerRadius: 20)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    HStack(spacing: 4.5) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(primaryItem?.isDueToday == true ? Color(red: 1.0, green: 0.55, blue: 0.20) : Color(red: 0.22, green: 0.95, blue: 0.95))
                        Text(headerTitle)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 4)

                    if remainingCount > 0 {
                        Text("+\(remainingCount)")
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.95))
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 1.5)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 6)

                if let item = primaryItem {
                    Spacer(minLength: 2)

                    HStack(spacing: 4.5) {
                        SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 14)
                        Text(item.courseName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 3)

                    Text(item.title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .lineSpacing(1.5)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 4)

                    HStack(spacing: 4.5) {
                        HStack(spacing: 3.5) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                            Text(item.compactDueString)
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .padding(.horizontal, 6.5)
                        .padding(.vertical, 3.5)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Capsule())

                        Spacer(minLength: 2)

                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 8))
                            Text("Cần nộp")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3.5)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Capsule())
                    }
                } else {
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)

                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.70))
                        }

                        Text("Thảnh thơi!")
                            .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Không có bài tập nào ✦")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
