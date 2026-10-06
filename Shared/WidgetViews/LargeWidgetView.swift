import SwiftUI
import WidgetKit

public struct LargeWidgetView: View {
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

    private var heroItem: Coursework? {
        todayItems.first ?? tomorrowItems.first
    }

    private var otherItems: [Coursework] {
        guard let hero = heroItem else { return [] }
        return Array(courseworkList.filter { $0.id != hero.id }.prefix(3))
    }

    private var headerTitle: String {
        if !todayItems.isEmpty && !tomorrowItems.isEmpty {
            return "Hôm nay & Ngày mai"
        } else if !todayItems.isEmpty {
            return "Báo bài Hôm nay"
        } else {
            return "Báo bài Ngày mai"
        }
    }

    public var body: some View {
        ZStack {
            WidgetAppleGlassBackground(cornerRadius: 22)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(heroItem?.isDueToday == true ? Color(red: 1.0, green: 0.55, blue: 0.20) : Color(red: 0.22, green: 0.95, blue: 0.95))

                        Text(headerTitle)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    if !courseworkList.isEmpty {
                        Text("\(courseworkList.count) bài cần nộp")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.95))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                    } else {
                        Text("Thảnh thơi")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.70))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 8)

                if let hero = heroItem {
                    Link(destination: URL(string: hero.alternateLink ?? "https://classroom.google.com")!) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                SubjectArtBadgeView(courseName: hero.courseName, title: hero.title, size: 17)
                                Text(hero.courseName)
                                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                    .lineLimit(1)

                                Spacer(minLength: 4)

                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 8.5))
                                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                    Text(hero.friendlyDueString)
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 7.5)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.25))
                                .clipShape(Capsule())

                                HStack(spacing: 3.5) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 8.5))
                                    Text("Cần nộp")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.25))
                                .clipShape(Capsule())
                            }

                            Text(hero.title)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .lineSpacing(2)
                                .minimumScaleFactor(0.90)
                        }
                        .padding(11)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 7)

                    if !otherItems.isEmpty {
                        VStack(spacing: 5.5) {
                            ForEach(otherItems) { item in
                                Link(destination: URL(string: item.alternateLink ?? "https://classroom.google.com")!) {
                                    HStack(alignment: .center, spacing: 8) {
                                        SubjectArtBadgeView(courseName: item.courseName, title: item.title, size: 16)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(alignment: .center, spacing: 4) {
                                                Text(item.courseName)
                                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                                    .lineLimit(1)

                                                Spacer(minLength: 4)

                                                HStack(spacing: 3) {
                                                    Image(systemName: "clock.fill")
                                                        .font(.system(size: 7.5))
                                                        .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))
                                                    Text(item.compactDueString)
                                                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                                        .foregroundStyle(.white)
                                                }
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2.5)
                                                .background(Color.black.opacity(0.25))
                                                .clipShape(Capsule())
                                            }

                                            Text(item.title)
                                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.88)
                                        }
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.black.opacity(0.15))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Spacer(minLength: 0)

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
                                Text("Chỉ còn 1 bài duy nhất!")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.25))

                                Text("Hoàn thành bài tập trên là bạn đã xong hết bài tập hôm nay & mai ✦")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.14))
                        )

                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)
                } else {
                    VStack(spacing: 10) {
                        Spacer(minLength: 0)

                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 58, height: 58)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.70))
                        }

                        Text("Thảnh thơi!")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Không có bài tập nào cần nộp hôm nay & ngày mai ✦")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(13)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
