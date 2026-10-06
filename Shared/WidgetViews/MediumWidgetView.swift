import SwiftUI
import WidgetKit

public struct MediumWidgetView: View {
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

    private var displayItems: [Coursework] {
        Array(courseworkList.prefix(2))
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

    private var totalPendingCount: Int {
        courseworkList.count
    }

    public var body: some View {
        ZStack {
            WidgetAppleGlassBackground(cornerRadius: 20)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    HStack(spacing: 5) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(primaryItem?.isDueToday == true ? Color(red: 1.0, green: 0.55, blue: 0.20) : Color(red: 0.22, green: 0.95, blue: 0.95))

                        Text(headerTitle)
                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    if totalPendingCount > 0 {
                        Text("\(totalPendingCount) bài cần nộp")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.95))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                    } else {
                        Text("Thảnh thơi")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.70))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2.5)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 6)

                if displayItems.isEmpty {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.70))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Thảnh thơi!")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Không có bài tập nào cần nộp ✦")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                } else if displayItems.count == 1, let item = displayItems.first {
                    Spacer(minLength: 2)

                    Link(destination: URL(string: item.alternateLink ?? "https://classroom.google.com")!) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .center, spacing: 6) {
                                SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 16)

                                Text(item.courseName)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                    .lineLimit(1)

                                Spacer(minLength: 6)

                                HStack(spacing: 3.5) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 8.5))
                                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                    Text(item.friendlyDueString)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 7.5)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.25))
                                .clipShape(Capsule())

                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 8.5))
                                    Text("Cần nộp")
                                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.25))
                                .clipShape(Capsule())
                            }

                            Text(item.title)
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .lineSpacing(2)
                                .minimumScaleFactor(0.88)
                        }
                        .padding(11)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 2)
                } else {
                    VStack(spacing: 6) {
                        ForEach(displayItems) { item in
                            Link(destination: URL(string: item.alternateLink ?? "https://classroom.google.com")!) {
                                HStack(alignment: .center, spacing: 9) {
                                    SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 20)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(alignment: .center, spacing: 5) {
                                            Text(item.courseName)
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                                .lineLimit(1)

                                            Spacer(minLength: 4)

                                            HStack(spacing: 3.5) {
                                                Image(systemName: "clock.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                                Text(item.compactDueString)
                                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.white)
                                                    .lineLimit(1)
                                            }
                                            .padding(.horizontal, 6.5)
                                            .padding(.vertical, 2.5)
                                            .background(Color.black.opacity(0.25))
                                            .clipShape(Capsule())

                                            if item.id == displayItems.first?.id {
                                                HStack(spacing: 3) {
                                                    Image(systemName: "arrow.up.circle.fill")
                                                        .font(.system(size: 8))
                                                    Text("Cần nộp")
                                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                                        .lineLimit(1)
                                                }
                                                .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2.5)
                                                .background(Color.black.opacity(0.25))
                                                .clipShape(Capsule())
                                            }
                                        }

                                        Text(item.title)
                                            .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.88)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(Color.black.opacity(0.18))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
